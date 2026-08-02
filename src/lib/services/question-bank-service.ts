// ============================================================================
// ExamForge AI — Question Bank Data Service
// ============================================================================
// Server-side data fetching for the question bank.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface QuestionListItem {
  id: string
  text: string
  subject: string | null
  topic: string | null
  type: string
  difficulty: string
  marks: number
  examUsageCount: number
  aiGenerated: boolean
  createdAt: string
}

export interface QuestionBankStats {
  totalQuestions: number
  aiGenerated: number
  subjectsCovered: number
  examUsage: number
}

export interface QuestionBankPageData {
  stats: QuestionBankStats
  questions: QuestionListItem[]
  subjects: string[]
  topics: string[]
}

// ──────────────────────────────────────────────────────────────
// Question Bank Service
// ──────────────────────────────────────────────────────────────

export async function getQuestionBankData(
  role: string,
  userId: string,
  schoolId: string | null
): Promise<QuestionBankPageData> {
  const supabase = await createClient()

  // Build query
  let query = supabase
    .from('questions')
    .select(`
      id,
      question_text,
      question_type,
      difficulty,
      marks,
      subject_id,
      topic_id,
      ai_generated,
      created_at,
      created_by,
      school_id
    `)
    .order('created_at', { ascending: false })

  // Scope by role
  if (role === 'school_admin' && schoolId) {
    query = query.eq('school_id', schoolId)
  } else if (role === 'teacher') {
    query = query.eq('created_by', userId)
  }

  const { data: questions, error } = await query.limit(200)

  if (error) {
    console.error('Error fetching questions:', error)
    return { stats: { totalQuestions: 0, aiGenerated: 0, subjectsCovered: 0, examUsage: 0 }, questions: [], subjects: [], topics: [] }
  }

  // Get subjects and topics
  const subjectIds = [...new Set((questions ?? []).map(q => q.subject_id).filter(Boolean))] as string[]
  const topicIds = [...new Set((questions ?? []).map(q => q.topic_id).filter(Boolean))] as string[]

  const [subjectsResult, topicsResult, examQuestionsResult] = await Promise.all([
    supabase.from('subjects').select('id, name').in('id', subjectIds.length > 0 ? subjectIds : ['__none__']),
    supabase.from('topics').select('id, name').in('id', topicIds.length > 0 ? topicIds : ['__none__']),
    supabase.from('exam_questions').select('question_id').in('question_id', (questions ?? []).map(q => q.id).length > 0 ? (questions ?? []).map(q => q.id) : ['__none__']),
  ])

  // Build lookup maps
  const subjectMap = new Map<string, string>()
  for (const s of subjectsResult.data ?? []) {
    subjectMap.set(s.id, s.name)
  }

  const topicMap = new Map<string, string>()
  for (const t of topicsResult.data ?? []) {
    topicMap.set(t.id, t.name)
  }

  // Build usage count map
  const usageMap = new Map<string, number>()
  for (const eq of examQuestionsResult.data ?? []) {
    usageMap.set(eq.question_id, (usageMap.get(eq.question_id) ?? 0) + 1)
  }

  // Map to list items
  const questionList: QuestionListItem[] = (questions ?? []).map(q => ({
    id: q.id,
    text: q.question_text ?? '',
    subject: q.subject_id ? (subjectMap.get(q.subject_id) ?? null) : null,
    topic: q.topic_id ? (topicMap.get(q.topic_id) ?? null) : null,
    type: q.question_type ?? 'multiple_choice',
    difficulty: q.difficulty ?? 'medium',
    marks: q.marks ?? 0,
    examUsageCount: usageMap.get(q.id) ?? 0,
    aiGenerated: q.ai_generated ?? false,
    createdAt: q.created_at,
  }))

  // Calculate stats
  const totalQuestions = questionList.length
  const aiGenerated = questionList.filter(q => q.aiGenerated).length
  const uniqueSubjects = new Set(questionList.map(q => q.subject).filter(Boolean))
  const subjectsCovered = uniqueSubjects.size
  const examUsage = questionList.filter(q => q.examUsageCount > 0).length

  return {
    stats: { totalQuestions, aiGenerated, subjectsCovered, examUsage },
    questions: questionList,
    subjects: Array.from(subjectMap.values()).sort(),
    topics: Array.from(topicMap.values()).sort(),
  }
}
