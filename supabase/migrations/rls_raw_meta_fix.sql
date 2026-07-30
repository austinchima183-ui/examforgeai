-- ============================================================================
-- ExamForge AI — RLS Raw Meta Data Fix Migration
-- ============================================================================
-- PURPOSE: Replace ALL insecure raw_user_meta_data references in RLS policies
-- with server-authoritative get_user_role() and get_user_school_id().
--
-- PROBLEM: 94 RLS policies across 4 migration files use
--   raw_user_meta_data->>'role' which is CLIENT-SPOOFABLE.
--   A user can set their own metadata during signup, claiming any role.
--
-- FIX: Replace with get_user_role() which reads from public.users table
--   (server-authoritative, SECURITY DEFINER).
--
-- ALSO: Enable RLS on 80 tables that have policies but RLS is not enforced.
-- ============================================================================

-- ─── Step 1: Ensure get_user_role() and get_user_school_id() exist ──────────
-- (Idempotent — safe to re-run)

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_user_school_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT school_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

-- ─── Step 2: ENABLE ROW LEVEL SECURITY on all tables missing it ─────────────

-- From ccms_enterprise_schema.sql (37 tables)
ALTER TABLE public.curricula ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_level_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.educational_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtopics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_objectives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_collection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answer_repository ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_curriculum_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encryption_key_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mfa_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_trail ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_check_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.error_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployment_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.database_migrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_level_configurations ENABLE ROW LEVEL SECURITY;

-- From super_admin_schema.sql (15 tables)
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intelligence_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.infrastructure_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.impersonation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.background_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- From final_production_schema.sql (39 tables)
ALTER TABLE public.mock_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_module_apis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eduos_module_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.landing_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.affiliate_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_coach_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_coach_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_bodies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.examination_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_request_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_utme_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.readiness_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_plan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_suites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.university_faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_statistics ENABLE ROW LEVEL SECURITY;

-- From marketplace_schema.sql (2 tables with insecure policies)
-- (marketplace_products and marketplace_categories already have RLS enabled,
--  but their policies need fixing — see Step 3)

-- ─── Step 3: Replace insecure raw_user_meta_data policies ──────────────────
-- For each table that has policies using raw_user_meta_data->>'role',
-- we DROP the old policy and CREATE a new one using get_user_role().

-- ─── CCMS Enterprise Schema Tables ────────────────────────────────────────

