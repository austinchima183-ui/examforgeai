import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── RecordMetricUseCase ────────────────────────────────────────────

class RecordMetricParams extends Equatable {
  final SystemMetric metric;

  const RecordMetricParams({required this.metric});

  @override
  List<Object?> get props => [metric];
}

class RecordMetricUseCase {
  final CcmsRepository _repository;
  RecordMetricUseCase(this._repository);

  Future<Result<SystemMetric>> call(RecordMetricParams params) async {
    return await _repository.recordMetric(params.metric);
  }
}

// ─── GetSystemMetricsUseCase ────────────────────────────────────────

class GetSystemMetricsParams extends Equatable {
  final String? metricName;
  final MetricType? metricType;
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const GetSystemMetricsParams({
    this.metricName,
    this.metricType,
    this.schoolId,
    this.startDate,
    this.endDate,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [metricName, metricType, schoolId, startDate, endDate, limit];
}

class GetSystemMetricsUseCase {
  final CcmsRepository _repository;
  GetSystemMetricsUseCase(this._repository);

  Future<Result<List<SystemMetric>>> call(GetSystemMetricsParams params) async {
    return await _repository.getSystemMetrics(
      metricName: params.metricName,
      metricType: params.metricType,
      schoolId: params.schoolId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
    );
  }
}

// ─── GetAlertRulesUseCase ───────────────────────────────────────────

class GetAlertRulesParams extends Equatable {
  final bool? isActive;
  final AlertSeverity? severity;

  const GetAlertRulesParams({this.isActive, this.severity});

  @override
  List<Object?> get props => [isActive, severity];
}

class GetAlertRulesUseCase {
  final CcmsRepository _repository;
  GetAlertRulesUseCase(this._repository);

  Future<Result<List<AlertRule>>> call(GetAlertRulesParams params) async {
    return await _repository.getAlertRules(
      isActive: params.isActive,
      severity: params.severity,
    );
  }
}

// ─── CreateAlertRuleUseCase ─────────────────────────────────────────

class CreateAlertRuleParams extends Equatable {
  final AlertRule rule;

  const CreateAlertRuleParams({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class CreateAlertRuleUseCase {
  final CcmsRepository _repository;
  CreateAlertRuleUseCase(this._repository);

  Future<Result<AlertRule>> call(CreateAlertRuleParams params) async {
    return await _repository.createAlertRule(params.rule);
  }
}

// ─── GetAlertIncidentsUseCase ───────────────────────────────────────

class GetAlertIncidentsParams extends Equatable {
  final String? alertRuleId;
  final String? status;
  final AlertSeverity? severity;
  final int limit;
  final int offset;

  const GetAlertIncidentsParams({
    this.alertRuleId,
    this.status,
    this.severity,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [alertRuleId, status, severity, limit, offset];
}

class GetAlertIncidentsUseCase {
  final CcmsRepository _repository;
  GetAlertIncidentsUseCase(this._repository);

  Future<Result<List<AlertIncident>>> call(
    GetAlertIncidentsParams params,
  ) async {
    return await _repository.getAlertIncidents(
      alertRuleId: params.alertRuleId,
      status: params.status,
      severity: params.severity,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── AcknowledgeAlertUseCase ────────────────────────────────────────

class AcknowledgeAlertParams extends Equatable {
  final String incidentId;
  final String acknowledgedBy;

  const AcknowledgeAlertParams({
    required this.incidentId,
    required this.acknowledgedBy,
  });

  @override
  List<Object?> get props => [incidentId, acknowledgedBy];
}

class AcknowledgeAlertUseCase {
  final CcmsRepository _repository;
  AcknowledgeAlertUseCase(this._repository);

  Future<Result<AlertIncident>> call(AcknowledgeAlertParams params) async {
    return await _repository.acknowledgeAlert(
      incidentId: params.incidentId,
      acknowledgedBy: params.acknowledgedBy,
    );
  }
}

// ─── ResolveAlertUseCase ────────────────────────────────────────────

class ResolveAlertParams extends Equatable {
  final String incidentId;
  final String resolutionNotes;

  const ResolveAlertParams({
    required this.incidentId,
    required this.resolutionNotes,
  });

  @override
  List<Object?> get props => [incidentId, resolutionNotes];
}

class ResolveAlertUseCase {
  final CcmsRepository _repository;
  ResolveAlertUseCase(this._repository);

  Future<Result<AlertIncident>> call(ResolveAlertParams params) async {
    return await _repository.resolveAlert(
      incidentId: params.incidentId,
      resolutionNotes: params.resolutionNotes,
    );
  }
}

// ─── RecordPerformanceLogUseCase ────────────────────────────────────

class RecordPerformanceLogParams extends Equatable {
  final PerformanceLog log;

  const RecordPerformanceLogParams({required this.log});

  @override
  List<Object?> get props => [log];
}

class RecordPerformanceLogUseCase {
  final CcmsRepository _repository;
  RecordPerformanceLogUseCase(this._repository);

  Future<Result<PerformanceLog>> call(
    RecordPerformanceLogParams params,
  ) async {
    return await _repository.recordPerformanceLog(params.log);
  }
}

// ─── GetPerformanceLogsUseCase ──────────────────────────────────────

class GetPerformanceLogsParams extends Equatable {
  final String? operationType;
  final String? operationName;
  final bool? isSlow;
  final String? userId;
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const GetPerformanceLogsParams({
    this.operationType,
    this.operationName,
    this.isSlow,
    this.userId,
    this.schoolId,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
        operationType,
        operationName,
        isSlow,
        userId,
        schoolId,
        startDate,
        endDate,
        limit,
        offset,
      ];
}

class GetPerformanceLogsUseCase {
  final CcmsRepository _repository;
  GetPerformanceLogsUseCase(this._repository);

  Future<Result<List<PerformanceLog>>> call(
    GetPerformanceLogsParams params,
  ) async {
    return await _repository.getPerformanceLogs(
      operationType: params.operationType,
      operationName: params.operationName,
      isSlow: params.isSlow,
      userId: params.userId,
      schoolId: params.schoolId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── ReportErrorUseCase ─────────────────────────────────────────────

class ReportErrorParams extends Equatable {
  final ErrorReport report;

  const ReportErrorParams({required this.report});

  @override
  List<Object?> get props => [report];
}

class ReportErrorUseCase {
  final CcmsRepository _repository;
  ReportErrorUseCase(this._repository);

  Future<Result<ErrorReport>> call(ReportErrorParams params) async {
    return await _repository.reportError(params.report);
  }
}

// ─── GetErrorReportsUseCase ─────────────────────────────────────────

class GetErrorReportsParams extends Equatable {
  final String? errorType;
  final bool? isResolved;
  final String? schoolId;
  final int limit;
  final int offset;

  const GetErrorReportsParams({
    this.errorType,
    this.isResolved,
    this.schoolId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [errorType, isResolved, schoolId, limit, offset];
}

class GetErrorReportsUseCase {
  final CcmsRepository _repository;
  GetErrorReportsUseCase(this._repository);

  Future<Result<List<ErrorReport>>> call(
    GetErrorReportsParams params,
  ) async {
    return await _repository.getErrorReports(
      errorType: params.errorType,
      isResolved: params.isResolved,
      schoolId: params.schoolId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── ResolveErrorUseCase ────────────────────────────────────────────

class ResolveErrorParams extends Equatable {
  final String errorId;
  final String resolvedBy;

  const ResolveErrorParams({
    required this.errorId,
    required this.resolvedBy,
  });

  @override
  List<Object?> get props => [errorId, resolvedBy];
}

class ResolveErrorUseCase {
  final CcmsRepository _repository;
  ResolveErrorUseCase(this._repository);

  Future<Result<ErrorReport>> call(ResolveErrorParams params) async {
    return await _repository.resolveError(
      errorId: params.errorId,
      resolvedBy: params.resolvedBy,
    );
  }
}

// ─── GetCcmsStatsUseCase ────────────────────────────────────────────

class GetCcmsStatsParams extends Equatable {
  final String? schoolId;
  final String? educationalLevelId;
  final String? subjectId;

  const GetCcmsStatsParams({
    this.schoolId,
    this.educationalLevelId,
    this.subjectId,
  });

  @override
  List<Object?> get props => [schoolId, educationalLevelId, subjectId];
}

class GetCcmsStatsUseCase {
  final CcmsRepository _repository;
  GetCcmsStatsUseCase(this._repository);

  Future<Result<CcmsStats>> call(GetCcmsStatsParams params) async {
    return await _repository.getCcmsStats(
      schoolId: params.schoolId,
      educationalLevelId: params.educationalLevelId,
      subjectId: params.subjectId,
    );
  }
}
