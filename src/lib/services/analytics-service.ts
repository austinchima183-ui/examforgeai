// ============================================================================
// ExamForge AI — Analytics Data Service
// ============================================================================
// Server-side data fetching for analytics charts and metrics.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'
import type { UserRole } from '@/lib/types'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface AnalyticsStats {
  totalExams: number
  activeStudents: number
  avgPassRate: number
  avgScore: number
}

export interface TimeSeriesPoint {
  date: string
  label: string
  value: number
  value2?: number
}

export interface SubjectPerformance {
  subject: string
  score: number
  passRate: number
}

export interface WeeklyActivity {
  week: string
  exams: number
  participants: number
}

export interface SchoolRanking {
  id: string
  name: string
  avgScore: number
  totalStudents: number
  totalExams: number
  passRate: number
}

export interface AnalyticsOverview {
  stats: AnalyticsStats
  examTrend: TimeSeriesPoint[]
  subjectPerformance: SubjectPerformance[]
  weeklyActivity: WeeklyActivity[]
  schoolRankings: SchoolRanking[]
  quickInsights: {
    topSubject: string | null
    needsAttention: string | null
    mostActiveMonth: string | null
  }
}

// ──────────────────────────────────────────────────────────────
// Analytics Service
// ──────────────────────────────────────────────────────────────

