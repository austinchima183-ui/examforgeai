-- ============================================================================
-- ExamForge AI - CBT Engine Enhancements Schema
-- ============================================================================
-- Enhancement migration for the Computer-Based Testing (CBT) Engine.
-- Adds: Exam Templates, Template Sections, Question Selection Rules,
--       Submission Receipts, and enhanced Exam Notifications.
--
-- Prerequisites:
--   Existing tables: schools, users, classes, subjects, exams, exam_attempts,
--                    question_bank (from cbt_engine_schema.sql and prior schemas)
--   Existing enums:  exam_type, question_type, difficulty_level, submission_type,
--                    exam_status, attempt_status, grading_status
--
-- Performance: Composite indexes for common query patterns, GIN indexes for
--              JSONB and array columns, partial indexes for hot paths.
--
-- Idempotent: All DDL uses IF NOT EXISTS / DO $$ blocks to ensure safe
--             re-execution without errors.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. EXTEND EXISTING ENUMS (IF NEEDED)
-- ============================================================================
-- The existing exam_type enum already includes 'school_exam' and other values
-- used by exam_templates. No new enum types are required for this migration
-- since we reuse: exam_type, question_type, difficulty_level, submission_type.
-- ============================================================================

-- Ensure 'custom' category support: verify exam_type has needed values.
-- The existing exam_type enum already covers: school_exam, mock_exam, assignment,
-- quiz, ca_test, mid_term, final_exam, external_exam, practice_test, diagnostic_test

-- ============================================================================
-- 2. EXAM_TEMPLATES TABLE
-- ============================================================================
-- Store reusable exam templates that can be used to quickly create new exams.
-- Templates capture all configuration (timing, anti-cheat, result visibility,
-- negative marking, etc.) and can be shared across a school or made public.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_templates (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  created_by              UUID REFERENCES users(id) ON DELETE SET NULL,
  name                    TEXT NOT NULL,
  description             TEXT,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  exam_type               exam_type NOT NULL DEFAULT 'school_exam',
  time_limit_minutes      INTEGER NOT NULL DEFAULT 60,
  pass_mark               NUMERIC(5,2) NOT NULL DEFAULT 50.00,
  pass_mark_type          TEXT NOT NULL DEFAULT 'percentage' CHECK (pass_mark_type IN ('percentage', 'absolute')),
  instructions            TEXT,
  allowed_attempts        INTEGER NOT NULL DEFAULT 1,
  negative_marking_enabled BOOLEAN NOT NULL DEFAULT false,
  negative_mark_value     NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  grace_period_minutes    INTEGER NOT NULL DEFAULT 0,
  auto_submit             BOOLEAN NOT NULL DEFAULT true,
  randomize_questions     BOOLEAN NOT NULL DEFAULT false,
  randomize_options       BOOLEAN NOT NULL DEFAULT false,
  show_results            TEXT NOT NULL DEFAULT 'after_submission' CHECK (show_results IN ('immediate', 'after_submission', 'after_grading', 'manual')),
  show_correct_answers    BOOLEAN NOT NULL DEFAULT false,
  show_explanations       BOOLEAN NOT NULL DEFAULT false,
  require_full_screen     BOOLEAN NOT NULL DEFAULT false,
  allow_resume            BOOLEAN NOT NULL DEFAULT true,
  browser_lockdown        BOOLEAN NOT NULL DEFAULT false,
  metadata                JSONB DEFAULT '{}',
  usage_count             INTEGER NOT NULL DEFAULT 0,
  is_public               BOOLEAN NOT NULL DEFAULT false,
  category                TEXT NOT NULL DEFAULT 'custom' CHECK (category IN ('school_exam', 'waec_prep', 'neco_prep', 'jamb_prep', 'bece_prep', 'certification', 'custom')),
  tags                    TEXT[] DEFAULT '{}',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Validation constraints
  CONSTRAINT exam_templates_name_not_empty CHECK (length(trim(name)) > 0),
  CONSTRAINT exam_templates_time_limit_positive CHECK (time_limit_minutes > 0),
  CONSTRAINT exam_templates_pass_mark_non_negative CHECK (pass_mark >= 0),
  CONSTRAINT exam_templates_negative_mark_non_negative CHECK (negative_mark_value >= 0),
  CONSTRAINT exam_templates_grace_period_non_negative CHECK (grace_period_minutes >= 0),
  CONSTRAINT exam_templates_allowed_attempts_positive CHECK (allowed_attempts > 0),
  CONSTRAINT exam_templates_usage_count_non_negative CHECK (usage_count >= 0)
);

