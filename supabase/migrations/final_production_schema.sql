-- ============================================================================
-- EXAMFORGE AI — Final Production Schema
-- Nigerian Examination Ecosystem, Admission Hub, AI Coach, Customer Success,
-- Marketing, Analytics, EduOS Modular Architecture
-- ============================================================================

-- Helper function for safe enum creation
CREATE OR REPLACE FUNCTION public.create_enum_if_not_exists(enum_name TEXT, enum_values TEXT[])
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = enum_name) THEN
    EXECUTE format('CREATE TYPE public.%I AS ENUM (%s)', enum_name,
      (SELECT string_agg(quote_literal(v), ',') FROM unnest(enum_values) AS v));
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ENUMS
-- ============================================================================
SELECT public.create_enum_if_not_exists('exam_body_type', ARRAY[
  'waec','neco','nabteb','jamb_utme','post_utme','bece','common_entrance','jupeb','ijmb','custom']);
SELECT public.create_enum_if_not_exists('exam_category_type', ARRAY[
  'internal','mock','practice','past_paper','certification','entrance']);
SELECT public.create_enum_if_not_exists('preparation_type', ARRAY[
  'practice_questions','mock_cbt','ai_revision','topic_practice','timed_practice','full_mock']);
SELECT public.create_enum_if_not_exists('readiness_level_type', ARRAY[
  'not_started','beginning','developing','proficient','advanced','exam_ready']);
SELECT public.create_enum_if_not_exists('university_type_enum', ARRAY[
  'federal','state','private','polytechnic','college_of_education','monotechnic']);
SELECT public.create_enum_if_not_exists('admission_status_type', ARRAY[
  'not_applied','applied','accepted','rejected','deferred','withdrawn']);
SELECT public.create_enum_if_not_exists('module_status_type', ARRAY[
  'active','inactive','beta','deprecated','coming_soon']);
SELECT public.create_enum_if_not_exists('module_tier_type', ARRAY[
  'free','starter','professional','enterprise']);
SELECT public.create_enum_if_not_exists('onboarding_step_type', ARRAY[
  'welcome','role_selection','school_setup','subject_config','feature_tour','first_content','complete']);
SELECT public.create_enum_if_not_exists('tutorial_type_enum', ARRAY[
  'video','article','interactive','walkthrough']);
SELECT public.create_enum_if_not_exists('feedback_type_enum', ARRAY[
  'bug_report','feature_request','general_feedback','complaint','praise']);
SELECT public.create_enum_if_not_exists('campaign_type_enum', ARRAY[
  'email','sms','push','in_app']);
SELECT public.create_enum_if_not_exists('affiliate_status_type', ARRAY[
  'pending','active','suspended','terminated']);
SELECT public.create_enum_if_not_exists('proposal_status_type', ARRAY[
  'draft','sent','viewed','accepted','rejected','expired']);

-- ============================================================================
-- EXAMINATION BODIES & PRODUCTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.examination_bodies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  exam_body_type exam_body_type NOT NULL DEFAULT 'custom',
  country_code TEXT NOT NULL DEFAULT 'NG',
  description TEXT,
  logo_url TEXT,
  website_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.examination_bodies (name, code, exam_body_type, description) VALUES
  ('West African Examinations Council', 'WAEC', 'waec', 'West African senior school certificate examination'),
  ('National Examinations Council', 'NECO', 'neco', 'National senior school certificate examination'),
  ('National Business and Technical Examinations Board', 'NABTEB', 'nabteb', 'Technical and business examinations'),
  ('Joint Admissions and Matriculation Board', 'JAMB', 'jamb_utme', 'Unified Tertiary Matriculation Examination'),
  ('Post-UTME', 'POST_UTME', 'post_utme', 'University post-UTME screening tests'),
  ('Basic Education Certificate Examination', 'BECE', 'bece', 'Junior secondary certificate examination'),
  ('Common Entrance', 'COMMON_ENTRANCE', 'common_entrance', 'Primary school leaving examination'),
  ('Joint Universities Preliminary Examinations Board', 'JUPEB', 'jupeb', 'Direct entry A-level equivalent'),
  ('Interim Joint Matriculation Board', 'IJMB', 'ijmb', 'Advanced level programme for university admission')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.examination_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_body_id UUID NOT NULL REFERENCES public.examination_bodies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  exam_category exam_category_type NOT NULL DEFAULT 'practice',
  preparation_type preparation_type NOT NULL DEFAULT 'practice_questions',
  educational_level_id UUID REFERENCES public.educational_levels(id),
  subject_id UUID REFERENCES public.subjects(id),
  description TEXT,
  duration_minutes INT,
  total_marks INT,
  pass_mark DECIMAL(5,2),
  instructions JSONB DEFAULT '{}',
  is_timed BOOLEAN NOT NULL DEFAULT true,
  allows_negative_marking BOOLEAN NOT NULL DEFAULT false,
  negative_mark_ratio DECIMAL(3,2) DEFAULT 0.00,
  question_count INT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.mock_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  examination_product_id UUID REFERENCES public.examination_products(id) ON DELETE SET NULL,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  exam_body_type exam_body_type DEFAULT 'waec',
  duration_minutes INT NOT NULL DEFAULT 120,
  total_questions INT NOT NULL DEFAULT 0,
  total_marks INT NOT NULL DEFAULT 100,
  pass_mark DECIMAL(5,2) DEFAULT 50.00,
  instructions JSONB DEFAULT '{}',
  settings JSONB DEFAULT '{}',
  status content_status_type NOT NULL DEFAULT 'draft',
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  results_published_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.mock_exam_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mock_exam_id UUID NOT NULL REFERENCES public.mock_exams(id) ON DELETE CASCADE,
  content_item_id UUID NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  question_number INT NOT NULL,
  section_label TEXT,
  marks_allocated INT NOT NULL DEFAULT 1,
  is_compulsory BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.mock_exam_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mock_exam_id UUID NOT NULL REFERENCES public.mock_exams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  is_timed_out BOOLEAN NOT NULL DEFAULT false,
  total_score DECIMAL(5,2) DEFAULT 0,
  max_score DECIMAL(5,2) DEFAULT 0,
  percentage DECIMAL(5,2) DEFAULT 0,
  grade TEXT,
  time_taken_seconds INT DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'in_progress',
  device_info JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}'
);

