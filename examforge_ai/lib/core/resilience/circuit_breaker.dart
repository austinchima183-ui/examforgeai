// ============================================================================
// ExamForge AI — Circuit Breaker Pattern Implementation
// ============================================================================
//
// Implements the circuit breaker pattern for network resilience. When a
// downstream service (Supabase, AI provider, Edge Function) repeatedly fails,
// the circuit "opens" to prevent cascading failures, allowing the system to
// gracefully degrade rather than exhaust resources on doomed requests.
//
// States:
//   - CLOSED: Normal operation. Requests flow through. Failures are counted.
//   - OPEN: Circuit is tripped. All requests are immediately rejected with
//     a CircuitOpenException, preventing resource waste. A timer runs
//     before transitioning to HALF-OPEN for a probe request.
//   - HALF-OPEN: A single probe request is allowed. If it succeeds, the
//     circuit closes. If it fails, the circuit reopens.
//
// ROOT CAUSE: The project has retry policies (ApiClient._guard, SyncEngine,
// LogShippingService) but NO circuit breaker. Without a circuit breaker,
// repeated failures to an unavailable service (e.g. Supabase DB outage)
// cause every request to exhaust retry attempts (3x with exponential backoff
// = up to 15s per request), multiplying latency across all callers. The
// circuit breaker short-circuits these doomed requests, reducing latency
// from minutes of retry exhaustion to milliseconds of fast-failure.
//
// SECURITY: Circuit state is never logged with sensitive request payloads.
// Only service names, failure counts, and timing data are recorded.
//
// PERFORMANCE: Circuit breaker checks are O(1) -- a single state comparison.
// State transitions are atomic via Dart's single-threaded event loop.
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/structured_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT STATES
// ═══════════════════════════════════════════════════════════════════════════

/// The three states of a circuit breaker.
enum CircuitState {
  /// Normal operation -- requests flow through.
  closed,

  /// Circuit is tripped -- requests are immediately rejected.
  open,

  /// Probing state -- one request is allowed to test if the service recovered.
  halfOpen,
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════

/// Exception thrown when a circuit is open and a request is rejected.
///
/// Callers should treat this as a signal to use fallback/cached data
/// rather than retrying -- the circuit will automatically probe the
/// service after its reset timeout.
class CircuitOpenException implements Exception {
  const CircuitOpenException({
    required this.serviceName,
    required this.circuitState,
    this.retryAfterMs,
  });

  final String serviceName;
  final CircuitState circuitState;
  final int? retryAfterMs;

  @override
  String toString() =>
      'CircuitOpenException: Circuit for "$serviceName" is ${circuitState.name}.'
      '${retryAfterMs != null ? ' Retry after ${retryAfterMs}ms.' : ''}';
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

/// Configuration for a single circuit breaker instance.
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    required this.serviceName,
    this.failureThreshold = 5,
    this.successThreshold = 3,
    this.resetTimeoutMs = 30000,
    this.halfOpenMaxRequests = 1,
    this.slidingWindowMs = 60000,
    this.monitoringIntervalMs = 10000,
  });

  /// Human-readable name of the protected service (e.g. 'supabase_database').
  final String serviceName;

  /// Number of consecutive failures required to trip the circuit open.
  final int failureThreshold;

  /// Number of consecutive successes required to close a half-open circuit.
  final int successThreshold;

  /// Milliseconds to wait before transitioning from OPEN to HALF-OPEN.
  /// Default 30s -- balances recovery speed with resource protection.
  final int resetTimeoutMs;

  /// Number of probe requests allowed in HALF-OPEN state.
  /// Default 1 -- only one request tests the service at a time.
  final int halfOpenMaxRequests;

  /// Sliding window duration in ms for counting recent failures.
  /// Failures outside this window don't count toward the threshold.
  final int slidingWindowMs;

  /// Interval in ms for periodic circuit state logging (observability).
  final int monitoringIntervalMs;
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER
// ═══════════════════════════════════════════════════════════════════════════

/// A circuit breaker that protects against cascading failures from an
/// unavailable downstream service.
///
/// Usage:
/// ```dart
/// final dbCircuit = CircuitBreaker(CircuitBreakerConfig(
///   serviceName: 'supabase_database',
///   failureThreshold: 5,
/// ));
///
/// try {
///   final result = await dbCircuit.execute(() => supabase.from('users').select());
/// } on CircuitOpenException {
///   // Use cached/fallback data
///   return localCache.get('users');
/// }
/// ```
class CircuitBreaker {
  CircuitBreaker(this._config) {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _halfOpenRequestCount = 0;
    _lastFailureTime = null;
    _openedAt = null;
    _recentFailures = [];
    _startMonitoring();
  }

