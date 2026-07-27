# ExamForge AI — Environment Configuration Guide

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **Review Cycle:** Quarterly (aligned with access reviews)

---

## Table of Contents

1. [All Environment Variables and Their Purpose](#1-all-environment-variables-and-their-purpose)
2. [Per-Environment Configuration Differences](#2-per-environment-configuration-differences)
3. [Secret Management](#3-secret-management)
4. [Environment Provisioning Steps](#4-environment-provisioning-steps)
5. [Configuration Validation Checklist](#5-configuration-validation-checklist)

---

## 1. All Environment Variables and Their Purpose

### 1.1 Tier 1: Critical Secrets

These variables contain sensitive values that must never be committed to source code or logged.

| Variable | Purpose | Example Value | Used By |
|----------|---------|---------------|---------|
| `SUPABASE_URL` | Supabase project URL (environment-specific, not a secret per se) | `https://abc123.supabase.co` | Flutter app, Edge Functions, deploy scripts |
| `SUPABASE_ANON_KEY` | Public anonymous key (safe in client code; rotates yearly) | `eyJhbGciOiJIUzI1NiIs...` | Flutter app (`SupabaseConfig.initialize()`) |
| `SUPABASE_SERVICE_KEY` | Service role key — **CRITICAL: server-side only, never in client** | `eyJhbGciOiJIUzI1NiIs...` | Edge Functions, deploy scripts, monitoring |
| `SUPABASE_SERVICE_ROLE_KEY` | Alias for `SUPABASE_SERVICE_KEY` in Edge Functions | Same as above | Edge Functions (`Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`) |
| `FLUTTERWAVE_PUBLIC_KEY` | Client-side Flutterwave key (safe in Flutter app) | `FLWPUBK_TEST-...` | Flutter app (payment widget) |
| `FLUTTERWAVE_SECRET_KEY` | Server-side Flutterwave key — **CRITICAL: Edge Functions only** | `FLWSECK_TEST-...` | Edge Functions (`flutterwave-webhook`, `process-refund`, `health-check`) |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | Webhook verification hash — **CRITICAL: Edge Functions only** | `a1b2c3d4e5f6...` | `flutterwave-webhook` Edge Function |
| `FCM_SERVER_KEY` | Firebase Cloud Messaging server key (server-side only) | `AAAAxxxx...` | Push notification service |
| `PRODUCTION_DATABASE_URL` | PostgreSQL connection string for production | `postgresql://examforge_app:pass@prod-db.examforge.ai:5432/examforge_production` | Deploy scripts, backup scripts |
| `STAGING_DATABASE_URL` | PostgreSQL connection string for staging | `postgresql://examforge_app:pass@staging-db.examforge.ai:5432/examforge_staging` | Deploy scripts, backup scripts |
| `DATABASE_URL` | Active environment DB URL (set by deploy script at runtime) | Same as production or staging URL | Runtime — set by `deploy.sh` based on target |
| `PRODUCTION_HOST` | Production server hostname | `prod-db.examforge.ai` | Deploy scripts (SSH target) |
| `PRODUCTION_USER` | Production SSH deploy user | `deploy` | Deploy scripts (SSH user) |
| `STAGING_HOST` | Staging server hostname | `staging-db.examforge.ai` | Deploy scripts (SSH target) |
| `STAGING_USER` | Staging SSH deploy user | `deploy` | Deploy scripts (SSH user) |
| `ENCRYPTION_MASTER_KEY` | Master key for key derivation (future use) | 256-bit hex string | Local encryption service |
| `GPG_RECIPIENT` | GPG key ID for backup encryption | `admin@examforge.ai` | Backup scripts |
| `AWS_ACCESS_KEY_ID` | S3 access key for backups | `AKIAIOSFODNN7EXAMPLE` | Backup scripts (S3 upload) |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key for backups | `wJalrXUtnFEMI/K7MDENG/...` | Backup scripts (S3 upload) |
| `SENTRY_DSN` | Sentry error tracking DSN | `https://key@sentry.io/project` | Application error reporting |
| `GRAFANA_API_KEY` | Grafana API key (if self-hosted) | `glsa_xxxxxxxx...` | Monitoring dashboards |

### 1.2 Tier 2: Configuration (Environment-Specific, Not Secrets)

| Variable | Purpose | Default | Used By |
|----------|---------|---------|---------|
| `ENVIRONMENT` | Current environment identifier | `development` | All services — controls feature flags, timeouts, CORS origins |
| `APP_URL` | Public-facing application URL | `http://localhost:3000` | CORS, health checks, deep links |
| `API_URL` | API base URL | `http://localhost:3001` | Flutter app API calls |
| `DB_HOST` | Database host | `localhost` | Backup scripts, direct DB connections |
| `DB_PORT` | Database port | `5432` | Backup scripts, direct DB connections |
| `DB_NAME` | Database name | `examforge_dev` | Backup scripts |
| `DB_USER` | Database user (least-privilege application user) | `postgres` | Backup scripts |
| `DB_PASSWORD` | Database password (Tier 1 when production) | — | Backup scripts |
| `DB_POOL_MIN` | Connection pool minimum | `2` | Database pool manager |
| `DB_POOL_MAX` | Connection pool maximum | `20` (prod: `50`) | Database pool manager |
| `DEPLOY_PATH` | Remote deployment directory | `/var/www/examforge-dev` | Deploy scripts |
| `DEPLOY_STRATEGY` | Deployment strategy | `standard` | Deploy scripts (`standard` or `blue-green`) |
| `BACKUP_ENABLED` | Whether to run pre-deploy backups | `false` (dev) / `true` (staging/prod) | Deploy scripts |
| `ROLLBACK_ENABLED` | Whether to enable automatic rollback | `true` | Deploy scripts |
| `HEALTH_CHECK_URL` | Health check endpoint URL | `${APP_URL}/health` | Deploy scripts |
| `SLOW_QUERY_THRESHOLD_MS` | Slow query threshold in milliseconds | `500` (prod: `300`) | Monitoring |
| `HEALTH_CHECK_INTERVAL_SEC` | Health check interval in seconds | `300` | Monitoring |
| `LOG_LEVEL` | Logging verbosity | `info` | Application logger |
| `AWS_REGION` | AWS region for S3 backups | `af-south-1` | Backup scripts |
| `AWS_ENDPOINT` | Custom S3 endpoint (for S3-compatible storage) | — (use default AWS) | Backup scripts |
| `S3_BUCKET` | S3 bucket name for backups | `examforge-backups-prod` | Backup scripts |
| `DEPLOY_HOST` | Resolved deployment host (set by deploy script) | Same as `PRODUCTION_HOST` or `STAGING_HOST` | Deploy scripts |
| `DEPLOY_USER` | Resolved deployment user (set by deploy script) | Same as `PRODUCTION_USER` or `STAGING_USER` | Deploy scripts |

### 1.3 Compile-Time Variables (Flutter --dart-define)

In release builds, environment variables are passed via `--dart-define` flags since the `.env` file is not available:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://abc123.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs... \
  --dart-define=SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIs... \
  --dart-define=FCM_SERVER_KEY=AAAAxxxx... \
  --dart-define=FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_TEST-... \
  --dart-define=FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-... \
  --dart-define=ENVIRONMENT=production
```

These are read in `EnvConfig.initialize()` via `String.fromEnvironment()` when the `.env` file is unavailable (release builds).

### 1.4 Edge Function Environment Variables

Supabase Edge Functions access environment variables via `Deno.env.get()`:

| Variable | Function | Access Pattern |
|----------|----------|---------------|
| `SUPABASE_URL` | All Edge Functions | `Deno.env.get('SUPABASE_URL')` |
| `SUPABASE_SERVICE_ROLE_KEY` | All Edge Functions | `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')` |
| `FLUTTERWAVE_SECRET_KEY` | `flutterwave-webhook`, `process-refund`, `health-check` | `Deno.env.get('FLUTTERWAVE_SECRET_KEY')` |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | `flutterwave-webhook` | `Deno.env.get('FLUTTERWAVE_WEBHOOK_SECRET_HASH')` |
| `ENVIRONMENT` | `health-check` | `Deno.env.get('ENVIRONMENT')` |
| `DEPLOY_VERSION` | `health-check` | `Deno.env.get('DEPLOY_VERSION')` |

---

## 2. Per-Environment Configuration Differences

### 2.1 Development

```bash
ENVIRONMENT=development
APP_URL=http://localhost:3000
API_URL=http://localhost:3001
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_KEY=dev-key
DB_HOST=localhost
DB_PORT=5432
DB_NAME=examforge_dev
DB_USER=postgres
BACKUP_ENABLED=false
ROLLBACK_ENABLED=true
DEPLOY_PATH=/var/www/examforge-dev
HEALTH_CHECK_URL=http://localhost:3000/health
SLOW_QUERY_THRESHOLD_MS=500
DB_POOL_MAX=20
LOG_LEVEL=debug
```

**Feature flags (development):**

| Flag | Enabled |
|------|---------|
| `ai_question_generation` | Yes |
| `ai_exam_hints` | Yes |
| `offline_mode` | Yes |
| `dark_mode` | Yes |
| `push_notifications` | Yes |
| `payment_gateway` | Yes |
| `biometric_login` | Yes |
| `multi_school` | Yes |
| `advanced_analytics` | Yes |
| `export_pdf` | Yes |

**Timeouts:**
- Connect: 30 seconds
- Receive: 30 seconds
- Send: 30 seconds

**CORS origins:** `http://localhost:3000`, `http://localhost:5173`

### 2.2 Staging

```bash
ENVIRONMENT=staging
APP_URL=https://staging.examforge.ai
API_URL=https://staging-api.examforge.ai
SUPABASE_URL=${STAGING_SUPABASE_URL}
SUPABASE_SERVICE_KEY=${STAGING_SUPABASE_SERVICE_KEY}
DB_HOST=staging-db.examforge.ai
DB_PORT=5432
DB_NAME=examforge_staging
DB_USER=examforge_app
BACKUP_ENABLED=true
ROLLBACK_ENABLED=true
DEPLOY_PATH=/var/www/examforge-staging
HEALTH_CHECK_URL=https://staging.examforge.ai/health
SLOW_QUERY_THRESHOLD_MS=500
DB_POOL_MAX=20
LOG_LEVEL=info
```

**Feature flags (staging):**

| Flag | Enabled |
|------|---------|
| `ai_question_generation` | Yes |
| `ai_exam_hints` | Yes |
| `offline_mode` | Yes |
| `dark_mode` | Yes |
| `push_notifications` | Yes |
| `payment_gateway` | Yes |
| `biometric_login` | Yes |
| `multi_school` | Yes |
| `advanced_analytics` | Yes |
| `export_pdf` | Yes |

**Timeouts:**
- Connect: 20 seconds
- Receive: 20 seconds
- Send: 20 seconds

**CORS origins:** `https://staging.examforge.ai`, `https://staging-app.examforge.ai`

### 2.3 Production

```bash
ENVIRONMENT=production
APP_URL=https://examforge.ai
API_URL=https://api.examforge.ai
SUPABASE_URL=${PRODUCTION_SUPABASE_URL}
SUPABASE_SERVICE_KEY=${PRODUCTION_SUPABASE_SERVICE_KEY}
DB_HOST=prod-db.examforge.ai
DB_PORT=5432
DB_NAME=examforge_production
DB_USER=examforge_app
BACKUP_ENABLED=true
ROLLBACK_ENABLED=true
DEPLOY_PATH=/var/www/examforge
HEALTH_CHECK_URL=https://examforge.ai/health
SLOW_QUERY_THRESHOLD_MS=300
DB_POOL_MAX=50
LOG_LEVEL=warning
```

**Feature flags (production):**

| Flag | Enabled |
|------|---------|
| `ai_question_generation` | Yes |
| `ai_exam_hints` | No |
| `offline_mode` | No |
| `dark_mode` | Yes |
| `push_notifications` | Yes |
| `payment_gateway` | Yes |
| `biometric_login` | No |
| `multi_school` | No |
| `advanced_analytics` | No |
| `export_pdf` | Yes |

**Timeouts:**
- Connect: 15 seconds
- Receive: 15 seconds
- Send: 15 seconds

**CORS origins:** `https://examforge.ai`, `https://www.examforge.ai`, `https://app.examforge.ai`, `https://admin.examforge.ai`

### 2.4 Configuration Comparison Matrix

| Parameter | Development | Staging | Production |
|-----------|------------|---------|------------|
| App URL | `localhost:3000` | `staging.examforge.ai` | `examforge.ai` |
| Database | `localhost:5432/examforge_dev` | `staging-db:5432/examforge_staging` | `prod-db:5432/examforge_production` |
| Backups | Disabled | Enabled (encrypted) | Enabled (encrypted + DR replication) |
| Connection pool max | 20 | 20 | 50 |
| Slow query threshold | 500ms | 500ms | 300ms |
| Verbose logging | Yes | Yes | No |
| Connect timeout | 30s | 20s | 15s |
| Experimental features | All enabled | All enabled | Production-only |
| CORS origins | localhost | staging subdomains | production domains |

---

## 3. Secret Management

### 3.1 Secret Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SECRET SOURCES                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   GitHub     │  │   Supabase   │  │    AWS       │     │
│  │   Secrets    │  │   Vault      │  │    IAM       │     │
│  │              │  │              │  │              │     │
│  │ • CI/CD vars │  │ • Edge Fn    │  │ • S3 access  │     │
│  │ • Deploy     │  │   secrets    │  │ • Backup     │     │
│  │   scripts    │  │ • App        │  │   uploads    │     │
│  │ • Build      │  │   secrets    │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                            ▼                                │
│                    ┌──────────────┐                         │
│                    │  Application │                         │
│                    │  Runtime     │                         │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 GitHub Secrets

GitHub Secrets store variables needed by CI/CD pipelines and the deploy script.

**Setting a secret:**
```bash
# Using the GitHub CLI
gh secret set SUPABASE_SERVICE_KEY --body "<value>" --repo examforge-ai/examforge-ai

# Setting for a specific environment
gh secret set PRODUCTION_DATABASE_URL --body "<value>" --repo examforge-ai/examforge-ai --env production
```

**Secrets stored in GitHub:**

| Secret | Environment | Purpose |
|--------|------------|---------|
| `SUPABASE_SERVICE_KEY` | All | Service role key for Edge Functions |
| `PRODUCTION_DATABASE_URL` | Production | Database connection string |
| `STAGING_DATABASE_URL` | Staging | Database connection string |
| `PRODUCTION_HOST` | Production | SSH deployment target |
| `PRODUCTION_USER` | Production | SSH deployment user |
| `STAGING_HOST` | Staging | SSH deployment target |
| `STAGING_USER` | Staging | SSH deployment user |
| `PRODUCTION_SUPABASE_URL` | Production | Supabase project URL |
| `PRODUCTION_SUPABASE_SERVICE_KEY` | Production | Supabase service key (production) |
| `STAGING_SUPABASE_URL` | Staging | Staging Supabase URL |
| `STAGING_SUPABASE_SERVICE_KEY` | Staging | Staging Supabase service key |
| `FLUTTERWAVE_SECRET_KEY` | All | Flutterwave API key |
| `FCM_SERVER_KEY` | All | Firebase Cloud Messaging key |
| `AWS_ACCESS_KEY_ID` | All | S3 backup access |
| `AWS_SECRET_ACCESS_KEY` | All | S3 backup secret |

### 3.3 Supabase Vault

Supabase Vault stores secrets needed by Edge Functions at runtime.

**Setting a secret in Supabase Vault:**
```bash
# Via Supabase CLI
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIs... --project-id examforge-production
supabase secrets set FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-... --project-id examforge-production
supabase secrets set FLUTTERWAVE_WEBHOOK_SECRET_HASH=a1b2c3d4e5f6... --project-id examforge-production
supabase secrets set ENVIRONMENT=production --project-id examforge-production

# Listing secrets
supabase secrets list --project-id examforge-production
```

**Secrets stored in Supabase Vault (per environment):**

| Secret | Production | Staging | Development |
|--------|-----------|---------|-------------|
| `SUPABASE_URL` | Yes | Yes | No (local) |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Yes | No (local) |
| `FLUTTERWAVE_SECRET_KEY` | Yes | Yes (test key) | No |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | Yes | Yes (test hash) | No |
| `ENVIRONMENT` | `production` | `staging` | — |
| `DEPLOY_VERSION` | Updated per deploy | Updated per deploy | — |

### 3.4 Local Secret Management (Development)

For local development, secrets are stored in the `.env` file:

```bash
# Copy the template
cp .env.example .env

# Fill in development values
# .env is listed in .gitignore and will NEVER be committed
```

**Fallback behavior (from `EnvConfig`):** In release builds without a `.env` file, the app falls back to `--dart-define` compile-time constants. In debug builds, safe placeholder values are used so the app can still launch.

### 3.5 Secret Access Audit Logging

All secret access is logged with:

| Field | Description |
|-------|-------------|
| Timestamp (UTC) | When the secret was accessed |
| User/service account | Who accessed the secret |
| Secret name | The name of the secret (NOT the value) |
| Action | `read`, `rotate`, or `delete` |
| Source IP | Where the access originated |
| Correlation ID | For tracing across services |

**Audit log locations:**

| System | Audit Location |
|--------|---------------|
| GitHub Actions | GitHub audit log (Settings → Audit log) |
| Supabase | `admin_access_log` table + Supabase Dashboard audit |
| AWS | CloudTrail |

### 3.6 Secret Rotation Schedule

| Secret | Rotation Period | Process | Owner |
|--------|----------------|---------|-------|
| `SUPABASE_SERVICE_KEY` | 90 days | Supabase Dashboard → Settings → API → Regenerate | Platform engineering |
| `FLUTTERWAVE_SECRET_KEY` | 90 days | Flutterwave Dashboard → Settings → API Keys | Finance + Engineering |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | 90 days | Flutterwave Dashboard → Settings → Webhooks | Engineering |
| `FCM_SERVER_KEY` | 180 days | Firebase Console → Cloud Messaging | Engineering |
| `DATABASE_URL` (password) | 90 days | SQL `ALTER ROLE` + update secrets | Platform engineering |
| `GPG_RECIPIENT` key | 365 days | Generate new key, re-encrypt | Security team |
| `AWS credentials` | 90 days | AWS IAM → Rotate credentials | Infrastructure team |
| `ENCRYPTION_MASTER_KEY` | On compromise only | Key rotation procedure | Security team |

---

## 4. Environment Provisioning Steps

### 4.1 Provisioning a New Development Environment

```bash
# 1. Clone the repository
git clone https://github.com/examforge-ai/examforge-ai.git
cd examforge-ai

# 2. Install Flutter SDK (3.22+)
# Follow: https://docs.flutter.dev/get-started/install

# 3. Install dependencies
flutter pub get

# 4. Copy environment template
cp .env.example .env
# Edit .env with your Supabase project credentials

# 5. Start local Supabase (optional, for full local development)
supabase init
supabase start
# Note the local credentials printed by supabase start

# 6. Apply migrations
supabase db push

# 7. Run the app
flutter run -d chrome
```

### 4.2 Provisioning a New Staging Environment

```bash
# 1. Create a new Supabase project
# Via Supabase Dashboard or CLI:
supabase projects create examforge-staging-new --region af-south-1

# 2. Note the project URL and keys
# From: Supabase Dashboard → Settings → API

# 3. Apply all migrations
for migration in supabase/migrations/*.sql; do
  echo "Applying: $(basename $migration)"
  psql "${STAGING_DATABASE_URL}" -f "$migration"
done

# 4. Set up Supabase Vault secrets
supabase secrets set \
  SUPABASE_SERVICE_ROLE_KEY=<key> \
  FLUTTERWAVE_SECRET_KEY=<test-key> \
  FLUTTERWAVE_WEBHOOK_SECRET_HASH=<test-hash> \
  ENVIRONMENT=staging \
  --project-id examforge-staging-new

# 5. Deploy Edge Functions
supabase functions deploy health-check --project-id examforge-staging-new
supabase functions deploy flutterwave-webhook --project-id examforge-staging-new
supabase functions deploy process-refund --project-id examforge-staging-new
supabase functions deploy marketplace-download --project-id examforge-staging-new

# 6. Configure Flutterwave webhook
# Flutterwave Dashboard → Settings → Webhooks
# URL: https://staging.examforge.ai/functions/v1/flutterwave-webhook
# Secret hash: matches FLUTTERWAVE_WEBHOOK_SECRET_HASH

# 7. Update GitHub Secrets
gh secret set STAGING_DATABASE_URL --body "<new-url>" --repo examforge-ai/examforge-ai
gh secret set STAGING_HOST --body "<new-host>" --repo examforge-ai/examforge-ai
gh secret set STAGING_SUPABASE_URL --body "<new-url>" --repo examforge-ai/examforge-ai
gh secret set STAGING_SUPABASE_SERVICE_KEY --body "<new-key>" --repo examforge-ai/examforge-ai

# 8. Create storage buckets
# Via Supabase Dashboard → Storage:
# - exam-files (private, 50MB limit)
# - profile-images (public, 5MB limit)
# - marketplace-files (private, 100MB limit)
# - question-media (private, 20MB limit)

# 9. Build and deploy the Flutter web app
flutter build web --release \
  --dart-define=SUPABASE_URL=<new-url> \
  --dart-define=SUPABASE_ANON_KEY=<new-anon-key> \
  --dart-define=ENVIRONMENT=staging

# 10. Verify the deployment
curl -s https://staging.examforge.ai/functions/v1/health-check | jq .
```

### 4.3 Provisioning a New Production Environment

> **⚠️ Production provisioning requires CTO approval and should follow the full deployment checklist in `lib/config/deployment_checklist.dart`.**

```bash
# 1. Create the Supabase production project
supabase projects create examforge-production --region af-south-1

# 2. Apply all migrations (IN ORDER)
# Use the deploy script for this:
./scripts/deploy.sh production --migrate-only

# 3. Set up production secrets in Supabase Vault
supabase secrets set \
  SUPABASE_SERVICE_ROLE_KEY=<production-key> \
  FLUTTERWAVE_SECRET_KEY=<production-key> \
  FLUTTERWAVE_WEBHOOK_SECRET_HASH=<production-hash> \
  ENVIRONMENT=production \
  --project-id examforge-production

# 4. Set up production secrets in GitHub
gh secret set PRODUCTION_DATABASE_URL --body "<url>" --repo examforge-ai/examforge-ai
gh secret set PRODUCTION_HOST --body "<host>" --repo examforge-ai/examforge-ai
gh secret set PRODUCTION_USER --body "deploy" --repo examforge-ai/examforge-ai
gh secret set PRODUCTION_SUPABASE_URL --body "<url>" --repo examforge-ai/examforge-ai
gh secret set PRODUCTION_SUPABASE_SERVICE_KEY --body "<key>" --repo examforge-ai/examforge-ai
gh secret set SUPABASE_SERVICE_KEY --body "<key>" --repo examforge-ai/examforge-ai
gh secret set FLUTTERWAVE_SECRET_KEY --body "<key>" --repo examforge-ai/examforge-ai
gh secret set FCM_SERVER_KEY --body "<key>" --repo examforge-ai/examforge-ai
gh secret set AWS_ACCESS_KEY_ID --body "<key>" --repo examforge-ai/examforge-ai
gh secret set AWS_SECRET_ACCESS_KEY --body "<key>" --repo examforge-ai/examforge-ai

# 5. Provision infrastructure with Terraform
cd infra/terraform
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan

# 6. Deploy Edge Functions
supabase functions deploy health-check --project-id examforge-production
supabase functions deploy flutterwave-webhook --project-id examforge-production
supabase functions deploy process-refund --project-id examforge-production
supabase functions deploy marketplace-download --project-id examforge-production

# 7. Configure production Flutterwave webhook
# Use production Flutterwave account (NOT test mode)
# Webhook URL: https://examforge.ai/functions/v1/flutterwave-webhook

# 8. Create S3 buckets
aws s3 mb s3://examforge-backups-prod --region af-south-1
aws s3 mb s3://examforge-backups-dr --region eu-west-1

# 9. Set up backup cron jobs
# Add the cron entries from the backup-restore-guide.md to the production server

# 10. Build and deploy
flutter build web --release \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --dart-define=SUPABASE_SERVICE_KEY=<prod-service-key> \
  --dart-define=FCM_SERVER_KEY=<fcm-key> \
  --dart-define=FLUTTERWAVE_PUBLIC_KEY=<flw-public-key> \
  --dart-define=FLUTTERWAVE_SECRET_KEY=<flw-secret-key> \
  --dart-define=ENVIRONMENT=production

./scripts/deploy.sh production --blue-green

# 11. Run the full deployment validation checklist
# See: docs/operations/deployment-guide.md Section 7

# 12. Verify health
curl -s https://examforge.ai/functions/v1/health-check | jq .
```

### 4.4 Decommissioning an Environment

```bash
# 1. Take a final backup
./scripts/backup_dr.sh backup <env> --full --encrypt --verify --upload

# 2. Delete Supabase project
# Via Supabase Dashboard → Settings → General → Delete Project
# WARNING: This is irreversible

# 3. Delete S3 buckets
aws s3 rb s3://examforge-backups-<env> --force --region af-south-1

# 4. Remove GitHub Secrets
gh secret delete <SECRET_NAME> --repo examforge-ai/examforge-ai

# 5. Remove SSH keys from the decommissioned server

# 6. Update Terraform configuration and apply
cd infra/terraform
terraform plan -var-file=terraform.tfvars -destroy
terraform apply -var-file=terraform.tfvars -destroy

# 7. Document the decommissioning
# Record: date, reason, final backup location, who approved
```

---

## 5. Configuration Validation Checklist

### 5.1 Pre-Deployment Configuration Checklist

Run through this checklist before every production deployment:

- [ ] **All required environment variables are set** — Verify in GitHub Secrets and Supabase Vault
- [ ] **No secrets in source code** — Run `gitleaks detect --source .`
- [ ] **`.env` file is in `.gitignore`** — Verify `.env` is listed
- [ ] **Database URL is correct** — Verify connectivity: `psql "${PRODUCTION_DATABASE_URL}" -c "SELECT 1;"`
- [ ] **Supabase URL and keys match the production project** — Verify in Supabase Dashboard
- [ ] **Flutterwave keys are for production (not test)** — Verify in Flutterwave Dashboard
- [ ] **CORS origins match the environment** — Check Edge Function CORS configuration
- [ ] **Feature flags are set correctly for production** — Review `feature_flags` table
- [ ] **Connection pool size is appropriate** — `DB_POOL_MAX=50` for production
- [ ] **Timeouts are set for production** — 15s for all timeouts
- [ ] **Slow query threshold is 300ms** — Verify `SLOW_QUERY_THRESHOLD_MS=300`
- [ ] **Backup is enabled** — Verify `BACKUP_ENABLED=true`
- [ ] **Logging level is appropriate** — `LOG_LEVEL=warning` in production
- [ ] **Health check URL is correct** — Verify `curl -s https://examforge.ai/health | jq .`

### 5.2 Post-Configuration Verification Script

```bash
#!/bin/bash
# Verify production configuration
set -euo pipefail

echo "═══ ExamForge AI — Configuration Verification ═══"
echo ""

# Check environment variables are set
for var in SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_KEY \
           FLUTTERWAVE_PUBLIC_KEY FLUTTERWAVE_SECRET_KEY \
           ENVIRONMENT; do
  if [ -z "${!var:-}" ]; then
    echo "❌ MISSING: $var"
  else
    echo "✅ SET: $var (length: ${#!var})"
  fi
done

echo ""

# Check database connectivity
if psql "${DATABASE_URL:-}" -c "SELECT 1;" &>/dev/null; then
  echo "✅ Database: reachable"
else
  echo "❌ Database: unreachable"
fi

# Check health endpoint
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_CHECK_URL:-http://localhost:3000/health}" 2>/dev/null || echo "000")
if [ "${HTTP_CODE}" = "200" ]; then
  echo "✅ Health check: 200 OK"
elif [ "${HTTP_CODE}" = "503" ]; then
  echo "⚠️  Health check: 503 Service Unavailable"
else
  echo "❌ Health check: HTTP ${HTTP_CODE}"
fi

# Check for secrets in source code
if command -v gitleaks &>/dev/null; then
  if gitleaks detect --source . --no-banner 2>/dev/null; then
    echo "✅ No secrets in source code"
  else
    echo "❌ Secrets detected in source code!"
  fi
else
  echo "⚠️  gitleaks not installed — skipping secret scan"
fi

echo ""
echo "═══ Verification Complete ═══"
```

### 5.3 Configuration Drift Detection

Run quarterly (aligned with access reviews) to detect configuration drift:

```sql
-- Check if RLS is disabled on any table (should be 0 rows)
SELECT tablename FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;

-- Check if any feature flags have been changed from expected values
SELECT name, is_enabled, rollout_percentage
FROM feature_flags
WHERE (name = 'ai_exam_hints' AND is_enabled = true)
   OR (name = 'offline_mode' AND is_enabled = true)
   OR (name = 'biometric_login' AND is_enabled = true)
   OR (name = 'multi_school' AND is_enabled = true)
   OR (name = 'advanced_analytics' AND is_enabled = true);
-- All should return 0 rows in production

-- Check for unauthorized database roles
SELECT rolname FROM pg_roles
WHERE rolname NOT IN (
  'postgres', 'authenticated', 'anon', 'service_role',
  'webhook_processor', 'refund_processor', 'monitoring_agent',
  'backup_reader', 'analytics_reader',
  'supabase_admin', 'supabase_auth_admin', 'supabase_storage_admin',
  'pgbouncer', 'pg_read_all_data', 'pg_write_all_data',
  -- Add other expected roles
  'supabase_functions_admin', 'supabase_replication_admin'
)
AND rolcanlogin = false AND rolinherit = true;
-- Any unexpected roles should be investigated
```

### 5.4 Environment-Specific Validation

| Check | Development | Staging | Production |
|-------|------------|---------|------------|
| `ENVIRONMENT` variable | `development` | `staging` | `production` |
| Flutterwave mode | Test | Test | **Live** |
| Database has test data | Yes | Yes | **No test data** |
| RLS enabled on all tables | Recommended | **Required** | **Required** |
| Backups configured | No | Yes | **Yes + DR** |
| Monitoring active | No | Yes | **Yes** |
| Alerting active | No | Yes | **Yes** |
| GPG encryption on backups | No | Yes | **Yes** |
| CORS restricted to known domains | No | Yes | **Yes** |
| Security headers enforced | No | Yes | **Yes** |

---

## Appendix A: Complete `.env.example`

```bash
# ──────────────────────────────────────────────────────────────
# ExamForge AI — Environment Configuration Template
# ──────────────────────────────────────────────────────────────
# Copy this file to .env and fill in the values.
#   cp .env.example .env
#
# NEVER commit the .env file to version control.
# ──────────────────────────────────────────────────────────────

# Supabase — Project URL and API keys from your Supabase dashboard
# Dashboard → Settings → API
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_KEY=<your-service-key>

# Firebase Cloud Messaging — Server key for push notifications
# Firebase Console → Project Settings → Cloud Messaging
FCM_SERVER_KEY=<your-fcm-server-key>

# Flutterwave — Payment gateway keys
# Flutterwave Dashboard → Settings → API Keys
FLUTTERWAVE_PUBLIC_KEY=<your-flutterwave-public-key>
FLUTTERWAVE_SECRET_KEY=<your-flutterwave-secret-key>
# Flutterwave Dashboard → Settings → Webhooks
FLUTTERWAVE_WEBHOOK_SECRET_HASH=<your-flutterwave-webhook-secret-hash>

# Application environment: development | staging | production
ENVIRONMENT=development
```

## Appendix B: Feature Flags Reference

| Flag | Description | Dev | Staging | Prod |
|------|-------------|-----|---------|------|
| `ai_question_generation` | AI-powered question generation | ✅ | ✅ | ✅ |
| `ai_exam_hints` | AI exam coaching and hints | ✅ | ✅ | ❌ |
| `offline_mode` | Offline exam mode with sync | ✅ | ✅ | ❌ |
| `dark_mode` | Dark theme support | ✅ | ✅ | ✅ |
| `push_notifications` | Push notification delivery | ✅ | ✅ | ✅ |
| `payment_gateway` | Flutterwave payment processing | ✅ | ✅ | ✅ |
| `biometric_login` | Fingerprint/face authentication | ✅ | ✅ | ❌ |
| `multi_school` | Multi-school management | ✅ | ✅ | ❌ |
| `advanced_analytics` | Advanced analytics dashboard | ✅ | ✅ | ❌ |
| `export_pdf` | PDF export functionality | ✅ | ✅ | ✅ |

## Appendix C: Database Connection Pool Configuration

| Environment | `DB_POOL_MIN` | `DB_POOL_MAX` | Rationale |
|------------|--------------|--------------|-----------|
| Development | 2 | 10 | Low traffic, single developer |
| Staging | 2 | 20 | Moderate traffic, testing |
| Production | 5 | 50 | High traffic, concurrent users during exam periods |

The `DatabasePoolManager` (`lib/core/database/database_pool_manager.dart`) manages connection pooling. During peak exam periods (e.g., WAEC/NECO/JAMB seasons), the production pool may need to be temporarily increased.
