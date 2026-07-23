import '../../../../core/network/api_client.dart';
import '../models/analytics_dashboard_models.dart';

/// Remote data source for Analytics Dashboard feature.
class AnalyticsDashboardRemoteDatasource {
  AnalyticsDashboardRemoteDatasource(this._apiClient);
  final ApiClient _apiClient;
  static const String _basePath = '/analytics';

  Future<bool> trackEvent(Map<String, dynamic> payload) async {
    await _apiClient.post('$_basePath/events/track', data: payload);
    return true;
  }

  Future<Map<String, dynamic>> getAnalyticsSummary({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    final response = await _apiClient.get('$_basePath/summary', queryParameters: {
      if (schoolId != null) 'school_id': schoolId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    },);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<DailyAnalyticModel>> getDailyMetrics({required String schoolId, required String metricName, required DateTime startDate, required DateTime endDate}) async {
    final response = await _apiClient.get('$_basePath/daily-metrics', queryParameters: {
      'school_id': schoolId, 'metric_name': metricName,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
    },);
    final data = response.data as List?;
    return data?.map((e) => DailyAnalyticModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<Map<String, dynamic>> getEventCounts({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    final response = await _apiClient.get('$_basePath/events/counts', queryParameters: {
      if (schoolId != null) 'school_id': schoolId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    },);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getFeatureAdoption({String? schoolId}) async {
    final response = await _apiClient.get('$_basePath/feature-adoption', queryParameters: {if (schoolId != null) 'school_id': schoolId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getRetentionData({String? schoolId, int? cohortDays}) async {
    final response = await _apiClient.get('$_basePath/retention', queryParameters: {if (schoolId != null) 'school_id': schoolId, if (cohortDays != null) 'cohort_days': cohortDays});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getChurnData({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    final response = await _apiClient.get('$_basePath/churn', queryParameters: {if (schoolId != null) 'school_id': schoolId, if (startDate != null) 'start_date': startDate.toIso8601String(), if (endDate != null) 'end_date': endDate.toIso8601String()});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getRevenueMetrics({DateTime? startDate, DateTime? endDate}) async {
    final response = await _apiClient.get('$_basePath/revenue', queryParameters: {if (startDate != null) 'start_date': startDate.toIso8601String(), if (endDate != null) 'end_date': endDate.toIso8601String()});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<ReleaseNoteModel>> getReleaseNotes({bool? isPublished, int limit = 20}) async {
    final response = await _apiClient.get('$_basePath/release-notes', queryParameters: {if (isPublished != null) 'is_published': isPublished, 'limit': limit});
    final data = response.data as List?;
    return data?.map((e) => ReleaseNoteModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<ReleaseNoteModel> createReleaseNote(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/release-notes', data: payload);
    return ReleaseNoteModel.fromJson(response.data as Map<String, dynamic>);
  }
}
