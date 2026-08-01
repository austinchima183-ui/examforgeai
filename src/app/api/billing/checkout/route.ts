import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

// ============================================================================
// ExamForge AI — Flutterwave Checkout Edge Function Proxy
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const { data: { session } } = await supabase.auth.getSession()

    const response = await fetch(`${SUPABASE_URL}/functions/v1/flutterwave-checkout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token ?? ''}`,
      },
      body: JSON.stringify({ ...body, user_id: user.id }),
    })

    const data = await response.json()
    return NextResponse.json(data, { status: response.status })
  } catch (error) {
    console.error('Flutterwave checkout error:', error)
    return NextResponse.json({ error: 'Failed to initiate checkout' }, { status: 500 })
  }
}
