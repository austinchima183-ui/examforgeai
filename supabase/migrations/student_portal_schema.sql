-- ═══════════════════════════════════════════════════════════════════════════
-- ExamForge AI — Student Learning Portal Schema
-- ═══════════════════════════════════════════════════════════════════════════
-- Provides tables for the student-facing learning experience:
--   • AI Tutor conversations & messages
--   • Practice sessions & practice answers
--   • Assignment submissions
--   • Learning resources & access tracking
--   • Document chat (PDF/DOCX/TXT)
--   • Flashcards & flashcard decks (spaced repetition)
--   • Study plans, goals & tasks
--   • Student progress snapshots
--   • Student notifications
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Custom Enum Types ─────────────────────────────────────────────────────

DO $$ BEGIN
  -- Practice mode type
  CREATE TYPE practice_mode AS ENUM (
    'timed', 'untimed'
  );

  -- Practice session status
  CREATE TYPE practice_session_status AS ENUM (
    'in_progress', 'completed', 'abandoned'
  );

  -- Assignment submission status
  CREATE TYPE submission_status AS ENUM (
    'draft', 'submitted', 'late_submitted', 'graded', 'returned', 'resubmitted'
  );

  -- Resource type for student portal
  CREATE TYPE student_resource_type AS ENUM (
    'lesson_note', 'worksheet', 'study_guide', 'slide', 'handout',
    'recommended_reading', 'video_link', 'past_question'
  );

  -- Document chat status
  CREATE TYPE document_chat_status AS ENUM (
    'processing', 'ready', 'failed'
  );

  -- Flashcard difficulty rating (for spaced repetition)
  CREATE TYPE flashcard_rating AS ENUM (
    'again', 'hard', 'good', 'easy'
  );

  -- Study plan frequency
  CREATE TYPE study_plan_frequency AS ENUM (
    'daily', 'weekly', 'custom'
  );

  -- Study task status
  CREATE TYPE study_task_status AS ENUM (
    'pending', 'in_progress', 'completed', 'skipped'
  );

  -- Goal priority
  CREATE TYPE goal_priority AS ENUM (
    'low', 'medium', 'high', 'urgent'
  );

  -- Goal status
  CREATE TYPE goal_status AS ENUM (
    'not_started', 'in_progress', 'achieved', 'abandoned'
  );

  -- AI tutor message role
  CREATE TYPE tutor_message_role AS ENUM (
    'user', 'assistant', 'system'
  );

  -- Progress period type
  CREATE TYPE progress_period AS ENUM (
    'daily', 'weekly', 'monthly', 'termly', 'annually'
  );

EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- AI TUTOR
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_tutor_conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  title           TEXT NOT NULL DEFAULT 'New Conversation',
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic           TEXT,
  curriculum_type TEXT DEFAULT 'nigerian',
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE INDEX idx_ai_tutor_conversations_student ON ai_tutor_conversations(student_id);
CREATE INDEX idx_ai_tutor_conversations_school ON ai_tutor_conversations(school_id);
CREATE INDEX idx_ai_tutor_conversations_subject ON ai_tutor_conversations(subject_id);
CREATE INDEX idx_ai_tutor_conversations_updated ON ai_tutor_conversations(student_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS ai_tutor_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES ai_tutor_conversations(id) ON DELETE CASCADE,
  role            tutor_message_role NOT NULL,
  content         TEXT NOT NULL,
  metadata        JSONB DEFAULT '{}',  -- tokens, model, source_refs, etc.
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_conversation FOREIGN KEY (conversation_id) REFERENCES ai_tutor_conversations(id)
);

CREATE INDEX idx_ai_tutor_messages_conversation ON ai_tutor_messages(conversation_id, created_at ASC);

