import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'
import { createHmac, timingSafeEqual } from 'crypto'

// ============================================================================
// ExamForge AI — Flutterwave Webhook Handler
// ============================================================================
// Verifies the Flutterwave HMAC-SHA256 signature before processing any
// webhook event. This is a public endpoint — authentication is via webhook
// signature verification only. No session/auth required.
// ============================================================================

const FLUTTERWAVE_SECRET_HASH = process.env.FLUTTERWAVE_WEBHOOK_SECRET ?? ''

/**
 * Constant-time string comparison to prevent timing attacks.
 */
function timingSafeCompare(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  const bufA = Buffer.from(a, 'utf8')
  const bufB = Buffer.from(b, 'utf8')
  return timingSafeEqual(bufA, bufB)
}

export async function POST(request: NextRequest) {
  // ─── Step 1: Verify webhook signature header exists ─────────
  const signature = request.headers.get('x-flutterwave-signature')

  if (!signature || !FLUTTERWAVE_SECRET_HASH) {
    return NextResponse.json(
      { error: 'Invalid webhook signature' },
      { status: 401 }
    )
  }

  // ─── Step 2: Verify HMAC-SHA256 signature against body ──────
  try {
    const body = await request.text()

    const expectedSignature = createHmac('sha256', FLUTTERWAVE_SECRET_HASH)
      .update(body)
      .digest('hex')

    if (!timingSafeCompare(signature, expectedSignature)) {
      return NextResponse.json(
        { error: 'Signature mismatch' },
        { status: 401 }
      )
    }

    // Parse the body
    const payload = JSON.parse(body)

    // ─── Step 3: Forward to Supabase Edge Function ─────────────
    // Forward the original verif-hash header so the Edge Function can
    // also verify the signature independently.
    const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
    const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? ''

    const response = await fetch(`${SUPABASE_URL}/functions/v1/flutterwave-webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'verif-hash': FLUTTERWAVE_SECRET_HASH,
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
