import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

// ============================================================================
// ExamForge AI — Flutterwave Webhook
// ============================================================================

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    const signature = request.headers.get('x-flutterwave-signature')
    if (!signature) {
      return NextResponse.json({ error: 'Missing signature' }, { status: 400 })
    }

    const response = await fetch(`${SUPABASE_URL}/functions/v1/flutterwave-webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-flutterwave-signature': signature,
      },
      body: JSON.stringify(body),
    })

    const data = await response.json()
    return NextResponse.json(data, { status: response.status })
  } catch (error) {
    console.error('Webhook error:', error)
    return NextResponse.json({ error: 'Webhook processing failed' }, { status: 500 })
  }
}
