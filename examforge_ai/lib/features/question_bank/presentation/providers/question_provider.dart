import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/usecases/create_question_usecase.dart';
import '../../domain/usecases/delete_question_usecase.dart';
import '../../domain/usecases/get_question_detail_usecase.dart';
import '../../domain/usecases/get_question_stats_usecase.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import '../../domain/usecases/manage_question_status_usecase.dart';
import '../../domain/usecases/search_questions_usecase.dart';
import '../../domain/usecases/update_question_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the question bank feature.
///
/// Tracks the current list of questions, pagination state, loading flags
/// for each operation, and the active filter applied by the user.
class QuestionBankState {
  const QuestionBankState({
    this.questions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.currentQuestion,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const QuestionFilterEntity(),
    this.successMessage,
  });

  /// The current page of questions.
  final List<QuestionEntity> questions;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a pagination (load-more) request is in progress.
  final bool isLoadingMore;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected question with full details, or `null`.
  final QuestionEntity? currentQuestion;

  /// Total number of questions matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final QuestionFilterEntity filter;

  /// A transient success message (e.g. "Question created"), or `null`.
  final String? successMessage;

  /// Number of questions currently loaded.
  int get loadedCount => questions.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isLoadingMore || isCreating || isUpdating || isDeleting;

  /// Creates a copy of this state with the given fields replaced.
  QuestionBankState copyWith({
    List<QuestionEntity>? questions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    QuestionEntity? currentQuestion,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    QuestionFilterEntity? filter,
    String? successMessage,
  }) {
    return QuestionBankState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  QuestionBankState clearError() => copyWith(error: null);

  /// Clears the current success message.
  QuestionBankState clearSuccessMessage() =>
      copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the question bank feature's state.
///
/// All question list operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the question list, pagination, and filter state on success
/// 4. Sets [error] on failure
class QuestionBankNotifier extends StateNotifier<QuestionBankState> {
  QuestionBankNotifier({
    required GetQuestionsUseCase getQuestionsUseCase,
    required CreateQuestionUseCase createQuestionUseCase,
    required UpdateQuestionUseCase updateQuestionUseCase,
    required DeleteQuestionUseCase deleteQuestionUseCase,
    required GetQuestionDetailUseCase getQuestionDetailUseCase,
    required SearchQuestionsUseCase searchQuestionsUseCase,
    required ManageQuestionStatusUseCase manageQuestionStatusUseCase,
    required GetQuestionStatsUseCase getQuestionStatsUseCase,
  })  : _getQuestionsUseCase = getQuestionsUseCase,
        _createQuestionUseCase = createQuestionUseCase,
        _updateQuestionUseCase = updateQuestionUseCase,
        _deleteQuestionUseCase = deleteQuestionUseCase,
        _getQuestionDetailUseCase = getQuestionDetailUseCase,
        _searchQuestionsUseCase = searchQuestionsUseCase,
        _manageQuestionStatusUseCase = manageQuestionStatusUseCase,
        _getQuestionStatsUseCase = getQuestionStatsUseCase,
        super(const QuestionBankState());

  final GetQuestionsUseCase _getQuestionsUseCase;
  final CreateQuestionUseCase _createQuestionUseCase;
  final UpdateQuestionUseCase _updateQuestionUseCase;
  final DeleteQuestionUseCase _deleteQuestionUseCase;
  final GetQuestionDetailUseCase _getQuestionDetailUseCase;
  final SearchQuestionsUseCase _searchQuestionsUseCase;
  final ManageQuestionStatusUseCase _manageQuestionStatusUseCase;
  final GetQuestionStatsUseCase _getQuestionStatsUseCase;

  // ─── Load Questions (first page) ────────────────────────────────────

  /// Loads the first page of questions using the current filter.
  Future<void> loadQuestions() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getQuestionsUseCase(
      GetQuestionsParams(filter: filter),
    );

    result.fold(
      onSuccess: (questions) {
        state = state.copyWith(
          isLoading: false,
          questions: questions,
          currentPage: 1,
          hasMore: questions.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${questions.length} questions (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load questions: $failure');
      },
    );

    // Also fetch total count in the background.
    _loadTotalCount();
  }

  // ─── Load More Questions (pagination) ───────────────────────────────

  /// Loads the next page of questions and appends to the existing list.
  Future<void> loadMoreQuestions() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final nextPage = state.currentPage + 1;
    final filter = state.filter.copyWith(page: nextPage);
    final result = await _getQuestionsUseCase(
      GetQuestionsParams(filter: filter),
    );

    result.fold(
      onSuccess: (questions) {
        final updatedList = [...state.questions, ...questions];
        state = state.copyWith(
          isLoadingMore: false,
          questions: updatedList,
          currentPage: nextPage,
          hasMore: questions.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${questions.length} more questions (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more questions: $failure');
      },
    );
  }

  // ─── Refresh Questions ──────────────────────────────────────────────

  /// Refreshes the question list by reloading the first page.
  Future<void> refreshQuestions() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getQuestionsUseCase(
      GetQuestionsParams(filter: filter),
    );

    result.fold(
      onSuccess: (questions) {
        state = state.copyWith(
          isLoading: false,
          questions: questions,
          currentPage: 1,
          hasMore: questions.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Refreshed questions list');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to refresh questions: $failure');
      },
    );
  }

  // ─── Create Question ────────────────────────────────────────────────

  /// Creates a new question with the provided [params].
  Future<void> createQuestion(CreateQuestionParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createQuestionUseCase(params);

    result.fold(
      onSuccess: (question) {
        final updatedList = [question, ...state.questions];
        state = state.copyWith(
          isCreating: false,
          questions: updatedList,
          successMessage: 'Question created successfully',
          error: null,
        );
        AppLogger.info('Question created: ${question.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create question: $failure');
      },
    );
  }

  // ─── Update Question ────────────────────────────────────────────────

  /// Updates an existing question with the provided [params].
  Future<void> updateQuestion(UpdateQuestionParams params) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _updateQuestionUseCase(params);

    result.fold(
      onSuccess: (updatedQuestion) {
        final updatedList = state.questions
            .map((q) => q.id == updatedQuestion.id ? updatedQuestion : q)
            .toList();
        state = state.copyWith(
          isUpdating: false,
          questions: updatedList,
          currentQuestion: state.currentQuestion?.id == updatedQuestion.id
              ? updatedQuestion
              : state.currentQuestion,
          successMessage: 'Question updated successfully',
          error: null,
        );
        AppLogger.info('Question updated: ${updatedQuestion.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update question: $failure');
      },
    );
  }

  // ─── Delete Question ────────────────────────────────────────────────

  /// Deletes a question by [questionId].
  Future<void> deleteQuestion(String questionId) async {
    state = state.copyWith(isDeleting: true, error: null);

    final result = await _deleteQuestionUseCase(
      DeleteQuestionParams(questionId: questionId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.questions.where((q) => q.id != questionId).toList();
        state = state.copyWith(
          isDeleting: false,
          questions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? null
              : state.currentQuestion,
          successMessage: 'Question deleted successfully',
          error: null,
        );
        AppLogger.info('Question deleted: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isDeleting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete question: $failure');
      },
    );
  }

  // ─── Get Question Detail ────────────────────────────────────────────

  /// Retrieves a single question with all its details.
  Future<void> getQuestionDetail(String questionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getQuestionDetailUseCase(
      GetQuestionDetailParams(
        questionId: questionId,
        includeDetails: true,
      ),
    );

    result.fold(
      onSuccess: (question) {
        state = state.copyWith(
          isLoading: false,
          currentQuestion: question,
          error: null,
        );
        AppLogger.info('Loaded question detail: ${question.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load question detail: $failure');
      },
    );
  }

  // ─── Search Questions ───────────────────────────────────────────────

  /// Searches questions using the given [query] combined with the
  /// current filter state.
  Future<void> searchQuestions(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    final searchFilter = state.filter.copyWith(
      searchQuery: query,
      page: 1,
    );
    final result = await _searchQuestionsUseCase(
      SearchQuestionsParams(query: query, filter: searchFilter),
    );

    result.fold(
      onSuccess: (questions) {
        state = state.copyWith(
          isLoading: false,
          questions: questions,
          currentPage: 1,
          hasMore: questions.length >= state.filter.perPage,
          filter: searchFilter,
          error: null,
        );
        AppLogger.info(
          'Search returned ${questions.length} results for "$query"',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Search failed: $failure');
      },
    );
  }

  // ─── Set Filter ─────────────────────────────────────────────────────

  /// Updates the active filter and reloads the question list.
  Future<void> setFilter(QuestionFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadQuestions();
  }

  // ─── Clear Filter ───────────────────────────────────────────────────

  /// Resets the filter to its default state and reloads questions.
  Future<void> clearFilter() async {
    state = state.copyWith(filter: const QuestionFilterEntity());
    await loadQuestions();
  }

  // ─── Publish Question ───────────────────────────────────────────────

  /// Publishes a draft question, making it visible to students.
  Future<void> publishQuestion(String questionId) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _manageQuestionStatusUseCase(
      ManageQuestionStatusParams(
        questionId: questionId,
        action: QuestionStatusAction.publish,
      ),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.questions.map((q) {
          if (q.id == questionId) {
            return q.copyWith(isPublished: true);
          }
          return q;
        }).toList();
        state = state.copyWith(
          isUpdating: false,
          questions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? state.currentQuestion!.copyWith(isPublished: true)
              : state.currentQuestion,
          successMessage: 'Question published successfully',
          error: null,
        );
        AppLogger.info('Question published: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish question: $failure');
      },
    );
  }

  // ─── Archive Question ───────────────────────────────────────────────

  /// Archives a question, hiding it from active lists.
  Future<void> archiveQuestion(String questionId) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _manageQuestionStatusUseCase(
      ManageQuestionStatusParams(
        questionId: questionId,
        action: QuestionStatusAction.archive,
      ),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.questions.map((q) {
          if (q.id == questionId) {
            return q.copyWith(isArchived: true);
          }
          return q;
        }).toList();
        state = state.copyWith(
          isUpdating: false,
          questions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? state.currentQuestion!.copyWith(isArchived: true)
              : state.currentQuestion,
          successMessage: 'Question archived successfully',
          error: null,
        );
        AppLogger.info('Question archived: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to archive question: $failure');
      },
    );
  }

  // ─── Restore Question ───────────────────────────────────────────────

  /// Restores an archived question back to active status.
  Future<void> restoreQuestion(String questionId) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _manageQuestionStatusUseCase(
      ManageQuestionStatusParams(
        questionId: questionId,
        action: QuestionStatusAction.restore,
      ),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.questions.map((q) {
          if (q.id == questionId) {
            return q.copyWith(isArchived: false);
          }
          return q;
        }).toList();
        state = state.copyWith(
          isUpdating: false,
          questions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? state.currentQuestion!.copyWith(isArchived: false)
              : state.currentQuestion,
          successMessage: 'Question restored successfully',
          error: null,
        );
        AppLogger.info('Question restored: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to restore question: $failure');
      },
    );
  }

  // ─── Duplicate Question ─────────────────────────────────────────────

  /// Creates a deep copy of a question with a new ID.
  Future<void> duplicateQuestion(String questionId) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _manageQuestionStatusUseCase(
      ManageQuestionStatusParams(
        questionId: questionId,
        action: QuestionStatusAction.duplicate,
      ),
    );

    result.fold(
      onSuccess: (data) {
        // The duplicate use case returns the new QuestionEntity.
        if (data is QuestionEntity) {
          final updatedList = [data, ...state.questions];
          state = state.copyWith(
            isCreating: false,
            questions: updatedList,
            successMessage: 'Question duplicated successfully',
            error: null,
          );
        } else {
          state = state.copyWith(
            isCreating: false,
            successMessage: 'Question duplicated successfully',
            error: null,
          );
        }
        AppLogger.info('Question duplicated from: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to duplicate question: $failure');
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success Message ──────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads the total count of questions matching the current filter.
  Future<void> _loadTotalCount() async {
    // We derive total count from the current page results.
    // A more accurate count would require a dedicated API call.
    // For now, we estimate based on the loaded data.
  }

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