-- ═══════════════════════════════════════════════════════════════════════════
-- PRACTICE SESSIONS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS practice_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic_id        UUID REFERENCES topics(id) ON DELETE SET NULL,
  difficulty      difficulty_level DEFAULT 'medium',
  mode            practice_mode NOT NULL DEFAULT 'untimed',
  time_limit_sec  INTEGER,             -- NULL for untimed; seconds for timed
  total_questions INTEGER NOT NULL DEFAULT 0,
  correct_count   INTEGER NOT NULL DEFAULT 0,
  score_pct       DECIMAL(5,2) DEFAULT 0,
  status          practice_session_status NOT NULL DEFAULT 'in_progress',
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_score_range CHECK (score_pct >= 0 AND score_pct <= 100)
);

CREATE INDEX idx_practice_sessions_student ON practice_sessions(student_id);
CREATE INDEX idx_practice_sessions_student_subject ON practice_sessions(student_id, subject_id);
CREATE INDEX idx_practice_sessions_status ON practice_sessions(student_id, status);
CREATE INDEX idx_practice_sessions_started ON practice_sessions(student_id, started_at DESC);

CREATE TABLE IF NOT EXISTS practice_answers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID NOT NULL REFERENCES practice_sessions(id) ON DELETE CASCADE,
  question_id     UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  student_answer  JSONB NOT NULL,       -- flexible format for different Q types
  is_correct      BOOLEAN,
  time_spent_sec  INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_session FOREIGN KEY (session_id) REFERENCES practice_sessions(id)
);

CREATE INDEX idx_practice_answers_session ON practice_answers(session_id);
CREATE INDEX idx_practice_answers_question ON practice_answers(question_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- ASSIGNMENT SUBMISSIONS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS assignment_submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id   UUID NOT NULL,        -- References teacher_workspace assignments
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  content         JSONB DEFAULT '{}',   -- Student answers / written content
  attachments     JSONB DEFAULT '[]',   -- [{filename, url, size, type}]
  status          submission_status NOT NULL DEFAULT 'draft',
  score           DECIMAL(5,2),
  max_score       DECIMAL(5,2),
  teacher_feedback TEXT,
  ai_feedback     JSONB,                -- AI-generated feedback
  submitted_at    TIMESTAMPTZ,
  graded_at       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_submission_score CHECK (score IS NULL OR (score >= 0 AND score <= max_score)),
  CONSTRAINT uq_student_assignment UNIQUE (assignment_id, student_id)
);

