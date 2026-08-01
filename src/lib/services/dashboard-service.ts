// ============================================================================
// ExamForge AI — Dashboard Data Service
// ============================================================================
// Server-side data fetching for role-specific dashboards.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'
import type { UserRole } from '@/lib/types'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface SuperAdminStats {
  schools: number
  users: number
  revenue: number
  exams: number
  activeSchools: number
  pendingPayments: number
}

export interface SchoolAdminStats {
  teachers: number
  students: number
  exams: number
  revenue: number
  activeClasses: number
  pendingSubmissions: number
}

export interface TeacherStats {
  classes: number
  students: number
  exams: number
  questions: number
  pendingGrading: number
  activeExams: number
}

export interface StudentStats {
  upcomingExams: number
  completed: number
  averageScore: number
  totalExams: number
  practiceSessions: number
}

export interface ActivityItem {
  id: string
  description: string
  timestamp: string
  type: string
}

// ──────────────────────────────────────────────────────────────
// Super Admin Dashboard
// ──────────────────────────────────────────────────────────────

export async function getSuperAdminStats(): Promise<SuperAdminStats> {
  const supabase = await createClient()

  const [schoolsResult, usersResult, examsResult, paymentsResult] = await Promise.all([
    supabase.from('schools').select('id, is_active', { count: 'exact', head: false }),
    supabase.from('profiles').select('id', { count: 'exact', head: true }),
    supabase.from('exams').select('id', { count: 'exact', head: true }),
    supabase.from('payments').select('amount').eq('status', 'successful'),
  ])

  const schools = schoolsResult.data ?? []
  const activeSchools = schools.filter(s => s.is_active).length
  const revenue = (paymentsResult.data ?? []).reduce((sum, p) => sum + p.amount, 0)

  const pendingPaymentsResult = await supabase
    .from('payments')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'pending')

  return {
    schools: schoolsResult.count ?? 0,
    users: usersResult.count ?? 0,
    revenue,
    exams: examsResult.count ?? 0,
    activeSchools,
    pendingPayments: pendingPaymentsResult.count ?? 0,
  }
}

export async function getSuperAdminActivities(): Promise<ActivityItem[]> {
  const supabase = await createClient()

  // Get recent school registrations
  const { data: recentSchools } = await supabase
    .from('schools')
    .select('id, name, created_at')
    .order('created_at', { ascending: false })
    .limit(3)

  // Get recent payments
  const { data: recentPayments } = await supabase
    .from('payments')
    .select('id, amount, currency, created_at, status')
    .eq('status', 'successful')
    .order('created_at', { ascending: false })
    .limit(3)

  // Get recent user registrations
  const { data: recentUsers } = await supabase
    .from('profiles')
    .select('id, full_name, role, created_at')
    .order('created_at', { ascending: false })
    .limit(3)

  const activities: ActivityItem[] = []

  for (const school of recentSchools ?? []) {
    activities.push({
      id: `school-${school.id}`,
      description: `New school registered: ${school.name}`,
      timestamp: school.created_at,
      type: 'school',
    })
  }

  for (const payment of recentPayments ?? []) {
    activities.push({
      id: `payment-${payment.id}`,
      description: `Payment received: ${payment.currency?.toUpperCase() ?? 'NGN'} ${payment.amount.toLocaleString()}`,
      timestamp: payment.created_at,
      type: 'revenue',
    })
  }

  for (const user of recentUsers ?? []) {
    activities.push({
      id: `user-${user.id}`,
      description: `New ${user.role} joined: ${user.full_name ?? 'Unknown'}`,
      timestamp: user.created_at,
      type: 'user',
    })
  }

  // Sort by timestamp descending
  activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())

  return activities.slice(0, 10)
}

// ──────────────────────────────────────────────────────────────
// School Admin Dashboard
// ──────────────────────────────────────────────────────────────

