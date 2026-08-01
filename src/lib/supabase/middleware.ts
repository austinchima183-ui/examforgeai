import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import type { Database } from './types'

// ============================================================================
// ExamForge AI — Middleware Supabase Client
// ============================================================================
// Creates a Supabase client for use in Next.js middleware.
// Handles session refresh by reading cookies from the request and writing
// updated cookies back to the response.
//
// This module is the ONLY place where auth session refresh should happen
// in the middleware layer. All other middleware logic should use the
// returned `supabase` client for auth checks.
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

/**
 * Create a Supabase client scoped to the middleware context.
 *
 * Unlike the server client, this reads cookies from the `NextRequest`
 * and writes updated cookies to the `NextResponse`. This ensures
 * that session refresh (token rotation) happens transparently
 * before the request reaches your page/API route.
 *
 * @param request - The incoming Next.js request
 * @returns Object containing the typed Supabase client and the response
 *
 * @example
 * ```ts
 * // In middleware.ts:
 * import { createClient, updateSession } from '@/lib/supabase/middleware'
 *
 * export async function middleware(request: NextRequest) {
 *   const { supabase, response } = await createClient(request)
 *   const { data: { session } } = await supabase.auth.getSession()
 *
 *   // Protect routes
 *   if (!session && request.nextUrl.pathname.startsWith('/dashboard')) {
 *     return NextResponse.redirect(new URL('/login', request.url))
 *   }
 *
 *   return response
 * }
 * ```
 */
export async function createClient(request: NextRequest) {
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

  // Create an initial response that we'll mutate with updated cookies
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      /**
       * Read all cookies from the incoming request.
       * Supabase uses these to reconstruct the auth session.
       */
      getAll() {
        return request.cookies.getAll()
      },

      /**
       * Write updated cookies to the response.
       * This is where token refresh happens — Supabase will call
       * setAll when it needs to rotate the access/refresh tokens.
       */
      setAll(cookiesToSet) {
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value)
        }

        // Recreate the response with the updated request headers
        // so that downstream handlers see the refreshed cookies
        response = NextResponse.next({
          request: {
            headers: request.headers,
          },
        })

        // Write the cookies to the outgoing response
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options)
        }
      },
    },
  })

  return { supabase, response }
}

/**
 * Refresh the Supabase auth session and return the response with updated cookies.
 *
 * This is the recommended way to handle auth in middleware — it ensures
 * that the session is always fresh before the request reaches your
 * page or API route. Call this early in your middleware chain.
 *
 * @param request - The incoming Next.js request
 * @returns NextResponse with refreshed auth cookies
 *
 * @example
 * ```ts
 * // In middleware.ts:
 * import { updateSession } from '@/lib/supabase/middleware'
 *
 * export async function middleware(request: NextRequest) {
 *   // 1. Refresh the session (handles token rotation)
 *   const response = await updateSession(request)
 *
 *   // 2. Optionally check auth state for route protection
 *   // (You would need to create a separate client for this,
 *   //  or use the createClient function above)
 *
 *   return response
 * }
 *
 * export const config = {
 *   matcher: [
 *     '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
 *   ],
 * }
 * ```
 */
export async function updateSession(request: NextRequest) {
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

  // Create an initial response
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  // Create a Supabase client that reads/writes cookies via the request/response
  const supabase = createServerClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      getAll() {
        return request.cookies.getAll()
      },
      setAll(cookiesToSet) {
        // Update the request cookies so downstream handlers see the new session
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value)
        }

        // Recreate the response with updated request headers
        response = NextResponse.next({
          request: {
            headers: request.headers,
          },
        })

        // Set the cookies on the outgoing response
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options)
        }
      },
    },
  })

  // This call triggers the session refresh if needed.
  // Supabase will call setAll() internally if the tokens need rotation.
  await supabase.auth.getUser()

  return response
}