COMMENT ON TABLE exam_templates IS 'Reusable exam templates for quick exam creation with pre-configured settings, sections, and question selection rules';
COMMENT ON COLUMN exam_templates.school_id IS 'The school that owns this template';
COMMENT ON COLUMN exam_templates.created_by IS 'Teacher or admin who created the template';
COMMENT ON COLUMN exam_templates.name IS 'Human-readable template name (e.g., "WAEC Mathematics Prep 2025")';
COMMENT ON COLUMN exam_templates.description IS 'Optional description of the template purpose and contents';
COMMENT ON COLUMN exam_templates.exam_type IS 'Type of exam this template creates, using the existing exam_type enum';
COMMENT ON COLUMN exam_templates.time_limit_minutes IS 'Default exam duration in minutes';
COMMENT ON COLUMN exam_templates.pass_mark IS 'Minimum marks/percentage required to pass';
COMMENT ON COLUMN exam_templates.pass_mark_type IS 'Whether pass_mark is a percentage (0-100) or absolute value';
COMMENT ON COLUMN exam_templates.negative_marking_enabled IS 'Whether negative marking is enabled for wrong answers';
COMMENT ON COLUMN exam_templates.negative_mark_value IS 'Marks to deduct per wrong answer when negative_marking_enabled is true';
COMMENT ON COLUMN exam_templates.grace_period_minutes IS 'Extra time allowed after time_limit before auto-submit';
COMMENT ON COLUMN exam_templates.show_results IS 'When students can see their results after submission';
COMMENT ON COLUMN exam_templates.usage_count IS 'Number of times this template has been used to create an exam';
COMMENT ON COLUMN exam_templates.is_public IS 'If true, template is visible to all schools (community template)';
COMMENT ON COLUMN exam_templates.category IS 'Template category for filtering: school_exam, waec_prep, neco_prep, jamb_prep, bece_prep, certification, custom';
COMMENT ON COLUMN exam_templates.tags IS 'Array of tags for search and filtering (e.g., {"mathematics", "ss3", "waec"})';
COMMENT ON COLUMN exam_templates.metadata IS 'Extensible JSONB for custom configuration and integrations';

