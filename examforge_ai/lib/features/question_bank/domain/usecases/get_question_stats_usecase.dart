import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [GetQuestionStatsUseCase].
class GetQuestionStatsParams {
  const GetQuestionStatsParams({
    this.schoolId,
  });

  /// Optional school ID to scope the statistics.
  /// When `null`, stats are computed across all accessible data.
  final String? schoolId;
}

/// Use case that retrieves aggregated question bank statistics.
///
/// Delegates to [QuestionBankRepository.getStats] and returns a
/// [QuestionBankStatsEntity] containing counts, breakdowns by
/// subject/difficulty/type/exam, and top-used questions.
///
/// ```dart
/// final result = await getQuestionStatsUseCase(
///   GetQuestionStatsParams(schoolId: 'sch-001'),
/// );
/// result.fold(
///   onSuccess: (stats) => renderDashboard(stats),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GetQuestionStatsUseCase {
  GetQuestionStatsUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<QuestionBankStatsEntity>> call(
    GetQuestionStatsParams params,
  ) async {
    return _repository.getStats(schoolId: params.schoolId);
  }
}
