import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_generator_repository.dart';
import '../../domain/usecases/improve_question_usecase.dart';
import '../../domain/usecases/review_generated_question_usecase.dart';
import '../../domain/usecases/save_to_question_bank_usecase.dart';
import '../../domain/usecases/validate_question_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI REVIEW STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI question review workflow.
///
/// Tracks pending questions for review, the currently selected question,
/// validation results, improvement previews, and filter state.
class AiReviewState {
  const AiReviewState({
    this.pendingQuestions = const [],
    this.currentQuestion,
    this.validationResults = const [],
    this.improvementResult,
    this.isLoading = false,
    this.isReviewing = false,
    this.error,
    this.successMessage,
    this.filter,
  });

  /// Questions pending review, optionally filtered by [filter].
  final List<GeneratedQuestionEntity> pendingQuestions;

  /// The currently selected question for detailed review.
  final GeneratedQuestionEntity? currentQuestion;

  /// Validation results for the [currentQuestion].
  final List<ValidationResultEntity> validationResults;

  /// The latest improvement preview, if any.
  final QuestionImprovementEntity? improvementResult;

  /// Whether questions are being loaded.
  final bool isLoading;

  /// Whether a review action (approve/reject/revision) is in progress.
  final bool isReviewing;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Optional filter on [ReviewStatus] for the pending questions list.
  final ReviewStatus? filter;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isReviewing;

  /// Number of pending questions currently loaded.
  int get pendingCount => pendingQuestions.length;

  /// Number of validation issues for the current question.
  int get validationIssueCount => validationResults.length;

  /// Whether the current question has critical validation issues.
  bool get hasCriticalIssues => validationResults.any(
        (v) =>
            v.severity == ValidationSeverity.error ||
            v.severity == ValidationSeverity.critical,
      );

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Note: [error], [successMessage], and [improvementResult] use direct
  /// assignment (no `??`) so they can be explicitly cleared with `null`.
  AiReviewState copyWith({
    List<GeneratedQuestionEntity>? pendingQuestions,
    GeneratedQuestionEntity? currentQuestion,
    bool clearCurrentQuestion = false,
    List<ValidationResultEntity>? validationResults,
    QuestionImprovementEntity? improvementResult,
    bool clearImprovementResult = false,
    bool? isLoading,
    bool? isReviewing,
    String? error,
    String? successMessage,
    ReviewStatus? filter,
  }) {
    return AiReviewState(
      pendingQuestions: pendingQuestions ?? this.pendingQuestions,
      currentQuestion: clearCurrentQuestion ? null : (currentQuestion ?? this.currentQuestion),
      validationResults: validationResults ?? this.validationResults,
      improvementResult: clearImprovementResult ? null : (improvementResult ?? this.improvementResult),
      isLoading: isLoading ?? this.isLoading,
      isReviewing: isReviewing ?? this.isReviewing,
      error: error,
      successMessage: successMessage,
      filter: filter ?? this.filter,
    );
  }

  /// Clears the current error message.
  AiReviewState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AiReviewState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI REVIEW NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI question review
/// workflow state.
///
/// Provides methods for loading pending questions, reviewing (approve,
/// reject, request revision), improving, validating, and saving
/// approved questions to the Question Bank.
class AiReviewNotifier extends StateNotifier<AiReviewState> {
  AiReviewNotifier({
    required AiGeneratorRepository repository,
    required ReviewGeneratedQuestionUseCase reviewGeneratedQuestionUseCase,
    required ImproveQuestionUseCase improveQuestionUseCase,
    required ValidateQuestionUseCase validateQuestionUseCase,
    required SaveToQuestionBankUseCase saveToQuestionBankUseCase,
  })  : _repository = repository,
        _reviewGeneratedQuestionUseCase = reviewGeneratedQuestionUseCase,
        _improveQuestionUseCase = improveQuestionUseCase,
        _validateQuestionUseCase = validateQuestionUseCase,
        _saveToQuestionBankUseCase = saveToQuestionBankUseCase,
        super(const AiReviewState());

  final AiGeneratorRepository _repository;
  final ReviewGeneratedQuestionUseCase _reviewGeneratedQuestionUseCase;
  final ImproveQuestionUseCase _improveQuestionUseCase;
  final ValidateQuestionUseCase _validateQuestionUseCase;
  final SaveToQuestionBankUseCase _saveToQuestionBankUseCase;

  // ─── Load Pending Questions ──────────────────────────────────────

  /// Loads questions pending review, optionally filtered by [filter].
  Future<void> loadPendingQuestions({ReviewStatus? filter}) async {
    state = state.copyWith(isLoading: true, error: null);

    final effectiveFilter = filter ?? state.filter;

    final result = await _repository.getGeneratedQuestions(
      reviewStatus: effectiveFilter,
      page: 1,
      perPage: 50,
    );

    result.fold(
      onSuccess: (questions) {
        state = state.copyWith(
          isLoading: false,
          pendingQuestions: questions,
          filter: effectiveFilter,
          error: null,
        );
        AppLogger.info('Loaded ${questions.length} pending questions');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load pending questions: $failure');
      },
    );
  }

  // ─── Load Question Detail ────────────────────────────────────────

