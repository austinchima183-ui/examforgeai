-- ═══════════════════════════════════════════════════════════════════════════════
-- EXAMFORGE AI — TEACHER WORKSPACE MODULE SCHEMA
-- ═══════════════════════════════════════════════════════════════════════════════
-- AI-powered productivity suite for teachers: lesson plans, schemes of work,
-- worksheets, assignments, report comments, teaching resources, content
-- assistant, resource library, and calendar/planner.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── CUSTOM ENUMS ──────────────────────────────────────────────────────────────

CREATE TYPE teaching_style AS ENUM (
  'lecture',
  'interactive',
  'discussion',
  'hands_on',
  'flipped',
  'blended',
  'inquiry_based',
  'project_based',
  'cooperative'
);

CREATE TYPE student_level AS ENUM (
  'beginner',
  'elementary',
  'intermediate',
  'advanced',
  'expert'
);

CREATE TYPE worksheet_type AS ENUM (
  'classwork',
  'homework',
  'revision',
  'practice',
  'activity',
  'assessment'
);

CREATE TYPE plan_duration AS ENUM (
  'weekly',
  'monthly',
  'term',
  'annual'
);

CREATE TYPE curriculum_type AS ENUM (
  'nigerian',
  'waec',
  'neco',
  'bece',
  'jamb',
  'igcse',
  'cambridge',
  'ib',
  'custom'
);

CREATE TYPE resource_type AS ENUM (
  'notes',
  'slides',
  'handout',
  'study_guide',
  'revision_material',
  'classroom_activity',
  'rubric',
  'template'
);

CREATE TYPE content_action AS ENUM (
  'explain',
  'simplify',
  'expand',
  'rewrite',
  'translate',
  'generate_examples',
  'generate_analogies',
  'create_discussion',
  'create_activity'
);

CREATE TYPE assignment_status AS ENUM (
  'draft',
  'published',
  'closed',
  'graded'
);

