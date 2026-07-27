import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [ImproveQuestionUseCase].
class ImproveQuestionParams {
  const ImproveQuestionParams({
    required this.questionId,
    required this.improvementType,
    this.customInstructions,
  });

  /// The ID of the generated question to improve.
  final String questionId;

  /// The type of improvement to request (e.g., "clarity",
  /// "distractors", "difficulty", "explanation").
  final String improvementType;

  /// Optional custom instructions to guide the AI improvement.
  final String? customInstructions;
}

/// Use case that submits a generated question for AI-powered improvement.
///
/// Validates that the question ID and improvement type are provided,
/// then delegates to [AiGeneratorRepository.improveQuestion].
///
/// ```dart
/// final result = await improveQuestionUseCase(
///   ImproveQuestionParams(
///     questionId: 'gq-123',
///     improvementType: 'distractors',
///     customInstructions: 'Make distractors more plausible for JAMB level',
///   ),
/// );
/// result.fold(
///   onSuccess: (improvement) => showImprovement(improvement),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ImproveQuestionUseCase {
  ImproveQuestionUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<QuestionImprovementEntity>> call(
    ImproveQuestionParams params,
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

    // ── Validate improvement type ───────────────────────────────────
    if (params.improvementType.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Improvement type is required',
          fieldErrors: {
            'improvementType': 'Specify the type of improvement needed',
          },
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.improveQuestion(
      params.questionId,
      params.improvementType,
      customInstructions: params.customInstructions,
    );
  }
}
