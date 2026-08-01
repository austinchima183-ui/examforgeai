// ============================================================================
// ExamForge AI — Schools Data Service
// ============================================================================
// Real Supabase queries for schools CRUD, pagination, search, filters.
// ============================================================================

import { createClient } from '@/lib/supabase/server'
import type { SchoolRow, SchoolInsert, SchoolUpdate } from '@/lib/supabase/types'

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
// Get Schools with Stats
// ──────────────────────────────────────────────────────────────

export async function getSchoolsData(): Promise<SchoolsPageData> {
  const supabase = await createClient()

  // Get all schools
  const { data: schools, error: schoolsError } = await supabase
    .from('schools')
    .select('*')
    .order('created_at', { ascending: false })

  if (schoolsError) {
    console.error('Error fetching schools:', schoolsError)
    return { schools: [], total: 0, activeSchools: 0, totalStudents: 0, totalTeachers: 0 }
  }

  // Get student and teacher counts per school
  const { data: studentCounts } = await supabase
    .from('profiles')
    .select('school_id')
    .eq('role', 'student')
    .eq('is_active', true)

  const { data: teacherCounts } = await supabase
    .from('profiles')
    .select('school_id')
    .eq('role', 'teacher')
    .eq('is_active', true)

  // Count students per school
  const studentsBySchool = new Map<string, number>()
  for (const s of studentCounts ?? []) {
    if (s.school_id) {
      studentsBySchool.set(s.school_id, (studentsBySchool.get(s.school_id) ?? 0) + 1)
    }
  }

  // Count teachers per school
  const teachersBySchool = new Map<string, number>()
  for (const t of teacherCounts ?? []) {
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
    console.error('Error fetching school:', error)
    return null
  }

  return data
}

// ──────────────────────────────────────────────────────────────
// Create School
// ──────────────────────────────────────────────────────────────

export async function createSchool(school: SchoolInsert) {
  const supabase = await createClient()
  const { data, error } = await supabase
    .from('schools')
    .insert(school)
    .select()
    .single()

  if (error) {
    console.error('Error creating school:', error)
    return { data: null, error: error.message }
  }

  return { data, error: null }
}

// ──────────────────────────────────────────────────────────────
// Update School
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
    console.error('Error updating school:', error)
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
    console.error('Error deactivating school:', error)
    return { data: null, error: error.message }
  }

  return { data, error: null }
}
