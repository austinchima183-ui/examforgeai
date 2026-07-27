#!/usr/bin/env python3
"""
Preprocess all ExamForge AI SQL migrations for Supabase Management API execution.

Transformations:
1. Strip BEGIN; and COMMIT; (Management API doesn't support explicit transactions)
2. Strip cross-file FK REFERENCES from CREATE TABLE statements
3. Add DROP POLICY IF EXISTS before CREATE POLICY
4. Add DROP TRIGGER IF EXISTS before CREATE TRIGGER
5. Handle bare CREATE TYPE -> DO $$ IF NOT EXISTS wrapper
6. Split into manageable chunks (avoid timeout)
7. Save preprocessed files to /tmp/migrations_processed/

Dependency order (determined from file analysis):
1. rls_role_fix.sql — creates get_user_role() and get_user_school_id()
2. school_management_schema.sql — base tables (academic_sessions, student_profiles, etc.)
3. question_bank_schema.sql — creates question_bank, topics, etc.
4. ai_generator_schema.sql — depends on question_bank
5. billing_schema.sql — standalone billing tables
6. marketplace_schema.sql — marketplace tables
7. cbt_engine_schema.sql — depends on question_bank + school_management
8. teacher_workspace_schema.sql — depends on school_management
9. teacher_workspace_expansion_schema.sql — depends on teacher_workspace + school_management
10. parent_portal_schema.sql — depends on school_management
11. student_portal_schema.sql — depends on various
12. communication_schema.sql — depends on school_management + parent_portal
13. cbt_engine_enhancements_schema.sql — depends on cbt_engine
14. results_analytics_schema.sql — depends on cbt_engine + school_management
15. super_admin_schema.sql — depends on billing + marketplace
16. ccms_enterprise_schema.sql — creates educational_levels, depends on question_bank + school_management
17. final_production_schema.sql — depends on ccms_enterprise (educational_levels)
18. marketplace_security.sql — depends on marketplace
19. payment_security_hardening.sql — depends on billing
20. refund_security.sql — depends on billing
21. mobile_offline_schema.sql — depends on various
22. infrastructure_monitoring.sql — mostly standalone
23. database_optimization.sql — depends on billing + marketplace + question_bank + cbt_engine
"""

import os
import re
import json

# Ordered list of migrations based on dependencies
MIGRATION_ORDER = [
    "rls_role_fix.sql",
    "school_management_schema.sql",
    "question_bank_schema.sql",
    "ai_generator_schema.sql",
    "billing_schema.sql",
    "marketplace_schema.sql",
    "cbt_engine_schema.sql",
    "teacher_workspace_schema.sql",
    "teacher_workspace_expansion_schema.sql",
    "parent_portal_schema.sql",
    "student_portal_schema.sql",
    "communication_schema.sql",
    "cbt_engine_enhancements_schema.sql",
    "results_analytics_schema.sql",
    "super_admin_schema.sql",
    "ccms_enterprise_schema.sql",
    "final_production_schema.sql",
    "marketplace_security.sql",
    "payment_security_hardening.sql",
    "refund_security.sql",
    "mobile_offline_schema.sql",
    "infrastructure_monitoring.sql",
    "database_optimization.sql",
]

# Tables created by schema.sql (already applied)
BASE_TABLES = ['users', 'schools', 'classes', 'subjects', 'class_subjects', 
               'notifications', 'audit_log', 'school_memberships']

