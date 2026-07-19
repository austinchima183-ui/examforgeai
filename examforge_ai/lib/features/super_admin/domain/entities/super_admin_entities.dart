import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum SettingScope {
  global('global', 'Global'),
  billing('billing', 'Billing'),
  ai('ai', 'AI'),
  communication('communication', 'Communication'),
  security('security', 'Security'),
  infrastructure('infrastructure', 'Infrastructure'),
  marketplace('marketplace', 'Marketplace'),
  email('email', 'Email'),
  notification('notification', 'Notification'),
  featureFlag('feature_flag', 'Feature Flag');

  const SettingScope(this.value, this.label);
  final String value;
  final String label;
  static SettingScope fromString(String v) =>
      SettingScope.values.firstWhere((e) => e.value == v, orElse: () => SettingScope.global);
}

enum SettingValueType {
  string('string', 'String'),
  integer('integer', 'Integer'),
  boolean('boolean', 'Boolean'),
  json('json', 'JSON'),
  float('float', 'Float'),
  encrypted('encrypted', 'Encrypted');

  const SettingValueType(this.value, this.label);
  final String value;
  final String label;
  static SettingValueType fromString(String v) =>
      SettingValueType.values.firstWhere((e) => e.value == v, orElse: () => SettingValueType.string);
}

enum AuditSeverity {
  info('info', 'Info'),
  warning('warning', 'Warning'),
  error('error', 'Error'),
  critical('critical', 'Critical');

  const AuditSeverity(this.value, this.label);
  final String value;
  final String label;
  static AuditSeverity fromString(String v) =>
      AuditSeverity.values.firstWhere((e) => e.value == v, orElse: () => AuditSeverity.info);
}

enum AuditCategory {
  authentication('authentication', 'Authentication'),
  authorization('authorization', 'Authorization'),
  dataAccess('data_access', 'Data Access'),
  dataModification('data_modification', 'Data Modification'),
  systemConfiguration('system_configuration', 'System Configuration'),
  billing('billing', 'Billing'),
  aiOperations('ai_operations', 'AI Operations'),
  security('security', 'Security'),
  userManagement('user_management', 'User Management'),
  schoolManagement('school_management', 'School Management'),
  marketplace('marketplace', 'Marketplace'),
  support('support', 'Support'),
  infrastructure('infrastructure', 'Infrastructure');

  const AuditCategory(this.value, this.label);
  final String value;
  final String label;
  static AuditCategory fromString(String v) =>
      AuditCategory.values.firstWhere((e) => e.value == v, orElse: () => AuditCategory.systemConfiguration);
}

enum TicketStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  waitingOnUser('waiting_on_user', 'Waiting on User'),
  waitingOnThirdParty('waiting_on_third_party', 'Waiting on Third Party'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed'),
  reopened('reopened', 'Reopened');

  const TicketStatus(this.value, this.label);
  final String value;
  final String label;
  static TicketStatus fromString(String v) =>
      TicketStatus.values.firstWhere((e) => e.value == v, orElse: () => TicketStatus.open);
}

enum TicketPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent'),
  critical('critical', 'Critical');

  const TicketPriority(this.value, this.label);
  final String value;
  final String label;
  static TicketPriority fromString(String v) =>
      TicketPriority.values.firstWhere((e) => e.value == v, orElse: () => TicketPriority.medium);
}

enum TicketCategory {
  technical('technical', 'Technical'),
  billing('billing', 'Billing'),
  account('account', 'Account'),
  featureRequest('feature_request', 'Feature Request'),
  bugReport('bug_report', 'Bug Report'),
  general('general', 'General'),
  aiRelated('ai_related', 'AI Related'),
  security('security', 'Security');

  const TicketCategory(this.value, this.label);
  final String value;
  final String label;
  static TicketCategory fromString(String v) =>
      TicketCategory.values.firstWhere((e) => e.value == v, orElse: () => TicketCategory.general);
}

enum AIProviderStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  degraded('degraded', 'Degraded'),
  maintenance('maintenance', 'Maintenance'),
  suspended('suspended', 'Suspended');

  const AIProviderStatus(this.value, this.label);
  final String value;
  final String label;
  static AIProviderStatus fromString(String v) =>
      AIProviderStatus.values.firstWhere((e) => e.value == v, orElse: () => AIProviderStatus.active);
}

enum HealthStatus {
  healthy('healthy', 'Healthy'),
  degraded('degraded', 'Degraded'),
  unhealthy('unhealthy', 'Unhealthy'),
  down('down', 'Down'),
  maintenance('maintenance', 'Maintenance');

  const HealthStatus(this.value, this.label);
  final String value;
  final String label;
  static HealthStatus fromString(String v) =>
      HealthStatus.values.firstWhere((e) => e.value == v, orElse: () => HealthStatus.healthy);
}

