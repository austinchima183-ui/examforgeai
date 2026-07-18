import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/get_enhanced_dashboard_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENHANCED DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the enhanced dashboard feature.
///
/// Tracks the dashboard entity, loading flag, and error state.
class EnhancedDashboardState {
  const EnhancedDashboardState({
    this.dashboard,
    this.isLoading = false,
    this.error,
  });

  /// The enhanced workspace dashboard data, or `null` if not yet loaded.
  final EnhancedWorkspaceDashboardEntity? dashboard;

  /// Whether a load or refresh operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  EnhancedDashboardState copyWith({
    EnhancedWorkspaceDashboardEntity? dashboard,
    bool? isLoading,
    String? error,
  }) {
    return EnhancedDashboardState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  EnhancedDashboardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ENHANCED DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the enhanced dashboard feature's state.
///
/// All dashboard operations flow through this notifier, which:
/// 1. Sets the loading flag before each async operation
/// 2. Delegates to the [GetEnhancedDashboardUseCase]
/// 3. Updates the dashboard state on success
/// 4. Sets [error] on failure
class EnhancedDashboardNotifier extends StateNotifier<EnhancedDashboardState> {
  EnhancedDashboardNotifier({
    required GetEnhancedDashboardUseCase getEnhancedDashboardUseCase,
  })  : _getEnhancedDashboardUseCase = getEnhancedDashboardUseCase,
        super(const EnhancedDashboardState());

  final GetEnhancedDashboardUseCase _getEnhancedDashboardUseCase;

  // ─── Load Dashboard ──────────────────────────────────────────────

  /// Loads the enhanced dashboard data for the current teacher.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEnhancedDashboardUseCase(
      const GetEnhancedDashboardParams(),
    );

    result.fold(
      onSuccess: (dashboard) {
        state = state.copyWith(
          isLoading: false,
          dashboard: dashboard,
          error: null,
        );
        AppLogger.info('Enhanced dashboard loaded');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load enhanced dashboard: $failure');
      },
    );
  }

  // ─── Refresh Dashboard ───────────────────────────────────────────

  /// Refreshes the enhanced dashboard data (same as [loadDashboard]).
  Future<void> refreshDashboard() async {
    await loadDashboard();
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
// ENHANCED DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final enhancedDashboardProvider = StateNotifierProvider<
    EnhancedDashboardNotifier, EnhancedDashboardState>((ref) {
  return EnhancedDashboardNotifier(
    getEnhancedDashboardUseCase:
        ref.watch(getEnhancedDashboardUseCaseProvider),
  );
});
