// ============================================================================
// ExamForge AI — Flutterwave Checkout Session Edge Function
// ============================================================================
// Initializes a Flutterwave checkout session server-side.
//
// WHY THIS EXISTS:
//   The Flutter client previously called the Flutterwave API directly to
//   initialize payment sessions, exposing the secret key in the process.
//   Moving this to an Edge Function ensures:
//     1. FLUTTERWAVE_SECRET_KEY never reaches the client
//     2. Transaction is recorded in the DB before the user pays
//     3. amount_integrity_hash is generated server-side (tamper-proof)
//     4. Only authenticated users can initiate payments
//
// SECURITY MODEL:
//   1. Requires authenticated user (JWT validation)
//   2. Amount and currency are validated server-side
//   3. Transaction is recorded with an integrity hash
//   4. Flutterwave secret key is never exposed to the client
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
        'https://web-alpha-bay-87.vercel.app',
        'https://examforge-ai.vercel.app',
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
// Prevents timing attacks when comparing sensitive values.
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

// ─── Generate amount integrity hash ──────────────────────────────────────
// Uses the Web Crypto API to produce an HMAC-SHA256 hash binding the
// amount, currency, and txRef together. This hash is stored alongside
// the transaction so the webhook can verify the amount wasn't tampered
// with between checkout initiation and payment completion.
async function generateIntegrityHash(
  amount: string,
  currency: string,
  txRef: string,
  secret: string
): Promise<string> {
  const payload = `${amount}|${currency}|${txRef}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
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

  // ─── CSRF Defense-in-Depth: Validate Origin header ─────────────────────
  const originCheck = (() => {
    const origin = req.headers.get('Origin');
    if (!origin) return { valid: true }; // Server-to-server requests
    const ALLOWED = ALLOWED_ORIGINS; // Already defined in this file
    return { valid: ALLOWED.includes(origin), origin };
  })();
  if (!originCheck.valid) {
    return new Response(
      JSON.stringify({ error: 'Forbidden — invalid origin', detail: `Origin "${originCheck.origin}" not allowed` }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
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

  const { amount, currency, email, txRef, meta } = body;

  // Required fields
  if (!amount || !currency || !email || !txRef) {
    return new Response(
      JSON.stringify({ error: 'Missing required fields: amount, currency, email, txRef' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const parsedAmount = parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    return new Response(JSON.stringify({ error: 'Amount must be a positive number' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Prevent unreasonably large amounts
  if (parsedAmount > 10000000) {
    return new Response(JSON.stringify({ error: 'Amount exceeds maximum allowed (10,000,000)' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Validate currency (supported currencies)
  const supportedCurrencies = ['NGN', 'USD', 'GBP', 'EUR', 'KES', 'GHS', 'ZAR'];
  const normalizedCurrency = currency.toUpperCase();
  if (!supportedCurrencies.includes(normalizedCurrency)) {
    return new Response(
      JSON.stringify({ error: `Unsupported currency: ${currency}. Supported: ${supportedCurrencies.join(', ')}` }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // Validate email format (basic check)
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return new Response(JSON.stringify({ error: 'Invalid email format' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 3: Generate amount integrity hash ──────────────────────────
  const integrityHashSecret = Deno.env.get('FLUTTERWAVE_WEBHOOK_SECRET_HASH') || flutterwaveSecretKey;
  const amountIntegrityHash = await generateIntegrityHash(
    parsedAmount.toString(),
    normalizedCurrency,
    txRef,
    integrityHashSecret
  );

  // ─── Step 4: Record transaction in database BEFORE calling Flutterwave ─
  const { data: transaction, error: txError } = await adminClient
    .from('transactions')
    .insert({
      user_id: user.id,
      amount: parsedAmount,
      currency: normalizedCurrency,
      flutterwave_tx_ref: txRef,
      amount_integrity_hash: amountIntegrityHash,
      status: 'pending',
      metadata: meta || {},
      email: email,
    })
    .select('id')
    .single();

  if (txError || !transaction) {
    console.error('Failed to record transaction:', txError);
    return new Response(JSON.stringify({ error: 'Failed to initialize transaction' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 5: Call Flutterwave API to initialize checkout ─────────────
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000);

  try {
    const flwResponse = await fetch('https://api.flutterwave.com/v3/payments', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${flutterwaveSecretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tx_ref: txRef,
        amount: parsedAmount,
        currency: normalizedCurrency,
        redirect_url: `${Deno.env.get('APP_URL') || 'https://app.examforge.ai'}/payment/callback`,
        customer: {
          email: email,
        },
        customizations: {
          title: 'ExamForge AI',
          logo: 'https://examforge.ai/logo.png',
        },
        meta: {
          ...(meta || {}),
          user_id: user.id,
          transaction_id: transaction.id,
        },
      }),
      signal: controller.signal,
    });

    const flwData = await flwResponse.json();

    if (flwData.status !== 'success' || !flwData.data?.link) {
      // Update transaction status to failed
      await adminClient
        .from('transactions')
        .update({ status: 'failed', processor_response: flwData })
        .eq('id', transaction.id);

      return new Response(
        JSON.stringify({
          error: 'Failed to initialize checkout session',
          details: flwData.message || 'Unknown error from Flutterwave',
        }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ─── Step 6: Return checkout URL ────────────────────────────────────
    return new Response(
      JSON.stringify({
        checkoutUrl: flwData.data.link,
        txRef: txRef,
        transactionId: transaction.id,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    clearTimeout(timeoutId);
    const errorMessage = err instanceof Error ? err.message : String(err);
    const isTimeout = err instanceof DOMException && err.name === 'AbortError';

    // Update transaction status to failed
    await adminClient
      .from('transactions')
      .update({ status: 'failed', processor_response: { error: errorMessage } })
      .eq('id', transaction.id);

    return new Response(
      JSON.stringify({
        error: isTimeout
          ? 'Checkout initialization timed out. Please retry.'
          : 'Checkout initialization failed due to network error',
      }),
      { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
