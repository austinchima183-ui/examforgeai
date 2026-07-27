-- ============================================================================
-- ExamForge AI — Infrastructure & Monitoring Schema
-- ============================================================================
-- Adds tables and functions for:
--   1. Application health monitoring
--   2. Performance metrics collection
--   3. Audit trail for all critical operations
--   4. Rate limiting per user/IP
--   5. Feature flag management
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- APPLICATION HEALTH CHECKS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS app_health_checks (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name      TEXT NOT NULL,                            -- e.g. 'api', 'ai_service', 'payment'
  status            TEXT NOT NULL DEFAULT 'healthy',          -- healthy, degraded, down
  response_time_ms  INT,                                      -- Response time in milliseconds
  error_rate        NUMERIC(5,4) DEFAULT 0,                   -- Error rate 0.0 - 1.0
  details           JSONB DEFAULT '{}',                       -- Additional health details
  checked_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_health_checks_service ON app_health_checks (service_name, checked_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE METRICS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS performance_metrics (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name       TEXT NOT NULL,                            -- e.g. 'page_load', 'ai_generation', 'payment_processing'
  metric_type       TEXT NOT NULL DEFAULT 'latency',          -- latency, throughput, error_rate, memory
  value             NUMERIC NOT NULL,                         -- Metric value
  unit              TEXT NOT NULL DEFAULT 'ms',               -- ms, requests/s, mb, percentage
  tags              JSONB DEFAULT '{}',                       -- Key-value tags for filtering
  user_id           UUID,
  school_id         UUID,
  recorded_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_perf_metrics_name ON performance_metrics (metric_name, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_perf_metrics_user ON performance_metrics (user_id, recorded_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- RATE LIMITING
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS rate_limits (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier        TEXT NOT NULL,                            -- user_id, ip_address, or api_key
  identifier_type   TEXT NOT NULL DEFAULT 'user_id',          -- user_id, ip, api_key
  endpoint          TEXT NOT NULL DEFAULT '*',                -- API endpoint pattern
  request_count     INT NOT NULL DEFAULT 0,
  window_start      TIMESTAMPTZ NOT NULL DEFAULT now(),
  window_duration   INT NOT NULL DEFAULT 60,                 -- Window in seconds
  max_requests      INT NOT NULL DEFAULT 100,                -- Max requests per window
  
  CONSTRAINT rate_limit_unique UNIQUE (identifier, identifier_type, endpoint, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_lookup ON rate_limits (identifier, identifier_type, endpoint);

-- Function to check and increment rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'user_id',
  p_endpoint TEXT DEFAULT '*',
  p_max_requests INT DEFAULT 100,
  p_window_seconds INT DEFAULT 60
) RETURNS TABLE (
  allowed BOOLEAN,
  remaining INT,
  reset_at TIMESTAMPTZ
) AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_count INT;
  v_reset_at TIMESTAMPTZ;
BEGIN
  v_window_start := date_trunc('second', now() - (mod(extract(epoch from now())::int, p_window_seconds) || ' seconds')::interval);
  v_reset_at := v_window_start + (p_window_seconds || ' seconds')::interval;

  SELECT request_count INTO v_count
  FROM rate_limits
  WHERE identifier = p_identifier
    AND identifier_type = p_identifier_type
    AND endpoint = p_endpoint
    AND window_start = v_window_start;

  IF NOT FOUND THEN
    INSERT INTO rate_limits (identifier, identifier_type, endpoint, request_count, window_start, window_duration, max_requests)
    VALUES (p_identifier, p_identifier_type, p_endpoint, 1, v_window_start, p_window_seconds, p_max_requests);
    
    RETURN QUERY SELECT true, p_max_requests - 1, v_reset_at;
    RETURN;
  END IF;

  IF v_count >= p_max_requests THEN
    RETURN QUERY SELECT false, 0, v_reset_at;
    RETURN;
  END IF;

  UPDATE rate_limits
  SET request_count = request_count + 1
  WHERE identifier = p_identifier
    AND identifier_type = p_identifier_type
    AND endpoint = p_endpoint
    AND window_start = v_window_start;

  RETURN QUERY SELECT true, p_max_requests - v_count - 1, v_reset_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════════════════
-- FEATURE FLAGS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS feature_flags (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT NOT NULL UNIQUE,                     -- e.g. 'ai_question_gen_v2'
  description       TEXT,
  is_enabled        BOOLEAN NOT NULL DEFAULT false,
  
  -- Targeting rules
  target_roles      TEXT[] DEFAULT '{}',                      -- Empty = all roles
  target_school_ids UUID[] DEFAULT '{}',                      -- Empty = all schools
  rollout_percentage INT DEFAULT 0,                           -- 0-100, 0 = disabled, 100 = all users
  
  -- Metadata
  created_by        UUID,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Function to check if a feature flag is enabled for a user
CREATE OR REPLACE FUNCTION is_feature_enabled(
  p_flag_name TEXT,
  p_user_id UUID DEFAULT NULL,
  p_role TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_flag RECORD;
BEGIN
  SELECT * INTO v_flag FROM feature_flags WHERE name = p_flag_name;

  IF NOT FOUND THEN
    RETURN false;  -- Unknown flags are disabled
  END IF;

  IF NOT v_flag.is_enabled THEN
    RETURN false;
  END IF;

  -- Check role targeting
  IF array_length(v_flag.target_roles, 1) > 0 AND p_role IS NOT NULL THEN
    IF NOT p_role = ANY(v_flag.target_roles) THEN
      RETURN false;
    END IF;
  END IF;

  -- Check school targeting
  IF array_length(v_flag.target_school_ids, 1) > 0 AND p_user_id IS NOT NULL THEN
    DECLARE
      v_school_id UUID;
    BEGIN
      SELECT school_id INTO v_school_id FROM users WHERE id = p_user_id;
      IF v_school_id IS NOT NULL AND NOT v_school_id = ANY(v_flag.target_school_ids) THEN
        RETURN false;
      END IF;
    END;
  END IF;

  -- Check rollout percentage (hash-based for consistency)
  IF v_flag.rollout_percentage < 100 THEN
    IF p_user_id IS NOT NULL THEN
      DECLARE
        v_hash INT;
      BEGIN
        -- Simple hash of user_id for deterministic rollout
        v_hash := abs(('x' || md5(p_user_id::text))::bit(32)::int);
        IF (v_hash % 100) >= v_flag.rollout_percentage THEN
          RETURN false;
        END IF;
      END;
    ELSE
      RETURN false;
    END IF;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Seed essential feature flags
INSERT INTO feature_flags (name, description, is_enabled, rollout_percentage) VALUES
  ('ai_question_generation', 'AI-powered question generation', true, 100),
  ('ai_exam_coach', 'AI exam coaching and study plans', true, 100),
  ('marketplace', 'Marketplace for educational resources', true, 100),
  ('parent_portal', 'Parent portal access', true, 100),
  ('offline_mode', 'Offline exam mode with sync', true, 100),
  ('enhanced_analytics', 'Advanced analytics dashboard', false, 0),
  ('ai_grading_v2', 'Improved AI grading engine', false, 10)
ON CONFLICT (name) DO NOTHING;

-- ════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE app_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- Health checks: super_admin read only
CREATE POLICY "Super admins can read health checks" ON app_health_checks
  FOR SELECT TO authenticated
  USING (get_user_role() = 'super_admin');
CREATE POLICY "Service role can insert health checks" ON app_health_checks
  FOR INSERT TO service_role WITH CHECK (true);

-- Metrics: super_admin read, service_role insert
CREATE POLICY "Super admins can read metrics" ON performance_metrics
  FOR SELECT TO authenticated
  USING (get_user_role() = 'super_admin');
CREATE POLICY "Service role can insert metrics" ON performance_metrics
  FOR INSERT TO service_role WITH CHECK (true);

-- Rate limits: service_role only
CREATE POLICY "Service role can manage rate limits" ON rate_limits
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Feature flags: anyone can read enabled flags
CREATE POLICY "Authenticated users can read feature flags" ON feature_flags
  FOR SELECT TO authenticated
  USING (is_enabled = true);
CREATE POLICY "Super admins can manage feature flags" ON feature_flags
  FOR ALL TO authenticated
  USING (get_user_role() = 'super_admin');

COMMIT;
