// ============================================================================
// ExamForge AI — Supabase Database Type Definitions
// ============================================================================
// Comprehensive TypeScript types mirroring the production PostgreSQL schema.
// Follows the Supabase generate-types structure: Database → Tables → Row/Insert/Update
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Enum Definitions
// ──────────────────────────────────────────────────────────────

export type UserRole = 'student' | 'teacher' | 'school_admin' | 'super_admin'

export type ExamStatus = 'draft' | 'published' | 'active' | 'completed' | 'archived' | 'cancelled'

export type QuestionType =
  | 'multiple_choice'
  | 'multi_select'
  | 'true_false'
  | 'short_answer'
  | 'essay'
  | 'fill_in_blank'
  | 'matching'
  | 'ordering'
  | 'numerical'

export type DifficultyLevel = 'easy' | 'medium' | 'hard' | 'expert'

export type SubscriptionStatus =
  | 'trial'
  | 'active'
  | 'past_due'
  | 'paused'
  | 'cancelled'
  | 'expired'
  | 'pending_activation'

export type PaymentStatus =
  | 'pending'
  | 'processing'
  | 'successful'
  | 'failed'
  | 'refunded'
  | 'partially_refunded'
  | 'disputed'
  | 'voided'

export type PaymentChannel = 'card' | 'bank_transfer' | 'ussd' | 'mobile_money' | 'qr_code' | 'credit' | 'coupon' | 'refund'

export type PlanTier = 'free' | 'starter' | 'professional' | 'enterprise'

export type BillingModel = 'teacher_saas' | 'school_saas' | 'enterprise_saas'

export type ConversationType = 'direct' | 'group' | 'department' | 'class' | 'school_wide'

export type MessageType = 'text' | 'image' | 'pdf' | 'document' | 'voice_note' | 'audio' | 'video' | 'system'

export type NotificationChannel = 'in_app' | 'push' | 'email' | 'sms'

export type NotificationType =
  | 'exam_reminder'
  | 'exam_result'
  | 'assignment'
  | 'announcement'
  | 'message'
  | 'subscription'
  | 'payment'
  | 'system'
  | 'ai_generation'
  | 'marketplace'
  | 'enrollment'

export type AiProvider = 'openai' | 'gemini' | 'claude' | 'deepseek' | 'grok' | 'local_llm'

export type GenerationStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'

export type ReviewStatus = 'pending' | 'approved' | 'rejected' | 'needs_revision'

export type MobilePlatform = 'android' | 'ios' | 'web'

export type ContentStatus = 'draft' | 'published' | 'archived' | 'flagged'

export type ExamBodyType = 'waec' | 'neco' | 'nabteb' | 'jamb_utme' | 'post_utme' | 'bece' | 'common_entrance' | 'jupeb' | 'ijmb' | 'custom'

export type ExamCategoryType = 'internal' | 'mock' | 'practice' | 'past_paper' | 'certification' | 'entrance'

export type MarketplaceProductStatus = 'draft' | 'published' | 'archived' | 'under_review' | 'rejected'

export type MarketplaceProductType = 'question_set' | 'exam_template' | 'lesson_plan' | 'worksheet' | 'study_guide' | 'curriculum_pack'

// ──────────────────────────────────────────────────────────────
// Table Row / Insert / Update Types
// ──────────────────────────────────────────────────────────────

// ─── Profiles ────────────────────────────────────────────────

