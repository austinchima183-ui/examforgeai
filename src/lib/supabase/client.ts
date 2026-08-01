'use client'

import { createBrowserClient as createSupabaseBrowserClient } from '@supabase/ssr'
import type { Database } from './types'

// ============================================================================
// ExamForge AI — Browser Supabase Client (Singleton Pattern)
// ============================================================================
// Ensures only one Supabase client instance exists per browser session.
// This prevents React StrictMode from creating duplicate clients and
// avoids auth state listener conflicts.
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

/**
 * Global singleton reference for the Supabase browser client.
 * Stored on `globalThis` to persist across hot-module reloads in development.
 */
const globalForSupabase = globalThis as unknown as {
  supabaseBrowserClient: ReturnType<typeof createSupabaseBrowserClient<Database>> | undefined
}

/**
 * Create or return the singleton Supabase browser client.
 *
 * Uses `createBrowserClient` from `@supabase/ssr` which handles:
 * - Automatic cookie-based session persistence
 * - PKCE auth flow for OAuth
 * - Token refresh in the browser
 *
 * @example
 * ```ts
 * // In a client component:
 * 'use client'
 * import { createClient } from '@/lib/supabase/client'
 *
 * const supabase = createClient()
 * const { data: { user } } = await supabase.auth.getUser()
 * ```
 */
export function createClient() {
  // Return existing singleton if available
  if (globalForSupabase.supabaseBrowserClient) {
    return globalForSupabase.supabaseBrowserClient
  }

  // Validate required environment variables
  if (!SUPABASE_URL) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_URL environment variable. ' +
      'Please add it to your .env.local file.'
    )
  }

  if (!SUPABASE_ANON_KEY) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_ANON_KEY environment variable. ' +
      'Please add it to your .env.local file.'
    )
  }

  // Create new browser client with full type safety
  globalForSupabase.supabaseBrowserClient = createSupabaseBrowserClient<Database>(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
  )

  return globalForSupabase.supabaseBrowserClient
}
