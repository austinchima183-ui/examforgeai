// ============================================================================
// ExamForge AI — Flutterwave Subscription Plan Subscription Edge Function
// ============================================================================
// Subscribes a customer to a Flutterwave payment plan.
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

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized — missing auth token' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const flutterwaveSecretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY');

  if (!flutterwaveSecretKey) {
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader } } });
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid authentication token' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  let body: Record<string, any>;
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }

  const { email, planCode, amount } = body;
  if (!email || !planCode) {
    return new Response(JSON.stringify({ error: 'Missing required fields: email, planCode' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return new Response(JSON.stringify({ error: 'Invalid email format' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  // Create subscription checkout via Flutterwave
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000);

  try {
    const subscriptionPayload: Record<string, any> = {
      tx_ref: `sub_${Date.now()}_${user.id.substring(0, 8)}`,
      amount: amount ? parseFloat(amount) : undefined,
      currency: 'NGN',
      redirect_url: `${Deno.env.get('APP_URL') || 'https://app.examforge.ai'}/payment/callback`,
      customer: { email },
      plan: planCode,
      customizations: { title: 'ExamForge AI Subscription', logo: 'https://examforge.ai/logo.png' },
      meta: { user_id: user.id },
    };

    const flwResponse = await fetch('https://api.flutterwave.com/v3/payments', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${flutterwaveSecretKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(subscriptionPayload),
      signal: controller.signal,
    });

    const flwData = await flwResponse.json();
    clearTimeout(timeoutId);

    if (flwData.status !== 'success' || !flwData.data?.link) {
      return new Response(JSON.stringify({ error: 'Failed to initialize subscription', details: flwData.message }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Audit log
    await adminClient.from('audit_log').insert({
      user_id: user.id,
      action: 'SUBSCRIPTION_INITIALIZED',
      resource_type: 'subscription',
      details: { plan_code: planCode, email },
    });

    return new Response(JSON.stringify({
      checkoutUrl: flwData.data.link,
      txRef: subscriptionPayload.tx_ref,
    }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (err) {
    clearTimeout(timeoutId);
    const isTimeout = err instanceof DOMException && err.name === 'AbortError';
    return new Response(JSON.stringify({ error: isTimeout ? 'Subscription timed out' : 'Subscription failed' }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