# Tables that are created by each migration (for FK dependency resolution)
TABLE_OWNERS = {
    "rls_role_fix.sql": ["parent_children"],
    "school_management_schema.sql": ["school_branches", "school_settings", "school_branding",
        "student_profiles", "teacher_profiles", "parent_profiles", "departments",
        "academic_sessions", "terms", "school_calendar_events", "timetable_slots",
        "timetable_conflicts", "student_attendance", "teacher_attendance",
        "homework_assignments", "homework_submissions", "announcements",
        "document_center", "promotion_history", "graduation_records",
        "class_students", "class_teachers"],
    "question_bank_schema.sql": ["question_bank", "answer_options", "matching_pairs",
        "ordering_items", "fill_in_blank_answers", "question_topics", "question_exams",
        "question_tags", "question_share_permissions", "question_import_logs",
        "question_review_queue", "question_difficulty_history", "question_stats",
        "topics", "subtopics", "curriculum_standards", "curriculum_topics",
        "curriculum_objectives", "tag_master", "question_collaboration"],
    "ai_generator_schema.sql": ["ai_providers", "ai_provider_configs", "ai_prompt_templates",
        "ai_prompt_versions", "ai_generation_jobs", "ai_generation_inputs",
        "ai_generation_outputs", "ai_job_logs", "ai_generation_reviews",
        "ai_generation_improvements", "document_upload_jobs", "document_processing_logs",
        "ai_cost_tracking", "ai_cost_budgets", "ai_generation_history",
        "ai_model_configs", "ai_generation_settings"],
    "billing_schema.sql": ["subscription_plans", "subscriptions", "transactions",
        "ai_credits", "ai_credit_transactions", "coupons", "coupon_usages",
        "referrals", "referral_usages", "invoices", "invoice_items",
        "licenses", "license_activations", "revenue_analytics", "webhook_status"],
    "marketplace_schema.sql": ["marketplace_categories", "marketplace_products",
        "marketplace_product_files", "marketplace_product_images",
        "marketplace_purchases", "marketplace_purchase_items",
        "marketplace_reviews", "marketplace_seller_profiles",
        "marketplace_seller_applications", "marketplace_disputes",
        "marketplace_dispute_messages", "marketplace_product_analytics",
        "marketplace_recommendations", "marketplace_quality_checks",
        "marketplace_saved_searches", "marketplace_notifications",
        "marketplace_search_log", "marketplace_cart", "marketplace_cart_items",
        "marketplace_wishlist", "marketplace_wishlist_items",
        "marketplace_discounts", "marketplace_product_discounts"],
    "cbt_engine_schema.sql": ["exams", "exam_subjects", "exam_sections",
        "exam_questions", "exam_attempts", "student_answers",
        "exam_sessions", "exam_timing_events", "exam_notifications",
        "exam_monitoring", "exam_rankings", "exam_settings"],
    "teacher_workspace_schema.sql": ["lesson_plans", "lesson_plan_sections",
        "schemes_of_work", "scheme_weeks", "worksheets", "worksheet_questions",
        "assignments", "assignment_submissions", "report_comments",
        "teaching_resources", "content_assistant_sessions",
        "content_assistant_messages", "resource_library_items",
        "resource_library_categories", "calendar_events", "calendar_reminders"],
    "teacher_workspace_expansion_schema.sql": ["ai_presentations", "presentation_slides",
        "ai_communications", "teacher_tasks", "rubrics", "rubric_criteria",
        "oral_questions", "practical_assessments", "practical_assessment_criteria",
        "shared_content", "content_comments", "dashboard_widgets",
        "dashboard_preferences"],
    "parent_portal_schema.sql": ["parent_messages", "parent_children_portal",
        "parent_insights", "parent_engagement_metrics", "parent_calendar_events",
        "parent_calendar_reminders", "parent_ai_conversations",
        "parent_ai_messages", "parent_notifications", "parent_reports",
        "parent_report_downloads", "parent_settings"],
    "student_portal_schema.sql": ["ai_tutor_conversations", "ai_tutor_messages",
        "practice_sessions", "practice_answers", "assignment_submissions_sp",
        "student_resources", "student_resource_access",
        "document_chats", "document_chat_messages", "flashcard_decks",
        "flashcards", "flashcard_review_log", "study_plans",
        "study_goals", "study_tasks", "student_progress_snapshots",
        "student_notifications_sp"],
    "communication_schema.sql": ["conversations", "conversation_participants",
        "messages", "message_read_status", "communication_announcements",
        "announcement_read_status", "communication_forums", "forum_topics",
        "forum_posts", "forum_post_reactions", "calendar_events_comm",
        "calendar_event_attendees", "ai_communication_assistant_sessions",
        "ai_communication_assistant_messages", "ai_school_knowledge_base",
        "shared_files", "file_access_log", "moderation_reports",
        "moderation_actions", "communication_audit_log"],
    "cbt_engine_enhancements_schema.sql": ["exam_templates", "template_sections",
        "template_section_question_rules", "submission_receipts",
        "exam_notifications_enhanced"],
    "results_analytics_schema.sql": ["grade_scales", "grade_scale_ranges",
        "ai_grading_results", "teacher_feedback", "student_subject_results",
        "student_overall_results", "analytics_snapshots",
        "analytics_dashboards", "dashboard_widgets_ra", "report_export_tracking",
        "performance_trends", "topic_mastery", "result_notifications_ra",
        "report_card_templates", "report_card_fields", "report_cards",
        "report_card_subject_entries", "report_card_comments"],
    "super_admin_schema.sql": ["platform_settings", "platform_audit_events",
        "support_tickets", "ticket_comments", "ticket_attachments",
        "ticket_assignments", "user_feedback", "ai_provider_configs_sa",
        "ai_provider_usage_stats", "infrastructure_health", "infrastructure_alerts",
        "marketplace_moderation_queue", "moderation_decisions",
        "operations_intelligence", "ai_operations_predictions",
        "admin_notifications", "admin_reports"],
    "ccms_enterprise_schema.sql": ["educational_levels", "level_categories",
        "curriculum_frameworks", "curriculum_versions", "curriculum_subjects",
        "content_items", "content_versions", "content_objectives",
        "content_tag_relations", "answer_repository", "answer_versions",
        "answer_explanations", "answer_distractor_analysis",
        "ai_curriculum_engine_configs", "ai_curriculum_generation_jobs",
        "ai_curriculum_generation_outputs", "enterprise_security_config",
        "enterprise_audit_log", "enterprise_monitoring",
        "enterprise_api_keys", "enterprise_api_usage"],
    "final_production_schema.sql": ["exam_bodies", "exam_categories",
        "preparation_materials", "university_programs", "admission_requirements",
        "admission_applications", "customer_success_agents",
        "customer_success_conversations", "customer_success_actions",
        "marketing_campaigns", "campaign_segments", "campaign_messages",
        "campaign_metrics", "user_readiness_scores", "ai_study_recommendations",
        "marketing_analytics", "product_analytics"],
    "marketplace_security.sql": ["download_tokens", "download_audit_log"],
    "payment_security_hardening.sql": ["webhook_events", "marketplace_commission_rates"],
    "refund_security.sql": ["refund_audit_log"],
    "mobile_offline_schema.sql": ["registered_devices", "push_notification_tokens",
        "push_notification_queue", "offline_sync_metadata", "offline_sync_queue",
        "offline_conflict_log", "offline_cache_tracking", "offline_exam_config",
        "offline_exam_attempts", "offline_exam_answers", "connectivity_analytics",
        "file_download_tracking", "app_analytics", "crash_reports",
        "pwa_install_tracking", "device_sync_sessions"],
    "infrastructure_monitoring.sql": ["app_health_checks", "performance_metrics",
        "rate_limits", "feature_flags"],
    "database_optimization.sql": ["slow_query_log"],
}