enum MarketplaceStatus {
  pendingReview('pending_review', 'Pending Review'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  featured('featured', 'Featured'),
  archived('archived', 'Archived'),
  flagged('flagged', 'Flagged'),
  suspended('suspended', 'Suspended');

  const MarketplaceStatus(this.value, this.label);
  final String value;
  final String label;
  static MarketplaceStatus fromString(String v) =>
      MarketplaceStatus.values.firstWhere((e) => e.value == v, orElse: () => MarketplaceStatus.pendingReview);
}

enum MarketplaceContentType {
  resource('resource', 'Resource'),
  lessonNote('lesson_note', 'Lesson Note'),
  worksheet('worksheet', 'Worksheet'),
  questionBank('question_bank', 'Question Bank'),
  template('template', 'Template'),
  examFormat('exam_format', 'Exam Format'),
  video('video', 'Video'),
  document('document', 'Document');

  const MarketplaceContentType(this.value, this.label);
  final String value;
  final String label;
  static MarketplaceContentType fromString(String v) =>
      MarketplaceContentType.values.firstWhere((e) => e.value == v, orElse: () => MarketplaceContentType.resource);
}

enum FeatureFlagType {
  boolean('boolean', 'Boolean'),
  percentage('percentage', 'Percentage'),
  userSegment('user_segment', 'User Segment'),
  schoolSegment('school_segment', 'School Segment'),
  gradualRollout('gradual_rollout', 'Gradual Rollout');

  const FeatureFlagType(this.value, this.label);
  final String value;
  final String label;
  static FeatureFlagType fromString(String v) =>
      FeatureFlagType.values.firstWhere((e) => e.value == v, orElse: () => FeatureFlagType.boolean);
}

enum NotificationPriority {
  low('low', 'Low'),
  normal('normal', 'Normal'),
  high('high', 'High'),
  urgent('urgent', 'Urgent'),
  critical('critical', 'Critical');

  const NotificationPriority(this.value, this.label);
  final String value;
  final String label;
  static NotificationPriority fromString(String v) =>
      NotificationPriority.values.firstWhere((e) => e.value == v, orElse: () => NotificationPriority.normal);
}

enum NotificationCategory {
  paymentFailure('payment_failure', 'Payment Failure'),
  aiProviderIssue('ai_provider_issue', 'AI Provider Issue'),
  systemError('system_error', 'System Error'),
  securityAlert('security_alert', 'Security Alert'),
  newRegistration('new_registration', 'New Registration'),
  subscriptionExpiration('subscription_expiration', 'Subscription Expiration'),
  infrastructure('infrastructure', 'Infrastructure'),
  support('support', 'Support'),
  featureRelease('feature_release', 'Feature Release'),
  maintenance('maintenance', 'Maintenance'),
  reportReady('report_ready', 'Report Ready'),
  intelligence('intelligence', 'Intelligence');

  const NotificationCategory(this.value, this.label);
  final String value;
  final String label;
  static NotificationCategory fromString(String v) =>
      NotificationCategory.values.firstWhere((e) => e.value == v, orElse: () => NotificationCategory.systemError);
}

enum IntelligenceAlertType {
  churnPrediction('churn_prediction', 'Churn Prediction'),
  anomalyDetection('anomaly_detection', 'Anomaly Detection'),
  engagementDrop('engagement_drop', 'Engagement Drop'),
  upsellOpportunity('upsell_opportunity', 'Upsell Opportunity'),
  revenueForecast('revenue_forecast', 'Revenue Forecast'),
  costOptimization('cost_optimization', 'Cost Optimization'),
  infrastructureBottleneck('infrastructure_bottleneck', 'Infrastructure Bottleneck'),
  supportNeeded('support_needed', 'Support Needed'),
  unusualUsage('unusual_usage', 'Unusual Usage'),
  growthOpportunity('growth_opportunity', 'Growth Opportunity');

  const IntelligenceAlertType(this.value, this.label);
  final String value;
  final String label;
  static IntelligenceAlertType fromString(String v) =>
      IntelligenceAlertType.values.firstWhere((e) => e.value == v, orElse: () => IntelligenceAlertType.anomalyDetection);
}

enum IntelligenceSeverity {
  info('info', 'Info'),
  attention('attention', 'Attention'),
  warning('warning', 'Warning'),
  critical('critical', 'Critical');

  const IntelligenceSeverity(this.value, this.label);
  final String value;
  final String label;
  static IntelligenceSeverity fromString(String v) =>
      IntelligenceSeverity.values.firstWhere((e) => e.value == v, orElse: () => IntelligenceSeverity.attention);
}

enum ReportType {
  dailySummary('daily_summary', 'Daily Summary'),
  weeklySummary('weekly_summary', 'Weekly Summary'),
  monthlySummary('monthly_summary', 'Monthly Summary'),
  revenueReport('revenue_report', 'Revenue Report'),
  userAnalytics('user_analytics', 'User Analytics'),
  aiUsageReport('ai_usage_report', 'AI Usage Report'),
  churnAnalysis('churn_analysis', 'Churn Analysis'),
  schoolPerformance('school_performance', 'School Performance'),
  systemHealth('system_health', 'System Health'),
  securityAudit('security_audit', 'Security Audit'),
  custom('custom', 'Custom');

