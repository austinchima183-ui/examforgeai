import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/usecases/get_question_stats_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK STATS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the question bank statistics dashboard.
///
/// Holds the aggregated statistics entity and tracks loading/error state.
class QuestionBankStatsState {
  const QuestionBankStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  /// The aggregated question bank statistics, or `null` if not yet loaded.
  final QuestionBankStatsEntity? stats;

  /// Whether statistics are currently being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  QuestionBankStatsState copyWith({
    QuestionBankStatsEntity? stats,
    bool? isLoading,
    String? error,
  }) {
    return QuestionBankStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK STATS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the question bank statistics
/// feature's state.
///
/// Loads aggregated statistics from the backend, optionally scoped to a
/// specific school. Supports pull-to-refresh via [refreshStats].
class QuestionBankStatsNotifier
    extends StateNotifier<QuestionBankStatsState> {
  QuestionBankStatsNotifier({
    required GetQuestionStatsUseCase getQuestionStatsUseCase,
  })  : _getQuestionStatsUseCase = getQuestionStatsUseCase,
        super(const QuestionBankStatsState());

  final GetQuestionStatsUseCase _getQuestionStatsUseCase;

  // ─── Load Stats ─────────────────────────────────────────────────────

  /// Loads question bank statistics, optionally scoped to [schoolId].
  Future<void> loadStats({String? schoolId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getQuestionStatsUseCase(
      GetQuestionStatsParams(schoolId: schoolId),
    );

    result.fold(
      onSuccess: (stats) {
        state = state.copyWith(
          isLoading: false,
          stats: stats,
          error: null,
        );
        AppLogger.info(
          'Loaded stats: ${stats.totalQuestions} total questions',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load stats: $failure');
      },
    );
  }

  // ─── Refresh Stats ──────────────────────────────────────────────────

  /// Refreshes statistics by reloading from the backend.
  Future<void> refreshStats({String? schoolId}) async {
    await loadStats(schoolId: schoolId);
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
