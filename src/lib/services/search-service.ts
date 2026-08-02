// ============================================================================
// ExamForge AI — Global Search Service
// ============================================================================
// Unified search across all entities in the ExamForge AI platform.
// ============================================================================

import { createClient } from '@/lib/supabase/server'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface SearchResult {
  id: string
  title: string
  subtitle: string
  type: string
  href: string
  icon: string
}

export interface SearchResults {
  results: SearchResult[]
  total: number
  query: string
}

// ──────────────────────────────────────────────────────────────
// Search Service
// ──────────────────────────────────────────────────────────────

export async function globalSearch(
  query: string,
  userId: string,
  schoolId: string | null,
  role: string
): Promise<SearchResults> {
  if (!query || query.trim().length < 2) {
    return { results: [], total: 0, query }
  }

  const supabase = await createClient()
  const searchTerm = `%${query.trim()}%`
  const results: SearchResult[] = []

  // Search schools
  if (role === 'super_admin' || role === 'school_admin') {
    const { data } = await supabase
      .from('schools')
      .select('id, name, location')
      .ilike('name', searchTerm)
      .limit(5)
    for (const item of data ?? []) {
      results.push({
        id: item.id,
        title: item.name,
        subtitle: item.location ?? 'School',
        type: 'school',
        href: `/schools`,
        icon: 'School',
      })
    }
  }

  // Search students
  const studentQuery = supabase
    .from('profiles')
    .select('id, full_name, email')
    .eq('role', 'student')
    .ilike('full_name', searchTerm)
    .limit(5)
  if (schoolId && role !== 'super_admin') {
    studentQuery.eq('school_id', schoolId)
  }
  const { data: students } = await studentQuery
  for (const item of students ?? []) {
    results.push({
      id: item.id,
      title: item.full_name ?? item.email,
      subtitle: item.email,
      type: 'student',
      href: '/students',
      icon: 'GraduationCap',
    })
  }

  // Search teachers
  const teacherQuery = supabase
    .from('profiles')
    .select('id, full_name, email')
    .eq('role', 'teacher')
    .ilike('full_name', searchTerm)
    .limit(5)
  if (schoolId && role !== 'super_admin') {
    teacherQuery.eq('school_id', schoolId)
  }
  const { data: teachers } = await teacherQuery
  for (const item of teachers ?? []) {
    results.push({
      id: item.id,
      title: item.full_name ?? item.email,
      subtitle: item.email,
      type: 'teacher',
      href: '/teachers',
      icon: 'BookOpen',
    })
  }

  // Search parents
  const parentQuery = supabase
    .from('profiles')
    .select('id, full_name, email')
    .eq('role', 'parent')
    .ilike('full_name', searchTerm)
    .limit(5)
  if (schoolId && role !== 'super_admin') {
    parentQuery.eq('school_id', schoolId)
  }
  const { data: parents } = await parentQuery
  for (const item of parents ?? []) {
    results.push({
      id: item.id,
      title: item.full_name ?? item.email,
      subtitle: item.email,
      type: 'parent',
      href: '/parents',
      icon: 'Users',
    })
  }

  // Search questions
  const questionQuery = supabase
    .from('questions')
    .select('id, question_text, question_type')
    .ilike('question_text', searchTerm)
    .limit(5)
  if (schoolId && role !== 'super_admin') {
    questionQuery.eq('school_id', schoolId)
  }
  const { data: questions } = await questionQuery
  for (const item of questions ?? []) {
    results.push({
      id: item.id,
      title: item.question_text?.slice(0, 80) ?? 'Question',
      subtitle: item.question_type ?? 'Question',
      type: 'question',
      href: '/question-bank',
      icon: 'HelpCircle',
    })
  }

  // Search exams
  const examQuery = supabase
    .from('exams')
    .select('id, title, subject')
    .ilike('title', searchTerm)
    .limit(5)
  if (schoolId && role !== 'super_admin') {
    examQuery.eq('school_id', schoolId)
  }
  const { data: exams } = await examQuery
  for (const item of exams ?? []) {
    results.push({
      id: item.id,
      title: item.title,
      subtitle: item.subject ?? 'Exam',
      type: 'exam',
      href: '/cbt',
      icon: 'FileText',
    })
  }

  // Search marketplace
  const { data: marketplaceItems } = await supabase
    .from('marketplace_products')
    .select('id, title, category')
    .eq('status', 'published')
    .ilike('title', searchTerm)
    .limit(5)
  for (const item of marketplaceItems ?? []) {
    results.push({
      id: item.id,
      title: item.title,
      subtitle: item.category ?? 'Marketplace',
      type: 'marketplace',
      href: '/marketplace',
      icon: 'Store',
    })
  }

  // Search notifications
  const { data: notifs } = await supabase
    .from('notifications')
    .select('id, title, type')
    .eq('user_id', userId)
    .ilike('title', searchTerm)
    .limit(5)
  for (const item of notifs ?? []) {
    results.push({
      id: item.id,
      title: item.title,
      subtitle: item.type ?? 'Notification',
      type: 'notification',
      href: '/notifications',
      icon: 'Bell',
    })
  }

  return {
    results: results.slice(0, 20),
    total: results.length,
    query,
  }
}
