// ============================================================================
// ExamForge AI — Root Middleware
// ============================================================================
// Handles authentication, onboarding, and role-based access control.
// Uses the Supabase SSR updateSession pattern for session refresh.
//
// Guard Chain (executed in order):
//   1. AuthGuard    — Ensures user has a valid session on protected routes
//   2. OnboardingGuard — Redirects un-onboarded users to /onboarding
//   3. RoleBasedGuard  — Enforces role-based access to specific routes
// ============================================================================

import { createClient } from '@/lib/supabase/middleware'
import { NextResponse, type NextRequest } from 'next/server'
import type { UserRole } from '@/lib/types'

// ──────────────────────────────────────────────────────────────
// Route Definitions
// ──────────────────────────────────────────────────────────────

const PUBLIC_ROUTES = [
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
  '/api/auth/callback',
]

const AUTH_ROUTES = [
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
]

const ONBOARDING_ROUTE = '/onboarding'
const DASHBOARD_ROUTE = '/dashboard'

// ──────────────────────────────────────────────────────────────
// Role-Based Route Prefixes
// ──────────────────────────────────────────────────────────────

const ROLE_ROUTE_PREFIXES: Record<string, UserRole[]> = {
  '/admin': ['super_admin'],
  '/school': ['school_admin', 'super_admin'],
  '/teacher': ['teacher', 'school_admin', 'super_admin'],
  '/student': ['student'],
}

// ──────────────────────────────────────────────────────────────
// Helper Functions
// ──────────────────────────────────────────────────────────────

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(
    (route) => pathname === route || pathname.startsWith(route + '/')
  )
}

function isAuthRoute(pathname: string): boolean {
  return AUTH_ROUTES.some(
    (route) => pathname === route || pathname.startsWith(route + '/')
  )
}

function isOnboardingRoute(pathname: string): boolean {
  return pathname === ONBOARDING_ROUTE || pathname.startsWith(ONBOARDING_ROUTE + '/')
}

function isApiRoute(pathname: string): boolean {
  return pathname.startsWith('/api/')
}

/**
 * Extract the user's role from the JWT app_metadata.
 * Supabase stores custom claims in app_metadata.role.
 */
function getUserRole(user: { app_metadata?: Record<string, unknown> } | null): UserRole | null {
  if (!user?.app_metadata) return null
  const role = user.app_metadata.role as UserRole | undefined
  if (role && ['student', 'teacher', 'school_admin', 'super_admin'].includes(role)) {
    return role
  }
  return null
}

/**
 * Check if a user's role has access to a given pathname.
 */
function hasRoleAccess(pathname: string, role: UserRole | null): boolean {
  // If no role is defined, allow access to non-restricted routes
  if (!role) return true

  for (const [prefix, allowedRoles] of Object.entries(ROLE_ROUTE_PREFIXES)) {
    if (pathname === prefix || pathname.startsWith(prefix + '/')) {
      return allowedRoles.includes(role)
    }
  }

  // Routes not in the prefix map are accessible to all authenticated users
  return true
}

// ──────────────────────────────────────────────────────────────
// Middleware
// ──────────────────────────────────────────────────────────────

export async function middleware(request: NextRequest) {
  const { supabase, response } = await createClient(request)

  // ─── Step 1: Refresh session & get user ───
  const { data: { user } } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // ─── Step 2: AuthGuard ───
  // If user is NOT authenticated and tries to access a protected route,
  // redirect to /login
  if (!user && !isPublicRoute(pathname) && !isApiRoute(pathname)) {
    const redirectUrl = new URL('/login', request.url)
    redirectUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(redirectUrl)
  }

  // If user IS authenticated and visits a public auth route (login, register, etc.),
  // redirect to /dashboard
  if (user && isAuthRoute(pathname)) {
    return NextResponse.redirect(new URL(DASHBOARD_ROUTE, request.url))
  }

  // ─── Step 3: OnboardingGuard ───
  // If user is authenticated but hasn't completed onboarding,
  // redirect to /onboarding (unless they're already there)
  if (user && !isOnboardingRoute(pathname) && !isPublicRoute(pathname)) {
    const onboardingComplete = user.app_metadata?.onboarding_complete as boolean | undefined

    if (onboardingComplete === false) {
      return NextResponse.redirect(new URL(ONBOARDING_ROUTE, request.url))
    }
  }

  // If user is on /onboarding but has already completed it, redirect to dashboard
  if (user && isOnboardingRoute(pathname)) {
    const onboardingComplete = user.app_metadata?.onboarding_complete as boolean | undefined

    if (onboardingComplete === true) {
      return NextResponse.redirect(new URL(DASHBOARD_ROUTE, request.url))
    }
  }

  // ─── Step 4: RoleBasedGuard ───
  // Check if the user's role allows access to the current route
  if (user && !isPublicRoute(pathname) && !isApiRoute(pathname) && !isOnboardingRoute(pathname)) {
    const role = getUserRole(user)

    if (!hasRoleAccess(pathname, role)) {
      // User doesn't have the required role — redirect to their dashboard
      return NextResponse.redirect(new URL(DASHBOARD_ROUTE, request.url))
    }
  }

  // ─── Step 5: Allow request through ───
  return response
}

// ──────────────────────────────────────────────────────────────
// Matcher Config
// ──────────────────────────────────────────────────────────────
// Excludes static files, images, and other non-page assets from
// running through the middleware.
// ──────────────────────────────────────────────────────────────

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (images, fonts, etc.)
     */
    '/((?!_next/static|_next/image|favicon\\.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|tiff|bmp|webm|mp4|woff|woff2|ttf|eot|otf)$).*)',
  ],
}
