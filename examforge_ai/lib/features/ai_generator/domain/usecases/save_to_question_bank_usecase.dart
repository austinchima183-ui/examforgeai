import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [SaveToQuestionBankUseCase].
class SaveToQuestionBankParams {
  const SaveToQuestionBankParams({
    required this.generatedQuestionId,
  });

  /// The ID of the generated question to save to the question bank.
  final String generatedQuestionId;
}

/// Use case that saves an approved generated question to the Question
/// Bank module.
///
/// Validates that a non-empty [generatedQuestionId] is provided, then
/// delegates to [AiGeneratorRepository.saveToQuestionBank], which
/// creates a corresponding [QuestionEntity] and returns the new
/// question bank ID.
///
/// ```dart
/// final result = await saveToQuestionBankUseCase(
///   SaveToQuestionBankParams(generatedQuestionId: 'gq-123'),
/// );
/// result.fold(
///   onSuccess: (questionBankId) => showSuccess('Saved as $questionBankId'),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class SaveToQuestionBankUseCase {
  SaveToQuestionBankUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<String>> call(SaveToQuestionBankParams params) async {
    // ── Validate generated question ID ──────────────────────────────
    if (params.generatedQuestionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Generated question ID is required',
          fieldErrors: {
            'generatedQuestionId': 'Provide a valid generated question ID',
          },
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.saveToQuestionBank(params.generatedQuestionId);
  }
}
