-- ============================================================================
-- EXAMFORGE AI — Curriculum Content Management System (CCMS) + Enterprise Schema
-- ============================================================================
-- Supports: Nursery, Kindergarten, Primary 1-6, JSS1-3, SS1-3,
--           Technical Schools, Colleges of Education, Universities
-- Features: Multi-curriculum, content versioning, answer repository,
--           AI curriculum engine, enterprise security, monitoring, audit trails
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_enum_if_not_exists(
  enum_name TEXT,
  enum_values TEXT[]
) RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = enum_name) THEN
    EXECUTE format('CREATE TYPE public.%I AS ENUM (%s)',
      enum_name,
      string_agg(quote_literal(v), ',' ) )
    FROM unnest(enum_values) AS v;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Educational Levels
SELECT public.create_enum_if_not_exists('educational_level_type', ARRAY[
  'nursery', 'kindergarten',
  'primary_1', 'primary_2', 'primary_3', 'primary_4', 'primary_5', 'primary_6',
  'jss_1', 'jss_2', 'jss_3',
  'ss_1', 'ss_2', 'ss_3',
  'technical_1', 'technical_2', 'technical_3',
  'college_of_education_1', 'college_of_education_2', 'college_of_education_3',
  'university_100', 'university_200', 'university_300', 'university_400',
  'university_500', 'university_600'
]);

-- Level Category
SELECT public.create_enum_if_not_exists('level_category_type', ARRAY[
  'early_childhood', 'primary', 'junior_secondary', 'senior_secondary',
  'technical', 'tertiary_college', 'tertiary_university'
]);

-- Curriculum Type
SELECT public.create_enum_if_not_exists('curriculum_type', ARRAY[
  'nerdc', 'waec', 'neco', 'nabteb', 'custom', 'international'
]);

-- Content Status
SELECT public.create_enum_if_not_exists('content_status_type', ARRAY[
  'draft', 'review', 'published', 'archived', 'deprecated'
]);

-- Content Type
SELECT public.create_enum_if_not_exists('content_type_enum', ARRAY[
  'question', 'explanation', 'marking_scheme', 'teacher_note',
  'lesson_note', 'worksheet', 'practical_guide', 'reading_material',
  'video_script', 'assessment_rubric'
]);

-- Question Category
SELECT public.create_enum_if_not_exists('question_category_type', ARRAY[
  'objective', 'theory', 'practical', 'oral', 'project', 'essay',
  'fill_in_blank', 'true_false', 'matching', 'ordering', 'multiple_choice'
]);

-- Difficulty Level
SELECT public.create_enum_if_not_exists('difficulty_level_type', ARRAY[
  'beginner', 'elementary', 'intermediate', 'advanced', 'expert'
]);

-- Bloom's Taxonomy
SELECT public.create_enum_if_not_exists('bloom_taxonomy_type', ARRAY[
  'remember', 'understand', 'apply', 'analyze', 'evaluate', 'create'
]);

-- Sync Status
SELECT public.create_enum_if_not_exists('sync_status_type', ARRAY[
  'pending', 'in_progress', 'completed', 'failed', 'conflict'
]);

-- Audit Action
SELECT public.create_enum_if_not_exists('audit_action_type', ARRAY[
  'create', 'read', 'update', 'delete', 'login', 'logout',
  'export', 'import', 'approve', 'reject', 'archive', 'restore',
  'permission_change', 'role_change', 'password_change', 'mfa_enable',
  'mfa_disable', 'session_invalidate', 'api_key_create', 'api_key_revoke'
]);

-- Alert Severity
SELECT public.create_enum_if_not_exists('alert_severity_type', ARRAY[
  'info', 'warning', 'critical', 'emergency'
]);

-- Deployment Status
SELECT public.create_enum_if_not_exists('deployment_status_type', ARRAY[
  'pending', 'running', 'success', 'failed', 'rolled_back'
]);

-- Test Type
SELECT public.create_enum_if_not_exists('test_type_enum', ARRAY[
  'unit', 'widget', 'integration', 'e2e', 'load', 'security', 'performance'
]);

-- Conflict Resolution Strategy
SELECT public.create_enum_if_not_exists('conflict_strategy_type', ARRAY[
  'server_wins', 'client_wins', 'merge', 'manual'
]);

-- MFA Method
SELECT public.create_enum_if_not_exists('mfa_method_type', ARRAY[
  'sms', 'email', 'authenticator_app', 'hardware_key'
]);

-- Rate Limit Scope
SELECT public.create_enum_if_not_exists('rate_limit_scope_type', ARRAY[
  'global', 'per_user', 'per_ip', 'per_api_key', 'per_endpoint'
]);

-- Monitoring Metric Type
SELECT public.create_enum_if_not_exists('metric_type_enum', ARRAY[
  'counter', 'gauge', 'histogram', 'summary'
]);

-- Import Status
SELECT public.create_enum_if_not_exists('import_status_type', ARRAY[
  'pending', 'processing', 'completed', 'failed', 'partially_completed'
]);

-- ============================================================================
-- EDUCATIONAL LEVELS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.educational_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  level_category level_category_type NOT NULL,
  level_order INT NOT NULL,
  min_age INT,
  max_age INT,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed default educational levels
INSERT INTO public.educational_levels (code, name, level_category, level_order, min_age, max_age, description) VALUES
  ('nursery', 'Nursery', 'early_childhood', 1, 2, 4, 'Pre-primary nursery education'),
  ('kindergarten', 'Kindergarten', 'early_childhood', 2, 4, 6, 'Pre-primary kindergarten education'),
  ('primary_1', 'Primary 1', 'primary', 3, 5, 7, 'First year of primary education'),
  ('primary_2', 'Primary 2', 'primary', 4, 6, 8, 'Second year of primary education'),
  ('primary_3', 'Primary 3', 'primary', 5, 7, 9, 'Third year of primary education'),
  ('primary_4', 'Primary 4', 'primary', 6, 8, 10, 'Fourth year of primary education'),
  ('primary_5', 'Primary 5', 'primary', 7, 9, 11, 'Fifth year of primary education'),
  ('primary_6', 'Primary 6', 'primary', 8, 10, 12, 'Sixth year of primary education'),
  ('jss_1', 'JSS 1', 'junior_secondary', 9, 10, 13, 'First year of junior secondary'),
  ('jss_2', 'JSS 2', 'junior_secondary', 10, 11, 14, 'Second year of junior secondary'),
  ('jss_3', 'JSS 3', 'junior_secondary', 11, 12, 15, 'Third year of junior secondary'),
  ('ss_1', 'SS 1', 'senior_secondary', 12, 13, 16, 'First year of senior secondary'),
  ('ss_2', 'SS 2', 'senior_secondary', 13, 14, 17, 'Second year of senior secondary'),
  ('ss_3', 'SS 3', 'senior_secondary', 14, 15, 18, 'Third year of senior secondary'),
  ('technical_1', 'Technical Year 1', 'technical', 15, 13, 16, 'First year technical/vocational'),
  ('technical_2', 'Technical Year 2', 'technical', 16, 14, 17, 'Second year technical/vocational'),
  ('technical_3', 'Technical Year 3', 'technical', 17, 15, 18, 'Third year technical/vocational'),
  ('coe_1', 'CoE Year 1', 'tertiary_college', 18, 16, 20, 'First year college of education'),
  ('coe_2', 'CoE Year 2', 'tertiary_college', 19, 17, 21, 'Second year college of education'),
  ('coe_3', 'CoE Year 3', 'tertiary_college', 20, 18, 22, 'Third year college of education'),
  ('uni_100', 'University 100 Level', 'tertiary_university', 21, 16, 20, 'First year university'),
  ('uni_200', 'University 200 Level', 'tertiary_university', 22, 17, 21, 'Second year university'),
  ('uni_300', 'University 300 Level', 'tertiary_university', 23, 18, 22, 'Third year university'),
  ('uni_400', 'University 400 Level', 'tertiary_university', 24, 19, 23, 'Fourth year university'),
  ('uni_500', 'University 500 Level', 'tertiary_university', 25, 20, 24, 'Fifth year university'),
  ('uni_600', 'University 600 Level', 'tertiary_university', 26, 21, 25, 'Sixth year university')
ON CONFLICT (code) DO NOTHING;

-- School-level configuration (enable/disable levels per school)
CREATE TABLE IF NOT EXISTS public.school_level_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  educational_level_id UUID NOT NULL REFERENCES public.educational_levels(id) ON DELETE CASCADE,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  custom_name TEXT,
  academic_year_start DATE,
  academic_year_end DATE,
  max_students_per_class INT DEFAULT 40,
  grading_system JSONB DEFAULT '{}',
  configuration JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, educational_level_id)
);

-- ============================================================================
-- CURRICULUM MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.curricula (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  curriculum_type curriculum_type NOT NULL DEFAULT 'nerdc',
  country_code TEXT NOT NULL DEFAULT 'NG',
  description TEXT,
  publisher TEXT,
  edition TEXT,
  effective_date DATE,
  expiry_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  parent_curriculum_id UUID REFERENCES public.curricula(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Curriculum versions
CREATE TABLE IF NOT EXISTS public.curriculum_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum_id UUID NOT NULL REFERENCES public.curricula(id) ON DELETE CASCADE,
  version_number TEXT NOT NULL,
  change_summary TEXT,
  changelog TEXT,
  is_current BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  published_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(curriculum_id, version_number)
);

-- Curriculum-educational level mapping
CREATE TABLE IF NOT EXISTS public.curriculum_level_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum_id UUID NOT NULL REFERENCES public.curricula(id) ON DELETE CASCADE,
  educational_level_id UUID NOT NULL REFERENCES public.educational_levels(id) ON DELETE CASCADE,
  is_applicable BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(curriculum_id, educational_level_id)
);