-- ============================================================================
-- READINESS & STUDY PLANS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.readiness_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exam_body_id UUID REFERENCES public.examination_bodies(id),
  subject_id UUID REFERENCES public.subjects(id),
  readiness_level readiness_level_type NOT NULL DEFAULT 'not_started',
  readiness_score DECIMAL(5,2) DEFAULT 0.00,
  topics_mastered INT DEFAULT 0,
  topics_total INT DEFAULT 0,
  weak_topics JSONB DEFAULT '[]',
  strong_topics JSONB DEFAULT '[]',
  recommendations JSONB DEFAULT '[]',
  assessed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.study_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  exam_body_id UUID REFERENCES public.examination_bodies(id),
  educational_level_id UUID REFERENCES public.educational_levels(id),
  subject_id UUID REFERENCES public.subjects(id),
  target_date DATE,
  daily_study_minutes INT DEFAULT 60,
  plan_type TEXT NOT NULL DEFAULT 'ai_generated',
  plan_schedule JSONB DEFAULT '{}',
  milestones JSONB DEFAULT '[]',
  current_streak_days INT DEFAULT 0,
  longest_streak_days INT DEFAULT 0,
  total_study_minutes INT DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  ai_generated BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.study_plan_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_plan_id UUID NOT NULL REFERENCES public.study_plans(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  subject_id UUID REFERENCES public.subjects(id),
  topic_id UUID REFERENCES public.topics(id),
  content_item_id UUID REFERENCES public.content_items(id),
  duration_minutes INT DEFAULT 30,
  scheduled_date DATE NOT NULL,
  completed_at TIMESTAMPTZ,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  performance_score DECIMAL(5,2),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- UNIVERSITIES & ADMISSIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.universities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  university_type university_type_enum NOT NULL DEFAULT 'federal',
  city TEXT,
  state TEXT,
  country TEXT NOT NULL DEFAULT 'Nigeria',
  logo_url TEXT,
  website_url TEXT,
  description TEXT,
  year_founded INT,
  accreditation_status TEXT DEFAULT 'accredited',
  is_active BOOLEAN NOT NULL DEFAULT true,
  ranking_national INT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.university_faculties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id UUID NOT NULL REFERENCES public.universities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.university_departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  faculty_id UUID NOT NULL REFERENCES public.university_faculties(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  description TEXT,
  degree_type TEXT DEFAULT 'B.Sc.',
  duration_years INT DEFAULT 4,
  utme_subjects JSONB DEFAULT '[]',
  o_level_requirements JSONB DEFAULT '[]',
  jamb_subject_combination JSONB DEFAULT '[]',
  cut_off_mark INT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.post_utme_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id UUID NOT NULL REFERENCES public.universities(id) ON DELETE CASCADE,
  department_id UUID REFERENCES public.university_departments(id),
  faculty_id UUID REFERENCES public.university_faculties(id),
  name TEXT NOT NULL,
  description TEXT,
  year INT NOT NULL DEFAULT EXTRACT(YEAR FROM now()),
  duration_minutes INT DEFAULT 60,
  total_questions INT DEFAULT 50,
  total_marks INT DEFAULT 100,
  pass_mark DECIMAL(5,2) DEFAULT 50.00,
  instructions JSONB DEFAULT '{}',
  settings JSONB DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  source_type TEXT DEFAULT 'platform',
  has_licensing_rights BOOLEAN NOT NULL DEFAULT false,
  license_details JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.admission_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  university_id UUID REFERENCES public.universities(id),
  department_id UUID REFERENCES public.university_departments(id),
  checklist_items JSONB NOT NULL DEFAULT '[]',
  completed_items JSONB DEFAULT '[]',
  documents JSONB DEFAULT '[]',
  deadlines JSONB DEFAULT '[]',
  overall_readiness_score DECIMAL(5,2) DEFAULT 0.00,
  status TEXT DEFAULT 'in_progress',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.admission_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  university_id UUID NOT NULL REFERENCES public.universities(id),
  department_id UUID REFERENCES public.university_departments(id),
  course TEXT,
  admission_status admission_status_type NOT NULL DEFAULT 'not_applied',
  application_year INT NOT NULL DEFAULT EXTRACT(YEAR FROM now()),
  jamb_score INT,
  post_utme_score DECIMAL(5,2),
  o_level_results JSONB DEFAULT '[]',
  documents JSONB DEFAULT '[]',
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- AI COACH
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.ai_coach_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_type TEXT NOT NULL DEFAULT 'study_coach',
  context JSONB DEFAULT '{}',
  messages JSONB DEFAULT '[]',
  recommendations JSONB DEFAULT '[]',
  study_plan_id UUID REFERENCES public.study_plans(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ai_coach_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommendation_type TEXT NOT NULL,
  priority INT NOT NULL DEFAULT 5,
  title TEXT NOT NULL,
  description TEXT,
  action_type TEXT,
  action_data JSONB DEFAULT '{}',
  is_dismissed BOOLEAN NOT NULL DEFAULT false,
  dismissed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- EDUOS MODULAR ARCHITECTURE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.eduos_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  version TEXT NOT NULL DEFAULT '1.0.0',
  module_tier module_tier_type NOT NULL DEFAULT 'starter',
  module_status module_status_type NOT NULL DEFAULT 'active',
  icon_url TEXT,
  color_code TEXT,
  sort_order INT DEFAULT 0,
  features JSONB DEFAULT '[]',
  dependencies TEXT[] DEFAULT '{}',
  api_endpoints JSONB DEFAULT '[]',
  is_core BOOLEAN NOT NULL DEFAULT false,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  pricing_monthly DECIMAL(10,2) DEFAULT 0.00,
  pricing_yearly DECIMAL(10,2) DEFAULT 0.00,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed EduOS modules
INSERT INTO public.eduos_modules (code, name, description, module_tier, is_core, is_premium, sort_order, features, dependencies) VALUES
  ('auth', 'Authentication & Security', 'Core authentication, MFA, and session management', 'free', true, false, 1, '["login","register","mfa","session_management","password_recovery"]', '{}'),
  ('question_bank', 'Question Bank', 'Create, manage, and organize questions across all levels', 'starter', true, false, 2, '["question_crud","collections","import_export","search","filter"]', '{"auth"}'),
  ('ai_generator', 'AI Question Generator', 'AI-powered question generation with curriculum awareness', 'professional', true, true, 3, '["ai_generation","review","improve","document_upload","prompt_templates"]', '{"auth","question_bank"}'),
  ('cbt_engine', 'CBT Examination Engine', 'Computer-based testing with anti-cheat and real-time monitoring', 'professional', true, true, 4, '["exam_creation","templates","live_monitoring","auto_grading","receipts"]', '{"auth","question_bank"}'),
  ('school_management', 'School Management', 'Complete school administration system', 'professional', true, true, 5, '["student_management","teacher_management","timetable","attendance","homework","reports"]', '{"auth"}'),
  ('teacher_workspace', 'AI Teacher Workspace', 'Lesson plans, worksheets, rubrics with AI assistance', 'professional', true, true, 6, '["lesson_plans","worksheets","rubrics","presentations","schemes_of_work","oral_questions"]', '{"auth","question_bank","ai_generator"}'),
  ('student_hub', 'Student Learning Hub', 'AI tutor, flashcards, practice mode, study planner', 'starter', true, false, 7, '["ai_tutor","flashcards","practice_mode","progress_tracking","study_planner"]', '{"auth","question_bank"}'),
  ('parent_portal', 'Parent Portal', 'Monitor child progress, communicate with teachers', 'starter', true, false, 8, '["child_monitoring","messaging","calendar","reports","ai_assistant"]', '{"auth","student_hub"}'),
  ('communication', 'Communication Hub', 'Messaging, forums, announcements, calendar', 'starter', true, false, 9, '["chat","forums","announcements","calendar","ai_assistant","knowledge_base"]', '{"auth"}'),
  ('billing', 'Billing & Subscriptions', 'Flutterwave integration, invoices, credits, licenses', 'free', true, false, 10, '["subscriptions","payments","invoices","ai_credits","coupons","referrals"]', '{"auth"}'),
  ('marketplace', 'Resource Marketplace', 'Buy and sell educational resources', 'professional', false, true, 11, '["product_listings","cart","checkout","reviews","seller_dashboard","commissions"]', '{"auth","billing"}'),
  ('curriculum', 'Curriculum Management (CCMS)', 'Nigerian curriculum content management across all levels', 'professional', true, true, 12, '["educational_levels","subjects","topics","content_management","ai_curriculum_engine","answer_repository"]', '{"auth","question_bank"}'),
  ('exam_ecosystem', 'Examination Ecosystem', 'WAEC, NECO, JAMB, Post-UTME preparation', 'professional', false, true, 13, '["exam_bodies","mock_exams","readiness_scores","timed_practice"]', '{"auth","cbt_engine","curriculum"}'),
  ('admission_hub', 'Admission Success Hub', 'University search, admission checker, Post-UTME center', 'professional', false, true, 14, '["university_search","admission_checker","post_utme","checklists","eligibility"]', '{"auth","exam_ecosystem"}'),
  ('ai_coach', 'AI Exam Coach', 'Personalized study plans, weak topic detection, motivation', 'professional', false, true, 15, '["study_plans","weak_topic_detection","readiness_prediction","milestone_tracking","motivation"]', '{"auth","student_hub","exam_ecosystem"}'),
  ('analytics', 'Analytics Dashboard', 'User acquisition, conversion, retention, revenue analytics', 'enterprise', false, true, 16, '["user_analytics","revenue_analytics","feature_adoption","churn_analysis","marketing_performance"]', '{"auth","billing"}'),
  ('customer_success', 'Customer Success', 'Onboarding, help center, tutorials, feedback', 'free', true, false, 17, '["onboarding_wizard","help_center","tutorials","feedback","feature_requests"]', '{"auth"}'),
  ('marketing', 'Marketing & Growth', 'Landing pages, blog, referral, affiliate programs', 'enterprise', false, true, 18, '["landing_pages","blog","email_campaigns","referrals","affiliates","waitlist"]', '{"auth","billing"}'),
  ('offline', 'Offline & PWA', 'Offline-first architecture with smart sync', 'starter', true, false, 19, '["offline_mode","smart_sync","push_notifications","pwa_install"]', '{"auth"}'),
  ('enterprise', 'Enterprise & Security', 'Audit trails, MFA, API keys, rate limiting, monitoring', 'enterprise', false, true, 20, '["audit_trail","mfa","api_keys","rate_limiting","monitoring","deployment"]', '{"auth"}')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.eduos_module_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  module_id UUID NOT NULL REFERENCES public.eduos_modules(id) ON DELETE CASCADE,
  module_tier module_tier_type NOT NULL DEFAULT 'starter',
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  activated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  configuration JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, module_id)
);

CREATE TABLE IF NOT EXISTS public.eduos_module_apis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES public.eduos_modules(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL DEFAULT 'GET',
  description TEXT,
  auth_required BOOLEAN NOT NULL DEFAULT true,
  rate_limit INT DEFAULT 100,
  request_schema JSONB DEFAULT '{}',
  response_schema JSONB DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- CUSTOMER SUCCESS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.onboarding_flows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL,
  step_order INT NOT NULL,
  step_type onboarding_step_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  content JSONB DEFAULT '{}',
  action_required TEXT,
  is_skippable BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.onboarding_flows (role, step_order, step_type, title, description) VALUES
  ('schoolAdmin', 1, 'welcome', 'Welcome to ExamForge AI', 'Set up your school in minutes'),
  ('schoolAdmin', 2, 'school_setup', 'School Profile', 'Configure your school details and educational levels'),
  ('schoolAdmin', 3, 'subject_config', 'Subject Configuration', 'Select subjects for your school levels'),
  ('schoolAdmin', 4, 'feature_tour', 'Platform Tour', 'Explore key features of ExamForge AI'),
  ('schoolAdmin', 5, 'first_content', 'Create Your First Question', 'Add a question to your question bank'),
  ('schoolAdmin', 6, 'complete', 'Setup Complete', 'Your school is ready! Start exploring.'),
  ('teacher', 1, 'welcome', 'Welcome, Teacher!', 'Get started with ExamForge AI teaching tools'),
  ('teacher', 2, 'feature_tour', 'Teaching Tools Tour', 'Explore lesson planning, worksheets, and AI tools'),
  ('teacher', 3, 'first_content', 'Create Your First Question', 'Add a question to share with students'),
  ('teacher', 4, 'complete', 'Ready to Teach!', 'Your workspace is set up and ready'),
  ('student', 1, 'welcome', 'Welcome to ExamForge AI!', 'Your learning journey starts here'),
  ('student', 2, 'feature_tour', 'Learning Tools Tour', 'Explore practice mode, AI tutor, and flashcards'),
  ('student', 3, 'first_content', 'Try a Practice Question', 'Test your knowledge with a sample question'),
  ('student', 4, 'complete', 'Ready to Learn!', 'Start exploring and practicing'),
  ('parent', 1, 'welcome', 'Welcome, Parent!', 'Monitor your child''s educational progress'),
  ('parent', 2, 'feature_tour', 'Parent Portal Tour', 'Explore progress tracking and communication tools'),
  ('parent', 3, 'complete', 'All Set!', 'Start monitoring your child''s progress')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.onboarding_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  onboarding_flow_id UUID NOT NULL REFERENCES public.onboarding_flows(id) ON DELETE CASCADE,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  skipped_at TIMESTAMPTZ,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, onboarding_flow_id)
);

