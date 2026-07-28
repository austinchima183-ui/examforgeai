-- ═══════════════════════════════════════════════════════════════════════
-- EXAMFORGE AI — RESULTS, GRADING & ANALYTICS ENGINE
-- ═══════════════════════════════════════════════════════════════════════
-- Extends the existing CBT Engine schema with:
--   • Configurable grade scales (percentage, letter, GPA, custom)
--   • AI-assisted essay/subjective grading
--   • Teacher feedback and manual grading workflow
--   • Student subject results and overall results
--   • Analytics snapshots and configurable dashboards
--   • Report export tracking
--   • Performance trend tracking
--   • Topic mastery tracking
--   • Result notifications
--   • Comprehensive RLS policies and optimized indexes
-- ═══════════════════════════════════════════════════════════════════════

-- ─── EXTEND EXISTING ENUMS ────────────────────────────────────────────

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'result_published';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'grade_updated';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'teacher_comment_added';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'ai_grading_complete';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'manual_grading_pending';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'report_generated';

-- ─── NEW ENUMS ────────────────────────────────────────────────────────

CREATE TYPE public.grade_type AS ENUM (
  'percentage',
  'letter',
  'gpa',
  'custom'
);

CREATE TYPE public.ai_grading_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'overridden'
);

CREATE TYPE public.report_format AS ENUM (
  'pdf',
  'excel',
  'csv'
);

CREATE TYPE public.report_type AS ENUM (
  'student',
  'class',
  'school',
  'subject',
  'exam_summary'
);

CREATE TYPE public.report_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed'
);

CREATE TYPE public.dashboard_widget_type AS ENUM (
  'pass_rate',
  'score_distribution',
  'subject_comparison',
  'top_performers',
  'difficult_topics',
  'grade_distribution',
  'attendance_vs_performance',
  'historical_trend',
  'class_ranking',
  'exam_participation',
  'gpa_distribution',
  'improvement_tracking'
);

CREATE TYPE public.result_access_level AS ENUM (
  'full',
  'limited',
  'restricted'
);

CREATE TYPE public.performance_trend AS ENUM (
  'improving',
  'stable',
  'declining'
);

CREATE TYPE public.mastery_level AS ENUM (
  'not_started',
  'beginner',
  'developing',
  'proficient',
  'advanced',
  'expert'
);

-- ═══════════════════════════════════════════════════════════════════════
-- GRADE SCALES
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.grade_scales (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  grade_type  public.grade_type NOT NULL DEFAULT 'letter',
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_by  UUID REFERENCES public.profiles(id),
  settings    JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_grade_scales_school_name UNIQUE (school_id, name)
);

CREATE TABLE public.grade_scale_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grade_scale_id  UUID NOT NULL REFERENCES public.grade_scales(id) ON DELETE CASCADE,
  min_percentage  DOUBLE PRECISION NOT NULL,
  max_percentage  DOUBLE PRECISION NOT NULL,
  grade           TEXT NOT NULL,
  gpa_value       DOUBLE PRECISION,
  description     TEXT,
  is_passing      BOOLEAN NOT NULL DEFAULT TRUE,
  color           TEXT,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_grade_scale_entries_scale_grade UNIQUE (grade_scale_id, grade),
  CONSTRAINT chk_min_lt_max CHECK (min_percentage < max_percentage),
  CONSTRAINT chk_percentage_range CHECK (min_percentage >= 0 AND max_percentage <= 100)
);

