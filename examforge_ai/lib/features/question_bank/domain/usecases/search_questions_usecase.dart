import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [SearchQuestionsUseCase].
class SearchQuestionsParams {
  const SearchQuestionsParams({
    required this.query,
    this.filter = const QuestionFilterEntity(),
  });

  /// The search query string.
  final String query;

  /// Optional filter criteria to further refine results.
  final QuestionFilterEntity filter;
}

/// Use case that performs a full-text search across the question bank.
///
/// Validates that the search query is non-empty and meets a minimum
/// length requirement, then delegates to
/// [QuestionBankRepository.searchQuestions].
///
/// ```dart
/// final result = await searchQuestionsUseCase(
///   SearchQuestionsParams(
///     query: 'quadratic equation',
///     filter: QuestionFilterEntity(subjectId: 'math-101'),
///   ),
/// );
/// result.fold(
///   onSuccess: (questions) => displayResults(questions),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class SearchQuestionsUseCase {
  SearchQuestionsUseCase(this._repository);

  final QuestionBankRepository _repository;

  /// Minimum number of characters required for a search query.
  static const int minQueryLength = 2;

  Future<Result<List<QuestionEntity>>> call(
    SearchQuestionsParams params,
  ) async {
    final trimmedQuery = params.query.trim();

    if (trimmedQuery.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Search query cannot be empty',
          fieldErrors: {'query': 'Enter a search term'},
        ),
      );
    }

    if (trimmedQuery.length < minQueryLength) {
      return FailureResult(
        Failure.validation(
          message:
              'Search query must be at least $minQueryLength characters',
          fieldErrors: {
            'query': 'Type at least $minQueryLength characters to search',
          },
        ),
      );
    }

    // ── Validate pagination in filter ───────────────────────────────
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

    return _repository.searchQuestions(trimmedQuery, params.filter);
  }
}
