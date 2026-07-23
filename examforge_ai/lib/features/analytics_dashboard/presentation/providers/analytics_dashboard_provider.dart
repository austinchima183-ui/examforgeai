import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/analytics_dashboard_remote_datasource.dart';
import '../../data/repositories/analytics_dashboard_repository_impl.dart';
import '../../domain/entities/analytics_dashboard_entities.dart';
import '../../domain/repositories/analytics_dashboard_repository.dart';
import '../../domain/usecases/analytics_dashboard_usecases.dart';

/// Provider that manages Analytics Dashboard feature state.
class AnalyticsDashboardProvider extends ChangeNotifier {
  AnalyticsDashboardProvider({
    required GetAnalyticsSummaryUseCase getAnalyticsSummary,
    required GetDailyMetricsUseCase getDailyMetrics,
    required GetEventCountsUseCase getEventCounts,
    required GetFeatureAdoptionUseCase getFeatureAdoption,
    required GetRetentionDataUseCase getRetentionData,
    required GetChurnDataUseCase getChurnData,
    required GetRevenueMetricsUseCase getRevenueMetrics,
    required GetReleaseNotesUseCase getReleaseNotes,
  })  : _getAnalyticsSummary = getAnalyticsSummary,
        _getDailyMetrics = getDailyMetrics,
        _getEventCounts = getEventCounts,
        _getFeatureAdoption = getFeatureAdoption,
        _getRetentionData = getRetentionData,
        _getChurnData = getChurnData,
        _getRevenueMetrics = getRevenueMetrics,
        _getReleaseNotes = getReleaseNotes;

  final GetAnalyticsSummaryUseCase _getAnalyticsSummary;
  final GetDailyMetricsUseCase _getDailyMetrics;
  final GetEventCountsUseCase _getEventCounts;
  final GetFeatureAdoptionUseCase _getFeatureAdoption;
  final GetRetentionDataUseCase _getRetentionData;
  final GetChurnDataUseCase _getChurnData;
  final GetRevenueMetricsUseCase _getRevenueMetrics;
  final GetReleaseNotesUseCase _getReleaseNotes;

