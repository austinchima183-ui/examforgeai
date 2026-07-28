-- ============================================================================
-- ExamForge AI - CBT Engine Module Schema
-- ============================================================================
-- Production-ready schema for the Computer-Based Testing (CBT) Engine.
-- Supports: exam creation, question selection, student attempts, auto-save,
--           anti-cheating, live monitoring via Supabase Realtime,
--           result processing, rankings, and notifications.
--
-- Prerequisites:
--   Existing tables: schools, users, classes, subjects, academic_sessions,
--                    question_bank, answer_options, matching_pairs,
--                    ordering_items, fill_in_blank_answers, notifications, audit_log
--   Existing enums:  user_role, subscription_status, exam_status, exam_type,
--                    question_type, difficulty_level, notification_type,
--                    share_permission, import_status, content_type,
--                    curriculum_standard_type
--
-- Performance: Designed for high-throughput with composite indexes,
--              GIN indexes for JSONB, Supabase Realtime for live monitoring,
--              and partitioning-ready layout.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. EXTEND EXISTING ENUMS
-- ============================================================================
-- Add new values to existing enums that the CBT Engine requires.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Extend exam_status: add 'cancelled' (existing: draft, published, active,
--                                            completed, archived)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'cancelled'
      AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'exam_status')
  ) THEN
    ALTER TYPE exam_status ADD VALUE 'cancelled';
  END IF;
END
$$;

-- ============================================================================
-- 2. NEW ENUMERATION TYPES
-- ============================================================================
-- All new enums required by the CBT Engine.
-- Uses IF NOT EXISTS pattern to ensure idempotent migrations.
-- ============================================================================

DO $$
BEGIN
  -- -------------------------------------------------------------------------
  -- attempt_status: Lifecycle states for a student's exam attempt
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attempt_status') THEN
    CREATE TYPE attempt_status AS ENUM (
      'not_started',
      'in_progress',
      'submitted',
      'auto_submitted',
      'timed_out',
      'disqualified',
      'abandoned'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- submission_type: How the exam attempt was submitted
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'submission_type') THEN
    CREATE TYPE submission_type AS ENUM (
      'manual',
      'auto_submit',
      'timed_out',
      'force_submit'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- grading_status: State of grading for an attempt or result
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'grading_status') THEN
    CREATE TYPE grading_status AS ENUM (
      'pending',
      'auto_graded',
      'partially_graded',
      'fully_graded',
      'disputed'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- monitoring_event_type: Anti-cheating / proctoring event categories
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'monitoring_event_type') THEN
    CREATE TYPE monitoring_event_type AS ENUM (
      'tab_switch',
      'focus_lost',
      'copy_attempt',
      'paste_attempt',
      'multiple_login',
      'idle_timeout',
      'browser_resize',
      'right_click',
      'screenshot_attempt',
      'full_screen_exit',
      'session_recovery',
      'suspicious_activity'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- notification_category: CBT-specific notification types
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_category') THEN
    CREATE TYPE notification_category AS ENUM (
      'exam_available',
      'exam_starting',
      'time_warning',
      'exam_submitted',
      'results_released',
      'grading_required',
      'exam_reminder'
    );
  END IF;
END
$$;

COMMENT ON TYPE attempt_status IS
  'Lifecycle states for a student exam attempt: not_started → in_progress → submitted/auto_submitted/timed_out/disqualified/abandoned';
COMMENT ON TYPE submission_type IS
  'How an exam attempt was submitted: manual, auto_submit, timed_out, or force_submit';
COMMENT ON TYPE grading_status IS
  'Grading progress: pending → auto_graded → partially_graded → fully_graded (or disputed)';
COMMENT ON TYPE monitoring_event_type IS
  'Anti-cheating / proctoring event categories for live monitoring';
COMMENT ON TYPE notification_category IS
  'CBT-specific notification categories for exam lifecycle communication';

-- ============================================================================
-- 3. EXAMS TABLE
-- ============================================================================
-- Core exam definition. Supports templates, scheduling, anti-cheating settings,
-- result visibility control, and extensive configuration via metadata JSONB.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exams (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  created_by              UUID NOT NULL REFERENCES users(id),
  title                   TEXT NOT NULL,
  description             TEXT,
  subject_id              UUID REFERENCES subjects(id) ON DELETE CASCADE,
  class_id                UUID REFERENCES classes(id) ON DELETE CASCADE,
  academic_session_id     UUID REFERENCES academic_sessions(id) ON DELETE CASCADE,
  exam_type               exam_type NOT NULL DEFAULT 'school_exam',
  status                  exam_status NOT NULL DEFAULT 'draft',
  start_time              TIMESTAMPTZ NOT NULL,
  end_time                TIMESTAMPTZ NOT NULL,
  time_limit_minutes      INTEGER NOT NULL,
  total_marks             NUMERIC(7,2) DEFAULT 0.00,
  pass_mark               NUMERIC(7,2) DEFAULT 0.00,
  pass_mark_type          VARCHAR(10) DEFAULT 'percentage',    -- 'percentage' or 'absolute'
  instructions            TEXT,
  allowed_attempts        INTEGER DEFAULT 1,
  negative_marking_enabled BOOLEAN DEFAULT false,
  negative_mark_value     NUMERIC(5,2) DEFAULT 0.00,          -- marks to deduct per wrong answer
  grace_period_minutes    INTEGER DEFAULT 0,                    -- extra time after time_limit
  auto_submit             BOOLEAN DEFAULT true,
  randomize_questions     BOOLEAN DEFAULT false,
  randomize_options       BOOLEAN DEFAULT false,
  show_results            VARCHAR(20) DEFAULT 'after_submission',  -- 'immediate', 'after_submission', 'after_grading', 'manual'
  show_correct_answers    BOOLEAN DEFAULT false,
  show_explanations       BOOLEAN DEFAULT false,
  is_template             BOOLEAN DEFAULT false,
  template_id             UUID REFERENCES exams(id) ON DELETE SET NULL,  -- cloned from
  max_students            INTEGER,                              -- null = unlimited
  ip_restriction          TEXT[],                               -- allowed IP ranges, null = no restriction
  require_full_screen     BOOLEAN DEFAULT false,
  allow_resume            BOOLEAN DEFAULT true,
  browser_lockdown        BOOLEAN DEFAULT false,
  metadata                JSONB DEFAULT '{}',
  published_at            TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now(),

  -- Validation constraints
  CONSTRAINT exams_time_range_valid CHECK (end_time > start_time),
  CONSTRAINT exams_time_limit_positive CHECK (time_limit_minutes > 0),
  CONSTRAINT exams_pass_mark_non_negative CHECK (pass_mark >= 0),
  CONSTRAINT exams_total_marks_non_negative CHECK (total_marks >= 0),
  CONSTRAINT exams_negative_mark_non_negative CHECK (negative_mark_value >= 0),
  CONSTRAINT exams_grace_period_non_negative CHECK (grace_period_minutes >= 0),
  CONSTRAINT exams_allowed_attempts_positive CHECK (allowed_attempts > 0),
  CONSTRAINT exams_pass_mark_type_valid CHECK (pass_mark_type IN ('percentage', 'absolute')),
  CONSTRAINT exams_show_results_valid CHECK (show_results IN ('immediate', 'after_submission', 'after_grading', 'manual')),
  CONSTRAINT exams_max_students_positive CHECK (max_students IS NULL OR max_students > 0)
);

COMMENT ON TABLE exams IS 'Core exam definitions with scheduling, configuration, anti-cheating, and result visibility settings';
COMMENT ON COLUMN exams.school_id IS 'The school that owns this exam';
COMMENT ON COLUMN exams.created_by IS 'Teacher or admin who created the exam';
COMMENT ON COLUMN exams.time_limit_minutes IS 'Duration of the exam in minutes';
COMMENT ON COLUMN exams.total_marks IS 'Computed total marks from exam_questions; updated via trigger';
COMMENT ON COLUMN exams.pass_mark IS 'Minimum marks/percentage required to pass';
COMMENT ON COLUMN exams.pass_mark_type IS 'Whether pass_mark is a percentage (0-100) or absolute value';
COMMENT ON COLUMN exams.negative_mark_value IS 'Marks to deduct per wrong answer when negative_marking_enabled is true';
COMMENT ON COLUMN exams.grace_period_minutes IS 'Extra time allowed after time_limit before auto-submit';
COMMENT ON COLUMN exams.show_results IS 'When students can see their results';
COMMENT ON COLUMN exams.is_template IS 'If true, this exam is a reusable template';
COMMENT ON COLUMN exams.template_id IS 'If set, this exam was cloned from the referenced template';
COMMENT ON COLUMN exams.max_students IS 'Maximum concurrent students; null means unlimited';
COMMENT ON COLUMN exams.ip_restriction IS 'Array of allowed IP ranges/CIDRs; null means no restriction';
COMMENT ON COLUMN exams.require_full_screen IS 'Force students into full-screen mode during the exam';
COMMENT ON COLUMN exams.allow_resume IS 'Allow students to resume if disconnected';
COMMENT ON COLUMN exams.browser_lockdown IS 'Enable browser lockdown mode (restricts copy/paste, right-click, etc.)';
COMMENT ON COLUMN exams.metadata IS 'Extensible JSONB for custom configuration and integrations';
COMMENT ON COLUMN exams.published_at IS 'Timestamp when the exam was published; null while in draft';

-- ============================================================================
-- 4. EXAM_SECTIONS TABLE
-- ============================================================================
-- Logical groupings of questions within an exam (e.g., "Section A: Objective",
-- "Section B: Theory"). Each section can have its own time limit and
-- question randomization settings.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_sections (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  instructions          TEXT,               -- section-specific instructions
  sort_order            INTEGER DEFAULT 0,
  time_limit_minutes    INTEGER,            -- null = use exam time limit
  randomize_questions   BOOLEAN DEFAULT false,
  created_at            TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT exam_sections_sort_order_non_negative CHECK (sort_order >= 0),
  CONSTRAINT exam_sections_time_limit_positive CHECK (time_limit_minutes IS NULL OR time_limit_minutes > 0)
);

COMMENT ON TABLE exam_sections IS 'Logical sections within an exam for organizing questions (e.g., Section A, Section B)';
COMMENT ON COLUMN exam_sections.time_limit_minutes IS 'Section-specific time limit; null means use the exam-level time limit';
COMMENT ON COLUMN exam_sections.instructions IS 'Instructions shown to students at the start of this section';
COMMENT ON COLUMN exam_sections.randomize_questions IS 'If true, question order is randomized within this section';

-- ============================================================================
-- 5. EXAM_QUESTIONS TABLE
-- ============================================================================
-- Junction table linking questions from question_bank to an exam (and
-- optionally to a section). Marks can be overridden per-exam.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_questions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  section_id            UUID REFERENCES exam_sections(id) ON DELETE CASCADE,
  question_id           UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  sort_order            INTEGER DEFAULT 0,
  marks                 NUMERIC(5,2) NOT NULL DEFAULT 1.00,   -- can override question default
  negative_marks        NUMERIC(5,2) DEFAULT 0.00,            -- override
  is_compulsory         BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- A question can only appear once per exam
  CONSTRAINT exam_questions_unique_question UNIQUE(exam_id, question_id),
  CONSTRAINT exam_questions_marks_positive CHECK (marks >= 0),
  CONSTRAINT exam_questions_negative_marks_non_negative CHECK (negative_marks >= 0),
  CONSTRAINT exam_questions_sort_order_non_negative CHECK (sort_order >= 0)
);

COMMENT ON TABLE exam_questions IS 'Questions assigned to an exam; marks and negative marks can be overridden per exam';
COMMENT ON COLUMN exam_questions.marks IS 'Marks allocated to this question in this exam; overrides question_bank.marks';
COMMENT ON COLUMN exam_questions.negative_marks IS 'Negative marks for wrong answer; overrides question_bank.negative_marks';
COMMENT ON COLUMN exam_questions.is_compulsory IS 'If true, the student must attempt this question';

