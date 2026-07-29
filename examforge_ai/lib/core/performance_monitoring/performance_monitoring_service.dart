import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../memory_optimization/memory_optimization_service.dart';
import '../realtime_optimization/optimized_realtime_manager.dart';
import '../startup_optimization/startup_optimizer.dart';
import '../network_optimization/network_optimization_service.dart';
import '../database/database_pool_manager.dart';
import '../performance/performance_manager.dart' show Disposable;

// ═══════════════════════════════════════════════════════════════════════
// PERFORMANCE MONITORING SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Centralized metrics collection from all optimization services
// Metrics: startup, memory, network, realtime, database, AI
// ═══════════════════════════════════════════════════════════════════════

class AlertThresholds {
  const AlertThresholds({
    this.startupMs = 2000,
    this.maxResources = 50,
    this.minCacheHitRate = 60,
    this.maxActiveQueries = 10,
    this.maxRealtimeChannels = 8,
    this.maxMemoryMB = 200,
  });
  final int startupMs;
  final int maxResources;
  final int minCacheHitRate;
  final int maxActiveQueries;
  final int maxRealtimeChannels;
  final int maxMemoryMB;
}

class PerformanceMonitoringService implements Disposable {
  PerformanceMonitoringService({
    this.reportingIntervalMs = 60000,
    this.alertThresholds = const AlertThresholds(),
  });

  final int reportingIntervalMs;
  final AlertThresholds alertThresholds;
  Timer? _reportingTimer;
  final List<Map<String, dynamic>> _metricsHistory = [];
  static const int _maxHistorySize = 1440;

  DatabasePoolManager? _dbPoolManager;
  OptimizedRealtimeManager? _realtimeManager;
  NetworkOptimizationService? _networkService;
  MemoryPressureDetector? _memoryDetector;

  void initialize({
    DatabasePoolManager? dbPoolManager,
    OptimizedRealtimeManager? realtimeManager,
    NetworkOptimizationService? networkService,
    MemoryPressureDetector? memoryDetector,
  }) {
    _dbPoolManager = dbPoolManager;
    _realtimeManager = realtimeManager;
    _networkService = networkService;
    _memoryDetector = memoryDetector;

    _reportingTimer = Timer.periodic(
      Duration(milliseconds: reportingIntervalMs),
      (_) => collectAndReport(),
    );
    AppLogger.info('PerformanceMonitoringService initialized');
  }

  Map<String, dynamic> collectMetrics() {
    final timestamp = DateTime.now().toIso8601String();
    return {
      'timestamp': timestamp,
      'startup': StartupOptimizer.instance.startupReport,
      'memory': ResourceTracker.instance.leakReport(),
      'memory_pressure': _memoryDetector?.stats ?? {},
      'network': _networkService?.performanceStats ?? {},
      'realtime': _realtimeManager?.performanceStats ?? {},
      'database': DatabasePoolManager.stats,
    };
  }

  void collectAndReport() {
    final metrics = collectMetrics();
    _metricsHistory.add(metrics);
    if (_metricsHistory.length > _maxHistorySize) {
      _metricsHistory.removeAt(0);
    }
    _checkAlerts(metrics);
  }

  void _checkAlerts(Map<String, dynamic> metrics) {
    final startupMs = metrics['startup']?['total_startup_ms'] as int?;
    if (startupMs != null && startupMs > alertThresholds.startupMs) {
      AppLogger.warning('ALERT: Startup ${startupMs}ms > threshold ${alertThresholds.startupMs}ms');
    }

    final resources = metrics['memory']?['total_resources'] as int?;
    if (resources != null && resources > alertThresholds.maxResources) {
      AppLogger.warning('ALERT: ${resources} resources > threshold ${alertThresholds.maxResources}');
    }

    final cacheHit = metrics['network']?['cache_hit_rate_percent'] as int?;
    if (cacheHit != null && cacheHit < alertThresholds.minCacheHitRate) {
      AppLogger.warning('ALERT: Cache hit ${cacheHit}% < threshold ${alertThresholds.minCacheHitRate}%');
    }
  }

  Map<String, dynamic> get latestMetrics =>
      _metricsHistory.isNotEmpty ? _metricsHistory.last : collectMetrics();

  Map<String, dynamic> generateDashboardReport() {
    final current = collectMetrics();
    return {
      'current': current,
      'history_size': _metricsHistory.length,
      'alerts': _checkAlertsSummary(current),
      'recommendations': _generateRecommendations(current),
    };
  }

  List<String> _checkAlertsSummary(Map<String, dynamic> metrics) {
    final alerts = <String>[];
    final startupMs = metrics['startup']?['total_startup_ms'] as int?;
    if (startupMs != null && startupMs > alertThresholds.startupMs) {
      alerts.add('Startup time exceeds threshold');
    }
    final resources = metrics['memory']?['total_resources'] as int?;
    if (resources != null && resources > alertThresholds.maxResources) {
      alerts.add('Resource count exceeds threshold');
    }
    return alerts;
  }

  List<String> _generateRecommendations(Map<String, dynamic> metrics) {
    final recs = <String>[];
    final cacheHit = metrics['network']?['cache_hit_rate_percent'] as int?;
    if (cacheHit != null && cacheHit < 50) {
      recs.add('Increase cache TTL — hit rate below 50%');
    }
    final channels = metrics['realtime']?['active_channels'] as int?;
    if (channels != null && channels > 5) {
      recs.add('Review realtime subscriptions — consider channel consolidation');
    }
    return recs;
  }

  @override
  void dispose() {
    _reportingTimer?.cancel();
    _reportingTimer = null;
    AppLogger.info('PerformanceMonitoringService disposed');
  }
}

final performanceMonitoringServiceProvider = Provider<PerformanceMonitoringService>((ref) {
  final service = PerformanceMonitoringService();
  ref.onDispose(() => service.dispose());
  return service;
});

final performanceDashboardProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(performanceMonitoringServiceProvider).generateDashboardReport();
});

final latestMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(performanceMonitoringServiceProvider).latestMetrics;
});

final alertThresholdsProvider = Provider<AlertThresholds>((ref) {
  return const AlertThresholds();
});
