import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/enterprise_security_usecases.dart';
import '../../domain/usecases/monitoring_usecases.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class EnterpriseState extends Equatable {
  final List<AuditEntry> auditTrail;
  final MfaConfiguration? mfaConfig;
  final List<ApiKey> apiKeys;
  final List<SecurityEvent> securityEvents;
  final List<UserSession> userSessions;
  final CcmsStats? ccmsStats;
  final List<AlertRule> alertRules;
  final List<AlertIncident> alertIncidents;
  final List<SystemMetric> metrics;
  final List<PerformanceLog> performanceLogs;
  final List<ErrorReport> errorReports;
  final bool rateLimitResult;
  final bool isLoading;
  final String? error;

  const EnterpriseState({
    this.auditTrail = const [],
    this.mfaConfig,
    this.apiKeys = const [],
    this.securityEvents = const [],
    this.userSessions = const [],
    this.ccmsStats,
    this.alertRules = const [],
    this.alertIncidents = const [],
    this.metrics = const [],
    this.performanceLogs = const [],
    this.errorReports = const [],
    this.rateLimitResult = false,
    this.isLoading = false,
    this.error,
  });

  EnterpriseState copyWith({
    List<AuditEntry>? auditTrail,
    MfaConfiguration? mfaConfig,
    List<ApiKey>? apiKeys,
    List<SecurityEvent>? securityEvents,
    List<UserSession>? userSessions,
    CcmsStats? ccmsStats,
    List<AlertRule>? alertRules,
    List<AlertIncident>? alertIncidents,
    List<SystemMetric>? metrics,
    List<PerformanceLog>? performanceLogs,
    List<ErrorReport>? errorReports,
    bool? rateLimitResult,
    bool? isLoading,
    String? error,
  }) {
    return EnterpriseState(
      auditTrail: auditTrail ?? this.auditTrail,
      mfaConfig: mfaConfig ?? this.mfaConfig,
      apiKeys: apiKeys ?? this.apiKeys,
      securityEvents: securityEvents ?? this.securityEvents,
      userSessions: userSessions ?? this.userSessions,
      ccmsStats: ccmsStats ?? this.ccmsStats,
      alertRules: alertRules ?? this.alertRules,
      alertIncidents: alertIncidents ?? this.alertIncidents,
      metrics: metrics ?? this.metrics,
      performanceLogs: performanceLogs ?? this.performanceLogs,
      errorReports: errorReports ?? this.errorReports,
      rateLimitResult: rateLimitResult ?? this.rateLimitResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        auditTrail,
        mfaConfig,
        apiKeys,
        securityEvents,
        userSessions,
        ccmsStats,
        alertRules,
        alertIncidents,
        metrics,
        performanceLogs,
        errorReports,
        rateLimitResult,
        isLoading,
        error,
      ];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class EnterpriseNotifier extends StateNotifier<EnterpriseState> {
  // Audit use cases
  final RecordAuditEventUseCase _recordAuditEventUseCase;
  final GetAuditTrailUseCase _getAuditTrailUseCase;

  // MFA use cases
  final GetMfaConfigUseCase _getMfaConfigUseCase;
  final EnableMfaUseCase _enableMfaUseCase;
  final DisableMfaUseCase _disableMfaUseCase;
  final VerifyMfaUseCase _verifyMfaUseCase;

  // API key use cases
  final CreateApiKeyUseCase _createApiKeyUseCase;
  final RevokeApiKeyUseCase _revokeApiKeyUseCase;
  final GetApiKeysUseCase _getApiKeysUseCase;

  // Security use cases
  final RecordSecurityEventUseCase _recordSecurityEventUseCase;
  final GetSecurityEventsUseCase _getSecurityEventsUseCase;
  final CheckRateLimitUseCase _checkRateLimitUseCase;

  // Session use cases
  final GetUserSessionsUseCase _getUserSessionsUseCase;
  final InvalidateUserSessionsUseCase _invalidateUserSessionsUseCase;

  // Stats use case
  final GetCcmsStatsUseCase _getCcmsStatsUseCase;

  // Alert use cases
  final GetAlertRulesUseCase _getAlertRulesUseCase;
  final CreateAlertRuleUseCase _createAlertRuleUseCase;
  final GetAlertIncidentsUseCase _getAlertIncidentsUseCase;
  final AcknowledgeAlertUseCase _acknowledgeAlertUseCase;
  final ResolveAlertUseCase _resolveAlertUseCase;

  // Metrics use cases
  final RecordMetricUseCase _recordMetricUseCase;
  final GetSystemMetricsUseCase _getSystemMetricsUseCase;

  // Performance use cases
  final RecordPerformanceLogUseCase _recordPerformanceLogUseCase;
  final GetPerformanceLogsUseCase _getPerformanceLogsUseCase;

  // Error use cases
  final ReportErrorUseCase _reportErrorUseCase;
  final GetErrorReportsUseCase _getErrorReportsUseCase;
  final ResolveErrorUseCase _resolveErrorUseCase;

  EnterpriseNotifier({
    // Audit
    required RecordAuditEventUseCase recordAuditEventUseCase,
    required GetAuditTrailUseCase getAuditTrailUseCase,
    // MFA
    required GetMfaConfigUseCase getMfaConfigUseCase,
    required EnableMfaUseCase enableMfaUseCase,
    required DisableMfaUseCase disableMfaUseCase,
    required VerifyMfaUseCase verifyMfaUseCase,
    // API keys
    required CreateApiKeyUseCase createApiKeyUseCase,
    required RevokeApiKeyUseCase revokeApiKeyUseCase,
    required GetApiKeysUseCase getApiKeysUseCase,
    // Security
    required RecordSecurityEventUseCase recordSecurityEventUseCase,
    required GetSecurityEventsUseCase getSecurityEventsUseCase,
    required CheckRateLimitUseCase checkRateLimitUseCase,
    // Sessions
    required GetUserSessionsUseCase getUserSessionsUseCase,
    required InvalidateUserSessionsUseCase invalidateUserSessionsUseCase,
    // Stats
    required GetCcmsStatsUseCase getCcmsStatsUseCase,
    // Alerts
    required GetAlertRulesUseCase getAlertRulesUseCase,
    required CreateAlertRuleUseCase createAlertRuleUseCase,
    required GetAlertIncidentsUseCase getAlertIncidentsUseCase,
    required AcknowledgeAlertUseCase acknowledgeAlertUseCase,
    required ResolveAlertUseCase resolveAlertUseCase,
    // Metrics
    required RecordMetricUseCase recordMetricUseCase,
    required GetSystemMetricsUseCase getSystemMetricsUseCase,
    // Performance
    required RecordPerformanceLogUseCase recordPerformanceLogUseCase,
    required GetPerformanceLogsUseCase getPerformanceLogsUseCase,
    // Error
    required ReportErrorUseCase reportErrorUseCase,
    required GetErrorReportsUseCase getErrorReportsUseCase,
    required ResolveErrorUseCase resolveErrorUseCase,
  })  : _recordAuditEventUseCase = recordAuditEventUseCase,
        _getAuditTrailUseCase = getAuditTrailUseCase,
        _getMfaConfigUseCase = getMfaConfigUseCase,
        _enableMfaUseCase = enableMfaUseCase,
        _disableMfaUseCase = disableMfaUseCase,
        _verifyMfaUseCase = verifyMfaUseCase,
        _createApiKeyUseCase = createApiKeyUseCase,
        _revokeApiKeyUseCase = revokeApiKeyUseCase,
        _getApiKeysUseCase = getApiKeysUseCase,
        _recordSecurityEventUseCase = recordSecurityEventUseCase,
        _getSecurityEventsUseCase = getSecurityEventsUseCase,
        _checkRateLimitUseCase = checkRateLimitUseCase,
        _getUserSessionsUseCase = getUserSessionsUseCase,
        _invalidateUserSessionsUseCase = invalidateUserSessionsUseCase,
        _getCcmsStatsUseCase = getCcmsStatsUseCase,
        _getAlertRulesUseCase = getAlertRulesUseCase,
        _createAlertRuleUseCase = createAlertRuleUseCase,
        _getAlertIncidentsUseCase = getAlertIncidentsUseCase,
        _acknowledgeAlertUseCase = acknowledgeAlertUseCase,
        _resolveAlertUseCase = resolveAlertUseCase,
        _recordMetricUseCase = recordMetricUseCase,
        _getSystemMetricsUseCase = getSystemMetricsUseCase,
        _recordPerformanceLogUseCase = recordPerformanceLogUseCase,
        _getPerformanceLogsUseCase = getPerformanceLogsUseCase,
        _reportErrorUseCase = reportErrorUseCase,
        _getErrorReportsUseCase = getErrorReportsUseCase,
        _resolveErrorUseCase = resolveErrorUseCase,
        super(const EnterpriseState());

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

  // ─── Audit Methods ─────────────────────────────────────────────────────

  Future<void> recordAudit(AuditEntry data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _recordAuditEventUseCase(
      RecordAuditEventParams(entry: data),
    );
    result.fold(
      onSuccess: (recorded) => state = state.copyWith(
        auditTrail: [recorded, ...state.auditTrail],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadAuditTrail({
    String? userId,
    String? schoolId,
    AuditAction? action,
    String? resourceType,
    String? resourceId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAuditTrailUseCase(GetAuditTrailParams(
      userId: userId,
      schoolId: schoolId,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    ));
    result.fold(
      onSuccess: (trail) =>
          state = state.copyWith(auditTrail: trail, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── MFA Methods ───────────────────────────────────────────────────────

  Future<void> loadMfaConfig(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await _getMfaConfigUseCase(GetMfaConfigParams(userId: userId));
    result.fold(
      onSuccess: (config) =>
          state = state.copyWith(mfaConfig: config, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> enableMfa({
    required String userId,
    required MfaMethod method,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _enableMfaUseCase(EnableMfaParams(
      userId: userId,
      method: method,
      phoneNumber: phoneNumber,
    ));
    result.fold(
      onSuccess: (config) =>
          state = state.copyWith(mfaConfig: config, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> disableMfa({
    required String userId,
    required String verificationCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _disableMfaUseCase(DisableMfaParams(
      userId: userId,
      verificationCode: verificationCode,
    ));
    result.fold(
      onSuccess: (_) => state = state.copyWith(isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> verifyMfa({
    required String userId,
    required String verificationCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _verifyMfaUseCase(VerifyMfaParams(
      userId: userId,
      verificationCode: verificationCode,
    ));
    result.fold(
      onSuccess: (_) => state = state.copyWith(isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── API Key Methods ───────────────────────────────────────────────────

  Future<void> createApiKey({
    required String userId,
    required String name,
    String? schoolId,
    List<String>? scopes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createApiKeyUseCase(CreateApiKeyParams(
      userId: userId,
      name: name,
      schoolId: schoolId,
      scopes: scopes,
    ));
    result.fold(
      onSuccess: (key) => state = state.copyWith(
        apiKeys: [...state.apiKeys, key],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> revokeApiKey(String apiKeyId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await _revokeApiKeyUseCase(RevokeApiKeyParams(apiKeyId: apiKeyId));
    result.fold(
      onSuccess: (_) => state = state.copyWith(
        apiKeys: state.apiKeys.where((k) => k.id != apiKeyId).toList(),
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadApiKeys(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await _getApiKeysUseCase(GetApiKeysParams(userId: userId));
    result.fold(
      onSuccess: (keys) =>
          state = state.copyWith(apiKeys: keys, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Security Event Methods ────────────────────────────────────────────

  Future<void> recordSecurityEvent(SecurityEvent data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _recordSecurityEventUseCase(
      RecordSecurityEventParams(event: data),
    );
    result.fold(
      onSuccess: (recorded) => state = state.copyWith(
        securityEvents: [recorded, ...state.securityEvents],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadSecurityEvents({
    String? userId,
    String? schoolId,
    AlertSeverity? severity,
    bool? isResolved,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSecurityEventsUseCase(GetSecurityEventsParams(
      userId: userId,
      schoolId: schoolId,
      severity: severity,
      isResolved: isResolved,
      limit: limit,
      offset: offset,
    ));
    result.fold(
      onSuccess: (events) =>
          state = state.copyWith(securityEvents: events, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Rate Limit Methods ────────────────────────────────────────────────

  Future<void> checkRateLimit({
    required RateLimitScope scope,
    required String identifier,
    String? endpoint,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _checkRateLimitUseCase(CheckRateLimitParams(
      scope: scope,
      identifier: identifier,
      endpointPattern: endpoint,
    ));
    result.fold(
      onSuccess: (isWithinLimit) => state = state.copyWith(
        rateLimitResult: isWithinLimit,
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Session Methods ───────────────────────────────────────────────────

  Future<void> loadUserSessions(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await _getUserSessionsUseCase(GetUserSessionsParams(userId: userId));
    result.fold(
      onSuccess: (sessions) =>
          state = state.copyWith(userSessions: sessions, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> invalidateSessions({
    required String userId,
    required String sessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _invalidateUserSessionsUseCase(
      InvalidateUserSessionsParams(userId: userId, sessionId: sessionId),
    );
    result.fold(
      onSuccess: (_) => state = state.copyWith(
        userSessions:
            state.userSessions.where((s) => s.id != sessionId).toList(),
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── CCMS Stats Methods ────────────────────────────────────────────────

  Future<void> loadCcmsStats(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCcmsStatsUseCase(
      GetCcmsStatsParams(schoolId: schoolId),
    );
    result.fold(
      onSuccess: (stats) =>
          state = state.copyWith(ccmsStats: stats, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Alert Rule Methods ────────────────────────────────────────────────

  Future<void> loadAlertRules({
    bool? isActive,
    AlertSeverity? severity,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAlertRulesUseCase(GetAlertRulesParams(
      isActive: isActive,
      severity: severity,
    ));
    result.fold(
      onSuccess: (rules) =>
          state = state.copyWith(alertRules: rules, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> createAlertRule(AlertRule data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createAlertRuleUseCase(
      CreateAlertRuleParams(rule: data),
    );
    result.fold(
      onSuccess: (created) => state = state.copyWith(
        alertRules: [...state.alertRules, created],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Alert Incident Methods ────────────────────────────────────────────

  Future<void> loadAlertIncidents({
    String? alertRuleId,
    String? status,
    AlertSeverity? severity,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAlertIncidentsUseCase(GetAlertIncidentsParams(
      alertRuleId: alertRuleId,
      status: status,
      severity: severity,
      limit: limit,
      offset: offset,
    ));
    result.fold(
      onSuccess: (incidents) =>
          state = state.copyWith(alertIncidents: incidents, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> acknowledgeAlert({
    required String incidentId,
    required String acknowledgedBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _acknowledgeAlertUseCase(AcknowledgeAlertParams(
      incidentId: incidentId,
      acknowledgedBy: acknowledgedBy,
    ));
    result.fold(
      onSuccess: (updated) {
        final list = state.alertIncidents
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        state = state.copyWith(alertIncidents: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> resolveAlert({
    required String incidentId,
    required String notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _resolveAlertUseCase(ResolveAlertParams(
      incidentId: incidentId,
      resolutionNotes: notes,
    ));
    result.fold(
      onSuccess: (updated) {
        final list = state.alertIncidents
            .map((i) => i.id == updated.id ? updated : i)
            .toList();
        state = state.copyWith(alertIncidents: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Metrics Methods ───────────────────────────────────────────────────

  Future<void> recordMetric(SystemMetric data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _recordMetricUseCase(
      RecordMetricParams(metric: data),
    );
    result.fold(
      onSuccess: (recorded) => state = state.copyWith(
        metrics: [recorded, ...state.metrics],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadMetrics({
    String? metricName,
    MetricType? metricType,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSystemMetricsUseCase(GetSystemMetricsParams(
      metricName: metricName,
      metricType: metricType,
      schoolId: schoolId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    ));
    result.fold(
      onSuccess: (metrics) =>
          state = state.copyWith(metrics: metrics, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Performance Log Methods ───────────────────────────────────────────

  Future<void> recordPerformanceLog(PerformanceLog data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _recordPerformanceLogUseCase(
      RecordPerformanceLogParams(log: data),
    );
    result.fold(
      onSuccess: (recorded) => state = state.copyWith(
        performanceLogs: [recorded, ...state.performanceLogs],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadPerformanceLogs({
    String? operationType,
    String? operationName,
    bool? isSlow,
    String? userId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getPerformanceLogsUseCase(GetPerformanceLogsParams(
      operationType: operationType,
      operationName: operationName,
      isSlow: isSlow,
      userId: userId,
      schoolId: schoolId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    ));
    result.fold(
      onSuccess: (logs) =>
          state = state.copyWith(performanceLogs: logs, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  // ─── Error Report Methods ──────────────────────────────────────────────

  Future<void> reportError(ErrorReport data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _reportErrorUseCase(
      ReportErrorParams(report: data),
    );
    result.fold(
      onSuccess: (recorded) => state = state.copyWith(
        errorReports: [recorded, ...state.errorReports],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadErrorReports({
    String? errorType,
    bool? isResolved,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getErrorReportsUseCase(GetErrorReportsParams(
      errorType: errorType,
      isResolved: isResolved,
      schoolId: schoolId,
      limit: limit,
      offset: offset,
    ));
    result.fold(
      onSuccess: (reports) =>
          state = state.copyWith(errorReports: reports, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> resolveError(String errorId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _resolveErrorUseCase(
      ResolveErrorParams(
        errorId: errorId,
        resolvedBy: 'current_user',
      ),
    );
    result.fold(
      onSuccess: (resolved) {
        final list = state.errorReports
            .map((e) => e.id == resolved.id ? resolved : e)
            .toList();
        state = state.copyWith(errorReports: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }
}