CREATE TABLE IF NOT EXISTS public.product_tours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  target_role TEXT,
  steps JSONB NOT NULL DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT true,
  trigger_event TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.help_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  content TEXT NOT NULL,
  content_rich JSONB DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  target_roles TEXT[] DEFAULT '{}',
  views_count INT NOT NULL DEFAULT 0,
  helpful_count INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT false,
  sort_order INT DEFAULT 0,
  author_id UUID REFERENCES auth.users(id),
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.video_tutorials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  duration_seconds INT,
  category TEXT,
  target_roles TEXT[] DEFAULT '{}',
  views_count INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT false,
  sort_order INT DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.feedback_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  feedback_type feedback_type_enum NOT NULL DEFAULT 'general_feedback',
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'open',
  attachments JSONB DEFAULT '[]',
  resolution TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.feature_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  status TEXT DEFAULT 'under_review',
  upvotes INT NOT NULL DEFAULT 0,
  is_under_consideration BOOLEAN NOT NULL DEFAULT false,
  implementation_status TEXT,
  response TEXT,
  responded_by UUID REFERENCES auth.users(id),
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.feature_request_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_request_id UUID NOT NULL REFERENCES public.feature_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(feature_request_id, user_id)
);

-- ============================================================================
-- MARKETING & GROWTH
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.landing_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  is_published BOOLEAN NOT NULL DEFAULT false,
  sections JSONB NOT NULL DEFAULT '[]',
  seo_title TEXT,
  seo_description TEXT,
  og_image_url TEXT,
  published_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.blog_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  excerpt TEXT,
  content TEXT NOT NULL,
  content_rich JSONB DEFAULT '{}',
  featured_image_url TEXT,
  category TEXT,
  tags TEXT[] DEFAULT '{}',
  author_id UUID REFERENCES auth.users(id),
  status content_status_type NOT NULL DEFAULT 'draft',
  views_count INT NOT NULL DEFAULT 0,
  likes_count INT NOT NULL DEFAULT 0,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  seo_title TEXT,
  seo_description TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.email_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  campaign_type campaign_type_enum NOT NULL DEFAULT 'email',
  subject TEXT,
  body TEXT,
  body_html TEXT,
  target_audience JSONB DEFAULT '{}',
  status TEXT DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  recipient_count INT DEFAULT 0,
  open_count INT DEFAULT 0,
  click_count INT DEFAULT 0,
  bounce_count INT DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.referral_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  reward_type TEXT NOT NULL DEFAULT 'credit',
  reward_value DECIMAL(10,2) DEFAULT 0.00,
  referral_code TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  max_referrals INT,
  total_referrals INT DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_program_id UUID NOT NULL REFERENCES public.referral_programs(id) ON DELETE CASCADE,
  referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referral_code TEXT NOT NULL,
  referred_email TEXT,
  referred_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending',
  reward_issued BOOLEAN NOT NULL DEFAULT false,
  reward_issued_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.affiliates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  affiliate_code TEXT NOT NULL UNIQUE,
  status affiliate_status_type NOT NULL DEFAULT 'pending',
  commission_rate DECIMAL(5,4) DEFAULT 0.1000,
  total_earnings DECIMAL(10,2) DEFAULT 0.00,
  pending_earnings DECIMAL(10,2) DEFAULT 0.00,
  paid_earnings DECIMAL(10,2) DEFAULT 0.00,
  referrals_count INT DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.affiliate_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  affiliate_id UUID NOT NULL REFERENCES public.affiliates(id) ON DELETE CASCADE,
  referred_id UUID REFERENCES auth.users(id),
  referred_email TEXT,
  subscription_id UUID,
  commission_earned DECIMAL(10,2) DEFAULT 0.00,
  status TEXT DEFAULT 'pending',
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- SALES TOOLKIT
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sales_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  prospect_name TEXT NOT NULL,
  prospect_email TEXT NOT NULL,
  prospect_phone TEXT,
  modules TEXT[] DEFAULT '{}',
  tier module_tier_type NOT NULL DEFAULT 'professional',
  student_count INT DEFAULT 100,
  pricing_monthly DECIMAL(10,2) DEFAULT 0.00,
  pricing_yearly DECIMAL(10,2) DEFAULT 0.00,
  discount_percentage DECIMAL(5,2) DEFAULT 0.00,
  total_annual DECIMAL(10,2) DEFAULT 0.00,
  proposal_status proposal_status_type NOT NULL DEFAULT 'draft',
  content JSONB DEFAULT '{}',
  viewed_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.demo_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_name TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  demo_type TEXT DEFAULT 'school',
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  configuration JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- ANALYTICS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  event_name TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  school_id UUID REFERENCES public.schools(id),
  session_id TEXT,
  properties JSONB DEFAULT '{}',
  device_info JSONB DEFAULT '{}',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.daily_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  school_id UUID REFERENCES public.schools(id),
  metric_name TEXT NOT NULL,
  metric_type TEXT NOT NULL DEFAULT 'counter',
  value DECIMAL NOT NULL DEFAULT 0,
  dimensions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(date, school_id, metric_name)
);

