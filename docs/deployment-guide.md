# ExamForge AI — Deployment Guide

> **Step-by-step instructions for deploying the CCMS & Nigerian Curriculum Module**
> Covers development, staging, and production environments.

---

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Supabase Configuration](#supabase-configuration)
3. [Database Migration Execution](#database-migration-execution)
4. [Environment Variables](#environment-variables)
5. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
6. [Blue-Green Deployment](#blue-green-deployment)
7. [Health Checks](#health-checks)
8. [Monitoring Setup](#monitoring-setup)
9. [Backup and Restore Procedures](#backup-and-restore-procedures)
10. [Disaster Recovery](#disaster-recovery)
11. [Scaling Strategies](#scaling-strategies)
12. [Performance Optimization](#performance-optimization)
13. [Rollback Procedures](#rollback-procedures)

---

## Environment Setup

### Development Environment

#### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.22+ | Frontend development |
| Dart SDK | 3.4+ | Language runtime |
| Supabase CLI | 1.150+ | Local Supabase instance |
| Node.js | 20 LTS | Edge functions |
| Git | 2.40+ | Version control |
| Docker | 24+ | Container runtime for local services |

#### Local Setup Steps

1. **Clone the repository:**

```bash
git clone https://github.com/examforge/examforge-ai.git
cd examforge-ai
```

2. **Install Flutter dependencies:**

```bash
flutter pub get
```

3. **Start local Supabase:**

```bash
supabase init
supabase start
```

This starts a local Supabase stack with PostgreSQL, GoTrue, Realtime, Storage, and PostgREST.

4. **Copy environment template:**

```bash
cp .env.example .env
```

5. **Configure local environment variables:**

```ini
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<from supabase start output>
SUPABASE_SERVICE_KEY=<from supabase start output>
ENVIRONMENT=development
```

6. **Run migrations:**

```bash
supabase db push
```

7. **Run the application:**

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=<key>
```

### Staging Environment

The staging environment mirrors production but uses a separate Supabase project:

1. Create a Supabase project named `examforge-staging`
2. Apply all migrations
3. Configure environment variables with staging keys
4. Deploy via CI/CD pipeline

### Production Environment

Production uses a dedicated Supabase project with enhanced security:

- Custom domain (`api.examforge.ai`)
- Point-in-time recovery enabled
- Read replicas for scaling
- Enhanced rate limiting
- Dedicated IP allowlist

---

## Supabase Configuration

### Project Settings

Navigate to **Supabase Dashboard → Settings** and configure:

#### General

| Setting | Value |
|---------|-------|
| Project Name | `examforge-prod` |
| Region | `af-south-1` (Cape Town — closest to Nigeria) |
| Database Size Limit | 8 GB (upgradable) |

#### Authentication

| Setting | Value |
|---------|-------|
| Email Auth | Enabled |
| Confirm Email | Required |
| Password Min Length | 8 |
| Password Requirements | Uppercase, lowercase, number, special |
| MFA | Enabled |
| Session Timeout | 24 hours |
| Refresh Token Rotation | Enabled |
| OTP Expiry | 300 seconds |

#### Auth Providers

| Provider | Configuration |
|----------|--------------|
| Email/Password | Enabled |
| Google | OAuth 2.0 with school domain restriction |
| Apple | Sign in with Apple |

#### Database

| Setting | Value |
|---------|-------|
| SSL | Required |
| Connection Pooling | Enabled (PgBouncer) |
| Max Connections | 60 (free) / 200 (pro) |
| Point-in-Time Recovery | Enabled (Pro plan) |
| Read Replicas | 1 (Pro plan) |

#### Storage

| Bucket | Public | Size Limit | Allowed Types |
|--------|--------|------------|---------------|
| `content-media` | No | 50 MB | images, pdf, audio, video |
| `imports` | No | 100 MB | csv, xlsx, json |
| `exports` | No | 200 MB | pdf, csv, xlsx |
| `avatars` | Yes | 2 MB | images |

### Custom Domain Setup

1. Add a CNAME record pointing your domain to the Supabase project:

```
api.examforge.ai → <project-ref>.supabase.co
```

2. Configure the custom domain in Supabase Dashboard → Settings → Custom Domains

3. Update your application's `SUPABASE_URL` to use the custom domain

---

## Database Migration Execution

### Migration Files

Migrations are stored in `supabase/migrations/` and must be applied in order:

| Order | File | Description |
|-------|------|-------------|
| 1 | `school_management_schema.sql` | Core school and user tables |
| 2 | `ccms_enterprise_schema.sql` | CCMS tables, indexes, RLS, functions |
| 3 | `cbt_engine_schema.sql` | CBT exam engine |
| 4 | `billing_schema.sql` | Billing and payments |
| 5 | `marketplace_schema.sql` | Marketplace |
| 6 | `communication_schema.sql` | Messaging |
| 7 | `student_portal_schema.sql` | Student features |
| 8 | `parent_portal_schema.sql` | Parent features |
| 9 | `ai_generator_schema.sql` | AI content generation |
| 10 | `question_bank_schema.sql` | Question bank |
| 11 | `mobile_offline_schema.sql` | Offline sync |

### Running Migrations

#### Local Development

```bash
# Apply all pending migrations
supabase db push

# Reset database and apply all migrations
supabase db reset
```

#### Staging/Production

```bash
# Apply migrations to remote project
supabase db push --linked

# Or use the migration script
./scripts/deploy.sh migrate staging
```

#### Manual Migration

For production, always test migrations on staging first:

```bash
# 1. Generate a migration diff
supabase db diff --schema public

# 2. Review the SQL carefully

# 3. Apply with dry-run
psql "$DATABASE_URL" < migration.sql --dry-run

# 4. Apply for real
psql "$DATABASE_URL" < migration.sql
```

### Migration Rollback

Each migration file in the `database_migrations` table stores a `rollback_sql` field:

```sql
-- Check current migration state
SELECT migration_name, version, applied_at, is_rolled_back
FROM public.database_migrations
ORDER BY applied_at DESC;

-- Rollback a specific migration (if rollback_sql is available)
-- This must be done manually with extreme caution
```

---

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://abc.supabase.co` |
| `SUPABASE_ANON_KEY` | Public anonymous key | `eyJ...` |
| `SUPABASE_SERVICE_KEY` | Service role key (server only) | `eyJ...` |
| `ENVIRONMENT` | Deployment environment | `development` / `staging` / `production` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FCM_SERVER_KEY` | Firebase Cloud Messaging key | — |
| `FLUTTERWAVE_PUBLIC_KEY` | Payment gateway public key | — |
| `FLUTTERWAVE_SECRET_KEY` | Payment gateway secret key | — |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | Webhook verification hash | — |
| `SENTRY_DSN` | Error tracking DSN | — |
| `ANALYTICS_ENABLED` | Enable analytics | `true` |
| `OFFLINE_SYNC_INTERVAL` | Sync interval in seconds | `300` |
| `CACHE_TTL_MINUTES` | Default cache TTL | `30` |
| `MAX_CONTENT_PAGE_SIZE` | Max items per page | `50` |

### Environment-Specific Configurations

#### Development

```ini
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ...local
SUPABASE_SERVICE_KEY=eyJ...local
ENVIRONMENT=development
ANALYTICS_ENABLED=false
OFFLINE_SYNC_INTERVAL=60
CACHE_TTL_MINUTES=5
```

#### Staging

```ini
SUPABASE_URL=https://examforge-staging.supabase.co
SUPABASE_ANON_KEY=eyJ...staging
SUPABASE_SERVICE_KEY=eyJ...staging
ENVIRONMENT=staging
FLUTTERWAVE_PUBLIC_KEY=pk_test_...
FLUTTERWAVE_SECRET_KEY=sk_test_...
SENTRY_DSN=https://sentry.io/staging
ANALYTICS_ENABLED=true
OFFLINE_SYNC_INTERVAL=180
```

#### Production

```ini
SUPABASE_URL=https://api.examforge.ai
SUPABASE_ANON_KEY=eyJ...prod
SUPABASE_SERVICE_KEY=<stored in vault>
ENVIRONMENT=production
FLUTTERWAVE_PUBLIC_KEY=pk_live_...
FLUTTERWAVE_SECRET_KEY=<stored in vault>
FLUTTERWAVE_WEBHOOK_SECRET_HASH=<stored in vault>
FCM_SERVER_KEY=<stored in vault>
SENTRY_DSN=https://sentry.io/prod
ANALYTICS_ENABLED=true
OFFLINE_SYNC_INTERVAL=300
CACHE_TTL_MINUTES=30
MAX_CONTENT_PAGE_SIZE=50
```

**Important:** Production secrets must never be stored in code or `.env` files. Use a secrets manager (e.g., Supabase Vault, AWS Secrets Manager, HashiCorp Vault).

---

## CI/CD Pipeline Configuration

### GitHub Actions Workflow

The CI/CD pipeline is defined in `.github/workflows/`:

```yaml
name: ExamForge AI CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  deploy-staging:
    needs: test
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Staging
        run: ./scripts/deploy.sh staging

  deploy-production:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Production
        run: ./scripts/deploy.sh production
```

### Deployment Script

The `scripts/deploy.sh` script handles:

1. Pre-deployment health check
2. Database migration execution
3. Application build and deployment
4. Post-deployment smoke tests
5. Deployment record creation

```bash
#!/bin/bash
ENVIRONMENT=$1

echo "Deploying to $ENVIRONMENT..."

# 1. Run migrations
echo "Running database migrations..."
supabase db push --linked

# 2. Build application
echo "Building application..."
flutter build web --dart-define=ENVIRONMENT=$ENVIRONMENT

# 3. Deploy to hosting
echo "Deploying to hosting..."
# ... platform-specific deployment

# 4. Create deployment record
echo "Recording deployment..."
# ... API call to create deployment record

# 5. Smoke tests
echo "Running smoke tests..."
curl -f https://api.examforge.ai/health || exit 1

echo "Deployment complete!"
```

---

## Blue-Green Deployment

### Overview

ExamForge AI uses a blue-green deployment strategy to achieve zero-downtime deployments.

### Architecture

```
                    ┌─────────────────┐
                    │   Load Balancer  │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
             ┌──────┴──────┐  ┌──────┴──────┐
             │   BLUE      │  │   GREEN     │
             │  (current)  │  │  (new)      │
             │  v2.3.1     │  │  v2.4.0     │
             └─────────────┘  └─────────────┘
```

### Deployment Steps

1. **Build the green environment** with the new version
2. **Run database migrations** (backward-compatible only)
3. **Warm up the green environment** with health checks
4. **Switch traffic** from blue to green at the load balancer
5. **Monitor** for errors and performance issues
6. **Rollback** if issues are detected (switch back to blue)
7. **Decommission** the blue environment after 24 hours

### Migration Rules for Zero-Downtime

During blue-green deployment, migrations must be **backward-compatible**:

- **Adding columns**: Always nullable or with default values
- **Adding tables**: Always safe
- **Renaming columns**: Use a two-phase approach (add new → migrate data → drop old)
- **Removing columns**: Phase 1: stop reading in code; Phase 2: drop in next deployment
- **Changing types**: Add new column, migrate data, update code, drop old column

---

## Health Checks

### Application Health Endpoint

```bash
curl https://api.examforge.ai/health
```

Response:

```json
{
  "status": "healthy",
  "version": "2.4.0",
  "uptime_seconds": 86400,
  "checks": {
    "database": "ok",
    "auth": "ok",
    "storage": "ok",
    "realtime": "ok"
  }
}
```

### Database Health

```sql
-- Check database connectivity
SELECT pg_is_in_recovery();

-- Check connection count
SELECT count(*) FROM pg_stat_activity;

-- Check for long-running queries
SELECT pid, query, state, duration
FROM pg_stat_activity
WHERE state = 'active' AND duration > interval '5 seconds';
```

### Automated Health Checks

Configure the monitoring system to check health every 30 seconds:

```sql
INSERT INTO public.alert_rules (
  name, description, metric_name, condition_operator,
  threshold_value, duration_seconds, severity, notification_channels, is_active
) VALUES (
  'Health Check Failure',
  'Application health endpoint returning non-200',
  'health_check_status',
  '!=',
  200,
  60,
  'critical',
  '{"email:ops@examforge.ai", "webhook:https://hooks.slack.com/..."}',
  true
);
```

---

## Monitoring Setup

### Metrics Collection

The `system_metrics` table collects platform metrics:

```sql
-- Record a custom metric
SELECT public.record_metric(
  'api_response_time_ms',
  'histogram',
  245.5,
  'milliseconds',
  '{"endpoint": "/rest/v1/content_items", "method": "GET"}'::jsonb
);
```

### Key Metrics to Monitor

| Metric | Type | Alert Threshold |
|--------|------|----------------|
| `api_response_time_ms` | Histogram | > 2000ms (warning), > 5000ms (critical) |
| `database_query_time_ms` | Histogram | > 1000ms (warning) |
| `auth_success_rate` | Gauge | < 95% (warning) |
| `content_creation_rate` | Counter | < 1/hour per school (info) |
| `active_users` | Gauge | Drop > 50% (warning) |
| `error_rate` | Counter | > 1% of requests (critical) |
| `storage_usage_bytes` | Gauge | > 80% capacity (warning) |
| `sync_conflict_rate` | Counter | > 10/hour (warning) |

### Alert Rule Configuration

```sql
-- Create alert for high API response times
INSERT INTO public.alert_rules (
  name, metric_name, condition_operator, threshold_value,
  duration_seconds, severity, notification_channels
) VALUES (
  'High API Response Time',
  'api_response_time_ms',
  '>',
  5000,
  300,  -- 5 minutes sustained
  'critical',
  '{"email:ops@examforge.ai", "sms:+2348012345678"}'
);
```

### Dashboard Setup

Use Supabase's built-in dashboard or connect to Grafana:

1. Install the Supabase Prometheus exporter
2. Configure Grafana data source
3. Import the ExamForge AI dashboard template
4. Set up alert channels (email, Slack, SMS)

---

## Backup and Restore Procedures

### Automated Backups

Backups are tracked in the `backup_records` table and handled by the `scripts/backup.sh` script:

```bash
#!/bin/bash
# scripts/backup.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="examforge_prod_${TIMESTAMP}.sql.gz"

# Create logical backup
pg_dump "$DATABASE_URL" | gzip > "/backups/$BACKUP_FILE"

# Upload to object storage
aws s3 cp "/backups/$BACKUP_FILE" "s3://examforge-backups/$BACKUP_FILE"

# Record backup in database
psql "$DATABASE_URL" -c "INSERT INTO public.backup_records (
  backup_type, storage_location, file_size_bytes, is_encrypted, status, retention_until
) VALUES (
  'full', 's3://examforge-backups/$BACKUP_FILE', $(stat -f%z "/backups/$BACKUP_FILE"),
  true, 'completed', now() + interval '90 days'
);"

# Clean local backup
rm "/backups/$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE"
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full | Daily at 02:00 UTC | 90 days |
| Incremental | Every 6 hours | 30 days |
| Pre-migration | Before each migration | 1 year |
| On-demand | Manual trigger | Configurable |

### Restore Procedure

#### Point-in-Time Recovery (Supabase Pro)

```bash
# Via Supabase Dashboard → Database → Backups
# Select the desired point in time and click "Restore"
```

#### Logical Backup Restore

```bash
# Download backup
aws s3 cp "s3://examforge-backups/examforge_prod_20240115_020000.sql.gz" .

# Restore to a new database (never restore directly to production)
gunzip examforge_prod_20240115_020000.sql.gz
psql "$STAGING_DATABASE_URL" < examforge_prod_20240115_020000.sql

# Verify data integrity
psql "$STAGING_DATABASE_URL" -c "SELECT count(*) FROM public.content_items;"
psql "$STAGING_DATABASE_URL" -c "SELECT count(*) FROM public.users;"
```

---

## Disaster Recovery

### Recovery Time Objectives

| Scenario | RTO | RPO |
|----------|-----|-----|
| Single server failure | 15 min | 0 (replication) |
| Availability zone failure | 30 min | < 5 min |
| Full region failure | 2 hours | < 15 min |
| Data corruption | 4 hours | < 1 hour (PITR) |

### Disaster Recovery Steps

1. **Assess the impact**: Determine scope (single school, region, or full platform)
2. **Activate the incident response team**: Notify via PagerDuty or equivalent
3. **Failover**: Switch to the read replica or standby region
4. **Restore data**: Apply PITR if data loss occurred
5. **Verify**: Run integrity checks on restored data
6. **Communicate**: Notify affected users via status page
7. **Post-mortem**: Document root cause and prevention measures

### High Availability Architecture

```
┌─────────────────────────────────────────────────────┐
│                    CDN / Edge                        │
│                (CloudFlare / AWS CF)                 │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│              Supabase Primary (Region A)              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │ PostgREST│ │  GoTrue  │ │ Realtime │ │Storage │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ │
│  ┌──────────┐                                       │
│  │ PostgreSQL│─── Streaming Replication ──────────── │
│  │ (Primary)│                                       │
│  └──────────┘                                       │
└─────────────────────────────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│              Supabase Replica (Region B)              │
│  ┌──────────┐                                       │
│  │ PostgreSQL│                                       │
│  │(Replica) │                                       │
│  └──────────┘                                       │
└─────────────────────────────────────────────────────┘
```

---

## Scaling Strategies

### Horizontal Scaling

| Component | Strategy |
|-----------|----------|
| Application servers | Add more instances behind load balancer |
| PostgreSQL | Read replicas for read-heavy workloads |
| Supabase services | Auto-scales on Pro plan |
| Storage | Unlimited on Supabase (pay per GB) |
| Edge functions | Auto-scales on demand |

### Vertical Scaling

| Component | Current | Scale-Up Path |
|-----------|---------|--------------|
| Database (Supabase Free) | 500 MB | Pro: 8 GB → Enterprise: unlimited |
| Compute (Supabase Free) | 1 vCPU | Pro: 2 vCPU → Enterprise: 4+ vCPU |
| Connections (Free) | 60 | Pro: 200 → Enterprise: 500+ |

### Database Optimization for Scale

```sql
-- Create audit partition for current month (automated)
SELECT public.create_audit_partition_if_not_exists(
  extract(year from now())::int,
  extract(month from now())::int
);

-- Run maintenance operations
SELECT public.clean_old_metrics(90);      -- Clean metrics older than 90 days
SELECT public.clean_old_audit_trail(365);  -- Clean audit trail older than 1 year
SELECT public.clean_old_performance_logs(30); -- Clean perf logs older than 30 days

-- Vacuum and analyze for query performance
VACUUM ANALYZE public.content_items;
VACUUM ANALYZE public.audit_trail;
```

---

## Performance Optimization

### Database Optimization

1. **Indexes**: All frequently queried columns have indexes (see schema). Add new indexes as query patterns evolve:

```sql
-- Example: Add composite index for common filter pattern
CREATE INDEX CONCURRENTLY idx_content_items_teacher_dashboard
ON public.content_items(created_by, status, created_at DESC)
WHERE status IN ('draft', 'review');
```

2. **Query optimization**: Use `EXPLAIN ANALYZE` for slow queries:

```sql
EXPLAIN ANALYZE
SELECT * FROM public.content_items
WHERE subject_id = 'uuid' AND educational_level_id = 'uuid' AND status = 'published'
ORDER BY created_at DESC LIMIT 20;
```

3. **Connection pooling**: Use PgBouncer (enabled by default in Supabase) to manage connections efficiently.

### Application-Level Optimization

1. **Pagination**: Always use limit/offset for large result sets (default: 20 items per page)
2. **Caching**: The `CacheManager` provides TTL-based caching for frequently accessed data
3. **Lazy loading**: Load content details on demand, not in list views
4. **Image optimization**: Use Supabase image transformations for media

### CDN Configuration

```
# Cache static assets for 1 year
/static/*  → Cache-Control: public, max-age=31536000, immutable

# Cache API responses for 5 minutes
/rest/v1/educational_levels  → Cache-Control: public, max-age=300, s-maxage=300
/rest/v1/subjects  → Cache-Control: public, max-age=300, s-maxage=300

# Never cache authenticated endpoints
/rest/v1/content_items  → Cache-Control: private, no-cache
```

---

## Rollback Procedures

### Application Rollback

1. **Identify the target version**: Check the `deployments` table for the last known good version

```sql
SELECT id, version, environment, status, started_at, completed_at
FROM public.deployments
WHERE environment = 'production' AND status = 'success'
ORDER BY started_at DESC LIMIT 5;
```

2. **Deploy the previous version**:

```bash
./scripts/deploy.sh production --version=<previous-version>
```

3. **Update deployment status**:

```sql
UPDATE public.deployments
SET status = 'rolled_back', notes = 'Rolled back due to critical bug'
WHERE id = '<failed-deployment-id>';
```

### Database Rollback

Database rollbacks are dangerous and should only be performed as a last resort:

1. **Stop the application** to prevent further writes
2. **Restore from backup** taken before the migration
3. **Verify data integrity** on a staging copy first
4. **Restart the application**

### Partial Rollback (Content-Level)

If only certain content changes need to be reverted:

```sql
-- Restore a content item to a previous version
UPDATE public.content_items ci
SET
  title = cv.title,
  body = cv.body,
  options = cv.options,
  correct_answer = cv.correct_answer,
  step_by_step_explanation = cv.step_by_step_explanation,
  marking_scheme = cv.marking_scheme,
  difficulty_level = cv.difficulty_level,
  bloom_level = cv.bloom_level,
  version = cv.version_number + 1
FROM public.content_versions cv
WHERE ci.id = cv.content_item_id
  AND ci.id = '<content-id>'
  AND cv.version_number = <target-version>;
```

### Emergency Contacts

| Role | Contact |
|------|---------|
| On-Call Engineer | +234-801-234-5678 |
| Platform Lead | platform@examforge.ai |
| Database Admin | dba@examforge.ai |
| Security Team | security@examforge.ai |
