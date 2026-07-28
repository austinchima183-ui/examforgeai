# ExamForge AI — Monitoring Guide

> **Version:** 1.0  
> **Last Updated:** 2025-03-01  
> **Owner:** Platform Engineering Team  
> **Review Cycle:** Quarterly

---

## Table of Contents

1. [Services Monitored](#1-services-monitored)
2. [Metrics Collected](#2-metrics-collected)
3. [Dashboard Descriptions](#3-dashboard-descriptions)
4. [Health Check Endpoints and Interpretation](#4-health-check-endpoints-and-interpretation)
5. [Metric Retention Policies](#5-metric-retention-policies)
6. [Custom Metric Submission](#6-custom-metric-submission)

---

## 1. Services Monitored

### 1.1 Service Inventory

| Service | Type | Health Check Method | Criticality |
|---------|------|---------------------|-------------|
| **Database** (Supabase PostgreSQL) | Managed | `SELECT` query on `app_health_checks` table | Critical |
| **AI Service** (OpenAI + Gemini) | Third-party API | Generation test with timeout | High |
| **Payment** (Flutterwave) | Third-party API | `GET /v3/transactions` API call | Critical |
| **Auth** (Supabase Auth) | Managed | `getSession()` SDK call | Critical |
| **Storage** (Supabase Storage) | Managed | `listBuckets()` SDK call | High |
| **Edge Functions** (Supabase) | Managed | HTTP health check on each function | High |

### 1.2 Edge Functions

| Function | Purpose | Health Check |
|----------|---------|-------------|
| `health-check` | Service health monitoring + alert evaluation | Self-monitoring |
| `flutterwave-webhook` | Payment webhook processing | Webhook delivery rate |
| `process-refund` | Refund processing | Refund success rate |
| `marketplace-download` | Signed download URLs | Download success rate |

### 1.3 Storage Buckets

| Bucket | Public | Size Limit | MIME Types | Monitoring |
|--------|--------|-----------|------------|------------|
| `exam-files` | No | 50 MB | PDF, PNG, JPEG, WebP | Upload/download metrics |
| `profile-images` | Yes | 5 MB | PNG, JPEG, WebP | Upload metrics |
| `marketplace-files` | No | 100 MB | PDF, ZIP, PNG, JPEG | Download revenue metrics |
| `question-media` | No | 20 MB | PNG, JPEG, WebP, GIF | Upload metrics |

### 1.4 External Dependencies

| Dependency | Monitoring Method | SLA |
|------------|------------------|-----|
| OpenAI API | Direct API call via `ai_service_metrics` | 99.9% (per OpenAI SLA) |
| Google Gemini API | Direct API call via `ai_service_metrics` | 99.95% (per Google SLA) |
| Flutterwave API | Direct API call via `payment_metrics` | 99.5% (per Flutterwave SLA) |
| AWS S3 | SDK upload/download test | 99.99% (per AWS SLA) |

---

## 2. Metrics Collected

### 2.1 API Latency Metrics (`api_latency_metrics`)

Collected for every API request routed through the platform.

| Field | Type | Description |
|-------|------|-------------|
| `endpoint` | TEXT | API endpoint path (e.g., `/api/v1/questions`, `/webhooks/flutterwave`) |
| `method` | TEXT | HTTP method (GET, POST, PUT, DELETE) |
| `status_code` | INT | HTTP response status code |
| `response_time_ms` | INT | Response time in milliseconds |
| `request_size_bytes` | BIGINT | Request body size |
| `response_size_bytes` | BIGINT | Response body size |
| `user_id` | UUID | Authenticated user (null for anonymous) |
| `school_id` | UUID | School context |
| `request_id` | TEXT | Correlation ID for distributed tracing |
| `client_ip` | INET | Client IP address |
| `user_agent` | TEXT | Client user agent |
| `error_message` | TEXT | Error details if status >= 400 |

**Key Queries:**

```sql
-- Top 10 slowest endpoints (last 24 hours)
SELECT endpoint, method, AVG(response_time_ms) as avg_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_ms
FROM api_latency_metrics
WHERE created_at > now() - INTERVAL '24 hours'
GROUP BY endpoint, method
ORDER BY p95_ms DESC LIMIT 10;

-- Error rate by endpoint (last hour)
SELECT endpoint,
  COUNT(*) as total,
  SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) as errors,
  ROUND(SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) as error_rate_pct
FROM api_latency_metrics
WHERE created_at > now() - INTERVAL '1 hour'
GROUP BY endpoint
HAVING SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) > 0
ORDER BY error_rate_pct DESC;
```

### 2.2 AI Service Metrics (`ai_service_metrics`)

Collected for every AI provider interaction.

| Field | Type | Description |
|-------|------|-------------|
| `feature` | TEXT | AI feature (`question_generation`, `grading`, `tutoring`) |
| `provider` | TEXT | Provider name (`openai`, `gemini`) |
| `model` | TEXT | Model used (e.g., `gpt-4`, `gemini-pro`) |
| `prompt_tokens` | INT | Tokens in prompt |
| `completion_tokens` | INT | Tokens in completion |
| `total_tokens` | INT | Total tokens used |
| `latency_ms` | INT | Total response time |
| `time_to_first_token_ms` | INT | Time to first token |
| `was_cached` | BOOLEAN | Whether response was served from cache |
| `was_blocked` | BOOLEAN | Whether request was blocked by security |
| `block_reason` | TEXT | Why blocked (e.g., `prompt_injection`) |
| `quality_score` | NUMERIC(3,2) | Output quality score (0-1) |
| `error_message` | TEXT | Error details if failed |

**Key Queries:**

```sql
-- AI cost tracking (last 24 hours)
SELECT provider, model,
  COUNT(*) as requests,
  SUM(total_tokens) as total_tokens,
  SUM(prompt_tokens) as prompt_tokens,
  SUM(completion_tokens) as completion_tokens
FROM ai_service_metrics
WHERE created_at > now() - INTERVAL '24 hours'
GROUP BY provider, model
ORDER BY total_tokens DESC;

-- Prompt injection detection (last 24 hours)
SELECT block_reason, COUNT(*) as blocked_count
FROM ai_service_metrics
WHERE was_blocked = true AND created_at > now() - INTERVAL '24 hours'
GROUP BY block_reason
ORDER BY blocked_count DESC;
```

### 2.3 Authentication Metrics (`auth_metrics`)

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | TEXT | Event type (`login_success`, `login_failure`, `signup`, `password_reset`, `token_refresh`) |
| `auth_method` | TEXT | Method (`email_password`, `google`, `magic_link`) |
| `email` | TEXT | Email attempted (hashed for privacy) |
| `failure_reason` | TEXT | Reason for failure |
| `client_ip` | INET | Client IP address |
| `country_code` | TEXT | GeoIP country |

**Key Queries:**

```sql
-- Login failure analysis (last hour)
SELECT failure_reason, COUNT(*) as count
FROM auth_metrics
WHERE event_type = 'login_failure' AND created_at > now() - INTERVAL '1 hour'
GROUP BY failure_reason
ORDER BY count DESC;

-- Brute force detection
SELECT client_ip, COUNT(*) as failures, MIN(created_at) as first_attempt, MAX(created_at) as last_attempt
FROM auth_metrics
WHERE event_type = 'login_failure' AND created_at > now() - INTERVAL '1 hour'
GROUP BY client_ip
HAVING COUNT(*) > 10
ORDER BY failures DESC;
```

### 2.4 Payment Metrics (`payment_metrics`)

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | TEXT | Event type (`payment_initiated`, `payment_success`, `payment_failed`, `refund_initiated`, etc.) |
| `payment_provider` | TEXT | Provider (`flutterwave`) |
| `amount` | NUMERIC(15,2) | Transaction amount |
| `currency` | TEXT | Currency code (default: `NGN`) |
| `flutterwave_tx_id` | TEXT | Flutterwave transaction ID |
| `failure_reason` | TEXT | Reason for failure |
| `processing_time_ms` | INT | Time to process |

**Key Queries:**

```sql
-- Revenue summary (last 24 hours)
SELECT
  SUM(CASE WHEN event_type = 'payment_success' THEN amount ELSE 0 END) as revenue,
  COUNT(CASE WHEN event_type = 'payment_initiated' THEN 1 END) as initiated,
  COUNT(CASE WHEN event_type = 'payment_success' THEN 1 END) as succeeded,
  COUNT(CASE WHEN event_type = 'payment_failed' THEN 1 END) as failed,
  ROUND(COUNT(CASE WHEN event_type = 'payment_success' THEN 1 END)::NUMERIC /
    NULLIF(COUNT(CASE WHEN event_type = 'payment_initiated' THEN 1 END), 0) * 100, 2) as success_rate_pct
FROM payment_metrics
WHERE created_at > now() - INTERVAL '24 hours';

-- Refund metrics
SELECT event_type, COUNT(*), SUM(amount)
FROM payment_metrics
WHERE event_type IN ('refund_initiated', 'refund_success', 'refund_failed')
  AND created_at > now() - INTERVAL '7 days'
GROUP BY event_type;
```

### 2.5 Server Resource Metrics (`server_resource_metrics`)

| Field | Type | Description |
|-------|------|-------------|
| `host_name` | TEXT | Server hostname |
| `cpu_usage_pct` | NUMERIC(5,2) | CPU usage percentage |
| `memory_usage_pct` | NUMERIC(5,2) | Memory usage percentage |
| `disk_usage_pct` | NUMERIC(5,2) | Disk usage percentage |
| `load_avg_1m` / `load_avg_5m` | NUMERIC(5,2) | Load averages |
| `active_connections` | INT | Active network connections |
| `network_in_bytes` / `network_out_bytes` | BIGINT | Network I/O |

### 2.6 Storage Metrics (`storage_metrics`)

| Field | Type | Description |
|-------|------|-------------|
| `bucket_name` | TEXT | Supabase storage bucket name |
| `total_files` | INT | Total file count |
| `total_size_bytes` | BIGINT | Total storage size |
| `files_added` / `files_deleted` | INT | File change counts |
| `bytes_added` / `bytes_deleted` | BIGINT | Size change |

### 2.7 Performance Metrics (`performance_metrics`)

| Field | Type | Description |
|-------|------|-------------|
| `metric_name` | TEXT | Metric name (`page_load`, `ai_generation`, `payment_processing`) |
| `metric_type` | TEXT | Type (`latency`, `throughput`, `error_rate`, `memory`) |
| `value` | NUMERIC | Metric value |
| `unit` | TEXT | Unit (`ms`, `requests/s`, `mb`, `percentage`) |
| `tags` | JSONB | Key-value tags for filtering |

---

## 3. Dashboard Descriptions

### 3.1 System Overview Dashboard

**Access:** Super admin dashboard → Monitoring → System Overview  
**Data source:** `app_health_checks`, `server_resource_metrics`

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| Service Status | Green/yellow/red status for database, auth, storage, payment, AI | Status (healthy/degraded/down) |
| Response Times | Real-time response time per service | Response time in ms |
| Active Alerts | Currently firing alerts from `alert_state` | Alert name, severity, duration |
| System Uptime | Uptime percentage over last 30 days | Uptime % |
| Request Rate | Requests per minute over last hour | Requests/minute |

### 3.2 API Performance Dashboard

**Data source:** `api_latency_metrics`, `api_latency_summary_24h` view

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| Latency Percentiles | P50, P90, P95, P99 for all endpoints | Milliseconds |
| Error Rate Trend | Error rate over time by endpoint | Percentage |
| Top Slow Endpoints | Endpoints with highest P95 latency | Endpoint, P95 ms |
| Status Code Distribution | 2xx, 4xx, 5xx distribution | Count per status code |
| Throughput | Requests per second by endpoint | Requests/second |

### 3.3 AI Service Dashboard

**Data source:** `ai_service_metrics`, `ai_service_summary_24h` view

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| Token Usage | Total tokens consumed by provider/model | Token count |
| Latency by Feature | AI response time by feature type | Milliseconds |
| Provider Health | Success rate by provider | Percentage |
| Cost Tracking | Estimated cost by provider/model | USD |
| Security Blocks | Prompt injection blocks over time | Blocked count |
| Cache Hit Rate | Percentage of cached responses | Percentage |

### 3.4 Payment Dashboard

**Data source:** `payment_metrics`, `payment_summary_24h` view

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| Revenue Trend | Revenue over time (NGN) | Amount in NGN |
| Transaction Volume | Successful vs failed transactions | Count |
| Flutterwave Health | Payment provider response time and success rate | ms, percentage |
| Refund Metrics | Refund rate and volume | Count, amount |
| Processing Time | Average payment processing duration | Milliseconds |

### 3.5 Security Dashboard

**Data source:** `auth_metrics`, `ai_service_metrics` (blocked), `admin_access_log`

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| Auth Failure Rate | Login failures by reason over time | Count, rate |
| Brute Force Detection | IPs with >10 failures/hour | IP, count |
| Prompt Injection Attempts | AI security blocks over time | Count, type |
| Admin Actions | Recent admin access log entries | Action, user, resource |
| Active Rate Limits | Currently rate-limited identifiers | Identifier, endpoint |

### 3.6 Infrastructure Dashboard

**Data source:** `server_resource_metrics`, `storage_metrics`

| Panel | Description | Key Indicators |
|-------|-------------|----------------|
| CPU Usage | CPU usage percentage over time | Percentage |
| Memory Usage | Memory usage percentage over time | Percentage |
| Disk Usage | Disk usage percentage by host | Percentage |
| Network I/O | Network bytes in/out over time | Bytes/second |
| Storage Buckets | Size and file count per bucket | Count, bytes |
| Active Connections | Network connections over time | Count |

---

## 4. Health Check Endpoints and Interpretation

### 4.1 Primary Health Check Endpoint

**URL:** `GET /functions/v1/health-check`

| Environment | Full URL |
|------------|----------|
| Development | `http://localhost:54321/functions/v1/health-check` |
| Staging | `https://staging.examforge.ai/functions/v1/health-check` |
| Production | `https://examforge.ai/functions/v1/health-check` |

### 4.2 Response Schema

```json
{
  "status": "healthy | degraded | down",
  "timestamp": "ISO 8601 datetime",
  "version": "deploy-ID or 'unknown'",
  "environment": "development | staging | production",
  "services": {
    "database": {
      "status": "healthy | degraded | down",
      "responseTimeMs": 45,
      "error": "optional error message"
    },
    "storage": {
      "status": "healthy | degraded | down",
      "responseTimeMs": 120,
      "buckets": 4
    },
    "auth": {
      "status": "healthy | degraded | down",
      "responseTimeMs": 30
    },
    "payment": {
      "status": "healthy | degraded | down",
      "responseTimeMs": 350,
      "status": 200
    }
  }
}
```

### 4.3 Status Determination Logic

| Service | Healthy | Degraded | Down |
|---------|---------|----------|------|
| **Database** | Response time < 1000ms, no errors | Response time ≥ 1000ms | Query fails or connection refused |
| **Storage** | `listBuckets()` succeeds | — | `listBuckets()` returns error |
| **Auth** | `getSession()` succeeds (or "Auth session missing") | — | Error other than "Auth session missing" |
| **Payment** | Flutterwave API returns 2xx | Flutterwave API returns non-2xx | Flutterwave API unreachable or `FLUTTERWAVE_SECRET_KEY` missing |

**Overall status:**
- `down` if **any** service is down → HTTP 503
- `degraded` if any service is degraded (but none down) → HTTP 200
- `healthy` if all services are healthy → HTTP 200

### 4.4 Health Check Behavior

The health check Edge Function also:

1. **Records results** — Inserts into `app_health_checks` table for each service
2. **Evaluates alerts** — Calls `evaluateAlerts()` which:
   - Creates/updates alerts in `alert_state` for down/degraded services
   - Inserts entries into `alert_history` for new alerts
   - Resolves alerts when services recover
3. **Sets security headers** — HSTS, X-Content-Type-Options, X-Frame-Options, etc.
4. **CORS handling** — Only allows origins matching the environment

### 4.5 Monitoring the Health Check

```bash
# Simple health check
curl -s https://examforge.ai/functions/v1/health-check | jq .

# Check only the overall status
curl -s https://examforge.ai/functions/v1/health-check | jq -r '.status'

# Check specific service
curl -s https://examforge.ai/functions/v1/health-check | jq '.services.database'

# Automated monitoring with alerting
curl -sf https://examforge.ai/functions/v1/health-check > /dev/null || echo "HEALTH CHECK FAILED" | mail -s "ExamForge Alert" ops@examforge.ai
```

### 4.6 Allowed Origins per Environment

| Environment | Allowed Origins |
|------------|----------------|
| Production | `https://examforge.ai`, `https://www.examforge.ai`, `https://app.examforge.ai`, `https://admin.examforge.ai` |
| Staging | `https://staging.examforge.ai`, `https://staging-app.examforge.ai` |
| Development | `http://localhost:3000`, `http://localhost:5173` |

---

## 5. Metric Retention Policies

### 5.1 Retention by Table

| Table | Raw Data Retention | Aggregated Retention | Archival |
|-------|-------------------|---------------------|----------|
| `api_latency_metrics` | 30 days | 2 years (hourly aggregates) | S3 GLACIER after 2 years |
| `ai_service_metrics` | 90 days | 2 years (daily aggregates) | S3 GLACIER after 2 years |
| `auth_metrics` | 90 days | 2 years (daily aggregates) | S3 GLACIER after 2 years |
| `payment_metrics` | 7 years (regulatory) | N/A (keep raw) | S3 GLACIER after 1 year |
| `server_resource_metrics` | 14 days | 1 year (hourly aggregates) | Deleted after 1 year |
| `storage_metrics` | 30 days | 1 year (daily aggregates) | Deleted after 1 year |
| `app_health_checks` | 30 days | 1 year (hourly aggregates) | Deleted after 1 year |
| `performance_metrics` | 30 days | 1 year (daily aggregates) | Deleted after 1 year |
| `alert_history` | 2 years | N/A (keep raw) | S3 GLACIER after 2 years |
| `alert_state` | Current only | N/A | N/A |
| `rate_limits` | Current window only | N/A | N/A |

### 5.2 Aggregation Jobs

Run daily via a scheduled Edge Function or PostgreSQL `pg_cron`:

```sql
-- Example: Aggregate API latency metrics (run daily)
INSERT INTO api_latency_metrics_hourly (
  endpoint, method, hour, avg_response_ms, p50_ms, p95_ms, p99_ms,
  total_requests, error_count
)
SELECT
  endpoint, method,
  date_trunc('hour', created_at) as hour,
  AVG(response_time_ms),
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time_ms),
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms),
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_ms),
  COUNT(*),
  SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END)
FROM api_latency_metrics
WHERE created_at > now() - INTERVAL '25 hours'
  AND created_at < now() - INTERVAL '1 hour'
GROUP BY endpoint, method, date_trunc('hour', created_at);

-- Purge raw data older than retention period
DELETE FROM api_latency_metrics WHERE created_at < now() - INTERVAL '30 days';
DELETE FROM auth_metrics WHERE created_at < now() - INTERVAL '90 days';
DELETE FROM server_resource_metrics WHERE recorded_at < now() - INTERVAL '14 days';
DELETE FROM app_health_checks WHERE checked_at < now() - INTERVAL '30 days';
```

### 5.3 Payment Metrics Regulatory Retention

Payment metrics are subject to Nigerian financial regulations and must be retained for **7 years**. The `payment_metrics` table uses a different retention policy:

```sql
-- Do NOT delete payment_metrics within 7 years
-- Archive to S3 after 1 year for cost optimization:
-- 1. Export to CSV/Parquet
-- 2. Upload to s3://examforge-backups-prod/compliance/payment_metrics/
-- 3. Verify the export
-- 4. Only then delete from the database
```

---

## 6. Custom Metric Submission

### 6.1 Via Edge Function (Service Role)

```typescript
// In any Supabase Edge Function
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

// Submit a performance metric
await supabase.from('performance_metrics').insert({
  metric_name: 'cbt_exam_duration',
  metric_type: 'latency',
  value: 3500,
  unit: 'ms',
  tags: { exam_type: 'waec', subject: 'mathematics' },
  school_id: schoolId,
  user_id: userId,
});
```

### 6.2 Via Flutter Client (Authenticated User)

```dart
// In the Flutter app, using the Supabase client
await SupabaseConfig.client.from('performance_metrics').insert({
  'metric_name': 'page_load_time',
  'metric_type': 'latency',
  'value': 1200,
  'unit': 'ms',
  'tags': {'page': 'cbt_exam', 'connection': '3g'},
  'user_id': SupabaseConfig.currentUser?.id,
  'school_id': schoolId,
});
```

> **Note:** Client-side metric submissions are subject to RLS policies. Only authenticated users can insert metrics for their own school context.

### 6.3 Via Direct Database Insert (Server-Side)

```sql
-- Insert a custom metric directly (requires service_role or monitoring_agent role)
INSERT INTO performance_metrics (metric_name, metric_type, value, unit, tags, school_id)
VALUES ('cache_hit_rate', 'throughput', 87.5, 'percentage', '{"cache_type": "api_response"}', 'school-uuid');
```

### 6.4 Metric Naming Conventions

| Pattern | Example | Use Case |
|---------|---------|----------|
| `<feature>_<metric>` | `cbt_exam_duration` | Feature-specific latency |
| `<service>_<operation>` | `storage_upload_size` | Service operation metric |
| `<feature>_<counter>` | `ai_generation_total` | Feature usage counter |
| `<system>_<resource>` | `database_pool_active` | System resource metric |

### 6.5 Tag Guidelines

Tags are stored as JSONB in the `tags` column. Use these standard tag keys:

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `page` | Application page | `cbt_exam`, `dashboard`, `marketplace` |
| `connection` | Network type | `wifi`, `4g`, `3g`, `offline` |
| `provider` | Service provider | `openai`, `gemini`, `flutterwave` |
| `exam_type` | Examination body | `waec`, `neco`, `jamb_utme` |
| `subject` | Subject | `mathematics`, `english` |
| `cache_type` | Cache category | `api_response`, `ai_result`, `image` |
| `platform` | Client platform | `web`, `android`, `ios` |
| `error_type` | Error category | `timeout`, `auth_failure`, `rate_limit` |

### 6.6 Querying Custom Metrics

```sql
-- Query metrics by name and tags
SELECT metric_name, AVG(value) as avg_value, MIN(value) as min_value, MAX(value) as max_value
FROM performance_metrics
WHERE metric_name = 'cbt_exam_duration'
  AND tags->>'exam_type' = 'waec'
  AND recorded_at > now() - INTERVAL '7 days'
GROUP BY metric_name;

-- Query with time bucketing
SELECT
  date_trunc('hour', recorded_at) as hour,
  AVG(value) as avg_duration_ms
FROM performance_metrics
WHERE metric_name = 'page_load_time'
  AND recorded_at > now() - INTERVAL '24 hours'
GROUP BY date_trunc('hour', recorded_at)
ORDER BY hour;
```

---

## Appendix A: Monitoring Database Views

| View | Purpose | Source Tables |
|------|---------|---------------|
| `api_latency_summary_24h` | API latency percentiles by endpoint | `api_latency_metrics` |
| `ai_service_summary_24h` | AI token usage, latency, errors by provider | `ai_service_metrics` |
| `auth_summary_24h` | Auth event counts by type and method | `auth_metrics` |
| `payment_summary_24h` | Payment event counts and amounts | `payment_metrics` |

## Appendix B: Alert Configuration Quick Reference

See `supabase/migrations/alerting_configuration.sql` for the full list of alert rules. Key alerts:

| Alert | Severity | Condition | Evaluation Window |
|-------|----------|-----------|-------------------|
| `database_down` | Critical | DB health check fails | 60 seconds |
| `payment_provider_down` | Critical | >5 payment errors | 5 minutes |
| `security_breach_detected` | Critical | >50 auth failures | 5 minutes |
| `high_error_rate` | High | API error rate >5% | 5 minutes |
| `high_api_latency` | High | P95 >2000ms | 5 minutes |
| `ai_provider_failures` | High | AI error rate >15% | 5 minutes |
| `moderate_api_latency` | Warning | P95 >1000ms | 5 minutes |
| `cpu_spike` | Warning | CPU >80% | 5 minutes |
| `disk_space_low` | Warning | Disk >80% full | 10 minutes |
