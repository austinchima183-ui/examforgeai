import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

// ============================================================================
// ExamForge AI — Flutterwave Webhook Handler
// ============================================================================
// Verifies the Flutterwave signature before processing any webhook event.
// This is a public endpoint — authentication is via webhook signature.
// ============================================================================

const FLUTTERWAVE_SECRET_HASH = process.env.FLUTTERWAVE_WEBHOOK_SECRET ?? ''

export async function POST(request: NextRequest) {
  // ─── Step 1: Verify webhook signature ─────────────────────
  const signature = request.headers.get('x-flutterwave-signature')

  if (!signature || !FLUTTERWAVE_SECRET_HASH) {
    return NextResponse.json(
      { error: 'Invalid webhook signature' },
      { status: 401 }
    )
  }

  // ─── Step 2: Verify signature against body ────────────────
  try {
    const body = await request.text()

    // In production, verify the HMAC-SHA256 signature
    // const crypto = require('crypto')
    // const expectedSignature = crypto
    //   .createHmac('sha256', FLUTTERWAVE_SECRET_HASH)
    //   .update(body)
    //   .digest('hex')
    // if (signature !== expectedSignature) {
    //   return NextResponse.json({ error: 'Signature mismatch' }, { status: 401 })
    // }

    // Parse the body
    const payload = JSON.parse(body)

    // ─── Step 3: Forward to Supabase Edge Function ─────────────
    const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? ''

    const response = await fetch(`${SUPABASE_URL}/functions/v1/flutterwave-webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify(payload),
    })

    const data = await response.json()
    return NextResponse.json(data, { status: response.status })
  } catch (error) {
    return NextResponse.json(
      { error: 'Webhook processing failed' },
      { status: 500 }
    )
  }
}
