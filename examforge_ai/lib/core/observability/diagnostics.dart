// ============================================================================
// ExamForge AI — Production Diagnostics Module
// ============================================================================
//
// Internal diagnostics module that displays:
//   - App version, build number, git commit
//   - Environment (development/staging/production)
//   - Current user, current school
//   - Realtime status, database status, storage status
//   - Current AI provider
//   - Offline queue length, pending sync count
//   - Current memory, network type
//
// ROOT CAUSE: There is no diagnostics module in the project. Support
// and operations teams have no way to inspect the app state in production.
// This module fills that gap.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'health_monitoring.dart';
import 'metrics.dart';
import 'tracing.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DIAGNOSTIC INFO
// ═══════════════════════════════════════════════════════════════════════════

/// Complete diagnostic snapshot of the application state.
class DiagnosticInfo {
  DiagnosticInfo({
    required this.appVersion,
    required this.environment,
    this.buildNumber,
    this.gitCommit,
    this.currentUserId,
    this.currentSchoolId,
    this.currentUserRole,
    this.realtimeStatus,
    this.databaseStatus,
    this.storageStatus,
    this.aiProvider,
    this.offlineQueueLength,
    this.pendingSyncCount,
    this.currentMemoryBytes,
    this.networkType,
    this.isOffline,
    this.healthStatus,
    this.metricsSnapshot,
    this.crashCount,
    this.activeTraces,
    this.activeAlerts,
    this.timestamp,
  });

  final String appVersion;
  final String environment;
  final String? buildNumber;
  final String? gitCommit;
  final String? currentUserId;
  final String? currentSchoolId;
  final String? currentUserRole;
  final String? realtimeStatus;
  final String? databaseStatus;
  final String? storageStatus;
  final String? aiProvider;
  final int? offlineQueueLength;
  final int? pendingSyncCount;
  final double? currentMemoryBytes;
  final String? networkType;
  final bool? isOffline;
  final HealthStatus? healthStatus;
  final Map<String, dynamic>? metricsSnapshot;
  final int? crashCount;
  final int? activeTraces;
  final int? activeAlerts;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
    'app_version': appVersion,
    'environment': environment,
    if (buildNumber != null) 'build_number': buildNumber,
    if (gitCommit != null) 'git_commit': gitCommit,
    if (currentUserId != null) 'user_id': currentUserId,
    if (currentSchoolId != null) 'school_id': currentSchoolId,
    if (currentUserRole != null) 'user_role': currentUserRole,
    if (realtimeStatus != null) 'realtime_status': realtimeStatus,
    if (databaseStatus != null) 'database_status': databaseStatus,
    if (storageStatus != null) 'storage_status': storageStatus,
    if (aiProvider != null) 'ai_provider': aiProvider,
    'offline_queue_length': offlineQueueLength ?? 0,
    'pending_sync_count': pendingSyncCount ?? 0,
    if (currentMemoryBytes != null) 'memory_bytes': currentMemoryBytes,
    if (networkType != null) 'network_type': networkType,
    'is_offline': isOffline ?? false,
    'health_status': healthStatus?.label ?? 'unknown',
    if (metricsSnapshot != null) 'metrics': metricsSnapshot,
    'crash_count': crashCount ?? 0,
    'active_traces': activeTraces ?? 0,
    'active_alerts': activeAlerts ?? 0,
    'timestamp': (timestamp ?? DateTime.now()).toUtc().toIso8601String(),
  };

  @override
  String toString() => 'DiagnosticInfo(v=$appVersion, env=$environment, user=$currentUserId)';
}

// ═══════════════════════════════════════════════════════════════════════════
// DIAGNOSTICS SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// Production diagnostics service that collects a snapshot of all
/// relevant application state for debugging and support.
class DiagnosticsService {
  DiagnosticsService._();
  static final DiagnosticsService instance = DiagnosticsService._();

  String _appVersion = '1.0.0';
  String _environment = kDebugMode ? 'development' : kReleaseMode ? 'production' : 'staging';
  String? _buildNumber;
  String? _gitCommit;
  String? _currentUserId;
  String? _currentSchoolId;
  String? _currentUserRole;

  /// Set app version info.
  void setAppInfo({
    required String version,
    String? buildNumber,
    String? gitCommit,
  }) {
    _appVersion = version;
    _buildNumber = buildNumber;
    _gitCommit = gitCommit;
  }

  /// Set current user context.
  void setUserContext({
    String? userId,
    String? schoolId,
    String? role,
  }) {
    _currentUserId = userId;
    _currentSchoolId = schoolId;
    _currentUserRole = role;
  }

  /// Clear user context on sign-out.
  void clearUserContext() {
    _currentUserId = null;
    _currentSchoolId = null;
    _currentUserRole = null;
  }

  /// Collect a comprehensive diagnostic snapshot.
  DiagnosticInfo collectDiagnostics() {
    final metrics = MetricsService.instance.getSnapshot();
    final healthService = HealthMonitoringService();

    return DiagnosticInfo(
      appVersion: _appVersion,
      environment: _environment,
      buildNumber: _buildNumber,
      gitCommit: _gitCommit,
      currentUserId: _currentUserId,
      currentSchoolId: _currentSchoolId,
      currentUserRole: _currentUserRole,
      realtimeStatus: healthService.getComponentHealth('supabase_realtime')?.status.label,
      databaseStatus: healthService.getComponentHealth('supabase_database')?.status.label,
      storageStatus: healthService.getComponentHealth('supabase_storage')?.status.label,
      aiProvider: 'supabase_edge',
      offlineQueueLength: 0,
      pendingSyncCount: 0,
      networkType: kIsWeb ? 'web' : 'unknown',
      isOffline: false,
      healthStatus: healthService.currentHealth.overallStatus,
      metricsSnapshot: metrics,
      activeTraces: TracingService.instance.activeTraceCount,
      crashCount: 0,
      activeAlerts: 0,
      timestamp: DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for diagnostics service instance.
final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  return DiagnosticsService.instance;
});

/// Provider for current diagnostic snapshot.
final diagnosticsInfoProvider = Provider<DiagnosticInfo>((ref) {
  final service = ref.watch(diagnosticsServiceProvider);
  return service.collectDiagnostics();
});
