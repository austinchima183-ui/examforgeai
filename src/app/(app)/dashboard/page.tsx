import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import type { UserRole } from '@/lib/types'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Dashboard Redirector
// ============================================================================
// Server Component. Reads the user role from the Supabase session
// and redirects to the role-specific dashboard.
// ============================================================================

const ROLE_DASHBOARD_MAP: Record<UserRole, string> = {
  student: '/dashboard/student',
  teacher: '/dashboard/teacher',
  school_admin: '/dashboard/school-admin',
  super_admin: '/dashboard/super-admin',
}

export default async function DashboardPage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  // If not authenticated, redirect to login
  if (!user) {
    redirect(ROUTES.LOGIN)
  }

  // Determine role from app_metadata or default to student
  const role = (user.app_metadata?.role as UserRole) ?? 'student'

  // Redirect to role-specific dashboard
  const targetPath = ROLE_DASHBOARD_MAP[role] ?? ROLE_DASHBOARD_MAP.student
  redirect(targetPath)
}
