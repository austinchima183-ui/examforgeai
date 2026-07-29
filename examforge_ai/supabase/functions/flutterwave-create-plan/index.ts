// ============================================================================
// ExamForge AI — Flutterwave Payment Plan Creation Edge Function
// ============================================================================
// Creates a recurring payment plan via Flutterwave.
// Must be server-side because it requires the Flutterwave secret key.
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ALLOWED_ORIGINS = (() => {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  switch (env) {
    case 'production':
      return ['https://examforge.ai', 'https://www.examforge.ai', 'https://app.examforge.ai', 'https://admin.examforge.ai'];
    case 'staging':
      return ['https://staging.examforge.ai', 'https://staging-app.examforge.ai'];
    default:
      return ['http://localhost:3000', 'http://localhost:5173', 'http://127.0.0.1:3000', 'http://127.0.0.1:5173'];
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

  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  // Authenticate
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized — missing auth token' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const flutterwaveSecretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY');

  if (!flutterwaveSecretKey) {
    console.error('FLUTTERWAVE_SECRET_KEY not configured');
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader } } });
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid authentication token' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  // Authorize: only super_admin or school_admin can create plans
  const { data: userProfile } = await userClient.from('users').select('role').eq('id', user.id).maybeSingle();
  if (!userProfile || !['super_admin', 'school_admin'].includes(userProfile.role)) {
    return new Response(JSON.stringify({ error: 'Forbidden — insufficient permissions' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  // Parse and validate request
  let body: Record<string, any>;
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }

  const { name, amount, currency, interval } = body;
  if (!name || !amount || !currency || !interval) {
    return new Response(JSON.stringify({ error: 'Missing required fields: name, amount, currency, interval' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const parsedAmount = parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    return new Response(JSON.stringify({ error: 'Amount must be a positive number' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const validIntervals = ['daily', 'weekly', 'monthly', 'quarterly', 'biannually', 'annually'];
  if (!validIntervals.includes(interval.toLowerCase())) {
    return new Response(JSON.stringify({ error: `Invalid interval. Must be one of: ${validIntervals.join(', ')}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const supportedCurrencies = ['NGN', 'USD', 'GBP', 'EUR', 'KES', 'GHS', 'ZAR'];
  const normalizedCurrency = currency.toUpperCase();
  if (!supportedCurrencies.includes(normalizedCurrency)) {
    return new Response(JSON.stringify({ error: `Unsupported currency: ${currency}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  // Call Flutterwave API
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000);

  try {
    const flwResponse = await fetch('https://api.flutterwave.com/v3/payment-plans', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${flutterwaveSecretKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, amount: parsedAmount, currency: normalizedCurrency, interval: interval.toLowerCase() }),
      signal: controller.signal,
    });

    const flwData = await flwResponse.json();
    clearTimeout(timeoutId);

    if (flwData.status !== 'success') {
      return new Response(JSON.stringify({ error: 'Failed to create payment plan', details: flwData.message || 'Unknown error' }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Audit log
    await adminClient.from('audit_log').insert({
      user_id: user.id,
      action: 'PAYMENT_PLAN_CREATED',
      resource_type: 'payment_plan',
      details: { plan_id: flwData.data?.id, name, amount: parsedAmount, currency: normalizedCurrency, interval },
    });

    return new Response(JSON.stringify({
      planId: flwData.data?.id,
      name: flwData.data?.name,
      amount: flwData.data?.amount,
      currency: flwData.data?.currency,
      interval: flwData.data?.interval,
      planCode: flwData.data?.plan_code,
    }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (err) {
    clearTimeout(timeoutId);
    const isTimeout = err instanceof DOMException && err.name === 'AbortError';
    return new Response(JSON.stringify({ error: isTimeout ? 'Plan creation timed out' : 'Plan creation failed' }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
