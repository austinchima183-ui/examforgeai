import '../../../../core/utils/result.dart';
import '../entities/super_admin_entities.dart';

abstract class SuperAdminRepository {
  // ═══ Dashboard ═══
  Future<Result<DashboardMetrics>> getDashboardMetrics({bool forceRefresh = false});

  // ═══ Platform Settings ═══
  Future<Result<List<PlatformSetting>>> getPlatformSettings({SettingScope? scope});
  Future<Result<PlatformSetting>> getPlatformSetting(String key, {SettingScope? scope});
  Future<Result<PlatformSetting>> updatePlatformSetting(PlatformSetting setting);
  Future<Result<List<PlatformSetting>>> bulkUpdateSettings(List<PlatformSetting> settings);

  // ═══ Feature Flags ═══
  Future<Result<List<FeatureFlag>>> getFeatureFlags({bool? isActive});
  Future<Result<FeatureFlag>> getFeatureFlag(String key);
  Future<Result<FeatureFlag>> createFeatureFlag(FeatureFlag flag);
  Future<Result<FeatureFlag>> updateFeatureFlag(FeatureFlag flag);
  Future<Result<void>> deleteFeatureFlag(String flagId);
  Future<Result<FeatureFlag>> toggleFeatureFlag(String flagId, bool isActive);

