# ExamForge AI — Deployment Guide

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **Review Cycle:** Quarterly

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Environment Setup](#2-environment-setup)
3. [Database Migration Procedures](#3-database-migration-procedures)
4. [Blue-Green Deployment Steps](#4-blue-green-deployment-steps)
5. [Rollback Procedures](#5-rollback-procedures)
6. [Health Check Verification](#6-health-check-verification)
7. [Post-Deployment Validation](#7-post-deployment-validation)
8. [Emergency Deployment Procedures](#8-emergency-deployment-procedures)

---

## 1. Prerequisites

### 1.1 Required Tools

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| Flutter SDK | 3.22+ | Build the web, Android, and iOS clients |
| Dart | 3.4+ | Language runtime for Flutter |
| PostgreSQL client (`psql`) | 15+ | Database migration execution |
| `pg_dump` / `pg_restore` | 15+ | Backup and restore operations |
| SSH client | — | Remote deployment access |
| `rsync` | 3.2+ | File synchronization to remote servers |
| `curl` | 7.68+ | Health check verification |
| Terraform | 1.6+ | Infrastructure provisioning |
| AWS CLI | 2.x | S3 backup uploads |
| GPG | 2.3+ | Backup encryption |
| `supabase` CLI | 1.150+ | Edge Function deployment, storage management |
| `openssl` | 3.0+ | Deploy ID generation and cryptographic operations |

### 1.2 Required Access

| Access Level | Resource | How to Obtain |
|-------------|----------|---------------|
| SSH access | `deploy@prod-db.examforge.ai` | Request from CTO, add public key to `authorized_keys` |
| SSH access | `deploy@staging-db.examforge.ai` | Request from team lead |
| Supabase Dashboard | Production project (`examforge-production`) | Supabase team invite |
| Supabase Dashboard | Staging project (`examforge-staging`) | Supabase team invite |
| GitHub Actions | `examforge-ai` repository | GitHub org membership |
| Flutterwave Dashboard | Production account | Finance team provision |
| AWS Console | `examforge-backups-prod`, `examforge-backups-dr` | IAM role assignment |
| Terraform state | `examforge-terraform-state` bucket | CTO provision |

### 1.3 Required Secrets

All secrets are stored in **GitHub Secrets** (for CI/CD) and **Supabase Vault** (for Edge Functions). Never store secrets in `.env` files in production.

| Secret | Rotation Period | Storage Location |
|--------|----------------|-----------------|
| `SUPABASE_SERVICE_KEY` | 90 days | GitHub Secrets + Supabase Vault |
| `FLUTTERWAVE_SECRET_KEY` | 90 days | GitHub Secrets + Supabase Vault |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | 90 days | Supabase Vault |
| `FCM_SERVER_KEY` | 180 days | GitHub Secrets |
| `PRODUCTION_DATABASE_URL` | 90 days | GitHub Secrets |
| `STAGING_DATABASE_URL` | 90 days | GitHub Secrets |
| `AWS_ACCESS_KEY_ID` | 90 days | GitHub Secrets |
| `AWS_SECRET_ACCESS_KEY` | 90 days | GitHub Secrets |

---

## 2. Environment Setup

### 2.1 Development Environment

```bash
# Clone and setup
git clone https://github.com/examforge-ai/examforge-ai.git
cd examforge-ai

# Copy environment template
cp .env.example .env

# Edit with development values (placeholders are acceptable)
# SUPABASE_URL=https://<project-ref>.supabase.co
# ENVIRONMENT=development

# Start local Supabase (if using local development)
supabase init
supabase start

# Run Flutter web in development mode
flutter run -d chrome --dart-define=ENVIRONMENT=dev
```

**Development defaults:**
- App URL: `http://localhost:3000`
- API URL: `http://localhost:3001`
- Supabase URL: `http://localhost:54321`
- Database: `postgresql://localhost:5432/examforge_dev`
- Backups: disabled
- Verbose logging: enabled

### 2.2 Staging Environment

```bash
# Deploy to staging using the deploy script
./scripts/deploy.sh staging --blue-green

# Staging is configured to:
#   APP_URL=https://staging.examforge.ai
#   API_URL=https://staging-api.examforge.ai
#   DB_HOST=staging-db.examforge.ai
#   BACKUP_ENABLED=true
#   SLOW_QUERY_THRESHOLD_MS=500
```

**Staging defaults:**
- Feature flags: all experimental features enabled
- Timeouts: 20s connect, 20s receive, 20s send
- Encryption and verification: mandatory on backups
- Database pool: max 20 connections

### 2.3 Production Environment

```bash
# Deploy to production using the deploy script
./scripts/deploy.sh production --blue-green

# Production is configured to:
#   APP_URL=https://examforge.ai
#   API_URL=https://api.examforge.ai
#   DB_HOST=prod-db.examforge.ai
#   BACKUP_ENABLED=true
#   SLOW_QUERY_THRESHOLD_MS=300
#   DB_POOL_MAX=50
```

**Production defaults:**
- Feature flags: only production-ready features enabled
- Timeouts: 15s connect, 15s receive, 15s send
- Encryption and verification: mandatory on backups
- Database pool: max 50 connections
- All RLS policies enforced

### 2.4 Environment Configuration Validation

Before any deployment, validate the environment configuration:

```bash
# Check all required environment variables are set
./scripts/deploy.sh production --health-check

# Verify database connectivity
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT 1;"

# Verify Supabase Edge Functions are accessible
curl -s https://examforge.ai/health | jq .
```

---

## 3. Database Migration Procedures

### 3.1 Migration File Naming Convention

Migration files are located in `supabase/migrations/` and follow the naming pattern:

```
<descriptive_name>.sql
```

Current migrations include:
- `schema.sql` — Core schema (schools, users, classes, subjects, notifications)
- `cbt_engine_schema.sql` — CBT exam engine tables
- `question_bank_schema.sql` — Question bank and media
- `ai_generator_schema.sql` — AI question generation
- `billing_schema.sql` — Subscriptions and billing
- `marketplace_schema.sql` — Educational resource marketplace
- `marketplace_security.sql` — Marketplace RLS and security
- `school_management_schema.sql` — School management module
- `teacher_workspace_schema.sql` — Teacher workspace
- `teacher_workspace_expansion_schema.sql` — Expanded workspace features
- `parent_portal_schema.sql` — Parent portal
- `student_portal_schema.sql` — Student portal
- `results_analytics_schema.sql` — Results and analytics
- `communication_schema.sql` — Messaging system
- `super_admin_schema.sql` — Super admin dashboard
- `ccms_enterprise_schema.sql` — Content Collection Management System
- `mobile_offline_schema.sql` — Offline support and sync
- `infrastructure_monitoring.sql` — Health checks, metrics, rate limits, feature flags
- `monitoring_observability.sql` — Extended observability tables
- `alerting_configuration.sql` — Alert rules and escalation
- `operational_security.sql` — Least-privilege roles and permissions
- `database_optimization.sql` — Indexes, partitions, query optimization
- `payment_security_hardening.sql` — Payment security controls
- `refund_security.sql` — Refund audit and security
- `rls_role_fix.sql` — RLS policy corrections
- `final_production_schema.sql` — Nigerian exam ecosystem, admission hub, AI coach

### 3.2 Running Migrations

#### Automatic (via deploy script)

```bash
# Run migrations as part of a full deployment
./scripts/deploy.sh production --blue-green

# Run migrations only (no application deployment)
./scripts/deploy.sh production --migrate-only
```

The deploy script:
1. Creates the `_deploy_migrations` tracking table if it doesn't exist
2. Iterates through all `.sql` files in `supabase/migrations/`
3. Checks if each migration has already been applied (via tracking table)
4. Applies pending migrations sequentially
5. Records each successful migration with the deploy ID
6. Sets `ROLLBACK_NEEDED=true` if any migration fails

#### Manual Migration Execution

```bash
# Connect to the database
psql "${PRODUCTION_DATABASE_URL}"

# Check applied migrations
SELECT * FROM _deploy_migrations ORDER BY applied_at DESC;

# Apply a specific migration manually
psql "${PRODUCTION_DATABASE_URL}" -f supabase/migrations/new_migration.sql

# Record the manual migration
INSERT INTO _deploy_migrations (deploy_id, migration_name)
VALUES ('manual-$(date +%Y%m%d%H%M%S)', 'new_migration.sql');
```

### 3.3 Migration Best Practices

1. **Always test migrations on staging first** — Run the full migration pipeline on staging before production.
2. **Use `IF NOT EXISTS`** — All `CREATE TABLE` and `CREATE INDEX` statements should use `IF NOT EXISTS` to be idempotent.
3. **Wrap in transactions** — Use `BEGIN;` / `COMMIT;` blocks so failed migrations roll back automatically.
4. **No destructive changes without approval** — `DROP TABLE`, `DROP COLUMN`, or `ALTER COLUMN` changes require dual approval via the `operation_approval` table.
5. **Test rollback** — For every migration, prepare a corresponding rollback script.
6. **Large table migrations** — For tables with >100,000 rows, use batched updates to avoid locking.

### 3.4 Migration Rollback

```bash
# Roll back the last migration
psql "${PRODUCTION_DATABASE_URL}" -c "
  UPDATE _deploy_migrations
  SET rolled_back_at = NOW()
  WHERE id = (SELECT MAX(id) FROM _deploy_migrations WHERE rolled_back_at IS NULL);
"

# Apply the inverse SQL manually
# (You must prepare rollback SQL for each migration)
```

---

## 4. Blue-Green Deployment Steps

### 4.1 Overview

ExamForge AI uses a blue-green deployment strategy for staging and production environments. Two identical environments ("blue" and "green") exist simultaneously. At any time, one is live (serving traffic) and the other is idle (available for the next deployment).

### 4.2 Deployment Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Pre-deploy  │────▶│  Deploy to   │────▶│  Health Check │
│    Checks    │     │ Target Slot  │     │  Target Slot  │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                           ┌──────────────────────┤
                           │                      │
                     PASS ▼                FAIL ▼
                  ┌──────────────┐     ┌──────────────┐
                  │ Switch Traffic│     │   Abort &    │
                  │ to Target Slot│     │   Rollback   │
                  └──────┬───────┘     └──────────────┘
                         │
                  ┌──────▼───────┐
                  │Post-deploy   │
                  │Validation    │
                  └──────────────┘
```

### 4.3 Step-by-Step Procedure

```bash
# Step 1: Generate a deploy ID and configure environment
./scripts/deploy.sh production --blue-green

# The script automatically:
# 1. Generates DEPLOY_ID (e.g., deploy-20250301120000-a1b2c3d4)
# 2. Configures environment variables for production
# 3. Runs pre-deployment checks
# 4. Takes a pre-deployment backup (BACKUP_ENABLED=true)

# Step 2: Run database migrations
# (Handled automatically by the deploy script)
# If migrations fail, ROLLBACK_NEEDED=true and deployment aborts

# Step 3: Determine current and target slots
# The script reads the current symlink:
#   If current -> blue, deploy to green
#   If current -> green, deploy to blue

# Step 4: Deploy to target slot
# Build artifacts are rsync'd to the target slot directory:
#   /var/www/examforge/blue/  or  /var/www/examforge/green/

# Step 5: Health check on target slot
# The script hits the target slot's health endpoint:
#   curl -s -o /dev/null -w "%{http_code}" <target_url>/health
# Up to 5 retries with 10-second intervals

# Step 6: Switch traffic
# If health check passes:
#   ln -sfn green current  (or ln -sfn blue current)
#   sudo systemctl reload nginx

# Step 7: Post-deployment tasks
# - Clear application caches
# - Warm up caches by hitting the app URL
# - Clean up old releases (keep last 5)
```

### 4.4 Manual Blue-Green Deployment

If the automated script is unavailable:

```bash
# 1. Build the Flutter web app
flutter build web --release \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key> \
  --dart-define=ENVIRONMENT=production

# 2. Determine current slot
ssh deploy@prod-db.examforge.ai "readlink /var/www/examforge/current | xargs basename"
# Output: "blue" or "green"

# 3. Deploy to target slot
TARGET_SLOT="green"  # opposite of current
ssh deploy@prod-db.examforge.ai "mkdir -p /var/www/examforge/${TARGET_SLOT}"
rsync -avz --delete build/web/ deploy@prod-db.examforge.ai:/var/www/examforge/${TARGET_SLOT}/

# 4. Health check on target
curl -s https://api-green-.examforge.ai/health | jq .

# 5. Switch traffic
ssh deploy@prod-db.examforge.ai "cd /var/www/examforge && ln -sfn ${TARGET_SLOT} current"
ssh deploy@prod-db.examforge.ai "sudo systemctl reload nginx"

# 6. Verify
curl -s https://examforge.ai/health | jq .
```

---

## 5. Rollback Procedures

### 5.1 Automated Rollback

The deploy script automatically triggers a rollback if:
- Database migration fails
- Application deployment fails (rsync error)
- Post-deployment health check fails

```bash
# Rollback is triggered automatically, or manually:
./scripts/deploy.sh production --rollback
```

### 5.2 Manual Rollback Steps

1. **Identify the previous version:**
   ```bash
   cat deploy/production-version.txt
   # e.g., deploy-20250228150000-e5f6g7h8
   ```

2. **Restore the previous symlink:**
   ```bash
   ssh deploy@prod-db.examforge.ai \
     "cd /var/www/examforge && ln -sfn releases/<previous-version> current"
   ```

3. **Reload the server:**
   ```bash
   ssh deploy@prod-db.examforge.ai "sudo systemctl reload nginx"
   ```

4. **Verify the rollback:**
   ```bash
   sleep 5
   curl -s https://examforge.ai/health | jq .
   ```

### 5.3 Database Rollback

If a migration was applied that needs to be reverted:

```bash
# 1. Mark the migration as rolled back
psql "${PRODUCTION_DATABASE_URL}" -c "
  UPDATE _deploy_migrations
  SET rolled_back_at = NOW()
  WHERE migration_name = 'problematic_migration.sql'
    AND rolled_back_at IS NULL;
"

# 2. Apply the inverse SQL (you must prepare this)
psql "${PRODUCTION_DATABASE_URL}" -f supabase/migrations/rollback/problematic_migration_rollback.sql

# 3. Restore from pre-deployment backup if data was lost
./scripts/backup_dr.sh restore production backups/production/db_production_pre_restore_<timestamp>.dump
```

### 5.4 Full Disaster Recovery

If the entire deployment is beyond rollback:

```bash
# 1. Restore the database from the most recent backup
./scripts/backup_dr.sh restore production <backup-file>

# 2. Redeploy the previous application version
./scripts/deploy.sh production --rollback

# 3. Verify all services
curl -s https://examforge.ai/health | jq .
```

---

## 6. Health Check Verification

### 6.1 Health Check Endpoint

The health check is served by the `health-check` Edge Function at:

| Environment | URL |
|------------|-----|
| Development | `http://localhost:54321/functions/v1/health-check` |
| Staging | `https://staging.examforge.ai/functions/v1/health-check` |
| Production | `https://examforge.ai/functions/v1/health-check` |

### 6.2 Response Format

```json
{
  "status": "healthy",
  "timestamp": "2025-03-01T12:00:00.000Z",
  "version": "deploy-20250301120000-a1b2c3d4",
  "environment": "production",
  "services": {
    "database": {
      "status": "healthy",
      "responseTimeMs": 45
    },
    "storage": {
      "status": "healthy",
      "responseTimeMs": 120,
      "buckets": 4
    },
    "auth": {
      "status": "healthy",
      "responseTimeMs": 30
    },
    "payment": {
      "status": "healthy",
      "responseTimeMs": 350
    }
  }
}
```

### 6.3 Status Interpretation

| Status | HTTP Code | Meaning | Action |
|--------|-----------|---------|--------|
| `healthy` | 200 | All services operational | No action needed |
| `degraded` | 200 | One or more services slow (>1000ms) | Investigate, monitor |
| `down` | 503 | One or more services unavailable | Immediate response required |

### 6.4 Individual Service Checks

- **Database:** `SELECT` query on `app_health_checks` table, timeout >1000ms = degraded
- **Storage:** `listBuckets()` API call, failure = down
- **Auth:** `getSession()` call, failure (except "Auth session missing") = down
- **Payment:** `GET /v3/transactions` on Flutterwave API, non-2xx = degraded, unreachable = down

### 6.5 Automated Health Check

The deploy script runs health checks automatically:

```bash
# Check health with 5 retries, 10-second intervals
./scripts/deploy.sh production --health-check
```

---

## 7. Post-Deployment Validation

### 7.1 Critical Validation Checklist

After every production deployment, verify the following:

| # | Check | Command | Expected Result |
|---|-------|---------|-----------------|
| 1 | Health endpoint returns 200 | `curl -s https://examforge.ai/health \| jq .status` | `"healthy"` |
| 2 | Database connectivity works | `psql "${PRODUCTION_DATABASE_URL}" -c "SELECT 1;"` | `1 row` |
| 3 | Authentication works | Sign in via test account | Successful login |
| 4 | Payment webhook is reachable | Check Flutterwave dashboard webhook status | "Active" |
| 5 | AI question generation works | Generate a test question via teacher workspace | Question returned |
| 6 | File upload works | Upload a test file to `exam-files` bucket | Upload succeeds |
| 7 | CBT exam can be started | Create and start a test exam | Exam session active |
| 8 | Marketplace browse works | Visit marketplace home page | Products displayed |
| 9 | Parent portal accessible | Log in as parent test account | Dashboard loads |
| 10 | Real-time subscriptions work | Open two sessions, verify realtime updates | Updates propagate |

### 7.2 Performance Validation

| Metric | Threshold | Measurement Method |
|--------|-----------|-------------------|
| Dashboard load time | < 3 seconds | Chrome DevTools Lighthouse |
| CBT exam page load | < 2 seconds | Chrome DevTools on 3G |
| API P95 latency | < 2000ms | `api_latency_summary_24h` view |
| Database query time | < 500ms average | `performance_metrics` table |
| AI generation latency | < 10 seconds average | `ai_service_summary_24h` view |

### 7.3 Security Validation

| Check | Method |
|-------|--------|
| RLS is enabled on all tables | `SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false` returns empty |
| No secrets in source code | `gitleaks detect --source .` returns no findings |
| Flutterwave webhook signature validation | Send a test webhook with an invalid signature; verify 401 response |
| AI prompt injection detection | Send a test prompt injection; verify it's blocked |
| Exam answer encryption at rest | Verify `SessionRecoveryService` uses `LocalEncryptionService` |

### 7.4 Deployment Recording

Record every deployment:

```sql
-- The deploy script automatically writes the version file
-- Additionally, log in the database:
INSERT INTO app_health_checks (service_name, status, details)
VALUES ('deployment', 'healthy', '{"deploy_id": "deploy-...", "version": "1.0.0", "deployer": "engineer@examforge.ai"}');
```

---

## 8. Emergency Deployment Procedures

### 8.1 Emergency Deployment Criteria

An emergency deployment is warranted when:
- A critical security vulnerability is discovered (e.g., payment bypass, data leak)
- A P1 incident is caused by a code defect that requires a fix
- A compliance mandate requires immediate changes
- A payment processing failure affects live transactions

### 8.2 Emergency Deployment Process

```
┌────────────────────────┐
│ 1. Declare Emergency   │  CTO or Team Lead authorizes
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 2. Create Hotfix Branch│  Branch from production tag
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 3. Develop & Test Fix  │  Fastest safe path; minimum viable fix
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 4. Expedited Review    │  One reviewer sufficient (normally two)
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 5. Deploy to Staging   │  Quick smoke test on staging
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 6. Deploy to Production│  Skip blue-green if time-critical
└───────────┬────────────┘
            │
┌───────────▼────────────┐
│ 7. Verify & Communicate│  Health check + incident channel update
└────────────────────────┘
```

### 8.3 Skip Blue-Green for Critical Fixes

In extreme emergencies where the 5-10 minute blue-green delay is unacceptable:

```bash
# Emergency: direct standard deployment
./scripts/deploy.sh production  # No --blue-green flag = standard deployment

# This performs:
# 1. Pre-deploy backup
# 2. Database migrations
# 3. Direct rsync to /var/www/examforge/releases/<deploy-id>/
# 4. Symlink update
# 5. Server reload
# 6. Health check
```

### 8.4 Emergency Rollback

```bash
# Immediate rollback to previous version (no confirmation prompt)
ssh deploy@prod-db.examforge.ai \
  "cd /var/www/examforge && ln -sfn releases/$(cat deploy/production-version.txt) current && sudo systemctl reload nginx"
```

### 8.5 Communication During Emergency Deployment

1. **Before:** Post in `#incident-response` Slack channel: "Emergency deployment starting for [reason]. ETA: [time]."
2. **During:** Provide updates every 15 minutes.
3. **After:** Post completion notice with results: "Emergency deployment complete. Version: [deploy-id]. Health: [status]."

### 8.6 Post-Emergency Actions

- [ ] Schedule a post-incident review within 48 hours
- [ ] Create a follow-up task to apply proper blue-green deployment for the fix
- [ ] Update the deployment guide if the emergency revealed a process gap
- [ ] Review whether the emergency could have been prevented by better testing
- [ ] Update monitoring/alerting if the issue was not caught by existing alerts

---

## Appendix A: Deploy Script Reference

```bash
# Full deployment pipeline
./scripts/deploy.sh production --blue-green

# Migrations only
./scripts/deploy.sh production --migrate-only

# Health check only
./scripts/deploy.sh production --health-check

# Rollback to previous version
./scripts/deploy.sh production --rollback

# Standard (non-blue-green) deployment
./scripts/deploy.sh production
```

## Appendix B: Key File Locations

| Item | Path |
|------|------|
| Deploy script | `scripts/deploy.sh` |
| Backup script | `scripts/backup.sh` |
| DR script | `scripts/backup_dr.sh` |
| Migrations | `supabase/migrations/*.sql` |
| Core schema | `supabase/schema.sql` |
| Edge Functions | `supabase/functions/*/index.ts` |
| Environment config | `lib/config/env_config.dart` |
| App config | `lib/config/app_config.dart` |
| Supabase config | `lib/config/supabase_config.dart` |
| Deployment checklist | `lib/config/deployment_checklist.dart` |
| API constants | `lib/core/constants/api_constants.dart` |
| Terraform | `infra/terraform/main.tf` |
| Environment reference | `infra/ENVIRONMENT_REFERENCE.md` |

## Appendix C: Database Tables Quick Reference

| Table | Schema | Purpose |
|-------|--------|---------|
| `schools` | core | Registered schools/institutions |
| `users` | core | User profiles (extends auth.users) |
| `classes` | core | Class/arm within a school |
| `subjects` | core | Subjects available for exams |
| `notifications` | core | User notifications |
| `audit_log` | core | Audit trail for all operations |
| `examination_bodies` | exam | Nigerian exam bodies (WAEC, NECO, JAMB) |
| `examination_products` | exam | Exam products by body |
| `exam_sessions` | cbt | CBT exam sessions |
| `exam_responses` | cbt | Student exam responses |
| `transactions` | billing | Payment transactions |
| `webhook_events` | billing | Flutterwave webhook events |
| `products` | marketplace | Educational resources |
| `orders` | marketplace | Purchase orders |
| `app_health_checks` | monitoring | Service health check results |
| `performance_metrics` | monitoring | Application performance metrics |
| `api_latency_metrics` | monitoring | API latency tracking |
| `ai_service_metrics` | monitoring | AI provider metrics |
| `alert_state` | monitoring | Active alerts |
| `alert_rules` | monitoring | Alert rule definitions |
| `feature_flags` | monitoring | Feature flag management |
| `rate_limits` | monitoring | API rate limiting |
| `admin_access_log` | security | Admin action audit trail |
| `operation_approval` | security | Dual-approval operations |
