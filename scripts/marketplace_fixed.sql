-- ============================================================================
-- ExamForge AI Marketplace & Digital Resource Store
-- Comprehensive Supabase SQL Schema
-- ============================================================================
-- This migration creates the full marketplace infrastructure including:
--   - Custom ENUM types
--   - Core marketplace tables (categories, products, orders, purchases, etc.)
--   - Analytics & AI recommendation tables
--   - Quality check & dispute management
--   - Search, notifications, and saved searches
--   - Indexes (GIN, B-tree, full-text)
--   - Triggers for timestamps, rating aggregation, and sales counts
--   - Row-Level Security (RLS) policies
--   - Functions for search, recommendation scoring, quality checks
--   - Materialized view for trending products
--   - Table and column comments
-- ============================================================================

-- ============================================================================
-- SECTION 1: CUSTOM ENUM TYPES
-- ============================================================================

DO $$
BEGIN
  -- Product type classification for the marketplace
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_product_type') THEN
    CREATE TYPE marketplace_product_type AS ENUM (
      'question_bank',
      'exam_template',
      'lesson_note',
      'scheme_of_work',
      'worksheet',
      'powerpoint',
      'teaching_slides',
      'flashcards',
      'study_guide',
      'practical_manual',
      'laboratory_guide',
      'curriculum_pack',
      'assessment_rubric',
      'homework_pack',
      'classroom_activity',
      'educational_image',
      'educational_video',
      'educational_audio',
      'printable_resource',
      'other'
    );
  END IF;

  -- Product lifecycle status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_product_status') THEN
    CREATE TYPE marketplace_product_status AS ENUM (
      'draft',
      'pending_review',
      'approved',
      'rejected',
      'suspended',
      'archived'
    );
  END IF;

  -- License type for product usage
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_license_type') THEN
    CREATE TYPE marketplace_license_type AS ENUM (
      'personal',
      'teacher',
      'school',
      'department',
      'enterprise'
    );
  END IF;

  -- Order processing status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_order_status') THEN
    CREATE TYPE marketplace_order_status AS ENUM (
      'pending',
      'completed',
      'failed',
      'refunded',
      'partially_refunded'
    );
  END IF;

  -- Review moderation status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_review_status') THEN
    CREATE TYPE marketplace_review_status AS ENUM (
      'published',
      'hidden',
      'under_review',
      'reported'
    );
  END IF;

  -- Seller account status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_seller_status') THEN
    CREATE TYPE marketplace_seller_status AS ENUM (
      'active',
      'suspended',
      'pending_verification',
      'deactivated'
    );
  END IF;

  -- Commission classification types
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'commission_type') THEN
    CREATE TYPE commission_type AS ENUM (
      'platform',
      'promotional',
      'referral',
      'tax'
    );
  END IF;

  -- AI quality check status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'quality_check_status') THEN
    CREATE TYPE quality_check_status AS ENUM (
      'pending',
      'passed',
      'failed',
      'needs_improvement'
    );
  END IF;
END
$$;

-- ============================================================================
-- SECTION 2: HELPER FUNCTIONS (must exist before table creation)
-- ============================================================================

-- Generic updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Generate unique order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'EF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Generate unique license keys
CREATE OR REPLACE FUNCTION generate_license_key()
RETURNS TEXT AS $$
BEGIN
  RETURN 'EFL-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 4))
       || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 4))
       || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 4))
       || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 4));
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ============================================================================
-- SECTION 3: TABLE DEFINITIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 marketplace_categories - Hierarchical product categories
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id   UUID REFERENCES marketplace_categories(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  description TEXT,
  icon        TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_category_name_length CHECK (char_length(name) >= 2),
  CONSTRAINT chk_category_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

COMMENT ON TABLE marketplace_categories IS 'Hierarchical categories for organizing marketplace products';
COMMENT ON COLUMN marketplace_categories.parent_id IS 'Self-referencing FK for nested sub-categories. NULL = top-level category';
COMMENT ON COLUMN marketplace_categories.slug IS 'URL-friendly identifier, must be unique across all categories';
COMMENT ON COLUMN marketplace_categories.sort_order IS 'Lower values appear first in listings';

-- ----------------------------------------------------------------------------
-- 3.2 seller_profiles - Seller identity and business information
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS seller_profiles (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name             TEXT NOT NULL,
  bio                      TEXT,
  avatar_url               TEXT,
  status                   marketplace_seller_status NOT NULL DEFAULT 'pending_verification',
  verification_level       INTEGER NOT NULL DEFAULT 0 CHECK (verification_level BETWEEN 0 AND 5),
  total_sales              INTEGER NOT NULL DEFAULT 0,
  total_revenue            DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  average_rating           DECIMAL(3,2) NOT NULL DEFAULT 0.00 CHECK (average_rating BETWEEN 0.00 AND 5.00),
  total_reviews            INTEGER NOT NULL DEFAULT 0,
  total_products           INTEGER NOT NULL DEFAULT 0,
  bank_account_encrypted   TEXT,
  payout_method            TEXT,
  payout_details_encrypted TEXT,
  is_verified              BOOLEAN NOT NULL DEFAULT FALSE,
  verified_at              TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_seller_display_name CHECK (char_length(display_name) >= 2),
  CONSTRAINT chk_seller_revenue_non_negative CHECK (total_revenue >= 0),
  CONSTRAINT chk_seller_total_sales_non_negative CHECK (total_sales >= 0)
);

COMMENT ON TABLE seller_profiles IS 'Seller identity, verification, and aggregate metrics for marketplace vendors';
COMMENT ON COLUMN seller_profiles.verification_level IS '0=unverified, 1=email, 2=ID, 3=bank, 4=tax, 5=premium verified';
COMMENT ON COLUMN seller_profiles.bank_account_encrypted IS 'Encrypted bank account details for payouts';
COMMENT ON COLUMN seller_profiles.payout_details_encrypted IS 'Encrypted payout method-specific details';

-- ----------------------------------------------------------------------------
-- 3.3 marketplace_products - Core product listing table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_products (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id              UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
  category_id            UUID REFERENCES marketplace_categories(id) ON DELETE SET NULL,
  title                  TEXT NOT NULL,
  slug                   TEXT NOT NULL UNIQUE,
  description            TEXT NOT NULL,
  product_type           marketplace_product_type NOT NULL,
  subject                TEXT,
  class_level            TEXT,
  curriculum             TEXT,
  language               TEXT NOT NULL DEFAULT 'en',
  preview_images         JSONB DEFAULT '[]',
  preview_documents      JSONB DEFAULT '[]',
  full_document_urls     JSONB DEFAULT '[]',
  price                  DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  original_price         DECIMAL(10,2) CHECK (original_price IS NULL OR original_price > price),
  currency               TEXT NOT NULL DEFAULT 'NGN',
  license_type           marketplace_license_type NOT NULL DEFAULT 'personal',
  license_config         JSONB DEFAULT '{}',
  version                TEXT NOT NULL DEFAULT '1.0.0',
  tags                   TEXT[] DEFAULT '{}',
  ai_generated_summary   TEXT,
  is_ai_generated        BOOLEAN NOT NULL DEFAULT FALSE,
  is_featured            BOOLEAN NOT NULL DEFAULT FALSE,
  is_free                BOOLEAN NOT NULL DEFAULT FALSE,
  status                 marketplace_product_status NOT NULL DEFAULT 'draft',
  quality_score          DECIMAL(5,2) CHECK (quality_score IS NULL OR quality_score BETWEEN 0.00 AND 100.00),
  quality_check_status   quality_check_status,
  quality_check_details  JSONB,
  total_sales            INTEGER NOT NULL DEFAULT 0,
  total_revenue          DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  average_rating         DECIMAL(3,2) NOT NULL DEFAULT 0.00 CHECK (average_rating BETWEEN 0.00 AND 5.00),
  total_reviews          INTEGER NOT NULL DEFAULT 0,
  download_count         INTEGER NOT NULL DEFAULT 0,
  view_count             INTEGER NOT NULL DEFAULT 0,
  published_at           TIMESTAMPTZ,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at             TIMESTAMPTZ,

  CONSTRAINT chk_product_title_length CHECK (char_length(title) >= 3),
  CONSTRAINT chk_product_description_length CHECK (char_length(description) >= 10),
  CONSTRAINT chk_product_price_non_negative CHECK (price >= 0),
  CONSTRAINT chk_product_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

COMMENT ON TABLE marketplace_products IS 'Core product listings for the ExamForge AI digital marketplace';
COMMENT ON COLUMN marketplace_products.preview_images IS 'JSONB array of {url, alt, sort_order} for product preview images';
COMMENT ON COLUMN marketplace_products.preview_documents IS 'JSONB array of {url, name, pages} for sample document previews';
COMMENT ON COLUMN marketplace_products.full_document_urls IS 'JSONB array of {url, name, size_bytes, mime_type} for full deliverables';
COMMENT ON COLUMN marketplace_products.license_config IS 'JSONB for extended license terms: seats, expiry, redistribution rights, etc.';
COMMENT ON COLUMN marketplace_products.quality_score IS 'AI-computed quality score 0-100';
COMMENT ON COLUMN marketplace_products.quality_check_details IS 'JSONB: {checked_by, check_version, criteria_scores, notes}';
COMMENT ON COLUMN marketplace_products.deleted_at IS 'Soft delete timestamp. NULL = active product';

-- Full-text search column (managed by trigger, not GENERATED column)
ALTER TABLE marketplace_products
  ADD COLUMN IF NOT EXISTS fts_document tsvector;

-- Trigger function to update fts_document on insert/update
CREATE OR REPLACE FUNCTION marketplace_products_fts_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fts_document :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.ai_generated_summary, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

DROP TRIGGER IF EXISTS trg_marketplace_products_fts ON marketplace_products;
CREATE TRIGGER trg_marketplace_products_fts
  BEFORE INSERT OR UPDATE ON marketplace_products
  FOR EACH ROW
  EXECUTE FUNCTION marketplace_products_fts_update();

COMMENT ON COLUMN marketplace_products.fts_document IS 'Auto-computed tsvector for full-text search with weighted ranking (A=title, B=description, C=summary, D=tags)';

-- ----------------------------------------------------------------------------
-- 3.4 marketplace_product_versions - Version history for products
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_product_versions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  version        TEXT NOT NULL,
  changelog      TEXT,
  document_urls  JSONB DEFAULT '[]',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_version_format CHECK (version ~ '^\d+\.\d+\.\d+$'),
  CONSTRAINT uq_product_version UNIQUE (product_id, version)
);

COMMENT ON TABLE marketplace_product_versions IS 'Version history for products, enabling rollback and changelog tracking';
COMMENT ON COLUMN marketplace_product_versions.document_urls IS 'JSONB array of {url, name, size_bytes, mime_type} for this specific version';

-- ----------------------------------------------------------------------------
-- 3.5 marketplace_carts - Shopping cart headers
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_carts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_carts IS 'Shopping cart header. One active cart per user.';

-- ----------------------------------------------------------------------------
-- 3.6 marketplace_cart_items - Items within a shopping cart
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_cart_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id      UUID NOT NULL REFERENCES marketplace_carts(id) ON DELETE CASCADE,
  product_id   UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  license_type marketplace_license_type NOT NULL DEFAULT 'personal',
  quantity     INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  added_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_cart_product UNIQUE (cart_id, product_id, license_type)
);

