import '../../../features/cbt_engine/domain/entities/cbt_entities.dart';
import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// VIOLATION SUMMARY
// ═══════════════════════════════════════════════════════════════════════

/// Aggregated summary of monitoring violations for a student's exam
/// attempt, used to determine if disqualification is warranted.
class ViolationSummary {
  const ViolationSummary({
    required this.totalViolations,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
    required this.shouldDisqualify,
    required this.byType,
  });

  final int totalViolations;
  final int criticalCount;
  final int warningCount;
  final int infoCount;
  final bool shouldDisqualify;

  /// Count of violations grouped by [MonitoringEventType].
  final Map<MonitoringEventType, int> byType;

  @override
  String toString() =>
      'ViolationSummary(total: $totalViolations, critical: $criticalCount, '
      'warning: $warningCount, info: $infoCount, disqualify: $shouldDisqualify)';
}

// ═══════════════════════════════════════════════════════════════════════
// ANTI-CHEAT SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Detects and logs suspicious behavior during an exam attempt.
// Generates [MonitoringLogEntity] instances that should be persisted
// via the CBT repository. Also provides analysis methods to determine
// if a student should be disqualified based on violation thresholds.
// ═══════════════════════════════════════════════════════════════════════

class AntiCheatService {
  // ─── Tab Visibility Change ──────────────────────────────────────────

