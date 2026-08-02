// ============================================================================
// ExamForge AI — Reports Data Service
// ============================================================================
// Server-side data fetching for report generation.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface SchoolReport {
  schoolId: string
  schoolName: string
  totalStudents: number
  totalTeachers: number
  totalExams: number
  avgScore: number
  passRate: number
  revenue: number
}

export interface TeacherReport {
  teacherId: string
  teacherName: string
  examsCreated: number
  questionsCreated: number
  avgStudentScore: number
  totalStudents: number
}

export interface StudentReport {
  studentId: string
  studentName: string
  email: string
  examsCompleted: number
  avgScore: number
  highestScore: number
  passRate: number
}

export interface RevenueReport {
  period: string
  totalRevenue: number
  totalPayments: number
  successfulPayments: number
  failedPayments: number
  averagePayment: number
}

export interface ReportsData {
  schoolReports: SchoolReport[]
  teacherReports: TeacherReport[]
  studentReports: StudentReport[]
  revenueReport: RevenueReport
}

// ──────────────────────────────────────────────────────────────
// Reports Service
// ──────────────────────────────────────────────────────────────

export async function getReportsData(
  role: string,
  userId: string,
  schoolId: string | null,
  dateFrom?: string,
  dateTo?: string
): Promise<ReportsData> {
  const supabase = await createClient()

  // ─── School Reports ──────────────────────────────────────
  let schoolQuery = supabase.from('schools').select('id, name').eq('is_active', true)
  if (schoolId && role !== 'super_admin') {
    schoolQuery = schoolQuery.eq('id', schoolId)
  }
  const { data: schools } = await schoolQuery.limit(50)

  const schoolReports: SchoolReport[] = []
  for (const school of schools ?? []) {
    const [studentsResult, teachersResult, examsResult, sessionsResult, paymentsResult] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', school.id).eq('role', 'student').eq('is_active', true),
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', school.id).eq('role', 'teacher').eq('is_active', true),
      supabase.from('exams').select('id', { count: 'exact', head: true }).eq('school_id', school.id),
      supabase.from('exam_sessions').select('percentage').eq('status', 'submitted'),
      supabase.from('payments').select('amount').eq('school_id', school.id).eq('status', 'successful'),
    ])

    const sessions = sessionsResult.data ?? []
    const avgScore = sessions.length > 0
      ? Math.round(sessions.reduce((sum, s) => sum + (s.percentage ?? 0), 0) / sessions.length)
      : 0
    const passRate = sessions.length > 0
      ? Math.round(sessions.filter(s => (s.percentage ?? 0) >= 50).length / sessions.length * 100)
      : 0
    const revenue = (paymentsResult.data ?? []).reduce((sum, p) => sum + p.amount, 0)

    schoolReports.push({
      schoolId: school.id,
      schoolName: school.name,
      totalStudents: studentsResult.count ?? 0,
      totalTeachers: teachersResult.count ?? 0,
      totalExams: examsResult.count ?? 0,
      avgScore,
      passRate,
      revenue,
    })
  }

  // ─── Teacher Reports ─────────────────────────────────────
  let teacherQuery = supabase.from('profiles').select('id, full_name').eq('role', 'teacher').eq('is_active', true)
  if (schoolId && role !== 'super_admin') {
    teacherQuery = teacherQuery.eq('school_id', schoolId)
  }
  const { data: teachers } = await teacherQuery.limit(50)

  const teacherReports: TeacherReport[] = []
  for (const teacher of teachers ?? []) {
    const [examsResult, questionsResult] = await Promise.all([
      supabase.from('exams').select('id', { count: 'exact', head: true }).eq('created_by', teacher.id),
      supabase.from('questions').select('id', { count: 'exact', head: true }).eq('created_by', teacher.id),
    ])
    teacherReports.push({
      teacherId: teacher.id,
      teacherName: teacher.full_name ?? 'Unknown',
      examsCreated: examsResult.count ?? 0,
      questionsCreated: questionsResult.count ?? 0,
      avgStudentScore: 0,
      totalStudents: 0,
    })
  }

  // ─── Student Reports ─────────────────────────────────────
  let studentQuery = supabase.from('profiles').select('id, full_name, email').eq('role', 'student').eq('is_active', true)
  if (schoolId && role !== 'super_admin') {
    studentQuery = studentQuery.eq('school_id', schoolId)
  }
  const { data: students } = await studentQuery.limit(50)

  const studentReports: StudentReport[] = []
  for (const student of students ?? []) {
    const { data: sessions } = await supabase
      .from('exam_sessions')
      .select('percentage')
      .eq('student_id', student.id)
      .in('status', ['submitted', 'timed_out', 'graded'])

    const scores = (sessions ?? []).map(s => s.percentage ?? 0)
    const avgScore = scores.length > 0 ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0
    const highestScore = scores.length > 0 ? Math.max(...scores) : 0
    const passRate = scores.length > 0 ? Math.round(scores.filter(s => s >= 50).length / scores.length * 100) : 0

    studentReports.push({
      studentId: student.id,
      studentName: student.full_name ?? student.email?.split('@')[0] ?? 'Unknown',
      email: student.email ?? '',
      examsCompleted: scores.length,
      avgScore,
      highestScore,
      passRate,
    })
  }

  // ─── Revenue Report ──────────────────────────────────────
  let paymentQuery = supabase.from('payments').select('amount, status, created_at')
  if (schoolId && role !== 'super_admin') {
    paymentQuery = paymentQuery.eq('school_id', schoolId)
  }
  if (dateFrom) {
    paymentQuery = paymentQuery.gte('created_at', dateFrom)
  }
  if (dateTo) {
    paymentQuery = paymentQuery.lte('created_at', dateTo)
  }
  const { data: payments } = await paymentQuery

  const allPayments = payments ?? []
  const successfulPayments = allPayments.filter(p => p.status === 'successful')
  const totalRevenue = successfulPayments.reduce((sum, p) => sum + p.amount, 0)
  const averagePayment = successfulPayments.length > 0 ? Math.round(totalRevenue / successfulPayments.length) : 0

  const revenueReport: RevenueReport = {
    period: dateFrom && dateTo ? `${dateFrom} to ${dateTo}` : 'All time',
    totalRevenue,
    totalPayments: allPayments.length,
    successfulPayments: successfulPayments.length,
    failedPayments: allPayments.filter(p => p.status === 'failed').length,
    averagePayment,
  }

  return {
    schoolReports,
    teacherReports,
    studentReports,
    revenueReport,
  }
}
