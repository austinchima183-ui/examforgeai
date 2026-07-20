import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/analytics_dashboard_entities.dart';
import '../../domain/repositories/analytics_dashboard_repository.dart';
import '../datasources/analytics_dashboard_remote_datasource.dart';

/// Concrete implementation of [AnalyticsDashboardRepository].
class AnalyticsDashboardRepositoryImpl implements AnalyticsDashboardRepository {
  AnalyticsDashboardRepositoryImpl(this._remoteDatasource);
  final AnalyticsDashboardRemoteDatasource _remoteDatasource;

  Result<T> _handleError<T>(Object e) {
    if (e is ServerException) return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    if (e is NetworkException) return FailureResult(Failure.network(message: e.message));
    if (e is AuthException) return FailureResult(Failure.auth(message: e.message, code: e.code));
    if (e is NotFoundException) return FailureResult(Failure.notFound(message: e.message));
    return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
  }

  @override
  Future<Result<bool>> trackEvent({required String eventType, required String eventName, String? userId, String? schoolId, String? sessionId, Map<String, dynamic>? properties, Map<String, dynamic>? deviceInfo}) async {
    try {
      final result = await _remoteDatasource.trackEvent({'event_type': eventType, 'event_name': eventName, if (userId != null) 'user_id': userId, if (schoolId != null) 'school_id': schoolId, if (sessionId != null) 'session_id': sessionId, 'properties': properties ?? {}, 'device_info': deviceInfo ?? {}});
      return Success(result);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAnalyticsSummary({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDatasource.getAnalyticsSummary(schoolId: schoolId, startDate: startDate, endDate: endDate);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<DailyAnalytic>>> getDailyMetrics({required String schoolId, required String metricName, required DateTime startDate, required DateTime endDate}) async {
    try {
      final models = await _remoteDatasource.getDailyMetrics(schoolId: schoolId, metricName: metricName, startDate: startDate, endDate: endDate);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getEventCounts({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDatasource.getEventCounts(schoolId: schoolId, startDate: startDate, endDate: endDate);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getFeatureAdoption({String? schoolId}) async {
    try {
      final data = await _remoteDatasource.getFeatureAdoption(schoolId: schoolId);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getRetentionData({String? schoolId, int? cohortDays}) async {
    try {
      final data = await _remoteDatasource.getRetentionData(schoolId: schoolId, cohortDays: cohortDays);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getChurnData({String? schoolId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDatasource.getChurnData(schoolId: schoolId, startDate: startDate, endDate: endDate);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getRevenueMetrics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDatasource.getRevenueMetrics(startDate: startDate, endDate: endDate);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<ReleaseNote>>> getReleaseNotes({bool? isPublished, int limit = 20}) async {
    try {
      final models = await _remoteDatasource.getReleaseNotes(isPublished: isPublished, limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<ReleaseNote>> createReleaseNote(ReleaseNote releaseNote) async {
    try {
      final model = await _remoteDatasource.createReleaseNote({
        'version': releaseNote.version, 'title': releaseNote.title,
        'content': releaseNote.content, 'content_rich': releaseNote.contentRich,
        'release_type': releaseNote.releaseType, 'is_published': releaseNote.isPublished,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }
}
