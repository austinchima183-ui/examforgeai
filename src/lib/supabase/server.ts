'use server'

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from './types'
import type { SupabaseClient } from '@supabase/supabase-js'

// ============================================================================
// ExamForge AI — Server-Side Supabase Client
// ============================================================================
// Creates a Supabase client for use in Server Components, Server Actions,
// and Route Handlers. Reads and writes cookies via Next.js `cookies()`.
//
// IMPORTANT: This function MUST be called within a request context.
// It relies on `next/headers` which is only available in server-side code.
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

/**
 * Create a typed Supabase client for server-side usage.
 *
 * Handles cookie-based auth by:
 * 1. Reading all cookies from the incoming request via `cookies()`
 * 2. Forwarding them to the Supabase client for session resolution
 * 3. Writing updated cookies back to the response when auth state changes
 *    (e.g., token refresh)
 *
 * @example
 * ```ts
 * // In a Server Component:
 * import { createClient } from '@/lib/supabase/server'
 *
 * export default async function DashboardPage() {
 *   const supabase = await createClient()
 *   const { data: { user } } = await supabase.auth.getUser()
 *   // ...
 * }
 * ```
 *
 * @example
 * ```ts
 * // In a Server Action:
 * 'use server'
 * import { createClient } from '@/lib/supabase/server'
 *
 * export async function updateProfile(formData: FormData) {
 *   const supabase = await createClient()
 *   const { data: { user } } = await supabase.auth.getUser()
 *   if (!user) throw new Error('Unauthorized')
 *   // ...
 * }
 * ```
 */
export async function createClient(): Promise<SupabaseClient<Database>> {
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

  const cookieStore = await cookies()

  return createServerClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      /**
       * Get all cookies and return them as a parsed object
       * for the Supabase client to resolve the auth session.
       */
      getAll() {
        return cookieStore.getAll()
      },

      /**
       * Set cookies when the Supabase client refreshes the session
       * or when auth state changes. This ensures the browser's
       * cookie jar stays in sync with the server.
       */
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options)
          }
        } catch (error) {
          /**
           * The `setAll` method is called when the Supabase client
           * needs to update cookies (e.g., during token refresh).
           * If this is called in a Server Component, `cookieStore.set()`
           * will throw because the response headers are already sent.
           *
           * This is expected behavior — the middleware will handle
           * cookie refresh on the next request cycle.
           */
          if (process.env.NODE_ENV === 'development') {
            console.warn(
              '[Supabase Server] Failed to set cookies — this is expected in Server Components. ' +
              'The middleware will handle session refresh on the next request.',
              error
            )
          }
        }
      },
    },
  })
}
