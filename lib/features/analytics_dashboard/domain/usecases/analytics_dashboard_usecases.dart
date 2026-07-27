import '../../../../core/utils/result.dart';
import '../entities/analytics_dashboard_entities.dart';
import '../repositories/analytics_dashboard_repository.dart';

// ============================================================================
// PARAMS
// ============================================================================

class TrackEventParams {
  final String eventType;
  final String eventName;
  final String? userId;
  final String? schoolId;
  final String? sessionId;
  final Map<String, dynamic>? properties;
  final Map<String, dynamic>? deviceInfo;
  const TrackEventParams({required this.eventType, required this.eventName, this.userId, this.schoolId, this.sessionId, this.properties, this.deviceInfo});
}

class GetAnalyticsSummaryParams {
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  const GetAnalyticsSummaryParams({this.schoolId, this.startDate, this.endDate});
}

class GetDailyMetricsParams {
  final String schoolId;
  final String metricName;
  final DateTime startDate;
  final DateTime endDate;
  const GetDailyMetricsParams({required this.schoolId, required this.metricName, required this.startDate, required this.endDate});
}

class GetEventCountsParams {
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  const GetEventCountsParams({this.schoolId, this.startDate, this.endDate});
}

class GetFeatureAdoptionParams {
  final String? schoolId;
  const GetFeatureAdoptionParams({this.schoolId});
}

class GetRetentionDataParams {
  final String? schoolId;
  final int? cohortDays;
  const GetRetentionDataParams({this.schoolId, this.cohortDays});
}

class GetChurnDataParams {
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  const GetChurnDataParams({this.schoolId, this.startDate, this.endDate});
}

class GetRevenueMetricsParams {
  final DateTime? startDate;
  final DateTime? endDate;
  const GetRevenueMetricsParams({this.startDate, this.endDate});
}

class GetReleaseNotesParams {
  final bool? isPublished;
  final int limit;
  const GetReleaseNotesParams({this.isPublished, this.limit = 20});
}

class CreateReleaseNoteParams {
  final ReleaseNote releaseNote;
  const CreateReleaseNoteParams({required this.releaseNote});
}

// ============================================================================
// USE CASES
// ============================================================================

class TrackEventUseCase {
  final AnalyticsDashboardRepository _repo;
  TrackEventUseCase(this._repo);
  Future<Result<bool>> call(TrackEventParams p) => _repo.trackEvent(eventType: p.eventType, eventName: p.eventName, userId: p.userId, schoolId: p.schoolId, sessionId: p.sessionId, properties: p.properties, deviceInfo: p.deviceInfo);
}

class GetAnalyticsSummaryUseCase {
  final AnalyticsDashboardRepository _repo;
  GetAnalyticsSummaryUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetAnalyticsSummaryParams p) => _repo.getAnalyticsSummary(schoolId: p.schoolId, startDate: p.startDate, endDate: p.endDate);
}

class GetDailyMetricsUseCase {
  final AnalyticsDashboardRepository _repo;
  GetDailyMetricsUseCase(this._repo);
  Future<Result<List<DailyAnalytic>>> call(GetDailyMetricsParams p) => _repo.getDailyMetrics(schoolId: p.schoolId, metricName: p.metricName, startDate: p.startDate, endDate: p.endDate);
}

class GetEventCountsUseCase {
  final AnalyticsDashboardRepository _repo;
  GetEventCountsUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetEventCountsParams p) => _repo.getEventCounts(schoolId: p.schoolId, startDate: p.startDate, endDate: p.endDate);
}

class GetFeatureAdoptionUseCase {
  final AnalyticsDashboardRepository _repo;
  GetFeatureAdoptionUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetFeatureAdoptionParams p) => _repo.getFeatureAdoption(schoolId: p.schoolId);
}

class GetRetentionDataUseCase {
  final AnalyticsDashboardRepository _repo;
  GetRetentionDataUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetRetentionDataParams p) => _repo.getRetentionData(schoolId: p.schoolId, cohortDays: p.cohortDays);
}

class GetChurnDataUseCase {
  final AnalyticsDashboardRepository _repo;
  GetChurnDataUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetChurnDataParams p) => _repo.getChurnData(schoolId: p.schoolId, startDate: p.startDate, endDate: p.endDate);
}

class GetRevenueMetricsUseCase {
  final AnalyticsDashboardRepository _repo;
  GetRevenueMetricsUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetRevenueMetricsParams p) => _repo.getRevenueMetrics(startDate: p.startDate, endDate: p.endDate);
}

class GetReleaseNotesUseCase {
  final AnalyticsDashboardRepository _repo;
  GetReleaseNotesUseCase(this._repo);
  Future<Result<List<ReleaseNote>>> call(GetReleaseNotesParams p) => _repo.getReleaseNotes(isPublished: p.isPublished, limit: p.limit);
}

class CreateReleaseNoteUseCase {
  final AnalyticsDashboardRepository _repo;
  CreateReleaseNoteUseCase(this._repo);
  Future<Result<ReleaseNote>> call(CreateReleaseNoteParams p) => _repo.createReleaseNote(p.releaseNote);
}
