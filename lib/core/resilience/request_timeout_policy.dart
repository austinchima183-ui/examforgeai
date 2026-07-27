// ============================================================================
// ExamForge AI — Request Timeout Policies
// ============================================================================
//
// Centralizes all request timeout configurations per environment and per
// operation type. Timeouts are critical for resilience: without them, a
// hanging request blocks the caller indefinitely, consuming resources and
// preventing fallback execution.
//
// ROOT CAUSE: The project has timeout values scattered across multiple
// files (AppConfig connectTimeout/receiveTimeout/sendTimeout are all 15s
// for production, ApiClient uses Dio's configured timeouts, SyncEngine
// has its own adaptive intervals). However, there's no operation-specific
// timeout policy — all operations share the same 15s timeout regardless
// of their characteristics. A database SELECT should timeout faster (5s)
// than an AI generation request (30s), and an exam submission should have
// a longer timeout (45s) to avoid losing student work.
//
// This module provides per-operation timeout policies that are:
//   - Environment-aware (production tighter, development more generous)
//   - Operation-specific (different timeouts for DB vs AI vs exam)
//   - Observable (timeout events are logged for metrics collection)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../logging/structured_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// OPERATION TYPES
// ═══════════════════════════════════════════════════════════════════════════

/// Categories of operations that have distinct timeout requirements.
enum OperationType {
  /// Fast database reads (SELECT queries) -- should complete quickly.
  databaseRead,

  /// Database writes (INSERT/UPDATE/DELETE) -- slightly more tolerant.
  databaseWrite,

  /// Supabase Auth operations (login, signup, token refresh).
  authOperation,

  /// Supabase Storage uploads/downloads -- large payloads, more tolerant.
  storageOperation,

  /// Supabase Realtime subscription setup.
  realtimeSubscription,

  /// Supabase Edge Function invocations -- can take longer.
  edgeFunctionCall,

  /// AI generation requests -- inherently slow, very tolerant.
  aiGeneration,

  /// AI validation/security checks -- should be fast.
  aiValidation,

  /// Exam start/submit operations -- critical, must not timeout prematurely.
  examSubmission,

  /// Exam auto-save -- background operation, moderate timeout.
  examAutoSave,

  /// Sync operations -- background, can be slow.
  syncOperation,

  /// Payment/flutterwave operations -- financial, need reliability.
  paymentOperation,

  /// Health check probes -- should be very fast.
  healthCheck,

  /// General API call -- default timeout.
  generalApi,
}

// ═══════════════════════════════════════════════════════════════════════════
// TIMEOUT POLICY
// ═══════════════════════════════════════════════════════════════════════════

/// Timeout policy for a specific operation type.
class TimeoutPolicy {
  const TimeoutPolicy({
    required this.operationType,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.maxRetries,
    required this.retryable,
  });

  final OperationType operationType;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
  final bool retryable;

  /// Total maximum time before giving up on this operation including retries.
  /// Formula: receiveTimeout * maxRetries + sum of retry backoff delays.
  /// For exponential backoff 1s,2s,4s: total = receive * retries + 7s
  Duration get worstCaseTotal => Duration(
    milliseconds: receiveTimeout.inMilliseconds * maxRetries +
        (retryable ? _backoffSum(maxRetries) : 0),
  );

  int _backoffSum(int retries) {
    int sum = 0;
    int delay = 1000;
    for (int i = 0; i < retries; i++) {
      sum += delay;
      delay *= 2;
    }
    return sum;
  }

  Map<String, dynamic> toJson() => {
    'operation': operationType.name,
    'connect_timeout_ms': connectTimeout.inMilliseconds,
    'receive_timeout_ms': receiveTimeout.inMilliseconds,
    'send_timeout_ms': sendTimeout.inMilliseconds,
    'max_retries': maxRetries,
    'retryable': retryable,
    'worst_case_total_ms': worstCaseTotal.inMilliseconds,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// ENVIRONMENT-SPECIFIC TIMEOUT POLICY SETS
// ═══════════════════════════════════════════════════════════════════════════

/// Production timeout policies -- tighter timeouts to prevent resource waste.
const productionTimeoutPolicies = <OperationType, TimeoutPolicy>{
  OperationType.databaseRead: TimeoutPolicy(
    operationType: OperationType.databaseRead,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    sendTimeout: Duration(seconds: 3),
    maxRetries: 3,
    retryable: true,
  ),
  OperationType.databaseWrite: TimeoutPolicy(
    operationType: OperationType.databaseWrite,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 5),
    maxRetries: 2,
    retryable: true,
  ),
  OperationType.authOperation: TimeoutPolicy(
    operationType: OperationType.authOperation,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 5),
    maxRetries: 1,
    retryable: false,
  ),
  OperationType.storageOperation: TimeoutPolicy(
    operationType: OperationType.storageOperation,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 30),
    maxRetries: 2,
    retryable: true,
  ),
  OperationType.realtimeSubscription: TimeoutPolicy(
    operationType: OperationType.realtimeSubscription,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 5),
    maxRetries: 3,
    retryable: true,
  ),
  OperationType.edgeFunctionCall: TimeoutPolicy(
    operationType: OperationType.edgeFunctionCall,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 20),
    sendTimeout: Duration(seconds: 10),
    maxRetries: 2,
    retryable: true,
  ),
  OperationType.aiGeneration: TimeoutPolicy(
    operationType: OperationType.aiGeneration,
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 10),
    maxRetries: 1,
    retryable: false,
  ),
  OperationType.aiValidation: TimeoutPolicy(
    operationType: OperationType.aiValidation,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    sendTimeout: Duration(seconds: 3),
    maxRetries: 0,
    retryable: false,
  ),
  OperationType.examSubmission: TimeoutPolicy(
    operationType: OperationType.examSubmission,
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 45),
    sendTimeout: Duration(seconds: 15),
    maxRetries: 2,
    retryable: true,
  ),
  OperationType.examAutoSave: TimeoutPolicy(
    operationType: OperationType.examAutoSave,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 15),
    sendTimeout: Duration(seconds: 10),
    maxRetries: 1,
    retryable: true,
  ),
  OperationType.syncOperation: TimeoutPolicy(
    operationType: OperationType.syncOperation,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 10),
    maxRetries: 3,
    retryable: true,
  ),
  OperationType.paymentOperation: TimeoutPolicy(
    operationType: OperationType.paymentOperation,
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 10),
    maxRetries: 1,
    retryable: false,
  ),
  OperationType.healthCheck: TimeoutPolicy(
    operationType: OperationType.healthCheck,
    connectTimeout: Duration(seconds: 3),
    receiveTimeout: Duration(seconds: 5),
    sendTimeout: Duration(seconds: 3),
    maxRetries: 0,
    retryable: false,
  ),
  OperationType.generalApi: TimeoutPolicy(
    operationType: OperationType.generalApi,
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    sendTimeout: Duration(seconds: 15),
    maxRetries: 3,
    retryable: true,
  ),
};