COMMENT ON TABLE marketplace_cart_items IS 'Individual items in a shopping cart. Unique per cart+product+license combination.';

-- ----------------------------------------------------------------------------
-- 3.7 marketplace_orders - Order headers
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_orders (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id          UUID REFERENCES seller_profiles(id) ON DELETE SET NULL,
  order_number       TEXT NOT NULL UNIQUE DEFAULT generate_order_number(),
  status             marketplace_order_status NOT NULL DEFAULT 'pending',
  subtotal           DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  platform_fee       DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (platform_fee >= 0),
  tax_amount         DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
  discount_amount    DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
  total_amount       DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  currency           TEXT NOT NULL DEFAULT 'NGN',
  promo_code_id      UUID,
  flutterwave_tx_ref TEXT,
  flutterwave_flw_ref TEXT,
  payment_method     TEXT,
  paid_at            TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_order_total_consistency CHECK (total_amount = subtotal + platform_fee + tax_amount - discount_amount)
);

COMMENT ON TABLE marketplace_orders IS 'Order headers with payment tracking via Flutterwave integration';
COMMENT ON COLUMN marketplace_orders.flutterwave_tx_ref IS 'Flutterwave transaction reference (merchant-generated)';
COMMENT ON COLUMN marketplace_orders.flutterwave_flw_ref IS 'Flutterwave internal transaction reference';
COMMENT ON COLUMN marketplace_orders.seller_id IS 'Primary seller for the order (for single-seller orders). NULL for multi-seller orders.';

-- ----------------------------------------------------------------------------
-- 3.8 marketplace_order_items - Line items within an order
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_order_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  product_id        UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE RESTRICT,
  seller_id         UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE RESTRICT,
  license_type      marketplace_license_type NOT NULL DEFAULT 'personal',
  price_at_purchase DECIMAL(10,2) NOT NULL CHECK (price_at_purchase >= 0),
  platform_fee      DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (platform_fee >= 0),
  seller_revenue    DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (seller_revenue >= 0),
  currency          TEXT NOT NULL DEFAULT 'NGN',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_order_items IS 'Individual line items within an order, each with seller revenue breakdown';

-- ----------------------------------------------------------------------------
-- 3.9 marketplace_purchases - Purchase records for access control
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_purchases (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id          UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  order_item_id       UUID NOT NULL REFERENCES marketplace_order_items(id) ON DELETE CASCADE,
  license_type        marketplace_license_type NOT NULL DEFAULT 'personal',
  license_key         TEXT NOT NULL UNIQUE DEFAULT generate_license_key(),
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at          TIMESTAMPTZ,
  download_count      INTEGER NOT NULL DEFAULT 0,
  last_downloaded_at  TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_buyer_product_license UNIQUE (buyer_id, product_id, license_type)
);

COMMENT ON TABLE marketplace_purchases IS 'Purchase records controlling access to digital products. Each record grants a license.';
COMMENT ON COLUMN marketplace_purchases.license_key IS 'Unique license key for the purchase, auto-generated';
COMMENT ON COLUMN marketplace_purchases.expires_at IS 'NULL = perpetual license. Otherwise, the license expiry timestamp.';

-- ----------------------------------------------------------------------------
-- 3.10 marketplace_reviews - Product reviews and ratings
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_reviews (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id           UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  buyer_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id            UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
  rating               INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title                TEXT,
  content              TEXT,
  is_verified_purchase BOOLEAN NOT NULL DEFAULT FALSE,
  status               marketplace_review_status NOT NULL DEFAULT 'published',
  seller_response      TEXT,
  seller_responded_at  TIMESTAMPTZ,
  helpful_count        INTEGER NOT NULL DEFAULT 0,
  report_count         INTEGER NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_review_buyer_product UNIQUE (buyer_id, product_id)
);

COMMENT ON TABLE marketplace_reviews IS 'Product reviews and ratings. One review per buyer per product.';
COMMENT ON COLUMN marketplace_reviews.is_verified_purchase IS 'TRUE if the reviewer has purchased the product';
COMMENT ON COLUMN marketplace_reviews.seller_response IS 'Optional seller response to the review';

-- ----------------------------------------------------------------------------
-- 3.11 marketplace_review_helpful - Helpful votes on reviews
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_review_helpful (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id  UUID NOT NULL REFERENCES marketplace_reviews(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_review_helpful UNIQUE (review_id, user_id)
);

COMMENT ON TABLE marketplace_review_helpful IS 'Helpful/unhelpful votes on reviews. One vote per user per review.';

-- ----------------------------------------------------------------------------
-- 3.12 marketplace_wishlists - User wishlist (favorites)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_wishlists (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_wishlist_user_product UNIQUE (user_id, product_id)
);

COMMENT ON TABLE marketplace_wishlists IS 'User wishlist / favorites. Unique constraint prevents duplicate entries.';

-- ----------------------------------------------------------------------------
-- 3.13 marketplace_promo_codes - Promotional discount codes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_promo_codes (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                    TEXT NOT NULL UNIQUE,
  description             TEXT,
  discount_type           TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value          DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
  max_uses                INTEGER CHECK (max_uses IS NULL OR max_uses > 0),
  current_uses            INTEGER NOT NULL DEFAULT 0,
  min_order_amount        DECIMAL(10,2) CHECK (min_order_amount IS NULL OR min_order_amount >= 0),
  max_discount_amount     DECIMAL(10,2) CHECK (max_discount_amount IS NULL OR max_discount_amount >= 0),
  applicable_product_types TEXT[] DEFAULT '{}',
  applicable_seller_ids   UUID[] DEFAULT '{}',
  starts_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at              TIMESTAMPTZ,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  created_by              UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_promo_current_uses CHECK (current_uses >= 0),
  CONSTRAINT chk_promo_dates CHECK (expires_at IS NULL OR starts_at < expires_at)
);

COMMENT ON TABLE marketplace_promo_codes IS 'Promotional discount codes for marketplace orders';
COMMENT ON COLUMN marketplace_promo_codes.discount_type IS 'percentage = % off, fixed = flat amount off';
COMMENT ON COLUMN marketplace_promo_codes.applicable_product_types IS 'Empty array = applies to all product types';
COMMENT ON COLUMN marketplace_promo_codes.applicable_seller_ids IS 'Empty array = applies to all sellers';

-- ----------------------------------------------------------------------------
-- 3.14 marketplace_commission_rates - Commission configuration
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_commission_rates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_type    marketplace_product_type,
  license_type    marketplace_license_type,
  commission_rate DECIMAL(5,4) NOT NULL CHECK (commission_rate BETWEEN 0.0000 AND 1.0000),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  effective_from  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_to    TIMESTAMPTZ,
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_commission_dates CHECK (effective_to IS NULL OR effective_from < effective_to)
);

COMMENT ON TABLE marketplace_commission_rates IS 'Configurable commission rates by product type and license type. Rate stored as decimal (e.g., 0.1500 = 15%)';

