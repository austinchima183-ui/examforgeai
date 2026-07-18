import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// The type of review action to perform on a generated question.
enum ReviewAction {
  approve('approve'),
  reject('reject'),
  revision('revision');

  const ReviewAction(this.value);

  /// The string representation stored in the backend.
  final String value;

  /// Parses a raw [value] string into a [ReviewAction].
  ///
  /// Returns `null` if the value does not match any known action.
  static ReviewAction? fromString(String? value) {
    if (value == null) return null;
    return ReviewAction.values.cast<ReviewAction?>().firstWhere(
          (action) => action?.value == value,
          orElse: () => null,
        );
  }
}

/// Parameters for the [ReviewGeneratedQuestionUseCase].
class ReviewParams {
  const ReviewParams({
    required this.questionId,
    required this.action,
    this.notes,
  });

  /// The ID of the generated question to review.
  final String questionId;

  /// The review action to perform.
  final ReviewAction action;

  /// Optional notes or reason for the review decision.
  final String? notes;
}

/// Use case that handles review actions on generated questions.
///
/// Supports three review actions:
/// - **approve**: Marks the question as approved and ready for the
///   question bank.
/// - **reject**: Marks the question as rejected with a required reason.
/// - **revision**: Marks the question as needing revision with notes.
///
/// Validates that the question ID is provided and that rejection
/// includes a reason, then delegates to the appropriate repository
/// method.
///
/// ```dart
/// final result = await reviewGeneratedQuestionUseCase(
///   ReviewParams(
///     questionId: 'gq-123',
///     action: ReviewAction.approve,
///     notes: 'Well-structured question with clear distractors',
///   ),
/// );
/// result.fold(
///   onSuccess: (question) => showSuccess('Question approved'),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ReviewGeneratedQuestionUseCase {
  ReviewGeneratedQuestionUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<GeneratedQuestionEntity>> call(ReviewParams params) async {
    // ── Validate question ID ────────────────────────────────────────
    if (params.questionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Provide a valid question ID'},
        ),
      );
    }

    // ── Validate rejection reason ───────────────────────────────────
    if (params.action == ReviewAction.reject &&
        (params.notes == null || params.notes!.trim().isEmpty)) {
      return const FailureResult(
        Failure.validation(
          message: 'A reason is required when rejecting a question',
          fieldErrors: {'notes': 'Please provide a reason for rejection'},
        ),
      );
    }

    // ── Validate revision notes ─────────────────────────────────────
    if (params.action == ReviewAction.revision &&
        (params.notes == null || params.notes!.trim().isEmpty)) {
      return const FailureResult(
        Failure.validation(
          message: 'Notes are required when requesting revision',
          fieldErrors: {'notes': 'Please provide revision instructions'},
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    switch (params.action) {
      case ReviewAction.approve:
        return _repository.approveQuestion(
          params.questionId,
          reviewNotes: params.notes,
        );
      case ReviewAction.reject:
        return _repository.rejectQuestion(
          params.questionId,
          params.notes!,
        );
      case ReviewAction.revision:
        return _repository.requestRevision(
          params.questionId,
          params.notes!,
        );
    }
  }
}
