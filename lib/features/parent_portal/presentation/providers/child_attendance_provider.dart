import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_child_attendance_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD ATTENDANCE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the child attendance feature.
///
/// Tracks the attendance entity, loading flag, and error state.
class ChildAttendanceState {
  const ChildAttendanceState({
    this.attendance,
    this.isLoading = false,
    this.error,
  });

  /// The child attendance data, or `null` if not yet loaded.
  final ChildAttendanceEntity? attendance;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  ChildAttendanceState copyWith({
    ChildAttendanceEntity? attendance,
    bool? isLoading,
    String? error,
  }) {
    return ChildAttendanceState(
      attendance: attendance ?? this.attendance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ChildAttendanceState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD ATTENDANCE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the child attendance feature's state.
///
/// Loads and refreshes attendance records for a specific student,
/// delegating to [GetChildAttendanceUseCase].
class ChildAttendanceNotifier extends StateNotifier<ChildAttendanceState> {
  ChildAttendanceNotifier({
    required GetChildAttendanceUseCase getChildAttendanceUseCase,
  })  : _getChildAttendanceUseCase = getChildAttendanceUseCase,
        super(const ChildAttendanceState());

  final GetChildAttendanceUseCase _getChildAttendanceUseCase;

  // ─── Load Attendance ─────────────────────────────────────────────

  /// Loads attendance records for the specified [studentId].
  ///
  /// Optionally accepts [startDate] and [endDate] to filter the date range.
  Future<void> loadAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getChildAttendanceUseCase(
      GetChildAttendanceParams(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    result.fold(
      onSuccess: (attendance) {
        state = state.copyWith(
          isLoading: false,
          attendance: attendance,
          error: null,
        );
        AppLogger.info('Child attendance loaded for student: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load child attendance: $failure');
      },
    );
  }

  // ─── Refresh Attendance ──────────────────────────────────────────

  /// Refreshes the child attendance data.
  Future<void> refreshAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await loadAttendance(
      studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ─── Clear Error ─────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD ATTENDANCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the child attendance [StateNotifier].
///
/// Wires up the [ChildAttendanceNotifier] with its required use case.
final childAttendanceProvider = StateNotifierProvider<
    ChildAttendanceNotifier, ChildAttendanceState>((ref) {
  return ChildAttendanceNotifier(
    getChildAttendanceUseCase:
        ref.watch(getChildAttendanceUseCaseProvider),
  );
});