export async function getSchoolAdminStats(schoolId: string): Promise<SchoolAdminStats> {
  const supabase = await createClient()

  const [teachersResult, studentsResult, examsResult, paymentsResult] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', schoolId).eq('role', 'teacher').eq('is_active', true),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', schoolId).eq('role', 'student').eq('is_active', true),
    supabase.from('exams').select('id', { count: 'exact', head: true }).eq('school_id', schoolId),
    supabase.from('payments').select('amount').eq('school_id', schoolId).eq('status', 'successful'),
  ])

  const revenue = (paymentsResult.data ?? []).reduce((sum, p) => sum + p.amount, 0)

  const pendingSubmissionsResult = await supabase
    .from('exam_sessions')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'submitted')

  return {
    teachers: teachersResult.count ?? 0,
    students: studentsResult.count ?? 0,
    exams: examsResult.count ?? 0,
    revenue,
    activeClasses: 0,
    pendingSubmissions: pendingSubmissionsResult.count ?? 0,
  }
}

export async function getSchoolAdminActivities(schoolId: string): Promise<ActivityItem[]> {
  const supabase = await createClient()

  const { data: recentExams } = await supabase
    .from('exams')
    .select('id, title, status, created_at')
    .eq('school_id', schoolId)
    .order('created_at', { ascending: false })
    .limit(5)

  const { data: recentUsers } = await supabase
    .from('profiles')
    .select('id, full_name, role, created_at')
    .eq('school_id', schoolId)
    .order('created_at', { ascending: false })
    .limit(5)

  const activities: ActivityItem[] = []

  for (const exam of recentExams ?? []) {
    activities.push({
      id: `exam-${exam.id}`,
      description: `Exam "${exam.title}" status changed to ${exam.status}`,
      timestamp: exam.created_at,
      type: 'exam',
    })
  }

  for (const user of recentUsers ?? []) {
    activities.push({
      id: `user-${user.id}`,
      description: `New ${user.role} joined: ${user.full_name ?? 'Unknown'}`,
      timestamp: user.created_at,
      type: user.role === 'teacher' ? 'teacher' : 'student',
    })
  }

  activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())

  return activities.slice(0, 10)
}

// ──────────────────────────────────────────────────────────────
// Teacher Dashboard
// ──────────────────────────────────────────────────────────────

export async function getTeacherStats(userId: string): Promise<TeacherStats> {
  const supabase = await createClient()

  const [examsResult, questionsResult, sessionsResult] = await Promise.all([
    supabase.from('exams').select('id', { count: 'exact', head: true }).eq('created_by', userId),
    supabase.from('questions').select('id', { count: 'exact', head: true }).eq('created_by', userId),
    supabase.from('exam_sessions').select('id, exam_id').eq('status', 'submitted'),
  ])

  // Get unique student count from exam sessions for this teacher's exams
  const teacherExamIds = (await supabase.from('exams').select('id').eq('created_by', userId)).data?.map(e => e.id) ?? []
  const uniqueStudents = new Set<string>()

  for (const session of sessionsResult.data ?? []) {
    if (teacherExamIds.includes(session.exam_id)) {
      uniqueStudents.add(session.exam_id)
    }
  }

  const pendingGradingResult = await supabase
    .from('exam_sessions')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'submitted')

  const activeExamsResult = await supabase
    .from('exams')
    .select('id', { count: 'exact', head: true })
    .eq('created_by', userId)
    .eq('status', 'active')

  return {
    classes: 0,
    students: uniqueStudents.size,
    exams: examsResult.count ?? 0,
    questions: questionsResult.count ?? 0,
    pendingGrading: pendingGradingResult.count ?? 0,
    activeExams: activeExamsResult.count ?? 0,
  }
}

export async function getTeacherActivities(userId: string): Promise<ActivityItem[]> {
  const supabase = await createClient()

  const { data: recentExams } = await supabase
    .from('exams')
    .select('id, title, status, created_at')
    .eq('created_by', userId)
    .order('created_at', { ascending: false })
    .limit(5)

  const { data: recentQuestions } = await supabase
    .from('questions')
    .select('id, question_type, created_at, ai_generated')
    .eq('created_by', userId)
    .order('created_at', { ascending: false })
    .limit(3)

  const activities: ActivityItem[] = []

  for (const exam of recentExams ?? []) {
    activities.push({
      id: `exam-${exam.id}`,
      description: `Exam "${exam.title}" — ${exam.status}`,
      timestamp: exam.created_at,
      type: 'exam',
    })
  }

  for (const question of recentQuestions ?? []) {
    activities.push({
      id: `question-${question.id}`,
      description: `${question.ai_generated ? 'AI-generated' : 'Created'} ${question.question_type} question`,
      timestamp: question.created_at,
      type: 'question',
    })
  }

  activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())

  return activities.slice(0, 10)
}