export async function getAnalyticsData(
  role: UserRole,
  userId: string,
  schoolId: string | null,
  dateRange: '7d' | '30d' | '90d' | '1y' | 'all' = '30d'
): Promise<AnalyticsOverview> {
  const supabase = await createClient()

  // Calculate date range filter
  const now = new Date()
  let startDate: Date | null = null
  switch (dateRange) {
    case '7d':
      startDate = new Date(now.getTime() - 7 * 86400000)
      break
    case '30d':
      startDate = new Date(now.getTime() - 30 * 86400000)
      break
    case '90d':
      startDate = new Date(now.getTime() - 90 * 86400000)
      break
    case '1y':
      startDate = new Date(now.getTime() - 365 * 86400000)
      break
    case 'all':
      startDate = null
      break
  }

  const dateFilter = startDate ? startDate.toISOString() : null

  // ─── Stats ───────────────────────────────────────────────
  const [examsResult, studentsResult, sessionsResult] = await Promise.all([
    supabase.from('exams').select('id', { count: 'exact', head: true }),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'student').eq('is_active', true),
    supabase.from('exam_sessions').select('percentage, status').in('status', ['submitted', 'timed_out', 'graded']),
  ])

  const totalExams = examsResult.count ?? 0
  const activeStudents = studentsResult.count ?? 0

  const sessions = sessionsResult.data ?? []
  const passedSessions = sessions.filter(s => (s.percentage ?? 0) >= 50)
  const avgPassRate = sessions.length > 0 ? Math.round((passedSessions.length / sessions.length) * 100) : 0
  const avgScore = sessions.length > 0
    ? Math.round(sessions.reduce((sum, s) => sum + (s.percentage ?? 0), 0) / sessions.length)
    : 0

  const stats: AnalyticsStats = {
    totalExams,
    activeStudents,
    avgPassRate,
    avgScore,
  }

  // ─── Exam Trend (monthly) ────────────────────────────────
  const { data: examTrendData } = await supabase
    .from('exam_sessions')
    .select('created_at, percentage')
    .in('status', ['submitted', 'timed_out', 'graded'])
    .order('created_at', { ascending: true })
    .limit(500)

  const monthlyMap = new Map<string, { count: number; totalPct: number }>()
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  for (const session of examTrendData ?? []) {
    const d = new Date(session.created_at)
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
    const existing = monthlyMap.get(key) ?? { count: 0, totalPct: 0 }
    existing.count++
    existing.totalPct += session.percentage ?? 0
    monthlyMap.set(key, existing)
  }

  const examTrend: TimeSeriesPoint[] = Array.from(monthlyMap.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-7)
    .map(([key, val]) => {
      const [y, m] = key.split('-')
      return {
        date: key,
        label: `${monthNames[parseInt(m) - 1]} ${y}`,
        value: val.count,
        value2: val.count > 0 ? Math.round(val.totalPct / val.count) : 0,
      }
    })

  // ─── Subject Performance ─────────────────────────────────
  const { data: subjectExams } = await supabase
    .from('exams')
    .select('subject, exam_sessions(percentage)')
    .in('status', ['completed', 'active', 'published'])

  const subjectMap = new Map<string, { scores: number[]; total: number }>()
  for (const exam of subjectExams ?? []) {
    if (!exam.subject) continue
    const sessions = exam.exam_sessions as unknown as Array<{ percentage: number | null }> | null
    const existing = subjectMap.get(exam.subject) ?? { scores: [], total: 0 }
    for (const s of sessions ?? []) {
      if (s.percentage !== null) {
        existing.scores.push(s.percentage)
        existing.total += s.percentage
      }
    }
    subjectMap.set(exam.subject, existing)
  }

  const subjectPerformance: SubjectPerformance[] = Array.from(subjectMap.entries())
    .map(([subject, data]) => ({
      subject,
      score: data.scores.length > 0 ? Math.round(data.total / data.scores.length) : 0,
      passRate: data.scores.length > 0 ? Math.round((data.scores.filter(s => s >= 50).length / data.scores.length) * 100) : 0,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 6)

  // ─── Weekly Activity ─────────────────────────────────────
  const { data: weeklySessions } = await supabase
    .from('exam_sessions')
    .select('created_at')
    .in('status', ['submitted', 'timed_out', 'graded', 'in_progress'])
    .order('created_at', { ascending: false })
    .limit(200)

  const weekMap = new Map<string, number>()
  for (const session of weeklySessions ?? []) {
    const d = new Date(session.created_at)
    const weekStart = new Date(d)
    weekStart.setDate(d.getDate() - d.getDay())
    const key = weekStart.toISOString().split('T')[0]
    weekMap.set(key, (weekMap.get(key) ?? 0) + 1)
  }

  const weeklyActivity: WeeklyActivity[] = Array.from(weekMap.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-4)
    .map(([key, count]) => {
      const d = new Date(key)
      const end = new Date(d)
      end.setDate(d.getDate() + 6)
      return {
        week: `${d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${end.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`,
        exams: count,
        participants: Math.max(1, Math.round(count * 0.7)),
      }
    })

  // ─── School Rankings ─────────────────────────────────────
  const { data: schoolsData } = await supabase
    .from('schools')
    .select('id, name, is_active')
    .eq('is_active', true)
    .limit(10)

  const schoolRankings: SchoolRanking[] = []
  for (const school of schoolsData ?? []) {
    const [studentCount, examCount] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', school.id).eq('role', 'student').eq('is_active', true),
      supabase.from('exams').select('id', { count: 'exact', head: true }).eq('school_id', school.id),
    ])
    schoolRankings.push({
      id: school.id,
      name: school.name,
      avgScore: 0,
      totalStudents: studentCount.count ?? 0,
      totalExams: examCount.count ?? 0,
      passRate: 0,
    })
  }

  // ─── Quick Insights ──────────────────────────────────────
  const topSubject = subjectPerformance.length > 0 ? subjectPerformance[0].subject : null
  const needsAttention = subjectPerformance.length > 0 ? subjectPerformance[subjectPerformance.length - 1].subject : null
  const mostActiveMonth = examTrend.length > 0
    ? examTrend.reduce((max, p) => p.value > max.value ? p : max, examTrend[0]).label
    : null

  return {
    stats,
    examTrend,
    subjectPerformance,
    weeklyActivity,
    schoolRankings,
    quickInsights: {
      topSubject,
      needsAttention,
      mostActiveMonth,
    },
  }
}
