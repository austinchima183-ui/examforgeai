import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../../domain/usecases/manage_exam_status_usecase.dart';


// ═══════════════════════════════════════════════════════════════════════
// EXAM LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the exam listing and filtering feature.
///
/// Tracks the current list of exams, pagination state, active filters,
/// and loading flags.
class ExamListState {
  const ExamListState({
    this.exams = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.subjectFilter,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
  });

  /// The current page of exams.
  final List<ExamEntity> exams;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by exam status.
  final ExamStatus? statusFilter;

  /// Filter by subject ID.
  final String? subjectFilter;

  /// The current page number (1-based).
  final int currentPage;

  /// Total number of exams matching the current filter.
  final int totalCount;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Number of exams currently loaded.
  int get loadedCount => exams.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  ExamListState copyWith({
    List<ExamEntity>? exams,
    bool? isLoading,
    String? error,
    ExamStatus? statusFilter,
    String? subjectFilter,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
  }) {
    return ExamListState(
      exams: exams ?? this.exams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      subjectFilter: subjectFilter ?? this.subjectFilter,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Clears the current error message.
  ExamListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the exam list feature's state.
///
/// Provides methods for loading, filtering, paginating, and managing
/// exam lifecycle actions (archive, cancel, clone).
class ExamListNotifier extends StateNotifier<ExamListState> {
  ExamListNotifier({
    required CbtRepository cbtRepository,
    required ManageExamStatusUseCase manageExamStatusUseCase,
  })  : _cbtRepository = cbtRepository,
        _manageExamStatusUseCase = manageExamStatusUseCase,
        super(const ExamListState());

  final CbtRepository _cbtRepository;
  final ManageExamStatusUseCase _manageExamStatusUseCase;

  static const int _perPage = 20;

  // ─── Load Exams (first page) ────────────────────────────────────────

  /// Loads the first page of exams using the current filter.
  Future<void> loadExams() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _cbtRepository.getExams(
      status: state.statusFilter,
      subjectId: state.subjectFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (exams) {
        state = state.copyWith(
          isLoading: false,
          exams: exams,
          currentPage: 1,
          hasMore: exams.length >= _perPage,
          error: null,
        );
        AppLogger.info('Loaded ${exams.length} exams (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load exams: $failure');
      },
    );
  }

  // ─── Load More (pagination) ─────────────────────────────────────────

  /// Loads the next page of exams and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _cbtRepository.getExams(
      status: state.statusFilter,
      subjectId: state.subjectFilter,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (exams) {
        final updatedList = [...state.exams, ...exams];
        state = state.copyWith(
          exams: updatedList,
          currentPage: nextPage,
          hasMore: exams.length >= _perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${exams.length} more exams (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more exams: $failure');
      },
    );
  }

  // ─── Refresh ────────────────────────────────────────────────────────

  /// Refreshes the exam list by reloading the first page.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _cbtRepository.getExams(
      status: state.statusFilter,
      subjectId: state.subjectFilter,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (exams) {
        state = state.copyWith(
          isLoading: false,
          exams: exams,
          currentPage: 1,
          hasMore: exams.length >= _perPage,
          error: null,
        );
        AppLogger.info('Refreshed exams list');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to refresh exams: $failure');
      },
    );
  }

  // ─── Set Filter ─────────────────────────────────────────────────────

  /// Updates the status filter and reloads the exam list.
  Future<void> setStatusFilter(ExamStatus? status) async {
    state = state.copyWith(statusFilter: status);
    await loadExams();
  }

  /// Updates the subject filter and reloads the exam list.
  Future<void> setSubjectFilter(String? subjectId) async {
    state = state.copyWith(subjectFilter: subjectId);
    await loadExams();
  }

  /// Sets multiple filters at once and reloads.
  Future<void> setFilter({
    ExamStatus? status,
    String? subjectId,
  }) async {
    state = state.copyWith(
      statusFilter: status,
      subjectFilter: subjectId,
    );
    await loadExams();
  }

  // ─── Clear Filters ──────────────────────────────────────────────────

  /// Resets all filters and reloads the exam list.
  Future<void> clearFilters() async {
    state = state.copyWith(
      statusFilter: null,
      subjectFilter: null,
    );
    await loadExams();
  }

  // ─── Archive Exam ───────────────────────────────────────────────────

  /// Archives an exam by its ID.
  Future<void> archiveExam(String examId) async {
    final result = await _manageExamStatusUseCase(
      ManageStatusParams(
        examId: examId,
        action: ManageStatusAction.archive,
      ),
    );

    result.fold(
      onSuccess: (updatedExam) {
        final updatedList = state.exams
            .map((e) => e.id == updatedExam.id ? updatedExam : e)
            .toList();
        state = state.copyWith(exams: updatedList);
        AppLogger.info('Exam archived: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to archive exam: $failure');
      },
    );
  }

  // ─── Cancel Exam ────────────────────────────────────────────────────

  /// Cancels an exam by its ID.
  Future<void> cancelExam(String examId) async {
    final result = await _manageExamStatusUseCase(
      ManageStatusParams(
        examId: examId,
        action: ManageStatusAction.cancel,
      ),
    );

    result.fold(
      onSuccess: (updatedExam) {
        final updatedList = state.exams
            .map((e) => e.id == updatedExam.id ? updatedExam : e)
            .toList();
        state = state.copyWith(exams: updatedList);
        AppLogger.info('Exam cancelled: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to cancel exam: $failure');
      },
    );
  }

  // ─── Clone Exam ─────────────────────────────────────────────────────

  /// Clones an exam by its ID.
  Future<void> cloneExam(String examId) async {
    final result = await _manageExamStatusUseCase(
      ManageStatusParams(
        examId: examId,
        action: ManageStatusAction.clone,
      ),
    );

    result.fold(
      onSuccess: (clonedExam) {
        final updatedList = [clonedExam, ...state.exams];
        state = state.copyWith(exams: updatedList);
        AppLogger.info('Exam cloned: ${clonedExam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to clone exam: $failure');
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────────

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