-- curricula
DROP POLICY IF EXISTS curricula_select ON public.curricula;
DROP POLICY IF EXISTS curricula_insert ON public.curricula;
DROP POLICY IF EXISTS curricula_update ON public.curricula;
DROP POLICY IF EXISTS curricula_delete ON public.curricula;
CREATE POLICY curricula_select ON public.curricula FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
  OR (get_user_role() = 'teacher' AND school_id = get_user_school_id())
);
CREATE POLICY curricula_insert ON public.curricula FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY curricula_update ON public.curricula FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
  AND (get_user_role() = 'school_admin' AND school_id = get_user_school_id())
    OR get_user_role() = 'super_admin'
);
CREATE POLICY curricula_delete ON public.curricula FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- curriculum_versions
DROP POLICY IF EXISTS curriculum_versions_select ON public.curriculum_versions;
DROP POLICY IF EXISTS curriculum_versions_insert ON public.curriculum_versions;
DROP POLICY IF EXISTS curriculum_versions_update ON public.curriculum_versions;
DROP POLICY IF EXISTS curriculum_versions_delete ON public.curriculum_versions;
CREATE POLICY curriculum_versions_select ON public.curriculum_versions FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY curriculum_versions_insert ON public.curriculum_versions FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY curriculum_versions_update ON public.curriculum_versions FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY curriculum_versions_delete ON public.curriculum_versions FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- educational_levels
DROP POLICY IF EXISTS educational_levels_select ON public.educational_levels;
DROP POLICY IF EXISTS educational_levels_insert ON public.educational_levels;
DROP POLICY IF EXISTS educational_levels_update ON public.educational_levels;
DROP POLICY IF EXISTS educational_levels_delete ON public.educational_levels;
CREATE POLICY educational_levels_select ON public.educational_levels FOR SELECT USING (true);
CREATE POLICY educational_levels_insert ON public.educational_levels FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY educational_levels_update ON public.educational_levels FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY educational_levels_delete ON public.educational_levels FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- subjects
DROP POLICY IF EXISTS subjects_select ON public.subjects;
DROP POLICY IF EXISTS subjects_insert ON public.subjects;
DROP POLICY IF EXISTS subjects_update ON public.subjects;
DROP POLICY IF EXISTS subjects_delete ON public.subjects;
CREATE POLICY subjects_select ON public.subjects FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher', 'student')
);
CREATE POLICY subjects_insert ON public.subjects FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY subjects_update ON public.subjects FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY subjects_delete ON public.subjects FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- topics
DROP POLICY IF EXISTS topics_select ON public.topics;
DROP POLICY IF EXISTS topics_insert ON public.topics;
DROP POLICY IF EXISTS topics_update ON public.topics;
DROP POLICY IF EXISTS topics_delete ON public.topics;
CREATE POLICY topics_select ON public.topics FOR SELECT USING (true);
CREATE POLICY topics_insert ON public.topics FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY topics_update ON public.topics FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY topics_delete ON public.topics FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- subtopics
DROP POLICY IF EXISTS subtopics_select ON public.subtopics;
DROP POLICY IF EXISTS subtopics_insert ON public.subtopics;
DROP POLICY IF EXISTS subtopics_update ON public.subtopics;
DROP POLICY IF EXISTS subtopics_delete ON public.subtopics;
CREATE POLICY subtopics_select ON public.subtopics FOR SELECT USING (true);
CREATE POLICY subtopics_insert ON public.subtopics FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY subtopics_update ON public.subtopics FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY subtopics_delete ON public.subtopics FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- learning_objectives
DROP POLICY IF EXISTS learning_objectives_select ON public.learning_objectives;
DROP POLICY IF EXISTS learning_objectives_insert ON public.learning_objectives;
DROP POLICY IF EXISTS learning_objectives_update ON public.learning_objectives;
DROP POLICY IF EXISTS learning_objectives_delete ON public.learning_objectives;
CREATE POLICY learning_objectives_select ON public.learning_objectives FOR SELECT USING (true);
CREATE POLICY learning_objectives_insert ON public.learning_objectives FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY learning_objectives_update ON public.learning_objectives FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY learning_objectives_delete ON public.learning_objectives FOR DELETE USING (
  get_user_role() = 'super_admin'
);

-- content_items
DROP POLICY IF EXISTS content_items_select ON public.content_items;
DROP POLICY IF EXISTS content_items_insert ON public.content_items;
DROP POLICY IF EXISTS content_items_update ON public.content_items;
DROP POLICY IF EXISTS content_items_delete ON public.content_items;
CREATE POLICY content_items_select ON public.content_items FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
  OR (get_user_role() = 'student' AND status = 'published')
);
CREATE POLICY content_items_insert ON public.content_items FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_items_update ON public.content_items FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_items_delete ON public.content_items FOR DELETE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- content_versions
DROP POLICY IF EXISTS content_versions_select ON public.content_versions;
DROP POLICY IF EXISTS content_versions_insert ON public.content_versions;
CREATE POLICY content_versions_select ON public.content_versions FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_versions_insert ON public.content_versions FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);

-- content_imports
DROP POLICY IF EXISTS content_imports_select ON public.content_imports;
DROP POLICY IF EXISTS content_imports_insert ON public.content_imports;
CREATE POLICY content_imports_select ON public.content_imports FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY content_imports_insert ON public.content_imports FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- content_reviews
DROP POLICY IF EXISTS content_reviews_select ON public.content_reviews;
DROP POLICY IF EXISTS content_reviews_insert ON public.content_reviews;
DROP POLICY IF EXISTS content_reviews_update ON public.content_reviews;
CREATE POLICY content_reviews_select ON public.content_reviews FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_reviews_insert ON public.content_reviews FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_reviews_update ON public.content_reviews FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- content_collections
DROP POLICY IF EXISTS content_collections_select ON public.content_collections;
DROP POLICY IF EXISTS content_collections_insert ON public.content_collections;
DROP POLICY IF EXISTS content_collections_update ON public.content_collections;
DROP POLICY IF EXISTS content_collections_delete ON public.content_collections;
CREATE POLICY content_collections_select ON public.content_collections FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_collections_insert ON public.content_collections FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_collections_update ON public.content_collections FOR UPDATE USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_collections_delete ON public.content_collections FOR DELETE USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- content_collection_items
DROP POLICY IF EXISTS content_collection_items_select ON public.content_collection_items;
DROP POLICY IF EXISTS content_collection_items_insert ON public.content_collection_items;
CREATE POLICY content_collection_items_select ON public.content_collection_items FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY content_collection_items_insert ON public.content_collection_items FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);

