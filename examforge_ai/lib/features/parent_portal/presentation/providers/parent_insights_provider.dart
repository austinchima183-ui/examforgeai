import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/dismiss_insight_usecase.dart';
import '../../domain/usecases/get_parent_insights_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT INSIGHTS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent AI insights feature.
///
/// Tracks the insights list, loading flag, error message, and
/// the active student ID filter.
class ParentInsightsState {
  const ParentInsightsState({
    this.insights = const [],
    this.isLoading = false,
    this.error,
    this.studentIdFilter,
  });

  /// The list of AI-generated insights.
  final List<ParentAiInsightEntity> insights;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The active student ID filter, or `null` for all children.
  final String? studentIdFilter;

  /// Creates a copy of this state with the given fields replaced.
  ParentInsightsState copyWith({
    List<ParentAiInsightEntity>? insights,
    bool? isLoading,
    String? error,
    String? studentIdFilter,
  }) {
    return ParentInsightsState(
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      studentIdFilter: studentIdFilter ?? this.studentIdFilter,
    );
  }

  /// Clears the current error message.
  ParentInsightsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT INSIGHTS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent AI insights feature's state.
///
/// All insights operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates [insights] and [studentIdFilter] on success
/// 4. Sets [error] on failure
class ParentInsightsNotifier extends StateNotifier<ParentInsightsState> {
  ParentInsightsNotifier({
    required GetParentInsightsUseCase getParentInsightsUseCase,
    required DismissInsightUseCase dismissInsightUseCase,
  })  : _getParentInsightsUseCase = getParentInsightsUseCase,
        _dismissInsightUseCase = dismissInsightUseCase,
        super(const ParentInsightsState());

  final GetParentInsightsUseCase _getParentInsightsUseCase;
  final DismissInsightUseCase _dismissInsightUseCase;

  // ─── Load Insights ─────────────────────────────────────────────────

  /// Loads AI insights, optionally filtered by [studentId] and [isRead].
  Future<void> loadInsights({
    String? studentId,
    bool? isRead,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      studentIdFilter: studentId ?? state.studentIdFilter,
    );

    final result = await _getParentInsightsUseCase(
      GetParentInsightsParams(
        studentId: studentId,
        isRead: isRead,
      ),
    );

    result.fold(
      onSuccess: (insights) {
        state = state.copyWith(
          isLoading: false,
          insights: insights,
          error: null,
        );
        AppLogger.info(
          'Parent insights loaded (${insights.length} insights)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent insights: $failure');
      },
    );
  }

  // ─── Dismiss Insight ───────────────────────────────────────────────

  /// Dismisses the specified [insightId] so it no longer appears.
  Future<void> dismissInsight(String insightId) async {
    final result = await _dismissInsightUseCase(
      DismissInsightParams(insightId: insightId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedInsights =
            state.insights.where((i) => i.id != insightId).toList();
        state = state.copyWith(insights: updatedInsights);
        AppLogger.info('Parent insight dismissed: $insightId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to dismiss parent insight: $failure');
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
// PARENT INSIGHTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentInsightsProvider =
    StateNotifierProvider<ParentInsightsNotifier, ParentInsightsState>((ref) {
  return ParentInsightsNotifier(
    getParentInsightsUseCase: ref.watch(getParentInsightsUseCaseProvider),
    dismissInsightUseCase: ref.watch(dismissInsightUseCaseProvider),
  );
});
