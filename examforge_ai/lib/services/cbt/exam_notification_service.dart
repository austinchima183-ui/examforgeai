import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Service for managing exam-related notifications.
// Sends notifications to students and teachers based on exam lifecycle
// events.
//
// Notification types:
// - Exam becomes available (published)
// - Exam starts (active)
// - Time is almost over (5 min warning, 1 min warning)
// - Exam submitted successfully
// - Results released
// - Manual grading required (teacher)
// - All submissions complete (teacher)
// - Suspicious activity detected (teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Notification type constants used as the `type` field when inserting
/// rows into the `notifications` table.
class ExamNotificationType {
  ExamNotificationType._();

  /// Exam has been published and is now available to students.
  static const String examPublished = 'exam_published';

  /// Exam has started (became active).
  static const String examStarted = 'exam_started';

  /// Time is running out for the student's current attempt.
  static const String timeWarning = 'time_warning';

  /// Student has successfully submitted their exam attempt.
  static const String examSubmitted = 'exam_submitted';

  /// Exam results have been released.
  static const String resultsReleased = 'results_released';

  /// Teacher needs to manually grade submissions.
  static const String manualGradingRequired = 'manual_grading_required';

  /// All students have submitted their attempts.
  static const String allSubmissionsComplete = 'all_submissions_complete';

  /// Suspicious activity was detected during an exam attempt.
  static const String suspiciousActivity = 'suspicious_activity';
}