-- ═══════════════════════════════════════════════════════════════════════
-- AI GRADING RESULTS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.ai_grading_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id         UUID NOT NULL REFERENCES public.student_answers(id) ON DELETE CASCADE,
  exam_id           UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  student_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  ai_provider       TEXT NOT NULL,
  suggested_score   DOUBLE PRECISION NOT NULL,
  max_possible      DOUBLE PRECISION NOT NULL,
  confidence_score  DOUBLE PRECISION,
  grading_rubric    JSONB NOT NULL DEFAULT '{}'::JSONB,
  explanation       TEXT,
  strengths         JSONB NOT NULL DEFAULT '[]'::JSONB,
  weaknesses        JSONB NOT NULL DEFAULT '[]'::JSONB,
  suggestions       JSONB NOT NULL DEFAULT '[]'::JSONB,
  status            public.ai_grading_status NOT NULL DEFAULT 'pending',
  input_tokens      INT,
  output_tokens     INT,
  processing_time_ms INT,
  error_message     TEXT,
  reviewed_by       UUID REFERENCES public.profiles(id),
  reviewed_at       TIMESTAMPTZ,
  final_score       DOUBLE PRECISION,
  review_comment    TEXT,
  is_accepted       BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_ai_grading_answer UNIQUE (answer_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- TEACHER FEEDBACK
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.teacher_feedback (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id       UUID NOT NULL REFERENCES public.student_answers(id) ON DELETE CASCADE,
  exam_id         UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  marks_awarded   DOUBLE PRECISION NOT NULL DEFAULT 0,
  max_marks       DOUBLE PRECISION NOT NULL,
  comment         TEXT,
  ai_grading_id   UUID REFERENCES public.ai_grading_results(id) ON DELETE SET NULL,
  overrode_ai     BOOLEAN NOT NULL DEFAULT FALSE,
  is_private      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_teacher_feedback_answer_teacher UNIQUE (answer_id, teacher_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- STUDENT SUBJECT RESULTS (aggregated per subject per term)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.student_subject_results (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  class_id              UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  academic_session_id   UUID NOT NULL REFERENCES public.academic_sessions(id) ON DELETE CASCADE,
  exam_count            INT NOT NULL DEFAULT 0,
  total_marks_obtained  DOUBLE PRECISION NOT NULL DEFAULT 0,
  total_marks_possible  DOUBLE PRECISION NOT NULL DEFAULT 0,
  percentage            DOUBLE PRECISION NOT NULL DEFAULT 0,
  grade                 TEXT,
  gpa_value             DOUBLE PRECISION,
  class_average         DOUBLE PRECISION,
  class_position        INT,
  class_size            INT,
  subject_average       DOUBLE PRECISION,
  is_passed             BOOLEAN NOT NULL DEFAULT FALSE,
  performance_trend     public.performance_trend DEFAULT 'stable',
  strengths             JSONB NOT NULL DEFAULT '[]'::JSONB,
  weaknesses            JSONB NOT NULL DEFAULT '[]'::JSONB,
  ai_recommendations    JSONB NOT NULL DEFAULT '[]'::JSONB,
  metadata              JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_student_subject_result UNIQUE (student_id, subject_id, class_id, academic_session_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- STUDENT OVERALL RESULTS (aggregated across subjects per term)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.student_overall_results (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id              UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  school_id               UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  class_id                UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  academic_session_id     UUID NOT NULL REFERENCES public.academic_sessions(id) ON DELETE CASCADE,
  total_subjects          INT NOT NULL DEFAULT 0,
  total_marks_obtained    DOUBLE PRECISION NOT NULL DEFAULT 0,
  total_marks_possible    DOUBLE PRECISION NOT NULL DEFAULT 0,
  overall_percentage      DOUBLE PRECISION NOT NULL DEFAULT 0,
  overall_grade           TEXT,
  overall_gpa             DOUBLE PRECISION,
  class_average           DOUBLE PRECISION,
  class_position          INT,
  class_size              INT,
  subjects_passed         INT NOT NULL DEFAULT 0,
  subjects_failed         INT NOT NULL DEFAULT 0,
  is_promoted             BOOLEAN,
  performance_trend       public.performance_trend DEFAULT 'stable',
  best_subject_id         UUID REFERENCES public.subjects(id),
  worst_subject_id        UUID REFERENCES public.subjects(id),
  ai_study_recommendations JSONB NOT NULL DEFAULT '[]'::JSONB,
  teacher_comment         TEXT,
  metadata                JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_student_overall_result UNIQUE (student_id, class_id, academic_session_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- TOPIC MASTERY (per student per topic)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.topic_mastery (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  topic_id              UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  mastery_level         public.mastery_level NOT NULL DEFAULT 'not_started',
  questions_attempted   INT NOT NULL DEFAULT 0,
  questions_correct     INT NOT NULL DEFAULT 0,
  accuracy_percentage   DOUBLE PRECISION NOT NULL DEFAULT 0,
  avg_time_per_question INT NOT NULL DEFAULT 0,
  last_practiced_at     TIMESTAMPTZ,
  improvement_streak    INT NOT NULL DEFAULT 0,
  metadata              JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_topic_mastery UNIQUE (student_id, topic_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- ANALYTICS SNAPSHOTS (pre-computed for fast dashboard loading)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.analytics_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  snapshot_type   TEXT NOT NULL,
  entity_id       UUID,
  academic_session_id UUID REFERENCES public.academic_sessions(id) ON DELETE CASCADE,
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,
  data            JSONB NOT NULL DEFAULT '{}'::JSONB,
  computed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ,

  CONSTRAINT chk_snapshot_dates CHECK (period_start <= period_end)
);

-- ═══════════════════════════════════════════════════════════════════════
-- CONFIGURABLE DASHBOARDS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.dashboard_configurations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'school_admin',
  name        TEXT NOT NULL,
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  layout      JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_dashboard_config UNIQUE (school_id, role, name)
);

CREATE TABLE public.dashboard_widget_configs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dashboard_id      UUID NOT NULL REFERENCES public.dashboard_configurations(id) ON DELETE CASCADE,
  widget_type       public.dashboard_widget_type NOT NULL,
  title             TEXT NOT NULL,
  position_row      INT NOT NULL DEFAULT 0,
  position_col      INT NOT NULL DEFAULT 0,
  width             INT NOT NULL DEFAULT 1,
  height            INT NOT NULL DEFAULT 1,
  is_visible        BOOLEAN NOT NULL DEFAULT TRUE,
  config            JSONB NOT NULL DEFAULT '{}'::JSONB,
  data_source       JSONB NOT NULL DEFAULT '{}'::JSONB,
  refresh_interval  INT NOT NULL DEFAULT 300,
  sort_order        INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════
-- REPORT EXPORTS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.report_exports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id         UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  requested_by      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  report_type       public.report_type NOT NULL,
  report_format     public.report_format NOT NULL,
  status            public.report_status NOT NULL DEFAULT 'pending',
  title             TEXT NOT NULL,
  parameters        JSONB NOT NULL DEFAULT '{}'::JSONB,
  filters           JSONB NOT NULL DEFAULT '{}'::JSONB,
  file_url          TEXT,
  file_size_bytes   BIGINT,
  row_count         INT,
  error_message     TEXT,
  processing_time_ms INT,
  expires_at        TIMESTAMPTZ,
  downloaded_at     TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════
-- RESULT ACCESS LOG (audit trail)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.result_access_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  school_id     UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  action        TEXT NOT NULL,
  entity_type   TEXT NOT NULL,
  entity_id     UUID NOT NULL,
  access_level  public.result_access_level NOT NULL DEFAULT 'limited',
  ip_address    INET,
  user_agent    TEXT,
  details       JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════
-- RESULT LOCKING (prevents modifications after publication)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.result_locks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id       UUID NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  school_id     UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  locked_by     UUID NOT NULL REFERENCES public.profiles(id),
  locked_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  reason        TEXT,
  is_locked     BOOLEAN NOT NULL DEFAULT TRUE,
  unlocked_by   UUID REFERENCES public.profiles(id),
  unlocked_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_result_lock_exam UNIQUE (exam_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- CLASS PERFORMANCE SUMMARY (aggregated class-level analytics)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.class_performance_summaries (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id                UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  school_id               UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  subject_id              UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  academic_session_id     UUID NOT NULL REFERENCES public.academic_sessions(id) ON DELETE CASCADE,
  total_students          INT NOT NULL DEFAULT 0,
  average_score           DOUBLE PRECISION NOT NULL DEFAULT 0,
  highest_score           DOUBLE PRECISION NOT NULL DEFAULT 0,
  lowest_score            DOUBLE PRECISION NOT NULL DEFAULT 0,
  median_score            DOUBLE PRECISION NOT NULL DEFAULT 0,
  pass_rate               DOUBLE PRECISION NOT NULL DEFAULT 0,
  distinction_rate        DOUBLE PRECISION NOT NULL DEFAULT 0,
  grade_distribution      JSONB NOT NULL DEFAULT '{}'::JSONB,
  score_distribution      JSONB NOT NULL DEFAULT '[]'::JSONB,
  topic_performance       JSONB NOT NULL DEFAULT '{}'::JSONB,
  improvement_rate        DOUBLE PRECISION NOT NULL DEFAULT 0,
  metadata                JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_class_performance UNIQUE (class_id, subject_id, academic_session_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- SCHOOL PERFORMANCE SUMMARY (aggregated school-level analytics)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE public.school_performance_summaries (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  academic_session_id     UUID NOT NULL REFERENCES public.academic_sessions(id) ON DELETE CASCADE,
  total_students          INT NOT NULL DEFAULT 0,
  total_classes           INT NOT NULL DEFAULT 0,
  total_exams             INT NOT NULL DEFAULT 0,
  average_score           DOUBLE PRECISION NOT NULL DEFAULT 0,
  pass_rate               DOUBLE PRECISION NOT NULL DEFAULT 0,
  distinction_rate        DOUBLE PRECISION NOT NULL DEFAULT 0,
  best_class_id           UUID REFERENCES public.classes(id),
  best_subject_id         UUID REFERENCES public.subjects(id),
  most_difficult_topic_id UUID REFERENCES public.topics(id),
  class_rankings          JSONB NOT NULL DEFAULT '[]'::JSONB,
  subject_rankings        JSONB NOT NULL DEFAULT '[]'::JSONB,
  grade_distribution      JSONB NOT NULL DEFAULT '{}'::JSONB,
  trend_data              JSONB NOT NULL DEFAULT '[]'::JSONB,
  metadata                JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_school_performance UNIQUE (school_id, academic_session_id)
);

-- ═══════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════

-- Grade scales
CREATE INDEX idx_grade_scales_school ON public.grade_scales(school_id);
CREATE INDEX idx_grade_scales_active ON public.grade_scales(school_id, is_active);
CREATE INDEX idx_grade_scale_entries_scale ON public.grade_scale_entries(grade_scale_id);

-- AI grading
CREATE INDEX idx_ai_grading_answer ON public.ai_grading_results(answer_id);
CREATE INDEX idx_ai_grading_exam ON public.ai_grading_results(exam_id);
CREATE INDEX idx_ai_grading_student ON public.ai_grading_results(student_id);
CREATE INDEX idx_ai_grading_status ON public.ai_grading_results(status);
CREATE INDEX idx_ai_grading_reviewed ON public.ai_grading_results(reviewed_by) WHERE reviewed_by IS NOT NULL;

-- Teacher feedback
CREATE INDEX idx_teacher_feedback_answer ON public.teacher_feedback(answer_id);
CREATE INDEX idx_teacher_feedback_student ON public.teacher_feedback(student_id);
CREATE INDEX idx_teacher_feedback_teacher ON public.teacher_feedback(teacher_id);
CREATE INDEX idx_teacher_feedback_exam ON public.teacher_feedback(exam_id);

-- Student subject results
CREATE INDEX idx_student_subject_student ON public.student_subject_results(student_id);
CREATE INDEX idx_student_subject_school ON public.student_subject_results(school_id);
CREATE INDEX idx_student_subject_subject ON public.student_subject_results(subject_id);
CREATE INDEX idx_student_subject_class ON public.student_subject_results(class_id);
CREATE INDEX idx_student_subject_session ON public.student_subject_results(academic_session_id);
CREATE INDEX idx_student_subject_pct ON public.student_subject_results(percentage DESC);
CREATE INDEX idx_student_subject_trend ON public.student_subject_results(performance_trend);

-- Student overall results
CREATE INDEX idx_student_overall_student ON public.student_overall_results(student_id);
CREATE INDEX idx_student_overall_school ON public.student_overall_results(school_id);
CREATE INDEX idx_student_overall_class ON public.student_overall_results(class_id);
CREATE INDEX idx_student_overall_session ON public.student_overall_results(academic_session_id);
CREATE INDEX idx_student_overall_pct ON public.student_overall_results(overall_percentage DESC);
CREATE INDEX idx_student_overall_position ON public.student_overall_results(class_position) WHERE class_position IS NOT NULL;

-- Topic mastery
CREATE INDEX idx_topic_mastery_student ON public.topic_mastery(student_id);
CREATE INDEX idx_topic_mastery_topic ON public.topic_mastery(topic_id);
CREATE INDEX idx_topic_mastery_subject ON public.topic_mastery(subject_id);
CREATE INDEX idx_topic_mastery_level ON public.topic_mastery(mastery_level);
CREATE INDEX idx_topic_mastery_accuracy ON public.topic_mastery(accuracy_percentage DESC);

-- Analytics snapshots
CREATE INDEX idx_analytics_snapshots_school ON public.analytics_snapshots(school_id);
CREATE INDEX idx_analytics_snapshots_type ON public.analytics_snapshots(snapshot_type);
CREATE INDEX idx_analytics_snapshots_period ON public.analytics_snapshots(period_start, period_end);
CREATE INDEX idx_analytics_snapshots_session ON public.analytics_snapshots(academic_session_id);

-- Dashboard configs
CREATE INDEX idx_dashboard_configs_school ON public.dashboard_configurations(school_id);
CREATE INDEX idx_dashboard_configs_role ON public.dashboard_configurations(school_id, role);
CREATE INDEX idx_dashboard_widget_configs_dashboard ON public.dashboard_widget_configs(dashboard_id);

-- Report exports
CREATE INDEX idx_report_exports_school ON public.report_exports(school_id);
CREATE INDEX idx_report_exports_requested_by ON public.report_exports(requested_by);
CREATE INDEX idx_report_exports_status ON public.report_exports(status);
CREATE INDEX idx_report_exports_type ON public.report_exports(report_type);
CREATE INDEX idx_report_exports_created ON public.report_exports(created_at DESC);

-- Result access log
CREATE INDEX idx_result_access_user ON public.result_access_log(user_id);
CREATE INDEX idx_result_access_school ON public.result_access_log(school_id);
CREATE INDEX idx_result_access_entity ON public.result_access_log(entity_type, entity_id);
CREATE INDEX idx_result_access_created ON public.result_access_log(created_at DESC);

-- Result locks
CREATE INDEX idx_result_locks_exam ON public.result_locks(exam_id);
CREATE INDEX idx_result_locks_school ON public.result_locks(school_id);

-- Class performance
CREATE INDEX idx_class_perf_class ON public.class_performance_summaries(class_id);
CREATE INDEX idx_class_perf_school ON public.class_performance_summaries(school_id);
CREATE INDEX idx_class_perf_subject ON public.class_performance_summaries(subject_id);
CREATE INDEX idx_class_perf_session ON public.class_performance_summaries(academic_session_id);

-- School performance
CREATE INDEX idx_school_perf_school ON public.school_performance_summaries(school_id);
CREATE INDEX idx_school_perf_session ON public.school_performance_summaries(academic_session_id);

-- ═══════════════════════════════════════════════════════════════════════
-- ROW-LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE public.grade_scales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_scale_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_grading_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_subject_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_overall_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_widget_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.result_access_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.result_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_performance_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_performance_summaries ENABLE ROW LEVEL SECURITY;

-- ─── GRADE SCALES RLS ────────────────────────────────────────────────

CREATE POLICY "Super admins can manage grade scales"
  ON public.grade_scales FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'));

CREATE POLICY "School admins can manage their school grade scales"
  ON public.grade_scales FOR ALL
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

CREATE POLICY "Teachers can view their school grade scales"
  ON public.grade_scales FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Students can view active grade scales"
  ON public.grade_scales FOR SELECT
  USING (is_active = true AND school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

-- ─── GRADE SCALE ENTRIES RLS ─────────────────────────────────────────

CREATE POLICY "Grade scale entries follow grade scale access"
  ON public.grade_scale_entries FOR SELECT
  USING (grade_scale_id IN (SELECT id FROM public.grade_scales));

CREATE POLICY "Grade scale entries managed with grade scale"
  ON public.grade_scale_entries FOR ALL
  USING (grade_scale_id IN (SELECT id FROM public.grade_scales));

-- ─── AI GRADING RESULTS RLS ──────────────────────────────────────────

CREATE POLICY "Teachers can view AI grading for their exams"
  ON public.ai_grading_results FOR SELECT
  USING (exam_id IN (
    SELECT e.id FROM public.exams e
    WHERE e.school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid())
    AND auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('teacher', 'school_admin', 'super_admin'))
  ));

CREATE POLICY "Students can view their own AI grading"
  ON public.ai_grading_results FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Teachers can update AI grading results"
  ON public.ai_grading_results FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'school_admin', 'super_admin')));

-- ─── TEACHER FEEDBACK RLS ────────────────────────────────────────────

CREATE POLICY "Teachers can manage their feedback"
  ON public.teacher_feedback FOR ALL
  USING (teacher_id = auth.uid());

CREATE POLICY "Students can view their own feedback"
  ON public.teacher_feedback FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "School admins can view school feedback"
  ON public.teacher_feedback FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

-- ─── STUDENT SUBJECT RESULTS RLS ─────────────────────────────────────

CREATE POLICY "Students can view their own subject results"
  ON public.student_subject_results FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Teachers can view subject results for their classes"
  ON public.student_subject_results FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'school_admin', 'super_admin')));

-- ─── STUDENT OVERALL RESULTS RLS ─────────────────────────────────────

CREATE POLICY "Students can view their own overall results"
  ON public.student_overall_results FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Teachers and admins can view school overall results"
  ON public.student_overall_results FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'school_admin', 'super_admin')));