-- ============================================================================
-- SUBJECT MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  curriculum_id UUID REFERENCES public.curricula(id) ON DELETE SET NULL,
  educational_level_id UUID REFERENCES public.educational_levels(id) ON DELETE SET NULL,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  subject_group TEXT,
  is_core BOOLEAN NOT NULL DEFAULT false,
  is_elective BOOLEAN NOT NULL DEFAULT false,
  is_vocational BOOLEAN NOT NULL DEFAULT false,
  language_of_instruction TEXT DEFAULT 'English',
  description TEXT,
  icon_url TEXT,
  color_code TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_custom BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed default Nigerian subjects by level category
-- Primary subjects
INSERT INTO public.subjects (name, code, subject_group, is_core, is_elective, is_vocational, sort_order, is_custom, description) VALUES
  ('English Studies', 'PRI-ENG', 'language', true, false, false, 1, false, 'English language studies for primary level'),
  ('Mathematics', 'PRI-MATH', 'mathematics', true, false, false, 2, false, 'Mathematics for primary level'),
  ('Basic Science', 'PRI-BS', 'science', true, false, false, 3, false, 'Basic science and technology for primary'),
  ('Basic Technology', 'PRI-BT', 'technology', true, false, false, 4, false, 'Basic technology education'),
  ('Civic Education', 'PRI-CIVIC', 'social_studies', true, false, false, 5, false, 'Civic education and citizenship'),
  ('Social Studies', 'PRI-SOCIAL', 'social_studies', true, false, false, 6, false, 'Social studies for primary level'),
  ('Cultural & Creative Arts', 'PRI-CCA', 'arts', false, true, false, 7, false, 'Cultural and creative arts'),
  ('Computer Studies', 'PRI-COMP', 'technology', true, false, false, 8, false, 'Computer studies and ICT'),
  ('Agricultural Science', 'PRI-AGRI', 'vocational', false, true, false, 9, false, 'Agricultural science basics'),
  ('Home Economics', 'PRI-HOME', 'vocational', false, true, false, 10, false, 'Home economics for primary'),
  ('Physical & Health Education', 'PRI-PHE', 'physical', false, true, false, 11, false, 'Physical and health education'),
  ('Security Education', 'PRI-SEC', 'social_studies', false, true, false, 12, false, 'Security awareness education'),
  ('French', 'PRI-FRENCH', 'language', false, true, false, 13, false, 'French language basics'),
  ('Yoruba', 'PRI-YORUBA', 'language', false, true, false, 14, false, 'Yoruba language studies'),
  ('Hausa', 'PRI-HAUSA', 'language', false, true, false, 15, false, 'Hausa language studies'),
  ('Igbo', 'PRI-IGBO', 'language', false, true, false, 16, false, 'Igbo language studies')
ON CONFLICT DO NOTHING;

-- Junior Secondary subjects
INSERT INTO public.subjects (name, code, subject_group, is_core, is_elective, is_vocational, sort_order, is_custom, description) VALUES
  ('English Studies', 'JSS-ENG', 'language', true, false, false, 1, false, 'English language for junior secondary'),
  ('Mathematics', 'JSS-MATH', 'mathematics', true, false, false, 2, false, 'Mathematics for junior secondary'),
  ('Basic Science', 'JSS-BS', 'science', true, false, false, 3, false, 'Basic science for junior secondary'),
  ('Basic Technology', 'JSS-BT', 'technology', true, false, false, 4, false, 'Basic technology for junior secondary'),
  ('Civic Education', 'JSS-CIVIC', 'social_studies', true, false, false, 5, false, 'Civic education for JSS'),
  ('Social Studies', 'JSS-SOCIAL', 'social_studies', true, false, false, 6, false, 'Social studies for junior secondary'),
  ('Business Studies', 'JSS-BUS', 'commercial', true, false, false, 7, false, 'Business studies for JSS'),
  ('Computer Studies', 'JSS-COMP', 'technology', true, false, false, 8, false, 'Computer studies for JSS'),
  ('Agricultural Science', 'JSS-AGRI', 'vocational', false, true, false, 9, false, 'Agricultural science for JSS'),
  ('Home Economics', 'JSS-HOME', 'vocational', false, true, false, 10, false, 'Home economics for JSS'),
  ('Christian Religious Studies', 'JSS-CRS', 'religious', false, true, false, 11, false, 'Christian religious studies'),
  ('Islamic Religious Studies', 'JSS-IRS', 'religious', false, true, false, 12, false, 'Islamic religious studies'),
  ('French', 'JSS-FRENCH', 'language', false, true, false, 13, false, 'French language for JSS'),
  ('Yoruba', 'JSS-YORUBA', 'language', false, true, false, 14, false, 'Yoruba language for JSS'),
  ('Hausa', 'JSS-HAUSA', 'language', false, true, false, 15, false, 'Hausa language for JSS'),
  ('Igbo', 'JSS-IGBO', 'language', false, true, false, 16, false, 'Igbo language for JSS'),
  ('Cultural & Creative Arts', 'JSS-CCA', 'arts', false, true, false, 17, false, 'Cultural and creative arts for JSS'),
  ('Physical & Health Education', 'JSS-PHE', 'physical', false, true, false, 18, false, 'Physical and health education for JSS'),
  ('Security Education', 'JSS-SEC', 'social_studies', false, true, false, 19, false, 'Security education for JSS')
ON CONFLICT DO NOTHING;

-- Senior Secondary subjects (Science, Arts, Commercial, Vocational)
INSERT INTO public.subjects (name, code, subject_group, is_core, is_elective, is_vocational, sort_order, is_custom, description) VALUES
  ('English Language', 'SS-ENG', 'language', true, false, false, 1, false, 'English language for senior secondary'),
  ('General Mathematics', 'SS-MATH', 'mathematics', true, false, false, 2, false, 'Mathematics for senior secondary'),
  ('Physics', 'SS-PHY', 'science', false, true, false, 3, false, 'Physics for senior secondary'),
  ('Chemistry', 'SS-CHEM', 'science', false, true, false, 4, false, 'Chemistry for senior secondary'),
  ('Biology', 'SS-BIO', 'science', false, true, false, 5, false, 'Biology for senior secondary'),
  ('Agricultural Science', 'SS-AGRI', 'science', false, true, false, 6, false, 'Agricultural science for SS'),
  ('Further Mathematics', 'SS-FMATH', 'mathematics', false, true, false, 7, false, 'Further mathematics for SS'),
  ('Technical Drawing', 'SS-TDRAW', 'technology', false, true, false, 8, false, 'Technical drawing for SS'),
  ('Computer Studies', 'SS-COMP', 'technology', false, true, false, 9, false, 'Computer studies for SS'),
  ('Literature in English', 'SS-LIT', 'arts', false, true, false, 10, false, 'Literature in English for SS'),
  ('Government', 'SS-GOVT', 'arts', false, true, false, 11, false, 'Government for senior secondary'),
  ('History', 'SS-HIST', 'arts', false, true, false, 12, false, 'History for senior secondary'),
  ('Economics', 'SS-ECON', 'commercial', false, true, false, 13, false, 'Economics for senior secondary'),
  ('Commerce', 'SS-COMM', 'commercial', false, true, false, 14, false, 'Commerce for senior secondary'),
  ('Accounting', 'SS-ACCT', 'commercial', false, true, false, 15, false, 'Financial accounting for SS'),
  ('Geography', 'SS-GEO', 'arts', false, true, false, 16, false, 'Geography for senior secondary'),
  ('Civic Education', 'SS-CIVIC', 'social_studies', true, false, false, 17, false, 'Civic education for SS'),
  ('Christian Religious Studies', 'SS-CRS', 'religious', false, true, false, 18, false, 'Christian religious studies for SS'),
  ('Islamic Religious Studies', 'SS-IRS', 'religious', false, true, false, 19, false, 'Islamic religious studies for SS'),
  ('French', 'SS-FRENCH', 'language', false, true, false, 20, false, 'French language for SS'),
  ('Yoruba', 'SS-YORUBA', 'language', false, true, false, 21, false, 'Yoruba language for SS'),
  ('Hausa', 'SS-HAUSA', 'language', false, true, false, 22, false, 'Hausa language for SS'),
  ('Igbo', 'SS-IGBO', 'language', false, true, false, 23, false, 'Igbo language for SS'),
  ('Visual Arts', 'SS-VART', 'arts', false, true, false, 24, false, 'Visual arts for senior secondary'),
  ('Music', 'SS-MUSIC', 'arts', false, true, false, 25, false, 'Music for senior secondary'),
  ('Physical Education', 'SS-PHE', 'physical', false, true, false, 26, false, 'Physical education for SS'),
  ('Food & Nutrition', 'SS-FNUTR', 'vocational', false, true, true, 27, false, 'Food and nutrition for SS'),
  ('Clothing & Textile', 'SS-CTEXT', 'vocational', false, true, true, 28, false, 'Clothing and textile for SS'),
  ('Data Processing', 'SS-DPROC', 'technology', false, true, false, 29, false, 'Data processing for SS'),
  ('Animal Husbandry', 'SS-ANIMAL', 'vocational', false, true, true, 30, false, 'Animal husbandry for SS'),
  ('Fisheries', 'SS-FISH', 'vocational', false, true, true, 31, false, 'Fisheries for senior secondary'),
  ('Tourism', 'SS-TOUR', 'vocational', false, true, true, 32, false, 'Tourism studies for SS'),
  ('Marketing', 'SS-MKTG', 'commercial', false, true, false, 33, false, 'Marketing for senior secondary'),
  ('Insurance', 'SS-INS', 'commercial', false, true, false, 34, false, 'Insurance for senior secondary')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TOPIC & SUBTOPIC MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  educational_level_id UUID REFERENCES public.educational_levels(id) ON DELETE SET NULL,
  curriculum_id UUID REFERENCES public.curricula(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  code TEXT,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  estimated_duration_minutes INT,
  icon_url TEXT,
  parent_topic_id UUID REFERENCES public.topics(id) ON DELETE CASCADE,
  depth_level INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.subtopics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  code TEXT,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  estimated_duration_minutes INT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Learning Objectives
CREATE TABLE IF NOT EXISTS public.learning_objectives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID REFERENCES public.topics(id) ON DELETE CASCADE,
  subtopic_id UUID REFERENCES public.subtopics(id) ON DELETE SET NULL,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  educational_level_id UUID NOT NULL REFERENCES public.educational_levels(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  description TEXT NOT NULL,
  bloom_level bloom_taxonomy_type NOT NULL DEFAULT 'remember',
  is_assessable BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(code)
);

-- ============================================================================
-- CONTENT MANAGEMENT (CCMS CORE)
-- ============================================================================

-- Content Items — the central table for all educational content
CREATE TABLE IF NOT EXISTS public.content_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content_type content_type_enum NOT NULL,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  educational_level_id UUID NOT NULL REFERENCES public.educational_levels(id) ON DELETE CASCADE,
  topic_id UUID REFERENCES public.topics(id) ON DELETE SET NULL,
  subtopic_id UUID REFERENCES public.subtopics(id) ON DELETE SET NULL,
  curriculum_id UUID REFERENCES public.curricula(id) ON DELETE SET NULL,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  question_category question_category_type,
  difficulty_level difficulty_level_type NOT NULL DEFAULT 'intermediate',
  bloom_level bloom_taxonomy_type NOT NULL DEFAULT 'remember',
  body TEXT NOT NULL,
  body_rich JSONB DEFAULT '{}',
  options JSONB DEFAULT '[]',
  correct_answer JSONB NOT NULL DEFAULT '{}',
  step_by_step_explanation TEXT,
  marking_scheme JSONB DEFAULT '{}',
  teacher_notes TEXT,
  learning_objective_ids UUID[] DEFAULT '{}',
  curriculum_references JSONB DEFAULT '[]',
  marks_allocated INT DEFAULT 1,
  time_allocated_seconds INT,
  source_type TEXT NOT NULL DEFAULT 'school_created',
  source_reference TEXT,
  is_past_question BOOLEAN NOT NULL DEFAULT false,
  past_exam_year INT,
  past_exam_body TEXT,
  has_licensing_rights BOOLEAN NOT NULL DEFAULT false,
  license_details JSONB DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  media_urls JSONB DEFAULT '[]',
  status content_status_type NOT NULL DEFAULT 'draft',
  version INT NOT NULL DEFAULT 1,
  parent_content_id UUID REFERENCES public.content_items(id) ON DELETE SET NULL,
  review_count INT NOT NULL DEFAULT 0,
  average_quality_score DECIMAL(3,2) DEFAULT 0.00,
  usage_count INT NOT NULL DEFAULT 0,
  is_ai_generated BOOLEAN NOT NULL DEFAULT false,
  ai_generation_metadata JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  reviewed_by UUID REFERENCES auth.users(id),
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Content Versions — full version history
CREATE TABLE IF NOT EXISTS public.content_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_item_id UUID NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  version_number INT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  body_rich JSONB DEFAULT '{}',
  options JSONB DEFAULT '[]',
  correct_answer JSONB NOT NULL DEFAULT '{}',
  step_by_step_explanation TEXT,
  marking_scheme JSONB DEFAULT '{}',
  teacher_notes TEXT,
  difficulty_level difficulty_level_type NOT NULL DEFAULT 'intermediate',
  bloom_level bloom_taxonomy_type NOT NULL DEFAULT 'remember',
  change_summary TEXT,
  changed_fields TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(content_item_id, version_number)
);

