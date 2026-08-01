'use client'

import { Suspense, useState, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { useSupabase } from '@/lib/hooks/use-supabase'
import { ROUTES } from '@/lib/constants/routes'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Mail, Loader2, CheckCircle2, ArrowLeft } from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Verify Email Page
// ============================================================================
// Shows a message to check email for verification. Provides a resend
// verification button and a link back to login.
// ============================================================================

function VerifyEmailContent() {
  const router = useRouter()
  const supabase = useSupabase()
  const searchParams = useSearchParams()
  const email = searchParams.get('email') ?? ''
  const [resending, setResending] = useState(false)
  const [resendSuccess, setResendSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // If the user has already verified their email and clicks the link,
  // Supabase will redirect them via the auth callback. But if they
  // manually navigate here, we should check if they're already verified.
  useEffect(() => {
    const checkVerification = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user?.email_confirmed_at) {
        router.push(ROUTES.DASHBOARD)
      }
    }
    checkVerification()
  }, [supabase.auth, router])

  const handleResendVerification = async () => {
    if (!email) {
      setError('No email address found. Please sign up again.')
      return
    }

    setResending(true)
    setError(null)

    try {
      const { error: resendError } = await supabase.auth.resend({
        type: 'signup',
        email,
      })

      if (resendError) {
        setError(resendError.message)
        return
      }

      setResendSuccess(true)
    } catch {
      setError('An unexpected error occurred. Please try again.')
    } finally {
      setResending(false)
    }
  }

  return (
    <div className="space-y-6 text-center">
      <div className="flex justify-center">
        <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
          <Mail className="h-8 w-8 text-primary" />
        </div>
      </div>

      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">Verify your email</h1>
        <p className="text-sm text-muted-foreground">
          We&apos;ve sent a verification link to{' '}
          {email ? (
            <span className="font-medium text-foreground">{email}</span>
          ) : (
            'your email address'
          )}
          . Please check your inbox and click the link to activate your account.
        </p>
      </div>

      <div className="rounded-md bg-muted/50 p-4 text-sm text-muted-foreground space-y-2">
        <p>Didn&apos;t receive the email?</p>
        <ul className="text-left list-disc list-inside space-y-1">
          <li>Check your spam or junk folder</li>
          <li>Make sure you entered the correct email address</li>
          <li>Wait a few minutes and try again</li>
        </ul>
      </div>

      {resendSuccess ? (
        <div className="rounded-md bg-primary/10 px-3 py-2 text-sm text-primary flex items-center justify-center gap-2">
          <CheckCircle2 className="h-4 w-4" />
          Verification email sent! Check your inbox.
        </div>
      ) : (
        <Button
          variant="outline"
          className="w-full"
          onClick={handleResendVerification}
          disabled={resending || !email}
        >
          {resending ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              Resending...
            </>
          ) : (
            <>
              <Mail className="h-4 w-4" />
              Resend Verification Email
            </>
          )}
        </Button>
      )}

      {error && (
        <div className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </div>
      )}

      <div className="pt-2">
        <Link
          href={ROUTES.LOGIN}
          className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back to Sign In
        </Link>
      </div>
    </div>
  )
}

function VerifyEmailFallback() {
  return (
    <div className="space-y-6 text-center">
      <div className="flex justify-center">
        <Skeleton className="h-16 w-16 rounded-full" />
      </div>
      <div className="space-y-2">
        <Skeleton className="h-8 w-48 mx-auto" />
        <Skeleton className="h-4 w-64 mx-auto" />
      </div>
      <Skeleton className="h-24 w-full rounded-md" />
      <Skeleton className="h-10 w-full rounded-md" />
    </div>
  )
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={<VerifyEmailFallback />}>
      <VerifyEmailContent />
    </Suspense>
  )
}
