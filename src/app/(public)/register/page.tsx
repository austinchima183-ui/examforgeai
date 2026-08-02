'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useSupabase } from '@/lib/hooks/use-supabase'
import { signupSchema, type SignupInput } from '@/lib/validators/auth'
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
import { Separator } from '@/components/ui/separator'
import { UserPlus, Mail, Lock, User, Loader2, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Register Page
// ============================================================================
// Client component with full name, email, password, confirm password form.
// Uses React Hook Form + Zod signupSchema. Role is forced to 'student'.
// Submits via Supabase signUp, shows success message to verify email.
// ============================================================================

export default function RegisterPage() {
  const router = useRouter()
  const supabase = useSupabase()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  const [registeredEmail, setRegisteredEmail] = useState('')

  const form = useForm<SignupInput>({
    resolver: zodResolver(signupSchema),
    defaultValues: {
      fullName: '',
      email: '',
      password: '',
      confirmPassword: '',
      role: 'student',
    },
  })

  const onSubmit = async (values: SignupInput) => {
    setError(null)
    setLoading(true)

    try {
      const { data, error: authError } = await supabase.auth.signUp({
        email: values.email,
        password: values.password,
        options: {
          data: {
            full_name: values.fullName,
            // Role is forced to 'student' — security constraint
            role: 'student',
          },
        },
      })

      if (authError) {
        const errorMessages: Record<string, string> = {
          'User already registered': 'An account with this email already exists. Please sign in instead.',
          'Password should be at least 6 characters': 'Password must be at least 8 characters.',
          'Signup is disabled': 'Registration is currently disabled. Please contact support.',
        }
        setError(errorMessages[authError.message] ?? authError.message)
        return
      }

      if (data.user) {
        setRegisteredEmail(values.email)
        setSuccess(true)
      }
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
          <h1 className="text-2xl font-bold tracking-tight">Check your email</h1>
          <p className="text-sm text-muted-foreground">
            We&apos;ve sent a verification link to{' '}
            <span className="font-medium text-foreground">{registeredEmail}</span>.
            Please check your inbox and click the link to verify your account.
          </p>
        </div>

        <div className="rounded-md bg-muted/50 p-4 text-sm text-muted-foreground">
          Didn&apos;t receive the email? Check your spam folder or{' '}
          <button
            onClick={() => setSuccess(false)}
            className="text-foreground hover:underline font-medium focus-visible:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
            aria-label="Try registering again"
          >
            try again
          </button>
          .
        </div>

        <Link
          href={ROUTES.LOGIN}
          className="inline-flex items-center justify-center w-full rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
        >
          Back to Sign In
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <h1 className="text-2xl font-bold tracking-tight">Create your account</h1>
        <p className="text-sm text-muted-foreground">
          Get started with ExamForge AI for free
        </p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4" aria-label="Create account form">
          <FormField
            control={form.control}
            name="fullName"
            render={({ field }) => (
              <FormItem className="relative">
                <FormLabel>Full Name</FormLabel>
                <FormControl>
                  <Input
                    placeholder="Enter your full name"
                    className="pl-9"
                    autoComplete="name"
                    aria-required="true"
                    disabled={loading}
                    {...field}
                  />
                </FormControl>
                <User className="absolute left-3 top-9 h-4 w-4 text-muted-foreground pointer-events-none" />
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem className="relative">
                <FormLabel>Email</FormLabel>
                <FormControl>
                  <Input
                    type="email"
                    placeholder="you@example.com"
                    className="pl-9"
                    autoComplete="email"
                    aria-required="true"
                    disabled={loading}
                    {...field}
                  />
                </FormControl>
                <Mail className="absolute left-3 top-9 h-4 w-4 text-muted-foreground pointer-events-none" />
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem className="relative">
                <FormLabel>Password</FormLabel>
                <FormControl>
                  <Input
                    type="password"
                    placeholder="Create a password"
                    className="pl-9"
                    autoComplete="new-password"
                    aria-required="true"
                    disabled={loading}
                    {...field}
                  />
                </FormControl>
                <Lock className="absolute left-3 top-9 h-4 w-4 text-muted-foreground pointer-events-none" />
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
              <FormItem className="relative">
                <FormLabel>Confirm Password</FormLabel>
                <FormControl>
                  <Input
                    type="password"
                    placeholder="Confirm your password"
                    className="pl-9"
                    autoComplete="new-password"
                    aria-required="true"
                    disabled={loading}
                    {...field}
                  />
                </FormControl>
                <Lock className="absolute left-3 top-9 h-4 w-4 text-muted-foreground pointer-events-none" />
                <FormMessage />
              </FormItem>
            )}
          />

          {error && (
            <div role="alert" aria-live="assertive" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {error}
            </div>
          )}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Creating account...
              </>
            ) : (
              <>
                <UserPlus className="h-4 w-4" />
                Create Account
              </>
            )}
          </Button>
        </form>
      </Form>

      <Separator />

      <p className="text-center text-sm text-muted-foreground">
        Already have an account?{' '}
        <Link
          href={ROUTES.LOGIN}
          className="font-medium text-foreground hover:underline focus-visible:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-sm"
        >
          Sign in
        </Link>
      </p>
    </div>
  )
}
