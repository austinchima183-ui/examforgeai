import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// SESSION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Represents a recoverable session state for an interrupted exam.
class SessionState {
  const SessionState({
    required this.attemptId,
    required this.examId,
    required this.currentQuestionIndex,
    required this.answers,
    required this.remainingTime,
    required this.savedAt,
  });

  final String attemptId;
  final String examId;
  final int currentQuestionIndex;
  final Map<String, dynamic> answers;
  final Duration remainingTime;
  final DateTime savedAt;

  /// Whether this session state is stale (older than [maxAge]).
  bool isStale({Duration maxAge = const Duration(hours: 24)}) {
    return DateTime.now().difference(savedAt) > maxAge;
  }

  /// Convert to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'attempt_id': attemptId,
      'exam_id': examId,
      'current_question_index': currentQuestionIndex,
      'answers': answers,
      'remaining_time_seconds': remainingTime.inSeconds,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      attemptId: json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      currentQuestionIndex: json['current_question_index'] as int? ??
          json['currentQuestionIndex'] as int? ??
          0,
      answers: json['answers'] as Map<String, dynamic>? ?? {},
      remainingTime: Duration(
        seconds: json['remaining_time_seconds'] as int? ??
            json['remainingTimeSeconds'] as int? ??
            0,
      ),
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'] as String)
          : json['savedAt'] != null
              ? DateTime.parse(json['savedAt'] as String)
              : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SessionState(attemptId: $attemptId, examId: $examId, '
      'question: $currentQuestionIndex, remaining: ${remainingTime.inSeconds}s)';
}

// ═══════════════════════════════════════════════════════════════════════
// SESSION RECOVERY SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Persists and recovers exam session state locally using
// SharedPreferences. When a student's exam session is interrupted
// (browser crash, network loss, device restart), this service
// allows restoring their progress — current question index,
// answers, and remaining time.
// ═══════════════════════════════════════════════════════════════════════

class SessionRecoveryService {
  static const _keyPrefix = 'cbt_session_';

  SharedPreferences? _prefs;

  // ─── Initialization ─────────────────────────────────────────────────

  /// Initialize the service with SharedPreferences.
  ///
  /// Must be called before any other method. Safe to call multiple times.
  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure prefs are available.
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  // ─── Save Session State ─────────────────────────────────────────────

  /// Save session state locally for crash recovery.
  ///
  /// [attemptId] the exam attempt being taken.
  /// [examId] the exam being taken.
  /// [currentQuestionIndex] which question the student is viewing.
  /// [answers] all saved answers so far (questionId → answer data).
  /// [remainingTime] time left on the exam clock.
  Future<void> saveSessionState({
    required String attemptId,
    required String examId,
    required int currentQuestionIndex,
    required Map<String, dynamic> answers,
    required Duration remainingTime,
  }) async {
    try {
      final state = SessionState(
        attemptId: attemptId,
        examId: examId,
        currentQuestionIndex: currentQuestionIndex,
        answers: answers,
        remainingTime: remainingTime,
        savedAt: DateTime.now(),
      );

      final prefs = await _getPrefs();
      final key = '$_keyPrefix$attemptId';
      final jsonStr = jsonEncode(state.toJson());

      await prefs.setString(key, jsonStr);

      AppLogger.debug(
        'Session state saved for attempt $attemptId '
        '(question: $currentQuestionIndex, '
        'remaining: ${remainingTime.inSeconds}s)',
      );
    } catch (e) {
      AppLogger.error('Failed to save session state', error: e);
      // Don't rethrow — session save failures should be non-blocking.
    }
  }

  // ─── Recover Session State ──────────────────────────────────────────

  /// Recover a previously saved session state.
  ///
  /// Returns `null` if no saved state exists, if the state is
  /// corrupt, or if the state has expired (older than 24 hours).
  Future<SessionState?> recoverSession(String attemptId) async {
    try {
      final prefs = await _getPrefs();
      final key = '$_keyPrefix$attemptId';
      final jsonStr = prefs.getString(key);

      if (jsonStr == null) {
        AppLogger.debug('No saved session found for attempt $attemptId');
        return null;
      }

      final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
      final state = SessionState.fromJson(jsonData);

      // Check if the session is stale (older than 24 hours)
      if (state.isStale()) {
        AppLogger.info(
          'Saved session for attempt $attemptId is stale, discarding',
        );
        await clearSession(attemptId);
        return null;
      }

      AppLogger.info(
        'Recovered session for attempt $attemptId: '
        'question ${state.currentQuestionIndex}, '
        '${state.remainingTime.inSeconds}s remaining',
      );

      return state;
    } catch (e) {
      AppLogger.error(
        'Failed to recover session for attempt $attemptId',
        error: e,
      );
      // Try to clear the corrupt state
      await clearSession(attemptId);
      return null;
    }
  }

  // ─── Clear Session ──────────────────────────────────────────────────

  /// Clear saved session state for an attempt.
  ///
  /// Should be called after a session is successfully resumed or
  /// after an exam is submitted.
  Future<void> clearSession(String attemptId) async {
    try {
      final prefs = await _getPrefs();
      final key = '$_keyPrefix$attemptId';
      await prefs.remove(key);
      AppLogger.debug('Cleared session state for attempt $attemptId');
    } catch (e) {
      AppLogger.error(
        'Failed to clear session for attempt $attemptId',
        error: e,
      );
    }
  }

  // ─── Check for Recoverable Session ──────────────────────────────────

  /// Check if a recoverable session exists for the given attempt.
  ///
  /// Returns `true` if a valid, non-stale session state exists.
  Future<bool> hasRecoverableSession(String attemptId) async {
    try {
      final state = await recoverSession(attemptId);
      return state != null;
    } catch (_) {
      return false;
    }
  }

  // ─── List All Recoverable Sessions ──────────────────────────────────

  /// Get all attempt IDs that have recoverable session states.
  ///
  /// Useful for showing a list of resumable exams to the student.
  Future<List<String>> getAllRecoverableAttemptIds() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys();
      final attemptIds = <String>[];

      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          final attemptId = key.substring(_keyPrefix.length);
          if (await hasRecoverableSession(attemptId)) {
            attemptIds.add(attemptId);
          }
        }
      }

      return attemptIds;
    } catch (e) {
      AppLogger.error('Failed to list recoverable sessions', error: e);
      return [];
    }
  }

  // ─── Clear All Sessions ─────────────────────────────────────────────

  /// Clear all saved session states.
  ///
  /// Useful for logout or account switch scenarios.
  Future<void> clearAllSessions() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }

      AppLogger.info('Cleared all session states');
    } catch (e) {
      AppLogger.error('Failed to clear all sessions', error: e);
    }
  }

  // ─── Dispose ────────────────────────────────────────────────────────

  /// Dispose of resources. SharedPreferences instance is retained
  /// as it's a singleton managed by the platform.
  void dispose() {
    _prefs = null;
  }
}
