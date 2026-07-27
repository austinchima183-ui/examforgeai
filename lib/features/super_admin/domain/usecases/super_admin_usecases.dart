import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/super_admin_entities.dart';
import '../repositories/super_admin_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class GetDashboardMetricsParams {
  const GetDashboardMetricsParams({this.forceRefresh = false});
  final bool forceRefresh;
}

class GetDashboardMetricsUseCase {
  GetDashboardMetricsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<DashboardMetrics>> call(GetDashboardMetricsParams params) =>
      _repository.getDashboardMetrics(forceRefresh: params.forceRefresh);
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLATFORM SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class GetPlatformSettingsParams {
  const GetPlatformSettingsParams({this.scope});
  final SettingScope? scope;
}

class GetPlatformSettingsUseCase {
  GetPlatformSettingsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<PlatformSetting>>> call(GetPlatformSettingsParams params) =>
      _repository.getPlatformSettings(scope: params.scope);
}

class UpdatePlatformSettingParams {
  const UpdatePlatformSettingParams({required this.setting});
  final PlatformSetting setting;
}

class UpdatePlatformSettingUseCase {
  UpdatePlatformSettingUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<PlatformSetting>> call(UpdatePlatformSettingParams params) async {
    if (params.setting.key.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Setting key is required',
        fieldErrors: {'key': 'Key cannot be empty'},
      ),);
    }
    if (params.setting.isReadonly) {
      return const FailureResult(Failure.validation(
        message: 'Cannot modify a readonly setting',
        fieldErrors: {'readonly': 'This setting is read-only'},
      ),);
    }
    return _repository.updatePlatformSetting(params.setting);
  }
}

class BulkUpdateSettingsParams {
  const BulkUpdateSettingsParams({required this.settings});
  final List<PlatformSetting> settings;
}

class BulkUpdateSettingsUseCase {
  BulkUpdateSettingsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<PlatformSetting>>> call(BulkUpdateSettingsParams params) async {
    if (params.settings.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'No settings provided'));
    }
    final readonlySettings = params.settings.where((s) => s.isReadonly).toList();
    if (readonlySettings.isNotEmpty) {
      return FailureResult(Failure.validation(
        message: 'Cannot modify readonly settings: ${readonlySettings.map((s) => s.key).join(', ')}',
        fieldErrors: const {},
      ),);
    }
    return _repository.bulkUpdateSettings(params.settings);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEATURE FLAGS
// ═══════════════════════════════════════════════════════════════════════════════

class GetFeatureFlagsParams {
  const GetFeatureFlagsParams({this.isActive});
  final bool? isActive;
}

class GetFeatureFlagsUseCase {
  GetFeatureFlagsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<FeatureFlag>>> call(GetFeatureFlagsParams params) =>
      _repository.getFeatureFlags(isActive: params.isActive);
}

class CreateFeatureFlagParams {
  const CreateFeatureFlagParams({required this.flag});
  final FeatureFlag flag;
}

class CreateFeatureFlagUseCase {
  CreateFeatureFlagUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<FeatureFlag>> call(CreateFeatureFlagParams params) async {
    if (params.flag.key.isEmpty || params.flag.name.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Feature flag key and name are required',
        fieldErrors: {'key': 'Key is required', 'name': 'Name is required'},
      ),);
    }
    return _repository.createFeatureFlag(params.flag);
  }
}

class UpdateFeatureFlagParams {
  const UpdateFeatureFlagParams({required this.flag});
  final FeatureFlag flag;
}

class UpdateFeatureFlagUseCase {
  UpdateFeatureFlagUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<FeatureFlag>> call(UpdateFeatureFlagParams params) =>
      _repository.updateFeatureFlag(params.flag);
}

class ToggleFeatureFlagParams {
  const ToggleFeatureFlagParams({required this.flagId, required this.isActive});
  final String flagId;
  final bool isActive;
}