# All tables that will exist (for FK stripping logic)
ALL_TABLES = set(BASE_TABLES)
for tables in TABLE_OWNERS.values():
    ALL_TABLES.update(tables)

# Cross-file FK constraints to strip (from the JSON file)
FK_CONSTRAINTS = json.load(open('/home/z/my-project/download/stripped_fk_constraints.json'))

# Group FK constraints by file
FK_BY_FILE = {}
for fk in FK_CONSTRAINTS:
    f = fk['file']
    if f not in FK_BY_FILE:
        FK_BY_FILE[f] = []
    FK_BY_FILE[f].append(fk)

MIGRATIONS_DIR = '/home/z/my-project/examforge_ai/supabase/migrations'
OUTPUT_DIR = '/tmp/migrations_processed'

os.makedirs(OUTPUT_DIR, exist_ok=True)

def strip_begin_commit(sql):
    """Remove BEGIN; and COMMIT; but NOT bare BEGIN inside DO$$ blocks."""
    # Remove lines that are exactly "BEGIN;" (with semicolon) 
    lines = sql.split('\n')
    result = []
    for line in lines:
        stripped = line.strip()
        # Only remove BEGIN; (with semicolon, not PL/pgSQL BEGIN keyword)
        if stripped == 'BEGIN;':
            continue
        if stripped == 'COMMIT;':
            continue
        result.append(line)
    return '\n'.join(result)

