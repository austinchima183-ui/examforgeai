// ============================================================================
// ExamForge AI — Shared CORS Configuration
// ============================================================================
// Centralized CORS configuration for all Edge Functions.
// Environment-specific origin allow-lists — no wildcards in production.
//
// CSRF DEFENSE-IN-DEPTH:
//   This module provides both CORS headers and Origin validation.
//   While JWT Bearer tokens are not subject to CSRF (browsers don't
//   auto-attach Authorization headers), we validate the Origin header
//   on all mutation requests as an additional layer of protection.
//   This prevents:
//     - Cross-origin form submissions from malicious sites
//     - Preflight bypass attacks
//     - Confused deputy attacks
//
//   The Origin check is applied BEFORE request processing. If the
//   Origin header is present and doesn't match our allow-list,
//   the request is rejected with 403.

export const ALLOWED_ORIGINS = (() => {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  switch (env) {
    case 'production':
      return [
        'https://examforge.ai',
        'https://www.examforge.ai',
        'https://app.examforge.ai',
        'https://admin.examforge.ai',
        // Vercel deployment URLs (auto-generated)
        'https://web-alpha-bay-87.vercel.app',
        'https://examforge-ai.vercel.app',
      ];
    case 'staging':
      return [
        'https://staging.examforge.ai',
        'https://staging-app.examforge.ai',
      ];
    default: // development
      return [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:5173',
      ];
  }
})();

export function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('Origin') || '';
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-csrf-protection',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

// ============================================================================
// Origin Validation — CSRF Defense-in-Depth
// ============================================================================
// Validates that the request's Origin header matches our allowed origins.
// Returns true if the origin is valid or absent (some internal requests
// may not include Origin). Returns false for disallowed origins.
//
// IMPORTANT: This is NOT the primary CSRF protection — JWT Bearer tokens
// provide that. This is an additional layer that prevents cross-origin
// requests even if a future change accidentally introduces cookie-based
// auth or if the Authorization header is leaked.
// ============================================================================

export interface OriginValidationResult {
  valid: boolean;
  origin: string | null;
  reason?: string;
}

export function validateRequestOrigin(req: Request): OriginValidationResult {
  const origin = req.headers.get('Origin');

  // If no Origin header, allow the request.
  // Browser fetch() always sends Origin for cross-origin requests.
  // Same-origin requests may omit it (HTTP/1.1) or send it (HTTP/2).
  // Server-to-server requests (webhooks, internal) typically omit it.
  if (!origin) {
    return { valid: true, origin: null };
  }

  // Check if the origin is in our allow-list
  if (ALLOWED_ORIGINS.includes(origin)) {
    return { valid: true, origin };
  }

  // Reject disallowed origins
  return {
    valid: false,
    origin,
    reason: `Origin "${origin}" is not in the allowed origins list`,
  };
}

// ============================================================================
// Combined Request Validator
// ============================================================================
// Use this at the top of every mutation endpoint (POST, PUT, DELETE, PATCH)
// to enforce both CORS and Origin validation in a single call.
// ============================================================================

export interface RequestValidationResult {
  allowed: boolean;
  corsHeaders: Record<string, string>;
  rejectionResponse?: Response;
}

export function validateMutationRequest(req: Request): RequestValidationResult {
  const corsHeaders = getCorsHeaders(req);

  // Step 1: Validate Origin header (CSRF defense-in-depth)
  const originCheck = validateRequestOrigin(req);
  if (!originCheck.valid) {
    return {
      allowed: false,
      corsHeaders,
      rejectionResponse: new Response(
        JSON.stringify({
          error: 'Forbidden — invalid origin',
          detail: originCheck.reason,
        }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      ),
    };
  }

  // Step 2: Verify HTTP method is a mutation (defense-in-depth)
  const mutationMethods = ['POST', 'PUT', 'DELETE', 'PATCH'];
  if (!mutationMethods.includes(req.method)) {
    return {
      allowed: false,
      corsHeaders,
      rejectionResponse: new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        {
          status: 405,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      ),
    };
  }

  return { allowed: true, corsHeaders };
}
