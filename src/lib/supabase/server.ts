'use server'

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

// ============================================================================
// ExamForge AI — Server-Side Supabase Client
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export async function createClient() {
  if (!SUPABASE_URL) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_URL environment variable.'
    )
  }

  if (!SUPABASE_ANON_KEY) {
    throw new Error(
      'Missing NEXT_PUBLIC_SUPABASE_ANON_KEY environment variable.'
    )
  }

  const cookieStore = await cookies()

  return createServerClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      getAll() {
        return cookieStore.getAll()
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options)
          }
        } catch (error) {
          if (process.env.NODE_ENV === 'development') {
            console.warn(
              '[Supabase Server] Failed to set cookies — this is expected in Server Components.',
              error
            )
          }
        }
      },
    },
  })
}
