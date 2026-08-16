// ============================================================================
// ExamForge AI — Shared Rate Limiting
// ============================================================================
// Two-tier rate limiting for Edge Functions:
//
//   TIER 1 — In-memory (per-isolate):
//     Fast, zero-latency check. Protects against burst within a single
//     Edge Function instance. Resets when the isolate recycles.
//
//   TIER 2 — Database-backed (Supabase):
//     Global rate limiting across all isolates. Uses an upsert pattern
//     with atomic increment. Slightly higher latency (~5-10ms) but
//     provides true global enforcement.
//
//   For most endpoints, TIER 1 is sufficient (defense-in-depth with
//   Caddy's global rate limiting). For payment and admin endpoints,
//   TIER 2 is recommended to prevent distributed attacks.
//
//   Caddy provides the outermost rate limiting layer:
//     - Static: 10r/m per IP
//     - API: 60r/m per IP
//     - Admin: 30r/m per IP
//     - API subdomain: 120r/m per IP

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── Tier 1: In-Memory Rate Limiting ────────────────────────────────────────
const rateLimitStore = new Map<string, { count: number; resetAt: number }>();

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
  limit: number;
}

/**
 * Check if a request is within rate limits (in-memory, per-isolate).
 * @param key - Unique identifier (e.g., user ID or IP address)
 * @param maxRequests - Maximum requests per window
 * @param windowMs - Window duration in milliseconds
 */
export function checkRateLimit(
  key: string,
  maxRequests: number = 20,
  windowMs: number = 60_000,
): RateLimitResult {
  const now = Date.now();
  const entry = rateLimitStore.get(key);

  if (!entry || now >= entry.resetAt) {
    // New window
    const resetAt = now + windowMs;
    rateLimitStore.set(key, { count: 1, resetAt });
    return { allowed: true, remaining: maxRequests - 1, resetAt, limit: maxRequests };
  }

  if (entry.count >= maxRequests) {
    return { allowed: false, remaining: 0, resetAt: entry.resetAt, limit: maxRequests };
  }

  entry.count++;
  return {
    allowed: true,
    remaining: maxRequests - entry.count,
    resetAt: entry.resetAt,
    limit: maxRequests,
  };
}

// ─── Tier 2: Database-Backed Rate Limiting ─────────────────────────────────
// Uses Supabase to store rate limit counters globally.
// Uses an atomic RPC function for increment to prevent race conditions.

export interface DbRateLimitConfig {
  supabaseUrl: string;
  supabaseServiceKey: string;
  key: string;
  maxRequests: number;
  windowMs: number;
}

/**
 * Check rate limits using the database (global across all isolates).
 * Falls back to in-memory check if the DB call fails.
 */
export async function checkDbRateLimit(config: DbRateLimitConfig): Promise<RateLimitResult> {
  const { supabaseUrl, supabaseServiceKey, key, maxRequests, windowMs } = config;

  try {
    const client = createClient(supabaseUrl, supabaseServiceKey);
    const now = new Date().toISOString();
    const windowStart = new Date(Date.now() - (Date.now() % windowMs)).toISOString();

    // Try atomic RPC first
    const { data, error } = await client.rpc('check_rate_limit_atomic', {
      p_key: key,
      p_max_requests: maxRequests,
      p_window_start: windowStart,
      p_now: now,
    });

    if (!error && data) {
      return {
        allowed: data.allowed,
        remaining: data.remaining || 0,
        resetAt: data.reset_at || Date.now() + windowMs,
        limit: maxRequests,
      };
    }

    // Fallback: use upsert pattern on rate_limits table
    const { data: existing, error: selectError } = await client
      .from('rate_limits')
      .select('count, window_start')
      .eq('key', key)
      .maybeSingle();

    if (selectError) {
      // DB error — fall back to in-memory
      console.warn('DB rate limit check failed, falling back to in-memory:', selectError);
      return checkRateLimit(key, maxRequests, windowMs);
    }

    const currentWindowStart = new Date(windowStart).getTime();

    if (!existing || new Date(existing.window_start).getTime() < currentWindowStart) {
      // New window — reset counter
      await client
        .from('rate_limits')
        .upsert({
          key,
          count: 1,
          window_start: windowStart,
          updated_at: now,
        }, { onConflict: 'key' });

      return {
        allowed: true,
        remaining: maxRequests - 1,
        resetAt: currentWindowStart + windowMs,
        limit: maxRequests,
      };
    }

    if (existing.count >= maxRequests) {
      return {
        allowed: false,
        remaining: 0,
        resetAt: currentWindowStart + windowMs,
        limit: maxRequests,
      };
    }

    // Increment counter
    await client
      .from('rate_limits')
      .update({ count: existing.count + 1, updated_at: now })
      .eq('key', key);

    return {
      allowed: true,
      remaining: maxRequests - existing.count - 1,
      resetAt: currentWindowStart + windowMs,
      limit: maxRequests,
    };
  } catch (err) {
    // Any error — fall back to in-memory
    console.warn('DB rate limit error, falling back to in-memory:', err);
    return checkRateLimit(key, maxRequests, windowMs);
  }
}

/**
 * Generate rate limit headers for the response.
 */
export function getRateLimitHeaders(result: RateLimitResult): Record<string, string> {
  return {
    'X-RateLimit-Limit': result.limit.toString(),
    'X-RateLimit-Remaining': result.remaining.toString(),
    'X-RateLimit-Reset': Math.ceil(result.resetAt / 1000).toString(),
  };
}

/**
 * Clean up expired rate limit entries periodically.
 */
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (now >= entry.resetAt) {
      rateLimitStore.delete(key);
    }
  }
}, 60_000);