-- ─── TOPIC MASTERY RLS ───────────────────────────────────────────────

CREATE POLICY "Students can view their own topic mastery"
  ON public.topic_mastery FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Teachers can view topic mastery for their students"
  ON public.topic_mastery FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'school_admin', 'super_admin')));

-- ─── ANALYTICS SNAPSHOTS RLS ─────────────────────────────────────────

CREATE POLICY "School members can view their analytics snapshots"
  ON public.analytics_snapshots FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage analytics snapshots"
  ON public.analytics_snapshots FOR INSERT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

-- ─── DASHBOARD CONFIGURATIONS RLS ────────────────────────────────────

CREATE POLICY "School members can view their dashboard configs"
  ON public.dashboard_configurations FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage dashboard configurations"
  ON public.dashboard_configurations FOR ALL
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

CREATE POLICY "Dashboard widget configs follow dashboard access"
  ON public.dashboard_widget_configs FOR SELECT
  USING (dashboard_id IN (SELECT id FROM public.dashboard_configurations));

CREATE POLICY "Dashboard widget configs managed with dashboard"
  ON public.dashboard_widget_configs FOR ALL
  USING (dashboard_id IN (SELECT id FROM public.dashboard_configurations));

-- ─── REPORT EXPORTS RLS ──────────────────────────────────────────────

