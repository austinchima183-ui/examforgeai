'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useSupabase } from '@/lib/hooks/use-supabase'
import { updatePasswordSchema, type UpdatePasswordInput } from '@/lib/validators/auth'
import { ROUTES } from '@/lib/constants/routes'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
  FormDescription,
} from '@/components/ui/form'
import { Lock, Loader2, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Reset Password Page
// ============================================================================
// New password + confirm password form. Uses the hash fragment from the
// email link to establish the session, then calls Supabase updateUser.
// ============================================================================

export default function ResetPasswordPage() {
  const router = useRouter()
  const supabase = useSupabase()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  const form = useForm<UpdatePasswordInput>({
    resolver: zodResolver(updatePasswordSchema),
    defaultValues: {
      password: '',
      confirmPassword: '',
    },
  })

  // Supabase sends the access token in the URL hash fragment.
  // The @supabase/ssr client automatically handles this on page load.
  // We just need to verify the session is valid before allowing password reset.
  useEffect(() => {
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      // If no session from the hash, the user arrived here without a valid reset link
      if (!session) {
        setError('Invalid or expired password reset link. Please request a new one.')
      }
    }
    checkSession()
  }, [supabase.auth])

  const onSubmit = async (values: UpdatePasswordInput) => {
    setError(null)
    setLoading(true)

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: values.password,
      })

      if (updateError) {
        setError(updateError.message)
        return
      }

      setSuccess(true)

      // Redirect to login after a short delay
      setTimeout(() => {
        router.push(ROUTES.LOGIN)
      }, 3000)
    } catch {
      setError('An unexpected error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="space-y-6 text-center">
        <div className="flex justify-center">
          <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
            <CheckCircle2 className="h-8 w-8 text-primary" />
          </div>
        </div>

        <div className="space-y-2">
          <h1 className="text-2xl font-bold tracking-tight">Password updated!</h1>
          <p className="text-sm text-muted-foreground">
            Your password has been successfully changed. You&apos;ll be redirected to the sign in page shortly.
          </p>
        </div>

        <Link
          href={ROUTES.LOGIN}
          className="inline-flex items-center justify-center w-full rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
        >
          Sign in now
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <h1 className="text-2xl font-bold tracking-tight">Set new password</h1>
        <p className="text-sm text-muted-foreground">
          Enter your new password below to complete the reset process.
        </p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel>New Password</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      type="password"
                      placeholder="Enter new password"
                      className="pl-9"
                      autoComplete="new-password"
                      disabled={loading}
                      {...field}
                    />
                  </div>
                </FormControl>
                <FormDescription>
                  At least 8 characters with uppercase, lowercase, and a number
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="confirmPassword"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Confirm New Password</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      type="password"
                      placeholder="Confirm new password"
                      className="pl-9"
                      autoComplete="new-password"
                      disabled={loading}
                      {...field}
                    />
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          {error && (
            <div className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {error}
            </div>
          )}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Updating password...
              </>
            ) : (
              'Reset Password'
            )}
          </Button>
        </form>
      </Form>

      <div className="text-center">
        <Link
          href={ROUTES.LOGIN}
          className="text-sm text-muted-foreground hover:text-foreground transition-colors"
        >
          Back to Sign In
        </Link>
      </div>
    </div>
  )
}