CREATE TABLE IF NOT EXISTS public.release_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_rich JSONB DEFAULT '{}',
  release_type TEXT DEFAULT 'patch',
  is_published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- INDEXES (80+)
-- ============================================================================
CREATE INDEX idx_exam_bodies_type ON public.examination_bodies(exam_body_type);
CREATE INDEX idx_exam_bodies_active ON public.examination_bodies(is_active);
CREATE INDEX idx_exam_products_body ON public.examination_products(exam_body_id);
CREATE INDEX idx_exam_products_level ON public.examination_products(educational_level_id);
CREATE INDEX idx_exam_products_subject ON public.examination_products(subject_id);
CREATE INDEX idx_exam_products_category ON public.examination_products(exam_category);
CREATE INDEX idx_exam_products_prep_type ON public.examination_products(preparation_type);
CREATE INDEX idx_exam_products_active ON public.examination_products(is_active);
CREATE INDEX idx_exam_products_premium ON public.examination_products(is_premium);
CREATE INDEX idx_mock_exams_school ON public.mock_exams(school_id);
CREATE INDEX idx_mock_exams_product ON public.mock_exams(examination_product_id);
CREATE INDEX idx_mock_exams_body ON public.mock_exams(exam_body_type);
CREATE INDEX idx_mock_exams_status ON public.mock_exams(status);
CREATE INDEX idx_mock_exams_created ON public.mock_exams(created_at DESC);
CREATE INDEX idx_mock_exam_questions_exam ON public.mock_exam_questions(mock_exam_id);
CREATE INDEX idx_mock_exam_questions_content ON public.mock_exam_questions(content_item_id);
CREATE INDEX idx_mock_exam_attempts_exam ON public.mock_exam_attempts(mock_exam_id);
CREATE INDEX idx_mock_exam_attempts_user ON public.mock_exam_attempts(user_id);
CREATE INDEX idx_mock_exam_attempts_status ON public.mock_exam_attempts(status);
CREATE INDEX idx_readiness_user ON public.readiness_assessments(user_id);
CREATE INDEX idx_readiness_exam_body ON public.readiness_assessments(exam_body_id);
CREATE INDEX idx_readiness_subject ON public.readiness_assessments(subject_id);
CREATE INDEX idx_readiness_level ON public.readiness_assessments(readiness_level);
CREATE INDEX idx_readiness_assessed ON public.readiness_assessments(assessed_at DESC);
CREATE INDEX idx_study_plans_user ON public.study_plans(user_id);
CREATE INDEX idx_study_plans_active ON public.study_plans(is_active) WHERE is_active = true;
CREATE INDEX idx_study_plans_exam ON public.study_plans(exam_body_id);
CREATE INDEX idx_study_plan_activities_plan ON public.study_plan_activities(study_plan_id);
CREATE INDEX idx_study_plan_activities_date ON public.study_plan_activities(scheduled_date);
CREATE INDEX idx_study_plan_activities_completed ON public.study_plan_activities(is_completed);
CREATE INDEX idx_universities_type ON public.universities(university_type);
CREATE INDEX idx_universities_active ON public.universities(is_active);
CREATE INDEX idx_universities_state ON public.universities(state);
CREATE INDEX idx_universities_search ON public.universities USING gin(to_tsvector('english', name || ' ' || COALESCE(city, '') || ' ' || COALESCE(state, '')));
CREATE INDEX idx_uni_faculties_uni ON public.university_faculties(university_id);
CREATE INDEX idx_uni_departments_faculty ON public.university_departments(faculty_id);
CREATE INDEX idx_uni_departments_active ON public.university_departments(is_active);
CREATE INDEX idx_post_utme_uni ON public.post_utme_products(university_id);
CREATE INDEX idx_post_utme_dept ON public.post_utme_products(department_id);
CREATE INDEX idx_post_utme_year ON public.post_utme_products(year);
CREATE INDEX idx_post_utme_active ON public.post_utme_products(is_active);
CREATE INDEX idx_admission_checklists_user ON public.admission_checklists(user_id);
CREATE INDEX idx_admission_applications_user ON public.admission_applications(user_id);
CREATE INDEX idx_admission_applications_uni ON public.admission_applications(university_id);
CREATE INDEX idx_admission_applications_status ON public.admission_applications(admission_status);
CREATE INDEX idx_ai_coach_sessions_user ON public.ai_coach_sessions(user_id);
CREATE INDEX idx_ai_coach_rec_user ON public.ai_coach_recommendations(user_id);
CREATE INDEX idx_ai_coach_rec_type ON public.ai_coach_recommendations(recommendation_type);
CREATE INDEX idx_ai_coach_rec_dismissed ON public.ai_coach_recommendations(is_dismissed) WHERE is_dismissed = false;
CREATE INDEX idx_eduos_modules_code ON public.eduos_modules(code);
CREATE INDEX idx_eduos_modules_tier ON public.eduos_modules(module_tier);
CREATE INDEX idx_eduos_modules_status ON public.eduos_modules(module_status);
CREATE INDEX idx_eduos_module_subs_school ON public.eduos_module_subscriptions(school_id);
CREATE INDEX idx_eduos_module_subs_module ON public.eduos_module_subscriptions(module_id);
CREATE INDEX idx_eduos_module_subs_enabled ON public.eduos_module_subscriptions(school_id, is_enabled);
CREATE INDEX idx_eduos_module_apis_module ON public.eduos_module_apis(module_id);
CREATE INDEX idx_onboarding_flows_role ON public.onboarding_flows(role);
CREATE INDEX idx_onboarding_progress_user ON public.onboarding_progress(user_id);
CREATE INDEX idx_onboarding_progress_completed ON public.onboarding_progress(user_id, is_completed);
CREATE INDEX idx_help_articles_category ON public.help_articles(category);
CREATE INDEX idx_help_articles_slug ON public.help_articles(slug);
CREATE INDEX idx_help_articles_published ON public.help_articles(is_published) WHERE is_published = true;
CREATE INDEX idx_help_articles_search ON public.help_articles USING gin(to_tsvector('english', title || ' ' || content));
CREATE INDEX idx_video_tutorials_category ON public.video_tutorials(category);
CREATE INDEX idx_video_tutorials_published ON public.video_tutorials(is_published);
CREATE INDEX idx_feedback_user ON public.feedback_submissions(user_id);
CREATE INDEX idx_feedback_type ON public.feedback_submissions(feedback_type);
CREATE INDEX idx_feedback_status ON public.feedback_submissions(status);
CREATE INDEX idx_feature_requests_user ON public.feature_requests(user_id);
CREATE INDEX idx_feature_requests_status ON public.feature_requests(status);
CREATE INDEX idx_feature_requests_upvotes ON public.feature_requests(upvotes DESC);
CREATE INDEX idx_feature_request_votes_request ON public.feature_request_votes(feature_request_id);
CREATE INDEX idx_feature_request_votes_user ON public.feature_request_votes(user_id);
CREATE INDEX idx_landing_pages_slug ON public.landing_pages(slug);
CREATE INDEX idx_landing_pages_published ON public.landing_pages(is_published);
CREATE INDEX idx_blog_posts_slug ON public.blog_posts(slug);
CREATE INDEX idx_blog_posts_status ON public.blog_posts(status);
CREATE INDEX idx_blog_posts_category ON public.blog_posts(category);
CREATE INDEX idx_blog_posts_published ON public.blog_posts(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_blog_posts_search ON public.blog_posts USING gin(to_tsvector('english', title || ' ' || excerpt || ' ' || content));
CREATE INDEX idx_email_campaigns_status ON public.email_campaigns(status);
CREATE INDEX idx_email_campaigns_type ON public.email_campaigns(campaign_type);
CREATE INDEX idx_referral_programs_code ON public.referral_programs(referral_code);
CREATE INDEX idx_referral_programs_school ON public.referral_programs(school_id);
CREATE INDEX idx_referrals_program ON public.referrals(referral_program_id);
CREATE INDEX idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX idx_affiliates_code ON public.affiliates(affiliate_code);
CREATE INDEX idx_affiliates_user ON public.affiliates(user_id);
CREATE INDEX idx_affiliates_status ON public.affiliates(status);
CREATE INDEX idx_affiliate_referrals_affiliate ON public.affiliate_referrals(affiliate_id);
CREATE INDEX idx_sales_proposals_school ON public.sales_proposals(school_id);
CREATE INDEX idx_sales_proposals_status ON public.sales_proposals(proposal_status);
CREATE INDEX idx_sales_proposals_created ON public.sales_proposals(created_at DESC);
CREATE INDEX idx_demo_accounts_active ON public.demo_accounts(is_active);
CREATE INDEX idx_demo_accounts_expires ON public.demo_accounts(expires_at);
CREATE INDEX idx_analytics_events_type ON public.analytics_events(event_type);
CREATE INDEX idx_analytics_events_user ON public.analytics_events(user_id);
CREATE INDEX idx_analytics_events_school ON public.analytics_events(school_id);
CREATE INDEX idx_analytics_events_timestamp ON public.analytics_events(timestamp DESC);
CREATE INDEX idx_analytics_events_composite ON public.analytics_events(event_type, timestamp DESC);
CREATE INDEX idx_daily_analytics_date ON public.daily_analytics(date DESC);
CREATE INDEX idx_daily_analytics_metric ON public.daily_analytics(metric_name);
CREATE INDEX idx_daily_analytics_school ON public.daily_analytics(school_id);
CREATE INDEX idx_daily_analytics_composite ON public.daily_analytics(date, metric_name, school_id);
CREATE INDEX idx_release_notes_version ON public.release_notes(version);
CREATE INDEX idx_release_notes_published ON public.release_notes(is_published) WHERE is_published = true;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.examination_bodies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.readiness_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_plan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_utme_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_coach_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_coach_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_module_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_module_apis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.help_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_tutorials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_request_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.landing_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliate_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.release_notes ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Exam bodies readable by all" ON public.examination_bodies FOR SELECT TO authenticated USING (true);
CREATE POLICY "Exam products readable by all" ON public.examination_products FOR SELECT TO authenticated USING (true);
CREATE POLICY "Universities readable by all" ON public.universities FOR SELECT TO authenticated USING (true);
CREATE POLICY "Uni faculties readable by all" ON public.university_faculties FOR SELECT TO authenticated USING (true);
CREATE POLICY "Uni departments readable by all" ON public.university_departments FOR SELECT TO authenticated USING (true);
CREATE POLICY "EduOS modules readable by all" ON public.eduos_modules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Onboarding flows readable by all" ON public.onboarding_flows FOR SELECT TO authenticated USING (true);
CREATE POLICY "Help articles readable by all" ON public.help_articles FOR SELECT TO authenticated USING (is_published = true);
CREATE POLICY "Video tutorials readable by all" ON public.video_tutorials FOR SELECT TO authenticated USING (is_published = true);
CREATE POLICY "Blog posts readable by all" ON public.blog_posts FOR SELECT TO authenticated USING (status = 'published');
CREATE POLICY "Landing pages readable by all" ON public.landing_pages FOR SELECT TO authenticated USING (is_published = true);
CREATE POLICY "Release notes readable by all" ON public.release_notes FOR SELECT TO authenticated USING (is_published = true);
CREATE POLICY "Feature requests readable by all" ON public.feature_requests FOR SELECT TO authenticated USING (true);

-- User-scoped access
CREATE POLICY "Readiness assessments user scoped" ON public.readiness_assessments FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Study plans user scoped" ON public.study_plans FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Study plan activities via plan" ON public.study_plan_activities FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.study_plans WHERE study_plans.id = study_plan_activities.study_plan_id AND study_plans.user_id = auth.uid()));
CREATE POLICY "Admission checklists user scoped" ON public.admission_checklists FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Admission applications user scoped" ON public.admission_applications FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "AI coach sessions user scoped" ON public.ai_coach_sessions FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "AI coach recommendations user scoped" ON public.ai_coach_recommendations FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Onboarding progress user scoped" ON public.onboarding_progress FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Feedback submissions user scoped" ON public.feedback_submissions FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Feature request votes user scoped" ON public.feature_request_votes FOR ALL TO authenticated USING (user_id = auth.uid());

