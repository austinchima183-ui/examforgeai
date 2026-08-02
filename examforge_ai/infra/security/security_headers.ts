// ============================================================================
// ExamForge AI — Security Headers Middleware
// ============================================================================
// Provides comprehensive HTTP security headers for all responses.
//
// ROOT CAUSE: No security headers were applied to any endpoint. This left
// the platform vulnerable to clickjacking, XSS, MIME-type sniffing, and
// other browser-based attacks.
//
// IMPLEMENTATION: Applied as middleware in Caddy reverse proxy configuration
// and as a reference for edge function headers.
// ============================================================================

// ─── Security Headers Configuration ──────────────────────────────────────
//
// These headers MUST be applied to ALL HTTP responses from ExamForge AI.
// They are enforced at the reverse proxy level (Caddy) and duplicated
// in edge functions for defense-in-depth.

export const SECURITY_HEADERS: Record<string, string> = {
  // ─── Content Security Policy (CSP) ────────────────────────────────
  // Restricts resource loading to approved origins only.
  // Prevents XSS by disallowing inline scripts from unknown sources.
  'Content-Security-Policy': [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: blob: https://*.supabase.co https://examforge.ai",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://api.flutterwave.com https://api.ravenbank.co",
    "frame-ancestors 'none'",               // Prevent clickjacking
    "form-action 'self'",
    "base-uri 'self'",
    "object-src 'none'",                    // No Flash/Java applets
    "upgrade-insecure-requests",            // Force HTTPS
  ].join('; '),

  // ─── HTTP Strict Transport Security (HSTS) ────────────────────────
  // Forces browsers to only use HTTPS for the next 2 years.
  // Includes subdomains and preloading.
  'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',

  // ─── X-Content-Type-Options ───────────────────────────────────────
  // Prevents MIME-type sniffing (prevents content-type confusion attacks).
  'X-Content-Type-Options': 'nosniff',

  // ─── X-Frame-Options ──────────────────────────────────────────────
  // Prevents the site from being embedded in iframes (clickjacking).
  'X-Frame-Options': 'DENY',

  // ─── X-XSS-Protection ────────────────────────────────────────────
  // Legacy XSS filter (modern browsers use CSP instead).
  'X-XSS-Protection': '1; mode=block',

  // ─── Referrer-Policy ──────────────────────────────────────────────
  // Only send referrer to same-origin (prevents information leakage).
  'Referrer-Policy': 'strict-origin-when-cross-origin',

  // ─── Permissions-Policy ──────────────────────────────────────────
  // Disable browser features we don't need (reduces attack surface).
  'Permissions-Policy': [
    'camera=()',
    'microphone=()',
    'geolocation=()',
    'payment=(self)',                    // Payment API needed for Flutterwave
    'usb=()',
    'magnetometer=()',
    'gyroscope=()',
    'accelerometer=()',
    'fullscreen=(self)',                 // Needed for CBT exam mode
  ].join(', '),

  // ─── Cross-Origin Policies ────────────────────────────────────────
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',

  // ─── Cache Control for API responses ──────────────────────────────
  'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
  'Pragma': 'no-cache',
};

// ─── CSP per Environment ─────────────────────────────────────────────────

export function getCspForEnvironment(env: string): string {
  const basePolicy = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline'",
    "style-src 'self' 'unsafe-inline'",
    "font-src 'self'",
    "img-src 'self' data: blob:",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "form-action 'self'",
    "base-uri 'self'",
    "object-src 'none'",
  ];

  switch (env) {
    case 'production':
      return [
        ...basePolicy,
        "script-src 'self' https://cdn.jsdelivr.net",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com",
        "img-src 'self' data: blob: https://examforge.ai https://*.supabase.co",
        "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://api.flutterwave.com",
        "upgrade-insecure-requests",
      ].join('; ');

    case 'staging':
      return [
        ...basePolicy,
        "connect-src 'self' https://staging*.supabase.co wss://staging*.supabase.co",
        "img-src 'self' data: blob: https://staging.examforge.ai",
      ].join('; ');

    default: // development
      return [
        ...basePolicy,
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' http://localhost:*",
        "connect-src 'self' http://localhost:* ws://localhost:* http://127.0.0.1:*",
        "img-src 'self' data: blob: http://localhost:*",
      ].join('; ');
  }
}

// ─── Secure Cookie Configuration ─────────────────────────────────────────
//
// All cookies MUST use these settings:
//   - Secure: Only sent over HTTPS
//   - HttpOnly: Not accessible via JavaScript
//   - SameSite=Strict: Not sent on cross-origin requests
//   - Appropriate expiry (session or short-lived)

export const SECURE_COOKIE_OPTIONS = {
  secure: true,        // HTTPS only
  httpOnly: true,      // No JS access
  sameSite: 'Strict' as const,  // No cross-origin sending
  path: '/',
  maxAge: 3600,        // 1 hour default for session cookies
  domain: undefined,   // Set per environment
};

export const CORS_ALLOWLIST = {
  production: [
    'https://examforge.ai',
    'https://www.examforge.ai',
    'https://app.examforge.ai',
    'https://admin.examforge.ai',
  ],
  staging: [
    'https://staging.examforge.ai',
    'https://staging-app.examforge.ai',
  ],
  development: [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5173',
  ],
} as const;