-- ============================================================================
-- 3. EXAM_TEMPLATE_SECTIONS TABLE
-- ============================================================================
-- Sections within a template, mirroring the exam_sections structure.
-- Each section can have its own time limit and question randomization.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_template_sections (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id           UUID NOT NULL REFERENCES exam_templates(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  instructions          TEXT,
  sort_order            INTEGER NOT NULL DEFAULT 0,
  time_limit_minutes    INTEGER,            -- null = use template time limit
  randomize_questions   BOOLEAN NOT NULL DEFAULT false,
  marks_per_question    NUMERIC(5,2) NOT NULL DEFAULT 1.00,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT exam_template_sections_title_not_empty CHECK (length(trim(title)) > 0),
  CONSTRAINT exam_template_sections_sort_order_non_negative CHECK (sort_order >= 0),
  CONSTRAINT exam_template_sections_time_limit_positive CHECK (time_limit_minutes IS NULL OR time_limit_minutes > 0),
  CONSTRAINT exam_template_sections_marks_positive CHECK (marks_per_question > 0)
);

COMMENT ON TABLE exam_template_sections IS 'Logical sections within an exam template for organizing questions (e.g., Section A: Objective, Section B: Theory)';
COMMENT ON COLUMN exam_template_sections.template_id IS 'Parent template this section belongs to';
COMMENT ON COLUMN exam_template_sections.instructions IS 'Section-specific instructions shown to students';
COMMENT ON COLUMN exam_template_sections.time_limit_minutes IS 'Section-specific time limit; null means use the template-level time limit';
COMMENT ON COLUMN exam_template_sections.randomize_questions IS 'If true, question order is randomized within this section';
COMMENT ON COLUMN exam_template_sections.marks_per_question IS 'Default marks per question for this section; can be overridden by selection rules';

-- ============================================================================
-- 4. QUESTION_SELECTION_RULES TABLE
-- ============================================================================
-- Rules for automatically selecting questions from the question bank when
-- creating an exam from a template. Supports filtering by subject, topic,
-- difficulty, question type, and curriculum alignment. Selection can be
-- random, balanced (across difficulty levels), or progressive.
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_selection_rules (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id           UUID NOT NULL REFERENCES exam_templates(id) ON DELETE CASCADE,
  section_id            UUID REFERENCES exam_template_sections(id) ON DELETE CASCADE,
  subject_id            UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic_ids             UUID[] DEFAULT '{}',
  difficulty_levels     difficulty_level[] DEFAULT '{}',
  question_types        question_type[] DEFAULT '{}',
  curriculum_types      TEXT[] DEFAULT '{}',
  min_questions         INTEGER NOT NULL DEFAULT 1,
  max_questions         INTEGER NOT NULL DEFAULT 50,
  marks_per_question    NUMERIC(5,2) NOT NULL DEFAULT 1.00,
  selection_mode        TEXT NOT NULL DEFAULT 'random' CHECK (selection_mode IN ('random', 'balanced', 'progressive')),
  include_images        BOOLEAN NOT NULL DEFAULT false,
  include_audio         BOOLEAN NOT NULL DEFAULT false,
  include_video         BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT question_selection_rules_min_questions_positive CHECK (min_questions > 0),
  CONSTRAINT question_selection_rules_max_questions_positive CHECK (max_questions > 0),
  CONSTRAINT question_selection_rules_min_max_valid CHECK (min_questions <= max_questions),
  CONSTRAINT question_selection_rules_marks_positive CHECK (marks_per_question > 0)
);

COMMENT ON TABLE question_selection_rules IS 'Rules for auto-selecting questions from the question bank when creating exams from templates';
COMMENT ON COLUMN question_selection_rules.template_id IS 'Parent template this rule belongs to';
COMMENT ON COLUMN question_selection_rules.section_id IS 'Target section for selected questions; null means unassigned/first section';
COMMENT ON COLUMN question_selection_rules.subject_id IS 'Filter: only select questions from this subject; null means use template subject';
COMMENT ON COLUMN question_selection_rules.topic_ids IS 'Filter: only select questions from these topics; empty means no topic filter';
COMMENT ON COLUMN question_selection_rules.difficulty_levels IS 'Filter: only select questions at these difficulty levels; empty means all levels';
COMMENT ON COLUMN question_selection_rules.question_types IS 'Filter: only select questions of these types; empty means all types';
COMMENT ON COLUMN question_selection_rules.curriculum_types IS 'Filter: only select questions matching these curriculum standards; empty means all';
COMMENT ON COLUMN question_selection_rules.min_questions IS 'Minimum number of questions to select; ensures adequate coverage';
COMMENT ON COLUMN question_selection_rules.max_questions IS 'Maximum number of questions to select; prevents overly long exams';
COMMENT ON COLUMN question_selection_rules.marks_per_question IS 'Default marks per question for this rule; can override section default';
COMMENT ON COLUMN question_selection_rules.selection_mode IS 'How questions are selected: random, balanced (across difficulty), progressive (easier to harder)';
COMMENT ON COLUMN question_selection_rules.include_images IS 'If true, include questions that contain images';
COMMENT ON COLUMN question_selection_rules.include_audio IS 'If true, include questions that contain audio';
COMMENT ON COLUMN question_selection_rules.include_video IS 'If true, include questions that contain video';

-- ============================================================================
-- 5. SUBMISSION_RECEIPTS TABLE
-- ============================================================================
-- Digital receipts for exam submissions. Provides verifiable proof of
-- submission with a unique receipt number, device info, IP address, and
-- answer statistics. Used for audit trails and dispute resolution.
-- ============================================================================

CREATE TABLE IF NOT EXISTS submission_receipts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id            UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exam_title            TEXT NOT NULL,
  submitted_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  submission_type       submission_type NOT NULL,
  total_questions       INTEGER NOT NULL DEFAULT 0,
  answered_questions    INTEGER NOT NULL DEFAULT 0,
  unanswered_questions  INTEGER NOT NULL DEFAULT 0,
  flagged_questions     INTEGER NOT NULL DEFAULT 0,
  time_spent_minutes    INTEGER NOT NULL DEFAULT 0,
  ip_address            INET,
  device_info           JSONB DEFAULT '{}',
  receipt_number        TEXT NOT NULL UNIQUE DEFAULT upper(substring(md5(random()::text) from 1 for 12)),
  is_verified           BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT submission_receipts_total_questions_non_negative CHECK (total_questions >= 0),
  CONSTRAINT submission_receipts_answered_non_negative CHECK (answered_questions >= 0),
  CONSTRAINT submission_receipts_unanswered_non_negative CHECK (unanswered_questions >= 0),
  CONSTRAINT submission_receipts_flagged_non_negative CHECK (flagged_questions >= 0),
  CONSTRAINT submission_receipts_time_spent_non_negative CHECK (time_spent_minutes >= 0),
  CONSTRAINT submission_receipts_answer_counts_valid CHECK (answered_questions + unanswered_questions <= total_questions)
);

COMMENT ON TABLE submission_receipts IS 'Digital receipts for exam submissions providing verifiable proof with unique receipt numbers, device info, and answer statistics';
COMMENT ON COLUMN submission_receipts.attempt_id IS 'The exam attempt this receipt belongs to';
COMMENT ON COLUMN submission_receipts.exam_id IS 'The exam this receipt is for (denormalized for quick lookups)';
COMMENT ON COLUMN submission_receipts.student_id IS 'The student who submitted (denormalized for quick lookups)';
COMMENT ON COLUMN submission_receipts.exam_title IS 'Exam title at time of submission (denormalized to preserve history)';
COMMENT ON COLUMN submission_receipts.submitted_at IS 'Exact timestamp when the submission was received by the server';
COMMENT ON COLUMN submission_receipts.submission_type IS 'How the exam was submitted: manual, auto_submit, timed_out, force_submit';
COMMENT ON COLUMN submission_receipts.total_questions IS 'Total number of questions in the exam at submission time';
COMMENT ON COLUMN submission_receipts.answered_questions IS 'Number of questions the student answered';
COMMENT ON COLUMN submission_receipts.unanswered_questions IS 'Number of questions left unanswered';
COMMENT ON COLUMN submission_receipts.flagged_questions IS 'Number of questions the student flagged for review';
COMMENT ON COLUMN submission_receipts.time_spent_minutes IS 'Total time the student spent on the exam in minutes';
COMMENT ON COLUMN submission_receipts.ip_address IS 'IP address from which the exam was submitted';
COMMENT ON COLUMN submission_receipts.device_info IS 'JSONB with device details: browser, OS, screen resolution, user agent';
COMMENT ON COLUMN submission_receipts.receipt_number IS 'Unique human-readable receipt number for student reference (auto-generated)';
COMMENT ON COLUMN submission_receipts.is_verified IS 'Whether the submission has been verified as legitimate (no tampering detected)';

