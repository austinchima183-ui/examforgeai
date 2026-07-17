import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [GetQuestionDetailUseCase].
class GetQuestionDetailParams {
  const GetQuestionDetailParams({
    required this.questionId,
    this.includeDetails = true,
  });

  /// The ID of the question to retrieve.
  final String questionId;

  /// Whether to include related details (answer options, matching pairs,
  /// ordering items, fill-in-blank answers, attachments, tags).
  /// When `false`, only the core question data is returned.
  final bool includeDetails;
}

/// Use case that retrieves a single question with optional detail
/// inclusion.
///
/// Validates that a non-empty [questionId] is provided, then delegates
/// to either [QuestionBankRepository.getQuestionWithDetails] or
/// [QuestionBankRepository.getQuestion] depending on [includeDetails].
///
/// ```dart
/// final result = await getQuestionDetailUseCase(
///   GetQuestionDetailParams(
///     questionId: 'q-456',
///     includeDetails: true,
///   ),
/// );
/// result.fold(
///   onSuccess: (question) => displayQuestion(question),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GetQuestionDetailUseCase {
  GetQuestionDetailUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<QuestionEntity>> call(
    GetQuestionDetailParams params,
  ) async {
    if (params.questionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Please provide a valid question ID'},
        ),
      );
    }

    if (params.includeDetails) {
      return _repository.getQuestionWithDetails(params.questionId);
    }

    return _repository.getQuestion(params.questionId);
  }
}
