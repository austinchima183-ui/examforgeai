import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/local_encryption_service.dart';
import '../../core/utils/logger.dart';

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
// SESSION RECOVERY SERVICE (WITH ENCRYPTION)
// ═══════════════════════════════════════════════════════════════════════
// Persists and recovers exam session state locally using
// SharedPreferences. When a student's exam session is interrupted
// (browser crash, network loss, device restart), this service
// allows restoring their progress — current question index,
// answers, and remaining time.
//
// **SECURITY FIX:** Exam answers are now encrypted before storage
// using [LocalEncryptionService]. Previously, answers were stored
// as plaintext JSON, meaning anyone with access to SharedPreferences
// could read exam answers. This is a critical exam integrity issue.
//
// The service also maintains backwards compatibility by attempting
// to decrypt first, then falling back to plaintext parsing for
// legacy data.
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

    // Initialize encryption if not already done
    if (!LocalEncryptionService.isInitialized) {
      // Use a stable device-specific seed stored in secure storage.
      const secureStorage = FlutterSecureStorage();
      String? deviceSeed = await secureStorage.read(key: '_device_seed');
      if (deviceSeed == null) {
        deviceSeed = DateTime.now().microsecondsSinceEpoch.toString();
        await secureStorage.write(key: '_device_seed', value: deviceSeed);
      }
      await LocalEncryptionService.initialize(deviceSeed: deviceSeed);
    }
  }

  /// Initialize with a specific device seed (preferred method).
  Future<void> initWithSeed(String deviceSeed) async {
    _prefs = await SharedPreferences.getInstance();

    if (!LocalEncryptionService.isInitialized) {
      await LocalEncryptionService.initialize(deviceSeed: deviceSeed);
    }

    // Persist for future sessions
    if (!_prefs!.containsKey('_device_seed')) {
      await _prefs!.setString('_device_seed', deviceSeed);
    }
  }

  /// Ensure prefs are available.
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Save Session State ─────────────────────────────────────────────

  /// Save session state locally for crash recovery.
  ///
  /// **SECURITY:** Exam answers are encrypted before storage to prevent
  /// unauthorized access to exam content via SharedPreferences inspection.
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

      // ─── ENCRYPT ANSWERS BEFORE STORAGE ───────────────────────────
      // Build a separate JSON structure where answers are encrypted
      // while metadata (attemptId, examId, etc.) remains plaintext
      // for quick metadata checks without decryption.
      final stateJson = state.toJson();

      // Encrypt the answers map specifically
      final answersJson = jsonEncode(stateJson['answers']);
      final encryptedAnswers = LocalEncryptionService.encryptData(answersJson);

      final storageJson = {
        'attempt_id': stateJson['attempt_id'],
        'exam_id': stateJson['exam_id'],
        'current_question_index': stateJson['current_question_index'],
        'remaining_time_seconds': stateJson['remaining_time_seconds'],
        'saved_at': stateJson['saved_at'],
        'answers_encrypted': encryptedAnswers,
        '_encrypted': true,  // Flag for decryption on recovery
      };

      final jsonStr = jsonEncode(storageJson);
      await prefs.setString(key, jsonStr);

      AppLogger.debug(
        'Session state saved (encrypted) for attempt $attemptId '
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
  /// Handles both encrypted (current) and plaintext (legacy) formats
  /// for backwards compatibility.
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

      // ─── DECRYPT ANSWERS ──────────────────────────────────────────
      Map<String, dynamic> answers;

      if (jsonData['_encrypted'] == true && jsonData.containsKey('answers_encrypted')) {
        // New encrypted format — decrypt the answers
        final encryptedAnswers = jsonData['answers_encrypted'] as String;
        final decryptedAnswersJson = LocalEncryptionService.decryptData(encryptedAnswers);
        try {
          answers = jsonDecode(decryptedAnswersJson) as Map<String, dynamic>;
        } catch (_) {
          // Decryption failed — data may be corrupted
          AppLogger.error('Failed to decrypt exam answers for attempt $attemptId');
          await clearSession(attemptId);
          return null;
        }
      } else if (jsonData.containsKey('answers')) {
        // Legacy plaintext format — migrate to encrypted on next save
        answers = jsonData['answers'] as Map<String, dynamic>;
        AppLogger.info('Recovered legacy (unencrypted) session for attempt $attemptId');
      } else {
        answers = {};
      }

      final state = SessionState(
        attemptId: jsonData['attempt_id'] as String? ?? '',
        examId: jsonData['exam_id'] as String? ?? '',
        currentQuestionIndex: jsonData['current_question_index'] as int? ?? 0,
        answers: answers,
        remainingTime: Duration(
          seconds: jsonData['remaining_time_seconds'] as int? ?? 0,
        ),
        savedAt: jsonData['saved_at'] != null
            ? DateTime.parse(jsonData['saved_at'] as String)
            : DateTime.now(),
      );

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

  void dispose() {
    _prefs = null;
  }
}
