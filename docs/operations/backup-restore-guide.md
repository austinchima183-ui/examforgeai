# ExamForge AI — Backup and Restore Guide

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **RPO Target:** 1 hour (maximum data loss)  
> **RTO Target:** 4 hours (maximum downtime)

---

## Table of Contents

1. [Backup Schedule](#1-backup-schedule)
2. [RPO and RTO Targets](#2-rpo-and-rto-targets)
3. [Backup Verification Procedures](#3-backup-verification-procedures)
4. [Restore Procedures](#4-restore-procedures)
5. [Recovery Testing Schedule](#5-recovery-testing-schedule)
6. [Cross-Region DR Procedures](#6-cross-region-dr-procedures)
7. [Backup Encryption and Security](#7-backup-encryption-and-security)
8. [Disaster Recovery Documentation](#8-disaster-recovery-documentation)

---

## 1. Backup Schedule

### 1.1 Overview

| Backup Type | Frequency | Retention | Storage Location | Encryption |
|------------|-----------|-----------|-----------------|------------|
| **Incremental** | Every hour | 24 hours | S3 (`af-south-1`) | GPG |
| **Full Daily** | Daily at 02:00 UTC | 30 days | S3 (`af-south-1`) + local | GPG |
| **Monthly Archival** | 1st of each month | 12 months | S3 (`af-south-1`) + DR (`eu-west-1`) | GPG |
| **Pre-deployment** | Before every deployment | 90 days | S3 + local | GPG |
| **Configuration** | Daily at 02:30 UTC | 30 days | S3 (`af-south-1`) | GPG |
| **Storage Objects** | Daily at 03:00 UTC | 14 days | S3 (`af-south-1`) | GPG |

### 1.2 Cron Configuration

```cron
# Hourly incremental backup (production)
0 * * * * /home/z/my-project/examforge_ai/scripts/backup_dr.sh backup production --incremental --encrypt --verify --upload >> /home/z/my-project/examforge_ai/logs/backup_cron.log 2>&1

# Daily full backup (production) — 02:00 UTC
0 2 * * * /home/z/my-project/examforge_ai/scripts/backup_dr.sh backup production --full --encrypt --verify --upload >> /home/z/my-project/examforge_ai/logs/backup_cron.log 2>&1

# Daily full backup (staging) — 03:00 UTC
0 3 * * * /home/z/my-project/examforge_ai/scripts/backup_dr.sh backup staging --full --encrypt --verify --upload >> /home/z/my-project/examforge_ai/logs/backup_cron.log 2>&1

# Configuration backup (production) — 02:30 UTC
30 2 * * * tar -czf /home/z/my-project/examforge_ai/backups/production/config_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz --exclude='*.env' --exclude='*.db' --exclude='build/' -C /home/z/my-project/examforge_ai supabase/ lib/config/ scripts/ .github/ infra/ >> /home/z/my-project/examforge_ai/logs/backup_cron.log 2>&1

# Storage backup (production) — 04:00 UTC
0 4 * * * /home/z/my-project/examforge_ai/scripts/backup_dr.sh backup production --full --encrypt --upload >> /home/z/my-project/examforge_ai/logs/backup_cron.log 2>&1
```

### 1.3 What Is Backed Up

| Component | Method | Tables/Buckets |
|-----------|--------|---------------|
| **Database** | `pg_dump` (custom format, compress=9) | All tables in `public` schema |
| **Configuration** | `tar` archive | `supabase/`, `lib/config/`, `lib/core/security/`, `scripts/`, `.github/`, `infra/` |
| **Storage Objects** | Supabase CLI / API | `exam-files`, `profile-images`, `marketplace-files`, `question-media` |
| **Edge Functions** | Git repository (version controlled) | `supabase/functions/` |

### 1.4 Key Database Tables in Backups

The backup includes all tables across these modules:

- **Core:** `schools`, `users`, `classes`, `subjects`, `class_subjects`, `class_students`, `notifications`, `audit_log`
- **Examination:** `examination_bodies`, `examination_products`, `educational_levels`
- **CBT Engine:** `exam_sessions`, `exam_responses`, `cbt_sessions`
- **Question Bank:** `content_items`, `topics`, `curricula`
- **Billing:** `transactions`, `webhook_events`, `subscriptions`, `refund_audit_log`
- **Marketplace:** `products`, `orders`, `seller_profiles`, `cart_items`, `product_reviews`
- **School Management:** `teachers`, `students`, `attendance`, `homework`, `timetables`
- **Parent Portal:** `parent_child_links`, `parent_messages`, `parent_insights`
- **Monitoring:** `app_health_checks`, `performance_metrics`, `api_latency_metrics`, `ai_service_metrics`, `auth_metrics`, `payment_metrics`, `server_resource_metrics`, `storage_metrics`, `alert_state`, `alert_history`, `alert_rules`
- **Security:** `admin_access_log`, `operation_approval`, `rate_limits`

---

## 2. RPO and RTO Targets

### 2.1 Definitions

| Metric | Target | Definition |
|--------|--------|------------|
| **RPO** (Recovery Point Objective) | **1 hour** | Maximum acceptable data loss measured in time. With hourly incremental backups, we can recover to within 1 hour of the failure. |
| **RTO** (Recovery Time Objective) | **4 hours** | Maximum acceptable downtime from incident to full service restoration. |

### 2.2 RPO Achievement

```
Time ──────────────────────────────────────────────▶

  T-1h        T-0 (failure)       T+restore
    │              │                   │
    ├── incremental ──┤               │
    │  backup at T-1h  │              │
    │                  │              │
    ├── DATA LOSS ◄───┤              │
    │   (max 1 hour)   │              │
    │                  ├── restore ───┤
    │                  │   process    │
    │                  │              │
    ▼                  ▼              ▼
  Backup taken    Incident       Service restored
```

- Hourly incremental backups ensure RPO ≤ 1 hour
- Full daily backups provide a reliable restore point if incrementals fail
- WAL archiving on production provides point-in-time recovery within the RPO window

### 2.3 RTO Achievement

The 4-hour RTO budget is allocated as follows:

| Phase | Duration | Activity |
|-------|----------|----------|
| Detection | 0-15 min | Alert fires, on-call acknowledges |
| Assessment | 15-30 min | Determine scope and restore strategy |
| Preparation | 30-45 min | Locate backup, verify integrity, prepare restore target |
| Database Restore | 45-120 min | `pg_restore` execution (depends on DB size) |
| Application Restore | 120-150 min | Deploy application, restore configuration |
| Verification | 150-180 min | Health checks, data integrity validation |
| Communication | 180-210 min | Stakeholder notification, DNS propagation |
| Buffer | 210-240 min | Unforeseen complications |

### 2.4 RPO/RTO Monitoring

The `backup_dr.sh` script tracks RPO/RTO compliance:

```bash
# Check backup status and RPO/RTO compliance
./scripts/backup_dr.sh status

# Output:
#   PRODUCTION:
#     Files:        45
#     Latest:       2025-03-01 02:00:00
#     Total size:   2.3G
#     RPO target:   3600s (1 hour)
#     RTO target:   14400s (4 hours)
```

---

## 3. Backup Verification Procedures

### 3.1 Automatic Verification

Every backup (staging/production) is automatically verified by the `backup_dr.sh` script:

1. **SHA-256 checksum generation** — Computed immediately after backup creation
2. **Checksum validation** — Verified against the generated checksum file
3. **pg_restore list test** — `pg_restore --list` confirms the dump is restorable
4. **File size validation** — Ensures backup is non-empty and above minimum size threshold

### 3.2 Manual Verification

```bash
# Verify a specific backup file
./scripts/backup_dr.sh verify production /path/to/backup_file.dump

# Manual verification steps:
# 1. Check file exists and is non-empty
ls -la /path/to/backup_file.dump

# 2. Verify checksum
sha256sum -c /path/to/backup_file.dump.sha256

# 3. List backup contents (pg_dump custom format)
pg_restore --list /path/to/backup_file.dump

# 4. Test restore to a temporary database
createdb examforge_verify_test
pg_restore --dbname=examforge_verify_test --no-owner --no-privileges /path/to/backup_file.dump

# 5. Verify table count
psql examforge_verify_test -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

# 6. Verify key data
psql examforge_verify_test -c "SELECT COUNT(*) FROM schools;"
psql examforge_verify_test -c "SELECT COUNT(*) FROM users;"

# 7. Clean up
dropdb examforge_verify_test
```

### 3.3 Verification Failure Response

If verification fails:

1. **Do not delete the previous backup** — Keep it until a verified backup exists
2. **Alert immediately** — The `backup_failed` alert rule triggers automatically
3. **Investigate the failure** — Check disk space, database connectivity, GPG key status
4. **Re-run the backup** — `./scripts/backup_dr.sh backup production --full --encrypt --verify --upload`
5. **Escalate if persistent** — If 3 consecutive backups fail, escalate to P2 incident

### 3.4 S3 Upload Verification

```bash
# Verify backup exists in S3
aws s3 ls s3://examforge-backups-prod/production/2025/03/01/ --region af-south-1

# Download and verify
aws s3 cp s3://examforge-backups-prod/production/2025/03/01/db_production_full_20250301_020000.dump.gpg /tmp/verify.dump.gpg --region af-south-1
sha256sum -c /tmp/verify.dump.gpg.sha256
```

---

## 4. Restore Procedures

### 4.1 Full Database Restore

```bash
# Restore from a full backup
./scripts/backup_dr.sh restore production /path/to/db_production_full_20250301_020000.dump

# The script will:
# 1. Verify the backup checksum
# 2. Prompt for confirmation (type "RESTORE")
# 3. Take a pre-restore backup of the current database
# 4. Execute pg_restore with --clean --if-exists
# 5. Report recovery time
```

### 4.2 Point-in-Time Recovery

For situations where you need to restore to a specific point in time (e.g., just before a destructive migration):

```bash
# Step 1: Identify the target backup
# The most recent full backup before the target time
ls -la backups/production/db_production_full_*.dump

# Step 2: Restore the full backup to a temporary database
createdb examforge_pitr_temp
pg_restore --dbname=examforge_pitr_temp --no-owner --no-privileges \
  backups/production/db_production_full_20250228_020000.dump

# Step 3: Apply WAL segments for point-in-time recovery
# (Requires WAL archiving to be enabled on production)
# Set recovery target time in postgresql.conf:
#   restore_command = 'cp /path/to/wal_archive/%f %p'
#   recovery_target_time = '2025-03-01 11:30:00 UTC'

# Step 4: Verify the restored data at the target point in time
psql examforge_pitr_temp -c "SELECT now(), COUNT(*) FROM transactions WHERE created_at <= '2025-03-01 11:30:00 UTC';"

# Step 5: If verified, swap the production database
# (This requires a maintenance window)
psql "${PRODUCTION_DATABASE_URL}" -c "ALTER DATABASE examforge_production RENAME TO examforge_production_pre_swap;"
psql "${PRODUCTION_DATABASE_URL}" -c "ALTER DATABASE examforge_pitr_temp RENAME TO examforge_production;"
```

### 4.3 Selective Table Restore

If only specific tables need to be restored:

```bash
# Step 1: List tables in the backup
pg_restore --list /path/to/backup.dump | grep "TABLE DATA"

# Step 2: Restore specific tables
pg_restore --dbname="${PRODUCTION_DATABASE_URL}" \
  --no-owner --no-privileges \
  --data-only \
  --table=schools \
  --table=users \
  /path/to/backup.dump

# Step 3: Verify restored data
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT COUNT(*) FROM schools;"
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT COUNT(*) FROM users;"
```

### 4.4 Configuration Restore

```bash
# Restore configuration from backup
tar -xzf backups/production/config_production_20250301_023000.tar.gz -C /tmp/config_restore/

# Compare with current configuration
diff -r /tmp/config_restore/supabase/ supabase/
diff -r /tmp/config_restore/lib/config/ lib/config/

# Apply restored configuration
cp -r /tmp/config_restore/supabase/ supabase/
cp -r /tmp/config_restore/lib/config/ lib/config/
```

### 4.5 Storage Objects Restore

```bash
# Restore storage objects from backup
tar -xzf backups/production/storage_production_20250301_030000.tar.gz -C /tmp/storage_restore/

# Re-upload objects to Supabase storage
# This requires the Supabase CLI and appropriate permissions
for bucket in exam-files profile-images marketplace-files question-media; do
  if [ -d "/tmp/storage_restore/${bucket}" ]; then
    supabase storage upload --bucket="${bucket}" --dir="/tmp/storage_restore/${bucket}/" --project-id=examforge-production
  fi
done
```

### 4.6 Encrypted Backup Decryption

```bash
# Decrypt a GPG-encrypted backup
gpg --decrypt --output /tmp/decrypted_backup.dump \
  backups/production/db_production_full_20250301_020000.dump.gpg

# Verify the decrypted backup
pg_restore --list /tmp/decrypted_backup.dump

# Clean up the decrypted file after use
rm -f /tmp/decrypted_backup.dump
```

---

## 5. Recovery Testing Schedule

### 5.1 Testing Cadence

| Test Type | Frequency | Environment | Duration |
|-----------|-----------|-------------|----------|
| Full database restore | Monthly (1st Saturday) | Staging | ~2 hours |
| Point-in-time recovery | Quarterly | Staging | ~3 hours |
| Storage restore | Quarterly | Staging | ~1 hour |
| Full DR failover | Semi-annually | DR region | ~4 hours |
| Encrypted backup decryption | Monthly | Local | ~30 minutes |

### 5.2 Running Recovery Tests

```bash
# Automated recovery test (runs on staging)
./scripts/backup_dr.sh test-recovery staging

# The test:
# 1. Finds the latest full backup
# 2. Creates a temporary test database
# 3. Restores the backup into the test database
# 4. Measures recovery time
# 5. Verifies table count
# 6. Checks RTO compliance
# 7. Drops the test database
# 8. Reports results
```

### 5.3 Recovery Test Report Template

```markdown
# Recovery Test Report — [Date]

## Test Parameters
- **Environment:** Staging
- **Backup File:** [filename]
- **Backup Size:** [size]
- **Backup Date:** [date]

## Results
- **Recovery Time:** [X minutes Y seconds]
- **RTO Compliance:** PASS / FAIL (target: 4 hours)
- **Tables Restored:** [count]
- **Data Integrity:** PASS / FAIL

## Verification Checks
| Check | Result |
|-------|--------|
| Schools table count matches | ✅ / ❌ |
| Users table count matches | ✅ / ❌ |
| Transactions table count matches | ✅ / ❌ |
| RLS policies intact | ✅ / ❌ |
| Feature flags correct | ✅ / ❌ |
| Edge Functions accessible | ✅ / ❌ |

## Issues Found
[Description of any issues encountered]

## Recommendations
[Recommendations for improvement]
```

### 5.4 Test Failure Response

If a recovery test fails:

1. **Document the failure** — Record exactly what failed and when
2. **Do not dismiss** — Every test failure is a potential production incident
3. **Create a P2 task** — Fix the backup or restore process
4. **Re-test** — Run the recovery test again after the fix
5. **Report** — Include test failures in the monthly incident report

---

## 6. Cross-Region DR Procedures

### 6.1 DR Architecture

```
┌─────────────────────────────────────────────┐
│            PRIMARY REGION                    │
│            af-south-1 (Cape Town)           │
│                                             │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐ │
│  │ Supabase │  │ S3 Bucket│  │ App Server│ │
│  │ (Prod DB)│  │ (Backups)│  │ (Current) │ │
│  └────┬─────┘  └────┬─────┘  └───────────┘ │
│       │              │                       │
│       │    ┌─────────┘                       │
│       │    │ Cross-region replication        │
└───────┼────┼─────────────────────────────────┘
        │    │
        │    ▼
┌───────┼─────────────────────────────────────┐
│       │    DR REGION                         │
│       │    eu-west-1 (Ireland)               │
│       │                                      │
│       │  ┌───────────────────────┐           │
│       └──│ S3 Bucket (GLACIER)  │           │
│          │ examforge-backups-dr │           │
│          └───────────────────────┘           │
│                                             │
│  ┌───────────────────────┐                  │
│  │ Standby Supabase      │  (Cold standby)  │
│  │ (if provisioned)      │                  │
│  └───────────────────────┘                  │
└─────────────────────────────────────────────┘
```

### 6.2 Cross-Region Replication

Production backups are automatically replicated to the DR region (`eu-west-1`) during the upload step:

```bash
# This happens automatically in backup_dr.sh for production backups:
# Cross-region replication (copy to secondary region)
aws s3 cp /path/to/backup.gpg \
  s3://examforge-backups-dr/production/2025/03/01/backup.gpg \
  --region eu-west-1 --storage-class GLACIER
```

### 6.3 DR Failover Procedure

In the event that the primary region (`af-south-1`) is completely unavailable:

1. **Declare a P1 incident** — Follow the incident response playbook
2. **Assess the situation** — Is this a temporary outage or extended failure?
3. **If extended (>4 hours estimated):**
   a. Provision a new Supabase project in the DR region (`eu-west-1`)
   b. Download the latest encrypted backup from `s3://examforge-backups-dr/`
   c. Decrypt the backup:
      ```bash
      gpg --decrypt --output /tmp/dr_restore.dump \
        s3://examforge-backups-dr/production/2025/03/01/db_production_full_*.dump.gpg
      ```
   d. Restore the backup to the new Supabase project
   e. Update DNS to point to the new Supabase instance
   f. Deploy the application pointing to the new backend
   g. Verify all services via health check endpoint
   h. Communicate the failover to stakeholders

4. **If temporary (<4 hours):**
   - Wait for primary region recovery
   - Monitor Supabase status page
   - Communicate service degradation to users

### 6.4 DR Failback Procedure

When the primary region is restored:

1. **Sync data** — Replicate any new data from the DR region back to primary
2. **Verify data integrity** — Compare record counts between DR and primary
3. **Switch DNS back** — Point to the primary region
4. **Verify services** — Full health check on primary
5. **Document** — Record the failover duration, data loss (if any), and lessons learned

---

## 7. Backup Encryption and Security

### 7.1 Encryption at Rest

All backups are encrypted using **GPG** with the public key of `admin@examforge.ai`:

```bash
# Encryption (automatic in backup_dr.sh)
gpg --encrypt --recipient admin@examforge.ai --trust-model always \
  --output backup.dump.gpg backup.dump

# Decryption (manual, requires private key)
gpg --decrypt --output backup.dump backup.dump.gpg
```

### 7.2 GPG Key Management

| Item | Detail |
|------|--------|
| Key type | RSA 4096-bit |
| Recipient | `admin@examforge.ai` |
| Key rotation | Every 365 days |
| Private key storage | Hardware security module (HSM) or encrypted offline storage |
| Public key storage | All backup servers and CI/CD environment |
| Key escrow | CTO and one additional key custodian |

### 7.3 Key Rotation Procedure

```bash
# 1. Generate a new GPG key pair
gpg --full-generate-key
# Select: RSA and RSA, 4096 bits, expires in 1 year
# Real name: ExamForge AI Backup Key
# Email: admin@examforge.ai

# 2. Export the new public key to all backup servers
gpg --export admin@examforge.ai > examforge_backup_public.key
# Distribute to all servers that run backups

# 3. Re-encrypt the most recent backup with the new key
# (Old backups remain encrypted with the old key until they expire via retention policy)

# 4. Verify decryption with the new key
gpg --decrypt --output /tmp/verify.dump latest_backup.dump.gpg

# 5. Securely store the new private key
gpg --export-secret-keys admin@examforge.ai | gpg --symmetric --cipher-algo AES256 -o examforge_backup_private.key.gpg
# Store examforge_backup_private.key.gpg in a secure offline location

# 6. Update GPG_RECIPIENT in all backup scripts and environment variables
```

### 7.4 Access Control for Backups

| Role | Access Level | How Granted |
|------|-------------|-------------|
| `backup_reader` (DB role) | SELECT on all tables | Granted via `operational_security.sql` migration |
| Deploy user | Execute backup scripts, read backup files | SSH key-based access |
| AWS IAM role | S3 read/write on backup buckets | IAM policy assignment |
| GPG private key holder | Decrypt backups | Key custodian designation (CTO + 1) |

### 7.5 Backup Audit Trail

All backup operations are logged:

- **File logs:** `/home/z/my-project/examforge_ai/logs/backup_dr.log`
- **Database records:** `app_health_checks` table with `service_name = 'backup'`
- **S3 access logs:** Enabled on all backup buckets
- **GPG key usage:** Logged by the GPG agent

---

## 8. Disaster Recovery Documentation

### 8.1 DR Contacts

| Role | Responsibility | Contact |
|------|---------------|---------|
| DR Coordinator | Manages the DR process | CTO (see wiki) |
| Database Admin | Executes database restore | On-call engineer |
| Infrastructure Admin | Provisions DR infrastructure | On-call engineer |
| Communication Lead | Stakeholder communication | Team lead |
| Business Owner | Authorizes DR failover | CTO |

### 8.2 DR Scenarios

| Scenario | Probability | Impact | Recovery Strategy |
|----------|------------|--------|-------------------|
| Database corruption | Medium | High | Restore from most recent verified backup |
| Primary region outage | Low | Critical | Failover to DR region (eu-west-1) |
| Ransomware attack | Low | Critical | Restore from offline encrypted backups |
| Accidental data deletion | Medium | Medium | Point-in-time recovery |
| Storage bucket deletion | Low | High | Restore from S3 backup + storage archive |
| Full platform compromise | Very Low | Critical | Full DR from encrypted offline backups |

### 8.3 DR Checklist

When a disaster is declared:

- [ ] Declare a P1 incident and open incident channel
- [ ] Assess the scope: what data/services are affected?
- [ ] Determine the appropriate recovery strategy (restore vs failover)
- [ ] Notify stakeholders: "A disaster recovery operation is in progress. ETA for service restoration: [time]."
- [ ] Execute the recovery procedure
- [ ] Verify all services are healthy via the health check endpoint
- [ ] Verify data integrity (record counts, recent transactions, user logins)
- [ ] Communicate restoration to stakeholders
- [ ] Monitor for 2 hours post-recovery for issues
- [ ] Conduct a post-incident review within 48 hours
- [ ] Update DR documentation based on lessons learned

### 8.4 Backup Retention Policy Summary

| Backup Type | Local Retention | S3 Retention | DR Region Retention |
|------------|----------------|-------------|-------------------|
| Hourly incremental | 24 hours | 24 hours | Not replicated |
| Daily full | 30 days | 30 days | Not replicated |
| Monthly archival (1st of month) | 12 months | 12 months | 12 months (GLACIER) |
| Pre-deployment | 90 days | 90 days | 90 days (GLACIER) |
| Pre-restore | 30 days | 30 days | Not replicated |

### 8.5 S3 Bucket Organization

```
s3://examforge-backups-prod/           (af-south-1, STANDARD_IA)
├── production/
│   ├── 2025/
│   │   ├── 01/
│   │   │   ├── db_production_full_20250101_020000.dump.gpg
│   │   │   ├── db_production_full_20250101_020000.dump.sha256
│   │   │   ├── db_production_incremental_20250101_030000.dump.gpg
│   │   │   └── ...
│   │   ├── 02/
│   │   └── 03/
│   └── ...
└── summaries/
    ├── db_production_incremental_20250101_030000.changes_summary.csv
    └── ...

s3://examforge-backups-dr/             (eu-west-1, GLACIER)
├── production/
│   └── 2025/
│       └── 03/
│           └── db_production_full_20250301_020000.dump.gpg
```

---

## Appendix A: Quick Reference Commands

```bash
# Full backup (production)
./scripts/backup_dr.sh backup production --full --encrypt --verify --upload

# Incremental backup (production)
./scripts/backup_dr.sh backup production --incremental --encrypt --verify --upload

# Restore from backup
./scripts/backup_dr.sh restore production /path/to/backup.dump

# Dry-run restore (preview what would be restored)
./scripts/backup_dr.sh restore production /path/to/backup.dump --dry-run

# Recovery test
./scripts/backup_dr.sh test-recovery staging

# Check backup status
./scripts/backup_dr.sh status

# Verify a specific backup
./scripts/backup_dr.sh verify production /path/to/backup.dump

# Decrypt an encrypted backup
gpg --decrypt --output decrypted.dump backup.dump.gpg
```

## Appendix B: Backup Script Locations

| Script | Path | Purpose |
|--------|------|---------|
| Basic backup | `scripts/backup.sh` | Simple backup with encryption and S3 upload |
| DR backup | `scripts/backup_dr.sh` | Full DR system with verification, recovery testing, cross-region |
| Deploy (with pre-deploy backup) | `scripts/deploy.sh` | Deployment with automatic pre-deploy backup |