-- ============================================================================
-- 6. EXAM_STUDENTS TABLE
-- ============================================================================
-- Eligible / assigned students for an exam. Supports per-student attempt
-- overrides and accommodation (extra time).
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_students (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  allowed_attempts      INTEGER,            -- override exam default; null = use exam default
  extra_time_minutes    INTEGER DEFAULT 0,  -- accommodations (e.g., disability extra time)
  is_exempt             BOOLEAN DEFAULT false,
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- A student can only be assigned once per exam
  CONSTRAINT exam_students_unique_assignment UNIQUE(exam_id, student_id),
  CONSTRAINT exam_students_extra_time_non_negative CHECK (extra_time_minutes >= 0),
  CONSTRAINT exam_students_allowed_attempts_positive CHECK (allowed_attempts IS NULL OR allowed_attempts > 0)
);

COMMENT ON TABLE exam_students IS 'Eligible students for an exam with per-student overrides for attempts and time accommodations';
COMMENT ON COLUMN exam_students.allowed_attempts IS 'Override exam-level allowed_attempts for this student; null = use exam default';
COMMENT ON COLUMN exam_students.extra_time_minutes IS 'Extra time accommodation in minutes (e.g., for students with disabilities)';
COMMENT ON COLUMN exam_students.is_exempt IS 'If true, this student is exempt from the exam';
COMMENT ON COLUMN exam_students.started_at IS 'When the student first started the exam';
COMMENT ON COLUMN exam_students.completed_at IS 'When the student finished all attempts';

-- ============================================================================
-- 7. EXAM_ATTEMPTS TABLE
-- ============================================================================
-- Records each attempt a student makes at an exam. Tracks timing, grading,
-- device info, and auto-save snapshots. Heavily queried for monitoring and
-- result processing.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_attempts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_number        INTEGER NOT NULL DEFAULT 1,
  status                attempt_status NOT NULL DEFAULT 'not_started',
  started_at            TIMESTAMPTZ,
  submitted_at          TIMESTAMPTZ,
  submission_type       submission_type,
  time_spent_seconds    INTEGER DEFAULT 0,
  total_marks           NUMERIC(7,2) DEFAULT 0.00,
  score_percentage      NUMERIC(5,2) DEFAULT 0.00,
  is_passed             BOOLEAN DEFAULT false,
  grading_status        grading_status NOT NULL DEFAULT 'pending',
  graded_by             UUID REFERENCES users(id),
  graded_at             TIMESTAMPTZ,
  device_info           JSONB DEFAULT '{}',
  ip_address            INET,
  user_agent            TEXT,
  last_activity_at      TIMESTAMPTZ,
  auto_save_data        JSONB DEFAULT '{}',   -- latest auto-save snapshot
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- A student can only have one attempt per number per exam
  CONSTRAINT exam_attempts_unique_attempt UNIQUE(exam_id, student_id, attempt_number),
  CONSTRAINT exam_attempts_attempt_number_positive CHECK (attempt_number > 0),
  CONSTRAINT exam_attempts_time_spent_non_negative CHECK (time_spent_seconds >= 0),
  CONSTRAINT exam_attempts_total_marks_non_negative CHECK (total_marks >= 0),
  CONSTRAINT exam_attempts_score_percentage_range CHECK (score_percentage >= 0 AND score_percentage <= 100)
);

COMMENT ON TABLE exam_attempts IS 'Student exam attempts with timing, grading, auto-save, and monitoring data';
COMMENT ON COLUMN exam_attempts.attempt_number IS 'Attempt number (1-based); students may have multiple attempts if allowed';
COMMENT ON COLUMN exam_attempts.submission_type IS 'How the attempt was submitted: manual, auto_submit, timed_out, force_submit';
COMMENT ON COLUMN exam_attempts.time_spent_seconds IS 'Total time spent on this attempt in seconds';
COMMENT ON COLUMN exam_attempts.total_marks IS 'Computed total marks for this attempt';
COMMENT ON COLUMN exam_attempts.score_percentage IS 'Score as a percentage of total possible marks';
COMMENT ON COLUMN exam_attempts.is_passed IS 'Whether the student passed based on the exam pass_mark';
COMMENT ON COLUMN exam_attempts.grading_status IS 'Current grading status: pending → auto_graded → fully_graded';
COMMENT ON COLUMN exam_attempts.device_info IS 'JSONB with device details: browser, OS, screen resolution, etc.';
COMMENT ON COLUMN exam_attempts.auto_save_data IS 'Latest auto-save snapshot of student answers for recovery';
COMMENT ON COLUMN exam_attempts.last_activity_at IS 'Last recorded student activity timestamp (for idle detection)';

-- ============================================================================
-- 8. STUDENT_ANSWERS TABLE
-- ============================================================================
-- Individual question answers within an attempt. Uses flexible JSONB for
-- answer_data to support all question types (MCQ, matching, ordering, etc.).
-- ============================================================================

CREATE TABLE IF NOT EXISTS student_answers (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id            UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  question_id           UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  exam_question_id      UUID REFERENCES exam_questions(id),
  answer_data           JSONB NOT NULL DEFAULT '{}',  -- flexible answer storage
  is_correct            BOOLEAN,
  marks_awarded         NUMERIC(5,2) DEFAULT 0.00,
  marks_deducted        NUMERIC(5,2) DEFAULT 0.00,
  time_spent_seconds    INTEGER DEFAULT 0,
  is_flagged            BOOLEAN DEFAULT false,
  teacher_comment       TEXT,
  graded_by             UUID REFERENCES users(id),
  graded_at             TIMESTAMPTZ,
  answered_at           TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- A question can only be answered once per attempt
  CONSTRAINT student_answers_unique_answer UNIQUE(attempt_id, question_id),
  CONSTRAINT student_answers_marks_awarded_non_negative CHECK (marks_awarded >= 0),
  CONSTRAINT student_answers_marks_deducted_non_negative CHECK (marks_deducted >= 0),
  CONSTRAINT student_answers_time_spent_non_negative CHECK (time_spent_seconds >= 0)
);

COMMENT ON TABLE student_answers IS 'Individual question answers within an exam attempt with flexible JSONB answer storage';
COMMENT ON COLUMN student_answers.answer_data IS
  'Flexible answer payload: selected_options (MCQ/MR), text_answer (essay/short), matching_pairs, ordered_items, blank_answers, numerical_answer';
COMMENT ON COLUMN student_answers.exam_question_id IS 'Link back to the exam_questions entry for marks/negative_marks lookup';
COMMENT ON COLUMN student_answers.is_correct IS 'Whether the answer is correct; null for subjective questions until graded';
COMMENT ON COLUMN student_answers.marks_awarded IS 'Marks given for this answer (may be partial for subjective questions)';
COMMENT ON COLUMN student_answers.marks_deducted IS 'Marks deducted for wrong answer (negative marking)';
COMMENT ON COLUMN student_answers.is_flagged IS 'Whether the student flagged this question for review';
COMMENT ON COLUMN student_answers.teacher_comment IS 'Teacher comment/feedback on the answer';

-- ============================================================================
-- 9. EXAM_SESSIONS TABLE (REALTIME - for live monitoring)
-- ============================================================================
-- Active session tracking for live monitoring via Supabase Realtime.
-- Teachers can observe student progress in real-time. This table is added
-- to the supabase_realtime publication for live updates.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_sessions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id              UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  exam_id                 UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_active               BOOLEAN DEFAULT true,
  current_question_index  INTEGER DEFAULT 0,
  questions_answered      INTEGER DEFAULT 0,
  questions_flagged       INTEGER DEFAULT 0,
  last_heartbeat          TIMESTAMPTZ DEFAULT now(),
  connection_status       VARCHAR(20) DEFAULT 'connected',  -- 'connected', 'disconnected', 'reconnecting'
  ip_address              INET,
  device_fingerprint      TEXT,
  tab_switch_count        INTEGER DEFAULT 0,
  focus_lost_count        INTEGER DEFAULT 0,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT exam_sessions_connection_status_valid CHECK (connection_status IN ('connected', 'disconnected', 'reconnecting')),
  CONSTRAINT exam_sessions_current_question_non_negative CHECK (current_question_index >= 0),
  CONSTRAINT exam_sessions_questions_answered_non_negative CHECK (questions_answered >= 0),
  CONSTRAINT exam_sessions_questions_flagged_non_negative CHECK (questions_flagged >= 0),
  CONSTRAINT exam_sessions_tab_switch_count_non_negative CHECK (tab_switch_count >= 0),
  CONSTRAINT exam_sessions_focus_lost_count_non_negative CHECK (focus_lost_count >= 0)
);

COMMENT ON TABLE exam_sessions IS 'REALTIME: Active exam sessions for live monitoring of student progress and connection status';
COMMENT ON COLUMN exam_sessions.is_active IS 'Whether the session is currently active';
COMMENT ON COLUMN exam_sessions.current_question_index IS 'The question the student is currently viewing (0-based index)';
COMMENT ON COLUMN exam_sessions.questions_answered IS 'Count of questions answered so far in this session';
COMMENT ON COLUMN exam_sessions.questions_flagged IS 'Count of questions flagged for review';
COMMENT ON COLUMN exam_sessions.last_heartbeat IS 'Last heartbeat timestamp; stale sessions are cleaned up by cleanup_stale_sessions()';
COMMENT ON COLUMN exam_sessions.connection_status IS 'Current connection state: connected, disconnected, reconnecting';
COMMENT ON COLUMN exam_sessions.device_fingerprint IS 'Browser/device fingerprint for anti-cheating detection';
COMMENT ON COLUMN exam_sessions.tab_switch_count IS 'Number of tab switches detected during this session';
COMMENT ON COLUMN exam_sessions.focus_lost_count IS 'Number of focus-loss events detected during this session';

-- ============================================================================
-- 10. EXAM_MONITORING_LOGS TABLE
-- ============================================================================
-- Detailed anti-cheating / proctoring event logs. Each monitoring event
-- (tab switch, copy attempt, etc.) is recorded with severity and resolution
-- status for teacher review.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_monitoring_logs (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id            UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type            monitoring_event_type NOT NULL,
  event_data            JSONB DEFAULT '{}',
  severity              VARCHAR(10) DEFAULT 'info',   -- 'info', 'warning', 'critical'
  is_resolved           BOOLEAN DEFAULT false,
  resolved_by           UUID REFERENCES users(id),
  resolved_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT exam_monitoring_logs_severity_valid CHECK (severity IN ('info', 'warning', 'critical'))
);

COMMENT ON TABLE exam_monitoring_logs IS 'Anti-cheating / proctoring event logs for student exam attempts';
COMMENT ON COLUMN exam_monitoring_logs.event_type IS 'Type of monitoring event detected';
COMMENT ON COLUMN exam_monitoring_logs.event_data IS 'Additional event details (e.g., tab URL, clipboard content hash, timestamp)';
COMMENT ON COLUMN exam_monitoring_logs.severity IS 'Event severity: info (benign), warning (suspicious), critical (likely cheating)';
COMMENT ON COLUMN exam_monitoring_logs.is_resolved IS 'Whether a teacher/admin has reviewed and resolved this event';
COMMENT ON COLUMN exam_monitoring_logs.resolved_by IS 'Teacher/admin who resolved this event';

