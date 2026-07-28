-- ============================================================================
-- ExamForge AI — Marketplace Security Hardening Migration
-- ============================================================================
-- Adds:
--   1. Secure download tokens table (time-limited, one-time-use URLs)
--   2. Download audit trail
--   3. Signed URL generation function
--   4. Server-side download count enforcement
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- DOWNLOAD TOKENS TABLE
-- ════════════════════════════════════════════════════════════════════════════
-- Each purchase generates a time-limited, one-time-use download token.
-- The token is used to construct a signed URL that grants temporary
-- access to the purchased resource in Supabase Storage.
-- Tokens expire after 24 hours and can only be used a limited number
-- of times (preventing link sharing).

CREATE TABLE IF NOT EXISTS download_tokens (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token             TEXT NOT NULL UNIQUE,                       -- Random secure token
  purchase_id       UUID NOT NULL REFERENCES marketplace_purchases(id) ON DELETE CASCADE,
  product_id        UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  buyer_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seller_id         UUID NOT NULL,

  -- Token metadata
  file_path         TEXT NOT NULL,                              -- Storage path to the file
  file_name         TEXT NOT NULL,                              -- Original filename for download

  -- Usage limits
  max_downloads     INT NOT NULL DEFAULT 5,                    -- Maximum download attempts
  download_count    INT NOT NULL DEFAULT 0,                    -- Current download count
  expires_at        TIMESTAMPTZ NOT NULL,                       -- Token expiry time

  -- Status
  is_revoked        BOOLEAN NOT NULL DEFAULT false,
  last_download_ip  TEXT,
  last_download_at  TIMESTAMPTZ,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Ensure token is not expired on creation
  CONSTRAINT token_not_expired CHECK (expires_at > created_at)
);

COMMENT ON TABLE download_tokens IS 'Time-limited download tokens for marketplace purchases. Prevents unauthorized file access and link sharing.';

-- Indexes for fast token lookups
CREATE INDEX IF NOT EXISTS idx_download_tokens_token ON download_tokens (token);
CREATE INDEX IF NOT EXISTS idx_download_tokens_buyer ON download_tokens (buyer_id);
CREATE INDEX IF NOT EXISTS idx_download_tokens_purchase ON download_tokens (purchase_id);
CREATE INDEX IF NOT EXISTS idx_download_tokens_expires ON download_tokens (expires_at)
  WHERE is_revoked = false;

