import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/cbt/realtime_service.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../../domain/usecases/get_live_exam_stats_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM MONITOR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the live exam monitoring feature.
///
/// Tracks the exam being monitored, live statistics, active sessions,
/// attempts, monitoring events, and subscription state.
class ExamMonitorState {
  const ExamMonitorState({
    this.exam,
    this.liveStats,
    this.activeSessions = const [],
    this.attempts = const [],
    this.monitoringEvents = const [],
    this.isWatching = false,
    this.error,
    this.filter,
  });

  /// The exam being monitored.
  final ExamEntity? exam;

  /// Live statistics for the exam.
  final LiveExamStats? liveStats;

  /// Currently active exam sessions.
  final List<ExamSessionEntity> activeSessions;

  /// Recent exam attempts.
  final List<ExamAttemptEntity> attempts;

  /// Monitoring events (anti-cheat alerts).
  final List<MonitoringLogEntity> monitoringEvents;

  /// Whether the monitor is actively watching (subscribed to Realtime).
  final bool isWatching;

  /// The most recent error message, or `null`.
  final String? error;

  /// Optional student ID filter for monitoring events.
  final String? filter;

  /// Total number of active students.
  int get activeCount => activeSessions.where((s) => s.isActive).length;

  /// Total number of unresolved monitoring events.
  int get unresolvedEventCount =>
      monitoringEvents.where((e) => !e.isResolved).length;

  /// Critical unresolved events.
  List<MonitoringLogEntity> get criticalEvents => monitoringEvents
      .where((e) => e.severity == 'critical' && !e.isResolved)
      .toList();