  const ReportType(this.value, this.label);
  final String value;
  final String label;
  static ReportType fromString(String v) =>
      ReportType.values.firstWhere((e) => e.value == v, orElse: () => ReportType.custom);
}

enum MaintenanceStatus {
  scheduled('scheduled', 'Scheduled'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const MaintenanceStatus(this.value, this.label);
  final String value;
  final String label;
  static MaintenanceStatus fromString(String v) =>
      MaintenanceStatus.values.firstWhere((e) => e.value == v, orElse: () => MaintenanceStatus.scheduled);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════════════

class PlatformSetting extends Equatable {
  const PlatformSetting({
    required this.id,
    required this.key,
    required this.value,
    required this.valueType,
    required this.scope,
    this.description,
    this.isEncrypted = false,
    this.isReadonly = false,
    this.defaultValue,
    this.validationRules,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String key;
  final Map<String, dynamic> value;
  final SettingValueType valueType;
  final SettingScope scope;
  final String? description;
  final bool isEncrypted;
  final bool isReadonly;
  final Map<String, dynamic>? defaultValue;
  final Map<String, dynamic>? validationRules;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlatformSetting copyWith({
    String? id, String? key, Map<String, dynamic>? value, SettingValueType? valueType,
    SettingScope? scope, String? description, bool? isEncrypted, bool? isReadonly,
    Map<String, dynamic>? defaultValue, Map<String, dynamic>? validationRules,
    String? updatedBy, DateTime? createdAt, DateTime? updatedAt,
  }) => PlatformSetting(
    id: id ?? this.id, key: key ?? this.key, value: value ?? this.value,
    valueType: valueType ?? this.valueType, scope: scope ?? this.scope,
    description: description ?? this.description, isEncrypted: isEncrypted ?? this.isEncrypted,
    isReadonly: isReadonly ?? this.isReadonly, defaultValue: defaultValue ?? this.defaultValue,
    validationRules: validationRules ?? this.validationRules, updatedBy: updatedBy ?? this.updatedBy,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, key, value, valueType, scope, description, isEncrypted, isReadonly, defaultValue, validationRules, updatedBy, createdAt, updatedAt];
}

class FeatureFlag extends Equatable {
  const FeatureFlag({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    required this.flagType,
    required this.value,
    this.targetSegments,
    this.schoolIds,
    this.userRoles,
    this.isActive = true,
    this.startsAt,
    this.expiresAt,
    this.rolloutPercentage = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String key;
  final String name;
  final String? description;
  final FeatureFlagType flagType;
  final Map<String, dynamic> value;
  final List<String>? targetSegments;
  final List<String>? schoolIds;
  final List<String>? userRoles;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final int rolloutPercentage;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureFlag copyWith({
    String? id, String? key, String? name, String? description, FeatureFlagType? flagType,
    Map<String, dynamic>? value, List<String>? targetSegments, List<String>? schoolIds,
    List<String>? userRoles, bool? isActive, DateTime? startsAt, DateTime? expiresAt,
    int? rolloutPercentage, String? createdBy, DateTime? createdAt, DateTime? updatedAt,
  }) => FeatureFlag(
    id: id ?? this.id, key: key ?? this.key, name: name ?? this.name,
    description: description ?? this.description, flagType: flagType ?? this.flagType,
    value: value ?? this.value, targetSegments: targetSegments ?? this.targetSegments,
    schoolIds: schoolIds ?? this.schoolIds, userRoles: userRoles ?? this.userRoles,
    isActive: isActive ?? this.isActive, startsAt: startsAt ?? this.startsAt,
    expiresAt: expiresAt ?? this.expiresAt, rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
    createdBy: createdBy ?? this.createdBy, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, key, name, description, flagType, value, targetSegments, schoolIds, userRoles, isActive, startsAt, expiresAt, rolloutPercentage, createdBy, createdAt, updatedAt];
}

class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    this.actorId,
    this.actorEmail,
    this.actorRole,
    required this.action,
    required this.category,
    required this.severity,
    this.resourceType,
    this.resourceId,
    this.schoolId,
    this.description,
    this.oldValues,
    this.newValues,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    this.requestId,
    this.durationMs,
    this.isSensitive = false,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String? actorEmail;
  final String? actorRole;
  final String action;
  final AuditCategory category;
  final AuditSeverity severity;
  final String? resourceType;
  final String? resourceId;
  final String? schoolId;
  final String? description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final String? requestId;
  final int? durationMs;
  final bool isSensitive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, actorId, action, category, severity, resourceType, resourceId, schoolId, createdAt];
}

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.reporterId,
    this.schoolId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.relatedResourceType,
    this.relatedResourceId,
    this.tags,
    this.attachments,
    this.resolutionNotes,
    this.firstResponseAt,
    this.resolvedAt,
    this.closedAt,
    this.satisfactionRating,
    this.satisfactionComment,
    this.isEscalated = false,
    this.escalatedAt,
    this.escalatedTo,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ticketNumber;
  final String reporterId;
  final String? schoolId;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedTo;
  final String? relatedResourceType;
  final String? relatedResourceId;
  final List<String>? tags;
  final List<Map<String, dynamic>>? attachments;
  final String? resolutionNotes;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final int? satisfactionRating;
  final String? satisfactionComment;
  final bool isEscalated;
  final DateTime? escalatedAt;
  final String? escalatedTo;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket copyWith({
    String? id, String? ticketNumber, String? reporterId, String? schoolId,
    String? subject, String? description, TicketCategory? category,
    TicketPriority? priority, TicketStatus? status, String? assignedTo,
    String? relatedResourceType, String? relatedResourceId, List<String>? tags,
    List<Map<String, dynamic>>? attachments, String? resolutionNotes,
    DateTime? firstResponseAt, DateTime? resolvedAt, DateTime? closedAt,
    int? satisfactionRating, String? satisfactionComment, bool? isEscalated,
    DateTime? escalatedAt, String? escalatedTo, DateTime? dueDate,
    DateTime? createdAt, DateTime? updatedAt,
  }) => SupportTicket(
    id: id ?? this.id, ticketNumber: ticketNumber ?? this.ticketNumber,
    reporterId: reporterId ?? this.reporterId, schoolId: schoolId ?? this.schoolId,
    subject: subject ?? this.subject, description: description ?? this.description,
    category: category ?? this.category, priority: priority ?? this.priority,
    status: status ?? this.status, assignedTo: assignedTo ?? this.assignedTo,
    relatedResourceType: relatedResourceType ?? this.relatedResourceType,
    relatedResourceId: relatedResourceId ?? this.relatedResourceId,
    tags: tags ?? this.tags, attachments: attachments ?? this.attachments,
    resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    firstResponseAt: firstResponseAt ?? this.firstResponseAt,
    resolvedAt: resolvedAt ?? this.resolvedAt, closedAt: closedAt ?? this.closedAt,
    satisfactionRating: satisfactionRating ?? this.satisfactionRating,
    satisfactionComment: satisfactionComment ?? this.satisfactionComment,
    isEscalated: isEscalated ?? this.isEscalated, escalatedAt: escalatedAt ?? this.escalatedAt,
    escalatedTo: escalatedTo ?? this.escalatedTo, dueDate: dueDate ?? this.dueDate,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, ticketNumber, reporterId, subject, category, priority, status, createdAt];
}

class TicketComment extends Equatable {
  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.content,
    this.isInternal = false,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ticketId;
  final String authorId;
  final String content;
  final bool isInternal;
  final List<Map<String, dynamic>>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, ticketId, authorId, content, isInternal, createdAt];
}

class AIProvider extends Equatable {
  const AIProvider({
    required this.id,
    required this.name,
    required this.slug,
    required this.providerType,
    required this.apiBaseUrl,
    this.apiKeyEncrypted,
    this.isDefault = false,
    this.isActive = true,
    required this.status,
    this.supportedModels,
    this.defaultModel,
    this.rateLimitPerMinute = 60,
    this.rateLimitPerDay = 10000,
    this.costPer1kInputTokens = 0,
    this.costPer1kOutputTokens = 0,
    this.monthlyBudget,
    this.currentMonthSpend = 0,
    this.priority = 0,
    this.failoverProviderId,
    this.healthCheckUrl,
    this.lastHealthCheckAt,
    this.configuration,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String providerType;
  final String apiBaseUrl;
  final String? apiKeyEncrypted;
  final bool isDefault;
  final bool isActive;
  final AIProviderStatus status;
  final List<String>? supportedModels;
  final String? defaultModel;
  final int rateLimitPerMinute;
  final int rateLimitPerDay;
  final double costPer1kInputTokens;
  final double costPer1kOutputTokens;
  final double? monthlyBudget;
  final double currentMonthSpend;
  final int priority;
  final String? failoverProviderId;
  final String? healthCheckUrl;
  final DateTime? lastHealthCheckAt;
  final Map<String, dynamic>? configuration;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get budgetUtilization => monthlyBudget != null && monthlyBudget! > 0
      ? (currentMonthSpend / monthlyBudget!) * 100 : 0;

  AIProvider copyWith({
    String? id, String? name, String? slug, String? providerType, String? apiBaseUrl,
    String? apiKeyEncrypted, bool? isDefault, bool? isActive, AIProviderStatus? status,
    List<String>? supportedModels, String? defaultModel, int? rateLimitPerMinute,
    int? rateLimitPerDay, double? costPer1kInputTokens, double? costPer1kOutputTokens,
    double? monthlyBudget, double? currentMonthSpend, int? priority,
    String? failoverProviderId, String? healthCheckUrl, DateTime? lastHealthCheckAt,
    Map<String, dynamic>? configuration, Map<String, dynamic>? metadata,
    String? createdBy, DateTime? createdAt, DateTime? updatedAt,
  }) => AIProvider(
    id: id ?? this.id, name: name ?? this.name, slug: slug ?? this.slug,
    providerType: providerType ?? this.providerType, apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    apiKeyEncrypted: apiKeyEncrypted ?? this.apiKeyEncrypted, isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive, status: status ?? this.status,
    supportedModels: supportedModels ?? this.supportedModels, defaultModel: defaultModel ?? this.defaultModel,
    rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
    rateLimitPerDay: rateLimitPerDay ?? this.rateLimitPerDay,
    costPer1kInputTokens: costPer1kInputTokens ?? this.costPer1kInputTokens,
    costPer1kOutputTokens: costPer1kOutputTokens ?? this.costPer1kOutputTokens,
    monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    currentMonthSpend: currentMonthSpend ?? this.currentMonthSpend,
    priority: priority ?? this.priority,
    failoverProviderId: failoverProviderId ?? this.failoverProviderId,
    healthCheckUrl: healthCheckUrl ?? this.healthCheckUrl,
    lastHealthCheckAt: lastHealthCheckAt ?? this.lastHealthCheckAt,
    configuration: configuration ?? this.configuration, metadata: metadata ?? this.metadata,
    createdBy: createdBy ?? this.createdBy, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, name, slug, providerType, status, isDefault, isActive, priority, createdAt];
}

class AIRequestLog extends Equatable {
  const AIRequestLog({
    required this.id,
    required this.providerId,
    this.userId,
    this.schoolId,
    required this.model,
    required this.requestType,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.cost = 0,
    this.latencyMs = 0,
    this.isSuccess = true,
    this.errorMessage,
    this.errorCode,
    this.requestMetadata,
    required this.createdAt,
  });

  final String id;
  final String providerId;
  final String? userId;
  final String? schoolId;
  final String model;
  final String requestType;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double cost;
  final int latencyMs;
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? requestMetadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, providerId, model, requestType, isSuccess, cost, createdAt];
}

class InfrastructureService extends Equatable {
  const InfrastructureService({
    required this.id,
    required this.serviceName,
    required this.serviceType,
    this.endpointUrl,
    required this.healthStatus,
    this.lastCheckAt,
    this.lastHealthyAt,
    this.responseTimeMs,
    this.uptimePercentage = 100,
    this.errorRate = 0,
    this.configuration,
    this.metadata,
    this.isCritical = false,
    this.alertThresholdResponseMs = 5000,
    this.alertThresholdErrorRate = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceName;
  final String serviceType;
  final String? endpointUrl;
  final HealthStatus healthStatus;
  final DateTime? lastCheckAt;
  final DateTime? lastHealthyAt;
  final int? responseTimeMs;
  final double uptimePercentage;
  final double errorRate;
  final Map<String, dynamic>? configuration;
  final Map<String, dynamic>? metadata;
  final bool isCritical;
  final int alertThresholdResponseMs;
  final double alertThresholdErrorRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAlerting => healthStatus == HealthStatus.unhealthy || healthStatus == HealthStatus.down
      || (responseTimeMs != null && responseTimeMs! > alertThresholdResponseMs)
      || errorRate > alertThresholdErrorRate;

  InfrastructureService copyWith({
    String? id, String? serviceName, String? serviceType, String? endpointUrl,
    HealthStatus? healthStatus, DateTime? lastCheckAt, DateTime? lastHealthyAt,
    int? responseTimeMs, double? uptimePercentage, double? errorRate,
    Map<String, dynamic>? configuration, Map<String, dynamic>? metadata,
    bool? isCritical, int? alertThresholdResponseMs, double? alertThresholdErrorRate,
    DateTime? createdAt, DateTime? updatedAt,
  }) => InfrastructureService(
    id: id ?? this.id, serviceName: serviceName ?? this.serviceName,
    serviceType: serviceType ?? this.serviceType, endpointUrl: endpointUrl ?? this.endpointUrl,
    healthStatus: healthStatus ?? this.healthStatus, lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    lastHealthyAt: lastHealthyAt ?? this.lastHealthyAt, responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    uptimePercentage: uptimePercentage ?? this.uptimePercentage, errorRate: errorRate ?? this.errorRate,
    configuration: configuration ?? this.configuration, metadata: metadata ?? this.metadata,
    isCritical: isCritical ?? this.isCritical,
    alertThresholdResponseMs: alertThresholdResponseMs ?? this.alertThresholdResponseMs,
    alertThresholdErrorRate: alertThresholdErrorRate ?? this.alertThresholdErrorRate,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, serviceName, serviceType, healthStatus, isCritical, createdAt];
}

class MarketplaceContent extends Equatable {
  const MarketplaceContent({
    required this.id,
    required this.authorId,
    this.schoolId,
    required this.title,
    required this.description,
    required this.contentType,
    required this.status,
    this.subject,
    this.classLevel,
    this.curriculum,
    this.tags,
    this.thumbnailUrl,
    this.contentUrls,
    this.price = 0,
    this.isFree = true,
    this.downloadCount = 0,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.featuredUntil,
    this.isFlagged = false,
    this.flagReason,
    this.flaggedBy,
    this.flaggedAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String? schoolId;
  final String title;
  final String description;
  final MarketplaceContentType contentType;
  final MarketplaceStatus status;
  final String? subject;
  final String? classLevel;
  final String? curriculum;
  final List<String>? tags;
  final String? thumbnailUrl;
  final List<String>? contentUrls;
  final double price;
  final bool isFree;
  final int downloadCount;
  final double ratingAverage;
  final int ratingCount;
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? featuredUntil;
  final bool isFlagged;
  final String? flagReason;
  final String? flaggedBy;
  final DateTime? flaggedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceContent copyWith({
    String? id, String? authorId, String? schoolId, String? title, String? description,
    MarketplaceContentType? contentType, MarketplaceStatus? status, String? subject,
    String? classLevel, String? curriculum, List<String>? tags, String? thumbnailUrl,
    List<String>? contentUrls, double? price, bool? isFree, int? downloadCount,
    double? ratingAverage, int? ratingCount, String? reviewNotes, String? reviewedBy,
    DateTime? reviewedAt, DateTime? featuredUntil, bool? isFlagged, String? flagReason,
    String? flaggedBy, DateTime? flaggedAt, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) => MarketplaceContent(
    id: id ?? this.id, authorId: authorId ?? this.authorId, schoolId: schoolId ?? this.schoolId,
    title: title ?? this.title, description: description ?? this.description,
    contentType: contentType ?? this.contentType, status: status ?? this.status,
    subject: subject ?? this.subject, classLevel: classLevel ?? this.classLevel,
    curriculum: curriculum ?? this.curriculum, tags: tags ?? this.tags,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl, contentUrls: contentUrls ?? this.contentUrls,
    price: price ?? this.price, isFree: isFree ?? this.isFree,
    downloadCount: downloadCount ?? this.downloadCount, ratingAverage: ratingAverage ?? this.ratingAverage,
    ratingCount: ratingCount ?? this.ratingCount, reviewNotes: reviewNotes ?? this.reviewNotes,
    reviewedBy: reviewedBy ?? this.reviewedBy, reviewedAt: reviewedAt ?? this.reviewedAt,
    featuredUntil: featuredUntil ?? this.featuredUntil, isFlagged: isFlagged ?? this.isFlagged,
    flagReason: flagReason ?? this.flagReason, flaggedBy: flaggedBy ?? this.flaggedBy,
    flaggedAt: flaggedAt ?? this.flaggedAt, metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, authorId, title, contentType, status, createdAt];
}

class PlatformNotification extends Equatable {
  const PlatformNotification({
    required this.id,
    this.recipientId,
    required this.category,
    required this.priority,
    required this.title,
    required this.message,
    this.actionUrl,
    this.actionLabel,
    this.isRead = false,
    this.readAt,
    this.isDismissed = false,
    this.dismissedAt,
    this.relatedEntityType,
    this.relatedEntityId,
    this.metadata,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String? recipientId;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? actionUrl;
  final String? actionLabel;
  final bool isRead;
  final DateTime? readAt;
  final bool isDismissed;
  final DateTime? dismissedAt;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final Map<String, dynamic>? metadata;
  final DateTime? expiresAt;
  final DateTime createdAt;

  PlatformNotification copyWith({
    String? id, String? recipientId, NotificationCategory? category,
    NotificationPriority? priority, String? title, String? message,
    String? actionUrl, String? actionLabel, bool? isRead, DateTime? readAt,
    bool? isDismissed, DateTime? dismissedAt, String? relatedEntityType,
    String? relatedEntityId, Map<String, dynamic>? metadata, DateTime? expiresAt,
    DateTime? createdAt,
  }) => PlatformNotification(
    id: id ?? this.id, recipientId: recipientId ?? this.recipientId,
    category: category ?? this.category, priority: priority ?? this.priority,
    title: title ?? this.title, message: message ?? this.message,
    actionUrl: actionUrl ?? this.actionUrl, actionLabel: actionLabel ?? this.actionLabel,
    isRead: isRead ?? this.isRead, readAt: readAt ?? this.readAt,
    isDismissed: isDismissed ?? this.isDismissed, dismissedAt: dismissedAt ?? this.dismissedAt,
    relatedEntityType: relatedEntityType ?? this.relatedEntityType,
    relatedEntityId: relatedEntityId ?? this.relatedEntityId,
    metadata: metadata ?? this.metadata, expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [id, recipientId, category, priority, title, isRead, createdAt];
}

class IntelligenceAlert extends Equatable {
  const IntelligenceAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.affectedEntityType,
    this.affectedEntityId,
    this.affectedSchoolId,
    this.predictedValue,
    this.predictedDate,
    this.confidenceScore,
    this.supportingData,
    this.recommendedActions,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.expiresAt,
    this.modelVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final IntelligenceAlertType alertType;
  final IntelligenceSeverity severity;
  final String title;
  final String description;
  final String? affectedEntityType;
  final String? affectedEntityId;
  final String? affectedSchoolId;
  final double? predictedValue;
  final DateTime? predictedDate;
  final double? confidenceScore;
  final Map<String, dynamic>? supportingData;
  final List<Map<String, dynamic>>? recommendedActions;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime? expiresAt;
  final String? modelVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  IntelligenceAlert copyWith({
    String? id, IntelligenceAlertType? alertType, IntelligenceSeverity? severity,
    String? title, String? description, String? affectedEntityType,
    String? affectedEntityId, String? affectedSchoolId, double? predictedValue,
    DateTime? predictedDate, double? confidenceScore,
    Map<String, dynamic>? supportingData, List<Map<String, dynamic>>? recommendedActions,
    bool? isAcknowledged, String? acknowledgedBy, DateTime? acknowledgedAt,
    bool? isResolved, String? resolvedBy, DateTime? resolvedAt, String? resolutionNotes,
    DateTime? expiresAt, String? modelVersion, DateTime? createdAt, DateTime? updatedAt,
  }) => IntelligenceAlert(
    id: id ?? this.id, alertType: alertType ?? this.alertType, severity: severity ?? this.severity,
    title: title ?? this.title, description: description ?? this.description,
    affectedEntityType: affectedEntityType ?? this.affectedEntityType,
    affectedEntityId: affectedEntityId ?? this.affectedEntityId,
    affectedSchoolId: affectedSchoolId ?? this.affectedSchoolId,
    predictedValue: predictedValue ?? this.predictedValue,
    predictedDate: predictedDate ?? this.predictedDate,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    supportingData: supportingData ?? this.supportingData,
    recommendedActions: recommendedActions ?? this.recommendedActions,
    isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    isResolved: isResolved ?? this.isResolved, resolvedBy: resolvedBy ?? this.resolvedBy,
    resolvedAt: resolvedAt ?? this.resolvedAt, resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    expiresAt: expiresAt ?? this.expiresAt, modelVersion: modelVersion ?? this.modelVersion,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, alertType, severity, title, isAcknowledged, isResolved, createdAt];
}

class SystemReport extends Equatable {
  const SystemReport({
    required this.id,
    required this.reportType,
    required this.title,
    this.description,
    required this.format,
    required this.status,
    this.parameters,
    this.fileUrl,
    this.fileSizeBytes,
    this.generatedBy,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.isScheduled = false,
    this.scheduleCron,
    this.nextRunAt,
    this.recipients,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ReportType reportType;
  final String title;
  final String? description;
  final String format;
  final String status;
  final Map<String, dynamic>? parameters;
  final String? fileUrl;
  final int? fileSizeBytes;
  final String? generatedBy;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final bool isScheduled;
  final String? scheduleCron;
  final DateTime? nextRunAt;
  final List<String>? recipients;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, reportType, title, status, createdAt];
}

class MaintenanceWindow extends Equatable {
  const MaintenanceWindow({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.affectedServices,
    required this.startAt,
    required this.endAt,
    this.actualStartAt,
    this.actualEndAt,
    this.isPlanned = true,
    this.notificationSent = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final MaintenanceStatus status;
  final List<String>? affectedServices;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final bool isPlanned;
  final bool notificationSent;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceWindow copyWith({
    String? id,
    String? title,
    String? description,
    MaintenanceStatus? status,
    List<String>? affectedServices,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? actualStartAt,
    DateTime? actualEndAt,
    bool? isPlanned,
    bool? notificationSent,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MaintenanceWindow(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        affectedServices: affectedServices ?? this.affectedServices,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        actualStartAt: actualStartAt ?? this.actualStartAt,
        actualEndAt: actualEndAt ?? this.actualEndAt,
        isPlanned: isPlanned ?? this.isPlanned,
        notificationSent: notificationSent ?? this.notificationSent,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, title, status, startAt, endAt, createdAt];
}

class ImpersonationSession extends Equatable {
  const ImpersonationSession({
    required this.id,
    required this.adminId,
    required this.targetUserId,
    required this.targetUserRole,
    this.targetSchoolId,
    required this.reason,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    this.endedAt,
    this.endReason,
    this.ipAddress,
    this.userAgent,
    this.actionsTaken,
    required this.createdAt,
  });

  final String id;
  final String adminId;
  final String targetUserId;
  final String targetUserRole;
  final String? targetSchoolId;
  final String reason;
  final String status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? endedAt;
  final String? endReason;
  final String? ipAddress;
  final String? userAgent;
  final List<Map<String, dynamic>>? actionsTaken;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, adminId, targetUserId, status, startedAt];
}

class DashboardMetrics extends Equatable {
  const DashboardMetrics({
    this.totalSchools = 0,
    this.totalTeachers = 0,
    this.totalStudents = 0,
    this.totalParents = 0,
    this.activeExams = 0,
    this.dailyActiveUsers = 0,
    this.monthlyActiveUsers = 0,
    this.aiRequestsToday = 0,
    this.revenueToday = 0,
    this.monthlyRevenue = 0,
    this.annualRevenue = 0,
    this.activeSubscriptions = 0,
    this.trialAccounts = 0,
    this.systemHealth = 'healthy',
    this.apiStatus = 'healthy',
    this.backgroundJobsPending = 0,
    this.backgroundJobsRunning = 0,
    this.recentActivities = const [],
    this.computedAt,
  });

  final int totalSchools;
  final int totalTeachers;
  final int totalStudents;
  final int totalParents;
  final int activeExams;
  final int dailyActiveUsers;
  final int monthlyActiveUsers;
  final int aiRequestsToday;
  final double revenueToday;
  final double monthlyRevenue;
  final double annualRevenue;
  final int activeSubscriptions;
  final int trialAccounts;
  final String systemHealth;
  final String apiStatus;
  final int backgroundJobsPending;
  final int backgroundJobsRunning;
  final List<Map<String, dynamic>> recentActivities;
  final DateTime? computedAt;

  @override
  List<Object?> get props => [totalSchools, totalTeachers, totalStudents, dailyActiveUsers, revenueToday, monthlyRevenue, activeSubscriptions, systemHealth];
}

class SchoolManagementDetail extends Equatable {
  const SchoolManagementDetail({
    required this.id,
    required this.name,
    this.domain,
    this.logoUrl,
    this.isActive = true,
    this.isVerified = false,
    this.subscriptionStatus,
    this.studentCount = 0,
    this.teacherCount = 0,
    this.storageUsedMb = 0,
    this.storageLimitMb = 0,
    this.studentLimit = 0,
    this.teacherLimit = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? domain;
  final String? logoUrl;
  final bool isActive;
  final bool isVerified;
  final String? subscriptionStatus;
  final int studentCount;
  final int teacherCount;
  final double storageUsedMb;
  final double storageLimitMb;
  final int studentLimit;
  final int teacherLimit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get storageUtilization => storageLimitMb > 0 ? (storageUsedMb / storageLimitMb) * 100 : 0;

  @override
  List<Object?> get props => [id, name, isActive, isVerified, subscriptionStatus, studentCount, teacherCount];
}

class UserManagementDetail extends Equatable {
  const UserManagementDetail({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.schoolId,
    this.schoolName,
    this.isActive = true,
    this.isEmailVerified = false,
    this.lastLoginAt,
    this.loginCount = 0,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? schoolId;
  final String? schoolName;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;
  final int loginCount;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, email, fullName, role, isActive, schoolId];
}

class RevenueAnalytics extends Equatable {
  const RevenueAnalytics({
    this.totalRevenue = 0,
    this.monthlyRecurringRevenue = 0,
    this.averageRevenuePerUser = 0,
    this.averageRevenuePerSchool = 0,
    this.churnRate = 0,
    this.growthRate = 0,
    this.failedPayments = 0,
    this.refundsThisMonth = 0,
    this.pendingInvoices = 0,
    this.revenueByMonth = const [],
    this.revenueByBillingModel = const {},
  });

  final double totalRevenue;
  final double monthlyRecurringRevenue;
  final double averageRevenuePerUser;
  final double averageRevenuePerSchool;
  final double churnRate;
  final double growthRate;
  final int failedPayments;
  final double refundsThisMonth;
  final int pendingInvoices;
  final List<Map<String, dynamic>> revenueByMonth;
  final Map<String, dynamic> revenueByBillingModel;

  @override
  List<Object?> get props => [totalRevenue, monthlyRecurringRevenue, churnRate, growthRate];
}

class LoginMonitoringEntry extends Equatable {
  const LoginMonitoringEntry({
    required this.id,
    this.userId,
    this.email,
    this.role,
    this.schoolId,
    required this.isSuccess,
    this.failureReason,
    this.ipAddress,
    this.userAgent,
    this.deviceFingerprint,
    this.country,
    this.city,
    this.sessionId,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String? email;
  final String? role;
  final String? schoolId;
  final bool isSuccess;
  final String? failureReason;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceFingerprint;
  final String? country;
  final String? city;
  final String? sessionId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, isSuccess, ipAddress, createdAt];
}

class ActiveSession extends Equatable {
  const ActiveSession({
    required this.id,
    required this.userId,
    required this.sessionTokenHash,
    this.deviceInfo,
    this.ipAddress,
    this.userAgent,
    this.country,
    this.city,
    this.isCurrent = false,
    required this.lastActivityAt,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String sessionTokenHash;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  final String? country;
  final String? city;
  final bool isCurrent;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, sessionTokenHash, isCurrent, lastActivityAt];
}

class PlatformPolicy extends Equatable {
  const PlatformPolicy({
    required this.id,
    required this.policyKey,
    required this.title,
    required this.content,
    this.version = 1,
    this.isActive = true,
    required this.effectiveDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String policyKey;
  final String title;
  final String content;
  final int version;
  final bool isActive;
  final DateTime effectiveDate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, policyKey, title, version, isActive];
}

class EmailTemplate extends Equatable {
  const EmailTemplate({
    required this.id,
    required this.templateKey,
    required this.name,
    required this.subject,
    required this.htmlBody,
    this.textBody,
    this.category,
    this.variables,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String templateKey;
  final String name;
  final String subject;
  final String htmlBody;
  final String? textBody;
  final String? category;
  final List<String>? variables;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, templateKey, name, isActive];
}
