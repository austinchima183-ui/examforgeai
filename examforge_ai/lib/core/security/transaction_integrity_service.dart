// ============================================================================
// ExamForge AI — Transaction Integrity Verification Service
// ============================================================================
// Provides robust integrity hash verification for financial transactions.
//
// SECURITY MODEL:
//   - Never accept NULL hashes
//   - Never accept empty hashes
//   - Fail closed on any verification error
//   - Replay attack detection via nonce + timestamp
//   - Duplicate request detection via idempotency keys
//   - Timing-attack resistant comparison
//   - Race condition protection via atomic operations
//
// ROOT CAUSE (why this file exists):
//   The original integrity hash verification had multiple vulnerabilities:
//   - No NULL/empty hash handling
//   - No replay attack detection
//   - No duplicate request detection
//   - Race conditions in concurrent verification
//   - Inconsistent error handling (sometimes returned true on error)
// ============================================================================

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../utils/logger.dart';
import 'constant_time_comparison.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════

/// Thrown when integrity verification fails.
class IntegrityVerificationException implements Exception {
  final String message;
  final String code;
  final String? transactionRef;

  const IntegrityVerificationException({
    required this.message,
    required this.code,
    this.transactionRef,
  });

  @override
  String toString() =>
      'IntegrityVerificationException(code: $code, message: $message, txRef: $transactionRef)';
}

/// Thrown when a replay attack is detected.
class ReplayAttackDetectedException extends IntegrityVerificationException {
  ReplayAttackDetectedException(String txRef, String reason)
      : super(
          message: 'Replay attack detected: $reason',
          code: 'REPLAY_ATTACK_DETECTED',
          transactionRef: txRef,
        );
}

/// Thrown when a duplicate request is detected.
class DuplicateRequestDetectedException extends IntegrityVerificationException {
  DuplicateRequestDetectedException(String txRef, String reason)
      : super(
          message: 'Duplicate request detected: $reason',
          code: 'DUPLICATE_REQUEST_DETECTED',
          transactionRef: txRef,
        );
}

/// Thrown when a race condition is detected during verification.
class RaceConditionDetectedException extends IntegrityVerificationException {
  RaceConditionDetectedException(String txRef)
      : super(
          message: 'Concurrent modification detected during verification',
          code: 'RACE_CONDITION_DETECTED',
          transactionRef: txRef,
        );
}

// ═══════════════════════════════════════════════════════════════════════
// INTEGRITY HASH RECORD
// ═══════════════════════════════════════════════════════════════════════

/// Immutable record of a verified transaction integrity hash.
class IntegrityHashRecord {
  final String transactionRef;
  final String amount;
  final String currency;
  final String hash;
  final DateTime createdAt;
  final String? nonce;

  const IntegrityHashRecord({
    required this.transactionRef,
    required this.amount,
    required this.currency,
    required this.hash,
    required this.createdAt,
    this.nonce,
  });

  Map<String, dynamic> toJson() => {
        'transaction_ref': transactionRef,
        'amount': amount,
        'currency': currency,
        'hash': hash,
        'created_at': createdAt.toIso8601String(),
        'nonce': nonce,
      };
}

// ═══════════════════════════════════════════════════════════════════════
// TRANSACTION INTEGRITY SERVICE
// ═══════════════════════════════════════════════════════════════════════

/// Enterprise-grade transaction integrity verification.
///
/// This service provides:
/// 1. Hash computation for transaction data (amount + currency + ref + nonce)
/// 2. Hash verification with constant-time comparison
/// 3. Replay attack detection via nonce tracking
/// 4. Duplicate request detection via idempotency tracking
/// 5. Race condition protection for concurrent operations
/// 6. Fail-closed error handling
class TransactionIntegrityService {
  TransactionIntegrityService._();

  /// HMAC secret key for integrity hash computation.
  /// In production, this MUST be loaded from secure server-side storage.
  static String _hmacSecret = '';

  /// Nonce tracking for replay attack detection.
  /// Maps nonce -> timestamp of when it was seen.
  static final Map<String, DateTime> _seenNonces = {};

  /// Idempotency key tracking for duplicate request detection.
  /// Maps idempotency key -> result of the first request.
  static final Map<String, IntegrityHashRecord> _idempotencyCache = {};

  /// Maximum age of a nonce before it's considered stale (5 minutes).
  static const Duration _nonceMaxAge = Duration(minutes: 5);

  /// Maximum number of nonces to track (prevents memory exhaustion).
  static const int _maxTrackedNonces = 10000;

