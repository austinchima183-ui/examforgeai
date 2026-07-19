-- ═══════════════════════════════════════════════════════════════════════════════
-- ExamForge AI — Enterprise Super Admin Platform Schema
-- ═══════════════════════════════════════════════════════════════════════════════
-- Provides complete operational visibility and control over the SaaS ecosystem:
--   • Platform settings & feature flags
--   • Audit logs & security monitoring
--   • Support tickets & feedback
--   • AI provider management
--   • Infrastructure health tracking
--   • Marketplace content moderation
--   • Operations intelligence & AI predictions
--   • Admin notifications & reports
-- ═══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ─── Custom Enum Types ────────────────────────────────────────────────────────

DO $$ BEGIN
  -- Platform setting scope
  CREATE TYPE setting_scope AS ENUM ('global', 'billing', 'ai', 'communication', 'security', 'infrastructure', 'marketplace', 'email', 'notification', 'feature_flag');

  -- Setting value type
  CREATE TYPE setting_value_type AS ENUM ('string', 'integer', 'boolean', 'json', 'float', 'encrypted');

  -- Audit log severity
  CREATE TYPE audit_severity AS ENUM ('info', 'warning', 'error', 'critical');

  -- Audit log category
  CREATE TYPE audit_category AS ENUM ('authentication', 'authorization', 'data_access', 'data_modification', 'system_configuration', 'billing', 'ai_operations', 'security', 'user_management', 'school_management', 'marketplace', 'support', 'infrastructure');

  -- Ticket status
  CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'waiting_on_user', 'waiting_on_third_party', 'resolved', 'closed', 'reopened');

  -- Ticket priority
  CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent', 'critical');

  -- Ticket category
  CREATE TYPE ticket_category AS ENUM ('technical', 'billing', 'account', 'feature_request', 'bug_report', 'general', 'ai_related', 'security');

  -- Feedback type
  CREATE TYPE feedback_type AS ENUM ('bug_report', 'feature_request', 'complaint', 'compliment', 'suggestion', 'rating');

  -- AI provider status
  CREATE TYPE ai_provider_status AS ENUM ('active', 'inactive', 'degraded', 'maintenance', 'suspended');

  -- Health status
  CREATE TYPE health_status AS ENUM ('healthy', 'degraded', 'unhealthy', 'down', 'maintenance');

  -- Marketplace content status
  CREATE TYPE marketplace_status AS ENUM ('pending_review', 'approved', 'rejected', 'featured', 'archived', 'flagged', 'suspended');

  -- Marketplace content type
  CREATE TYPE marketplace_content_type AS ENUM ('resource', 'lesson_note', 'worksheet', 'question_bank', 'template', 'exam_format', 'video', 'document');

  -- Feature flag type
  CREATE TYPE feature_flag_type AS ENUM ('boolean', 'percentage', 'user_segment', 'school_segment', 'gradual_rollout');

  -- Notification priority
  CREATE TYPE notification_priority AS ENUM ('low', 'normal', 'high', 'urgent', 'critical');

  -- Notification category
  CREATE TYPE notification_category AS ENUM ('payment_failure', 'ai_provider_issue', 'system_error', 'security_alert', 'new_registration', 'subscription_expiration', 'infrastructure', 'support', 'feature_release', 'maintenance', 'report_ready', 'intelligence');

  -- Report type
  CREATE TYPE report_type AS ENUM ('daily_summary', 'weekly_summary', 'monthly_summary', 'revenue_report', 'user_analytics', 'ai_usage_report', 'churn_analysis', 'school_performance', 'system_health', 'security_audit', 'custom');

  -- Report format
  CREATE TYPE report_format AS ENUM ('pdf', 'csv', 'xlsx', 'json');

  -- Report status
  CREATE TYPE report_status AS ENUM ('pending', 'generating', 'completed', 'failed', 'expired');

  -- Maintenance window status
  CREATE TYPE maintenance_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

  -- Intelligence alert type
  CREATE TYPE intelligence_alert_type AS ENUM ('churn_prediction', 'anomaly_detection', 'engagement_drop', 'upsell_opportunity', 'revenue_forecast', 'cost_optimization', 'infrastructure_bottleneck', 'support_needed', 'unusual_usage', 'growth_opportunity');

  -- Intelligence alert severity
  CREATE TYPE intelligence_severity AS ENUM ('info', 'attention', 'warning', 'critical');

  -- Impersonation status
  CREATE TYPE impersonation_status AS ENUM ('active', 'ended', 'expired', 'revoked');

  -- Background job status
  CREATE TYPE job_status AS ENUM ('pending', 'running', 'completed', 'failed', 'cancelled', 'retrying');

EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ─── Platform Settings ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(255) NOT NULL,
  value JSONB NOT NULL DEFAULT '{}',
  value_type setting_value_type NOT NULL DEFAULT 'string',
  scope setting_scope NOT NULL DEFAULT 'global',
  description TEXT,
  is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
  is_readonly BOOLEAN NOT NULL DEFAULT FALSE,
  default_value JSONB,
  validation_rules JSONB DEFAULT '{}',
  updated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(key, scope)
);

CREATE INDEX IF NOT EXISTS idx_platform_settings_scope ON platform_settings(scope);
CREATE INDEX IF NOT EXISTS idx_platform_settings_key ON platform_settings(key);

-- ─── Feature Flags ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  flag_type feature_flag_type NOT NULL DEFAULT 'boolean',
  value JSONB NOT NULL DEFAULT '{"enabled": false}',
  target_segments JSONB DEFAULT '[]',
  school_ids UUID[] DEFAULT '{}',
  user_roles VARCHAR[] DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  starts_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_key ON feature_flags(key);
CREATE INDEX IF NOT EXISTS idx_feature_flags_active ON feature_flags(is_active) WHERE is_active = TRUE;

-- ─── Audit Logs ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES auth.users(id),
  actor_email VARCHAR(320),
  actor_role VARCHAR(50),
  action VARCHAR(255) NOT NULL,
  category audit_category NOT NULL DEFAULT 'system_configuration',
  severity audit_severity NOT NULL DEFAULT 'info',
  resource_type VARCHAR(100),
  resource_id VARCHAR(255),
  school_id UUID,
  description TEXT,
  old_values JSONB,
  new_values JSONB,
  metadata JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  session_id VARCHAR(255),
  request_id VARCHAR(255),
  duration_ms INTEGER,
  is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partition audit_logs by month for performance at scale
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_category ON audit_logs(category);
CREATE INDEX IF NOT EXISTS idx_audit_logs_severity ON audit_logs(severity);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_school ON audit_logs(school_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_desc ON audit_logs(created_at DESC);

-- ─── Support Tickets ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number VARCHAR(50) NOT NULL UNIQUE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id),
  school_id UUID,
  subject VARCHAR(500) NOT NULL,
  description TEXT NOT NULL,
  category ticket_category NOT NULL DEFAULT 'general',
  priority ticket_priority NOT NULL DEFAULT 'medium',
  status ticket_status NOT NULL DEFAULT 'open',
  assigned_to UUID REFERENCES auth.users(id),
  related_resource_type VARCHAR(100),
  related_resource_id VARCHAR(255),
  tags TEXT[] DEFAULT '{}',
  attachments JSONB DEFAULT '[]',
  resolution_notes TEXT,
  first_response_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
  satisfaction_comment TEXT,
  is_escalated BOOLEAN NOT NULL DEFAULT FALSE,
  escalated_at TIMESTAMPTZ,
  escalated_to UUID REFERENCES auth.users(id),
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_reporter ON support_tickets(reporter_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assignee ON support_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_school ON support_tickets(school_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_desc ON support_tickets(created_at DESC);

-- Ticket comments/conversation
CREATE TABLE IF NOT EXISTS ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  is_internal BOOLEAN NOT NULL DEFAULT FALSE,
  attachments JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket ON ticket_comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_created ON ticket_comments(ticket_id, created_at);

-- ─── User Feedback ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  school_id UUID,
  feedback_type feedback_type NOT NULL,
  title VARCHAR(500),
  content TEXT NOT NULL,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  feature_area VARCHAR(100),
  page_url VARCHAR(1000),
  screenshot_urls JSONB DEFAULT '[]',
  is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
  status ticket_status NOT NULL DEFAULT 'open',
  admin_response TEXT,
  responded_by UUID REFERENCES auth.users(id),
  responded_at TIMESTAMPTZ,
  upvotes INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_user ON user_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_type ON user_feedback(feedback_type);
CREATE INDEX IF NOT EXISTS idx_user_feedback_status ON user_feedback(status);
CREATE INDEX IF NOT EXISTS idx_user_feedback_school ON user_feedback(school_id);

-- ─── AI Providers ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ai_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  slug VARCHAR(100) NOT NULL UNIQUE,
  provider_type VARCHAR(50) NOT NULL,
  api_base_url VARCHAR(500) NOT NULL,
  api_key_encrypted TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  status ai_provider_status NOT NULL DEFAULT 'active',
  supported_models JSONB NOT NULL DEFAULT '[]',
  default_model VARCHAR(100),
  rate_limit_per_minute INTEGER DEFAULT 60,
  rate_limit_per_day INTEGER DEFAULT 10000,
  cost_per_1k_input_tokens DECIMAL(10, 6) DEFAULT 0,
  cost_per_1k_output_tokens DECIMAL(10, 6) DEFAULT 0,
  monthly_budget DECIMAL(12, 2),
  current_month_spend DECIMAL(12, 2) NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 0,
  failover_provider_id UUID REFERENCES ai_providers(id),
  health_check_url VARCHAR(500),
  last_health_check_at TIMESTAMPTZ,
  configuration JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_providers_active ON ai_providers(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_ai_providers_default ON ai_providers(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_ai_providers_priority ON ai_providers(priority);

-- AI request logs (for monitoring and analytics)
CREATE TABLE IF NOT EXISTS ai_request_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES ai_providers(id),
  user_id UUID REFERENCES auth.users(id),
  school_id UUID,
  model VARCHAR(100) NOT NULL,
  request_type VARCHAR(100) NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  total_tokens INTEGER NOT NULL DEFAULT 0,
  cost DECIMAL(12, 6) NOT NULL DEFAULT 0,
  latency_ms INTEGER NOT NULL DEFAULT 0,
  is_success BOOLEAN NOT NULL DEFAULT TRUE,
  error_message TEXT,
  error_code VARCHAR(50),
  request_metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_request_logs_provider ON ai_request_logs(provider_id);
CREATE INDEX IF NOT EXISTS idx_ai_request_logs_user ON ai_request_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_request_logs_school ON ai_request_logs(school_id);
CREATE INDEX IF NOT EXISTS idx_ai_request_logs_created ON ai_request_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_request_logs_created_desc ON ai_request_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_request_logs_success ON ai_request_logs(is_success) WHERE is_success = FALSE;

-- ─── Infrastructure Health ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS infrastructure_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(100) NOT NULL UNIQUE,
  service_type VARCHAR(50) NOT NULL,
  endpoint_url VARCHAR(500),
  health_status health_status NOT NULL DEFAULT 'healthy',
  last_check_at TIMESTAMPTZ,
  last_healthy_at TIMESTAMPTZ,
  response_time_ms INTEGER,
  uptime_percentage DECIMAL(5, 2) DEFAULT 100.00,
  error_rate DECIMAL(5, 2) DEFAULT 0.00,
  configuration JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  is_critical BOOLEAN NOT NULL DEFAULT FALSE,
  alert_threshold_response_ms INTEGER DEFAULT 5000,
  alert_threshold_error_rate DECIMAL(5, 2) DEFAULT 5.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_infra_services_status ON infrastructure_services(health_status);
CREATE INDEX IF NOT EXISTS idx_infra_services_critical ON infrastructure_services(is_critical) WHERE is_critical = TRUE;

-- Health check history for trend analysis
CREATE TABLE IF NOT EXISTS health_check_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES infrastructure_services(id) ON DELETE CASCADE,
  health_status health_status NOT NULL,
  response_time_ms INTEGER,
  error_message TEXT,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_health_check_service ON health_check_history(service_id);
CREATE INDEX IF NOT EXISTS idx_health_check_time ON health_check_history(checked_at DESC);

-- ─── Marketplace Content ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS marketplace_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES auth.users(id),
  school_id UUID,
  title VARCHAR(500) NOT NULL,
  description TEXT NOT NULL,
  content_type marketplace_content_type NOT NULL,
  status marketplace_status NOT NULL DEFAULT 'pending_review',
  subject VARCHAR(100),
  class_level VARCHAR(100),
  curriculum VARCHAR(100),
  tags TEXT[] DEFAULT '{}',
  thumbnail_url VARCHAR(1000),
  content_urls JSONB DEFAULT '[]',
  price DECIMAL(10, 2) DEFAULT 0,
  is_free BOOLEAN NOT NULL DEFAULT TRUE,
  download_count INTEGER NOT NULL DEFAULT 0,
  rating_average DECIMAL(3, 2) DEFAULT 0,
  rating_count INTEGER NOT NULL DEFAULT 0,
  review_notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  featured_until TIMESTAMPTZ,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  flag_reason TEXT,
  flagged_by UUID REFERENCES auth.users(id),
  flagged_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_status ON marketplace_content(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_type ON marketplace_content(content_type);
CREATE INDEX IF NOT EXISTS idx_marketplace_author ON marketplace_content(author_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_school ON marketplace_content(school_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_featured ON marketplace_content(status) WHERE status = 'featured';
CREATE INDEX IF NOT EXISTS idx_marketplace_flagged ON marketplace_content(is_flagged) WHERE is_flagged = TRUE;

-- ─── Maintenance Windows ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS maintenance_windows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status maintenance_status NOT NULL DEFAULT 'scheduled',
  affected_services JSONB DEFAULT '[]',
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  actual_start_at TIMESTAMPTZ,
  actual_end_at TIMESTAMPTZ,
  is_planned BOOLEAN NOT NULL DEFAULT TRUE,
  notification_sent BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT maintenance_end_after_start CHECK (end_at > start_at)
);

CREATE INDEX IF NOT EXISTS idx_maintenance_status ON maintenance_windows(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_start ON maintenance_windows(start_at);

-- ─── Platform Notifications ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID REFERENCES auth.users(id),
  category notification_category NOT NULL,
  priority notification_priority NOT NULL DEFAULT 'normal',
  title VARCHAR(500) NOT NULL,
  message TEXT NOT NULL,
  action_url VARCHAR(1000),
  action_label VARCHAR(100),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
  dismissed_at TIMESTAMPTZ,
  related_entity_type VARCHAR(100),
  related_entity_id VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_platform_notif_recipient ON platform_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_platform_notif_read ON platform_notifications(recipient_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_platform_notif_category ON platform_notifications(category);
CREATE INDEX IF NOT EXISTS idx_platform_notif_priority ON platform_notifications(priority);
CREATE INDEX IF NOT EXISTS idx_platform_notif_created ON platform_notifications(created_at DESC);

-- ─── System Reports ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS system_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type report_type NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  format report_format NOT NULL DEFAULT 'pdf',
  status report_status NOT NULL DEFAULT 'pending',
  parameters JSONB DEFAULT '{}',
  file_url VARCHAR(1000),
  file_size_bytes BIGINT,
  generated_by UUID REFERENCES auth.users(id),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  is_scheduled BOOLEAN NOT NULL DEFAULT FALSE,
  schedule_cron VARCHAR(100),
  next_run_at TIMESTAMPTZ,
  recipients JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_system_reports_type ON system_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_system_reports_status ON system_reports(status);
CREATE INDEX IF NOT EXISTS idx_system_reports_scheduled ON system_reports(is_scheduled) WHERE is_scheduled = TRUE;

-- ─── Background Jobs ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS background_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type VARCHAR(100) NOT NULL,
  job_name VARCHAR(255) NOT NULL,
  status job_status NOT NULL DEFAULT 'pending',
  priority INTEGER NOT NULL DEFAULT 0,
  payload JSONB DEFAULT '{}',
  result JSONB,
  error_message TEXT,
  max_retries INTEGER NOT NULL DEFAULT 3,
  retry_count INTEGER NOT NULL DEFAULT 0,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bg_jobs_status ON background_jobs(status);
CREATE INDEX IF NOT EXISTS idx_bg_jobs_type ON background_jobs(job_type);
CREATE INDEX IF NOT EXISTS idx_bg_jobs_scheduled ON background_jobs(scheduled_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_bg_jobs_priority ON background_jobs(priority DESC);

-- ─── Impersonation Sessions ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS impersonation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id),
  target_user_id UUID NOT NULL REFERENCES auth.users(id),
  target_user_role VARCHAR(50) NOT NULL,
  target_school_id UUID,
  reason TEXT NOT NULL,
  status impersonation_status NOT NULL DEFAULT 'active',
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  end_reason VARCHAR(100),
  ip_address INET,
  user_agent TEXT,
  actions_taken JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT impersonation_expiry_future CHECK (expires_at > started_at)
);

CREATE INDEX IF NOT EXISTS idx_impersonation_admin ON impersonation_sessions(admin_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_target ON impersonation_sessions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_status ON impersonation_sessions(status) WHERE status = 'active';

-- ─── Usage Statistics ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS usage_statistics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID,
  stat_date DATE NOT NULL,
  metric_key VARCHAR(100) NOT NULL,
  metric_value DECIMAL(18, 4) NOT NULL DEFAULT 0,
  dimensions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(school_id, stat_date, metric_key, dimensions)
);

CREATE INDEX IF NOT EXISTS idx_usage_stats_school ON usage_statistics(school_id);
CREATE INDEX IF NOT EXISTS idx_usage_stats_date ON usage_statistics(stat_date DESC);
CREATE INDEX IF NOT EXISTS idx_usage_stats_metric ON usage_statistics(metric_key);
CREATE INDEX IF NOT EXISTS idx_usage_stats_school_date ON usage_statistics(school_id, stat_date DESC);

-- ─── Operations Intelligence ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS intelligence_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type intelligence_alert_type NOT NULL,
  severity intelligence_severity NOT NULL DEFAULT 'attention',
  title VARCHAR(500) NOT NULL,
  description TEXT NOT NULL,
  affected_entity_type VARCHAR(100),
  affected_entity_id VARCHAR(255),
  affected_school_id UUID,
  predicted_value DECIMAL(18, 4),
  predicted_date DATE,
  confidence_score DECIMAL(5, 2) CHECK (confidence_score BETWEEN 0 AND 100),
  supporting_data JSONB DEFAULT '{}',
  recommended_actions JSONB DEFAULT '[]',
  is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  expires_at TIMESTAMPTZ,
  model_version VARCHAR(50),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_intelligence_type ON intelligence_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_intelligence_severity ON intelligence_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_intelligence_ack ON intelligence_alerts(is_acknowledged) WHERE is_acknowledged = FALSE;
CREATE INDEX IF NOT EXISTS idx_intelligence_resolved ON intelligence_alerts(is_resolved) WHERE is_resolved = FALSE;
CREATE INDEX IF NOT EXISTS idx_intelligence_school ON intelligence_alerts(affected_school_id);
CREATE INDEX IF NOT EXISTS idx_intelligence_created ON intelligence_alerts(created_at DESC);

-- ─── Login Monitoring ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS login_monitoring (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  email VARCHAR(320),
  role VARCHAR(50),
  school_id UUID,
  is_success BOOLEAN NOT NULL,
  failure_reason VARCHAR(255),
  ip_address INET,
  user_agent TEXT,
  device_fingerprint VARCHAR(255),
  country VARCHAR(3),
  city VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  session_id VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_login_monitor_user ON login_monitoring(user_id);
CREATE INDEX IF NOT EXISTS idx_login_monitor_success ON login_monitoring(is_success) WHERE is_success = FALSE;
CREATE INDEX IF NOT EXISTS idx_login_monitor_ip ON login_monitoring(ip_address);
CREATE INDEX IF NOT EXISTS idx_login_monitor_created ON login_monitoring(created_at DESC);

-- ─── Active Sessions ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS active_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  session_token_hash VARCHAR(255) NOT NULL,
  device_info JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  country VARCHAR(3),
  city VARCHAR(100),
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_active_sessions_user ON active_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_active_sessions_token ON active_sessions(session_token_hash);
CREATE INDEX IF NOT EXISTS idx_active_sessions_expires ON active_sessions(expires_at);

-- ─── Dashboard Snapshots (cached metrics for fast loading) ────────────────────

CREATE TABLE IF NOT EXISTS dashboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_type VARCHAR(50) NOT NULL,
  data JSONB NOT NULL DEFAULT '{}',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE(snapshot_type)
);

CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_type ON dashboard_snapshots(snapshot_type);
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_expires ON dashboard_snapshots(expires_at);

-- ─── Platform Policies ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_key VARCHAR(100) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  effective_date DATE NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_platform_policies_key ON platform_policies(policy_key);
CREATE INDEX IF NOT EXISTS idx_platform_policies_active ON platform_policies(is_active) WHERE is_active = TRUE;

-- ─── Email Templates ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  subject VARCHAR(500) NOT NULL,
  html_body TEXT NOT NULL,
  text_body TEXT,
  category VARCHAR(50),
  variables JSONB DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_templates_key ON email_templates(template_key);
CREATE INDEX IF NOT EXISTS idx_email_templates_category ON email_templates(category);

-- ─── Notification Templates ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  title_template VARCHAR(500) NOT NULL,
  body_template TEXT NOT NULL,
  category notification_category,
  channel VARCHAR(20) NOT NULL DEFAULT 'in_app',
  variables JSONB DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notif_templates_key ON notification_templates(template_key);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════════

-- Platform Settings: only super admins can modify
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can read platform settings" ON platform_settings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );
CREATE POLICY "Super admins can modify platform settings" ON platform_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Feature Flags: super admins manage, others read
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read feature flags" ON feature_flags
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Super admins can manage feature flags" ON feature_flags
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Audit Logs: super admins only
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can read audit logs" ON audit_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );
CREATE POLICY "System can insert audit logs" ON audit_logs
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Support Tickets: reporters + assigned admins + super admins
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own tickets" ON support_tickets
  FOR SELECT USING (
    reporter_id = auth.uid() OR assigned_to = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );
CREATE POLICY "Users can create tickets" ON support_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Admins can update tickets" ON support_tickets
  FOR UPDATE USING (
    assigned_to = auth.uid() OR
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Ticket comments
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ticket participants can read comments" ON ticket_comments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM support_tickets WHERE support_tickets.id = ticket_comments.ticket_id AND
      (support_tickets.reporter_id = auth.uid() OR support_tickets.assigned_to = auth.uid()
       OR EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')))
  );

-- AI Providers: super admins only
ALTER TABLE ai_providers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can manage AI providers" ON ai_providers
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- AI request logs: super admins read, system writes
ALTER TABLE ai_request_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can read AI logs" ON ai_request_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Infrastructure: super admins only
ALTER TABLE infrastructure_services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins manage infrastructure" ON infrastructure_services
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Marketplace: anyone can read approved, super admins manage
ALTER TABLE marketplace_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read approved marketplace content" ON marketplace_content
  FOR SELECT USING (status IN ('approved', 'featured'));
CREATE POLICY "Authors can read own content" ON marketplace_content
  FOR SELECT USING (author_id = auth.uid());
CREATE POLICY "Super admins manage marketplace" ON marketplace_content
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Platform notifications: recipient only
ALTER TABLE platform_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own notifications" ON platform_notifications
  FOR SELECT USING (
    recipient_id = auth.uid()
    OR recipient_id IS NULL
  );
CREATE POLICY "Super admins manage notifications" ON platform_notifications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Intelligence alerts: super admins only
ALTER TABLE intelligence_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins manage intelligence" ON intelligence_alerts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Impersonation: super admins only
ALTER TABLE impersonation_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins manage impersonation" ON impersonation_sessions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Login monitoring: super admins only
ALTER TABLE login_monitoring ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins read login monitoring" ON login_monitoring
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- Active sessions: owner + super admins
ALTER TABLE active_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own sessions" ON active_sessions
  FOR SELECT USING (user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin'));

-- Background jobs: super admins only
ALTER TABLE background_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins manage jobs" ON background_jobs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM auth.users WHERE auth.uid() = id AND raw_user_meta_data->>'role' = 'superAdmin')
  );

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_platform_settings_updated BEFORE UPDATE ON platform_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_feature_flags_updated BEFORE UPDATE ON feature_flags
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_support_tickets_updated BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_ai_providers_updated BEFORE UPDATE ON ai_providers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_infra_services_updated BEFORE UPDATE ON infrastructure_services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_marketplace_updated BEFORE UPDATE ON marketplace_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_maintenance_updated BEFORE UPDATE ON maintenance_windows
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_bg_jobs_updated BEFORE UPDATE ON background_jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_intelligence_updated BEFORE UPDATE ON intelligence_alerts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate ticket numbers
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.ticket_number := 'TKT-' || to_char(now(), 'YYYYMMDD') || '-' || lpad(nextval('ticket_number_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS ticket_number_seq START 1;
CREATE TRIGGER trg_support_tickets_number BEFORE INSERT ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION generate_ticket_number();

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get platform-wide dashboard metrics (cached in dashboard_snapshots)
CREATE OR REPLACE FUNCTION get_platform_dashboard_metrics()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_schools', (SELECT COUNT(*) FROM schools WHERE is_active = TRUE),
    'total_teachers', (SELECT COUNT(*) FROM user_profiles WHERE role = 'teacher' AND is_active = TRUE),
    'total_students', (SELECT COUNT(*) FROM user_profiles WHERE role = 'student' AND is_active = TRUE),
    'total_parents', (SELECT COUNT(*) FROM user_profiles WHERE role = 'parent' AND is_active = TRUE),
    'active_exams', (SELECT COUNT(*) FROM exams WHERE status IN ('active', 'in_progress')),
    'daily_active_users', (SELECT COUNT(DISTINCT user_id) FROM login_monitoring WHERE is_success = TRUE AND created_at >= now() - INTERVAL '24 hours'),
    'monthly_active_users', (SELECT COUNT(DISTINCT user_id) FROM login_monitoring WHERE is_success = TRUE AND created_at >= now() - INTERVAL '30 days'),
    'ai_requests_today', (SELECT COUNT(*) FROM ai_request_logs WHERE created_at >= CURRENT_DATE),
    'revenue_today', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'completed' AND created_at >= CURRENT_DATE),
    'monthly_revenue', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'completed' AND created_at >= DATE_TRUNC('month', CURRENT_DATE)),
    'annual_revenue', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'completed' AND created_at >= DATE_TRUNC('year', CURRENT_DATE)),
    'active_subscriptions', (SELECT COUNT(*) FROM subscriptions WHERE status = 'active'),
    'trial_accounts', (SELECT COUNT(*) FROM subscriptions WHERE status = 'trialing'),
    'computed_at', now()
  ) INTO result;

  -- Cache the result
  INSERT INTO dashboard_snapshots (snapshot_type, data, expires_at)
  VALUES ('platform_metrics', result, now() + INTERVAL '5 minutes')
  ON CONFLICT (snapshot_type) DO UPDATE SET data = result, computed_at = now(), expires_at = now() + INTERVAL '5 minutes';

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get school growth metrics
CREATE OR REPLACE FUNCTION get_school_growth_metrics(
  period_start DATE DEFAULT CURRENT_DATE - INTERVAL '12 months',
  period_end DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(month DATE, new_schools BIGINT, total_schools BIGINT, churned_schools BIGINT) AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT generate_series(period_start, period_end, INTERVAL '1 month')::DATE AS month
  ),
  new_counts AS (
    SELECT DATE_TRUNC('month', created_at)::DATE AS month, COUNT(*)::BIGINT AS new_schools
    FROM schools WHERE created_at >= period_start AND created_at <= period_end
    GROUP BY DATE_TRUNC('month', created_at)
  ),
  churn_counts AS (
    SELECT DATE_TRUNC('month', updated_at)::DATE AS month, COUNT(*)::BIGINT AS churned_schools
    FROM schools WHERE is_active = FALSE AND updated_at >= period_start AND updated_at <= period_end
    GROUP BY DATE_TRUNC('month', updated_at)
  )
  SELECT m.month,
    COALESCE(nc.new_schools, 0),
    (SELECT COUNT(*) FROM schools WHERE created_at <= m.month + INTERVAL '1 month' AND is_active = TRUE)::BIGINT,
    COALESCE(cc.churned_schools, 0)
  FROM months m
  LEFT JOIN new_counts nc ON nc.month = m.month
  LEFT JOIN churn_counts cc ON cc.month = m.month
  ORDER BY m.month;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get AI usage analytics
CREATE OR REPLACE FUNCTION get_ai_usage_analytics(
  period_start DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  period_end DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(date DATE, total_requests BIGINT, successful_requests BIGINT, failed_requests BIGINT,
  total_tokens BIGINT, total_cost DECIMAL, avg_latency_ms DECIMAL) AS $$
BEGIN
  RETURN QUERY
  SELECT created_at::DATE AS date,
    COUNT(*)::BIGINT,
    COUNT(*) FILTER (WHERE is_success = TRUE)::BIGINT,
    COUNT(*) FILTER (WHERE is_success = FALSE)::BIGINT,
    SUM(total_tokens)::BIGINT,
    SUM(cost)::DECIMAL,
    AVG(latency_ms)::DECIMAL
  FROM ai_request_logs
  WHERE created_at >= period_start AND created_at <= period_end + INTERVAL '1 day'
  GROUP BY created_at::DATE
  ORDER BY date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Detect suspicious login activity
CREATE OR REPLACE FUNCTION detect_suspicious_logins(
  lookback_hours INTEGER DEFAULT 24,
  failure_threshold INTEGER DEFAULT 5
)
RETURNS TABLE(user_id UUID, email VARCHAR, failure_count BIGINT, distinct_ips BIGINT, last_attempt TIMESTAMPTZ) AS $$
BEGIN
  RETURN QUERY
  SELECT lm.user_id, lm.email,
    COUNT(*)::BIGINT AS failure_count,
    COUNT(DISTINCT lm.ip_address)::BIGINT AS distinct_ips,
    MAX(lm.created_at) AS last_attempt
  FROM login_monitoring lm
  WHERE lm.is_success = FALSE
    AND lm.created_at >= now() - (lookback_hours || ' hours')::INTERVAL
  GROUP BY lm.user_id, lm.email
  HAVING COUNT(*) >= failure_threshold
  ORDER BY failure_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Seed default platform settings
INSERT INTO platform_settings (key, value, value_type, scope, description, default_value) VALUES
  ('maintenance_mode', 'false', 'boolean', 'global', 'Enable maintenance mode to disable platform access', 'false'),
  ('max_login_attempts', '5', 'integer', 'security', 'Maximum failed login attempts before lockout', '5'),
  ('lockout_duration_minutes', '30', 'integer', 'security', 'Account lockout duration in minutes', '30'),
  ('session_timeout_minutes', '480', 'integer', 'security', 'Session timeout in minutes', '480'),
  ('impersonation_max_duration_minutes', '60', 'integer', 'security', 'Maximum impersonation session duration', '60'),
  ('enable_registration', 'true', 'boolean', 'global', 'Allow new user registrations', 'true'),
  ('default_ai_provider', 'openai', 'string', 'ai', 'Default AI provider slug', 'openai'),
  ('ai_budget_alert_threshold', '80', 'integer', 'ai', 'Alert when AI spend reaches this percentage of budget', '80'),
  ('support_auto_assign', 'true', 'boolean', 'support', 'Automatically assign support tickets', 'true'),
  ('marketplace_auto_approve', 'false', 'boolean', 'marketplace', 'Automatically approve marketplace submissions', 'false'),
  ('backup_frequency_hours', '24', 'integer', 'infrastructure', 'Database backup frequency in hours', '24'),
  ('dashboard_cache_minutes', '5', 'integer', 'infrastructure', 'Dashboard data cache duration in minutes', '5'),
  ('max_file_upload_mb', '50', 'integer', 'global', 'Maximum file upload size in MB', '50')
ON CONFLICT (key, scope) DO NOTHING;

-- Seed default infrastructure services
INSERT INTO infrastructure_services (service_name, service_type, is_critical, health_status) VALUES
  ('API Server', 'api', TRUE, 'healthy'),
  ('Database (PostgreSQL)', 'database', TRUE, 'healthy'),
  ('Authentication Service', 'auth', TRUE, 'healthy'),
  ('AI Provider Gateway', 'ai_gateway', TRUE, 'healthy'),
  ('File Storage (S3)', 'storage', TRUE, 'healthy'),
  ('Email Service', 'email', FALSE, 'healthy'),
  ('Push Notification Service', 'push', FALSE, 'healthy'),
  ('CDN', 'cdn', FALSE, 'healthy'),
  ('Background Job Queue', 'queue', TRUE, 'healthy'),
  ('WebSocket Server', 'websocket', FALSE, 'healthy')
ON CONFLICT (service_name) DO NOTHING;

COMMIT;
