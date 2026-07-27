import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [GetGenerationHistoryUseCase].
class GetHistoryParams {
  const GetHistoryParams({
    this.schoolId,
    this.page = 1,
    this.perPage = 20,
  });

  /// Optional school ID to scope the history results.
  /// When `null`, results include all accessible data.
  final String? schoolId;

  /// Page number for pagination (defaults to 1).
  final int page;

  /// Number of items per page (defaults to 20).
  final int perPage;
}

/// Use case that retrieves the generation request history.
///
/// Validates that pagination parameters are within bounds, then
/// delegates to [AiGeneratorRepository.getGenerationHistory].
///
/// ```dart
/// final result = await getGenerationHistoryUseCase(
///   GetHistoryParams(schoolId: 'sch-001', page: 1, perPage: 10),
/// );
/// result.fold(
///   onSuccess: (requests) => renderHistoryList(requests),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GetGenerationHistoryUseCase {
  GetGenerationHistoryUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<List<GenerationRequestEntity>>> call(
    GetHistoryParams params,
  ) async {
    // ── Validate page number ────────────────────────────────────────
    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page number must be at least 1',
          fieldErrors: {'page': 'Invalid page number'},
        ),
      );
    }

    // ── Validate per-page count ─────────────────────────────────────
    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Per-page count must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid per-page count'},
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.getGenerationHistory(
      schoolId: params.schoolId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