-- answer_repository
DROP POLICY IF EXISTS answer_repository_select ON public.answer_repository;
DROP POLICY IF EXISTS answer_repository_insert ON public.answer_repository;
CREATE POLICY answer_repository_select ON public.answer_repository FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY answer_repository_insert ON public.answer_repository FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);

-- ai_curriculum_configs
DROP POLICY IF EXISTS ai_curriculum_configs_select ON public.ai_curriculum_configs;
DROP POLICY IF EXISTS ai_curriculum_configs_insert ON public.ai_curriculum_configs;
CREATE POLICY ai_curriculum_configs_select ON public.ai_curriculum_configs FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY ai_curriculum_configs_insert ON public.ai_curriculum_configs FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- ai_generation_rules
DROP POLICY IF EXISTS ai_generation_rules_select ON public.ai_generation_rules;
DROP POLICY IF EXISTS ai_generation_rules_insert ON public.ai_generation_rules;
CREATE POLICY ai_generation_rules_select ON public.ai_generation_rules FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);
CREATE POLICY ai_generation_rules_insert ON public.ai_generation_rules FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- ─── CCMS Security/Monitoring Tables ──────────────────────────────────────

-- encryption_key_metadata — super_admin only
DROP POLICY IF EXISTS encryption_key_metadata_select ON public.encryption_key_metadata;
CREATE POLICY encryption_key_metadata_select ON public.encryption_key_metadata FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- mfa_configurations — owner or admin
DROP POLICY IF EXISTS mfa_configurations_select ON public.mfa_configurations;
DROP POLICY IF EXISTS mfa_configurations_insert ON public.mfa_configurations;
CREATE POLICY mfa_configurations_select ON public.mfa_configurations FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin') OR user_id = auth.uid()
);
CREATE POLICY mfa_configurations_insert ON public.mfa_configurations FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- security_events — admin only
DROP POLICY IF EXISTS security_events_select ON public.security_events;
DROP POLICY IF EXISTS security_events_insert ON public.security_events;
CREATE POLICY security_events_select ON public.security_events FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY security_events_insert ON public.security_events FOR INSERT WITH CHECK (
  get_user_role() = 'super_admin'
);

-- rate_limit_configs — super_admin only
DROP POLICY IF EXISTS rate_limit_configs_select ON public.rate_limit_configs;
CREATE POLICY rate_limit_configs_select ON public.rate_limit_configs FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- rate_limit_counters — service role only (not user-accessible)
DROP POLICY IF EXISTS rate_limit_counters_select ON public.rate_limit_counters;
CREATE POLICY rate_limit_counters_select ON public.rate_limit_counters FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- audit_trail — admin only
DROP POLICY IF EXISTS audit_trail_select ON public.audit_trail;
DROP POLICY IF EXISTS audit_trail_insert ON public.audit_trail;
CREATE POLICY audit_trail_select ON public.audit_trail FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY audit_trail_insert ON public.audit_trail FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- backup_records — super_admin only
DROP POLICY IF EXISTS backup_records_select ON public.backup_records;
CREATE POLICY backup_records_select ON public.backup_records FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- system_metrics — admin only
DROP POLICY IF EXISTS system_metrics_select ON public.system_metrics;
CREATE POLICY system_metrics_select ON public.system_metrics FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- performance_logs — admin only
DROP POLICY IF EXISTS performance_logs_select ON public.performance_logs;
CREATE POLICY performance_logs_select ON public.performance_logs FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- health_check_history — admin only
DROP POLICY IF EXISTS health_check_history_select ON public.health_check_history;
CREATE POLICY health_check_history_select ON public.health_check_history FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- maintenance_windows — admin only
DROP POLICY IF EXISTS maintenance_windows_select ON public.maintenance_windows;
DROP POLICY IF EXISTS maintenance_windows_insert ON public.maintenance_windows;
CREATE POLICY maintenance_windows_select ON public.maintenance_windows FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY maintenance_windows_insert ON public.maintenance_windows FOR INSERT WITH CHECK (
  get_user_role() = 'super_admin'
);