  /// Creates a copy of this state with the given fields replaced.
  ExamMonitorState copyWith({
    ExamEntity? exam,
    LiveExamStats? liveStats,
    List<ExamSessionEntity>? activeSessions,
    List<ExamAttemptEntity>? attempts,
    List<MonitoringLogEntity>? monitoringEvents,
    bool? isWatching,
    String? error,
    String? filter,
  }) {
    return ExamMonitorState(
      exam: exam ?? this.exam,
      liveStats: liveStats ?? this.liveStats,
      activeSessions: activeSessions ?? this.activeSessions,
      attempts: attempts ?? this.attempts,
      monitoringEvents: monitoringEvents ?? this.monitoringEvents,
      isWatching: isWatching ?? this.isWatching,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM MONITOR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the live exam monitoring state.
///
/// Provides methods for loading exam data, subscribing/unsubscribing
/// to Realtime updates, resolving monitoring events, and forcing
/// student submissions.
class ExamMonitorNotifier extends StateNotifier<ExamMonitorState> {
  ExamMonitorNotifier({
    required CbtRepository cbtRepository,
    required GetLiveExamStatsUseCase getLiveExamStatsUseCase,
    required CbtRealtimeService cbtRealtimeService,
  })  : _cbtRepository = cbtRepository,
        _getLiveExamStatsUseCase = getLiveExamStatsUseCase,
        _cbtRealtimeService = cbtRealtimeService,
        super(const ExamMonitorState());

  final CbtRepository _cbtRepository;
  final GetLiveExamStatsUseCase _getLiveExamStatsUseCase;
  final CbtRealtimeService _cbtRealtimeService;

  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _attemptsSubscription;
  StreamSubscription? _monitoringSubscription;

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD EXAM FOR MONITORING
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads the exam data and initial statistics for the monitoring view.
  Future<void> loadExamForMonitoring(String examId) async {
    state = state.copyWith(error: null);

    // Load exam details
    final examResult = await _cbtRepository.getExamWithDetails(examId);

    examResult.fold(
      onSuccess: (exam) {
        state = state.copyWith(exam: exam);
        AppLogger.info('Exam loaded for monitoring: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load exam for monitoring: $failure',
        );
        return;
      },
    );

    // Load initial live stats
    await refreshStats();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // START WATCHING (Subscribe to Realtime)
  // ═══════════════════════════════════════════════════════════════════════

  /// Subscribes to Realtime updates for the given exam.
  ///
  /// Opens three channels:
  /// - Exam sessions (student activity)
  /// - Exam attempts (submissions)
  /// - Monitoring events (anti-cheat alerts)
  Future<void> startWatching(String examId) async {
    if (state.isWatching) return;

    state = state.copyWith(isWatching: true, error: null);

    // Subscribe to exam sessions
    _sessionsSubscription = _cbtRealtimeService
        .watchExamSessions(examId)
        .listen(
      (session) {
        final updated = _upsertSession(session);
        state = state.copyWith(activeSessions: updated);
      },
      onError: (error) {
        AppLogger.warning('Session stream error: $error');
      },
    );

    // Subscribe to exam attempts
    _attemptsSubscription = _cbtRealtimeService
        .watchExamAttempts(examId)
        .listen(
      (attempt) {
        final updated = _upsertAttempt(attempt);
        state = state.copyWith(attempts: updated);
      },
      onError: (error) {
        AppLogger.warning('Attempt stream error: $error');
      },
    );

    // Subscribe to monitoring events
    _monitoringSubscription = _cbtRealtimeService
        .watchMonitoringEvents(examId)
        .listen(
      (event) {
        final updated = [event, ...state.monitoringEvents];
        // Keep only the last 100 events to prevent memory issues
        if (updated.length > 100) {
          updated.removeRange(100, updated.length);
        }
        state = state.copyWith(monitoringEvents: updated);
      },
      onError: (error) {
        AppLogger.warning('Monitoring stream error: $error');
      },
    );

    AppLogger.info('Started watching exam: $examId');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STOP WATCHING (Unsubscribe)
  // ═══════════════════════════════════════════════════════════════════════

  /// Unsubscribes from all Realtime updates.
  void stopWatching() {
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;
    _attemptsSubscription?.cancel();
    _attemptsSubscription = null;
    _monitoringSubscription?.cancel();
    _monitoringSubscription = null;

    _cbtRealtimeService.unsubscribeAll();

    state = state.copyWith(isWatching: false);
    AppLogger.info('Stopped watching exam');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESOLVE MONITORING EVENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Marks a monitoring event as resolved.
  Future<void> resolveMonitoringEvent(String eventId) async {
    final updated = state.monitoringEvents.map((e) {
      if (e.id == eventId) {
        return e.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
        );
      }
      return e;
    }).toList();
    state = state.copyWith(monitoringEvents: updated);

    AppLogger.info('Monitoring event resolved: $eventId');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORCE SUBMIT STUDENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Force-submits a student's exam attempt.
  ///
  /// Used by the teacher/admin when a student needs to be removed
  /// from the exam (e.g., due to disqualification).
  Future<void> forceSubmitStudent(String attemptId) async {
    final result = await _cbtRepository.submitAttempt(
      attemptId,
      type: SubmissionType.forceSubmit,
    );

    result.fold(
      onSuccess: (_) {
        // Update the attempt in the list
        final updated = state.attempts.map((a) {
          if (a.id == attemptId) {
            return a.copyWith(
              status: AttemptStatus.submitted,
              submittedAt: DateTime.now(),
              submissionType: SubmissionType.forceSubmit,
            );
          }
          return a;
        }).toList();
        state = state.copyWith(attempts: updated);

        AppLogger.info('Force submitted attempt: $attemptId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Force submit failed: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REFRESH STATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Refreshes the live exam statistics.
  Future<void> refreshStats() async {
    if (state.exam == null) return;

    final result = await _getLiveExamStatsUseCase(
      GetLiveStatsParams(examId: state.exam!.id),
    );

    result.fold(
      onSuccess: (stats) {
        state = state.copyWith(liveStats: stats);
        AppLogger.debug('Live stats refreshed for exam: ${state.exam!.id}');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to refresh stats: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SET FILTER
  // ═══════════════════════════════════════════════════════════════════════

  /// Sets a student filter for monitoring events.
  void setFilter(String? studentId) {
    state = state.copyWith(filter: studentId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR ERROR
  // ═══════════════════════════════════════════════════════════════════════

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Upserts a session into the active sessions list.
  List<ExamSessionEntity> _upsertSession(ExamSessionEntity session) {
    final existing = state.activeSessions
        .where((s) => s.id != session.id)
        .toList();
    if (session.isActive) {
      existing.add(session);
    }
    return existing;
  }

  /// Upserts an attempt into the attempts list.
  List<ExamAttemptEntity> _upsertAttempt(ExamAttemptEntity attempt) {
    final existing = state.attempts
        .where((a) => a.id != attempt.id)
        .toList();
    existing.add(attempt);
    return existing;
  }

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}
