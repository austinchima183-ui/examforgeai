'use client'

import { createContext, useContext, useMemo, type ReactNode } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/lib/supabase/types'

// ============================================================================
// ExamForge AI — Supabase Context Provider
// ============================================================================
// Provides the Supabase browser client via React context so that all
// client components can access the same singleton instance without
// importing the createClient function directly.
//
// Usage:
//   Wrap your app with <SupabaseProvider> in the root layout.
//   Then use the `useSupabase` hook in any client component.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Context
// ──────────────────────────────────────────────────────────────

type SupabaseBrowserClient = SupabaseClient<Database>

const SupabaseContext = createContext<SupabaseBrowserClient | null>(null)

// ──────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────

interface SupabaseProviderProps {
  children: ReactNode
}

export function SupabaseProvider({ children }: SupabaseProviderProps) {
  // Create the singleton client once — the createClient function
  // from @/lib/supabase/client already handles singleton caching
  // via globalThis, so this is safe even with React StrictMode.
  const supabase = useMemo(() => createClient(), [])

  return (
    <SupabaseContext.Provider value={supabase}>
      {children}
    </SupabaseContext.Provider>
  )
}

// ──────────────────────────────────────────────────────────────
// Hook
// ──────────────────────────────────────────────────────────────

/**
 * Access the Supabase browser client from any client component.
 *
 * Must be used within a <SupabaseProvider>.
 *
 * @example
 * ```tsx
 * 'use client'
 * import { useSupabase } from '@/lib/hooks/use-supabase'
 *
 * function MyComponent() {
 *   const supabase = useSupabase()
 *   const { data } = await supabase.from('exams').select('*')
 * }
 * ```
 */
export function useSupabase(): SupabaseBrowserClient {
  const context = useContext(SupabaseContext)

  if (!context) {
    throw new Error(
      'useSupabase must be used within a <SupabaseProvider>. ' +
      'Make sure to wrap your app with <SupabaseProvider> in the root layout.'
    )
  }

  return context
}