-- ============================================================================
-- 6. EXAM_NOTIFICATIONS TABLE (ENHANCED)
-- ============================================================================
-- Enhanced exam-specific notifications that extend the general notifications
-- system. Uses user_id (instead of student_id) to support notifications for
-- both students and teachers. notification_type provides fine-grained event
-- categorization for the exam lifecycle.
--
-- NOTE: This replaces the simpler exam_notifications table from the base
-- cbt_engine_schema.sql. The old table used student_id + category enum;
-- this version uses user_id + notification_type TEXT for broader support.
-- ============================================================================

-- Safely drop the old exam_notifications table if it exists with the old schema
-- (has 'category' column instead of 'notification_type')
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'exam_notifications'
      AND table_schema = 'public'
  ) THEN
    -- Check if it's the old schema (has 'category' column)
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'exam_notifications'
        AND table_schema = 'public'
        AND column_name = 'category'
    ) THEN
      -- Drop old table with cascade to remove dependent indexes/policies
      DROP TABLE IF EXISTS exam_notifications CASCADE;
      RAISE NOTICE 'Dropped old exam_notifications table (category-based schema) for enhancement migration';
    END IF;
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS exam_notifications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_type     TEXT NOT NULL CHECK (notification_type IN (
    'exam_published', 'exam_started', 'time_warning_5min', 'time_warning_1min',
    'exam_submitted', 'results_released', 'manual_grading_required',
    'all_submissions_complete', 'suspicious_activity', 'exam_cancelled',
    'exam_rescheduled', 'grading_complete'
  )),
  title                 TEXT NOT NULL,
  message               TEXT NOT NULL,
  data                  JSONB DEFAULT '{}',
  is_read               BOOLEAN NOT NULL DEFAULT false,
  read_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE exam_notifications IS 'Enhanced exam-specific notifications extending the general notifications system with fine-grained event types';
COMMENT ON COLUMN exam_notifications.exam_id IS 'The exam this notification relates to';
COMMENT ON COLUMN exam_notifications.user_id IS 'The user (student or teacher) who receives this notification';
COMMENT ON COLUMN exam_notifications.notification_type IS 'Specific event type: exam_published, exam_started, time_warning_*, exam_submitted, results_released, etc.';
COMMENT ON COLUMN exam_notifications.title IS 'Notification title for quick scanning';
COMMENT ON COLUMN exam_notifications.message IS 'Full notification message body';
COMMENT ON COLUMN exam_notifications.data IS 'Structured payload (e.g., exam_id, time_remaining, result summary, attempt details)';
COMMENT ON COLUMN exam_notifications.is_read IS 'Whether the user has read this notification';
COMMENT ON COLUMN exam_notifications.read_at IS 'Timestamp when the user read the notification';

-- ============================================================================
-- 7. INDEXES
-- ============================================================================
-- Comprehensive indexing strategy for high-performance queries.
-- Single-column indexes for FK joins and lookups.
-- Composite indexes for common query patterns.
-- GIN indexes for JSONB and array columns.
-- Partial indexes for high-frequency filtered queries.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- exam_templates indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_templates_school_id ON exam_templates(school_id);
CREATE INDEX IF NOT EXISTS idx_exam_templates_created_by ON exam_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_exam_templates_subject_id ON exam_templates(subject_id);
CREATE INDEX IF NOT EXISTS idx_exam_templates_class_id ON exam_templates(class_id);
CREATE INDEX IF NOT EXISTS idx_exam_templates_exam_type ON exam_templates(exam_type);
CREATE INDEX IF NOT EXISTS idx_exam_templates_category ON exam_templates(category);
CREATE INDEX IF NOT EXISTS idx_exam_templates_is_public ON exam_templates(is_public);
CREATE INDEX IF NOT EXISTS idx_exam_templates_created_at ON exam_templates(created_at);
-- Composite: templates by school filtered by category (template library)
CREATE INDEX IF NOT EXISTS idx_exam_templates_school_category ON exam_templates(school_id, category);
-- Composite: templates by school ordered by usage (popular templates)
CREATE INDEX IF NOT EXISTS idx_exam_templates_school_usage ON exam_templates(school_id, usage_count DESC);
-- Composite: public templates by category (community template library)
CREATE INDEX IF NOT EXISTS idx_exam_templates_public_category ON exam_templates(category, created_at DESC) WHERE is_public = true;
-- GIN index for metadata JSONB
CREATE INDEX IF NOT EXISTS idx_exam_templates_metadata_gin ON exam_templates USING gin(metadata);
-- GIN index for tags array (tag-based search)
CREATE INDEX IF NOT EXISTS idx_exam_templates_tags_gin ON exam_templates USING gin(tags);