CREATE POLICY "Users can view their own report exports"
  ON public.report_exports FOR SELECT
  USING (requested_by = auth.uid() OR school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

CREATE POLICY "Users can create report exports"
  ON public.report_exports FOR INSERT
  USING (auth.uid() = requested_by);

-- ─── RESULT ACCESS LOG RLS ───────────────────────────────────────────

CREATE POLICY "Admins can view result access logs"
  ON public.result_access_log FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

CREATE POLICY "System can insert access logs"
  ON public.result_access_log FOR INSERT
  USING (auth.uid() = user_id);

-- ─── RESULT LOCKS RLS ────────────────────────────────────────────────

CREATE POLICY "School members can view result locks"
  ON public.result_locks FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage result locks"
  ON public.result_locks FOR ALL
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

-- ─── CLASS PERFORMANCE RLS ───────────────────────────────────────────

CREATE POLICY "School members can view class performance"
  ON public.class_performance_summaries FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage class performance"
  ON public.class_performance_summaries FOR ALL
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

-- ─── SCHOOL PERFORMANCE RLS ──────────────────────────────────────────

CREATE POLICY "School members can view school performance"
  ON public.school_performance_summaries FOR SELECT
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can manage school performance"
  ON public.school_performance_summaries FOR ALL
  USING (school_id IN (SELECT school_id FROM public.profiles WHERE id = auth.uid() AND role IN ('school_admin', 'super_admin')));

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCTIONS & TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_grade_scales_updated
  BEFORE UPDATE ON public.grade_scales
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_ai_grading_results_updated
  BEFORE UPDATE ON public.ai_grading_results
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_teacher_feedback_updated
  BEFORE UPDATE ON public.teacher_feedback
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_student_subject_results_updated
  BEFORE UPDATE ON public.student_subject_results
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_student_overall_results_updated
  BEFORE UPDATE ON public.student_overall_results
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_topic_mastery_updated
  BEFORE UPDATE ON public.topic_mastery
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_dashboard_configs_updated
  BEFORE UPDATE ON public.dashboard_configurations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_dashboard_widgets_updated
  BEFORE UPDATE ON public.dashboard_widget_configs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_report_exports_updated
  BEFORE UPDATE ON public.report_exports
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_class_performance_updated
  BEFORE UPDATE ON public.class_performance_summaries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_school_performance_updated
  BEFORE UPDATE ON public.school_performance_summaries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── FUNCTION: Apply grade scale to a percentage ─────────────────────

CREATE OR REPLACE FUNCTION public.apply_grade_scale(
  p_percentage DOUBLE PRECISION,
  p_grade_scale_id UUID
)
RETURNS TABLE(grade TEXT, gpa_value DOUBLE PRECISION, is_passing BOOLEAN, description TEXT) AS $$
DECLARE
  v_school_id UUID;
BEGIN
  SELECT school_id INTO v_school_id FROM public.grade_scales WHERE id = p_grade_scale_id;
  
  RETURN QUERY
  SELECT gse.grade, gse.gpa_value, gse.is_passing, gse.description
  FROM public.grade_scale_entries gse
  WHERE gse.grade_scale_id = p_grade_scale_id
    AND p_percentage >= gse.min_percentage
    AND p_percentage <= gse.max_percentage
  ORDER BY gse.sort_order
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- ─── FUNCTION: Compute student subject result ────────────────────────

CREATE OR REPLACE FUNCTION public.compute_student_subject_result(
  p_student_id UUID,
  p_subject_id UUID,
  p_class_id UUID,
  p_academic_session_id UUID
)
RETURNS public.student_subject_results AS $$
DECLARE
  v_result public.student_subject_results;
  v_total_obtained DOUBLE PRECISION;
  v_total_possible DOUBLE PRECISION;
  v_exam_count INT;
  v_percentage DOUBLE PRECISION;
  v_grade TEXT;
  v_class_avg DOUBLE PRECISION;
  v_school_id UUID;
BEGIN
  -- Get school_id from class
  SELECT school_id INTO v_school_id FROM public.classes WHERE id = p_class_id;
  
  -- Aggregate exam results
  SELECT 
    COALESCE(SUM(er.total_marks), 0),
    COALESCE(SUM(er.total_possible), 0),
    COUNT(*)
  INTO v_total_obtained, v_total_possible, v_exam_count
  FROM public.exam_results er
  JOIN public.exams e ON e.id = er.exam_id
  WHERE er.student_id = p_student_id
    AND e.subject_id = p_subject_id
    AND e.class_id = p_class_id
    AND e.academic_session_id = p_academic_session_id
    AND er.is_released = true;
  
  v_percentage := CASE WHEN v_total_possible > 0 THEN (v_total_obtained / v_total_possible) * 100 ELSE 0 END;
  
  -- Get class average
  SELECT COALESCE(AVG(ssr.percentage), 0) INTO v_class_avg
  FROM public.student_subject_results ssr
  WHERE ssr.subject_id = p_subject_id
    AND ssr.class_id = p_class_id
    AND ssr.academic_session_id = p_academic_session_id;
  
  -- Upsert
  INSERT INTO public.student_subject_results (
    student_id, school_id, subject_id, class_id, academic_session_id,
    exam_count, total_marks_obtained, total_marks_possible, percentage,
    class_average, is_passed
  ) VALUES (
    p_student_id, v_school_id, p_subject_id, p_class_id, p_academic_session_id,
    v_exam_count, v_total_obtained, v_total_possible, v_percentage,
    v_class_avg, v_percentage >= 50
  )
  ON CONFLICT (student_id, subject_id, class_id, academic_session_id)
  DO UPDATE SET
    exam_count = EXCLUDED.exam_count,
    total_marks_obtained = EXCLUDED.total_marks_obtained,
    total_marks_possible = EXCLUDED.total_marks_possible,
    percentage = EXCLUDED.percentage,
    class_average = EXCLUDED.class_average,
    is_passed = EXCLUDED.is_passed,
    updated_at = now()
  RETURNING * INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ─── FUNCTION: Log result access ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.log_result_access(
  p_user_id UUID,
  p_school_id UUID,
  p_action TEXT,
  p_entity_type TEXT,
  p_entity_id UUID,
  p_access_level public.result_access_level DEFAULT 'limited',
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.result_access_log (
    user_id, school_id, action, entity_type, entity_id,
    access_level, ip_address, user_agent, details
  ) VALUES (
    p_user_id, p_school_id, p_action, p_entity_type, p_entity_id,
    p_access_level, p_ip_address, p_user_agent, p_details
  ) RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION: Check result lock ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_result_locked(p_exam_id UUID)
RETURNS BOOLEAN AS $$
SELECT COALESCE(is_locked, false) FROM public.result_locks WHERE exam_id = p_exam_id;
$$ LANGUAGE sql STABLE;

-- ═══════════════════════════════════════════════════════════════════════
-- SEED DATA: Default grade scales
-- ═══════════════════════════════════════════════════════════════════════

-- Note: School-specific grade scales are created when a school is onboarded.
-- The following inserts a global default template that can be cloned.

INSERT INTO public.grade_scales (id, school_id, name, grade_type, is_default, is_active, settings)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'Default WAEC/NECO Grading Scale',
  'letter',
  true,
  false,
  '{"curriculum": "WAEC", "country": "Nigeria"}'::JSONB
) ON CONFLICT DO NOTHING;

INSERT INTO public.grade_scale_entries (grade_scale_id, min_percentage, max_percentage, grade, gpa_value, description, is_passing, color, sort_order) VALUES
  ('00000000-0000-0000-0000-000000000001', 75, 100, 'A1', 4.0, 'Excellent', true, '#22C55E', 1),
  ('00000000-0000-0000-0000-000000000001', 70, 74.99, 'B2', 3.6, 'Very Good', true, '#84CC16', 2),
  ('00000000-0000-0000-0000-000000000001', 65, 69.99, 'B3', 3.2, 'Good', true, '#A3E635', 3),
  ('00000000-0000-0000-0000-000000000001', 60, 64.99, 'C4', 2.8, 'Credit', true, '#FACC15', 4),
  ('00000000-0000-0000-0000-000000000001', 55, 59.99, 'C5', 2.4, 'Credit', true, '#FDE047', 5),
  ('00000000-0000-0000-0000-000000000001', 50, 54.99, 'C6', 2.0, 'Credit', true, '#FCD34D', 6),
  ('00000000-0000-0000-0000-000000000001', 45, 49.99, 'D7', 1.6, 'Pass', true, '#FB923C', 7),
  ('00000000-0000-0000-0000-000000000001', 40, 44.99, 'E8', 1.2, 'Pass', true, '#F97316', 8),
  ('00000000-0000-0000-0000-000000000001', 0, 39.99, 'F9', 0.0, 'Fail', false, '#EF4444', 9)
ON CONFLICT DO NOTHING;

-- GPA Scale (US-style for Cambridge/International schools)
INSERT INTO public.grade_scales (id, school_id, name, grade_type, is_default, is_active, settings)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'Default GPA Grading Scale',
  'gpa',
  false,
  false,
  '{"curriculum": "International", "scale": "4.0"}'::JSONB
) ON CONFLICT DO NOTHING;

