// ============================================================================
// ExamForge AI — Billing Data Service
// ============================================================================
// Server-side data fetching for billing, subscriptions, and payments.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface PlanInfo {
  id: string
  name: string
  tier: string
  price: number
  currency: string
  billingCycle: string
  features: string[]
  maxStudents: number | null
  maxAiQuestions: number | null
  maxStorageGb: number | null
  maxExams: number | null
}

export interface InvoiceItem {
  id: string
  date: string
  amount: number
  currency: string
  status: string
  description: string
}

export interface UsageInfo {
  studentsUsed: number
  studentsLimit: number
  aiQuestionsUsed: number
  aiQuestionsLimit: number
  examsUsed: number
  examsLimit: number
  storageUsedGb: number
  storageLimitGb: number
}

export interface BillingPageData {
  currentPlan: PlanInfo | null
  invoices: InvoiceItem[]
  usage: UsageInfo
  upcomingInvoice: {
    amount: number
    currency: string
    date: string
  } | null
  subscription: {
    id: string
    status: string
    currentPeriodStart: string
    currentPeriodEnd: string
    cancelAtPeriodEnd: boolean
  } | null
}

// ──────────────────────────────────────────────────────────────
// Billing Service
// ──────────────────────────────────────────────────────────────

export async function getBillingData(userId: string): Promise<BillingPageData> {
  const supabase = await createClient()

  // Get current subscription
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('id, status, current_period_start, current_period_end, cancel_at_period_end, plan_id')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  // Get plan details
  let currentPlan: PlanInfo | null = null
  if (subscription?.plan_id) {
    const { data: plan } = await supabase
      .from('plans')
      .select('*')
      .eq('id', subscription.plan_id)
      .single()

    if (plan) {
      currentPlan = {
        id: plan.id,
        name: plan.name ?? 'Free',
        tier: plan.tier ?? 'free',
        price: plan.price ?? 0,
        currency: plan.currency ?? 'NGN',
        billingCycle: plan.billing_cycle ?? 'monthly',
        features: plan.features ?? [],
        maxStudents: plan.max_students,
        maxAiQuestions: plan.max_ai_questions,
        maxStorageGb: plan.max_storage_gb,
        maxExams: plan.max_exams,
      }
    }
  }

  // If no plan, default to free
  if (!currentPlan) {
    currentPlan = {
      id: 'free',
      name: 'Free',
      tier: 'free',
      price: 0,
      currency: 'NGN',
      billingCycle: 'monthly',
      features: ['Basic exam creation', 'Up to 50 students', '5 exams per month'],
      maxStudents: 50,
      maxAiQuestions: 100,
      maxStorageGb: 1,
      maxExams: 5,
    }
  }

  // Get payment history
  const { data: payments } = await supabase
    .from('payments')
    .select('id, amount, currency, status, description, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(20)

  const invoices: InvoiceItem[] = (payments ?? []).map(p => ({
    id: p.id,
    date: p.created_at,
    amount: p.amount,
    currency: p.currency ?? 'NGN',
    status: p.status,
    description: p.description ?? 'ExamForge AI Subscription',
  }))

  // Calculate usage (based on school context or individual)
  const { data: profile } = await supabase
    .from('profiles')
    .select('school_id, role')
    .eq('id', userId)
    .single()

  const schoolId = (profile as { school_id: string | null } | null)?.school_id

  let studentsUsed = 0
  let aiQuestionsUsed = 0
  let examsUsed = 0
  let storageUsedGb = 0

  if (schoolId) {
    const [studentsResult, questionsResult, examsResult] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('school_id', schoolId).eq('role', 'student').eq('is_active', true),
      supabase.from('questions').select('id', { count: 'exact', head: true }).eq('school_id', schoolId).eq('ai_generated', true),
      supabase.from('exams').select('id', { count: 'exact', head: true }).eq('school_id', schoolId),
    ])
    studentsUsed = studentsResult.count ?? 0
    aiQuestionsUsed = questionsResult.count ?? 0
    examsUsed = examsResult.count ?? 0
  }

  const usage: UsageInfo = {
    studentsUsed,
    studentsLimit: currentPlan.maxStudents ?? 999,
    aiQuestionsUsed,
    aiQuestionsLimit: currentPlan.maxAiQuestions ?? 999,
    examsUsed,
    examsLimit: currentPlan.maxExams ?? 999,
    storageUsedGb,
    storageLimitGb: currentPlan.maxStorageGb ?? 10,
  }

  // Next billing date
  const upcomingInvoice = subscription?.current_period_end
    ? {
        amount: currentPlan.price,
        currency: currentPlan.currency,
        date: subscription.current_period_end,
      }
    : null

  return {
    currentPlan,
    invoices,
    usage,
    upcomingInvoice,
    subscription: subscription
      ? {
          id: subscription.id,
          status: subscription.status,
          currentPeriodStart: subscription.current_period_start ?? '',
          currentPeriodEnd: subscription.current_period_end ?? '',
          cancelAtPeriodEnd: subscription.cancel_at_period_end ?? false,
        }
      : null,
  }
}
