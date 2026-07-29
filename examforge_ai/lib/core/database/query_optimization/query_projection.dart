import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUERY PROJECTION UTILITY
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Replace unbounded select() calls with column-projected queries
// Root cause: Datasource audit found many .select() calls without explicit
//   columns, fetching ALL fields for list views. This causes:
//   - 2-5x payload size increase
//   - Slower network transfer
//   - More JSON parsing overhead
//   - Unnecessary memory consumption for unused fields
// Solution: Define column projection lists per table per view context
// ═══════════════════════════════════════════════════════════════════════

/// Column projection definitions for efficient Supabase queries.
///
/// Instead of `.select()` which fetches all columns, use these
/// projection lists to fetch only what's needed for each view context.
///
/// Usage:
///   // Before: .select() — fetches ALL 20+ columns
///   final exams = await supabase.from('exams').select();
///
///   // After: .select(QueryProjection.examsListView) — fetches 7 columns
///   final exams = await supabase.from('exams').select(QueryProjection.examsListView);
class QueryProjection {
  QueryProjection._();

  // ═══════════════════════════════════════════════════════════════════
  // EXAMS
  // ═══════════════════════════════════════════════════════════════════

  /// Minimal columns for exam list view (cards, search results).
  /// Reduces payload from ~20 columns to 8.
  static const String examsListView =
      'id, title, school_id, subject_id, class_id, status, '
      'time_limit_minutes, created_at, created_by, total_marks, '
      'start_time, end_time, exam_type';

  /// Columns for exam detail view (full display).
  static const String examsDetailView =
      'id, title, description, school_id, subject_id, class_id, '
      'academic_session_id, exam_type, status, start_time, end_time, '
      'time_limit_minutes, total_marks, pass_mark, pass_mark_type, '
      'instructions, allowed_attempts, negative_marking_enabled, '
      'negative_mark_value, grace_period_minutes, auto_submit, '
      'randomize_questions, randomize_options, show_results, '
      'show_correct_answers, show_explanations, is_template, '
      'max_students, created_by, created_at, updated_at, metadata';

  /// Columns for exam card display (minimal, for dashboard widgets).
  static const String examsCardView =
      'id, title, status, subject_id, time_limit_minutes, '
      'total_marks, start_time, end_time, created_at';

  // ═══════════════════════════════════════════════════════════════════
  // EXAM ATTEMPTS
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for attempt listing (teacher monitoring dashboard).
  static const String attemptsListView =
      'id, exam_id, student_id, attempt_number, status, '
      'started_at, submitted_at, time_spent_seconds, '
      'total_marks, score_percentage, is_passed, grading_status';

  /// Columns for attempt detail (student result view).
  static const String attemptsDetailView =
      'id, exam_id, student_id, attempt_number, status, '
      'started_at, submitted_at, submission_type, '
      'time_spent_seconds, total_marks, score_percentage, '
      'is_passed, grading_status, graded_by, graded_at, '
      'device_info, ip_address, last_activity_at, auto_save_data';

  // ═══════════════════════════════════════════════════════════════════
  // EXAM SESSIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for live monitoring dashboard.
  static const String sessionsMonitoringView =
      'id, attempt_id, exam_id, student_id, is_active, '
      'current_question_index, questions_answered, '
      'questions_flagged, last_heartbeat, connection_status, '
      'tab_switch_count, focus_lost_count';

  // ═══════════════════════════════════════════════════════════════════
  // STUDENT ANSWERS
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for save answer upsert check (minimal).
  static const String answersUpsertCheck = 'id';

  /// Columns for answer detail.
  static const String answersDetailView =
      'id, attempt_id, question_id, answer_data, '
      'answered_at, is_flagged, updated_at';

  // ═══════════════════════════════════════════════════════════════════
  // MONITORING LOGS
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for monitoring event listing.
  static const String monitoringListView =
      'id, attempt_id, exam_id, student_id, '
      'event_type, severity, is_resolved, created_at';

  // ═══════════════════════════════════════════════════════════════════
  // COMMUNICATION
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for conversation list (chat sidebar).
  static const String conversationsListView =
      'id, title, type, last_message_at, '
      'last_message_preview, unread_count, updated_at';

  /// Columns for message listing (chat thread).
  static const String messagesListView =
      'id, conversation_id, sender_id, content, '
      'message_type, is_read, is_edited, created_at';

  /// Columns for announcement list.
  static const String announcementsListView =
      'id, school_id, title, type, priority, '
      'is_pinned, created_by, created_at';

  /// Columns for notification badge count (minimal).
  static const String notificationsBadgeView = 'id, is_read';

  /// Columns for notification list.
  static const String notificationsListView =
      'id, user_id, type, title, message, '
      'is_read, reference_id, reference_type, created_at';

  // ═══════════════════════════════════════════════════════════════════
  // QUESTION BANK
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for question list view (search results, cards).
  static const String questionsListView =
      'id, subject_id, topic_id, class_level, '
      'question_type, difficulty, status, '
      'content_preview, created_by, created_at';