-- ----------------------------------------------------------------------------
-- 3.15 marketplace_commission_records - Commission tracking per order item
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_commission_records (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id    UUID NOT NULL REFERENCES marketplace_order_items(id) ON DELETE CASCADE,
  seller_id        UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
  commission_type  commission_type NOT NULL DEFAULT 'platform',
  commission_rate  DECIMAL(5,4) NOT NULL CHECK (commission_rate BETWEEN 0.0000 AND 1.0000),
  commission_amount DECIMAL(12,2) NOT NULL CHECK (commission_amount >= 0),
  seller_revenue   DECIMAL(12,2) NOT NULL CHECK (seller_revenue >= 0),
  currency         TEXT NOT NULL DEFAULT 'NGN',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_commission_records IS 'Detailed commission records for each order item, enabling payout calculations';

-- ----------------------------------------------------------------------------
-- 3.16 marketplace_seller_analytics - Daily seller analytics aggregates
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_seller_analytics (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id         UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
  date              DATE NOT NULL,
  views             INTEGER NOT NULL DEFAULT 0,
  sales             INTEGER NOT NULL DEFAULT 0,
  revenue           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  unique_visitors   INTEGER NOT NULL DEFAULT 0,
  conversion_rate   DECIMAL(5,4) NOT NULL DEFAULT 0.0000 CHECK (conversion_rate BETWEEN 0.0000 AND 1.0000),
  average_rating    DECIMAL(3,2) DEFAULT 0.00 CHECK (average_rating IS NULL OR average_rating BETWEEN 0.00 AND 5.00),
  new_reviews       INTEGER NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_seller_analytics_date UNIQUE (seller_id, date)
);

COMMENT ON TABLE marketplace_seller_analytics IS 'Daily aggregated analytics for seller dashboards and reporting';

-- ----------------------------------------------------------------------------
-- 3.17 marketplace_product_analytics - Daily product analytics aggregates
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_product_analytics (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id          UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  views               INTEGER NOT NULL DEFAULT 0,
  downloads           INTEGER NOT NULL DEFAULT 0,
  sales               INTEGER NOT NULL DEFAULT 0,
  revenue             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  search_impressions  INTEGER NOT NULL DEFAULT 0,
  click_through_rate  DECIMAL(5,4) NOT NULL DEFAULT 0.0000 CHECK (click_through_rate BETWEEN 0.0000 AND 1.0000),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_product_analytics_date UNIQUE (product_id, date)
);

COMMENT ON TABLE marketplace_product_analytics IS 'Daily aggregated analytics for product performance and search visibility';

-- ----------------------------------------------------------------------------
-- 3.18 marketplace_search_logs - Search tracking for AI recommendations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_search_logs (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  query              TEXT NOT NULL,
  filters            JSONB DEFAULT '{}',
  results_count      INTEGER NOT NULL DEFAULT 0,
  clicked_product_id UUID REFERENCES marketplace_products(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_search_logs IS 'Search query logs used for AI recommendation engine training and search analytics';
COMMENT ON COLUMN marketplace_search_logs.filters IS 'JSONB: {subject, class_level, product_type, price_min, price_max, curriculum, sort_by}';

-- ----------------------------------------------------------------------------
-- 3.19 marketplace_ai_recommendations - AI recommendation tracking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_ai_recommendations (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id           UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  recommendation_type  TEXT NOT NULL,
  recommendation_reason TEXT,
  score                DECIMAL(5,4) NOT NULL DEFAULT 0.0000 CHECK (score BETWEEN 0.0000 AND 1.0000),
  was_clicked          BOOLEAN NOT NULL DEFAULT FALSE,
  was_purchased        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_ai_recommendations IS 'AI-generated product recommendations with click and conversion tracking';
COMMENT ON COLUMN marketplace_ai_recommendations.recommendation_type IS 'Type: similar_products, also_bought, trending, personalized, curriculum_based, subject_related';

-- ----------------------------------------------------------------------------
-- 3.20 marketplace_quality_checks - AI Quality Review records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_quality_checks (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id                 UUID NOT NULL REFERENCES marketplace_products(id) ON DELETE CASCADE,
  overall_score              DECIMAL(5,2) NOT NULL CHECK (overall_score BETWEEN 0.00 AND 100.00),
  grammar_score              DECIMAL(5,2) CHECK (grammar_score BETWEEN 0.00 AND 100.00),
  spelling_score             DECIMAL(5,2) CHECK (spelling_score BETWEEN 0.00 AND 100.00),
  formatting_score           DECIMAL(5,2) CHECK (formatting_score BETWEEN 0.00 AND 100.00),
  curriculum_alignment_score DECIMAL(5,2) CHECK (curriculum_alignment_score BETWEEN 0.00 AND 100.00),
  reading_level              DECIMAL(5,2),
  reading_level_label        TEXT,
  duplicate_check_result     JSONB DEFAULT '{}',
  accuracy_flag              BOOLEAN NOT NULL DEFAULT FALSE,
  accuracy_details           JSONB DEFAULT '{}',
  suggestions                TEXT[] DEFAULT '{}',
  flagged_issues             TEXT[] DEFAULT '{}',
  checked_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_quality_checks IS 'AI-powered quality review records for product content validation';
COMMENT ON COLUMN marketplace_quality_checks.duplicate_check_result IS 'JSONB: {is_duplicate: bool, similarity_score: float, matching_product_ids: []}';
COMMENT ON COLUMN marketplace_quality_checks.accuracy_details IS 'JSONB: {factual_errors: [], source_conflicts: [], confidence_score: float}';
COMMENT ON COLUMN marketplace_quality_checks.reading_level_label IS 'Human-readable label like "Grade 5" or "Intermediate"';

-- ----------------------------------------------------------------------------
-- 3.21 marketplace_disputes - Dispute management
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_disputes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     UUID NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  buyer_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id    UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
  reason       TEXT NOT NULL,
  description  TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'under_review', 'resolved', 'closed')),
  resolution   TEXT,
  resolved_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_disputes IS 'Dispute management for order conflicts between buyers and sellers';

-- ----------------------------------------------------------------------------
-- 3.22 marketplace_notifications - Marketplace-specific notifications
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  message    TEXT NOT NULL,
  data       JSONB DEFAULT '{}',
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_notifications IS 'In-app marketplace notifications for users (sellers and buyers)';
COMMENT ON COLUMN marketplace_notifications.type IS 'Notification type: sale, review, dispute, payout, product_approved, product_rejected, etc.';
COMMENT ON COLUMN marketplace_notifications.data IS 'JSONB payload with type-specific data (e.g., {order_id, product_id, amount})';

-- ----------------------------------------------------------------------------
-- 3.23 marketplace_saved_searches - Saved search filters
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS marketplace_saved_searches (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  filters    JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE marketplace_saved_searches IS 'Saved search filter configurations for quick marketplace browsing';
COMMENT ON COLUMN marketplace_saved_searches.filters IS 'JSONB: {query, subject, class_level, product_type, price_min, price_max, curriculum, sort_by}';

-- ============================================================================
-- SECTION 4: INDEXES
-- ============================================================================

-- ---- marketplace_categories indexes ----
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON marketplace_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON marketplace_categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_active_sort ON marketplace_categories(is_active, sort_order);

-- ---- seller_profiles indexes ----
CREATE INDEX IF NOT EXISTS idx_seller_profiles_user_id ON seller_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_seller_profiles_status ON seller_profiles(status);
CREATE INDEX IF NOT EXISTS idx_seller_profiles_verified ON seller_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_seller_profiles_rating ON seller_profiles(average_rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_seller_profiles_total_sales ON seller_profiles(total_sales DESC);

-- ---- marketplace_products indexes ----
-- B-tree indexes for common filter/sort columns
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON marketplace_products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON marketplace_products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON marketplace_products(status);
CREATE INDEX IF NOT EXISTS idx_products_product_type ON marketplace_products(product_type);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON marketplace_products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_published_at ON marketplace_products(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_price ON marketplace_products(price);
CREATE INDEX IF NOT EXISTS idx_products_rating ON marketplace_products(average_rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_products_total_sales ON marketplace_products(total_sales DESC);
CREATE INDEX IF NOT EXISTS idx_products_quality_score ON marketplace_products(quality_score DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_products_featured ON marketplace_products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_free ON marketplace_products(is_free) WHERE is_free = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON marketplace_products(deleted_at) WHERE deleted_at IS NOT NULL;

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_products_status_type ON marketplace_products(status, product_type);
CREATE INDEX IF NOT EXISTS idx_products_status_created ON marketplace_products(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_category_status ON marketplace_products(category_id, status);
CREATE INDEX IF NOT EXISTS idx_products_seller_status ON marketplace_products(seller_id, status);

-- GIN index for tag array searches
CREATE INDEX IF NOT EXISTS idx_products_tags_gin ON marketplace_products USING GIN(tags);

-- GIN index for full-text search
CREATE INDEX IF NOT EXISTS idx_products_fts_gin ON marketplace_products USING GIN(fts_document);

-- GIN index on JSONB columns
CREATE INDEX IF NOT EXISTS idx_products_preview_images_gin ON marketplace_products USING GIN(preview_images);
CREATE INDEX IF NOT EXISTS idx_products_license_config_gin ON marketplace_products USING GIN(license_config);

-- Trigram index for ILIKE/similarity searches on title
CREATE INDEX IF NOT EXISTS idx_products_title_trgm ON marketplace_products USING GIN(title gin_trgm_ops);

-- Partial index for active published products
CREATE INDEX IF NOT EXISTS idx_products_active_published ON marketplace_products(status, published_at DESC)
  WHERE status = 'approved' AND deleted_at IS NULL;

-- ---- marketplace_product_versions indexes ----
CREATE INDEX IF NOT EXISTS idx_product_versions_product_id ON marketplace_product_versions(product_id);
CREATE INDEX IF NOT EXISTS idx_product_versions_created_at ON marketplace_product_versions(created_at DESC);

-- ---- marketplace_carts indexes ----
CREATE INDEX IF NOT EXISTS idx_carts_user_id ON marketplace_carts(user_id);

-- ---- marketplace_cart_items indexes ----
CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON marketplace_cart_items(cart_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON marketplace_cart_items(product_id);

-- ---- marketplace_orders indexes ----
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON marketplace_orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON marketplace_orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON marketplace_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON marketplace_orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON marketplace_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_paid_at ON marketplace_orders(paid_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_flutterwave_tx_ref ON marketplace_orders(flutterwave_tx_ref) WHERE flutterwave_tx_ref IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_buyer_status ON marketplace_orders(buyer_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_seller_status ON marketplace_orders(seller_id, status);

-- ---- marketplace_order_items indexes ----
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON marketplace_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON marketplace_order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_seller_id ON marketplace_order_items(seller_id);

-- ---- marketplace_purchases indexes ----
CREATE INDEX IF NOT EXISTS idx_purchases_buyer_id ON marketplace_purchases(buyer_id);
CREATE INDEX IF NOT EXISTS idx_purchases_product_id ON marketplace_purchases(product_id);
CREATE INDEX IF NOT EXISTS idx_purchases_license_key ON marketplace_purchases(license_key);
CREATE INDEX IF NOT EXISTS idx_purchases_active ON marketplace_purchases(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_purchases_buyer_active ON marketplace_purchases(buyer_id, is_active);
CREATE INDEX IF NOT EXISTS idx_purchases_expires_at ON marketplace_purchases(expires_at) WHERE expires_at IS NOT NULL;

-- ---- marketplace_reviews indexes ----
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON marketplace_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_buyer_id ON marketplace_reviews(buyer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_seller_id ON marketplace_reviews(seller_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON marketplace_reviews(status);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON marketplace_reviews(rating DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_product_status ON marketplace_reviews(product_id, status);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON marketplace_reviews(created_at DESC);

-- ---- marketplace_review_helpful indexes ----
CREATE INDEX IF NOT EXISTS idx_review_helpful_review_id ON marketplace_review_helpful(review_id);
CREATE INDEX IF NOT EXISTS idx_review_helpful_user_id ON marketplace_review_helpful(user_id);

-- ---- marketplace_wishlists indexes ----
CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON marketplace_wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product_id ON marketplace_wishlists(product_id);

-- ---- marketplace_promo_codes indexes ----
CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON marketplace_promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_promo_codes_active ON marketplace_promo_codes(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_promo_codes_dates ON marketplace_promo_codes(starts_at, expires_at);

-- ---- marketplace_commission_rates indexes ----
CREATE INDEX IF NOT EXISTS idx_commission_rates_product_type ON marketplace_commission_rates(product_type);
CREATE INDEX IF NOT EXISTS idx_commission_rates_active ON marketplace_commission_rates(is_active) WHERE is_active = TRUE;

-- ---- marketplace_commission_records indexes ----
CREATE INDEX IF NOT EXISTS idx_commission_records_order_item_id ON marketplace_commission_records(order_item_id);
CREATE INDEX IF NOT EXISTS idx_commission_records_seller_id ON marketplace_commission_records(seller_id);
CREATE INDEX IF NOT EXISTS idx_commission_records_type ON marketplace_commission_records(commission_type);
CREATE INDEX IF NOT EXISTS idx_commission_records_created_at ON marketplace_commission_records(created_at DESC);

-- ---- marketplace_seller_analytics indexes ----
CREATE INDEX IF NOT EXISTS idx_seller_analytics_seller_id ON marketplace_seller_analytics(seller_id);
CREATE INDEX IF NOT EXISTS idx_seller_analytics_date ON marketplace_seller_analytics(date DESC);
CREATE INDEX IF NOT EXISTS idx_seller_analytics_seller_date ON marketplace_seller_analytics(seller_id, date DESC);

-- ---- marketplace_product_analytics indexes ----
CREATE INDEX IF NOT EXISTS idx_product_analytics_product_id ON marketplace_product_analytics(product_id);
CREATE INDEX IF NOT EXISTS idx_product_analytics_date ON marketplace_product_analytics(date DESC);
CREATE INDEX IF NOT EXISTS idx_product_analytics_product_date ON marketplace_product_analytics(product_id, date DESC);

-- ---- marketplace_search_logs indexes ----
CREATE INDEX IF NOT EXISTS idx_search_logs_user_id ON marketplace_search_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_search_logs_created_at ON marketplace_search_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_search_logs_query ON marketplace_search_logs(query);
CREATE INDEX IF NOT EXISTS idx_search_logs_clicked_product ON marketplace_search_logs(clicked_product_id) WHERE clicked_product_id IS NOT NULL;

-- ---- marketplace_ai_recommendations indexes ----
CREATE INDEX IF NOT EXISTS idx_ai_recs_user_id ON marketplace_ai_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_recs_product_id ON marketplace_ai_recommendations(product_id);
CREATE INDEX IF NOT EXISTS idx_ai_recs_type ON marketplace_ai_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_ai_recs_score ON marketplace_ai_recommendations(score DESC);
CREATE INDEX IF NOT EXISTS idx_ai_recs_user_type ON marketplace_ai_recommendations(user_id, recommendation_type);
CREATE INDEX IF NOT EXISTS idx_ai_recs_clicked ON marketplace_ai_recommendations(was_clicked) WHERE was_clicked = TRUE;
CREATE INDEX IF NOT EXISTS idx_ai_recs_purchased ON marketplace_ai_recommendations(was_purchased) WHERE was_purchased = TRUE;

-- ---- marketplace_quality_checks indexes ----
CREATE INDEX IF NOT EXISTS idx_quality_checks_product_id ON marketplace_quality_checks(product_id);
CREATE INDEX IF NOT EXISTS idx_quality_checks_overall_score ON marketplace_quality_checks(overall_score DESC);
CREATE INDEX IF NOT EXISTS idx_quality_checks_checked_at ON marketplace_quality_checks(checked_at DESC);

-- ---- marketplace_disputes indexes ----
CREATE INDEX IF NOT EXISTS idx_disputes_order_id ON marketplace_disputes(order_id);
CREATE INDEX IF NOT EXISTS idx_disputes_buyer_id ON marketplace_disputes(buyer_id);
CREATE INDEX IF NOT EXISTS idx_disputes_seller_id ON marketplace_disputes(seller_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON marketplace_disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_created_at ON marketplace_disputes(created_at DESC);

-- ---- marketplace_notifications indexes ----
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON marketplace_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON marketplace_notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON marketplace_notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON marketplace_notifications(created_at DESC);

-- ---- marketplace_saved_searches indexes ----
CREATE INDEX IF NOT EXISTS idx_saved_searches_user_id ON marketplace_saved_searches(user_id);

-- ============================================================================
-- SECTION 5: TRIGGERS
-- ============================================================================

-- ---- Auto-update updated_at on all tables with that column ----
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_name = 'updated_at'
      AND table_name IN (
        'marketplace_categories',
        'seller_profiles',
        'marketplace_products',
        'marketplace_carts',
        'marketplace_orders',
        'marketplace_reviews',
        'marketplace_promo_codes',
        'marketplace_commission_rates',
        'marketplace_disputes'
      )
    GROUP BY table_name
  LOOP
    EXECUTE format(
      'CREATE OR REPLACE TRIGGER trg_%s_updated_at
         BEFORE UPDATE ON %I
         FOR EACH ROW
         EXECUTE FUNCTION update_updated_at_column()',
      t, t
    );
  END LOOP;
END;
$$;

-- ---- Auto-update product average_rating and total_reviews ----
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE marketplace_products
    SET
      average_rating = (
        SELECT COALESCE(AVG(rating), 0.00)
        FROM marketplace_reviews
        WHERE product_id = NEW.product_id AND status = 'published'
      ),
      total_reviews = (
        SELECT COUNT(*)
        FROM marketplace_reviews
        WHERE product_id = NEW.product_id AND status = 'published'
      )
    WHERE id = NEW.product_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE marketplace_products
    SET
      average_rating = (
        SELECT COALESCE(AVG(rating), 0.00)
        FROM marketplace_reviews
        WHERE product_id = NEW.product_id AND status = 'published'
      ),
      total_reviews = (
        SELECT COUNT(*)
        FROM marketplace_reviews
        WHERE product_id = NEW.product_id AND status = 'published'
      )
    WHERE id = NEW.product_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE marketplace_products
    SET
      average_rating = (
        SELECT COALESCE(AVG(rating), 0.00)
        FROM marketplace_reviews
        WHERE product_id = OLD.product_id AND status = 'published'
      ),
      total_reviews = (
        SELECT COUNT(*)
        FROM marketplace_reviews
        WHERE product_id = OLD.product_id AND status = 'published'
      )
    WHERE id = OLD.product_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_product_rating ON marketplace_reviews;
DROP TRIGGER IF EXISTS trg_product_rating ON marketplace_reviews;
CREATE TRIGGER trg_product_rating
  AFTER INSERT OR UPDATE OF rating, status OR DELETE ON marketplace_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_product_rating();

-- ---- Auto-update product total_sales and total_revenue on purchase ----
CREATE OR REPLACE FUNCTION update_product_sales()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE marketplace_products
  SET
    total_sales = (
      SELECT COUNT(*)
      FROM marketplace_purchases
      WHERE product_id = NEW.product_id AND is_active = TRUE
    ),
    total_revenue = (
      SELECT COALESCE(SUM(oi.price_at_purchase), 0.00)
      FROM marketplace_order_items oi
      WHERE oi.product_id = NEW.product_id
    )
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_product_sales ON marketplace_purchases;
DROP TRIGGER IF EXISTS trg_product_sales ON marketplace_purchases;
CREATE TRIGGER trg_product_sales
  AFTER INSERT OR UPDATE OF is_active ON marketplace_purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_product_sales();

-- ---- Auto-update seller aggregate stats ----
CREATE OR REPLACE FUNCTION update_seller_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE seller_profiles
  SET
    total_products = (
      SELECT COUNT(*)
      FROM marketplace_products
      WHERE seller_id = NEW.seller_id AND deleted_at IS NULL AND status != 'archived'
    ),
    average_rating = (
      SELECT COALESCE(AVG(average_rating), 0.00)
      FROM marketplace_products
      WHERE seller_id = NEW.seller_id AND deleted_at IS NULL AND status = 'approved'
    ),
    total_reviews = (
      SELECT COALESCE(SUM(total_reviews), 0)
      FROM marketplace_products
      WHERE seller_id = NEW.seller_id AND deleted_at IS NULL AND status = 'approved'
    )
  WHERE id = NEW.seller_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_seller_stats ON marketplace_products;
DROP TRIGGER IF EXISTS trg_seller_stats ON marketplace_products;
CREATE TRIGGER trg_seller_stats
  AFTER INSERT OR UPDATE OF status, average_rating, total_reviews OR DELETE ON marketplace_products
  FOR EACH ROW
  EXECUTE FUNCTION update_seller_stats();

-- ---- Auto-increment review helpful_count ----
CREATE OR REPLACE FUNCTION update_review_helpful_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE marketplace_reviews
    SET helpful_count = helpful_count + 1
    WHERE id = NEW.review_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE marketplace_reviews
    SET helpful_count = GREATEST(helpful_count - 1, 0)
    WHERE id = OLD.review_id;
    RETURN OLD;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_review_helpful_count ON marketplace_review_helpful;
DROP TRIGGER IF EXISTS trg_review_helpful_count ON marketplace_review_helpful;
CREATE TRIGGER trg_review_helpful_count
  AFTER INSERT OR DELETE ON marketplace_review_helpful
  FOR EACH ROW
  EXECUTE FUNCTION update_review_helpful_count();

-- ---- Auto-set published_at when product is approved ----
CREATE OR REPLACE FUNCTION set_product_published_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    NEW.published_at = COALESCE(NEW.published_at, NOW());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_product_published_at ON marketplace_products;
DROP TRIGGER IF EXISTS trg_product_published_at ON marketplace_products;
CREATE TRIGGER trg_product_published_at
  BEFORE UPDATE OF status ON marketplace_products
  FOR EACH ROW
  EXECUTE FUNCTION set_product_published_at();

-- ---- Auto-set verified purchase flag on reviews ----
CREATE OR REPLACE FUNCTION set_review_verified_purchase()
RETURNS TRIGGER AS $$
BEGIN
  NEW.is_verified_purchase = EXISTS (
    SELECT 1
    FROM marketplace_purchases p
    WHERE p.buyer_id = NEW.buyer_id
      AND p.product_id = NEW.product_id
      AND p.is_active = TRUE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_review_verified ON marketplace_reviews;
DROP TRIGGER IF EXISTS trg_review_verified ON marketplace_reviews;
CREATE TRIGGER trg_review_verified
  BEFORE INSERT ON marketplace_reviews
  FOR EACH ROW
  EXECUTE FUNCTION set_review_verified_purchase();

-- ---- Auto-increment promo code current_uses ----
CREATE OR REPLACE FUNCTION increment_promo_uses()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.promo_code_id IS NOT NULL AND (OLD.promo_code_id IS NULL OR OLD.promo_code_id != NEW.promo_code_id) THEN
    UPDATE marketplace_promo_codes
    SET current_uses = current_uses + 1
    WHERE id = NEW.promo_code_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_promo_uses ON marketplace_orders;
DROP TRIGGER IF EXISTS trg_promo_uses ON marketplace_orders;
CREATE TRIGGER trg_promo_uses
  AFTER INSERT OR UPDATE OF promo_code_id ON marketplace_orders
  FOR EACH ROW
  EXECUTE FUNCTION increment_promo_uses();

-- ============================================================================
-- SECTION 6: ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all marketplace tables
ALTER TABLE marketplace_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_product_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_review_helpful ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_commission_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_commission_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_seller_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_product_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_search_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_quality_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_saved_searches ENABLE ROW LEVEL SECURITY;

-- Helper: check if user is a super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'super_admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: check if user is a marketplace admin
CREATE OR REPLACE FUNCTION is_marketplace_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' IN ('super_admin', 'marketplace_admin')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: get seller profile id for current user
CREATE OR REPLACE FUNCTION current_seller_id()
RETURNS UUID AS $$
  SELECT id FROM seller_profiles WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- RLS: marketplace_categories (public read, admin write)
-- ============================================================================
DROP POLICY IF EXISTS "Categories are publicly readable" ON marketplace_categories;
CREATE POLICY "Categories are publicly readable"
  ON marketplace_categories FOR SELECT
  USING (is_active = TRUE OR is_marketplace_admin());

DROP POLICY IF EXISTS "Admins can manage categories" ON marketplace_categories;
CREATE POLICY "Admins can manage categories"
  ON marketplace_categories FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: seller_profiles (public read limited, self write, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Seller profiles are publicly readable" ON seller_profiles;
CREATE POLICY "Seller profiles are publicly readable"
  ON seller_profiles FOR SELECT
  USING (TRUE);  -- Public can view seller profiles for trust/transparency

DROP POLICY IF EXISTS "Sellers can update own profile" ON seller_profiles;
CREATE POLICY "Sellers can update own profile"
  ON seller_profiles FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Sellers can insert own profile" ON seller_profiles;
CREATE POLICY "Sellers can insert own profile"
  ON seller_profiles FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can manage all seller profiles" ON seller_profiles;
CREATE POLICY "Admins can manage all seller profiles"
  ON seller_profiles FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_products (public read approved, seller CRUD own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Approved products are publicly readable" ON marketplace_products;
CREATE POLICY "Approved products are publicly readable"
  ON marketplace_products FOR SELECT
  USING (
    (status = 'approved' AND deleted_at IS NULL)
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Sellers can insert own products" ON marketplace_products;
CREATE POLICY "Sellers can insert own products"
  ON marketplace_products FOR INSERT
  WITH CHECK (seller_id = current_seller_id() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Sellers can update own products" ON marketplace_products;
CREATE POLICY "Sellers can update own products"
  ON marketplace_products FOR UPDATE
  USING (seller_id = current_seller_id() OR is_marketplace_admin())
  WITH CHECK (seller_id = current_seller_id() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Sellers can soft-delete own products" ON marketplace_products;
CREATE POLICY "Sellers can soft-delete own products"
  ON marketplace_products FOR DELETE
  USING (seller_id = current_seller_id() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_product_versions (seller see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Product versions visible to seller and admin" ON marketplace_product_versions;
CREATE POLICY "Product versions visible to seller and admin"
  ON marketplace_product_versions FOR SELECT
  USING (
    product_id IN (SELECT id FROM marketplace_products WHERE seller_id = current_seller_id())
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Sellers can manage own product versions" ON marketplace_product_versions;
CREATE POLICY "Sellers can manage own product versions"
  ON marketplace_product_versions FOR INSERT
  WITH CHECK (
    product_id IN (SELECT id FROM marketplace_products WHERE seller_id = current_seller_id())
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Sellers can update own product versions" ON marketplace_product_versions;
CREATE POLICY "Sellers can update own product versions"
  ON marketplace_product_versions FOR UPDATE
  USING (
    product_id IN (SELECT id FROM marketplace_products WHERE seller_id = current_seller_id())
    OR is_marketplace_admin()
  );

-- ============================================================================
-- RLS: marketplace_carts (users see own cart only)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own cart" ON marketplace_carts;
CREATE POLICY "Users can see own cart"
  ON marketplace_carts FOR SELECT
  USING (user_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Users can insert own cart" ON marketplace_carts;
CREATE POLICY "Users can insert own cart"
  ON marketplace_carts FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own cart" ON marketplace_carts;
CREATE POLICY "Users can update own cart"
  ON marketplace_carts FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own cart" ON marketplace_carts;
CREATE POLICY "Users can delete own cart"
  ON marketplace_carts FOR DELETE
  USING (user_id = auth.uid() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_cart_items (users manage own cart items)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own cart items" ON marketplace_cart_items;
CREATE POLICY "Users can see own cart items"
  ON marketplace_cart_items FOR SELECT
  USING (cart_id IN (SELECT id FROM marketplace_carts WHERE user_id = auth.uid()) OR is_marketplace_admin());

DROP POLICY IF EXISTS "Users can insert own cart items" ON marketplace_cart_items;
CREATE POLICY "Users can insert own cart items"
  ON marketplace_cart_items FOR INSERT
  WITH CHECK (cart_id IN (SELECT id FROM marketplace_carts WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can update own cart items" ON marketplace_cart_items;
CREATE POLICY "Users can update own cart items"
  ON marketplace_cart_items FOR UPDATE
  USING (cart_id IN (SELECT id FROM marketplace_carts WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can delete own cart items" ON marketplace_cart_items;
CREATE POLICY "Users can delete own cart items"
  ON marketplace_cart_items FOR DELETE
  USING (cart_id IN (SELECT id FROM marketplace_carts WHERE user_id = auth.uid()) OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_orders (buyer/seller see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own orders" ON marketplace_orders;
CREATE POLICY "Users can see own orders"
  ON marketplace_orders FOR SELECT
  USING (
    buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Buyers can create orders" ON marketplace_orders;
CREATE POLICY "Buyers can create orders"
  ON marketplace_orders FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

DROP POLICY IF EXISTS "Buyers and sellers can update relevant orders" ON marketplace_orders;
CREATE POLICY "Buyers and sellers can update relevant orders"
  ON marketplace_orders FOR UPDATE
  USING (
    buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

-- ============================================================================
-- RLS: marketplace_order_items (buyer/seller see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own order items" ON marketplace_order_items;
CREATE POLICY "Users can see own order items"
  ON marketplace_order_items FOR SELECT
  USING (
    order_id IN (SELECT id FROM marketplace_orders WHERE buyer_id = auth.uid())
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "System creates order items" ON marketplace_order_items;
CREATE POLICY "System creates order items"
  ON marketplace_order_items FOR INSERT
  WITH CHECK (is_marketplace_admin() OR auth.uid() IS NOT NULL);

-- ============================================================================
-- RLS: marketplace_purchases (buyers see own purchases)
-- ============================================================================
DROP POLICY IF EXISTS "Buyers can see own purchases" ON marketplace_purchases;
CREATE POLICY "Buyers can see own purchases"
  ON marketplace_purchases FOR SELECT
  USING (buyer_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "System creates purchases" ON marketplace_purchases;
CREATE POLICY "System creates purchases"
  ON marketplace_purchases FOR INSERT
  WITH CHECK (is_marketplace_admin() OR buyer_id = auth.uid());

DROP POLICY IF EXISTS "Buyers can update own purchase download count" ON marketplace_purchases;
CREATE POLICY "Buyers can update own purchase download count"
  ON marketplace_purchases FOR UPDATE
  USING (buyer_id = auth.uid() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_reviews (public read published, buyer write own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Published reviews are publicly readable" ON marketplace_reviews;
CREATE POLICY "Published reviews are publicly readable"
  ON marketplace_reviews FOR SELECT
  USING (
    status = 'published'
    OR buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Buyers can insert own reviews" ON marketplace_reviews;
CREATE POLICY "Buyers can insert own reviews"
  ON marketplace_reviews FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

DROP POLICY IF EXISTS "Buyers can update own reviews, sellers can respond" ON marketplace_reviews;
CREATE POLICY "Buyers can update own reviews, sellers can respond"
  ON marketplace_reviews FOR UPDATE
  USING (
    buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Buyers can delete own reviews" ON marketplace_reviews;
CREATE POLICY "Buyers can delete own reviews"
  ON marketplace_reviews FOR DELETE
  USING (buyer_id = auth.uid() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_review_helpful (authenticated users can vote)
-- ============================================================================
DROP POLICY IF EXISTS "Anyone can see helpful votes" ON marketplace_review_helpful;
CREATE POLICY "Anyone can see helpful votes"
  ON marketplace_review_helpful FOR SELECT
  USING (TRUE);

DROP POLICY IF EXISTS "Authenticated users can vote helpful" ON marketplace_review_helpful;
CREATE POLICY "Authenticated users can vote helpful"
  ON marketplace_review_helpful FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can remove own helpful vote" ON marketplace_review_helpful;
CREATE POLICY "Users can remove own helpful vote"
  ON marketplace_review_helpful FOR DELETE
  USING (user_id = auth.uid() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_wishlists (users manage own wishlist)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own wishlist" ON marketplace_wishlists;
CREATE POLICY "Users can see own wishlist"
  ON marketplace_wishlists FOR SELECT
  USING (user_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Users can add to own wishlist" ON marketplace_wishlists;
CREATE POLICY "Users can add to own wishlist"
  ON marketplace_wishlists FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can remove from own wishlist" ON marketplace_wishlists;
CREATE POLICY "Users can remove from own wishlist"
  ON marketplace_wishlists FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- RLS: marketplace_promo_codes (admin only management, limited public read)
-- ============================================================================
DROP POLICY IF EXISTS "Active promo codes are readable for validation" ON marketplace_promo_codes;
CREATE POLICY "Active promo codes are readable for validation"
  ON marketplace_promo_codes FOR SELECT
  USING (is_active = TRUE OR is_marketplace_admin());

DROP POLICY IF EXISTS "Only admins can manage promo codes" ON marketplace_promo_codes;
CREATE POLICY "Only admins can manage promo codes"
  ON marketplace_promo_codes FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_commission_rates (admin only)
-- ============================================================================
DROP POLICY IF EXISTS "Commission rates readable by admins" ON marketplace_commission_rates;
CREATE POLICY "Commission rates readable by admins"
  ON marketplace_commission_rates FOR SELECT
  USING (is_marketplace_admin());

DROP POLICY IF EXISTS "Only admins can manage commission rates" ON marketplace_commission_rates;
CREATE POLICY "Only admins can manage commission rates"
  ON marketplace_commission_rates FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_commission_records (admin and relevant seller)
-- ============================================================================
DROP POLICY IF EXISTS "Sellers can see own commission records" ON marketplace_commission_records;
CREATE POLICY "Sellers can see own commission records"
  ON marketplace_commission_records FOR SELECT
  USING (seller_id = current_seller_id() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Only admins can manage commission records" ON marketplace_commission_records;
CREATE POLICY "Only admins can manage commission records"
  ON marketplace_commission_records FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_seller_analytics (sellers see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Sellers can see own analytics" ON marketplace_seller_analytics;
CREATE POLICY "Sellers can see own analytics"
  ON marketplace_seller_analytics FOR SELECT
  USING (seller_id = current_seller_id() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Only admins can manage seller analytics" ON marketplace_seller_analytics;
CREATE POLICY "Only admins can manage seller analytics"
  ON marketplace_seller_analytics FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_product_analytics (sellers see own products, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Sellers can see own product analytics" ON marketplace_product_analytics;
CREATE POLICY "Sellers can see own product analytics"
  ON marketplace_product_analytics FOR SELECT
  USING (
    product_id IN (SELECT id FROM marketplace_products WHERE seller_id = current_seller_id())
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Only admins can manage product analytics" ON marketplace_product_analytics;
CREATE POLICY "Only admins can manage product analytics"
  ON marketplace_product_analytics FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_search_logs (admin only read/write)
-- ============================================================================
DROP POLICY IF EXISTS "System can log searches" ON marketplace_search_logs;
CREATE POLICY "System can log searches"
  ON marketplace_search_logs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can view search logs" ON marketplace_search_logs;
CREATE POLICY "Admins can view search logs"
  ON marketplace_search_logs FOR SELECT
  USING (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_ai_recommendations (users see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own recommendations" ON marketplace_ai_recommendations;
CREATE POLICY "Users can see own recommendations"
  ON marketplace_ai_recommendations FOR SELECT
  USING (user_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "System can create recommendations" ON marketplace_ai_recommendations;
CREATE POLICY "System can create recommendations"
  ON marketplace_ai_recommendations FOR INSERT
  WITH CHECK (TRUE);  -- System-generated

DROP POLICY IF EXISTS "System can update recommendation tracking" ON marketplace_ai_recommendations;
CREATE POLICY "System can update recommendation tracking"
  ON marketplace_ai_recommendations FOR UPDATE
  USING (is_marketplace_admin() OR user_id = auth.uid());

-- ============================================================================
-- RLS: marketplace_quality_checks (sellers see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Sellers can see quality checks for own products" ON marketplace_quality_checks;
CREATE POLICY "Sellers can see quality checks for own products"
  ON marketplace_quality_checks FOR SELECT
  USING (
    product_id IN (SELECT id FROM marketplace_products WHERE seller_id = current_seller_id())
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Only admins can manage quality checks" ON marketplace_quality_checks;
CREATE POLICY "Only admins can manage quality checks"
  ON marketplace_quality_checks FOR ALL
  USING (is_marketplace_admin())
  WITH CHECK (is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_disputes (buyer/seller see own, admin full)
-- ============================================================================
DROP POLICY IF EXISTS "Parties can see own disputes" ON marketplace_disputes;
CREATE POLICY "Parties can see own disputes"
  ON marketplace_disputes FOR SELECT
  USING (
    buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

DROP POLICY IF EXISTS "Buyers can create disputes" ON marketplace_disputes;
CREATE POLICY "Buyers can create disputes"
  ON marketplace_disputes FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

DROP POLICY IF EXISTS "Parties and admins can update disputes" ON marketplace_disputes;
CREATE POLICY "Parties and admins can update disputes"
  ON marketplace_disputes FOR UPDATE
  USING (
    buyer_id = auth.uid()
    OR seller_id = current_seller_id()
    OR is_marketplace_admin()
  );

-- ============================================================================
-- RLS: marketplace_notifications (users see own)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own notifications" ON marketplace_notifications;
CREATE POLICY "Users can see own notifications"
  ON marketplace_notifications FOR SELECT
  USING (user_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "System can create notifications" ON marketplace_notifications;
CREATE POLICY "System can create notifications"
  ON marketplace_notifications FOR INSERT
  WITH CHECK (TRUE);  -- System-generated

DROP POLICY IF EXISTS "Users can update own notifications (mark read)" ON marketplace_notifications;
CREATE POLICY "Users can update own notifications (mark read)"
  ON marketplace_notifications FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own notifications" ON marketplace_notifications;
CREATE POLICY "Users can delete own notifications"
  ON marketplace_notifications FOR DELETE
  USING (user_id = auth.uid() OR is_marketplace_admin());

-- ============================================================================
-- RLS: marketplace_saved_searches (users manage own)
-- ============================================================================
DROP POLICY IF EXISTS "Users can see own saved searches" ON marketplace_saved_searches;
CREATE POLICY "Users can see own saved searches"
  ON marketplace_saved_searches FOR SELECT
  USING (user_id = auth.uid() OR is_marketplace_admin());

DROP POLICY IF EXISTS "Users can create own saved searches" ON marketplace_saved_searches;
CREATE POLICY "Users can create own saved searches"
  ON marketplace_saved_searches FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own saved searches" ON marketplace_saved_searches;
CREATE POLICY "Users can delete own saved searches"
  ON marketplace_saved_searches FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- SECTION 7: FUNCTIONS - Search, Recommendations, Quality Checks
-- ============================================================================

-- ---- Full-text search function for marketplace products ----
CREATE OR REPLACE FUNCTION marketplace_search(
  search_query   TEXT,
  p_product_type marketplace_product_type DEFAULT NULL,
  p_category_id  UUID DEFAULT NULL,
  p_subject      TEXT DEFAULT NULL,
  p_class_level  TEXT DEFAULT NULL,
  p_curriculum   TEXT DEFAULT NULL,
  p_price_min    DECIMAL DEFAULT NULL,
  p_price_max    DECIMAL DEFAULT NULL,
  p_license_type marketplace_license_type DEFAULT NULL,
  p_tags         TEXT[] DEFAULT NULL,
  p_is_free      BOOLEAN DEFAULT NULL,
  p_sort_by      TEXT DEFAULT 'relevance',
  p_limit        INTEGER DEFAULT 20,
  p_offset       INTEGER DEFAULT 0
)
RETURNS TABLE (
  id                UUID,
  title             TEXT,
  slug              TEXT,
  description       TEXT,
  product_type      marketplace_product_type,
  subject           TEXT,
  class_level       TEXT,
  curriculum        TEXT,
  price             DECIMAL,
  original_price    DECIMAL,
  currency          TEXT,
  license_type      marketplace_license_type,
  tags              TEXT[],
  preview_images    JSONB,
  average_rating    DECIMAL,
  total_reviews     INTEGER,
  total_sales       INTEGER,
  quality_score     DECIMAL,
  is_free           BOOLEAN,
  is_featured       BOOLEAN,
  seller_id         UUID,
  seller_name       TEXT,
  published_at      TIMESTAMPTZ,
  search_rank       REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.title,
    p.slug,
    p.description,
    p.product_type,
    p.subject,
    p.class_level,
    p.curriculum,
    p.price,
    p.original_price,
    p.currency,
    p.license_type,
    p.tags,
    p.preview_images,
    p.average_rating,
    p.total_reviews,
    p.total_sales,
    p.quality_score,
    p.is_free,
    p.is_featured,
    p.seller_id,
    sp.display_name AS seller_name,
    p.published_at,
    ts_rank(p.fts_document, websearch_to_tsquery('english', search_query)) AS search_rank
  FROM marketplace_products p
  INNER JOIN seller_profiles sp ON p.seller_id = sp.id
  WHERE p.status = 'approved'
    AND p.deleted_at IS NULL
    -- Full-text search
    AND p.fts_document @@ websearch_to_tsquery('english', search_query)
    -- Optional filters
    AND (p_product_type IS NULL OR p.product_type = p_product_type)
    AND (p_category_id IS NULL OR p.category_id = p_category_id)
    AND (p_subject IS NULL OR p.subject ILIKE '%' || p_subject || '%')
    AND (p_class_level IS NULL OR p.class_level = p_class_level)
    AND (p_curriculum IS NULL OR p.curriculum ILIKE '%' || p_curriculum || '%')
    AND (p_price_min IS NULL OR p.price >= p_price_min)
    AND (p_price_max IS NULL OR p.price <= p_price_max)
    AND (p_license_type IS NULL OR p.license_type = p_license_type)
    AND (p_is_free IS NULL OR p.is_free = p_is_free)
    AND (p_tags IS NULL OR p.tags && p_tags)
  ORDER BY
    CASE p_sort_by
      WHEN 'relevance' THEN ts_rank(p.fts_document, websearch_to_tsquery('english', search_query))
      ELSE 0
    END DESC,
    CASE p_sort_by
      WHEN 'newest' THEN EXTRACT(EPOCH FROM p.published_at)
      WHEN 'price_low' THEN -p.price
      WHEN 'price_high' THEN p.price
      WHEN 'rating' THEN p.average_rating
      WHEN 'popular' THEN p.total_sales
      ELSE 0
    END DESC,
    p.is_featured DESC,
    p.published_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION marketplace_search IS 'Full-text search with weighted ranking and multi-faceted filtering for marketplace products';

-- ---- AI Recommendation scoring function ----
CREATE OR REPLACE FUNCTION calculate_recommendation_score(
  p_user_id    UUID,
  p_product_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
  v_score            DECIMAL := 0.0;
  v_user_purchases   UUID[];
  v_user_tags        TEXT[];
  v_product_tags     TEXT[];
  v_tag_overlap      INTEGER;
  v_purchase_count   INTEGER;
  v_product_rating   DECIMAL;
  v_product_sales    INTEGER;
  v_quality_score    DECIMAL;
BEGIN
  -- Get user's purchase history product categories
  SELECT array_agg(DISTINCT product_id) INTO v_user_purchases
  FROM marketplace_purchases
  WHERE buyer_id = p_user_id AND is_active = TRUE;

  -- Get tags from user's purchased products
  SELECT array_agg(DISTINCT unnest_tags) INTO v_user_tags
  FROM (
    SELECT unnest(tags) AS unnest_tags
    FROM marketplace_products
    WHERE id = ANY(v_user_purchases) AND tags IS NOT NULL
  ) sub;

  -- Get product tags
  SELECT tags INTO v_product_tags
  FROM marketplace_products
  WHERE id = p_product_id;

  -- 1. Tag overlap score (0-0.30): How many tags overlap with user's interests
  IF v_user_tags IS NOT NULL AND v_product_tags IS NOT NULL THEN
    SELECT COUNT(*) INTO v_tag_overlap
    FROM (SELECT unnest(v_user_tags) INTERSECT SELECT unnest(v_product_tags)) overlap;
    v_score := v_score + LEAST(v_tag_overlap::DECIMAL / 10.0, 0.30);
  END IF;

  -- 2. Quality score component (0-0.25)
  SELECT COALESCE(quality_score, 0) INTO v_quality_score
  FROM marketplace_products WHERE id = p_product_id;
  v_score := v_score + (v_quality_score / 100.0) * 0.25;

  -- 3. Rating component (0-0.20)
  SELECT COALESCE(average_rating, 0) INTO v_product_rating
  FROM marketplace_products WHERE id = p_product_id;
  v_score := v_score + (v_product_rating / 5.0) * 0.20;

  -- 4. Popularity component (0-0.15): Normalized sales
  SELECT COALESCE(total_sales, 0) INTO v_product_sales
  FROM marketplace_products WHERE id = p_product_id;
  v_score := v_score + LEAST(v_product_sales::DECIMAL / 1000.0, 0.15);

  -- 5. Same-subject bonus (0-0.10)
  IF v_user_purchases IS NOT NULL THEN
    SELECT COUNT(*) INTO v_purchase_count
    FROM marketplace_products
    WHERE id = ANY(v_user_purchases)
      AND subject = (SELECT subject FROM marketplace_products WHERE id = p_product_id)
      AND subject IS NOT NULL;
    v_score := v_score + LEAST(v_purchase_count::DECIMAL * 0.05, 0.10);
  END IF;

  RETURN LEAST(v_score, 1.0000);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION calculate_recommendation_score IS 'Calculates a 0-1 recommendation score for a user-product pair based on tag overlap, quality, rating, popularity, and subject affinity';

-- ---- Quality check function ----
CREATE OR REPLACE FUNCTION run_product_quality_check(
  p_product_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_overall_score    DECIMAL(5,2);
  v_grammar_score    DECIMAL(5,2) := 0.00;
  v_spelling_score   DECIMAL(5,2) := 0.00;
  v_formatting_score DECIMAL(5,2) := 0.00;
  v_curriculum_score DECIMAL(5,2) := 0.00;
  v_reading_level    DECIMAL(5,2);
  v_reading_label    TEXT;
  v_accuracy_flag    BOOLEAN := FALSE;
  v_suggestions      TEXT[] := '{}';
  v_flagged_issues   TEXT[] := '{}';
  v_quality_status   quality_check_status;
  v_check_id         UUID;
  v_description      TEXT;
  v_title            TEXT;
BEGIN
  -- Fetch product content
  SELECT title, description INTO v_title, v_description
  FROM marketplace_products WHERE id = p_product_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product % not found', p_product_id;
  END IF;

  -- ---- Grammar heuristic scoring ----
  -- This is a simplified heuristic; in production, integrate with AI/NLP service
  v_grammar_score := CASE
    WHEN char_length(v_description) < 50 THEN 40.00
    WHEN char_length(v_description) < 200 THEN 60.00
    WHEN char_length(v_description) >= 200 THEN 75.00
    ELSE 50.00
  END;

  -- Add bonus for structured content (headings, lists, etc.)
  IF v_description ~ '(^|\n)#{1,6}\s' THEN  -- Markdown headings
    v_grammar_score := LEAST(v_grammar_score + 10, 100);
  END IF;

  -- ---- Spelling heuristic ----
  v_spelling_score := 85.00;  -- Placeholder; integrate spell-check API in production

  -- ---- Formatting heuristic ----
  v_formatting_score := CASE
    WHEN v_description ~ '\n{2,}' THEN 80.00   -- Has paragraph breaks
    WHEN v_description ~ '\n' THEN 65.00        -- Has line breaks
    ELSE 50.00                                    -- No line breaks
  END;

  IF v_description ~ '\*\*|__|\*|_' THEN  -- Markdown formatting
    v_formatting_score := LEAST(v_formatting_score + 10, 100);
  END IF;

  -- ---- Curriculum alignment ----
  v_curriculum_score := 70.00;  -- Placeholder; integrate with curriculum DB in production

  -- ---- Reading level (Flesch-Kincaid approximation) ----
  v_reading_level := 8.0;  -- Default grade level; calculate from content in production
  v_reading_label := CASE
    WHEN v_reading_level <= 4 THEN 'Elementary'
    WHEN v_reading_level <= 6 THEN 'Middle School'
    WHEN v_reading_level <= 8 THEN 'Junior Secondary'
    WHEN v_reading_level <= 10 THEN 'Senior Secondary'
    WHEN v_reading_level <= 12 THEN 'Advanced Secondary'
    ELSE 'University Level'
  END;

  -- ---- Calculate overall score (weighted) ----
  v_overall_score := (
    v_grammar_score * 0.20 +
    v_spelling_score * 0.15 +
    v_formatting_score * 0.20 +
    v_curriculum_score * 0.45
  );

  -- ---- Generate suggestions ----
  IF v_grammar_score < 70 THEN
    v_suggestions := array_append(v_suggestions, 'Consider improving grammar and sentence structure');
  END IF;
  IF v_formatting_score < 70 THEN
    v_suggestions := array_append(v_suggestions, 'Add formatting: headings, bullet points, or numbered lists');
  END IF;
  IF char_length(v_description) < 200 THEN
    v_suggestions := array_append(v_suggestions, 'Description is too short; add more detail for better discoverability');
  END IF;

  -- ---- Flag issues ----
  IF v_grammar_score < 50 THEN
    v_flagged_issues := array_append(v_flagged_issues, 'Poor grammar quality detected');
  END IF;
  IF v_spelling_score < 50 THEN
    v_flagged_issues := array_append(v_flagged_issues, 'Potential spelling issues detected');
  END IF;

  -- ---- Determine quality status ----
  v_quality_status := CASE
    WHEN v_overall_score >= 80 THEN 'passed'
    WHEN v_overall_score >= 60 THEN 'needs_improvement'
    ELSE 'failed'
  END;

  -- ---- Insert quality check record ----
  INSERT INTO marketplace_quality_checks (
    product_id, overall_score, grammar_score, spelling_score,
    formatting_score, curriculum_alignment_score, reading_level,
    reading_level_label, accuracy_flag, accuracy_details,
    suggestions, flagged_issues
  ) VALUES (
    p_product_id, v_overall_score, v_grammar_score, v_spelling_score,
    v_formatting_score, v_curriculum_score, v_reading_level,
    v_reading_label, v_accuracy_flag,
    jsonb_build_object('factual_errors', '[]', 'source_conflicts', '[]', 'confidence_score', 0.85),
    v_suggestions, v_flagged_issues
  ) RETURNING id INTO v_check_id;

  -- ---- Update product quality fields ----
  UPDATE marketplace_products
  SET
    quality_score = v_overall_score,
    quality_check_status = v_quality_status,
    quality_check_details = jsonb_build_object(
      'check_id', v_check_id,
      'checked_at', NOW(),
      'overall_score', v_overall_score
    )
  WHERE id = p_product_id;

  RETURN v_check_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION run_product_quality_check IS 'Runs an automated quality check on a marketplace product, computing grammar, spelling, formatting, and curriculum alignment scores. Returns the quality check record ID.';

-- ---- Get applicable commission rate ----
CREATE OR REPLACE FUNCTION get_commission_rate(
  p_product_type marketplace_product_type,
  p_license_type marketplace_license_type
)
RETURNS DECIMAL AS $$
DECLARE
  v_rate DECIMAL;
BEGIN
  -- Try specific product_type + license_type match first
  SELECT commission_rate INTO v_rate
  FROM marketplace_commission_rates
  WHERE (product_type = p_product_type OR product_type IS NULL)
    AND (license_type = p_license_type OR license_type IS NULL)
    AND is_active = TRUE
    AND effective_from <= NOW()
    AND (effective_to IS NULL OR effective_to > NOW())
  ORDER BY
    -- Most specific match first
    CASE WHEN product_type IS NOT NULL AND license_type IS NOT NULL THEN 0
         WHEN product_type IS NOT NULL AND license_type IS NULL THEN 1
         WHEN product_type IS NULL AND license_type IS NOT NULL THEN 2
         ELSE 3
    END,
    effective_from DESC
  LIMIT 1;

  RETURN COALESCE(v_rate, 0.1500);  -- Default 15% commission
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_commission_rate IS 'Returns the applicable commission rate for a product type and license type. Falls back to 15% if no rate is configured.';

-- ---- Calculate promo code discount ----
CREATE OR REPLACE FUNCTION calculate_promo_discount(
  p_code        TEXT,
  p_subtotal    DECIMAL,
  p_product_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
  discount_amount   DECIMAL,
  promo_code_id     UUID,
  is_valid          BOOLEAN,
  validation_message TEXT
) AS $$
DECLARE
  v_promo            RECORD;
  v_valid            BOOLEAN := TRUE;
  v_message          TEXT := 'Valid';
  v_discount         DECIMAL := 0.00;
  v_applicable_total DECIMAL;
BEGIN
  -- Fetch promo code
  SELECT * INTO v_promo
  FROM marketplace_promo_codes
  WHERE code = p_code AND is_active = TRUE
    AND starts_at <= NOW()
    AND (expires_at IS NULL OR expires_at > NOW());

  IF NOT FOUND THEN
    RETURN QUERY SELECT 0.00::DECIMAL, NULL::UUID, FALSE, 'Promo code not found or expired';
    RETURN;
  END IF;

  -- Check usage limit
  IF v_promo.max_uses IS NOT NULL AND v_promo.current_uses >= v_promo.max_uses THEN
    RETURN QUERY SELECT 0.00::DECIMAL, v_promo.id, FALSE, 'Promo code usage limit reached';
    RETURN;
  END IF;

  -- Check minimum order amount
  IF v_promo.min_order_amount IS NOT NULL AND p_subtotal < v_promo.min_order_amount THEN
    RETURN QUERY SELECT 0.00::DECIMAL, v_promo.id, FALSE,
      'Minimum order amount is ' || v_promo.min_order_amount || ' ' || v_promo.currency;
    RETURN;
  END IF;

  -- Check product type applicability
  IF v_promo.applicable_product_types IS NOT NULL AND array_length(v_promo.applicable_product_types, 1) > 0 THEN
    IF p_product_ids IS NOT NULL THEN
      SELECT COALESCE(SUM(p.price), 0.00) INTO v_applicable_total
      FROM marketplace_products p
      WHERE p.id = ANY(p_product_ids)
        AND p.product_type = ANY(v_promo.applicable_product_types);
    ELSE
      v_applicable_total := p_subtotal;
    END IF;
  ELSE
    v_applicable_total := p_subtotal;
  END IF;

  -- Calculate discount
  IF v_promo.discount_type = 'percentage' THEN
    v_discount := v_applicable_total * v_promo.discount_value / 100.0;
    -- Cap at max discount
    IF v_promo.max_discount_amount IS NOT NULL THEN
      v_discount := LEAST(v_discount, v_promo.max_discount_amount);
    END IF;
  ELSE  -- fixed
    v_discount := LEAST(v_promo.discount_value, v_applicable_total);
  END IF;

  RETURN QUERY SELECT v_discount, v_promo.id, TRUE, 'Valid';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_promo_discount IS 'Validates a promo code and calculates the discount amount for a given subtotal and optional product list';

-- ---- Record marketplace analytics event ----
CREATE OR REPLACE FUNCTION record_product_view(
  p_product_id UUID,
  p_user_id    UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Increment product view count
  UPDATE marketplace_products
  SET view_count = view_count + 1
  WHERE id = p_product_id;

  -- Upsert daily analytics
  INSERT INTO marketplace_product_analytics (product_id, date, views)
  VALUES (p_product_id, CURRENT_DATE, 1)
  ON CONFLICT (product_id, date)
  DO UPDATE SET views = marketplace_product_analytics.views + 1;

  -- Upsert seller analytics if user is authenticated
  IF p_user_id IS NOT NULL THEN
    INSERT INTO marketplace_seller_analytics (seller_id, date, views, unique_visitors)
    SELECT sp.id, CURRENT_DATE, 1, 0
    FROM seller_profiles sp
    INNER JOIN marketplace_products mp ON mp.seller_id = sp.id
    WHERE mp.id = p_product_id
    ON CONFLICT (seller_id, date)
    DO UPDATE SET views = marketplace_seller_analytics.views + 1;
  END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION record_product_view IS 'Records a product view event, incrementing the product view count and daily analytics';

-- ---- Record search event ----
CREATE OR REPLACE FUNCTION record_search_event(
  p_user_id            UUID,
  p_query              TEXT,
  p_filters            JSONB DEFAULT '{}',
  p_results_count      INTEGER DEFAULT 0,
  p_clicked_product_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO marketplace_search_logs (user_id, query, filters, results_count, clicked_product_id)
  VALUES (p_user_id, p_query, p_filters, p_results_count, p_clicked_product_id)
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION record_search_event IS 'Records a search event for analytics and AI recommendation training';

-- ============================================================================
-- SECTION 8: MATERIALIZED VIEW - Trending Products
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_marketplace_trending_products AS
SELECT
  p.id,
  p.title,
  p.slug,
  p.description,
  p.product_type,
  p.subject,
  p.class_level,
  p.curriculum,
  p.price,
  p.original_price,
  p.currency,
  p.license_type,
  p.tags,
  p.preview_images,
  p.average_rating,
  p.total_reviews,
  p.total_sales,
  p.quality_score,
  p.is_free,
  p.is_featured,
  p.seller_id,
  sp.display_name AS seller_name,
  p.published_at,
  -- Trending score: weighted combination of recent metrics
  (
    COALESCE(pa.sales, 0) * 3.0 +
    COALESCE(pa.views, 0) * 0.1 +
    COALESCE(pa.downloads, 0) * 2.0 +
    p.average_rating * 10.0 +
    CASE WHEN p.is_featured THEN 50.0 ELSE 0.0 END +
    CASE WHEN pa.date >= CURRENT_DATE - INTERVAL '3 days' THEN 20.0 ELSE 0.0 END
  ) AS trending_score,
  pa.date AS analytics_date
FROM marketplace_products p
INNER JOIN seller_profiles sp ON p.seller_id = sp.id
LEFT JOIN marketplace_product_analytics pa ON pa.product_id = p.id
  AND pa.date >= CURRENT_DATE - INTERVAL '7 days'
WHERE p.status = 'approved'
  AND p.deleted_at IS NULL
  AND sp.status = 'active'
ORDER BY trending_score DESC;

-- Unique index for concurrent refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_trending_id
  ON mv_marketplace_trending_products(id);

COMMENT ON MATERIALIZED VIEW mv_marketplace_trending_products IS 'Pre-computed trending products view with weighted scoring. Refresh periodically (e.g., every hour) for up-to-date rankings.';

-- ============================================================================
-- SECTION 9: REFRESH JOBS (scheduled via pg_cron if available)
-- ============================================================================

-- Create a function to refresh the trending materialized view
CREATE OR REPLACE FUNCTION refresh_trending_products()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_marketplace_trending_products;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_trending_products IS 'Refreshes the trending products materialized view concurrently without locking reads';

-- Optional: Schedule with pg_cron (uncomment if pg_cron extension is available)
-- SELECT cron.schedule(
--   'refresh-trending-products',
--   '0 * * * *',  -- Every hour
--   $$SELECT refresh_trending_products()$$
-- );

-- ============================================================================
-- SECTION 10: SEED DATA - Default categories and commission rates
-- ============================================================================

-- Insert default root categories
INSERT INTO marketplace_categories (name, slug, description, icon, sort_order, is_active) VALUES
  ('Question Banks', 'question-banks', 'Curated collections of exam questions organized by subject and topic', 'help-circle', 1, TRUE),
  ('Exam Templates', 'exam-templates', 'Pre-formatted exam papers ready for customization', 'file-text', 2, TRUE),
  ('Lesson Notes', 'lesson-notes', 'Comprehensive lesson notes and study materials', 'book-open', 3, TRUE),
  ('Schemes of Work', 'schemes-of-work', 'Termly and weekly schemes of work for teachers', 'calendar', 4, TRUE),
  ('Worksheets', 'worksheets', 'Printable and digital worksheets for classroom use', 'clipboard', 5, TRUE),
  ('Presentations', 'presentations', 'PowerPoint and teaching slide decks', 'monitor', 6, TRUE),
  ('Study Guides', 'study-guides', 'Exam preparation and revision study guides', 'graduation-cap', 7, TRUE),
  ('Practical Manuals', 'practical-manuals', 'Laboratory and practical experiment guides', 'flask-conical', 8, TRUE),
  ('Curriculum Packs', 'curriculum-packs', 'Complete curriculum resource bundles', 'package', 9, TRUE),
  ('Assessment Rubrics', 'assessment-rubrics', 'Grading rubrics and assessment criteria', 'check-square', 10, TRUE),
  ('Homework Packs', 'homework-packs', 'Ready-to-assign homework collections', 'home', 11, TRUE),
  ('Classroom Activities', 'classroom-activities', 'Interactive activities and group exercises', 'users', 12, TRUE),
  ('Educational Media', 'educational-media', 'Images, videos, and audio resources for education', 'image', 13, TRUE),
  ('Printable Resources', 'printable-resources', 'Ready-to-print educational materials', 'printer', 14, TRUE),
  ('Other Resources', 'other-resources', 'Miscellaneous educational resources', 'archive', 99, TRUE)
ON CONFLICT (slug) DO NOTHING;

-- Insert default commission rates
INSERT INTO marketplace_commission_rates (product_type, license_type, commission_rate, is_active) VALUES
  (NULL, 'personal', 0.1500, TRUE),        -- 15% for personal license (default)
  (NULL, 'teacher', 0.1200, TRUE),          -- 12% for teacher license
  (NULL, 'school', 0.1000, TRUE),           -- 10% for school license
  (NULL, 'department', 0.1000, TRUE),       -- 10% for department license
  (NULL, 'enterprise', 0.0800, TRUE),       -- 8% for enterprise license
  ('question_bank', NULL, 0.1500, TRUE),    -- 15% for question banks
  ('exam_template', NULL, 0.1200, TRUE),    -- 12% for exam templates
  ('lesson_note', NULL, 0.1300, TRUE),      -- 13% for lesson notes
  ('curriculum_pack', NULL, 0.1000, TRUE),  -- 10% for curriculum packs
  ('educational_video', NULL, 0.1800, TRUE) -- 18% for videos (higher bandwidth)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SECTION 11: EXTENSION REQUIREMENTS
-- ============================================================================

-- Ensure pg_trgm extension is available for similarity/trigram searches
-- (Must be enabled by Supabase dashboard or migration)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Ensure pg_cron extension for scheduled jobs (optional)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
-- Summary of created objects:
--   8 custom ENUM types
--   23 tables with constraints and foreign keys
--   90+ indexes (B-tree, GIN, partial, composite)
--   9 triggers (updated_at, rating aggregation, sales counts, etc.)
--   25+ RLS policies across all tables
--   6 functions (search, recommendations, quality checks, commission, promo, analytics)
--   1 materialized view (trending products)
--   1 refresh function for materialized view
-- ============================================================================