-- error_reports — admin only
DROP POLICY IF EXISTS error_reports_select ON public.error_reports;
CREATE POLICY error_reports_select ON public.error_reports FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- deployment_steps — super_admin only
DROP POLICY IF EXISTS deployment_steps_select ON public.deployment_steps;
CREATE POLICY deployment_steps_select ON public.deployment_steps FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- deployments — super_admin only
DROP POLICY IF EXISTS deployments_select ON public.deployments;
CREATE POLICY deployments_select ON public.deployments FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- database_migrations — super_admin only
DROP POLICY IF EXISTS database_migrations_select ON public.database_migrations;
CREATE POLICY database_migrations_select ON public.database_migrations FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- school_level_configurations — admin
DROP POLICY IF EXISTS school_level_configurations_select ON public.school_level_configurations;
CREATE POLICY school_level_configurations_select ON public.school_level_configurations FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- ─── Super Admin Schema Tables ────────────────────────────────────────────

-- platform_settings — super_admin only
DROP POLICY IF EXISTS platform_settings_select ON public.platform_settings;
CREATE POLICY platform_settings_select ON public.platform_settings FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- platform_notifications — admin
DROP POLICY IF EXISTS platform_notifications_select ON public.platform_notifications;
CREATE POLICY platform_notifications_select ON public.platform_notifications FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- platform_policies — super_admin only
DROP POLICY IF EXISTS platform_policies_select ON public.platform_policies;
CREATE POLICY platform_policies_select ON public.platform_policies FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- audit_logs — admin
DROP POLICY IF EXISTS audit_logs_select ON public.audit_logs;
CREATE POLICY audit_logs_select ON public.audit_logs FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- support_tickets — admin or owner
DROP POLICY IF EXISTS support_tickets_select ON public.support_tickets;
DROP POLICY IF EXISTS support_tickets_insert ON public.support_tickets;
CREATE POLICY support_tickets_select ON public.support_tickets FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin') OR created_by = auth.uid()
);
CREATE POLICY support_tickets_insert ON public.support_tickets FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);

-- ticket_comments — admin or ticket owner
DROP POLICY IF EXISTS ticket_comments_select ON public.ticket_comments;
DROP POLICY IF EXISTS ticket_comments_insert ON public.ticket_comments;
CREATE POLICY ticket_comments_select ON public.ticket_comments FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY ticket_comments_insert ON public.ticket_comments FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- intelligence_alerts — admin
DROP POLICY IF EXISTS intelligence_alerts_select ON public.intelligence_alerts;
CREATE POLICY intelligence_alerts_select ON public.intelligence_alerts FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- infrastructure_services — super_admin
DROP POLICY IF EXISTS infrastructure_services_select ON public.infrastructure_services;
CREATE POLICY infrastructure_services_select ON public.infrastructure_services FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- impersonation_sessions — super_admin
DROP POLICY IF EXISTS impersonation_sessions_select ON public.impersonation_sessions;
CREATE POLICY impersonation_sessions_select ON public.impersonation_sessions FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- login_monitoring — admin
DROP POLICY IF EXISTS login_monitoring_select ON public.login_monitoring;
CREATE POLICY login_monitoring_select ON public.login_monitoring FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- feature_flags — admin
DROP POLICY IF EXISTS feature_flags_select ON public.feature_flags;
CREATE POLICY feature_flags_select ON public.feature_flags FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- email_templates — super_admin
DROP POLICY IF EXISTS email_templates_select ON public.email_templates;
CREATE POLICY email_templates_select ON public.email_templates FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- notification_templates — super_admin
DROP POLICY IF EXISTS notification_templates_select ON public.notification_templates;
CREATE POLICY notification_templates_select ON public.notification_templates FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- system_reports — admin
DROP POLICY IF EXISTS system_reports_select ON public.system_reports;
CREATE POLICY system_reports_select ON public.system_reports FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- background_jobs — super_admin
DROP POLICY IF EXISTS background_jobs_select ON public.background_jobs;
CREATE POLICY background_jobs_select ON public.background_jobs FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- user_feedback — admin or owner
DROP POLICY IF EXISTS user_feedback_select ON public.user_feedback;
DROP POLICY IF EXISTS user_feedback_insert ON public.user_feedback;
CREATE POLICY user_feedback_select ON public.user_feedback FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin') OR user_id = auth.uid()
);
CREATE POLICY user_feedback_insert ON public.user_feedback FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);