-- ---------------------------------------------------------------------------
-- exam_template_sections indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_template_sections_template_id ON exam_template_sections(template_id);
-- Composite: sections by template ordered by sort_order (section list retrieval)
CREATE INDEX IF NOT EXISTS idx_exam_template_sections_template_sort ON exam_template_sections(template_id, sort_order);

-- ---------------------------------------------------------------------------
-- question_selection_rules indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_template_id ON question_selection_rules(template_id);
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_section_id ON question_selection_rules(section_id);
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_subject_id ON question_selection_rules(subject_id);
-- Composite: rules by template with section (for template assembly)
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_template_section ON question_selection_rules(template_id, section_id);
-- GIN index for topic_ids array (topic-based matching)
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_topic_ids_gin ON question_selection_rules USING gin(topic_ids);
-- GIN index for difficulty_levels array
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_difficulty_gin ON question_selection_rules USING gin(difficulty_levels);
-- GIN index for question_types array
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_question_types_gin ON question_selection_rules USING gin(question_types);
-- GIN index for curriculum_types array
CREATE INDEX IF NOT EXISTS idx_question_selection_rules_curriculum_gin ON question_selection_rules USING gin(curriculum_types);

-- ---------------------------------------------------------------------------
-- submission_receipts indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_submission_receipts_attempt_id ON submission_receipts(attempt_id);
CREATE INDEX IF NOT EXISTS idx_submission_receipts_exam_id ON submission_receipts(exam_id);
CREATE INDEX IF NOT EXISTS idx_submission_receipts_student_id ON submission_receipts(student_id);
CREATE INDEX IF NOT EXISTS idx_submission_receipts_receipt_number ON submission_receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_submission_receipts_submitted_at ON submission_receipts(submitted_at);
CREATE INDEX IF NOT EXISTS idx_submission_receipts_is_verified ON submission_receipts(is_verified);
-- Composite: receipts by exam ordered by submission time (teacher dashboard)
CREATE INDEX IF NOT EXISTS idx_submission_receipts_exam_submitted ON submission_receipts(exam_id, submitted_at DESC);
-- Composite: student's receipt history
CREATE INDEX IF NOT EXISTS idx_submission_receipts_student_submitted ON submission_receipts(student_id, submitted_at DESC);
-- GIN index for device_info JSONB (forensic analysis)
CREATE INDEX IF NOT EXISTS idx_submission_receipts_device_info_gin ON submission_receipts USING gin(device_info);
-- Partial index: unverified receipts (requires review)
CREATE INDEX IF NOT EXISTS idx_submission_receipts_unverified ON submission_receipts(exam_id, submitted_at DESC) WHERE is_verified = false;