  /// Initializes the service with the HMAC secret.
  ///
  /// The secret MUST be loaded from environment variables or secure storage.
  /// Never hardcode this value.
  static void initialize(String hmacSecret) {
    if (hmacSecret.isEmpty) {
      throw ArgumentError('HMAC secret must not be empty');
    }
    _hmacSecret = hmacSecret;
    AppLogger.info('TransactionIntegrityService initialized');
  }

  /// Whether the service is properly initialized.
  static bool get isInitialized => _hmacSecret.isNotEmpty;

  // ─── HASH COMPUTATION ──────────────────────────────────────────────

  /// Computes an integrity hash for a transaction.
  ///
  /// The hash covers: transactionRef + amount + currency + nonce + timestamp.
  /// Uses HMAC-SHA256 for keyed hashing to prevent hash manipulation.
  ///
  /// [transactionRef]: Unique transaction reference.
  /// [amount]: Transaction amount as a string (e.g., "5000.00").
  /// [currency]: ISO 4217 currency code (e.g., "NGN").
  /// [nonce]: Optional nonce for replay attack prevention.
  ///
  /// Returns the hex-encoded HMAC-SHA256 hash.
  static String computeHash({
    required String transactionRef,
    required String amount,
    required String currency,
    String? nonce,
  }) {
    _ensureInitialized();

    // Validate inputs — fail fast on invalid data
    if (transactionRef.isEmpty) {
      throw const IntegrityVerificationException(
        message: 'Transaction reference must not be empty',
        code: 'EMPTY_TX_REF',
      );
    }
    if (amount.isEmpty) {
      throw const IntegrityVerificationException(
        message: 'Amount must not be empty',
        code: 'EMPTY_AMOUNT',
      );
    }
    if (currency.isEmpty) {
      throw const IntegrityVerificationException(
        message: 'Currency must not be empty',
        code: 'EMPTY_CURRENCY',
      );
    }

    // Validate amount is a valid positive number
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      throw IntegrityVerificationException(
        message: 'Amount is not a valid number: $amount',
        code: 'INVALID_AMOUNT',
        transactionRef: transactionRef,
      );
    }
    if (parsedAmount < 0) {
      throw IntegrityVerificationException(
        message: 'Amount must not be negative: $amount',
        code: 'NEGATIVE_AMOUNT',
        transactionRef: transactionRef,
      );
    }

    // Validate currency is a valid 3-letter code
    if (currency.length != 3 || !RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw IntegrityVerificationException(
        message: 'Currency must be a valid 3-letter ISO 4217 code: $currency',
        code: 'INVALID_CURRENCY',
        transactionRef: transactionRef,
      );
    }

    // Build the payload in a deterministic order
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final noncePart = nonce ?? '';
    final payload = '$transactionRef|$amount|$currency|$noncePart|$timestamp';

    // Compute HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(_hmacSecret));
    final digest = hmac.convert(utf8.encode(payload));