  // ═══ Audit Logs ═══
  Future<Result<List<AuditLog>>> getAuditLogs({
    AuditCategory? category,
    AuditSeverity? severity,
    String? actorId,
    String? resourceType,
    String? resourceId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<AuditLog>> createAuditLog(AuditLog log);
  Future<Result<int>> getAuditLogCount({AuditCategory? category, DateTime? startDate, DateTime? endDate});

  // ═══ School Management ═══
  Future<Result<List<SchoolManagementDetail>>> getSchools({
    bool? isActive,
    bool? isVerified,
    String? search,
    String? subscriptionStatus,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<SchoolManagementDetail>> getSchool(String schoolId);
  Future<Result<SchoolManagementDetail>> createSchool(Map<String, dynamic> schoolData);
  Future<Result<SchoolManagementDetail>> updateSchool(String schoolId, Map<String, dynamic> data);
  Future<Result<void>> suspendSchool(String schoolId, String reason);
  Future<Result<void>> reactivateSchool(String schoolId);
  Future<Result<void>> deleteSchool(String schoolId);
  Future<Result<void>> verifySchool(String schoolId);
  Future<Result<int>> getSchoolCount({bool? isActive});

  // ═══ User Management ═══
  Future<Result<List<UserManagementDetail>>> getUsers({
    String? role,
    String? schoolId,
    bool? isActive,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<UserManagementDetail>> getUser(String userId);
  Future<Result<void>> suspendUser(String userId, String reason);
  Future<Result<void>> activateUser(String userId);
  Future<Result<void>> resetUserPassword(String userId);
  Future<Result<void>> changeUserRole(String userId, String newRole);
  Future<Result<ImpersonationSession>> startImpersonation(String targetUserId, String reason);
  Future<Result<void>> endImpersonation(String sessionId);
  Future<Result<List<ImpersonationSession>>> getImpersonationSessions({String? status, int limit = 20});
  Future<Result<int>> getUserCount({String? role, bool? isActive});

  // ═══ AI Management ═══
  Future<Result<List<AIProvider>>> getAIProviders({bool? isActive});
  Future<Result<AIProvider>> getAIProvider(String providerId);
  Future<Result<AIProvider>> createAIProvider(AIProvider provider);
  Future<Result<AIProvider>> updateAIProvider(AIProvider provider);
  Future<Result<void>> deleteAIProvider(String providerId);
  Future<Result<AIProvider>> setDefaultProvider(String providerId);
  Future<Result<AIProvider>> toggleProvider(String providerId, bool isActive);
  Future<Result<List<AIRequestLog>>> getAIRequestLogs({
    String? providerId,
    String? userId,
    String? schoolId,
    bool? isSuccess,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<Map<String, dynamic>>> getAIUsageAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  });

  // ═══ Infrastructure ═══
  Future<Result<List<InfrastructureService>>> getInfrastructureServices({HealthStatus? status});
  Future<Result<InfrastructureService>> getInfrastructureService(String serviceId);
  Future<Result<InfrastructureService>> updateInfrastructureService(InfrastructureService service);
  Future<Result<void>> runHealthCheck(String serviceId);
  Future<Result<void>> runAllHealthChecks();

  // ═══ Support Tickets ═══
  Future<Result<List<SupportTicket>>> getSupportTickets({
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
    String? schoolId,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<SupportTicket>> getSupportTicket(String ticketId);
  Future<Result<SupportTicket>> updateSupportTicket(SupportTicket ticket);
  Future<Result<SupportTicket>> assignTicket(String ticketId, String assignToUserId);
  Future<Result<SupportTicket>> escalateTicket(String ticketId, String escalateToUserId, String reason);
  Future<Result<SupportTicket>> resolveTicket(String ticketId, String resolutionNotes);
  Future<Result<TicketComment>> addTicketComment(String ticketId, String content, {bool isInternal = false});
  Future<Result<List<TicketComment>>> getTicketComments(String ticketId);
  Future<Result<int>> getTicketCount({TicketStatus? status});

  // ═══ Marketplace ═══
  Future<Result<List<MarketplaceContent>>> getMarketplaceContent({
    MarketplaceStatus? status,
    MarketplaceContentType? contentType,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<MarketplaceContent>> getMarketplaceItem(String contentId);
  Future<Result<MarketplaceContent>> approveMarketplaceContent(String contentId, {String? notes});
  Future<Result<MarketplaceContent>> rejectMarketplaceContent(String contentId, String reason);
  Future<Result<MarketplaceContent>> featureMarketplaceContent(String contentId, DateTime? until);
  Future<Result<MarketplaceContent>> removeMarketplaceContent(String contentId, String reason);
  Future<Result<MarketplaceContent>> flagMarketplaceContent(String contentId, String reason);
  Future<Result<int>> getMarketplaceContentCount({MarketplaceStatus? status});

  // ═══ Platform Notifications ═══
  Future<Result<List<PlatformNotification>>> getNotifications({
    String? recipientId,
    NotificationCategory? category,
    NotificationPriority? priority,
    bool? unreadOnly,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<PlatformNotification>> markNotificationRead(String notificationId);
  Future<Result<void>> markAllNotificationsRead({String? recipientId});
  Future<Result<void>> dismissNotification(String notificationId);
  Future<Result<PlatformNotification>> createNotification(PlatformNotification notification);
  Future<Result<int>> getUnreadNotificationCount({String? recipientId});

  // ═══ Operations Intelligence ═══
  Future<Result<List<IntelligenceAlert>>> getIntelligenceAlerts({
    IntelligenceAlertType? alertType,
    IntelligenceSeverity? severity,
    bool? unacknowledgedOnly,
    bool? unresolvedOnly,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<IntelligenceAlert>> getIntelligenceAlert(String alertId);
  Future<Result<IntelligenceAlert>> acknowledgeAlert(String alertId);
  Future<Result<IntelligenceAlert>> resolveAlert(String alertId, String resolutionNotes);
  Future<Result<List<IntelligenceAlert>>> generateIntelligenceInsights();
  Future<Result<Map<String, dynamic>>> getChurnPredictions({int limit = 20});
  Future<Result<Map<String, dynamic>>> getRevenueForecast({int monthsAhead = 6});
  Future<Result<Map<String, dynamic>>> getEngagementInsights();
  Future<Result<Map<String, dynamic>>> getCostOptimizationSuggestions();

  // ═══ Revenue Analytics ═══
  Future<Result<RevenueAnalytics>> getRevenueAnalytics({DateTime? startDate, DateTime? endDate});

  // ═══ Security ═══
  Future<Result<List<LoginMonitoringEntry>>> getLoginMonitoring({
    String? userId,
    bool? failedOnly,
    String? ipAddress,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });
  Future<Result<List<ActiveSession>>> getActiveSessions({String? userId});
  Future<Result<void>> terminateSession(String sessionId);
  Future<Result<List<Map<String, dynamic>>>> detectSuspiciousActivity({int lookbackHours = 24});
  Future<Result<void>> lockUserAccount(String userId, String reason);
  Future<Result<void>> unlockUserAccount(String userId);

  // ═══ System Reports ═══
  Future<Result<List<SystemReport>>> getSystemReports({ReportType? type, String? status});
  Future<Result<SystemReport>> generateReport(ReportType type, Map<String, dynamic> parameters, {String format = 'pdf'});
  Future<Result<SystemReport>> getSystemReport(String reportId);

  // ═══ Maintenance Windows ═══
  Future<Result<List<MaintenanceWindow>>> getMaintenanceWindows({MaintenanceStatus? status});
  Future<Result<MaintenanceWindow>> createMaintenanceWindow(MaintenanceWindow window);
  Future<Result<MaintenanceWindow>> updateMaintenanceWindow(MaintenanceWindow window);
  Future<Result<void>> cancelMaintenanceWindow(String windowId);

  // ═══ Platform Policies ═══
  Future<Result<List<PlatformPolicy>>> getPlatformPolicies({bool? isActive});
  Future<Result<PlatformPolicy>> getPlatformPolicy(String policyKey);
  Future<Result<PlatformPolicy>> upsertPlatformPolicy(PlatformPolicy policy);

  // ═══ Email Templates ═══
  Future<Result<List<EmailTemplate>>> getEmailTemplates({String? category});
  Future<Result<EmailTemplate>> getEmailTemplate(String templateKey);
  Future<Result<EmailTemplate>> upsertEmailTemplate(EmailTemplate template);

  // ═══ Platform Analytics ═══
  Future<Result<Map<String, dynamic>>> getSchoolGrowthMetrics({DateTime? startDate, DateTime? endDate});
  Future<Result<Map<String, dynamic>>> getUserGrowthMetrics({DateTime? startDate, DateTime? endDate});
  Future<Result<Map<String, dynamic>>> getFeatureUsageMetrics({DateTime? startDate, DateTime? endDate});
  Future<Result<Map<String, dynamic>>> getStorageUsageMetrics();
  Future<Result<Map<String, dynamic>>> getGeographicDistribution();
  Future<Result<Map<String, dynamic>>> getRetentionMetrics({int months = 12});
}
