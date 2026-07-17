import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/get_workspace_dashboard_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the workspace dashboard feature.
///
/// Tracks the dashboard summary data, loading flags, and error state.
class WorkspaceDashboardState {
  const WorkspaceDashboardState({
    this.dashboardSummary,
    this.isLoading = false,
    this.error,
  });

  /// The aggregated dashboard summary, or `null` if not yet loaded.
  final WorkspaceDashboardEntity? dashboardSummary;

  /// Whether a dashboard load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  WorkspaceDashboardState copyWith({
    WorkspaceDashboardEntity? dashboardSummary,
    bool? isLoading,
    String? error,
  }) {
    return WorkspaceDashboardState(
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  WorkspaceDashboardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the workspace dashboard state.
///
/// All dashboard operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the dashboard summary on success
/// 4. Sets [error] on failure
class WorkspaceDashboardNotifier extends StateNotifier<WorkspaceDashboardState> {
  WorkspaceDashboardNotifier({
    required GetWorkspaceDashboardUseCase getWorkspaceDashboardUseCase,
  })  : _getWorkspaceDashboardUseCase = getWorkspaceDashboardUseCase,
        super(const WorkspaceDashboardState());

  final GetWorkspaceDashboardUseCase _getWorkspaceDashboardUseCase;

  // ─── Load Dashboard ────────────────────────────────────────────────

  /// Loads the workspace dashboard summary for the current teacher.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getWorkspaceDashboardUseCase(
      const GetWorkspaceDashboardParams(),
    );

    result.fold(
      onSuccess: (summary) {
        state = state.copyWith(
          isLoading: false,
          dashboardSummary: summary,
          error: null,
        );
        AppLogger.info('Dashboard summary loaded successfully');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load dashboard: $failure');
      },
    );
  }

  // ─── Refresh Dashboard ─────────────────────────────────────────────

  /// Refreshes the workspace dashboard by reloading the summary.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getWorkspaceDashboardUseCase(
      const GetWorkspaceDashboardParams(),
    );

    result.fold(
      onSuccess: (summary) {
        state = state.copyWith(
          isLoading: false,
          dashboardSummary: summary,
          error: null,
        );
        AppLogger.info('Dashboard refreshed successfully');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to refresh dashboard: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

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
// WORKSPACE DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final workspaceDashboardProvider =
    StateNotifierProvider<WorkspaceDashboardNotifier, WorkspaceDashboardState>(
  (ref) {
    return WorkspaceDashboardNotifier(
      getWorkspaceDashboardUseCase:
          ref.watch(getWorkspaceDashboardUseCaseProvider),
    );
  },
);
