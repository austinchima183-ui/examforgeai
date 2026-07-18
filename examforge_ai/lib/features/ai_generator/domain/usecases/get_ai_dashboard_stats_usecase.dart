import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [GetAiDashboardStatsUseCase].
class GetDashboardStatsParams {
  const GetDashboardStatsParams({
    this.schoolId,
  });

  /// Optional school ID to scope the dashboard statistics.
  /// When `null`, stats are computed across all accessible data.
  final String? schoolId;
}

/// Use case that retrieves aggregated AI dashboard statistics.
///
/// Delegates to [AiGeneratorRepository.getDashboardStats] and returns
/// an [AiDashboardStatsEntity] containing totals, breakdowns by
/// type/difficulty/Bloom level, cost analysis, and recent generation
/// activity.
///
/// ```dart
/// final result = await getAiDashboardStatsUseCase(
///   GetDashboardStatsParams(schoolId: 'sch-001'),
/// );
/// result.fold(
///   onSuccess: (stats) => renderDashboard(stats),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class GetAiDashboardStatsUseCase {
  GetAiDashboardStatsUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<AiDashboardStatsEntity>> call(
    GetDashboardStatsParams params,
  ) async {
    return _repository.getDashboardStats(schoolId: params.schoolId);
  }
}