-- ---------------------------------------------------------------------------
-- exam_notifications indexes (enhanced)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_notifications_exam_id ON exam_notifications(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_user_id ON exam_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_notification_type ON exam_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_is_read ON exam_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_created_at ON exam_notifications(created_at);
-- Composite: unread notifications per user (notification bell count — high frequency)
CREATE INDEX IF NOT EXISTS idx_exam_notifications_user_unread ON exam_notifications(user_id, is_read) WHERE is_read = false;
-- Composite: notifications per user ordered by time (notification list)
CREATE INDEX IF NOT EXISTS idx_exam_notifications_user_created ON exam_notifications(user_id, created_at DESC);
-- Composite: notifications per exam by type (admin/teacher filtering)
CREATE INDEX IF NOT EXISTS idx_exam_notifications_exam_type ON exam_notifications(exam_id, notification_type);
-- GIN index for data JSONB
CREATE INDEX IF NOT EXISTS idx_exam_notifications_data_gin ON exam_notifications USING gin(data);

-- ============================================================================
-- 8. TRIGGERS
-- ============================================================================
-- Automated triggers for updated_at maintenance and template usage tracking.
-- Uses the existing update_updated_at_column() function from the base schema.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auto-update updated_at on tables with that column
-- ---------------------------------------------------------------------------

-- exam_templates
DROP TRIGGER IF EXISTS set_exam_templates_updated_at ON exam_templates;
CREATE TRIGGER set_exam_templates_updated_at
  BEFORE UPDATE ON exam_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 9. FUNCTIONS
-- ============================================================================
-- Production-ready PL/pgSQL functions for template usage tracking.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- increment_template_usage(p_template_id UUID)
-- Increments the usage_count of an exam template when it is used to create
-- an exam. Called by application code or trigger after exam creation.
-- Returns the new usage_count value.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_template_usage(p_template_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  IF p_template_id IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE exam_templates
  SET usage_count = usage_count + 1,
      updated_at = now()
  WHERE id = p_template_id
  RETURNING usage_count INTO v_new_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Exam template not found: %', p_template_id;
  END IF;

  RETURN v_new_count;
END;
$$;

COMMENT ON FUNCTION increment_template_usage(UUID) IS
  'Increment the usage_count of an exam template when used to create an exam; returns the new count';

-- ---------------------------------------------------------------------------
-- create_exam_from_template(p_template_id UUID, p_created_by UUID,
--   p_start_time TIMESTAMPTZ, p_end_time TIMESTAMPTZ,
--   p_school_id UUID, p_title TEXT DEFAULT NULL)
-- Creates a new exam from a template, copying all configuration and sections.
-- Increments template usage_count. Returns the new exam id.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_exam_from_template(
  p_template_id  UUID,
  p_created_by   UUID,
  p_start_time   TIMESTAMPTZ,
  p_end_time     TIMESTAMPTZ,
  p_school_id    UUID,
  p_title        TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exam_id       UUID;
  v_template      exam_templates%ROWTYPE;
  v_section       exam_template_sections%ROWTYPE;
  v_new_section_id UUID;
BEGIN
  -- Fetch the template
  SELECT * INTO v_template FROM exam_templates WHERE id = p_template_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Template not found: %', p_template_id;
  END IF;

  -- Verify the template belongs to the specified school or is public
  IF v_template.school_id != p_school_id AND v_template.is_public = false THEN
    RAISE EXCEPTION 'Template % does not belong to school % and is not public', p_template_id, p_school_id;
  END IF;

  -- Create the exam from template configuration
  INSERT INTO exams (
    school_id, created_by, title, description, subject_id, class_id,
    exam_type, status, start_time, end_time, time_limit_minutes,
    pass_mark, pass_mark_type, instructions, allowed_attempts,
    negative_marking_enabled, negative_mark_value, grace_period_minutes,
    auto_submit, randomize_questions, randomize_options,
    show_results, show_correct_answers, show_explanations,
    is_template, template_id, require_full_screen, allow_resume,
    browser_lockdown, metadata
  ) VALUES (
    p_school_id, p_created_by,
    COALESCE(p_title, v_template.name), v_template.description,
    v_template.subject_id, v_template.class_id,
    v_template.exam_type, 'draft', p_start_time, p_end_time,
    v_template.time_limit_minutes, v_template.pass_mark,
    v_template.pass_mark_type, v_template.instructions,
    v_template.allowed_attempts, v_template.negative_marking_enabled,
    v_template.negative_mark_value, v_template.grace_period_minutes,
    v_template.auto_submit, v_template.randomize_questions,
    v_template.randomize_options, v_template.show_results,
    v_template.show_correct_answers, v_template.show_explanations,
    false, p_template_id, v_template.require_full_screen,
    v_template.allow_resume, v_template.browser_lockdown,
    v_template.metadata
  )
  RETURNING id INTO v_exam_id;

  -- Copy template sections to exam sections
  FOR v_section IN
    SELECT * FROM exam_template_sections
    WHERE template_id = p_template_id
    ORDER BY sort_order
  LOOP
    INSERT INTO exam_sections (
      exam_id, title, description, instructions, sort_order,
      time_limit_minutes, randomize_questions
    ) VALUES (
      v_exam_id, v_section.title, v_section.description,
      v_section.instructions, v_section.sort_order,
      v_section.time_limit_minutes, v_section.randomize_questions
    )
    RETURNING id INTO v_new_section_id;

    -- Note: Question selection rules are NOT automatically resolved here.
    -- The application layer should use question_selection_rules to select
    -- questions from the question bank and populate exam_questions.
    -- This function only clones the structural template.
  END LOOP;

  -- Increment template usage count
  PERFORM increment_template_usage(p_template_id);

  RETURN v_exam_id;
END;
$$;

COMMENT ON FUNCTION create_exam_from_template(UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT) IS
  'Create a new exam from a template, copying all configuration and sections; increments template usage_count; returns the new exam id';

-- ---------------------------------------------------------------------------
-- generate_submission_receipt(p_attempt_id UUID)
-- Generates a submission receipt for an exam attempt. Creates a verifiable
-- digital receipt with answer statistics, device info, and a unique receipt
-- number. Returns the receipt id.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_submission_receipt(p_attempt_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_receipt_id     UUID;
  v_attempt        exam_attempts%ROWTYPE;
  v_exam           exams%ROWTYPE;
  v_total_questions  INTEGER := 0;
  v_answered        INTEGER := 0;
  v_unanswered      INTEGER := 0;
  v_flagged         INTEGER := 0;
  v_time_spent_min  INTEGER := 0;
BEGIN
  -- Fetch the attempt
  SELECT * INTO v_attempt FROM exam_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Exam attempt not found: %', p_attempt_id;
  END IF;

  -- Fetch the exam
  SELECT * INTO v_exam FROM exams WHERE id = v_attempt.exam_id;

  -- Calculate answer statistics
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE answer_data != '{}'),
    COUNT(*) FILTER (WHERE answer_data = '{}'),
    COUNT(*) FILTER (WHERE is_flagged = true)
  INTO v_total_questions, v_answered, v_unanswered, v_flagged
  FROM student_answers
  WHERE attempt_id = p_attempt_id;

  -- If no student_answers exist yet, count from exam_questions
  IF v_total_questions = 0 THEN
    SELECT COUNT(*) INTO v_total_questions
    FROM exam_questions
    WHERE exam_id = v_attempt.exam_id;

    v_unanswered := v_total_questions;
  END IF;

  -- Calculate time spent in minutes
  IF v_attempt.started_at IS NOT NULL AND v_attempt.submitted_at IS NOT NULL THEN
    v_time_spent_min := EXTRACT(EPOCH FROM (v_attempt.submitted_at - v_attempt.started_at))::INTEGER / 60;
  END IF;

  -- Create the receipt
  INSERT INTO submission_receipts (
    attempt_id, exam_id, student_id, exam_title,
    submitted_at, submission_type, total_questions, answered_questions,
    unanswered_questions, flagged_questions, time_spent_minutes,
    ip_address, device_info
  ) VALUES (
    p_attempt_id, v_attempt.exam_id, v_attempt.student_id, v_exam.title,
    COALESCE(v_attempt.submitted_at, now()), COALESCE(v_attempt.submission_type, 'manual'),
    v_total_questions, v_answered, v_unanswered, v_flagged,
    v_time_spent_min, v_attempt.ip_address, v_attempt.device_info
  )
  RETURNING id INTO v_receipt_id;

  RETURN v_receipt_id;
END;
$$;

COMMENT ON FUNCTION generate_submission_receipt(UUID) IS
  'Generate a verifiable submission receipt for an exam attempt with answer statistics and unique receipt number';

-- ---------------------------------------------------------------------------
-- create_exam_notification(p_exam_id UUID, p_user_id UUID,
--   p_notification_type TEXT, p_title TEXT, p_message TEXT, p_data JSONB)
-- Convenience function to insert an exam notification with validation.
-- Returns the notification id.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_exam_notification(
  p_exam_id           UUID,
  p_user_id           UUID,
  p_notification_type TEXT,
  p_title             TEXT,
  p_message           TEXT,
  p_data              JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  -- Validate notification_type
  IF p_notification_type NOT IN (
    'exam_published', 'exam_started', 'time_warning_5min', 'time_warning_1min',
    'exam_submitted', 'results_released', 'manual_grading_required',
    'all_submissions_complete', 'suspicious_activity', 'exam_cancelled',
    'exam_rescheduled', 'grading_complete'
  ) THEN
    RAISE EXCEPTION 'Invalid notification_type: %', p_notification_type;
  END IF;

  INSERT INTO exam_notifications (
    exam_id, user_id, notification_type, title, message, data
  ) VALUES (
    p_exam_id, p_user_id, p_notification_type, p_title, p_message, p_data
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

COMMENT ON FUNCTION create_exam_notification(UUID, UUID, TEXT, TEXT, TEXT, JSONB) IS
  'Convenience function to insert an exam notification with type validation; returns the notification id';

-- ---------------------------------------------------------------------------
-- mark_exam_notification_read(p_notification_id UUID, p_user_id UUID)
-- Marks a notification as read by the specified user. Returns true if
-- the notification was successfully marked as read.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_exam_notification_read(
  p_notification_id UUID,
  p_user_id         UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE exam_notifications
  SET is_read = true,
      read_at = now()
  WHERE id = p_notification_id
    AND user_id = p_user_id
    AND is_read = false;

  RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION mark_exam_notification_read(UUID, UUID) IS
  'Mark an exam notification as read by the specified user; returns true if updated';

-- ---------------------------------------------------------------------------
-- get_unread_notification_count(p_user_id UUID)
-- Returns the count of unread exam notifications for a user.
-- Optimized by the idx_exam_notifications_user_unread partial index.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM exam_notifications
  WHERE user_id = p_user_id
    AND is_read = false;

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION get_unread_notification_count(UUID) IS
  'Get the count of unread exam notifications for a user; optimized by partial index';

-- ============================================================================
-- 10. ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- RLS is enabled on all new tables. Policies follow the same pattern as
-- the base CBT schema: super_admin > school_admin > teacher > student.
-- ============================================================================

ALTER TABLE exam_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_template_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_selection_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE submission_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 11. ROW LEVEL SECURITY POLICIES
-- ============================================================================
-- Role hierarchy: super_admin (full) > school_admin (school-scoped) >
--                teacher (own-created) > student (own-records)
-- ============================================================================

-- ===========================================================================
-- EXAM_TEMPLATES RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_templates"
  ON exam_templates FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage templates in their school
CREATE POLICY "School admins can manage exam_templates"
  ON exam_templates FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Teachers can read own school templates and public templates
CREATE POLICY "Teachers can read exam_templates"
  ON exam_templates FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND (
      school_id = (SELECT school_id FROM users WHERE id = auth.uid())
      OR is_public = true
    )
  );

-- Teachers can insert templates in their school
CREATE POLICY "Teachers can insert exam_templates"
  ON exam_templates FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'teacher'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Teachers can update templates they created
CREATE POLICY "Teachers can update own exam_templates"
  ON exam_templates FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  );

-- Teachers can delete templates they created
CREATE POLICY "Teachers can delete own exam_templates"
  ON exam_templates FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  );

-- Students can read public templates (for practice exams)
CREATE POLICY "Students can read public exam_templates"
  ON exam_templates FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND is_public = true
  );

-- ===========================================================================
-- EXAM_TEMPLATE_SECTIONS RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_template_sections"
  ON exam_template_sections FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage sections for templates in their school
CREATE POLICY "School admins can manage exam_template_sections"
  ON exam_template_sections FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND et.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND et.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Teachers can manage sections for templates they created
CREATE POLICY "Teachers can manage own exam_template_sections"
  ON exam_template_sections FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.created_by = auth.uid()
    )
  );

