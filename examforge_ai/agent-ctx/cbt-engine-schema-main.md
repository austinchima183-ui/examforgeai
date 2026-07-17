# CBT Engine Schema - Work Record

## Task ID: cbt-engine-schema
## Agent: main
## Date: 2024-01-15

## Summary
Created the comprehensive, production-ready CBT Engine SQL schema at `/home/z/my-project/examforge_ai/supabase/migrations/cbt_engine_schema.sql`.

## What Was Done

### 1. Analyzed Existing Schema
- Read `supabase/schema.sql` - base schema with schools, users, classes, subjects, notifications, audit_log
- Read `supabase/migrations/question_bank_schema.sql` - question_bank, answer_options, academic_sessions, topics, subtopics, matching_pairs, ordering_items, fill_in_blank_answers
- Read `supabase/migrations/ai_generator_schema.sql` - AI generation engine tables
- Identified existing enums: user_role, subscription_status, exam_status, exam_type, question_type, difficulty_level, notification_type, etc.

### 2. Created CBT Engine Schema (3,118 lines)

#### Enums (6 new + 1 extended)
- Extended `exam_status` with 'cancelled'
- Created `attempt_status`, `submission_type`, `grading_status`, `monitoring_event_type`, `notification_category`

#### Tables (12)
1. **exams** - Core exam definitions with scheduling, anti-cheating, result visibility, templates
2. **exam_sections** - Logical sections within exams
3. **exam_questions** - Junction: questions assigned to exams with mark overrides
4. **exam_students** - Eligible students with accommodations
5. **exam_attempts** - Student attempt tracking with auto-save
6. **student_answers** - Flexible JSONB answer storage
7. **exam_sessions** - REALTIME live monitoring
8. **exam_monitoring_logs** - Anti-cheating event logs
9. **exam_results** - Processed results with grades and release status
10. **exam_rankings** - Pre-computed rankings
11. **exam_notifications** - CBT-specific lifecycle notifications
12. **grade_scales** - Configurable grading with JSONB boundaries

#### Indexes (62)
- Single-column indexes for FK joins
- Composite indexes for common query patterns
- Partial indexes for high-frequency monitoring queries
- GIN indexes for JSONB and array columns

#### Functions (9 user-facing + 8 trigger)
1. `check_exam_access()` - Validate student exam access
2. `start_exam_attempt()` - Create attempt + session
3. `auto_grade_attempt()` - Auto-grade objective questions
4. `submit_exam_attempt()` - Submit, grade, create result
5. `calculate_rankings()` - Compute and store rankings
6. `release_results()` - Release results to students
7. `get_exam_statistics()` - Aggregate stats as JSONB
8. `cleanup_stale_sessions()` - Close stale sessions
9. `generate_exam_notification()` - Create lifecycle notifications
10. `apply_grade_scale()` - Apply grade scale to results (bonus)

#### Triggers (14)
- Auto-update updated_at
- Auto-calculate total_marks on exam_questions changes
- Propagate attempt updates to sessions (Realtime)
- Auto-create exam_result on attempt submission
- Auto-send notifications on exam status change
- Auto-calculate score_percentage/is_passed on result update
- Update exam_students timestamps on attempt changes
- Set published_at on exam publish
- Enforce single default grade scale per school

#### RLS Policies (59)
- Super admins: full access to all tables
- School admins: CRUD within their school
- Teachers: CRUD on own exams, read/update on related data
- Students: read assigned exams, manage own attempts/answers, read own released results
- Students CANNOT read monitoring logs

#### Supabase Realtime
- exam_sessions, exam_attempts, exam_monitoring_logs added to supabase_realtime publication

## Files Created
- `/home/z/my-project/examforge_ai/supabase/migrations/cbt_engine_schema.sql`