class ToggleFeatureFlagUseCase {
  ToggleFeatureFlagUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<FeatureFlag>> call(ToggleFeatureFlagParams params) async {
    if (params.flagId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Flag ID is required'));
    }
    return _repository.toggleFeatureFlag(params.flagId, params.isActive);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUDIT LOGS
// ═══════════════════════════════════════════════════════════════════════════════

class GetAuditLogsParams {
  const GetAuditLogsParams({
    this.category, this.severity, this.actorId, this.resourceType,
    this.resourceId, this.schoolId, this.startDate, this.endDate,
    this.limit = 50, this.offset = 0,
  });
  final AuditCategory? category;
  final AuditSeverity? severity;
  final String? actorId;
  final String? resourceType;
  final String? resourceId;
  final String? schoolId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
}

class GetAuditLogsUseCase {
  GetAuditLogsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<AuditLog>>> call(GetAuditLogsParams params) =>
      _repository.getAuditLogs(
        category: params.category, severity: params.severity, actorId: params.actorId,
        resourceType: params.resourceType, resourceId: params.resourceId,
        schoolId: params.schoolId, startDate: params.startDate, endDate: params.endDate,
        limit: params.limit, offset: params.offset,
      );
}

class CreateAuditLogParams {
  const CreateAuditLogParams({required this.log});
  final AuditLog log;
}

class CreateAuditLogUseCase {
  CreateAuditLogUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<AuditLog>> call(CreateAuditLogParams params) async {
    if (params.log.action.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Audit action is required'));
    }
    return _repository.createAuditLog(params.log);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class GetSchoolsParams {
  const GetSchoolsParams({
    this.isActive, this.isVerified, this.search, this.subscriptionStatus,
    this.limit = 50, this.offset = 0,
  });
  final bool? isActive;
  final bool? isVerified;
  final String? search;
  final String? subscriptionStatus;
  final int limit;
  final int offset;
}

class GetSchoolsUseCase {
  GetSchoolsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<SchoolManagementDetail>>> call(GetSchoolsParams params) =>
      _repository.getSchools(
        isActive: params.isActive, isVerified: params.isVerified, search: params.search,
        subscriptionStatus: params.subscriptionStatus, limit: params.limit, offset: params.offset,
      );
}

class ManageSchoolParams {
  const ManageSchoolParams({required this.schoolId, this.reason});
  final String schoolId;
  final String? reason;
}

class SuspendSchoolUseCase {
  SuspendSchoolUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageSchoolParams params) async {
    if (params.schoolId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'School ID is required'));
    }
    if (params.reason == null || params.reason!.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Suspension reason is required',
        fieldErrors: {'reason': 'Please provide a reason for suspension'},
      ),);
    }
    return _repository.suspendSchool(params.schoolId, params.reason!);
  }
}

class ReactivateSchoolUseCase {
  ReactivateSchoolUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageSchoolParams params) async {
    if (params.schoolId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'School ID is required'));
    }
    return _repository.reactivateSchool(params.schoolId);
  }
}

class VerifySchoolUseCase {
  VerifySchoolUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageSchoolParams params) async {
    if (params.schoolId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'School ID is required'));
    }
    return _repository.verifySchool(params.schoolId);
  }
}

class CreateSchoolParams {
  const CreateSchoolParams({required this.schoolData});
  final Map<String, dynamic> schoolData;
}

class CreateSchoolUseCase {
  CreateSchoolUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<SchoolManagementDetail>> call(CreateSchoolParams params) async {
    final name = params.schoolData['name'] as String? ?? '';
    if (name.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'School name is required',
        fieldErrors: {'name': 'Name cannot be empty'},
      ),);
    }
    return _repository.createSchool(params.schoolData);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class GetUsersParams {
  const GetUsersParams({
    this.role, this.schoolId, this.isActive, this.search,
    this.limit = 50, this.offset = 0,
  });
  final String? role;
  final String? schoolId;
  final bool? isActive;
  final String? search;
  final int limit;
  final int offset;
}

class GetUsersUseCase {
  GetUsersUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<UserManagementDetail>>> call(GetUsersParams params) =>
      _repository.getUsers(
        role: params.role, schoolId: params.schoolId, isActive: params.isActive,
        search: params.search, limit: params.limit, offset: params.offset,
      );
}

class ManageUserParams {
  const ManageUserParams({required this.userId, this.reason, this.newRole});
  final String userId;
  final String? reason;
  final String? newRole;
}

class SuspendUserUseCase {
  SuspendUserUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageUserParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    if (params.reason == null || params.reason!.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Suspension reason is required',
        fieldErrors: {'reason': 'Please provide a reason'},
      ),);
    }
    return _repository.suspendUser(params.userId, params.reason!);
  }
}

class ActivateUserUseCase {
  ActivateUserUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageUserParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    return _repository.activateUser(params.userId);
  }
}