-- Content Reviews
CREATE TABLE IF NOT EXISTS public.content_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_item_id UUID NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES auth.users(id),
  quality_score INT NOT NULL CHECK (quality_score >= 1 AND quality_score <= 5),
  accuracy_score INT NOT NULL CHECK (accuracy_score >= 1 AND accuracy_score <= 5),
  relevance_score INT NOT NULL CHECK (relevance_score >= 1 AND relevance_score <= 5),
  curriculum_alignment_score INT NOT NULL CHECK (curriculum_alignment_score >= 1 AND curriculum_alignment_score <= 5),
  comment TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Bulk Import Tracking
CREATE TABLE IF NOT EXISTS public.content_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  educational_level_id UUID REFERENCES public.educational_levels(id) ON DELETE SET NULL,
  file_name TEXT NOT NULL,
  file_url TEXT,
  file_size_bytes BIGINT,
  total_items INT NOT NULL DEFAULT 0,
  processed_items INT NOT NULL DEFAULT 0,
  successful_items INT NOT NULL DEFAULT 0,
  failed_items INT NOT NULL DEFAULT 0,
  status import_status_type NOT NULL DEFAULT 'pending',
  error_log JSONB DEFAULT '[]',
  mapping_config JSONB DEFAULT '{}',
  has_licensing_declaration BOOLEAN NOT NULL DEFAULT false,
  license_details JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Content Collections (curated groups of content items)
CREATE TABLE IF NOT EXISTS public.content_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  educational_level_id UUID REFERENCES public.educational_levels(id) ON DELETE SET NULL,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  collection_type TEXT NOT NULL DEFAULT 'custom',
  is_public BOOLEAN NOT NULL DEFAULT false,
  sort_order INT NOT NULL DEFAULT 0,
  content_count INT NOT NULL DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.content_collection_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID NOT NULL REFERENCES public.content_collections(id) ON DELETE CASCADE,
  content_item_id UUID NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  sort_order INT NOT NULL DEFAULT 0,
  added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(collection_id, content_item_id)
);

-- ============================================================================
-- AI CURRICULUM ENGINE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ai_curriculum_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  educational_level_id UUID REFERENCES public.educational_levels(id) ON DELETE SET NULL,
  curriculum_id UUID REFERENCES public.curricula(id) ON DELETE SET NULL,
  preferred_difficulty difficulty_level_type DEFAULT 'intermediate',
  preferred_bloom_levels bloom_taxonomy_type[] DEFAULT '{remember,understand,apply}',
  question_type_distribution JSONB DEFAULT '{}',
  language_style TEXT DEFAULT 'age_appropriate',
  include_explanations BOOLEAN NOT NULL DEFAULT true,
  include_marking_schemes BOOLEAN NOT NULL DEFAULT true,
  include_teacher_notes BOOLEAN NOT NULL DEFAULT false,
  content_tone TEXT DEFAULT 'academic',
  cultural_context TEXT DEFAULT 'nigerian',
  max_questions_per_generation INT DEFAULT 10,
  quality_threshold DECIMAL(3,2) DEFAULT 3.50,
  auto_approve_threshold DECIMAL(3,2) DEFAULT 4.50,
  topic_coverage_preference TEXT DEFAULT 'balanced',
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, subject_id, educational_level_id, curriculum_id)
);

-- AI Generation Rules per level
CREATE TABLE IF NOT EXISTS public.ai_generation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  educational_level_id UUID NOT NULL REFERENCES public.educational_levels(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL,
  conditions JSONB NOT NULL DEFAULT '{}',
  actions JSONB NOT NULL DEFAULT '{}',
  priority INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- ANSWER REPOSITORY (Enhanced)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.answer_repository (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_item_id UUID NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  correct_answers JSONB NOT NULL DEFAULT '[]',
  step_by_step_explanation TEXT NOT NULL,
  explanation_rich JSONB DEFAULT '{}',
  marking_scheme JSONB NOT NULL DEFAULT '{}',
  alternative_answers JSONB DEFAULT '[]',
  common_mistakes JSONB DEFAULT '[]',
  teacher_notes TEXT,
  curriculum_references JSONB DEFAULT '[]',
  learning_objective_ids UUID[] DEFAULT '{}',
  difficulty_justification TEXT,
  version INT NOT NULL DEFAULT 1,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(content_item_id, version)
);

-- ============================================================================
-- ENTERPRISE SECURITY
-- ============================================================================

-- Audit Trail
CREATE TABLE IF NOT EXISTS public.audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  school_id UUID REFERENCES public.schools(id),
  action audit_action_type NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  device_id TEXT,
  session_id TEXT,
  api_endpoint TEXT,
  http_method TEXT,
  response_status INT,
  duration_ms INT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- MFA Configuration
CREATE TABLE IF NOT EXISTS public.mfa_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mfa_method mfa_method_type NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  secret_encrypted TEXT,
  backup_codes_encrypted TEXT,
  phone_number_encrypted TEXT,
  verification_attempts INT NOT NULL DEFAULT 0,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, mfa_method)
);

-- API Keys
CREATE TABLE IF NOT EXISTS public.api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  key_hash TEXT NOT NULL UNIQUE,
  key_prefix TEXT NOT NULL,
  name TEXT NOT NULL,
  scopes TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  rate_limit_override INT,
  expires_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  usage_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rate Limiting
CREATE TABLE IF NOT EXISTS public.rate_limit_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scope rate_limit_scope_type NOT NULL,
  identifier TEXT NOT NULL,
  endpoint_pattern TEXT DEFAULT '*',
  max_requests INT NOT NULL,
  window_seconds INT NOT NULL DEFAULT 60,
  action_on_limit TEXT NOT NULL DEFAULT 'reject',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(scope, identifier, endpoint_pattern)
);

CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scope rate_limit_scope_type NOT NULL,
  identifier TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  request_count INT NOT NULL DEFAULT 0,
  window_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  blocked_at TIMESTAMPTZ,
  UNIQUE(scope, identifier, endpoint, window_start)
);

-- Security Events
CREATE TABLE IF NOT EXISTS public.security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'medium',
  user_id UUID REFERENCES auth.users(id),
  school_id UUID REFERENCES public.schools(id),
  ip_address INET,
  user_agent TEXT,
  details JSONB DEFAULT '{}',
  is_resolved BOOLEAN NOT NULL DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Session Management
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_token_hash TEXT NOT NULL,
  device_id TEXT,
  device_name TEXT,
  device_type TEXT,
  ip_address INET,
  user_agent TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  invalidated_by UUID REFERENCES auth.users(id),
  invalidated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Data Encryption Keys (metadata only, keys stored in vault)
CREATE TABLE IF NOT EXISTS public.encryption_key_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_identifier TEXT NOT NULL UNIQUE,
  algorithm TEXT NOT NULL DEFAULT 'AES-256-GCM',
  purpose TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  rotated_from UUID REFERENCES public.encryption_key_metadata(id),
  rotated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- MONITORING & OBSERVABILITY
-- ============================================================================

-- System Metrics
CREATE TABLE IF NOT EXISTS public.system_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  metric_type metric_type_enum NOT NULL,
  value DOUBLE PRECISION NOT NULL,
  unit TEXT,
  tags JSONB DEFAULT '{}',
  school_id UUID REFERENCES public.schools(id),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Alert Rules
CREATE TABLE IF NOT EXISTS public.alert_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  metric_name TEXT NOT NULL,
  condition_operator TEXT NOT NULL,
  threshold_value DOUBLE PRECISION NOT NULL,
  duration_seconds INT,
  severity alert_severity_type NOT NULL DEFAULT 'warning',
  notification_channels TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_triggered_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Alert Incidents
CREATE TABLE IF NOT EXISTS public.alert_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_rule_id UUID NOT NULL REFERENCES public.alert_rules(id) ON DELETE CASCADE,
  current_value DOUBLE PRECISION NOT NULL,
  threshold_value DOUBLE PRECISION NOT NULL,
  severity alert_severity_type NOT NULL,
  status TEXT NOT NULL DEFAULT 'firing',
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Performance Logs
CREATE TABLE IF NOT EXISTS public.performance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type TEXT NOT NULL,
  operation_name TEXT NOT NULL,
  duration_ms INT NOT NULL,
  is_slow BOOLEAN NOT NULL DEFAULT false,
  user_id UUID REFERENCES auth.users(id),
  school_id UUID REFERENCES public.schools(id),
  endpoint TEXT,
  query_hash TEXT,
  request_payload_size_bytes INT,
  response_payload_size_bytes INT,
  error_message TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Error Tracking
CREATE TABLE IF NOT EXISTS public.error_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  error_hash TEXT,
  occurrence_count INT NOT NULL DEFAULT 1,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID REFERENCES auth.users(id),
  school_id UUID REFERENCES public.schools(id),
  device_info JSONB DEFAULT '{}',
  app_version TEXT,
  platform TEXT,
  is_resolved BOOLEAN NOT NULL DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

-- ============================================================================
-- CI/CD & DEPLOYMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  environment TEXT NOT NULL,
  version TEXT NOT NULL,
  commit_hash TEXT,
  branch TEXT,
  deployer_id UUID REFERENCES auth.users(id),
  status deployment_status_type NOT NULL DEFAULT 'pending',
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  rollback_from TEXT,
  notes TEXT,
  metadata JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.deployment_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_id UUID NOT NULL REFERENCES public.deployments(id) ON DELETE CASCADE,
  step_name TEXT NOT NULL,
  step_order INT NOT NULL,
  status deployment_status_type NOT NULL DEFAULT 'pending',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  logs TEXT,
  duration_ms INT
);