export interface ProfileRow {
  id: string // UUID — references auth.users(id)
  email: string
  full_name: string | null
  avatar_url: string | null
  phone: string | null
  role: UserRole
  school_id: string | null // UUID — references schools(id)
  is_active: boolean
  onboarding_completed: boolean
  onboarding_step: string | null
  preferences: Record<string, unknown> | null
  metadata: Record<string, unknown> | null
  last_login_at: string | null // timestamptz
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface ProfileInsert {
  id: string
  email: string
  full_name?: string | null
  avatar_url?: string | null
  phone?: string | null
  role?: UserRole
  school_id?: string | null
  is_active?: boolean
  onboarding_completed?: boolean
  onboarding_step?: string | null
  preferences?: Record<string, unknown> | null
  metadata?: Record<string, unknown> | null
  last_login_at?: string | null
  created_at?: string
  updated_at?: string
}

export interface ProfileUpdate {
  id?: string
  email?: string
  full_name?: string | null
  avatar_url?: string | null
  phone?: string | null
  role?: UserRole
  school_id?: string | null
  is_active?: boolean
  onboarding_completed?: boolean
  onboarding_step?: string | null
  preferences?: Record<string, unknown> | null
  metadata?: Record<string, unknown> | null
  last_login_at?: string | null
  created_at?: string
  updated_at?: string
}

// ─── Schools ─────────────────────────────────────────────────

export interface SchoolRow {
  id: string // UUID
  name: string
  code: string
  address: string | null
  city: string | null
  state: string | null
  country: string
  logo_url: string | null
  website_url: string | null
  phone: string | null
  email: string | null
  motto: string | null
  principal_name: string | null
  primary_color: string | null
  secondary_color: string | null
  school_type: string | null
  educational_level: string | null
  is_active: boolean
  settings: Record<string, unknown> | null
  metadata: Record<string, unknown> | null
  created_by: string | null // UUID
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface SchoolInsert {
  id?: string
  name: string
  code: string
  address?: string | null
  city?: string | null
  state?: string | null
  country?: string
  logo_url?: string | null
  website_url?: string | null
  phone?: string | null
  email?: string | null
  motto?: string | null
  principal_name?: string | null
  primary_color?: string | null
  secondary_color?: string | null
  school_type?: string | null
  educational_level?: string | null
  is_active?: boolean
  settings?: Record<string, unknown> | null
  metadata?: Record<string, unknown> | null
  created_by?: string | null
  created_at?: string
  updated_at?: string
}

export interface SchoolUpdate {
  id?: string
  name?: string
  code?: string
  address?: string | null
  city?: string | null
  state?: string | null
  country?: string
  logo_url?: string | null
  website_url?: string | null
  phone?: string | null
  email?: string | null
  motto?: string | null
  principal_name?: string | null
  primary_color?: string | null
  secondary_color?: string | null
  school_type?: string | null
  educational_level?: string | null
  is_active?: boolean
  settings?: Record<string, unknown> | null
  metadata?: Record<string, unknown> | null
  created_by?: string | null
  created_at?: string
  updated_at?: string
}

// ─── Questions ───────────────────────────────────────────────

export interface QuestionRow {
  id: string // UUID
  school_id: string | null // UUID
  subject_id: string | null // UUID
  topic_id: string | null // UUID
  created_by: string // UUID
  question_type: QuestionType
  difficulty: DifficultyLevel
  content: string // JSON-encoded rich content
  options: unknown[] | null // JSONB — for MCQ, multi-select, etc.
  correct_answer: string | null // JSON-encoded correct answer
  explanation: string | null
  marks: number
  negative_marks: number
  time_seconds: number | null
  exam_body: ExamBodyType | null
  exam_category: ExamCategoryType | null
  year: number | null
  tags: string[] | null
  is_published: boolean
  is_premium: boolean
  ai_generated: boolean
  generation_id: string | null // UUID — references ai_generations(id)
  review_status: ReviewStatus | null
  reviewed_by: string | null // UUID
  reviewed_at: string | null // timestamptz
  metadata: Record<string, unknown> | null
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface QuestionInsert {
  id?: string
  school_id?: string | null
  subject_id?: string | null
  topic_id?: string | null
  created_by: string
  question_type: QuestionType
  difficulty?: DifficultyLevel
  content: string
  options?: unknown[] | null
  correct_answer?: string | null
  explanation?: string | null
  marks?: number
  negative_marks?: number
  time_seconds?: number | null
  exam_body?: ExamBodyType | null
  exam_category?: ExamCategoryType | null
  year?: number | null
  tags?: string[] | null
  is_published?: boolean
  is_premium?: boolean
  ai_generated?: boolean
  generation_id?: string | null
  review_status?: ReviewStatus | null
  reviewed_by?: string | null
  reviewed_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface QuestionUpdate {
  id?: string
  school_id?: string | null
  subject_id?: string | null
  topic_id?: string | null
  created_by?: string
  question_type?: QuestionType
  difficulty?: DifficultyLevel
  content?: string
  options?: unknown[] | null
  correct_answer?: string | null
  explanation?: string | null
  marks?: number
  negative_marks?: number
  time_seconds?: number | null
  exam_body?: ExamBodyType | null
  exam_category?: ExamCategoryType | null
  year?: number | null
  tags?: string[] | null
  is_published?: boolean
  is_premium?: boolean
  ai_generated?: boolean
  generation_id?: string | null
  review_status?: ReviewStatus | null
  reviewed_by?: string | null
  reviewed_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Exams ───────────────────────────────────────────────────

export interface ExamRow {
  id: string // UUID
  school_id: string | null // UUID
  created_by: string // UUID
  title: string
  description: string | null
  exam_type: ExamCategoryType
  exam_body: ExamBodyType | null
  subject_id: string | null // UUID
  duration_minutes: number
  total_marks: number
  pass_mark: number
  instructions: Record<string, unknown> | null // JSONB
  settings: Record<string, unknown> | null // JSONB
  status: ExamStatus
  question_count: number
  is_timed: boolean
  allows_negative_marking: boolean
  negative_mark_ratio: number
  is_premium: boolean
  shuffle_questions: boolean
  shuffle_options: boolean
  show_results_immediately: boolean
  published_at: string | null // timestamptz
  starts_at: string | null // timestamptz
  ends_at: string | null // timestamptz
  metadata: Record<string, unknown> | null
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface ExamInsert {
  id?: string
  school_id?: string | null
  created_by: string
  title: string
  description?: string | null
  exam_type?: ExamCategoryType
  exam_body?: ExamBodyType | null
  subject_id?: string | null
  duration_minutes?: number
  total_marks?: number
  pass_mark?: number
  instructions?: Record<string, unknown> | null
  settings?: Record<string, unknown> | null
  status?: ExamStatus
  question_count?: number
  is_timed?: boolean
  allows_negative_marking?: boolean
  negative_mark_ratio?: number
  is_premium?: boolean
  shuffle_questions?: boolean
  shuffle_options?: boolean
  show_results_immediately?: boolean
  published_at?: string | null
  starts_at?: string | null
  ends_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface ExamUpdate {
  id?: string
  school_id?: string | null
  created_by?: string
  title?: string
  description?: string | null
  exam_type?: ExamCategoryType
  exam_body?: ExamBodyType | null
  subject_id?: string | null
  duration_minutes?: number
  total_marks?: number
  pass_mark?: number
  instructions?: Record<string, unknown> | null
  settings?: Record<string, unknown> | null
  status?: ExamStatus
  question_count?: number
  is_timed?: boolean
  allows_negative_marking?: boolean
  negative_mark_ratio?: number
  is_premium?: boolean
  shuffle_questions?: boolean
  shuffle_options?: boolean
  show_results_immediately?: boolean
  published_at?: string | null
  starts_at?: string | null
  ends_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Exam Answers ────────────────────────────────────────────

export interface ExamAnswerRow {
  id: string // UUID
  session_id: string // UUID — references exam_sessions(id)
  question_id: string // UUID — references questions(id)
  student_id: string // UUID — references auth.users(id)
  answer: string | null // JSON-encoded answer data
  is_correct: boolean | null
  marks_awarded: number | null
  time_taken_seconds: number | null
  flagged: boolean
  metadata: Record<string, unknown> | null
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface ExamAnswerInsert {
  id?: string
  session_id: string
  question_id: string
  student_id: string
  answer?: string | null
  is_correct?: boolean | null
  marks_awarded?: number | null
  time_taken_seconds?: number | null
  flagged?: boolean
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface ExamAnswerUpdate {
  id?: string
  session_id?: string
  question_id?: string
  student_id?: string
  answer?: string | null
  is_correct?: boolean | null
  marks_awarded?: number | null
  time_taken_seconds?: number | null
  flagged?: boolean
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Exam Sessions ───────────────────────────────────────────

export interface ExamSessionRow {
  id: string // UUID
  exam_id: string // UUID — references exams(id)
  student_id: string // UUID — references auth.users(id)
  status: 'not_started' | 'in_progress' | 'submitted' | 'timed_out' | 'abandoned' | 'graded'
  started_at: string | null // timestamptz
  submitted_at: string | null // timestamptz
  time_remaining_seconds: number | null
  total_score: number | null
  max_score: number | null
  percentage: number | null
  grade: string | null
  answers_completed: number
  answers_total: number
  device_info: Record<string, unknown> | null // JSONB
  ip_address: string | null
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface ExamSessionInsert {
  id?: string
  exam_id: string
  student_id: string
  status?: 'not_started' | 'in_progress' | 'submitted' | 'timed_out' | 'abandoned' | 'graded'
  started_at?: string | null
  submitted_at?: string | null
  time_remaining_seconds?: number | null
  total_score?: number | null
  max_score?: number | null
  percentage?: number | null
  grade?: string | null
  answers_completed?: number
  answers_total?: number
  device_info?: Record<string, unknown> | null
  ip_address?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface ExamSessionUpdate {
  id?: string
  exam_id?: string
  student_id?: string
  status?: 'not_started' | 'in_progress' | 'submitted' | 'timed_out' | 'abandoned' | 'graded'
  started_at?: string | null
  submitted_at?: string | null
  time_remaining_seconds?: number | null
  total_score?: number | null
  max_score?: number | null
  percentage?: number | null
  grade?: string | null
  answers_completed?: number
  answers_total?: number
  device_info?: Record<string, unknown> | null
  ip_address?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Subscriptions ───────────────────────────────────────────

export interface SubscriptionRow {
  id: string // UUID
  subscriber_id: string // UUID — references auth.users(id) or schools(id)
  plan_id: string // UUID — references subscription_plans(id)
  billing_model: BillingModel
  status: SubscriptionStatus
  current_period_start: string // timestamptz
  current_period_end: string // timestamptz
  trial_start: string | null // timestamptz
  trial_end: string | null // timestamptz
  cancelled_at: string | null // timestamptz
  cancelled_reason: string | null
  seats_total: number
  seats_used: number
  ai_credits_total: number
  ai_credits_used: number
  ai_credits_reset_at: string | null // timestamptz
  auto_renew: boolean
  provider_subscription_id: string | null // Flutterwave subscription reference
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface SubscriptionInsert {
  id?: string
  subscriber_id: string
  plan_id: string
  billing_model: BillingModel
  status?: SubscriptionStatus
  current_period_start?: string
  current_period_end?: string
  trial_start?: string | null
  trial_end?: string | null
  cancelled_at?: string | null
  cancelled_reason?: string | null
  seats_total?: number
  seats_used?: number
  ai_credits_total?: number
  ai_credits_used?: number
  ai_credits_reset_at?: string | null
  auto_renew?: boolean
  provider_subscription_id?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface SubscriptionUpdate {
  id?: string
  subscriber_id?: string
  plan_id?: string
  billing_model?: BillingModel
  status?: SubscriptionStatus
  current_period_start?: string
  current_period_end?: string
  trial_start?: string | null
  trial_end?: string | null
  cancelled_at?: string | null
  cancelled_reason?: string | null
  seats_total?: number
  seats_used?: number
  ai_credits_total?: number
  ai_credits_used?: number
  ai_credits_reset_at?: string | null
  auto_renew?: boolean
  provider_subscription_id?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Payments ────────────────────────────────────────────────

export interface PaymentRow {
  id: string // UUID
  subscription_id: string | null // UUID — references subscriptions(id)
  user_id: string // UUID — references auth.users(id)
  school_id: string | null // UUID — references schools(id)
  amount: number
  currency: string
  status: PaymentStatus
  channel: PaymentChannel
  provider_tx_ref: string | null // Flutterwave transaction reference
  provider_tx_id: string | null // Flutterwave transaction ID
  provider_flw_ref: string | null // Flutterwave FLW reference
  description: string | null
  invoice_id: string | null // UUID — references invoices(id)
  billing_period_start: string | null // timestamptz
  billing_period_end: string | null // timestamptz
  paid_at: string | null // timestamptz
  refunded_at: string | null // timestamptz
  refund_amount: number | null
  refund_reason: string | null
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface PaymentInsert {
  id?: string
  subscription_id?: string | null
  user_id: string
  school_id?: string | null
  amount: number
  currency?: string
  status?: PaymentStatus
  channel?: PaymentChannel
  provider_tx_ref?: string | null
  provider_tx_id?: string | null
  provider_flw_ref?: string | null
  description?: string | null
  invoice_id?: string | null
  billing_period_start?: string | null
  billing_period_end?: string | null
  paid_at?: string | null
  refunded_at?: string | null
  refund_amount?: number | null
  refund_reason?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface PaymentUpdate {
  id?: string
  subscription_id?: string | null
  user_id?: string
  school_id?: string | null
  amount?: number
  currency?: string
  status?: PaymentStatus
  channel?: PaymentChannel
  provider_tx_ref?: string | null
  provider_tx_id?: string | null
  provider_flw_ref?: string | null
  description?: string | null
  invoice_id?: string | null
  billing_period_start?: string | null
  billing_period_end?: string | null
  paid_at?: string | null
  refunded_at?: string | null
  refund_amount?: number | null
  refund_reason?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Marketplace Products ────────────────────────────────────

export interface MarketplaceProductRow {
  id: string // UUID
  seller_id: string // UUID — references auth.users(id)
  school_id: string | null // UUID — references schools(id)
  name: string
  description: string | null
  product_type: MarketplaceProductType
  status: MarketplaceProductStatus
  price: number
  currency: string
  subject_id: string | null // UUID
  exam_body: ExamBodyType | null
  educational_level: string | null
  cover_image_url: string | null
  preview_urls: string[] | null
  file_url: string | null
  file_size_bytes: number | null
  download_count: number
  purchase_count: number
  average_rating: number
  review_count: number
  is_featured: boolean
  is_free: boolean
  tags: string[] | null
  metadata: Record<string, unknown> | null // JSONB
  published_at: string | null // timestamptz
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface MarketplaceProductInsert {
  id?: string
  seller_id: string
  school_id?: string | null
  name: string
  description?: string | null
  product_type: MarketplaceProductType
  status?: MarketplaceProductStatus
  price?: number
  currency?: string
  subject_id?: string | null
  exam_body?: ExamBodyType | null
  educational_level?: string | null
  cover_image_url?: string | null
  preview_urls?: string[] | null
  file_url?: string | null
  file_size_bytes?: number | null
  download_count?: number
  purchase_count?: number
  average_rating?: number
  review_count?: number
  is_featured?: boolean
  is_free?: boolean
  tags?: string[] | null
  metadata?: Record<string, unknown> | null
  published_at?: string | null
  created_at?: string
  updated_at?: string
}

export interface MarketplaceProductUpdate {
  id?: string
  seller_id?: string
  school_id?: string | null
  name?: string
  description?: string | null
  product_type?: MarketplaceProductType
  status?: MarketplaceProductStatus
  price?: number
  currency?: string
  subject_id?: string | null
  exam_body?: ExamBodyType | null
  educational_level?: string | null
  cover_image_url?: string | null
  preview_urls?: string[] | null
  file_url?: string | null
  file_size_bytes?: number | null
  download_count?: number
  purchase_count?: number
  average_rating?: number
  review_count?: number
  is_featured?: boolean
  is_free?: boolean
  tags?: string[] | null
  metadata?: Record<string, unknown> | null
  published_at?: string | null
  created_at?: string
  updated_at?: string
}

// ─── Conversations ───────────────────────────────────────────

export interface ConversationRow {
  id: string // UUID
  type: ConversationType
  school_id: string | null // UUID — references schools(id)
  title: string | null
  avatar_url: string | null
  created_by: string // UUID — references auth.users(id)
  last_message_at: string | null // timestamptz
  last_message_preview: string | null
  is_active: boolean
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface ConversationInsert {
  id?: string
  type: ConversationType
  school_id?: string | null
  title?: string | null
  avatar_url?: string | null
  created_by: string
  last_message_at?: string | null
  last_message_preview?: string | null
  is_active?: boolean
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface ConversationUpdate {
  id?: string
  type?: ConversationType
  school_id?: string | null
  title?: string | null
  avatar_url?: string | null
  created_by?: string
  last_message_at?: string | null
  last_message_preview?: string | null
  is_active?: boolean
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Messages ────────────────────────────────────────────────

export interface MessageRow {
  id: string // UUID
  conversation_id: string // UUID — references conversations(id)
  sender_id: string // UUID — references auth.users(id)
  content: string
  message_type: MessageType
  attachment_url: string | null
  attachment_name: string | null
  attachment_size_bytes: number | null
  is_edited: boolean
  is_deleted: boolean
  edited_at: string | null // timestamptz
  deleted_at: string | null // timestamptz
  reply_to_id: string | null // UUID — self-reference
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface MessageInsert {
  id?: string
  conversation_id: string
  sender_id: string
  content: string
  message_type?: MessageType
  attachment_url?: string | null
  attachment_name?: string | null
  attachment_size_bytes?: number | null
  is_edited?: boolean
  is_deleted?: boolean
  edited_at?: string | null
  deleted_at?: string | null
  reply_to_id?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface MessageUpdate {
  id?: string
  conversation_id?: string
  sender_id?: string
  content?: string
  message_type?: MessageType
  attachment_url?: string | null
  attachment_name?: string | null
  attachment_size_bytes?: number | null
  is_edited?: boolean
  is_deleted?: boolean
  edited_at?: string | null
  deleted_at?: string | null
  reply_to_id?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Notifications ───────────────────────────────────────────

export interface NotificationRow {
  id: string // UUID
  user_id: string // UUID — references auth.users(id)
  type: NotificationType
  channel: NotificationChannel
  title: string
  body: string
  data: Record<string, unknown> | null // JSONB
  reference_id: string | null // UUID — polymorphic reference
  reference_type: string | null
  is_read: boolean
  read_at: string | null // timestamptz
  action_url: string | null
  icon: string | null
  priority: string | null
  expires_at: string | null // timestamptz
  sent_at: string | null // timestamptz
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface NotificationInsert {
  id?: string
  user_id: string
  type: NotificationType
  channel?: NotificationChannel
  title: string
  body: string
  data?: Record<string, unknown> | null
  reference_id?: string | null
  reference_type?: string | null
  is_read?: boolean
  read_at?: string | null
  action_url?: string | null
  icon?: string | null
  priority?: string | null
  expires_at?: string | null
  sent_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface NotificationUpdate {
  id?: string
  user_id?: string
  type?: NotificationType
  channel?: NotificationChannel
  title?: string
  body?: string
  data?: Record<string, unknown> | null
  reference_id?: string | null
  reference_type?: string | null
  is_read?: boolean
  read_at?: string | null
  action_url?: string | null
  icon?: string | null
  priority?: string | null
  expires_at?: string | null
  sent_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── AI Generations ──────────────────────────────────────────

export interface AiGenerationRow {
  id: string // UUID
  user_id: string // UUID — references auth.users(id)
  school_id: string | null // UUID — references schools(id)
  provider: AiProvider
  model: string
  status: GenerationStatus
  prompt_template_id: string | null // UUID
  input_params: Record<string, unknown> | null // JSONB
  prompt_text: string | null
  system_prompt: string | null
  output: Record<string, unknown> | null // JSONB
  raw_response: string | null
  questions_generated: number
  questions_accepted: number
  questions_rejected: number
  tokens_input: number | null
  tokens_output: number | null
  cost_usd: number | null
  duration_ms: number | null
  error_message: string | null
  error_code: string | null
  review_status: ReviewStatus | null
  reviewed_by: string | null // UUID
  reviewed_at: string | null // timestamptz
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface AiGenerationInsert {
  id?: string
  user_id: string
  school_id?: string | null
  provider: AiProvider
  model: string
  status?: GenerationStatus
  prompt_template_id?: string | null
  input_params?: Record<string, unknown> | null
  prompt_text?: string | null
  system_prompt?: string | null
  output?: Record<string, unknown> | null
  raw_response?: string | null
  questions_generated?: number
  questions_accepted?: number
  questions_rejected?: number
  tokens_input?: number | null
  tokens_output?: number | null
  cost_usd?: number | null
  duration_ms?: number | null
  error_message?: string | null
  error_code?: string | null
  review_status?: ReviewStatus | null
  reviewed_by?: string | null
  reviewed_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface AiGenerationUpdate {
  id?: string
  user_id?: string
  school_id?: string | null
  provider?: AiProvider
  model?: string
  status?: GenerationStatus
  prompt_template_id?: string | null
  input_params?: Record<string, unknown> | null
  prompt_text?: string | null
  system_prompt?: string | null
  output?: Record<string, unknown> | null
  raw_response?: string | null
  questions_generated?: number
  questions_accepted?: number
  questions_rejected?: number
  tokens_input?: number | null
  tokens_output?: number | null
  cost_usd?: number | null
  duration_ms?: number | null
  error_message?: string | null
  error_code?: string | null
  review_status?: ReviewStatus | null
  reviewed_by?: string | null
  reviewed_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ─── Device Tokens ───────────────────────────────────────────

export interface DeviceTokenRow {
  id: string // UUID
  user_id: string // UUID — references auth.users(id)
  token: string
  platform: MobilePlatform
  device_name: string | null
  device_model: string | null
  os_version: string | null
  app_version: string | null
  is_active: boolean
  last_used_at: string | null // timestamptz
  unregistered_at: string | null // timestamptz
  metadata: Record<string, unknown> | null // JSONB
  created_at: string // timestamptz
  updated_at: string // timestamptz
}

export interface DeviceTokenInsert {
  id?: string
  user_id: string
  token: string
  platform: MobilePlatform
  device_name?: string | null
  device_model?: string | null
  os_version?: string | null
  app_version?: string | null
  is_active?: boolean
  last_used_at?: string | null
  unregistered_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

export interface DeviceTokenUpdate {
  id?: string
  user_id?: string
  token?: string
  platform?: MobilePlatform
  device_name?: string | null
  device_model?: string | null
  os_version?: string | null
  app_version?: string | null
  is_active?: boolean
  last_used_at?: string | null
  unregistered_at?: string | null
  metadata?: Record<string, unknown> | null
  created_at?: string
  updated_at?: string
}

// ──────────────────────────────────────────────────────────────
// Database Schema — Supabase Type Structure
// ──────────────────────────────────────────────────────────────

export interface Tables {
  profiles: {
    Row: ProfileRow
    Insert: ProfileInsert
    Update: ProfileUpdate
  }
  schools: {
    Row: SchoolRow
    Insert: SchoolInsert
    Update: SchoolUpdate
  }
  questions: {
    Row: QuestionRow
    Insert: QuestionInsert
    Update: QuestionUpdate
  }
  exams: {
    Row: ExamRow
    Insert: ExamInsert
    Update: ExamUpdate
  }
  exam_answers: {
    Row: ExamAnswerRow
    Insert: ExamAnswerInsert
    Update: ExamAnswerUpdate
  }
  exam_sessions: {
    Row: ExamSessionRow
    Insert: ExamSessionInsert
    Update: ExamSessionUpdate
  }
  subscriptions: {
    Row: SubscriptionRow
    Insert: SubscriptionInsert
    Update: SubscriptionUpdate
  }
  payments: {
    Row: PaymentRow
    Insert: PaymentInsert
    Update: PaymentUpdate
  }
  marketplace_products: {
    Row: MarketplaceProductRow
    Insert: MarketplaceProductInsert
    Update: MarketplaceProductUpdate
  }
  conversations: {
    Row: ConversationRow
    Insert: ConversationInsert
    Update: ConversationUpdate
  }
  messages: {
    Row: MessageRow
    Insert: MessageInsert
    Update: MessageUpdate
  }
  notifications: {
    Row: NotificationRow
    Insert: NotificationInsert
    Update: NotificationUpdate
  }
  ai_generations: {
    Row: AiGenerationRow
    Insert: AiGenerationInsert
    Update: AiGenerationUpdate
  }
  device_tokens: {
    Row: DeviceTokenRow
    Insert: DeviceTokenInsert
    Update: DeviceTokenUpdate
  }
}

export interface Database {
  public: {
    Tables: Tables
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: {
      user_role: UserRole
      exam_status: ExamStatus
      question_type: QuestionType
      difficulty_level: DifficultyLevel
      subscription_status: SubscriptionStatus
      payment_status: PaymentStatus
      payment_channel: PaymentChannel
      plan_tier: PlanTier
      billing_model: BillingModel
      conversation_type: ConversationType
      message_type: MessageType
      notification_channel: NotificationChannel
      notification_type: NotificationType
      ai_provider: AiProvider
      generation_status: GenerationStatus
      review_status: ReviewStatus
      mobile_platform: MobilePlatform
      content_status: ContentStatus
      exam_body_type: ExamBodyType
      exam_category_type: ExamCategoryType
      marketplace_product_status: MarketplaceProductStatus
      marketplace_product_type: MarketplaceProductType
    }
    CompositeTypes: Record<string, never>
  }
}

// ──────────────────────────────────────────────────────────────
// Convenience Type Aliases
// ──────────────────────────────────────────────────────────────

/** Extract the Row type for any table */
export type TablesRow<T extends keyof Tables> = Tables[T]['Row']

/** Extract the Insert type for any table */
export type TablesInsert<T extends keyof Tables> = Tables[T]['Insert']

/** Extract the Update type for any table */
export type TablesUpdate<T extends keyof Tables> = Tables[T]['Update']

/** Typed Supabase client using our Database schema */
export type TypedSupabaseClient = import('@supabase/supabase-js').SupabaseClient<Database>
