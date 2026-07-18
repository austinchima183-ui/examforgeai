import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [GenerateQuestionsUseCase].
class GenerateQuestionsParams {
  const GenerateQuestionsParams({
    required this.input,
  });

  /// The generation input containing teacher preferences and parameters.
  final GenerationInputEntity input;
}

/// Use case that generates questions using an AI provider.
///
/// Validates that the input has all required fields (subject, topic,
/// difficulty), that the number of questions is within reasonable bounds,
/// and that the language is specified, then delegates to
/// [AiGeneratorRepository.generateQuestions].
///
/// ```dart
/// final result = await generateQuestionsUseCase(
///   GenerateQuestionsParams(
///     input: GenerationInputEntity(
///       subjectId: 'math-101',
///       topicId: 'algebra-01',
///       difficulty: DifficultyLevel.medium,
///       numQuestions: 10,
///     ),
///   ),
/// );
/// result.fold(
///   onSuccess: (questions) => renderQuestions(questions),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GenerateQuestionsUseCase {
  GenerateQuestionsUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<List<GeneratedQuestionEntity>>> call(
    GenerateQuestionsParams params,
  ) async {
    // ── Validate subject ────────────────────────────────────────────
    if (params.input.subjectId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Subject is required for question generation',
          fieldErrors: {'subjectId': 'Please select a subject'},
        ),
      );
    }

    // ── Validate topic ──────────────────────────────────────────────
    if (params.input.topicId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Topic is required for question generation',
          fieldErrors: {'topicId': 'Please select a topic'},
        ),
      );
    }

    // ── Validate number of questions ────────────────────────────────
    if (params.input.numQuestions < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'At least one question must be requested',
          fieldErrors: {'numQuestions': 'Request at least 1 question'},
        ),
      );
    }

    if (params.input.numQuestions > 50) {
      return const FailureResult(
        Failure.validation(
          message: 'Cannot generate more than 50 questions at once',
          fieldErrors: {
            'numQuestions': 'Maximum of 50 questions per request',
          },
        ),
      );
    }

    // ── Validate language ───────────────────────────────────────────
    if (params.input.language.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Language is required for question generation',
          fieldErrors: {'language': 'Please specify a language'},
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.generateQuestions(params.input);
  }
}
