// ============================================================================
// ExamForge AI — Graceful Degradation Service
// ============================================================================
//
// Orchestrates application behavior during service outages by selecting
// appropriate fallback strategies based on circuit breaker states and
// connectivity quality. When a circuit breaker is open for a service,
// this module provides the fallback behavior rather than letting the
// request fail and propagate to the user.
//
// ROOT CAUSE: The ConnectivityEngine's AdaptiveBehavior class handles
// connectivity-quality-based degradation (image quality, sync intervals,
// etc.), but it does NOT handle service-specific outages. When Supabase
// DB is down, AdaptiveBehavior doesn't know -- it only knows about
// network quality. The CircuitBreaker knows about service health but
// doesn't provide fallback data. This module bridges both: it reads
// circuit breaker states + connectivity quality and provides concrete
// fallback strategies per feature module.
//
// DEGRADATION LEVELS:
//   - Level 0 (Full): All services operational, normal behavior.
//   - Level 1 (Minor): One non-critical service is degraded (e.g. AI hints).
//     Core features still work. Reduced functionality.
//   - Level 2 (Major): A critical service is degraded (e.g. database).
//     Core features use local cache. Write operations queued for sync.
//   - Level 3 (Severe): Multiple services offline. Minimal functionality.
//     Only offline exam mode and local data available.
//   - Level 4 (Emergency): Database AND auth offline. Only cached data.
//     Exam in progress continues locally. No new sessions.
//
// SECURITY: Degradation decisions never expose service names or error
// details to the UI. Users only see: "Some features temporarily reduced."
//
// PERFORMANCE: Degradation level check is O(n) where n = number of
// circuit breakers (7). Constant and negligible overhead.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_engine.dart';
import '../logging/structured_logger.dart';
import 'circuit_breaker.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DEGRADATION LEVELS
// ═══════════════════════════════════════════════════════════════════════════

/// Degradation level from 0 (full service) to 4 (emergency).
enum DegradationLevel {
  /// All services operational. Normal behavior.
  full(0, 'All services operational'),

  /// One non-critical service degraded. Core features still work.
  minor(1, 'Reduced: Some features temporarily limited'),

  /// A critical service degraded. Using local cache for reads.
  major(2, 'Limited: Core features using cached data'),

  /// Multiple services offline. Minimal functionality.
  severe(3, 'Offline mode: Only local data available'),

  /// Database AND auth offline. Emergency: only ongoing exams continue.
  emergency(4, 'Critical: Only in-progress exams continue locally');

  const DegradationLevel(this.level, this.userMessage);
  final int level;
  final String userMessage;
}

// ═══════════════════════════════════════════════════════════════════════════
// DEGRADATION DECISION
// ═══════════════════════════════════════════════════════════════════════════

/// A concrete degradation decision with the level, affected services,
/// and recommended fallback strategies.
class DegradationDecision {
  const DegradationDecision({
    required this.level,
    required this.affectedServices,
    required this.fallbackStrategies,
    required this.isOnline,
  });

  final DegradationLevel level;
  final List<String> affectedServices;
  final Map<String, String> fallbackStrategies;
  final bool isOnline;

  /// Whether the user should see a degradation banner.
  bool get showBanner => level.level >= 1;

  /// Whether offline exam mode should be activated.
  bool get useOfflineExam => level.level >= 2;

  /// Whether writes should be queued for later sync.
  bool get queueWrites => level.level >= 2;

  /// Whether AI features should be disabled.
  bool get disableAi => level.level >= 1;

  /// Whether new exam sessions should be blocked.
  bool get blockNewExams => level.level >= 4;

  /// Whether only cached data should be shown.
  bool get useCacheOnly => level.level >= 2;