// ──────────────────────────────────────────────────────────────
// Student Dashboard
// ──────────────────────────────────────────────────────────────

export async function getStudentStats(userId: string): Promise<StudentStats> {
  const supabase = await createClient()

  // Get completed sessions
  const { data: completedSessions } = await supabase
    .from('exam_sessions')
    .select('id, percentage, total_score, max_score')
    .eq('student_id', userId)
    .in('status', ['submitted', 'timed_out', 'graded'])

  const completed = completedSessions?.length ?? 0
  const scoresWithPercentage = completedSessions?.filter(s => s.percentage !== null) ?? []
  const averageScore = scoresWithPercentage.length > 0
    ? Math.round(scoresWithPercentage.reduce((sum, s) => sum + (s.percentage ?? 0), 0) / scoresWithPercentage.length)
    : 0

  // Get upcoming exams (exams that are published/active and not yet taken)
  const { data: takenExamIds } = await supabase
    .from('exam_sessions')
    .select('exam_id')
    .eq('student_id', userId)

  const takenIds = new Set(takenExamIds?.map(s => s.exam_id) ?? [])

  const { data: upcomingExams } = await supabase
    .from('exams')
    .select('id')
    .in('status', ['published', 'active'])

  const upcomingExamsCount = (upcomingExams ?? []).filter(e => !takenIds.has(e.id)).length

  return {
    upcomingExams: upcomingExamsCount,
    completed,
    averageScore,
    totalExams: completed,
    practiceSessions: 0,
  }
}

export async function getStudentActivities(userId: string): Promise<ActivityItem[]> {
  const supabase = await createClient()

  const { data: recentSessions } = await supabase
    .from('exam_sessions')
    .select('id, exam_id, status, percentage, created_at')
    .eq('student_id', userId)
    .order('created_at', { ascending: false })
    .limit(10)

  // Get exam titles
  const examIds = [...new Set(recentSessions?.map(s => s.exam_id) ?? [])]
  const { data: exams } = await supabase
    .from('exams')
    .select('id, title')
    .in('id', examIds)

  const examMap = new Map(exams?.map(e => [e.id, e.title]) ?? [])

  const activities: ActivityItem[] = (recentSessions ?? []).map(session => {
    const examTitle = examMap.get(session.exam_id) ?? 'Unknown Exam'
    let description = ''
    let type = 'exam'

    if (session.status === 'submitted' || session.status === 'graded') {
      description = `Completed "${examTitle}" — scored ${session.percentage ?? 0}%`
      type = 'result'
    } else if (session.status === 'in_progress') {
      description = `Started "${examTitle}"`
      type = 'exam'
    } else {
      description = `${session.status} — "${examTitle}"`
      type = 'exam'
    }

    return {
      id: `session-${session.id}`,
      description,
      timestamp: session.created_at,
      type,
    }
  })

  return activities.slice(0, 10)
}

// ──────────────────────────────────────────────────────────────
// Role-based Dashboard Router
// ──────────────────────────────────────────────────────────────

export async function getDashboardData(role: UserRole, userId: string, schoolId: string | null) {
  switch (role) {
    case 'super_admin':
      return {
        stats: await getSuperAdminStats(),
        activities: await getSuperAdminActivities(),
      }
    case 'school_admin':
      if (!schoolId) {
        return { stats: null, activities: [] }
      }
      return {
        stats: await getSchoolAdminStats(schoolId),
        activities: await getSchoolAdminActivities(schoolId),
      }
    case 'teacher':
      return {
        stats: await getTeacherStats(userId),
        activities: await getTeacherActivities(userId),
      }
    case 'student':
      return {
        stats: await getStudentStats(userId),
        activities: await getStudentActivities(userId),
      }
    default:
      return {
        stats: await getStudentStats(userId),
        activities: await getStudentActivities(userId),
      }
  }
}