  /// Columns for question detail view.
  static const String questionsDetailView =
      'id, subject_id, topic_id, class_level, '
      'question_type, difficulty, status, '
      'content, explanation, marks, '
      'negative_marks, is_compulsory, '
      'curriculum_alignment, created_by, '
      'created_at, updated_at, metadata';

  // ═══════════════════════════════════════════════════════════════════
  // SCHOOL MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for student list (class roster).
  static const String studentProfilesListView =
      'id, user_id, school_id, class_id, '
      'admission_number, is_active, is_graduated, '
      'users!student_profiles_user_id_fkey(id, full_name, email)';

  /// Columns for teacher list (school staff).
  static const String teacherProfilesListView =
      'id, user_id, school_id, is_active, '
      'users!teacher_profiles_user_id_fkey(id, full_name, email, avatar_url)';

  /// Columns for school list (admin dashboard).
  static const String schoolsListView =
      'id, name, address, city, state, '
      'is_active, created_at';

  /// Columns for attendance summary (quick view).
  static const String attendanceSummaryView =
      'id, school_id, class_id, date, '
      'total_present, total_absent, total_late';

  // ═══════════════════════════════════════════════════════════════════
  // MARKETPLACE
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for product card (search results, listings).
  static const String productsListView =
      'id, title, slug, category_id, seller_id, '
      'price, original_price, thumbnail_url, '
      'status, rating_average, rating_count, '
      'download_count, created_at';

  /// Columns for product detail.
  static const String productsDetailView =
      'id, title, slug, description, category_id, '
      'seller_id, price, original_price, '
      'thumbnail_url, preview_urls, version, '
      'status, is_featured, rating_average, '
      'rating_count, download_count, '
      'created_at, updated_at, metadata';

  /// Columns for order list.
  static const String ordersListView =
      'id, order_number, buyer_id, seller_id, '
      'total_amount, status, created_at';

  // ═══════════════════════════════════════════════════════════════════
  // BILLING
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for subscription list.
  static const String subscriptionsListView =
      'id, subscriber_id, subscriber_type, plan_id, '
      'status, current_period_start, current_period_end, '
      'created_at';

  /// Columns for transaction list.
  static const String transactionsListView =
      'id, user_id, school_id, amount, currency, '
      'status, transaction_type, flutterwave_tx_ref, '
      'created_at';

  /// Columns for invoice list.
  static const String invoicesListView =
      'id, user_id, school_id, invoice_number, '
      'amount_due, amount_paid, status, '
      'due_date, created_at';

  /// Columns for AI credit balance (minimal).
  static const String creditBalanceView =
      'owner_id, owner_type, balance, total_purchased, '
      'total_consumed, last_updated_at';

  // ═══════════════════════════════════════════════════════════════════
  // TEACHER WORKSPACE
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for lesson plan list.
  static const String lessonPlansListView =
      'id, teacher_id, subject_id, class_id, '
      'title, status, week_number, day_number, '
      'created_at';

  /// Columns for worksheet list.
  static const String worksheetsListView =
      'id, teacher_id, title, subject_id, '
      'status, difficulty, created_at';

  /// Columns for scheme of work list.
  static const String schemesOfWorkListView =
      'id, teacher_id, subject_id, term_id, '
      'title, status, created_at';

  /// Columns for teaching resource list.
  static const String resourcesListView =
      'id, teacher_id, folder_id, title, '
      'resource_type, file_url, status, '
      'created_at';

  // ═══════════════════════════════════════════════════════════════════
  // RESULTS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════

  /// Columns for student subject result listing.
  static const String subjectResultsListView =
      'id, student_id, subject_id, academic_session_id, '
      'total_score, grade, is_passed, created_at';

  /// Columns for student overall result.
  static const String overallResultsListView =
      'id, student_id, academic_session_id, '
      'overall_score, overall_grade, gpa, created_at';

  /// Columns for AI grading queue.
  static const String aiGradingListView =
      'id, answer_id, grading_status, '
      'estimated_score, created_at';

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Apply Projection to Query
  // ═══════════════════════════════════════════════════════════════════

  /// Apply column projection to a Supabase select query.
  ///
  /// Usage:
  ///   final query = QueryProjection.applyProjection(
  ///     supabase.from('exams'),
  ///     QueryProjection.examsListView,
  ///   );
  ///   final response = await query.eq('school_id', schoolId);
  static sb.PostgrestFilterBuilder<dynamic> applyProjection(
    sb.SupabaseClient supabase,
    String table,
    String columns,
  ) {
    return supabase.from(table).select(columns);
  }

  /// Measure the payload size reduction from using projections.
  /// Returns estimated bytes saved based on average column sizes.
  static int estimatePayloadSaving({
    required int totalColumns,
    required int projectedColumns,
    required int rowCount,
    int avgColumnBytes = 50,
  }) {
    final fullPayload = totalColumns * avgColumnBytes * rowCount;
    final projectedPayload = projectedColumns * avgColumnBytes * rowCount;
    return fullPayload - projectedPayload;
  }
}
