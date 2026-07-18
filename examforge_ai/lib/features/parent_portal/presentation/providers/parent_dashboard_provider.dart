import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_parent_dashboard_usecase.dart';
import '../../domain/usecases/get_parent_insights_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent dashboard feature.
///
/// Tracks the dashboard entity, AI insights, loading flag, and error state.
class ParentDashboardState {
  const ParentDashboardState({
    this.dashboard,
    this.insights = const [],
    this.isLoading = false,
    this.error,
  });

  /// The parent dashboard data, or `null` if not yet loaded.
  final ParentDashboardEntity? dashboard;

  /// List of AI-generated insights for the parent.
  final List<ParentAiInsightEntity> insights;

  /// Whether a load or refresh operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  ParentDashboardState copyWith({
    ParentDashboardEntity? dashboard,
    List<ParentAiInsightEntity>? insights,
    bool? isLoading,
    String? error,
  }) {
    return ParentDashboardState(
      dashboard: dashboard ?? this.dashboard,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ParentDashboardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent dashboard feature's state.
///
/// All dashboard operations flow through this notifier, which:
/// 1. Sets the loading flag before each async operation
/// 2. Delegates to the [GetParentDashboardUseCase] and [GetParentInsightsUseCase]
/// 3. Updates the dashboard state on success
/// 4. Sets [error] on failure
class ParentDashboardNotifier extends StateNotifier<ParentDashboardState> {
  ParentDashboardNotifier({
    required this.getParentDashboardUseCase,
    required this.getParentInsightsUseCase,
  }) : super(const ParentDashboardState());

  final GetParentDashboardUseCase getParentDashboardUseCase;
  final GetParentInsightsUseCase getParentInsightsUseCase;

  // ─── Load Dashboard ──────────────────────────────────────────────

  /// Loads the parent dashboard data including AI insights.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load dashboard and insights in parallel
    final dashboardResult = await getParentDashboardUseCase(
      const GetParentDashboardParams(),
    );

    final insightsResult = await getParentInsightsUseCase(
      const GetParentInsightsParams(),
    );

    dashboardResult.fold(
      onSuccess: (dashboard) {
        final insights = insightsResult.fold(
          onSuccess: (data) => data,
          onFailure: (_) => <ParentAiInsightEntity>[],
        );
        state = state.copyWith(
          isLoading: false,
          dashboard: dashboard,
          insights: insights,
          error: null,
        );
        AppLogger.info('Parent dashboard loaded');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent dashboard: $failure');
      },
    );
  }

  // ─── Refresh Dashboard ───────────────────────────────────────────

  /// Refreshes the parent dashboard data (same as [loadDashboard]).
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
// PARENT DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the parent dashboard [StateNotifier].
///
/// Wires up the [ParentDashboardNotifier] with its required use cases.
final parentDashboardProvider = StateNotifierProvider<
    ParentDashboardNotifier, ParentDashboardState>((ref) {
  return ParentDashboardNotifier(
    getParentDashboardUseCase:
        ref.watch(getParentDashboardUseCaseProvider),
    getParentInsightsUseCase:
        ref.watch(getParentInsightsUseCaseProvider),
  );
});
