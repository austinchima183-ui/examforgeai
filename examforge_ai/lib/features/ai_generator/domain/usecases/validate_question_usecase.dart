import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [ValidateQuestionUseCase].
class ValidateQuestionParams {
  const ValidateQuestionParams({
    required this.questionId,
  });

  /// The ID of the generated question to validate.
  final String questionId;
}

/// Use case that validates a generated question for quality,
/// correctness, and curriculum alignment.
///
/// Validates that a non-empty [questionId] is provided, then delegates
/// to [AiGeneratorRepository.validateQuestion], which returns a list
/// of validation results with varying severity levels.
///
/// ```dart
/// final result = await validateQuestionUseCase(
///   ValidateQuestionParams(questionId: 'gq-123'),
/// );
/// result.fold(
///   onSuccess: (validationResults) {
///     final hasErrors = validationResults.any(
///       (r) => r.severity == ValidationSeverity.error ||
///              r.severity == ValidationSeverity.critical,
///     );
///     if (hasErrors) showValidationErrors(validationResults);
///   },
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ValidateQuestionUseCase {
  ValidateQuestionUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<List<ValidationResultEntity>>> call(
    ValidateQuestionParams params,
  ) async {
    // ── Validate question ID ────────────────────────────────────────
    if (params.questionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Provide a valid question ID'},
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.validateQuestion(params.questionId);
  }
}
