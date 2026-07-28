-- ============================================================================
-- ExamForge AI — Billing & Subscription Schema
-- ============================================================================
-- Supports three independent billing models:
--   1. Teacher SaaS  (individual teacher subscribes independently)
--   2. School SaaS   (school subscribes, manages teachers/students/parents)
--   3. Enterprise SaaS (organizations, ministries, exam bodies — custom pricing)
--
-- Payment provider: Flutterwave (Standard Checkout, Webhooks, Recurring)
-- AI Credit System, Coupons, Referrals, Invoices, Licenses, Revenue Analytics
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- CUSTOM ENUM TYPES
-- ════════════════════════════════════════════════════════════════════════════

DO $$ BEGIN
  -- Billing model: who is the subscriber?
  CREATE TYPE billing_model AS ENUM ('teacher_saas', 'school_saas', 'enterprise_saas');

  -- Subscription plan tier
  CREATE TYPE plan_tier AS ENUM ('free', 'starter', 'professional', 'enterprise');

  -- Subscription status lifecycle
  CREATE TYPE subscription_status AS ENUM (
    'trial', 'active', 'past_due', 'paused',
    'cancelled', 'expired', 'pending_activation'
  );

  -- Transaction/payment status
  CREATE TYPE transaction_status AS ENUM (
    'pending', 'processing', 'successful', 'failed',
    'refunded', 'partially_refunded', 'disputed', 'voided'
  );

  -- Payment channel
  CREATE TYPE payment_channel AS ENUM (
    'card', 'bank_transfer', 'ussd', 'mobile_money',
    'qr_code', 'credit', 'coupon', 'refund'
  );

  -- Coupon discount type
  CREATE TYPE coupon_discount_type AS ENUM (
    'percentage', 'fixed_amount', 'free_trial', 'fixed_per_seat'
  );

  -- Referral reward type
  CREATE TYPE referral_reward_type AS ENUM (
    'credit_days', 'percentage_discount', 'fixed_credit', 'ai_credits'
  );

  -- AI credit transaction type
  CREATE TYPE credit_transaction_type AS ENUM (
    'monthly_allocation', 'purchase', 'usage', 'expiration',
    'bonus', 'referral_reward', 'admin_adjustment', 'refund'
  );

  -- License type
  CREATE TYPE license_type AS ENUM (
    'school', 'teacher', 'branch', 'seat', 'custom'
  );

  -- Invoice status
  CREATE TYPE invoice_status AS ENUM (
    'draft', 'issued', 'paid', 'partially_paid',
    'overdue', 'cancelled', 'void', 'credit_note'
  );

  -- Webhook event processing status
  CREATE TYPE webhook_status AS ENUM (
    'received', 'processing', 'processed', 'failed', 'retrying'
  );

  -- Billing notification type
  CREATE TYPE billing_notification_type AS ENUM (
    'payment_success', 'payment_failed', 'trial_ending',
    'subscription_renewal', 'plan_expiring', 'low_ai_credits',
    'invoice_generated', 'refund_status', 'card_expiring',
    'subscription_cancelled', 'upgrade_available'
  );

EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- SUBSCRIPTION PLANS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS subscription_plans (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT NOT NULL,
  tier              plan_tier NOT NULL DEFAULT 'free',
  billing_model     billing_model NOT NULL DEFAULT 'school_saas',
  description       TEXT,

  -- Pricing
  monthly_price     NUMERIC(12,2) NOT NULL DEFAULT 0,
  annual_price      NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency          TEXT NOT NULL DEFAULT 'NGN',
  setup_fee         NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- Feature limits
  max_students      INT NOT NULL DEFAULT 0,        -- 0 = unlimited
  max_teachers     INT NOT NULL DEFAULT 0,
  max_schools       INT NOT NULL DEFAULT 1,
  max_storage_mb    INT NOT NULL DEFAULT 100,       -- MB
  max_exams_per_month INT NOT NULL DEFAULT 0,
  ai_credits_monthly INT NOT NULL DEFAULT 0,

  -- Feature flags
  includes_ai_workspace       BOOLEAN NOT NULL DEFAULT false,
  includes_parent_portal      BOOLEAN NOT NULL DEFAULT false,
  includes_communication      BOOLEAN NOT NULL DEFAULT false,
  includes_advanced_analytics BOOLEAN NOT NULL DEFAULT false,
  includes_api_access         BOOLEAN NOT NULL DEFAULT false,
  includes_white_label        BOOLEAN NOT NULL DEFAULT false,
  includes_priority_support   BOOLEAN NOT NULL DEFAULT false,
  includes_dedicated_manager BOOLEAN NOT NULL DEFAULT false,

  -- Trial
  trial_days        INT NOT NULL DEFAULT 0,

  -- Visibility & ordering
  is_active         BOOLEAN NOT NULL DEFAULT true,
  is_popular        BOOLEAN NOT NULL DEFAULT false,
  sort_order        INT NOT NULL DEFAULT 0,

  -- Metadata
  features_list     JSONB DEFAULT '[]',     -- Array of feature strings for display
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE subscription_plans IS 'Configurable subscription plan definitions. Super Admin can create/modify plans.';
COMMENT ON COLUMN subscription_plans.tier IS 'Plan tier: free, starter, professional, enterprise';
COMMENT ON COLUMN subscription_plans.billing_model IS 'Which billing model this plan belongs to: teacher, school, or enterprise';
COMMENT ON COLUMN subscription_plans.max_students IS 'Maximum students allowed. 0 = unlimited';
COMMENT ON COLUMN subscription_plans.ai_credits_monthly IS 'AI credits allocated per billing cycle';

-- ════════════════════════════════════════════════════════════════════════════
-- ACTIVE SUBSCRIPTIONS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS subscriptions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Who is subscribing?
  subscriber_id     UUID NOT NULL,               -- FK to users or schools
  subscriber_type   billing_model NOT NULL,       -- determines which table subscriber_id references
  school_id         UUID,                         -- For school/enterprise, this is the school org

  -- Plan
  plan_id           UUID NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
  status            subscription_status NOT NULL DEFAULT 'trial',

  -- Billing cycle
  billing_cycle     TEXT NOT NULL DEFAULT 'monthly',  -- monthly / annual
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end   TIMESTAMPTZ NOT NULL,

  -- Trial
  trial_start       TIMESTAMPTZ,
  trial_end         TIMESTAMPTZ,

  -- Flutterwave recurring
  flutterwave_subscription_id TEXT,
  flutterwave_plan_code       TEXT,

  -- Coupon applied
  coupon_id         UUID,
  coupon_discount_applied NUMERIC(12,2) DEFAULT 0,

  -- Pricing snapshot (frozen at subscription time)
  price_at_subscription NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency               TEXT NOT NULL DEFAULT 'NGN',

  -- Seat counts (for seat-based licensing)
  seats_purchased   INT NOT NULL DEFAULT 1,
  seats_used        INT NOT NULL DEFAULT 0,

  -- Auto-renew
  auto_renew        BOOLEAN NOT NULL DEFAULT true,
  cancelled_at      TIMESTAMPTZ,
  cancellation_reason TEXT,

  -- Metadata
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE subscriptions IS 'Active subscriptions for teachers, schools, and enterprises. Tracks billing cycle, status, and Flutterwave integration.';
COMMENT ON COLUMN subscriptions.subscriber_id IS 'References users.id (for teacher_saas) or schools.id (for school/enterprise)';
COMMENT ON COLUMN subscriptions.subscriber_type IS 'Determines which billing model: teacher, school, or enterprise';

-- ════════════════════════════════════════════════════════════════════════════
-- TRANSACTIONS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  subscription_id   UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  user_id           UUID NOT NULL,                  -- who initiated the payment
  school_id         UUID,

  -- Flutterwave reference
  flutterwave_tx_ref     TEXT UNIQUE,               -- Our internal reference
  flutterwave_transaction_id TEXT,                  -- Flutterwave's ID
  flutterwave_flw_ref    TEXT,                       -- Flutterwave's FLW reference

  -- Transaction details
  amount            NUMERIC(12,2) NOT NULL,
  currency          TEXT NOT NULL DEFAULT 'NGN',
  channel           payment_channel NOT NULL DEFAULT 'card',
  status            transaction_status NOT NULL DEFAULT 'pending',

  -- Fee tracking
  flutterwave_fee   NUMERIC(12,2) DEFAULT 0,
  app_fee           NUMERIC(12,2) DEFAULT 0,
  net_amount        NUMERIC(12,2) DEFAULT 0,

  -- Payment details (NOT card info — never store card numbers!)
  payment_method_summary TEXT,                      -- e.g. "Visa ending 4242"
  processor_response     JSONB DEFAULT '{}',

  -- Refund tracking
  refund_amount     NUMERIC(12,2) DEFAULT 0,
  refund_reason     TEXT,
  refunded_at       TIMESTAMPTZ,

  -- Fraud detection
  risk_score        INT DEFAULT 0,                  -- 0-100
  fraud_flagged     BOOLEAN NOT NULL DEFAULT false,
  fraud_notes       TEXT,

  -- Metadata
  description       TEXT,
  metadata          JSONB DEFAULT '{}',

  -- Timestamps
  initiated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at      TIMESTAMPTZ,
  verified_at       TIMESTAMPTZ,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE transactions IS 'Payment transactions processed through Flutterwave. Never stores sensitive card information.';
COMMENT ON COLUMN transactions.flutterwave_tx_ref IS 'Our internal transaction reference sent to Flutterwave';
COMMENT ON COLUMN transactions.risk_score IS 'Fraud risk score 0-100, higher = more risky';

-- ════════════════════════════════════════════════════════════════════════════
-- INVOICES
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS invoices (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  subscription_id   UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  transaction_id    UUID REFERENCES transactions(id) ON DELETE SET NULL,
  school_id         UUID,
  user_id           UUID NOT NULL,

  -- Invoice number (auto-generated)
  invoice_number    TEXT NOT NULL UNIQUE,
  invoice_type      invoice_status NOT NULL DEFAULT 'draft',

  -- Billing details
  bill_to_name      TEXT NOT NULL,
  bill_to_email     TEXT,
  bill_to_address   TEXT,
  bill_to_tax_id    TEXT,                           -- Tax identification number

  -- Line items (array of objects)
  line_items        JSONB NOT NULL DEFAULT '[]',
  -- Format: [{description, quantity, unit_price, total, tax_rate, tax_amount}]

  -- Totals
  subtotal          NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_amount        NUMERIC(12,2) NOT NULL DEFAULT 0,
  discount_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency          TEXT NOT NULL DEFAULT 'NGN',

  -- Linked credit note
  credit_note_for   UUID REFERENCES invoices(id) ON DELETE SET NULL,

  -- Dates
  issue_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date          DATE NOT NULL,
  paid_at           TIMESTAMPTZ,

  -- PDF storage
  pdf_url           TEXT,

  -- Email delivery
  email_sent        BOOLEAN NOT NULL DEFAULT false,
  email_sent_at     TIMESTAMPTZ,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE invoices IS 'Tax-ready invoices with line items. Supports PDF download, email delivery, and credit notes.';

-- ════════════════════════════════════════════════════════════════════════════
-- RECEIPTS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS receipts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  transaction_id    UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  invoice_id        UUID REFERENCES invoices(id) ON DELETE SET NULL,
  user_id           UUID NOT NULL,
  school_id         UUID,

  receipt_number    TEXT NOT NULL UNIQUE,

  -- Receipt details
  amount_paid       NUMERIC(12,2) NOT NULL,
  currency          TEXT NOT NULL DEFAULT 'NGN',
  payment_method    TEXT NOT NULL,
  payment_date      TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- PDF storage
  pdf_url           TEXT,

  -- Email delivery
  email_sent        BOOLEAN NOT NULL DEFAULT false,
  email_sent_at     TIMESTAMPTZ,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE receipts IS 'Payment receipts linked to transactions. Auto-generated on successful payment.';

-- ════════════════════════════════════════════════════════════════════════════
-- AI CREDITS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_credit_balances (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Owner can be a user (teacher) or school
  owner_id          UUID NOT NULL,
  owner_type        billing_model NOT NULL DEFAULT 'teacher_saas',
  school_id         UUID,

  -- Balance
  total_credits     INT NOT NULL DEFAULT 0,
  used_credits      INT NOT NULL DEFAULT 0,
  remaining_credits INT NOT NULL DEFAULT 0,

  -- Current cycle
  current_cycle_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_cycle_end   TIMESTAMPTZ NOT NULL,

  -- Expiration policy
  credits_expire    BOOLEAN NOT NULL DEFAULT true,
  expiration_date   TIMESTAMPTZ,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_credit_balance_owner UNIQUE (owner_id, owner_type)
);

COMMENT ON TABLE ai_credit_balances IS 'AI credit balances per teacher or school. Monthly allocations + purchased credits.';

-- ════════════════════════════════════════════════════════════════════════════
-- AI CREDIT TRANSACTIONS (USAGE TRACKING)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_credit_transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  balance_id        UUID NOT NULL REFERENCES ai_credit_balances(id) ON DELETE CASCADE,
  owner_id          UUID NOT NULL,
  owner_type        billing_model NOT NULL DEFAULT 'teacher_saas',
  school_id         UUID,

  -- Transaction details
  transaction_type  credit_transaction_type NOT NULL,
  credits           INT NOT NULL,                  -- positive = credit, negative = debit
  balance_before    INT NOT NULL DEFAULT 0,
  balance_after     INT NOT NULL DEFAULT 0,

  -- What consumed/added credits
  feature_name      TEXT,                          -- e.g. 'question_generation', 'smart_marking'
  reference_id      UUID,                          -- Link to the feature usage record

  -- Cost monitoring
  estimated_cost_usd NUMERIC(8,4) DEFAULT 0,      -- Internal cost tracking

  description       TEXT,
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai_credit_transactions IS 'Audit trail for all AI credit changes: monthly allocation, usage, purchase, expiration, bonus.';
COMMENT ON COLUMN ai_credit_transactions.credits IS 'Positive for credit additions, negative for usage deductions';

-- ════════════════════════════════════════════════════════════════════════════
-- COUPONS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS coupons (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  code              TEXT NOT NULL UNIQUE,           -- e.g. BACK2SCHOOL2024
  name              TEXT NOT NULL,
  description       TEXT,

  -- Discount
  discount_type     coupon_discount_type NOT NULL,
  discount_value    NUMERIC(12,2) NOT NULL,         -- Percentage or fixed amount
  discount_percent  NUMERIC(5,2),                   -- For percentage type
  max_discount_amount NUMERIC(12,2),                -- Cap for percentage discounts

  -- Applicability
  applicable_tiers  JSONB DEFAULT '[]',             -- Array of plan_tier values, empty = all
  applicable_billing_models JSONB DEFAULT '[]',     -- Array of billing_model values
  applicable_plans  UUID[] DEFAULT '{}',            -- Specific plan IDs

  -- Usage limits
  max_redemptions   INT NOT NULL DEFAULT 0,         -- 0 = unlimited
  current_redemptions INT NOT NULL DEFAULT 0,
  max_redemptions_per_user INT NOT NULL DEFAULT 1,

  -- Duration
  duration_months   INT DEFAULT 1,                  -- How many billing cycles the discount applies

  -- Validity
  valid_from        TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_until       TIMESTAMPTZ,

  -- Free trial specific
  trial_days        INT,                            -- For free_trial discount type

  is_active         BOOLEAN NOT NULL DEFAULT true,

  created_by        UUID,
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE coupons IS 'Discount codes, free trial codes, seasonal promotions. Configurable by Super Admin.';

-- ════════════════════════════════════════════════════════════════════════════
-- COUPON REDEMPTIONS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS coupon_redemptions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  coupon_id         UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL,
  school_id         UUID,
  subscription_id   UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  transaction_id    UUID REFERENCES transactions(id) ON DELETE SET NULL,

  discount_applied  NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency          TEXT NOT NULL DEFAULT 'NGN',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_coupon_redemption_per_user UNIQUE (coupon_id, user_id)
);

COMMENT ON TABLE coupons IS 'Tracks each coupon redemption to enforce per-user limits and audit usage.';

-- ════════════════════════════════════════════════════════════════════════════
-- REFERRAL CODES
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS referral_codes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  referrer_id       UUID NOT NULL,                  -- The user who owns this referral code
  referrer_type     billing_model NOT NULL DEFAULT 'teacher_saas',
  school_id         UUID,

  code              TEXT NOT NULL UNIQUE,            -- Unique referral code
  is_active         BOOLEAN NOT NULL DEFAULT true,

  -- Reward configuration
  reward_type       referral_reward_type NOT NULL DEFAULT 'credit_days',
  reward_value      NUMERIC(12,2) NOT NULL DEFAULT 0,
  reward_description TEXT,

  -- Referee reward (what the referred person gets)
  referee_reward_type referral_reward_type DEFAULT 'ai_credits',
  referee_reward_value NUMERIC(12,2) DEFAULT 0,

  -- Tracking
  total_referrals   INT NOT NULL DEFAULT 0,
  successful_referrals INT NOT NULL DEFAULT 0,
  total_rewards_earned NUMERIC(12,2) NOT NULL DEFAULT 0,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE referral_codes IS 'Referral codes for teachers, schools, and enterprises. Tracks referrals and rewards.';

-- ════════════════════════════════════════════════════════════════════════════
-- REFERRAL TRACKING
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS referral_tracking (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  referral_code_id  UUID NOT NULL REFERENCES referral_codes(id) ON DELETE CASCADE,
  referrer_id       UUID NOT NULL,
  referee_id        UUID NOT NULL,                  -- The person who was referred
  referee_type      billing_model NOT NULL DEFAULT 'teacher_saas',

  -- Status
  is_successful     BOOLEAN NOT NULL DEFAULT false, -- True once referee makes a payment
  reward_claimed    BOOLEAN NOT NULL DEFAULT false,

  -- Rewards
  referrer_reward_applied BOOLEAN NOT NULL DEFAULT false,
  referee_reward_applied  BOOLEAN NOT NULL DEFAULT false,

  subscription_id   UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  transaction_id    UUID REFERENCES transactions(id) ON DELETE SET NULL,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE referral_tracking IS 'Tracks each referral from click to conversion. Rewards applied only after successful payment.';

-- ════════════════════════════════════════════════════════════════════════════
-- LICENSES
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS licenses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  subscription_id   UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  school_id         UUID,
  user_id           UUID,                           -- NULL for school/branch licenses

  license_type      license_type NOT NULL DEFAULT 'school',
  license_key       TEXT NOT NULL UNIQUE,

  -- Seat-based
  seats_total       INT NOT NULL DEFAULT 1,
  seats_used        INT NOT NULL DEFAULT 0,

  -- Validity
  issued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at        TIMESTAMPTZ NOT NULL,

  -- Status
  is_active         BOOLEAN NOT NULL DEFAULT true,
  revoked_at        TIMESTAMPTZ,
  revoke_reason     TEXT,

  -- Renewal
  auto_renew        BOOLEAN NOT NULL DEFAULT true,
  renewal_reminder_sent BOOLEAN NOT NULL DEFAULT false,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE licenses IS 'Software licenses: school, teacher, branch, seat-based. Auto-generated on subscription activation.';

-- ════════════════════════════════════════════════════════════════════════════
-- WEBHOOK EVENTS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS webhook_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  event_type        TEXT NOT NULL,                  -- e.g. 'charge.completed', 'transfer.failed'
  event_id          TEXT,                           -- Flutterwave's event ID

  -- Payload
  payload           JSONB NOT NULL DEFAULT '{}',

  -- Processing
  status            webhook_status NOT NULL DEFAULT 'received',
  processing_attempts INT NOT NULL DEFAULT 0,
  max_attempts      INT NOT NULL DEFAULT 5,
  last_error        TEXT,
  processed_at      TIMESTAMPTZ,

  -- Security: verify webhook signature
  signature_valid   BOOLEAN NOT NULL DEFAULT false,
  raw_body          TEXT,                           -- For signature verification

  -- Idempotency
  idempotency_key   TEXT UNIQUE,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE webhook_events IS 'Flutterwave webhook events. Signature-verified, idempotent, with retry mechanism.';

-- ════════════════════════════════════════════════════════════════════════════
-- BILLING NOTIFICATIONS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS billing_notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id           UUID NOT NULL,
  school_id         UUID,
  subscription_id   UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  transaction_id    UUID REFERENCES transactions(id) ON DELETE SET NULL,

  notification_type billing_notification_type NOT NULL,
  title             TEXT NOT NULL,
  message           TEXT NOT NULL,

  -- Delivery channels
  in_app_sent       BOOLEAN NOT NULL DEFAULT false,
  push_sent         BOOLEAN NOT NULL DEFAULT false,
  email_sent        BOOLEAN NOT NULL DEFAULT false,
  sms_sent          BOOLEAN NOT NULL DEFAULT false,

  is_read           BOOLEAN NOT NULL DEFAULT false,
  read_at           TIMESTAMPTZ,

  -- Scheduling
  scheduled_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at           TIMESTAMPTZ,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE billing_notifications IS 'Billing-related notifications: payment confirmations, trial warnings, low credits, invoice generated, etc.';

-- ════════════════════════════════════════════════════════════════════════════
-- USER NOTIFICATION PREFERENCES (billing-specific)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS billing_notification_preferences (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL UNIQUE,

  -- Channel preferences
  enable_in_app     BOOLEAN NOT NULL DEFAULT true,
  enable_push       BOOLEAN NOT NULL DEFAULT true,
  enable_email      BOOLEAN NOT NULL DEFAULT true,
  enable_sms        BOOLEAN NOT NULL DEFAULT false,

  -- Type preferences
  notify_payment_success   BOOLEAN NOT NULL DEFAULT true,
  notify_payment_failed    BOOLEAN NOT NULL DEFAULT true,
  notify_trial_ending      BOOLEAN NOT NULL DEFAULT true,
  notify_subscription_renewal BOOLEAN NOT NULL DEFAULT true,
  notify_plan_expiring     BOOLEAN NOT NULL DEFAULT true,
  notify_low_ai_credits    BOOLEAN NOT NULL DEFAULT true,
  notify_invoice_generated BOOLEAN NOT NULL DEFAULT true,
  notify_refund_status     BOOLEAN NOT NULL DEFAULT true,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE billing_notification_preferences IS 'Per-user notification preferences for billing events.';

-- ════════════════════════════════════════════════════════════════════════════
-- REVENUE REPORTS (materialized for dashboard)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS revenue_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  period_type       TEXT NOT NULL,                  -- daily, weekly, monthly, annual
  period_start      DATE NOT NULL,
  period_end        DATE NOT NULL,

  -- Revenue breakdown
  total_revenue     NUMERIC(14,2) NOT NULL DEFAULT 0,
  subscription_revenue NUMERIC(14,2) NOT NULL DEFAULT 0,
  ai_credit_revenue NUMERIC(14,2) NOT NULL DEFAULT 0,
  setup_fee_revenue NUMERIC(14,2) NOT NULL DEFAULT 0,
  refund_amount     NUMERIC(14,2) NOT NULL DEFAULT 0,
  net_revenue       NUMERIC(14,2) NOT NULL DEFAULT 0,

  -- Flutterwave fees
  processor_fees    NUMERIC(12,2) NOT NULL DEFAULT 0,
  platform_fees     NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- Metrics
  active_subscriptions INT NOT NULL DEFAULT 0,
  new_subscriptions    INT NOT NULL DEFAULT 0,
  cancelled_subscriptions INT NOT NULL DEFAULT 0,
  churn_rate        NUMERIC(5,4) NOT NULL DEFAULT 0,     -- 0.0 to 1.0
  trial_conversions INT NOT NULL DEFAULT 0,
  trial_conversion_rate NUMERIC(5,4) DEFAULT 0,

  -- Billing model breakdown
  teacher_saas_revenue NUMERIC(14,2) DEFAULT 0,
  school_saas_revenue  NUMERIC(14,2) DEFAULT 0,
  enterprise_saas_revenue NUMERIC(14,2) DEFAULT 0,

  -- AI credits
  ai_credits_sold  INT NOT NULL DEFAULT 0,
  ai_credits_used  INT NOT NULL DEFAULT 0,

  currency          TEXT NOT NULL DEFAULT 'NGN',
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_revenue_report_period UNIQUE (period_type, period_start, period_end)
);

COMMENT ON TABLE revenue_reports IS 'Aggregated revenue data for Super Admin dashboard. Updated by scheduled jobs.';

-- ════════════════════════════════════════════════════════════════════════════
-- SCHOOL BILLING PROFILES
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS school_billing_profiles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id         UUID NOT NULL UNIQUE,

  -- Billing contacts
  billing_contact_name  TEXT,
  billing_contact_email TEXT,
  billing_contact_phone TEXT,
  billing_address       TEXT,

  -- Tax
  tax_id_number     TEXT,
  tax_exempt        BOOLEAN NOT NULL DEFAULT false,

  -- Payment methods on file (Flutterwave tokens — never raw card data)
  default_payment_method TEXT,                      -- Flutterwave token reference
  payment_methods   JSONB DEFAULT '[]',

  -- Renewal settings
  auto_renew        BOOLEAN NOT NULL DEFAULT true,
  renewal_reminder_days INT NOT NULL DEFAULT 14,    -- Days before expiry to send reminder

  -- Usage tracking
  current_student_count  INT NOT NULL DEFAULT 0,
  current_teacher_count  INT NOT NULL DEFAULT 0,
  current_storage_used_mb NUMERIC(12,2) NOT NULL DEFAULT 0,
  current_ai_credits_used INT NOT NULL DEFAULT 0,

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE school_billing_profiles IS 'School-specific billing configuration: contacts, payment methods, usage limits, renewal settings.';

-- ════════════════════════════════════════════════════════════════════════════
-- BILLING AUDIT LOGS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS billing_audit_logs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  actor_id          UUID,                           -- Who performed the action
  action            TEXT NOT NULL,                  -- e.g. 'subscription.created', 'payment.refunded'
  entity_type       TEXT NOT NULL,                  -- e.g. 'subscription', 'transaction', 'coupon'
  entity_id         UUID,                           -- The entity affected

  -- Context
  school_id         UUID,
  ip_address        INET,
  user_agent        TEXT,

  -- Change tracking
  old_values        JSONB,
  new_values        JSONB,

  description       TEXT,
  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE billing_audit_logs IS 'Comprehensive audit trail for all billing actions. Immutable — no updates or deletes.';

-- ════════════════════════════════════════════════════════════════════════════
-- AI CREDIT PACKS (purchasable credit bundles)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_credit_packs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name              TEXT NOT NULL,
  description       TEXT,
  credits           INT NOT NULL,                   -- Number of AI credits in the pack
  price             NUMERIC(12,2) NOT NULL,
  currency          TEXT NOT NULL DEFAULT 'NGN',
  price_per_credit  NUMERIC(8,4) GENERATED ALWAYS AS (price / NULLIF(credits, 0)) STORED,

  -- Validity
  validity_days     INT NOT NULL DEFAULT 365,       -- Credits expire after N days
  is_active         BOOLEAN NOT NULL DEFAULT true,
  sort_order        INT NOT NULL DEFAULT 0,

  -- Applicability
  applicable_billing_models JSONB DEFAULT '[]',     -- Which billing models can purchase

  metadata          JSONB DEFAULT '{}',

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai_credit_packs IS 'Purchasable AI credit bundles. Configurable by Super Admin.';

-- ════════════════════════════════════════════════════════════════════════════
-- RATE LIMITING (billing-specific)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS billing_rate_limits (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  identifier        TEXT NOT NULL,                  -- user_id or IP address
  action_type       TEXT NOT NULL,                  -- e.g. 'payment_initiate', 'coupon_redeem'
  attempt_count     INT NOT NULL DEFAULT 1,
  window_start      TIMESTAMPTZ NOT NULL DEFAULT now(),
  max_attempts      INT NOT NULL DEFAULT 10,
  window_minutes    INT NOT NULL DEFAULT 60,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_rate_limit UNIQUE (identifier, action_type)
);

COMMENT ON TABLE billing_rate_limits IS 'Rate limiting for billing actions to prevent abuse.';

-- ════════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ════════════════════════════════════════════════════════════════════════════

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_subscriber ON subscriptions(subscriber_id, subscriber_type);
CREATE INDEX IF NOT EXISTS idx_subscriptions_school ON subscriptions(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON subscriptions(current_period_end) WHERE status IN ('active', 'trial');
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON subscriptions(plan_id);

-- Transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_school ON transactions(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_subscription ON transactions(subscription_id) WHERE subscription_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_flutterwave_ref ON transactions(flutterwave_tx_ref);
CREATE INDEX IF NOT EXISTS idx_transactions_flutterwave_id ON transactions(flutterwave_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_initiated_at ON transactions(initiated_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_fraud ON transactions(fraud_flagged) WHERE fraud_flagged = true;

-- Invoices
CREATE INDEX IF NOT EXISTS idx_invoices_user ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_school ON invoices(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_subscription ON invoices(subscription_id) WHERE subscription_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(invoice_type);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date) WHERE invoice_type IN ('issued', 'overdue');

-- Receipts
CREATE INDEX IF NOT EXISTS idx_receipts_transaction ON receipts(transaction_id);
CREATE INDEX IF NOT EXISTS idx_receipts_user ON receipts(user_id);

-- AI Credit Balances
CREATE INDEX IF NOT EXISTS idx_credit_balances_owner ON ai_credit_balances(owner_id, owner_type);
CREATE INDEX IF NOT EXISTS idx_credit_balances_cycle ON ai_credit_balances(current_cycle_end);

-- AI Credit Transactions
CREATE INDEX IF NOT EXISTS idx_credit_transactions_balance ON ai_credit_transactions(balance_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_owner ON ai_credit_transactions(owner_id, owner_type);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON ai_credit_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_feature ON ai_credit_transactions(feature_name);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created ON ai_credit_transactions(created_at DESC);

-- Coupons
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_active ON coupons(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_coupons_validity ON coupons(valid_from, valid_until);

-- Coupon Redemptions
CREATE INDEX IF NOT EXISTS idx_coupon_redemptions_coupon ON coupon_redemptions(coupon_id);
CREATE INDEX IF NOT EXISTS idx_coupon_redemptions_user ON coupon_redemptions(user_id);

-- Referral Codes
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_codes_referrer ON referral_codes(referrer_id);

-- Referral Tracking
CREATE INDEX IF NOT EXISTS idx_referral_tracking_code ON referral_tracking(referral_code_id);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_referee ON referral_tracking(referee_id);
CREATE INDEX IF NOT EXISTS idx_referral_tracking_successful ON referral_tracking(is_successful) WHERE is_successful = true;

-- Licenses
CREATE INDEX IF NOT EXISTS idx_licenses_subscription ON licenses(subscription_id);
CREATE INDEX IF NOT EXISTS idx_licenses_school ON licenses(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_licenses_user ON licenses(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_licenses_key ON licenses(license_key);
CREATE INDEX IF NOT EXISTS idx_licenses_expires ON licenses(expires_at) WHERE is_active = true;

-- Webhook Events
CREATE INDEX IF NOT EXISTS idx_webhooks_status ON webhook_events(status) WHERE status IN ('received', 'processing', 'failed', 'retrying');
CREATE INDEX IF NOT EXISTS idx_webhooks_event_type ON webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_webhooks_idempotency ON webhook_events(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_webhooks_created ON webhook_events(created_at DESC);

-- Billing Notifications
CREATE INDEX IF NOT EXISTS idx_billing_notifications_user ON billing_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_type ON billing_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_billing_notifications_read ON billing_notifications(is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_billing_notifications_scheduled ON billing_notifications(scheduled_at) WHERE sent_at IS NULL;

-- Revenue Reports
CREATE INDEX IF NOT EXISTS idx_revenue_reports_period ON revenue_reports(period_type, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_revenue_reports_date_range ON revenue_reports(period_start, period_end);

-- School Billing Profiles
CREATE INDEX IF NOT EXISTS idx_school_billing_school ON school_billing_profiles(school_id);

-- Audit Logs
CREATE INDEX IF NOT EXISTS idx_billing_audit_entity ON billing_audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_billing_audit_actor ON billing_audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_billing_audit_action ON billing_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_billing_audit_created ON billing_audit_logs(created_at DESC);

-- AI Credit Packs
CREATE INDEX IF NOT EXISTS idx_credit_packs_active ON ai_credit_packs(is_active) WHERE is_active = true;

-- Rate Limits
CREATE INDEX IF NOT EXISTS idx_rate_limits_identifier ON billing_rate_limits(identifier, action_type);

-- ════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_billing_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$ DECLARE t TEXT; BEGIN
  FOR t IN SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at'
    AND table_schema = 'public'
    AND table_name IN (
      'subscription_plans', 'subscriptions', 'transactions', 'invoices',
      'ai_credit_balances', 'coupons', 'referral_codes', 'referral_tracking',
      'licenses', 'webhook_events', 'billing_notification_preferences',
      'revenue_reports', 'school_billing_profiles', 'ai_credit_packs',
      'billing_rate_limits'
    )
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at
       BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_billing_updated_at()',
      t, t
    );
  EXCEPTION WHEN others THEN NULL;
  END LOOP;
END $$;

-- Generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  seq_val INT;
  year_part TEXT := to_char(now(), 'YY');
  month_part TEXT := to_char(now(), 'MM');
BEGIN
  SELECT nextval('invoice_number_seq') INTO seq_val;
  RETURN 'INV-' || year_part || month_part || '-' || lpad(seq_val::text, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Create sequence for invoice numbers
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

-- Generate receipt number
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TEXT AS $$
DECLARE
  seq_val INT;
  year_part TEXT := to_char(now(), 'YY');
  month_part TEXT := to_char(now(), 'MM');
BEGIN
  SELECT nextval('receipt_number_seq') INTO seq_val;
  RETURN 'RCT-' || year_part || month_part || '-' || lpad(seq_val::text, 6, '0');
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS receipt_number_seq START 1;

-- Generate transaction reference for Flutterwave
CREATE OR REPLACE FUNCTION generate_tx_ref()
RETURNS TEXT AS $$
BEGIN
  RETURN 'EF-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 16);
END;
$$ LANGUAGE plpgsql;

-- Check subscription limits (used by RLS and API)
CREATE OR REPLACE FUNCTION check_subscription_limit(
  p_school_id UUID,
  p_limit_type TEXT  -- 'students', 'teachers', 'storage', 'exams'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_plan RECORD;
  v_current_count INT;
BEGIN
  SELECT sp.max_students, sp.max_teachers, sp.max_storage_mb, sp.max_exams_per_month
  INTO v_plan
  FROM subscriptions s
  JOIN subscription_plans sp ON s.plan_id = sp.id
  WHERE s.school_id = p_school_id
    AND s.status IN ('active', 'trial')
  ORDER BY s.created_at DESC LIMIT 1;

  IF NOT FOUND THEN RETURN false; END IF;

  CASE p_limit_type
    WHEN 'students' THEN
      SELECT count(*) INTO v_current_count FROM students WHERE school_id = p_school_id AND is_active = true;
      RETURN v_plan.max_students = 0 OR v_current_count < v_plan.max_students;
    WHEN 'teachers' THEN
      SELECT count(*) INTO v_current_count FROM teachers WHERE school_id = p_school_id AND is_active = true;
      RETURN v_plan.max_teachers = 0 OR v_current_count < v_plan.max_teachers;
    WHEN 'exams' THEN
      RETURN v_plan.max_exams_per_month = 0; -- simplified; real impl counts monthly exams
    ELSE
      RETURN true;
  END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Consume AI credits (called by feature modules)
CREATE OR REPLACE FUNCTION consume_ai_credits(
  p_owner_id UUID,
  p_owner_type billing_model,
  p_credits INT,
  p_feature_name TEXT,
  p_reference_id UUID DEFAULT NULL,
  p_estimated_cost_usd NUMERIC DEFAULT 0
)
RETURNS BOOLEAN AS $$
DECLARE
  v_balance RECORD;
  v_balance_after INT;
BEGIN
  -- Lock the balance row for atomic update
  SELECT * INTO v_balance
  FROM ai_credit_balances
  WHERE owner_id = p_owner_id AND owner_type = p_owner_type
  FOR UPDATE;

  IF NOT FOUND THEN RETURN false; END IF;

  IF v_balance.remaining_credits < p_credits THEN
    RETURN false;  -- Insufficient credits
  END IF;

  v_balance_after := v_balance.remaining_credits - p_credits;

  -- Update balance
  UPDATE ai_credit_balances SET
    used_credits = used_credits + p_credits,
    remaining_credits = v_balance_after
  WHERE id = v_balance.id;

  -- Record transaction
  INSERT INTO ai_credit_transactions (
    balance_id, owner_id, owner_type, school_id,
    transaction_type, credits, balance_before, balance_after,
    feature_name, reference_id, estimated_cost_usd
  ) VALUES (
    v_balance.id, p_owner_id, p_owner_type, v_balance.school_id,
    'usage', -p_credits, v_balance.remaining_credits, v_balance_after,
    p_feature_name, p_reference_id, p_estimated_cost_usd
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Expire old credits (run daily via cron/supabase function)
CREATE OR REPLACE FUNCTION expire_ai_credits()
RETURNS INT AS $$
DECLARE
  v_expired_count INT := 0;
  v_balance RECORD;
BEGIN
  FOR v_balance IN
    SELECT * FROM ai_credit_balances
    WHERE credits_expire = true
      AND expiration_date IS NOT NULL
      AND expiration_date < now()
      AND remaining_credits > 0
  LOOP
    -- Record expiration transaction
    INSERT INTO ai_credit_transactions (
      balance_id, owner_id, owner_type, school_id,
      transaction_type, credits, balance_before, balance_after,
      feature_name
    ) VALUES (
      v_balance.id, v_balance.owner_id, v_balance.owner_type, v_balance.school_id,
      'expiration', -v_balance.remaining_credits, v_balance.remaining_credits, 0,
      'credit_expiration'
    );

    -- Reset balance
    UPDATE ai_credit_balances SET
      remaining_credits = 0,
      used_credits = used_credits + remaining_credits
    WHERE id = v_balance.id;

    v_expired_count := v_expired_count + 1;
  END LOOP;

  RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════════════════

-- Subscription Plans: anyone can read active plans, only super_admin can modify
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read active subscription plans"
  ON subscription_plans FOR SELECT
  TO authenticated
  USING (is_active = true OR get_user_role() = 'super_admin');

CREATE POLICY "Super admins can manage subscription plans"
  ON subscription_plans FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Subscriptions: users see own subscriptions, school admins see school's
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own subscriptions"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (
    subscriber_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "Users can create own subscriptions"
  ON subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (
    subscriber_id = auth.uid()
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "Users can update own subscriptions"
  ON subscriptions FOR UPDATE
  TO authenticated
  USING (
    subscriber_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

-- Transactions: users see own transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "Users can create own transactions"
  ON transactions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() OR get_user_role() IN ('super_admin', 'school_admin'));

CREATE POLICY "Super admins can update transactions"
  ON transactions FOR UPDATE
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Invoices: users see own invoices
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own invoices"
  ON invoices FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "System can create invoices"
  ON invoices FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- Created by system/background jobs

CREATE POLICY "Super admins can update invoices"
  ON invoices FOR UPDATE
  TO authenticated
  USING (get_user_role() IN ('super_admin', 'school_admin'));

-- Receipts: users see own receipts
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own receipts"
  ON receipts FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

-- AI Credit Balances: owners see their own
ALTER TABLE ai_credit_balances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own credit balances"
  ON ai_credit_balances FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "System can modify credit balances"
  ON ai_credit_balances FOR ALL
  TO authenticated
  USING (get_user_role() IN ('super_admin', 'school_admin'));

-- AI Credit Transactions: owners see their own
ALTER TABLE ai_credit_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own credit transactions"
  ON ai_credit_transactions FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

-- Coupons: anyone can read active coupons, super_admin manages
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read active coupons"
  ON coupons FOR SELECT
  TO authenticated
  USING (is_active = true OR get_user_role() = 'super_admin');

CREATE POLICY "Super admins can manage coupons"
  ON coupons FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Coupon Redemptions: users see own redemptions
ALTER TABLE coupon_redemptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own coupon redemptions"
  ON coupon_redemptions FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "Users can redeem coupons"
  ON coupon_redemptions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Referral Codes: users see own codes
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own referral codes"
  ON referral_codes FOR SELECT
  TO authenticated
  USING (
    referrer_id = auth.uid()
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "Users can create own referral codes"
  ON referral_codes FOR INSERT
  TO authenticated
  WITH CHECK (referrer_id = auth.uid());

CREATE POLICY "Users can update own referral codes"
  ON referral_codes FOR UPDATE
  TO authenticated
  USING (referrer_id = auth.uid() OR get_user_role() = 'super_admin');

-- Referral Tracking: users see own referrals
ALTER TABLE referral_tracking ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own referral tracking"
  ON referral_tracking FOR SELECT
  TO authenticated
  USING (
    referrer_id = auth.uid()
    OR referee_id = auth.uid()
    OR get_user_role() = 'super_admin'
  );

-- Licenses: users see own licenses, school admins see school licenses
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read relevant licenses"
  ON licenses FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() IN ('super_admin', 'school_admin')
  );

CREATE POLICY "Super admins can manage licenses"
  ON licenses FOR ALL
  TO authenticated
  USING (get_user_role() IN ('super_admin', 'school_admin'));

-- Webhook Events: only super_admin
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can manage webhook events"
  ON webhook_events FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Billing Notifications: users see their own
ALTER TABLE billing_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own billing notifications"
  ON billing_notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR get_user_role() = 'super_admin');

CREATE POLICY "Users can update own billing notifications"
  ON billing_notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Billing Notification Preferences: users manage their own
ALTER TABLE billing_notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notification preferences"
  ON billing_notification_preferences FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- Revenue Reports: only super_admin
ALTER TABLE revenue_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can read revenue reports"
  ON revenue_reports FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

CREATE POLICY "Super admins can manage revenue reports"
  ON revenue_reports FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- School Billing Profiles: school admins and super_admin
ALTER TABLE school_billing_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "School admins can read own billing profile"
  ON school_billing_profiles FOR SELECT
  TO authenticated
  USING (
    school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can update own billing profile"
  ON school_billing_profiles FOR UPDATE
  TO authenticated
  USING (
    school_id IN (SELECT id FROM schools WHERE admin_id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

-- Billing Audit Logs: only super_admin can read
ALTER TABLE billing_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Super admins can read billing audit logs"
  ON billing_audit_logs FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

CREATE POLICY "System can create audit logs"
  ON billing_audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- System-generated

-- AI Credit Packs: anyone can read active packs
ALTER TABLE ai_credit_packs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read active credit packs"
  ON ai_credit_packs FOR SELECT
  TO authenticated
  USING (is_active = true OR get_user_role() = 'super_admin');

CREATE POLICY "Super admins can manage credit packs"
  ON ai_credit_packs FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Rate Limits: system only
ALTER TABLE billing_rate_limits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "System manages rate limits"
  ON billing_rate_limits FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ════════════════════════════════════════════════════════════════════════════
-- SEED DATA: DEFAULT SUBSCRIPTION PLANS
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO subscription_plans (name, tier, billing_model, description, monthly_price, annual_price, currency, max_students, max_teachers, max_schools, max_storage_mb, max_exams_per_month, ai_credits_monthly, includes_ai_workspace, includes_parent_portal, includes_communication, includes_advanced_analytics, includes_api_access, includes_white_label, includes_priority_support, includes_dedicated_manager, trial_days, is_active, is_popular, sort_order, features_list)
VALUES
  -- ═══ TEACHER SaaS PLANS ═══
  ('Free Teacher', 'free', 'teacher_saas', 'Get started with basic question generation and exam creation tools. Perfect for individual teachers exploring ExamForge AI.', 0, 0, 'NGN', 50, 1, 1, 100, 3, 10, false, false, false, false, false, false, false, false, 0, true, false, 1,
   '["Up to 50 students", "3 exams per month", "10 AI credits/month", "100 MB storage", "Basic question bank", "Email support"]'),

  ('Starter Teacher', 'starter', 'teacher_saas', 'Expand your teaching toolkit with more AI power, more students, and basic analytics to track performance.', 2500, 25000, 'NGN', 200, 1, 1, 500, 15, 50, true, false, false, false, false, false, false, false, 14, true, true, 2,
   '["Up to 200 students", "15 exams per month", "50 AI credits/month", "500 MB storage", "AI Teacher Workspace", "Basic analytics", "Email support"]'),

  ('Professional Teacher', 'professional', 'teacher_saas', 'Full teaching power: unlimited exams, advanced AI, parent portal, communication tools, and premium support.', 5000, 50000, 'NGN', 0, 1, 1, 2000, 0, 200, true, true, true, true, false, false, true, false, 14, true, false, 3,
   '["Unlimited students", "Unlimited exams", "200 AI credits/month", "2 GB storage", "AI Teacher Workspace", "Parent Portal", "Communication Suite", "Advanced Reports", "Priority support"]'),

  -- ═══ SCHOOL SaaS PLANS ═══
  ('Free School', 'free', 'school_saas', 'Try ExamForge AI for your school with limited features. Great for small schools getting started.', 0, 0, 'NGN', 100, 5, 1, 500, 10, 50, false, false, false, false, false, false, false, false, 0, true, false, 4,
   '["Up to 100 students", "5 teachers", "10 exams per month", "50 AI credits/month", "500 MB storage", "Basic question bank", "Email support"]'),

  ('Starter School', 'starter', 'school_saas', 'Empower your school with more capacity, AI tools, and basic analytics for better outcomes.', 15000, 150000, 'NGN', 500, 20, 1, 5000, 0, 300, true, false, false, false, false, false, false, false, 30, true, true, 5,
   '["Up to 500 students", "20 teachers", "Unlimited exams", "300 AI credits/month", "5 GB storage", "AI Teacher Workspace", "Basic analytics", "Email support"]'),

  ('Professional School', 'professional', 'school_saas', 'The complete school package: unlimited teachers, parent portal, communication suite, advanced reporting, and priority support.', 35000, 350000, 'NGN', 0, 0, 1, 20000, 0, 1000, true, true, true, true, false, false, true, false, 30, true, false, 6,
   '["Unlimited students", "Unlimited teachers", "Unlimited exams", "1,000 AI credits/month", "20 GB storage", "AI Teacher Workspace", "Parent Portal", "Communication Suite", "Advanced Reports", "Priority support"]'),

  -- ═══ ENTERPRISE SaaS PLANS ═══
  ('Enterprise', 'enterprise', 'enterprise_saas', 'For organizations, ministries, and examination bodies needing custom pricing, white-label branding, API access, and dedicated account management.', 0, 0, 'NGN', 0, 0, 0, 0, 0, 0, true, true, true, true, true, true, true, true, 60, true, false, 7,
   '["Unlimited everything", "White-label branding", "Full API access", "Custom AI credit packages", "Dedicated account manager", "Priority support", "Advanced security", "Custom integrations", "SLA guarantee", "On-premise option"]')
ON CONFLICT DO NOTHING;

-- ═══ SEED: AI CREDIT PACKS ═══
INSERT INTO ai_credit_packs (name, description, credits, price, currency, validity_days, is_active, sort_order, applicable_billing_models)
VALUES
  ('Starter Pack', 'Perfect for topping up your monthly allocation. 50 AI credits to power question generation and smart marking.', 50, 1000, 'NGN', 90, true, 1, '["teacher_saas", "school_saas"]'),
  ('Growth Pack', 'Great value for active teachers and small schools. 200 AI credits with extended validity.', 200, 3500, 'NGN', 180, true, 2, '["teacher_saas", "school_saas"]'),
  ('Professional Pack', 'Best value per credit. 500 AI credits for power users and larger schools.', 500, 7500, 'NGN', 365, true, 3, '["teacher_saas", "school_saas", "enterprise_saas"]'),
  ('Enterprise Pack', 'Bulk credits for organizations and examination bodies. 2,000 AI credits at the lowest per-credit rate.', 2000, 25000, 'NGN', 365, true, 4, '["enterprise_saas", "school_saas"]')
ON CONFLICT DO NOTHING;

-- ════════════════════════════════════════════════════════════════════════════
-- VIEWS FOR DASHBOARD QUERIES
-- ════════════════════════════════════════════════════════════════════════════

-- Active subscription summary
CREATE OR REPLACE VIEW v_active_subscriptions AS
SELECT
  s.id,
  s.subscriber_id,
  s.subscriber_type,
  s.school_id,
  s.plan_id,
  sp.name AS plan_name,
  sp.tier AS plan_tier,
  s.status,
  s.billing_cycle,
  s.current_period_start,
  s.current_period_end,
  s.seats_purchased,
  s.seats_used,
  s.auto_renew,
  s.price_at_subscription,
  s.currency
FROM subscriptions s
JOIN subscription_plans sp ON s.plan_id = sp.id
WHERE s.status IN ('active', 'trial');

-- Revenue summary by month
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
  date_trunc('month', t.initiated_at) AS month,
  t.currency,
  count(*) AS transaction_count,
  sum(t.amount) FILTER (WHERE t.status = 'successful') AS successful_volume,
  sum(t.net_amount) FILTER (WHERE t.status = 'successful') AS net_revenue,
  sum(t.amount) FILTER (WHERE t.status = 'refunded') AS refund_volume,
  count(*) FILTER (WHERE t.status = 'failed') AS failed_count
FROM transactions t
GROUP BY 1, 2
ORDER BY 1 DESC;

-- Credit usage summary
CREATE OR REPLACE VIEW v_credit_usage AS
SELECT
  act.owner_id,
  act.owner_type,
  acb.school_id,
  act.feature_name,
  count(*) AS transaction_count,
  sum(abs(act.credits)) AS total_credits_used,
  sum(act.estimated_cost_usd) AS total_estimated_cost,
  date_trunc('day', act.created_at) AS usage_date
FROM ai_credit_transactions act
JOIN ai_credit_balances acb ON act.balance_id = acb.id
WHERE act.transaction_type = 'usage'
GROUP BY 1, 2, 3, 4, 7
ORDER BY 7 DESC;

COMMIT;
