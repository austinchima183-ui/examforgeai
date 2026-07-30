// ============================================================================
// ExamForge AI — Health Check & Metrics Collection Edge Function
// ============================================================================
// Collects service health metrics and evaluates alert rules.
// Also serves as the /health endpoint for deployment verification.
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
      return ['http://localhost:3000', 'http://localhost:5173'];
  }
})();

function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('Origin') || '';
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

function getSecurityHeaders(): Record<string, string> {
  return {
    'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'no-referrer',
    'Cache-Control': 'no-store, no-cache, must-revalidate',
  };
}

interface HealthCheckResult {
  service: string;
  status: 'healthy' | 'degraded' | 'down';
  responseTimeMs: number;
  details?: Record<string, any>;
}

async function checkDatabaseHealth(supabase: any): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    const { data, error } = await supabase.from('app_health_checks').select('id').limit(1);
    const responseTime = Date.now() - start;
    if (error) return { service: 'database', status: 'down', responseTimeMs: responseTime, details: { error: error.message } };
    const status = responseTime > 1000 ? 'degraded' : 'healthy';
    return { service: 'database', status, responseTimeMs: responseTime };
  } catch (err) {
    return { service: 'database', status: 'down', responseTimeMs: Date.now() - start, details: { error: String(err) } };
  }
}

async function checkStorageHealth(supabase: any): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    const { data, error } = await supabase.storage.listBuckets();
    const responseTime = Date.now() - start;
    if (error) return { service: 'storage', status: 'down', responseTimeMs: responseTime, details: { error: error.message } };
    return { service: 'storage', status: 'healthy', responseTimeMs: responseTime, details: { buckets: data?.length || 0 } };
  } catch (err) {
    return { service: 'storage', status: 'down', responseTimeMs: Date.now() - start, details: { error: String(err) } };
  }
}

async function checkAuthHealth(supabase: any): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    const { error } = await supabase.auth.getSession();
    const responseTime = Date.now() - start;
    if (error && error.message !== 'Auth session missing!') {
      return { service: 'auth', status: 'down', responseTimeMs: responseTime, details: { error: error.message } };
    }
    return { service: 'auth', status: 'healthy', responseTimeMs: responseTime };
  } catch (err) {
    return { service: 'auth', status: 'down', responseTimeMs: Date.now() - start, details: { error: String(err) } };
  }
}

