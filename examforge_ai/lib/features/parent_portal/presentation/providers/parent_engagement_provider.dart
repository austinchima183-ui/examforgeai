import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_engagement_analytics_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT ENGAGEMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent engagement analytics feature
/// (admin dashboard).
///
/// Tracks the analytics data, loading flag, error message, and the
/// active school ID.
class ParentEngagementState {
  const ParentEngagementState({
    this.analytics,
    this.isLoading = false,
    this.error,
    this.schoolId,
  });

  /// The engagement analytics data, or `null` if not yet loaded.
  final EngagementAnalyticsEntity? analytics;

  /// Whether a load or refresh operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The school ID currently being viewed.
  final String? schoolId;

  /// Creates a copy of this state with the given fields replaced.
  ParentEngagementState copyWith({
    EngagementAnalyticsEntity? analytics,
    bool? isLoading,
    String? error,
    String? schoolId,
  }) {
    return ParentEngagementState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  /// Clears the current error message.
  ParentEngagementState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT ENGAGEMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent engagement analytics
/// feature's state (admin dashboard).
///
/// All engagement operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the [GetEngagementAnalyticsUseCase]
/// 3. Updates [analytics] and [schoolId] on success
/// 4. Sets [error] on failure
class ParentEngagementNotifier extends StateNotifier<ParentEngagementState> {
  ParentEngagementNotifier({
    required GetEngagementAnalyticsUseCase getEngagementAnalyticsUseCase,
  })  : _getEngagementAnalyticsUseCase = getEngagementAnalyticsUseCase,
        super(const ParentEngagementState());

  final GetEngagementAnalyticsUseCase _getEngagementAnalyticsUseCase;

  // ─── Load Analytics ────────────────────────────────────────────────

  /// Loads engagement analytics for the specified [schoolId].
  Future<void> loadAnalytics(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null, schoolId: schoolId);

    final result = await _getEngagementAnalyticsUseCase(
      GetEngagementAnalyticsParams(schoolId: schoolId),
    );

    result.fold(
      onSuccess: (analytics) {
        state = state.copyWith(
          isLoading: false,
          analytics: analytics,
          error: null,
        );
        AppLogger.info('Engagement analytics loaded for school: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load engagement analytics: $failure');
      },
    );
  }

  // ─── Refresh Analytics ─────────────────────────────────────────────

  /// Refreshes engagement analytics for the current school.
  Future<void> refreshAnalytics() async {
    if (state.schoolId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEngagementAnalyticsUseCase(
      GetEngagementAnalyticsParams(schoolId: state.schoolId!),
    );

    result.fold(
      onSuccess: (analytics) {
        state = state.copyWith(
          isLoading: false,
          analytics: analytics,
          error: null,
        );
        AppLogger.info(
          'Engagement analytics refreshed for school: ${state.schoolId}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to refresh engagement analytics: $failure',
        );
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
// PARENT ENGAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentEngagementProvider =
    StateNotifierProvider<ParentEngagementNotifier, ParentEngagementState>(
        (ref) {
  return ParentEngagementNotifier(
    getEngagementAnalyticsUseCase:
        ref.watch(getEngagementAnalyticsUseCaseProvider),
  );
});
