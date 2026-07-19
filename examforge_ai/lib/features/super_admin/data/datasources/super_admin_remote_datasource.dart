import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/utils/logger.dart';
import '../models/super_admin_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote super-admin data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class SuperAdminRemoteDataSource {
  // ─── Dashboard ─────────────────────────────────────────────────────

  Future<DashboardMetricsModel> getDashboardMetrics({bool forceRefresh = false});

  // ─── Platform Settings ─────────────────────────────────────────────

  Future<List<PlatformSettingModel>> getPlatformSettings({String? scope});
  Future<PlatformSettingModel> getPlatformSetting(String key, {String? scope});
  Future<PlatformSettingModel> updatePlatformSetting(Map<String, dynamic> settingData);
  Future<List<PlatformSettingModel>> bulkUpdateSettings(List<Map<String, dynamic>> settingsData);

  // ─── Feature Flags ─────────────────────────────────────────────────

  Future<List<FeatureFlagModel>> getFeatureFlags({bool? isActive});
  Future<FeatureFlagModel> getFeatureFlag(String key);
  Future<FeatureFlagModel> createFeatureFlag(Map<String, dynamic> flagData);
  Future<FeatureFlagModel> updateFeatureFlag(String flagId, Map<String, dynamic> data);
  Future<void> deleteFeatureFlag(String flagId);
  Future<FeatureFlagModel> toggleFeatureFlag(String flagId, bool isActive);

  // ─── Audit Logs ────────────────────────────────────────────────────

  Future<List<AuditLogModel>> getAuditLogs({
    String? category,
    String? severity,
    String? actorId,
    String? resourceType,
    String? resourceId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<AuditLogModel> createAuditLog(Map<String, dynamic> logData);
  Future<int> getAuditLogCount({String? category, DateTime? startDate, DateTime? endDate});

  // ─── School Management ─────────────────────────────────────────────

  Future<List<SchoolManagementDetailModel>> getSchools({
    bool? isActive,
    bool? isVerified,
    String? search,
    String? subscriptionStatus,
    int limit = 50,
    int offset = 0,
  });
  Future<SchoolManagementDetailModel> getSchool(String schoolId);
  Future<SchoolManagementDetailModel> createSchool(Map<String, dynamic> schoolData);
  Future<SchoolManagementDetailModel> updateSchool(String schoolId, Map<String, dynamic> data);
  Future<void> suspendSchool(String schoolId, String reason);
  Future<void> reactivateSchool(String schoolId);
  Future<void> deleteSchool(String schoolId);
  Future<void> verifySchool(String schoolId);
  Future<int> getSchoolCount({bool? isActive});

  // ─── User Management ───────────────────────────────────────────────

  Future<List<UserManagementDetailModel>> getUsers({
    String? role,
    String? schoolId,
    bool? isActive,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<UserManagementDetailModel> getUser(String userId);
  Future<void> suspendUser(String userId, String reason);
  Future<void> activateUser(String userId);
  Future<void> resetUserPassword(String userId);
  Future<void> changeUserRole(String userId, String newRole);
  Future<ImpersonationSessionModel> startImpersonation(Map<String, dynamic> data);
  Future<void> endImpersonation(String sessionId);
  Future<List<ImpersonationSessionModel>> getImpersonationSessions({String? status, int limit = 20});
  Future<int> getUserCount({String? role, bool? isActive});

  // ─── AI Management ─────────────────────────────────────────────────

  Future<List<AIProviderModel>> getAIProviders({bool? isActive});
  Future<AIProviderModel> getAIProvider(String providerId);
  Future<AIProviderModel> createAIProvider(Map<String, dynamic> providerData);
  Future<AIProviderModel> updateAIProvider(String providerId, Map<String, dynamic> data);
  Future<void> deleteAIProvider(String providerId);
  Future<AIProviderModel> setDefaultProvider(String providerId);
  Future<AIProviderModel> toggleProvider(String providerId, bool isActive);
  Future<List<AIRequestLogModel>> getAIRequestLogs({
    String? providerId,
    String? userId,
    String? schoolId,
    bool? isSuccess,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getAIUsageAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  });

  // ─── Infrastructure ────────────────────────────────────────────────

  Future<List<InfrastructureServiceModel>> getInfrastructureServices({String? status});
  Future<InfrastructureServiceModel> getInfrastructureService(String serviceId);
  Future<InfrastructureServiceModel> updateInfrastructureService(String serviceId, Map<String, dynamic> data);
  Future<void> runHealthCheck(String serviceId);
  Future<void> runAllHealthChecks();

  // ─── Support Tickets ───────────────────────────────────────────────

  Future<List<SupportTicketModel>> getSupportTickets({
    String? status,
    String? priority,
    String? category,
    String? assignedTo,
    String? schoolId,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<SupportTicketModel> getSupportTicket(String ticketId);
  Future<SupportTicketModel> updateSupportTicket(String ticketId, Map<String, dynamic> data);
  Future<SupportTicketModel> assignTicket(String ticketId, String assignToUserId);
  Future<SupportTicketModel> escalateTicket(String ticketId, String escalateToUserId, String reason);
  Future<SupportTicketModel> resolveTicket(String ticketId, String resolutionNotes);
  Future<TicketCommentModel> addTicketComment(Map<String, dynamic> commentData);
  Future<List<TicketCommentModel>> getTicketComments(String ticketId);
  Future<int> getTicketCount({String? status});

  // ─── Marketplace ───────────────────────────────────────────────────

  Future<List<MarketplaceContentModel>> getMarketplaceContent({
    String? status,
    String? contentType,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<MarketplaceContentModel> getMarketplaceItem(String contentId);
  Future<MarketplaceContentModel> approveMarketplaceContent(String contentId, {String? notes});
  Future<MarketplaceContentModel> rejectMarketplaceContent(String contentId, String reason);
  Future<MarketplaceContentModel> featureMarketplaceContent(String contentId, DateTime? until);
  Future<MarketplaceContentModel> removeMarketplaceContent(String contentId, String reason);
  Future<MarketplaceContentModel> flagMarketplaceContent(String contentId, String reason);
  Future<int> getMarketplaceContentCount({String? status});

  // ─── Platform Notifications ────────────────────────────────────────

  Future<List<PlatformNotificationModel>> getNotifications({
    String? recipientId,
    String? category,
    String? priority,
    bool? unreadOnly,
    int limit = 50,
    int offset = 0,
  });
  Future<PlatformNotificationModel> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead({String? recipientId});
  Future<void> dismissNotification(String notificationId);
  Future<PlatformNotificationModel> createNotification(Map<String, dynamic> notificationData);
  Future<int> getUnreadNotificationCount({String? recipientId});

  // ─── Operations Intelligence ───────────────────────────────────────

  Future<List<IntelligenceAlertModel>> getIntelligenceAlerts({
    String? alertType,
    String? severity,
    bool? unacknowledgedOnly,
    bool? unresolvedOnly,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  });
  Future<IntelligenceAlertModel> getIntelligenceAlert(String alertId);
  Future<IntelligenceAlertModel> acknowledgeAlert(String alertId);
  Future<IntelligenceAlertModel> resolveAlert(String alertId, String resolutionNotes);
  Future<List<IntelligenceAlertModel>> generateIntelligenceInsights();
  Future<Map<String, dynamic>> getChurnPredictions({int limit = 20});
  Future<Map<String, dynamic>> getRevenueForecast({int monthsAhead = 6});
  Future<Map<String, dynamic>> getEngagementInsights();
  Future<Map<String, dynamic>> getCostOptimizationSuggestions();

  // ─── Revenue Analytics ─────────────────────────────────────────────

  Future<RevenueAnalyticsModel> getRevenueAnalytics({DateTime? startDate, DateTime? endDate});

  // ─── Security ──────────────────────────────────────────────────────

  Future<List<LoginMonitoringEntryModel>> getLoginMonitoring({
    String? userId,
    bool? failedOnly,
    String? ipAddress,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<List<ActiveSessionModel>> getActiveSessions({String? userId});
  Future<void> terminateSession(String sessionId);
  Future<List<Map<String, dynamic>>> detectSuspiciousActivity({int lookbackHours = 24});
  Future<void> lockUserAccount(String userId, String reason);
  Future<void> unlockUserAccount(String userId);

  // ─── System Reports ────────────────────────────────────────────────

  Future<List<SystemReportModel>> getSystemReports({String? type, String? status});
  Future<SystemReportModel> generateReport(Map<String, dynamic> params);
  Future<SystemReportModel> getSystemReport(String reportId);

  // ─── Maintenance Windows ───────────────────────────────────────────

  Future<List<MaintenanceWindowModel>> getMaintenanceWindows({String? status});
  Future<MaintenanceWindowModel> createMaintenanceWindow(Map<String, dynamic> windowData);
  Future<MaintenanceWindowModel> updateMaintenanceWindow(String windowId, Map<String, dynamic> data);
  Future<void> cancelMaintenanceWindow(String windowId);

  // ─── Platform Policies ─────────────────────────────────────────────

  Future<List<PlatformPolicyModel>> getPlatformPolicies({bool? isActive});
  Future<PlatformPolicyModel> getPlatformPolicy(String policyKey);
  Future<PlatformPolicyModel> upsertPlatformPolicy(Map<String, dynamic> policyData);

  // ─── Email Templates ───────────────────────────────────────────────

  Future<List<EmailTemplateModel>> getEmailTemplates({String? category});
  Future<EmailTemplateModel> getEmailTemplate(String templateKey);
  Future<EmailTemplateModel> upsertEmailTemplate(Map<String, dynamic> templateData);

  // ─── Platform Analytics ────────────────────────────────────────────

  Future<Map<String, dynamic>> getSchoolGrowthMetrics({DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getUserGrowthMetrics({DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getFeatureUsageMetrics({DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getStorageUsageMetrics();
  Future<Map<String, dynamic>> getGeographicDistribution();
  Future<Map<String, dynamic>> getRetentionMetrics({int months = 12});
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Supabase-backed implementation of [SuperAdminRemoteDataSource].
///
/// Every method maps Supabase-specific responses and errors into the
/// domain-agnostic types defined in the data layer. Supabase
/// [sb.PostgrestException] instances are converted to our custom
/// exceptions with user-friendly messages.
class SuperAdminRemoteDataSourceImpl implements SuperAdminRemoteDataSource {
  SuperAdminRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ───────────────────────────────────────────────────
  static const _platformSettingsTable = 'platform_settings';
  static const _featureFlagsTable = 'feature_flags';
  static const _auditLogsTable = 'audit_logs';
  static const _schoolsTable = 'schools';
  static const _userProfilesTable = 'user_profiles';
  static const _impersonationSessionsTable = 'impersonation_sessions';
  static const _aiProvidersTable = 'ai_providers';
  static const _aiRequestLogsTable = 'ai_request_logs';
  static const _infrastructureServicesTable = 'infrastructure_services';
  static const _supportTicketsTable = 'support_tickets';
  static const _ticketCommentsTable = 'ticket_comments';
  static const _marketplaceContentTable = 'marketplace_content';
  static const _platformNotificationsTable = 'platform_notifications';
  static const _intelligenceAlertsTable = 'intelligence_alerts';
  static const _loginMonitoringTable = 'login_monitoring';
  static const _activeSessionsTable = 'active_sessions';
  static const _systemReportsTable = 'system_reports';
  static const _maintenanceWindowsTable = 'maintenance_windows';
  static const _platformPoliciesTable = 'platform_policies';
  static const _emailTemplatesTable = 'email_templates';

  // ═══════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DashboardMetricsModel> getDashboardMetrics({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_platform_dashboard_metrics',
      );

      AppLogger.info('Fetched platform dashboard metrics');
      return DashboardMetricsModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getDashboardMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch dashboard metrics.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLATFORM SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<PlatformSettingModel>> getPlatformSettings({
    String? scope,
  }) async {
    try {
      var query = _supabase.from(_platformSettingsTable).select();

      if (scope != null) {
        query = query.eq('scope', scope);
      }

      final list = await query.order('key', ascending: true);
      AppLogger.info('Fetched ${list.length} platform settings');
      return list
          .map<PlatformSettingModel>(
            (row) => PlatformSettingModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPlatformSettings error', error: e);
      throw const ServerException(
        message: 'Failed to fetch platform settings.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformSettingModel> getPlatformSetting(
    String key, {
    String? scope,
  }) async {
    try {
      var query = _supabase
          .from(_platformSettingsTable)
          .select()
          .eq('key', key);

      if (scope != null) {
        query = query.eq('scope', scope);
      }

      final response = await query.limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Platform setting not found.');
      }

      return PlatformSettingModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getPlatformSetting error', error: e);
      throw const ServerException(
        message: 'Failed to fetch platform setting.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformSettingModel> updatePlatformSetting(
    Map<String, dynamic> settingData,
  ) async {
    try {
      settingData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_platformSettingsTable)
          .update(settingData)
          .eq('id', settingData['id'] as String)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Platform setting not found for update.');
      }

      AppLogger.info('Platform setting updated: ${response.first['key']}');
      return PlatformSettingModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updatePlatformSetting error', error: e);
      throw const ServerException(
        message: 'Failed to update platform setting.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PlatformSettingModel>> bulkUpdateSettings(
    List<Map<String, dynamic>> settingsData,
  ) async {
    try {
      final results = <PlatformSettingModel>[];

      for (final data in settingsData) {
        data['updated_at'] = DateTime.now().toIso8601String();

        final response = await _supabase
            .from(_platformSettingsTable)
            .update(data)
            .eq('id', data['id'] as String)
            .select();

        if (response.isNotEmpty) {
          results.add(PlatformSettingModel.fromJson(response.first));
        }
      }

      AppLogger.info('Bulk updated ${results.length} platform settings');
      return results;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected bulkUpdateSettings error', error: e);
      throw const ServerException(
        message: 'Failed to bulk update platform settings.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE FLAGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<FeatureFlagModel>> getFeatureFlags({bool? isActive}) async {
    try {
      var query = _supabase.from(_featureFlagsTable).select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final list = await query.order('key', ascending: true);
      AppLogger.info('Fetched ${list.length} feature flags');
      return list
          .map<FeatureFlagModel>(
            (row) => FeatureFlagModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getFeatureFlags error', error: e);
      throw const ServerException(
        message: 'Failed to fetch feature flags.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<FeatureFlagModel> getFeatureFlag(String key) async {
    try {
      final response = await _supabase
          .from(_featureFlagsTable)
          .select()
          .eq('key', key)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Feature flag not found.');
      }

      return FeatureFlagModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getFeatureFlag error', error: e);
      throw const ServerException(
        message: 'Failed to fetch feature flag.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<FeatureFlagModel> createFeatureFlag(
    Map<String, dynamic> flagData,
  ) async {
    try {
      final response = await _supabase
          .from(_featureFlagsTable)
          .insert(flagData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Feature flag creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Feature flag created: ${response.first['key']}');
      return FeatureFlagModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createFeatureFlag error', error: e);
      throw const ServerException(
        message: 'Failed to create feature flag.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<FeatureFlagModel> updateFeatureFlag(
    String flagId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_featureFlagsTable)
          .update(data)
          .eq('id', flagId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Feature flag not found for update.');
      }

      AppLogger.info('Feature flag updated: $flagId');
      return FeatureFlagModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateFeatureFlag error', error: e);
      throw const ServerException(
        message: 'Failed to update feature flag.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteFeatureFlag(String flagId) async {
    try {
      await _supabase
          .from(_featureFlagsTable)
          .delete()
          .eq('id', flagId);

      AppLogger.info('Feature flag deleted: $flagId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteFeatureFlag error', error: e);
      throw const ServerException(
        message: 'Failed to delete feature flag.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<FeatureFlagModel> toggleFeatureFlag(
    String flagId,
    bool isActive,
  ) async {
    try {
      final response = await _supabase
          .from(_featureFlagsTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', flagId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Feature flag not found for toggle.');
      }

      AppLogger.info('Feature flag toggled: $flagId → isActive=$isActive');
      return FeatureFlagModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected toggleFeatureFlag error', error: e);
      throw const ServerException(
        message: 'Failed to toggle feature flag.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? category,
    String? severity,
    String? actorId,
    String? resourceType,
    String? resourceId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_auditLogsTable).select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (actorId != null) {
        query = query.eq('actor_id', actorId);
      }
      if (resourceType != null) {
        query = query.eq('resource_type', resourceType);
      }
      if (resourceId != null) {
        query = query.eq('resource_id', resourceId);
      }
      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} audit logs');
      return list
          .map<AuditLogModel>(
            (row) => AuditLogModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAuditLogs error', error: e);
      throw const ServerException(
        message: 'Failed to fetch audit logs.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AuditLogModel> createAuditLog(Map<String, dynamic> logData) async {
    try {
      final response = await _supabase
          .from(_auditLogsTable)
          .insert(logData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Audit log creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Audit log created: ${response.first['id']}');
      return AuditLogModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createAuditLog error', error: e);
      throw const ServerException(
        message: 'Failed to create audit log.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getAuditLogCount({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from(_auditLogsTable)
          .select('id');

      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;
      AppLogger.info('Audit log count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAuditLogCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch audit log count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCHOOL MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SchoolManagementDetailModel>> getSchools({
    bool? isActive,
    bool? isVerified,
    String? search,
    String? subscriptionStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_schoolsTable).select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }
      if (subscriptionStatus != null) {
        query = query.eq('subscription_status', subscriptionStatus);
      }
      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} schools');
      return list
          .map<SchoolManagementDetailModel>(
            (row) => SchoolManagementDetailModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSchools error', error: e);
      throw const ServerException(
        message: 'Failed to fetch schools.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolManagementDetailModel> getSchool(String schoolId) async {
    try {
      final response = await _supabase
          .from(_schoolsTable)
          .select()
          .eq('id', schoolId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('School not found.');
      }

      return SchoolManagementDetailModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSchool error', error: e);
      throw const ServerException(
        message: 'Failed to fetch school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolManagementDetailModel> createSchool(
    Map<String, dynamic> schoolData,
  ) async {
    try {
      final response = await _supabase
          .from(_schoolsTable)
          .insert(schoolData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'School creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('School created: ${response.first['id']}');
      return SchoolManagementDetailModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createSchool error', error: e);
      throw const ServerException(
        message: 'Failed to create school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolManagementDetailModel> updateSchool(
    String schoolId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_schoolsTable)
          .update(data)
          .eq('id', schoolId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('School not found for update.');
      }

      AppLogger.info('School updated: $schoolId');
      return SchoolManagementDetailModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateSchool error', error: e);
      throw const ServerException(
        message: 'Failed to update school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> suspendSchool(String schoolId, String reason) async {
    try {
      await _supabase
          .from(_schoolsTable)
          .update({
            'is_active': false,
            'suspension_reason': reason,
            'suspended_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', schoolId);

      AppLogger.info('School suspended: $schoolId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected suspendSchool error', error: e);
      throw const ServerException(
        message: 'Failed to suspend school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> reactivateSchool(String schoolId) async {
    try {
      await _supabase
          .from(_schoolsTable)
          .update({
            'is_active': true,
            'suspension_reason': null,
            'suspended_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', schoolId);

      AppLogger.info('School reactivated: $schoolId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected reactivateSchool error', error: e);
      throw const ServerException(
        message: 'Failed to reactivate school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteSchool(String schoolId) async {
    try {
      await _supabase
          .from(_schoolsTable)
          .delete()
          .eq('id', schoolId);

      AppLogger.info('School deleted: $schoolId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteSchool error', error: e);
      throw const ServerException(
        message: 'Failed to delete school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> verifySchool(String schoolId) async {
    try {
      await _supabase
          .from(_schoolsTable)
          .update({
            'is_verified': true,
            'verified_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', schoolId);

      AppLogger.info('School verified: $schoolId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected verifySchool error', error: e);
      throw const ServerException(
        message: 'Failed to verify school.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getSchoolCount({bool? isActive}) async {
    try {
      var query = _supabase.from(_schoolsTable).select('id');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query;
      AppLogger.info('School count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSchoolCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch school count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<UserManagementDetailModel>> getUsers({
    String? role,
    String? schoolId,
    bool? isActive,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_userProfilesTable).select();

      if (role != null) {
        query = query.eq('role', role);
      }
      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or('full_name.ilike.%$search%,email.ilike.%$search%');
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} users');
      return list
          .map<UserManagementDetailModel>(
            (row) => UserManagementDetailModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUsers error', error: e);
      throw const ServerException(
        message: 'Failed to fetch users.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<UserManagementDetailModel> getUser(String userId) async {
    try {
      final response = await _supabase
          .from(_userProfilesTable)
          .select()
          .eq('id', userId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('User not found.');
      }

      return UserManagementDetailModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getUser error', error: e);
      throw const ServerException(
        message: 'Failed to fetch user.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _supabase
          .from(_userProfilesTable)
          .update({
            'is_active': false,
            'suspension_reason': reason,
            'suspended_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('User suspended: $userId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected suspendUser error', error: e);
      throw const ServerException(
        message: 'Failed to suspend user.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> activateUser(String userId) async {
    try {
      await _supabase
          .from(_userProfilesTable)
          .update({
            'is_active': true,
            'suspension_reason': null,
            'suspended_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('User activated: $userId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected activateUser error', error: e);
      throw const ServerException(
        message: 'Failed to activate user.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> resetUserPassword(String userId) async {
    try {
      // Retrieve user email to send password reset
      final profile = await _supabase
          .from(_userProfilesTable)
          .select('email')
          .eq('id', userId)
          .limit(1);

      if (profile.isEmpty) {
        throw const NotFoundException('User not found for password reset.');
      }

      final email = profile.first['email'] as String;

      await _supabase.auth.resetPasswordForEmail(email);

      AppLogger.info('Password reset initiated for user: $userId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthException(
        message: e.message,
        code: e.statusCode?.toString() ?? 'auth_error',
      );
    } catch (e) {
      AppLogger.error('Unexpected resetUserPassword error', error: e);
      throw const ServerException(
        message: 'Failed to reset user password.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> changeUserRole(String userId, String newRole) async {
    try {
      await _supabase
          .from(_userProfilesTable)
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('User role changed: $userId → $newRole');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected changeUserRole error', error: e);
      throw const ServerException(
        message: 'Failed to change user role.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ImpersonationSessionModel> startImpersonation(
    Map<String, dynamic> data,
  ) async {
    try {
      data['admin_id'] = _supabase.auth.currentUser?.id;
      data['started_at'] = DateTime.now().toIso8601String();
      data['status'] = 'active';

      final response = await _supabase
          .from(_impersonationSessionsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Impersonation session creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Impersonation session started: ${response.first['id']}');
      return ImpersonationSessionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected startImpersonation error', error: e);
      throw const ServerException(
        message: 'Failed to start impersonation session.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> endImpersonation(String sessionId) async {
    try {
      await _supabase
          .from(_impersonationSessionsTable)
          .update({
            'status': 'ended',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      AppLogger.info('Impersonation session ended: $sessionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected endImpersonation error', error: e);
      throw const ServerException(
        message: 'Failed to end impersonation session.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ImpersonationSessionModel>> getImpersonationSessions({
    String? status,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from(_impersonationSessionsTable)
          .select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final list = await query
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info('Fetched ${list.length} impersonation sessions');
      return list
          .map<ImpersonationSessionModel>(
            (row) => ImpersonationSessionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getImpersonationSessions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch impersonation sessions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getUserCount({String? role, bool? isActive}) async {
    try {
      var query = _supabase.from(_userProfilesTable).select('id');

      if (role != null) {
        query = query.eq('role', role);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query;
      AppLogger.info('User count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch user count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<AIProviderModel>> getAIProviders({bool? isActive}) async {
    try {
      var query = _supabase.from(_aiProvidersTable).select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final list = await query.order('priority', ascending: true);
      AppLogger.info('Fetched ${list.length} AI providers');
      return list
          .map<AIProviderModel>(
            (row) => AIProviderModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAIProviders error', error: e);
      throw const ServerException(
        message: 'Failed to fetch AI providers.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AIProviderModel> getAIProvider(String providerId) async {
    try {
      final response = await _supabase
          .from(_aiProvidersTable)
          .select()
          .eq('id', providerId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('AI provider not found.');
      }

      return AIProviderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getAIProvider error', error: e);
      throw const ServerException(
        message: 'Failed to fetch AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AIProviderModel> createAIProvider(
    Map<String, dynamic> providerData,
  ) async {
    try {
      final response = await _supabase
          .from(_aiProvidersTable)
          .insert(providerData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'AI provider creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('AI provider created: ${response.first['id']}');
      return AIProviderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createAIProvider error', error: e);
      throw const ServerException(
        message: 'Failed to create AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AIProviderModel> updateAIProvider(
    String providerId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_aiProvidersTable)
          .update(data)
          .eq('id', providerId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('AI provider not found for update.');
      }

      AppLogger.info('AI provider updated: $providerId');
      return AIProviderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateAIProvider error', error: e);
      throw const ServerException(
        message: 'Failed to update AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteAIProvider(String providerId) async {
    try {
      await _supabase
          .from(_aiProvidersTable)
          .delete()
          .eq('id', providerId);

      AppLogger.info('AI provider deleted: $providerId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteAIProvider error', error: e);
      throw const ServerException(
        message: 'Failed to delete AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AIProviderModel> setDefaultProvider(String providerId) async {
    try {
      // Unset current default(s)
      await _supabase
          .from(_aiProvidersTable)
          .update({
            'is_default': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('is_default', true);

      // Set new default
      final response = await _supabase
          .from(_aiProvidersTable)
          .update({
            'is_default': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', providerId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('AI provider not found for setting default.');
      }

      AppLogger.info('Default AI provider set: $providerId');
      return AIProviderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected setDefaultProvider error', error: e);
      throw const ServerException(
        message: 'Failed to set default AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AIProviderModel> toggleProvider(
    String providerId,
    bool isActive,
  ) async {
    try {
      final response = await _supabase
          .from(_aiProvidersTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', providerId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('AI provider not found for toggle.');
      }

      AppLogger.info('AI provider toggled: $providerId → isActive=$isActive');
      return AIProviderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected toggleProvider error', error: e);
      throw const ServerException(
        message: 'Failed to toggle AI provider.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AIRequestLogModel>> getAIRequestLogs({
    String? providerId,
    String? userId,
    String? schoolId,
    bool? isSuccess,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_aiRequestLogsTable).select();

      if (providerId != null) {
        query = query.eq('provider_id', providerId);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (isSuccess != null) {
        query = query.eq('is_success', isSuccess);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} AI request logs');
      return list
          .map<AIRequestLogModel>(
            (row) => AIRequestLogModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAIRequestLogs error', error: e);
      throw const ServerException(
        message: 'Failed to fetch AI request logs.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAIUsageAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_ai_usage_analytics',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      AppLogger.info('Fetched AI usage analytics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAIUsageAnalytics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch AI usage analytics.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // INFRASTRUCTURE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<InfrastructureServiceModel>> getInfrastructureServices({
    String? status,
  }) async {
    try {
      var query = _supabase.from(_infrastructureServicesTable).select();

      if (status != null) {
        query = query.eq('health_status', status);
      }

      final list = await query.order('service_name', ascending: true);
      AppLogger.info('Fetched ${list.length} infrastructure services');
      return list
          .map<InfrastructureServiceModel>(
            (row) => InfrastructureServiceModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getInfrastructureServices error', error: e);
      throw const ServerException(
        message: 'Failed to fetch infrastructure services.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InfrastructureServiceModel> getInfrastructureService(
    String serviceId,
  ) async {
    try {
      final response = await _supabase
          .from(_infrastructureServicesTable)
          .select()
          .eq('id', serviceId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Infrastructure service not found.');
      }

      return InfrastructureServiceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getInfrastructureService error', error: e);
      throw const ServerException(
        message: 'Failed to fetch infrastructure service.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InfrastructureServiceModel> updateInfrastructureService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_infrastructureServicesTable)
          .update(data)
          .eq('id', serviceId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(
          'Infrastructure service not found for update.',
        );
      }

      AppLogger.info('Infrastructure service updated: $serviceId');
      return InfrastructureServiceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateInfrastructureService error', error: e);
      throw const ServerException(
        message: 'Failed to update infrastructure service.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> runHealthCheck(String serviceId) async {
    try {
      await _supabase.rpc(
        'run_health_check',
        params: {'service_id': serviceId},
      );

      AppLogger.info('Health check triggered for service: $serviceId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected runHealthCheck error', error: e);
      throw const ServerException(
        message: 'Failed to run health check.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> runAllHealthChecks() async {
    try {
      await _supabase.rpc('run_all_health_checks');

      AppLogger.info('All health checks triggered');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected runAllHealthChecks error', error: e);
      throw const ServerException(
        message: 'Failed to run all health checks.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUPPORT TICKETS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SupportTicketModel>> getSupportTickets({
    String? status,
    String? priority,
    String? category,
    String? assignedTo,
    String? schoolId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_supportTicketsTable).select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (assignedTo != null) {
        query = query.eq('assigned_to', assignedTo);
      }
      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or('subject.ilike.%$search%,ticket_number.ilike.%$search%');
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} support tickets');
      return list
          .map<SupportTicketModel>(
            (row) => SupportTicketModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSupportTickets error', error: e);
      throw const ServerException(
        message: 'Failed to fetch support tickets.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SupportTicketModel> getSupportTicket(String ticketId) async {
    try {
      final response = await _supabase
          .from(_supportTicketsTable)
          .select()
          .eq('id', ticketId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Support ticket not found.');
      }

      return SupportTicketModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSupportTicket error', error: e);
      throw const ServerException(
        message: 'Failed to fetch support ticket.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SupportTicketModel> updateSupportTicket(
    String ticketId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_supportTicketsTable)
          .update(data)
          .eq('id', ticketId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Support ticket not found for update.');
      }

      AppLogger.info('Support ticket updated: $ticketId');
      return SupportTicketModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateSupportTicket error', error: e);
      throw const ServerException(
        message: 'Failed to update support ticket.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SupportTicketModel> assignTicket(
    String ticketId,
    String assignToUserId,
  ) async {
    try {
      final response = await _supabase
          .from(_supportTicketsTable)
          .update({
            'assigned_to': assignToUserId,
            'status': 'in_progress',
            if (null == (await _supabase
                .from(_supportTicketsTable)
                .select('first_response_at')
                .eq('id', ticketId)
                .limit(1))
                .first['first_response_at'])
              'first_response_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Support ticket not found for assignment.');
      }

      AppLogger.info('Support ticket assigned: $ticketId → $assignToUserId');
      return SupportTicketModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected assignTicket error', error: e);
      throw const ServerException(
        message: 'Failed to assign support ticket.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SupportTicketModel> escalateTicket(
    String ticketId,
    String escalateToUserId,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_supportTicketsTable)
          .update({
            'is_escalated': true,
            'escalated_to': escalateToUserId,
            'escalated_at': DateTime.now().toIso8601String(),
            'priority': 'urgent',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Support ticket not found for escalation.');
      }

      AppLogger.info('Support ticket escalated: $ticketId');
      return SupportTicketModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected escalateTicket error', error: e);
      throw const ServerException(
        message: 'Failed to escalate support ticket.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SupportTicketModel> resolveTicket(
    String ticketId,
    String resolutionNotes,
  ) async {
    try {
      final response = await _supabase
          .from(_supportTicketsTable)
          .update({
            'status': 'resolved',
            'resolution_notes': resolutionNotes,
            'resolved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Support ticket not found for resolution.');
      }

      AppLogger.info('Support ticket resolved: $ticketId');
      return SupportTicketModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected resolveTicket error', error: e);
      throw const ServerException(
        message: 'Failed to resolve support ticket.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TicketCommentModel> addTicketComment(
    Map<String, dynamic> commentData,
  ) async {
    try {
      commentData['author_id'] = _supabase.auth.currentUser?.id;
      commentData['created_at'] = DateTime.now().toIso8601String();
      commentData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_ticketCommentsTable)
          .insert(commentData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Ticket comment creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Ticket comment added: ${response.first['id']}');
      return TicketCommentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected addTicketComment error', error: e);
      throw const ServerException(
        message: 'Failed to add ticket comment.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TicketCommentModel>> getTicketComments(
    String ticketId,
  ) async {
    try {
      final list = await _supabase
          .from(_ticketCommentsTable)
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      AppLogger.info('Fetched ${list.length} ticket comments for ticket $ticketId');
      return list
          .map<TicketCommentModel>(
            (row) => TicketCommentModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTicketComments error', error: e);
      throw const ServerException(
        message: 'Failed to fetch ticket comments.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getTicketCount({String? status}) async {
    try {
      var query = _supabase.from(_supportTicketsTable).select('id');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      AppLogger.info('Ticket count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTicketCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch ticket count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MARKETPLACE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceContentModel>> getMarketplaceContent({
    String? status,
    String? contentType,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_marketplaceContentTable).select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }
      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} marketplace content items');
      return list
          .map<MarketplaceContentModel>(
            (row) => MarketplaceContentModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to fetch marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> getMarketplaceItem(
    String contentId,
  ) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .select()
          .eq('id', contentId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found.');
      }

      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceItem error', error: e);
      throw const ServerException(
        message: 'Failed to fetch marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> approveMarketplaceContent(
    String contentId, {
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .update({
            'status': 'approved',
            'review_notes': notes,
            'reviewed_by': _supabase.auth.currentUser?.id,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found for approval.');
      }

      AppLogger.info('Marketplace content approved: $contentId');
      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected approveMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to approve marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> rejectMarketplaceContent(
    String contentId,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .update({
            'status': 'rejected',
            'review_notes': reason,
            'reviewed_by': _supabase.auth.currentUser?.id,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found for rejection.');
      }

      AppLogger.info('Marketplace content rejected: $contentId');
      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected rejectMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to reject marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> featureMarketplaceContent(
    String contentId,
    DateTime? until,
  ) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .update({
            'status': 'featured',
            'featured_until': until?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found for featuring.');
      }

      AppLogger.info('Marketplace content featured: $contentId');
      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected featureMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to feature marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> removeMarketplaceContent(
    String contentId,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .update({
            'status': 'archived',
            'review_notes': reason,
            'reviewed_by': _supabase.auth.currentUser?.id,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found for removal.');
      }

      AppLogger.info('Marketplace content removed: $contentId');
      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected removeMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to remove marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceContentModel> flagMarketplaceContent(
    String contentId,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_marketplaceContentTable)
          .update({
            'is_flagged': true,
            'flag_reason': reason,
            'flagged_by': _supabase.auth.currentUser?.id,
            'flagged_at': DateTime.now().toIso8601String(),
            'status': 'flagged',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Marketplace content not found for flagging.');
      }

      AppLogger.info('Marketplace content flagged: $contentId');
      return MarketplaceContentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected flagMarketplaceContent error', error: e);
      throw const ServerException(
        message: 'Failed to flag marketplace content.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getMarketplaceContentCount({String? status}) async {
    try {
      var query = _supabase.from(_marketplaceContentTable).select('id');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      AppLogger.info('Marketplace content count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceContentCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch marketplace content count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLATFORM NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<PlatformNotificationModel>> getNotifications({
    String? recipientId,
    String? category,
    String? priority,
    bool? unreadOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_platformNotificationsTable).select();

      if (recipientId != null) {
        query = query.eq('recipient_id', recipientId);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} platform notifications');
      return list
          .map<PlatformNotificationModel>(
            (row) => PlatformNotificationModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getNotifications error', error: e);
      throw const ServerException(
        message: 'Failed to fetch platform notifications.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformNotificationModel> markNotificationRead(
    String notificationId,
  ) async {
    try {
      final response = await _supabase
          .from(_platformNotificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Notification not found.');
      }

      AppLogger.info('Notification marked as read: $notificationId');
      return PlatformNotificationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected markNotificationRead error', error: e);
      throw const ServerException(
        message: 'Failed to mark notification as read.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> markAllNotificationsRead({String? recipientId}) async {
    try {
      final targetRecipient = recipientId ?? _supabase.auth.currentUser?.id;
      if (targetRecipient == null) {
        throw const AuthException(
          message: 'No authenticated user and no recipient specified.',
          code: 'no_recipient',
        );
      }

      await _supabase
          .from(_platformNotificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_id', targetRecipient)
          .eq('is_read', false);

      AppLogger.info('All notifications marked as read for $targetRecipient');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected markAllNotificationsRead error', error: e);
      throw const ServerException(
        message: 'Failed to mark all notifications as read.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _supabase
          .from(_platformNotificationsTable)
          .update({
            'is_dismissed': true,
            'dismissed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      AppLogger.info('Notification dismissed: $notificationId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected dismissNotification error', error: e);
      throw const ServerException(
        message: 'Failed to dismiss notification.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformNotificationModel> createNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final response = await _supabase
          .from(_platformNotificationsTable)
          .insert(notificationData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Notification creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Notification created: ${response.first['id']}');
      return PlatformNotificationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createNotification error', error: e);
      throw const ServerException(
        message: 'Failed to create notification.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getUnreadNotificationCount({String? recipientId}) async {
    try {
      final targetRecipient = recipientId ?? _supabase.auth.currentUser?.id;
      if (targetRecipient == null) {
        throw const AuthException(
          message: 'No authenticated user and no recipient specified.',
          code: 'no_recipient',
        );
      }

      final response = await _supabase
          .from(_platformNotificationsTable)
          .select('id')
          .eq('recipient_id', targetRecipient)
          .eq('is_read', false);

      AppLogger.info('Unread notification count: ${response.length}');
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getUnreadNotificationCount error', error: e);
      throw const ServerException(
        message: 'Failed to fetch unread notification count.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // OPERATIONS INTELLIGENCE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<IntelligenceAlertModel>> getIntelligenceAlerts({
    String? alertType,
    String? severity,
    bool? unacknowledgedOnly,
    bool? unresolvedOnly,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_intelligenceAlertsTable).select();

      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (unacknowledgedOnly == true) {
        query = query.eq('is_acknowledged', false);
      }
      if (unresolvedOnly == true) {
        query = query.eq('is_resolved', false);
      }
      if (schoolId != null) {
        query = query.eq('affected_school_id', schoolId);
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} intelligence alerts');
      return list
          .map<IntelligenceAlertModel>(
            (row) => IntelligenceAlertModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getIntelligenceAlerts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch intelligence alerts.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IntelligenceAlertModel> getIntelligenceAlert(
    String alertId,
  ) async {
    try {
      final response = await _supabase
          .from(_intelligenceAlertsTable)
          .select()
          .eq('id', alertId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Intelligence alert not found.');
      }

      return IntelligenceAlertModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getIntelligenceAlert error', error: e);
      throw const ServerException(
        message: 'Failed to fetch intelligence alert.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IntelligenceAlertModel> acknowledgeAlert(String alertId) async {
    try {
      final response = await _supabase
          .from(_intelligenceAlertsTable)
          .update({
            'is_acknowledged': true,
            'acknowledged_by': _supabase.auth.currentUser?.id,
            'acknowledged_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Intelligence alert not found for acknowledgement.');
      }

      AppLogger.info('Intelligence alert acknowledged: $alertId');
      return IntelligenceAlertModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected acknowledgeAlert error', error: e);
      throw const ServerException(
        message: 'Failed to acknowledge intelligence alert.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IntelligenceAlertModel> resolveAlert(
    String alertId,
    String resolutionNotes,
  ) async {
    try {
      final response = await _supabase
          .from(_intelligenceAlertsTable)
          .update({
            'is_resolved': true,
            'resolved_by': _supabase.auth.currentUser?.id,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolutionNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Intelligence alert not found for resolution.');
      }

      AppLogger.info('Intelligence alert resolved: $alertId');
      return IntelligenceAlertModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected resolveAlert error', error: e);
      throw const ServerException(
        message: 'Failed to resolve intelligence alert.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<IntelligenceAlertModel>> generateIntelligenceInsights() async {
    try {
      final response = await _supabase.rpc(
        'generate_intelligence_insights',
      );

      final list = response as List<dynamic>;
      AppLogger.info('Generated ${list.length} intelligence insights');
      return list
          .map<IntelligenceAlertModel>(
            (row) => IntelligenceAlertModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected generateIntelligenceInsights error', error: e);
      throw const ServerException(
        message: 'Failed to generate intelligence insights.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getChurnPredictions({int limit = 20}) async {
    try {
      final response = await _supabase.rpc(
        'get_churn_predictions',
        params: {'limit_count': limit},
      );

      AppLogger.info('Fetched churn predictions');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getChurnPredictions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch churn predictions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getRevenueForecast({
    int monthsAhead = 6,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_revenue_forecast',
        params: {'months_ahead': monthsAhead},
      );

      AppLogger.info('Fetched revenue forecast');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRevenueForecast error', error: e);
      throw const ServerException(
        message: 'Failed to fetch revenue forecast.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getEngagementInsights() async {
    try {
      final response = await _supabase.rpc(
        'get_engagement_insights',
      );

      AppLogger.info('Fetched engagement insights');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getEngagementInsights error', error: e);
      throw const ServerException(
        message: 'Failed to fetch engagement insights.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCostOptimizationSuggestions() async {
    try {
      final response = await _supabase.rpc(
        'get_cost_optimization_suggestions',
      );

      AppLogger.info('Fetched cost optimization suggestions');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCostOptimizationSuggestions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch cost optimization suggestions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVENUE ANALYTICS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<RevenueAnalyticsModel> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_revenue_analytics',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      AppLogger.info('Fetched revenue analytics');
      return RevenueAnalyticsModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRevenueAnalytics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch revenue analytics.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECURITY
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<LoginMonitoringEntryModel>> getLoginMonitoring({
    String? userId,
    bool? failedOnly,
    String? ipAddress,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_loginMonitoringTable).select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (failedOnly == true) {
        query = query.eq('is_success', false);
      }
      if (ipAddress != null) {
        query = query.eq('ip_address', ipAddress);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${list.length} login monitoring entries');
      return list
          .map<LoginMonitoringEntryModel>(
            (row) => LoginMonitoringEntryModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getLoginMonitoring error', error: e);
      throw const ServerException(
        message: 'Failed to fetch login monitoring data.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ActiveSessionModel>> getActiveSessions({String? userId}) async {
    try {
      var query = _supabase
          .from(_activeSessionsTable)
          .select()
          .gt('expires_at', DateTime.now().toIso8601String());

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final list = await query.order('last_activity_at', ascending: false);
      AppLogger.info('Fetched ${list.length} active sessions');
      return list
          .map<ActiveSessionModel>(
            (row) => ActiveSessionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getActiveSessions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch active sessions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> terminateSession(String sessionId) async {
    try {
      await _supabase
          .from(_activeSessionsTable)
          .delete()
          .eq('id', sessionId);

      AppLogger.info('Session terminated: $sessionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected terminateSession error', error: e);
      throw const ServerException(
        message: 'Failed to terminate session.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> detectSuspiciousActivity({
    int lookbackHours = 24,
  }) async {
    try {
      final response = await _supabase.rpc(
        'detect_suspicious_logins',
        params: {'lookback_hours': lookbackHours},
      );

      AppLogger.info('Fetched suspicious activity detections');
      return (response as List<dynamic>)
          .map<Map<String, dynamic>>(
            (row) => row as Map<String, dynamic>,
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected detectSuspiciousActivity error', error: e);
      throw const ServerException(
        message: 'Failed to detect suspicious activity.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> lockUserAccount(String userId, String reason) async {
    try {
      await _supabase
          .from(_userProfilesTable)
          .update({
            'is_locked': true,
            'lock_reason': reason,
            'locked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('User account locked: $userId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected lockUserAccount error', error: e);
      throw const ServerException(
        message: 'Failed to lock user account.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> unlockUserAccount(String userId) async {
    try {
      await _supabase
          .from(_userProfilesTable)
          .update({
            'is_locked': false,
            'lock_reason': null,
            'locked_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('User account unlocked: $userId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected unlockUserAccount error', error: e);
      throw const ServerException(
        message: 'Failed to unlock user account.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SYSTEM REPORTS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SystemReportModel>> getSystemReports({
    String? type,
    String? status,
  }) async {
    try {
      var query = _supabase.from(_systemReportsTable).select();

      if (type != null) {
        query = query.eq('report_type', type);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final list = await query.order('created_at', ascending: false);
      AppLogger.info('Fetched ${list.length} system reports');
      return list
          .map<SystemReportModel>(
            (row) => SystemReportModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSystemReports error', error: e);
      throw const ServerException(
        message: 'Failed to fetch system reports.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SystemReportModel> generateReport(Map<String, dynamic> params) async {
    try {
      final response = await _supabase.rpc(
        'generate_system_report',
        params: params,
      );

      AppLogger.info('System report generated');
      return SystemReportModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected generateReport error', error: e);
      throw const ServerException(
        message: 'Failed to generate system report.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SystemReportModel> getSystemReport(String reportId) async {
    try {
      final response = await _supabase
          .from(_systemReportsTable)
          .select()
          .eq('id', reportId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('System report not found.');
      }

      return SystemReportModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSystemReport error', error: e);
      throw const ServerException(
        message: 'Failed to fetch system report.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAINTENANCE WINDOWS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MaintenanceWindowModel>> getMaintenanceWindows({
    String? status,
  }) async {
    try {
      var query = _supabase.from(_maintenanceWindowsTable).select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final list = await query.order('start_at', ascending: true);
      AppLogger.info('Fetched ${list.length} maintenance windows');
      return list
          .map<MaintenanceWindowModel>(
            (row) => MaintenanceWindowModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getMaintenanceWindows error', error: e);
      throw const ServerException(
        message: 'Failed to fetch maintenance windows.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MaintenanceWindowModel> createMaintenanceWindow(
    Map<String, dynamic> windowData,
  ) async {
    try {
      windowData['created_by'] ??= _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from(_maintenanceWindowsTable)
          .insert(windowData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Maintenance window creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Maintenance window created: ${response.first['id']}');
      return MaintenanceWindowModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createMaintenanceWindow error', error: e);
      throw const ServerException(
        message: 'Failed to create maintenance window.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MaintenanceWindowModel> updateMaintenanceWindow(
    String windowId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_maintenanceWindowsTable)
          .update(data)
          .eq('id', windowId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException('Maintenance window not found for update.');
      }

      AppLogger.info('Maintenance window updated: $windowId');
      return MaintenanceWindowModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateMaintenanceWindow error', error: e);
      throw const ServerException(
        message: 'Failed to update maintenance window.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> cancelMaintenanceWindow(String windowId) async {
    try {
      await _supabase
          .from(_maintenanceWindowsTable)
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', windowId);

      AppLogger.info('Maintenance window cancelled: $windowId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected cancelMaintenanceWindow error', error: e);
      throw const ServerException(
        message: 'Failed to cancel maintenance window.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLATFORM POLICIES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<PlatformPolicyModel>> getPlatformPolicies({bool? isActive}) async {
    try {
      var query = _supabase.from(_platformPoliciesTable).select();

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final list = await query.order('policy_key', ascending: true);
      AppLogger.info('Fetched ${list.length} platform policies');
      return list
          .map<PlatformPolicyModel>(
            (row) => PlatformPolicyModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPlatformPolicies error', error: e);
      throw const ServerException(
        message: 'Failed to fetch platform policies.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformPolicyModel> getPlatformPolicy(String policyKey) async {
    try {
      final response = await _supabase
          .from(_platformPoliciesTable)
          .select()
          .eq('policy_key', policyKey)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Platform policy not found.');
      }

      return PlatformPolicyModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getPlatformPolicy error', error: e);
      throw const ServerException(
        message: 'Failed to fetch platform policy.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PlatformPolicyModel> upsertPlatformPolicy(
    Map<String, dynamic> policyData,
  ) async {
    try {
      policyData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_platformPoliciesTable)
          .upsert(policyData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Platform policy upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Platform policy upserted: ${response.first['policy_key']}');
      return PlatformPolicyModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertPlatformPolicy error', error: e);
      throw const ServerException(
        message: 'Failed to upsert platform policy.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EMAIL TEMPLATES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<EmailTemplateModel>> getEmailTemplates({String? category}) async {
    try {
      var query = _supabase.from(_emailTemplatesTable).select();

      if (category != null) {
        query = query.eq('category', category);
      }

      final list = await query.order('template_key', ascending: true);
      AppLogger.info('Fetched ${list.length} email templates');
      return list
          .map<EmailTemplateModel>(
            (row) => EmailTemplateModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getEmailTemplates error', error: e);
      throw const ServerException(
        message: 'Failed to fetch email templates.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<EmailTemplateModel> getEmailTemplate(String templateKey) async {
    try {
      final response = await _supabase
          .from(_emailTemplatesTable)
          .select()
          .eq('template_key', templateKey)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException('Email template not found.');
      }

      return EmailTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getEmailTemplate error', error: e);
      throw const ServerException(
        message: 'Failed to fetch email template.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<EmailTemplateModel> upsertEmailTemplate(
    Map<String, dynamic> templateData,
  ) async {
    try {
      templateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_emailTemplatesTable)
          .upsert(templateData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Email template upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Email template upserted: ${response.first['template_key']}');
      return EmailTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertEmailTemplate error', error: e);
      throw const ServerException(
        message: 'Failed to upsert email template.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLATFORM ANALYTICS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getSchoolGrowthMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_school_growth_metrics',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      AppLogger.info('Fetched school growth metrics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSchoolGrowthMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch school growth metrics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getUserGrowthMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_growth_metrics',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      AppLogger.info('Fetched user growth metrics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserGrowthMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch user growth metrics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getFeatureUsageMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_feature_usage_metrics',
        params: {
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );

      AppLogger.info('Fetched feature usage metrics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getFeatureUsageMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch feature usage metrics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getStorageUsageMetrics() async {
    try {
      final response = await _supabase.rpc(
        'get_storage_usage_metrics',
      );

      AppLogger.info('Fetched storage usage metrics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getStorageUsageMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch storage usage metrics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getGeographicDistribution() async {
    try {
      final response = await _supabase.rpc(
        'get_geographic_distribution',
      );

      AppLogger.info('Fetched geographic distribution');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getGeographicDistribution error', error: e);
      throw const ServerException(
        message: 'Failed to fetch geographic distribution.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getRetentionMetrics({int months = 12}) async {
    try {
      final response = await _supabase.rpc(
        'get_retention_metrics',
        params: {'months': months},
      );

      AppLogger.info('Fetched retention metrics');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRetentionMetrics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch retention metrics.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Returns the current authenticated user ID, or `null` if not signed in.
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Maps a Supabase [sb.PostgrestException] to a domain exception.
  Exception _mapPostgrestException(sb.PostgrestException e) {
    final statusCode = e.code != null ? int.tryParse(e.code!) ?? 0 : 0;
    final message = e.message ?? 'An unexpected database error occurred.';

    AppLogger.warning(
      'Supabase PostgrestException — code: ${e.code}, message: $message',
    );

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(
          message: message,
          fieldErrors: e.details is Map<String, dynamic>
              ? e.details as Map<String, String>
              : {},
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: e.details,
        );
    }
  }
}
