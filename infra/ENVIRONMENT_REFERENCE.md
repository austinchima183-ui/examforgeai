# ============================================================================
# ExamForge AI — Complete Environment Variable Reference
# ============================================================================
# This document provides a comprehensive reference for ALL environment
# variables used across the ExamForge AI platform.
#
# ROOT CAUSE: No centralized documentation of environment variables existed.
# Secrets were scattered across multiple files with no rotation policy,
# no audit logging, and no least-privilege enforcement.
#
# SECURITY MODEL:
#   - No API keys in source code (enforced by CI secret scanning)
#   - No secrets committed to Git (enforced by .gitignore + gitleaks)
#   - Environment-specific configuration per deployment target
#   - Secure secret rotation process documented
#   - Least-privilege access per environment
#   - Secret access audit logging
# ============================================================================

# ════════════════════════════════════════════════════════════════════════════
# TIER 1: CRITICAL SECRETS (Must be in Secrets Manager — never in code)
# ════════════════════════════════════════════════════════════════════════════

# --- Supabase ---
SUPABASE_URL                    # Project URL (not a secret, but environment-specific)
SUPABASE_ANON_KEY               # Public anon key (safe in client code, rotates yearly)
SUPABASE_SERVICE_ROLE_KEY       # Service role key (CRITICAL — server-side only, never in client)
# NOTE: Do NOT use SUPABASE_SERVICE_KEY — all Edge Functions use SUPABASE_SERVICE_ROLE_KEY

# --- Flutterwave Payment ---
FLUTTERWAVE_PUBLIC_KEY          # Client-side key (safe in Flutter app)
FLUTTERWAVE_SECRET_KEY          # Server-side key (CRITICAL — Edge Functions only)
FLUTTERWAVE_WEBHOOK_SECRET_HASH # Webhook verification hash (CRITICAL — Edge Functions only)

# --- Firebase Cloud Messaging ---
FCM_SERVER_KEY                  # Push notification server key (server-side only)

# --- Database ---
PRODUCTION_DATABASE_URL         # PostgreSQL connection string (CRITICAL)
STAGING_DATABASE_URL            # Staging PostgreSQL connection string
DATABASE_URL                    # Active environment DB URL (set by deploy script)

# --- Deployment ---
PRODUCTION_HOST                 # Production server hostname
PRODUCTION_USER                 # Production SSH deploy user
STAGING_HOST                    # Staging server hostname
STAGING_USER                    # Staging SSH deploy user

# --- Encryption ---
ENCRYPTION_MASTER_KEY           # Master key for key derivation (future use)
GPG_RECIPIENT                   # GPG key ID for backup encryption

# --- Cloud Storage ---
AWS_ACCESS_KEY_ID               # S3 access key for backups
AWS_SECRET_ACCESS_KEY           # S3 secret key for backups
AWS_REGION                      # AWS region (us-east-1)
AWS_ENDPOINT                    # Custom S3 endpoint (for S3-compatible storage)
S3_BUCKET                       # Backup bucket name

# --- Monitoring ---
SENTRY_DSN                      # Sentry error tracking DSN (if enabled)
GRAFANA_API_KEY                 # Grafana API key (if self-hosted)

# ════════════════════════════════════════════════════════════════════════════
# TIER 2: CONFIGURATION (Environment-specific, not secrets)
# ════════════════════════════════════════════════════════════════════════════

# --- Application ---
ENVIRONMENT                     # development | staging | production
APP_URL                         # Public-facing application URL
API_URL                         # API base URL

# --- Database ---
DB_HOST                         # Database host
DB_PORT                         # Database port (default: 5432)
DB_NAME                         # Database name
DB_USER                         # Database user (least-privilege application user)
DB_PASSWORD                     # Database password (Tier 1 secret)
DB_POOL_MIN                     # Connection pool minimum (default: 2)
DB_POOL_MAX                     # Connection pool maximum (default: 20)

# --- Deployment ---
DEPLOY_PATH                     # Remote deployment directory
DEPLOY_STRATEGY                 # standard | blue-green
BACKUP_ENABLED                  # true | false
ROLLBACK_ENABLED                # true | false
HEALTH_CHECK_URL                # Health check endpoint URL

# --- Monitoring ---
SLOW_QUERY_THRESHOLD_MS         # Slow query threshold (default: 500ms)
HEALTH_CHECK_INTERVAL_SEC       # Health check interval (default: 300s)
LOG_LEVEL                       # debug | info | warning | error | critical

# ════════════════════════════════════════════════════════════════════════════
# ENVIRONMENT-SPECIFIC DEFAULTS
# ════════════════════════════════════════════════════════════════════════════

# --- Development ---
# ENVIRONMENT=development
# APP_URL=http://localhost:3000
# SUPABASE_URL=http://localhost:54321
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=examforge_dev
# BACKUP_ENABLED=false

# --- Staging ---
# ENVIRONMENT=staging
# APP_URL=https://staging.examforge.ai
# DB_HOST=staging-db.examforge.ai
# BACKUP_ENABLED=true
# SLOW_QUERY_THRESHOLD_MS=500

# --- Production ---
# ENVIRONMENT=production
# APP_URL=https://examforge.ai
# DB_HOST=prod-db.examforge.ai
# BACKUP_ENABLED=true
# SLOW_QUERY_THRESHOLD_MS=300
# DB_POOL_MAX=50

# ════════════════════════════════════════════════════════════════════════════
# SECRET ROTATION SCHEDULE
# ════════════════════════════════════════════════════════════════════════════

# | Secret                          | Rotation Period | Process                          |
# |---------------------------------|-----------------|----------------------------------|
# | SUPABASE_SERVICE_ROLE_KEY        | 90 days         | Supabase Dashboard → Settings    |
# | FLUTTERWAVE_SECRET_KEY          | 90 days         | Flutterwave Dashboard → API Keys |
# | FLUTTERWAVE_WEBHOOK_SECRET_HASH | 90 days         | Flutterwave Dashboard → Webhooks |
# | FCM_SERVER_KEY                  | 180 days        | Firebase Console → Cloud Message |
# | DATABASE_URL (password)         | 90 days         | SQL ALTER ROLE + update secrets  |
# | GPG_RECIPIENT key               | 365 days        | Generate new key, re-encrypt     |
# | AWS credentials                 | 90 days         | AWS IAM → Rotate credentials     |
# | Encryption master key           | On compromise   | Key rotation procedure           |

# ════════════════════════════════════════════════════════════════════════════
# SECRET ACCESS AUDIT LOGGING
# ════════════════════════════════════════════════════════════════════════════

# All secret access is logged with:
#   - Timestamp (UTC)
#   - User/service account that accessed the secret
#   - Secret name (NOT the value)
#   - Action (read, rotate, delete)
#   - Source IP
#   - Correlation ID

# Secret access logs are stored in:
#   - GitHub Actions audit log (for CI/CD secrets)
#   - Supabase audit log (for application secrets)
#   - Cloud provider audit log (for infrastructure secrets)