  /// Loads a single question for detailed review.
  Future<void> loadQuestionDetail(String questionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getGeneratedQuestion(questionId);

    result.fold(
      onSuccess: (question) {
        state = state.copyWith(
          isLoading: false,
          currentQuestion: question,
          validationResults: const [],
          clearImprovementResult: true,
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

  // ─── Load Validation Results ─────────────────────────────────────

  /// Loads validation results for a specific question.
  Future<void> loadValidationResults(String questionId) async {
    state = state.copyWith(error: null);

    final result = await _validateQuestionUseCase(
      ValidateQuestionParams(questionId: questionId),
    );

    result.fold(
      onSuccess: (validationResults) {
        state = state.copyWith(
          validationResults: validationResults,
          error: null,
        );
        AppLogger.info(
          'Loaded ${validationResults.length} validation results for $questionId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to load validation results: $failure');
      },
    );
  }

  // ─── Approve ─────────────────────────────────────────────────────

  /// Approves a generated question, optionally with [notes].
  Future<void> approve(String questionId, {String? notes}) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.approve,
        notes: notes,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.pendingQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          isReviewing: false,
          pendingQuestions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? question
              : state.currentQuestion,
          successMessage: 'Question approved',
          error: null,
        );
        AppLogger.info('Question approved: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to approve question: $failure');
      },
    );
  }

  // ─── Reject ──────────────────────────────────────────────────────

  /// Rejects a generated question with the given [reason].
  Future<void> reject(String questionId, String reason) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.reject,
        notes: reason,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.pendingQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          isReviewing: false,
          pendingQuestions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? question
              : state.currentQuestion,
          successMessage: 'Question rejected',
          error: null,
        );
        AppLogger.info('Question rejected: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to reject question: $failure');
      },
    );
  }

  // ─── Request Revision ────────────────────────────────────────────

  /// Requests revision for a generated question with [notes].
  Future<void> requestRevision(String questionId, String notes) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.revision,
        notes: notes,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.pendingQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          isReviewing: false,
          pendingQuestions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? question
              : state.currentQuestion,
          successMessage: 'Revision requested',
          error: null,
        );
        AppLogger.info('Revision requested for question: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to request revision: $failure');
      },
    );
  }

  // ─── Improve and Preview ─────────────────────────────────────────

  /// Submits a question for AI improvement and previews the result.
  ///
  /// [improvementType] describes the kind of improvement (e.g.
  /// "clarity", "distractors", "difficulty", "explanation").
  Future<void> improveAndPreview(
    String questionId,
    String improvementType,
  ) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _improveQuestionUseCase(
      ImproveQuestionParams(
        questionId: questionId,
        improvementType: improvementType,
      ),
    );

    result.fold(
      onSuccess: (improvement) {
        state = state.copyWith(
          isReviewing: false,
          improvementResult: improvement,
          successMessage: 'Improvement preview ready',
          error: null,
        );
        AppLogger.info(
          'Improvement preview ready for $questionId ($improvementType)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to improve question: $failure');
      },
    );
  }

  // ─── Accept Improvement ──────────────────────────────────────────

  /// Accepts an improvement suggestion, applying it to the question.
  Future<void> acceptImprovement(String improvementId) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _repository.acceptImprovement(improvementId);

    result.fold(
      onSuccess: (updatedQuestion) {
        // Update the current question with the improved version
        final updatedList = state.pendingQuestions
            .map((q) => q.id == updatedQuestion.id ? updatedQuestion : q)
            .toList();
        state = state.copyWith(
          isReviewing: false,
          pendingQuestions: updatedList,
          currentQuestion: state.currentQuestion?.id == updatedQuestion.id
              ? updatedQuestion
              : state.currentQuestion,
          clearImprovementResult: true,
          successMessage: 'Improvement applied',
          error: null,
        );
        AppLogger.info('Improvement accepted: $improvementId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to accept improvement: $failure');
      },
    );
  }

  // ─── Save Approved to Question Bank ──────────────────────────────

  /// Saves an approved generated question to the Question Bank module.
  Future<void> saveApprovedToQuestionBank(String questionId) async {
    state = state.copyWith(isReviewing: true, error: null);

    final result = await _saveToQuestionBankUseCase(
      SaveToQuestionBankParams(generatedQuestionId: questionId),
    );

    result.fold(
      onSuccess: (questionBankId) {
        // Update the question in the list
        final updatedList = state.pendingQuestions.map((q) {
          if (q.id == questionId) {
            return q.copyWith(
              questionBankId: questionBankId,
              isApproved: true,
              reviewStatus: ReviewStatus.approved,
            );
          }
          return q;
        }).toList();
        state = state.copyWith(
          isReviewing: false,
          pendingQuestions: updatedList,
          currentQuestion: state.currentQuestion?.id == questionId
              ? state.currentQuestion!.copyWith(
                  questionBankId: questionBankId,
                  isApproved: true,
                  reviewStatus: ReviewStatus.approved,
                )
              : state.currentQuestion,
          successMessage: 'Question saved to Question Bank',
          error: null,
        );
        AppLogger.info(
          'Saved approved question to bank: $questionId → $questionBankId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isReviewing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to save to question bank: $failure');
      },
    );
  }

  // ─── Filter ──────────────────────────────────────────────────────

  /// Sets the review status filter and reloads pending questions.
  void setFilter(ReviewStatus? filter) {
    state = state.copyWith(filter: filter);
    loadPendingQuestions(filter: filter);
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