async function checkPaymentHealth(): Promise<HealthCheckResult> {
  const start = Date.now();
  try {
    const flwKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY');
    if (!flwKey) return { service: 'payment', status: 'down', responseTimeMs: 0, details: { error: 'FLUTTERWAVE_SECRET_KEY not configured' } };
    const response = await fetch('https://api.flutterwave.com/v3/transactions', {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${flwKey}` },
    });
    const responseTime = Date.now() - start;
    if (!response.ok) return { service: 'payment', status: 'degraded', responseTimeMs: responseTime, details: { status: response.status } };
    return { service: 'payment', status: 'healthy', responseTimeMs: responseTime };
  } catch (err) {
    return { service: 'payment', status: 'down', responseTimeMs: Date.now() - start, details: { error: String(err) } };
  }
}

async function recordHealthCheck(supabase: any, result: HealthCheckResult): Promise<void> {
  await supabase.from('app_health_checks').insert({
    service_name: result.service,
    status: result.status,
    response_time_ms: result.responseTimeMs,
    details: result.details || {},
    checked_at: new Date().toISOString(),
  });
}

async function evaluateAlerts(supabase: any, healthResults: HealthCheckResult[]): Promise<void> {
  for (const result of healthResults) {
    if (result.status === 'down') {
      const { data: existingAlert } = await supabase.from('alert_state').select('*').eq('alert_name', `${result.service}_down`).eq('is_firing', true).maybeSingle();
      if (!existingAlert) {
        await supabase.from('alert_state').upsert({
          alert_name: `${result.service}_down`, severity: 'critical', description: `${result.service} service is down`,
          is_firing: true, first_fired_at: new Date().toISOString(), last_fired_at: new Date().toISOString(),
          current_value: { response_time_ms: result.responseTimeMs, status: result.status }, threshold: { status: 'down' },
        }, { onConflict: 'alert_name' });
        await supabase.from('alert_history').insert({
          alert_name: `${result.service}_down`, severity: 'critical', description: `${result.service} service is down`,
          fired_at: new Date().toISOString(), metric_value: result.responseTimeMs, threshold_value: 0, metadata: result.details || {},
        });
      } else {
        await supabase.from('alert_state').update({ last_fired_at: new Date().toISOString(), current_value: { response_time_ms: result.responseTimeMs } }).eq('alert_name', `${result.service}_down`);
      }
    } else if (result.status === 'degraded') {
      const { data: existingAlert } = await supabase.from('alert_state').select('*').eq('alert_name', `${result.service}_degraded`).eq('is_firing', true).maybeSingle();
      if (!existingAlert) {
        await supabase.from('alert_state').upsert({
          alert_name: `${result.service}_degraded`, severity: 'warning', description: `${result.service} service is degraded (${result.responseTimeMs}ms)`,
          is_firing: true, first_fired_at: new Date().toISOString(), last_fired_at: new Date().toISOString(),
          current_value: { response_time_ms: result.responseTimeMs }, threshold: { max_response_time_ms: 1000 },
        }, { onConflict: 'alert_name' });
      }
    } else {
      await supabase.from('alert_state').update({ is_firing: false, resolved_at: new Date().toISOString() })
        .in('alert_name', [`${result.service}_down`, `${result.service}_degraded`]).eq('is_firing', true);
    }
  }
}

Deno.serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);
  const securityHeaders = getSecurityHeaders();
  const allHeaders = { ...corsHeaders, ...securityHeaders };

  if (req.method === 'OPTIONS') return new Response('ok', { headers: allHeaders });

  // ─── Authentication ──────────────────────────────────────────────
  // Health check requires authentication to prevent abuse.
  // Only authenticated users or internal service requests can trigger
  // health checks that write to the database.
  const authHeader = req.headers.get('Authorization');
  const apiKey = req.headers.get('apikey');
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Allow service-role requests (e.g., cron jobs) without user auth
  const isServiceRequest = apiKey === supabaseServiceKey;

  let isAuthenticatedUser = false;
  if (authHeader && !isServiceRequest) {
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    isAuthenticatedUser = !authError && !!user;
  }

  if (!isServiceRequest && !isAuthenticatedUser) {
    // For unauthenticated requests, return a read-only health status
    // without writing to the database
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const dbStart = Date.now();
    try {
      await supabase.from('schools').select('id').limit(1);
    } catch {}
    const dbResponseTime = Date.now() - dbStart;

    return new Response(JSON.stringify({
      status: dbResponseTime < 1000 ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      version: Deno.env.get('DEPLOY_VERSION') || 'unknown',
      environment: Deno.env.get('ENVIRONMENT') || 'unknown',
      services: { database: { status: dbResponseTime < 1000 ? 'healthy' : 'degraded', responseTimeMs: dbResponseTime } },
    }), {
      status: 200,
      headers: { ...allHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Authenticated: Full health check with DB writes ────────────
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  const healthResults = await Promise.all([
    checkDatabaseHealth(supabase), checkStorageHealth(supabase),
    checkAuthHealth(supabase), checkPaymentHealth(),
  ]);

  for (const result of healthResults) await recordHealthCheck(supabase, result);
  await evaluateAlerts(supabase, healthResults);

  const anyDown = healthResults.some(r => r.status === 'down');
  const anyDegraded = healthResults.some(r => r.status === 'degraded');
  const overallStatus = anyDown ? 'down' : anyDegraded ? 'degraded' : 'healthy';

  const response = {
    status: overallStatus,
    timestamp: new Date().toISOString(),
    version: Deno.env.get('DEPLOY_VERSION') || 'unknown',
    environment: Deno.env.get('ENVIRONMENT') || 'unknown',
    services: healthResults.reduce((acc, r) => {
      acc[r.service] = { status: r.status, responseTimeMs: r.responseTimeMs, ...r.details };
      return acc;
    }, {} as Record<string, any>),
  };

  return new Response(JSON.stringify(response), {
    status: anyDown ? 503 : 200,
    headers: { ...allHeaders, 'Content-Type': 'application/json' },
  });
});
