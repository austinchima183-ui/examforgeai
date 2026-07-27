import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/monitoring_usecases.dart';

class MonitoringState extends Equatable {
  final List<SystemMetric> metrics;
  final List<AlertRule> alertRules;
  final List<AlertIncident> alertIncidents;
  final List<PerformanceLog> performanceLogs;
  final List<ErrorReport> errorReports;
  final CcmsStats? ccmsStats;
  final bool isLoading;
  final String? error;

  const MonitoringState({
    this.metrics = const [],
    this.alertRules = const [],
    this.alertIncidents = const [],
    this.performanceLogs = const [],
    this.errorReports = const [],
    this.ccmsStats,
    this.isLoading = false,
    this.error,
  });

  MonitoringState copyWith({
    List<SystemMetric>? metrics,
    List<AlertRule>? alertRules,
    List<AlertIncident>? alertIncidents,
    List<PerformanceLog>? performanceLogs,
    List<ErrorReport>? errorReports,
    CcmsStats? ccmsStats,
    bool? isLoading,
    String? error,
  }) {
    return MonitoringState(
      metrics: metrics ?? this.metrics,
      alertRules: alertRules ?? this.alertRules,
      alertIncidents: alertIncidents ?? this.alertIncidents,
      performanceLogs: performanceLogs ?? this.performanceLogs,
      errorReports: errorReports ?? this.errorReports,
      ccmsStats: ccmsStats ?? this.ccmsStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [metrics, alertRules, alertIncidents, performanceLogs, errorReports, ccmsStats, isLoading, error];
}

class MonitoringNotifier extends StateNotifier<MonitoringState> {
  final RecordMetricUseCase _recordMetricUseCase;
  final GetSystemMetricsUseCase _getMetricsUseCase;
  final GetAlertRulesUseCase _getAlertRulesUseCase;
  final CreateAlertRuleUseCase _createAlertRuleUseCase;
  final GetAlertIncidentsUseCase _getAlertIncidentsUseCase;
  final AcknowledgeAlertUseCase _acknowledgeAlertUseCase;
  final ResolveAlertUseCase _resolveAlertUseCase;
  final RecordPerformanceLogUseCase _recordPerformanceLogUseCase;
  final GetPerformanceLogsUseCase _getPerformanceLogsUseCase;
  final ReportErrorUseCase _reportErrorUseCase;
  final GetErrorReportsUseCase _getErrorReportsUseCase;
  final ResolveErrorUseCase _resolveErrorUseCase;
  final GetCcmsStatsUseCase _getCcmsStatsUseCase;

  MonitoringNotifier({
    required RecordMetricUseCase recordMetricUseCase,
    required GetSystemMetricsUseCase getMetricsUseCase,
    required GetAlertRulesUseCase getAlertRulesUseCase,
    required CreateAlertRuleUseCase createAlertRuleUseCase,
    required GetAlertIncidentsUseCase getAlertIncidentsUseCase,
    required AcknowledgeAlertUseCase acknowledgeAlertUseCase,
    required ResolveAlertUseCase resolveAlertUseCase,
    required RecordPerformanceLogUseCase recordPerformanceLogUseCase,
    required GetPerformanceLogsUseCase getPerformanceLogsUseCase,
    required ReportErrorUseCase reportErrorUseCase,
    required GetErrorReportsUseCase getErrorReportsUseCase,
    required ResolveErrorUseCase resolveErrorUseCase,
    required GetCcmsStatsUseCase getCcmsStatsUseCase,
  })  : _recordMetricUseCase = recordMetricUseCase,
        _getMetricsUseCase = getMetricsUseCase,
        _getAlertRulesUseCase = getAlertRulesUseCase,
        _createAlertRuleUseCase = createAlertRuleUseCase,
        _getAlertIncidentsUseCase = getAlertIncidentsUseCase,
        _acknowledgeAlertUseCase = acknowledgeAlertUseCase,
        _resolveAlertUseCase = resolveAlertUseCase,
        _recordPerformanceLogUseCase = recordPerformanceLogUseCase,
        _getPerformanceLogsUseCase = getPerformanceLogsUseCase,
        _reportErrorUseCase = reportErrorUseCase,
        _getErrorReportsUseCase = getErrorReportsUseCase,
        _resolveErrorUseCase = resolveErrorUseCase,
        _getCcmsStatsUseCase = getCcmsStatsUseCase,
        super(const MonitoringState());

  Future<void> recordMetric(SystemMetric metric) async {
    await _recordMetricUseCase(RecordMetricParams(metric: metric));
  }

  Future<void> loadMetrics({String? metricName, MetricType? metricType, String? schoolId}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getMetricsUseCase(GetSystemMetricsParams(metricName: metricName, metricType: metricType, schoolId: schoolId));
    result.fold(
      onSuccess: (metrics) => state = state.copyWith(metrics: metrics, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadAlertRules({bool? isActive, AlertSeverity? severity}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAlertRulesUseCase(GetAlertRulesParams(isActive: isActive, severity: severity));
    result.fold(
      onSuccess: (rules) => state = state.copyWith(alertRules: rules, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createAlertRule(AlertRule rule) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createAlertRuleUseCase(CreateAlertRuleParams(rule: rule));
    result.fold(
      onSuccess: (created) => state = state.copyWith(alertRules: [...state.alertRules, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadAlertIncidents({AlertSeverity? severity}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAlertIncidentsUseCase(GetAlertIncidentsParams(severity: severity));
    result.fold(
      onSuccess: (incidents) => state = state.copyWith(alertIncidents: incidents, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> acknowledgeAlert({required String incidentId, required String acknowledgedBy}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _acknowledgeAlertUseCase(AcknowledgeAlertParams(incidentId: incidentId, acknowledgedBy: acknowledgedBy));
    result.fold(
      onSuccess: (updated) {
        final list = state.alertIncidents.map((i) => i.id == updated.id ? updated : i).toList();
        state = state.copyWith(alertIncidents: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> resolveAlert({required String incidentId, required String resolutionNotes}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _resolveAlertUseCase(ResolveAlertParams(incidentId: incidentId, resolutionNotes: resolutionNotes));
    result.fold(
      onSuccess: (updated) {
        final list = state.alertIncidents.map((i) => i.id == updated.id ? updated : i).toList();
        state = state.copyWith(alertIncidents: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> recordPerformanceLog(PerformanceLog log) async {
    await _recordPerformanceLogUseCase(RecordPerformanceLogParams(log: log));
  }

  Future<void> loadPerformanceLogs({String? operationType, bool? isSlow}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getPerformanceLogsUseCase(GetPerformanceLogsParams(operationType: operationType, isSlow: isSlow));
    result.fold(
      onSuccess: (logs) => state = state.copyWith(performanceLogs: logs, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> reportError(ErrorReport report) async {
    await _reportErrorUseCase(ReportErrorParams(report: report));
  }

  Future<void> loadErrorReports({String? errorType, bool? isResolved}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getErrorReportsUseCase(GetErrorReportsParams(errorType: errorType, isResolved: isResolved));
    result.fold(
      onSuccess: (reports) => state = state.copyWith(errorReports: reports, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> resolveError({required String errorId, required String resolvedBy}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _resolveErrorUseCase(ResolveErrorParams(errorId: errorId, resolvedBy: resolvedBy));
    result.fold(
      onSuccess: (updated) {
        final list = state.errorReports.map((e) => e.id == updated.id ? updated : e).toList();
        state = state.copyWith(errorReports: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadCcmsStats({String? schoolId, String? educationalLevelId, String? subjectId}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCcmsStatsUseCase(GetCcmsStatsParams(schoolId: schoolId, educationalLevelId: educationalLevelId, subjectId: subjectId));
    result.fold(
      onSuccess: (stats) => state = state.copyWith(ccmsStats: stats, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }
}

String _mapFailureToMessage(Failure failure) {
  return failure.when(
    server: (message, statusCode, data) => 'Server error: $message',
    cache: (message) => 'Cache error: $message',
    auth: (message, code) => 'Auth error: $message',
    network: (message) => 'Network error: $message',
    validation: (message, fieldErrors) => 'Validation error: $message',
    notFound: (message) => 'Not found: $message',
    unauthorized: (message) => 'Unauthorized: $message',
    forbidden: (message) => 'Forbidden: $message',
  );
}
