-- ============================================================================
-- ExamForge AI — Payment Security Hardening Migration
-- ============================================================================
-- This migration adds tables and indexes to support:
--   1. Webhook event idempotency (prevents duplicate payment crediting)
--   2. Server-side commission calculation (prevents client-side manipulation)
--   3. Transaction amount integrity verification
--   4. Webhook audit trail for forensic analysis
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- WEBHOOK EVENTS TABLE (Idempotency & Audit)
-- ════════════════════════════════════════════════════════════════════════════
-- Stores every webhook event received from Flutterwave. Each event is
-- processed exactly once (idempotency). The unique constraint on
-- (event_type, flutterwave_event_id) prevents duplicate processing even
-- under concurrent webhook deliveries.

CREATE TABLE IF NOT EXISTS webhook_events (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type            TEXT NOT NULL,                        -- e.g. 'charge.completed'
  flutterwave_event_id  TEXT NOT NULL,                        -- Flutterwave's unique event ID
  idempotency_key       TEXT NOT NULL UNIQUE,                 -- event_type + flutterwave_event_id
  payload               JSONB NOT NULL,                       -- Full webhook payload
  processing_status     webhook_status NOT NULL DEFAULT 'received',
  processed_at          TIMESTAMPTZ,
  error_message         TEXT,
  retry_count           INT NOT NULL DEFAULT 0,

  -- Link to the transaction this event affects (if applicable)
  transaction_id        UUID REFERENCES transactions(id) ON DELETE SET NULL,
  school_id             UUID,

  -- Audit
  source_ip             TEXT,                                  -- IP that sent the webhook
  verified              BOOLEAN NOT NULL DEFAULT false,        -- Was signature verified?
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Prevent the same event from being inserted twice
  CONSTRAINT uq_webhook_event UNIQUE (event_type, flutterwave_event_id)
);

COMMENT ON TABLE webhook_events IS 'Webhook event log for Flutterwave. Provides idempotency and audit trail.';
COMMENT ON COLUMN webhook_events.idempotency_key IS 'Unique key derived from event_type + Flutterwave event ID. Prevents duplicate processing.';
COMMENT ON COLUMN webhook_events.verified IS 'Whether the webhook signature was verified before processing.';

-- Index for quick idempotency lookups
CREATE INDEX IF NOT EXISTS idx_webhook_events_idempotency
  ON webhook_events (idempotency_key);

CREATE INDEX IF NOT EXISTS idx_webhook_events_status
  ON webhook_events (processing_status)
  WHERE processing_status IN ('received', 'processing', 'retrying');

