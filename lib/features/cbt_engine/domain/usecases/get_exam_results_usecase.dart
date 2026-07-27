import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';

/// Parameters for the [GetExamResultsUseCase].
class GetResultsParams {
  const GetResultsParams({
    required this.examId,
    this.isReleased,
  });

  /// The ID of the exam to retrieve results for.
  final String examId;

  /// Optional filter for release status.
  /// - `true`: Only released results (visible to students).
  /// - `false`: Only unreleased results (teacher-only).
  /// - `null`: All results regardless of release status.
  final bool? isReleased;
}

/// Use case that retrieves exam results.
///
/// Validates that the exam exists before delegating to the repository.
/// Supports filtering by release status so that:
/// - Teachers can see all results (released and unreleased)
/// - Students can only see released results
class GetExamResultsUseCase {
  GetExamResultsUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<List<ExamResultEntity>>> call(GetResultsParams params) async {
    // ── Validate exam exists ──────────────────────────────────────────
    final examResult = await _repository.getExam(params.examId);
    if (examResult.isFailure) {
      return FailureResult(examResult.fold(
        onSuccess: (_) =>
            const Failure.server(message: 'Unknown error', statusCode: 500),
        onFailure: (failure) => failure,
      ),);
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getExamResults(
      params.examId,
      isReleased: params.isReleased,
    );
  }
}