CREATE TYPE event_type AS ENUM (
  'class',
  'meeting',
  'deadline',
  'reminder',
  'exam',
  'holiday',
  'personal',
  'other'
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- LESSON PLANS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lesson_plans (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  topic_id                UUID REFERENCES topics(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  subject                 TEXT NOT NULL,
  class_name              TEXT,
  topic                   TEXT,
  subtopic                TEXT,
  curriculum              curriculum_type DEFAULT 'nigerian',
  learning_objectives     TEXT[] DEFAULT '{}',
  learning_outcomes       TEXT[] DEFAULT '{}',
  teaching_materials      TEXT[] DEFAULT '{}',
  classroom_activities    JSONB DEFAULT '[]',
  practical_activities    JSONB DEFAULT '[]',
  homework                TEXT[] DEFAULT '{}',
  assessment_questions    JSONB DEFAULT '[]',
  references_list         TEXT[] DEFAULT '{}',
  extension_activities    TEXT[] DEFAULT '{}',
  teaching_style          teaching_style DEFAULT 'interactive',
  student_level           student_level DEFAULT 'intermediate',
  duration_minutes        INTEGER DEFAULT 40,
  notes                   TEXT,
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  version                 INTEGER NOT NULL DEFAULT 1,
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHEMES OF WORK
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS schemes_of_work (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  subject                 TEXT NOT NULL,
  class_name              TEXT,
  curriculum              curriculum_type DEFAULT 'nigerian',
  duration_type           plan_duration NOT NULL DEFAULT 'term',
  academic_session_id     UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
  term                    TEXT,
  start_date              DATE,
  end_date                DATE,
  weekly_plans            JSONB DEFAULT '[]',
  objectives              TEXT[] DEFAULT '{}',
  resources_needed        TEXT[] DEFAULT '{}',
  assessment_strategy     TEXT,
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  version                 INTEGER NOT NULL DEFAULT 1,
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- WORKSHEETS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS worksheets (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  subject                 TEXT NOT NULL,
  class_name              TEXT,
  topic                   TEXT,
  worksheet_type          worksheet_type NOT NULL DEFAULT 'classwork',
  instructions            TEXT,
  questions               JSONB DEFAULT '[]',
  answer_key              JSONB DEFAULT '[]',
  total_marks             NUMERIC(6,2) DEFAULT 0,
  duration_minutes        INTEGER,
  difficulty              difficulty_level DEFAULT 'medium',
  curriculum              curriculum_type DEFAULT 'nigerian',
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  version                 INTEGER NOT NULL DEFAULT 1,
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- WORKSPACE ASSIGNMENTS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS workspace_assignments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  subject                 TEXT NOT NULL,
  class_name              TEXT,
  topic                   TEXT,
  instructions            TEXT,
  questions               JSONB DEFAULT '[]',
  marking_rubric          JSONB DEFAULT '[]',
  total_marks             NUMERIC(6,2) DEFAULT 0,
  difficulty              difficulty_level DEFAULT 'medium',
  deadline                TIMESTAMPTZ,
  assignment_status       assignment_status DEFAULT 'draft',
  curriculum              curriculum_type DEFAULT 'nigerian',
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  version                 INTEGER NOT NULL DEFAULT 1,
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- REPORT COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS report_comments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  student_id              UUID REFERENCES users(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  academic_session_id     UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
  term                    TEXT,
  comment_text            TEXT NOT NULL,
  academic_performance    TEXT,
  attendance_comment      TEXT,
  behaviour_comment       TEXT,
  participation_comment   TEXT,
  strengths              TEXT[] DEFAULT '{}',
  areas_for_improvement  TEXT[] DEFAULT '{}',
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  is_edited               BOOLEAN DEFAULT false,
  is_published            BOOLEAN DEFAULT false,
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TEACHING RESOURCES
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS teaching_resources (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  topic_id                UUID REFERENCES topics(id) ON DELETE SET NULL,
  academic_session_id     UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  subject                 TEXT,
  class_name              TEXT,
  topic                   TEXT,
  resource_type           resource_type NOT NULL DEFAULT 'notes',
  content                 TEXT,
  content_json            JSONB,
  file_urls               TEXT[] DEFAULT '{}',
  is_ai_generated         BOOLEAN DEFAULT false,
  ai_prompt_snapshot      JSONB,
  version                 INTEGER NOT NULL DEFAULT 1,
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  is_favorite             BOOLEAN DEFAULT false,
  folder_id               UUID REFERENCES resource_folders(id) ON DELETE SET NULL,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESOURCE FOLDERS (for organizing teaching resources and library items)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS resource_folders (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_folder_id        UUID REFERENCES resource_folders(id) ON DELETE CASCADE,
  name                    TEXT NOT NULL,
  description             TEXT,
  icon                    TEXT DEFAULT 'folder',
  color                   TEXT,
  sort_order              INTEGER DEFAULT 0,
  is_shared               BOOLEAN DEFAULT false,
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- AI CONTENT HISTORY
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_content_history (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_type             content_action NOT NULL,
  source_content          TEXT NOT NULL,
  generated_content       TEXT NOT NULL,
  subject                 TEXT,
  topic                   TEXT,
  prompt_snapshot         JSONB,
  model_used              TEXT,
  tokens_used             INTEGER DEFAULT 0,
  generation_time_ms      INTEGER DEFAULT 0,
  is_saved                BOOLEAN DEFAULT false,
  saved_as_type           TEXT,
  saved_as_id             UUID,
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALENDAR EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS calendar_events (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title                   TEXT NOT NULL,
  description             TEXT,
  event_type              event_type NOT NULL DEFAULT 'class',
  subject                 TEXT,
  subject_id              UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  location                TEXT,
  start_time              TIMESTAMPTZ NOT NULL,
  end_time                TIMESTAMPTZ NOT NULL,
  is_all_day              BOOLEAN DEFAULT false,
  is_recurring            BOOLEAN DEFAULT false,
  recurrence_rule         TEXT,
  color                   TEXT,
  reminder_minutes_before INTEGER,
  related_resource_type   TEXT,
  related_resource_id     UUID,
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- WORKSPACE TEMPLATES
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS workspace_templates (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id              UUID REFERENCES users(id) ON DELETE SET NULL,
  name                    TEXT NOT NULL,
  description             TEXT,
  template_type           TEXT NOT NULL,
  content                 JSONB NOT NULL DEFAULT '{}',
  thumbnail_url           TEXT,
  is_public               BOOLEAN DEFAULT false,
  usage_count             INTEGER DEFAULT 0,
  tags                    TEXT[] DEFAULT '{}',
  metadata                JSONB DEFAULT '{}',
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERSION HISTORY (generic for lesson plans, schemes, worksheets, etc.)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS workspace_version_history (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  resource_type           TEXT NOT NULL,
  resource_id             UUID NOT NULL,
  version_number          INTEGER NOT NULL,
  snapshot                JSONB NOT NULL,
  change_summary          TEXT,
  created_at              TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Lesson Plans
CREATE INDEX idx_lesson_plans_teacher ON lesson_plans(teacher_id);
CREATE INDEX idx_lesson_plans_school ON lesson_plans(school_id);
CREATE INDEX idx_lesson_plans_subject ON lesson_plans(subject_id);
CREATE INDEX idx_lesson_plans_class ON lesson_plans(class_id);
CREATE INDEX idx_lesson_plans_published ON lesson_plans(is_published) WHERE is_published = true;
CREATE INDEX idx_lesson_plans_archived ON lesson_plans(is_archived) WHERE is_archived = false;
CREATE INDEX idx_lesson_plans_tags ON lesson_plans USING GIN(tags);
CREATE INDEX idx_lesson_plans_title_search ON lesson_plans USING GIN(to_tsvector('english', title));
CREATE INDEX idx_lesson_plans_created_at ON lesson_plans(created_at DESC);

-- Schemes of Work
CREATE INDEX idx_schemes_teacher ON schemes_of_work(teacher_id);
CREATE INDEX idx_schemes_school ON schemes_of_work(school_id);
CREATE INDEX idx_schemes_subject ON schemes_of_work(subject_id);
CREATE INDEX idx_schemes_duration ON schemes_of_work(duration_type);
CREATE INDEX idx_schemes_curriculum ON schemes_of_work(curriculum);
CREATE INDEX idx_schemes_published ON schemes_of_work(is_published) WHERE is_published = true;
CREATE INDEX idx_schemes_tags ON schemes_of_work USING GIN(tags);
CREATE INDEX idx_schemes_title_search ON schemes_of_work USING GIN(to_tsvector('english', title));

-- Worksheets
CREATE INDEX idx_worksheets_teacher ON worksheets(teacher_id);
CREATE INDEX idx_worksheets_school ON worksheets(school_id);
CREATE INDEX idx_worksheets_subject ON worksheets(subject_id);
CREATE INDEX idx_worksheets_type ON worksheets(worksheet_type);
CREATE INDEX idx_worksheets_difficulty ON worksheets(difficulty);
CREATE INDEX idx_worksheets_published ON worksheets(is_published) WHERE is_published = true;
CREATE INDEX idx_worksheets_tags ON worksheets USING GIN(tags);
CREATE INDEX idx_worksheets_title_search ON worksheets USING GIN(to_tsvector('english', title));

-- Workspace Assignments
CREATE INDEX idx_assignments_teacher ON workspace_assignments(teacher_id);
CREATE INDEX idx_assignments_school ON workspace_assignments(school_id);
CREATE INDEX idx_assignments_subject ON workspace_assignments(subject_id);
CREATE INDEX idx_assignments_status ON workspace_assignments(assignment_status);
CREATE INDEX idx_assignments_deadline ON workspace_assignments(deadline);
CREATE INDEX idx_assignments_published ON workspace_assignments(is_published) WHERE is_published = true;
CREATE INDEX idx_assignments_tags ON workspace_assignments USING GIN(tags);

-- Report Comments
CREATE INDEX idx_report_comments_teacher ON report_comments(teacher_id);
CREATE INDEX idx_report_comments_student ON report_comments(student_id);
CREATE INDEX idx_report_comments_school ON report_comments(school_id);
CREATE INDEX idx_report_comments_session ON report_comments(academic_session_id);
CREATE INDEX idx_report_comments_published ON report_comments(is_published) WHERE is_published = true;

-- Teaching Resources
CREATE INDEX idx_resources_teacher ON teaching_resources(teacher_id);
CREATE INDEX idx_resources_school ON teaching_resources(school_id);
CREATE INDEX idx_resources_type ON teaching_resources(resource_type);
CREATE INDEX idx_resources_subject ON teaching_resources(subject_id);
CREATE INDEX idx_resources_folder ON teaching_resources(folder_id);
CREATE INDEX idx_resources_favorite ON teaching_resources(is_favorite) WHERE is_favorite = true;
CREATE INDEX idx_resources_published ON teaching_resources(is_published) WHERE is_published = true;
CREATE INDEX idx_resources_tags ON teaching_resources USING GIN(tags);
CREATE INDEX idx_resources_title_search ON teaching_resources USING GIN(to_tsvector('english', title));

-- Resource Folders
CREATE INDEX idx_folders_teacher ON resource_folders(teacher_id);
CREATE INDEX idx_folders_parent ON resource_folders(parent_folder_id);
CREATE INDEX idx_folders_shared ON resource_folders(is_shared) WHERE is_shared = true;

-- AI Content History
CREATE INDEX idx_ai_history_teacher ON ai_content_history(teacher_id);
CREATE INDEX idx_ai_history_action ON ai_content_history(action_type);
CREATE INDEX idx_ai_history_saved ON ai_content_history(is_saved) WHERE is_saved = true;
CREATE INDEX idx_ai_history_created ON ai_content_history(created_at DESC);

-- Calendar Events
CREATE INDEX idx_calendar_teacher ON calendar_events(teacher_id);
CREATE INDEX idx_calendar_school ON calendar_events(school_id);
CREATE INDEX idx_calendar_type ON calendar_events(event_type);
CREATE INDEX idx_calendar_start ON calendar_events(start_time);
CREATE INDEX idx_calendar_range ON calendar_events(teacher_id, start_time, end_time);
CREATE INDEX idx_calendar_recurring ON calendar_events(is_recurring) WHERE is_recurring = true;

-- Workspace Templates
CREATE INDEX idx_templates_school ON workspace_templates(school_id);
CREATE INDEX idx_templates_type ON workspace_templates(template_type);
CREATE INDEX idx_templates_public ON workspace_templates(is_public) WHERE is_public = true;
CREATE INDEX idx_templates_tags ON workspace_templates USING GIN(tags);

-- Version History
CREATE INDEX idx_version_resource ON workspace_version_history(resource_type, resource_id);
CREATE INDEX idx_version_teacher ON workspace_version_history(teacher_id);
CREATE INDEX idx_version_created ON workspace_version_history(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW-LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE lesson_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE schemes_of_work ENABLE ROW LEVEL SECURITY;
ALTER TABLE worksheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE teaching_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_content_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_version_history ENABLE ROW LEVEL SECURITY;

-- ─── Lesson Plans RLS ──────────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own lesson plans"
  ON lesson_plans FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "School admins can view school lesson plans"
  ON lesson_plans FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.id = auth.uid()
      WHERE u.role = 'schoolAdmin' AND u.school_id = s.id
    )
  );

CREATE POLICY "Teachers can create own lesson plans"
  ON lesson_plans FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own lesson plans"
  ON lesson_plans FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own lesson plans"
  ON lesson_plans FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Schemes of Work RLS ──────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own schemes"
  ON schemes_of_work FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "School admins can view school schemes"
  ON schemes_of_work FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.id = auth.uid()
      WHERE u.role = 'schoolAdmin' AND u.school_id = s.id
    )
  );

CREATE POLICY "Teachers can create own schemes"
  ON schemes_of_work FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own schemes"
  ON schemes_of_work FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own schemes"
  ON schemes_of_work FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Worksheets RLS ───────────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own worksheets"
  ON worksheets FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "School admins can view school worksheets"
  ON worksheets FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.id = auth.uid()
      WHERE u.role = 'schoolAdmin' AND u.school_id = s.id
    )
  );

CREATE POLICY "Teachers can create own worksheets"
  ON worksheets FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own worksheets"
  ON worksheets FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own worksheets"
  ON worksheets FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Workspace Assignments RLS ────────────────────────────────────────────────

CREATE POLICY "Teachers can view own assignments"
  ON workspace_assignments FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "School admins can view school assignments"
  ON workspace_assignments FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.id = auth.uid()
      WHERE u.role = 'schoolAdmin' AND u.school_id = s.id
    )
  );

CREATE POLICY "Teachers can create own assignments"
  ON workspace_assignments FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own assignments"
  ON workspace_assignments FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own assignments"
  ON workspace_assignments FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Report Comments RLS ─────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own report comments"
  ON report_comments FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Students can view own published report comments"
  ON report_comments FOR SELECT
  USING (student_id = auth.uid() AND is_published = true);

CREATE POLICY "Teachers can create own report comments"
  ON report_comments FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own report comments"
  ON report_comments FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own report comments"
  ON report_comments FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Teaching Resources RLS ──────────────────────────────────────────────────

CREATE POLICY "Teachers can view own resources"
  ON teaching_resources FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can view shared school resources"
  ON teaching_resources FOR SELECT
  USING (
    is_published = true
    AND school_id IN (
      SELECT u.school_id FROM users u WHERE u.id = auth.uid()
    )
  );

CREATE POLICY "Teachers can create own resources"
  ON teaching_resources FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own resources"
  ON teaching_resources FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own resources"
  ON teaching_resources FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Resource Folders RLS ────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own folders"
  ON resource_folders FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can view shared folders"
  ON resource_folders FOR SELECT
  USING (is_shared = true AND school_id IN (
    SELECT u.school_id FROM users u WHERE u.id = auth.uid()
  ));

CREATE POLICY "Teachers can create own folders"
  ON resource_folders FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own folders"
  ON resource_folders FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own folders"
  ON resource_folders FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── AI Content History RLS ──────────────────────────────────────────────────

CREATE POLICY "Teachers can view own AI history"
  ON ai_content_history FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can create own AI history"
  ON ai_content_history FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own AI history"
  ON ai_content_history FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own AI history"
  ON ai_content_history FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Calendar Events RLS ─────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own calendar events"
  ON calendar_events FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can create own calendar events"
  ON calendar_events FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can update own calendar events"
  ON calendar_events FOR UPDATE
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own calendar events"
  ON calendar_events FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Workspace Templates RLS ─────────────────────────────────────────────────

CREATE POLICY "Anyone can view public templates"
  ON workspace_templates FOR SELECT
  USING (is_public = true OR teacher_id = auth.uid());

CREATE POLICY "Teachers can create own templates"
  ON workspace_templates FOR INSERT
  WITH CHECK (teacher_id = auth.uid() OR teacher_id IS NULL);

CREATE POLICY "Teachers can update own templates"
  ON workspace_templates FOR UPDATE
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can delete own templates"
  ON workspace_templates FOR DELETE
  USING (teacher_id = auth.uid());

-- ─── Version History RLS ─────────────────────────────────────────────────────

CREATE POLICY "Teachers can view own version history"
  ON workspace_version_history FOR SELECT
  USING (teacher_id = auth.uid());

CREATE POLICY "Teachers can create own version history"
  ON workspace_version_history FOR INSERT
  WITH CHECK (teacher_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Auto-update updated_at on all tables
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_lesson_plans_updated_at
  BEFORE UPDATE ON lesson_plans
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_schemes_of_work_updated_at
  BEFORE UPDATE ON schemes_of_work
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_worksheets_updated_at
  BEFORE UPDATE ON worksheets
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_workspace_assignments_updated_at
  BEFORE UPDATE ON workspace_assignments
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_report_comments_updated_at
  BEFORE UPDATE ON report_comments
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_teaching_resources_updated_at
  BEFORE UPDATE ON teaching_resources
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_resource_folders_updated_at
  BEFORE UPDATE ON resource_folders
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_calendar_events_updated_at
  BEFORE UPDATE ON calendar_events
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_workspace_templates_updated_at
  BEFORE UPDATE ON workspace_templates
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Auto-increment version on lesson plan updates
CREATE OR REPLACE FUNCTION increment_lesson_plan_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_increment_lesson_plan_version
  BEFORE UPDATE ON lesson_plans
  FOR EACH ROW EXECUTE FUNCTION increment_lesson_plan_version();

CREATE TRIGGER auto_increment_scheme_version
  BEFORE UPDATE ON schemes_of_work
  FOR EACH ROW EXECUTE FUNCTION increment_lesson_plan_version();

CREATE TRIGGER auto_increment_worksheet_version
  BEFORE UPDATE ON worksheets
  FOR EACH ROW EXECUTE FUNCTION increment_lesson_plan_version();

CREATE TRIGGER auto_increment_assignment_version
  BEFORE UPDATE ON workspace_assignments
  FOR EACH ROW EXECUTE FUNCTION increment_lesson_plan_version();

CREATE TRIGGER auto_increment_resource_version
  BEFORE UPDATE ON teaching_resources
  FOR EACH ROW EXECUTE FUNCTION increment_lesson_plan_version();

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get teacher dashboard summary
CREATE OR REPLACE FUNCTION get_teacher_workspace_summary(
  p_teacher_id UUID,
  p_school_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_lesson_plans', (SELECT COUNT(*) FROM lesson_plans WHERE teacher_id = p_teacher_id),
    'total_schemes', (SELECT COUNT(*) FROM schemes_of_work WHERE teacher_id = p_teacher_id),
    'total_worksheets', (SELECT COUNT(*) FROM worksheets WHERE teacher_id = p_teacher_id),
    'total_assignments', (SELECT COUNT(*) FROM workspace_assignments WHERE teacher_id = p_teacher_id),
    'pending_assignments', (SELECT COUNT(*) FROM workspace_assignments WHERE teacher_id = p_teacher_id AND assignment_status = 'draft'),
    'total_resources', (SELECT COUNT(*) FROM teaching_resources WHERE teacher_id = p_teacher_id),
    'today_events', (SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id', id, 'title', title, 'event_type', event_type,
      'start_time', start_time, 'end_time', end_time, 'color', color
    )), '[]'::jsonb) FROM calendar_events
    WHERE teacher_id = p_teacher_id
      AND start_time::date = CURRENT_DATE
    ORDER BY start_time),
    'upcoming_events', (SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id', id, 'title', title, 'event_type', event_type,
      'start_time', start_time, 'end_time', end_time, 'color', color
    )), '[]'::jsonb) FROM calendar_events
    WHERE teacher_id = p_teacher_id
      AND start_time > now()
      AND start_time < now() + INTERVAL '7 days'
    ORDER BY start_time LIMIT 10),
    'recent_ai_content', (SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id', id, 'action_type', action_type, 'generated_content', LEFT(generated_content, 100),
      'created_at', created_at
    )), '[]'::jsonb) FROM ai_content_history
    WHERE teacher_id = p_teacher_id
    ORDER BY created_at DESC LIMIT 5),
    'draft_lesson_plans', (SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id', id, 'title', title, 'subject', subject, 'updated_at', updated_at
    )), '[]'::jsonb) FROM lesson_plans
    WHERE teacher_id = p_teacher_id AND is_published = false AND is_archived = false
    ORDER BY updated_at DESC LIMIT 5)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Save version snapshot before update