    return digest.toString();
  }

  // ─── HASH VERIFICATION ──────────────────────────────────────────────

  /// Verifies an integrity hash against expected transaction data.
  ///
  /// **CRITICAL**: This method FAILS CLOSED. Any error during verification
  /// results in a failed verification — never in a pass.
  ///
  /// [storedHash]: The hash stored when the transaction was created.
  /// [transactionRef]: The transaction reference.
  /// [amount]: The expected amount.
  /// [currency]: The expected currency.
  /// [nonce]: The nonce used when the hash was computed (if any).
  ///
  /// Returns `true` only if the hash is valid and matches.
  /// Throws [IntegrityVerificationException] on verification failure.
  static bool verifyHash({
    required String? storedHash,
    required String transactionRef,
    required String amount,
    required String currency,
    String? nonce,
  }) {
    // ─── NULL CHECK (CRITICAL) ──────────────────────────────────────
    if (storedHash == null) {
      AppLogger.critical(
        'TransactionIntegrityService: NULL hash rejected for tx_ref=$transactionRef',
      );
      throw IntegrityVerificationException(
        message: 'Integrity hash must not be NULL. '
            'Transactions without integrity hashes cannot be verified.',
        code: 'NULL_HASH_REJECTED',
        transactionRef: transactionRef,
      );
    }

    // ─── EMPTY CHECK (CRITICAL) ─────────────────────────────────────
    if (storedHash.isEmpty) {
      AppLogger.critical(
        'TransactionIntegrityService: Empty hash rejected for tx_ref=$transactionRef',
      );
      throw IntegrityVerificationException(
        message: 'Integrity hash must not be empty. '
            'Transactions with empty hashes cannot be verified.',
        code: 'EMPTY_HASH_REJECTED',
        transactionRef: transactionRef,
      );
    }

    // ─── INVALID HASH FORMAT CHECK ──────────────────────────────────
    if (!_isValidHashFormat(storedHash)) {
      AppLogger.critical(
        'TransactionIntegrityService: Invalid hash format rejected for tx_ref=$transactionRef',
      );
      throw IntegrityVerificationException(
        message: 'Integrity hash has invalid format. '
            'Expected hex-encoded SHA-256 HMAC.',
        code: 'INVALID_HASH_FORMAT',
        transactionRef: transactionRef,
      );
    }

    try {
      // Recompute the hash with the provided parameters
      final expectedHash = computeHash(
        transactionRef: transactionRef,
        amount: amount,
        currency: currency,
        nonce: nonce,
      );

      // Use constant-time comparison to prevent timing attacks
      final isValid = ConstantTimeComparison.equalsHex(storedHash, expectedHash);

      if (!isValid) {
        AppLogger.critical(
          'TransactionIntegrityService: Hash mismatch for tx_ref=$transactionRef. '
          'Possible data tampering detected!',
        );
        throw IntegrityVerificationException(
          message: 'Integrity hash verification failed. '
              'The transaction data may have been modified.',
          code: 'HASH_MISMATCH',
          transactionRef: transactionRef,
        );
      }

      return true;
    } on IntegrityVerificationException {
      rethrow;
    } catch (e) {
      // FAIL CLOSED: Any unexpected error = verification failure
      AppLogger.critical(
        'TransactionIntegrityService: Verification error for tx_ref=$transactionRef',
        error: e,
      );
      throw IntegrityVerificationException(
        message: 'Integrity verification failed due to unexpected error: $e',
        code: 'VERIFICATION_ERROR',
        transactionRef: transactionRef,
      );
    }
  }

  // ─── REPLAY ATTACK DETECTION ────────────────────────────────────────

  /// Checks if a nonce has been used before (replay attack detection).
  ///
  /// Returns `true` if the nonce is fresh (not a replay).
  /// Throws [ReplayAttackDetectedException] if the nonce was already used.
  static bool checkNonce(String nonce, String transactionRef) {
    if (nonce.isEmpty) {
      // Empty nonce is not a replay, but also not recommended
      AppLogger.warning(
        'TransactionIntegrityService: Empty nonce provided for tx_ref=$transactionRef',
      );
      return true;
    }

    final now = DateTime.now();

    // Clean up expired nonces first
    _cleanupExpiredNonces(now);

    if (_seenNonces.containsKey(nonce)) {
      final firstSeen = _seenNonces[nonce]!;
      final age = now.difference(firstSeen);

      AppLogger.critical(
        'TransactionIntegrityService: REPLAY ATTACK DETECTED! '
        'Nonce reuse for tx_ref=$transactionRef. '
        'Original seen at $firstSeen (age: ${age.inSeconds}s)',
      );
      throw ReplayAttackDetectedException(
        transactionRef,
        'Nonce was already used at $firstSeen',
      );
    }

    // Track this nonce
    _seenNonces[nonce] = now;

    // Prevent memory exhaustion
    if (_seenNonces.length > _maxTrackedNonces) {
      _evictOldestNonces();
    }

    return true;
  }

  // ─── DUPLICATE REQUEST DETECTION ────────────────────────────────────

  /// Checks for duplicate requests using an idempotency key.
  ///
  /// If the key was seen before, returns the original result.
  /// If the key is new, executes the operation and caches the result.
  ///
  /// Returns the [IntegrityHashRecord] from the first request.
  static IntegrityHashRecord checkIdempotency(
    String idempotencyKey,
    IntegrityHashRecord Function() operation,
  ) {
    if (idempotencyKey.isEmpty) {
      // No idempotency key — execute the operation
      return operation();
    }

    if (_idempotencyCache.containsKey(idempotencyKey)) {
      AppLogger.warning(
        'TransactionIntegrityService: Duplicate request detected '
        'for idempotency key=$idempotencyKey',
      );
      return _idempotencyCache[idempotencyKey]!;
    }

    // Execute the operation
    final result = operation();

    // Cache the result
    _idempotencyCache[idempotencyKey] = result;

    return result;
  }

  /// Checks if an idempotency key has been used without executing an operation.
  ///
  /// Returns the cached record if found, null otherwise.
  static IntegrityHashRecord? getIdempotencyRecord(String idempotencyKey) {
    return _idempotencyCache[idempotencyKey];
  }

  // ─── RACE CONDITION PROTECTION ──────────────────────────────────────

  /// Lock tracking for concurrent verification prevention.
  static final Set<String> _lockedTransactions = {};

  /// Acquires a verification lock on a transaction.
  ///
  /// Throws [RaceConditionDetectedException] if the transaction is already
  /// being verified concurrently.
  static bool acquireVerificationLock(String transactionRef) {
    if (_lockedTransactions.contains(transactionRef)) {
      AppLogger.critical(
        'TransactionIntegrityService: RACE CONDITION detected! '
        'Concurrent verification attempt for tx_ref=$transactionRef',
      );
      throw RaceConditionDetectedException(transactionRef);
    }
    _lockedTransactions.add(transactionRef);
    return true;
  }

  /// Releases a verification lock on a transaction.
  static void releaseVerificationLock(String transactionRef) {
    _lockedTransactions.remove(transactionRef);
  }

  /// Executes a verification operation with automatic lock management.
  ///
  /// Acquires the lock before execution and releases it after (even on error).
  static T withVerificationLock<T>(
    String transactionRef,
    T Function() operation,
  ) {
    acquireVerificationLock(transactionRef);
    try {
      return operation();
    } finally {
      releaseVerificationLock(transactionRef);
    }
  }

  // ─── ROLLBACK SUPPORT ──────────────────────────────────────────────

  /// Verifies that a rollback is safe to perform.
  ///
  /// Checks:
  /// 1. The original transaction exists
  /// 2. The original hash is valid
  /// 3. No concurrent operations are in progress
  /// 4. The rollback amount doesn't exceed the original
  static bool verifyRollbackSafe({
    required String transactionRef,
    required String originalHash,
    required String originalAmount,
    required String originalCurrency,
    required String rollbackAmount,
    String? nonce,
  }) {
    // Acquire lock to prevent race conditions during rollback
    acquireVerificationLock(transactionRef);

    try {
      // Verify the original transaction's integrity
      verifyHash(
        storedHash: originalHash,
        transactionRef: transactionRef,
        amount: originalAmount,
        currency: originalCurrency,
        nonce: nonce,
      );

      // Verify rollback amount doesn't exceed original
      final original = double.tryParse(originalAmount) ?? 0;
      final rollback = double.tryParse(rollbackAmount) ?? 0;

      if (rollback <= 0) {
        throw const IntegrityVerificationException(
          message: 'Rollback amount must be positive',
          code: 'INVALID_ROLLBACK_AMOUNT',
        );
      }

      if (rollback > original) {
        throw IntegrityVerificationException(
          message: 'Rollback amount ($rollbackAmount) exceeds original ($originalAmount)',
          code: 'ROLLBACK_EXCEEDS_ORIGINAL',
          transactionRef: transactionRef,
        );
      }

      return true;
    } finally {
      releaseVerificationLock(transactionRef);
    }
  }

  // ─── PRIVATE HELPERS ────────────────────────────────────────────────

  /// Validates that a hash string looks like a valid hex-encoded HMAC.
  static bool _isValidHashFormat(String hash) {
    // SHA-256 HMAC produces a 64-character hex string
    if (hash.length != 64) return false;
    return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hash);
  }

  /// Ensures the service is initialized before use.
  static void _ensureInitialized() {
    if (!isInitialized) {
      throw const IntegrityVerificationException(
        message: 'TransactionIntegrityService not initialized. '
            'Call initialize() with a valid HMAC secret first.',
        code: 'NOT_INITIALIZED',
      );
    }
  }

  /// Removes nonces older than [_nonceMaxAge].
  static void _cleanupExpiredNonces(DateTime now) {
    _seenNonces.removeWhere((key, timestamp) {
      return now.difference(timestamp) > _nonceMaxAge;
    });
  }

  /// Evicts the oldest nonces when the tracking limit is reached.
  static void _evictOldestNonces() {
    final sortedEntries = _seenNonces.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 10% of entries
    final toRemove = (_maxTrackedNonces * 0.1).floor();
    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      _seenNonces.remove(sortedEntries[i].key);
    }
  }

  /// Resets all internal state (for testing only).
  static void reset() {
    _hmacSecret = '';
    _seenNonces.clear();
    _idempotencyCache.clear();
    _lockedTransactions.clear();
  }
}
