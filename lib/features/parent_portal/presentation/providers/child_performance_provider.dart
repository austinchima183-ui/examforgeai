import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_child_performance_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD PERFORMANCE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the child performance feature.
///
/// Tracks the performance entity, loading flag, and error state.
class ChildPerformanceState {
  const ChildPerformanceState({
    this.performance,
    this.isLoading = false,
    this.error,
  });

  /// The child performance data, or `null` if not yet loaded.
  final ChildPerformanceEntity? performance;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  ChildPerformanceState copyWith({
    ChildPerformanceEntity? performance,
    bool? isLoading,
    String? error,
  }) {
    return ChildPerformanceState(
      performance: performance ?? this.performance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ChildPerformanceState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD PERFORMANCE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the child performance feature's state.
///
/// Loads and refreshes academic performance data for a specific student,
/// delegating to [GetChildPerformanceUseCase].
class ChildPerformanceNotifier extends StateNotifier<ChildPerformanceState> {
  ChildPerformanceNotifier({
    required GetChildPerformanceUseCase getChildPerformanceUseCase,
  })  : _getChildPerformanceUseCase = getChildPerformanceUseCase,
        super(const ChildPerformanceState());

  final GetChildPerformanceUseCase _getChildPerformanceUseCase;

  // ─── Load Performance ────────────────────────────────────────────

  /// Loads academic performance data for the specified [studentId].
  Future<void> loadPerformance(String studentId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getChildPerformanceUseCase(
      GetChildPerformanceParams(studentId: studentId),
    );

    result.fold(
      onSuccess: (performance) {
        state = state.copyWith(
          isLoading: false,
          performance: performance,
          error: null,
        );
        AppLogger.info('Child performance loaded for student: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load child performance: $failure');
      },
    );
  }

  // ─── Refresh Performance ─────────────────────────────────────────

  /// Refreshes the child performance data.
  Future<void> refreshPerformance(String studentId) async {
    await loadPerformance(studentId);
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
// CHILD PERFORMANCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the child performance [StateNotifier].
///
/// Wires up the [ChildPerformanceNotifier] with its required use case.
final childPerformanceProvider = StateNotifierProvider<
    ChildPerformanceNotifier, ChildPerformanceState>((ref) {
  return ChildPerformanceNotifier(
    getChildPerformanceUseCase:
        ref.watch(getChildPerformanceUseCaseProvider),
  );
});