INSERT INTO public.grade_scale_entries (grade_scale_id, min_percentage, max_percentage, grade, gpa_value, description, is_passing, color, sort_order) VALUES
  ('00000000-0000-0000-0000-000000000002', 93, 100, 'A', 4.0, 'Excellent', true, '#22C55E', 1),
  ('00000000-0000-0000-0000-000000000002', 90, 92.99, 'A-', 3.7, 'Excellent', true, '#4ADE80', 2),
  ('00000000-0000-0000-0000-000000000002', 87, 89.99, 'B+', 3.3, 'Good', true, '#84CC16', 3),
  ('00000000-0000-0000-0000-000000000002', 83, 86.99, 'B', 3.0, 'Good', true, '#A3E635', 4),
  ('00000000-0000-0000-0000-000000000002', 80, 82.99, 'B-', 2.7, 'Good', true, '#BEF264', 5),
  ('00000000-0000-0000-0000-000000000002', 77, 79.99, 'C+', 2.3, 'Satisfactory', true, '#FACC15', 6),
  ('00000000-0000-0000-0000-000000000002', 73, 76.99, 'C', 2.0, 'Satisfactory', true, '#FDE047', 7),
  ('00000000-0000-0000-0000-000000000002', 70, 72.99, 'C-', 1.7, 'Satisfactory', true, '#FCD34D', 8),
  ('00000000-0000-0000-0000-000000000002', 67, 69.99, 'D+', 1.3, 'Below Average', true, '#FB923C', 9),
  ('00000000-0000-0000-0000-000000000002', 60, 66.99, 'D', 1.0, 'Poor', true, '#F97316', 10),
  ('00000000-0000-0000-0000-000000000002', 0, 59.99, 'F', 0.0, 'Fail', false, '#EF4444', 11)
ON CONFLICT DO NOTHING;
