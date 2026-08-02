import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'
import type { UserRole } from '@/lib/types'

// ============================================================================
// ExamForge AI — Process Refund Edge Function Proxy
// ============================================================================
// Only school_admin and super_admin can initiate refunds.
// The Edge Function also enforces this, but we enforce at the proxy
// layer as defense-in-depth.

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!

const REFUND_ALLOWED_ROLES: UserRole[] = ['school_admin', 'super_admin']

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // ─── Role check: only admins can initiate refunds ─────────────
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const role = (profile?.role as UserRole) ?? (user.app_metadata?.role as UserRole) ?? 'student'

  if (!REFUND_ALLOWED_ROLES.includes(role)) {
    return NextResponse.json(
      { error: 'Forbidden — only administrators can process refunds' },
      { status: 403 }
    )
  }

  try {
    const body = await request.json()
    const { data: { session } } = await supabase.auth.getSession()

    const response = await fetch(`${SUPABASE_URL}/functions/v1/process-refund`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token ?? ''}`,
      },
      body: JSON.stringify(body),
    })

    const data = await response.json()
    return NextResponse.json(data, { status: response.status })
  } catch (error) {
    console.error('Refund error:', error)
    return NextResponse.json({ error: 'Failed to process refund' }, { status: 500 })
  }
}