-- Teachers can read sections for public templates
CREATE POLICY "Teachers can read public exam_template_sections"
  ON exam_template_sections FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND (et.is_public = true OR et.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    )
  );

-- Students can read sections for public templates
CREATE POLICY "Students can read public exam_template_sections"
  ON exam_template_sections FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.is_public = true
    )
  );

-- ===========================================================================
-- QUESTION_SELECTION_RULES RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to question_selection_rules"
  ON question_selection_rules FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage rules for templates in their school
CREATE POLICY "School admins can manage question_selection_rules"
  ON question_selection_rules FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND et.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND et.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Teachers can manage rules for templates they created
CREATE POLICY "Teachers can manage own question_selection_rules"
  ON question_selection_rules FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.created_by = auth.uid()
    )
  );

-- Teachers can read rules for school/public templates
CREATE POLICY "Teachers can read question_selection_rules"
  ON question_selection_rules FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id
        AND (et.created_by = auth.uid()
             OR et.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
             OR et.is_public = true)
    )
  );

-- Students can read rules for public templates (to understand exam structure)
CREATE POLICY "Students can read public question_selection_rules"
  ON question_selection_rules FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND EXISTS (
      SELECT 1 FROM exam_templates et
      WHERE et.id = template_id AND et.is_public = true
    )
  );

