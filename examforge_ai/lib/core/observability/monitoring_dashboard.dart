// ============================================================================
// ExamForge AI — Monitoring Dashboard Providers
// ============================================================================
//
// Riverpod providers that aggregate all observability data for the
// admin monitoring dashboard:
//   - System health
//   - Live requests (active traces)
//   - Crash count
//   - AI requests count
//   - Latency charts
//   - Exam activity
//   - Sync activity
//   - Storage usage
//   - Realtime connections
//   - Queue status
//
// ROOT CAUSE: There is no unified monitoring dashboard in the project.
// All observability data is scattered across individual services with no
// aggregated view. These providers unify the data for the dashboard UI.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_engine.dart';
import 'crash_reporter.dart';
import 'health_monitoring.dart';
import 'log_shipping.dart';
import 'metrics.dart';
import 'tracing.dart';
import 'workers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Aggregated monitoring dashboard data.
class MonitoringDashboardData {
  MonitoringDashboardData({
    required this.systemHealth,
    required this.crashCount,
    required this.activeAlerts,
    required this.activeTraces,
    required this.completedTraces,
    required this.latencyStats,
    required this.workerStatus,
    required this.logShippingStatus,
    required this.metricsSnapshot,
    required this.timestamp,
  });

  final HealthStatus systemHealth;
  final int crashCount;
  final List<Alert> activeAlerts;
  final int activeTraces;
  final int completedTraces;
  final Map<String, Map<String, dynamic>> latencyStats;
  final Map<String, dynamic> workerStatus;
  final Map<String, dynamic> logShippingStatus;
  final Map<String, dynamic> metricsSnapshot;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'system_health': systemHealth.label,
    'crash_count': crashCount,
    'active_alerts': activeAlerts.length,
    'critical_alerts': activeAlerts.where((a) => a.severity.priority >= AlertSeverity.critical.priority).length,
    'active_traces': activeTraces,
    'completed_traces': completedTraces,
    'latency_stats': latencyStats,
    'worker_status': workerStatus,
    'log_shipping_status': logShippingStatus,
    'metrics_snapshot': metricsSnapshot,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider that aggregates all monitoring data into a single dashboard snapshot.
final monitoringDashboardProvider = Provider<MonitoringDashboardData>((ref) {
  final healthReport = ref.watch(systemHealthProvider);
  final crashReports = ref.watch(crashReporterProvider);
  final alerts = ref.watch(activeAlertsProvider);
  final shippingStatus = ref.watch(logShippingStatusProvider);
  final metricsSnapshot = ref.watch(metricsSnapshotProvider);
  final workerStatus = ref.watch(workerStatusSummaryProvider);
  final apiLatencyStats = ref.watch(apiLatencyStatsProvider);
  final activeTraceCount = ref.watch(activeTraceCountProvider);
  final completedTraceCount = ref.watch(completedTraceCountProvider);

  return MonitoringDashboardData(
    systemHealth: healthReport.overallStatus,
    crashCount: crashReports.length,
    activeAlerts: alerts,
    activeTraces: activeTraceCount,
    completedTraces: completedTraceCount,
    latencyStats: apiLatencyStats,
    workerStatus: workerStatus,
    logShippingStatus: shippingStatus,
    metricsSnapshot: metricsSnapshot,
    timestamp: DateTime.now(),
  );
});

/// Provider for system health label only (for quick status displays).
final systemHealthLabelProvider = Provider<String>((ref) {
  final health = ref.watch(systemHealthProvider);
  return health.overallStatus.label;
});

/// Provider for total active + completed traces count.
final totalTraceCountProvider = Provider<int>((ref) {
  final active = ref.watch(activeTraceCountProvider);
  final completed = ref.watch(completedTraceCountProvider);
  return active + completed;
});

/// Provider for alert summary by category.
final alertSummaryProvider = Provider<Map<String, int>>((ref) {
  final alerts = ref.watch(activeAlertsProvider);
  final summary = <String, int>{};
  for (final alert in alerts) {
    summary[alert.category.label] = (summary[alert.category.label] ?? 0) + 1;
  }
  return summary;
});