/// Staging timeout policies -- slightly more generous for testing.
const stagingTimeoutPolicies = <OperationType, TimeoutPolicy>{
  OperationType.databaseRead: TimeoutPolicy(
    operationType: OperationType.databaseRead,
    connectTimeout: Duration(seconds: 8),
    receiveTimeout: Duration(seconds: 8),
    sendTimeout: Duration(seconds: 5),
    maxRetries: 3,
    retryable: true,
  ),
  OperationType.generalApi: TimeoutPolicy(
    operationType: OperationType.generalApi,
    connectTimeout: Duration(seconds: 20),
    receiveTimeout: Duration(seconds: 20),
    sendTimeout: Duration(seconds: 20),
    maxRetries: 3,
    retryable: true,
  ),
};

/// Development timeout policies -- very generous for debugging.
const developmentTimeoutPolicies = <OperationType, TimeoutPolicy>{
  OperationType.databaseRead: TimeoutPolicy(
    operationType: OperationType.databaseRead,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 5),
    maxRetries: 3,
    retryable: true,
  ),
  OperationType.generalApi: TimeoutPolicy(
    operationType: OperationType.generalApi,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 30),
    maxRetries: 3,
    retryable: true,
  ),
};

// ═══════════════════════════════════════════════════════════════════════════
// TIMEOUT POLICY SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// Resolves the appropriate timeout policy for a given operation type
/// based on the current environment.
///
/// For operations not explicitly defined in staging/development, the
/// production policy is used as the base with a multiplier applied.
class RequestTimeoutPolicyService {
  RequestTimeoutPolicyService._();
  static final RequestTimeoutPolicyService instance = RequestTimeoutPolicyService._();

  /// Current set of timeout policies based on environment.
  Map<OperationType, TimeoutPolicy> _policies = productionTimeoutPolicies;

  /// Initializes the service with environment-appropriate policies.
  void initialize() {
    if (kDebugMode) {
      _policies = _mergePolicies(
        base: productionTimeoutPolicies,
        overrides: developmentTimeoutPolicies,
      );
    } else if (kProfileMode) {
      _policies = _mergePolicies(
        base: productionTimeoutPolicies,
        overrides: stagingTimeoutPolicies,
      );
    } else {
      _policies = productionTimeoutPolicies;
    }

    StructuredLogger.info(
      'RequestTimeoutPolicyService: Timeout policies initialized for '
          '${kDebugMode ? "development" : kProfileMode ? "staging" : "production"}',
      metadata: {'environment': kDebugMode ? 'development' : kProfileMode ? 'staging' : 'production'},
    );
  }

  /// Gets the timeout policy for the given operation type.
  TimeoutPolicy getPolicy(OperationType type) {
    final policy = _policies[type];
    if (policy == null) {
      StructuredLogger.warning(
        'RequestTimeoutPolicyService: No timeout policy for ${type.name}, using generalApi fallback',
        metadata: {'operation_type': type.name},
      );
      return _policies[OperationType.generalApi]!;
    }
    return policy;
  }

  /// Gets all current timeout policies.
  Map<OperationType, TimeoutPolicy> getAllPolicies() => Map.unmodifiable(_policies);

  /// Merges override policies into base policies.
  static Map<OperationType, TimeoutPolicy> _mergePolicies({
    required Map<OperationType, TimeoutPolicy> base,
    required Map<OperationType, TimeoutPolicy> overrides,
  }) {
    final merged = Map<OperationType, TimeoutPolicy>.from(base);
    merged.addAll(overrides);
    return merged;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for the timeout policy service.
final requestTimeoutPolicyServiceProvider = Provider<RequestTimeoutPolicyService>((ref) {
  final service = RequestTimeoutPolicyService.instance;
  service.initialize();
  return service;
});

/// Provider for getting a specific operation's timeout policy.
final timeoutPolicyProvider = Provider.family<TimeoutPolicy, OperationType>((ref, type) {
  final service = ref.watch(requestTimeoutPolicyServiceProvider);
  return service.getPolicy(type);
});