-- ============================================================================
-- 11. EXAM_RESULTS TABLE
-- ============================================================================
-- Processed results for each exam attempt. Created automatically when an
-- attempt is submitted. Contains total marks, grade, rank, and release status.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_results (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_id            UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  total_marks           NUMERIC(7,2) NOT NULL DEFAULT 0.00,
  total_possible        NUMERIC(7,2) NOT NULL DEFAULT 0.00,
  score_percentage      NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  grade                 VARCHAR(5),                   -- A, B, C, D, E, F
  is_passed             BOOLEAN NOT NULL DEFAULT false,
  rank                  INTEGER,                      -- if rankings enabled
  subject_average       NUMERIC(5,2),                 -- class average
  time_spent_seconds    INTEGER DEFAULT 0,
  grading_status        grading_status NOT NULL DEFAULT 'pending',
  released_at           TIMESTAMPTZ,
  is_released           BOOLEAN DEFAULT false,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- One result per attempt per student per exam
  CONSTRAINT exam_results_unique_result UNIQUE(exam_id, student_id, attempt_id),
  CONSTRAINT exam_results_total_marks_non_negative CHECK (total_marks >= 0),
  CONSTRAINT exam_results_total_possible_non_negative CHECK (total_possible >= 0),
  CONSTRAINT exam_results_score_percentage_range CHECK (score_percentage >= 0 AND score_percentage <= 100),
  CONSTRAINT exam_results_subject_average_range CHECK (subject_average IS NULL OR (subject_average >= 0 AND subject_average <= 100)),
  CONSTRAINT exam_results_time_spent_non_negative CHECK (time_spent_seconds >= 0)
);

COMMENT ON TABLE exam_results IS 'Processed exam results with grades, rankings, and release status';
COMMENT ON COLUMN exam_results.total_marks IS 'Total marks scored by the student';
COMMENT ON COLUMN exam_results.total_possible IS 'Total possible marks for the exam';
COMMENT ON COLUMN exam_results.score_percentage IS 'Score as percentage of total possible';
COMMENT ON COLUMN exam_results.grade IS 'Letter grade (A-F) based on the grade scale';
COMMENT ON COLUMN exam_results.is_passed IS 'Whether the student passed based on the exam pass_mark';
COMMENT ON COLUMN exam_results.rank IS 'Student rank among all exam takers; null if rankings not computed yet';
COMMENT ON COLUMN exam_results.subject_average IS 'Class/subject average score percentage for comparison';
COMMENT ON COLUMN exam_results.grading_status IS 'Grading status for this result';
COMMENT ON COLUMN exam_results.is_released IS 'Whether the result is visible to the student';
COMMENT ON COLUMN exam_results.released_at IS 'When the result was released to the student';

-- ============================================================================
-- 12. EXAM_RANKINGS TABLE
-- ============================================================================
-- Pre-computed rankings for an exam. Calculated by the calculate_rankings()
-- function and stored for efficient retrieval.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_rankings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_id            UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  rank                  INTEGER NOT NULL,
  total_marks           NUMERIC(7,2) NOT NULL,
  score_percentage      NUMERIC(5,2) NOT NULL,
  created_at            TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT exam_rankings_unique_ranking UNIQUE(exam_id, student_id, attempt_id),
  CONSTRAINT exam_rankings_rank_positive CHECK (rank > 0),
  CONSTRAINT exam_rankings_total_marks_non_negative CHECK (total_marks >= 0),
  CONSTRAINT exam_rankings_score_percentage_range CHECK (score_percentage >= 0 AND score_percentage <= 100)
);

COMMENT ON TABLE exam_rankings IS 'Pre-computed exam rankings for efficient leaderboard and result display';
COMMENT ON COLUMN exam_rankings.rank IS 'Student rank (1 = highest score)';

-- ============================================================================
-- 13. EXAM_NOTIFICATIONS TABLE
-- ============================================================================
-- CBT-specific notifications for exam lifecycle events (exam available,
-- time warnings, results released, etc.). Separate from the general
-- notifications table to support CBT-specific categorization and scheduling.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exam_notifications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID REFERENCES exams(id) ON DELETE CASCADE,
  student_id            UUID REFERENCES users(id) ON DELETE CASCADE,
  category              notification_category NOT NULL,
  title                 TEXT NOT NULL,
  message               TEXT NOT NULL,
  data                  JSONB DEFAULT '{}',
  is_read               BOOLEAN DEFAULT false,
  read_at               TIMESTAMPTZ,
  scheduled_for         TIMESTAMPTZ,         -- for scheduled notifications
  sent_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE exam_notifications IS 'CBT-specific notifications for exam lifecycle events';
COMMENT ON COLUMN exam_notifications.category IS 'Notification category: exam_available, exam_starting, time_warning, etc.';
COMMENT ON COLUMN exam_notifications.scheduled_for IS 'When the notification should be sent (for future scheduling)';
COMMENT ON COLUMN exam_notifications.sent_at IS 'When the notification was actually sent';
COMMENT ON COLUMN exam_notifications.data IS 'Structured payload (e.g., exam_id, time_remaining, result summary)';

-- ============================================================================
-- 14. GRADE_SCALES TABLE
-- ============================================================================
-- Configurable grading scales (e.g., WAEC Scale, Custom Scale). Each scale
-- has a JSONB array of scale entries defining grade boundaries.
-- ============================================================================

