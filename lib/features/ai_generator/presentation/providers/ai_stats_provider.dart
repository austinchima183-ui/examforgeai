import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_generator_repository.dart';
import '../../domain/usecases/get_ai_dashboard_stats_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI STATS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI dashboard statistics feature.
///
/// Tracks aggregated dashboard stats, usage history, and loading state.
class AiStatsState {
  const AiStatsState({
    this.stats,
    this.usageHistory = const [],
    this.isLoading = false,
    this.error,
  });

  /// Aggregated AI dashboard statistics.
  final AiDashboardStatsEntity? stats;

  /// Usage history records (daily breakdown).
  final List<AiUsageStatsEntity> usageHistory;

  /// Whether stats are being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether stats have been loaded at least once.
  bool get hasData => stats != null;

  /// Total questions generated according to the loaded stats.
  int get totalGenerated => stats?.totalGenerated ?? 0;

  /// Total questions approved.
  int get totalApproved => stats?.totalApproved ?? 0;

  /// Total questions rejected.
  int get totalRejected => stats?.totalRejected ?? 0;

  /// Questions pending review.
  int get pendingReview => stats?.pendingReview ?? 0;

  /// Total cost in USD.
  double get totalCost => stats?.totalCost ?? 0.0;

  /// Total tokens consumed.
  int get totalTokensUsed => stats?.totalTokensUsed ?? 0;

  /// Creates a copy of this state with the given fields replaced.
  AiStatsState copyWith({
    AiDashboardStatsEntity? stats,
    List<AiUsageStatsEntity>? usageHistory,
    bool? isLoading,
    String? error,
  }) {
    return AiStatsState(
      stats: stats ?? this.stats,
      usageHistory: usageHistory ?? this.usageHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  AiStatsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI STATS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI dashboard statistics
/// feature's state.
///
/// Provides methods for loading dashboard stats and usage history with
/// optional date range filters.
class AiStatsNotifier extends StateNotifier<AiStatsState> {
  AiStatsNotifier({
    required GetAiDashboardStatsUseCase getAiDashboardStatsUseCase,
    required AiGeneratorRepository repository,
  })  : _getAiDashboardStatsUseCase = getAiDashboardStatsUseCase,
        _repository = repository,
        super(const AiStatsState());

  final GetAiDashboardStatsUseCase _getAiDashboardStatsUseCase;
  final AiGeneratorRepository _repository;

  // ─── Load Stats ──────────────────────────────────────────────────

  /// Loads aggregated dashboard statistics, optionally scoped to a
  /// specific school.
  Future<void> loadStats({String? schoolId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAiDashboardStatsUseCase(
      GetDashboardStatsParams(schoolId: schoolId),
    );

    result.fold(
      onSuccess: (stats) {
        state = state.copyWith(
          isLoading: false,
          stats: stats,
          error: null,
        );
        AppLogger.info(
          'Loaded AI stats: ${stats.totalGenerated} generated, '
          '${stats.totalApproved} approved',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load AI stats: $failure');
      },
    );
  }

  // ─── Load Usage History ──────────────────────────────────────────

  /// Loads usage history with optional school scoping and date range.
  Future<void> loadUsageHistory({
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getUsageStats(
      schoolId: schoolId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      onSuccess: (usageStats) {
        state = state.copyWith(
          isLoading: false,
          usageHistory: usageStats,
          error: null,
        );
        AppLogger.info(
          'Loaded ${usageStats.length} usage history records',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load usage history: $failure');
      },
    );
  }

  // ─── Refresh Stats ───────────────────────────────────────────────

  /// Refreshes both dashboard stats and usage history.
  Future<void> refreshStats({String? schoolId}) async {
    await Future.wait([
      loadStats(schoolId: schoolId),
      loadUsageHistory(schoolId: schoolId),
    ]);
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
