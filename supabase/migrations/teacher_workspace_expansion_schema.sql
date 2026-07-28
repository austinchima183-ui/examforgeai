-- ═══════════════════════════════════════════════════════════════════════════════
-- EXAMFORGE AI — TEACHER WORKSPACE EXPANSION SCHEMA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Adds: AI Presentations, Communications, Tasks/To-Dos, Rubrics, Oral Questions,
-- Practical Assessments, Collaboration (sharing, comments), Enhanced Dashboard.
-- Depends on: schema.sql, teacher_workspace_schema.sql, school_management_schema.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── NEW CUSTOM ENUMS ──────────────────────────────────────────────────────────

CREATE TYPE presentation_type AS ENUM (
  'powerpoint',
  'teaching_slides',
  'infographic',
  'diagram',
  'flowchart',
  'mind_map',
  'summary_sheet'
);

CREATE TYPE communication_type AS ENUM (
  'parent_letter',
  'student_feedback',
  'email',
  'sms',
  'announcement',
  'meeting_invitation',
  'permission_letter',
  'certificate'
);

CREATE TYPE communication_tone AS ENUM (
  'formal',
  'friendly',
  'encouraging',
  'professional'
);

CREATE TYPE task_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

CREATE TYPE task_status AS ENUM (
  'pending',
  'in_progress',
  'completed',
  'cancelled'
);

CREATE TYPE rubric_criterion_level AS ENUM (
  'beginning',
  'developing',
  'proficient',
  'exemplary'
);