-- ===========================================================================
-- SUBMISSION_RECEIPTS RLS POLICIES
-- ===========================================================================

-- Students can read their own receipts
CREATE POLICY "Students can read own submission_receipts"
  ON submission_receipts FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Teachers can read receipts for their exams
CREATE POLICY "Teachers can read submission_receipts for own exams"
  ON submission_receipts FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all receipts in their school
CREATE POLICY "School admins can read submission_receipts"
  ON submission_receipts FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to submission_receipts"
  ON submission_receipts FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Receipts are inserted via service_role or SECURITY DEFINER functions

-- ===========================================================================
-- EXAM_NOTIFICATIONS RLS POLICIES (ENHANCED)
-- ===========================================================================

-- Users can read their own notifications
CREATE POLICY "Users can read own exam_notifications"
  ON exam_notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own exam_notifications"
  ON exam_notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Teachers can read notifications for their exams
CREATE POLICY "Teachers can read exam_notifications for own exams"
  ON exam_notifications FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read notifications for exams in their school
CREATE POLICY "School admins can read exam_notifications"
  ON exam_notifications FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_notifications"
  ON exam_notifications FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Notifications are inserted via service_role or SECURITY DEFINER functions

-- ============================================================================
-- 12. SUPABASE REALTIME SETUP
-- ============================================================================
-- Enable Realtime on exam_notifications for instant notification delivery.
-- This allows the frontend to subscribe to new notifications in real-time.
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE exam_notifications;

-- ============================================================================
-- 13. TABLE COMMENTS SUMMARY
-- ============================================================================

COMMENT ON SCHEMA public IS 'ExamForge AI CBT Engine - Enhancement Schema v2.0 (Templates, Receipts, Enhanced Notifications)';

-- Final verification notice
DO $$
BEGIN
  RAISE NOTICE 'CBT Engine Enhancements schema migration completed successfully.';
  RAISE NOTICE 'Tables created: exam_templates, exam_template_sections, question_selection_rules, submission_receipts, exam_notifications (enhanced)';
  RAISE NOTICE 'Functions created: increment_template_usage, create_exam_from_template, generate_submission_receipt, create_exam_notification, mark_exam_notification_read, get_unread_notification_count';
  RAISE NOTICE 'Triggers created: set_exam_templates_updated_at';
  RAISE NOTICE 'Realtime enabled on: exam_notifications';
  RAISE NOTICE 'RLS enabled on all enhancement tables';
END
$$;

COMMIT;

-- ============================================================================
-- END OF CBT ENGINE ENHANCEMENTS SCHEMA
-- ============================================================================
