import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_child_assignments_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD ASSIGNMENTS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the child assignments feature.
///
/// Tracks the list of assignment entities, loading flag, and error state.
class ChildAssignmentsState {
  const ChildAssignmentsState({
    this.assignments = const [],
    this.isLoading = false,
    this.error,
  });

  /// The list of assignment entities.
  final List<ChildAssignmentEntity> assignments;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  ChildAssignmentsState copyWith({
    List<ChildAssignmentEntity>? assignments,
    bool? isLoading,
    String? error,
  }) {
    return ChildAssignmentsState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ChildAssignmentsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD ASSIGNMENTS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the child assignments feature's state.
///
/// Loads and refreshes assignment data for a specific student,
/// delegating to [GetChildAssignmentsUseCase].
class ChildAssignmentsNotifier extends StateNotifier<ChildAssignmentsState> {
  ChildAssignmentsNotifier({
    required GetChildAssignmentsUseCase getChildAssignmentsUseCase,
  })  : _getChildAssignmentsUseCase = getChildAssignmentsUseCase,
        super(const ChildAssignmentsState());

  final GetChildAssignmentsUseCase _getChildAssignmentsUseCase;

  // ─── Load Assignments ────────────────────────────────────────────

  /// Loads assignments for the specified [studentId].
  ///
  /// Optionally filters by [status] (e.g., "pending", "submitted",
  /// "graded", "missing").
  Future<void> loadAssignments(
    String studentId, {
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getChildAssignmentsUseCase(
      GetChildAssignmentsParams(
        studentId: studentId,
        status: status,
      ),
    );

    result.fold(
      onSuccess: (assignments) {
        state = state.copyWith(
          isLoading: false,
          assignments: assignments,
          error: null,
        );
        AppLogger.info('Child assignments loaded for student: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load child assignments: $failure');
      },
    );
  }

  // ─── Refresh Assignments ─────────────────────────────────────────

  /// Refreshes the child assignments data.
  Future<void> refreshAssignments(
    String studentId, {
    String? status,
  }) async {
    await loadAssignments(studentId, status: status);
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
// CHILD ASSIGNMENTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the child assignments [StateNotifier].
///
/// Wires up the [ChildAssignmentsNotifier] with its required use case.
final childAssignmentsProvider = StateNotifierProvider<
    ChildAssignmentsNotifier, ChildAssignmentsState>((ref) {
  return ChildAssignmentsNotifier(
    getChildAssignmentsUseCase:
        ref.watch(getChildAssignmentsUseCaseProvider),
  );
});
