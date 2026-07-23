import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/question_bank_repository.dart';

/// The type of status action to perform on a question.
enum QuestionStatusAction {
  publish('publish'),
  archive('archive'),
  restore('restore'),
  duplicate('duplicate');

  const QuestionStatusAction(this.value);

  /// The string representation stored in the backend.
  final String value;

  /// Parses a raw [value] string into a [QuestionStatusAction].
  ///
  /// Returns `null` if the value does not match any known action.
  static QuestionStatusAction? fromString(String? value) {
    if (value == null) return null;
    return QuestionStatusAction.values.cast<QuestionStatusAction?>().firstWhere(
          (action) => action?.value == value,
          orElse: () => null,
        );
  }
}

/// Parameters for the [ManageQuestionStatusUseCase].
class ManageQuestionStatusParams {
  const ManageQuestionStatusParams({
    required this.questionId,
    required this.action,
  });

  /// The ID of the question to act upon.
  final String questionId;

  /// The status action to perform.
  final QuestionStatusAction action;
}

/// Use case that manages the lifecycle status of a question.
///
/// Supports four actions:
/// - **publish** — makes a draft question visible to students.
/// - **archive** — hides a question from active lists.
/// - **restore** — brings an archived question back to active.
/// - **duplicate** — creates a deep copy of a question.
///
/// Validates that [questionId] is non-empty and delegates to the
/// appropriate repository method based on [action].
///
/// ```dart
/// final result = await manageStatusUseCase(
///   ManageQuestionStatusParams(
///     questionId: 'q-789',
///     action: QuestionStatusAction.publish,
///   ),
/// );
/// result.fold(
///   onSuccess: (data) => handleSuccess(data),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ManageQuestionStatusUseCase {
  ManageQuestionStatusUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<dynamic>> call(ManageQuestionStatusParams params) async {
    if (params.questionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Please provide a valid question ID'},
        ),
      );
    }

    switch (params.action) {
      case QuestionStatusAction.publish:
        return _repository.publishQuestion(params.questionId);

      case QuestionStatusAction.archive:
        return _repository.archiveQuestion(params.questionId);

      case QuestionStatusAction.restore:
        return _repository.restoreQuestion(params.questionId);

      case QuestionStatusAction.duplicate:
        return _repository.duplicateQuestion(params.questionId);
    }
  }
}
