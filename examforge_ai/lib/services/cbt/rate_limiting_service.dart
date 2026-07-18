import 'dart:async';

import '../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// RATE LIMITING SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Service for rate limiting exam-related API operations.
// Prevents abuse by enforcing request limits per user, per operation
// type.
//
// Operation types:
// - startAttempt:    Max 3 per minute per student per exam
// - saveAnswer:      Max 30 per minute per attempt
// - submitAttempt:   Max 3 per minute per student
// - autoSave:        Max 6 per minute per attempt
// - heartbeat:       Max 12 per minute per session
//
// Rate-limit data is held in memory with automatic cleanup of expired
// entries every 60 seconds.
// ═══════════════════════════════════════════════════════════════════════

/// Enumerates the exam operations that can be rate-limited.
///
/// Each operation has a configurable [maxRequests] limit within a
/// one-minute window.
enum RateLimitOperation {
  /// Starting a new exam attempt.
  startAttempt(maxRequests: 3),

  /// Saving an individual answer during an exam.
  saveAnswer(maxRequests: 30),

  /// Submitting a completed exam attempt.
  submitAttempt(maxRequests: 3),

  /// Auto-saving exam progress.
  autoSave(maxRequests: 6),

  /// Sending a heartbeat to keep an exam session alive.
  heartbeat(maxRequests: 12);

  const RateLimitOperation({required this.maxRequests});

  /// Maximum number of requests allowed within the rate-limit window
  /// (one minute) for this operation.
  final int maxRequests;
}

/// A single recorded request timestamp for a user + operation pair.
class _RequestRecord {
  _RequestRecord({required this.timestamp});

  /// The time at which the request was made.
  final DateTime timestamp;
}

class RateLimitingService {
  RateLimitingService() {
    _startCleanupTimer();
  }

  // ─── Rate-limit window ─────────────────────────────────────────────

  /// The duration of the rate-limit window. All request counts are
  /// measured within this rolling window.
  static const Duration _windowDuration = Duration(minutes: 1);

  // ─── In-memory request tracking ────────────────────────────────────

  /// Key format: `"{userId}:{operationName}"`.
  /// Value: list of request timestamps within the current window.
  final Map<String, List<_RequestRecord>> _requestLog = {};

  /// Timer that periodically removes expired request records.
  Timer? _cleanupTimer;

  /// Interval at which the cleanup timer fires.
  static const Duration _cleanupInterval = Duration(seconds: 60);

  // ═══════════════════════════════════════════════════════════════════
  // Check Rate Limit
  // ═══════════════════════════════════════════════════════════════════

  /// Check whether the given [userId] is allowed to perform [operation]
  /// without exceeding the rate limit.
  ///
  /// Returns `true` if the request is allowed, `false` if the rate
  /// limit has been exceeded.
  ///
  /// This method does **not** record the request — call
  /// [recordRequest] separately if the request is allowed and will
  /// be executed.
  bool checkRateLimit(String userId, RateLimitOperation operation) {
    _pruneExpiredEntries(userId, operation);

    final key = _makeKey(userId, operation);
    final records = _requestLog[key];
    final currentCount = records?.length ?? 0;

    if (currentCount >= operation.maxRequests) {
      AppLogger.warning(
        'Rate limit exceeded for $userId on ${operation.name}: '
        '$currentCount/${operation.maxRequests} requests in window',
      );
      return false;
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Record Request
  // ═══════════════════════════════════════════════════════════════════

  /// Record that [userId] has made a request for [operation].
  ///
  /// Should be called **after** confirming via [checkRateLimit] that
  /// the request is allowed.
  void recordRequest(String userId, RateLimitOperation operation) {
    final key = _makeKey(userId, operation);
    final now = DateTime.now();

    _requestLog.putIfAbsent(key, () => []);
    _requestLog[key]!.add(_RequestRecord(timestamp: now));

    AppLogger.debug(
      'Request recorded for $userId on ${operation.name}: '
      '${_requestLog[key]!.length}/${operation.maxRequests}',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Get Remaining Requests
  // ═══════════════════════════════════════════════════════════════════

  /// Returns the number of remaining requests [userId] can make for
  /// [operation] within the current rate-limit window.
  int getRemainingRequests(String userId, RateLimitOperation operation) {
    _pruneExpiredEntries(userId, operation);

    final key = _makeKey(userId, operation);
    final currentCount = _requestLog[key]?.length ?? 0;

    final remaining = operation.maxRequests - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Reset Rate Limit
  // ═══════════════════════════════════════════════════════════════════

  /// Reset the rate-limit records for a specific [userId] and
  /// [operation].
  ///
  /// Useful for administrative overrides or after a successful
  /// operation that should clear the counter.
  void resetRateLimit(String userId, RateLimitOperation operation) {
    final key = _makeKey(userId, operation);
    _requestLog.remove(key);
    AppLogger.info(
      'Rate limit reset for $userId on ${operation.name}',
    );
  }

  /// Reset all rate-limit records for a specific [userId].
  ///
  /// Typically called when a user signs out or their session ends.
  void resetAllForUser(String userId) {
    _requestLog.removeWhere((key, _) => key.startsWith('$userId:'));
    AppLogger.info('All rate limits reset for user $userId');
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dispose
  // ═══════════════════════════════════════════════════════════════════

  /// Dispose of all resources, cancelling the cleanup timer and
  /// clearing in-memory records.
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _requestLog.clear();
    AppLogger.info('RateLimitingService disposed');
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Build the composite key used to look up request records.
  String _makeKey(String userId, RateLimitOperation operation) {
    return '$userId:${operation.name}';
  }

  /// Remove expired entries from the request log for a specific
  /// user + operation combination.
  void _pruneExpiredEntries(String userId, RateLimitOperation operation) {
    final key = _makeKey(userId, operation);
    final records = _requestLog[key];
    if (records == null || records.isEmpty) return;

    final cutoff = DateTime.now().subtract(_windowDuration);
    records.removeWhere((record) => record.timestamp.isBefore(cutoff));

    // Clean up empty lists to avoid memory leaks.
    if (records.isEmpty) {
      _requestLog.remove(key);
    }
  }

  /// Remove all expired entries across all users and operations.
  ///
  /// Called periodically by the cleanup timer.
  void _pruneAllExpiredEntries() {
    final cutoff = DateTime.now().subtract(_windowDuration);
    final emptyKeys = <String>[];

    for (final entry in _requestLog.entries) {
      entry.value.removeWhere((record) => record.timestamp.isBefore(cutoff));
      if (entry.value.isEmpty) {
        emptyKeys.add(entry.key);
      }
    }

    // Remove keys with no remaining records.
    for (final key in emptyKeys) {
      _requestLog.remove(key);
    }

    if (emptyKeys.isNotEmpty) {
      AppLogger.debug(
        'Rate-limit cleanup: removed ${emptyKeys.length} expired keys',
      );
    }
  }

  /// Start the periodic cleanup timer that removes expired request
  /// records.
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _pruneAllExpiredEntries();
    });

    AppLogger.info(
      'RateLimitingService cleanup timer started '
      '(interval: ${_cleanupInterval.inSeconds}s)',
    );
  }
}
