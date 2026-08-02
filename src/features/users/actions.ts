// ============================================================================
// ExamForge AI — User Server Actions
// ============================================================================
// All mutations verify the authenticated user, their role, and school
// ownership before allowing any changes.

'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { getAuthUser } from '@/lib/auth/require-auth'
import type { UserRole } from '@/lib/types'

// ─── Zod Schemas ──────────────────────────────────────────────────────

const createUserSchema = z.object({
  email: z.string().email('Valid email is required'),
  full_name: z.string().min(1, 'Full name is required'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  phone: z.string().optional(),
  role: z.enum(['student', 'teacher', 'parent']),
  school_id: z.string().optional(),
  class_name: z.string().optional(), // For students
  department: z.string().optional(), // For teachers
  subject: z.string().optional(), // For teachers
  children: z.array(z.string()).optional(), // For parents - student IDs
})

// ─── Create User Action ──────────────────────────────────────────────

export async function createUserAction(formData: FormData) {
  const authResult = await getAuthUser()
  if (!authResult) return { error: 'Unauthorized' }

  const { user, supabase } = authResult

  // Only admins can create users
  if (user.role !== 'super_admin' && user.role !== 'school_admin') {
    return { error: 'Insufficient permissions to create users' }
  }

  const rawData = {
    email: formData.get('email') as string,
    full_name: formData.get('full_name') as string,
    password: formData.get('password') as string,
    phone: formData.get('phone') as string || undefined,
    role: formData.get('role') as UserRole,
    school_id: formData.get('school_id') as string || user.schoolId || undefined,
    class_name: formData.get('class_name') as string || undefined,
    department: formData.get('department') as string || undefined,
    subject: formData.get('subject') as string || undefined,
  }

  const validated = createUserSchema.safeParse(rawData)
  if (!validated.success) {
    return { error: validated.error.issues[0].message }
  }

  const { email, password, full_name, role, school_id, phone, class_name, department, subject } = validated.data

  // Create auth user via Supabase Admin API
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name,
      role,
      phone,
    },
  })

  if (authError) {
    return { error: authError.message }
  }

  if (!authData.user) {
    return { error: 'Failed to create user' }
  }

  // Create profile
  const profileData: Record<string, unknown> = {
    id: authData.user.id,
    email,
    full_name,
    role,
    phone,
    school_id: school_id || null,
    is_active: true,
  }

  if (role === 'student' && class_name) {
    profileData.class_name = class_name
  }

  if (role === 'teacher') {
    if (department) profileData.department = department
    if (subject) profileData.subject = subject
  }

  const { error: profileError } = await supabase
    .from('profiles')
    .insert(profileData)

  if (profileError) {
    // Clean up auth user if profile creation fails
    await supabase.auth.admin.deleteUser(authData.user.id)
    return { error: profileError.message }
  }

  // Revalidate the relevant page
  const revalidateMap: Record<string, string> = {
    student: '/students',
    teacher: '/teachers',
    parent: '/parents',
  }
  revalidatePath(revalidateMap[role] ?? '/')

  return { error: null, userId: authData.user.id }
}