CREATE INDEX IF NOT EXISTS idx_webhook_events_created_at
  ON webhook_events (created_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- SERVER-SIDE COMMISSION RATES
-- ════════════════════════════════════════════════════════════════════════════
-- Commission rates are stored server-side and cannot be manipulated by
-- the client. The Supabase Edge Function reads these when calculating
-- seller payouts, never the client app.

CREATE TABLE IF NOT EXISTS marketplace_commission_rates (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_type          TEXT NOT NULL,                         -- 'question_bank', 'exam_template', etc.
  seller_tier           TEXT NOT NULL DEFAULT 'standard',      -- 'standard', 'premium', 'verified'
  commission_rate       NUMERIC(5,4) NOT NULL,                 -- e.g. 0.1500 = 15%
  minimum_commission    NUMERIC(12,2) NOT NULL DEFAULT 0,     -- Floor amount in NGN
  maximum_commission    NUMERIC(12,2),                         -- Cap amount in NGN (null = no cap)
  is_active             BOOLEAN NOT NULL DEFAULT true,
  effective_from        TIMESTAMPTZ NOT NULL DEFAULT now(),
  effective_until       TIMESTAMPTZ,                           -- null = currently active
  created_by            UUID NOT NULL,                         -- super_admin who set this
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_commission_rate UNIQUE (product_type, seller_tier, effective_from)
);

COMMENT ON TABLE marketplace_commission_rates IS 'Server-authoritative commission rates. Client apps must NEVER calculate commissions.';
COMMENT ON COLUMN marketplace_commission_rates.commission_rate IS 'Platform commission as decimal (0.15 = 15%). Calculated server-side only.';

-- Seed default commission rates
INSERT INTO marketplace_commission_rates (product_type, seller_tier, commission_rate, minimum_commission, created_by)
VALUES
  ('question_bank', 'standard', 0.2000, 50.00, '00000000-0000-0000-0000-000000000000'),
  ('question_bank', 'premium', 0.1500, 50.00, '00000000-0000-0000-0000-000000000000'),
  ('question_bank', 'verified', 0.1200, 50.00, '00000000-0000-0000-0000-000000000000'),
  ('exam_template', 'standard', 0.2000, 100.00, '00000000-0000-0000-0000-000000000000'),
  ('exam_template', 'premium', 0.1500, 100.00, '00000000-0000-0000-0000-000000000000'),
  ('exam_template', 'verified', 0.1200, 100.00, '00000000-0000-0000-0000-000000000000'),
  ('ai_resource', 'standard', 0.2500, 50.00, '00000000-0000-0000-0000-000000000000'),
  ('ai_resource', 'premium', 0.2000, 50.00, '00000000-0000-0000-0000-000000000000'),
  ('ai_resource', 'verified', 0.1700, 50.00, '00000000-0000-0000-0000-000000000000')
ON CONFLICT (product_type, seller_tier, effective_from) DO NOTHING;

-- ════════════════════════════════════════════════════════════════════════════
-- AMOUNT INTEGRITY HASH COLUMN
-- ════════════════════════════════════════════════════════════════════════════
-- Adds an integrity hash to the transactions table that is computed
-- from the amount, currency, and subscription_id. This hash is set
-- when the transaction is created and verified when the payment is
-- confirmed, making it tamper-evident if someone tries to modify the
-- amount between checkout initiation and verification.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'amount_integrity_hash'
  ) THEN
    ALTER TABLE transactions ADD COLUMN amount_integrity_hash TEXT;
    COMMENT ON COLUMN transactions.amount_integrity_hash IS 'SHA-256 hash of (tx_ref + amount + currency) set at checkout creation. Verified at payment confirmation to detect amount tampering.';
  END IF;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTION: Compute and verify amount integrity hash
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION compute_amount_integrity_hash(
  p_tx_ref TEXT,
  p_amount NUMERIC,
  p_currency TEXT
) RETURNS TEXT AS $$
BEGIN
  RETURN encode(
    digest(
      p_tx_ref || ':' || p_amount::text || ':' || p_currency,
      'sha256'
    ),
    'hex'
  );
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION verify_transaction_integrity(
  p_tx_ref TEXT,
  p_amount NUMERIC,
  p_currency TEXT,
  p_stored_hash TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  IF p_stored_hash IS NULL THEN
    RETURN true;  -- No hash set for legacy transactions
  END IF;
  RETURN compute_amount_integrity_hash(p_tx_ref, p_amount, p_currency) = p_stored_hash;
END;
$$ LANGUAGE plpgsql STABLE;

-- ════════════════════════════════════════════════════════════════════════════
-- TRIGGER: Auto-set integrity hash on transaction insert
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_transaction_integrity_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.amount_integrity_hash IS NULL AND NEW.flutterwave_tx_ref IS NOT NULL THEN
    NEW.amount_integrity_hash := compute_amount_integrity_hash(
      NEW.flutterwave_tx_ref, NEW.amount, NEW.currency
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_transaction_integrity_hash ON transactions;
CREATE TRIGGER trg_set_transaction_integrity_hash
  BEFORE INSERT ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION set_transaction_integrity_hash();

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTION: Calculate marketplace commission (SERVER-SIDE ONLY)
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION calculate_marketplace_commission(
  p_product_type TEXT,
  p_seller_id UUID,
  p_sale_amount NUMERIC
) RETURNS NUMERIC AS $$
DECLARE
  v_seller_tier TEXT := 'standard';
  v_rate NUMERIC;
  v_minimum NUMERIC;
  v_maximum NUMERIC;
  v_commission NUMERIC;
BEGIN
  -- Get seller tier from seller profile
  SELECT seller_tier INTO v_seller_tier
  FROM marketplace_seller_profiles
  WHERE id = p_seller_id
  LIMIT 1;

  IF NOT FOUND THEN
    v_seller_tier := 'standard';
  END IF;

  -- Get active commission rate for this product type and seller tier
  SELECT commission_rate, minimum_commission, maximum_commission
  INTO v_rate, v_minimum, v_maximum
  FROM marketplace_commission_rates
  WHERE product_type = p_product_type
    AND seller_tier = v_seller_tier
    AND is_active = true
    AND effective_from <= now()
    AND (effective_until IS NULL OR effective_until > now())
  ORDER BY effective_from DESC
  LIMIT 1;

  IF NOT FOUND THEN
    -- Default 20% commission if no rate is configured
    v_rate := 0.20;
    v_minimum := 50.00;
    v_maximum := NULL;
  END IF;

  -- Calculate commission
  v_commission := p_sale_amount * v_rate;

  -- Apply minimum floor
  IF v_commission < v_minimum THEN
    v_commission := v_minimum;
  END IF;

  -- Apply maximum cap if set
  IF v_maximum IS NOT NULL AND v_commission > v_maximum THEN
    v_commission := v_maximum;
  END IF;

  -- Commission cannot exceed the sale amount
  IF v_commission > p_sale_amount THEN
    v_commission := p_sale_amount;
  END IF;

  RETURN v_commission;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION calculate_marketplace_commission IS 'Server-side commission calculation. Must NEVER be computed client-side.';

-- ════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES FOR NEW TABLES
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_commission_rates ENABLE ROW LEVEL SECURITY;

-- Webhook events: Only service_role can insert (from Edge Function).
-- Super admins can read for auditing. No one can update/delete.
CREATE POLICY "Service role can insert webhook events"
  ON webhook_events FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "Super admins can read webhook events"
  ON webhook_events FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'super_admin'
    )
  );

-- Commission rates: Anyone can read (needed for display), only super_admin writes
CREATE POLICY "Anyone can read active commission rates"
  ON marketplace_commission_rates FOR SELECT
  TO authenticated
  USING (is_active = true AND effective_from <= now());

CREATE POLICY "Super admins can manage commission rates"
  ON marketplace_commission_rates FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'super_admin'
    )
  );

COMMIT;