CREATE OR REPLACE FUNCTION save_workspace_version()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD IS DISTINCT FROM NEW THEN
    INSERT INTO workspace_version_history (teacher_id, resource_type, resource_id, version_number, snapshot, change_summary)
    VALUES (
      COALESCE(NEW.teacher_id, OLD.teacher_id),
      TG_TABLE_NAME,
      COALESCE(NEW.id, OLD.id),
      COALESCE(OLD.version, 1),
      to_jsonb(OLD),
      'Auto-saved version ' || COALESCE(OLD.version, 1)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER save_lesson_plan_version
  BEFORE UPDATE ON lesson_plans
  FOR EACH ROW EXECUTE FUNCTION save_workspace_version();

CREATE TRIGGER save_scheme_version
  BEFORE UPDATE ON schemes_of_work
  FOR EACH ROW EXECUTE FUNCTION save_workspace_version();

CREATE TRIGGER save_worksheet_version
  BEFORE UPDATE ON worksheets
  FOR EACH ROW EXECUTE FUNCTION save_workspace_version();

CREATE TRIGGER save_assignment_version
  BEFORE UPDATE ON workspace_assignments
  FOR EACH ROW EXECUTE FUNCTION save_workspace_version();

CREATE TRIGGER save_resource_version
  BEFORE UPDATE ON teaching_resources
  FOR EACH ROW EXECUTE FUNCTION save_workspace_version();