  /// Handle a tab visibility change event.
  ///
  /// Called when the student switches to another browser tab or
  /// returns to the exam tab. Returns a [MonitoringLogEntity] if
  /// the event warrants logging, or `null` if it's benign.
  MonitoringLogEntity? onTabVisibilityChanged(
    bool isVisible,
    String attemptId,
    String examId,
    String studentId,
  ) {
    if (isVisible) {
      // Returning to the exam tab — log the return for audit trail
      AppLogger.debug('Tab visibility restored for attempt $attemptId');
      return null;
    }

    // Tab lost focus — this is suspicious
    AppLogger.warning(
      'Tab switch detected for attempt $attemptId, student $studentId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.tabSwitch,
      eventData: {
        'visible': isVisible,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.tabSwitch.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Copy Attempt ───────────────────────────────────────────────────

  /// Handle a copy attempt (Ctrl+C, right-click → copy).
  MonitoringLogEntity? onCopyAttempt(
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.warning(
      'Copy attempt detected for attempt $attemptId, student $studentId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.copyAttempt,
      eventData: {
        'action': 'copy',
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.copyAttempt.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Paste Attempt ──────────────────────────────────────────────────

  /// Handle a paste attempt (Ctrl+V, right-click → paste).
  MonitoringLogEntity? onPasteAttempt(
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.warning(
      'Paste attempt detected for attempt $attemptId, student $studentId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.pasteAttempt,
      eventData: {
        'action': 'paste',
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.pasteAttempt.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Right Click ────────────────────────────────────────────────────

  /// Handle a right-click event (context menu).
  MonitoringLogEntity? onRightClick(
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.debug(
      'Right-click detected for attempt $attemptId, student $studentId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.rightClick,
      eventData: {
        'action': 'right_click',
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.rightClick.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Fullscreen Exit ────────────────────────────────────────────────

  /// Handle a fullscreen exit event.
  MonitoringLogEntity? onFullScreenExit(
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.warning(
      'Fullscreen exit detected for attempt $attemptId, student $studentId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.fullScreenExit,
      eventData: {
        'action': 'fullscreen_exit',
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.fullScreenExit.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Keyboard Shortcut ──────────────────────────────────────────────

  /// Handle a keyboard shortcut that may indicate cheating.
  ///
  /// Examples: Ctrl+C, Ctrl+V, Ctrl+U (view source), Ctrl+S (save),
  /// F12 (dev tools), Ctrl+Shift+I (dev tools), PrintScreen.
  MonitoringLogEntity? onKeyboardShortcut(
    String shortcut,
    String attemptId,
    String examId,
    String studentId,
  ) {
    final criticalShortcuts = [
      'Ctrl+C',
      'Ctrl+V',
      'Ctrl+U',
      'Ctrl+S',
      'Ctrl+Shift+I',
      'F12',
      'PrintScreen',
      'Ctrl+P',
      'Alt+Tab',
    ];

    final warningShortcuts = [
      'Ctrl+F',
      'Ctrl+A',
      'Ctrl+Shift+C',
      'Ctrl+Shift+J',
    ];

    MonitoringEventType eventType;
    String severity;

    if (criticalShortcuts.contains(shortcut)) {
      eventType = shortcut == 'Ctrl+C'
          ? MonitoringEventType.copyAttempt
          : shortcut == 'Ctrl+V'
              ? MonitoringEventType.pasteAttempt
              : MonitoringEventType.screenshotAttempt;
      severity = 'critical';
    } else if (warningShortcuts.contains(shortcut)) {
      eventType = MonitoringEventType.suspiciousActivity;
      severity = 'warning';
    } else {
      // Unknown shortcut — log as info
      eventType = MonitoringEventType.suspiciousActivity;
      severity = 'info';
    }

    AppLogger.warning(
      'Keyboard shortcut "$shortcut" detected for attempt $attemptId '
      '(severity: $severity)',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: eventType,
      eventData: {
        'shortcut': shortcut,
        'severity_override': severity,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Idle Timeout ───────────────────────────────────────────────────

  /// Handle an idle timeout event.
  ///
  /// Called when the student has been inactive for longer than
  /// the acceptable threshold.
  MonitoringLogEntity? onIdleTimeout(
    Duration idleDuration,
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.warning(
      'Idle timeout detected for attempt $attemptId: '
      '${idleDuration.inMinutes} minutes idle',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.idleTimeout,
      eventData: {
        'idle_duration_seconds': idleDuration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.idleTimeout.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Window Resize ──────────────────────────────────────────────────

  /// Handle a window resize event.
  ///
  /// Frequent resizes may indicate the student is arranging their
  /// screen to look at other materials.
  MonitoringLogEntity? onWindowResize(
    String attemptId,
    String examId,
    String studentId,
  ) {
    AppLogger.debug(
      'Window resize detected for attempt $attemptId',
    );

    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.browserResize,
      eventData: {
        'action': 'window_resize',
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: MonitoringEventType.browserResize.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Should Disqualify ──────────────────────────────────────────────

  /// Determine if the violation counts exceed disqualification thresholds.
  ///
  /// Returns `true` if any of the thresholds are exceeded:
  /// - [maxTabSwitches]: maximum allowed tab switches (default 3)
  /// - [maxFocusLost]: maximum allowed focus lost events (default 5)
  /// - [maxCopyAttempts]: maximum allowed copy attempts (default 1)
  /// - [maxPasteAttempts]: maximum allowed paste attempts (default 1)
  /// - [maxCriticalEvents]: maximum total critical events (default 2)
  bool shouldDisqualify(
    int tabSwitches,
    int focusLost,
    int copyAttempts, {
    int maxTabSwitches = 3,
    int maxFocusLost = 5,
    int maxCopyAttempts = 1,
    int maxPasteAttempts = 1,
    int maxCriticalEvents = 2,
    int pasteAttempts = 0,
    int criticalEvents = 0,
  }) {
    return tabSwitches > maxTabSwitches ||
        focusLost > maxFocusLost ||
        copyAttempts > maxCopyAttempts ||
        pasteAttempts > maxPasteAttempts ||
        criticalEvents > maxCriticalEvents;
  }

  // ─── Get Violation Summary ──────────────────────────────────────────

  /// Analyze a list of monitoring logs and produce a [ViolationSummary].
  ///
  /// Groups violations by type and severity, and determines whether
  /// the cumulative violations warrant disqualification.
  ViolationSummary getViolationSummary(List<MonitoringLogEntity> logs) {
    int criticalCount = 0;
    int warningCount = 0;
    int infoCount = 0;
    final byType = <MonitoringEventType, int>{};

    int tabSwitches = 0;
    int focusLostCount = 0;
    int copyCount = 0;
    int pasteCount = 0;
    int criticalEvents = 0;

    for (final log in logs) {
      // Count by severity
      switch (log.severity) {
        case 'critical':
          criticalCount++;
          criticalEvents++;
          break;
        case 'warning':
          warningCount++;
          break;
        case 'info':
          infoCount++;
          break;
      }

      // Count by type
      byType[log.eventType] = (byType[log.eventType] ?? 0) + 1;

      // Track specific violation counts for disqualification check
      switch (log.eventType) {
        case MonitoringEventType.tabSwitch:
          tabSwitches++;
          break;
        case MonitoringEventType.focusLost:
          focusLostCount++;
          break;
        case MonitoringEventType.copyAttempt:
          copyCount++;
          break;
        case MonitoringEventType.pasteAttempt:
          pasteCount++;
          break;
        default:
          break;
      }
    }

    final shouldDq = shouldDisqualify(
      tabSwitches,
      focusLostCount,
      copyCount,
      pasteAttempts: pasteCount,
      criticalEvents: criticalEvents,
    );

    return ViolationSummary(
      totalViolations: logs.length,
      criticalCount: criticalCount,
      warningCount: warningCount,
      infoCount: infoCount,
      shouldDisqualify: shouldDq,
      byType: byType,
    );
  }

  // ─── Generate Monitoring Log from Event ─────────────────────────────

  /// Create a monitoring log entity for any custom event type.
  ///
  /// Useful for events not covered by the specific handler methods.
  MonitoringLogEntity createMonitoringLog({
    required String attemptId,
    required String examId,
    required String studentId,
    required MonitoringEventType eventType,
    Map<String, dynamic>? eventData,
  }) {
    return MonitoringLogEntity(
      id: _generateId(),
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: eventType,
      eventData: {
        ...?eventData,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: eventType.severity,
      createdAt: DateTime.now(),
    );
  }

  // ─── Private Helpers ────────────────────────────────────────────────

  /// Generate a unique ID for monitoring log entries.
  ///
  /// Uses timestamp + random suffix for uniqueness.
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = DateTime.now().microsecond;
    return 'mon_$timestamp$suffix';
  }
}