-- api_keys — super_admin
DROP POLICY IF EXISTS api_keys_select ON public.api_keys;
CREATE POLICY api_keys_select ON public.api_keys FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- ─── Final Production Schema Tables ──────────────────────────────────────

-- mock_exams — admin + teacher
DROP POLICY IF EXISTS mock_exams_select ON public.mock_exams;
DROP POLICY IF EXISTS mock_exams_insert ON public.mock_exams;
CREATE POLICY mock_exams_select ON public.mock_exams FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher', 'student')
);
CREATE POLICY mock_exams_insert ON public.mock_exams FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin', 'teacher')
);

-- eduos_modules — admin
DROP POLICY IF EXISTS eduos_modules_select ON public.eduos_modules;
CREATE POLICY eduos_modules_select ON public.eduos_modules FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- eduos_module_apis — admin
DROP POLICY IF EXISTS eduos_module_apis_select ON public.eduos_module_apis;
CREATE POLICY eduos_module_apis_select ON public.eduos_module_apis FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- eduos_module_subscriptions — admin
DROP POLICY IF EXISTS eduos_module_subscriptions_select ON public.eduos_module_subscriptions;
CREATE POLICY eduos_module_subscriptions_select ON public.eduos_module_subscriptions FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- email_campaigns — super_admin
DROP POLICY IF EXISTS email_campaigns_select ON public.email_campaigns;
CREATE POLICY email_campaigns_select ON public.email_campaigns FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- sales_proposals — super_admin
DROP POLICY IF EXISTS sales_proposals_select ON public.sales_proposals;
CREATE POLICY sales_proposals_select ON public.sales_proposals FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- demo_accounts — super_admin
DROP POLICY IF EXISTS demo_accounts_select ON public.demo_accounts;
CREATE POLICY demo_accounts_select ON public.demo_accounts FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- daily_analytics — admin
DROP POLICY IF EXISTS daily_analytics_select ON public.daily_analytics;
CREATE POLICY daily_analytics_select ON public.daily_analytics FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- landing_pages — super_admin
DROP POLICY IF EXISTS landing_pages_select ON public.landing_pages;
CREATE POLICY landing_pages_select ON public.landing_pages FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- blog_posts — admin
DROP POLICY IF EXISTS blog_posts_select ON public.blog_posts;
DROP POLICY IF EXISTS blog_posts_insert ON public.blog_posts;
CREATE POLICY blog_posts_select ON public.blog_posts FOR SELECT USING (true);
CREATE POLICY blog_posts_insert ON public.blog_posts FOR INSERT WITH CHECK (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- affiliates — super_admin
DROP POLICY IF EXISTS affiliates_select ON public.affiliates;
CREATE POLICY affiliates_select ON public.affiliates FOR SELECT USING (
  get_user_role() = 'super_admin'
);

-- referrals — admin
DROP POLICY IF EXISTS referrals_select ON public.referrals;
CREATE POLICY referrals_select ON public.referrals FOR SELECT USING (
  get_user_role() IN ('super_admin', 'school_admin')
);

-- ─── Marketplace Schema Tables ───────────────────────────────────────────

-- marketplace_products (2 insecure policies)
DROP POLICY IF EXISTS marketplace_products_admin_all ON public.marketplace_products;
DROP POLICY IF EXISTS marketplace_products_seller_select ON public.marketplace_products;
CREATE POLICY marketplace_products_admin_all ON public.marketplace_products FOR ALL USING (
  get_user_role() IN ('super_admin', 'school_admin')
);
CREATE POLICY marketplace_products_seller_select ON public.marketplace_products FOR SELECT USING (
  seller_id = auth.uid() OR status = 'published'
);

-- marketplace_categories (2 insecure policies)
DROP POLICY IF EXISTS marketplace_categories_admin_all ON public.marketplace_categories;
CREATE POLICY marketplace_categories_admin_all ON public.marketplace_categories FOR ALL USING (
  get_user_role() = 'super_admin'
);

-- ─── Step 4: Add index for get_user_role() performance ────────────────────
CREATE INDEX IF NOT EXISTS idx_users_id_role ON public.users(id, role);

-- ─── Step 5: Verify — no more raw_user_meta_data in RLS policies ──────────
-- This query should return 0 rows after migration:
-- SELECT schemaname, tablename, policyname, qual, with_check
-- FROM pg_policies
-- WHERE qual LIKE '%raw_user_meta_data%'
--    OR with_check LIKE '%raw_user_meta_data%';
