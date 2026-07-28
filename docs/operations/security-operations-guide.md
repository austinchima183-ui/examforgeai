# ExamForge AI — Security Operations Guide

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Security & Platform Engineering  
> **Classification:** Internal — Highly Confidential  
> **Compliance:** Nigeria Data Protection Regulation (NDPR) / NDPA 2023

---

## Table of Contents

1. [Secret Rotation Procedures](#1-secret-rotation-procedures)
2. [Access Review Schedule](#2-access-review-schedule)
3. [Vulnerability Scanning Schedule](#3-vulnerability-scanning-schedule)
4. [Security Incident Classification](#4-security-incident-classification)
5. [Forensic Investigation Procedures](#5-forensic-investigation-procedures)
6. [Compliance Requirements](#6-compliance-requirements)
7. [Penetration Testing Schedule](#7-penetration-testing-schedule)

---

## 1. Secret Rotation Procedures

### 1.1 Secret Inventory

| Secret | Storage Location | Rotation Period | Rotation Method | Impact of Rotation |
|--------|-----------------|----------------|-----------------|-------------------|
| `SUPABASE_SERVICE_KEY` | GitHub Secrets + Supabase Vault | 90 days | Supabase Dashboard → Settings → API | All Edge Functions must be redeployed with new key |
| `FLUTTERWAVE_SECRET_KEY` | GitHub Secrets + Supabase Vault | 90 days | Flutterwave Dashboard → Settings → API Keys | Payment processing briefly interrupted during swap |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | Supabase Vault | 90 days | Flutterwave Dashboard → Settings → Webhooks | Webhook processing fails until new hash is set |
| `FCM_SERVER_KEY` | GitHub Secrets | 180 days | Firebase Console → Cloud Messaging | Push notifications interrupted until new key |
| `DATABASE_URL` (password) | GitHub Secrets | 90 days | SQL `ALTER ROLE` + update all secrets | Database connections fail until all services updated |
| `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` | GitHub Secrets | 90 days | AWS IAM → Rotate credentials | Backup uploads fail until updated |
| `GPG_RECIPIENT` key | Offline (HSM/encrypted storage) | 365 days | Generate new key, re-encrypt backups | Old backups require old key for decryption |
| `ENCRYPTION_MASTER_KEY` | Supabase Vault + offline | On compromise only | Key rotation procedure | Local encrypted data must be re-encrypted |

### 1.2 Rotation Procedure: `SUPABASE_SERVICE_KEY`

```bash
# Step 1: Generate new key in Supabase Dashboard
# Go to: Supabase Dashboard → Settings → API → Service Role Key → Regenerate

# Step 2: Update GitHub Secrets
gh secret set SUPABASE_SERVICE_KEY --body "<new-key>" --repo examforge-ai/examforge-ai

# Step 3: Update Supabase Vault (for Edge Functions)
# Go to: Supabase Dashboard → Vault → Update SUPABASE_SERVICE_ROLE_KEY

# Step 4: Redeploy all Edge Functions
supabase functions deploy health-check --project-id examforge-production
supabase functions deploy flutterwave-webhook --project-id examforge-production
supabase functions deploy process-refund --project-id examforge-production
supabase functions deploy marketplace-download --project-id examforge-production

# Step 5: Verify health
curl -s https://examforge.ai/functions/v1/health-check | jq .

# Step 6: Revoke the old key (wait 1 hour for propagation)
# Go to: Supabase Dashboard → Settings → API → Old Service Role Key → Revoke

# Step 7: Log the rotation
INSERT INTO admin_access_log (admin_user_id, admin_role, action, target_resource)
VALUES ('<admin-uuid>', 'super_admin', 'secret_rotation', 'SUPABASE_SERVICE_KEY');
```

### 1.3 Rotation Procedure: `FLUTTERWAVE_SECRET_KEY`

```bash
# Step 1: Generate new key in Flutterwave Dashboard
# Go to: Flutterwave Dashboard → Settings → API Keys → Generate New Key

# Step 2: Update GitHub Secrets
gh secret set FLUTTERWAVE_SECRET_KEY --body "<new-key>" --repo examforge-ai/examforge-ai

# Step 3: Update Supabase Vault
# Go to: Supabase Dashboard → Vault → Update FLUTTERWAVE_SECRET_KEY

# Step 4: Redeploy affected Edge Functions
supabase functions deploy flutterwave-webhook --project-id examforge-production
supabase functions deploy process-refund --project-id examforge-production
supabase functions deploy health-check --project-id examforge-production

# Step 5: Test payment processing
# Initiate a small test transaction via the Flutterwave test mode

# Step 6: Disable the old key in Flutterwave Dashboard
# Go to: Flutterwave Dashboard → Settings → API Keys → Old Key → Disable

# Step 7: Log the rotation
INSERT INTO admin_access_log (admin_user_id, admin_role, action, target_resource)
VALUES ('<admin-uuid>', 'super_admin', 'secret_rotation', 'FLUTTERWAVE_SECRET_KEY');
```

### 1.4 Rotation Procedure: `DATABASE_URL` Password

```bash
# Step 1: Generate a new strong password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "New password generated (length: ${#NEW_PASSWORD})"

# Step 2: Update the database role password
psql "${PRODUCTION_DATABASE_URL}" -c "ALTER ROLE examforge_app WITH PASSWORD '${NEW_PASSWORD}';"

# Step 3: Update PRODUCTION_DATABASE_URL in GitHub Secrets
NEW_URL="postgresql://examforge_app:${NEW_PASSWORD}@prod-db.examforge.ai:5432/examforge_production"
gh secret set PRODUCTION_DATABASE_URL --body "${NEW_URL}" --repo examforge-ai/examforge-ai

# Step 4: Update any services that use the database URL directly
# (Deploy scripts, backup scripts, monitoring agents)

# Step 5: Verify connectivity
psql "${NEW_URL}" -c "SELECT 1;"

# Step 6: Log the rotation
INSERT INTO admin_access_log (admin_user_id, admin_role, action, target_resource)
VALUES ('<admin-uuid>', 'super_admin', 'secret_rotation', 'DATABASE_URL_PASSWORD');
```

### 1.5 Emergency Secret Rotation

If a secret is known to be compromised:

1. **Immediately rotate** — Do not wait for the scheduled rotation date
2. **Revoke the old key** — Do not leave the compromised key active
3. **Audit access** — Check logs for any unauthorized use of the compromised secret
4. **Assess impact** — Determine if the compromised secret was used to access any data
5. **Notify stakeholders** — If personal data was accessed, follow NDPR notification requirements
6. **Document** — Record the compromise, rotation, and assessment in the security incident log

---

## 2. Access Review Schedule

### 2.1 Review Calendar

| Review Type | Frequency | Scope | Responsible Party |
|------------|-----------|-------|-------------------|
| **Full access audit** | Quarterly (Jan, Apr, Jul, Oct) | All users, roles, and permissions | Security team + CTO |
| **Admin access review** | Monthly | Super admins and school admins | CTO |
| **Service account audit** | Quarterly | All service accounts, API keys, and tokens | Platform engineering |
| **SSH key audit** | Semi-annually | All SSH keys on production servers | Infrastructure team |
| **Third-party access review** | Quarterly | Vendor access, contractor accounts | Security team |
| **Supabase project membership** | Quarterly | All users with Supabase Dashboard access | CTO |

### 2.2 Access Review Checklist

For each quarterly review, verify:

- [ ] **Principle of least privilege:** Every user has the minimum access required
- [ ] **Orphaned accounts:** No accounts belonging to departed team members
- [ ] **Dormant accounts:** No accounts with no login in 90+ days
- [ ] **Role accuracy:** User roles in the `users` table match their actual job function
- [ ] **MFA enforcement:** All admin accounts have multi-factor authentication enabled
- [ ] **Service account scope:** All service accounts (`webhook_processor`, `refund_processor`, `monitoring_agent`, `backup_reader`, `analytics_reader`) have only the permissions defined in `operational_security.sql`
- [ ] **RLS policy integrity:** No RLS policies have been disabled or modified without approval
- [ ] **Feature flag access:** Only authorized personnel can modify feature flags

### 2.3 Review Procedure

```sql
-- Find users who haven't logged in for 90 days
SELECT id, email, full_name, role, last_login_at
FROM users
WHERE last_login_at < now() - INTERVAL '90 days'
  AND is_active = true
ORDER BY last_login_at ASC;

-- Find super admins
SELECT id, email, full_name, last_login_at
FROM users
WHERE role = 'super_admin' AND is_active = true;

-- Check admin access log for unusual patterns
SELECT admin_user_id, action, COUNT(*) as action_count
FROM admin_access_log
WHERE created_at > now() - INTERVAL '90 days'
GROUP BY admin_user_id, action
ORDER BY action_count DESC;

-- Verify RLS is enabled on all tables
SELECT tablename FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;

-- Check for disabled RLS policies
SELECT tablename, policyname FROM pg_policies
WHERE schemaname = 'public' AND cmd = 'ALL';
```

### 2.4 Review Output

After each review, produce a report containing:

1. Total user count by role
2. Dormant accounts identified (with action taken)
3. Access changes made during the review
4. Any security concerns discovered
5. Recommendations for the next review period

---

## 3. Vulnerability Scanning Schedule

### 3.1 Scanning Tools

| Tool | Target | Scan Type | Frequency |
|------|--------|-----------|-----------|
| **GitHub Dependabot** | Dart/Flutter dependencies (`pubspec.yaml`) | Dependency vulnerability | Continuous (on push) |
| **GitHub CodeQL** | Dart source code | Static analysis (SAST) | On every PR |
| **Gitleaks** | Full codebase | Secret/credential detection | On every PR + nightly |
| **OWASP ZAP** | `https://examforge.ai` | Dynamic analysis (DAST) | Weekly |
| **Trivy** | Docker images, infrastructure config | Container/IaC scanning | On every build |
| **Supabase Security Advisor** | Supabase project configuration | Platform-specific checks | Weekly |
| **Nikto** | Web server | Web server misconfiguration | Monthly |

### 3.2 Scan Schedule

| Day | Scan | Time (UTC) | Duration | Alert On |
|-----|------|-----------|----------|----------|
| Monday | OWASP ZAP (full scan) | 02:00 | ~3 hours | High/Critical findings |
| Wednesday | Supabase Security Advisor | 10:00 | ~15 minutes | Any findings |
| Friday | Gitleaks (full repo scan) | 02:00 | ~10 minutes | Any findings |
| 1st of month | Nikto web server scan | 02:00 | ~1 hour | Any findings |
| Continuous | Dependabot + CodeQL | On every PR | ~5 minutes | High/Critical findings |
| On build | Trivy container scan | CI/CD pipeline | ~2 minutes | High/Critical findings |

### 3.3 Vulnerability Severity Classification

| Severity | CVSS Score | Response Time | Example |
|----------|-----------|---------------|---------|
| **Critical** | 9.0–10.0 | Fix within 24 hours | Remote code execution, SQL injection |
| **High** | 7.0–8.9 | Fix within 7 days | Authentication bypass, XSS with session hijack |
| **Medium** | 4.0–6.9 | Fix within 30 days | Reflected XSS, information disclosure |
| **Low** | 0.1–3.9 | Fix within 90 days | Verbose error messages, minor info leak |

### 3.4 Vulnerability Remediation Process

1. **Triage** — Classify severity based on CVSS and business context
2. **Assign** — Assign to the appropriate team member
3. **Remediate** — Develop and test the fix
4. **Verify** — Re-scan to confirm the vulnerability is resolved
5. **Document** — Record the vulnerability, remediation, and verification in the security log

```sql
-- Track vulnerability remediation
INSERT INTO admin_access_log (admin_user_id, admin_role, action, target_resource, details)
VALUES (
  '<admin-uuid>', 'super_admin', 'vulnerability_remediated',
  'CVE-2025-XXXX', '{"severity": "high", "description": "...", "fix": "..."}'
);
```

---

## 4. Security Incident Classification

### 4.1 Incident Categories

| Category | Code | Examples |
|----------|------|----------|
| **Unauthorized Access** | SEC-UNAUTH | Account takeover, privilege escalation, unauthorized API access |
| **Data Breach** | SEC-DATA | Personal data exposure, database exfiltration, storage leak |
| **Payment Fraud** | SEC-PAY | Transaction manipulation, webhook replay, refund abuse |
| **AI Security** | SEC-AI | Prompt injection, model manipulation, AI-generated content abuse |
| **Denial of Service** | SEC-DOS | API flooding, database overload, resource exhaustion |
| **Insider Threat** | SEC-INSIDER | Unauthorized admin actions, data theft by employee |
| **Phishing/Social Engineering** | SEC-PHISH | Credential theft via phishing, social engineering attacks |
| **Infrastructure Compromise** | SEC-INFRA | Server breach, key compromise, supply chain attack |

### 4.2 Severity Matrix

| Category | Low | Medium | High | Critical |
|----------|-----|--------|------|----------|
| **SEC-UNAUTH** | Failed attempt blocked | Single account compromised | Admin account compromised | Multiple accounts compromised |
| **SEC-DATA** | Non-sensitive data exposed | PII of <100 users | PII of 100-10,000 users | PII of >10,000 users |
| **SEC-PAY** | Test transaction anomaly | Single fraudulent transaction | Multiple fraudulent transactions | Payment system compromise |
| **SEC-AI** | Blocked injection attempt | Successful injection, limited output | AI generating harmful content | AI used as attack vector |
| **SEC-DOS** | Brief slowdown | Service degraded for <1 hour | Service down for 1-4 hours | Service down for >4 hours |
| **SEC-INSIDER** | Policy violation | Unauthorized data viewing | Data exfiltration attempt | Confirmed data theft |
| **SEC-PHISH** | Phishing email reported | Credential entered on phishing site | Account accessed by attacker | Multiple accounts compromised |
| **SEC-INFRA** | Unusual login attempt | Unauthorized access detected | Server compromised | Full infrastructure compromise |

### 4.3 Response Actions by Severity

**Critical:**
1. Immediately isolate affected systems
2. Escalate to CTO (Level 2)
3. Engage legal counsel within 24 hours
4. Notify affected users within 72 hours (NDPR requirement)
5. Report to NDPC (Nigeria Data Protection Commission) if personal data is involved
6. Preserve all forensic evidence

**High:**
1. Contain the incident immediately
2. Escalate to Team Lead (Level 1)
3. Investigate and remediate within 24 hours
4. Document all actions taken
5. Assess if user notification is required

**Medium:**
1. Investigate within 4 hours
2. Remediate within 48 hours
3. Document findings
4. Update security controls if needed

**Low:**
1. Log the incident
2. Investigate within 24 hours
3. Remediate within 7 days
4. Include in monthly security report

---

## 5. Forensic Investigation Procedures

### 5.1 Evidence Preservation

When a security incident is detected:

1. **Do not destroy evidence** — Do not restart services, clear logs, or modify data until evidence is preserved
2. **Capture system state** — Take snapshots of affected systems:
   ```bash
   # Database snapshot
   pg_dump --format=custom --file=/secure/evidence/db_snapshot_$(date +%Y%m%d%H%M%S).dump "${PRODUCTION_DATABASE_URL}"
   
   # Log capture
   cp /var/log/examforge/app.log /secure/evidence/app_$(date +%Y%m%d%H%M%S).log
   
   # Configuration snapshot
   tar -czf /secure/evidence/config_$(date +%Y%m%d%H%M%S).tar.gz supabase/ lib/config/ infra/
   ```

3. **Record timestamps** — All evidence must have accurate timestamps (UTC)
4. **Calculate hashes** — Generate SHA-256 checksums for all evidence files:
   ```bash
   sha256sum /secure/evidence/* > /secure/evidence/checksums.txt
   ```

### 5.2 Database Forensics

```sql
-- Check for unauthorized data access
SELECT user_id, school_id, action, target_resource, client_ip, created_at
FROM admin_access_log
WHERE created_at > now() - INTERVAL '7 days'
  AND action IN ('data_export', 'user_management', 'config_change')
ORDER BY created_at DESC;

-- Check for RLS policy bypasses
SELECT * FROM admin_access_log
WHERE action = 'unauthorized_access_attempt'
  AND created_at > now() - INTERVAL '7 days';

-- Check authentication anomalies
SELECT client_ip, COUNT(*) as attempts,
  SUM(CASE WHEN event_type = 'login_success' THEN 1 ELSE 0 END) as successes,
  SUM(CASE WHEN event_type = 'login_failure' THEN 1 ELSE 0 END) as failures
FROM auth_metrics
WHERE created_at > now() - INTERVAL '7 days'
GROUP BY client_ip
HAVING SUM(CASE WHEN event_type = 'login_failure' THEN 1 ELSE 0 END) > 10
ORDER BY failures DESC;

-- Check AI security incidents
SELECT user_id, feature, block_reason, created_at
FROM ai_service_metrics
WHERE was_blocked = true AND created_at > now() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

### 5.3 Forensic Investigation Checklist

- [ ] Preserve database snapshot
- [ ] Capture application logs
- [ ] Capture access logs (Supabase, Caddy/nginx)
- [ ] Calculate evidence hashes
- [ ] Document the timeline of events
- [ ] Identify the attack vector
- [ ] Determine the scope of data accessed
- [ ] Assess whether notification is required under NDPR
- [ ] Prepare incident report
- [ ] Implement remediation measures
- [ ] Verify remediation effectiveness

---

## 6. Compliance Requirements

### 6.1 Nigerian Data Protection Regulation (NDPR / NDPA 2023)

ExamForge AI processes personal data of Nigerian students, teachers, and parents. The following compliance requirements apply:

#### 6.1.1 Data Processing Principles

| Principle | Requirement | Implementation |
|-----------|-------------|----------------|
| **Lawfulness** | Process data only with legal basis | User consent obtained at registration; legitimate interest for operational data |
| **Purpose Limitation** | Use data only for stated purposes | Data collected for educational services only; no secondary use |
| **Data Minimization** | Collect only necessary data | Required fields only in registration; optional fields clearly marked |
| **Accuracy** | Keep data accurate and up-to-date | Users can update profile; `updated_at` triggers on all tables |
| **Storage Limitation** | Retain data only as long as needed | Retention policies per table (see monitoring guide) |
| **Security** | Protect data with appropriate measures | Encryption at rest and in transit; RLS policies; least-privilege access |
| **Accountability** | Demonstrate compliance | Audit log on all operations; `admin_access_log` table |

#### 6.1.2 Data Subject Rights

| Right | Implementation | Contact |
|-------|---------------|---------|
| Right of access | Users can view their data via profile page | privacy@examforge.ai |
| Right to rectification | Users can edit their profile | In-app profile settings |
| Right to erasure | Account deletion with data cleanup | privacy@examforge.ai (manual process) |
| Right to data portability | Export available upon request | privacy@examforge.ai |
| Right to object | Users can opt out of non-essential processing | In-app settings |

#### 6.1.3 Data Breach Notification

Under NDPR/NDPA, data breaches involving personal data must be reported:

| Timeline | Action |
|----------|--------|
| Within 24 hours | Assess the breach and determine if personal data is affected |
| Within 72 hours | Notify the Nigeria Data Protection Commission (NDPC) if personal data is involved |
| Without undue delay | Notify affected data subjects if the breach is likely to result in high risk |

**Notification must include:**
- Nature of the breach
- Categories and approximate number of data subjects affected
- Likely consequences of the breach
- Measures taken or proposed to address the breach

#### 6.1.4 Data Protection Officer

| Role | Name | Contact |
|------|------|---------|
| Data Protection Officer | (To be designated) | dpo@examforge.ai |

The DPO is responsible for:
- Monitoring compliance with NDPR/NDPA
- Advising on data protection impact assessments
- Serving as the contact point for the NDPC
- Managing data subject requests

### 6.2 Payment Card Industry (PCI) Considerations

ExamForge AI uses Flutterwave as the payment processor. Because card data never touches our servers (Flutterwave handles all card details), we fall under **PCI DSS SAQ A** (the simplest level of compliance):

| Requirement | Implementation |
|-------------|---------------|
| Card data never touches our servers | Flutterwave hosted checkout and API |
| Webhook signature verification | `FLUTTERWAVE_WEBHOOK_SECRET_HASH` with constant-time comparison |
| Amount verification | Server-side expected amount comparison in webhook processing |
| Idempotency | `WebhookIdempotencyTracker` prevents replay attacks |
| Secure transmission | TLS 1.2+ enforced on all endpoints |

### 6.3 Regular Compliance Audits

| Audit Type | Frequency | Scope | Auditor |
|------------|-----------|-------|---------|
| NDPR self-assessment | Annually | All data processing activities | DPO |
| PCI SAQ A self-assessment | Annually | Payment processing | Finance + Security |
| Internal security audit | Semi-annually | Full platform security posture | Security team |
| Third-party penetration test | Annually | External attack surface | External security firm |
| Access control audit | Quarterly | User roles and permissions | Security team |

---

## 7. Penetration Testing Schedule

### 7.1 Annual Penetration Test

| Parameter | Detail |
|-----------|--------|
| **Frequency** | Annually (Q1 each year) |
| **Duration** | 2 weeks |
| **Scope** | Full external attack surface |
| **Provider** | Certified third-party security firm |
| **Budget** | Allocated in annual security budget |

### 7.2 Scope Definition

The annual penetration test covers:

1. **Web Application** (`https://examforge.ai`)
   - Authentication and authorization testing
   - Session management
   - Input validation and injection testing
   - Business logic testing
   - API endpoint testing

2. **API Endpoints**
   - `/functions/v1/health-check`
   - `/functions/v1/flutterwave-webhook`
   - `/functions/v1/process-refund`
   - `/functions/v1/marketplace-download`
   - All Supabase REST API endpoints

3. **Infrastructure**
   - TLS configuration
   - Security headers (HSTS, CSP, X-Frame-Options)
   - DNS configuration
   - S3 bucket permissions

4. **Mobile Application** (if applicable)
   - Local storage security
   - Certificate pinning
   - API key exposure

### 7.3 Testing Methodology

Based on OWASP Testing Guide v4:

| Phase | Activities |
|-------|-----------|
| **Reconnaissance** | DNS enumeration, technology fingerprinting, API discovery |
| **Authentication Testing** | Brute force, session hijacking, privilege escalation |
| **Authorization Testing** | RLS bypass, horizontal/vertical privilege escalation |
| **Input Validation** | SQL injection, XSS, SSRF, command injection |
| **Business Logic** | Payment bypass, exam cheating, marketplace fraud |
| **AI Security** | Prompt injection, model manipulation, output filtering bypass |
| **Reporting** | Detailed findings with reproduction steps and remediation |

### 7.4 Internal Adversary Simulations

Between annual penetration tests, the security team runs internal adversary simulations:

| Simulation | Frequency | Duration | Team |
|-----------|-----------|----------|------|
| Web app attack simulation | Quarterly | 1 day | Security team |
| Phishing simulation | Semi-annually | 1 week | Security team |
| Insider threat simulation | Annually | 2 days | Security team |
| Payment fraud simulation | Quarterly | 4 hours | Security + Finance |

### 7.5 Findings Remediation

All penetration test findings are tracked to resolution:

| Severity | Remediation SLA | Verification |
|----------|----------------|-------------|
| Critical | 7 days | Re-test by original tester |
| High | 14 days | Re-test by security team |
| Medium | 30 days | Re-test by security team |
| Low | 90 days | Verified in next penetration test |

```sql
-- Track penetration test findings
INSERT INTO admin_access_log (admin_user_id, admin_role, action, target_resource, details)
VALUES (
  '<admin-uuid>', 'super_admin', 'pentest_finding',
  'PENTEST-2025-001', '{"severity": "high", "description": "...", "remediation": "...", "status": "open"}'
);
```

### 7.6 Post-Test Report

The penetration test report includes:

1. Executive summary
2. Scope and methodology
3. Findings by severity (with CVSS scores)
4. Detailed reproduction steps for each finding
5. Remediation recommendations
6. Risk rating for the overall platform
7. Comparison with previous year's findings (trend analysis)

---

## Appendix A: Security Checklist for Production

| # | Check | Method | Status |
|---|-------|--------|--------|
| SEC-001 | Webhook signatures use constant-time comparison | Code review | ✅ |
| SEC-002 | Payment amount verification enabled | Code review | ✅ |
| SEC-003 | Webhook idempotency enabled | Code review | ✅ |
| SEC-004 | API tokens stored in secure storage | Code review | ✅ |
| SEC-005 | Exam answers encrypted at rest | Code review | ✅ |
| SEC-006 | Marketplace downloads use signed URLs | Code review | ✅ |
| SEC-007 | RLS policies use correct role references | SQL query | ✅ |
| SEC-008 | AI prompt injection detection active | Code review | ✅ |
| SEC-009 | No secrets in source code | Gitleaks scan | ✅ |
| SEC-010 | All tables have RLS enabled | SQL query | ✅ |
| SEC-011 | Security headers configured | Curl check | ✅ |
| SEC-012 | TLS 1.2+ enforced | SSL Labs test | ✅ |
| SEC-013 | Rate limiting active | Load test | ✅ |
| SEC-014 | Admin actions audited | Log review | ✅ |
| SEC-015 | Dual approval for high-risk operations | Code review | ✅ |

## Appendix B: Database Security Roles

| Role | Purpose | Permissions |
|------|---------|-------------|
| `authenticated` | Flutter app users (via anon key + RLS) | Per-table RLS policies |
| `webhook_processor` | Flutterwave webhook Edge Function | SELECT/INSERT/UPDATE on `transactions`, `webhook_events` |
| `refund_processor` | Process-refund Edge Function | SELECT/UPDATE on `transactions`, INSERT on `refund_audit_log`, SELECT on `users` |
| `monitoring_agent` | Health check and metrics Edge Function | SELECT/INSERT on all monitoring tables, ALL on `alert_state` |
| `backup_reader` | Backup scripts | SELECT on all tables |
| `analytics_reader` | Super admin dashboard | SELECT on all tables + summary views |
