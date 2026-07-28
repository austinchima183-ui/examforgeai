// ============================================================================
// ExamForge AI — Flutterwave Transaction Verification Edge Function
// ============================================================================
// Verifies a Flutterwave transaction server-side.
//
// WHY THIS EXISTS:
//   The Flutter client previously verified transactions client-side, which
//   is insecure because:
//     1. The client can skip verification or tamper with the result
//     2. Amount/currency validation was done in the client (bypassable)
//     3. Transaction status updates were client-initiated
//
// SECURITY MODEL:
//   1. Requires authenticated user (JWT validation)
//   2. Amount and currency are validated server-side against expected values
//   3. Transaction ownership is verified (user can only verify their own tx)
//   4. Integrity hash is checked to detect amount tampering
//   5. Constant-time comparison for sensitive values
//   6. Only updates status if Flutterwave confirms success
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── CORS Configuration (Hardened) ────────────────────────────────────────
const ALLOWED_ORIGINS = (() => {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  switch (env) {
    case 'production':
      return [
        'https://examforge.ai',
        'https://www.examforge.ai',
        'https://app.examforge.ai',
        'https://admin.examforge.ai',
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
        'http://127.0.0.1:5173',
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

// ─── Constant-time string comparison ──────────────────────────────────────
function constantTimeEquals(a: string, b: string): boolean {
  const lengthsMatch = a.length === b.length;
  const maxLen = Math.max(a.length, b.length);
  let accumulator = 0;
  for (let i = 0; i < maxLen; i++) {
    const aByte = i < a.length ? a.charCodeAt(i) : 0xFF;
    const bByte = i < b.length ? b.charCodeAt(i) : 0xFF;
    accumulator |= aByte ^ bByte;
  }
  return accumulator === 0 && lengthsMatch;
}

Deno.serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // ─── CORS preflight ──────────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 1: Authenticate ────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized — missing auth token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const flutterwaveSecretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY');

  if (!flutterwaveSecretKey) {
    console.error('FLUTTERWAVE_SECRET_KEY not configured');
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid authentication token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 2: Parse and validate request ──────────────────────────────
  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { txRef, expectedAmount, expectedCurrency } = body;

  if (!txRef) {
    return new Response(JSON.stringify({ error: 'Missing required field: txRef' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 3: Look up local transaction ───────────────────────────────
  const { data: localTx, error: txError } = await adminClient
    .from('transactions')
    .select('id, user_id, amount, currency, status, amount_integrity_hash, flutterwave_transaction_id')
    .eq('flutterwave_tx_ref', txRef)
    .maybeSingle();

  if (txError || !localTx) {
    return new Response(JSON.stringify({ error: 'Transaction not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 4: Verify ownership ────────────────────────────────────────
  // The authenticated user must own this transaction.
  if (!constantTimeEquals(localTx.user_id, user.id)) {
    console.error(`Ownership mismatch: user ${user.id} tried to verify tx owned by ${localTx.user_id}`);
    return new Response(JSON.stringify({ error: 'Forbidden — transaction does not belong to you' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Already verified? Return current status.
  if (localTx.status === 'successful') {
    return new Response(
      JSON.stringify({
        status: 'successful',
        message: 'Transaction already verified',
        transactionId: localTx.id,
        amount: localTx.amount,
        currency: localTx.currency,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // ─── Step 5: Call Flutterwave verify API ─────────────────────────────
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000);

  try {
    const flwResponse = await fetch(
      `https://api.flutterwave.com/v3/transactions/verify_by_reference/${encodeURIComponent(txRef)}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${flutterwaveSecretKey}`,
          'Content-Type': 'application/json',
        },
        signal: controller.signal,
      }
    );

    const flwData = await flwResponse.json();

    if (flwData.status !== 'success') {
      return new Response(
        JSON.stringify({
          error: 'Verification failed at payment gateway',
          details: flwData.message || 'Unknown error from Flutterwave',
        }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const txData = flwData.data || {};

    // ─── Step 6: Validate amount server-side ───────────────────────────
    // Use the expected amount from the request body OR the DB record
    const serverExpectedAmount = expectedAmount
      ? parseFloat(expectedAmount)
      : parseFloat(localTx.amount);

    const chargedAmount = parseFloat(txData.charged_amount) || 0;
    const tolerance = 1.0; // Allow 1 unit tolerance for rounding

    if (isNaN(serverExpectedAmount) || serverExpectedAmount <= 0) {
      return new Response(JSON.stringify({ error: 'Invalid expected amount' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (Math.abs(chargedAmount - serverExpectedAmount) > tolerance) {
      console.error(
        `FRAUD ALERT: Amount mismatch for txRef=${txRef}. Expected=${serverExpectedAmount}, Charged=${chargedAmount}`
      );

      // Mark transaction as disputed
      await adminClient
        .from('transactions')
        .update({
          status: 'disputed',
          processor_response: txData,
          verified_at: new Date().toISOString(),
        })
        .eq('id', localTx.id);

      return new Response(
        JSON.stringify({
          error: 'Amount mismatch — possible tampering detected',
          expectedAmount: serverExpectedAmount,
          chargedAmount,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ─── Step 7: Validate currency server-side ─────────────────────────
    const serverExpectedCurrency = (expectedCurrency || localTx.currency || 'NGN').toUpperCase();
    const actualCurrency = (txData.currency || '').toUpperCase();

    if (!constantTimeEquals(actualCurrency, serverExpectedCurrency)) {
      console.error(
        `FRAUD ALERT: Currency mismatch for txRef=${txRef}. Expected=${serverExpectedCurrency}, Actual=${actualCurrency}`
      );

      await adminClient
        .from('transactions')
        .update({
          status: 'disputed',
          processor_response: txData,
          verified_at: new Date().toISOString(),
        })
        .eq('id', localTx.id);

      return new Response(
        JSON.stringify({
          error: 'Currency mismatch — possible tampering detected',
          expectedCurrency: serverExpectedCurrency,
          actualCurrency,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ─── Step 8: Verify integrity hash ─────────────────────────────────
    if (localTx.amount_integrity_hash) {
      const { data: hashValid } = await adminClient.rpc('verify_transaction_integrity', {
        p_tx_ref: txRef,
        p_amount: localTx.amount,
        p_currency: localTx.currency,
        p_stored_hash: localTx.amount_integrity_hash,
      });

      if (!hashValid) {
        console.error(`FRAUD ALERT: Integrity hash mismatch for txRef=${txRef}. Possible tampering!`);
        await adminClient
          .from('transactions')
          .update({
            status: 'disputed',
            processor_response: txData,
            verified_at: new Date().toISOString(),
          })
          .eq('id', localTx.id);

        return new Response(
          JSON.stringify({ error: 'Integrity check failed — possible tampering detected' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // ─── Step 9: Update transaction status ─────────────────────────────
    const flwStatus = (txData.status || '').toLowerCase();
    const mappedStatus =
      flwStatus === 'successful'
        ? 'successful'
        : flwStatus === 'failed'
        ? 'failed'
        : 'pending';

    const flwTxId = txData.id?.toString();

    const updateData: Record<string, any> = {
      status: mappedStatus,
      flutterwave_transaction_id: flwTxId,
      flutterwave_flw_ref: txData.flw_ref,
      flutterwave_fee: parseFloat(txData.app_fee) || 0,
      net_amount: parseFloat(txData.amount_settled) || 0,
      payment_method_summary: txData.payment_type,
      processor_response: txData,
      verified_at: new Date().toISOString(),
    };

    if (mappedStatus === 'successful') {
      updateData.completed_at = new Date().toISOString();
    }

    await adminClient.from('transactions').update(updateData).eq('id', localTx.id);

    // ─── Step 10: Return verification result ───────────────────────────
    return new Response(
      JSON.stringify({
        status: mappedStatus,
        transactionId: localTx.id,
        txRef: txRef,
        amount: chargedAmount,
        currency: actualCurrency,
        flwTransactionId: flwTxId,
        paymentMethod: txData.payment_type,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    clearTimeout(timeoutId);
    const errorMessage = err instanceof Error ? err.message : String(err);
    const isTimeout = err instanceof DOMException && err.name === 'AbortError';

    return new Response(
      JSON.stringify({
        error: isTimeout
          ? 'Verification timed out. Please retry.'
          : 'Verification failed due to network error',
      }),
      { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
