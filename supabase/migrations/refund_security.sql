-- ============================================================================
-- ExamForge AI — Refund Security Migration
-- ============================================================================
-- Adds server-side refund validation infrastructure:
--   1. refunded_amount column on transactions
--   2. refund_audit_log table for comprehensive audit trail
--   3. RLS policies for refund audit data
--   4. Constraints preventing over-refunding
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- ADD refunded_amount COLUMN TO TRANSACTIONS
-- ════════════════════════════════════════════════════════════════════════════
-- Tracks cumulative refund amount per transaction. Combined with the
-- original amount, this allows the edge function to calculate remaining
-- refundable amount and prevent over-refunding.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'refunded_amount'
  ) THEN
    ALTER TABLE transactions ADD COLUMN refunded_amount NUMERIC(12,2) NOT NULL DEFAULT 0;
    COMMENT ON COLUMN transactions.refunded_amount IS 'Cumulative amount refunded for this transaction. Must never exceed the original amount.';
  END IF;
END $$;

-- Add constraint: refunded_amount cannot exceed original amount
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_refunded_not_exceeds_amount'
  ) THEN
    ALTER TABLE transactions ADD CONSTRAINT chk_refunded_not_exceeds_amount
      CHECK (refunded_amount <= amount);
  END IF;
END $$;

-- Add constraint: refunded_amount must be non-negative
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_refunded_non_negative'
  ) THEN
    ALTER TABLE transactions ADD CONSTRAINT chk_refunded_non_negative
      CHECK (refunded_amount >= 0);
  END IF;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- REFUND AUDIT LOG TABLE
-- ════════════════════════════════════════════════════════════════════════════
-- Every refund attempt (successful or not) is logged here for forensic
-- analysis and compliance. This provides an immutable audit trail.

CREATE TABLE IF NOT EXISTS refund_audit_log (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id        UUID NOT NULL REFERENCES transactions(id) ON DELETE RESTRICT,
  refund_amount         NUMERIC(12,2) NOT NULL,
  requested_by          UUID NOT NULL,                       -- user who initiated the refund
  status                TEXT NOT NULL,                        -- 'initiated', 'approved', 'rejected', 'failed'
  reason                TEXT NOT NULL,                        -- Human-readable reason for the refund or rejection
  metadata              JSONB NOT NULL DEFAULT '{}',         -- Additional context (Flutterwave response, validation details)

  -- Timestamps
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Validation
  CONSTRAINT chk_refund_audit_amount_positive CHECK (refund_amount > 0),
  CONSTRAINT chk_refund_audit_status_valid CHECK (status IN ('initiated', 'approved', 'rejected', 'failed'))
);

COMMENT ON TABLE refund_audit_log IS 'Immutable audit trail for all refund attempts. Every refund request, whether successful or not, is logged for compliance and forensic analysis.';
COMMENT ON COLUMN refund_audit_log.status IS 'initiated = request received, approved = refund processed, rejected = validation failed, failed = gateway error';
COMMENT ON COLUMN refund_audit_log.metadata IS 'Additional context including Flutterwave response, validation details, and rejection reasons';

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_refund_audit_transaction
  ON refund_audit_log (transaction_id);

CREATE INDEX IF NOT EXISTS idx_refund_audit_requested_by
  ON refund_audit_log (requested_by);

CREATE INDEX IF NOT EXISTS idx_refund_audit_status
  ON refund_audit_log (status)
  WHERE status IN ('initiated', 'approved');

CREATE INDEX IF NOT EXISTS idx_refund_audit_created_at
  ON refund_audit_log (created_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES FOR REFUND AUDIT LOG
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE refund_audit_log ENABLE ROW LEVEL SECURITY;

-- Service role can insert (from Edge Function)
CREATE POLICY "Service role can insert refund audit entries"
  ON refund_audit_log FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Super admins can read all refund audit entries
CREATE POLICY "Super admins can read refund audit entries"
  ON refund_audit_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'super_admin'
    )
  );

-- School admins can read refund audit for their school's transactions
CREATE POLICY "School admins can read their school refund audit"
  ON refund_audit_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = refund_audit_log.transaction_id
      AND u.role = 'school_admin'
      AND (u.school_id = t.school_id OR t.school_id IS NULL)
    )
  );

-- Prevent deletion and updates of audit log entries (immutability)
-- No UPDATE or DELETE policies = only service_role can modify

COMMIT;
