import { createClient } from '@/lib/supabase/middleware'
import { NextResponse, type NextRequest } from 'next/server'
import type { UserRole } from '@/lib/types'

// ============================================================================
// ExamForge AI — Production Middleware
// ============================================================================
// Auth guard + RBAC enforcement. Runs on every request.
// 1. Refreshes the Supabase session (cookie-based)
// 2. Redirects unauthenticated users to /login
// 3. Enforces role-based access control on protected routes
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Public routes (no auth required)
// ──────────────────────────────────────────────────────────────

const PUBLIC_ROUTES = [
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
  '/api/auth/callback',
  '/api/billing/webhook',
]

// ──────────────────────────────────────────────────────────────
// Route-to-Role Access Map (same as require-auth.ts)
// ──────────────────────────────────────────────────────────────

const ROUTE_ROLE_MAP: Record<string, UserRole[]> = {
  '/dashboard/super-admin': ['super_admin'],
  '/dashboard/school-admin': ['school_admin', 'super_admin'],
  '/dashboard/teacher': ['teacher', 'school_admin', 'super_admin'],
  '/dashboard/student': ['student', 'parent'],
  '/schools': ['super_admin', 'school_admin'],
  '/billing': ['super_admin', 'school_admin'],
  '/analytics': ['super_admin', 'school_admin', 'teacher'],
  '/reports': ['super_admin', 'school_admin', 'teacher'],
  '/question-bank': ['teacher', 'school_admin', 'super_admin'],
  '/cbt': ['teacher', 'school_admin', 'super_admin', 'student'],
  '/marketplace': ['super_admin', 'school_admin', 'teacher', 'student'],
  '/results': ['super_admin', 'school_admin', 'teacher', 'student'],
  '/students': ['super_admin', 'school_admin', 'teacher'],
  '/teachers': ['super_admin', 'school_admin'],
  '/parents': ['super_admin', 'school_admin'],
  '/search': ['super_admin', 'school_admin', 'teacher', 'student'],
  '/settings': ['super_admin', 'school_admin', 'teacher', 'student'],
  '/profile': ['super_admin', 'school_admin', 'teacher', 'student', 'parent'],
  '/notifications': ['super_admin', 'school_admin', 'teacher', 'student', 'parent'],
}

// ──────────────────────────────────────────────────────────────
// Role Dashboard Map
// ──────────────────────────────────────────────────────────────

const ROLE_DASHBOARD_MAP: Record<string, string> = {
  student: '/dashboard/student',
  parent: '/dashboard/student',
  teacher: '/dashboard/teacher',
  school_admin: '/dashboard/school-admin',
  super_admin: '/dashboard/super-admin',
}

// ──────────────────────────────────────────────────────────────
// Helper: Find the most specific matching route
// ──────────────────────────────────────────────────────────────

function findMatchingRoute(pathname: string): string | null {
  const matchingRoutes = Object.keys(ROUTE_ROLE_MAP)
    .filter(route => pathname === route || pathname.startsWith(route + '/'))

  if (matchingRoutes.length === 0) return null

  // Return the longest (most specific) match
  return matchingRoutes.sort((a, b) => b.length - a.length)[0]
}

// ──────────────────────────────────────────────────────────────
// Middleware
// ──────────────────────────────────────────────────────────────

export async function middleware(request: NextRequest) {
  const { supabase, response } = await createClient(request)

  // ─── Step 1: Refresh session ──────────────────────────────
  const { data: { user } } = await supabase.auth.getUser()

  const pathname = request.nextUrl.pathname

  // ─── Step 2: Allow public routes ─────────────────────────
  const isPublicRoute = PUBLIC_ROUTES.some(
    route => pathname === route || pathname.startsWith(route + '/')
  )

  if (isPublicRoute) {
    // If authenticated and trying to access login/register, redirect to dashboard
    if (user && (pathname === '/login' || pathname === '/register')) {
      const role = (user.app_metadata?.role as string) ?? 'student'
      const dashboardPath = ROLE_DASHBOARD_MAP[role] ?? '/dashboard'
      const redirectUrl = request.nextUrl.clone()
      redirectUrl.pathname = dashboardPath
      return NextResponse.redirect(redirectUrl)
    }
    return response
  }

  // ─── Step 3: Allow static assets and API routes ───────────
  if (
    pathname.startsWith('/_next/') ||
    pathname.startsWith('/api/') ||
    pathname.includes('.') // static files
  ) {
    return response
  }

  // ─── Step 4: Auth guard ───────────────────────────────────
  if (!user) {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/login'
    redirectUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(redirectUrl)
  }

  // ─── Step 5: Get user role from app_metadata ─────────────
  const role = (user.app_metadata?.role as UserRole) ?? 'student'

  // ─── Step 6: RBAC guard ──────────────────────────────────
  const matchingRoute = findMatchingRoute(pathname)

  if (matchingRoute) {
    const allowedRoles = ROUTE_ROLE_MAP[matchingRoute]

    if (!allowedRoles.includes(role)) {
      // User doesn't have access to this route — redirect to their dashboard
      const dashboardPath = ROLE_DASHBOARD_MAP[role] ?? '/dashboard'
      const redirectUrl = request.nextUrl.clone()
      redirectUrl.pathname = dashboardPath
      return NextResponse.redirect(redirectUrl)
    }
  }

  // ─── Step 7: Redirect /dashboard to role-specific dashboard ─
  if (pathname === '/dashboard') {
    const dashboardPath = ROLE_DASHBOARD_MAP[role] ?? '/dashboard/student'
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = dashboardPath
    return NextResponse.redirect(redirectUrl)
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (images, etc.)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
