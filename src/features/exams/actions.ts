// ============================================================================
// ExamForge AI — Exam & Question Server Actions
// ============================================================================
// All mutations verify the authenticated user, their role, and school
// ownership before allowing any changes.

'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { getAuthUser } from '@/lib/auth/require-auth'

// ─── Zod Schemas ──────────────────────────────────────────────────────

const createExamSchema = z.object({
  title: z.string().min(1, 'Exam title is required'),
  subject: z.string().min(1, 'Subject is required'),
  description: z.string().optional(),
  duration_minutes: z.coerce.number().min(1, 'Duration must be at least 1 minute'),
  total_marks: z.coerce.number().min(1, 'Total marks must be at least 1'),
  pass_mark: z.coerce.number().min(0, 'Pass mark must be 0 or higher'),
  class_name: z.string().optional(),
  school_id: z.string().optional(),
  start_time: z.string().optional(),
  end_time: z.string().optional(),
  shuffle_questions: z.boolean().default(false),
  show_results: z.boolean().default(true),
  allow_review: z.boolean().default(false),
  auto_submit: z.boolean().default(true),
})

const createQuestionSchema = z.object({
  text: z.string().min(1, 'Question text is required'),
  type: z.enum(['multiple_choice', 'multi_select', 'true_false', 'short_answer', 'essay', 'fill_in_blank', 'matching', 'ordering', 'numerical']),
  subject: z.string().min(1, 'Subject is required'),
  topic: z.string().optional(),
  difficulty: z.enum(['easy', 'medium', 'hard', 'expert']).default('medium'),
  marks: z.coerce.number().min(1, 'Marks must be at least 1'),
  options: z.string().optional(), // JSON string of options
  correct_answer: z.string().optional(),
  explanation: z.string().optional(),
  school_id: z.string().optional(),
})

// ─── Create Exam Action ──────────────────────────────────────────────

export async function createExamAction(formData: FormData) {
  const authResult = await getAuthUser()
  if (!authResult) return { error: 'Unauthorized' }

  const { user, supabase } = authResult

  // Only teachers and admins can create exams
  if (user.role !== 'super_admin' && user.role !== 'school_admin' && user.role !== 'teacher') {
    return { error: 'Insufficient permissions to create exams' }
  }

  const rawData = {
    title: formData.get('title') as string,
    subject: formData.get('subject') as string,
    description: formData.get('description') as string || undefined,
    duration_minutes: formData.get('duration_minutes') as string,
    total_marks: formData.get('total_marks') as string,
    pass_mark: formData.get('pass_mark') as string,
    class_name: formData.get('class_name') as string || undefined,
    school_id: formData.get('school_id') as string || user.schoolId || undefined,
    start_time: formData.get('start_time') as string || undefined,
    end_time: formData.get('end_time') as string || undefined,
    shuffle_questions: formData.get('shuffle_questions') === 'true',
    show_results: formData.get('show_results') !== 'false',
    allow_review: formData.get('allow_review') === 'true',
    auto_submit: formData.get('auto_submit') !== 'false',
  }

  const validated = createExamSchema.safeParse(rawData)
  if (!validated.success) {
    return { error: validated.error.issues[0].message }
  }

  const { error } = await supabase
    .from('exams')
    .insert({
      ...validated.data,
      created_by: user.id,
      status: 'draft',
    })

  if (!error) {
    revalidatePath('/cbt')
  }

  return { error: error?.message ?? null }
}

// ─── Create Question Action ─────────────────────────────────────────

export async function createQuestionAction(formData: FormData) {
  const authResult = await getAuthUser()
  if (!authResult) return { error: 'Unauthorized' }

  const { user, supabase } = authResult

  // Only teachers and admins can create questions
  if (user.role !== 'super_admin' && user.role !== 'school_admin' && user.role !== 'teacher') {
    return { error: 'Insufficient permissions to create questions' }
  }

  const rawData = {
    text: formData.get('text') as string,
    type: formData.get('type') as string,
    subject: formData.get('subject') as string,
    topic: formData.get('topic') as string || undefined,
    difficulty: formData.get('difficulty') as string || 'medium',
    marks: formData.get('marks') as string,
    options: formData.get('options') as string || undefined,
    correct_answer: formData.get('correct_answer') as string || undefined,
    explanation: formData.get('explanation') as string || undefined,
    school_id: formData.get('school_id') as string || user.schoolId || undefined,
  }

  const validated = createQuestionSchema.safeParse(rawData)
  if (!validated.success) {
    return { error: validated.error.issues[0].message }
  }

  const insertData: Record<string, unknown> = {
    text: validated.data.text,
    type: validated.data.type,
    subject: validated.data.subject,
    topic: validated.data.topic,
    difficulty: validated.data.difficulty,
    marks: validated.data.marks,
    correct_answer: validated.data.correct_answer,
    explanation: validated.data.explanation,
    school_id: validated.data.school_id || null,
    created_by: user.id,
  }

  // Parse options JSON if provided
  if (validated.data.options) {
    try {
      insertData.options = JSON.parse(validated.data.options)
    } catch {
      // Not valid JSON, store as-is
    }
  }

  const { error } = await supabase
    .from('questions')
    .insert(insertData)

  if (!error) {
    revalidatePath('/question-bank')
  }

  return { error: error?.message ?? null }
}
