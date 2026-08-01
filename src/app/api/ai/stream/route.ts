import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

// ============================================================================
// ExamForge AI — AI Stream Edge Function Proxy
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

    const response = await fetch(`${SUPABASE_URL}/functions/v1/ai-stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token ?? ''}`,
      },
      body: JSON.stringify(body),
    })

    if (!response.body) {
      return NextResponse.json({ error: 'No stream available' }, { status: 500 })
    }

    return new NextResponse(response.body, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    })
  } catch (error) {
    console.error('AI Stream error:', error)
    return NextResponse.json({ error: 'Failed to stream AI request' }, { status: 500 })
  }
}
