# ExamForge AI — Incident Response Playbook

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **Classification:** Internal — Confidential

---

## Table of Contents

1. [Severity Classification](#1-severity-classification)
2. [Response Time SLAs](#2-response-time-slas)
3. [Escalation Paths](#3-escalation-paths)
4. [Incident Commander Role](#4-incident-commander-role)
5. [Communication Templates](#5-communication-templates)
6. [Specific Incident Playbooks](#6-specific-incident-playbooks)
7. [Post-Incident Review Process](#7-post-incident-review-process)
8. [Incident Timeline Requirements](#8-incident-timeline-requirements)

---

## 1. Severity Classification

### P1 — Critical

**Definition:** Complete system outage or security breach affecting all users. Revenue-impacting failures. Data loss or corruption.

**Examples:**
- Database (`examforge_production`) is completely unreachable
- Flutterwave payment processing is down for all users
- Active security breach with confirmed data exfiltration
- All Supabase Edge Functions failing
- Storage failure preventing exam file access for all schools

**Impact:** >50% of users affected. Revenue loss >₦500,000/hour.

### P2 — High

**Definition:** Major feature degradation affecting a significant user segment. No complete workaround available.

**Examples:**
- AI question generation failing for one provider (OpenAI or Gemini)
- Payment failures spiking above 10% error rate
- CBT exam sessions intermittently failing
- Real-time subscriptions not working
- Marketplace downloads failing

**Impact:** 10-50% of users affected. Revenue impact ₦100,000-500,000/hour.

### P3 — Medium

**Definition:** Minor feature degradation with a workaround available. Non-critical services impacted.

**Examples:**
- Dashboard analytics slow (>5s load time)
- Push notifications delayed by >15 minutes
- PDF export failing intermittently
- Parent portal messaging delayed
- Search functionality degraded

**Impact:** <10% of users affected. Minimal revenue impact.

### P4 — Low

**Definition:** Cosmetic issues, minor bugs, or feature requests. No user-facing impact.

**Examples:**
- UI rendering glitch on a specific browser
- Typo in notification text
- Non-critical metric dashboard not updating
- Log formatting inconsistency

**Impact:** Negligible. No revenue impact.

---

## 2. Response Time SLAs

| Severity | Acknowledge | First Response | Resolution Target | Update Frequency |
|----------|-------------|----------------|-------------------|-----------------|
| **P1 — Critical** | 5 minutes | 15 minutes | 4 hours | Every 30 minutes |
| **P2 — High** | 15 minutes | 30 minutes | 8 hours | Every 1 hour |
| **P3 — Medium** | 1 hour | 4 hours | 24 hours | Every 4 hours |
| **P4 — Low** | 4 hours | 1 business day | 5 business days | As needed |

### SLA Measurement

- **Acknowledge:** Time from alert firing to on-call acknowledging in `#incident-response` Slack channel
- **First Response:** Time from alert to first meaningful action taken (not just "looking into it")
- **Resolution Target:** Time from alert to service fully restored and verified
- **Update Frequency:** Minimum cadence for stakeholder communication during active incident

---

## 3. Escalation Paths

### 3.1 Escalation Levels

```
Level 0: On-Call Engineer
  ├── Receives initial alert via Slack + SMS + PagerDuty
  ├── Has 15 minutes (P1) to acknowledge
  └── If no ack: auto-escalate to Level 1

Level 1: Team Lead
  ├── Notified via Slack + SMS
  ├── Joins incident channel within 10 minutes
  └── If unresolved after 30 minutes: escalate to Level 2

Level 2: CTO / Engineering Director
  ├── Notified via Slack + SMS + Phone Call
  ├── Makes strategic decisions (vendor escalation, customer comms)
  └── Coordinates with external parties if needed
```

### 3.2 Escalation Triggers

| Condition | Escalate From | Escalate To |
|-----------|--------------|-------------|
| No acknowledgment within 15 minutes (P1) | Level 0 | Level 1 |
| No acknowledgment within 1 hour (P2) | Level 0 | Level 1 |
| P1 not resolved within 1 hour | Level 0 | Level 1 |
| P1 not resolved within 2 hours | Level 1 | Level 2 |
| Security incident confirmed | Level 0 | Level 2 (immediately) |
| Payment provider outage affecting live transactions | Level 0 | Level 1 (immediately) |
| Data loss or corruption confirmed | Level 0 | Level 2 (immediately) |
| Media or regulatory attention | Level 1 | Level 2 (immediately) |

### 3.3 Escalation Notification Channels

Per the `escalation_policy` table in the database:

| Severity | Level 0 Channel | Level 0 Timeout | Level 1 Channel | Level 1 Timeout | Level 2 Channel |
|----------|----------------|-----------------|-----------------|-----------------|-----------------|
| Critical | Slack + SMS + Call | 5 min | Slack + SMS + Call | 15 min | Slack + SMS + Call |
| High | Slack + SMS | 15 min | Slack + SMS | 30 min | Slack + SMS + Call |
| Warning | Slack | 1 hour | Slack + SMS | 2 hours | Slack + SMS |
| Info | Slack | 24 hours | Slack | 48 hours | Slack |

---

## 4. Incident Commander Role

### 4.1 Responsibilities

The Incident Commander (IC) is the single point of coordination during an incident. They do **not** fix the issue directly — they coordinate the response.

1. **Declare the incident** — Create an incident channel (`#inc-YYYYMMDD-brief-description`)
2. **Assign roles** — Designate responders for investigation, communication, and resolution
3. **Maintain the timeline** — Record all significant events with timestamps
4. **Coordinate communication** — Ensure stakeholders are updated per SLA
5. **Make escalation decisions** — Escalate if resolution is not progressing
6. **Authorize workarounds** — Approve temporary measures (e.g., feature flag disable)
7. **Declare resolution** — Verify service is restored and close the incident

### 4.2 IC Assignment

| Incident Severity | IC Role |
|------------------|---------|
| P1 | On-call engineer (first responder becomes IC until team lead joins) |
| P2 | On-call engineer |
| P3 | On-call engineer or next available engineer |
| P4 | Assigned engineer |

### 4.3 IC Handoff Protocol

When transferring IC role during a long-running incident:

1. Announce handoff in the incident channel: "IC handoff: @new-ic taking over from @old-ic at <timestamp>"
2. Brief the new IC on current status, active investigations, and pending actions
3. Update the incident timeline with the handoff
4. The outgoing IC remains available for questions for at least 30 minutes

---

## 5. Communication Templates

### 5.1 Incident Declaration

```
🚨 INCIDENT DECLARED — [P1/P2/P3/P4]

**Summary:** [Brief description of the issue]
**Severity:** [P1/P2/P3/P4]
**Impact:** [Who is affected and how]
**IC:** @incident-commander
**Channel:** #inc-YYYYMMDD-description

**Current Status:** Investigating
**Next Update:** [Time]
```

### 5.2 Stakeholder Update

```
📊 INCIDENT UPDATE — [P1/P2/P3/P4] — [Brief Title]

**Current Status:** [Investigating / Mitigating / Resolved]
**Duration:** [X hours Y minutes]
**Impact:** [Current impact description]

**What happened:** [Summary of findings since last update]
**What we're doing:** [Current actions being taken]
**What's next:** [Planned next steps]

**Next Update:** [Time]
```

### 5.3 Resolution Notice

```
✅ INCIDENT RESOLVED — [Brief Title]

**Duration:** [Total incident duration]
**Impact:** [Final impact summary]
**Root Cause:** [What caused the issue]
**Resolution:** [How the issue was fixed]

**Action Items:**
1. [Follow-up task from the incident]
2. [Preventive measure to implement]

**Post-Incident Review:** Scheduled for [date/time]
```

### 5.4 External Customer Communication

```
Subject: [Service Status] — [Issue Description]

Dear ExamForge AI Users,

We are currently experiencing [description of issue]. This affects [specific features/services].

Our team is actively working to resolve this issue. [Workaround if available].

We will provide an update within [timeframe].

We apologize for the inconvenience.

— ExamForge AI Team
```

---

## 6. Specific Incident Playbooks

### 6.1 Database Outage

**Symptoms:** Health check returns `database: down`. App shows connection errors. Queries timeout.

**Investigation Steps:**

1. Check database connectivity:
   ```bash
   psql "${PRODUCTION_DATABASE_URL}" -c "SELECT 1;"
   ```

2. Check Supabase status page: https://status.supabase.com

3. Check connection pool exhaustion:
   ```sql
   SELECT count(*), state FROM pg_stat_activity GROUP BY state;
   ```

4. Check for long-running queries blocking others:
   ```sql
   SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
   FROM pg_stat_activity
   WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '30 seconds'
   ORDER BY duration DESC;
   ```

5. Check disk space:
   ```sql
   SELECT pg_size_pretty(pg_database_size('examforge_production'));
   ```

**Resolution Steps:**

- **Connection pool exhaustion:** Kill idle connections:
  ```sql
  SELECT pg_terminate_backend(pid) FROM pg_stat_activity
  WHERE state = 'idle' AND query_start < now() - interval '10 minutes';
  ```

- **Long-running queries blocking:** Terminate the blocking query:
  ```sql
  SELECT pg_terminate_backend(<pid>);
  ```

- **Supabase outage:** Check Supabase status, contact Supabase support if needed

- **Disk full:** Remove old data from `api_latency_metrics`, `auth_metrics`, etc.:
  ```sql
  DELETE FROM api_latency_metrics WHERE created_at < now() - interval '7 days';
  ```

- **Complete database failure:** Restore from backup:
  ```bash
  ./scripts/backup_dr.sh restore production <latest-backup-file>
  ```

### 6.2 Payment Provider Outage

**Symptoms:** Flutterwave API returning 5xx errors. Payment processing failures. Webhook events not arriving.

**Investigation Steps:**

1. Check Flutterwave status: https://status.flutterwave.com

2. Test API connectivity:
   ```bash
   curl -s -w "%{http_code}" -H "Authorization: Bearer ${FLUTTERWAVE_SECRET_KEY}" \
     https://api.flutterwave.com/v3/transactions
   ```

3. Check recent payment metrics:
   ```sql
   SELECT event_type, COUNT(*), SUM(amount)
   FROM payment_metrics
   WHERE created_at > now() - interval '1 hour'
   GROUP BY event_type ORDER BY event_type;
   ```

4. Check webhook event processing:
   ```sql
   SELECT COUNT(*) FROM webhook_events
   WHERE processed = false AND created_at > now() - interval '1 hour';
   ```

**Resolution Steps:**

- **Flutterwave API down:** Enable payment queue mode. Record all payment attempts for later processing:
  ```sql
  -- Flag transactions as pending provider recovery
  UPDATE transactions SET status = 'pending_provider_recovery'
  WHERE status = 'initiated' AND created_at > now() - interval '1 hour';
  ```

- **Webhook not arriving:** Manually verify pending transactions:
  ```bash
  # Trigger manual transaction verification via Edge Function
  curl -X POST https://examforge.ai/functions/v1/verify-transactions \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}"
  ```

- **Partial outage (some endpoints work):** Retry with exponential backoff for failed payments

### 6.3 AI Provider Outage

**Symptoms:** AI question generation failing. AI grading returning errors. Prompt injection detection still works but generation fails.

**Investigation Steps:**

1. Check AI provider status (OpenAI: https://status.openai.com, Google AI: https://status.cloud.google.com)

2. Check AI service metrics:
   ```sql
   SELECT provider, feature, COUNT(*) as total,
     SUM(CASE WHEN error_message IS NOT NULL THEN 1 ELSE 0 END) as errors
   FROM ai_service_metrics
   WHERE created_at > now() - interval '1 hour'
   GROUP BY provider, feature;
   ```

3. Test provider connectivity:
   ```bash
   # OpenAI
   curl -s https://api.openai.com/v1/models -H "Authorization: Bearer $OPENAI_API_KEY" | jq '.data | length'

   # Gemini
   curl -s "https://generativelanguage.googleapis.com/v1/models?key=$GEMINI_API_KEY" | jq '.models | length'
   ```

**Resolution Steps:**

- **Single provider down:** Fall back to alternate provider. The `AiProvidersRegistry` supports multiple providers:
  ```dart
  // Feature flag: disable failing provider, enable fallback
  // This can be done via the feature_flags table:
  // UPDATE feature_flags SET is_enabled = false WHERE name = 'ai_openai_provider';
  ```

- **All providers down:** Disable AI features gracefully:
  ```sql
  UPDATE feature_flags SET is_enabled = false
  WHERE name IN ('ai_question_generation', 'ai_exam_coach', 'ai_grading_v2');
  ```

  Show user-facing message: "AI features are temporarily unavailable. You can still create questions manually."

- **Rate limited:** Implement request queuing and reduce concurrent AI requests

### 6.4 Security Incident

**Symptoms:** Unusual auth failures. Prompt injection attempts. Unauthorized access detected. Data exfiltration indicators.

**Investigation Steps:**

1. Check authentication anomalies:
   ```sql
   SELECT client_ip, COUNT(*) as failures, array_agg(DISTINCT email) as emails
   FROM auth_metrics
   WHERE event_type = 'login_failure' AND created_at > now() - interval '1 hour'
   GROUP BY client_ip
   HAVING COUNT(*) > 10
   ORDER BY failures DESC;
   ```

2. Check AI security blocks:
   ```sql
   SELECT COUNT(*), array_agg(DISTINCT block_reason)
   FROM ai_service_metrics
   WHERE was_blocked = true AND created_at > now() - interval '24 hours';
   ```

3. Check admin access log:
   ```sql
   SELECT admin_user_id, action, target_resource, client_ip
   FROM admin_access_log
   WHERE created_at > now() - interval '24 hours'
   ORDER BY created_at DESC;
   ```

4. Check for RLS policy violations:
   ```sql
   SELECT * FROM admin_access_log
   WHERE action = 'unauthorized_access_attempt'
   ORDER BY created_at DESC LIMIT 50;
   ```

**Resolution Steps:**

- **Brute force attack:** Block offending IPs at the infrastructure level. Enable rate limiting:
  ```sql
  -- The rate_limits table and check_rate_limit function handle this automatically
  -- For immediate IP blocking, add to infrastructure firewall
  ```

- **Prompt injection attacks:** The `AiSecurityService` blocks these automatically. Review and tune detection rules.

- **Confirmed data breach:**
  1. **Immediately escalate to Level 2** (CTO)
  2. Isolate affected systems
  3. Rotate all secrets (`SUPABASE_SERVICE_KEY`, `FLUTTERWAVE_SECRET_KEY`, `DATABASE_URL` password)
  4. Preserve forensic evidence (logs, database snapshots)
  5. Notify affected users per Nigerian Data Protection Regulation (NDPR)
  6. Engage legal counsel within 72 hours

- **Unauthorized admin access:**
  1. Revoke the compromised session
  2. Force password reset for affected accounts
  3. Enable MFA for all admin accounts
  4. Audit all actions taken by the compromised account

### 6.5 Storage Failure

**Symptoms:** File uploads failing. Exam files not loading. Marketplace downloads returning errors.

**Investigation Steps:**

1. Check storage health via the health-check Edge Function:
   ```bash
   curl -s https://examforge.ai/functions/v1/health-check | jq '.services.storage'
   ```

2. Check Supabase Storage bucket status:
   ```bash
   supabase storage list --project-id examforge-production
   ```

3. Check storage metrics:
   ```sql
   SELECT bucket_name, total_files, total_size_bytes
   FROM storage_metrics
   ORDER BY recorded_at DESC LIMIT 10;
   ```

4. Verify specific bucket accessibility:
   - `exam-files` — Exam papers and documents (private)
   - `profile-images` — User avatars (public)
   - `marketplace-files` — Marketplace resources (private)
   - `question-media` — Question images/media (private)

**Resolution Steps:**

- **Bucket permission issue:** Verify RLS policies on `storage.objects`:
  ```sql
  SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
  ```

- **Storage quota exceeded:** Archive or remove old files, increase quota

- **Supabase Storage outage:** Check https://status.supabase.com, contact support

- **File corruption:** Restore from backup:
  ```bash
  ./scripts/backup_dr.sh restore production <storage-backup-file>
  ```

### 6.6 Deployment Failure

**Symptoms:** Deploy script exits with error. Health check fails after deployment. Application returns 5xx errors.

**Investigation Steps:**

1. Check the deploy script output for error details

2. Check if the current symlink points to a valid release:
   ```bash
   ssh deploy@prod-db.examforge.ai "ls -la /var/www/examforge/current"
   ```

3. Check application logs:
   ```bash
   ssh deploy@prod-db.examforge.ai "tail -100 /var/log/examforge/app.log"
   ```

4. Check if database migrations were applied:
   ```sql
   SELECT * FROM _deploy_migrations ORDER BY applied_at DESC LIMIT 5;
   ```

5. Verify the health endpoint:
   ```bash
   curl -s https://examforge.ai/health | jq .
   ```

**Resolution Steps:**

- **Migration failure:** The deploy script automatically rolls back. If manual intervention is needed:
  ```bash
  ./scripts/deploy.sh production --rollback
  ```

- **Build artifact issue:** Rebuild and redeploy:
  ```bash
  flutter clean
  flutter build web --release --dart-define=ENVIRONMENT=production
  ./scripts/deploy.sh production --blue-green
  ```

- **Symlink error:** Manually fix:
  ```bash
  ssh deploy@prod-db.examforge.ai \
    "cd /var/www/examforge && ln -sfn releases/<working-version> current && sudo systemctl reload nginx"
  ```

- **Edge Function deployment failure:** Redeploy the specific function:
  ```bash
  supabase functions deploy health-check --project-id examforge-production
  supabase functions deploy flutterwave-webhook --project-id examforge-production
  supabase functions deploy process-refund --project-id examforge-production
  supabase functions deploy marketplace-download --project-id examforge-production
  ```

---

## 7. Post-Incident Review Process

### 7.1 When to Conduct a Review

- **Mandatory:** All P1 and P2 incidents
- **Recommended:** P3 incidents that reveal systemic issues
- **Optional:** P4 incidents at team discretion

### 7.2 Timeline

| Milestone | Deadline |
|-----------|----------|
| Schedule review | Within 24 hours of resolution |
| Conduct review | Within 48 hours of resolution |
| Publish findings | Within 72 hours of resolution |
| Complete action items | Per assigned deadlines |

### 7.3 Review Template

```markdown
# Post-Incident Review: [Incident Title]

## Summary
- **Date:** [YYYY-MM-DD]
- **Duration:** [X hours Y minutes]
- **Severity:** [P1/P2/P3/P4]
- **IC:** [Name]
- **Responders:** [Names]

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | Alert fired: [description] |
| HH:MM | IC acknowledged |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Service restored |
| HH:MM | Incident closed |

## Root Cause
[Detailed description of what caused the incident]

## Impact
- **Users affected:** [Number or percentage]
- **Revenue impact:** [Amount in NGN]
- **Data impact:** [Any data loss or corruption]

## What Went Well
1. [Positive aspect of the response]
2. [Positive aspect of the response]

## What Could Be Improved
1. [Area for improvement]
2. [Area for improvement]

## Action Items
| # | Action | Owner | Deadline | Priority |
|---|--------|-------|----------|----------|
| 1 | [Specific action] | [Name] | [Date] | High |
| 2 | [Specific action] | [Name] | [Date] | Medium |

## Lessons Learned
[Key takeaways for the team]
```

### 7.4 Blameless Culture

Post-incident reviews are **blameless**. The focus is on:
- Understanding **why** the system failed, not **who** made a mistake
- Identifying systemic improvements, not individual culpability
- Preventing recurrence, not assigning fault

---

## 8. Incident Timeline Requirements

### 8.1 What to Record

Every incident must have a detailed timeline recording:

| Field | Required | Example |
|-------|----------|---------|
| Timestamp (UTC) | Yes | `2025-03-01T12:00:00Z` |
| Event type | Yes | `alert_fired`, `acknowledged`, `escalated`, `mitigated`, `resolved` |
| Actor | Yes | `@engineer-name` or `system` |
| Description | Yes | Detailed description of what happened |
| Related metric values | No | Error rate, latency, etc. at time of event |
| Decisions made | Yes | "Decided to failover to backup provider" |
| Communication sent | No | "Stakeholder update sent at 12:15 UTC" |

### 8.2 Timeline Storage

Incident timelines are stored in the `alert_history` table:

```sql
-- Query incident history
SELECT alert_name, severity, fired_at, acknowledged_at, resolved_at,
       EXTRACT(EPOCH FROM (resolved_at - fired_at))/3600 AS duration_hours
FROM alert_history
WHERE fired_at > now() - interval '30 days'
ORDER BY fired_at DESC;
```

### 8.3 Reporting

Monthly incident reports are generated from the `alert_history` table and include:

- Total incidents by severity
- Mean Time to Acknowledge (MTTA) by severity
- Mean Time to Resolve (MTTR) by severity
- Top recurring alert types
- SLA compliance rate
- Action item completion rate from post-incident reviews

```sql
-- Monthly incident summary
SELECT
  severity,
  COUNT(*) AS total_incidents,
  AVG(EXTRACT(EPOCH FROM (acknowledged_at - fired_at))) / 60 AS avg_mttta_minutes,
  AVG(EXTRACT(EPOCH FROM (resolved_at - fired_at))) / 3600 AS avg_mttr_hours
FROM alert_history
WHERE fired_at > now() - interval '30 days'
  AND resolved_at IS NOT NULL
GROUP BY severity
ORDER BY severity;
```

---

## Appendix A: Alert Rule Quick Reference

| Alert Name | Severity | Category | Metric Source | Threshold |
|-----------|----------|----------|---------------|-----------|
| `database_down` | Critical | Database | `app_health_checks` | Response time = 0 |
| `payment_provider_down` | Critical | Payment | `payment_metrics` | >5 errors in 5 min |
| `security_breach_detected` | Critical | Security | `auth_metrics` | >50 failures in 5 min |
| `high_error_rate` | High | Infrastructure | `api_latency_metrics` | Error rate >5% |
| `high_api_latency` | High | Infrastructure | `api_latency_metrics` | P95 >2000ms |
| `high_db_latency` | High | Database | `performance_metrics` | Avg >500ms |
| `payment_failures_spike` | High | Payment | `payment_metrics` | Failure rate >10% |
| `ai_provider_failures` | High | AI | `ai_service_metrics` | Error rate >15% |
| `backup_failed` | High | Infrastructure | `app_health_checks` | Backup status = 0 |
| `storage_failure` | High | Infrastructure | `app_health_checks` | Storage status = 0 |
| `moderate_api_latency` | Warning | Infrastructure | `api_latency_metrics` | P95 >1000ms |
| `cpu_spike` | Warning | Infrastructure | `server_resource_metrics` | CPU >80% |
| `memory_spike` | Warning | Infrastructure | `server_resource_metrics` | Memory >85% |
| `ai_prompt_injection` | Warning | Security | `ai_service_metrics` | >5 blocked in 5 min |
| `auth_failures_spike` | Warning | Security | `auth_metrics` | >20 failures in 5 min |
| `disk_space_low` | Warning | Infrastructure | `server_resource_metrics` | Disk >80% |

## Appendix B: Emergency Contacts

| Role | Name | Phone | Slack | Availability |
|------|------|-------|-------|-------------|
| On-Call Engineer | (Rotating) | (See PagerDuty) | @on-call | 24/7 |
| Team Lead | (See wiki) | (See wiki) | @team-lead | Business hours + on-call |
| CTO | (See wiki) | (See wiki) | @cto | Business hours + escalation |
| Supabase Support | — | — | N/A | Enterprise plan: 24/7 |
| Flutterwave Support | — | — | N/A | Business hours (WAT) |