-- Test Results
CREATE TABLE IF NOT EXISTS public.test_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_type test_type_enum NOT NULL,
  test_suite TEXT NOT NULL,
  test_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  duration_ms INT,
  error_message TEXT,
  stack_trace TEXT,
  coverage_percentage DECIMAL(5,2),
  metadata JSONB DEFAULT '{}',
  deployment_id UUID REFERENCES public.deployments(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.test_suites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  test_type test_type_enum NOT NULL,
  total_tests INT NOT NULL DEFAULT 0,
  passed_tests INT NOT NULL DEFAULT 0,
  failed_tests INT NOT NULL DEFAULT 0,
  skipped_tests INT NOT NULL DEFAULT 0,
  coverage_percentage DECIMAL(5,2) DEFAULT 0.00,
  duration_ms INT,
  deployment_id UUID REFERENCES public.deployments(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- Database Migration Tracking
CREATE TABLE IF NOT EXISTS public.database_migrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  migration_name TEXT NOT NULL UNIQUE,
  version TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  applied_by UUID REFERENCES auth.users(id),
  execution_time_ms INT,
  checksum TEXT,
  rollback_sql TEXT,
  is_rolled_back BOOLEAN NOT NULL DEFAULT false
);

-- ============================================================================
-- BACKUP & DISASTER RECOVERY
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.backup_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_type TEXT NOT NULL,
  storage_location TEXT NOT NULL,
  file_size_bytes BIGINT,
  is_encrypted BOOLEAN NOT NULL DEFAULT true,
  checksum TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'in_progress',
  error_message TEXT,
  retention_until TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Educational Levels
CREATE INDEX idx_educational_levels_category ON public.educational_levels(level_category);
CREATE INDEX idx_educational_levels_order ON public.educational_levels(level_order);
CREATE INDEX idx_educational_levels_active ON public.educational_levels(is_active);

-- School Level Configurations
CREATE INDEX idx_school_level_config_school ON public.school_level_configurations(school_id);
CREATE INDEX idx_school_level_config_level ON public.school_level_configurations(educational_level_id);
CREATE INDEX idx_school_level_config_enabled ON public.school_level_configurations(school_id, is_enabled);

-- Curricula
CREATE INDEX idx_curricula_type ON public.curricula(curriculum_type);
CREATE INDEX idx_curricula_country ON public.curricula(country_code);
CREATE INDEX idx_curricula_active ON public.curricula(is_active);
CREATE INDEX idx_curricula_parent ON public.curricula(parent_curriculum_id);

-- Curriculum Versions
CREATE INDEX idx_curriculum_versions_curriculum ON public.curriculum_versions(curriculum_id);
CREATE INDEX idx_curriculum_versions_current ON public.curriculum_versions(curriculum_id, is_current);

-- Curriculum Level Mappings
CREATE INDEX idx_curriculum_level_mappings_curriculum ON public.curriculum_level_mappings(curriculum_id);
CREATE INDEX idx_curriculum_level_mappings_level ON public.curriculum_level_mappings(educational_level_id);

-- Subjects
CREATE INDEX idx_subjects_curriculum ON public.subjects(curriculum_id);
CREATE INDEX idx_subjects_level ON public.subjects(educational_level_id);
CREATE INDEX idx_subjects_school ON public.subjects(school_id);
CREATE INDEX idx_subjects_group ON public.subjects(subject_group);
CREATE INDEX idx_subjects_core ON public.subjects(is_core);
CREATE INDEX idx_subjects_active ON public.subjects(is_active);
CREATE INDEX idx_subjects_custom ON public.subjects(is_custom);
CREATE INDEX idx_subjects_search ON public.subjects USING gin(to_tsvector('english', name || ' ' || COALESCE(code, '') || ' ' || COALESCE(description, '')));

-- Topics
CREATE INDEX idx_topics_subject ON public.topics(subject_id);
CREATE INDEX idx_topics_level ON public.topics(educational_level_id);
CREATE INDEX idx_topics_curriculum ON public.topics(curriculum_id);
CREATE INDEX idx_topics_parent ON public.topics(parent_topic_id);
CREATE INDEX idx_topics_active ON public.topics(is_active);
CREATE INDEX idx_topics_sort ON public.topics(subject_id, sort_order);
CREATE INDEX idx_topics_search ON public.topics USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Subtopics
CREATE INDEX idx_subtopics_topic ON public.subtopics(topic_id);
CREATE INDEX idx_subtopics_active ON public.subtopics(is_active);
CREATE INDEX idx_subtopics_sort ON public.subtopics(topic_id, sort_order);

-- Learning Objectives
CREATE INDEX idx_learning_objectives_topic ON public.learning_objectives(topic_id);
CREATE INDEX idx_learning_objectives_subtopic ON public.learning_objectives(subtopic_id);
CREATE INDEX idx_learning_objectives_subject ON public.learning_objectives(subject_id);
CREATE INDEX idx_learning_objectives_level ON public.learning_objectives(educational_level_id);
CREATE INDEX idx_learning_objectives_bloom ON public.learning_objectives(bloom_level);
CREATE INDEX idx_learning_objectives_code ON public.learning_objectives(code);

-- Content Items (heavily queried)
CREATE INDEX idx_content_items_subject ON public.content_items(subject_id);
CREATE INDEX idx_content_items_level ON public.content_items(educational_level_id);
CREATE INDEX idx_content_items_topic ON public.content_items(topic_id);
CREATE INDEX idx_content_items_subtopic ON public.content_items(subtopic_id);
CREATE INDEX idx_content_items_curriculum ON public.content_items(curriculum_id);
CREATE INDEX idx_content_items_school ON public.content_items(school_id);
CREATE INDEX idx_content_items_type ON public.content_items(content_type);
CREATE INDEX idx_content_items_status ON public.content_items(status);
CREATE INDEX idx_content_items_difficulty ON public.content_items(difficulty_level);
CREATE INDEX idx_content_items_category ON public.content_items(question_category);
CREATE INDEX idx_content_items_bloom ON public.content_items(bloom_level);
CREATE INDEX idx_content_items_source ON public.content_items(source_type);
CREATE INDEX idx_content_items_past ON public.content_items(is_past_question);
CREATE INDEX idx_content_items_ai ON public.content_items(is_ai_generated);
CREATE INDEX idx_content_items_created_by ON public.content_items(created_by);
CREATE INDEX idx_content_items_published ON public.content_items(published_at) WHERE status = 'published';
CREATE INDEX idx_content_items_quality ON public.content_items(average_quality_score) WHERE status = 'published';
CREATE INDEX idx_content_items_usage ON public.content_items(usage_count DESC) WHERE status = 'published';
CREATE INDEX idx_content_items_version ON public.content_items(parent_content_id);
CREATE INDEX idx_content_items_tags ON public.content_items USING gin(tags);
CREATE INDEX idx_content_items_search ON public.content_items USING gin(to_tsvector('english', title || ' ' || body || ' ' || COALESCE(step_by_step_explanation, '')));
CREATE INDEX idx_content_items_composite ON public.content_items(subject_id, educational_level_id, difficulty_level, status);

-- Content Versions
CREATE INDEX idx_content_versions_item ON public.content_versions(content_item_id);
CREATE INDEX idx_content_versions_number ON public.content_versions(content_item_id, version_number DESC);

-- Content Reviews
CREATE INDEX idx_content_reviews_item ON public.content_reviews(content_item_id);
CREATE INDEX idx_content_reviews_reviewer ON public.content_reviews(reviewer_id);
CREATE INDEX idx_content_reviews_status ON public.content_reviews(status);

-- Content Imports
CREATE INDEX idx_content_imports_school ON public.content_imports(school_id);
CREATE INDEX idx_content_imports_status ON public.content_imports(status);
CREATE INDEX idx_content_imports_created_by ON public.content_imports(created_by);

-- Content Collections
CREATE INDEX idx_content_collections_school ON public.content_collections(school_id);
CREATE INDEX idx_content_collections_subject ON public.content_collections(subject_id);
CREATE INDEX idx_content_collections_type ON public.content_collections(collection_type);
CREATE INDEX idx_content_collections_public ON public.content_collections(is_public);

-- Content Collection Items
CREATE INDEX idx_content_collection_items_collection ON public.content_collection_items(collection_id);
CREATE INDEX idx_content_collection_items_content ON public.content_collection_items(content_item_id);

-- AI Curriculum Configs
CREATE INDEX idx_ai_curriculum_configs_school ON public.ai_curriculum_configs(school_id);
CREATE INDEX idx_ai_curriculum_configs_subject ON public.ai_curriculum_configs(subject_id);
CREATE INDEX idx_ai_curriculum_configs_level ON public.ai_curriculum_configs(educational_level_id);

-- AI Generation Rules
CREATE INDEX idx_ai_generation_rules_level ON public.ai_generation_rules(educational_level_id);
CREATE INDEX idx_ai_generation_rules_subject ON public.ai_generation_rules(subject_id);
CREATE INDEX idx_ai_generation_rules_active ON public.ai_generation_rules(is_active);

-- Answer Repository
CREATE INDEX idx_answer_repository_content ON public.answer_repository(content_item_id);
CREATE INDEX idx_answer_repository_verified ON public.answer_repository(is_verified);
CREATE INDEX idx_answer_repository_version ON public.answer_repository(content_item_id, version);

-- Audit Trail (very high volume)
CREATE INDEX idx_audit_trail_user ON public.audit_trail(user_id);
CREATE INDEX idx_audit_trail_school ON public.audit_trail(school_id);
CREATE INDEX idx_audit_trail_action ON public.audit_trail(action);
CREATE INDEX idx_audit_trail_resource ON public.audit_trail(resource_type, resource_id);
CREATE INDEX idx_audit_trail_created ON public.audit_trail(created_at DESC);
CREATE INDEX idx_audit_trail_ip ON public.audit_trail(ip_address);
CREATE INDEX idx_audit_trail_session ON public.audit_trail(session_id);

-- MFA Configurations
CREATE INDEX idx_mfa_configs_user ON public.mfa_configurations(user_id);
CREATE INDEX idx_mfa_configs_enabled ON public.mfa_configurations(user_id, is_enabled);

-- API Keys
CREATE INDEX idx_api_keys_user ON public.api_keys(user_id);
CREATE INDEX idx_api_keys_school ON public.api_keys(school_id);
CREATE INDEX idx_api_keys_prefix ON public.api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON public.api_keys(is_active);
CREATE INDEX idx_api_keys_hash ON public.api_keys(key_hash);

-- Rate Limiting
CREATE INDEX idx_rate_limit_configs_scope ON public.rate_limit_configs(scope, identifier);
CREATE INDEX idx_rate_limit_counters_scope ON public.rate_limit_counters(scope, identifier);
CREATE INDEX idx_rate_limit_counters_window ON public.rate_limit_counters(window_start);

-- Security Events
CREATE INDEX idx_security_events_type ON public.security_events(event_type);
CREATE INDEX idx_security_events_user ON public.security_events(user_id);
CREATE INDEX idx_security_events_school ON public.security_events(school_id);
CREATE INDEX idx_security_events_severity ON public.security_events(severity);
CREATE INDEX idx_security_events_resolved ON public.security_events(is_resolved);
CREATE INDEX idx_security_events_created ON public.security_events(created_at DESC);

-- User Sessions
CREATE INDEX idx_user_sessions_user ON public.user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON public.user_sessions(session_token_hash);
CREATE INDEX idx_user_sessions_active ON public.user_sessions(user_id, is_active);
CREATE INDEX idx_user_sessions_device ON public.user_sessions(device_id);
CREATE INDEX idx_user_sessions_expiry ON public.user_sessions(expires_at);

-- Encryption Keys
CREATE INDEX idx_encryption_keys_identifier ON public.encryption_key_metadata(key_identifier);
CREATE INDEX idx_encryption_keys_active ON public.encryption_key_metadata(is_active);

-- System Metrics
CREATE INDEX idx_system_metrics_name ON public.system_metrics(metric_name);
CREATE INDEX idx_system_metrics_recorded ON public.system_metrics(recorded_at DESC);
CREATE INDEX idx_system_metrics_school ON public.system_metrics(school_id);
CREATE INDEX idx_system_metrics_name_time ON public.system_metrics(metric_name, recorded_at DESC);

-- Alert Rules
CREATE INDEX idx_alert_rules_metric ON public.alert_rules(metric_name);
CREATE INDEX idx_alert_rules_active ON public.alert_rules(is_active);

-- Alert Incidents
CREATE INDEX idx_alert_incidents_rule ON public.alert_incidents(alert_rule_id);
CREATE INDEX idx_alert_incidents_status ON public.alert_incidents(status);
CREATE INDEX idx_alert_incidents_created ON public.alert_incidents(created_at DESC);

-- Performance Logs
CREATE INDEX idx_performance_logs_type ON public.performance_logs(operation_type);
CREATE INDEX idx_performance_logs_slow ON public.performance_logs(is_slow) WHERE is_slow = true;
CREATE INDEX idx_performance_logs_created ON public.performance_logs(created_at DESC);
CREATE INDEX idx_performance_logs_endpoint ON public.performance_logs(endpoint);
CREATE INDEX idx_performance_logs_school ON public.performance_logs(school_id);

-- Error Reports
CREATE INDEX idx_error_reports_type ON public.error_reports(error_type);
CREATE INDEX idx_error_reports_hash ON public.error_reports(error_hash);
CREATE INDEX idx_error_reports_resolved ON public.error_reports(is_resolved);
CREATE INDEX idx_error_reports_last_seen ON public.error_reports(last_seen_at DESC);
CREATE INDEX idx_error_reports_school ON public.error_reports(school_id);

-- Deployments
CREATE INDEX idx_deployments_env ON public.deployments(environment);
CREATE INDEX idx_deployments_status ON public.deployments(status);
CREATE INDEX idx_deployments_started ON public.deployments(started_at DESC);

-- Deployment Steps
CREATE INDEX idx_deployment_steps_deployment ON public.deployment_steps(deployment_id);

-- Test Results
CREATE INDEX idx_test_results_type ON public.test_results(test_type);
CREATE INDEX idx_test_results_suite ON public.test_results(test_suite);
CREATE INDEX idx_test_results_status ON public.test_results(status);
CREATE INDEX idx_test_results_deployment ON public.test_results(deployment_id);

-- Test Suites
CREATE INDEX idx_test_suites_deployment ON public.test_suites(deployment_id);
CREATE INDEX idx_test_suites_type ON public.test_suites(test_type);

-- Database Migrations
CREATE INDEX idx_db_migrations_name ON public.database_migrations(migration_name);
CREATE INDEX idx_db_migrations_version ON public.database_migrations(version);

-- Backup Records
CREATE INDEX idx_backup_records_type ON public.backup_records(backup_type);
CREATE INDEX idx_backup_records_status ON public.backup_records(status);
CREATE INDEX idx_backup_records_created ON public.backup_records(started_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.educational_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_level_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curricula ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_level_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtopics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_objectives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_collection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_curriculum_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answer_repository ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_trail ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mfa_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encryption_key_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.error_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployment_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_suites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.database_migrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_records ENABLE ROW LEVEL SECURITY;

-- Educational Levels: read-only for all authenticated users
CREATE POLICY "Educational levels readable by all authenticated users"
  ON public.educational_levels FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "Educational levels managed by super admins"
  ON public.educational_levels FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- School Level Configurations: school-scoped access
CREATE POLICY "School level configs readable by school members"
  ON public.school_level_configurations FOR SELECT
  TO authenticated USING (
    school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "School level configs managed by school admins"
  ON public.school_level_configurations FOR ALL
  TO authenticated USING (
    (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
     AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

-- Curricula: read for all, write for admins
CREATE POLICY "Curricula readable by authenticated users"
  ON public.curricula FOR SELECT TO authenticated USING (true);

CREATE POLICY "Curricula managed by admins"
  ON public.curricula FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('superAdmin', 'schoolAdmin'))
  );

-- Curriculum Versions: read for all, write for admins
CREATE POLICY "Curriculum versions readable by authenticated users"
  ON public.curriculum_versions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Curriculum versions managed by admins"
  ON public.curriculum_versions FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('superAdmin', 'schoolAdmin'))
  );

-- Curriculum Level Mappings: read for all, write for admins
CREATE POLICY "Curriculum level mappings readable by authenticated users"
  ON public.curriculum_level_mappings FOR SELECT TO authenticated USING (true);

CREATE POLICY "Curriculum level mappings managed by admins"
  ON public.curriculum_level_mappings FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('superAdmin', 'schoolAdmin'))
  );

