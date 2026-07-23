import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../features/cbt_engine/domain/entities/cbt_entities.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// CBT REALTIME SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Supabase Realtime service for live monitoring of exam sessions.
// Provides real-time streams for exam sessions, attempts, and
// monitoring events, plus heartbeat and session state updates.
// ═══════════════════════════════════════════════════════════════════════

class CbtRealtimeService {
  CbtRealtimeService({required sb.SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Active channel subscriptions ───────────────────────────────────

  final Map<String, sb.RealtimeChannel> _channels = {};
  final Map<String, StreamController<dynamic>> _controllers = {};

  // ─── Table names ────────────────────────────────────────────────────

  static const _examSessionsTable = 'exam_sessions';
  static const _examAttemptsTable = 'exam_attempts';
  static const _monitoringLogsTable = 'monitoring_logs';

  // ═══════════════════════════════════════════════════════════════════
  // Watch Exam Sessions
  // ═══════════════════════════════════════════════════════════════════

  /// Subscribe to real-time exam session updates for the monitoring
  /// dashboard.
  ///
  /// Emits [ExamSessionEntity] instances whenever a session is
  /// inserted, updated, or deleted for the given [examId].
  Stream<ExamSessionEntity> watchExamSessions(String examId) {
    final channelName = 'cbt_sessions_$examId';
    final controller = StreamController<ExamSessionEntity>.broadcast();

    _controllers[channelName] = controller;

    final channel = _supabaseClient.channel(
      channelName,
      opts: const sb.RealtimeChannelConfig(self: true),
    );

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _examSessionsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        try {
          final session = _parseSessionEntity(payload.newRecord);
          if (!controller.isClosed) {
            controller.add(session);
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to parse session realtime event',
            error: e,
          );
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    // Fetch initial data
    _fetchInitialSessions(examId, controller);

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Watch Exam Attempts
  // ═══════════════════════════════════════════════════════════════════

  /// Subscribe to real-time exam attempt updates.
  ///
  /// Emits [ExamAttemptEntity] instances whenever an attempt is
  /// inserted, updated, or deleted for the given [examId].
  Stream<ExamAttemptEntity> watchExamAttempts(String examId) {
    final channelName = 'cbt_attempts_$examId';
    final controller = StreamController<ExamAttemptEntity>.broadcast();

    _controllers[channelName] = controller;

    final channel = _supabaseClient.channel(
      channelName,
      opts: const sb.RealtimeChannelConfig(self: true),
    );

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _examAttemptsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        try {
          final attempt = _parseAttemptEntity(payload.newRecord);
          if (!controller.isClosed) {
            controller.add(attempt);
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to parse attempt realtime event',
            error: e,
          );
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Watch Monitoring Events
  // ═══════════════════════════════════════════════════════════════════

  /// Subscribe to real-time monitoring events for live anti-cheat
  /// dashboards.
  ///
  /// Emits [MonitoringLogEntity] instances whenever a new monitoring
  /// event is logged for the given [examId].
  Stream<MonitoringLogEntity> watchMonitoringEvents(String examId) {
    final channelName = 'cbt_monitoring_$examId';
    final controller = StreamController<MonitoringLogEntity>.broadcast();

    _controllers[channelName] = controller;

    final channel = _supabaseClient.channel(
      channelName,
      opts: const sb.RealtimeChannelConfig(self: true),
    );

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _monitoringLogsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        try {
          final event = _parseMonitoringEntity(payload.newRecord);
          if (!controller.isClosed) {
            controller.add(event);
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to parse monitoring realtime event',
            error: e,
          );
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Send Heartbeat
  // ═══════════════════════════════════════════════════════════════════

  /// Send a heartbeat for an active session to prevent timeout.
  ///
  /// Updates the session's [lastHeartbeat] and [connectionStatus]
  /// to keep the session alive in the monitoring dashboard.
  Future<void> sendHeartbeat(String sessionId) async {
    try {
      await _supabaseClient
          .from(_examSessionsTable)
          .update({
            'last_heartbeat': DateTime.now().toIso8601String(),
            'connection_status': 'connected',
          })
          .eq('id', sessionId);

      AppLogger.debug('Heartbeat sent for session $sessionId');
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        'Heartbeat failed for session $sessionId',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Heartbeat unexpected error for session $sessionId',
        error: e,
      );
      throw ServerException(
        message: 'Failed to send heartbeat: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Update Session State
  // ═══════════════════════════════════════════════════════════════════

  /// Update an exam session's state in real time.
  ///
  /// Used for syncing the student's current question index,
  /// answer count, flag count, and other live state to the
  /// monitoring dashboard.
  Future<void> updateSessionState(ExamSessionEntity session) async {
    try {
      await _supabaseClient
          .from(_examSessionsTable)
          .update({
            'is_active': session.isActive,
            'current_question_index': session.currentQuestionIndex,
            'questions_answered': session.questionsAnswered,
            'questions_flagged': session.questionsFlagged,
            'last_heartbeat': DateTime.now().toIso8601String(),
            'connection_status': session.connectionStatus,
            'ip_address': session.ipAddress,
            'device_fingerprint': session.deviceFingerprint,
            'tab_switch_count': session.tabSwitchCount,
            'focus_lost_count': session.focusLostCount,
          })
          .eq('id', session.id);

      AppLogger.debug(
        'Session state updated for ${session.id} '
        '(question: ${session.currentQuestionIndex})',
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        'Update session state failed for ${session.id}',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Update session state unexpected error for ${session.id}',
        error: e,
      );
      throw ServerException(
        message: 'Failed to update session state: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Unsubscribe All
  // ═══════════════════════════════════════════════════════════════════

  /// Unsubscribe from all active realtime channels.
  ///
  /// Should be called when the user navigates away from the
  /// monitoring dashboard or logs out.
  void unsubscribeAll() {
    for (final entry in _controllers.entries) {
      if (!entry.value.isClosed) {
        entry.value.close();
      }
    }
    _controllers.clear();

    for (final channel in _channels.values) {
      _supabaseClient.removeChannel(channel);
    }
    _channels.clear();

    AppLogger.info('All CBT realtime subscriptions closed');
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dispose
  // ═══════════════════════════════════════════════════════════════════

  /// Dispose of all resources and subscriptions.
  void dispose() {
    unsubscribeAll();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch initial session data and emit to the stream controller.
  Future<void> _fetchInitialSessions(
    String examId,
    StreamController<ExamSessionEntity> controller,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_examSessionsTable)
          .select()
          .eq('exam_id', examId)
          .eq('is_active', true);

      for (final row in response) {
        if (!controller.isClosed) {
          controller.add(_parseSessionEntity(row));
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch initial sessions for exam $examId',
        error: e,
      );
    }
  }

  /// Parse a raw Supabase row into an [ExamSessionEntity].
  ExamSessionEntity _parseSessionEntity(Map<String, dynamic> json) {
    return ExamSessionEntity(
      id: json['id'] as String,
      attemptId: json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      currentQuestionIndex: json['current_question_index'] as int? ??
          json['currentQuestionIndex'] as int? ??
          0,
      questionsAnswered: json['questions_answered'] as int? ??
          json['questionsAnswered'] as int? ??
          0,
      questionsFlagged: json['questions_flagged'] as int? ??
          json['questionsFlagged'] as int? ??
          0,
      lastHeartbeat: _parseDateTime(json['last_heartbeat'] ?? json['lastHeartbeat']),
      connectionStatus: json['connection_status'] as String? ??
          json['connectionStatus'] as String? ??
          'connected',
      ipAddress: json['ip_address'] as String? ?? json['ipAddress'] as String?,
      deviceFingerprint: json['device_fingerprint'] as String? ??
          json['deviceFingerprint'] as String?,
      tabSwitchCount: json['tab_switch_count'] as int? ??
          json['tabSwitchCount'] as int? ??
          0,
      focusLostCount: json['focus_lost_count'] as int? ??
          json['focusLostCount'] as int? ??
          0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Parse a raw Supabase row into an [ExamAttemptEntity].
  ExamAttemptEntity _parseAttemptEntity(Map<String, dynamic> json) {
    return ExamAttemptEntity(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      attemptNumber: json['attempt_number'] as int? ??
          json['attemptNumber'] as int? ??
          1,
      status: AttemptStatus.fromString(
            json['status'] as String? ?? 'not_started',
          ) ??
          AttemptStatus.notStarted,
      startedAt: _parseDateTime(json['started_at'] ?? json['startedAt']),
      submittedAt: _parseDateTimeNullable(
        json['submitted_at'] ?? json['submittedAt'],
      ),
      submissionType: SubmissionType.fromString(
        json['submission_type'] as String? ?? json['submissionType'] as String?,
      ),
      timeSpentSeconds: json['time_spent_seconds'] as int? ??
          json['timeSpentSeconds'] as int? ??
          0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble() ??
          (json['scorePercentage'] as num?)?.toDouble() ??
          0.0,
      isPassed: json['is_passed'] as bool? ?? json['isPassed'] as bool? ?? false,
      gradingStatus: GradingStatus.fromString(
            json['grading_status'] as String? ??
                json['gradingStatus'] as String? ??
                'pending',
          ) ??
          GradingStatus.pending,
      gradedBy: json['graded_by'] as String? ?? json['gradedBy'] as String?,
      gradedAt: _parseDateTimeNullable(
        json['graded_at'] ?? json['gradedAt'],
      ),
      deviceInfo: json['device_info'] as Map<String, dynamic>? ??
          json['deviceInfo'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String? ?? json['ipAddress'] as String?,
      userAgent: json['user_agent'] as String? ?? json['userAgent'] as String?,
      lastActivityAt: _parseDateTimeNullable(
        json['last_activity_at'] ?? json['lastActivityAt'],
      ),
      autoSaveData: json['auto_save_data'] as Map<String, dynamic>? ??
          json['autoSaveData'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Parse a raw Supabase row into a [MonitoringLogEntity].
  MonitoringLogEntity _parseMonitoringEntity(Map<String, dynamic> json) {
    return MonitoringLogEntity(
      id: json['id'] as String,
      attemptId: json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      eventType: MonitoringEventType.fromString(
            json['event_type'] as String? ?? json['eventType'] as String?,
          ) ??
          MonitoringEventType.suspiciousActivity,
      eventData: json['event_data'] as Map<String, dynamic>? ??
          json['eventData'] as Map<String, dynamic>?,
      severity: json['severity'] as String? ?? 'info',
      isResolved: json['is_resolved'] as bool? ??
          json['isResolved'] as bool? ??
          false,
      resolvedBy: json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolvedAt: _parseDateTimeNullable(
        json['resolved_at'] ?? json['resolvedAt'],
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Parse a DateTime from various formats.
  DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Parse a nullable DateTime.
  DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return null;
  }
}
