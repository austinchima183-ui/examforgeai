import 'dart:async';

import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// AUTO-SAVE SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Timer-based auto-save for exam-taking. Periodically persists the
// student's current answer state to the backend so that work is not
// lost if the browser crashes or the session is interrupted.
// ═══════════════════════════════════════════════════════════════════════

class AutoSaveService {
  Timer? _autoSaveTimer;
  String? _currentAttemptId;
  Future<void> Function(String attemptId, Map<String, dynamic> data)? _onSave;
  Map<String, dynamic> Function()? _getData;
  Duration? _interval;

  bool _isSaving = false;

  /// Whether auto-save is currently active (timer is running).
  bool get isActive => _autoSaveTimer != null && _autoSaveTimer!.isActive;

  /// Whether a save operation is currently in progress.
  bool get isSaving => _isSaving;

  /// The attempt ID that auto-save is currently tracking.
  String? get currentAttemptId => _currentAttemptId;

  /// Start auto-save for an attempt.
  ///
  /// [attemptId] identifies the exam attempt to save data for.
  /// [interval] how often to trigger saves (e.g., every 30 seconds).
  /// [onSave] callback that performs the actual save to the backend.
  /// [getData] callback that returns the current answer state to save.
  void startAutoSave({
    required String attemptId,
    required Duration interval,
    required Future<void> Function(String attemptId, Map<String, dynamic> data)
        onSave,
    required Map<String, dynamic> Function() getData,
  }) {
    // Stop any existing auto-save first
    stopAutoSave();

    _currentAttemptId = attemptId;
    _onSave = onSave;
    _getData = getData;
    _interval = interval;

    AppLogger.info(
      'AutoSave started for attempt $attemptId, interval: ${interval.inSeconds}s',
    );

    _autoSaveTimer = Timer.periodic(interval, (_) async {
      await _performSave();
    });
  }

  /// Stop auto-save and clear the timer.
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    AppLogger.info(
      'AutoSave stopped for attempt ${_currentAttemptId ?? "unknown"}',
    );
  }

  /// Force save now, regardless of the timer schedule.
  ///
  /// Useful when the student navigates away from a question or the
  /// exam is about to be submitted.
  Future<void> forceSave() async {
    if (_currentAttemptId == null || _onSave == null || _getData == null) {
      AppLogger.warning('Cannot force save: auto-save not configured');
      return;
    }

    await _performSave();
  }

  /// Internal save implementation with concurrency guard.
  Future<void> _performSave() async {
    if (_isSaving) {
      AppLogger.debug('Auto-save skipped: previous save still in progress');
      return;
    }

    if (_currentAttemptId == null || _onSave == null || _getData == null) {
      return;
    }

    _isSaving = true;

    try {
      final data = _getData!();
      AppLogger.debug(
        'Auto-saving for attempt $_currentAttemptId '
        '(${data.length} keys)',
      );
      await _onSave!(_currentAttemptId!, data);
      AppLogger.debug('Auto-save completed for attempt $_currentAttemptId');
    } catch (e) {
      AppLogger.error(
        'Auto-save failed for attempt $_currentAttemptId',
        error: e,
      );
      // Don't rethrow — auto-save failures should be silent to the user.
      // The next timer tick will retry.
    } finally {
      _isSaving = false;
    }
  }

  /// Dispose of all resources.
  void dispose() {
    stopAutoSave();
    _currentAttemptId = null;
    _onSave = null;
    _getData = null;
    _interval = null;
    _isSaving = false;
  }
}
