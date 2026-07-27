import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../../domain/usecases/get_exam_results_usecase.dart';
import '../../domain/usecases/get_exam_statistics_usecase.dart';
import '../../domain/usecases/grade_exam_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM RESULTS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the exam results and grading feature.
///
/// Tracks results list, statistics, rankings, loading flags,
/// and the currently selected result.
class ExamResultsState {
  const ExamResultsState({
    this.results = const [],
    this.statistics,
    this.rankings = const [],
    this.currentResult,
    this.isLoading = false,
    this.isGrading = false,
    this.isReleasing = false,
    this.error,
    this.successMessage,
    this.filter,
  });

  /// List of exam results.
  final List<ExamResultEntity> results;

  /// Aggregated exam statistics.
  final ExamStatistics? statistics;

  /// Exam leaderboard rankings.
  final List<ExamRankingEntity> rankings;

  /// The currently selected result for detail view.
  final ExamResultEntity? currentResult;

  /// Whether results are being loaded.
  final bool isLoading;

  /// Whether a grading operation is in progress.
  final bool isGrading;

  /// Whether a release operation is in progress.
  final bool isReleasing;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Optional filter for release status.
  final bool? filter;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isGrading || isReleasing;

  /// Number of results currently loaded.
  int get resultCount => results.length;

  /// Number of students who passed.
  int get passedCount => results.where((r) => r.isPassed).length;

  /// Number of students who failed.
  int get failedCount => results.where((r) => !r.isPassed).length;

  /// Number of results that have been released to students.
  int get releasedCount => results.where((r) => r.isReleased).length;

  /// Creates a copy of this state with the given fields replaced.
  ExamResultsState copyWith({
    List<ExamResultEntity>? results,
    ExamStatistics? statistics,
    List<ExamRankingEntity>? rankings,
    ExamResultEntity? currentResult,
    bool? isLoading,
    bool? isGrading,
    bool? isReleasing,
    String? error,
    String? successMessage,
    bool? filter,
  }) {
    return ExamResultsState(
      results: results ?? this.results,
      statistics: statistics ?? this.statistics,
      rankings: rankings ?? this.rankings,
      currentResult: currentResult ?? this.currentResult,
      isLoading: isLoading ?? this.isLoading,
      isGrading: isGrading ?? this.isGrading,
      isReleasing: isReleasing ?? this.isReleasing,
      error: error,
      successMessage: successMessage,
      filter: filter ?? this.filter,
    );
  }

  /// Clears the current error message.
  ExamResultsState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ExamResultsState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM RESULTS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the exam results and grading state.
///
/// Provides methods for loading results, statistics, rankings,
/// grading individual answers, and releasing results to students.
class ExamResultsNotifier extends StateNotifier<ExamResultsState> {
  ExamResultsNotifier({
    required CbtRepository cbtRepository,
    required GetExamResultsUseCase getExamResultsUseCase,
    required GetExamStatisticsUseCase getExamStatisticsUseCase,
    required GradeExamUseCase gradeExamUseCase,
  })  : _cbtRepository = cbtRepository,
        _getExamResultsUseCase = getExamResultsUseCase,
        _getExamStatisticsUseCase = getExamStatisticsUseCase,
        _gradeExamUseCase = gradeExamUseCase,
        super(const ExamResultsState());

  final CbtRepository _cbtRepository;
  final GetExamResultsUseCase _getExamResultsUseCase;
  final GetExamStatisticsUseCase _getExamStatisticsUseCase;
  final GradeExamUseCase _gradeExamUseCase;

  // ─── Load Results ───────────────────────────────────────────────────

  /// Loads exam results, optionally filtered by release status.
  Future<void> loadResults(String examId, {bool? isReleased}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getExamResultsUseCase(
      GetResultsParams(examId: examId, isReleased: isReleased),
    );

    result.fold(
      onSuccess: (results) {
        state = state.copyWith(
          isLoading: false,
          results: results,
          filter: isReleased,
          error: null,
        );
        AppLogger.info(
          'Loaded ${results.length} results for exam: $examId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load results: $failure');
      },
    );
  }

  // ─── Load Statistics ────────────────────────────────────────────────

  /// Loads aggregated statistics for an exam.
  Future<void> loadStatistics(String examId) async {
    final result = await _getExamStatisticsUseCase(
      GetStatsParams(examId: examId),
    );

    result.fold(
      onSuccess: (statistics) {
        state = state.copyWith(statistics: statistics);
        AppLogger.info('Statistics loaded for exam: $examId');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load statistics: $failure');
      },
    );
  }

  // ─── Grade Answer ───────────────────────────────────────────────────

  /// Grades a specific answer with the awarded marks and optional comment.
  Future<void> gradeAnswer(
    String answerId,
    double marksAwarded, {
    String? comment,
  }) async {
    state = state.copyWith(isGrading: true, error: null);

    final result = await _gradeExamUseCase(
      GradeExamParams(
        examId: '', // examId is used for bulk grading only
        answerId: answerId,
        marksAwarded: marksAwarded,
        comment: comment,
      ),
    );

    result.fold(
      onSuccess: (gradedAnswer) {
        state = state.copyWith(
          isGrading: false,
          successMessage: 'Answer graded successfully',
          error: null,
        );
        AppLogger.info('Answer graded: $answerId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGrading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to grade answer: $failure');
      },
    );
  }

  // ─── Release Results ────────────────────────────────────────────────

  /// Releases exam results to students, making them visible.
  Future<void> releaseResults(String examId) async {
    state = state.copyWith(isReleasing: true, error: null);

    final result = await _cbtRepository.releaseResults(examId);

    result.fold(
      onSuccess: (_) {
        // Mark all results as released in the local state
        final updatedResults = state.results
            .map((r) => r.copyWith(
                  isReleased: true,
                  releasedAt: DateTime.now(),
                ),)
            .toList();

        state = state.copyWith(
          isReleasing: false,
          results: updatedResults,
          successMessage: 'Results released successfully',
          error: null,
        );
        AppLogger.info('Results released for exam: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReleasing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to release results: $failure');
      },
    );
  }

  // ─── Load Rankings ──────────────────────────────────────────────────

  /// Loads the exam leaderboard rankings.
  Future<void> loadRankings(String examId) async {
    final result = await _cbtRepository.getRankings(examId);

    result.fold(
      onSuccess: (rankings) {
        state = state.copyWith(rankings: rankings);
        AppLogger.info(
          'Loaded ${rankings.length} rankings for exam: $examId',
        );
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load rankings: $failure');
      },
    );
  }

  // ─── Load Student Result ────────────────────────────────────────────

  /// Loads the result for a specific student on an exam.
  Future<void> loadStudentResult(
    String examId,
    String studentId,
  ) async {
    final result = await _cbtRepository.getStudentResult(
      examId,
      studentId,
    );

    result.fold(
      onSuccess: (examResult) {
        state = state.copyWith(currentResult: examResult);
        AppLogger.info(
          'Student result loaded: exam=$examId, student=$studentId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load student result: $failure');
      },
    );
  }

  // ─── Clear Error / Success ──────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
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
