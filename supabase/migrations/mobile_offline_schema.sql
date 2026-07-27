-- ============================================================================
-- ExamForge AI - Mobile Experience, PWA & Offline-First Architecture
-- ============================================================================
-- Production-ready schema extension for mobile offline-first support,
-- synchronization, push notifications, device management, and monitoring.
--
-- Prerequisites:
--   Existing tables: schools, users (with user_role enum)
--   Existing enums:  user_role (super_admin, school_admin, teacher, student)
--
-- This migration EXTENDS the existing database with:
--   - Device registration & push notification management
--   - Offline-first sync engine (metadata, queue, conflicts, logs)
--   - Offline cache tracking
--   - Offline exam configuration & attempts
--   - Connectivity analytics
--   - File download management for offline access
--   - App analytics & crash reporting
--   - PWA install tracking
--
-- Performance: Composite indexes for common query patterns,
--              GIN indexes for JSONB/array columns,
--              partial indexes for status-filtered queries,
--              partitioning-ready layout for high-volume tables.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. NEW ENUMERATION TYPES
-- ============================================================================
-- All new enums required by the mobile/offline architecture.
-- Uses IF NOT EXISTS pattern to ensure idempotent migrations.
-- ============================================================================

DO $$
BEGIN
  -- -------------------------------------------------------------------------
  -- mobile_platform: Target mobile platforms
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mobile_platform') THEN
    CREATE TYPE mobile_platform AS ENUM (
      'android',
      'ios',
      'web'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- sync_operation_type: Types of sync operations queued for processing
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_operation_type') THEN
    CREATE TYPE sync_operation_type AS ENUM (
      'insert',
      'update',
      'delete'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- sync_queue_status: Lifecycle states for a sync queue item
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_queue_status') THEN
    CREATE TYPE sync_queue_status AS ENUM (
      'pending',
      'in_progress',
      'completed',
      'failed',
      'dead'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- sync_log_type: Categories of sync operations
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_log_type') THEN
    CREATE TYPE sync_log_type AS ENUM (
      'full',
      'incremental',
      'push',
      'pull'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- connection_quality: Network connection quality tiers
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'connection_quality') THEN
    CREATE TYPE connection_quality AS ENUM (
      'excellent',
      'good',
      'limited',
      'offline'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- connection_type: Physical connection medium
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'connection_type') THEN
    CREATE TYPE connection_type AS ENUM (
      'wifi',
      'mobile',
      'ethernet',
      'none'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- conflict_resolution: How a sync conflict was resolved
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'conflict_resolution') THEN
    CREATE TYPE conflict_resolution AS ENUM (
      'pending',
      'local_wins',
      'server_wins',
      'merge',
      'manual'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- offline_type: Types of offline exam modes
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'offline_type') THEN
    CREATE TYPE offline_type AS ENUM (
      'practice',
      'mock',
      'none'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- offline_attempt_sync_status: Sync states for offline exam attempts
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'offline_attempt_sync_status') THEN
    CREATE TYPE offline_attempt_sync_status AS ENUM (
      'pending',
      'synced',
      'validated',
      'rejected'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- download_status: File download lifecycle states
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'download_status') THEN
    CREATE TYPE download_status AS ENUM (
      'pending',
      'downloading',
      'completed',
      'failed',
      'expired'
    );
  END IF;

  -- -------------------------------------------------------------------------
  -- sync_log_status: Outcome of a sync operation
  -- -------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_log_status') THEN
    CREATE TYPE sync_log_status AS ENUM (
      'success',
      'partial',
      'failed'
    );
  END IF;
END
$$;

-- ============================================================================
-- 2. HELPER FUNCTION: set_updated_at
-- ============================================================================
-- Reusable trigger function that sets updated_at = now() on any row update.
-- Applied to every table with an updated_at column.
-- ============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_updated_at() IS
  'Generic trigger function: sets updated_at = now() on row update';

-- ============================================================================
-- 3. HELPER FUNCTION: is_super_admin
-- ============================================================================
-- Checks whether the currently authenticated user has the super_admin role.
-- Used throughout RLS policies to grant full access.
-- ============================================================================

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND role = 'super_admin'
      AND is_active = true
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION is_super_admin() IS
  'Returns true if the current authenticated user is an active super_admin';

-- ============================================================================
-- 4. HELPER FUNCTION: is_school_admin
-- ============================================================================
-- Checks whether the current user is a school_admin, optionally for a
-- specific school_id.
-- ============================================================================

CREATE OR REPLACE FUNCTION is_school_admin(check_school_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND role = 'school_admin'
      AND is_active = true
      AND (check_school_id IS NULL OR school_id = check_school_id)
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION is_school_admin(UUID) IS
  'Returns true if the current user is a school_admin (optionally for a specific school)';

-- ============================================================================
-- 5. HELPER FUNCTION: user_school_id
-- ============================================================================
-- Returns the school_id of the currently authenticated user.
-- ============================================================================

CREATE OR REPLACE FUNCTION user_school_id()
RETURNS UUID AS $$
  SELECT school_id FROM users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION user_school_id() IS
  'Returns the school_id of the currently authenticated user';

-- ============================================================================
-- 6. TABLE: device_registrations
-- ============================================================================
-- Track user devices for push notifications and session management.
-- Supports multi-device scenarios (a user may have phone + tablet + PWA).
-- ============================================================================

CREATE TABLE IF NOT EXISTS device_registrations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_token          TEXT NOT NULL,                        -- Platform-specific device identifier
  platform              mobile_platform NOT NULL DEFAULT 'web',
  device_name           TEXT,                                 -- e.g. "Galaxy S24 Ultra"
  device_model          TEXT,                                 -- e.g. "SM-S928B"
  os_version            TEXT,                                 -- e.g. "Android 14", "iOS 17.2"
  app_version           TEXT,                                 -- e.g. "2.4.1"
  is_active             BOOLEAN DEFAULT true,
  last_active_at        TIMESTAMPTZ DEFAULT now(),
  push_enabled          BOOLEAN DEFAULT true,
  push_notification_topics TEXT[] DEFAULT '{}',               -- FCM topic subscriptions
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- A user cannot register the same device token twice
  CONSTRAINT uq_device_registrations_user_token UNIQUE (user_id, device_token)
);

COMMENT ON TABLE device_registrations IS
  'Registered user devices for push notifications, session tracking, and multi-device support';
COMMENT ON COLUMN device_registrations.device_token IS 'Platform-specific device identifier (FCM registration token, APNs device token, or web push subscription endpoint)';
COMMENT ON COLUMN device_registrations.push_notification_topics IS 'Array of FCM/APNs topic subscriptions for targeted notification delivery';

-- Indexes for device_registrations
CREATE INDEX IF NOT EXISTS idx_device_registrations_user_id
  ON device_registrations (user_id);
CREATE INDEX IF NOT EXISTS idx_device_registrations_platform
  ON device_registrations (platform);
CREATE INDEX IF NOT EXISTS idx_device_registrations_active
  ON device_registrations (user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_device_registrations_last_active
  ON device_registrations (last_active_at DESC);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_device_registrations_updated_at ON device_registrations;
CREATE TRIGGER trg_device_registrations_updated_at
  BEFORE UPDATE ON device_registrations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 7. TABLE: push_notification_tokens
-- ============================================================================
-- Dedicated table for FCM/APNs push tokens, separate from device
-- registrations to allow token rotation without losing device context.
-- ============================================================================

CREATE TABLE IF NOT EXISTS push_notification_tokens (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token                 TEXT NOT NULL,                        -- FCM registration token or APNs device token
  platform              mobile_platform NOT NULL,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Each push token must be unique across the entire system
  CONSTRAINT uq_push_notification_tokens_token UNIQUE (token)
);

COMMENT ON TABLE push_notification_tokens IS
  'FCM/APNs push notification tokens, supporting token rotation and platform-specific routing';
COMMENT ON COLUMN push_notification_tokens.token IS 'The raw push notification token; unique globally to prevent duplicate deliveries';

-- Indexes for push_notification_tokens
CREATE INDEX IF NOT EXISTS idx_push_notification_tokens_user_id
  ON push_notification_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_push_notification_tokens_active
  ON push_notification_tokens (user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_push_notification_tokens_platform
  ON push_notification_tokens (platform);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_push_notification_tokens_updated_at ON push_notification_tokens;
CREATE TRIGGER trg_push_notification_tokens_updated_at
  BEFORE UPDATE ON push_notification_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 8. TABLE: sync_metadata
-- ============================================================================
-- Track synchronization state per user per table.
-- Each row represents the last known sync state for a specific user + table
-- combination, enabling incremental sync cursors and checksum verification.
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_metadata (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  table_name            TEXT NOT NULL,                        -- e.g. "exams", "question_bank"
  last_synced_at        TIMESTAMPTZ,                          -- Timestamp of last successful sync
  sync_cursor           TEXT,                                 -- Opaque cursor for incremental sync
  record_count          INTEGER DEFAULT 0,                    -- Number of records synced
  checksum              TEXT,                                 -- MD5/SHA256 of synced data for integrity
  is_full_sync          BOOLEAN DEFAULT false,                -- Whether a full sync has been completed
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- A user can only have one sync state per table
  CONSTRAINT uq_sync_metadata_user_table UNIQUE (user_id, table_name)
);

COMMENT ON TABLE sync_metadata IS
  'Per-user, per-table synchronization state, enabling incremental sync and integrity verification';
COMMENT ON COLUMN sync_metadata.sync_cursor IS 'Opaque cursor value returned by the server for incremental sync pagination';
COMMENT ON COLUMN sync_metadata.checksum IS 'Hash of synced data for client-server integrity verification';

-- Indexes for sync_metadata
CREATE INDEX IF NOT EXISTS idx_sync_metadata_user_id
  ON sync_metadata (user_id);
CREATE INDEX IF NOT EXISTS idx_sync_metadata_table_name
  ON sync_metadata (table_name);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_sync_metadata_updated_at ON sync_metadata;
CREATE TRIGGER trg_sync_metadata_updated_at
  BEFORE UPDATE ON sync_metadata
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 9. TABLE: sync_queue
-- ============================================================================
-- Queue of pending mutations created while offline.
-- The client enqueues operations when offline; the sync engine processes
-- them when connectivity is restored, respecting priority ordering.
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_queue (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  table_name            TEXT NOT NULL,                        -- Target table for the mutation
  record_id             TEXT,                                 -- Primary key of the affected record
  operation             sync_operation_type NOT NULL,         -- insert / update / delete
  payload               JSONB NOT NULL,                       -- The mutation data (full row or diff)
  priority              INTEGER DEFAULT 5,                    -- 1 = critical, 5 = normal, 10 = low
  attempts              INTEGER DEFAULT 0,                    -- Number of processing attempts
  max_attempts          INTEGER DEFAULT 5,                    -- Max retries before marking dead
  last_attempt_at       TIMESTAMPTZ,                          -- Timestamp of most recent attempt
  next_retry_at         TIMESTAMPTZ DEFAULT now(),            -- When to retry next (exponential backoff)
  status                sync_queue_status DEFAULT 'pending',
  error_message         TEXT,                                 -- Last error encountered during processing
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate priority range
  CONSTRAINT chk_sync_queue_priority CHECK (priority >= 1 AND priority <= 10),
  -- Validate attempts are non-negative
  CONSTRAINT chk_sync_queue_attempts CHECK (attempts >= 0),
  -- Prevent excessive retry configurations
  CONSTRAINT chk_sync_queue_max_attempts CHECK (max_attempts >= 1 AND max_attempts <= 20)
);

COMMENT ON TABLE sync_queue IS
  'Pending mutation queue for offline-first sync; processed in priority order when online';
COMMENT ON COLUMN sync_queue.priority IS 'Processing priority: 1 = critical (exam submissions), 5 = normal, 10 = low (analytics)';
COMMENT ON COLUMN sync_queue.payload IS 'Full row data for inserts, diff for updates, or empty for deletes';
COMMENT ON COLUMN sync_queue.next_retry_at IS 'Earliest time to retry; supports exponential backoff strategies';

-- Indexes for sync_queue (optimized for the processing query pattern)
CREATE INDEX IF NOT EXISTS idx_sync_queue_user_id
  ON sync_queue (user_id);
CREATE INDEX IF NOT EXISTS idx_sync_queue_status
  ON sync_queue (status);
CREATE INDEX IF NOT EXISTS idx_sync_queue_priority
  ON sync_queue (priority ASC);
CREATE INDEX IF NOT EXISTS idx_sync_queue_next_retry
  ON sync_queue (next_retry_at);
-- Composite index for the primary processing query: find pending items for a user
CREATE INDEX IF NOT EXISTS idx_sync_queue_process
  ON sync_queue (user_id, status, priority ASC, next_retry_at)
  WHERE status IN ('pending', 'failed');
-- GIN index for JSONB payload queries
CREATE INDEX IF NOT EXISTS idx_sync_queue_payload
  ON sync_queue USING GIN (payload jsonb_path_ops);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_sync_queue_updated_at ON sync_queue;
CREATE TRIGGER trg_sync_queue_updated_at
  BEFORE UPDATE ON sync_queue
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 10. TABLE: sync_conflicts
-- ============================================================================
-- Detected sync conflicts requiring resolution.
-- When both client and server modify the same record, a conflict is logged
-- here for manual or automated resolution.
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_conflicts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  table_name            TEXT NOT NULL,
  record_id             TEXT NOT NULL,
  local_data            JSONB NOT NULL,                       -- Client-side version of the record
  server_data           JSONB NOT NULL,                       -- Server-side version of the record
  resolution            conflict_resolution DEFAULT 'pending',
  resolved_data         JSONB,                                -- Merged/selected data after resolution
  resolved_by           UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Ensure resolution is set when resolved_data is provided
  CONSTRAINT chk_sync_conflicts_resolution CHECK (
    resolution = 'pending' OR resolved_at IS NOT NULL
  )
);

COMMENT ON TABLE sync_conflicts IS
  'Detected sync conflicts between local and server data, requiring resolution';
COMMENT ON COLUMN sync_conflicts.local_data IS 'The client-side version of the conflicting record';
COMMENT ON COLUMN sync_conflicts.server_data IS 'The server-side version of the conflicting record';
COMMENT ON COLUMN sync_conflicts.resolution IS 'How the conflict was resolved: pending, local_wins, server_wins, merge, or manual';
COMMENT ON COLUMN sync_conflicts.resolved_data IS 'The final merged/selected data after resolution';

-- Indexes for sync_conflicts
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_user_id
  ON sync_conflicts (user_id);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_resolution
  ON sync_conflicts (resolution);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_pending
  ON sync_conflicts (user_id, created_at DESC)
  WHERE resolution = 'pending';
-- GIN indexes for JSONB conflict data
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_local_data
  ON sync_conflicts USING GIN (local_data jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_server_data
  ON sync_conflicts USING GIN (server_data jsonb_path_ops);

-- ============================================================================
-- 11. TABLE: sync_logs
-- ============================================================================
-- Sync operation logs for monitoring, debugging, and analytics.
-- Each row represents a single sync session (full/incremental/push/pull).
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_logs (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE SET NULL,
  device_id             TEXT,                                 -- Device identifier from device_registrations
  sync_type             sync_log_type NOT NULL,               -- full / incremental / push / pull
  tables_synced         TEXT[] DEFAULT '{}',                  -- List of tables involved in this sync
  records_pushed        INTEGER DEFAULT 0,
  records_pulled        INTEGER DEFAULT 0,
  conflicts_count       INTEGER DEFAULT 0,
  errors_count          INTEGER DEFAULT 0,
  duration_ms           INTEGER,                              -- Total sync duration in milliseconds
  connection_quality    connection_quality,                   -- Network quality during sync
  status                sync_log_status NOT NULL,             -- success / partial / failed
  error_details         JSONB,                                -- Structured error information
  started_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate non-negative counters
  CONSTRAINT chk_sync_logs_records_pushed CHECK (records_pushed >= 0),
  CONSTRAINT chk_sync_logs_records_pulled CHECK (records_pulled >= 0),
  CONSTRAINT chk_sync_logs_conflicts CHECK (conflicts_count >= 0),
  CONSTRAINT chk_sync_logs_errors CHECK (errors_count >= 0),
  CONSTRAINT chk_sync_logs_duration CHECK (duration_ms IS NULL OR duration_ms >= 0)
);

COMMENT ON TABLE sync_logs IS
  'Sync operation logs for monitoring, debugging, and performance analytics';
COMMENT ON COLUMN sync_logs.sync_type IS 'Type of sync: full (complete re-sync), incremental (cursor-based), push (upload only), pull (download only)';
COMMENT ON COLUMN sync_logs.connection_quality IS 'Network quality at the time of sync, used for adaptive sync strategies';

-- Indexes for sync_logs
CREATE INDEX IF NOT EXISTS idx_sync_logs_user_id
  ON sync_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_status
  ON sync_logs (status);
CREATE INDEX IF NOT EXISTS idx_sync_logs_started_at
  ON sync_logs (started_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_logs_user_started
  ON sync_logs (user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_logs_sync_type
  ON sync_logs (sync_type);
-- GIN index for error_details queries
CREATE INDEX IF NOT EXISTS idx_sync_logs_error_details
  ON sync_logs USING GIN (error_details jsonb_path_ops);

-- ============================================================================
-- 12. TABLE: offline_cache_metadata
-- ============================================================================
-- Track locally cached resources and their validity.
-- Enables the client to determine which cached resources are stale and
-- need refreshing, and supports cache eviction based on expiry and size.
-- ============================================================================

CREATE TABLE IF NOT EXISTS offline_cache_metadata (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  resource_type         TEXT NOT NULL,                        -- e.g. "exam", "question_bank", "media"
  resource_id           TEXT NOT NULL,                        -- PK of the cached resource
  cache_key             TEXT NOT NULL,                        -- Unique cache identifier (for lookup)
  version               INTEGER DEFAULT 1,                   -- Cache version for invalidation
  expires_at            TIMESTAMPTZ,                          -- When this cache entry becomes stale
  file_size_bytes       INTEGER,                              -- Size of the cached resource
  checksum              TEXT,                                 -- Integrity hash of the cached content
  is_encrypted          BOOLEAN DEFAULT false,                -- Whether the cached data is encrypted
  access_count          INTEGER DEFAULT 0,                    -- Number of times accessed (for LRU eviction)
  last_accessed_at      TIMESTAMPTZ DEFAULT now(),
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Each user can only have one cache entry per key
  CONSTRAINT uq_offline_cache_user_key UNIQUE (user_id, cache_key),
  -- Validate non-negative values
  CONSTRAINT chk_offline_cache_version CHECK (version >= 1),
  CONSTRAINT chk_offline_cache_access_count CHECK (access_count >= 0),
  CONSTRAINT chk_offline_cache_file_size CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0)
);

COMMENT ON TABLE offline_cache_metadata IS
  'Locally cached resource metadata for offline access, with expiry and integrity tracking';
COMMENT ON COLUMN offline_cache_metadata.cache_key IS 'Unique cache key combining resource type and ID for client-side lookup';
COMMENT ON COLUMN offline_cache_metadata.expires_at IS 'When this cache entry becomes stale and should be refreshed';
COMMENT ON COLUMN offline_cache_metadata.is_encrypted IS 'Whether the cached content is encrypted at rest on the device';

-- Indexes for offline_cache_metadata
CREATE INDEX IF NOT EXISTS idx_offline_cache_user_id
  ON offline_cache_metadata (user_id);
CREATE INDEX IF NOT EXISTS idx_offline_cache_resource_type
  ON offline_cache_metadata (resource_type);
CREATE INDEX IF NOT EXISTS idx_offline_cache_expires_at
  ON offline_cache_metadata (expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_offline_cache_last_accessed
  ON offline_cache_metadata (user_id, last_accessed_at DESC);

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_offline_cache_metadata_updated_at ON offline_cache_metadata;
CREATE TRIGGER trg_offline_cache_metadata_updated_at
  BEFORE UPDATE ON offline_cache_metadata
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 13. TABLE: offline_exam_config
-- ============================================================================
-- Schools can configure which exams support offline mode.
-- This is per-exam configuration that controls offline behavior, integrity
-- requirements, and submission policies.
-- ============================================================================

CREATE TABLE IF NOT EXISTS offline_exam_config (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id                       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  exam_id                         UUID,                                 -- FK to exams table (soft reference)
  allows_offline                  BOOLEAN DEFAULT false,
  offline_type                    offline_type DEFAULT 'none',
  max_offline_attempts            INTEGER DEFAULT 3,
  requires_online_submission      BOOLEAN DEFAULT true,                -- Must verify online before accepting
  integrity_hash                  TEXT,                                 -- Hash of exam config for tamper detection
  auto_submit_on_reconnect        BOOLEAN DEFAULT true,                -- Auto-submit when connectivity restored
  created_at                      TIMESTAMPTZ DEFAULT now(),
  updated_at                      TIMESTAMPTZ DEFAULT now(),

  -- Validate offline attempts
  CONSTRAINT chk_offline_exam_max_attempts CHECK (max_offline_attempts >= 1 AND max_offline_attempts <= 10)
);

COMMENT ON TABLE offline_exam_config IS
  'Per-exam offline mode configuration set by school administrators';
COMMENT ON COLUMN offline_exam_config.offline_type IS 'Type of offline exam: practice (low stakes), mock (medium stakes), none (online only)';
COMMENT ON COLUMN offline_exam_config.integrity_hash IS 'SHA256 hash of exam configuration to detect client-side tampering';
COMMENT ON COLUMN offline_exam_config.auto_submit_on_reconnect IS 'Whether to automatically submit the exam when the device reconnects to the internet';

-- Indexes for offline_exam_config
CREATE INDEX IF NOT EXISTS idx_offline_exam_config_school_id
  ON offline_exam_config (school_id);
CREATE INDEX IF NOT EXISTS idx_offline_exam_config_exam_id
  ON offline_exam_config (exam_id);
CREATE INDEX IF NOT EXISTS idx_offline_exam_config_allows_offline
  ON offline_exam_config (school_id, allows_offline) WHERE allows_offline = true;

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_offline_exam_config_updated_at ON offline_exam_config;
CREATE TRIGGER trg_offline_exam_config_updated_at
  BEFORE UPDATE ON offline_exam_config
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 14. TABLE: offline_exam_attempts
-- ============================================================================
-- Offline exam attempts pending sync with the server.
-- Created when a student completes an exam while offline; synced and
-- validated when connectivity is restored.
-- ============================================================================

CREATE TABLE IF NOT EXISTS offline_exam_attempts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id               UUID NOT NULL,                         -- FK to exams table (soft reference)
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id             UUID REFERENCES schools(id) ON DELETE SET NULL,
  attempt_data          JSONB NOT NULL,                        -- Full attempt metadata (timing, navigation, etc.)
  answers               JSONB NOT NULL,                        -- Student's answers keyed by question ID
  started_at            TIMESTAMPTZ NOT NULL,
  completed_at          TIMESTAMPTZ,
  time_taken_seconds    INTEGER,                               -- Total time spent on the exam
  integrity_hash        TEXT,                                  -- Hash of answers for tamper detection
  device_info           JSONB,                                 -- Device snapshot at attempt time
  sync_status           offline_attempt_sync_status DEFAULT 'pending',
  sync_attempts         INTEGER DEFAULT 0,
  synced_at             TIMESTAMPTZ,
  validation_errors     JSONB,                                 -- Server-side validation issues
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate sync attempts
  CONSTRAINT chk_offline_exam_sync_attempts CHECK (sync_attempts >= 0),
  -- Validate time_taken
  CONSTRAINT chk_offline_exam_time_taken CHECK (time_taken_seconds IS NULL OR time_taken_seconds >= 0)
);

COMMENT ON TABLE offline_exam_attempts IS
  'Offline exam attempts pending synchronization, with integrity verification';
COMMENT ON COLUMN offline_exam_attempts.attempt_data IS 'Full attempt context: timing per question, navigation events, tab switches, etc.';
COMMENT ON COLUMN offline_exam_attempts.answers IS 'Student answers keyed by question ID; format depends on question type';
COMMENT ON COLUMN offline_exam_attempts.integrity_hash IS 'SHA256 hash of answers submitted at completion time for tamper detection';
COMMENT ON COLUMN offline_exam_attempts.sync_status IS 'pending = awaiting sync, synced = uploaded, validated = server-verified, rejected = failed validation';

-- Indexes for offline_exam_attempts
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_student_id
  ON offline_exam_attempts (student_id);
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_sync_status
  ON offline_exam_attempts (sync_status);
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_exam_id
  ON offline_exam_attempts (exam_id);
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_pending
  ON offline_exam_attempts (student_id, sync_status, created_at DESC)
  WHERE sync_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_school_id
  ON offline_exam_attempts (school_id);
-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_answers
  ON offline_exam_attempts USING GIN (answers jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_offline_exam_attempts_attempt_data
  ON offline_exam_attempts USING GIN (attempt_data jsonb_path_ops);

-- ============================================================================
-- 15. TABLE: connectivity_analytics
-- ============================================================================
-- Track connection quality per user/device over time.
-- Used for adaptive sync strategies, UX decisions (e.g., pre-caching
-- when connection is good), and analytics dashboards.
-- ============================================================================

CREATE TABLE IF NOT EXISTS connectivity_analytics (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   UUID REFERENCES users(id) ON DELETE SET NULL,
  device_id                 TEXT,                              -- Device identifier
  connection_type           connection_type,                   -- wifi / mobile / ethernet / none
  connection_quality        connection_quality,                -- excellent / good / limited / offline
  avg_latency_ms            INTEGER,                           -- Average round-trip latency
  bandwidth_estimate_kbps   INTEGER,                           -- Estimated downstream bandwidth
  was_offline               BOOLEAN,                           -- Whether the user went offline
  offline_duration_seconds  INTEGER,                           -- Duration of offline period
  recorded_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at                TIMESTAMPTZ DEFAULT now(),

  -- Validate non-negative values
  CONSTRAINT chk_connectivity_latency CHECK (avg_latency_ms IS NULL OR avg_latency_ms >= 0),
  CONSTRAINT chk_connectivity_bandwidth CHECK (bandwidth_estimate_kbps IS NULL OR bandwidth_estimate_kbps >= 0),
  CONSTRAINT chk_connectivity_offline_duration CHECK (offline_duration_seconds IS NULL OR offline_duration_seconds >= 0)
);

COMMENT ON TABLE connectivity_analytics IS
  'Network connectivity quality metrics per user/device for adaptive sync and analytics';
COMMENT ON COLUMN connectivity_analytics.was_offline IS 'Whether this event represents a transition to offline state';
COMMENT ON COLUMN connectivity_analytics.offline_duration_seconds IS 'Duration of the offline period (set when transitioning back online)';

-- Indexes for connectivity_analytics
CREATE INDEX IF NOT EXISTS idx_connectivity_analytics_user_id
  ON connectivity_analytics (user_id);
CREATE INDEX IF NOT EXISTS idx_connectivity_analytics_recorded_at
  ON connectivity_analytics (recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_connectivity_analytics_quality
  ON connectivity_analytics (connection_quality);
CREATE INDEX IF NOT EXISTS idx_connectivity_analytics_offline
  ON connectivity_analytics (user_id, was_offline, recorded_at DESC)
  WHERE was_offline = true;

-- ============================================================================
-- 16. TABLE: file_downloads
-- ============================================================================
-- Track user file downloads for offline access.
-- Manages the lifecycle of downloaded resources including licensing,
-- expiry, and access tracking.
-- ============================================================================

CREATE TABLE IF NOT EXISTS file_downloads (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  resource_type         TEXT NOT NULL,                        -- e.g. "exam_material", "question_image", "study_guide"
  resource_id           TEXT NOT NULL,                        -- PK of the source resource
  file_url              TEXT NOT NULL,                        -- Remote URL of the file
  file_name             TEXT NOT NULL,                        -- Original filename
  file_size_bytes       INTEGER,                              -- Size in bytes
  mime_type             TEXT,                                 -- e.g. "application/pdf", "image/png"
  local_path            TEXT,                                 -- Client-side local storage path
  download_status       download_status DEFAULT 'pending',
  license_expires_at    TIMESTAMPTZ,                          -- When the download license expires
  access_count          INTEGER DEFAULT 0,
  last_accessed_at      TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate non-negative values
  CONSTRAINT chk_file_downloads_access_count CHECK (access_count >= 0),
  CONSTRAINT chk_file_downloads_file_size CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0)
);

COMMENT ON TABLE file_downloads IS
  'User file downloads for offline access, with licensing, expiry, and access tracking';
COMMENT ON COLUMN file_downloads.license_expires_at IS 'When the download license expires; the client must re-download or renew';
COMMENT ON COLUMN file_downloads.local_path IS 'Client-side local storage path where the file is saved';

-- Indexes for file_downloads
CREATE INDEX IF NOT EXISTS idx_file_downloads_user_id
  ON file_downloads (user_id);
CREATE INDEX IF NOT EXISTS idx_file_downloads_status
  ON file_downloads (download_status);
CREATE INDEX IF NOT EXISTS idx_file_downloads_license_expires
  ON file_downloads (license_expires_at) WHERE license_expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_file_downloads_pending
  ON file_downloads (user_id, download_status, created_at DESC)
  WHERE download_status IN ('pending', 'downloading');

-- Trigger: auto-update updated_at
DROP TRIGGER IF EXISTS trg_file_downloads_updated_at ON file_downloads;
CREATE TRIGGER trg_file_downloads_updated_at
  BEFORE UPDATE ON file_downloads
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- 17. TABLE: app_analytics
-- ============================================================================
-- General app usage analytics for understanding user behavior,
-- feature adoption, and performance metrics.
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_analytics (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE SET NULL,
  device_id             TEXT,
  event_type            TEXT NOT NULL,                        -- e.g. "screen_view", "button_click", "exam_start"
  event_data            JSONB,                                -- Event-specific data payload
  session_id            TEXT,                                 -- Client-side session identifier
  app_version           TEXT,                                 -- App version at event time
  platform              mobile_platform,                      -- Platform at event time
  screen_name           TEXT,                                 -- Current screen/view name
  duration_ms           INTEGER,                              -- Duration of the event (e.g., screen view time)
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Validate duration
  CONSTRAINT chk_app_analytics_duration CHECK (duration_ms IS NULL OR duration_ms >= 0)
);

COMMENT ON TABLE app_analytics IS
  'App usage analytics for user behavior, feature adoption, and performance monitoring';
COMMENT ON COLUMN app_analytics.event_type IS 'Event category: screen_view, button_click, exam_start, exam_complete, feature_used, etc.';
COMMENT ON COLUMN app_analytics.session_id IS 'Client-side session identifier for grouping related events';

-- Indexes for app_analytics
CREATE INDEX IF NOT EXISTS idx_app_analytics_user_id
  ON app_analytics (user_id);
CREATE INDEX IF NOT EXISTS idx_app_analytics_event_type
  ON app_analytics (event_type);
CREATE INDEX IF NOT EXISTS idx_app_analytics_created_at
  ON app_analytics (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_analytics_user_event
  ON app_analytics (user_id, event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_analytics_session
  ON app_analytics (session_id);
-- GIN index for event_data queries
CREATE INDEX IF NOT EXISTS idx_app_analytics_event_data
  ON app_analytics USING GIN (event_data jsonb_path_ops);

-- ============================================================================
-- 18. TABLE: crash_reports
-- ============================================================================
-- Crash and error reporting for stability monitoring.
-- Supports stack trace capture, device context, and resolution tracking.
-- ============================================================================

CREATE TABLE IF NOT EXISTS crash_reports (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE SET NULL,
  device_id             TEXT,
  error_type            TEXT NOT NULL,                        -- e.g. "NullPointerException", "NetworkError"
  error_message         TEXT NOT NULL,
  stack_trace           TEXT,                                 -- Full stack trace or error log
  device_info           JSONB,                                -- Device state at crash time
  app_version           TEXT,
  platform              mobile_platform,
  is_resolved           BOOLEAN DEFAULT false,
  occurred_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE crash_reports IS
  'Crash and error reports for stability monitoring and resolution tracking';
COMMENT ON COLUMN crash_reports.error_type IS 'Exception or error class name, e.g. NullPointerException, NetworkError, TimeoutException';
COMMENT ON COLUMN crash_reports.is_resolved IS 'Whether a fix has been deployed that addresses this crash type';

-- Indexes for crash_reports
CREATE INDEX IF NOT EXISTS idx_crash_reports_is_resolved
  ON crash_reports (is_resolved) WHERE is_resolved = false;
CREATE INDEX IF NOT EXISTS idx_crash_reports_occurred_at
  ON crash_reports (occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_crash_reports_error_type
  ON crash_reports (error_type);
CREATE INDEX IF NOT EXISTS idx_crash_reports_unresolved
  ON crash_reports (is_resolved, occurred_at DESC) WHERE is_resolved = false;
CREATE INDEX IF NOT EXISTS idx_crash_reports_app_version
  ON crash_reports (app_version);
-- GIN index for device_info queries
CREATE INDEX IF NOT EXISTS idx_crash_reports_device_info
  ON crash_reports USING GIN (device_info jsonb_path_ops);

-- ============================================================================
-- 19. TABLE: pwa_install_events
-- ============================================================================
-- Track PWA installations for adoption metrics and re-engagement.
-- ============================================================================

CREATE TABLE IF NOT EXISTS pwa_install_events (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE SET NULL,
  platform              mobile_platform,                      -- Detected platform at install time
  browser               TEXT,                                 -- e.g. "Chrome 120", "Safari 17.2"
  installed_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active             BOOLEAN DEFAULT true,                 -- Whether the PWA is still installed
  last_opened_at        TIMESTAMPTZ,                          -- Last time the PWA was launched
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE pwa_install_events IS
  'PWA installation events for adoption tracking and re-engagement campaigns';
COMMENT ON COLUMN pwa_install_events.is_active IS 'Whether the PWA is still installed; set to false if uninstalled or stale';

-- Indexes for pwa_install_events
CREATE INDEX IF NOT EXISTS idx_pwa_install_events_user_id
  ON pwa_install_events (user_id);
CREATE INDEX IF NOT EXISTS idx_pwa_install_events_active
  ON pwa_install_events (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_pwa_install_events_installed_at
  ON pwa_install_events (installed_at DESC);

-- ============================================================================
-- 20. ROW LEVEL SECURITY
-- ============================================================================
-- RLS policies for all tables. General rules:
--   - Users can only see/modify their own data
--   - School admins can see data for users in their school
--   - Super admins can see all data
-- ============================================================================

-- ---------------------------------------------------------------------------
-- device_registrations
-- ---------------------------------------------------------------------------
ALTER TABLE device_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own devices"
  ON device_registrations FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own devices"
  ON device_registrations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own devices"
  ON device_registrations FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own devices"
  ON device_registrations FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "School admins can read school devices"
  ON device_registrations FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can read all devices"
  ON device_registrations FOR SELECT
  USING (is_super_admin());

CREATE POLICY "Super admins can manage all devices"
  ON device_registrations FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- push_notification_tokens
-- ---------------------------------------------------------------------------
ALTER TABLE push_notification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own push tokens"
  ON push_notification_tokens FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own push tokens"
  ON push_notification_tokens FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own push tokens"
  ON push_notification_tokens FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own push tokens"
  ON push_notification_tokens FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "School admins can read school push tokens"
  ON push_notification_tokens FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can manage all push tokens"
  ON push_notification_tokens FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- sync_metadata
-- ---------------------------------------------------------------------------
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sync metadata"
  ON sync_metadata FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync metadata"
  ON sync_metadata FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own sync metadata"
  ON sync_metadata FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own sync metadata"
  ON sync_metadata FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "School admins can read school sync metadata"
  ON sync_metadata FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can manage all sync metadata"
  ON sync_metadata FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- sync_queue
-- ---------------------------------------------------------------------------
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sync queue"
  ON sync_queue FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync queue items"
  ON sync_queue FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own sync queue items"
  ON sync_queue FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own sync queue items"
  ON sync_queue FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage all sync queue items"
  ON sync_queue FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- sync_conflicts
-- ---------------------------------------------------------------------------
ALTER TABLE sync_conflicts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sync conflicts"
  ON sync_conflicts FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync conflicts"
  ON sync_conflicts FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own sync conflicts"
  ON sync_conflicts FOR UPDATE
  USING (user_id = auth.uid() OR is_super_admin())
  WITH CHECK (user_id = auth.uid() OR is_super_admin());

CREATE POLICY "School admins can read school sync conflicts"
  ON sync_conflicts FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can manage all sync conflicts"
  ON sync_conflicts FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- sync_logs
-- ---------------------------------------------------------------------------
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sync logs"
  ON sync_logs FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync logs"
  ON sync_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "School admins can read school sync logs"
  ON sync_logs FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can manage all sync logs"
  ON sync_logs FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- offline_cache_metadata
-- ---------------------------------------------------------------------------
ALTER TABLE offline_cache_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own cache metadata"
  ON offline_cache_metadata FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own cache metadata"
  ON offline_cache_metadata FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own cache metadata"
  ON offline_cache_metadata FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own cache metadata"
  ON offline_cache_metadata FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage all cache metadata"
  ON offline_cache_metadata FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- offline_exam_config
-- ---------------------------------------------------------------------------
ALTER TABLE offline_exam_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "School members can read own school offline config"
  ON offline_exam_config FOR SELECT
  USING (school_id = user_school_id() OR is_super_admin());

CREATE POLICY "School admins can insert own school offline config"
  ON offline_exam_config FOR INSERT
  WITH CHECK (is_school_admin(school_id) OR is_super_admin());

CREATE POLICY "School admins can update own school offline config"
  ON offline_exam_config FOR UPDATE
  USING (is_school_admin(school_id) OR is_super_admin())
  WITH CHECK (is_school_admin(school_id) OR is_super_admin());

CREATE POLICY "School admins can delete own school offline config"
  ON offline_exam_config FOR DELETE
  USING (is_school_admin(school_id) OR is_super_admin());

-- ---------------------------------------------------------------------------
-- offline_exam_attempts
-- ---------------------------------------------------------------------------
ALTER TABLE offline_exam_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can read own offline attempts"
  ON offline_exam_attempts FOR SELECT
  USING (student_id = auth.uid());

CREATE POLICY "Students can insert own offline attempts"
  ON offline_exam_attempts FOR INSERT
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own offline attempts"
  ON offline_exam_attempts FOR UPDATE
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "School admins can read school offline attempts"
  ON offline_exam_attempts FOR SELECT
  USING (
    is_school_admin() AND
    school_id = user_school_id()
  );

CREATE POLICY "Super admins can manage all offline attempts"
  ON offline_exam_attempts FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- connectivity_analytics
-- ---------------------------------------------------------------------------
ALTER TABLE connectivity_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own connectivity analytics"
  ON connectivity_analytics FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own connectivity analytics"
  ON connectivity_analytics FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "School admins can read school connectivity analytics"
  ON connectivity_analytics FOR SELECT
  USING (
    is_school_admin() AND
    user_id IN (SELECT id FROM users WHERE school_id = user_school_id())
  );

CREATE POLICY "Super admins can manage all connectivity analytics"
  ON connectivity_analytics FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- file_downloads
-- ---------------------------------------------------------------------------
ALTER TABLE file_downloads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own file downloads"
  ON file_downloads FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own file downloads"
  ON file_downloads FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own file downloads"
  ON file_downloads FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own file downloads"
  ON file_downloads FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage all file downloads"
  ON file_downloads FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- app_analytics
-- ---------------------------------------------------------------------------
ALTER TABLE app_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own app analytics"
  ON app_analytics FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "School admins can read school app analytics"
  ON app_analytics FOR SELECT
  USING (
    is_school_admin() AND
    (user_id IN (SELECT id FROM users WHERE school_id = user_school_id()) OR user_id IS NULL)
  );

CREATE POLICY "Super admins can manage all app analytics"
  ON app_analytics FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- crash_reports
-- ---------------------------------------------------------------------------
ALTER TABLE crash_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own crash reports"
  ON crash_reports FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "School admins can read school crash reports"
  ON crash_reports FOR SELECT
  USING (
    is_school_admin() AND
    (user_id IN (SELECT id FROM users WHERE school_id = user_school_id()) OR user_id IS NULL)
  );

CREATE POLICY "Super admins can manage all crash reports"
  ON crash_reports FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ---------------------------------------------------------------------------
-- pwa_install_events
-- ---------------------------------------------------------------------------
ALTER TABLE pwa_install_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own PWA install events"
  ON pwa_install_events FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own PWA install events"
  ON pwa_install_events FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can update own PWA install events"
  ON pwa_install_events FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage all PWA install events"
  ON pwa_install_events FOR ALL
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- ============================================================================
-- 21. FUNCTIONS
-- ============================================================================
-- Business logic functions for common mobile/offline operations.
-- All functions use SECURITY DEFINER where elevated privileges are needed.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- register_device(): Upsert a device registration for push notifications
-- ---------------------------------------------------------------------------
-- Called when a user opens the app on a device. If the device_token already
-- exists for this user, it updates the existing record; otherwise it inserts.
-- Also deactivates stale devices (not seen in 90 days).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_device(
  p_user_id       UUID,
  p_device_token  TEXT,
  p_platform      mobile_platform,
  p_device_name   TEXT DEFAULT NULL,
  p_device_model  TEXT DEFAULT NULL,
  p_os_version    TEXT DEFAULT NULL,
  p_app_version   TEXT DEFAULT NULL,
  p_push_enabled  BOOLEAN DEFAULT true,
  p_topics        TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_device_id UUID;
BEGIN
  -- Upsert the device registration
  INSERT INTO device_registrations (
    user_id, device_token, platform, device_name, device_model,
    os_version, app_version, push_enabled, push_notification_topics,
    last_active_at
  ) VALUES (
    p_user_id, p_device_token, p_platform, p_device_name, p_device_model,
    p_os_version, p_app_version, p_push_enabled, p_topics, now()
  )
  ON CONFLICT (user_id, device_token) DO UPDATE SET
    platform              = EXCLUDED.platform,
    device_name           = COALESCE(EXCLUDED.device_name, device_registrations.device_name),
    device_model          = COALESCE(EXCLUDED.device_model, device_registrations.device_model),
    os_version            = COALESCE(EXCLUDED.os_version, device_registrations.os_version),
    app_version           = COALESCE(EXCLUDED.app_version, device_registrations.app_version),
    push_enabled          = EXCLUDED.push_enabled,
    push_notification_topics = EXCLUDED.push_notification_topics,
    is_active             = true,
    last_active_at        = now()
  RETURNING id INTO v_device_id;

  -- Also upsert the push notification token
  INSERT INTO push_notification_tokens (user_id, token, platform, is_active)
  VALUES (p_user_id, p_device_token, p_platform, true)
  ON CONFLICT (token) DO UPDATE SET
    user_id   = EXCLUDED.user_id,
    platform  = EXCLUDED.platform,
    is_active = true;

  -- Deactivate devices that haven't been seen in 90 days (for this user)
  UPDATE device_registrations
  SET is_active = false
  WHERE user_id = p_user_id
    AND is_active = true
    AND last_active_at < now() - INTERVAL '90 days'
    AND id != v_device_id;

  RETURN v_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION register_device(UUID, TEXT, mobile_platform, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT[]) IS
  'Upsert a device registration for a user, sync the push token, and deactivate stale devices (90+ days)';

-- ---------------------------------------------------------------------------
-- record_sync_event(): Log a sync operation for monitoring
-- ---------------------------------------------------------------------------
-- Creates a sync_logs entry and updates the corresponding sync_metadata
-- for each table that was synced.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION record_sync_event(
  p_user_id             UUID,
  p_device_id           TEXT DEFAULT NULL,
  p_sync_type           sync_log_type,
  p_tables_synced       TEXT[] DEFAULT '{}',
  p_records_pushed      INTEGER DEFAULT 0,
  p_records_pulled      INTEGER DEFAULT 0,
  p_conflicts_count     INTEGER DEFAULT 0,
  p_errors_count        INTEGER DEFAULT 0,
  p_duration_ms         INTEGER DEFAULT NULL,
  p_connection_quality  connection_quality DEFAULT NULL,
  p_status              sync_log_status,
  p_error_details       JSONB DEFAULT NULL,
  p_started_at          TIMESTAMPTZ DEFAULT now(),
  p_completed_at        TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
  v_table_name TEXT;
BEGIN
  -- Insert the sync log entry
  INSERT INTO sync_logs (
    user_id, device_id, sync_type, tables_synced, records_pushed,
    records_pulled, conflicts_count, errors_count, duration_ms,
    connection_quality, status, error_details, started_at, completed_at
  ) VALUES (
    p_user_id, p_device_id, p_sync_type, p_tables_synced, p_records_pushed,
    p_records_pulled, p_conflicts_count, p_errors_count, p_duration_ms,
    p_connection_quality, p_status, p_error_details, p_started_at,
    COALESCE(p_completed_at, now())
  ) RETURNING id INTO v_log_id;

  -- Update sync_metadata for each synced table
  FOREACH v_table_name IN ARRAY p_tables_synced LOOP
    INSERT INTO sync_metadata (user_id, table_name, last_synced_at, is_full_sync)
    VALUES (p_user_id, v_table_name, now(), p_sync_type = 'full')
    ON CONFLICT (user_id, table_name) DO UPDATE SET
      last_synced_at = now(),
      is_full_sync   = CASE WHEN p_sync_type = 'full' THEN true ELSE sync_metadata.is_full_sync END;
  END LOOP;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION record_sync_event IS
  'Log a sync operation and update per-table sync metadata for the user';

-- ---------------------------------------------------------------------------
-- queue_sync_operation(): Add an operation to the sync queue
-- ---------------------------------------------------------------------------
-- Called by the client when a mutation is made while offline.
-- Returns the queue item ID for tracking.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION queue_sync_operation(
  p_user_id     UUID,
  p_table_name  TEXT,
  p_record_id   TEXT DEFAULT NULL,
  p_operation   sync_operation_type,
  p_payload     JSONB,
  p_priority    INTEGER DEFAULT 5
)
RETURNS UUID AS $$
DECLARE
  v_queue_id UUID;
BEGIN
  -- Validate priority range
  IF p_priority < 1 OR p_priority > 10 THEN
    RAISE EXCEPTION 'Invalid priority value %. Must be between 1 and 10.', p_priority;
  END IF;

  INSERT INTO sync_queue (
    user_id, table_name, record_id, operation, payload, priority, next_retry_at
  ) VALUES (
    p_user_id, p_table_name, p_record_id, p_operation, p_payload,
    p_priority, now()
  ) RETURNING id INTO v_queue_id;

  RETURN v_queue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION queue_sync_operation(UUID, TEXT, TEXT, sync_operation_type, JSONB, INTEGER) IS
  'Add a mutation to the offline sync queue; priority 1 = critical, 10 = low';

-- ---------------------------------------------------------------------------
-- process_sync_queue(): Process pending sync items for a user
-- ---------------------------------------------------------------------------
-- Marks the next batch of pending items as in_progress for processing.
-- Items are selected by priority (ASC) then next_retry_at (ASC).
-- Returns the selected item IDs for the caller to process.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION process_sync_queue(
  p_user_id  UUID,
  p_batch_size INTEGER DEFAULT 50
)
RETURNS TABLE (
  id          UUID,
  table_name  TEXT,
  record_id   TEXT,
  operation   sync_operation_type,
  payload     JSONB,
  priority    INTEGER,
  attempts    INTEGER
) AS $$
BEGIN
  -- Atomically select and lock the next batch of pending items
  RETURN QUERY
  UPDATE sync_queue
  SET status         = 'in_progress',
      last_attempt_at = now(),
      attempts        = attempts + 1,
      updated_at      = now()
  WHERE id IN (
    SELECT sq.id
    FROM sync_queue sq
    WHERE sq.user_id = p_user_id
      AND sq.status IN ('pending', 'failed')
      AND sq.next_retry_at <= now()
      AND sq.attempts < sq.max_attempts
    ORDER BY sq.priority ASC, sq.next_retry_at ASC
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  )
  RETURNING sync_queue.id, sync_queue.table_name, sync_queue.record_id,
            sync_queue.operation, sync_queue.payload, sync_queue.priority,
            sync_queue.attempts;

  -- Mark items that exceeded max_attempts as dead
  UPDATE sync_queue
  SET status = 'dead',
      updated_at = now()
  WHERE user_id = p_user_id
    AND status IN ('pending', 'failed')
    AND attempts >= max_attempts
    AND next_retry_at <= now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION process_sync_queue(UUID, INTEGER) IS
  'Claim the next batch of pending sync items for processing, ordered by priority and retry time';

-- ---------------------------------------------------------------------------
-- complete_sync_queue_item(): Mark a sync queue item as completed or failed
-- ---------------------------------------------------------------------------
-- Helper to finalize processing of an item claimed by process_sync_queue.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION complete_sync_queue_item(
  p_id            UUID,
  p_success       BOOLEAN DEFAULT true,
  p_error_message TEXT DEFAULT NULL,
  p_retry_delay   INTERVAL DEFAULT INTERVAL '30 seconds'
)
RETURNS VOID AS $$
BEGIN
  IF p_success THEN
    UPDATE sync_queue
    SET status     = 'completed',
        updated_at = now()
    WHERE id = p_id;
  ELSE
    UPDATE sync_queue
    SET status         = CASE
                           WHEN attempts >= max_attempts THEN 'dead'
                           ELSE 'failed'
                         END,
        error_message  = p_error_message,
        next_retry_at  = CASE
                           WHEN attempts < max_attempts
                           THEN now() + p_retry_delay * POWER(2, LEAST(attempts - 1, 5))
                           ELSE next_retry_at
                         END,
        updated_at     = now()
    WHERE id = p_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION complete_sync_queue_item(UUID, BOOLEAN, TEXT, INTERVAL) IS
  'Mark a sync queue item as completed or failed with exponential backoff retry';

-- ---------------------------------------------------------------------------
-- record_connectivity_event(): Log a connectivity state change
-- ---------------------------------------------------------------------------
-- Records a connectivity analytics entry. If the user was offline and is
-- now online, it can calculate the offline duration from the last offline event.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION record_connectivity_event(
  p_user_id                   UUID,
  p_device_id                 TEXT DEFAULT NULL,
  p_connection_type           connection_type,
  p_connection_quality        connection_quality,
  p_avg_latency_ms            INTEGER DEFAULT NULL,
  p_bandwidth_estimate_kbps   INTEGER DEFAULT NULL,
  p_was_offline               BOOLEAN DEFAULT false,
  p_offline_duration_seconds  INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_offline_duration INTEGER;
BEGIN
  -- If user is coming back online, calculate offline duration from last event
  IF NOT p_was_offline AND p_connection_type != 'none' THEN
    SELECT offline_duration_seconds INTO v_offline_duration
    FROM connectivity_analytics
    WHERE user_id = p_user_id
      AND was_offline = true
      AND offline_duration_seconds IS NULL
    ORDER BY recorded_at DESC
    LIMIT 1;

    -- If we found an open offline event, update it with the duration
    IF FOUND THEN
      UPDATE connectivity_analytics
      SET offline_duration_seconds = EXTRACT(EPOCH FROM (now() - recorded_at))::INTEGER
      WHERE user_id = p_user_id
        AND was_offline = true
        AND offline_duration_seconds IS NULL;
    END IF;
  END IF;

  INSERT INTO connectivity_analytics (
    user_id, device_id, connection_type, connection_quality,
    avg_latency_ms, bandwidth_estimate_kbps, was_offline,
    offline_duration_seconds
  ) VALUES (
    p_user_id, p_device_id, p_connection_type, p_connection_quality,
    p_avg_latency_ms, p_bandwidth_estimate_kbps, p_was_offline,
    COALESCE(p_offline_duration_seconds, v_offline_duration)
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION record_connectivity_event IS
  'Log a connectivity state change; automatically calculates offline duration for reconnection events';

-- ---------------------------------------------------------------------------
-- cleanup_expired_cache(): Remove expired cache entries
-- ---------------------------------------------------------------------------
-- Should be called periodically (e.g., via pg_cron or Supabase Edge Function)
-- to remove stale cache entries and free up tracking metadata.
-- Returns the number of rows deleted.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cleanup_expired_cache(
  p_user_id  UUID DEFAULT NULL,
  p_dry_run  BOOLEAN DEFAULT false
)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  IF p_dry_run THEN
    -- Count only, don't delete
    SELECT COUNT(*) INTO v_deleted_count
    FROM offline_cache_metadata
    WHERE expires_at IS NOT NULL
      AND expires_at < now()
      AND (p_user_id IS NULL OR user_id = p_user_id);
    RETURN v_deleted_count;
  END IF;

  -- Delete expired entries
  DELETE FROM offline_cache_metadata
  WHERE expires_at IS NOT NULL
    AND expires_at < now()
    AND (p_user_id IS NULL OR user_id = p_user_id);

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_expired_cache(UUID, BOOLEAN) IS
  'Remove expired cache entries; optionally filter by user_id. dry_run=true returns count without deleting';

-- ---------------------------------------------------------------------------
-- get_user_sync_status(): Get a user's current sync state summary
-- ---------------------------------------------------------------------------
-- Returns a JSON object summarizing the user's sync status across all tables,
-- including pending queue items, unresolved conflicts, and last sync times.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_user_sync_status(
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'user_id', p_user_id,
    'pending_queue_count', (
      SELECT COUNT(*) FROM sync_queue
      WHERE user_id = p_user_id AND status IN ('pending', 'in_progress', 'failed')
    ),
    'dead_queue_count', (
      SELECT COUNT(*) FROM sync_queue
      WHERE user_id = p_user_id AND status = 'dead'
    ),
    'unresolved_conflicts', (
      SELECT COUNT(*) FROM sync_conflicts
      WHERE user_id = p_user_id AND resolution = 'pending'
    ),
    'pending_offline_attempts', (
      SELECT COUNT(*) FROM offline_exam_attempts
      WHERE student_id = p_user_id AND sync_status = 'pending'
    ),
    'cache_entries', (
      SELECT COUNT(*) FROM offline_cache_metadata
      WHERE user_id = p_user_id
    ),
    'expired_cache_entries', (
      SELECT COUNT(*) FROM offline_cache_metadata
      WHERE user_id = p_user_id AND expires_at IS NOT NULL AND expires_at < now()
    ),
    'active_devices', (
      SELECT COUNT(*) FROM device_registrations
      WHERE user_id = p_user_id AND is_active = true
    ),
    'last_sync_at', (
      SELECT MAX(last_synced_at) FROM sync_metadata
      WHERE user_id = p_user_id
    ),
    'sync_metadata', (
      SELECT COALESCE(jsonb_object_agg(
        table_name,
        jsonb_build_object(
          'last_synced_at', last_synced_at,
          'is_full_sync', is_full_sync,
          'record_count', record_count,
          'checksum', checksum
        )
      ), '{}')
      FROM sync_metadata WHERE user_id = p_user_id
    ),
    'recent_sync_errors', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', id,
          'sync_type', sync_type,
          'errors_count', errors_count,
          'error_details', error_details,
          'started_at', started_at
        )
        ORDER BY started_at DESC
      ), '[]')
      FROM (
        SELECT * FROM sync_logs
        WHERE user_id = p_user_id AND status = 'failed'
        ORDER BY started_at DESC LIMIT 5
      ) sub
    ),
    'generated_at', now()
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_sync_status(UUID) IS
  'Returns a comprehensive JSON summary of a user''s sync state, including queue counts, conflicts, and cache status';

-- ---------------------------------------------------------------------------
-- validate_offline_attempt(): Validate an offline exam attempt
-- ---------------------------------------------------------------------------
-- Validates an offline exam attempt before accepting it into the main
-- system. Checks:
--   1. The exam allows offline mode
--   2. The student hasn't exceeded max offline attempts
--   3. The integrity hash is valid
--   4. The time taken is reasonable (not negative, not exceeding exam duration)
--   5. The attempt data and answers are present and well-formed
-- Returns a JSONB with validation results.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION validate_offline_attempt(
  p_attempt_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_attempt         offline_exam_attempts%ROWTYPE;
  v_config          offline_exam_config%ROWTYPE;
  v_existing_count  INTEGER;
  v_errors          JSONB := '[]';
  v_is_valid        BOOLEAN := true;
  v_result          JSONB;
BEGIN
  -- Fetch the attempt
  SELECT * INTO v_attempt FROM offline_exam_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'valid', false,
      'errors', jsonb_build_array('Attempt not found')
    );
  END IF;

  -- Fetch the offline config for this exam
  SELECT * INTO v_config
  FROM offline_exam_config
  WHERE exam_id = v_attempt.exam_id
    AND school_id = v_attempt.school_id;

  -- Validation 1: Exam allows offline mode
  IF NOT FOUND OR NOT v_config.allows_offline THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object(
      'field', 'allows_offline',
      'message', 'This exam does not allow offline attempts'
    ));
    v_is_valid := false;
  END IF;

  -- Validation 2: Max offline attempts not exceeded
  IF FOUND THEN
    SELECT COUNT(*) INTO v_existing_count
    FROM offline_exam_attempts
    WHERE exam_id = v_attempt.exam_id
      AND student_id = v_attempt.student_id
      AND sync_status IN ('synced', 'validated', 'pending')
      AND id != p_attempt_id;

    IF v_existing_count >= v_config.max_offline_attempts THEN
      v_errors := v_errors || jsonb_build_array(jsonb_build_object(
        'field', 'max_offline_attempts',
        'message', format('Maximum offline attempts (%s) exceeded', v_config.max_offline_attempts)
      ));
      v_is_valid := false;
    END IF;
  END IF;

  -- Validation 3: Answers are present
  IF v_attempt.answers IS NULL OR jsonb_typeof(v_attempt.answers) = 'null' THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object(
      'field', 'answers',
      'message', 'Answers data is missing'
    ));
    v_is_valid := false;
  END IF;

  -- Validation 4: Attempt data is present
  IF v_attempt.attempt_data IS NULL OR jsonb_typeof(v_attempt.attempt_data) = 'null' THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object(
      'field', 'attempt_data',
      'message', 'Attempt metadata is missing'
    ));
    v_is_valid := false;
  END IF;

  -- Validation 5: Time taken is reasonable
  IF v_attempt.time_taken_seconds IS NOT NULL AND v_attempt.time_taken_seconds < 0 THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object(
      'field', 'time_taken_seconds',
      'message', 'Time taken cannot be negative'
    ));
    v_is_valid := false;
  END IF;

  -- Validation 6: Completed at is after started at
  IF v_attempt.completed_at IS NOT NULL AND v_attempt.completed_at < v_attempt.started_at THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object(
      'field', 'completed_at',
      'message', 'Completion time cannot be before start time'
    ));
    v_is_valid := false;
  END IF;

  -- Update the attempt status
  IF v_is_valid THEN
    UPDATE offline_exam_attempts
    SET sync_status = 'validated',
        validation_errors = NULL
    WHERE id = p_attempt_id;
  ELSE
    UPDATE offline_exam_attempts
    SET sync_status = 'rejected',
        validation_errors = v_errors
    WHERE id = p_attempt_id;
  END IF;

  -- Build result
  v_result := jsonb_build_object(
    'valid', v_is_valid,
    'attempt_id', p_attempt_id,
    'exam_id', v_attempt.exam_id,
    'student_id', v_attempt.student_id,
    'errors', v_errors,
    'validated_at', now()
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION validate_offline_attempt(UUID) IS
  'Validate an offline exam attempt for integrity, attempt limits, and data completeness; updates sync_status accordingly';

-- ============================================================================
-- 22. MAINTENANCE: Dead letter queue cleanup
-- ============================================================================
-- Periodically purge dead sync queue items older than 30 days to prevent
-- unbounded growth. Should be called via pg_cron or scheduled Edge Function.
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_dead_sync_queue(
  p_days_old INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM sync_queue
  WHERE status = 'dead'
    AND updated_at < now() - (p_days_old || ' days')::INTERVAL;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_dead_sync_queue(INTEGER) IS
  'Purge dead-letter sync queue items older than N days (default 30)';

-- ============================================================================
-- 23. MAINTENANCE: Old analytics cleanup
-- ============================================================================
-- Remove old analytics data beyond the retention window.
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_old_analytics(
  p_retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
  v_total_deleted INTEGER := 0;
  v_deleted INTEGER;
BEGIN
  -- Clean up old connectivity analytics
  DELETE FROM connectivity_analytics
  WHERE created_at < now() - (p_retention_days || ' days')::INTERVAL;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  v_total_deleted := v_total_deleted + v_deleted;

  -- Clean up old sync logs
  DELETE FROM sync_logs
  WHERE created_at < now() - (p_retention_days || ' days')::INTERVAL;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  v_total_deleted := v_total_deleted + v_deleted;

  -- Clean up old app analytics
  DELETE FROM app_analytics
  WHERE created_at < now() - (p_retention_days || ' days')::INTERVAL;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  v_total_deleted := v_total_deleted + v_deleted;

  -- Clean up resolved crash reports older than retention window
  DELETE FROM crash_reports
  WHERE is_resolved = true
    AND created_at < now() - (p_retention_days || ' days')::INTERVAL;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  v_total_deleted := v_total_deleted + v_deleted;

  RETURN v_total_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_old_analytics(INTEGER) IS
  'Purge analytics data older than N days (default 90) across connectivity, sync logs, app events, and resolved crash reports';

-- ============================================================================
-- 24. GRANTS
-- ============================================================================
-- Grant appropriate permissions to the authenticated role.
-- In Supabase, the `authenticated` role is used for all logged-in users.
-- ============================================================================

GRANT USAGE ON SCHEMA public TO authenticated;

-- Device registrations
GRANT SELECT, INSERT, UPDATE, DELETE ON device_registrations TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE device_registrations_id_seq TO authenticated;

-- Push notification tokens
GRANT SELECT, INSERT, UPDATE, DELETE ON push_notification_tokens TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE push_notification_tokens_id_seq TO authenticated;

-- Sync metadata
GRANT SELECT, INSERT, UPDATE, DELETE ON sync_metadata TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE sync_metadata_id_seq TO authenticated;

-- Sync queue
GRANT SELECT, INSERT, UPDATE, DELETE ON sync_queue TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE sync_queue_id_seq TO authenticated;

-- Sync conflicts
GRANT SELECT, INSERT, UPDATE, DELETE ON sync_conflicts TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE sync_conflicts_id_seq TO authenticated;

-- Sync logs
GRANT SELECT, INSERT ON sync_logs TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE sync_logs_id_seq TO authenticated;

-- Offline cache metadata
GRANT SELECT, INSERT, UPDATE, DELETE ON offline_cache_metadata TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE offline_cache_metadata_id_seq TO authenticated;

-- Offline exam config
GRANT SELECT ON offline_exam_config TO authenticated;
GRANT INSERT, UPDATE, DELETE ON offline_exam_config TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE offline_exam_config_id_seq TO authenticated;

-- Offline exam attempts
GRANT SELECT, INSERT, UPDATE ON offline_exam_attempts TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE offline_exam_attempts_id_seq TO authenticated;

-- Connectivity analytics
GRANT SELECT, INSERT ON connectivity_analytics TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE connectivity_analytics_id_seq TO authenticated;

-- File downloads
GRANT SELECT, INSERT, UPDATE, DELETE ON file_downloads TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE file_downloads_id_seq TO authenticated;

-- App analytics (insert-only for regular users; read via admin policies)
GRANT INSERT ON app_analytics TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE app_analytics_id_seq TO authenticated;

-- Crash reports (insert-only for regular users; read via admin policies)
GRANT INSERT ON crash_reports TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE crash_reports_id_seq TO authenticated;

-- PWA install events
GRANT SELECT, INSERT, UPDATE ON pwa_install_events TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE pwa_install_events_id_seq TO authenticated;

-- Grant function execution
GRANT EXECUTE ON FUNCTION register_device(UUID, TEXT, mobile_platform, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION record_sync_event(UUID, TEXT, sync_log_type, TEXT[], INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, connection_quality, sync_log_status, JSONB, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION queue_sync_operation(UUID, TEXT, TEXT, sync_operation_type, JSONB, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION process_sync_queue(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_sync_queue_item(UUID, BOOLEAN, TEXT, INTERVAL) TO authenticated;
GRANT EXECUTE ON FUNCTION record_connectivity_event(UUID, TEXT, connection_type, connection_quality, INTEGER, INTEGER, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_cache(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_sync_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_offline_attempt(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_dead_sync_queue(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_analytics(INTEGER) TO authenticated;

-- Grant helper functions
GRANT EXECUTE ON FUNCTION is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_school_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_school_id() TO authenticated;
GRANT EXECUTE ON FUNCTION set_updated_at() TO authenticated;

-- Service role has full access (for backend/Edge Functions)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- ============================================================================
-- 25. SCHEMA METADATA
-- ============================================================================
-- Record this migration for tracking purposes.
-- ============================================================================

COMMENT ON SCHEMA public IS 'ExamForge AI platform schema with mobile/offline-first extensions';

-- ============================================================================
-- COMMIT
-- ============================================================================

COMMIT;