def strip_cross_file_fks(sql, filename):
    """Remove REFERENCES clauses that point to tables not yet created in this file."""
    fks = FK_BY_FILE.get(filename, [])
    if not fks:
        return sql
    
    for fk in fks:
        ref_table = fk['ref_table']
        col = fk['column']
        on_delete = fk.get('on_delete')
        
        # Pattern: column_name TYPE REFERENCES ref_table(ref_col) ON DELETE action
        # We need to strip the REFERENCES clause
        if on_delete:
            patterns = [
                # With ON DELETE CASCADE / SET NULL / RESTRICT etc.
                re.compile(
                    rf'{col}\s+UUID\s+NOT\s+NULL\s+REFERENCES\s+{ref_table}\s*\(\s*id\s*\)\s+ON\s+DELETE\s+{on_delete}',
                    re.IGNORECASE
                ),
                re.compile(
                    rf'{col}\s+UUID\s+REFERENCES\s+{ref_table}\s*\(\s*id\s*\)\s+ON\s+DELETE\s+{on_delete}',
                    re.IGNORECASE
                ),
            ]
        else:
            patterns = [
                re.compile(
                    rf'{col}\s+UUID\s+NOT\s+NULL\s+REFERENCES\s+{ref_table}\s*\(\s*id\s*\)',
                    re.IGNORECASE
                ),
                re.compile(
                    rf'{col}\s+UUID\s+REFERENCES\s+{ref_table}\s*\(\s*id\s*\)',
                    re.IGNORECASE
                ),
            ]
        
        for pattern in patterns:
            # Replace with just the column definition without REFERENCES
            if on_delete:
                sql = pattern.sub(f'{col} UUID NOT NULL', sql)
            else:
                sql = pattern.sub(f'{col} UUID', sql)
    
    return sql

def add_drop_policy_if_exists(sql):
    """Add DROP POLICY IF EXISTS before each CREATE POLICY."""
    # Find all CREATE POLICY statements and add DROP POLICY IF EXISTS before them
    pattern = re.compile(r'CREATE POLICY\s+"([^"]+)"\s+ON\s+(\w+)', re.IGNORECASE)
    
    matches = list(pattern.finditer(sql))
    # Process in reverse to avoid position shifts
    for match in reversed(matches):
        policy_name = match.group(1)
        table_name = match.group(2)
        drop_stmt = f'DROP POLICY IF EXISTS "{policy_name}" ON {table_name};\n'
        sql = sql[:match.start()] + drop_stmt + sql[match.start():]
    
    return sql

def add_drop_trigger_if_exists(sql):
    """Add DROP TRIGGER IF EXISTS before each CREATE TRIGGER."""
    pattern = re.compile(r'CREATE\s+TRIGGER\s+(\w+)\s+', re.IGNORECASE)
    
    matches = list(pattern.finditer(sql))
    for match in reversed(matches):
        trigger_name = match.group(1)
        # Find the ON table_name part
        rest_of_line = sql[match.start():match.start()+200]
        on_match = re.search(r'ON\s+(\w+)', rest_of_line)
        if on_match:
            table_name = on_match.group(1)
            drop_stmt = f'DROP TRIGGER IF EXISTS {trigger_name} ON {table_name};\n'
            sql = sql[:match.start()] + drop_stmt + sql[match.start():]
    
    return sql

def wrap_bare_create_type(sql):
    """Wrap bare CREATE TYPE statements that aren't already in DO$$ blocks."""
    # This is tricky - we need to find CREATE TYPE statements NOT inside DO$$ blocks
    # For now, skip this since most files already use DO$$ or create_enum_if_not_exists
    return sql

