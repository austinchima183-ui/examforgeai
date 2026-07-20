import '../../../../core/utils/result.dart';
import '../entities/analytics_dashboard_entities.dart';

/// Abstract contract for the Analytics Dashboard repository.
abstract class AnalyticsDashboardRepository {
  Future<Result<bool>> trackEvent({required String eventType, required String eventName, String? userId, String? schoolId, String? sessionId, Map<String, dynamic>? properties, Map<String, dynamic>? deviceInfo});
  Future<Result<Map<String, dynamic>>> getAnalyticsSummary({String? schoolId, DateTime? startDate, DateTime? endDate});
  Future<Result<List<DailyAnalytic>>> getDailyMetrics({required String schoolId, required String metricName, required DateTime startDate, required DateTime endDate});
  Future<Result<Map<String, dynamic>>> getEventCounts({String? schoolId, DateTime? startDate, DateTime? endDate});
  Future<Result<Map<String, dynamic>>> getFeatureAdoption({String? schoolId});
  Future<Result<Map<String, dynamic>>> getRetentionData({String? schoolId, int? cohortDays});
  Future<Result<Map<String, dynamic>>> getChurnData({String? schoolId, DateTime? startDate, DateTime? endDate});
  Future<Result<Map<String, dynamic>>> getRevenueMetrics({DateTime? startDate, DateTime? endDate});
  Future<Result<List<ReleaseNote>>> getReleaseNotes({bool? isPublished, int limit = 20});
  Future<Result<ReleaseNote>> createReleaseNote(ReleaseNote releaseNote);
}
