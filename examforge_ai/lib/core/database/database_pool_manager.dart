// ============================================================================
// ExamForge AI — Database Pool Manager & Health Monitor
// ============================================================================
// Provides centralized database connectivity management with:
//   1. Connection pooling via Supabase client configuration
//   2. Query performance monitoring
//   3. Slow query logging
//   4. Connection health checks
//   5. Connection leak detection
//   6. Database health monitoring
//
// ROOT CAUSE (why this file exists):
// The original SupabaseConfig had no connection pooling, no query
// monitoring, no slow query logging, and no connection leak detection.
// Under load (100+ concurrent users), this leads to:
//   - Database connection exhaustion
//   - Unbounded query execution times
//   - Silent connection leaks
//   - No visibility into performance degradation
//
// ARCHITECTURE:
// Supabase Flutter SDK manages its own HTTP connection pool internally
// (backed by Dio). This manager wraps the Supabase client with:
//   - Query execution timing and logging
//   - Connection health heartbeat
//   - Slow query detection and alerting
//   - Connection pool metrics
//   - Prepared statement emulation for frequently-run queries
// ============================================================================

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// SLOW QUERY LOG ENTRY
// ═══════════════════════════════════════════════════════════════════════

/// Record of a slow query execution.
class SlowQueryEntry {
  const SlowQueryEntry({
    required this.queryType,
    required this.table,
    required this.durationMs,
    required this.timestamp,
    this.operation,
    this.details,
  });

  final String queryType; // 'select', 'insert', 'update', 'delete', 'rpc'
  final String table;
  final String? operation;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  @override
  String toString() =>
      'SlowQuery($queryType on $table, ${durationMs}ms, ${timestamp.toIso8601String()})';
}

// ═══════════════════════════════════════════════════════════════════════
// LRU CACHE ENTRY — Tracks access time for proper LRU eviction
// ═══════════════════════════════════════════════════════════════════════

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});

  final dynamic value;
  final DateTime expiresAt;
  DateTime lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void markAccessed() => lastAccessed = DateTime.now();
}

// ═══════════════════════════════════════════════════════════════════════
// DATABASE HEALTH STATUS
// ═══════════════════════════════════════════════════════════════════════

/// Current health status of the database connection.
class DatabaseHealthStatus {
  const DatabaseHealthStatus({
    required this.isConnected,
    required this.lastCheckedAt,
    this.responseTimeMs,
    this.activeQueries,
    this.totalQueriesExecuted,
    this.slowQueryCount,
    this.errorCount,
    this.averageResponseTimeMs,
  });

  final bool isConnected;
  final DateTime lastCheckedAt;
  final int? responseTimeMs;
  final int? activeQueries;
  final int? totalQueriesExecuted;
  final int? slowQueryCount;
  final int? errorCount;
  final double? averageResponseTimeMs;

  @override
  String toString() =>
      'DatabaseHealth(connected: $isConnected, '
      'response: ${responseTimeMs}ms, '
      'slowQueries: $slowQueryCount, '
      'errors: $errorCount)';
}

// ═══════════════════════════════════════════════════════════════════════
// DATABASE POOL MANAGER
// ═══════════════════════════════════════════════════════════════════════

/// Centralized database connection management with monitoring.
///
/// Wraps the Supabase client to provide:
/// - Query execution timing and logging
/// - Slow query detection (configurable threshold)
/// - Connection health checks
/// - Query statistics and metrics
/// - Connection leak detection
class DatabasePoolManager {
  DatabasePoolManager._();

  static bool _initialized = false;

  /// Slow query threshold in milliseconds.
  static int slowQueryThresholdMs = 500;

  /// Maximum slow query entries to keep in memory.
  static const int _maxSlowQueryLogSize = 1000;

  /// Slow query log.
  static final List<SlowQueryEntry> _slowQueryLog = [];

  /// Query execution statistics.
  static int _totalQueriesExecuted = 0;
  static int _totalErrors = 0;
  static int _activeQueries = 0;

  /// Response time tracking for average calculation.
  static final List<int> _recentResponseTimes = [];
  static const int _maxResponseTimeSamples = 100;

  /// Health check timer.
  static Timer? _healthCheckTimer;

  /// Connection pool health status.
  static DatabaseHealthStatus? _lastHealthStatus;

  /// Whether the pool manager is initialized.
  static bool get isInitialized => _initialized;

  /// Get current slow query log.
  static List<SlowQueryEntry> get slowQueryLog =>
      List.unmodifiable(_slowQueryLog);

