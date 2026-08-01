'use client'

import { createBrowserClient as createSupabaseBrowserClient } from '@supabase/ssr'

// ============================================================================
// ExamForge AI — Browser Supabase Client (Singleton Pattern)
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

const globalForSupabase = globalThis as unknown as {
  supabaseBrowserClient: ReturnType<typeof createSupabaseBrowserClient> | undefined
}

export function createClient() {
  if (globalForSupabase.supabaseBrowserClient) {
    return globalForSupabase.supabaseBrowserClient
  }

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

  globalForSupabase.supabaseBrowserClient = createSupabaseBrowserClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
  )

  return globalForSupabase.supabaseBrowserClient
}
