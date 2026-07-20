# ExamForge AI — API Documentation

> **Curriculum Content Management System (CCMS) & Enterprise API Reference**
> Complete reference for all Supabase RPC functions, CRUD endpoints, authentication, and security.

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Rate Limiting](#rate-limiting)
4. [RPC Functions](#rpc-functions)
5. [Table CRUD Endpoints](#table-crud-endpoints)
6. [Request/Response Formats](#requestresponse-formats)
7. [Error Codes](#error-codes)
8. [Webhook Patterns](#webhook-patterns)

---

## Overview

The ExamForge AI backend is powered by **Supabase**, which provides:

- **PostgreSQL database** with Row Level Security (RLS)
- **Auto-generated REST API** for all tables (PostgREST)
- **RPC (Remote Procedure Call)** endpoints for custom SQL functions
- **Real-time subscriptions** via WebSocket
- **Authentication** via Supabase Auth (email/password, OAuth, MFA)
- **Storage** for file uploads (documents, images, media)

### Base URL

```
https://<project-ref>.supabase.co/rest/v1
```

### Common Headers

```http
apikey: <your-anon-key-or-service-key>
Authorization: Bearer <user-access-token>
Content-Type: application/json
Prefer: return=representation
```

---

## Authentication

### Authentication Methods

| Method | Description |
|--------|-------------|
| Email/Password | Standard email and password login via Supabase Auth |
| OAuth | Google, Apple, Microsoft providers |
| MFA | SMS, email, authenticator app, hardware key |
| API Keys | Scoped API keys with rate limit overrides |

### Role-Based Access

The system uses a `role` field in `auth.users.raw_user_meta_data` to determine access levels:

| Role | Access Level |
|------|-------------|
| `superAdmin` | Full platform access, all schools, security, monitoring |
| `schoolAdmin` | School-scoped admin, curriculum management, user management |
| `teacher` | Content creation, review, AI generation |
| `student` | Read-only access to published content, practice mode |
| `parent` | Read-only access to child's curriculum and progress |

### Row Level Security (RLS)

All tables have RLS enabled. Access policies are summarized below:

| Table | Read Access | Write Access |
|-------|-----------|-------------|
| `educational_levels` | All authenticated users | Super admins only |
| `school_level_configurations` | School members | School admins |
| `curricula` | All authenticated users | Admins |
| `subjects` | School members | Admins |
| `topics` | School members | Teachers and admins |
| `content_items` | Published content or school members | Creators and admins |
| `content_reviews` | Via content access | Reviewers (teachers+) |
| `content_collections` | Public or school members | Creators and admins |
| `ai_curriculum_configs` | School members | Admins |
| `audit_trail` | Super admins only | System (insert only) |
| `security_events` | Super admins only | System (insert only) |
| `user_sessions` | Own sessions only | Owner or super admin |
| `system_metrics` | Admins | System |
| `performance_logs` | Super admins only | System |

### Obtaining an Access Token

```bash
# Sign in with email/password
curl -X POST 'https://<project-ref>.supabase.co/auth/v1/token?grant_type=password' \
  -H 'apikey: <anon-key>' \
  -H 'Content-Type: application/json' \
  -d '{"email": "teacher@school.edu.ng", "password": "securepassword"}'
```

Response:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "uuid",
    "email": "teacher@school.edu.ng",
    "role": "teacher",
    "raw_user_meta_data": {
      "role": "teacher",
      "school_id": "uuid"
    }
  }
}
```

---

## Rate Limiting

Rate limiting is enforced at the database level via the `check_rate_limit` RPC function and at the API gateway level.

### Rate Limit Scopes

| Scope | Description |
|-------|-------------|
| `global` | Platform-wide limits |
| `per_user` | Per authenticated user |
| `per_ip` | Per IP address |
| `per_api_key` | Per API key |
| `per_endpoint` | Per specific API endpoint |

### Default Limits

| Scope | Limit | Window |
|-------|-------|--------|
| `global` | 10,000 req/min | 60 seconds |
| `per_user` | 1,000 req/min | 60 seconds |
| `per_ip` | 500 req/min | 60 seconds |
| `per_api_key` | Configurable | Configurable |

### Rate Limit Headers

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 942
X-RateLimit-Reset: 1677654321
```

When rate-limited, the API returns:

```json
{
  "code": 429,
  "message": "Rate limit exceeded",
  "retry_after": 45
}
```

---

## RPC Functions

### `get_school_levels`

Retrieves all educational levels with their enablement status for a specific school.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_school_id` | UUID | Yes | The school ID |

**Returns:** Table of levels with enablement info

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Level ID |
| `code` | TEXT | Level code (e.g., `primary_1`) |
| `name` | TEXT | Display name (e.g., "Primary 1") |
| `level_category` | level_category_type | Category enum |
| `level_order` | INT | Sort order |
| `min_age` | INT | Minimum age |
| `max_age` | INT | Maximum age |
| `description` | TEXT | Level description |
| `is_enabled` | BOOLEAN | Whether enabled for this school |
| `custom_name` | TEXT | School-specific name override |

**Example:**

```bash
curl -X POST 'https://<project-ref>.supabase.co/rest/v1/rpc/get_school_levels' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{"p_school_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"}'
```

**Response:**

```json
[
  {
    "id": "uuid-1",
    "code": "nursery",
    "name": "Nursery",
    "level_category": "early_childhood",
    "level_order": 1,
    "min_age": 2,
    "max_age": 4,
    "description": "Pre-primary nursery education",
    "is_enabled": true,
    "custom_name": "Pre-School"
  },
  {
    "id": "uuid-2",
    "code": "primary_1",
    "name": "Primary 1",
    "level_category": "primary",
    "level_order": 3,
    "min_age": 5,
    "max_age": 7,
    "description": "First year of primary education",
    "is_enabled": true,
    "custom_name": null
  }
]
```

---

### `get_level_subjects`

Retrieves all subjects available for a school at a specific educational level.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_school_id` | UUID | Yes | The school ID |
| `p_educational_level_id` | UUID | Yes | The educational level ID |

**Returns:** Table of subjects

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Subject ID |
| `name` | TEXT | Subject name |
| `code` | TEXT | Subject code |
| `subject_group` | TEXT | Group (language, science, etc.) |
| `is_core` | BOOLEAN | Whether it is a core subject |
| `is_elective` | BOOLEAN | Whether it is elective |
| `is_vocational` | BOOLEAN | Whether it is vocational |
| `description` | TEXT | Subject description |
| `icon_url` | TEXT | Icon URL |
| `color_code` | TEXT | Display color |
| `is_custom` | BOOLEAN | Whether school-created |

**Example:**

```bash
curl -X POST 'https://<project-ref>.supabase.co/rest/v1/rpc/get_level_subjects' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "p_school_id": "school-uuid",
    "p_educational_level_id": "level-uuid"
  }'
```

---

### `get_curriculum_tree`

Returns the full hierarchical curriculum tree for a subject: topics → subtopics → learning objectives.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_subject_id` | UUID | Yes | Subject ID |
| `p_educational_level_id` | UUID | No | Optional level filter |

**Returns:** JSONB array of nested objects

```json
[
  {
    "topic": {
      "id": "uuid",
      "title": "Number and Numeration",
      "code": "MATH-01",
      "sort_order": 1,
      "estimated_duration_minutes": 90
    },
    "subtopics": [
      {
        "subtopic": {
          "id": "uuid",
          "title": "Place Value",
          "sort_order": 1
        },
        "learning_objectives": [
          {
            "id": "uuid",
            "code": "MATH-LO-01",
            "description": "Students can identify place values up to billions",
            "bloom_level": "remember",
            "is_assessable": true
          }
        ]
      }
    ],
    "learning_objectives": [
      {
        "id": "uuid",
        "code": "MATH-LO-00",
        "description": "Students understand the decimal number system",
        "bloom_level": "understand"
      }
    ]
  }
]
```

---

### `get_content_with_details`

Retrieves content items with joined subject, level, and topic names.

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `p_subject_id` | UUID | No | NULL | Filter by subject |
| `p_educational_level_id` | UUID | No | NULL | Filter by level |
| `p_topic_id` | UUID | No | NULL | Filter by topic |
| `p_content_type` | content_type_enum | No | NULL | Filter by type |
| `p_difficulty_level` | difficulty_level_type | No | NULL | Filter by difficulty |
| `p_status` | content_status_type | No | NULL | Filter by status |
| `p_limit` | INT | No | 50 | Max results |
| `p_offset` | INT | No | 0 | Pagination offset |

**Returns:** Table with enriched content data

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Content item ID |
| `title` | TEXT | Content title |
| `content_type` | content_type_enum | Type of content |
| `subject_name` | TEXT | Joined subject name |
| `level_name` | TEXT | Joined level name |
| `topic_title` | TEXT | Joined topic title |
| `difficulty_level` | difficulty_level_type | Difficulty |
| `bloom_level` | bloom_taxonomy_type | Bloom's taxonomy level |
| `status` | content_status_type | Publication status |
| `version` | INT | Current version number |
| `usage_count` | INT | Times used |
| `average_quality_score` | DECIMAL | Quality score (1-5) |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

---

### `get_ccms_stats`

Returns aggregate statistics for the CCMS module, optionally filtered by school.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_school_id` | UUID | No | School ID for scoped stats |

**Returns:** JSONB object

```json
{
  "total_subjects": 45,
  "total_topics": 320,
  "total_content": 12500,
  "published_content": 8200,
  "draft_content": 3100,
  "ai_generated_content": 2800,
  "past_questions": 1500,
  "avg_quality_score": 3.85,
  "total_imports": 28,
  "total_collections": 65,
  "pending_reviews": 142,
  "content_by_type": {
    "question": 7500,
    "explanation": 2500,
    "marking_scheme": 1500,
    "teacher_note": 500,
    "lesson_note": 300,
    "worksheet": 200
  },
  "content_by_difficulty": {
    "beginner": 2200,
    "elementary": 3100,
    "intermediate": 3800,
    "advanced": 2400,
    "expert": 1000
  }
}
```

---

### `record_audit_event`

Records an audit trail entry. Called internally by the system for all significant actions.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_user_id` | UUID | No | Acting user |
| `p_school_id` | UUID | No | Affected school |
| `p_action` | audit_action_type | Yes | Action performed |
| `p_resource_type` | TEXT | Yes | Resource type |
| `p_resource_id` | UUID | No | Resource ID |
| `p_old_values` | JSONB | No | Before-state snapshot |
| `p_new_values` | JSONB | No | After-state snapshot |
| `p_ip_address` | INET | No | Client IP |
| `p_user_agent` | TEXT | No | Client user agent |
| `p_device_id` | TEXT | No | Device identifier |
| `p_session_id` | TEXT | No | Session identifier |
| `p_metadata` | JSONB | No | Additional metadata |

**Returns:** UUID of the created audit entry

**Security:** This function is `SECURITY DEFINER`, meaning it runs with elevated privileges to allow audit inserts regardless of RLS.

---

### `record_security_event`

Records a security incident for monitoring and response.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_event_type` | TEXT | Yes | Event type (e.g., `brute_force`, `suspicious_login`) |
| `p_severity` | TEXT | No | `info`, `warning`, `critical`, `emergency` (default: `medium`) |
| `p_user_id` | UUID | No | Associated user |
| `p_school_id` | UUID | No | Associated school |
| `p_ip_address` | INET | No | Client IP |
| `p_user_agent` | TEXT | No | Client user agent |
| `p_details` | JSONB | No | Additional details |

**Returns:** UUID of the created security event

---

### `check_rate_limit`

Checks whether a request is within rate limits before processing.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_scope` | rate_limit_scope_type | Yes | Scope (global, per_user, per_ip, per_api_key, per_endpoint) |
| `p_identifier` | TEXT | Yes | Identifier within scope |
| `p_endpoint` | TEXT | No | Specific endpoint (default: `*`) |

**Returns:** Table with three columns

| Column | Type | Description |
|--------|------|-------------|
| `allowed` | BOOLEAN | Whether the request is allowed |
| `remaining` | INT | Remaining requests in window |
| `reset_at` | TIMESTAMPTZ | When the window resets |

**Example:**

```bash
curl -X POST 'https://<project-ref>.supabase.co/rest/v1/rpc/check_rate_limit' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -d '{"p_scope": "per_user", "p_identifier": "user-uuid", "p_endpoint": "/rest/v1/content_items"}'
```

**Response:**

```json
[{"allowed": true, "remaining": 942, "reset_at": "2024-01-15T10:31:00Z"}]
```

---

### `invalidate_user_sessions`

Invalidates active user sessions for security operations (password change, MFA enable, etc.).

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_user_id` | UUID | Yes | User whose sessions to invalidate |
| `p_except_session_id` | UUID | No | Session to keep active (current session) |
| `p_invalidated_by` | UUID | No | Admin who triggered invalidation |

**Returns:** INT — number of sessions invalidated

---

### `increment_content_usage`

Increments the usage counter for a content item. Called when content is used in an exam, practice session, or export.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_content_id` | UUID | Yes | Content item ID |

**Returns:** VOID

---

### `create_audit_partition_if_not_exists`

Creates a monthly partition for the `audit_trail` table if it does not already exist. Called by scheduled maintenance jobs.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `p_year` | INT | Yes | Year (e.g., 2024) |
| `p_month` | INT | Yes | Month (1-12) |

**Returns:** VOID

---

### `clean_old_metrics`

Deletes system metrics older than the retention period.

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `p_days_to_retain` | INT | No | 90 | Days to retain |

**Returns:** INT — number of rows deleted

---

### `clean_old_audit_trail`

Deletes audit trail entries older than the retention period.

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `p_days_to_retain` | INT | No | 365 | Days to retain |

**Returns:** INT — number of rows deleted

---

### `clean_old_performance_logs`

Deletes performance log entries older than the retention period.

**Parameters:**

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `p_days_to_retain` | INT | No | 30 | Days to retain |

**Returns:** INT — number of rows deleted

---

## Table CRUD Endpoints

All tables support standard Supabase/PostgREST CRUD operations. The following tables are available:

### Core CCMS Tables

| Table | Endpoint | Description |
|-------|----------|-------------|
| `educational_levels` | `/rest/v1/educational_levels` | Nigerian educational levels |
| `school_level_configurations` | `/rest/v1/school_level_configurations` | Per-school level settings |
| `curricula` | `/rest/v1/curricula` | Curriculum definitions |
| `curriculum_versions` | `/rest/v1/curriculum_versions` | Curriculum version history |
| `curriculum_level_mappings` | `/rest/v1/curriculum_level_mappings` | Curriculum-level associations |
| `subjects` | `/rest/v1/subjects` | Subject definitions |
| `topics` | `/rest/v1/topics` | Topic hierarchy |
| `subtopics` | `/rest/v1/subtopics` | Subtopics |
| `learning_objectives` | `/rest/v1/learning_objectives` | Learning objectives |
| `content_items` | `/rest/v1/content_items` | Central content table |
| `content_versions` | `/rest/v1/content_versions` | Content version history |
| `content_reviews` | `/rest/v1/content_reviews` | Quality reviews |
| `content_imports` | `/rest/v1/content_imports` | Bulk import tracking |
| `content_collections` | `/rest/v1/content_collections` | Content collections |
| `content_collection_items` | `/rest/v1/content_collection_items` | Collection-item links |
| `ai_curriculum_configs` | `/rest/v1/ai_curriculum_configs` | AI engine configuration |
| `ai_generation_rules` | `/rest/v1/ai_generation_rules` | AI generation rules |
| `answer_repository` | `/rest/v1/answer_repository` | Answer data with explanations |

### Enterprise Tables

| Table | Endpoint | Description |
|-------|----------|-------------|
| `audit_trail` | `/rest/v1/audit_trail` | Comprehensive audit log |
| `mfa_configurations` | `/rest/v1/mfa_configurations` | MFA settings |
| `api_keys` | `/rest/v1/api_keys` | API key management |
| `rate_limit_configs` | `/rest/v1/rate_limit_configs` | Rate limit settings |
| `rate_limit_counters` | `/rest/v1/rate_limit_counters` | Rate limit counters |
| `security_events` | `/rest/v1/security_events` | Security incidents |
| `user_sessions` | `/rest/v1/user_sessions` | Active sessions |
| `encryption_key_metadata` | `/rest/v1/encryption_key_metadata` | Encryption key info |
| `system_metrics` | `/rest/v1/system_metrics` | Platform metrics |
| `alert_rules` | `/rest/v1/alert_rules` | Alert configurations |
| `alert_incidents` | `/rest/v1/alert_incidents` | Fired alerts |
| `performance_logs` | `/rest/v1/performance_logs` | Performance tracking |
| `error_reports` | `/rest/v1/error_reports` | Error tracking |
| `deployments` | `/rest/v1/deployments` | CI/CD tracking |
| `deployment_steps` | `/rest/v1/deployment_steps` | Deployment step detail |
| `test_results` | `/rest/v1/test_results` | Test execution results |
| `test_suites` | `/rest/v1/test_suites` | Test suite summaries |
| `database_migrations` | `/rest/v1/database_migrations` | Migration tracking |
| `backup_records` | `/rest/v1/backup_records` | Backup tracking |

### CRUD Operations

#### SELECT (Read)

```bash
# Get all published content for a subject
curl 'https://<project-ref>.supabase.co/rest/v1/content_items?subject_id=eq.uuid&status=eq.published&select=id,title,difficulty_level,bloom_level' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>'
```

**Query Operators:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `eq` | Equals | `status=eq.published` |
| `neq` | Not equals | `status=neq.archived` |
| `gt` | Greater than | `usage_count=gt.100` |
| `gte` | Greater than or equal | `quality_score=gte.3.5` |
| `lt` | Less than | `created_at=lt.2024-01-01` |
| `like` | Pattern match | `title=like.*algebra*` |
| `ilike` | Case-insensitive pattern | `title=ilike.*Algebra*` |
| `in` | In list | `difficulty_level=in.(beginner,elementary)` |
| `is` | Is null / true | `reviewed_by=is.null` |
| `cs` | Contains (array) | `tags=cs.{mathematics}` |
| `cd` | Contained by | `tags=cd.{mathematics,algebra}` |

#### INSERT (Create)

```bash
curl -X POST 'https://<project-ref>.supabase.co/rest/v1/content_items' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -H 'Prefer: return=representation' \
  -d '{
    "title": "Solve for x: 2x + 5 = 15",
    "content_type": "question",
    "subject_id": "subject-uuid",
    "educational_level_id": "level-uuid",
    "difficulty_level": "elementary",
    "bloom_level": "apply",
    "body": "Solve for x: 2x + 5 = 15",
    "options": [
      {"label": "A", "text": "x = 3"},
      {"label": "B", "text": "x = 5"},
      {"label": "C", "text": "x = 7"},
      {"label": "D", "text": "x = 10"}
    ],
    "correct_answer": {"label": "B", "text": "x = 5"},
    "step_by_step_explanation": "Step 1: Subtract 5 from both sides: 2x = 10\nStep 2: Divide both sides by 2: x = 5",
    "marks_allocated": 2,
    "status": "draft",
    "source_type": "school_created",
    "school_id": "school-uuid"
  }'
```

#### UPDATE

```bash
curl -X PATCH 'https://<project-ref>.supabase.co/rest/v1/content_items?id=eq.uuid' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -H 'Prefer: return=representation' \
  -d '{"status": "published", "published_at": "now()"}'
```

#### DELETE

```bash
curl -X DELETE 'https://<project-ref>.supabase.co/rest/v1/content_items?id=eq.uuid' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>'
```

---

## Request/Response Formats

### Content Item (Full)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Solve for x: 2x + 5 = 15",
  "content_type": "question",
  "subject_id": "subject-uuid",
  "educational_level_id": "level-uuid",
  "topic_id": "topic-uuid",
  "subtopic_id": null,
  "curriculum_id": "curriculum-uuid",
  "school_id": "school-uuid",
  "question_category": "objective",
  "difficulty_level": "elementary",
  "bloom_level": "apply",
  "body": "Solve for x: 2x + 5 = 15",
  "body_rich": {"blocks": [{"type": "paragraph", "data": "Solve for x: 2x + 5 = 15"}]},
  "options": [
    {"label": "A", "text": "x = 3"},
    {"label": "B", "text": "x = 5"},
    {"label": "C", "text": "x = 7"},
    {"label": "D", "text": "x = 10"}
  ],
  "correct_answer": {"label": "B", "text": "x = 5"},
  "step_by_step_explanation": "Step 1: Subtract 5 from both sides...",
  "marking_scheme": {"method": "exact_match", "marks": {"B": 2}},
  "teacher_notes": "Common mistake: students add 5 instead of subtracting",
  "learning_objective_ids": ["lo-uuid-1"],
  "curriculum_references": [{"body": "NERDC", "year": 2022, "section": "MATH-SS1-02"}],
  "marks_allocated": 2,
  "time_allocated_seconds": 120,
  "source_type": "school_created",
  "source_reference": null,
  "is_past_question": false,
  "past_exam_year": null,
  "past_exam_body": null,
  "has_licensing_rights": false,
  "license_details": {},
  "tags": ["algebra", "linear-equations"],
  "media_urls": [],
  "status": "published",
  "version": 1,
  "parent_content_id": null,
  "review_count": 2,
  "average_quality_score": 4.25,
  "usage_count": 156,
  "is_ai_generated": false,
  "ai_generation_metadata": {},
  "metadata": {},
  "created_by": "user-uuid",
  "reviewed_by": "reviewer-uuid",
  "published_at": "2024-01-10T08:30:00Z",
  "created_at": "2024-01-08T14:00:00Z",
  "updated_at": "2024-01-10T08:30:00Z"
}
```

### Pagination

Use `Range` header for pagination:

```bash
# Get items 21-40 (page 2 with page size 20)
curl 'https://<project-ref>.supabase.co/rest/v1/content_items?select=*&order=created_at.desc' \
  -H 'apikey: <anon-key>' \
  -H 'Authorization: Bearer <token>' \
  -H 'Range: 20-39'
```

Response includes `Content-Range` header:

```
Content-Range: 20-39/12500
```

---

## Error Codes

### HTTP Status Codes

| Code | Meaning | Common Cause |
|------|---------|-------------|
| 200 | OK | Successful GET or PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid JSON, missing required fields |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient role/permissions (RLS) |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Unique constraint violation |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

### Supabase Error Format

```json
{
  "code": "42501",
  "message": "new row violates row-level security policy for table \"content_items\"",
  "details": null,
  "hint": null
}
```

### Common Database Error Codes

| Code | Description |
|------|-------------|
| `23505` | Unique constraint violation (duplicate entry) |
| `23503` | Foreign key constraint violation (referenced record not found) |
| `23514` | Check constraint violation (value out of range) |
| `42501` | RLS policy violation (insufficient permissions) |
| `P0001` | Raise exception from PL/pgSQL function |
| `PGRST116` | Resource not found (single row expected, none returned) |

### Application-Level Error Codes

| Code | Description |
|------|-------------|
| `AUTH_INVALID_CREDENTIALS` | Email or password is incorrect |
| `AUTH_SESSION_EXPIRED` | Session token has expired |
| `AUTH_MFA_REQUIRED` | MFA verification is required |
| `CONTENT_NOT_FOUND` | Content item does not exist |
| `CONTENT_ALREADY_PUBLISHED` | Content is already in published state |
| `CONTENT_REVIEW_PENDING` | Content has pending reviews |
| `IMPORT_IN_PROGRESS` | Import operation is already running |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `INSUFFICIENT_PERMISSIONS` | User lacks required role |
| `SCHOOL_NOT_CONFIGURED` | School has no levels configured |
| `AI_GENERATION_FAILED` | AI content generation failed |
| `VALIDATION_ERROR` | Input validation failed |

---

## Webhook Patterns

### Available Webhooks

| Event | Trigger | Payload |
|-------|---------|---------|
| `content.published` | Content item status changes to `published` | Content item object |
| `content.review_requested` | Content submitted for review | Content item + reviewer info |
| `import.completed` | Bulk import finishes | Import stats |
| `security.alert` | Security event with severity ≥ `critical` | Security event object |
| `alert.fired` | Monitoring alert triggers | Alert incident object |
| `deployment.completed` | Deployment finishes | Deployment object |

### Webhook Registration

Webhooks are registered via the Supabase Edge Functions or the `alert_rules.notification_channels` field:

```json
{
  "notification_channels": ["email:admin@school.edu.ng", "webhook:https://your-server.com/hook"]
}
```

### Webhook Payload Example

```json
{
  "event": "content.published",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "id": "content-uuid",
    "title": "Solve for x: 2x + 5 = 15",
    "content_type": "question",
    "subject_name": "Mathematics",
    "level_name": "Primary 5",
    "published_by": "teacher-uuid",
    "school_id": "school-uuid"
  },
  "signature": "sha256=abcdef1234567890..."
}
```

### Webhook Verification

Always verify webhook signatures:

```dart
import 'package:crypto/crypto.dart';

bool verifyWebhookSignature(String payload, String signature, String secret) {
  final key = utf8.encode(secret);
  final bytes = utf8.encode(payload);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);
  final expected = 'sha256=${digest.toString()}';
  return signature == expected;
}
```

### Retry Policy

Failed webhook deliveries are retried with exponential backoff:

| Attempt | Delay |
|---------|-------|
| 1 | Immediate |
| 2 | 1 minute |
| 3 | 5 minutes |
| 4 | 30 minutes |
| 5 | 2 hours |

After 5 failed attempts, the webhook is marked as failed and an alert is generated.

---

## Appendix: Enum Reference

### `educational_level_type`

`nursery`, `kindergarten`, `primary_1` through `primary_6`, `jss_1` through `jss_3`, `ss_1` through `ss_3`, `technical_1` through `technical_3`, `college_of_education_1` through `college_of_education_3`, `university_100` through `university_600`

### `level_category_type`

`early_childhood`, `primary`, `junior_secondary`, `senior_secondary`, `technical`, `tertiary_college`, `tertiary_university`

### `curriculum_type`

`nerdc`, `waec`, `neco`, `nabteb`, `custom`, `international`

### `content_status_type`

`draft`, `review`, `published`, `archived`, `deprecated`

### `content_type_enum`

`question`, `explanation`, `marking_scheme`, `teacher_note`, `lesson_note`, `worksheet`, `practical_guide`, `reading_material`, `video_script`, `assessment_rubric`

### `question_category_type`

`objective`, `theory`, `practical`, `oral`, `project`, `essay`, `fill_in_blank`, `true_false`, `matching`, `ordering`, `multiple_choice`

### `difficulty_level_type`

`beginner`, `elementary`, `intermediate`, `advanced`, `expert`

### `bloom_taxonomy_type`

`remember`, `understand`, `apply`, `analyze`, `evaluate`, `create`

### `audit_action_type`

`create`, `read`, `update`, `delete`, `login`, `logout`, `export`, `import`, `approve`, `reject`, `archive`, `restore`, `permission_change`, `role_change`, `password_change`, `mfa_enable`, `mfa_disable`, `session_invalidate`, `api_key_create`, `api_key_revoke`

### `mfa_method_type`

`sms`, `email`, `authenticator_app`, `hardware_key`

### `rate_limit_scope_type`

`global`, `per_user`, `per_ip`, `per_api_key`, `per_endpoint`

### `alert_severity_type`

`info`, `warning`, `critical`, `emergency`