CREATE TYPE assessment_type AS ENUM (
  'oral',
  'practical',
  'rubric_based'
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRESENTATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- AI-generated and manually created presentations, slides, infographics,
-- diagrams, flowcharts, mind maps, and summary sheets.

CREATE TABLE IF NOT EXISTS presentations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,

  title           TEXT NOT NULL,
  description     TEXT,
  presentation_type presentation_type NOT NULL DEFAULT 'teaching_slides',

  -- Slide content as JSONB: array of { title, body, notes, layout, imageUrl }
  slides          JSONB NOT NULL DEFAULT '[]'::jsonb,
  speaker_notes   TEXT,
  total_slides    INTEGER NOT NULL DEFAULT 0,

  -- AI generation context
  topic           TEXT,
  curriculum      curriculum_type,
  difficulty      student_level DEFAULT 'intermediate',
  custom_instructions TEXT,

  -- Generation metadata
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_model        TEXT,
  generation_time_ms INTEGER,
  tokens_used     INTEGER,

  -- Status & sharing
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  is_favorite     BOOLEAN NOT NULL DEFAULT FALSE,
  is_template     BOOLEAN NOT NULL DEFAULT FALSE,
  template_id     UUID REFERENCES presentations(id) ON DELETE SET NULL,

  -- Export tracking
  last_export_format TEXT,
  last_exported_at   TIMESTAMPTZ,

  -- Version
  version         INTEGER NOT NULL DEFAULT 1,

  -- Tags for search
  tags            TEXT[] DEFAULT '{}',

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_presentations_school ON presentations(school_id);
CREATE INDEX idx_presentations_teacher ON presentations(teacher_id);
CREATE INDEX idx_presentations_subject ON presentations(subject_id);
CREATE INDEX idx_presentations_class ON presentations(class_id);
CREATE INDEX idx_presentations_type ON presentations(presentation_type);
CREATE INDEX idx_presentations_published ON presentations(is_published) WHERE is_published = TRUE;
CREATE INDEX idx_presentations_archived ON presentations(is_archived) WHERE is_archived = FALSE;
CREATE INDEX idx_presentations_favorite ON presentations(teacher_id, is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX idx_presentations_template ON presentations(is_template) WHERE is_template = TRUE;
CREATE INDEX idx_presentations_tags ON presentations USING GIN(tags);
CREATE INDEX idx_presentations_created ON presentations(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRESENTATION VERSIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS presentation_versions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  presentation_id UUID NOT NULL REFERENCES presentations(id) ON DELETE CASCADE,
  version_number  INTEGER NOT NULL,
  snapshot        JSONB NOT NULL,
  change_summary  TEXT,
  created_by      UUID NOT NULL REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(presentation_id, version_number)
);

CREATE INDEX idx_presentation_versions_presentation ON presentation_versions(presentation_id, version_number DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMUNICATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- AI-generated letters, feedback, emails, SMS, announcements, certificates.

CREATE TABLE IF NOT EXISTS communications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,

  title           TEXT NOT NULL,
  content         TEXT NOT NULL,
  communication_type communication_type NOT NULL,
  tone            communication_tone NOT NULL DEFAULT 'professional',

  -- Recipients (can be individuals or groups)
  recipient_type  TEXT NOT NULL DEFAULT 'class', -- 'class', 'student', 'parent', 'all', 'custom'
  recipient_ids   UUID[] DEFAULT '{}',

  -- AI generation context
  purpose         TEXT,
  custom_instructions TEXT,
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_model        TEXT,
  generation_time_ms INTEGER,
  tokens_used     INTEGER,

  -- Status
  is_sent         BOOLEAN NOT NULL DEFAULT FALSE,
  is_draft        BOOLEAN NOT NULL DEFAULT TRUE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  is_template     BOOLEAN NOT NULL DEFAULT FALSE,

  sent_at         TIMESTAMPTZ,
  tags            TEXT[] DEFAULT '{}',

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_communications_school ON communications(school_id);
CREATE INDEX idx_communications_teacher ON communications(teacher_id);
CREATE INDEX idx_communications_type ON communications(communication_type);
CREATE INDEX idx_communications_tone ON communications(tone);
CREATE INDEX idx_communications_draft ON communications(is_draft) WHERE is_draft = TRUE;
CREATE INDEX idx_communications_sent ON communications(is_sent) WHERE is_sent = TRUE;
CREATE INDEX idx_communications_template ON communications(is_template) WHERE is_template = TRUE;
CREATE INDEX idx_communications_created ON communications(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TASKS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Tasks, to-dos, reminders, and meeting scheduling.

CREATE TABLE IF NOT EXISTS tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  title           TEXT NOT NULL,
  description     TEXT,
  priority        task_priority NOT NULL DEFAULT 'medium',
  status          task_status NOT NULL DEFAULT 'pending',

  -- Task categorization
  category        TEXT NOT NULL DEFAULT 'general', -- 'lesson', 'grading', 'meeting', 'admin', 'personal', 'general'
  related_resource_type TEXT, -- 'lesson_plan', 'worksheet', 'assignment', 'exam', etc.
  related_resource_id   UUID,

  -- Due date & reminders
  due_date        TIMESTAMPTZ,
  reminder_at     TIMESTAMPTZ,
  is_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE,

  -- Recurrence
  is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule TEXT, -- RFC 5545 RRULE format

  -- Subtasks
  subtasks        JSONB DEFAULT '[]'::jsonb, -- [{title, isCompleted}]

  -- Completion
  completed_at    TIMESTAMPTZ,
  completion_notes TEXT,

  -- Assignment to others
  assigned_to     UUID REFERENCES auth.users(id),

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tasks_school ON tasks(school_id);
CREATE INDEX idx_tasks_teacher ON tasks(teacher_id);
CREATE INDEX idx_tasks_status ON tasks(teacher_id, status);
CREATE INDEX idx_tasks_priority ON tasks(teacher_id, priority);
CREATE INDEX idx_tasks_due_date ON tasks(teacher_id, due_date) WHERE status != 'completed';
CREATE INDEX idx_tasks_category ON tasks(teacher_id, category);
CREATE INDEX idx_tasks_overdue ON tasks(teacher_id, due_date) WHERE due_date < now() AND status = 'pending';

-- ═══════════════════════════════════════════════════════════════════════════════
-- RUBRICS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Assessment rubrics with criteria and performance levels.

CREATE TABLE IF NOT EXISTS rubrics (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,

  title           TEXT NOT NULL,
  description     TEXT,

  -- Rubric structure as JSONB
  -- [{ criterion, weight, levels: [{ level, description, score }] }]
  criteria        JSONB NOT NULL DEFAULT '[]'::jsonb,

  total_points    NUMERIC(6,2) NOT NULL DEFAULT 0,

  -- AI generation context
  topic           TEXT,
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_model        TEXT,

  -- Status
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  is_template     BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,

  tags            TEXT[] DEFAULT '{}',

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_rubrics_school ON rubrics(school_id);
CREATE INDEX idx_rubrics_teacher ON rubrics(teacher_id);
CREATE INDEX idx_rubrics_subject ON rubrics(subject_id);
CREATE INDEX idx_rubrics_template ON rubrics(is_template) WHERE is_template = TRUE;
CREATE INDEX idx_rubrics_published ON rubrics(is_published) WHERE is_published = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ORAL QUESTIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS oral_questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,

  title           TEXT NOT NULL,
  description     TEXT,

  -- Questions as JSONB array: [{ question, expectedAnswer, marks, difficulty, bloomLevel }]
  questions       JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_marks     NUMERIC(6,2) NOT NULL DEFAULT 0,
  estimated_duration_minutes INTEGER NOT NULL DEFAULT 30,

  -- AI generation context
  topic           TEXT,
  curriculum      curriculum_type,
  difficulty      student_level DEFAULT 'intermediate',
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_model        TEXT,

  -- Status
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,

  tags            TEXT[] DEFAULT '{}',

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_oral_questions_school ON oral_questions(school_id);
CREATE INDEX idx_oral_questions_teacher ON oral_questions(teacher_id);
CREATE INDEX idx_oral_questions_subject ON oral_questions(subject_id);
CREATE INDEX idx_oral_questions_published ON oral_questions(is_published) WHERE is_published = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PRACTICAL ASSESSMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS practical_assessments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,

  title           TEXT NOT NULL,
  description     TEXT,

  -- Practical details
  objectives      TEXT[] DEFAULT '{}',
  materials_needed TEXT[] DEFAULT '{}',
  procedure_steps TEXT[] DEFAULT '{}',
  safety_precautions TEXT[] DEFAULT '{}',
  expected_results TEXT,
  assessment_criteria JSONB DEFAULT '[]'::jsonb,

  total_marks     NUMERIC(6,2) NOT NULL DEFAULT 0,
  estimated_duration_minutes INTEGER NOT NULL DEFAULT 60,

  -- AI generation context
  topic           TEXT,
  curriculum      curriculum_type,
  difficulty      student_level DEFAULT 'intermediate',
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_model        TEXT,

  -- Associated rubric
  rubric_id       UUID REFERENCES rubrics(id) ON DELETE SET NULL,

  -- Status
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,

  tags            TEXT[] DEFAULT '{}',

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_practical_assessments_school ON practical_assessments(school_id);
CREATE INDEX idx_practical_assessments_teacher ON practical_assessments(teacher_id);
CREATE INDEX idx_practical_assessments_subject ON practical_assessments(subject_id);
CREATE INDEX idx_practical_assessments_published ON practical_assessments(is_published) WHERE is_published = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- COLLABORATION: SHARED RESOURCES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS shared_resources (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- The resource being shared
  resource_type   TEXT NOT NULL, -- 'lesson_plan', 'worksheet', 'presentation', 'rubric', etc.
  resource_id     UUID NOT NULL,

  -- Who shared it
  shared_by       UUID NOT NULL REFERENCES auth.users(id),

  -- Who it's shared with
  shared_with     UUID NOT NULL REFERENCES auth.users(id),

  -- Permissions
  can_edit        BOOLEAN NOT NULL DEFAULT FALSE,
  can_view        BOOLEAN NOT NULL DEFAULT TRUE,
  can_comment     BOOLEAN NOT NULL DEFAULT TRUE,
  can_download    BOOLEAN NOT NULL DEFAULT TRUE,

  -- Message when sharing
  message         TEXT,

  is_accepted     BOOLEAN DEFAULT NULL, -- NULL = pending, TRUE = accepted, FALSE = declined

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_shared_resources_resource ON shared_resources(resource_type, resource_id);
CREATE INDEX idx_shared_resources_shared_by ON shared_resources(shared_by);
CREATE INDEX idx_shared_resources_shared_with ON shared_resources(shared_with);
CREATE INDEX idx_shared_resources_pending ON shared_resources(shared_with, is_accepted) WHERE is_accepted IS NULL;

-- ═══════════════════════════════════════════════════════════════════════════════
-- COLLABORATION: COMMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS collaboration_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- What is being commented on
  resource_type   TEXT NOT NULL,
  resource_id     UUID NOT NULL,

  -- Comment content
  content         TEXT NOT NULL,

  -- Author
  author_id       UUID NOT NULL REFERENCES auth.users(id),

  -- Threading: reply to another comment
  parent_comment_id UUID REFERENCES collaboration_comments(id) ON DELETE CASCADE,

  -- Metadata
  is_resolved     BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_by     UUID REFERENCES auth.users(id),
  resolved_at     TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_resource ON collaboration_comments(resource_type, resource_id);
CREATE INDEX idx_comments_author ON collaboration_comments(author_id);
CREATE INDEX idx_comments_parent ON collaboration_comments(parent_comment_id);
CREATE INDEX idx_comments_created ON collaboration_comments(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TEACHING STATISTICS MATERIALIZED VIEW
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW IF NOT EXISTS teacher_statistics AS
SELECT
  t.teacher_id,
  t.school_id,
  COUNT(DISTINCT lp.id) AS total_lesson_plans,
  COUNT(DISTINCT lp.id) FILTER (WHERE lp.is_published) AS published_lesson_plans,
  COUNT(DISTINCT sw.id) AS total_schemes,
  COUNT(DISTINCT ws.id) AS total_worksheets,
  COUNT(DISTINCT wa.id) AS total_assignments,
  COUNT(DISTINCT wa.id) FILTER (WHERE wa.status = 'published') AS published_assignments,
  COUNT(DISTINCT p.id) AS total_presentations,
  COUNT(DISTINCT r.id) AS total_rubrics,
  COUNT(DISTINCT tr.id) FILTER (WHERE tr.is_favorite) AS favorite_resources,
  COUNT(DISTINCT ach.id) AS total_ai_generations,
  SUM(COALESCE(ach.tokens_used, 0)) AS total_tokens_used,
  COUNT(DISTINCT tsk.id) FILTER (WHERE tsk.status = 'completed') AS completed_tasks,
  COUNT(DISTINCT tsk.id) FILTER (WHERE tsk.status = 'pending') AS pending_tasks,
  COUNT(DISTINCT tsk.id) FILTER (WHERE tsk.due_date < now() AND tsk.status = 'pending') AS overdue_tasks
FROM (
  SELECT DISTINCT teacher_id, school_id FROM lesson_plans
  UNION DISTINCT SELECT teacher_id, school_id FROM schemes_of_work
  UNION DISTINCT SELECT teacher_id, school_id FROM worksheets
) t
LEFT JOIN lesson_plans lp ON lp.teacher_id = t.teacher_id
LEFT JOIN schemes_of_work sw ON sw.teacher_id = t.teacher_id
LEFT JOIN worksheets ws ON ws.teacher_id = t.teacher_id
LEFT JOIN workspace_assignments wa ON wa.teacher_id = t.teacher_id
LEFT JOIN presentations p ON p.teacher_id = t.teacher_id
LEFT JOIN rubrics r ON r.teacher_id = t.teacher_id
LEFT JOIN teaching_resources tr ON tr.teacher_id = t.teacher_id
LEFT JOIN ai_content_history ach ON ach.teacher_id = t.teacher_id
LEFT JOIN tasks tsk ON tsk.teacher_id = t.teacher_id
GROUP BY t.teacher_id, t.school_id;

CREATE UNIQUE INDEX idx_teacher_statistics_teacher ON teacher_statistics(teacher_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE presentations ENABLE ROW LEVEL SECURITY;
ALTER TABLE presentation_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE rubrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE oral_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE practical_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_comments ENABLE ROW LEVEL SECURITY;

-- ─── Presentations RLS ─────────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own presentations"
  ON presentations FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can view shared presentations"
  ON presentations FOR SELECT
  USING (
    id IN (
      SELECT resource_id FROM shared_resources
      WHERE resource_type = 'presentation'
      AND shared_with = auth.uid()
      AND is_accepted = TRUE
    )
  );

CREATE POLICY "School admins can view school presentations"
  ON presentations FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.school_id = s.id
      WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin')
    )
  );

CREATE POLICY "Teachers can create own presentations"
  ON presentations FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own presentations"
  ON presentations FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own presentations"
  ON presentations FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Presentation Versions RLS ────────────────────────────────────────────────

CREATE POLICY "Users can view versions of accessible presentations"
  ON presentation_versions FOR SELECT
  USING (
    presentation_id IN (SELECT id FROM presentations)
  );

CREATE POLICY "Users can create versions of own presentations"
  ON presentation_versions FOR INSERT
  WITH CHECK (
    presentation_id IN (SELECT id FROM presentations WHERE teacher_id = auth.uid())
  );

-- ─── Communications RLS ───────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own communications"
  ON communications FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "School admins can view school communications"
  ON communications FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.school_id = s.id
      WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin')
    )
  );

CREATE POLICY "Teachers can create own communications"
  ON communications FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own communications"
  ON communications FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own communications"
  ON communications FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Tasks RLS ────────────────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own tasks"
  ON tasks FOR SELECT
  USING (teacher_id = auth.uid() OR assigned_to = auth.uid());

CREATE POLICY "Teachers can create own tasks"
  ON tasks FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own tasks"
  ON tasks FOR UPDATE
  USING (teacher_id = auth.uid() OR assigned_to = auth.uid());

CREATE POLICY "Teachers can delete own tasks"
  ON tasks FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Rubrics RLS ──────────────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own rubrics"
  ON rubrics FOR SELECT
  USING (teacher_id = auth.uid() OR is_template = TRUE);

CREATE POLICY "Teachers can view shared rubrics"
  ON rubrics FOR SELECT
  USING (
    id IN (
      SELECT resource_id FROM shared_resources
      WHERE resource_type = 'rubric'
      AND shared_with = auth.uid()
      AND is_accepted = TRUE
    )
  );

CREATE POLICY "Teachers can create own rubrics"
  ON rubrics FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own rubrics"
  ON rubrics FOR UPDATE
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own rubrics"
  ON rubrics FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Oral Questions RLS ───────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own oral questions"
  ON oral_questions FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can create own oral questions"
  ON oral_questions FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own oral questions"
  ON oral_questions FOR UPDATE
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own oral questions"
  ON oral_questions FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Practical Assessments RLS ────────────────────────────────────────────────

CREATE POLICY "Teachers can view own practical assessments"
  ON practical_assessments FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can create own practical assessments"
  ON practical_assessments FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own practical assessments"
  ON practical_assessments FOR UPDATE
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own practical assessments"
  ON practical_assessments FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Shared Resources RLS ─────────────────────────────────────────────────────

CREATE POLICY "Users can view resources shared with or by them"
  ON shared_resources FOR SELECT
  USING (shared_by = auth.uid() OR shared_with = auth.uid());

CREATE POLICY "Users can share resources"
  ON shared_resources FOR INSERT
  WITH CHECK (shared_by = auth.uid());

CREATE POLICY "Users can update shares they received"
  ON shared_resources FOR UPDATE
  USING (shared_with = auth.uid() OR shared_by = auth.uid());

CREATE POLICY "Users can delete their own shares"
  ON shared_resources FOR DELETE
  USING (shared_by = auth.uid() OR shared_with = auth.uid());

-- ─── Collaboration Comments RLS ───────────────────────────────────────────────

CREATE POLICY "Users can view comments on accessible resources"
  ON collaboration_comments FOR SELECT
  USING (
    author_id = auth.uid()
    OR resource_id IN (
      SELECT id FROM lesson_plans WHERE teacher_id = auth.uid()
      UNION ALL
      SELECT id FROM worksheets WHERE teacher_id = auth.uid()
      UNION ALL
      SELECT id FROM presentations WHERE teacher_id = auth.uid()
      UNION ALL
      SELECT resource_id FROM shared_resources
        WHERE shared_with = auth.uid() AND is_accepted = TRUE
    )
  );

CREATE POLICY "Users can create comments on accessible resources"
  ON collaboration_comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Users can update own comments"
  ON collaboration_comments FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "Users can delete own comments"
  ON collaboration_comments FOR DELETE
  USING (author_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Auto-update updated_at
CREATE TRIGGER set_presentations_updated_at
  BEFORE UPDATE ON presentations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_communications_updated_at
  BEFORE UPDATE ON communications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_rubrics_updated_at
  BEFORE UPDATE ON rubrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_oral_questions_updated_at
  BEFORE UPDATE ON oral_questions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_practical_assessments_updated_at
  BEFORE UPDATE ON practical_assessments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_collaboration_comments_updated_at
  BEFORE UPDATE ON collaboration_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create version snapshot on presentation update
CREATE OR REPLACE FUNCTION create_presentation_version()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.slides IS DISTINCT FROM NEW.slides OR OLD.title IS DISTINCT FROM NEW.title THEN
    INSERT INTO presentation_versions (presentation_id, version_number, snapshot, change_summary, created_by)
    VALUES (
      NEW.id,
      COALESCE((SELECT MAX(version_number) FROM presentation_versions WHERE presentation_id = NEW.id), 0) + 1,
      jsonb_build_object(
        'title', NEW.title,
        'description', NEW.description,
        'slides', NEW.slides,
        'speaker_notes', NEW.speaker_notes
      ),
      'Auto-saved version',
      NEW.teacher_id
    );
    NEW.version := NEW.version + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_presentation_version
  BEFORE UPDATE ON presentations
  FOR EACH ROW EXECUTE FUNCTION create_presentation_version();

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get enhanced workspace dashboard data
CREATE OR REPLACE FUNCTION get_enhanced_workspace_dashboard(p_teacher_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_school_id UUID;
BEGIN
  SELECT school_id INTO v_school_id FROM users WHERE id = p_teacher_id;

  SELECT jsonb_build_object(
    'stats', jsonb_build_object(
      'lesson_plans', (SELECT COUNT(*) FROM lesson_plans WHERE teacher_id = p_teacher_id AND is_archived = FALSE),
      'worksheets', (SELECT COUNT(*) FROM worksheets WHERE teacher_id = p_teacher_id),
      'assignments', (SELECT COUNT(*) FROM workspace_assignments WHERE teacher_id = p_teacher_id),
      'presentations', (SELECT COUNT(*) FROM presentations WHERE teacher_id = p_teacher_id AND is_archived = FALSE),
      'rubrics', (SELECT COUNT(*) FROM rubrics WHERE teacher_id = p_teacher_id AND is_archived = FALSE),
      'resources', (SELECT COUNT(*) FROM teaching_resources WHERE teacher_id = p_teacher_id),
      'ai_generations', (SELECT COUNT(*) FROM ai_content_history WHERE teacher_id = p_teacher_id),
      'pending_tasks', (SELECT COUNT(*) FROM tasks WHERE teacher_id = p_teacher_id AND status = 'pending'),
      'overdue_tasks', (SELECT COUNT(*) FROM tasks WHERE teacher_id = p_teacher_id AND status = 'pending' AND due_date < now()),
      'shared_with_me', (SELECT COUNT(*) FROM shared_resources WHERE shared_with = p_teacher_id AND is_accepted = TRUE)
    ),
    'today_classes', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', ce.id,
          'title', ce.title,
          'start_time', ce.start_time,
          'end_time', ce.end_time,
          'event_type', ce.event_type
        )
      ), '[]'::jsonb)
      FROM calendar_events ce
      WHERE ce.teacher_id = p_teacher_id
      AND ce.start_time::date = CURRENT_DATE
      ORDER BY ce.start_time
    ),
    'pending_assignments', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', wa.id,
          'title', wa.title,
          'deadline', wa.deadline,
          'status', wa.status
        )
      ), '[]'::jsonb)
      FROM workspace_assignments wa
      WHERE wa.teacher_id = p_teacher_id
      AND wa.status IN ('draft', 'published')
      ORDER BY wa.deadline NULLS LAST
      LIMIT 5
    ),
    'recent_documents', (
      SELECT COALESCE(jsonb_agg(subq), '[]'::jsonb) FROM (
        SELECT jsonb_build_object('id', id, 'title', title, 'type', 'lesson_plan', 'updated_at', updated_at) FROM lesson_plans WHERE teacher_id = p_teacher_id ORDER BY updated_at DESC LIMIT 2
        UNION ALL
        SELECT jsonb_build_object('id', id, 'title', title, 'type', 'worksheet', 'updated_at', updated_at) FROM worksheets WHERE teacher_id = p_teacher_id ORDER BY updated_at DESC LIMIT 2
        UNION ALL
        SELECT jsonb_build_object('id', id, 'title', title, 'type', 'presentation', 'updated_at', updated_at) FROM presentations WHERE teacher_id = p_teacher_id AND is_archived = FALSE ORDER BY updated_at DESC LIMIT 2
        ORDER BY updated_at DESC LIMIT 6
      ) subq
    ),
    'saved_templates', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('id', id, 'name', name, 'template_type', template_type, 'usage_count', usage_count)
      ), '[]'::jsonb)
      FROM workspace_templates
      WHERE teacher_id = p_teacher_id OR is_public = TRUE
      ORDER BY usage_count DESC LIMIT 6
    ),
    'upcoming_events', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('id', id, 'title', title, 'start_time', start_time, 'end_time', end_time, 'event_type', event_type)
      ), '[]'::jsonb)
      FROM calendar_events
      WHERE teacher_id = p_teacher_id
      AND start_time > now()
      ORDER BY start_time LIMIT 5
    ),
    'teaching_statistics', (
      SELECT jsonb_build_object(
        'total_students', COALESCE(SUM(jsonb_array_length(COALESCE(students, '[]'::jsonb))), 0),
        'classes_taught', (SELECT COUNT(DISTINCT class_id) FROM class_subjects WHERE teacher_id = p_teacher_id),
        'questions_generated', (SELECT COUNT(*) FROM ai_content_history WHERE teacher_id = p_teacher_id AND action = 'generate_questions'),
        'resources_shared', (SELECT COUNT(*) FROM shared_resources WHERE shared_by = p_teacher_id)
      )
      FROM classes c WHERE c.id IN (SELECT class_id FROM class_subjects WHERE teacher_id = p_teacher_id)
    ),
    'notifications_count', (
      SELECT COUNT(*) FROM shared_resources WHERE shared_with = p_teacher_id AND is_accepted IS NULL
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh teaching statistics
CREATE OR REPLACE FUNCTION refresh_teacher_statistics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY teacher_statistics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SEED DATA: DEFAULT TEMPLATES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Default rubric template
INSERT INTO rubrics (school_id, teacher_id, title, description, criteria, total_points, is_template)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid,
   'Default Assessment Rubric',
   'A general-purpose rubric template for any subject assessment.',
   '[
     {
       "criterion": "Understanding of Concepts",
       "weight": 30,
       "levels": [
         {"level": "beginning", "description": "Shows minimal understanding", "score": 1},
         {"level": "developing", "description": "Shows partial understanding", "score": 2},
         {"level": "proficient", "description": "Shows solid understanding", "score": 3},
         {"level": "exemplary", "description": "Shows exceptional understanding", "score": 4}
       ]
     },
     {
       "criterion": "Application of Knowledge",
       "weight": 30,
       "levels": [
         {"level": "beginning", "description": "Cannot apply concepts", "score": 1},
         {"level": "developing", "description": "Applies concepts with assistance", "score": 2},
         {"level": "proficient", "description": "Applies concepts independently", "score": 3},
         {"level": "exemplary", "description": "Applies concepts creatively", "score": 4}
       ]
     },
     {
       "criterion": "Communication",
       "weight": 20,
       "levels": [
         {"level": "beginning", "description": "Communication is unclear", "score": 1},
         {"level": "developing", "description": "Communication is somewhat clear", "score": 2},
         {"level": "proficient", "description": "Communication is clear and organized", "score": 3},
         {"level": "exemplary", "description": "Communication is exceptional", "score": 4}
       ]
     },
     {
       "criterion": "Effort & Participation",
       "weight": 20,
       "levels": [
         {"level": "beginning", "description": "Minimal effort shown", "score": 1},
         {"level": "developing", "description": "Some effort shown", "score": 2},
         {"level": "proficient", "description": "Consistent effort shown", "score": 3},
         {"level": "exemplary", "description": "Exceptional effort and leadership", "score": 4}
       ]
     }
   ]'::jsonb,
   16.00,
   TRUE
  ) ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHEDULED JOBS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Refresh teacher_statistics every 15 minutes
SELECT cron.schedule(
  'refresh-teacher-statistics',
  '*/15 * * * *',
  $$ SELECT refresh_teacher_statistics(); $$
) WHERE EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron');