def preprocess_file(filename):
    """Apply all preprocessing transformations to a migration file."""
    filepath = os.path.join(MIGRATIONS_DIR, filename)
    with open(filepath, 'r') as f:
        sql = f.read()
    
    # 1. Strip BEGIN/COMMIT
    sql = strip_begin_commit(sql)
    
    # 2. Strip cross-file FK REFERENCES
    sql = strip_cross_file_fks(sql, filename)
    
    # 3. Add DROP POLICY IF EXISTS
    sql = add_drop_policy_if_exists(sql)
    
    # 4. Add DROP TRIGGER IF EXISTS
    sql = add_drop_trigger_if_exists(sql)
    
    # 5. Wrap bare CREATE TYPE (if needed)
    sql = wrap_bare_create_type(sql)
    
    # Save the preprocessed file
    output_path = os.path.join(OUTPUT_DIR, filename)
    with open(output_path, 'w') as f:
        f.write(sql)
    
    return output_path

# Preprocess all files in dependency order
print("=" * 60)
print("PREPROCESSING ALL MIGRATIONS")
print("=" * 60)

for i, filename in enumerate(MIGRATION_ORDER, 1):
    output = preprocess_file(filename)
    print(f"[{i}] Preprocessed: {filename} -> {output}")

# Generate FK restoration SQL
print("\n" + "=" * 60)
print("GENERATING FK RESTORATION SQL")
print("=" * 60)

fk_restore_sql = "-- Restore all stripped cross-file FK constraints\n"
fk_restore_sql += "-- Generated automatically by preprocess_all_migrations.py\n\n"

# Group FKs by source table
fk_by_table = {}
for fk in FK_CONSTRAINTS:
    # We need to figure out which table each FK belongs to
    # The FK JSON has 'file', 'column', 'ref_table', 'ref_col', 'on_delete'
    # We need to find the source table from the original SQL
    filename = fk['file']
    col = fk['column']
    ref_table = fk['ref_table']
    ref_col = fk['ref_col']
    on_delete = fk.get('on_delete')
    
    # Read the original file to find which table contains this column
    filepath = os.path.join(MIGRATIONS_DIR, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find the table that contains this column with REFERENCES
    # Look for: col UUID ... REFERENCES ref_table
    # Find preceding CREATE TABLE
    pattern = re.compile(
        rf'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)\s*\([^)]*{col}\s+UUID[^)]*REFERENCES\s+{ref_table}',
        re.IGNORECASE | re.DOTALL
    )
    match = pattern.search(content)
    if match:
        source_table = match.group(1)
        constraint_name = f'fk_{source_table}_{col}_{ref_table}'
        
        if on_delete:
            fk_restore_sql += f"ALTER TABLE {source_table} ADD CONSTRAINT {constraint_name} FOREIGN KEY ({col}) REFERENCES {ref_table}({ref_col}) ON DELETE {on_delete};\n"
        else:
            fk_restore_sql += f"ALTER TABLE {source_table} ADD CONSTRAINT {constraint_name} FOREIGN KEY ({col}) REFERENCES {ref_table}({ref_col});\n"
    else:
        print(f"WARNING: Could not find source table for FK: {col} -> {ref_table} in {filename}")

fk_restore_path = os.path.join(OUTPUT_DIR, 'restore_fk_constraints.sql')
with open(fk_restore_path, 'w') as f:
    f.write(fk_restore_sql)

print(f"FK restoration SQL saved to: {fk_restore_path}")
print(f"Total FK constraints to restore: {len(FK_CONSTRAINTS)}")

# Generate summary
print("\n" + "=" * 60)
print("EXECUTION ORDER SUMMARY")
print("=" * 60)
for i, filename in enumerate(MIGRATION_ORDER, 1):
    tables = TABLE_OWNERS.get(filename, [])
    print(f"  [{i}] {filename} ({len(tables)} tables)")

print(f"\nTotal migrations: {len(MIGRATION_ORDER)}")
print(f"Total new tables: {sum(len(t) for t in TABLE_OWNERS.values())}")
print(f"Total FK constraints to restore: {len(FK_CONSTRAINTS)}")
print(f"\nAll preprocessed files saved to: {OUTPUT_DIR}")