  Map<String, dynamic>? _analyticsSummary;
  List<DailyAnalytic> _dailyMetrics = [];
  Map<String, dynamic>? _eventCounts;
  Map<String, dynamic>? _featureAdoption;
  Map<String, dynamic>? _retentionData;
  Map<String, dynamic>? _churnData;
  Map<String, dynamic>? _revenueMetrics;
  List<ReleaseNote> _releaseNotes = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get analyticsSummary => _analyticsSummary;
  List<DailyAnalytic> get dailyMetrics => _dailyMetrics;
  Map<String, dynamic>? get eventCounts => _eventCounts;
  Map<String, dynamic>? get featureAdoption => _featureAdoption;
  Map<String, dynamic>? get retentionData => _retentionData;
  Map<String, dynamic>? get churnData => _churnData;
  Map<String, dynamic>? get revenueMetrics => _revenueMetrics;
  List<ReleaseNote> get releaseNotes => _releaseNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _extractMessage(Failure failure) => failure.when(
    server: (msg, _, __) => msg, cache: (msg) => msg, auth: (msg, _) => msg,
    network: (msg) => msg, validation: (msg, _) => msg, notFound: (msg) => msg,
    unauthorized: (msg) => msg, forbidden: (msg) => msg,
  );

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> loadAnalyticsSummary({String? schoolId}) async {
    _setLoading(true); _setError(null);
    final result = await _getAnalyticsSummary(GetAnalyticsSummaryParams(schoolId: schoolId));
    result.fold(onSuccess: (summary) { _analyticsSummary = summary; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); },);
  }

  Future<void> loadDailyMetrics({required String schoolId, required String metricName, required DateTime startDate, required DateTime endDate}) async {
    final result = await _getDailyMetrics(GetDailyMetricsParams(schoolId: schoolId, metricName: metricName, startDate: startDate, endDate: endDate));
    result.fold(onSuccess: (metrics) { _dailyMetrics = metrics; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadEventCounts({String? schoolId}) async {
    final result = await _getEventCounts(GetEventCountsParams(schoolId: schoolId));
    result.fold(onSuccess: (counts) { _eventCounts = counts; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadFeatureAdoption({String? schoolId}) async {
    final result = await _getFeatureAdoption(GetFeatureAdoptionParams(schoolId: schoolId));
    result.fold(onSuccess: (adoption) { _featureAdoption = adoption; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadRetentionData({String? schoolId}) async {
    final result = await _getRetentionData(GetRetentionDataParams(schoolId: schoolId));
    result.fold(onSuccess: (data) { _retentionData = data; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadChurnData({String? schoolId}) async {
    final result = await _getChurnData(GetChurnDataParams(schoolId: schoolId));
    result.fold(onSuccess: (data) { _churnData = data; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadRevenueMetrics({DateTime? startDate, DateTime? endDate}) async {
    final result = await _getRevenueMetrics(GetRevenueMetricsParams(startDate: startDate, endDate: endDate));
    result.fold(onSuccess: (metrics) { _revenueMetrics = metrics; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadReleaseNotes({bool? isPublished}) async {
    final result = await _getReleaseNotes(GetReleaseNotesParams(isPublished: isPublished));
    result.fold(onSuccess: (notes) { _releaseNotes = notes; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); },);
  }

  Future<void> loadAll({String? schoolId}) async {
    _setLoading(true); _setError(null);
    await Future.wait([
      loadAnalyticsSummary(schoolId: schoolId),
      loadEventCounts(schoolId: schoolId),
      loadFeatureAdoption(schoolId: schoolId),
      loadRevenueMetrics(),
      loadReleaseNotes(isPublished: true),
    ]);
    _setLoading(false);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final analyticsDashboardRemoteDatasourceProvider = Provider<AnalyticsDashboardRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsDashboardRemoteDatasource(apiClient);
});

final analyticsDashboardRepositoryProvider = Provider<AnalyticsDashboardRepository>((ref) {
  final datasource = ref.watch(analyticsDashboardRemoteDatasourceProvider);
  return AnalyticsDashboardRepositoryImpl(datasource);
});

final getAnalyticsSummaryUseCaseProvider = Provider<GetAnalyticsSummaryUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetAnalyticsSummaryUseCase(repo);
});

final getDailyMetricsUseCaseProvider = Provider<GetDailyMetricsUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetDailyMetricsUseCase(repo);
});

final getEventCountsUseCaseProvider = Provider<GetEventCountsUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetEventCountsUseCase(repo);
});

final getFeatureAdoptionUseCaseProvider = Provider<GetFeatureAdoptionUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetFeatureAdoptionUseCase(repo);
});

final getRetentionDataUseCaseProvider = Provider<GetRetentionDataUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetRetentionDataUseCase(repo);
});

final getChurnDataUseCaseProvider = Provider<GetChurnDataUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetChurnDataUseCase(repo);
});

final getRevenueMetricsUseCaseProvider = Provider<GetRevenueMetricsUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetRevenueMetricsUseCase(repo);
});

final getReleaseNotesUseCaseProvider = Provider<GetReleaseNotesUseCase>((ref) {
  final repo = ref.watch(analyticsDashboardRepositoryProvider);
  return GetReleaseNotesUseCase(repo);
});

final analyticsDashboardProvider = ChangeNotifierProvider<AnalyticsDashboardProvider>((ref) {
  return AnalyticsDashboardProvider(
    getAnalyticsSummary: ref.watch(getAnalyticsSummaryUseCaseProvider),
    getDailyMetrics: ref.watch(getDailyMetricsUseCaseProvider),
    getEventCounts: ref.watch(getEventCountsUseCaseProvider),
    getFeatureAdoption: ref.watch(getFeatureAdoptionUseCaseProvider),
    getRetentionData: ref.watch(getRetentionDataUseCaseProvider),
    getChurnData: ref.watch(getChurnDataUseCaseProvider),
    getRevenueMetrics: ref.watch(getRevenueMetricsUseCaseProvider),
    getReleaseNotes: ref.watch(getReleaseNotesUseCaseProvider),
  );
});
