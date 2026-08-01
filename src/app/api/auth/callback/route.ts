import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { ROUTES } from '@/lib/constants/routes'

// ============================================================================
// ExamForge AI — Auth Callback Route Handler
// ============================================================================
// Handles Supabase auth callback (code exchange). Exchanges the code
// from the URL for a session, then redirects to /dashboard.
// ============================================================================

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? ROUTES.DASHBOARD
  const error = searchParams.get('error')
  const errorDescription = searchParams.get('error_description')

  // Handle OAuth error responses
  if (error) {
    console.error('[Auth Callback] OAuth error:', error, errorDescription)
    return NextResponse.redirect(
      `${origin}${ROUTES.LOGIN}?error=${encodeURIComponent(errorDescription ?? error)}`
    )
  }

  // Exchange code for session
  if (code) {
    try {
      const supabase = await createClient()
      const { error: exchangeError } = await supabase.auth.exchangeCodeForSession(code)

      if (exchangeError) {
        console.error('[Auth Callback] Code exchange error:', exchangeError.message)
        return NextResponse.redirect(
          `${origin}${ROUTES.LOGIN}?error=${encodeURIComponent('Authentication failed. Please try again.')}`
        )
      }

      // Successful code exchange — redirect to the intended destination
      return NextResponse.redirect(`${origin}${next}`)
    } catch (err) {
      console.error('[Auth Callback] Unexpected error:', err)
      return NextResponse.redirect(
        `${origin}${ROUTES.LOGIN}?error=${encodeURIComponent('An unexpected error occurred.')}`
      )
    }
  }

  // No code present — redirect to login
  return NextResponse.redirect(
    `${origin}${ROUTES.LOGIN}?error=${encodeURIComponent('Invalid authentication link.')}`
  )
}
