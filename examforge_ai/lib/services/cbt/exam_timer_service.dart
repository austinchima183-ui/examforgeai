import 'dart:async';

import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TIMER SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Countdown timer for exam-taking. Provides tick-by-tick updates,
// warning threshold notifications, and a terminal callback when
// time expires.
// ═══════════════════════════════════════════════════════════════════════

class ExamTimerService {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  Duration _total = Duration.zero;
  Duration _warningThreshold = const Duration(minutes: 5);

  VoidCallback? _onTick;
  VoidCallback? _onTimeUp;
  VoidCallback? _onWarning;

  bool _isRunning = false;
  bool _isPaused = false;
  bool _warningTriggered = false;

  // ─── Getters ────────────────────────────────────────────────────────

  /// The remaining time in the exam.
  Duration get remaining => _remaining;

  /// The elapsed time since the exam started.
  Duration get elapsed => _total - _remaining;

  /// Progress as a value from 0.0 (no time consumed) to 1.0 (time up).
  double get progress =>
      _total.inSeconds > 0 ? elapsed.inSeconds / _total.inSeconds : 0.0;

  /// Whether the timer is actively counting down.
  bool get isRunning => _isRunning && !_isPaused;

  /// Whether the timer is paused.
  bool get isPaused => _isPaused;

  /// Whether the timer has entered the warning zone.
  bool get isWarning =>
      _remaining.inSeconds <= _warningThreshold.inSeconds &&
      _remaining.inSeconds > 0;

  /// Whether the time has fully expired.
  bool get isTimeUp => _remaining.inSeconds <= 0;

  /// The total exam duration.
  Duration get total => _total;

  // ─── Start ──────────────────────────────────────────────────────────

  /// Start the exam timer.
  ///
  /// [duration] total exam duration.
  /// [onTick] called every second with updated state.
  /// [onTimeUp] called when the timer reaches zero.
  /// [onWarning] called once when remaining time falls below
  ///   [warningThreshold] (default 5 minutes).
  /// [warningThreshold] duration before time-up that triggers the
  ///   warning callback.
  void start({
    required Duration duration,
    required VoidCallback onTick,
    required VoidCallback onTimeUp,
    required VoidCallback onWarning,
    Duration? warningThreshold,
  }) {
    // Stop any existing timer
    stop();

    _total = duration;
    _remaining = duration;
    _onTick = onTick;
    _onTimeUp = onTimeUp;
    _onWarning = onWarning;
    _warningThreshold = warningThreshold ?? const Duration(minutes: 5);
    _warningTriggered = false;
    _isRunning = true;
    _isPaused = false;

    AppLogger.info(
      'ExamTimer started: ${duration.inMinutes} minutes, '
      'warning at ${_warningThreshold.inMinutes} minutes',
    );

    // Fire initial tick
    _onTick?.call();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;

      _remaining = Duration(seconds: _remaining.inSeconds - 1);

      // Check for warning threshold
      if (!_warningTriggered && isWarning) {
        _warningTriggered = true;
        AppLogger.info('ExamTimer warning: ${_remaining.inMinutes} minutes left');
        _onWarning?.call();
      }

      // Check for time up
      if (_remaining.inSeconds <= 0) {
        _remaining = Duration.zero;
        _onTick?.call();
        AppLogger.info('ExamTimer: time up!');
        _onTimeUp?.call();
        stop();
        return;
      }

      _onTick?.call();
    });
  }

  // ─── Pause ──────────────────────────────────────────────────────────

  /// Pause the exam timer.
  ///
  /// Only effective when the timer is running and not already paused.
  void pause() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    AppLogger.info(
      'ExamTimer paused at ${_formatDuration(_remaining)} remaining',
    );
  }

  // ─── Resume ─────────────────────────────────────────────────────────

  /// Resume the exam timer after a pause.
  void resume() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    AppLogger.info(
      'ExamTimer resumed at ${_formatDuration(_remaining)} remaining',
    );
  }

  // ─── Stop ───────────────────────────────────────────────────────────

  /// Stop the exam timer entirely.
  ///
  /// After stopping, [start] must be called again to restart.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    AppLogger.info('ExamTimer stopped');
  }

  // ─── Set Remaining ──────────────────────────────────────────────────

  /// Set the remaining time directly (e.g., after session recovery).
  ///
  /// Only effective when the timer is running.
  void setRemaining(Duration remaining) {
    _remaining = remaining.clamp(Duration.zero, _total);

    // Re-check warning state
    if (!_warningTriggered && isWarning) {
      _warningTriggered = true;
      _onWarning?.call();
    }

    _onTick?.call();
    AppLogger.debug(
      'ExamTimer remaining set to ${_formatDuration(_remaining)}',
    );
  }

  // ─── Dispose ────────────────────────────────────────────────────────

  /// Dispose of all resources.
  void dispose() {
    stop();
    _onTick = null;
    _onTimeUp = null;
    _onWarning = null;
  }

  // ─── Formatting ─────────────────────────────────────────────────────

  /// Format the remaining time as "HH:MM:SS".
  String get formattedRemaining => _formatDuration(_remaining);

  /// Format the elapsed time as "HH:MM:SS".
  String get formattedElapsed => _formatDuration(elapsed);

  /// Format the total time as "HH:MM:SS".
  String get formattedTotal => _formatDuration(_total);

  static String _formatDuration(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// Typedef for void callbacks (used by timer service).
typedef VoidCallback = void Function();