class ExamNotificationService {
  ExamNotificationService({required sb.SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Table name ────────────────────────────────────────────────────

  static const _notificationsTable = 'notifications';

  // ═══════════════════════════════════════════════════════════════════
  // Exam Published
  // ═══════════════════════════════════════════════════════════════════

  /// Notify students that an exam has been published and is now
  /// available for them to view or prepare for.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [studentIds] — list of student user IDs who should be notified.
  Future<void> notifyExamPublished(
    String examId,
    String examTitle,
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) {
      AppLogger.debug('No students to notify for exam published: $examId');
      return;
    }

    AppLogger.info(
      'Notifying ${studentIds.length} students: exam "$examTitle" published',
    );

    final notifications = studentIds.map((studentId) => _buildNotification(
          userId: studentId,
          type: ExamNotificationType.examPublished,
          title: 'New Exam Available',
          body: 'The exam "$examTitle" is now available. Good luck!',
          examId: examId,
          extraData: {
            'exam_title': examTitle,
          },
        ));

    await _insertNotifications(notifications.toList());
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Started
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a teacher that their exam has started (became active).
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [teacherId] — the user ID of the teacher who owns the exam.
  Future<void> notifyExamStarted(
    String examId,
    String examTitle,
    String teacherId,
  ) async {
    AppLogger.info(
      'Notifying teacher $teacherId: exam "$examTitle" started',
    );

    await _insertNotification(_buildNotification(
      userId: teacherId,
      type: ExamNotificationType.examStarted,
      title: 'Exam Started',
      body: 'Your exam "$examTitle" has started. Students can now begin.',
      examId: examId,
      extraData: {
        'exam_title': examTitle,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Time Warning
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a student that their exam time is almost over.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [studentId] — the user ID of the student taking the exam.
  /// [minutesRemaining] — number of minutes remaining before time is up.
  Future<void> notifyTimeWarning(
    String examId,
    String examTitle,
    String studentId,
    int minutesRemaining,
  ) async {
    AppLogger.info(
      'Notifying student $studentId: ${minutesRemaining}m remaining '
      'for exam "$examTitle"',
    );

    final urgency = minutesRemaining <= 1 ? 'final' : 'warning';

    await _insertNotification(_buildNotification(
      userId: studentId,
      type: ExamNotificationType.timeWarning,
      title: minutesRemaining <= 1
          ? 'Final Minute!'
          : 'Time Warning: $minutesRemaining Minutes Left',
      body: minutesRemaining <= 1
          ? 'Only 1 minute remaining for "$examTitle". Submit now!'
          : 'You have $minutesRemaining minutes remaining for "$examTitle". '
              'Please prepare to submit.',
      examId: examId,
      extraData: {
        'exam_title': examTitle,
        'minutes_remaining': minutesRemaining,
        'urgency': urgency,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Submitted
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a student that their exam attempt was submitted successfully.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [studentId] — the user ID of the student who submitted.
  /// [attemptId] — the unique identifier of the attempt that was submitted.
  Future<void> notifyExamSubmitted(
    String examId,
    String examTitle,
    String studentId,
    String attemptId,
  ) async {
    AppLogger.info(
      'Notifying student $studentId: exam "$examTitle" submitted '
      '(attempt: $attemptId)',
    );

    await _insertNotification(_buildNotification(
      userId: studentId,
      type: ExamNotificationType.examSubmitted,
      title: 'Exam Submitted',
      body: 'Your submission for "$examTitle" has been recorded successfully.',
      examId: examId,
      extraData: {
        'exam_title': examTitle,
        'attempt_id': attemptId,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Results Released
  // ═══════════════════════════════════════════════════════════════════

  /// Notify students that exam results have been released.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [studentIds] — list of student user IDs who should be notified.
  Future<void> notifyResultsReleased(
    String examId,
    String examTitle,
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) {
      AppLogger.debug('No students to notify for results released: $examId');
      return;
    }

    AppLogger.info(
      'Notifying ${studentIds.length} students: results released '
      'for exam "$examTitle"',
    );

    final notifications = studentIds.map((studentId) => _buildNotification(
          userId: studentId,
          type: ExamNotificationType.resultsReleased,
          title: 'Results Available',
          body: 'Results for "$examTitle" are now available for viewing.',
          examId: examId,
          extraData: {
            'exam_title': examTitle,
          },
        ));

    await _insertNotifications(notifications.toList());
  }

  // ═══════════════════════════════════════════════════════════════════
  // Manual Grading Required
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a teacher that manual grading is required for an exam.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [teacherId] — the user ID of the teacher who needs to grade.
  /// [pendingCount] — the number of submissions awaiting manual grading.
  Future<void> notifyManualGradingRequired(
    String examId,
    String examTitle,
    String teacherId,
    int pendingCount,
  ) async {
    AppLogger.info(
      'Notifying teacher $teacherId: $pendingCount submissions need '
      'manual grading for exam "$examTitle"',
    );

    await _insertNotification(_buildNotification(
      userId: teacherId,
      type: ExamNotificationType.manualGradingRequired,
      title: 'Manual Grading Required',
      body: '$pendingCount submission${pendingCount == 1 ? '' : 's'} for '
          '"$examTitle" require manual grading.',
      examId: examId,
      extraData: {
        'exam_title': examTitle,
        'pending_count': pendingCount,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // All Submissions Complete
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a teacher that all students have submitted their exam
  /// attempts.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [examTitle] — the human-readable title of the exam.
  /// [teacherId] — the user ID of the teacher who owns the exam.
  /// [totalSubmissions] — the total number of submissions received.
  Future<void> notifyAllSubmissionsComplete(
    String examId,
    String examTitle,
    String teacherId,
    int totalSubmissions,
  ) async {
    AppLogger.info(
      'Notifying teacher $teacherId: all $totalSubmissions submissions '
      'received for exam "$examTitle"',
    );

    await _insertNotification(_buildNotification(
      userId: teacherId,
      type: ExamNotificationType.allSubmissionsComplete,
      title: 'All Submissions Received',
      body: 'All $totalSubmissions submissions for "$examTitle" have been '
          'received. You can begin grading.',
      examId: examId,
      extraData: {
        'exam_title': examTitle,
        'total_submissions': totalSubmissions,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Suspicious Activity
  // ═══════════════════════════════════════════════════════════════════

  /// Notify a teacher that suspicious activity was detected during a
  /// student's exam attempt.
  ///
  /// [examId] — the unique identifier of the exam.
  /// [studentId] — the user ID of the student exhibiting suspicious
  ///   behavior.
  /// [teacherId] — the user ID of the teacher to notify.
  /// [eventType] — a string describing the type of suspicious event
  ///   (e.g., "tab_switch", "copy_attempt", "fullscreen_exit").
  Future<void> notifySuspiciousActivity(
    String examId,
    String studentId,
    String teacherId,
    String eventType,
  ) async {
    AppLogger.warning(
      'Notifying teacher $teacherId: suspicious activity '
      '("$eventType") by student $studentId in exam $examId',
    );

    await _insertNotification(_buildNotification(
      userId: teacherId,
      type: ExamNotificationType.suspiciousActivity,
      title: 'Suspicious Activity Detected',
      body: 'Student $studentId triggered a "$eventType" event during '
          'the exam. Please review.',
      examId: examId,
      extraData: {
        'student_id': studentId,
        'event_type': eventType,
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Build a notification map suitable for insertion into the
  /// `notifications` table.
  Map<String, dynamic> _buildNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String examId,
    Map<String, dynamic>? extraData,
  }) {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': {
        'exam_id': examId,
        ...?extraData,
      },
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Insert a single notification row into Supabase.
  ///
  /// Failures are logged but non-blocking — notification delivery is
  /// a best-effort operation and should not crash the calling service.
  Future<void> _insertNotification(Map<String, dynamic> notification) async {
    try {
      await _supabaseClient
          .from(_notificationsTable)
          .insert(notification);

      AppLogger.debug(
        'Notification inserted: type=${notification['type']}, '
        'user=${notification['user_id']}',
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        'Failed to insert notification (PostgrestException)',
        error: e,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error inserting notification',
        error: e,
      );
    }
  }

  /// Insert multiple notification rows into Supabase in a single batch.
  ///
  /// Failures are logged but non-blocking — notification delivery is
  /// a best-effort operation and should not crash the calling service.
  Future<void> _insertNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) return;

    try {
      await _supabaseClient
          .from(_notificationsTable)
          .insert(notifications);

      AppLogger.debug(
        '${notifications.length} notifications inserted (batch)',
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        'Failed to batch-insert notifications (PostgrestException)',
        error: e,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error batch-inserting notifications',
        error: e,
      );
    }
  }
}