-- School-scoped
CREATE POLICY "Mock exams school scoped" ON public.mock_exams FOR SELECT TO authenticated USING (school_id IS NULL OR school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid()) OR EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "Mock exams managed by teachers" ON public.mock_exams FOR INSERT TO authenticated WITH CHECK (auth.uid() IN (SELECT id FROM auth.users WHERE raw_user_meta_data->>'role' IN ('teacher','schoolAdmin','superAdmin')));
CREATE POLICY "Post UTME readable by all" ON public.post_utme_products FOR SELECT TO authenticated USING (true);
CREATE POLICY "Module subscriptions school scoped" ON public.eduos_module_subscriptions FOR SELECT TO authenticated USING (school_id::text = (SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid()) OR EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "Module subscriptions managed by admins" ON public.eduos_module_subscriptions FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('schoolAdmin','superAdmin')));

-- Super admin only
CREATE POLICY "Email campaigns managed by admins" ON public.email_campaigns FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('superAdmin','schoolAdmin')));
CREATE POLICY "Sales proposals managed by admins" ON public.sales_proposals FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('superAdmin','schoolAdmin')));
CREATE POLICY "Demo accounts managed by admins" ON public.demo_accounts FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "Daily analytics admin only" ON public.daily_analytics FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('superAdmin','schoolAdmin')));
CREATE POLICY "Analytics events insert by system" ON public.analytics_events FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Landing pages managed by admins" ON public.landing_pages FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "Blog posts managed by admins" ON public.blog_posts FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' IN ('superAdmin','schoolAdmin')));
CREATE POLICY "EduOS modules managed by super admin" ON public.eduos_modules FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "EduOS APIs managed by super admin" ON public.eduos_module_apis FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));

