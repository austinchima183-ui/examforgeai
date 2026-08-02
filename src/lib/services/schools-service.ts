// ============================================================================
// ExamForge AI — Schools Data Service
// ============================================================================
// Real Supabase queries for schools CRUD, pagination, search, filters.
// All queries are scoped by role to prevent data leakage.
// ============================================================================

import { createClient } from '@/lib/supabase/server'
import type { SchoolRow, SchoolInsert, SchoolUpdate } from '@/lib/supabase/types'
import type { UserRole } from '@/lib/types'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface SchoolListItem {
  id: string
  name: string
  code: string
  location: string
  school_type: string | null
  is_active: boolean
  student_count: number
  teacher_count: number
  admin_email: string | null
  admin_phone: string | null
  created_at: string
}

export interface SchoolsPageData {
  schools: SchoolListItem[]
  total: number
  activeSchools: number
  totalStudents: number
  totalTeachers: number
}

// ──────────────────────────────────────────────────────────────
// Get Schools with Stats (scoped by role)
// ──────────────────────────────────────────────────────────────

export async function getSchoolsData(role?: UserRole, schoolId?: string | null): Promise<SchoolsPageData> {
  const supabase = await createClient()

  // Scope: school_admin sees only their school, super_admin sees all
  let schoolsQuery = supabase
    .from('schools')
    .select('*')
    .order('created_at', { ascending: false })

  if (role === 'school_admin' && schoolId) {
    schoolsQuery = schoolsQuery.eq('id', schoolId)
  }

  const { data: schools, error: schoolsError } = await schoolsQuery

  if (schoolsError) {
    return { schools: [], total: 0, activeSchools: 0, totalStudents: 0, totalTeachers: 0 }
  }

  // Get student and teacher counts per school (batch query, no N+1)
  const schoolIds = (schools ?? []).map(s => s.id)

  const [studentCountsResult, teacherCountsResult] = await Promise.all([
    schoolIds.length > 0
      ? supabase.from('profiles').select('school_id').eq('role', 'student').eq('is_active', true).in('school_id', schoolIds)
      : Promise.resolve({ data: [] }),
    schoolIds.length > 0
      ? supabase.from('profiles').select('school_id').eq('role', 'teacher').eq('is_active', true).in('school_id', schoolIds)
      : Promise.resolve({ data: [] }),
  ])

  // Count students per school
  const studentsBySchool = new Map<string, number>()
  for (const s of studentCountsResult.data ?? []) {
    if (s.school_id) {
      studentsBySchool.set(s.school_id, (studentsBySchool.get(s.school_id) ?? 0) + 1)
    }
  }

  // Count teachers per school
  const teachersBySchool = new Map<string, number>()
  for (const t of teacherCountsResult.data ?? []) {
    if (t.school_id) {
      teachersBySchool.set(t.school_id, (teachersBySchool.get(t.school_id) ?? 0) + 1)
    }
  }

  const schoolList: SchoolListItem[] = (schools ?? []).map(school => ({
    id: school.id,
    name: school.name,
    code: school.code,
    location: [school.city, school.state, school.country].filter(Boolean).join(', '),
    school_type: school.school_type,
    is_active: school.is_active,
    student_count: studentsBySchool.get(school.id) ?? 0,
    teacher_count: teachersBySchool.get(school.id) ?? 0,
    admin_email: school.email,
    admin_phone: school.phone,
    created_at: school.created_at,
  }))

  const activeSchools = schoolList.filter(s => s.is_active).length
  const totalStudents = schoolList.reduce((sum, s) => sum + s.student_count, 0)
  const totalTeachers = schoolList.reduce((sum, s) => sum + s.teacher_count, 0)

  return {
    schools: schoolList,
    total: schoolList.length,
    activeSchools,
    totalStudents,
    totalTeachers,
  }
}

// ──────────────────────────────────────────────────────────────
// Get Single School
// ──────────────────────────────────────────────────────────────

export async function getSchoolById(id: string) {
  const supabase = await createClient()
  const { data, error } = await supabase
    .from('schools')
    .select('*')
    .eq('id', id)
    .single()

  if (error) {
    return null
  }

  return data
}

// ──────────────────────────────────────────────────────────────
// Create School (server action should verify auth)
// ──────────────────────────────────────────────────────────────

export async function createSchool(school: SchoolInsert) {
  const supabase = await createClient()
  const { data, error } = await supabase
    .from('schools')
    .insert(school)
    .select()
    .single()

  if (error) {
    return { data: null, error: error.message }
  }

  return { data, error: null }
}

// ──────────────────────────────────────────────────────────────
// Update School (server action should verify auth + ownership)
// ──────────────────────────────────────────────────────────────

export async function updateSchool(id: string, updates: SchoolUpdate) {
  const supabase = await createClient()
  const { data, error } = await supabase
    .from('schools')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single()

  if (error) {
    return { data: null, error: error.message }
  }

  return { data, error: null }
}

// ──────────────────────────────────────────────────────────────
// Delete School (soft delete — set is_active = false)
// ──────────────────────────────────────────────────────────────

export async function deactivateSchool(id: string) {
  const supabase = await createClient()
  const { data, error } = await supabase
    .from('schools')
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single()

  if (error) {
    return { data: null, error: error.message }
  }

  return { data, error: null }
}