-- Subjects: read for school members, write for admins
CREATE POLICY "Subjects readable by school members"
  ON public.subjects FOR SELECT
  TO authenticated USING (
    school_id IS NULL
    OR school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Subjects managed by admins"
  ON public.subjects FOR ALL
  TO authenticated USING (
    (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
     AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
    OR (school_id IS NULL AND EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin'))
  );

-- Topics: read for school members, write for teachers+
CREATE POLICY "Topics readable by school members"
  ON public.topics FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM public.subjects WHERE subjects.id = topics.subject_id AND (subjects.school_id IS NULL OR subjects.school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())))
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Topics managed by teachers and admins"
  ON public.topics FOR ALL
  TO authenticated USING (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

-- Subtopics: same as topics
CREATE POLICY "Subtopics readable by school members"
  ON public.subtopics FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.topics WHERE topics.id = subtopics.topic_id)
  );

CREATE POLICY "Subtopics managed by teachers and admins"
  ON public.subtopics FOR ALL
  TO authenticated USING (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

-- Learning Objectives: read for all, write for teachers+
CREATE POLICY "Learning objectives readable by authenticated users"
  ON public.learning_objectives FOR SELECT TO authenticated USING (true);

CREATE POLICY "Learning objectives managed by teachers and admins"
  ON public.learning_objectives FOR ALL
  TO authenticated USING (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

-- Content Items: school-scoped with role-based access
CREATE POLICY "Content items readable by school members"
  ON public.content_items FOR SELECT
  TO authenticated USING (
    status = 'published'
    OR (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid()))
    OR created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Content items created by teachers and admins"
  ON public.content_items FOR INSERT
  TO authenticated WITH CHECK (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

CREATE POLICY "Content items updated by creators and admins"
  ON public.content_items FOR UPDATE
  TO authenticated USING (
    created_by = auth.uid()
    OR (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
        AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

CREATE POLICY "Content items deleted by admins only"
  ON public.content_items FOR DELETE
  TO authenticated USING (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin'))
  );

-- Content Versions: follow content item access
CREATE POLICY "Content versions readable by content item access"
  ON public.content_versions FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_items WHERE content_items.id = content_versions.content_item_id AND (
      content_items.status = 'published' OR content_items.created_by = auth.uid() OR
      EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
    ))
  );

CREATE POLICY "Content versions managed by content creators"
  ON public.content_versions FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_items WHERE content_items.id = content_versions.content_item_id AND content_items.created_by = auth.uid())
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin'))
  );

-- Content Reviews: reviewers and admins
CREATE POLICY "Content reviews readable by content access"
  ON public.content_reviews FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_items WHERE content_items.id = content_reviews.content_item_id)
  );

