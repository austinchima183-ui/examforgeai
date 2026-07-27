# ExamForge AI — On-Call Runbook

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **Audience:** On-call engineers

---

## Table of Contents

1. [On-Call Schedule and Handoff Procedures](#1-on-call-schedule-and-handoff-procedures)
2. [Alert Acknowledgment and Response](#2-alert-acknowledgment-and-response)
3. [Common Issues and Quick Fixes](#3-common-issues-and-quick-fixes)
4. [Escalation Decision Tree](#4-escalation-decision-tree)
5. [Communication Channels](#5-communication-channels)
6. [Post-On-Call Report Template](#6-post-on-call-report-template)

---

## 1. On-Call Schedule and Handoff Procedures

### 1.1 Schedule

| Rotation | Duration | Coverage |
|----------|----------|----------|
| Primary on-call | 1 week (Monday 00:00 UTC – Sunday 23:59 UTC) | 24/7 alert response |
| Secondary on-call | 1 week (same period) | Backup if primary unresponsive |
| Follow-the-sun | Not applicable (single timezone team) | N/A |

**Schedule rotation:** The on-call schedule is maintained in PagerDuty and published in the `#on-call` Slack channel.

### 1.2 On-Call Responsibilities

- Acknowledge all P1 and P2 alerts within the SLA (5 min for P1, 15 min for P2)
- Triage and investigate alerts
- Coordinate incident response as the Incident Commander (IC)
- Execute runbook procedures for known issues
- Escalate to team lead or CTO when appropriate
- Update stakeholders per the incident communication SLA
- Document all actions in the incident timeline
- Complete a post-on-call handoff report at the end of the rotation

### 1.3 Handoff Procedure

The on-call handoff occurs every Monday at 00:00 UTC.

**Outgoing on-call engineer:**

1. Review all open incidents and ensure they are either resolved or have clear next steps
2. Document any ongoing issues that the incoming on-call engineer needs to know about
3. Post the handoff summary in `#on-call` Slack channel
4. Confirm the incoming engineer acknowledges the handoff
5. Update PagerDuty schedule to reflect the new primary

**Incoming on-call engineer:**

1. Review the handoff summary from the outgoing engineer
2. Verify access to all production systems (SSH, Supabase Dashboard, AWS Console)
3. Confirm PagerDuty is receiving notifications on your device
4. Review the current alert state:
   ```sql
   SELECT alert_name, severity, description, first_fired_at
   FROM alert_state
   WHERE is_firing = true;
   ```
5. Check for any planned maintenance or deployments during your rotation

### 1.4 Handoff Summary Template

```
📋 ON-CALL HANDOFF — Week of [Date]

**Outgoing:** @engineer-name
**Incoming:** @engineer-name

**Open Issues:**
1. [Issue description] — Status: [Investigating/Mitigated/Resolved] — Owner: [name]
2. [Issue description] — Status: [Investigating/Mitigated/Resolved] — Owner: [name]

**Recent Incidents This Week:**
1. [P1/P2] [Brief description] — Resolved in [duration]
2. [P1/P2] [Brief description] — Resolved in [duration]

**Ongoing Maintenance:**
- [Planned deployment on Wednesday]
- [Database maintenance on Thursday]

**Notes for Incoming:**
- [Anything the incoming engineer should be aware of]
- [Pending action items from this week's incidents]
```

---

## 2. Alert Acknowledgment and Response

### 2.1 Alert Flow

```
Alert Fires (Supabase Edge Function)
          │
          ▼
Alert State Updated (alert_state table)
          │
          ▼
Notification Sent (Slack + SMS/PagerDuty)
          │
          ▼
On-Call Engineer Acknowledges
          │
          ├── If P1: Acknowledge within 5 minutes
          ├── If P2: Acknowledge within 15 minutes
          ├── If P3: Acknowledge within 1 hour
          └── If P4: Acknowledge within 4 hours
          │
          ▼
Investigation Begins
          │
          ▼
Resolve or Escalate
```

### 2.2 Acknowledgment Process

1. **Acknowledge in Slack** — React to the alert message with ✅ or post "ACK" in the thread
2. **Acknowledge in PagerDuty** — Click "Acknowledge" on the incident
3. **Update the alert state:**
   ```sql
   UPDATE alert_state
   SET acknowledged_by = '<your-user-uuid>',
       acknowledged_at = now()
   WHERE alert_name = '<alert-name>' AND is_firing = true;
   ```
4. **Create an incident channel** (for P1/P2): `#inc-YYYYMMDD-brief-description`
5. **Start the investigation** — Follow the relevant playbook in this runbook

### 2.3 Triage Questions

When you receive an alert, answer these questions quickly:

1. **What service is affected?** Check the health endpoint: `curl -s https://examforge.ai/health | jq .`
2. **How many users are affected?** Check recent metrics:
   ```sql
   SELECT COUNT(DISTINCT user_id) FROM api_latency_metrics
   WHERE status_code >= 500 AND created_at > now() - INTERVAL '15 minutes';
   ```
3. **Is this a new issue or a recurrence?** Check alert history:
   ```sql
   SELECT alert_name, fired_at, resolved_at FROM alert_history
   WHERE alert_name = '<alert-name>' ORDER BY fired_at DESC LIMIT 5;
   ```
4. **Was there a recent deployment?** Check:
   ```bash
   cat deploy/production-version.txt
   ```
5. **Is it affecting revenue?** Check payment metrics:
   ```sql
   SELECT COUNT(*), SUM(amount) FROM payment_metrics
   WHERE event_type = 'payment_failed' AND created_at > now() - INTERVAL '1 hour';
   ```

---

## 3. Common Issues and Quick Fixes

### 3.1 Database Connection Pool Exhaustion

**Symptoms:** `database_down` or `high_db_latency` alert. Users seeing connection errors.

**Quick Fix:**
```sql
-- Check active connections
SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;

-- Kill idle connections older than 10 minutes
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE state = 'idle' AND query_start < now() - INTERVAL '10 minutes';

-- Verify pool recovery
SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;
```

**Prevention:** The `DB_POOL_MAX` configuration limits connections. In production, it's set to 50. If this happens regularly, consider increasing the pool size or investigating connection leaks in the application.

### 3.2 High API Error Rate

**Symptoms:** `high_error_rate` alert firing. >5% of requests returning 4xx/5xx.

**Quick Fix:**
```sql
-- Identify the failing endpoints
SELECT endpoint, status_code, COUNT(*), error_message
FROM api_latency_metrics
WHERE created_at > now() - INTERVAL '15 minutes' AND status_code >= 400
GROUP BY endpoint, status_code, error_message
ORDER BY COUNT(*) DESC LIMIT 10;

-- If a specific endpoint is failing, check if it's a deployment issue
-- Try rolling back if a recent deployment caused the issue
```

### 3.3 Flutterwave Webhook Processing Failures

**Symptoms:** `payment_provider_down` alert. Unprocessed webhook events in the queue.

**Quick Fix:**
```sql
-- Check unprocessed webhooks
SELECT COUNT(*) FROM webhook_events
WHERE processed = false AND created_at > now() - INTERVAL '1 hour';

-- Check recent payment failures
SELECT event_type, failure_reason, COUNT(*)
FROM payment_metrics
WHERE created_at > now() - INTERVAL '1 hour' AND event_type LIKE '%failed%'
GROUP BY event_type, failure_reason;
```

If Flutterwave is down, enable payment queue mode:
```sql
UPDATE transactions SET status = 'pending_provider_recovery'
WHERE status = 'initiated' AND created_at > now() - INTERVAL '1 hour';
```

### 3.4 AI Provider Rate Limiting

**Symptoms:** `ai_provider_failures` alert. AI generation returning 429 errors.

**Quick Fix:**
```sql
-- Check which provider is rate-limited
SELECT provider, error_message, COUNT(*)
FROM ai_service_metrics
WHERE created_at > now() - INTERVAL '15 minutes' AND error_message IS NOT NULL
GROUP BY provider, error_message
ORDER BY COUNT(*) DESC;
```

If OpenAI is rate-limited, switch to Gemini:
```sql
-- Feature flag: disable OpenAI, enable Gemini fallback
-- This is handled by the AiProvidersRegistry in the application
-- You can also reduce concurrent requests by adjusting rate limits
```

### 3.5 High CPU/Memory Usage

**Symptoms:** `cpu_spike` or `memory_spike` alert.

**Quick Fix:**
```sql
-- Check resource metrics
SELECT host_name, cpu_usage_pct, memory_usage_pct, disk_usage_pct, load_avg_1m
FROM server_resource_metrics
WHERE recorded_at > now() - INTERVAL '30 minutes'
ORDER BY recorded_at DESC LIMIT 10;
```

```bash
# SSH to the server and identify heavy processes
ssh deploy@prod-db.examforge.ai "ps aux --sort=-%cpu | head -20"

# If a specific process is consuming resources, investigate
# Common causes: large database query, memory leak in Edge Function, log file filling disk
```

### 3.6 Disk Space Running Low

**Symptoms:** `disk_space_low` alert. Disk usage >80%.

**Quick Fix:**
```bash
# Check what's using disk space
ssh deploy@prod-db.examforge.ai "du -sh /var/www/examforge/releases/* | sort -rh | head -10"
ssh deploy@prod-db.examforge.ai "du -sh /var/log/* | sort -rh | head -10"

# Clean up old releases (keep last 5)
ssh deploy@prod-db.examforge.ai "cd /var/www/examforge/releases && ls -t | tail -n +6 | xargs -r rm -rf"

# Clean up old logs
ssh deploy@prod-db.examforge.ai "find /var/log -name '*.log' -mtime +7 -delete"

# Clean up old metric data in the database
psql "${PRODUCTION_DATABASE_URL}" -c "
  DELETE FROM api_latency_metrics WHERE created_at < now() - INTERVAL '7 days';
  DELETE FROM server_resource_metrics WHERE recorded_at < now() - INTERVAL '7 days';
  DELETE FROM app_health_checks WHERE checked_at < now() - INTERVAL '7 days';
"
```

### 3.7 Edge Function Deployment Failure

**Symptoms:** Edge Function returning 5xx or not responding after deployment.

**Quick Fix:**
```bash
# Check Edge Function status
supabase functions list --project-id examforge-production

# Redeploy the failing function
supabase functions deploy <function-name> --project-id examforge-production

# Test the function
curl -s https://examforge.ai/functions/v1/<function-name> | jq .
```

### 3.8 Real-Time Subscriptions Not Working

**Symptoms:** CBT exam updates not appearing in real-time. Chat messages not showing.

**Quick Fix:**
```sql
-- Check Supabase Realtime status
-- Realtime relies on PostgreSQL logical replication
SELECT * FROM pg_replication_slots;

-- Check if Realtime is enabled on required tables
SELECT schemaname, tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
```

If replication slots are stale:
```sql
-- Drop and recreate stale replication slots
SELECT pg_drop_replication_slot(slot_name)
FROM pg_replication_slots
WHERE active = false AND slot_name LIKE '%realtime%';
```

### 3.9 Session Recovery Issues (CBT Exams)

**Symptoms:** Students losing exam progress. Session not recovering after disconnection.

**Quick Fix:**
- Verify the `SessionRecoveryService` is functioning
- Check `LocalEncryptionService` is encrypting answers correctly
- Verify `AutoSaveService` is saving at the configured interval
- Check `cbt_sessions` table for orphaned sessions:
  ```sql
  SELECT id, user_id, exam_id, status, last_activity_at
  FROM cbt_sessions
  WHERE status = 'active' AND last_activity_at < now() - INTERVAL '30 minutes';
  ```

### 3.10 Marketplace Download Failures

**Symptoms:** Users unable to download purchased resources. `marketplace-download` Edge Function errors.

**Quick Fix:**
```bash
# Test the download function
curl -s -X POST https://examforge.ai/functions/v1/marketplace-download \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"order_id": "<test-order-id>", "product_id": "<test-product-id>"}'

# Check signed URL generation
# The marketplace-download function generates signed URLs for marketplace-files bucket
```

---

## 4. Escalation Decision Tree

```
ALERT RECEIVED
      │
      ▼
Is it P1 (Critical)?
      │
  YES │          NO
      │           │
      ▼           ▼
Acknowledge     Is it P2 (High)?
within 5 min          │
      │          YES │          NO
      │               │           │
      │               ▼           ▼
      │         Acknowledge    Is it P3 (Medium)?
      │         within 15 min       │
      │               │        YES │          NO
      │               │             │           │
      │               │             ▼           ▼
      │               │        Acknowledge    P4 — Handle
      │               │        within 1 hr    during business
      │               │             │        hours
      │               │             │
      ▼               ▼             ▼
Can you resolve        │           │
within 15 min?         │           │
      │                │           │
  YES │   NO           │           │
      │    │           │           │
      ▼    ▼           ▼           ▼
Resolve  Escalate to   Same decision tree
         Team Lead     for each severity
         (Level 1)
```

### 4.1 When to Escalate

Escalate immediately if:

- **Security incident** confirmed (any severity) → Level 2 (CTO)
- **Payment processing** completely down → Level 1 (Team Lead) + Level 2
- **Data loss or corruption** confirmed → Level 2 (CTO)
- **You're stuck** after 30 minutes of investigation → Level 1
- **Multiple P1/P2 alerts** firing simultaneously → Level 1
- **External pressure** (media, regulators, major customer) → Level 2

### 4.2 How to Escalate

1. **Post in `#incident-response`:** "@team-lead Escalating: [brief description]. Need help with [specific ask]."
2. **Send SMS/call** if the escalation target doesn't respond within 5 minutes
3. **Continue investigating** while waiting for the escalated person to join
4. **Brief them quickly** when they join: "Here's what happened, here's what I've tried, here's what I need help with."

---

## 5. Communication Channels

### 5.1 Slack Channels

| Channel | Purpose | Who Has Access |
|---------|---------|---------------|
| `#on-call` | On-call schedule, handoff summaries | Engineering team |
| `#on-call-alerts` | Automated alert notifications | Engineering team |
| `#incident-response` | Active incident coordination | Engineering team + leadership |
| `#team-lead-alerts` | Level 1 escalation notifications | Team leads |
| `#cto-alerts` | Level 2 escalation notifications | CTO |
| `#deployments` | Deployment announcements | Engineering team |
| `#platform-status` | Platform status updates | All employees |

### 5.2 Communication Tools

| Tool | Use Case | When to Use |
|------|----------|-------------|
| **Slack** | Primary communication for all incidents | Always start here |
| **PagerDuty** | Alert routing and on-call management | Automatic — configured in escalation policy |
| **SMS** | Urgent escalation when Slack is insufficient | When target doesn't respond on Slack within 5 min |
| **Phone call** | Critical escalation | P1 incidents requiring immediate human response |
| **Email** | Post-incident reports, status updates | After incident resolution |

### 5.3 Notification Routing

Per the `notification_channels` table and `escalation_policy`:

| Severity | Level 0 | Level 1 | Level 2 |
|----------|---------|---------|---------|
| Critical | Slack `#on-call-alerts` + SMS + Call (5 min timeout) | Slack `#team-lead-alerts` + SMS + Call (15 min) | Slack `#cto-alerts` + SMS + Call (30 min) |
| High | Slack `#on-call-alerts` + SMS (15 min timeout) | Slack `#team-lead-alerts` + SMS (30 min) | Slack `#cto-alerts` + SMS + Call (1 hour) |
| Warning | Slack `#on-call-alerts` (1 hour timeout) | Slack `#team-lead-alerts` + SMS (2 hours) | Slack `#cto-alerts` + SMS (4 hours) |
| Info | Slack `#on-call-alerts` (24 hour timeout) | Slack `#team-lead-alerts` (48 hours) | Slack `#cto-alerts` (96 hours) |

---

## 6. Post-On-Call Report Template

Complete this report at the end of each on-call rotation and post it in `#on-call`.

```markdown
# On-Call Report — Week of [Start Date] to [End Date]

## On-Call Engineer
**Name:** [Your name]
**Week:** [Date range]

## Summary
- **Total alerts received:** [Number]
- **P1 incidents:** [Number]
- **P2 incidents:** [Number]
- **P3 incidents:** [Number]
- **P4 incidents:** [Number]
- **Mean time to acknowledge (MTTA):** [Average]
- **Mean time to resolve (MTTR):** [Average]

## Incidents

### [INC-YYYYMMDD-001] — [Brief Title]
- **Severity:** [P1/P2/P3/P4]
- **Duration:** [X hours Y minutes]
- **Root Cause:** [Brief description]
- **Resolution:** [What was done]
- **Action Items:**
  1. [ ] [Follow-up task] — Owner: [name] — Deadline: [date]

### [INC-YYYYMMDD-002] — [Brief Title]
- **Severity:** [P1/P2/P3/P4]
- **Duration:** [X hours Y minutes]
- **Root Cause:** [Brief description]
- **Resolution:** [What was done]
- **Action Items:**
  1. [ ] [Follow-up task] — Owner: [name] — Deadline: [date]

## Trends
- [Any patterns observed across incidents]
- [Recurring issues that need systemic fixes]
- [Alert fatigue concerns — too many false positives?]

## Process Improvements
1. [Suggestion for improving on-call process]
2. [Suggestion for improving runbooks]
3. [Suggestion for improving monitoring/alerting]

## Open Items for Next On-Call
1. [Item that needs continued attention]
2. [Planned maintenance during next rotation]

## Handoff Notes
[Any additional context for the next on-call engineer]
```

---

## Appendix A: Quick Reference — Key URLs

| Resource | URL |
|----------|-----|
| Production health check | `https://examforge.ai/functions/v1/health-check` |
| Staging health check | `https://staging.examforge.ai/functions/v1/health-check` |
| Supabase Dashboard (production) | `https://supabase.com/dashboard/project/examforge-production` |
| Supabase Dashboard (staging) | `https://supabase.com/dashboard/project/examforge-staging` |
| Flutterwave Dashboard | `https://dashboard.flutterwave.com` |
| AWS Console | `https://af-south-1.console.aws.amazon.com` |
| GitHub Actions | `https://github.com/examforge-ai/examforge-ai/actions` |
| Supabase Status | `https://status.supabase.com` |
| Flutterwave Status | `https://status.flutterwave.com` |
| OpenAI Status | `https://status.openai.com` |

## Appendix B: Quick Reference — Key Commands

```bash
# Health check
curl -s https://examforge.ai/health | jq .

# Check current deployment version
cat deploy/production-version.txt

# Rollback deployment
./scripts/deploy.sh production --rollback

# Check backup status
./scripts/backup_dr.sh status

# Manual backup
./scripts/backup_dr.sh backup production --full --encrypt --verify --upload

# Restore from backup
./scripts/backup_dr.sh restore production /path/to/backup.dump

# Run database migrations only
./scripts/deploy.sh production --migrate-only

# Deploy Edge Functions
supabase functions deploy health-check --project-id examforge-production
supabase functions deploy flutterwave-webhook --project-id examforge-production

# Check alert state
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT alert_name, severity, is_firing, first_fired_at FROM alert_state WHERE is_firing = true;"

# Check active connections
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;"

# Kill idle database connections
psql "${PRODUCTION_DATABASE_URL}" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND query_start < now() - INTERVAL '10 minutes';"
```

## Appendix C: Database Role Quick Reference

| Role | Used By | Key Permissions |
|------|---------|----------------|
| `authenticated` | Flutter app users | Per-table RLS policies |
| `webhook_processor` | `flutterwave-webhook` Edge Function | `transactions` (R/W), `webhook_events` (R/W) |
| `refund_processor` | `process-refund` Edge Function | `transactions` (R/W), `refund_audit_log` (W), `users` (R) |
| `monitoring_agent` | `health-check` Edge Function | All monitoring tables (R/W), `alert_state` (ALL) |
| `backup_reader` | Backup scripts | All tables (R) |
| `analytics_reader` | Super admin dashboard | All tables (R), summary views (R) |
