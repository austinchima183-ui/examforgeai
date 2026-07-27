// ============================================================================
// ExamForge AI — Server-Side Payment Operations Edge Function
// ============================================================================
// This Edge Function handles ALL Flutterwave operations that require the
// secret key. The Flutter client must NEVER have access to this key.
//
// Supported operations:
//   1. verify-payment  — Verify a Flutterwave payment server-side
//   2. initiate-refund — Request a refund through Flutterwave
//
// SECURITY MODEL:
//   - All requests require a valid Supabase JWT (authenticated user)
//   - The FLUTTERWAVE_SECRET_KEY is loaded from environment variables
//     and never exposed to the client
//   - All operations are audit-logged
//   - Rate limiting via Supabase Edge Function limits
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── CORS Configuration ─────────────────────────────────────────────────
const ALLOWED_ORIGINS = (() => {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  switch (env) {
    case 'production':
      return [
        'https://examforge.ai',
        'https://www.examforge.ai',
        'https://app.examforge.ai',
      ];
    case 'staging':
      return [
        'https://staging.examforge.ai',
        'https://staging-app.examforge.ai',
      ];
    default:
      return [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://127.0.0.1:3000',
      ];
  }
})();

function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('Origin') || '';
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

Deno.serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Verify authentication ────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const flutterwaveSecretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY')!;

  if (!flutterwaveSecretKey) {
    console.error('FLUTTERWAVE_SECRET_KEY not configured');
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Create user client to verify the JWT
  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: { Authorization: authHeader },
    },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid authentication' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Create admin client for privileged operations
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  // ─── Parse request ────────────────────────────────────────────────────
  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const operation = body.operation as string;

  try {
    switch (operation) {
      // ─── VERIFY PAYMENT ──────────────────────────────────────────────
      case 'verify-payment': {
        const { transaction_id, tx_ref } = body;

        if (!transaction_id && !tx_ref) {
          return new Response(
            JSON.stringify({ error: 'transaction_id or tx_ref required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }

        // Call Flutterwave API with secret key (server-side only)
        const flwUrl = transaction_id
          ? `https://api.flutterwave.com/v3/transactions/${transaction_id}/verify`
          : `https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref=${tx_ref}`;

        const flwResponse = await fetch(flwUrl, {
          headers: {
            'Authorization': `Bearer ${flutterwaveSecretKey}`,
            'Content-Type': 'application/json',
          },
        });

        const flwData = await flwResponse.json();

        // Verify amount matches our records
        if (flwData.status === 'success' && flwData.data) {
          const { data: localTx } = await adminClient
            .from('transactions')
            .select('id, amount, currency, status')
            .eq('flutterwave_tx_ref', flwData.data.tx_ref || tx_ref)
            .maybeSingle();

          if (localTx) {
            const chargedAmount = parseFloat(flwData.data.charged_amount) || 0;
            const expectedAmount = parseFloat(localTx.amount) || 0;

            if (Math.abs(chargedAmount - expectedAmount) > 1.0) {
              // Amount mismatch — potential fraud
              await adminClient.from('audit_log').insert({
                user_id: user.id,
                action: 'PAYMENT_AMOUNT_MISMATCH',
                resource_type: 'transaction',
                resource_id: localTx.id,
                details: {
                  expected: expectedAmount,
                  charged: chargedAmount,
                  tx_ref: flwData.data.tx_ref,
                },
              });

              return new Response(
                JSON.stringify({
                  verified: false,
                  error: 'Amount mismatch',
                  status: flwData.data.status,
                }),
                { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
              );
            }

            // Update transaction status
            if (flwData.data.status === 'successful' && localTx.status !== 'successful') {
              await adminClient
                .from('transactions')
                .update({
                  status: 'successful',
                  flutterwave_transaction_id: flwData.data.id?.toString(),
                  verified_at: new Date().toISOString(),
                  completed_at: new Date().toISOString(),
                })
                .eq('id', localTx.id);
            }
          }
        }

        // Audit log
        await adminClient.from('audit_log').insert({
          user_id: user.id,
          action: 'PAYMENT_VERIFICATION',
          resource_type: 'transaction',
          details: {
            operation: 'verify-payment',
            tx_ref: tx_ref,
            transaction_id: transaction_id,
            flutterwave_status: flwData.data?.status,
          },
        });

        return new Response(
          JSON.stringify({
            verified: flwData.status === 'success' && flwData.data?.status === 'successful',
            status: flwData.data?.status,
            amount: flwData.data?.amount,
            currency: flwData.data?.currency,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      // ─── INITIATE REFUND ─────────────────────────────────────────────
      case 'initiate-refund': {
        const { transaction_id, amount, reason } = body;

        if (!transaction_id) {
          return new Response(
            JSON.stringify({ error: 'transaction_id required' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }

        // Verify the user is authorized for this refund
        const { data: localTx } = await adminClient
          .from('transactions')
          .select('id, user_id, amount, status, school_id')
          .eq('flutterwave_transaction_id', transaction_id.toString())
          .maybeSingle();

        if (!localTx) {
          return new Response(
            JSON.stringify({ error: 'Transaction not found' }),
            { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }

        // Check authorization: user must own the transaction or be an admin
        const { data: userRole } = await adminClient
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

        const isAdmin = ['super_admin', 'school_admin'].includes(userRole?.role);
        const isOwner = localTx.user_id === user.id;

        if (!isAdmin && !isOwner) {
          return new Response(
            JSON.stringify({ error: 'Not authorized to refund this transaction' }),
            { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }

        // Call Flutterwave refund API
        const refundPayload: Record<string, any> = {
          amount: amount ? parseFloat(amount) : undefined,
          reason: reason || 'Customer requested refund',
        };

        const flwResponse = await fetch(
          `https://api.flutterwave.com/v3/transactions/${transaction_id}/refund`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${flutterwaveSecretKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(refundPayload),
          },
        );

        const flwData = await flwResponse.json();

        // Audit log
        await adminClient.from('audit_log').insert({
          user_id: user.id,
          action: 'REFUND_INITIATED',
          resource_type: 'transaction',
          resource_id: localTx.id,
          details: {
            transaction_id,
            amount: refundPayload.amount,
            reason,
            flutterwave_response: flwData.status,
          },
        });

        return new Response(
          JSON.stringify({
            success: flwData.status === 'success',
            refund_id: flwData.data?.id,
            status: flwData.data?.status,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      default:
        return new Response(
          JSON.stringify({ error: `Unknown operation: ${operation}` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
    }
  } catch (err) {
    console.error(`Payment operation error: ${err}`);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