CREATE TABLE IF NOT EXISTS grade_scales (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID REFERENCES schools(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,                          -- e.g., "WAEC Scale", "Custom Scale"
  is_default            BOOLEAN DEFAULT false,
  scale_entries         JSONB NOT NULL,                         -- array of {min_percentage, max_percentage, grade, description, is_passing}
  created_by            UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate scale_entries is a non-empty JSON array
  CONSTRAINT grade_scales_scale_entries_is_array CHECK (jsonb_typeof(scale_entries) = 'array'),
  CONSTRAINT grade_scales_name_not_empty CHECK (length(trim(name)) > 0)
);

COMMENT ON TABLE grade_scales IS 'Configurable grading scales with grade boundaries stored as JSONB';
COMMENT ON COLUMN grade_scales.name IS 'Scale name, e.g., "WAEC Scale", "Custom Scale"';
COMMENT ON COLUMN grade_scales.is_default IS 'If true, this is the default scale for the school';
COMMENT ON COLUMN grade_scales.scale_entries IS
  'JSON array of grade boundaries: [{"min_percentage": 70, "max_percentage": 100, "grade": "A", "description": "Excellent", "is_passing": true}, ...]';
COMMENT ON COLUMN grade_scales.created_by IS 'Teacher/admin who created this grade scale';

-- ============================================================================
-- 15. INDEXES
-- ============================================================================
-- Comprehensive indexing strategy for high-performance queries.
-- Single-column indexes for FK joins and lookups.
-- Composite indexes for common query patterns.
-- GIN indexes for JSONB and array columns.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- exams indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exams_school_id ON exams(school_id);
CREATE INDEX IF NOT EXISTS idx_exams_created_by ON exams(created_by);
CREATE INDEX IF NOT EXISTS idx_exams_subject_id ON exams(subject_id);
CREATE INDEX IF NOT EXISTS idx_exams_class_id ON exams(class_id);
CREATE INDEX IF NOT EXISTS idx_exams_status ON exams(status);
CREATE INDEX IF NOT EXISTS idx_exams_exam_type ON exams(exam_type);
CREATE INDEX IF NOT EXISTS idx_exams_start_time ON exams(start_time);
CREATE INDEX IF NOT EXISTS idx_exams_end_time ON exams(end_time);
-- Composite indexes for common filter patterns
CREATE INDEX IF NOT EXISTS idx_exams_school_status ON exams(school_id, status);
CREATE INDEX IF NOT EXISTS idx_exams_school_start_time ON exams(school_id, start_time);
-- Partial index for active exams (high-frequency monitoring query)
CREATE INDEX IF NOT EXISTS idx_exams_active ON exams(start_time, end_time) WHERE status = 'active';
-- GIN index for metadata JSONB
CREATE INDEX IF NOT EXISTS idx_exams_metadata_gin ON exams USING gin(metadata);
-- GIN index for IP restriction array
CREATE INDEX IF NOT EXISTS idx_exams_ip_restriction_gin ON exams USING gin(ip_restriction) WHERE ip_restriction IS NOT NULL;

-- ---------------------------------------------------------------------------
-- exam_sections indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_sections_exam_id ON exam_sections(exam_id);

-- ---------------------------------------------------------------------------
-- exam_questions indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_questions_exam_id ON exam_questions(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_questions_question_id ON exam_questions(question_id);
CREATE INDEX IF NOT EXISTS idx_exam_questions_section_id ON exam_questions(section_id);
-- Composite: questions by exam ordered by sort_order (for question list retrieval)
CREATE INDEX IF NOT EXISTS idx_exam_questions_exam_sort ON exam_questions(exam_id, sort_order);

-- ---------------------------------------------------------------------------
-- exam_students indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_students_exam_id ON exam_students(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_students_student_id ON exam_students(student_id);

-- ---------------------------------------------------------------------------
-- exam_attempts indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_attempts_exam_id ON exam_attempts(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_student_id ON exam_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_status ON exam_attempts(status);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_started_at ON exam_attempts(started_at);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_submitted_at ON exam_attempts(submitted_at);
-- Composite indexes for common filter patterns
CREATE INDEX IF NOT EXISTS idx_exam_attempts_exam_status ON exam_attempts(exam_id, status);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_student_status ON exam_attempts(student_id, status);

-- ---------------------------------------------------------------------------
-- student_answers indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_student_answers_attempt_id ON student_answers(attempt_id);
CREATE INDEX IF NOT EXISTS idx_student_answers_question_id ON student_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_student_answers_is_correct ON student_answers(is_correct);
-- Composite: correct/incorrect breakdown per attempt (for grading analytics)
CREATE INDEX IF NOT EXISTS idx_student_answers_attempt_correct ON student_answers(attempt_id, is_correct);
-- GIN index for flexible answer_data JSONB
CREATE INDEX IF NOT EXISTS idx_student_answers_answer_data_gin ON student_answers USING gin(answer_data);

-- ---------------------------------------------------------------------------
-- exam_sessions indexes (REALTIME - critical for live monitoring)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_sessions_exam_id ON exam_sessions(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_sessions_is_active ON exam_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_exam_sessions_last_heartbeat ON exam_sessions(last_heartbeat);
-- Composite: active sessions per exam (primary monitoring query)
CREATE INDEX IF NOT EXISTS idx_exam_sessions_exam_active ON exam_sessions(exam_id, is_active);
-- Composite: find stale sessions
CREATE INDEX IF NOT EXISTS idx_exam_sessions_active_heartbeat ON exam_sessions(is_active, last_heartbeat) WHERE is_active = true;
-- Index on student_id for student session lookup
CREATE INDEX IF NOT EXISTS idx_exam_sessions_student_id ON exam_sessions(student_id);

-- ---------------------------------------------------------------------------
-- exam_monitoring_logs indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_exam_id ON exam_monitoring_logs(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_student_id ON exam_monitoring_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_event_type ON exam_monitoring_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_severity ON exam_monitoring_logs(severity);
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_created_at ON exam_monitoring_logs(created_at);
-- Composite: unresolved critical events for an exam (teacher dashboard)
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_exam_unresolved
  ON exam_monitoring_logs(exam_id, severity, is_resolved)
  WHERE is_resolved = false;
-- GIN index for event_data JSONB
CREATE INDEX IF NOT EXISTS idx_exam_monitoring_logs_event_data_gin ON exam_monitoring_logs USING gin(event_data);

-- ---------------------------------------------------------------------------
-- exam_results indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_id ON exam_results(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_student_id ON exam_results(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_is_released ON exam_results(is_released);
CREATE INDEX IF NOT EXISTS idx_exam_results_is_passed ON exam_results(is_passed);
-- Composite: released results per exam (student dashboard)
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_released ON exam_results(exam_id, is_released);
-- Composite: leaderboard / ranking by score (DESC for top-scores-first queries)
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_score_desc ON exam_results(exam_id, score_percentage DESC);

-- ---------------------------------------------------------------------------
-- exam_rankings indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_rankings_exam_id ON exam_rankings(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_rankings_rank ON exam_rankings(rank);
-- Composite: leaderboard retrieval by exam (rank order)
CREATE INDEX IF NOT EXISTS idx_exam_rankings_exam_rank ON exam_rankings(exam_id, rank);

-- ---------------------------------------------------------------------------
-- exam_notifications indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_exam_notifications_student_id ON exam_notifications(student_id);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_is_read ON exam_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_category ON exam_notifications(category);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_scheduled_for ON exam_notifications(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_exam_notifications_exam_id ON exam_notifications(exam_id);
-- Composite: unread notifications per student (notification bell count)
CREATE INDEX IF NOT EXISTS idx_exam_notifications_student_unread ON exam_notifications(student_id, is_read) WHERE is_read = false;

-- ---------------------------------------------------------------------------
-- grade_scales indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_grade_scales_school_id ON grade_scales(school_id);
CREATE INDEX IF NOT EXISTS idx_grade_scales_is_default ON grade_scales(is_default) WHERE is_default = true;

-- ============================================================================
-- 16. SUPABASE REALTIME SETUP
-- ============================================================================
-- Enable Realtime on critical tables for live monitoring and updates.
-- exam_sessions: live student progress monitoring
-- exam_attempts: real-time attempt status updates
-- exam_monitoring_logs: real-time anti-cheating alerts
-- ============================================================================

-- Add tables to the supabase_realtime publication for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE exam_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE exam_attempts;
ALTER PUBLICATION supabase_realtime ADD TABLE exam_monitoring_logs;

-- ============================================================================
-- 17. FUNCTIONS
-- ============================================================================
-- Production-ready PL/pgSQL functions for the CBT Engine.
-- All functions use SECURITY DEFINER where elevated access is needed.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- check_exam_access(exam_id, student_id)
-- Check if a student can access/start an exam.
-- Returns TRUE if: exam is active, student is assigned, not exempt,
-- attempts not exhausted, within time window, and not disqualified.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_exam_access(
  p_exam_id    UUID,
  p_student_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_exam              exams%ROWTYPE;
  v_student_record    exam_students%ROWTYPE;
  v_attempt_count     INTEGER;
BEGIN
  -- Fetch the exam
  SELECT * INTO v_exam FROM exams WHERE id = p_exam_id;
  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Exam must be in 'published' or 'active' status
  IF v_exam.status NOT IN ('published', 'active') THEN
    RETURN false;
  END IF;

  -- Current time must be within the exam window (including grace period)
  IF now() < v_exam.start_time OR now() > v_exam.end_time + (v_exam.grace_period_minutes || ' minutes')::INTERVAL THEN
    RETURN false;
  END IF;

  -- Check student is assigned and not exempt
  SELECT * INTO v_student_record
  FROM exam_students
  WHERE exam_id = p_exam_id AND student_id = p_student_id;
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  IF v_student_record.is_exempt THEN
    RETURN false;
  END IF;

  -- Check attempt limit
  SELECT COUNT(*) INTO v_attempt_count
  FROM exam_attempts
  WHERE exam_id = p_exam_id
    AND student_id = p_student_id
    AND status NOT IN ('disqualified', 'abandoned');

  IF v_attempt_count >= COALESCE(v_student_record.allowed_attempts, v_exam.allowed_attempts) THEN
    RETURN false;
  END IF;

  -- Check max_students limit
  IF v_exam.max_students IS NOT NULL THEN
    IF (
      SELECT COUNT(DISTINCT student_id) FROM exam_sessions
      WHERE exam_id = p_exam_id AND is_active = true
    ) >= v_exam.max_students THEN
      RETURN false;
    END IF;
  END IF;

  RETURN true;
END;
$$;

COMMENT ON FUNCTION check_exam_access(UUID, UUID) IS
  'Check if a student can access/start an exam based on status, time window, assignment, and attempt limits';

-- ---------------------------------------------------------------------------
-- start_exam_attempt(p_exam_id, p_student_id)
-- Creates a new exam attempt and active session for a student.
-- Returns the attempt_id.
-- Validates access, calculates attempt_number, and initializes session.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION start_exam_attempt(
  p_exam_id    UUID,
  p_student_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_attempt_id        UUID;
  v_session_id        UUID;
  v_attempt_number    INTEGER;
  v_exam              exams%ROWTYPE;
  v_student_record    exam_students%ROWTYPE;
  v_effective_time_limit INTEGER;
BEGIN
  -- Validate access first
  IF NOT check_exam_access(p_exam_id, p_student_id) THEN
    RAISE EXCEPTION 'Student cannot access this exam. Check assignment, time window, and attempt limits.';
  END USING HINT = 'Use check_exam_access() to diagnose the reason';

  -- Fetch exam details
  SELECT * INTO v_exam FROM exams WHERE id = p_exam_id;

  -- Fetch student record for accommodations
  SELECT * INTO v_student_record
  FROM exam_students
  WHERE exam_id = p_exam_id AND student_id = p_student_id;

  -- Determine next attempt number
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt_number
  FROM exam_attempts
  WHERE exam_id = p_exam_id AND student_id = p_student_id;

  -- Create the attempt
  INSERT INTO exam_attempts (
    exam_id, student_id, attempt_number,
    status, started_at, last_activity_at
  ) VALUES (
    p_exam_id, p_student_id, v_attempt_number,
    'in_progress', now(), now()
  )
  RETURNING id INTO v_attempt_id;

  -- Create the active session for real-time monitoring
  INSERT INTO exam_sessions (
    attempt_id, exam_id, student_id,
    is_active, last_heartbeat, connection_status
  ) VALUES (
    v_attempt_id, p_exam_id, p_student_id,
    true, now(), 'connected'
  )
  RETURNING id INTO v_session_id;

  -- Update exam_students started_at if first attempt
  UPDATE exam_students
  SET started_at = COALESCE(started_at, now())
  WHERE exam_id = p_exam_id
    AND student_id = p_student_id
    AND started_at IS NULL;

  RETURN v_attempt_id;
END;
$$;

COMMENT ON FUNCTION start_exam_attempt(UUID, UUID) IS
  'Start a new exam attempt for a student: validates access, creates attempt + session, returns attempt_id';

-- ---------------------------------------------------------------------------
-- auto_grade_attempt(p_attempt_id)
-- Auto-grades objective questions (MCQ, true/false, fill_in_blank, matching,
-- ordering, numerical, multiple_response) for a given attempt.
-- Returns the computed total marks.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_grade_attempt(p_attempt_id UUID)
RETURNS NUMERIC(7,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exam_id           UUID;
  v_total_marks       NUMERIC(7,2) := 0.00;
  v_total_possible    NUMERIC(7,2) := 0.00;
  v_negative_total    NUMERIC(7,2) := 0.00;
  v_exam_record       exams%ROWTYPE;
  v_answer_record     RECORD;
  v_is_correct        BOOLEAN;
  v_marks_awarded     NUMERIC(5,2);
  v_marks_deducted    NUMERIC(5,2);
  v_question_type_val question_type;
  v_question_marks    NUMERIC(5,2);
  v_question_neg      NUMERIC(5,2);
  v_has_subjective    BOOLEAN := false;
  v_auto_graded_count INTEGER := 0;
  v_total_count       INTEGER := 0;
BEGIN
  -- Get the attempt and exam details
  SELECT ea.exam_id INTO v_exam_id
  FROM exam_attempts ea
  WHERE ea.id = p_attempt_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attempt not found: %', p_attempt_id;
  END IF;

  SELECT * INTO v_exam_record FROM exams WHERE id = v_exam_id;

  -- Process each student answer
  FOR v_answer_record IN
    SELECT
      sa.id            AS answer_id,
      sa.question_id   AS question_id,
      sa.answer_data   AS answer_data,
      sa.exam_question_id,
      qb.question_type AS question_type,
      eq.marks         AS exam_marks,
      eq.negative_marks AS exam_neg_marks,
      eq.is_compulsory,
      qb.marks         AS default_marks,
      qb.negative_marks AS default_neg_marks
    FROM student_answers sa
    JOIN question_bank qb ON qb.id = sa.question_id
    LEFT JOIN exam_questions eq ON eq.id = sa.exam_question_id
    WHERE sa.attempt_id = p_attempt_id
  LOOP
    v_total_count := v_total_count + 1;

    -- Determine effective marks for this question
    v_question_marks := COALESCE(v_answer_record.exam_marks, v_answer_record.default_marks, 1.00);
    v_question_neg   := COALESCE(v_answer_record.exam_neg_marks, v_answer_record.default_neg_marks, 0.00);
    v_question_type_val := v_answer_record.question_type;

    v_total_possible := v_total_possible + v_question_marks;

    -- Auto-grade based on question type
    v_is_correct := NULL;
    v_marks_awarded := 0.00;
    v_marks_deducted := 0.00;

    CASE v_question_type_val
      -- Objective types that can be auto-graded
      WHEN 'multiple_choice' THEN
        BEGIN
          -- Check if selected option matches any correct option
          SELECT EXISTS (
            SELECT 1 FROM answer_options ao
            WHERE ao.question_id = v_answer_record.question_id
              AND ao.is_correct = true
              AND ao.id::text = (v_answer_record.answer_data->>'selected_option')::text
          ) INTO v_is_correct;

          IF v_is_correct THEN
            v_marks_awarded := v_question_marks;
          ELSE
            IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
              v_marks_deducted := v_question_neg;
            END IF;
          END IF;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'true_false' THEN
        BEGIN
          SELECT EXISTS (
            SELECT 1 FROM answer_options ao
            WHERE ao.question_id = v_answer_record.question_id
              AND ao.is_correct = true
              AND ao.id::text = (v_answer_record.answer_data->>'selected_option')::text
          ) INTO v_is_correct;

          IF v_is_correct THEN
            v_marks_awarded := v_question_marks;
          ELSE
            IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
              v_marks_deducted := v_question_neg;
            END IF;
          END IF;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'multiple_response' THEN
        BEGIN
          -- All correct options selected and no incorrect options
          v_is_correct := true;

          -- Check all selected options are correct
          IF jsonb_typeof(v_answer_record.answer_data->'selected_options') = 'array' THEN
            DECLARE
              sel_option TEXT;
              all_correct BOOLEAN := true;
              correct_count INTEGER := 0;
              selected_count INTEGER := 0;
            BEGIN
              -- Count correct options
              SELECT COUNT(*) INTO correct_count
              FROM answer_options
              WHERE question_id = v_answer_record.question_id AND is_correct = true;

              -- Count selected options
              SELECT jsonb_array_length(v_answer_record.answer_data->'selected_options') INTO selected_count;

              IF selected_count <> correct_count THEN
                all_correct := false;
              ELSE
                -- Verify each selected option is correct
                FOR sel_option IN
                  SELECT jsonb_array_elements_text(v_answer_record.answer_data->'selected_options')
                LOOP
                  IF NOT EXISTS (
                    SELECT 1 FROM answer_options
                    WHERE question_id = v_answer_record.question_id
                      AND is_correct = true
                      AND id::text = sel_option
                  ) THEN
                    all_correct := false;
                    EXIT;
                  END IF;
                END LOOP;
              END IF;

              v_is_correct := all_correct;
            END;
          ELSE
            v_is_correct := false;
          END IF;

          IF v_is_correct THEN
            v_marks_awarded := v_question_marks;
          ELSE
            IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
              v_marks_deducted := v_question_neg;
            END IF;
          END IF;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'fill_in_blank' THEN
        BEGIN
          -- Compare blank answers (case-insensitive, trimmed)
          DECLARE
            blank_key TEXT;
            blank_answer TEXT;
            correct_answer TEXT;
            all_blanks_correct BOOLEAN := true;
          BEGIN
            IF v_answer_record.answer_data->>'has_blanks' IS NOT NULL OR
               jsonb_typeof(v_answer_record.answer_data->'blank_answers') = 'object' THEN
              FOR blank_key, correct_answer IN
                SELECT key, value->>0 AS val
                FROM jsonb_each(
                  (SELECT ao.content_json FROM answer_options ao
                   WHERE ao.question_id = v_answer_record.question_id
                   LIMIT 1)
                )
              LOOP
                blank_answer := lower(trim(COALESCE(
                  v_answer_record.answer_data->'blank_answers'->>blank_key, '')));
                correct_answer := lower(trim(COALESCE(correct_answer, '')));
                IF blank_answer IS DISTINCT FROM correct_answer THEN
                  all_blanks_correct := false;
                  EXIT;
                END IF;
              END LOOP;
              v_is_correct := all_blanks_correct;
            ELSE
              v_is_correct := false;
            END IF;

            IF v_is_correct THEN
              v_marks_awarded := v_question_marks;
            ELSE
              IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
                v_marks_deducted := v_question_neg;
              END IF;
            END IF;
          END;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'matching' THEN
        BEGIN
          -- Verify matching pairs
          DECLARE
            all_pairs_correct BOOLEAN := true;
            pair_key TEXT;
            pair_value TEXT;
          BEGIN
            IF jsonb_typeof(v_answer_record.answer_data->'matching_pairs') = 'object' THEN
              FOR pair_key, pair_value IN
                SELECT key, value
                FROM jsonb_each(v_answer_record.answer_data->'matching_pairs')
              LOOP
                IF NOT EXISTS (
                  SELECT 1 FROM matching_pairs mp
                  WHERE mp.question_id = v_answer_record.question_id
                    AND mp.left_item_id::text = pair_key
                    AND mp.right_item_id::text = pair_value
                ) THEN
                  all_pairs_correct := false;
                  EXIT;
                END IF;
              END LOOP;
              v_is_correct := all_pairs_correct;
            ELSE
              v_is_correct := false;
            END IF;

            IF v_is_correct THEN
              v_marks_awarded := v_question_marks;
            ELSE
              IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
                v_marks_deducted := v_question_neg;
              END IF;
            END IF;
          END;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'ordering' THEN
        BEGIN
          -- Verify order of items
          DECLARE
            all_ordered_correct BOOLEAN := true;
            idx INTEGER := 0;
            item_id TEXT;
          BEGIN
            IF jsonb_typeof(v_answer_record.answer_data->'ordered_items') = 'array' THEN
              FOR item_id IN
                SELECT jsonb_array_elements_text(v_answer_record.answer_data->'ordered_items')
              LOOP
                IF NOT EXISTS (
                  SELECT 1 FROM ordering_items oi
                  WHERE oi.question_id = v_answer_record.question_id
                    AND oi.id::text = item_id
                    AND oi.sort_order = idx
                ) THEN
                  all_ordered_correct := false;
                  EXIT;
                END IF;
                idx := idx + 1;
              END LOOP;
              v_is_correct := all_ordered_correct;
            ELSE
              v_is_correct := false;
            END IF;

            IF v_is_correct THEN
              v_marks_awarded := v_question_marks;
            ELSE
              IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
                v_marks_deducted := v_question_neg;
              END IF;
            END IF;
          END;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      WHEN 'numerical' THEN
        BEGIN
          -- Compare numerical answer with tolerance
          DECLARE
            student_num NUMERIC;
            correct_num NUMERIC;
            tolerance NUMERIC := 0.01;  -- 1% tolerance
          BEGIN
            student_num := (v_answer_record.answer_data->>'numerical_answer')::NUMERIC;
            -- Get correct answer from content_json or answer_options
            correct_num := (
              SELECT (content_json->>'numerical_answer')::NUMERIC
              FROM question_bank
              WHERE id = v_answer_record.question_id
            );

            IF student_num IS NOT NULL AND correct_num IS NOT NULL THEN
              IF correct_num = 0 THEN
                v_is_correct := (student_num = 0);
              ELSE
                v_is_correct := (ABS(student_num - correct_num) <= ABS(correct_num * tolerance));
              END IF;
            ELSE
              v_is_correct := false;
            END IF;

            IF v_is_correct THEN
              v_marks_awarded := v_question_marks;
            ELSE
              IF v_exam_record.negative_marking_enabled AND v_question_neg > 0 THEN
                v_marks_deducted := v_question_neg;
              END IF;
            END IF;
          EXCEPTION WHEN OTHERS THEN
            v_is_correct := false;
          END;
          v_auto_graded_count := v_auto_graded_count + 1;
        END;

      -- Subjective types that require manual grading
      WHEN 'short_answer', 'essay', 'case_study', 'practical',
           'image_based', 'audio_based', 'video_based' THEN
        BEGIN
          v_is_correct := NULL;  -- requires manual grading
          v_marks_awarded := 0.00;
          v_marks_deducted := 0.00;
          v_has_subjective := true;
        END;

      ELSE
        BEGIN
          v_is_correct := NULL;
          v_has_subjective := true;
        END;
    END CASE;

    -- Update the student answer
    UPDATE student_answers
    SET
      is_correct      = v_is_correct,
      marks_awarded   = v_marks_awarded,
      marks_deducted  = v_marks_deducted,
      graded_at       = CASE WHEN v_is_correct IS NOT NULL THEN now() ELSE NULL END
    WHERE id = v_answer_record.answer_id;

    -- Accumulate totals (only for graded answers)
    IF v_is_correct IS NOT NULL THEN
      v_total_marks := v_total_marks + v_marks_awarded - v_marks_deducted;
    END IF;
  END LOOP;

  -- Also add marks for questions not yet answered (no student_answers record)
  -- These get 0 marks (already default), but we need to count them in total_possible
  SELECT COALESCE(SUM(eq.marks), 0) INTO v_total_possible
  FROM exam_questions eq
  WHERE eq.exam_id = v_exam_id;

  -- Ensure total marks is not negative
  IF v_total_marks < 0 THEN
    v_total_marks := 0;
  END IF;

  -- Update the attempt
  UPDATE exam_attempts
  SET
    total_marks      = v_total_marks,
    score_percentage = CASE
                        WHEN v_total_possible > 0
                        THEN ROUND((v_total_marks / v_total_possible) * 100, 2)
                        ELSE 0.00
                      END,
    grading_status   = CASE
                        WHEN v_has_subjective AND v_auto_graded_count = v_total_count THEN
                          'partially_graded'
                        WHEN v_has_subjective THEN
                          'partially_graded'
                        WHEN v_auto_graded_count = v_total_count AND NOT v_has_subjective THEN
                          'auto_graded'
                        ELSE
                          'pending'
                      END
  WHERE id = p_attempt_id;

  RETURN v_total_marks;
END;
$$;

COMMENT ON FUNCTION auto_grade_attempt(UUID) IS
  'Auto-grade objective questions for an attempt; subjective questions remain pending for manual grading';

-- ---------------------------------------------------------------------------
-- submit_exam_attempt(p_attempt_id, p_submission_type)
-- Submit an exam attempt: stop session, auto-grade, create result.
-- Returns the exam_result id.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION submit_exam_attempt(
  p_attempt_id      UUID,
  p_submission_type submission_type
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result_id         UUID;
  v_exam_id           UUID;
  v_student_id        UUID;
  v_total_marks       NUMERIC(7,2);
  v_total_possible    NUMERIC(7,2);
  v_score_percentage  NUMERIC(5,2);
  v_is_passed         BOOLEAN;
  v_exam_record       exams%ROWTYPE;
  v_attempt_record    exam_attempts%ROWTYPE;
  v_time_spent        INTEGER;
BEGIN
  -- Get the attempt
  SELECT * INTO v_attempt_record FROM exam_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attempt not found: %', p_attempt_id;
  END IF;

  -- Verify attempt is in a submittable state
  IF v_attempt_record.status NOT IN ('in_progress', 'not_started') THEN
    RAISE EXCEPTION 'Attempt cannot be submitted. Current status: %', v_attempt_record.status;
  END IF;

  v_exam_id    := v_attempt_record.exam_id;
  v_student_id := v_attempt_record.student_id;

  -- Get exam details
  SELECT * INTO v_exam_record FROM exams WHERE id = v_exam_id;

  -- Calculate time spent
  IF v_attempt_record.started_at IS NOT NULL THEN
    v_time_spent := EXTRACT(EPOCH FROM (now() - v_attempt_record.started_at))::INTEGER;
  ELSE
    v_time_spent := 0;
  END IF;

  -- Update the attempt status
  UPDATE exam_attempts
  SET
    status          = CASE p_submission_type
                        WHEN 'manual' THEN 'submitted'
                        WHEN 'auto_submit' THEN 'auto_submitted'
                        WHEN 'timed_out' THEN 'timed_out'
                        WHEN 'force_submit' THEN 'submitted'
                      END,
    submitted_at    = now(),
    submission_type = p_submission_type,
    time_spent_seconds = v_time_spent,
    last_activity_at = now(),
    updated_at      = now()
  WHERE id = p_attempt_id;

  -- Deactivate the session
  UPDATE exam_sessions
  SET
    is_active         = false,
    connection_status = 'disconnected',
    updated_at        = now()
  WHERE attempt_id = p_attempt_id AND is_active = true;

  -- Auto-grade the attempt
  v_total_marks := auto_grade_attempt(p_attempt_id);

  -- Get computed values from the updated attempt
  SELECT total_marks, score_percentage INTO v_total_marks, v_score_percentage
  FROM exam_attempts WHERE id = p_attempt_id;

  -- Calculate total possible marks
  SELECT COALESCE(SUM(eq.marks), 0) INTO v_total_possible
  FROM exam_questions eq
  WHERE eq.exam_id = v_exam_id;

  -- Determine pass/fail
  IF v_exam_record.pass_mark_type = 'percentage' THEN
    v_is_passed := v_score_percentage >= v_exam_record.pass_mark;
  ELSE  -- absolute
    v_is_passed := v_total_marks >= v_exam_record.pass_mark;
  END IF;

  -- Update attempt with is_passed
  UPDATE exam_attempts
  SET
    is_passed = v_is_passed,
    updated_at = now()
  WHERE id = p_attempt_id;

  -- Update exam_students completed_at
  UPDATE exam_students
  SET completed_at = now()
  WHERE exam_id = v_exam_id
    AND student_id = v_student_id
    AND completed_at IS NULL;

  -- Create exam_result
  INSERT INTO exam_results (
    exam_id, student_id, attempt_id,
    total_marks, total_possible, score_percentage,
    is_passed, time_spent_seconds,
    grading_status
  ) VALUES (
    v_exam_id, v_student_id, p_attempt_id,
    v_total_marks, v_total_possible, v_score_percentage,
    v_is_passed, v_time_spent,
    (SELECT grading_status FROM exam_attempts WHERE id = p_attempt_id)
  )
  RETURNING id INTO v_result_id;

  -- Generate notification
  PERFORM generate_exam_notification(v_exam_id, 'exam_submitted'::notification_category);

  RETURN v_result_id;
END;
$$;

COMMENT ON FUNCTION submit_exam_attempt(UUID, submission_type) IS
  'Submit an exam attempt: update status, deactivate session, auto-grade, create result, notify';

-- ---------------------------------------------------------------------------
-- calculate_rankings(p_exam_id)
-- Calculate and store rankings for all submitted attempts of an exam.
-- Rankings are based on total_marks DESC, then time_spent_seconds ASC.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_rankings(p_exam_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete existing rankings for this exam
  DELETE FROM exam_rankings WHERE exam_id = p_exam_id;

  -- Insert new rankings using window function
  -- Best attempt per student (highest score, then fastest time)
  INSERT INTO exam_rankings (exam_id, student_id, attempt_id, rank, total_marks, score_percentage)
  SELECT
    p_exam_id,
   RankedData.student_id,
    RankedData.attempt_id,
    RankedData.rank,
    RankedData.total_marks,
    RankedData.score_percentage
  FROM (
    SELECT
      ea.student_id,
      ea.id AS attempt_id,
      ea.total_marks,
      ea.score_percentage,
      ROW_NUMBER() OVER (
        PARTITION BY ea.student_id
        ORDER BY ea.total_marks DESC, ea.time_spent_seconds ASC
      ) AS best_attempt_rank,
      RANK() OVER (
        ORDER BY ea.total_marks DESC, ea.time_spent_seconds ASC
      ) AS rank
    FROM exam_attempts ea
    WHERE ea.exam_id = p_exam_id
      AND ea.status IN ('submitted', 'auto_submitted', 'timed_out')
  ) RankedData
  WHERE RankedData.best_attempt_rank = 1;

  -- Also update the rank in exam_results
  UPDATE exam_results er
  SET rank = er_rank.rank
  FROM exam_rankings er_rank
  WHERE er_rank.exam_id = p_exam_id
    AND er.exam_id = er_rank.exam_id
    AND er.student_id = er_rank.student_id
    AND er.attempt_id = er_rank.attempt_id;

END;
$$;

COMMENT ON FUNCTION calculate_rankings(UUID) IS
  'Calculate and store exam rankings based on best attempt per student (highest score, then fastest time)';

-- ---------------------------------------------------------------------------
-- release_results(p_exam_id)
-- Release exam results to students (set is_released = true).
-- Generates a notification for each student with a result.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION release_results(p_exam_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_student_rec RECORD;
BEGIN
  -- Mark all results for this exam as released
  UPDATE exam_results
  SET
    is_released = true,
    released_at = now(),
    updated_at  = now()
  WHERE exam_id = p_exam_id
    AND is_released = false;

  -- Generate notifications for all students with results
  PERFORM generate_exam_notification(p_exam_id, 'results_released'::notification_category);
END;
$$;

COMMENT ON FUNCTION release_results(UUID) IS
  'Release exam results to students and send notifications';

-- ---------------------------------------------------------------------------
-- get_exam_statistics(p_exam_id)
-- Returns aggregate statistics for an exam as JSONB.
-- Includes: total_students, attempted, passed, failed, avg_score,
--           max_score, min_score, pass_rate, grade_distribution,
--           question_difficulty_analysis.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_exam_statistics(p_exam_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'exam_id', p_exam_id,
    'total_assigned', (
      SELECT COUNT(*) FROM exam_students WHERE exam_id = p_exam_id AND is_exempt = false
    ),
    'total_attempted', (
      SELECT COUNT(DISTINCT student_id)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'total_in_progress', (
      SELECT COUNT(DISTINCT student_id)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status = 'in_progress'
    ),
    'total_passed', (
      SELECT COUNT(DISTINCT student_id)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND is_passed = true AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'total_failed', (
      SELECT COUNT(DISTINCT student_id)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND is_passed = false AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'avg_score', (
      SELECT ROUND(AVG(score_percentage), 2)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'max_score', (
      SELECT MAX(score_percentage)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'min_score', (
      SELECT MIN(score_percentage)
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'avg_time_spent_seconds', (
      SELECT ROUND(AVG(time_spent_seconds))
      FROM exam_attempts
      WHERE exam_id = p_exam_id AND status IN ('submitted', 'auto_submitted', 'timed_out')
    ),
    'pass_rate', (
      SELECT ROUND(
        COUNT(CASE WHEN is_passed THEN 1 END)::NUMERIC /
        NULLIF(COUNT(CASE WHEN status IN ('submitted', 'auto_submitted', 'timed_out') THEN 1 END), 0) * 100,
        2
      )
      FROM exam_attempts
      WHERE exam_id = p_exam_id
    ),
    'grade_distribution', (
      SELECT jsonb_object_agg(coalesce(grade, 'U'), cnt)
      FROM (
        SELECT er.grade, COUNT(*) AS cnt
        FROM exam_results er
        WHERE er.exam_id = p_exam_id AND er.is_released = true
        GROUP BY er.grade
      ) gd
    ),
    'monitoring_summary', (
      SELECT jsonb_build_object(
        'total_events', COUNT(*),
        'critical_events', COUNT(*) FILTER (WHERE severity = 'critical'),
        'warning_events', COUNT(*) FILTER (WHERE severity = 'warning'),
        'unresolved_events', COUNT(*) FILTER (WHERE is_resolved = false)
      )
      FROM exam_monitoring_logs
      WHERE exam_id = p_exam_id
    ),
    'active_sessions', (
      SELECT COUNT(*)
      FROM exam_sessions
      WHERE exam_id = p_exam_id AND is_active = true
    )
  ) INTO v_stats;

  RETURN v_stats;
END;
$$;

COMMENT ON FUNCTION get_exam_statistics(UUID) IS
  'Returns aggregate exam statistics as JSONB: pass rate, score distribution, monitoring summary, etc.';

-- ---------------------------------------------------------------------------
-- cleanup_stale_sessions()
-- Close exam sessions that have had no heartbeat for 5+ minutes.
-- Also updates the associated attempt to abandoned if it was in_progress.
-- Returns the number of sessions cleaned up.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleanup_stale_sessions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cleaned_count INTEGER := 0;
  v_stale_session RECORD;
  v_exam_record exams%ROWTYPE;
BEGIN
  -- Find sessions with no heartbeat for 5+ minutes
  FOR v_stale_session IN
    SELECT es.id AS session_id, es.attempt_id, es.exam_id, es.student_id
    FROM exam_sessions es
    WHERE es.is_active = true
      AND es.last_heartbeat < now() - INTERVAL '5 minutes'
  LOOP
    -- Get exam details for resume check
    SELECT * INTO v_exam_record FROM exams WHERE id = v_stale_session.exam_id;

    -- Deactivate the stale session
    UPDATE exam_sessions
    SET
      is_active = false,
      connection_status = 'disconnected',
      updated_at = now()
    WHERE id = v_stale_session.session_id;

    -- If exam allows resume, mark attempt as abandoned (student can resume later)
    -- If not, auto-submit the attempt
    IF v_exam_record.allow_resume THEN
      UPDATE exam_attempts
      SET
        status = 'abandoned',
        updated_at = now()
      WHERE id = v_stale_session.attempt_id
        AND status = 'in_progress';
    ELSE
      -- Force submit the attempt
      BEGIN
        PERFORM submit_exam_attempt(v_stale_session.attempt_id, 'auto_submit'::submission_type);
      EXCEPTION WHEN OTHERS THEN
        -- Log but don't fail the cleanup
        INSERT INTO audit_log (action, resource_type, resource_id, details)
        VALUES (
          'auto_submit_failed',
          'exam_attempt',
          v_stale_session.attempt_id,
          jsonb_build_object('error', SQLERRM, 'session_id', v_stale_session.session_id)
        );
      END;
    END IF;

    -- Log the monitoring event
    INSERT INTO exam_monitoring_logs (attempt_id, exam_id, student_id, event_type, event_data, severity)
    VALUES (
      v_stale_session.attempt_id,
      v_stale_session.exam_id,
      v_stale_session.student_id,
      'idle_timeout',
      jsonb_build_object(
        'last_heartbeat', v_stale_session.last_heartbeat,  -- will be filled by trigger
        'cleanup_reason', 'stale_session'
      ),
      'warning'
    );

    v_cleaned_count := v_cleaned_count + 1;
  END LOOP;

  RETURN v_cleaned_count;
END;
$$;

COMMENT ON FUNCTION cleanup_stale_sessions() IS
  'Clean up exam sessions with no heartbeat for 5+ minutes: deactivate session, abandon or auto-submit attempt';

-- ---------------------------------------------------------------------------
-- generate_exam_notification(p_exam_id, p_category)
-- Create notifications for students based on category.
-- exam_available/starting/reminder → all assigned students
-- exam_submitted → the student who just submitted
-- results_released → all students with results
-- grading_required → all teachers who created the exam or teach the subject
-- time_warning → all students with active sessions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_exam_notification(
  p_exam_id   UUID,
  p_category  notification_category
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_exam exams%ROWTYPE;
  v_notification_title TEXT;
  v_notification_message TEXT;
BEGIN
  -- Fetch exam details
  SELECT * INTO v_exam FROM exams WHERE id = p_exam_id;
  IF NOT FOUND THEN RETURN; END IF;

  -- Build notification content based on category
  CASE p_category
    WHEN 'exam_available' THEN
      v_notification_title := 'New Exam Available';
      v_notification_message := format('The exam "%s" is now available. Start time: %s', v_exam.title, to_char(v_exam.start_time, 'YYYY-MM-DD HH24:MI'));

    WHEN 'exam_starting' THEN
      v_notification_title := 'Exam Starting Soon';
      v_notification_message := format('The exam "%s" starts in a few minutes. Please prepare.', v_exam.title);

    WHEN 'time_warning' THEN
      v_notification_title := 'Time Warning';
      v_notification_message := format('The exam "%s" will end soon. Please submit your answers.', v_exam.title);

    WHEN 'exam_submitted' THEN
      v_notification_title := 'Exam Submitted';
      v_notification_message := format('Your exam "%s" has been submitted successfully.', v_exam.title);

    WHEN 'results_released' THEN
      v_notification_title := 'Results Released';
      v_notification_message := format('Results for the exam "%s" have been released. Check your score.', v_exam.title);

    WHEN 'grading_required' THEN
      v_notification_title := 'Grading Required';
      v_notification_message := format('The exam "%s" has submissions that require manual grading.', v_exam.title);

    WHEN 'exam_reminder' THEN
      v_notification_title := 'Exam Reminder';
      v_notification_message := format('Reminder: The exam "%s" is scheduled for %s.', v_exam.title, to_char(v_exam.start_time, 'YYYY-MM-DD HH24:MI'));

    ELSE
      v_notification_title := 'Exam Notification';
      v_notification_message := format('Notification for exam "%s".', v_exam.title);
  END CASE;

  -- Create notifications based on category
  CASE p_category
    -- Notify all assigned students
    WHEN 'exam_available', 'exam_starting', 'exam_reminder' THEN
      INSERT INTO exam_notifications (exam_id, student_id, category, title, message, data)
      SELECT
        p_exam_id,
        es.student_id,
        p_category,
        v_notification_title,
        v_notification_message,
        jsonb_build_object(
          'exam_id', p_exam_id,
          'exam_title', v_exam.title,
          'start_time', v_exam.start_time,
          'end_time', v_exam.end_time
        )
      FROM exam_students es
      WHERE es.exam_id = p_exam_id AND es.is_exempt = false
      ON CONFLICT DO NOTHING;  -- exam_notifications has no unique constraint, but just in case

    -- Notify all students with active sessions
    WHEN 'time_warning' THEN
      INSERT INTO exam_notifications (exam_id, student_id, category, title, message, data)
      SELECT
        p_exam_id,
        es.student_id,
        p_category,
        v_notification_title,
        v_notification_message,
        jsonb_build_object(
          'exam_id', p_exam_id,
          'exam_title', v_exam.title
        )
      FROM exam_sessions es
      WHERE es.exam_id = p_exam_id AND es.is_active = true;

    -- Notify students with released results
    WHEN 'results_released' THEN
      INSERT INTO exam_notifications (exam_id, student_id, category, title, message, data)
      SELECT
        p_exam_id,
        er.student_id,
        p_category,
        v_notification_title,
        v_notification_message,
        jsonb_build_object(
          'exam_id', p_exam_id,
          'exam_title', v_exam.title,
          'score_percentage', er.score_percentage,
          'grade', er.grade,
          'is_passed', er.is_passed
        )
      FROM exam_results er
      WHERE er.exam_id = p_exam_id AND er.is_released = true;

    -- Notify exam creator about grading needed
    WHEN 'grading_required' THEN
      -- Notify the exam creator
      INSERT INTO exam_notifications (exam_id, student_id, category, title, message, data)
      VALUES (
        p_exam_id,
        v_exam.created_by,
        p_category,
        v_notification_title,
        v_notification_message,
        jsonb_build_object(
          'exam_id', p_exam_id,
          'exam_title', v_exam.title
        )
      );

    ELSE
      NULL;
  END CASE;
END;
$$;

COMMENT ON FUNCTION generate_exam_notification(UUID, notification_category) IS
  'Generate exam notifications for students/teachers based on the notification category';

-- ---------------------------------------------------------------------------
-- apply_grade_scale(p_exam_id, p_grade_scale_id)
-- Apply a grade scale to all results for an exam.
-- Updates the grade and is_passing fields based on score_percentage.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION apply_grade_scale(
  p_exam_id        UUID,
  p_grade_scale_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_scale_entry JSONB;
  v_result RECORD;
  v_grade VARCHAR(5);
  v_is_passing BOOLEAN;
BEGIN
  -- Validate grade scale exists
  IF NOT EXISTS (SELECT 1 FROM grade_scales WHERE id = p_grade_scale_id) THEN
    RAISE EXCEPTION 'Grade scale not found: %', p_grade_scale_id;
  END IF;

  -- Apply grade to each result
  FOR v_result IN
    SELECT id, score_percentage
    FROM exam_results
    WHERE exam_id = p_exam_id
  LOOP
    v_grade := NULL;
    v_is_passing := false;

    -- Find matching scale entry
    FOR v_scale_entry IN
      SELECT jsonb_array_elements(scale_entries) AS entry
      FROM grade_scales
      WHERE id = p_grade_scale_id
    LOOP
      IF v_result.score_percentage >= (v_scale_entry->>'min_percentage')::NUMERIC
         AND v_result.score_percentage <= (v_scale_entry->>'max_percentage')::NUMERIC THEN
        v_grade := v_scale_entry->>'grade';
        v_is_passing := COALESCE((v_scale_entry->>'is_passing')::BOOLEAN, false);
        EXIT;
      END IF;
    END LOOP;

    -- Update the result
    UPDATE exam_results
    SET
      grade = v_grade,
      is_passed = v_is_passing,
      updated_at = now()
    WHERE id = v_result.id;

    -- Also update the attempt's is_passed
    UPDATE exam_attempts ea
    SET
      is_passed = v_is_passing,
      updated_at = now()
    FROM exam_results er
    WHERE er.attempt_id = ea.id
      AND er.id = v_result.id;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION apply_grade_scale(UUID, UUID) IS
  'Apply a grade scale to all results for an exam, updating grade letters and pass/fail status';

-- ============================================================================
-- 18. TRIGGERS
-- ============================================================================
-- Automated triggers for data consistency and real-time updates.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auto-update updated_at on all CBT tables
-- ---------------------------------------------------------------------------

-- exams
DROP TRIGGER IF EXISTS set_exams_updated_at ON exams;
CREATE TRIGGER set_exams_updated_at
  BEFORE UPDATE ON exams
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- exam_attempts
DROP TRIGGER IF EXISTS set_exam_attempts_updated_at ON exam_attempts;
CREATE TRIGGER set_exam_attempts_updated_at
  BEFORE UPDATE ON exam_attempts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- exam_sessions
DROP TRIGGER IF EXISTS set_exam_sessions_updated_at ON exam_sessions;
CREATE TRIGGER set_exam_sessions_updated_at
  BEFORE UPDATE ON exam_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- exam_results
DROP TRIGGER IF EXISTS set_exam_results_updated_at ON exam_results;
CREATE TRIGGER set_exam_results_updated_at
  BEFORE UPDATE ON exam_results
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- grade_scales
DROP TRIGGER IF EXISTS set_grade_scales_updated_at ON grade_scales;
CREATE TRIGGER set_grade_scales_updated_at
  BEFORE UPDATE ON grade_scales
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- student_answers
DROP TRIGGER IF EXISTS set_student_answers_updated_at ON student_answers;
CREATE TRIGGER set_student_answers_updated_at
  BEFORE UPDATE ON student_answers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Auto-calculate total_marks when exam_questions change
-- Recalculates the exam total_marks from the sum of exam_questions.marks
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recalculate_exam_total_marks()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_exam_id UUID;
BEGIN
  -- Determine the exam_id based on the trigger operation
  IF TG_OP = 'DELETE' THEN
    v_exam_id := OLD.exam_id;
  ELSE
    v_exam_id := NEW.exam_id;
  END IF;

  -- Recalculate and update the exam total_marks
  UPDATE exams
  SET total_marks = (
    SELECT COALESCE(SUM(marks), 0)
    FROM exam_questions
    WHERE exam_id = v_exam_id
  )
  WHERE id = v_exam_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION recalculate_exam_total_marks() IS
  'Trigger function: recalculates exam total_marks when exam_questions are inserted, updated, or deleted';

DROP TRIGGER IF EXISTS on_exam_question_change ON exam_questions;
CREATE TRIGGER on_exam_question_change
  AFTER INSERT OR UPDATE OF marks OR DELETE ON exam_questions
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_exam_total_marks();

-- ---------------------------------------------------------------------------
-- Auto-update exam_sessions on attempt changes (for Realtime propagation)
-- When an attempt is updated, bump the session updated_at so Realtime
-- subscribers (teachers monitoring) get the update.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION propagate_attempt_update_to_session()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only propagate if the attempt is in_progress
  IF NEW.status = 'in_progress' OR OLD.status = 'in_progress' THEN
    UPDATE exam_sessions
    SET updated_at = now()
    WHERE attempt_id = NEW.id AND is_active = true;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION propagate_attempt_update_to_session() IS
  'Trigger function: bumps exam_sessions updated_at when exam_attempts change, propagating Realtime updates to monitors';

DROP TRIGGER IF EXISTS on_attempt_update_propagate ON exam_attempts;
CREATE TRIGGER on_attempt_update_propagate
  AFTER UPDATE ON exam_attempts
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status OR OLD.total_marks IS DISTINCT FROM NEW.total_marks)
  EXECUTE FUNCTION propagate_attempt_update_to_session();

-- ---------------------------------------------------------------------------
-- Auto-create exam_result when attempt is submitted
-- (backup trigger in case submit_exam_attempt is bypassed)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION auto_create_exam_result()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_possible NUMERIC(7,2);
  v_exam_record exams%ROWTYPE;
BEGIN
  -- Only fire when status changes to a terminal state
  IF NEW.status IN ('submitted', 'auto_submitted', 'timed_out')
     AND OLD.status NOT IN ('submitted', 'auto_submitted', 'timed_out') THEN

    -- Check if result already exists (might have been created by submit_exam_attempt)
    IF NOT EXISTS (
      SELECT 1 FROM exam_results
      WHERE attempt_id = NEW.id
    ) THEN
      -- Get exam details
      SELECT * INTO v_exam_record FROM exams WHERE id = NEW.exam_id;

      -- Calculate total possible
      SELECT COALESCE(SUM(marks), 0) INTO v_total_possible
      FROM exam_questions WHERE exam_id = NEW.exam_id;

      -- Determine pass/fail
      IF v_exam_record.pass_mark_type = 'percentage' THEN
        NEW.is_passed := NEW.score_percentage >= v_exam_record.pass_mark;
      ELSE
        NEW.is_passed := NEW.total_marks >= v_exam_record.pass_mark;
      END IF;

      -- Create result
      INSERT INTO exam_results (
        exam_id, student_id, attempt_id,
        total_marks, total_possible, score_percentage,
        is_passed, time_spent_seconds, grading_status
      ) VALUES (
        NEW.exam_id, NEW.student_id, NEW.id,
        NEW.total_marks, v_total_possible, NEW.score_percentage,
        NEW.is_passed, NEW.time_spent_seconds, NEW.grading_status
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION auto_create_exam_result() IS
  'Trigger function: automatically creates an exam_result when an attempt transitions to a submitted state';

DROP TRIGGER IF EXISTS on_attempt_submit_create_result ON exam_attempts;
CREATE TRIGGER on_attempt_submit_create_result
  AFTER UPDATE ON exam_attempts
  FOR EACH ROW
  WHEN (NEW.status IN ('submitted', 'auto_submitted', 'timed_out')
        AND OLD.status NOT IN ('submitted', 'auto_submitted', 'timed_out'))
  EXECUTE FUNCTION auto_create_exam_result();

-- ---------------------------------------------------------------------------
-- Auto-send notification on exam status change
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION notify_on_exam_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only fire when status actually changes
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    CASE NEW.status
      WHEN 'published' THEN
        PERFORM generate_exam_notification(NEW.id, 'exam_available'::notification_category);
      WHEN 'active' THEN
        PERFORM generate_exam_notification(NEW.id, 'exam_starting'::notification_category);
      WHEN 'completed' THEN
        -- Check if there are submissions requiring manual grading
        IF EXISTS (
          SELECT 1 FROM exam_attempts
          WHERE exam_id = NEW.id AND grading_status IN ('pending', 'partially_graded')
        ) THEN
          PERFORM generate_exam_notification(NEW.id, 'grading_required'::notification_category);
        END IF;
      ELSE
        NULL;
    END CASE;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notify_on_exam_status_change() IS
  'Trigger function: sends notifications when an exam status changes (published → students, completed → teachers)';

DROP TRIGGER IF EXISTS on_exam_status_change_notify ON exams;
CREATE TRIGGER on_exam_status_change_notify
  AFTER UPDATE ON exams
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION notify_on_exam_status_change();

-- ---------------------------------------------------------------------------
-- Auto-calculate score_percentage and is_passed on exam_results update
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION auto_calculate_result_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_exam exams%ROWTYPE;
BEGIN
  -- Recalculate score_percentage if total_marks or total_possible changed
  IF NEW.total_possible > 0 THEN
    NEW.score_percentage := ROUND((NEW.total_marks / NEW.total_possible) * 100, 2);
  ELSE
    NEW.score_percentage := 0.00;
  END IF;

  -- Recalculate is_passed based on exam pass_mark
  SELECT * INTO v_exam FROM exams WHERE id = NEW.exam_id;
  IF FOUND THEN
    IF v_exam.pass_mark_type = 'percentage' THEN
      NEW.is_passed := NEW.score_percentage >= v_exam.pass_mark;
    ELSE  -- absolute
      NEW.is_passed := NEW.total_marks >= v_exam.pass_mark;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION auto_calculate_result_fields() IS
  'Trigger function: auto-calculates score_percentage and is_passed when exam_results are updated';

DROP TRIGGER IF EXISTS on_result_update_calculate ON exam_results;
CREATE TRIGGER on_result_update_calculate
  BEFORE UPDATE ON exam_results
  FOR EACH ROW
  WHEN (NEW.total_marks IS DISTINCT FROM OLD.total_marks
        OR NEW.total_possible IS DISTINCT FROM OLD.total_possible)
  EXECUTE FUNCTION auto_calculate_result_fields();

-- ---------------------------------------------------------------------------
-- Auto-update exam_students timestamps when attempt is created
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_exam_students_timestamps()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'in_progress' AND OLD.status = 'not_started' THEN
    UPDATE exam_students
    SET started_at = COALESCE(started_at, now())
    WHERE exam_id = NEW.exam_id AND student_id = NEW.student_id;
  END IF;

  IF NEW.status IN ('submitted', 'auto_submitted', 'timed_out') THEN
    -- Check if this is the last allowed attempt
    DECLARE
      v_allowed_attempts INTEGER;
      v_current_attempts INTEGER;
    BEGIN
      SELECT COALESCE(es.allowed_attempts, e.allowed_attempts)
      INTO v_allowed_attempts
      FROM exam_students es
      JOIN exams e ON e.id = es.exam_id
      WHERE es.exam_id = NEW.exam_id AND es.student_id = NEW.student_id;

      SELECT COUNT(*) INTO v_current_attempts
      FROM exam_attempts
      WHERE exam_id = NEW.exam_id
        AND student_id = NEW.student_id
        AND status IN ('submitted', 'auto_submitted', 'timed_out');

      IF v_current_attempts >= v_allowed_attempts THEN
        UPDATE exam_students
        SET completed_at = now()
        WHERE exam_id = NEW.exam_id
          AND student_id = NEW.student_id
          AND completed_at IS NULL;
      END IF;
    END;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_exam_students_timestamps() IS
  'Trigger function: updates exam_students started_at/completed_at timestamps based on attempt status changes';

DROP TRIGGER IF EXISTS on_attempt_status_update_student ON exam_attempts;
CREATE TRIGGER on_attempt_status_update_student
  AFTER UPDATE ON exam_attempts
  FOR EACH ROW
  WHEN (NEW.status IS DISTINCT FROM OLD.status)
  EXECUTE FUNCTION update_exam_students_timestamps();

-- ---------------------------------------------------------------------------
-- Set published_at when exam status changes to 'published'
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_published_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'published' AND OLD.status != 'published' THEN
    NEW.published_at := now();
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION set_published_at() IS
  'Trigger function: sets published_at when exam status transitions to published';

DROP TRIGGER IF EXISTS on_exam_publish ON exams;
CREATE TRIGGER on_exam_publish
  BEFORE UPDATE ON exams
  FOR EACH ROW
  WHEN (NEW.status = 'published' AND OLD.status != 'published')
  EXECUTE FUNCTION set_published_at();

-- ---------------------------------------------------------------------------
-- Enforce only one default grade scale per school
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION enforce_single_default_grade_scale()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_default = true AND NEW.school_id IS NOT NULL THEN
    UPDATE grade_scales
    SET is_default = false
    WHERE school_id = NEW.school_id
      AND is_default = true
      AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION enforce_single_default_grade_scale() IS
  'Trigger function: ensures only one default grade scale per school';

DROP TRIGGER IF EXISTS on_grade_scale_default ON grade_scales;
CREATE TRIGGER on_grade_scale_default
  BEFORE INSERT OR UPDATE OF is_default ON grade_scales
  FOR EACH ROW
  WHEN (NEW.is_default = true)
  EXECUTE FUNCTION enforce_single_default_grade_scale();

-- ============================================================================
-- 19. ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Comprehensive RLS policies for the CBT Engine tables.
-- Access is governed by user_role hierarchy:
--   super_admin > school_admin > teacher > student
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Enable RLS on ALL CBT data tables
-- ---------------------------------------------------------------------------

ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_monitoring_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_rankings ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scales ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- EXAMS RLS POLICIES
-- ===========================================================================

-- Super admins have full access to all exams
CREATE POLICY "Super admins have full access to exams"
  ON exams FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can read exams in their school
CREATE POLICY "School admins can read school exams"
  ON exams FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can insert exams in their school
CREATE POLICY "School admins can insert school exams"
  ON exams FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can update exams in their school
CREATE POLICY "School admins can update school exams"
  ON exams FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can delete exams in their school
CREATE POLICY "School admins can delete school exams"
  ON exams FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Teachers can read exams they created or that belong to their school's classes
CREATE POLICY "Teachers can read own school exams"
  ON exams FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND (
      created_by = auth.uid()
      OR school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Teachers can insert exams in their school
CREATE POLICY "Teachers can insert school exams"
  ON exams FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'teacher'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Teachers can update exams they created
CREATE POLICY "Teachers can update own exams"
  ON exams FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  );

-- Teachers can delete exams they created
CREATE POLICY "Teachers can delete own exams"
  ON exams FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND created_by = auth.uid()
  );

-- Students can read published/active exams they're assigned to
CREATE POLICY "Students can read assigned published exams"
  ON exams FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND status IN ('published', 'active')
    AND EXISTS (
      SELECT 1 FROM exam_students es
      WHERE es.exam_id = id
        AND es.student_id = auth.uid()
        AND es.is_exempt = false
    )
  );

-- ===========================================================================
-- EXAM_SECTIONS RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_sections"
  ON exam_sections FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage sections for exams in their school
CREATE POLICY "School admins can manage exam_sections"
  ON exam_sections FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Teachers can manage sections for exams they created
CREATE POLICY "Teachers can manage own exam_sections"
  ON exam_sections FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- Students can read sections for exams they're assigned to
CREATE POLICY "Students can read assigned exam_sections"
  ON exam_sections FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND EXISTS (
      SELECT 1 FROM exams e
      JOIN exam_students es ON es.exam_id = e.id
      WHERE e.id = exam_id
        AND e.status IN ('published', 'active')
        AND es.student_id = auth.uid()
        AND es.is_exempt = false
    )
  );

-- ===========================================================================
-- EXAM_QUESTIONS RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_questions"
  ON exam_questions FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage questions for exams in their school
CREATE POLICY "School admins can manage exam_questions"
  ON exam_questions FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Teachers can manage questions for exams they created
CREATE POLICY "Teachers can manage own exam_questions"
  ON exam_questions FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- Students can read questions for exams they're taking
CREATE POLICY "Students can read assigned exam_questions"
  ON exam_questions FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND EXISTS (
      SELECT 1 FROM exams e
      JOIN exam_students es ON es.exam_id = e.id
      WHERE e.id = exam_id
        AND e.status IN ('published', 'active')
        AND es.student_id = auth.uid()
        AND es.is_exempt = false
    )
  );

-- ===========================================================================
-- EXAM_STUDENTS RLS POLICIES
-- ===========================================================================

-- Students can read their own records
CREATE POLICY "Students can read own exam_student records"
  ON exam_students FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Teachers can read/manage assigned students for their exams
CREATE POLICY "Teachers can manage exam_students for own exams"
  ON exam_students FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can manage exam_students in their school
CREATE POLICY "School admins can manage exam_students"
  ON exam_students FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_students"
  ON exam_students FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- EXAM_ATTEMPTS RLS POLICIES
-- ===========================================================================

-- Students can CRUD their own attempts
CREATE POLICY "Students can manage own exam_attempts"
  ON exam_attempts FOR ALL
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- Teachers can read attempts for their exams
CREATE POLICY "Teachers can read exam_attempts for own exams"
  ON exam_attempts FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all attempts in their school
CREATE POLICY "School admins can read school exam_attempts"
  ON exam_attempts FOR SELECT
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
CREATE POLICY "Super admins have full access to exam_attempts"
  ON exam_attempts FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- STUDENT_ANSWERS RLS POLICIES
-- ===========================================================================

-- Students can CRUD their own answers (via their attempts)
CREATE POLICY "Students can manage own student_answers"
  ON student_answers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM exam_attempts ea
      WHERE ea.id = attempt_id AND ea.student_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM exam_attempts ea
      WHERE ea.id = attempt_id AND ea.student_id = auth.uid()
    )
  );

-- Teachers can read/update answers for their exams (grading)
CREATE POLICY "Teachers can read update student_answers for own exams"
  ON student_answers FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_attempts ea
      JOIN exams e ON e.id = ea.exam_id
      WHERE ea.id = attempt_id AND e.created_by = auth.uid()
    )
  );

CREATE POLICY "Teachers can update student_answers for grading"
  ON student_answers FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_attempts ea
      JOIN exams e ON e.id = ea.exam_id
      WHERE ea.id = attempt_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exam_attempts ea
      JOIN exams e ON e.id = ea.exam_id
      WHERE ea.id = attempt_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all answers in their school
CREATE POLICY "School admins can read student_answers"
  ON student_answers FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exam_attempts ea
      JOIN exams e ON e.id = ea.exam_id
      WHERE ea.id = attempt_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to student_answers"
  ON student_answers FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- EXAM_SESSIONS RLS POLICIES (REALTIME)
-- ===========================================================================

-- Students can read/update their own sessions
CREATE POLICY "Students can read own exam_sessions"
  ON exam_sessions FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "Students can update own exam_sessions"
  ON exam_sessions FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- Students can insert their own sessions (when starting an exam)
CREATE POLICY "Students can insert own exam_sessions"
  ON exam_sessions FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

-- Teachers can read sessions for their exams (live monitoring)
CREATE POLICY "Teachers can read exam_sessions for own exams"
  ON exam_sessions FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all sessions in their school
CREATE POLICY "School admins can read exam_sessions"
  ON exam_sessions FOR SELECT
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
CREATE POLICY "Super admins have full access to exam_sessions"
  ON exam_sessions FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- EXAM_MONITORING_LOGS RLS POLICIES
-- ===========================================================================

-- Teachers can read logs for their exams
CREATE POLICY "Teachers can read exam_monitoring_logs for own exams"
  ON exam_monitoring_logs FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- Teachers can update (resolve) logs for their exams
CREATE POLICY "Teachers can update exam_monitoring_logs for own exams"
  ON exam_monitoring_logs FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all logs in their school
CREATE POLICY "School admins can read exam_monitoring_logs"
  ON exam_monitoring_logs FOR SELECT
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
CREATE POLICY "Super admins have full access to exam_monitoring_logs"
  ON exam_monitoring_logs FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Students CANNOT read monitoring logs (no SELECT policy for students)
-- Monitoring logs are inserted via service_role or SECURITY DEFINER functions

-- ===========================================================================
-- EXAM_RESULTS RLS POLICIES
-- ===========================================================================

-- Students can read their own released results
CREATE POLICY "Students can read own released exam_results"
  ON exam_results FOR SELECT
  TO authenticated
  USING (
    student_id = auth.uid()
    AND is_released = true
  );

-- Teachers can read results for their exams
CREATE POLICY "Teachers can read exam_results for own exams"
  ON exam_results FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- Teachers can update results for grading
CREATE POLICY "Teachers can update exam_results for own exams"
  ON exam_results FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  )
  WITH CHECK (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all results in their school
CREATE POLICY "School admins can read exam_results"
  ON exam_results FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- School admins can update results in their school
CREATE POLICY "School admins can update exam_results"
  ON exam_results FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id
        AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_results"
  ON exam_results FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- EXAM_RANKINGS RLS POLICIES
-- ===========================================================================

-- Students can read their own rankings
CREATE POLICY "Students can read own exam_rankings"
  ON exam_rankings FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Teachers can read rankings for their exams
CREATE POLICY "Teachers can read exam_rankings for own exams"
  ON exam_rankings FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM exams e
      WHERE e.id = exam_id AND e.created_by = auth.uid()
    )
  );

-- School admins can read all rankings in their school
CREATE POLICY "School admins can read exam_rankings"
  ON exam_rankings FOR SELECT
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
CREATE POLICY "Super admins have full access to exam_rankings"
  ON exam_rankings FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- EXAM_NOTIFICATIONS RLS POLICIES
-- ===========================================================================

-- Students can read their own notifications
CREATE POLICY "Students can read own exam_notifications"
  ON exam_notifications FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Students can update their own notifications (mark as read)
CREATE POLICY "Students can update own exam_notifications"
  ON exam_notifications FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- School admins can read notifications for exams in their school
CREATE POLICY "School admins can read exam_notifications"
  ON exam_notifications FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND (
      exam_id IS NULL
      OR EXISTS (
        SELECT 1 FROM exams e
        WHERE e.id = exam_id
          AND e.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
      )
    )
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to exam_notifications"
  ON exam_notifications FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Notifications are inserted via service_role or SECURITY DEFINER functions

-- ===========================================================================
-- GRADE_SCALES RLS POLICIES
-- ===========================================================================

-- Super admins have full access
CREATE POLICY "Super admins have full access to grade_scales"
  ON grade_scales FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- School admins can manage grade scales in their school
CREATE POLICY "School admins can manage grade_scales"
  ON grade_scales FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR school_id IS NULL)
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR school_id IS NULL)
  );

-- Teachers can read grade scales in their school
CREATE POLICY "Teachers can read grade_scales"
  ON grade_scales FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND (
      school_id = (SELECT school_id FROM users WHERE id = auth.uid())
      OR school_id IS NULL
      OR is_default = true
    )
  );

-- Students can read default grade scales (for understanding grading)
CREATE POLICY "Students can read grade_scales"
  ON grade_scales FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'student'
    AND (
      school_id = (SELECT school_id FROM users WHERE id = auth.uid())
      OR school_id IS NULL
    )
  );

-- ============================================================================
-- 20. TABLE COMMENTS SUMMARY
-- ============================================================================

COMMENT ON SCHEMA public IS 'ExamForge AI CBT Engine - Production Schema v1.0';

-- Final verification comment
DO $$
BEGIN
  RAISE NOTICE 'CBT Engine schema migration completed successfully.';
  RAISE NOTICE 'Tables created: exams, exam_sections, exam_questions, exam_students, exam_attempts, student_answers, exam_sessions, exam_monitoring_logs, exam_results, exam_rankings, exam_notifications, grade_scales';
  RAISE NOTICE 'Realtime enabled on: exam_sessions, exam_attempts, exam_monitoring_logs';
  RAISE NOTICE 'RLS enabled on all CBT tables';
END
$$;

COMMIT;

-- ============================================================================
-- END OF CBT ENGINE SCHEMA
-- ============================================================================