CREATE POLICY "Content reviews created by reviewers"
  ON public.content_reviews FOR INSERT
  TO authenticated WITH CHECK (
    reviewer_id = auth.uid() AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

-- Content Imports: school-scoped
CREATE POLICY "Content imports readable by school members"
  ON public.content_imports FOR SELECT
  TO authenticated USING (
    school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
    OR created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Content imports managed by school admins and teachers"
  ON public.content_imports FOR ALL
  TO authenticated USING (
    created_by = auth.uid()
    OR (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
        AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

-- Content Collections: school-scoped
CREATE POLICY "Content collections readable by school members"
  ON public.content_collections FOR SELECT
  TO authenticated USING (
    is_public = true
    OR school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
    OR created_by = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Content collections managed by creators and admins"
  ON public.content_collections FOR ALL
  TO authenticated USING (
    created_by = auth.uid()
    OR (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
        AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

-- Content Collection Items
CREATE POLICY "Collection items readable via collection access"
  ON public.content_collection_items FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_collections WHERE content_collections.id = content_collection_items.collection_id)
  );

CREATE POLICY "Collection items managed via collection access"
  ON public.content_collection_items FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_collections WHERE content_collections.id = content_collection_items.collection_id AND (content_collections.created_by = auth.uid() OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin'))))
  );

-- AI Curriculum Configs: school-scoped
CREATE POLICY "AI curriculum configs readable by school members"
  ON public.ai_curriculum_configs FOR SELECT
  TO authenticated USING (
    school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "AI curriculum configs managed by admins"
  ON public.ai_curriculum_configs FOR ALL
  TO authenticated USING (
    (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
     AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

-- AI Generation Rules: admin-only
CREATE POLICY "AI generation rules readable by authenticated users"
  ON public.ai_generation_rules FOR SELECT TO authenticated USING (true);

CREATE POLICY "AI generation rules managed by super admins"
  ON public.ai_generation_rules FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Answer Repository: follows content item access
CREATE POLICY "Answer repository readable by content access"
  ON public.answer_repository FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.content_items WHERE content_items.id = answer_repository.content_item_id AND (
      content_items.status = 'published' OR content_items.created_by = auth.uid() OR
      EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
    ))
  );

CREATE POLICY "Answer repository managed by teachers and admins"
  ON public.answer_repository FOR ALL
  TO authenticated USING (
    auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher', 'schoolAdmin', 'superAdmin'))
  );

-- Audit Trail: super admin read-only
CREATE POLICY "Audit trail readable by super admins"
  ON public.audit_trail FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Audit trail insert by system"
  ON public.audit_trail FOR INSERT
  TO authenticated WITH CHECK (true);

-- MFA Configurations: user-scoped
CREATE POLICY "MFA configs readable by owner"
  ON public.mfa_configurations FOR SELECT
  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "MFA configs managed by owner"
  ON public.mfa_configurations FOR ALL
  TO authenticated USING (user_id = auth.uid());

-- API Keys: user-scoped
CREATE POLICY "API keys readable by owner"
  ON public.api_keys FOR SELECT
  TO authenticated USING (
    user_id = auth.uid()
    OR (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid())
        AND auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('schoolAdmin', 'superAdmin')))
  );

CREATE POLICY "API keys managed by owner"
  ON public.api_keys FOR ALL
  TO authenticated USING (user_id = auth.uid());

-- Rate Limit Configs: super admin only
CREATE POLICY "Rate limit configs readable by super admins"
  ON public.rate_limit_configs FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Rate limit configs managed by super admins"
  ON public.rate_limit_configs FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Security Events: super admin
CREATE POLICY "Security events readable by super admins"
  ON public.security_events FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Security events insert by system"
  ON public.security_events FOR INSERT
  TO authenticated WITH CHECK (true);

-- User Sessions: own sessions
CREATE POLICY "User sessions readable by owner"
  ON public.user_sessions FOR SELECT
  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "User sessions managed by owner or super admin"
  ON public.user_sessions FOR ALL
  TO authenticated USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Encryption Key Metadata: super admin only
CREATE POLICY "Encryption key metadata readable by super admins"
  ON public.encryption_key_metadata FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- System Metrics: admin access
CREATE POLICY "System metrics readable by admins"
  ON public.system_metrics FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' IN ('superAdmin', 'schoolAdmin'))
  );

-- Alert Rules: super admin
CREATE POLICY "Alert rules readable by super admins"
  ON public.alert_rules FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Alert rules managed by super admins"
  ON public.alert_rules FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Alert Incidents: super admin
CREATE POLICY "Alert incidents readable by super admins"
  ON public.alert_incidents FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

CREATE POLICY "Alert incidents managed by super admins"
  ON public.alert_incidents FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Performance Logs: super admin
CREATE POLICY "Performance logs readable by super admins"
  ON public.performance_logs FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Error Reports: super admin
CREATE POLICY "Error reports readable by super admins"
  ON public.error_reports FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Deployments: super admin
CREATE POLICY "Deployments managed by super admins"
  ON public.deployments FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Test Results: super admin
CREATE POLICY "Test results readable by super admins"
  ON public.test_results FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Backup Records: super admin
CREATE POLICY "Backup records managed by super admins"
  ON public.backup_records FOR ALL
  TO authenticated USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = auth.uid() AND auth.users.raw_user_meta_data->>'role' = 'superAdmin')
  );

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Get educational levels for a school
CREATE OR REPLACE FUNCTION public.get_school_levels(p_school_id UUID)
RETURNS TABLE (
  id UUID, code TEXT, name TEXT, level_category level_category_type,
  level_order INT, min_age INT, max_age INT, description TEXT,
  is_enabled BOOLEAN, custom_name TEXT
) AS $$
SELECT el.id, el.code, el.name, el.level_category, el.level_order,
       el.min_age, el.max_age, el.description,
       COALESCE(slc.is_enabled, false) AS is_enabled,
       slc.custom_name
FROM public.educational_levels el
LEFT JOIN public.school_level_configurations slc
  ON slc.educational_level_id = el.id AND slc.school_id = p_school_id
WHERE el.is_active = true
ORDER BY el.level_order;
$$ LANGUAGE sql STABLE;

-- Get subjects for a school and educational level
CREATE OR REPLACE FUNCTION public.get_level_subjects(
  p_school_id UUID,
  p_educational_level_id UUID
)
RETURNS TABLE (
  id UUID, name TEXT, code TEXT, subject_group TEXT,
  is_core BOOLEAN, is_elective BOOLEAN, is_vocational BOOLEAN,
  description TEXT, icon_url TEXT, color_code TEXT, is_custom BOOLEAN
) AS $$
SELECT s.id, s.name, s.code, s.subject_group,
       s.is_core, s.is_elective, s.is_vocational,
       s.description, s.icon_url, s.color_code, s.is_custom
FROM public.subjects s
WHERE (s.school_id = p_school_id OR s.school_id IS NULL)
  AND (s.educational_level_id = p_educational_level_id OR s.educational_level_id IS NULL)
  AND s.is_active = true
ORDER BY s.sort_order, s.name;
$$ LANGUAGE sql STABLE;

-- Get content items with full details
CREATE OR REPLACE FUNCTION public.get_content_with_details(
  p_subject_id UUID DEFAULT NULL,
  p_educational_level_id UUID DEFAULT NULL,
  p_topic_id UUID DEFAULT NULL,
  p_content_type content_type_enum DEFAULT NULL,
  p_difficulty_level difficulty_level_type DEFAULT NULL,
  p_status content_status_type DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID, title TEXT, content_type content_type_enum,
  subject_name TEXT, level_name TEXT, topic_title TEXT,
  difficulty_level difficulty_level_type, bloom_level bloom_taxonomy_type,
  status content_status_type, version INT, usage_count INT,
  average_quality_score DECIMAL, created_at TIMESTAMPTZ
) AS $$
SELECT ci.id, ci.title, ci.content_type,
       s.name AS subject_name,
       el.name AS level_name,
       t.title AS topic_title,
       ci.difficulty_level, ci.bloom_level,
       ci.status, ci.version, ci.usage_count,
       ci.average_quality_score, ci.created_at
FROM public.content_items ci
LEFT JOIN public.subjects s ON s.id = ci.subject_id
LEFT JOIN public.educational_levels el ON el.id = ci.educational_level_id
LEFT JOIN public.topics t ON t.id = ci.topic_id
WHERE (p_subject_id IS NULL OR ci.subject_id = p_subject_id)
  AND (p_educational_level_id IS NULL OR ci.educational_level_id = p_educational_level_id)
  AND (p_topic_id IS NULL OR ci.topic_id = p_topic_id)
  AND (p_content_type IS NULL OR ci.content_type = p_content_type)
  AND (p_difficulty_level IS NULL OR ci.difficulty_level = p_difficulty_level)
  AND (p_status IS NULL OR ci.status = p_status)
ORDER BY ci.created_at DESC
LIMIT p_limit OFFSET p_offset;
$$ LANGUAGE sql STABLE;

-- Create content version automatically
CREATE OR REPLACE FUNCTION public.auto_version_content()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.version IS DISTINCT FROM NEW.version THEN
    INSERT INTO public.content_versions (
      content_item_id, version_number, title, body, body_rich,
      options, correct_answer, step_by_step_explanation,
      marking_scheme, teacher_notes, difficulty_level, bloom_level,
      change_summary, created_by
    ) VALUES (
      OLD.id, OLD.version, OLD.title, OLD.body, OLD.body_rich,
      OLD.options, OLD.correct_answer, OLD.step_by_step_explanation,
      OLD.marking_scheme, OLD.teacher_notes, OLD.difficulty_level, OLD.bloom_level,
      'Auto-versioned before update', OLD.created_by
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_version_content ON public.content_items;
CREATE TRIGGER trigger_auto_version_content
  BEFORE UPDATE ON public.content_items
  FOR EACH ROW EXECUTE FUNCTION public.auto_version_content();

-- Update content quality score
CREATE OR REPLACE FUNCTION public.update_content_quality_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.content_items
  SET average_quality_score = (
    SELECT ROUND(AVG((quality_score + accuracy_score + relevance_score + curriculum_alignment_score) / 4.0), 2)
    FROM public.content_reviews
    WHERE content_item_id = NEW.content_item_id
  ),
  review_count = (SELECT COUNT(*) FROM public.content_reviews WHERE content_item_id = NEW.content_item_id),
  updated_at = now()
  WHERE id = NEW.content_item_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_quality_score ON public.content_reviews;
CREATE TRIGGER trigger_update_quality_score
  AFTER INSERT OR UPDATE ON public.content_reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_content_quality_score();

-- Update content collection count
CREATE OR REPLACE FUNCTION public.update_collection_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.content_collections SET content_count = content_count + 1, updated_at = now() WHERE id = NEW.collection_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.content_collections SET content_count = GREATEST(content_count - 1, 0), updated_at = now() WHERE id = OLD.collection_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_collection_count_insert ON public.content_collection_items;
CREATE TRIGGER trigger_update_collection_count_insert
  AFTER INSERT ON public.content_collection_items
  FOR EACH ROW EXECUTE FUNCTION public.update_collection_count();

DROP TRIGGER IF EXISTS trigger_update_collection_count_delete ON public.content_collection_items;
CREATE TRIGGER trigger_update_collection_count_delete
  AFTER DELETE ON public.content_collection_items
  FOR EACH ROW EXECUTE FUNCTION public.update_collection_count();

-- Increment content usage count
CREATE OR REPLACE FUNCTION public.increment_content_usage(p_content_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.content_items SET usage_count = usage_count + 1, updated_at = now() WHERE id = p_content_id;
END;
$$ LANGUAGE sql;

-- Record audit event
CREATE OR REPLACE FUNCTION public.record_audit_event(
  p_user_id UUID DEFAULT NULL,
  p_school_id UUID DEFAULT NULL,
  p_action audit_action_type,
  p_resource_type TEXT,
  p_resource_id UUID DEFAULT NULL,
  p_old_values JSONB DEFAULT NULL,
  p_new_values JSONB DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_device_id TEXT DEFAULT NULL,
  p_session_id TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.audit_trail (
    user_id, school_id, action, resource_type, resource_id,
    old_values, new_values, ip_address, user_agent,
    device_id, session_id, metadata
  ) VALUES (
    p_user_id, p_school_id, p_action, p_resource_type, p_resource_id,
    p_old_values, p_new_values, p_ip_address, p_user_agent,
    p_device_id, p_session_id, p_metadata
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record security event
CREATE OR REPLACE FUNCTION public.record_security_event(
  p_event_type TEXT,
  p_severity TEXT DEFAULT 'medium',
  p_user_id UUID DEFAULT NULL,
  p_school_id UUID DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.security_events (
    event_type, severity, user_id, school_id, ip_address,
    user_agent, details
  ) VALUES (
    p_event_type, p_severity, p_user_id, p_school_id,
    p_ip_address, p_user_agent, p_details
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check rate limit
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_scope rate_limit_scope_type,
  p_identifier TEXT,
  p_endpoint TEXT DEFAULT '*'
)
RETURNS TABLE (allowed BOOLEAN, remaining INT, reset_at TIMESTAMPTZ) AS $$
DECLARE
  v_config RECORD;
  v_count INT;
  v_window_start TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_config FROM public.rate_limit_configs
  WHERE scope = p_scope AND identifier = p_identifier
    AND (endpoint_pattern = '*' OR endpoint_pattern = p_endpoint OR p_endpoint LIKE endpoint_pattern)
    AND is_active = true
  ORDER BY endpoint_pattern DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT true AS allowed, 999999 AS remaining, now() + interval '1 minute' AS reset_at;
    RETURN;
  END IF;

  v_window_start := date_trunc('second', now() - (v_config.window_seconds || ' seconds')::interval);

  SELECT COALESCE(SUM(request_count), 0) INTO v_count
  FROM public.rate_limit_counters
  WHERE scope = p_scope AND identifier = p_identifier
    AND endpoint = p_endpoint
    AND window_start >= v_window_start;

  IF v_count >= v_config.max_requests THEN
    RETURN QUERY SELECT false AS allowed, 0 AS remaining, v_window_start + (v_config.window_seconds || ' seconds')::interval AS reset_at;
  ELSE
    INSERT INTO public.rate_limit_counters (scope, identifier, endpoint, request_count, window_start)
    VALUES (p_scope, p_identifier, p_endpoint, 1, date_trunc('minute', now()))
    ON CONFLICT (scope, identifier, endpoint, window_start)
    DO UPDATE SET request_count = rate_limit_counters.request_count + 1;

    RETURN QUERY SELECT true AS allowed, v_config.max_requests - v_count - 1 AS remaining, v_window_start + (v_config.window_seconds || ' seconds')::interval AS reset_at;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Invalidate all user sessions (for remote session invalidation)
CREATE OR REPLACE FUNCTION public.invalidate_user_sessions(
  p_user_id UUID,
  p_except_session_id UUID DEFAULT NULL,
  p_invalidated_by UUID DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE public.user_sessions
  SET is_active = false, invalidated_by = p_invalidated_by, invalidated_at = now()
  WHERE user_id = p_user_id AND is_active = true
    AND (p_except_session_id IS NULL OR id != p_except_session_id);
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get CCMS statistics
CREATE OR REPLACE FUNCTION public.get_ccms_stats(p_school_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_subjects', (SELECT COUNT(*) FROM public.subjects WHERE (school_id = p_school_id OR school_id IS NULL) AND is_active = true),
    'total_topics', (SELECT COUNT(*) FROM public.topics t JOIN public.subjects s ON s.id = t.subject_id WHERE (s.school_id = p_school_id OR s.school_id IS NULL) AND t.is_active = true),
    'total_content', (SELECT COUNT(*) FROM public.content_items WHERE (school_id = p_school_id OR school_id IS NULL)),
    'published_content', (SELECT COUNT(*) FROM public.content_items WHERE status = 'published' AND (school_id = p_school_id OR school_id IS NULL)),
    'draft_content', (SELECT COUNT(*) FROM public.content_items WHERE status = 'draft' AND (school_id = p_school_id OR school_id IS NULL)),
    'ai_generated_content', (SELECT COUNT(*) FROM public.content_items WHERE is_ai_generated = true AND (school_id = p_school_id OR school_id IS NULL)),
    'past_questions', (SELECT COUNT(*) FROM public.content_items WHERE is_past_question = true AND (school_id = p_school_id OR school_id IS NULL)),
    'avg_quality_score', (SELECT ROUND(AVG(average_quality_score), 2) FROM public.content_items WHERE status = 'published' AND (school_id = p_school_id OR school_id IS NULL)),
    'total_imports', (SELECT COUNT(*) FROM public.content_imports WHERE school_id = p_school_id),
    'total_collections', (SELECT COUNT(*) FROM public.content_collections WHERE school_id = p_school_id),
    'pending_reviews', (SELECT COUNT(*) FROM public.content_reviews cr JOIN public.content_items ci ON ci.id = cr.content_item_id WHERE cr.status = 'pending' AND (ci.school_id = p_school_id OR ci.school_id IS NULL)),
    'content_by_type', (SELECT jsonb_object_agg(content_type, cnt) FROM (SELECT content_type, COUNT(*) as cnt FROM public.content_items WHERE (school_id = p_school_id OR school_id IS NULL) GROUP BY content_type) t),
    'content_by_difficulty', (SELECT jsonb_object_agg(difficulty_level, cnt) FROM (SELECT difficulty_level, COUNT(*) as cnt FROM public.content_items WHERE (school_id = p_school_id OR school_id IS NULL) GROUP BY difficulty_level) t)
  ) INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get curriculum tree (topics → subtopics → learning objectives)
CREATE OR REPLACE FUNCTION public.get_curriculum_tree(
  p_subject_id UUID,
  p_educational_level_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'topic', row_to_json(t.*),
      'subtopics', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'subtopic', row_to_json(st.*),
            'learning_objectives', (
              SELECT COALESCE(jsonb_agg(row_to_json(lo.*)), '[]'::jsonb)
              FROM public.learning_objectives lo
              WHERE lo.subtopic_id = st.id AND lo.is_active = true
              ORDER BY lo.sort_order
            )
          )
        ), '[]'::jsonb)
        FROM public.subtopics st
        WHERE st.topic_id = t.id AND st.is_active = true
        ORDER BY st.sort_order
      ),
      'learning_objectives', (
        SELECT COALESCE(jsonb_agg(row_to_json(lo.*)), '[]'::jsonb)
        FROM public.learning_objectives lo
        WHERE lo.topic_id = t.id AND lo.subtopic_id IS NULL AND lo.is_active = true
        ORDER BY lo.sort_order
      )
    )
  ) INTO v_result
  FROM public.topics t
  WHERE t.subject_id = p_subject_id
    AND (p_educational_level_id IS NULL OR t.educational_level_id = p_educational_level_id)
    AND t.is_active = true AND t.parent_topic_id IS NULL
  ORDER BY t.sort_order;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE;

-- Record performance metric
CREATE OR REPLACE FUNCTION public.record_metric(
  p_metric_name TEXT,
  p_metric_type metric_type_enum,
  p_value DOUBLE PRECISION,
  p_unit TEXT DEFAULT NULL,
  p_tags JSONB DEFAULT '{}',
  p_school_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.system_metrics (metric_name, metric_type, value, unit, tags, school_id)
  VALUES (p_metric_name, p_metric_type, p_value, p_unit, p_tags, p_school_id)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old metrics (retention policy)
CREATE OR REPLACE FUNCTION public.clean_old_metrics(p_days_to_retain INT DEFAULT 90)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM public.system_metrics WHERE recorded_at < now() - (p_days_to_retain || ' days')::interval;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old audit trail (retention policy)
CREATE OR REPLACE FUNCTION public.clean_old_audit_trail(p_days_to_retain INT DEFAULT 365)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM public.audit_trail WHERE created_at < now() - (p_days_to_retain || ' days')::interval;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old performance logs
CREATE OR REPLACE FUNCTION public.clean_old_performance_logs(p_days_to_retain INT DEFAULT 30)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM public.performance_logs WHERE created_at < now() - (p_days_to_retain || ' days')::interval;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_educational_levels_updated_at BEFORE UPDATE ON public.educational_levels FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_school_level_configurations_updated_at BEFORE UPDATE ON public.school_level_configurations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_curricula_updated_at BEFORE UPDATE ON public.curricula FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_topics_updated_at BEFORE UPDATE ON public.topics FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_subtopics_updated_at BEFORE UPDATE ON public.subtopics FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_learning_objectives_updated_at BEFORE UPDATE ON public.learning_objectives FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_content_items_updated_at BEFORE UPDATE ON public.content_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_content_collections_updated_at BEFORE UPDATE ON public.content_collections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_ai_curriculum_configs_updated_at BEFORE UPDATE ON public.ai_curriculum_configs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_ai_generation_rules_updated_at BEFORE UPDATE ON public.ai_generation_rules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_answer_repository_updated_at BEFORE UPDATE ON public.answer_repository FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_mfa_configurations_updated_at BEFORE UPDATE ON public.mfa_configurations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_rate_limit_configs_updated_at BEFORE UPDATE ON public.rate_limit_configs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_alert_rules_updated_at BEFORE UPDATE ON public.alert_rules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- PARTITIONING FOR HIGH-VOLUME TABLES
-- ============================================================================

-- Partition audit_trail by month (for performance with high-volume data)
-- Note: Requires PostgreSQL 10+ declarative partitioning
-- This creates monthly partitions automatically via a maintenance function

CREATE OR REPLACE FUNCTION public.create_audit_partition_if_not_exists(
  p_year INT,
  p_month INT
)
RETURNS VOID AS $$
DECLARE
  v_partition_name TEXT;
  v_start_date DATE;
  v_end_date DATE;
BEGIN
  v_partition_name := 'audit_trail_y' || p_year || 'm' || lpad(p_month::text, 2, '0');
  v_start_date := make_date(p_year, p_month, 1);
  v_end_date := v_start_date + interval '1 month';

  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = v_partition_name) THEN
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public.audit_trail
       FOR VALUES FROM (%L) TO (%L)',
      v_partition_name, v_start_date, v_end_date
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.educational_levels IS 'All Nigerian educational levels from Nursery to University, configurable per school';
COMMENT ON TABLE public.school_level_configurations IS 'Per-school enable/disable of educational levels with custom settings';
COMMENT ON TABLE public.curricula IS 'Curriculum definitions supporting NERDC, WAEC, NECO, NABTEB, custom, and international';
COMMENT ON TABLE public.curriculum_versions IS 'Version history for curriculum changes over time';
COMMENT ON TABLE public.subjects IS 'Subjects organized by educational level with Nigerian curriculum defaults';
COMMENT ON TABLE public.topics IS 'Hierarchical topic structure within subjects';
COMMENT ON TABLE public.subtopics IS 'Subtopics within topics for fine-grained content organization';
COMMENT ON TABLE public.learning_objectives IS 'Assessable learning objectives linked to Bloom taxonomy';
COMMENT ON TABLE public.content_items IS 'Central CCMS content table — questions, explanations, marking schemes, etc.';
COMMENT ON TABLE public.content_versions IS 'Full version history for content items with change tracking';
COMMENT ON TABLE public.content_reviews IS 'Quality review scores and feedback for content items';
COMMENT ON TABLE public.content_imports IS 'Bulk import tracking with licensing declarations';
COMMENT ON TABLE public.content_collections IS 'Curated groups of content items for organization';
COMMENT ON TABLE public.ai_curriculum_configs IS 'AI curriculum engine configuration per school/subject/level';
COMMENT ON TABLE public.ai_generation_rules IS 'Level-aware rules for AI content generation';
COMMENT ON TABLE public.answer_repository IS 'Enhanced answer data with explanations, marking schemes, and teacher notes';
COMMENT ON TABLE public.audit_trail IS 'Comprehensive audit log for all platform actions';
COMMENT ON TABLE public.mfa_configurations IS 'Multi-factor authentication settings per user';
COMMENT ON TABLE public.api_keys IS 'API key management with scope and rate limit controls';
COMMENT ON TABLE public.rate_limit_configs IS 'Rate limiting configuration by scope and endpoint';
COMMENT ON TABLE public.security_events IS 'Security incident tracking and resolution';
COMMENT ON TABLE public.user_sessions IS 'Active user sessions with device and IP tracking';
COMMENT ON TABLE public.system_metrics IS 'Platform metrics for monitoring and observability';
COMMENT ON TABLE public.alert_rules IS 'Automated alert rules based on metric thresholds';
COMMENT ON TABLE public.alert_incidents IS 'Fired alerts with acknowledgment and resolution tracking';
COMMENT ON TABLE public.performance_logs IS 'Performance tracking for API calls and database queries';
COMMENT ON TABLE public.error_reports IS 'Error tracking with deduplication and resolution status';
COMMENT ON TABLE public.deployments IS 'CI/CD deployment tracking across environments';
COMMENT ON TABLE public.test_results IS 'Automated test execution results';
COMMENT ON TABLE public.backup_records IS 'Database backup tracking with encryption and retention';
