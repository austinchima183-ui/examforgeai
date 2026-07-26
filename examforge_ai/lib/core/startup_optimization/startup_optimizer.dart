import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// STARTUP PERFORMANCE OPTIMIZER
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Reduce startup time to <2 seconds through phased initialization
// Root cause: 4,644-line DI file creates ALL providers upfront
// Solution: Phased init — critical first, deferred after UI renders
// ═══════════════════════════════════════════════════════════════════════

enum InitPhase {
  critical,   // Must complete before runApp
  essential,  // Must complete within 1s of UI render
  deferred,   // Can complete after UI is visible
  background, // Load when idle
}

class _InitStep {
  _InitStep(this.name, this.phase);
  final String name;
  final InitPhase phase;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;
  Duration? get duration =>
      startedAt != null && completedAt != null
          ? completedAt!.difference(startedAt!)
          : null;
  bool get isComplete => completedAt != null;
  bool get failed => error != null;
}

class StartupOptimizer {
  StartupOptimizer._();
  static final StartupOptimizer instance = StartupOptimizer._();

  final List<_InitStep> _steps = [];
  DateTime? _appStartTime;
  DateTime? _uiRenderTime;
  bool _isOptimized = false;

  void markAppStart() {
    _appStartTime = DateTime.now();
    AppLogger.info('StartupOptimizer: app start marked');
  }

  void markUIRender() {
    _uiRenderTime = DateTime.now();
    if (_appStartTime != null) {
      final ms = _uiRenderTime!.difference(_appStartTime!).inMilliseconds;
      AppLogger.info('StartupOptimizer: UI rendered in ${ms}ms');
      if (ms > 2000) {
        AppLogger.warning('Startup exceeds 2s target (${ms}ms)');
      }
    }
  }

  void startStep(String name, InitPhase phase) {
    final step = _InitStep(name, phase);
    step.startedAt = DateTime.now();
    _steps.add(step);
  }

  void completeStep(String name) {
    final step = _steps.where((s) => s.name == name && !s.isComplete).firstOrNull;
    if (step != null) {
      step.completedAt = DateTime.now();
      AppLogger.debug('StartupOptimizer: $name completed in ${step.duration?.inMilliseconds}ms');
    }
  }

  void failStep(String name, String error) {
    final step = _steps.where((s) => s.name == name && !s.isComplete).firstOrNull;
    if (step != null) {
      step.error = error;
      step.completedAt = DateTime.now();
    }
  }

  void enableOptimizedStartup() {
    _isOptimized = true;
    AppLogger.info('StartupOptimizer: optimized mode enabled');
  }

  bool get isOptimized => _isOptimized;

  List<String> getCriticalSteps() => _isOptimized
      ? ['CrashReporter', 'EnvConfig', 'SupabaseConfig', 'MinimalProviders']
      : ['CrashReporter', 'EnvConfig', 'SupabaseConfig', 'AppConfig', 'FullProviders'];

  List<String> getDeferredSteps() => [
    'ConnectivityEngine', 'SyncEngine', 'DatabasePoolManager',
    'PerformanceMonitor', 'NotificationService',
  ];

  List<String> getBackgroundSteps() => [
    'AiServiceProviders', 'MarketplaceProviders',
    'BillingProviders', 'SuperAdminProviders',
    'TeacherWorkspaceProviders',
  ];

  Map<String, dynamic> get startupReport {
    final totalMs = _uiRenderTime != null && _appStartTime != null
        ? _uiRenderTime!.difference(_appStartTime!).inMilliseconds : null;
    final criticalMs = _steps.where((s) => s.phase == InitPhase.critical && s.duration != null)
        .fold<int>(0, (sum, s) => sum + s.duration!.inMilliseconds);
    final essentialMs = _steps.where((s) => s.phase == InitPhase.essential && s.duration != null)
        .fold<int>(0, (sum, s) => sum + s.duration!.inMilliseconds);

    return {
      'total_startup_ms': totalMs,
      'target_ms': 2000,
      'meets_target': totalMs != null && totalMs <= 2000,
      'critical_phase_ms': criticalMs,
      'essential_phase_ms': essentialMs,
      'completed_steps': _steps.where((s) => s.isComplete).length,
      'failed_steps': _steps.where((s) => s.failed).length,
      'total_steps': _steps.length,
      'optimization_enabled': _isOptimized,
    };
  }
}

final startupOptimizerProvider = Provider<StartupOptimizer>((ref) {
  return StartupOptimizer.instance;
});

final startupReportProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(startupOptimizerProvider).startupReport;
});
