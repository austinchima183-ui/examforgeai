import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [GetQuestionsUseCase].
class GetQuestionsParams {
  const GetQuestionsParams({
    this.filter = const QuestionFilterEntity(),
  });

  /// Filter criteria for the query.
  final QuestionFilterEntity filter;
}

/// Use case that retrieves a filtered, paginated list of questions.
///
/// Validates that pagination parameters are within acceptable bounds,
/// then delegates to [QuestionBankRepository.getQuestions].
///
/// ```dart
/// final result = await getQuestionsUseCase(
///   GetQuestionsParams(
///     filter: QuestionFilterEntity(
///       subjectId: 'math-101',
///       page: 2,
///       perPage: 10,
///     ),
///   ),
/// );
/// result.fold(
///   onSuccess: (questions) => updateList(questions),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GetQuestionsUseCase {
  GetQuestionsUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<List<QuestionEntity>>> call(
    GetQuestionsParams params,
  ) async {
    // ── Validate pagination ─────────────────────────────────────────
    if (params.filter.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page number must be at least 1',
          fieldErrors: {'page': 'Invalid page number'},
        ),
      );
    }

    if (params.filter.perPage < 1 || params.filter.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Per-page count must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid per-page count'},
        ),
      );
    }

    // ── Validate sort option ────────────────────────────────────────
    const validSortOptions = {
      'newest',
      'oldest',
      'most_used',
      'least_used',
      'highest_rated',
      'a_z',
      'z_a',
    };

    if (!validSortOptions.contains(params.filter.sortBy)) {
      return FailureResult(
        Failure.validation(
          message:
              'Invalid sort option: "${params.filter.sortBy}". '
              'Must be one of: ${validSortOptions.join(', ')}',
          fieldErrors: {'sortBy': 'Invalid sort option'},
        ),
      );
    }

    return _repository.getQuestions(params.filter);
  }
}
