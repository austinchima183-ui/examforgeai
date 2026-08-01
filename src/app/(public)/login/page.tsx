'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useSupabase } from '@/lib/hooks/use-supabase'
import { useAuthStore } from '@/lib/stores/auth-store'
import { loginSchema, type LoginInput } from '@/lib/validators/auth'
import { ROUTES } from '@/lib/constants/routes'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Separator } from '@/components/ui/separator'
import { LogIn, Mail, Lock, Loader2 } from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Login Page
// ============================================================================
// Client component with email + password form using React Hook Form + Zod
// loginSchema. Submits via Supabase signInWithPassword, with loading state,
// error display, and links to forgot-password and register.
// ============================================================================

export default function LoginPage() {
  const router = useRouter()
  const supabase = useSupabase()
  const { initialize } = useAuthStore()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const form = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  })

  const onSubmit = async (values: LoginInput) => {
    setError(null)
    setLoading(true)

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: values.email,
        password: values.password,
      })

      if (authError) {
        const errorMessages: Record<string, string> = {
          'Invalid login credentials': 'Invalid email or password. Please try again.',
          'Email not confirmed': 'Please verify your email address before signing in.',
          'Too many requests': 'Too many login attempts. Please wait and try again.',
        }
        setError(errorMessages[authError.message] ?? authError.message)
        return
      }

      if (data.user) {
        const role = (data.user.app_metadata?.role as string) ?? 'student'
        initialize({
          id: data.user.id,
          email: data.user.email ?? '',
          fullName: data.user.user_metadata?.full_name ?? data.user.email?.split('@')[0] ?? 'User',
          role: role as 'student' | 'teacher' | 'school_admin' | 'super_admin',
          avatarUrl: data.user.user_metadata?.avatar_url ?? null,
          isEmailVerified: data.user.email_confirmed_at != null,
          createdAt: data.user.created_at,
          updatedAt: data.user.updated_at ?? data.user.created_at,
        })
        router.push(ROUTES.DASHBOARD)
      }
    } catch {
      setError('An unexpected error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <h1 className="text-2xl font-bold tracking-tight">Welcome back</h1>
        <p className="text-sm text-muted-foreground">
          Sign in to your account to continue
        </p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Email</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      type="email"
                      placeholder="you@example.com"
                      className="pl-9"
                      autoComplete="email"
                      disabled={loading}
                      {...field}
                    />
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <div className="flex items-center justify-between">
                  <FormLabel>Password</FormLabel>
                  <Link
                    href={ROUTES.FORGOT_PASSWORD}
                    className="text-xs text-muted-foreground hover:text-foreground transition-colors"
                  >
                    Forgot password?
                  </Link>
                </div>
                <FormControl>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      type="password"
                      placeholder="Enter your password"
                      className="pl-9"
                      autoComplete="current-password"
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
                Signing in...
              </>
            ) : (
              <>
                <LogIn className="h-4 w-4" />
                Sign In
              </>
            )}
          </Button>
        </form>
      </Form>

      <Separator />

      <p className="text-center text-sm text-muted-foreground">
        Don&apos;t have an account?{' '}
        <Link
          href={ROUTES.REGISTER}
          className="font-medium text-foreground hover:underline"
        >
          Create one
        </Link>
      </p>
    </div>
  )
}