  Map<String, dynamic> toJson() => {
    'level': level.level,
    'level_name': level.name,
    'user_message': level.userMessage,
    'affected_services': affectedServices,
    'fallback_strategies': fallbackStrategies,
    'is_online': isOnline,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// GRACEFUL DEGRADATION SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// Computes the current degradation level based on circuit breaker states
/// and connectivity quality. Provides fallback strategy recommendations.
class GracefulDegradationService {
  GracefulDegradationService._();
  static final GracefulDegradationService instance = GracefulDegradationService._();

  /// Computes the current degradation decision.
  ///
  /// Decision logic (evidence-based rules):
  ///   - If offline → Level 3 (Severe) or Level 4 (Emergency)
  ///   - If DB circuit open → at least Level 2 (Major)
  ///   - If auth circuit open → at least Level 2 (Major)
  ///   - If DB AND auth open → Level 4 (Emergency)
  ///   - If AI circuit open → Level 1 (Minor)
  ///   - If realtime open → Level 1 (Minor)
  ///   - If storage open → Level 1 (Minor)
  ///   - If edge functions open → Level 1 (Minor)
  ///   - Multiple minor degradations → Level 2 (Major)
  DegradationDecision compute({
    required Map<String, CircuitStateSnapshot> circuitStates,
    required bool isOnline,
    required ConnectionQuality connectionQuality,
  }) {
    final affected = <String>[];
    final strategies = <String, String>{};
    var level = DegradationLevel.full;

    // Check each circuit breaker state
    final dbState = circuitStates['supabase_database']?.state;
    final authState = circuitStates['supabase_auth']?.state;
    final realtimeState = circuitStates['supabase_realtime']?.state;
    final storageState = circuitStates['supabase_storage']?.state;
    final aiState = circuitStates['ai_provider']?.state;
    final edgeState = circuitStates['supabase_edge_functions']?.state;
    final notifState = circuitStates['notification_service']?.state;

    // Database outage is critical
    if (dbState == CircuitState.open || dbState == CircuitState.halfOpen) {
      affected.add('supabase_database');
      strategies['database'] = 'Use local Drift cache for reads, queue writes for sync';
      level = DegradationLevel.major;
    }

    // Auth outage is critical
    if (authState == CircuitState.open || authState == CircuitState.halfOpen) {
      affected.add('supabase_auth');
      strategies['auth'] = 'Use cached session, block new logins, refresh on reconnect';
      if (level.level < 2) {
        level = DegradationLevel.major;
      }
    }

    // If BOTH DB and auth are open → Emergency
    if ((dbState == CircuitState.open || dbState == CircuitState.halfOpen) &&
        (authState == CircuitState.open || authState == CircuitState.halfOpen)) {
      level = DegradationLevel.emergency;
      strategies['combined'] = 'Only in-progress exams continue locally';
    }

    // AI outage is minor (non-critical service)
    if (aiState == CircuitState.open || aiState == CircuitState.halfOpen) {
      affected.add('ai_provider');
      strategies['ai'] = 'Disable AI hints and question generation, show manual alternatives';
      if (level.level < 1) {
        level = DegradationLevel.minor;
      }
    }

    // Realtime outage is minor
    if (realtimeState == CircuitState.open || realtimeState == CircuitState.halfOpen) {
      affected.add('supabase_realtime');
      strategies['realtime'] = 'Use polling fallback instead of live updates';
      if (level.level < 1) {
        level = DegradationLevel.minor;
      }
    }

    // Storage outage is minor
    if (storageState == CircuitState.open || storageState == CircuitState.halfOpen) {
      affected.add('supabase_storage');
      strategies['storage'] = 'Disable file uploads, show cached images only';
      if (level.level < 1) {
        level = DegradationLevel.minor;
      }
    }

    // Edge functions outage is minor
    if (edgeState == CircuitState.open || edgeState == CircuitState.halfOpen) {
      affected.add('supabase_edge_functions');
      strategies['edge_functions'] = 'Use direct Supabase client calls instead of Edge Functions';
      if (level.level < 1) {
        level = DegradationLevel.minor;
      }
    }

    // Notification outage is minor
    if (notifState == CircuitState.open || notifState == CircuitState.halfOpen) {
      affected.add('notification_service');
      strategies['notifications'] = 'Show notifications in-app only, no push';
      if (level.level < 1) {
        level = DegradationLevel.minor;
      }
    }

    // Multiple minor degradations escalate to major
    final minorOutages = affected.where((s) =>
      s != 'supabase_database' && s != 'supabase_auth'
    ).length;
    if (minorOutages >= 3 && level.level < 2) {
      level = DegradationLevel.major;
      strategies['multiple'] = 'Multiple services degraded, using comprehensive offline fallback';
    }

    // If completely offline, upgrade to severe
    if (!isOnline) {
      if (level.level < 3) {
        level = DegradationLevel.severe;
      }
      strategies['network'] = 'Offline mode: All data from local cache';
    }

    // Log degradation state for observability
    if (level != DegradationLevel.full) {
      StructuredLogger.warning(
        'GracefulDegradation: Level ${level.name} (${affected.length} services affected)',
        metadata: {'level': level.name, 'affected_count': affected.length, 'services': affected},
      );
    }

    return DegradationDecision(
      level: level,
      affectedServices: affected,
      fallbackStrategies: strategies,
      isOnline: isOnline,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for the graceful degradation service.
final gracefulDegradationServiceProvider = Provider<GracefulDegradationService>((ref) {
  return GracefulDegradationService.instance;
});

/// Provider that computes the current degradation decision.
/// Watches circuit breaker states and connectivity quality.
final degradationDecisionProvider = Provider<DegradationDecision>((ref) {
  final manager = ref.watch(circuitBreakerManagerProvider);
  final circuitStates = manager.snapshot();
  final isOnline = ref.watch(isOnlineProvider);
  final quality = ref.watch(connectionQualityProvider);

  final service = ref.watch(gracefulDegradationServiceProvider);
  return service.compute(
    circuitStates: circuitStates,
    isOnline: isOnline ?? false,
    connectionQuality: quality ?? ConnectionQuality.offline,
  );
});

/// Provider for the degradation level (convenience accessor).
final degradationLevelProvider = Provider<DegradationLevel>((ref) {
  return ref.watch(degradationDecisionProvider).level;
});