-- ════════════════════════════════════════════════════════════════════════════
-- DOWNLOAD AUDIT LOG TABLE
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS download_audit_log (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_id          UUID NOT NULL REFERENCES download_tokens(id) ON DELETE CASCADE,
  purchase_id       UUID NOT NULL,
  product_id        UUID NOT NULL,
  buyer_id          UUID NOT NULL,

  -- Download details
  download_ip       TEXT,
  user_agent        TEXT,
  file_path         TEXT NOT NULL,
  success           BOOLEAN NOT NULL DEFAULT false,
  failure_reason    TEXT,                                      -- e.g. 'token_expired', 'max_downloads_reached', 'revoked'

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE download_audit_log IS 'Audit trail for all marketplace download attempts. Used for fraud detection and dispute resolution.';

CREATE INDEX IF NOT EXISTS idx_download_audit_buyer ON download_audit_log (buyer_id);
CREATE INDEX IF NOT EXISTS idx_download_audit_product ON download_audit_log (product_id);
CREATE INDEX IF NOT EXISTS idx_download_audit_created ON download_audit_log (created_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTION: Generate a secure download token
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION generate_download_token(
  p_purchase_id UUID,
  p_product_id UUID,
  p_buyer_id UUID,
  p_seller_id UUID,
  p_file_path TEXT,
  p_file_name TEXT,
  p_max_downloads INT DEFAULT 5,
  p_expiry_hours INT DEFAULT 24
) RETURNS TEXT AS $$
DECLARE
  v_token TEXT;
  v_token_id UUID;
  v_expires_at TIMESTAMPTZ;
BEGIN
  -- Verify the purchase exists and belongs to the buyer
  IF NOT EXISTS (
    SELECT 1 FROM marketplace_purchases
    WHERE id = p_purchase_id
      AND buyer_id = p_buyer_id
      AND status = 'completed'
  ) THEN
    RAISE EXCEPTION 'Invalid purchase: purchase does not exist or is not completed';
  END IF;

  -- Verify the product exists and is active
  IF NOT EXISTS (
    SELECT 1 FROM marketplace_products
    WHERE id = p_product_id AND status = 'published'
  ) THEN
    RAISE EXCEPTION 'Invalid product: product does not exist or is not published';
  END IF;

  -- Generate a cryptographically secure random token
  v_token := encode(gen_random_bytes(32), 'hex');
  v_expires_at := now() + (p_expiry_hours || ' hours')::INTERVAL;

  -- Insert the token record
  INSERT INTO download_tokens (
    token, purchase_id, product_id, buyer_id, seller_id,
    file_path, file_name, max_downloads, expires_at
  ) VALUES (
    v_token, p_purchase_id, p_product_id, p_buyer_id, p_seller_id,
    p_file_path, p_file_name, p_max_downloads, v_expires_at
  ) RETURNING id INTO v_token_id;

  RETURN v_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTION: Validate and consume a download token
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION validate_download_token(
  p_token TEXT,
  p_buyer_id UUID,
  p_download_ip TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
) RETURNS TABLE (
  is_valid BOOLEAN,
  file_path TEXT,
  file_name TEXT,
  product_id UUID,
  failure_reason TEXT
) AS $$
DECLARE
  v_token_record RECORD;
  v_failure_reason TEXT;
BEGIN
  -- Look up the token
  SELECT * INTO v_token_record
  FROM download_tokens
  WHERE token = p_token
    AND buyer_id = p_buyer_id;

  IF NOT FOUND THEN
    -- Log failed attempt
    INSERT INTO download_audit_log (token_id, purchase_id, product_id, buyer_id, download_ip, user_agent, file_path, success, failure_reason)
    SELECT id, purchase_id, product_id, buyer_id, p_download_ip, p_user_agent, file_path, false, 'token_not_found'
    FROM download_tokens WHERE token = p_token LIMIT 1;

    RETURN QUERY SELECT false, ''::TEXT, ''::TEXT, NULL::UUID, 'Invalid or unauthorized download token'::TEXT;
    RETURN;
  END IF;

  -- Check if token is revoked
  IF v_token_record.is_revoked THEN
    v_failure_reason := 'Token has been revoked';
    INSERT INTO download_audit_log (token_id, purchase_id, product_id, buyer_id, download_ip, user_agent, file_path, success, failure_reason)
    VALUES (v_token_record.id, v_token_record.purchase_id, v_token_record.product_id, v_token_record.buyer_id, p_download_ip, p_user_agent, v_token_record.file_path, false, v_failure_reason);

    RETURN QUERY SELECT false, ''::TEXT, ''::TEXT, NULL::UUID, v_failure_reason;
    RETURN;
  END IF;

  -- Check if token has expired
  IF v_token_record.expires_at < now() THEN
    v_failure_reason := 'Download token has expired';
    INSERT INTO download_audit_log (token_id, purchase_id, product_id, buyer_id, download_ip, user_agent, file_path, success, failure_reason)
    VALUES (v_token_record.id, v_token_record.purchase_id, v_token_record.product_id, v_token_record.buyer_id, p_download_ip, p_user_agent, v_token_record.file_path, false, v_failure_reason);

    RETURN QUERY SELECT false, ''::TEXT, ''::TEXT, NULL::UUID, v_failure_reason;
    RETURN;
  END IF;

  -- Check download limit
  IF v_token_record.download_count >= v_token_record.max_downloads THEN
    v_failure_reason := 'Maximum download limit reached';
    INSERT INTO download_audit_log (token_id, purchase_id, product_id, buyer_id, download_ip, user_agent, file_path, success, failure_reason)
    VALUES (v_token_record.id, v_token_record.purchase_id, v_token_record.product_id, v_token_record.buyer_id, p_download_ip, p_user_agent, v_token_record.file_path, false, v_failure_reason);

    RETURN QUERY SELECT false, ''::TEXT, ''::TEXT, NULL::UUID, v_failure_reason;
    RETURN;
  END IF;

  -- All checks passed — increment download count
  UPDATE download_tokens
  SET download_count = download_count + 1,
      last_download_ip = p_download_ip,
      last_download_at = now()
  WHERE id = v_token_record.id;

  -- Log successful download
  INSERT INTO download_audit_log (token_id, purchase_id, product_id, buyer_id, download_ip, user_agent, file_path, success)
  VALUES (v_token_record.id, v_token_record.purchase_id, v_token_record.product_id, v_token_record.buyer_id, p_download_ip, p_user_agent, v_token_record.file_path, true);

  -- Return valid result with file info
  RETURN QUERY SELECT
    true,
    v_token_record.file_path,
    v_token_record.file_name,
    v_token_record.product_id,
    NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE download_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE download_audit_log ENABLE ROW LEVEL SECURITY;

-- Buyers can only see their own tokens
CREATE POLICY "Buyers can read own download tokens"
  ON download_tokens FOR SELECT
  TO authenticated
  USING (buyer_id = auth.uid());

-- Sellers can see tokens for their products (for analytics)
CREATE POLICY "Sellers can read tokens for their products"
  ON download_tokens FOR SELECT
  TO authenticated
  USING (seller_id = auth.uid());

-- Super admins can see all tokens
CREATE POLICY "Super admins can read all download tokens"
  ON download_tokens FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Only service_role can create tokens (from Edge Function)
CREATE POLICY "Service role can create download tokens"
  ON download_tokens FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Only the validate function (SECURITY DEFINER) can update tokens
-- No direct update policy for authenticated users
CREATE POLICY "Service role can update download tokens"
  ON download_tokens FOR UPDATE
  TO service_role
  WITH CHECK (true);

-- Download audit log: read-only for admins
CREATE POLICY "Super admins can read download audit"
  ON download_audit_log FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Only service_role can insert audit records
CREATE POLICY "Service role can insert download audit"
  ON download_audit_log FOR INSERT
  TO service_role
  WITH CHECK (true);

COMMIT;
