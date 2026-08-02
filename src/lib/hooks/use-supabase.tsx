'use client'

import { createContext, useContext, useMemo, type ReactNode } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { SupabaseClient } from '@supabase/supabase-js'

type SupabaseBrowserClient = SupabaseClient

const SupabaseContext = createContext<SupabaseBrowserClient | null>(null)

interface SupabaseProviderProps {
  children: ReactNode
}

export function SupabaseProvider({ children }: SupabaseProviderProps) {
  const supabase = useMemo(() => createClient(), [])

  return (
    <SupabaseContext.Provider value={supabase}>
      {children}
    </SupabaseContext.Provider>
  )
}

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