class ResetUserPasswordUseCase {
  ResetUserPasswordUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageUserParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    return _repository.resetUserPassword(params.userId);
  }
}

class ChangeUserRoleUseCase {
  ChangeUserRoleUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(ManageUserParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    if (params.newRole == null || params.newRole!.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'New role is required'));
    }
    return _repository.changeUserRole(params.userId, params.newRole!);
  }
}

class StartImpersonationParams {
  const StartImpersonationParams({required this.targetUserId, required this.reason});
  final String targetUserId;
  final String reason;
}

class StartImpersonationUseCase {
  StartImpersonationUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<ImpersonationSession>> call(StartImpersonationParams params) async {
    if (params.targetUserId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Target user ID is required'));
    }
    if (params.reason.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Impersonation reason is required for audit compliance',
        fieldErrors: {'reason': 'Please provide a justification'},
      ),);
    }
    return _repository.startImpersonation(params.targetUserId, params.reason);
  }
}

class EndImpersonationParams {
  const EndImpersonationParams({required this.sessionId});
  final String sessionId;
}

class EndImpersonationUseCase {
  EndImpersonationUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(EndImpersonationParams params) async {
    if (params.sessionId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Session ID is required'));
    return _repository.endImpersonation(params.sessionId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class GetAIProvidersUseCase {
  GetAIProvidersUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<AIProvider>>> call({bool? isActive}) =>
      _repository.getAIProviders(isActive: isActive);
}

class UpsertAIProviderParams {
  const UpsertAIProviderParams({required this.provider});
  final AIProvider provider;
}

class CreateAIProviderUseCase {
  CreateAIProviderUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<AIProvider>> call(UpsertAIProviderParams params) async {
    if (params.provider.name.isEmpty || params.provider.slug.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Provider name and slug are required',
        fieldErrors: {},
      ),);
    }
    return _repository.createAIProvider(params.provider);
  }
}

class UpdateAIProviderUseCase {
  UpdateAIProviderUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<AIProvider>> call(UpsertAIProviderParams params) =>
      _repository.updateAIProvider(params.provider);
}

class SetDefaultProviderParams {
  const SetDefaultProviderParams({required this.providerId});
  final String providerId;
}

class SetDefaultProviderUseCase {
  SetDefaultProviderUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<AIProvider>> call(SetDefaultProviderParams params) async {
    if (params.providerId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Provider ID is required'));
    return _repository.setDefaultProvider(params.providerId);
  }
}

class ToggleProviderParams {
  const ToggleProviderParams({required this.providerId, required this.isActive});
  final String providerId;
  final bool isActive;
}

class ToggleProviderUseCase {
  ToggleProviderUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<AIProvider>> call(ToggleProviderParams params) async {
    if (params.providerId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Provider ID is required'));
    return _repository.toggleProvider(params.providerId, params.isActive);
  }
}

class GetAIRequestLogsParams {
  const GetAIRequestLogsParams({
    this.providerId, this.userId, this.schoolId, this.isSuccess,
    this.startDate, this.endDate, this.limit = 50, this.offset = 0,
  });
  final String? providerId;
  final String? userId;
  final String? schoolId;
  final bool? isSuccess;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
}

class GetAIRequestLogsUseCase {
  GetAIRequestLogsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<AIRequestLog>>> call(GetAIRequestLogsParams params) =>
      _repository.getAIRequestLogs(
        providerId: params.providerId, userId: params.userId, schoolId: params.schoolId,
        isSuccess: params.isSuccess, startDate: params.startDate, endDate: params.endDate,
        limit: params.limit, offset: params.offset,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORT TICKETS
// ═══════════════════════════════════════════════════════════════════════════════

class GetSupportTicketsParams {
  const GetSupportTicketsParams({
    this.status, this.priority, this.category, this.assignedTo,
    this.schoolId, this.search, this.limit = 50, this.offset = 0,
  });
  final TicketStatus? status;
  final TicketPriority? priority;
  final TicketCategory? category;
  final String? assignedTo;
  final String? schoolId;
  final String? search;
  final int limit;
  final int offset;
}

class GetSupportTicketsUseCase {
  GetSupportTicketsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<SupportTicket>>> call(GetSupportTicketsParams params) =>
      _repository.getSupportTickets(
        status: params.status, priority: params.priority, category: params.category,
        assignedTo: params.assignedTo, schoolId: params.schoolId, search: params.search,
        limit: params.limit, offset: params.offset,
      );
}

class AssignTicketParams {
  const AssignTicketParams({required this.ticketId, required this.assignToUserId});
  final String ticketId;
  final String assignToUserId;
}

class AssignTicketUseCase {
  AssignTicketUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<SupportTicket>> call(AssignTicketParams params) async {
    if (params.ticketId.isEmpty || params.assignToUserId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Ticket ID and assignee are required'));
    }
    return _repository.assignTicket(params.ticketId, params.assignToUserId);
  }
}

class ResolveTicketParams {
  const ResolveTicketParams({required this.ticketId, required this.resolutionNotes});
  final String ticketId;
  final String resolutionNotes;
}

class ResolveTicketUseCase {
  ResolveTicketUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<SupportTicket>> call(ResolveTicketParams params) async {
    if (params.ticketId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Ticket ID is required'));
    if (params.resolutionNotes.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resolution notes are required',
        fieldErrors: {'resolutionNotes': 'Please describe how the ticket was resolved'},
      ),);
    }
    return _repository.resolveTicket(params.ticketId, params.resolutionNotes);
  }
}

class EscalateTicketParams {
  const EscalateTicketParams({required this.ticketId, required this.escalateToUserId, required this.reason});
  final String ticketId;
  final String escalateToUserId;
  final String reason;
}

class EscalateTicketUseCase {
  EscalateTicketUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<SupportTicket>> call(EscalateTicketParams params) async {
    if (params.ticketId.isEmpty || params.escalateToUserId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Ticket ID and escalation target are required'));
    }
    return _repository.escalateTicket(params.ticketId, params.escalateToUserId, params.reason);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE
// ═══════════════════════════════════════════════════════════════════════════════

class GetMarketplaceContentParams {
  const GetMarketplaceContentParams({
    this.status, this.contentType, this.search, this.limit = 50, this.offset = 0,
  });
  final MarketplaceStatus? status;
  final MarketplaceContentType? contentType;
  final String? search;
  final int limit;
  final int offset;
}

class GetMarketplaceContentUseCase {
  GetMarketplaceContentUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<MarketplaceContent>>> call(GetMarketplaceContentParams params) =>
      _repository.getMarketplaceContent(
        status: params.status, contentType: params.contentType, search: params.search,
        limit: params.limit, offset: params.offset,
      );
}

class ModerateContentParams {
  const ModerateContentParams({required this.contentId, this.reason, this.notes, this.featuredUntil});
  final String contentId;
  final String? reason;
  final String? notes;
  final DateTime? featuredUntil;
}

class ApproveContentUseCase {
  ApproveContentUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<MarketplaceContent>> call(ModerateContentParams params) async {
    if (params.contentId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Content ID is required'));
    return _repository.approveMarketplaceContent(params.contentId, notes: params.notes);
  }
}

class RejectContentUseCase {
  RejectContentUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<MarketplaceContent>> call(ModerateContentParams params) async {
    if (params.contentId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Content ID is required'));
    if (params.reason == null || params.reason!.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Rejection reason is required',
        fieldErrors: {'reason': 'Please explain why this content is rejected'},
      ),);
    }
    return _repository.rejectMarketplaceContent(params.contentId, params.reason!);
  }
}

class FeatureContentUseCase {
  FeatureContentUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<MarketplaceContent>> call(ModerateContentParams params) async {
    if (params.contentId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Content ID is required'));
    return _repository.featureMarketplaceContent(params.contentId, params.featuredUntil);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OPERATIONS INTELLIGENCE
// ═══════════════════════════════════════════════════════════════════════════════

class GetIntelligenceAlertsParams {
  const GetIntelligenceAlertsParams({
    this.alertType, this.severity, this.unacknowledgedOnly,
    this.unresolvedOnly, this.schoolId, this.limit = 50, this.offset = 0,
  });
  final IntelligenceAlertType? alertType;
  final IntelligenceSeverity? severity;
  final bool? unacknowledgedOnly;
  final bool? unresolvedOnly;
  final String? schoolId;
  final int limit;
  final int offset;
}

class GetIntelligenceAlertsUseCase {
  GetIntelligenceAlertsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<IntelligenceAlert>>> call(GetIntelligenceAlertsParams params) =>
      _repository.getIntelligenceAlerts(
        alertType: params.alertType, severity: params.severity,
        unacknowledgedOnly: params.unacknowledgedOnly, unresolvedOnly: params.unresolvedOnly,
        schoolId: params.schoolId, limit: params.limit, offset: params.offset,
      );
}

class AcknowledgeAlertParams {
  const AcknowledgeAlertParams({required this.alertId});
  final String alertId;
}

class AcknowledgeAlertUseCase {
  AcknowledgeAlertUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<IntelligenceAlert>> call(AcknowledgeAlertParams params) async {
    if (params.alertId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Alert ID is required'));
    return _repository.acknowledgeAlert(params.alertId);
  }
}

class ResolveAlertParams {
  const ResolveAlertParams({required this.alertId, required this.resolutionNotes});
  final String alertId;
  final String resolutionNotes;
}

class ResolveAlertUseCase {
  ResolveAlertUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<IntelligenceAlert>> call(ResolveAlertParams params) async {
    if (params.alertId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Alert ID is required'));
    return _repository.resolveAlert(params.alertId, params.resolutionNotes);
  }
}

class GenerateIntelligenceInsightsUseCase {
  GenerateIntelligenceInsightsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<IntelligenceAlert>>> call() =>
      _repository.generateIntelligenceInsights();
}

class GetChurnPredictionsParams {
  const GetChurnPredictionsParams({this.limit = 20});
  final int limit;
}

class GetChurnPredictionsUseCase {
  GetChurnPredictionsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call(GetChurnPredictionsParams params) =>
      _repository.getChurnPredictions(limit: params.limit);
}

class GetRevenueForecastParams {
  const GetRevenueForecastParams({this.monthsAhead = 6});
  final int monthsAhead;
}

class GetRevenueForecastUseCase {
  GetRevenueForecastUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call(GetRevenueForecastParams params) =>
      _repository.getRevenueForecast(monthsAhead: params.monthsAhead);
}

class GetCostOptimizationsUseCase {
  GetCostOptimizationsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call() =>
      _repository.getCostOptimizationSuggestions();
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY
// ═══════════════════════════════════════════════════════════════════════════════

class GetLoginMonitoringParams {
  const GetLoginMonitoringParams({
    this.userId, this.failedOnly, this.ipAddress,
    this.startDate, this.endDate, this.limit = 50, this.offset = 0,
  });
  final String? userId;
  final bool? failedOnly;
  final String? ipAddress;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;
}

class GetLoginMonitoringUseCase {
  GetLoginMonitoringUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<LoginMonitoringEntry>>> call(GetLoginMonitoringParams params) =>
      _repository.getLoginMonitoring(
        userId: params.userId, failedOnly: params.failedOnly, ipAddress: params.ipAddress,
        startDate: params.startDate, endDate: params.endDate, limit: params.limit, offset: params.offset,
      );
}

class DetectSuspiciousActivityParams {
  const DetectSuspiciousActivityParams({this.lookbackHours = 24});
  final int lookbackHours;
}

class DetectSuspiciousActivityUseCase {
  DetectSuspiciousActivityUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call(DetectSuspiciousActivityParams params) =>
      _repository.detectSuspiciousActivity(lookbackHours: params.lookbackHours);
}

class LockUserAccountParams {
  const LockUserAccountParams({required this.userId, required this.reason});
  final String userId;
  final String reason;
}

class LockUserAccountUseCase {
  LockUserAccountUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(LockUserAccountParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    return _repository.lockUserAccount(params.userId, params.reason);
  }
}

class UnlockUserAccountParams {
  const UnlockUserAccountParams({required this.userId});
  final String userId;
}

class UnlockUserAccountUseCase {
  UnlockUserAccountUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(UnlockUserAccountParams params) async {
    if (params.userId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'User ID is required'));
    return _repository.unlockUserAccount(params.userId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════

class GetNotificationsParams {
  const GetNotificationsParams({
    this.recipientId, this.category, this.priority, this.unreadOnly,
    this.limit = 50, this.offset = 0,
  });
  final String? recipientId;
  final NotificationCategory? category;
  final NotificationPriority? priority;
  final bool? unreadOnly;
  final int limit;
  final int offset;
}

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<PlatformNotification>>> call(GetNotificationsParams params) =>
      _repository.getNotifications(
        recipientId: params.recipientId, category: params.category,
        priority: params.priority, unreadOnly: params.unreadOnly,
        limit: params.limit, offset: params.offset,
      );
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<PlatformNotification>> call(String notificationId) async {
    if (notificationId.isEmpty) return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Notification ID is required'));
    return _repository.markNotificationRead(notificationId);
  }
}

class GetUnreadNotificationCountUseCase {
  GetUnreadNotificationCountUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<int>> call({String? recipientId}) =>
      _repository.getUnreadNotificationCount(recipientId: recipientId);
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVENUE & ANALYTICS
// ═══════════════════════════════════════════════════════════════════════════════

class GetRevenueAnalyticsParams {
  const GetRevenueAnalyticsParams({this.startDate, this.endDate});
  final DateTime? startDate;
  final DateTime? endDate;
}

class GetRevenueAnalyticsUseCase {
  GetRevenueAnalyticsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<RevenueAnalytics>> call(GetRevenueAnalyticsParams params) =>
      _repository.getRevenueAnalytics(startDate: params.startDate, endDate: params.endDate);
}

class GetPlatformAnalyticsParams {
  const GetPlatformAnalyticsParams({this.startDate, this.endDate, this.months = 12});
  final DateTime? startDate;
  final DateTime? endDate;
  final int months;
}

class GetSchoolGrowthUseCase {
  GetSchoolGrowthUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call(GetPlatformAnalyticsParams params) =>
      _repository.getSchoolGrowthMetrics(startDate: params.startDate, endDate: params.endDate);
}

class GetUserGrowthUseCase {
  GetUserGrowthUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call(GetPlatformAnalyticsParams params) =>
      _repository.getUserGrowthMetrics(startDate: params.startDate, endDate: params.endDate);
}

class GetFeatureUsageUseCase {
  GetFeatureUsageUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call(GetPlatformAnalyticsParams params) =>
      _repository.getFeatureUsageMetrics(startDate: params.startDate, endDate: params.endDate);
}

class GetRetentionMetricsUseCase {
  GetRetentionMetricsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<Map<String, dynamic>>> call({int months = 12}) =>
      _repository.getRetentionMetrics(months: months);
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE
// ═══════════════════════════════════════════════════════════════════════════════

class GetInfrastructureServicesUseCase {
  GetInfrastructureServicesUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<InfrastructureService>>> call({HealthStatus? status}) =>
      _repository.getInfrastructureServices(status: status);
}

class RunHealthCheckParams {
  const RunHealthCheckParams({this.serviceId});
  final String? serviceId;
}

class RunHealthCheckUseCase {
  RunHealthCheckUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(RunHealthCheckParams params) {
    if (params.serviceId != null) {
      return _repository.runHealthCheck(params.serviceId!);
    }
    return _repository.runAllHealthChecks();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAINTENANCE WINDOWS
// ═══════════════════════════════════════════════════════════════════════════════

class CreateMaintenanceWindowParams {
  const CreateMaintenanceWindowParams({required this.window});
  final MaintenanceWindow window;
}

class CreateMaintenanceWindowUseCase {
  CreateMaintenanceWindowUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<MaintenanceWindow>> call(CreateMaintenanceWindowParams params) async {
    if (params.window.title.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Title is required'));
    }
    if (params.window.endAt.isBefore(params.window.startAt)) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'End time must be after start time'));
    }
    return _repository.createMaintenanceWindow(params.window);
  }
}

class GetMaintenanceWindowsParams {
  const GetMaintenanceWindowsParams({this.status});
  final MaintenanceStatus? status;
}

class GetMaintenanceWindowsUseCase {
  GetMaintenanceWindowsUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<List<MaintenanceWindow>>> call(GetMaintenanceWindowsParams params) =>
      _repository.getMaintenanceWindows(status: params.status);
}

class CancelMaintenanceWindowParams {
  const CancelMaintenanceWindowParams({required this.windowId});
  final String windowId;
}

class CancelMaintenanceWindowUseCase {
  CancelMaintenanceWindowUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<void>> call(CancelMaintenanceWindowParams params) =>
      _repository.cancelMaintenanceWindow(params.windowId);
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTS
// ═══════════════════════════════════════════════════════════════════════════════

class GenerateReportParams {
  const GenerateReportParams({required this.type, required this.parameters, this.format = 'pdf'});
  final ReportType type;
  final Map<String, dynamic> parameters;
  final String format;
}

class GenerateReportUseCase {
  GenerateReportUseCase(this._repository);
  final SuperAdminRepository _repository;

  Future<Result<SystemReport>> call(GenerateReportParams params) =>
      _repository.generateReport(params.type, params.parameters, format: params.format);
}