CREATE INDEX idx_assignment_submissions_student ON assignment_submissions(student_id);
CREATE INDEX idx_assignment_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX idx_assignment_submissions_status ON assignment_submissions(student_id, status);
CREATE INDEX idx_assignment_submissions_school ON assignment_submissions(school_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- LEARNING RESOURCES (Student-facing)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS student_learning_resources (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic_id        UUID REFERENCES topics(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  resource_type   student_resource_type NOT NULL DEFAULT 'lesson_note',
  file_url        TEXT,                 -- Supabase Storage URL (if file-based)
  file_size       BIGINT,               -- bytes
  file_format     TEXT,                 -- pdf, docx, pptx, etc.
  content         TEXT,                 -- Inline text content (for notes)
  thumbnail_url   TEXT,
  teacher_id      UUID REFERENCES users(id) ON DELETE SET NULL, -- Uploader
  is_downloadable BOOLEAN NOT NULL DEFAULT TRUE,
  is_public       BOOLEAN NOT NULL DEFAULT FALSE,
  tags            TEXT[] DEFAULT '{}',
  view_count      INTEGER NOT NULL DEFAULT 0,
  download_count  INTEGER NOT NULL DEFAULT 0,
  curriculum_type TEXT DEFAULT 'nigerian',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_student_resources_subject ON student_learning_resources(subject_id);
CREATE INDEX idx_student_resources_type ON student_learning_resources(resource_type);
CREATE INDEX idx_student_resources_school ON student_learning_resources(school_id);
CREATE INDEX idx_student_resources_public ON student_learning_resources(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_student_resources_tags ON student_learning_resources USING GIN(tags);

-- Resource access log
CREATE TABLE IF NOT EXISTS resource_access_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id     UUID NOT NULL REFERENCES student_learning_resources(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_type     TEXT NOT NULL DEFAULT 'view',  -- view, download
  accessed_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_resource_access_student ON resource_access_log(student_id, accessed_at DESC);
CREATE INDEX idx_resource_access_resource ON resource_access_log(resource_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- DOCUMENT CHAT (PDF / DOCX / TXT)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS document_chats (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  file_name       TEXT NOT NULL,
  file_url        TEXT NOT NULL,         -- Supabase Storage path
  file_size       BIGINT,
  file_format     TEXT NOT NULL,         -- pdf, docx, txt
  extracted_text  TEXT,                  -- Parsed text content
  summary         TEXT,                  -- AI-generated summary
  flashcard_deck_id UUID,               -- Optional generated flashcard deck
  status          document_chat_status NOT NULL DEFAULT 'processing',
  page_count      INTEGER,
  word_count      INTEGER,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_document_chats_student ON document_chats(student_id, created_at DESC);

CREATE TABLE IF NOT EXISTS document_chat_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id     UUID NOT NULL REFERENCES document_chats(id) ON DELETE CASCADE,
  role            tutor_message_role NOT NULL,
  content         TEXT NOT NULL,
  page_reference  INTEGER,              -- Page number reference if applicable
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_document_chat_messages_doc ON document_chat_messages(document_id, created_at ASC);

-- ═══════════════════════════════════════════════════════════════════════════
-- FLASHCARDS (Spaced Repetition)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS flashcard_decks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic_id        UUID REFERENCES topics(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  source_type     TEXT DEFAULT 'manual',  -- manual, ai_generated, document, resource
  source_id       UUID,                   -- ID of source (document, resource, etc.)
  card_count      INTEGER NOT NULL DEFAULT 0,
  is_favorite     BOOLEAN NOT NULL DEFAULT FALSE,
  tags            TEXT[] DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_flashcard_decks_student ON flashcard_decks(student_id);
CREATE INDEX idx_flashcard_decks_subject ON flashcard_decks(student_id, subject_id);
CREATE INDEX idx_flashcard_decks_favorite ON flashcard_decks(student_id, is_favorite) WHERE is_favorite = TRUE;

CREATE TABLE IF NOT EXISTS flashcards (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id         UUID NOT NULL REFERENCES flashcard_decks(id) ON DELETE CASCADE,
  front_content   TEXT NOT NULL,
  back_content    TEXT NOT NULL,
  hint            TEXT,
  image_url       TEXT,
  difficulty      difficulty_level DEFAULT 'medium',
  -- Spaced repetition fields (SM-2 algorithm)
  ease_factor     DECIMAL(4,2) NOT NULL DEFAULT 2.50,
  interval_days   INTEGER NOT NULL DEFAULT 0,
  repetitions     INTEGER NOT NULL DEFAULT 0,
  next_review_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_reviewed_at TIMESTAMPTZ,
  last_rating     flashcard_rating,
  total_reviews   INTEGER NOT NULL DEFAULT 0,
  correct_reviews INTEGER NOT NULL DEFAULT 0,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_flashcards_deck ON flashcards(deck_id, sort_order);
CREATE INDEX idx_flashcards_review ON flashcards(deck_id, next_review_at)
  WHERE next_review_at <= now();  -- Partial index for due cards

-- ═══════════════════════════════════════════════════════════════════════════
-- STUDY PLANS & GOALS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS study_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  frequency       study_plan_frequency NOT NULL DEFAULT 'daily',
  start_date      DATE NOT NULL,
  end_date        DATE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  is_ai_suggested BOOLEAN NOT NULL DEFAULT FALSE,
  ai_suggestion_reason TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_study_plans_student ON study_plans(student_id);
CREATE INDEX idx_study_plans_active ON study_plans(student_id, is_active) WHERE is_active = TRUE;

CREATE TABLE IF NOT EXISTS study_tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         UUID NOT NULL REFERENCES study_plans(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  scheduled_date  DATE NOT NULL,
  start_time      TIME,
  end_time        TIME,
  status          study_task_status NOT NULL DEFAULT 'pending',
  completion_pct  DECIMAL(5,2) NOT NULL DEFAULT 0,
  notes           TEXT,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_study_tasks_plan ON study_tasks(plan_id, scheduled_date);
CREATE INDEX idx_study_tasks_date ON study_tasks(plan_id, scheduled_date, status);

CREATE TABLE IF NOT EXISTS student_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  target_value    DECIMAL(10,2),        -- e.g., target score
  current_value   DECIMAL(10,2) DEFAULT 0,
  unit            TEXT DEFAULT '%',      -- %, points, hours, etc.
  priority        goal_priority NOT NULL DEFAULT 'medium',
  status          goal_status NOT NULL DEFAULT 'not_started',
  deadline        DATE,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_student_goals_student ON student_goals(student_id);
CREATE INDEX idx_student_goals_status ON student_goals(student_id, status);
CREATE INDEX idx_student_goals_subject ON student_goals(student_id, subject_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- STUDENT LEARNING PROGRESS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS student_progress_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  period          progress_period NOT NULL DEFAULT 'weekly',
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,  -- NULL for overall
  avg_score       DECIMAL(5,2),
  exams_taken     INTEGER NOT NULL DEFAULT 0,
  practice_sessions INTEGER NOT NULL DEFAULT 0,
  questions_attempted INTEGER NOT NULL DEFAULT 0,
  questions_correct INTEGER NOT NULL DEFAULT 0,
  study_time_min  INTEGER DEFAULT 0,
  assignments_completed INTEGER NOT NULL DEFAULT 0,
  assignments_pending INTEGER NOT NULL DEFAULT 0,
  flashcards_reviewed INTEGER NOT NULL DEFAULT 0,
  learning_streak INTEGER NOT NULL DEFAULT 0,    -- Consecutive study days
  weak_topics     JSONB DEFAULT '[]',             -- [{topic_id, topic_name, score_pct}]
  strong_topics   JSONB DEFAULT '[]',
  ai_suggestions  JSONB DEFAULT '[]',             -- AI-generated improvement tips
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_student_progress_student ON student_progress_snapshots(student_id, period_start DESC);
CREATE INDEX idx_student_progress_subject ON student_progress_snapshots(student_id, subject_id, period_start DESC);
CREATE INDEX idx_student_progress_period ON student_progress_snapshots(student_id, period, period_start DESC);

-- Daily learning activity (lightweight tracking)
CREATE TABLE IF NOT EXISTS student_daily_activity (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  study_time_min  INTEGER NOT NULL DEFAULT 0,
  questions_attempted INTEGER NOT NULL DEFAULT 0,
  questions_correct INTEGER NOT NULL DEFAULT 0,
  practice_sessions INTEGER NOT NULL DEFAULT 0,
  flashcards_reviewed INTEGER NOT NULL DEFAULT 0,
  assignments_submitted INTEGER NOT NULL DEFAULT 0,
  resources_viewed INTEGER NOT NULL DEFAULT 0,
  tutor_questions  INTEGER NOT NULL DEFAULT 0,
  is_active_day   BOOLEAN NOT NULL DEFAULT FALSE,  -- At least 1 activity
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_student_daily UNIQUE (student_id, activity_date)
);

CREATE INDEX idx_student_daily_student ON student_daily_activity(student_id, activity_date DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- STUDENT NOTIFICATIONS (extends base notifications)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS student_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id       UUID REFERENCES schools(id) ON DELETE SET NULL,
  type            TEXT NOT NULL,         -- new_assignment, upcoming_exam, result_published,
                                         -- teacher_announcement, study_reminder,
                                         -- deadline_approaching, feedback_received
  title           TEXT NOT NULL,
  message         TEXT NOT NULL,
  related_id      UUID,                 -- ID of the related entity
  related_type    TEXT,                 -- assignment, exam, result, resource, etc.
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  action_url      TEXT,                 -- Deep link
  scheduled_for   TIMESTAMPTZ,          -- For scheduled reminders
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_student_notifications_student ON student_notifications(student_id, is_read, created_at DESC);
CREATE INDEX idx_student_notifications_scheduled ON student_notifications(scheduled_for)
  WHERE is_read = FALSE AND scheduled_for IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE ai_tutor_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_tutor_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE practice_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_learning_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_access_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_progress_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_daily_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_notifications ENABLE ROW LEVEL SECURITY;

-- AI Tutor: Students can only access their own conversations
CREATE POLICY "Students can view own conversations"
  ON ai_tutor_conversations FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own conversations"
  ON ai_tutor_conversations FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own conversations"
  ON ai_tutor_conversations FOR UPDATE
  USING (student_id = auth.uid());

CREATE POLICY "Students can delete own conversations"
  ON ai_tutor_conversations FOR DELETE
  USING (student_id = auth.uid());

-- AI Tutor Messages: Cascade through conversation ownership
CREATE POLICY "Students can view own messages"
  ON ai_tutor_messages FOR SELECT
  USING (conversation_id IN (
    SELECT id FROM ai_tutor_conversations WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can insert own messages"
  ON ai_tutor_messages FOR INSERT
  WITH CHECK (conversation_id IN (
    SELECT id FROM ai_tutor_conversations WHERE student_id = auth.uid()
  ));

-- Practice Sessions: Student-only access
CREATE POLICY "Students can view own practice sessions"
  ON practice_sessions FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own practice sessions"
  ON practice_sessions FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own practice sessions"
  ON practice_sessions FOR UPDATE
  USING (student_id = auth.uid());

-- Practice Answers: Through session ownership
CREATE POLICY "Students can view own practice answers"
  ON practice_answers FOR SELECT
  USING (session_id IN (
    SELECT id FROM practice_sessions WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can insert own practice answers"
  ON practice_answers FOR INSERT
  WITH CHECK (session_id IN (
    SELECT id FROM practice_sessions WHERE student_id = auth.uid()
  ));

-- Assignment Submissions: Students own their submissions
CREATE POLICY "Students can view own submissions"
  ON assignment_submissions FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own submissions"
  ON assignment_submissions FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own submissions"
  ON assignment_submissions FOR UPDATE
  USING (student_id = auth.uid());

-- Learning Resources: School-level + public visibility
CREATE POLICY "Students can view accessible resources"
  ON student_learning_resources FOR SELECT
  USING (
    is_public = TRUE
    OR school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

-- Resource Access Log: Own access only
CREATE POLICY "Students can view own access log"
  ON resource_access_log FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can insert own access log"
  ON resource_access_log FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Document Chats: Student-only
CREATE POLICY "Students can view own document chats"
  ON document_chats FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own document chats"
  ON document_chats FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own document chats"
  ON document_chats FOR UPDATE
  USING (student_id = auth.uid());

CREATE POLICY "Students can delete own document chats"
  ON document_chats FOR DELETE
  USING (student_id = auth.uid());

-- Document Chat Messages: Through document ownership
CREATE POLICY "Students can view own doc chat messages"
  ON document_chat_messages FOR SELECT
  USING (document_id IN (
    SELECT id FROM document_chats WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can insert own doc chat messages"
  ON document_chat_messages FOR INSERT
  WITH CHECK (document_id IN (
    SELECT id FROM document_chats WHERE student_id = auth.uid()
  ));

-- Flashcard Decks: Student-only
CREATE POLICY "Students can view own flashcard decks"
  ON flashcard_decks FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own flashcard decks"
  ON flashcard_decks FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own flashcard decks"
  ON flashcard_decks FOR UPDATE
  USING (student_id = auth.uid());

CREATE POLICY "Students can delete own flashcard decks"
  ON flashcard_decks FOR DELETE
  USING (student_id = auth.uid());

-- Flashcards: Through deck ownership
CREATE POLICY "Students can view own flashcards"
  ON flashcards FOR SELECT
  USING (deck_id IN (
    SELECT id FROM flashcard_decks WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can create own flashcards"
  ON flashcards FOR INSERT
  WITH CHECK (deck_id IN (
    SELECT id FROM flashcard_decks WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can update own flashcards"
  ON flashcards FOR UPDATE
  USING (deck_id IN (
    SELECT id FROM flashcard_decks WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can delete own flashcards"
  ON flashcards FOR DELETE
  USING (deck_id IN (
    SELECT id FROM flashcard_decks WHERE student_id = auth.uid()
  ));

-- Study Plans: Student-only
CREATE POLICY "Students can view own study plans"
  ON study_plans FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own study plans"
  ON study_plans FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own study plans"
  ON study_plans FOR UPDATE
  USING (student_id = auth.uid());

CREATE POLICY "Students can delete own study plans"
  ON study_plans FOR DELETE
  USING (student_id = auth.uid());

-- Study Tasks: Through plan ownership
CREATE POLICY "Students can view own study tasks"
  ON study_tasks FOR SELECT
  USING (plan_id IN (
    SELECT id FROM study_plans WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can create own study tasks"
  ON study_tasks FOR INSERT
  WITH CHECK (plan_id IN (
    SELECT id FROM study_plans WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can update own study tasks"
  ON study_tasks FOR UPDATE
  USING (plan_id IN (
    SELECT id FROM study_plans WHERE student_id = auth.uid()
  ));

CREATE POLICY "Students can delete own study tasks"
  ON study_tasks FOR DELETE
  USING (plan_id IN (
    SELECT id FROM study_plans WHERE student_id = auth.uid()
  ));

-- Student Goals: Student-only
CREATE POLICY "Students can view own goals"
  ON student_goals FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can create own goals"
  ON student_goals FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own goals"
  ON student_goals FOR UPDATE
  USING (student_id = auth.uid());

CREATE POLICY "Students can delete own goals"
  ON student_goals FOR DELETE
  USING (student_id = auth.uid());

-- Student Progress: Student-only
CREATE POLICY "Students can view own progress"
  ON student_progress_snapshots FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "System can insert progress"
  ON student_progress_snapshots FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Daily Activity: Student-only
CREATE POLICY "Students can view own daily activity"
  ON student_daily_activity FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can insert own daily activity"
  ON student_daily_activity FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own daily activity"
  ON student_daily_activity FOR UPDATE
  USING (student_id = auth.uid());

-- Student Notifications: Student-only
CREATE POLICY "Students can view own notifications"
  ON student_notifications FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can update own notifications"
  ON student_notifications FOR UPDATE
  USING (student_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGER: Auto-update timestamps
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_tutor_conversations_updated
  BEFORE UPDATE ON ai_tutor_conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_assignment_submissions_updated
  BEFORE UPDATE ON assignment_submissions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_student_learning_resources_updated
  BEFORE UPDATE ON student_learning_resources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_document_chats_updated
  BEFORE UPDATE ON document_chats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_flashcard_decks_updated
  BEFORE UPDATE ON flashcard_decks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_flashcards_updated
  BEFORE UPDATE ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_study_plans_updated
  BEFORE UPDATE ON study_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_study_tasks_updated
  BEFORE UPDATE ON study_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_student_goals_updated
  BEFORE UPDATE ON student_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_student_daily_activity_updated
  BEFORE UPDATE ON student_daily_activity
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGER: Update flashcard_deck card_count on insert/delete
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_deck_card_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE flashcard_decks SET card_count = card_count + 1 WHERE id = NEW.deck_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE flashcard_decks SET card_count = GREATEST(card_count - 1, 0) WHERE id = OLD.deck_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_flashcard_count_insert
  AFTER INSERT ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_deck_card_count();

CREATE TRIGGER trg_flashcard_count_delete
  AFTER DELETE ON flashcards
  FOR EACH ROW EXECUTE FUNCTION update_deck_card_count();

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGER: Update resource view/download counts
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_resource_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.access_type = 'view' THEN
    UPDATE student_learning_resources SET view_count = view_count + 1 WHERE id = NEW.resource_id;
  ELSIF NEW.access_type = 'download' THEN
    UPDATE student_learning_resources SET download_count = download_count + 1 WHERE id = NEW.resource_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resource_access_count
  AFTER INSERT ON resource_access_log
  FOR EACH ROW EXECUTE FUNCTION update_resource_counts();

-- ═══════════════════════════════════════════════════════════════════════════
-- AUDIT LOG TRIGGER (reuses existing audit_log table)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION log_student_portal_audit()
RETURNS TRIGGER AS $$
DECLARE
  table_name TEXT := TG_TABLE_NAME;
  operation  TEXT := TG_OP;
  user_id    UUID;
  record_id  UUID;
BEGIN
  IF operation = 'INSERT' THEN
    record_id := NEW.id;
    user_id := COALESCE(NEW.student_id, NEW.student_id);
  ELSIF operation = 'UPDATE' THEN
    record_id := NEW.id;
    user_id := COALESCE(NEW.student_id, OLD.student_id);
  ELSIF operation = 'DELETE' THEN
    record_id := OLD.id;
    user_id := OLD.student_id;
  END IF;

  INSERT INTO audit_log (user_id, action, table_name, record_id, new_data, old_data)
  VALUES (
    user_id,
    operation,
    table_name,
    record_id,
    CASE WHEN operation IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
    CASE WHEN operation IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit to critical tables
CREATE TRIGGER trg_audit_assignment_submissions
  AFTER INSERT OR UPDATE OR DELETE ON assignment_submissions
  FOR EACH ROW EXECUTE FUNCTION log_student_portal_audit();

CREATE TRIGGER trg_audit_practice_sessions
  AFTER INSERT OR UPDATE ON practice_sessions
  FOR EACH ROW EXECUTE FUNCTION log_student_portal_audit();

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER VIEWS
-- ═══════════════════════════════════════════════════════════════════════════

-- Student dashboard overview (fast read)
CREATE OR REPLACE VIEW v_student_dashboard AS
SELECT
  u.id AS student_id,
  u.school_id,
  u.full_name,
  -- Upcoming exams (next 7 days)
  (SELECT COUNT(*) FROM exam_attempts ea
   JOIN exams e ON ea.exam_id = e.id
   WHERE ea.student_id = u.id
     AND e.status = 'active'
     AND e.start_time <= now() + interval '7 days') AS upcoming_exams,
  -- Pending assignments
  (SELECT COUNT(*) FROM assignment_submissions a
   WHERE a.student_id = u.id
     AND a.status IN ('draft', 'submitted')) AS pending_assignments,
  -- Learning streak
  COALESCE((SELECT learning_streak FROM student_progress_snapshots
            WHERE student_id = u.id
            ORDER BY period_start DESC LIMIT 1), 0) AS learning_streak,
  -- Recent average score
  COALESCE((SELECT avg_score FROM student_progress_snapshots
            WHERE student_id = u.id AND subject_id IS NULL
            ORDER BY period_start DESC LIMIT 1), 0) AS recent_avg_score,
  -- Practice sessions this week
  (SELECT COUNT(*) FROM practice_sessions
   WHERE student_id = u.id
     AND started_at >= date_trunc('week', now())) AS practice_this_week,
  -- Unread notifications
  (SELECT COUNT(*) FROM student_notifications
   WHERE student_id = u.id AND is_read = FALSE) AS unread_notifications
FROM users u
WHERE u.role = 'student';