  final CircuitBreakerConfig _config;

  late CircuitState _state;
  late int _failureCount;
  late int _successCount;
  late int _halfOpenRequestCount;
  DateTime? _lastFailureTime;
  DateTime? _openedAt;
  Timer? _resetTimer;
  Timer? _monitoringTimer;
  late final List<DateTime> _recentFailures;

  // ─── Public Accessors ─────────────────────────────────────────────────

  /// Current state of the circuit.
  CircuitState get state => _state;

  /// Number of consecutive failures in the current window.
  int get failureCount => _failureCount;

  /// Number of consecutive successes (used in HALF-OPEN to CLOSED transition).
  int get successCount => _successCount;

  /// When the circuit last transitioned to OPEN (null if currently closed).
  DateTime? get openedAt => _openedAt;

  /// Service name this circuit protects.
  String get serviceName => _config.serviceName;

  // ─── Execution ────────────────────────────────────────────────────────

  /// Executes [action] through the circuit breaker.
  ///
  /// - CLOSED: action is executed normally. On success, failure count resets.
  ///   On failure, failure count increments. If threshold reached, OPEN.
  /// - OPEN: immediately throws [CircuitOpenException]. No action is executed.
  /// - HALF-OPEN: action is executed as a probe. Success increments success
  ///   count (CLOSED if threshold met). Failure reopens the circuit.
  Future<T> execute<T>(Future<T> Function() action) async {
    // Check if the reset timeout has elapsed (OPEN to HALF-OPEN transition)
    if (_state == CircuitState.open) {
      final now = DateTime.now();
      final elapsedMs = _openedAt != null
          ? now.difference(_openedAt!).inMilliseconds
          : _config.resetTimeoutMs;

      if (elapsedMs >= _config.resetTimeoutMs) {
        _transitionTo(CircuitState.halfOpen);
        StructuredLogger.security(
          event: 'circuit_half_open',
          severity: 'info',
          metadata: {
            'service': _config.serviceName,
            'elapsed_ms': elapsedMs,
          },
        );
      } else {
        final retryAfterMs = _config.resetTimeoutMs - elapsedMs;
        throw CircuitOpenException(
          serviceName: _config.serviceName,
          circuitState: _state,
          retryAfterMs: retryAfterMs,
        );
      }
    }

    // HALF-OPEN: limit concurrent probe requests
    if (_state == CircuitState.halfOpen) {
      if (_halfOpenRequestCount >= _config.halfOpenMaxRequests) {
        throw CircuitOpenException(
          serviceName: _config.serviceName,
          circuitState: _state,
          retryAfterMs: _config.resetTimeoutMs,
        );
      }
      _halfOpenRequestCount++;
    }

    // Execute the action
    try {
      final result = await action();
      _recordSuccess();
      return result;
    } catch (e) {
      _recordFailure();
      rethrow;
    }
  }

  // ─── State Recording ──────────────────────────────────────────────────

  /// Records a successful request through the circuit.
  void _recordSuccess() {
    switch (_state) {
      case CircuitState.closed:
        // Reset failure count on success in closed state
        _failureCount = 0;
        _recentFailures.clear();

      case CircuitState.halfOpen:
        _successCount++;
        if (_successCount >= _config.successThreshold) {
          _transitionTo(CircuitState.closed);
          StructuredLogger.security(
            event: 'circuit_closed',
            severity: 'info',
            metadata: {
              'service': _config.serviceName,
              'success_count': _successCount,
            },
          );
        }

      case CircuitState.open:
        // Should not happen -- open state rejects all requests
        break;
    }
  }

  /// Records a failed request through the circuit.
  void _recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    _recentFailures.add(_lastFailureTime!);

    // Prune failures outside the sliding window
    _pruneRecentFailures();