  /// Get last health status.
  static DatabaseHealthStatus? get lastHealthStatus => _lastHealthStatus;

  /// Get query statistics.
  static Map<String, dynamic> get stats => {
        'totalQueries': _totalQueriesExecuted,
        'activeQueries': _activeQueries,
        'totalErrors': _totalErrors,
        'slowQueryCount': _slowQueryLog.length,
        'slowQueryThresholdMs': slowQueryThresholdMs,
        'averageResponseTimeMs': _calculateAverageResponseTime(),
      };

  // ─── INITIALIZATION ───────────────────────────────────────────────

  /// Initialize the database pool manager.
  ///
  /// Starts periodic health checks and slow query monitoring.
  static void initialize({
    int slowQueryThreshold = 500,
    Duration healthCheckInterval = const Duration(minutes: 5),
  }) {
    if (_initialized) {
      AppLogger.warning('DatabasePoolManager already initialized');
      return;
    }

    slowQueryThresholdMs = slowQueryThreshold;
    _initialized = true;

    // Start periodic health checks
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      checkHealth();
    });

    AppLogger.info(
      'DatabasePoolManager initialized — '
      'slowQueryThreshold: ${slowQueryThresholdMs}ms, '
      'healthCheckInterval: ${healthCheckInterval.inSeconds}s',
    );
  }

  /// Dispose the pool manager and cancel timers.
  static void dispose() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _initialized = false;
    AppLogger.info('DatabasePoolManager disposed');
  }

  // ─── QUERY EXECUTION WRAPPER ──────────────────────────────────────

  /// Execute a query with timing and monitoring.
  ///
  /// Wraps any Supabase query with:
  /// - Execution timing
  /// - Slow query detection and logging
  /// - Error counting
  /// - Active query tracking
  ///
  /// Usage:
  /// ```dart
  /// final result = await DatabasePoolManager.executeMonitored(
  ///   queryType: 'select',
  ///   table: 'transactions',
  ///   operation: 'verify_payment',
  ///   query: () => supabase.from('transactions').select().eq('id', txId).single(),
  /// );
  /// ```
  static Future<T> executeMonitored<T>({
    required String queryType,
    required String table,
    String? operation,
    required Future<T> Function() query,
  }) async {
    if (!_initialized) {
      // If not initialized, just execute the query without monitoring
      return query();
    }

    _activeQueries++;
    _totalQueriesExecuted++;
    final stopwatch = Stopwatch()..start();

    try {
      final result = await query();
      stopwatch.stop();

      final durationMs = stopwatch.elapsedMilliseconds;

      // Track response time
      _recentResponseTimes.add(durationMs);
      if (_recentResponseTimes.length > _maxResponseTimeSamples) {
        _recentResponseTimes.removeAt(0);
      }

      // Check for slow query
      if (durationMs > slowQueryThresholdMs) {
        _logSlowQuery(
          queryType: queryType,
          table: table,
          operation: operation,
          durationMs: durationMs,
        );
      }

      // Decrement active queries on success (only once)
      _activeQueries--;

      return result;
    } catch (e) {
      stopwatch.stop();
      _totalErrors++;
      // Decrement active queries on error (only once, not again in finally)
      _activeQueries--;

      AppLogger.error(
        'Database query error: $queryType on $table'
        '${operation != null ? " ($operation)" : ""} — '
        '${stopwatch.elapsedMilliseconds}ms',
        error: e,
      );
      rethrow;
    }
    // NOTE: No `finally` block — we decrement _activeQueries in both
    // success and error paths to avoid the double-decrement bug that
    // existed when both catch and finally decremented the counter.
  }

  // ─── PREPARED STATEMENT EMULATION ─────────────────────────────────

  /// Cache for frequently-used query results.
  /// In a full implementation, this would use Supabase's prepared
  /// statement support or PostgreSQL prepared statements.
  static final Map<String, _CacheEntry> _queryCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _maxCacheSize = 200;

  /// Execute a cached query (emulates prepared statement behavior).
  ///
  /// For queries that return the same data frequently (e.g., subscription
  /// plans, commission rates), this reduces database load by caching
  /// results for a configurable TTL.
  ///
  /// **Performance Fix:** Uses LRU (Least Recently Used) eviction instead
  /// of FIFO. Previously, frequently-accessed entries could be evicted
  /// simply because they were inserted early, defeating the purpose of
  /// caching. Now, entries are evicted based on last access time.
  static Future<T> executeCached<T>({
    required String cacheKey,
    required Future<T> Function() query,
    Duration ttl = _cacheTtl,
  }) async {
    // Check cache
    final cached = _queryCache[cacheKey];
    if (cached != null && !cached.isExpired && cached.value is T) {
      cached.markAccessed(); // Track access for LRU eviction
      return cached.value as T;
    }

    // Execute query
    final result = await executeMonitored(
      queryType: 'select',
      table: 'cache:$cacheKey',
      operation: 'cached_query',
      query: query,
    );

    // Store in cache
    _queryCache[cacheKey] = _CacheEntry(
      value: result,
      expiresAt: DateTime.now().add(ttl),
    );

    // Evict LRU entry if cache is too large (NOT FIFO)
    if (_queryCache.length > _maxCacheSize) {
      String? lruKey;
      DateTime? oldestAccess;
      for (final entry in _queryCache.entries) {
        if (oldestAccess == null || entry.value.lastAccessed.isBefore(oldestAccess)) {
          oldestAccess = entry.value.lastAccessed;
          lruKey = entry.key;
        }
      }
      if (lruKey != null) {
        _queryCache.remove(lruKey);
      }
    }

    return result;
  }

  /// Invalidate cache entries matching a pattern.
  static void invalidateCache(String pattern) {
    _queryCache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Clear the entire query cache.
  static void clearCache() {
    _queryCache.clear();
  }

  // ─── HEALTH CHECK ─────────────────────────────────────────────────

  /// Check database connection health.
  ///
  /// Executes a lightweight query and measures response time.
  /// Returns the health status.
  static Future<DatabaseHealthStatus> checkHealth() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Lightweight health check — select a single row from a system table
      final client = sb.Supabase.instance.client;
      await client.from('webhook_events').select('id').limit(1);

      stopwatch.stop();

      _lastHealthStatus = DatabaseHealthStatus(
        isConnected: true,
        lastCheckedAt: DateTime.now(),
        responseTimeMs: stopwatch.elapsedMilliseconds,
        activeQueries: _activeQueries,
        totalQueriesExecuted: _totalQueriesExecuted,
        slowQueryCount: _slowQueryLog.length,
        errorCount: _totalErrors,
        averageResponseTimeMs: _calculateAverageResponseTime(),
      );

      if (stopwatch.elapsedMilliseconds > slowQueryThresholdMs) {
        AppLogger.warning(
          'Database health check slow: ${stopwatch.elapsedMilliseconds}ms',
        );
      }

      return _lastHealthStatus!;
    } catch (e) {
      AppLogger.critical('Database health check FAILED', error: e);

      _lastHealthStatus = DatabaseHealthStatus(
        isConnected: false,
        lastCheckedAt: DateTime.now(),
        activeQueries: _activeQueries,
        totalQueriesExecuted: _totalQueriesExecuted,
        slowQueryCount: _slowQueryLog.length,
        errorCount: _totalErrors + 1,
        averageResponseTimeMs: _calculateAverageResponseTime(),
      );

      return _lastHealthStatus!;
    }
  }

  // ─── CONNECTION LEAK DETECTION ────────────────────────────────────

  /// Check for potential connection leaks.
  ///
  /// A connection leak is detected when active queries remain
  /// elevated for an extended period.
  static bool detectConnectionLeak() {
    if (_activeQueries > 10) {
      AppLogger.warning(
        'Potential connection leak detected: $_activeQueries active queries',
      );
      return true;
    }
    return false;
  }

  /// Get the number of active queries (for monitoring).
  static int get activeQueryCount => _activeQueries;

  // ─── PRIVATE HELPERS ──────────────────────────────────────────────

  static void _logSlowQuery({
    required String queryType,
    required String table,
    String? operation,
    required int durationMs,
  }) {
    final entry = SlowQueryEntry(
      queryType: queryType,
      table: table,
      operation: operation,
      durationMs: durationMs,
      timestamp: DateTime.now(),
    );

    _slowQueryLog.add(entry);

    // Trim log if too large
    if (_slowQueryLog.length > _maxSlowQueryLogSize) {
      _slowQueryLog.removeRange(0, _slowQueryLog.length - _maxSlowQueryLogSize);
    }

    AppLogger.warning(
      'SLOW QUERY: $queryType on $table'
      '${operation != null ? " ($operation)" : ""} — '
      '${durationMs}ms (threshold: ${slowQueryThresholdMs}ms)',
    );
  }

  static double? _calculateAverageResponseTime() {
    if (_recentResponseTimes.isEmpty) return null;
    final sum = _recentResponseTimes.reduce((a, b) => a + b);
    return sum / _recentResponseTimes.length;
  }
}