-- Affiliates user-scoped
CREATE POLICY "Affiliates user scoped" ON public.affiliates FOR SELECT TO authenticated USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));
CREATE POLICY "Affiliates managed by owner" ON public.affiliates FOR ALL TO authenticated USING (user_id = auth.uid());

-- Referrals
CREATE POLICY "Referrals readable by referrer" ON public.referrals FOR SELECT TO authenticated USING (referrer_id = auth.uid() OR EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'superAdmin'));

-- ============================================================================
-- FUNCTIONS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_exam_readiness(p_user_id UUID, p_exam_body_id UUID DEFAULT NULL, p_subject_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'user_id', p_user_id,
    'assessments', (SELECT COALESCE(jsonb_agg(row_to_json(ra.*)), '[]'::jsonb)
      FROM public.readiness_assessments ra
      WHERE ra.user_id = p_user_id
        AND (p_exam_body_id IS NULL OR ra.exam_body_id = p_exam_body_id)
        AND (p_subject_id IS NULL OR ra.subject_id = p_subject_id)
      ORDER BY ra.assessed_at DESC LIMIT 10),
    'overall_readiness', (SELECT ROUND(AVG(readiness_score), 2)
      FROM public.readiness_assessments
      WHERE user_id = p_user_id
        AND (p_exam_body_id IS NULL OR exam_body_id = p_exam_body_id)),
    'weak_areas', (SELECT COALESCE(jsonb_agg(DISTINCT jsonb_array_elements(weak_topics)), '[]'::jsonb)
      FROM public.readiness_assessments
      WHERE user_id = p_user_id AND (p_exam_body_id IS NULL OR exam_body_id = p_exam_body_id)),
    'study_plans', (SELECT COUNT(*) FROM public.study_plans WHERE user_id = p_user_id AND is_active = true),
    'total_study_minutes', (SELECT COALESCE(SUM(total_study_minutes), 0) FROM public.study_plans WHERE user_id = p_user_id)
  ) INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.check_admission_eligibility(
  p_user_id UUID,
  p_university_id UUID,
  p_department_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_dept RECORD;
  v_result JSONB;
BEGIN
  SELECT * INTO v_dept FROM public.university_departments WHERE id = p_department_id AND is_active = true;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('eligible', false, 'reason', 'Department not found');
  END IF;

  SELECT jsonb_build_object(
    'eligible', true,
    'university_id', p_university_id,
    'department_id', p_department_id,
    'department_name', v_dept.name,
    'degree_type', v_dept.degree_type,
    'duration_years', v_dept.duration_years,
    'cut_off_mark', v_dept.cut_off_mark,
    'utme_subjects', v_dept.utme_subjects,
    'o_level_requirements', v_dept.o_level_requirements,
    'jamb_subject_combination', v_dept.jamb_subject_combination,
    'checks', jsonb_build_object(
      'jamb_subjects_match', true,
      'o_level_requirements_met', true,
      'cut_off_mark_info', v_dept.cut_off_mark
    )
  ) INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.track_analytics_event(
  p_event_type TEXT,
  p_event_name TEXT,
  p_user_id UUID DEFAULT NULL,
  p_school_id UUID DEFAULT NULL,
  p_session_id TEXT DEFAULT NULL,
  p_properties JSONB DEFAULT '{}',
  p_device_info JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.analytics_events (event_type, event_name, user_id, school_id, session_id, properties, device_info)
  VALUES (p_event_type, p_event_name, p_user_id, p_school_id, p_session_id, p_properties, p_device_info)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_analytics_summary(
  p_school_id UUID DEFAULT NULL,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(DISTINCT user_id) FROM public.analytics_events WHERE (p_school_id IS NULL OR school_id = p_school_id) AND (p_start_date IS NULL OR timestamp >= p_start_date) AND (p_end_date IS NULL OR timestamp <= p_end_date)),
    'total_events', (SELECT COUNT(*) FROM public.analytics_events WHERE (p_school_id IS NULL OR school_id = p_school_id) AND (p_start_date IS NULL OR timestamp >= p_start_date) AND (p_end_date IS NULL OR timestamp <= p_end_date)),
    'event_types', (SELECT jsonb_object_agg(event_type, cnt) FROM (SELECT event_type, COUNT(*) as cnt FROM public.analytics_events WHERE (p_school_id IS NULL OR school_id = p_school_id) AND (p_start_date IS NULL OR timestamp >= p_start_date) AND (p_end_date IS NULL OR timestamp <= p_end_date) GROUP BY event_type) t),
    'daily_active_users', (SELECT COUNT(DISTINCT user_id) FROM public.analytics_events WHERE timestamp >= CURRENT_DATE AND (p_school_id IS NULL OR school_id = p_school_id)),
    'monthly_active_users', (SELECT COUNT(DISTINCT user_id) FROM public.analytics_events WHERE timestamp >= date_trunc('month', CURRENT_DATE) AND (p_school_id IS NULL OR school_id = p_school_id))
  ) INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_module_subscriptions(p_school_id UUID)
RETURNS TABLE (
  module_code TEXT, module_name TEXT, module_tier module_tier_type,
  module_status module_status_type, is_enabled BOOLEAN, is_core BOOLEAN,
  is_premium BOOLEAN, features JSONB, pricing_monthly DECIMAL, pricing_yearly DECIMAL
) AS $$
SELECT m.code, m.name, m.module_tier, m.module_status,
       COALESCE(ms.is_enabled, m.is_core) AS is_enabled,
       m.is_core, m.is_premium, m.features,
       m.pricing_monthly, m.pricing_yearly
FROM public.eduos_modules m
LEFT JOIN public.eduos_module_subscriptions ms ON ms.module_id = m.id AND ms.school_id = p_school_id
WHERE m.module_status = 'active'
ORDER BY m.sort_order;
$$ LANGUAGE sql STABLE;

-- Updated_at triggers
CREATE TRIGGER update_examination_bodies_updated_at BEFORE UPDATE ON public.examination_bodies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_examination_products_updated_at BEFORE UPDATE ON public.examination_products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_mock_exams_updated_at BEFORE UPDATE ON public.mock_exams FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_study_plans_updated_at BEFORE UPDATE ON public.study_plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_universities_updated_at BEFORE UPDATE ON public.universities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_post_utme_products_updated_at BEFORE UPDATE ON public.post_utme_products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_admission_checklists_updated_at BEFORE UPDATE ON public.admission_checklists FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_admission_applications_updated_at BEFORE UPDATE ON public.admission_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_ai_coach_sessions_updated_at BEFORE UPDATE ON public.ai_coach_sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_eduos_modules_updated_at BEFORE UPDATE ON public.eduos_modules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_eduos_module_subscriptions_updated_at BEFORE UPDATE ON public.eduos_module_subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_help_articles_updated_at BEFORE UPDATE ON public.help_articles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_feedback_submissions_updated_at BEFORE UPDATE ON public.feedback_submissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_feature_requests_updated_at BEFORE UPDATE ON public.feature_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_landing_pages_updated_at BEFORE UPDATE ON public.landing_pages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON public.blog_posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_email_campaigns_updated_at BEFORE UPDATE ON public.email_campaigns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_referral_programs_updated_at BEFORE UPDATE ON public.referral_programs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_affiliates_updated_at BEFORE UPDATE ON public.affiliates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_sales_proposals_updated_at BEFORE UPDATE ON public.sales_proposals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- GRANTS & COMMENTS
-- ============================================================================
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

COMMENT ON TABLE public.examination_bodies IS 'Nigerian examination bodies: WAEC, NECO, NABTEB, JAMB, Post-UTME, BECE, Common Entrance';
COMMENT ON TABLE public.examination_products IS 'Exam preparation products by body, level, and subject';
COMMENT ON TABLE public.mock_exams IS 'Timed mock examinations with scoring and grading';
COMMENT ON TABLE public.mock_exam_attempts IS 'Student attempts at mock exams with scores';
COMMENT ON TABLE public.readiness_assessments IS 'Readiness scores for exam preparation tracking';
COMMENT ON TABLE public.study_plans IS 'AI-generated and custom study plans for students';
COMMENT ON TABLE public.study_plan_activities IS 'Individual activities within study plans';
COMMENT ON TABLE public.universities IS 'Nigerian universities with faculties and departments';
COMMENT ON TABLE public.university_faculties IS 'University faculties (Arts, Science, Engineering, etc.)';
COMMENT ON TABLE public.university_departments IS 'University departments with admission requirements';
COMMENT ON TABLE public.post_utme_products IS 'Post-UTME practice tests by university and department';
COMMENT ON TABLE public.admission_checklists IS 'Student admission preparation checklists';
COMMENT ON TABLE public.admission_applications IS 'Student admission applications tracking';
COMMENT ON TABLE public.ai_coach_sessions IS 'AI study coach conversation sessions';
COMMENT ON TABLE public.ai_coach_recommendations IS 'Personalized AI recommendations for students';
COMMENT ON TABLE public.eduos_modules IS 'Education OS modular architecture — each capability is an independent module';
COMMENT ON TABLE public.eduos_module_subscriptions IS 'Per-school module activation and configuration';
COMMENT ON TABLE public.eduos_module_apis IS 'API endpoints exposed by each EduOS module';
COMMENT ON TABLE public.onboarding_flows IS 'Role-specific onboarding steps for new users';
COMMENT ON TABLE public.help_articles IS 'Help center knowledge base articles';
COMMENT ON TABLE public.video_tutorials IS 'Video tutorials for platform features';
COMMENT ON TABLE public.feedback_submissions IS 'User feedback, bug reports, and feature requests';
COMMENT ON TABLE public.feature_requests IS 'Community feature requests with voting';
COMMENT ON TABLE public.landing_pages IS 'Marketing landing pages with SEO';
COMMENT ON TABLE public.blog_posts IS 'Blog posts for content marketing';
COMMENT ON TABLE public.email_campaigns IS 'Email and push notification campaigns';
COMMENT ON TABLE public.referral_programs IS 'Referral programs with reward tracking';
COMMENT ON TABLE public.affiliates IS 'Affiliate program with commission tracking';
COMMENT ON TABLE public.sales_proposals IS 'Sales proposals for school subscriptions';
COMMENT ON TABLE public.demo_accounts IS 'Demo school accounts for sales demonstrations';
COMMENT ON TABLE public.analytics_events IS 'Raw analytics events for platform metrics';
COMMENT ON TABLE public.daily_analytics IS 'Aggregated daily analytics metrics';
COMMENT ON TABLE public.release_notes IS 'Platform release notes and changelog';
