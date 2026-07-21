-- ============================================================================
-- ExamForge AI — Database Optimization & Monitoring Migration
-- ============================================================================
-- Adds infrastructure for:
--   1. Connection pool monitoring
--   2. Slow query logging table
--   3. Query performance optimization indexes
--   4. Connection health check function
--   5. Prepared statement optimization
--   6. Database health monitoring views
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- SLOW QUERY LOG TABLE
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS slow_query_log (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query_type            TEXT NOT NULL,                        -- 'select', 'insert', 'update', 'delete', 'rpc'
  table_name            TEXT NOT NULL,
  operation             TEXT,                                  -- Application-level operation name
  duration_ms           INT NOT NULL,
  threshold_ms          INT NOT NULL DEFAULT 500,
  details               JSONB NOT NULL DEFAULT '{}',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_slow_query_duration CHECK (duration_ms > 0)
);

COMMENT ON TABLE slow_query_log IS 'Log of database queries that exceeded the slow query threshold. Used for performance optimization.';

CREATE INDEX IF NOT EXISTS idx_slow_query_created_at
  ON slow_query_log (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_slow_query_table
  ON slow_query_log (table_name);

CREATE INDEX IF NOT EXISTS idx_slow_query_duration
  ON slow_query_log (duration_ms DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- DATABASE HEALTH CHECK FUNCTION
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION check_database_health()
RETURNS TABLE(
  is_healthy BOOLEAN,
  active_connections INT,
  total_connections INT,
  max_connections INT,
  cache_hit_ratio NUMERIC,
  slow_queries_last_hour INT,
  database_size_mb NUMERIC
) AS $$
DECLARE
  v_cache_hit_ratio NUMERIC;
  v_slow_queries INT;
  v_db_size NUMERIC;
BEGIN
  -- Cache hit ratio (should be > 99% for healthy DB)
  SELECT COALESCE(
    SUM(heap_blks_hit)::numeric / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0) * 100,
    0
  ) INTO v_cache_hit_ratio
  FROM pg_statio_user_tables;

  -- Slow queries in the last hour
  SELECT COUNT(*) INTO v_slow_queries
  FROM slow_query_log
  WHERE created_at > now() - interval '1 hour';

  -- Database size in MB
  SELECT pg_database_size(current_database()) / 1024.0 / 1024.0 INTO v_db_size;

  RETURN QUERY SELECT
    v_cache_hit_ratio > 95.0 AS is_healthy,
    (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') AS active_connections,
    (SELECT count(*) FROM pg_stat_activity) AS total_connections,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
    COALESCE(ROUND(v_cache_hit_ratio, 2), 0) AS cache_hit_ratio,
    v_slow_queries AS slow_queries_last_hour,
    ROUND(v_db_size, 2) AS database_size_mb;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_database_health IS 'Returns database health metrics including connection counts, cache hit ratio, and slow query count.';

-- ════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE OPTIMIZATION INDEXES
-- ════════════════════════════════════════════════════════════════════════════
-- These indexes target the most common and performance-critical queries.

-- Transactions: lookup by tx_ref (used in webhook processing)
CREATE INDEX IF NOT EXISTS idx_transactions_tx_ref
  ON transactions (flutterwave_tx_ref)
  WHERE flutterwave_tx_ref IS NOT NULL;

-- Transactions: lookup by status (used in dashboard queries)
CREATE INDEX IF NOT EXISTS idx_transactions_status
  ON transactions (status)
  WHERE status IN ('pending', 'successful');

-- Transactions: school-scoped queries
CREATE INDEX IF NOT EXISTS idx_transactions_school_status
  ON transactions (school_id, status)
  WHERE school_id IS NOT NULL;

-- Subscriptions: active subscriptions lookup
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_active
  ON subscriptions (user_id, status)
  WHERE status IN ('active', 'trialing');

-- AI Credits: balance lookup
CREATE INDEX IF NOT EXISTS idx_ai_credits_user
  ON ai_credits (user_id)
  WHERE balance > 0;

-- Marketplace products: published products search
CREATE INDEX IF NOT EXISTS idx_marketplace_products_published
  ON marketplace_products (status, created_at DESC)
  WHERE status = 'published';

-- Marketplace purchases: user's purchases
CREATE INDEX IF NOT EXISTS idx_marketplace_purchases_buyer
  ON marketplace_purchases (buyer_id, status)
  WHERE status = 'completed';

-- Questions: bank lookup by subject and class
CREATE INDEX IF NOT EXISTS idx_questions_subject_class
  ON questions (subject_id, class_level, created_at DESC);

-- Exam sessions: active sessions for a student
CREATE INDEX IF NOT EXISTS idx_exam_sessions_student_active
  ON exam_sessions (student_id, status)
  WHERE status IN ('in_progress', 'paused');

-- ════════════════════════════════════════════════════════════════════════════
-- SLOW QUERY MONITORING VIEW
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW slow_query_summary AS
SELECT
  table_name,
  query_type,
  COUNT(*) AS total_slow_queries,
  AVG(duration_ms)::int AS avg_duration_ms,
  MAX(duration_ms) AS max_duration_ms,
  MIN(duration_ms) AS min_duration_ms,
  MAX(created_at) AS last_occurrence
FROM slow_query_log
WHERE created_at > now() - interval '24 hours'
GROUP BY table_name, query_type
ORDER BY total_slow_queries DESC;

COMMENT ON VIEW slow_query_summary IS 'Summary of slow queries in the last 24 hours, grouped by table and query type.';

-- ════════════════════════════════════════════════════════════════════════════
-- CONNECTION LEAK DETECTION VIEW
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW connection_health AS
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  now() - query_start AS duration,
  LEFT(query, 100) AS query_preview
FROM pg_stat_activity
WHERE state = 'active'
  AND usename = current_user
  AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC;

COMMENT ON VIEW connection_health IS 'Active database connections with duration. Long-running queries may indicate connection leaks.';

-- ════════════════════════════════════════════════════════════════════════════
-- RLS FOR SLOW QUERY LOG
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE slow_query_log ENABLE ROW LEVEL SECURITY;

-- Only super_admin and service_role can read slow query logs
CREATE POLICY "Service role can insert slow query logs"
  ON slow_query_log FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "Super admins can read slow query logs"
  ON slow_query_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'super_admin'
    )
  );

COMMIT;
