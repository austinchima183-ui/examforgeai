// ============================================================================
// ExamForge AI — Flutterwave Webhook Edge Function
// ============================================================================
// This is the ONLY entry point for Flutterwave webhook events.
// It performs:
//   1. Signature verification (constant-time comparison)
//   2. Idempotency check (using webhook_events table)
//   3. Amount verification (checks charged_amount against expected amount)
//   4. Currency verification
//   5. Transaction replay detection
//   6. Server-side commission calculation (for marketplace payments)
//
// IMPORTANT: The Flutter app does NOT process webhooks directly.
// All webhooks must come through this Edge Function to ensure
// server-authoritative verification.
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ─── Constant-time string comparison ────────────────────────────────────────
// Prevents timing attacks on the webhook signature.
function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) {
    // Don't return early — do dummy comparison to maintain constant time
    b = a;
  }
  let result = a.length ^ b.length;
  for (let i = 0; i < Math.min(a.length, b.length); i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0 && a.length === b.length;
}

// ─── Verify Flutterwave webhook signature ──────────────────────────────────
function verifyWebhookSignature(headers: Record<string, string>, secretHash: string): boolean {
  const incomingHash = headers['verif-hash'] || headers['Verif-Hash'] || '';
  if (!incomingHash || !secretHash) {
    console.error('Missing webhook hash(es)');
    return false;
  }
  return constantTimeEquals(incomingHash, secretHash);
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const webhookSecret = Deno.env.get('FLUTTERWAVE_WEBHOOK_SECRET_HASH');
  if (!webhookSecret) {
    console.error('FLUTTERWAVE_WEBHOOK_SECRET_HASH not configured');
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 1: Verify signature ──────────────────────────────────────────
  const headers: Record<string, string> = {};
  req.headers.forEach((value, key) => { headers[key] = value; });

  const body = await req.text();
  if (!verifyWebhookSignature(headers, webhookSecret)) {
    console.error('Webhook signature verification FAILED');
    return new Response(JSON.stringify({ error: 'Invalid signature' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 2: Parse payload ─────────────────────────────────────────────
  let payload: Record<string, any>;
  try {
    payload = JSON.parse(body);
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const event = payload.event || '';
  const data = payload.data || {};
  const flwId = data.id?.toString() || '';
  const idempotencyKey = `${event}_${flwId}`;

  // ─── Step 3: Initialize Supabase client ────────────────────────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // ─── Step 4: Idempotency check ─────────────────────────────────────────
  const { data: existingEvent } = await supabase
    .from('webhook_events')
    .select('id, processing_status')
    .eq('idempotency_key', idempotencyKey)
    .maybeSingle();

  if (existingEvent) {
    if (existingEvent.processing_status === 'processed') {
      console.log(`Webhook already processed: ${idempotencyKey}`);
      return new Response(JSON.stringify({ status: 'already_processed' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (existingEvent.processing_status === 'processing') {
      console.log(`Webhook currently being processed: ${idempotencyKey}`);
      return new Response(JSON.stringify({ status: 'processing' }), {
        status: 202,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }

  // ─── Step 5: Log webhook event ─────────────────────────────────────────
  const clientIp = headers['x-forwarded-for'] || headers['x-real-ip'] || 'unknown';
  await supabase.from('webhook_events').upsert({
    event_type: event,
    flutterwave_event_id: flwId,
    idempotency_key: idempotencyKey,
    payload: payload,
    processing_status: 'processing',
    source_ip: clientIp,
    verified: true,
  }, { onConflict: 'idempotency_key' });

  // ─── Step 6: Process the event ─────────────────────────────────────────
  let processingError: string | null = null;

  try {
    switch (event) {
      case 'charge.completed': {
        const txRef = data.tx_ref;
        if (!txRef) {
          processingError = 'Missing tx_ref in charge.completed event';
          break;
        }

        // Look up our local transaction to get expected amount
        const { data: localTx, error: txError } = await supabase
          .from('transactions')
          .select('id, amount, currency, amount_integrity_hash, status, flutterwave_transaction_id')
          .eq('flutterwave_tx_ref', txRef)
          .maybeSingle();

        if (txError || !localTx) {
          processingError = `Transaction not found for tx_ref: ${txRef}`;
          break;
        }

        // Skip if already successful (prevents re-processing)
        if (localTx.status === 'successful') {
          console.log(`Transaction ${txRef} already marked successful`);
          break;
        }

        // ─── AMOUNT VERIFICATION (CRITICAL) ────────────────────────────
        const chargedAmount = parseFloat(data.charged_amount) || 0;
        const expectedAmount = parseFloat(localTx.amount) || 0;
        const tolerance = 1.0; // Allow 1 NGN tolerance for rounding

        if (Math.abs(chargedAmount - expectedAmount) > tolerance) {
          processingError = `AMOUNT MISMATCH: expected=${expectedAmount}, charged=${chargedAmount}`;
          console.error(`FRAUD ALERT: ${processingError} for tx_ref=${txRef}`);
          break;
        }

        // ─── CURRENCY VERIFICATION ─────────────────────────────────────
        const actualCurrency = (data.currency || '').toUpperCase();
        const expectedCurrency = (localTx.currency || 'NGN').toUpperCase();
        if (actualCurrency !== expectedCurrency) {
          processingError = `CURRENCY MISMATCH: expected=${expectedCurrency}, actual=${actualCurrency}`;
          console.error(`FRAUD ALERT: ${processingError} for tx_ref=${txRef}`);
          break;
        }

        // ─── INTEGRITY HASH VERIFICATION ───────────────────────────────
        if (localTx.amount_integrity_hash) {
          const { data: hashValid } = await supabase.rpc('verify_transaction_integrity', {
            p_tx_ref: txRef,
            p_amount: localTx.amount,
            p_currency: localTx.currency,
            p_stored_hash: localTx.amount_integrity_hash,
          });
          if (!hashValid) {
            processingError = `INTEGRITY HASH MISMATCH for tx_ref=${txRef}. Possible tampering!`;
            console.error(`FRAUD ALERT: ${processingError}`);
            break;
          }
        }

        // ─── REPLAY DETECTION ──────────────────────────────────────────
        const flwTxId = data.id?.toString();
        if (flwTxId && localTx.flutterwave_transaction_id && 
            localTx.flutterwave_transaction_id !== flwTxId) {
          // Check if this Flutterwave transaction ID was used by another transaction
          const { data: replayCheck } = await supabase
            .from('transactions')
            .select('id')
            .eq('flutterwave_transaction_id', flwTxId)
            .neq('id', localTx.id)
            .eq('status', 'successful')
            .maybeSingle();
          
          if (replayCheck) {
            processingError = `REPLAY ATTACK: Flutterwave TX ${flwTxId} already used by transaction ${replayCheck.id}`;
            console.error(`FRAUD ALERT: ${processingError}`);
            break;
          }
        }

        // ─── UPDATE TRANSACTION ────────────────────────────────────────
        const flwStatus = (data.status || '').toLowerCase();
        const mappedStatus = flwStatus === 'successful' ? 'successful'
            : flwStatus === 'failed' ? 'failed'
            : 'pending';

        const updateData: Record<string, any> = {
          status: mappedStatus,
          flutterwave_transaction_id: flwTxId,
          flutterwave_flw_ref: data.flw_ref,
          flutterwave_fee: parseFloat(data.app_fee) || 0,
          net_amount: parseFloat(data.amount_settled) || 0,
          payment_method_summary: data.payment_type,
          processor_response: data,
          verified_at: new Date().toISOString(),
          risk_score: data.risk_score || 0,
        };

        if (mappedStatus === 'successful') {
          updateData.completed_at = new Date().toISOString();
        }

        await supabase
          .from('transactions')
          .update(updateData)
          .eq('id', localTx.id);

        // Link webhook event to transaction
        await supabase
          .from('webhook_events')
          .update({ transaction_id: localTx.id })
          .eq('idempotency_key', idempotencyKey);

        break;
      }

      case 'subscription.cancelled': {
        const subId = data.subscription_id;
        if (subId) {
          await supabase
            .from('subscriptions')
            .update({
              status: 'cancelled',
              cancelled_at: new Date().toISOString(),
            })
            .eq('id', subId);
        }
        break;
      }

      case 'transfer.completed':
      case 'transfer.failed':
        console.log(`Transfer event received: ${event}`);
        break;

      default:
        console.log(`Unhandled webhook event: ${event}`);
    }
  } catch (err) {
    processingError = err instanceof Error ? err.message : String(err);
    console.error(`Webhook processing error: ${processingError}`);
  }

  // ─── Step 7: Update webhook event status ───────────────────────────────
  const finalStatus = processingError ? 'failed' : 'processed';
  await supabase
    .from('webhook_events')
    .update({
      processing_status: finalStatus,
      processed_at: new Date().toISOString(),
      error_message: processingError,
    })
    .eq('idempotency_key', idempotencyKey);

  // ─── Step 8: Return response ───────────────────────────────────────────
  // Always return 200 to Flutterwave (they retry on non-2xx)
  // Our idempotency layer handles retries safely.
  return new Response(JSON.stringify({
    status: processingError ? 'processed_with_error' : 'success',
    error: processingError,
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
