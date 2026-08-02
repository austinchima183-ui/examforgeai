import type { NextConfig } from 'next'

// ============================================================================
// ExamForge AI — Next.js Production Configuration
// ============================================================================

const securityHeaders = [
  // CORS — restrict to production origin only (replaces Vercel's default access-control-allow-origin: *)
  {
    key: 'Access-Control-Allow-Origin',
    value: 'https://examforge-ai.vercel.app',
  },
  {
    key: 'Access-Control-Allow-Methods',
    value: 'GET,POST,PUT,DELETE,OPTIONS',
  },
  {
    key: 'Access-Control-Allow-Headers',
    value: 'Content-Type,Authorization,x-flutterwave-signature',
  },
  {
    key: 'Access-Control-Max-Age',
    value: '86400',
  },
  // Content Security Policy — strict policy preventing XSS
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'", // 'unsafe-eval' removed — Next.js 16 + React 19 do not require eval()
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: blob: https://pzfnptrrnxkgodclyhft.supabase.co",
      "connect-src 'self' https://pzfnptrrnxkgodclyhft.supabase.co https://api.flutterwave.com wss://pzfnptrrnxkgodclyhft.supabase.co",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join('; '),
  },
  // Prevent clickjacking
  {
    key: 'X-Frame-Options',
    value: 'DENY',
  },
  // Prevent MIME type sniffing
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  // Referrer policy — only send origin to cross-origin
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  // Permissions policy — disable unnecessary features
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
  },
  // Strict Transport Security — force HTTPS for 1 year
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=31536000; includeSubDomains; preload',
  },
  // XSS Protection (legacy, but still useful for older browsers)
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block',
  },
]

const nextConfig: NextConfig = {
  // NOTE: 'output: standalone' removed — incompatible with Vercel's serverless deployment.
  // Use 'standalone' only for self-hosted (Docker/bare-metal) deployments.
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'pzfnptrrnxkgodclyhft.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ]
  },
}

export default nextConfig