    switch (_state) {
      case CircuitState.closed:
        if (_recentFailures.length >= _config.failureThreshold) {
          _transitionTo(CircuitState.open);
          StructuredLogger.security(
            event: 'circuit_opened',
            severity: 'warning',
            metadata: {
              'service': _config.serviceName,
              'failure_count': _recentFailures.length,
              'threshold': _config.failureThreshold,
            },
          );
        }

      case CircuitState.halfOpen:
        // Probe failed -- reopen the circuit
        _transitionTo(CircuitState.open);
        StructuredLogger.security(
          event: 'circuit_reopened',
          severity: 'warning',
          metadata: {
            'service': _config.serviceName,
            'probe_failure': true,
          },
        );

      case CircuitState.open:
        break;
    }
  }

  /// Prunes failure timestamps outside the sliding window.
  void _pruneRecentFailures() {
    final cutoff = DateTime.now().subtract(
      Duration(milliseconds: _config.slidingWindowMs),
    );
    _recentFailures.removeWhere((t) => t.isBefore(cutoff));
  }

  // ─── State Transitions ────────────────────────────────────────────────

  void _transitionTo(CircuitState newState) {
    final oldState = _state;
    _state = newState;

    switch (newState) {
      case CircuitState.closed:
        _failureCount = 0;
        _successCount = 0;
        _halfOpenRequestCount = 0;
        _recentFailures.clear();
        _openedAt = null;
        _resetTimer?.cancel();

      case CircuitState.open:
        _successCount = 0;
        _halfOpenRequestCount = 0;
        _openedAt = DateTime.now();
        // Start timer for OPEN to HALF-OPEN transition
        _resetTimer?.cancel();
        _resetTimer = Timer(
          Duration(milliseconds: _config.resetTimeoutMs),
          () {
            if (_state == CircuitState.open) {
              _transitionTo(CircuitState.halfOpen);
            }
          },
        );

      case CircuitState.halfOpen:
        _successCount = 0;
        _halfOpenRequestCount = 0;
        _resetTimer?.cancel();
    }

    StructuredLogger.info(
      'CircuitBreaker: ${_config.serviceName} state transition ${oldState.name} to ${newState.name}',
      metadata: {'service': _config.serviceName, 'old_state': oldState.name, 'new_state': newState.name},
    );
  }

  // ─── Monitoring ───────────────────────────────────────────────────────

  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      Duration(milliseconds: _config.monitoringIntervalMs),
      (_) => _logCircuitState(),
    );
  }

  void _logCircuitState() {
    StructuredLogger.info(
      'CircuitBreaker: ${_config.serviceName} state=${_state.name} failures=$failureCount successes=$successCount',
      metadata: {'service': _config.serviceName, 'state': _state.name},
    );
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────

  /// Disposes timers and cancels monitoring.
  void dispose() {
    _resetTimer?.cancel();
    _monitoringTimer?.cancel();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCUIT BREAKER MANAGER
// ═══════════════════════════════════════════════════════════════════════════

/// Manages all circuit breaker instances for the application.
///
/// Provides a centralized registry so that any service can access its
/// circuit breaker without manual wiring. Each protected service gets
/// its own circuit with environment-appropriate thresholds.
class CircuitBreakerManager {
  CircuitBreakerManager._();
  static final CircuitBreakerManager _instance = CircuitBreakerManager._();
  static CircuitBreakerManager get instance => _instance;

  final Map<String, CircuitBreaker> _circuits = {};

  /// Registers a circuit breaker for [serviceName].
  void register(CircuitBreakerConfig config) {
    if (_circuits.containsKey(config.serviceName)) {
      StructuredLogger.warning(
        'CircuitBreakerManager: Circuit for "${config.serviceName}" already registered',
        metadata: {'service': config.serviceName},
      );
      return;
    }
    _circuits[config.serviceName] = CircuitBreaker(config);
  }

  /// Gets the circuit breaker for [serviceName], or throws if not found.
  CircuitBreaker get(String serviceName) {
    final circuit = _circuits[serviceName];
    if (circuit == null) {
      throw StateError(
        'No circuit breaker registered for "$serviceName". '
        'Call CircuitBreakerManager.instance.register() first.',
      );
    }
    return circuit;
  }

  /// Gets all registered circuit breakers.
  Map<String, CircuitBreaker> get all => Map.unmodifiable(_circuits);

  /// Disposes all circuit breakers.
  void disposeAll() {
    for (final circuit in _circuits.values) {
      circuit.dispose();
    }
    _circuits.clear();
  }

  /// Returns a snapshot of all circuit states for observability dashboards.
  Map<String, CircuitStateSnapshot> snapshot() {
    return _circuits.map((name, circuit) => MapEntry(
      name,
      CircuitStateSnapshot(
        serviceName: name,
        state: circuit.state,
        failureCount: circuit.failureCount,
        successCount: circuit.successCount,
        openedAt: circuit.openedAt,
      ),
    ),);
  }
}

/// Immutable snapshot of a circuit breaker's current state.
class CircuitStateSnapshot {
  const CircuitStateSnapshot({
    required this.serviceName,
    required this.state,
    required this.failureCount,
    required this.successCount,
    this.openedAt,
  });

  final String serviceName;
  final CircuitState state;
  final int failureCount;
  final int successCount;
  final DateTime? openedAt;

  bool get isOpen => state == CircuitState.open;
  bool get isHalfOpen => state == CircuitState.halfOpen;
  bool get isClosed => state == CircuitState.closed;

  Map<String, dynamic> toJson() => {
    'service_name': serviceName,
    'state': state.name,
    'failure_count': failureCount,
    'success_count': successCount,
    'opened_at': openedAt?.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTION CIRCUIT CONFIGURATIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Pre-configured circuit breaker configs for ExamForge AI's services.
///
/// Thresholds are tuned for each service's characteristics:
/// - Database: tolerant of brief blips (5 failures, 30s reset) because
///   Supabase can recover quickly from transient load spikes.
/// - AI Provider: more conservative (3 failures, 60s reset) because
///   AI latency spikes are often sustained and probing too frequently
///   wastes rate-limited API quota.
/// - Edge Functions: moderate thresholds (4 failures, 45s reset) --
///   Edge Functions are lightweight and typically recover quickly.
class ProductionCircuitConfigs {
  ProductionCircuitConfigs._();

  static const supabaseDatabase = CircuitBreakerConfig(
    serviceName: 'supabase_database',
    failureThreshold: 5,
    successThreshold: 3,
    resetTimeoutMs: 30000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  static const supabaseAuth = CircuitBreakerConfig(
    serviceName: 'supabase_auth',
    failureThreshold: 5,
    successThreshold: 2,
    resetTimeoutMs: 30000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  static const supabaseStorage = CircuitBreakerConfig(
    serviceName: 'supabase_storage',
    failureThreshold: 4,
    successThreshold: 2,
    resetTimeoutMs: 30000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  static const supabaseRealtime = CircuitBreakerConfig(
    serviceName: 'supabase_realtime',
    failureThreshold: 3,
    successThreshold: 3,
    resetTimeoutMs: 15000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 30000,
  );

  static const supabaseEdgeFunctions = CircuitBreakerConfig(
    serviceName: 'supabase_edge_functions',
    failureThreshold: 4,
    successThreshold: 2,
    resetTimeoutMs: 45000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  static const aiProvider = CircuitBreakerConfig(
    serviceName: 'ai_provider',
    failureThreshold: 3,
    successThreshold: 2,
    resetTimeoutMs: 60000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  static const notificationService = CircuitBreakerConfig(
    serviceName: 'notification_service',
    failureThreshold: 5,
    successThreshold: 3,
    resetTimeoutMs: 30000,
    halfOpenMaxRequests: 1,
    slidingWindowMs: 60000,
  );

  /// All production circuit configs as a list for bulk registration.
  static List<CircuitBreakerConfig> get all => [
    supabaseDatabase,
    supabaseAuth,
    supabaseStorage,
    supabaseRealtime,
    supabaseEdgeFunctions,
    aiProvider,
    notificationService,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for the circuit breaker manager singleton.
final circuitBreakerManagerProvider = Provider<CircuitBreakerManager>((ref) {
  final manager = CircuitBreakerManager.instance;

  // Register all production circuits
  for (final config in ProductionCircuitConfigs.all) {
    manager.register(config);
  }

  // Clean up on disposal
  ref.onDispose(() => manager.disposeAll());

  return manager;
});

/// Provider that exposes a snapshot of all circuit breaker states.
/// Refreshes every 30 seconds for dashboard updates.
final circuitBreakerSnapshotProvider = StreamProvider<Map<String, CircuitStateSnapshot>>((ref) {
  final manager = ref.watch(circuitBreakerManagerProvider);

  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => manager.snapshot(),
  );
});

/// Provider for individual circuit breaker access by service name.
final circuitBreakerProvider = Provider.family<CircuitBreaker, String>((ref, serviceName) {
  final manager = ref.watch(circuitBreakerManagerProvider);
  return manager.get(serviceName);
});
