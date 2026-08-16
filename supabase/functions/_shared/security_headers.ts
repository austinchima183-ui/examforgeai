// ============================================================================
// ExamForge AI — Shared Security Headers
// ============================================================================
// Security headers applied to ALL Edge Function responses.
// These headers protect against XSS, clickjacking, MIME sniffing, and more.
//
// CSP NONCE SUPPORT:
//   Flutter Web requires 'unsafe-inline' and 'unsafe-eval' for its compiled
//   JavaScript output. We cannot remove these without breaking the app.
//   However, for API Edge Function responses (JSON/SSE), we serve a STRICT
//   CSP with NO unsafe-inline/eval since these responses contain no HTML/JS.
//
//   For HTML responses (rare from edge functions), we generate a nonce
//   that allows only scripts with matching nonce attribute.

/**
 * Generate a cryptographically random CSP nonce.
 * Use this for HTML responses that need to allow specific inline scripts.
 */
export function generateCspNonce(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Get security headers for API (JSON/SSE) responses.
 * Uses STRICT CSP — no unsafe-inline, no unsafe-eval.
 * API responses contain no HTML/JS, so these are not needed.
 */
export function getSecurityHeaders(): Record<string, string> {
  return {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    'Pragma': 'no-cache',
    // Cross-origin isolation headers (enable SharedArrayBuffer, prevent Spectre)
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Resource-Policy': 'same-origin',
    ...getHstsHeader(),
  };
}

/**
 * Get security headers including a strict CSP for API responses.
 * This CSP does NOT include unsafe-inline or unsafe-eval.
 */
export function getSecurityHeadersWithStrictCsp(): Record<string, string> {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  const csp = env === 'production'
    ? [
        "default-src 'none'",
        "frame-ancestors 'none'",
        "form-action 'none'",
        "base-uri 'none'",
      ].join('; ')
    : [
        "default-src 'none'",
        "frame-ancestors 'none'",
      ].join('; ');

  return {
    ...getSecurityHeaders(),
    'Content-Security-Policy': csp,
  };
}

function getHstsHeader(): Record<string, string> {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  if (env === 'production') {
    return {
      'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
    };
  }
  return {};
}

/**
 * Combine CORS headers, security headers, and any extra headers.
 * Security headers are applied last to ensure they cannot be overridden.
 */
export function combineHeaders(
  corsHeaders: Record<string, string>,
  extra?: Record<string, string>,
): Record<string, string> {
  return {
    ...corsHeaders,
    ...extra,
    ...getSecurityHeaders(),
  };
}

/**
 * Combine CORS headers with strict CSP security headers.
 * Use this for JSON/SSE API responses (not HTML).
 */
export function combineHeadersWithStrictCsp(
  corsHeaders: Record<string, string>,
  extra?: Record<string, string>,
): Record<string, string> {
  return {
    ...corsHeaders,
    ...extra,
    ...getSecurityHeadersWithStrictCsp(),
  };
}
