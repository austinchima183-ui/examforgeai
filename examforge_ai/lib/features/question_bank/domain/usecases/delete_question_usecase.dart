import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [DeleteQuestionUseCase].
class DeleteQuestionParams {
  const DeleteQuestionParams({
    required this.questionId,
  });

  /// The ID of the question to delete.
  final String questionId;
}

/// Use case that permanently deletes a question from the question bank.
///
/// Validates that a non-empty [questionId] is provided, then delegates
/// to [QuestionBankRepository.deleteQuestion].
///
/// ```dart
/// final result = await deleteQuestionUseCase(
///   DeleteQuestionParams(questionId: 'q-123'),
/// );
/// result.fold(
///   onSuccess: (_) => showSuccess('Question deleted'),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class DeleteQuestionUseCase {
  DeleteQuestionUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<void>> call(DeleteQuestionParams params) async {
    if (params.questionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Please provide a valid question ID'},
        ),
      );
    }

    return _repository.deleteQuestion(params.questionId);
  }
}
