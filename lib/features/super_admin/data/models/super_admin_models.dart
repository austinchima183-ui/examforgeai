import '../../domain/entities/super_admin_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Platform Setting Model
// ═══════════════════════════════════════════════════════════════════════════════

class PlatformSettingModel {
  const PlatformSettingModel({
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
  final String valueType;
  final String scope;
  final String? description;
  final bool isEncrypted;
  final bool isReadonly;
  final Map<String, dynamic>? defaultValue;
  final Map<String, dynamic>? validationRules;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PlatformSettingModel.fromJson(Map<String, dynamic> json) => PlatformSettingModel(
    id: json['id'] as String,
    key: json['key'] as String,
    value: (json['value'] as Map<String, dynamic>?) ?? {},
    valueType: json['value_type'] as String? ?? json['valueType'] as String? ?? 'string',
    scope: json['scope'] as String? ?? 'global',
    description: json['description'] as String?,
    isEncrypted: json['is_encrypted'] as bool? ?? json['isEncrypted'] as bool? ?? false,
    isReadonly: json['is_readonly'] as bool? ?? json['isReadonly'] as bool? ?? false,
    defaultValue: (json['default_value'] as Map<String, dynamic>?) ?? (json['defaultValue'] as Map<String, dynamic>?),
    validationRules: (json['validation_rules'] as Map<String, dynamic>?) ?? (json['validationRules'] as Map<String, dynamic>?),
    updatedBy: json['updated_by'] as String? ?? json['updatedBy'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'key': key, 'value': value, 'value_type': valueType,
    'scope': scope, 'description': description, 'is_encrypted': isEncrypted,
    'is_readonly': isReadonly, 'default_value': defaultValue,
    'validation_rules': validationRules, 'updated_by': updatedBy,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  factory PlatformSettingModel.fromEntity(PlatformSetting e) => PlatformSettingModel(
    id: e.id, key: e.key, value: e.value, valueType: e.valueType.value,
    scope: e.scope.value, description: e.description, isEncrypted: e.isEncrypted,
    isReadonly: e.isReadonly, defaultValue: e.defaultValue,
    validationRules: e.validationRules, updatedBy: e.updatedBy,
    createdAt: e.createdAt, updatedAt: e.updatedAt,
  );

  PlatformSetting toEntity() => PlatformSetting(
    id: id, key: key, value: value, valueType: SettingValueType.fromString(valueType),
    scope: SettingScope.fromString(scope), description: description, isEncrypted: isEncrypted,
    isReadonly: isReadonly, defaultValue: defaultValue, validationRules: validationRules,
    updatedBy: updatedBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Feature Flag Model
// ═══════════════════════════════════════════════════════════════════════════════

class FeatureFlagModel {
  const FeatureFlagModel({
    required this.id, required this.key, required this.name, this.description,
    required this.flagType, required this.value, this.targetSegments,
    this.schoolIds, this.userRoles, this.isActive = true, this.startsAt,
    this.expiresAt, this.rolloutPercentage = 0, this.createdBy,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String key; final String name; final String? description;
  final String flagType; final Map<String, dynamic> value;
  final List<String>? targetSegments; final List<String>? schoolIds;
  final List<String>? userRoles; final bool isActive;
  final DateTime? startsAt; final DateTime? expiresAt; final int rolloutPercentage;
  final String? createdBy; final DateTime createdAt; final DateTime updatedAt;

  factory FeatureFlagModel.fromJson(Map<String, dynamic> json) => FeatureFlagModel(
    id: json['id'] as String, key: json['key'] as String, name: json['name'] as String,
    description: json['description'] as String?,
    flagType: json['flag_type'] as String? ?? json['flagType'] as String? ?? 'boolean',
    value: (json['value'] as Map<String, dynamic>?) ?? {},
    targetSegments: (json['target_segments'] as List?)?.cast<String>() ?? (json['targetSegments'] as List?)?.cast<String>(),
    schoolIds: (json['school_ids'] as List?)?.cast<String>() ?? (json['schoolIds'] as List?)?.cast<String>(),
    userRoles: (json['user_roles'] as List?)?.cast<String>() ?? (json['userRoles'] as List?)?.cast<String>(),
    isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at'] as String) : null,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    rolloutPercentage: json['rollout_percentage'] as int? ?? json['rolloutPercentage'] as int? ?? 0,
    createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'key': key, 'name': name, 'description': description,
    'flag_type': flagType, 'value': value, 'target_segments': targetSegments,
    'school_ids': schoolIds, 'user_roles': userRoles, 'is_active': isActive,
    'starts_at': startsAt?.toIso8601String(), 'expires_at': expiresAt?.toIso8601String(),
    'rollout_percentage': rolloutPercentage, 'created_by': createdBy,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  factory FeatureFlagModel.fromEntity(FeatureFlag e) => FeatureFlagModel(
    id: e.id, key: e.key, name: e.name, description: e.description,
    flagType: e.flagType.value, value: e.value, targetSegments: e.targetSegments,
    schoolIds: e.schoolIds, userRoles: e.userRoles, isActive: e.isActive,
    startsAt: e.startsAt, expiresAt: e.expiresAt, rolloutPercentage: e.rolloutPercentage,
    createdBy: e.createdBy, createdAt: e.createdAt, updatedAt: e.updatedAt,
  );

  FeatureFlag toEntity() => FeatureFlag(
    id: id, key: key, name: name, description: description,
    flagType: FeatureFlagType.fromString(flagType), value: value,
    targetSegments: targetSegments, schoolIds: schoolIds, userRoles: userRoles,
    isActive: isActive, startsAt: startsAt, expiresAt: expiresAt,
    rolloutPercentage: rolloutPercentage, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Audit Log Model
// ═══════════════════════════════════════════════════════════════════════════════

class AuditLogModel {
  const AuditLogModel({
    required this.id, this.actorId, this.actorEmail, this.actorRole,
    required this.action, required this.category, required this.severity,
    this.resourceType, this.resourceId, this.schoolId, this.description,
    this.oldValues, this.newValues, this.metadata, this.ipAddress,
    this.userAgent, this.sessionId, this.requestId, this.durationMs,
    this.isSensitive = false, required this.createdAt,
  });
  final String id; final String? actorId; final String? actorEmail; final String? actorRole;
  final String action; final String category; final String severity;
  final String? resourceType; final String? resourceId; final String? schoolId;
  final String? description; final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues; final Map<String, dynamic>? metadata;
  final String? ipAddress; final String? userAgent; final String? sessionId;
  final String? requestId; final int? durationMs; final bool isSensitive;
  final DateTime createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
    id: json['id'] as String, actorId: json['actor_id'] as String? ?? json['actorId'] as String?,
    actorEmail: json['actor_email'] as String? ?? json['actorEmail'] as String?,
    actorRole: json['actor_role'] as String? ?? json['actorRole'] as String?,
    action: json['action'] as String, category: json['category'] as String? ?? 'system_configuration',
    severity: json['severity'] as String? ?? 'info', resourceType: json['resource_type'] as String?,
    resourceId: json['resource_id'] as String?, schoolId: json['school_id'] as String?,
    description: json['description'] as String?,
    oldValues: json['old_values'] as Map<String, dynamic>?, newValues: json['new_values'] as Map<String, dynamic>?,
    metadata: json['metadata'] as Map<String, dynamic>?, ipAddress: json['ip_address'] as String?,
    userAgent: json['user_agent'] as String?, sessionId: json['session_id'] as String?,
    requestId: json['request_id'] as String?, durationMs: json['duration_ms'] as int?,
    isSensitive: json['is_sensitive'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'actor_id': actorId, 'actor_email': actorEmail, 'actor_role': actorRole,
    'action': action, 'category': category, 'severity': severity,
    'resource_type': resourceType, 'resource_id': resourceId, 'school_id': schoolId,
    'description': description, 'old_values': oldValues, 'new_values': newValues,
    'metadata': metadata, 'ip_address': ipAddress, 'user_agent': userAgent,
    'session_id': sessionId, 'request_id': requestId, 'duration_ms': durationMs,
    'is_sensitive': isSensitive, 'created_at': createdAt.toIso8601String(),
  };

  AuditLog toEntity() => AuditLog(
    id: id, actorId: actorId, actorEmail: actorEmail, actorRole: actorRole,
    action: action, category: AuditCategory.fromString(category), severity: AuditSeverity.fromString(severity),
    resourceType: resourceType, resourceId: resourceId, schoolId: schoolId,
    description: description, oldValues: oldValues, newValues: newValues, metadata: metadata,
    ipAddress: ipAddress, userAgent: userAgent, sessionId: sessionId, requestId: requestId,
    durationMs: durationMs, isSensitive: isSensitive, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Support Ticket Model
// ═══════════════════════════════════════════════════════════════════════════════

class SupportTicketModel {
  const SupportTicketModel({
    required this.id, required this.ticketNumber, required this.reporterId,
    this.schoolId, required this.subject, required this.description,
    required this.category, required this.priority, required this.status,
    this.assignedTo, this.relatedResourceType, this.relatedResourceId,
    this.tags, this.attachments, this.resolutionNotes, this.firstResponseAt,
    this.resolvedAt, this.closedAt, this.satisfactionRating, this.satisfactionComment,
    this.isEscalated = false, this.escalatedAt, this.escalatedTo, this.dueDate,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String ticketNumber; final String reporterId; final String? schoolId;
  final String subject; final String description; final String category; final String priority;
  final String status; final String? assignedTo; final String? relatedResourceType;
  final String? relatedResourceId; final List<String>? tags;
  final List<Map<String, dynamic>>? attachments; final String? resolutionNotes;
  final DateTime? firstResponseAt; final DateTime? resolvedAt; final DateTime? closedAt;
  final int? satisfactionRating; final String? satisfactionComment; final bool isEscalated;
  final DateTime? escalatedAt; final String? escalatedTo; final DateTime? dueDate;
  final DateTime createdAt; final DateTime updatedAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) => SupportTicketModel(
    id: json['id'] as String, ticketNumber: json['ticket_number'] as String? ?? json['ticketNumber'] as String? ?? '',
    reporterId: json['reporter_id'] as String, schoolId: json['school_id'] as String?,
    subject: json['subject'] as String, description: json['description'] as String,
    category: json['category'] as String? ?? 'general', priority: json['priority'] as String? ?? 'medium',
    status: json['status'] as String? ?? 'open', assignedTo: json['assigned_to'] as String?,
    relatedResourceType: json['related_resource_type'] as String?, relatedResourceId: json['related_resource_id'] as String?,
    tags: (json['tags'] as List?)?.cast<String>(), attachments: (json['attachments'] as List?)?.cast<Map<String, dynamic>>(),
    resolutionNotes: json['resolution_notes'] as String?,
    firstResponseAt: json['first_response_at'] != null ? DateTime.parse(json['first_response_at'] as String) : null,
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
    satisfactionRating: json['satisfaction_rating'] as int?, satisfactionComment: json['satisfaction_comment'] as String?,
    isEscalated: json['is_escalated'] as bool? ?? false,
    escalatedAt: json['escalated_at'] != null ? DateTime.parse(json['escalated_at'] as String) : null,
    escalatedTo: json['escalated_to'] as String?,
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'ticket_number': ticketNumber, 'reporter_id': reporterId,
    'school_id': schoolId, 'subject': subject, 'description': description,
    'category': category, 'priority': priority, 'status': status,
    'assigned_to': assignedTo, 'related_resource_type': relatedResourceType,
    'related_resource_id': relatedResourceId, 'tags': tags, 'attachments': attachments,
    'resolution_notes': resolutionNotes, 'first_response_at': firstResponseAt?.toIso8601String(),
    'resolved_at': resolvedAt?.toIso8601String(), 'closed_at': closedAt?.toIso8601String(),
    'satisfaction_rating': satisfactionRating, 'satisfaction_comment': satisfactionComment,
    'is_escalated': isEscalated, 'escalated_at': escalatedAt?.toIso8601String(),
    'escalated_to': escalatedTo, 'due_date': dueDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  SupportTicket toEntity() => SupportTicket(
    id: id, ticketNumber: ticketNumber, reporterId: reporterId, schoolId: schoolId,
    subject: subject, description: description, category: TicketCategory.fromString(category),
    priority: TicketPriority.fromString(priority), status: TicketStatus.fromString(status),
    assignedTo: assignedTo, relatedResourceType: relatedResourceType, relatedResourceId: relatedResourceId,
    tags: tags, attachments: attachments, resolutionNotes: resolutionNotes,
    firstResponseAt: firstResponseAt, resolvedAt: resolvedAt, closedAt: closedAt,
    satisfactionRating: satisfactionRating, satisfactionComment: satisfactionComment,
    isEscalated: isEscalated, escalatedAt: escalatedAt, escalatedTo: escalatedTo,
    dueDate: dueDate, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ticket Comment Model
// ═══════════════════════════════════════════════════════════════════════════════

class TicketCommentModel {
  const TicketCommentModel({
    required this.id, required this.ticketId, required this.authorId,
    required this.content, this.isInternal = false, this.attachments,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String ticketId; final String authorId; final String content;
  final bool isInternal; final List<Map<String, dynamic>>? attachments;
  final DateTime createdAt; final DateTime updatedAt;

  factory TicketCommentModel.fromJson(Map<String, dynamic> json) => TicketCommentModel(
    id: json['id'] as String, ticketId: json['ticket_id'] as String,
    authorId: json['author_id'] as String, content: json['content'] as String,
    isInternal: json['is_internal'] as bool? ?? false,
    attachments: (json['attachments'] as List?)?.cast<Map<String, dynamic>>(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'ticket_id': ticketId, 'author_id': authorId, 'content': content,
    'is_internal': isInternal, 'attachments': attachments,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  TicketComment toEntity() => TicketComment(
    id: id, ticketId: ticketId, authorId: authorId, content: content,
    isInternal: isInternal, attachments: attachments, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI Provider Model
// ═══════════════════════════════════════════════════════════════════════════════

class AIProviderModel {
  const AIProviderModel({
    required this.id, required this.name, required this.slug, required this.providerType,
    required this.apiBaseUrl, this.apiKeyEncrypted, this.isDefault = false,
    this.isActive = true, required this.status, this.supportedModels, this.defaultModel,
    this.rateLimitPerMinute = 60, this.rateLimitPerDay = 10000,
    this.costPer1kInputTokens = 0, this.costPer1kOutputTokens = 0,
    this.monthlyBudget, this.currentMonthSpend = 0, this.priority = 0,
    this.failoverProviderId, this.healthCheckUrl, this.lastHealthCheckAt,
    this.configuration, this.metadata, this.createdBy,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String name; final String slug; final String providerType;
  final String apiBaseUrl; final String? apiKeyEncrypted; final bool isDefault;
  final bool isActive; final String status; final List<String>? supportedModels;
  final String? defaultModel; final int rateLimitPerMinute; final int rateLimitPerDay;
  final double costPer1kInputTokens; final double costPer1kOutputTokens;
  final double? monthlyBudget; final double currentMonthSpend; final int priority;
  final String? failoverProviderId; final String? healthCheckUrl;
  final DateTime? lastHealthCheckAt; final Map<String, dynamic>? configuration;
  final Map<String, dynamic>? metadata; final String? createdBy;
  final DateTime createdAt; final DateTime updatedAt;

  factory AIProviderModel.fromJson(Map<String, dynamic> json) => AIProviderModel(
    id: json['id'] as String, name: json['name'] as String, slug: json['slug'] as String,
    providerType: json['provider_type'] as String, apiBaseUrl: json['api_base_url'] as String,
    apiKeyEncrypted: json['api_key_encrypted'] as String?,
    isDefault: json['is_default'] as bool? ?? false, isActive: json['is_active'] as bool? ?? true,
    status: json['status'] as String? ?? 'active',
    supportedModels: (json['supported_models'] as List?)?.cast<String>(),
    defaultModel: json['default_model'] as String?,
    rateLimitPerMinute: json['rate_limit_per_minute'] as int? ?? 60,
    rateLimitPerDay: json['rate_limit_per_day'] as int? ?? 10000,
    costPer1kInputTokens: (json['cost_per_1k_input_tokens'] as num?)?.toDouble() ?? 0,
    costPer1kOutputTokens: (json['cost_per_1k_output_tokens'] as num?)?.toDouble() ?? 0,
    monthlyBudget: (json['monthly_budget'] as num?)?.toDouble(),
    currentMonthSpend: (json['current_month_spend'] as num?)?.toDouble() ?? 0,
    priority: json['priority'] as int? ?? 0, failoverProviderId: json['failover_provider_id'] as String?,
    healthCheckUrl: json['health_check_url'] as String?,
    lastHealthCheckAt: json['last_health_check_at'] != null ? DateTime.parse(json['last_health_check_at'] as String) : null,
    configuration: json['configuration'] as Map<String, dynamic>?, metadata: json['metadata'] as Map<String, dynamic>?,
    createdBy: json['created_by'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'slug': slug, 'provider_type': providerType,
    'api_base_url': apiBaseUrl, 'api_key_encrypted': apiKeyEncrypted,
    'is_default': isDefault, 'is_active': isActive, 'status': status,
    'supported_models': supportedModels, 'default_model': defaultModel,
    'rate_limit_per_minute': rateLimitPerMinute, 'rate_limit_per_day': rateLimitPerDay,
    'cost_per_1k_input_tokens': costPer1kInputTokens, 'cost_per_1k_output_tokens': costPer1kOutputTokens,
    'monthly_budget': monthlyBudget, 'current_month_spend': currentMonthSpend,
    'priority': priority, 'failover_provider_id': failoverProviderId,
    'health_check_url': healthCheckUrl, 'last_health_check_at': lastHealthCheckAt?.toIso8601String(),
    'configuration': configuration, 'metadata': metadata, 'created_by': createdBy,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  factory AIProviderModel.fromEntity(AIProvider e) => AIProviderModel(
    id: e.id, name: e.name, slug: e.slug, providerType: e.providerType,
    apiBaseUrl: e.apiBaseUrl, apiKeyEncrypted: e.apiKeyEncrypted, isDefault: e.isDefault,
    isActive: e.isActive, status: e.status.value, supportedModels: e.supportedModels,
    defaultModel: e.defaultModel, rateLimitPerMinute: e.rateLimitPerMinute,
    rateLimitPerDay: e.rateLimitPerDay, costPer1kInputTokens: e.costPer1kInputTokens,
    costPer1kOutputTokens: e.costPer1kOutputTokens, monthlyBudget: e.monthlyBudget,
    currentMonthSpend: e.currentMonthSpend, priority: e.priority,
    failoverProviderId: e.failoverProviderId, healthCheckUrl: e.healthCheckUrl,
    lastHealthCheckAt: e.lastHealthCheckAt, configuration: e.configuration,
    metadata: e.metadata, createdBy: e.createdBy, createdAt: e.createdAt, updatedAt: e.updatedAt,
  );

  AIProvider toEntity() => AIProvider(
    id: id, name: name, slug: slug, providerType: providerType,
    apiBaseUrl: apiBaseUrl, apiKeyEncrypted: apiKeyEncrypted, isDefault: isDefault,
    isActive: isActive, status: AIProviderStatus.fromString(status),
    supportedModels: supportedModels, defaultModel: defaultModel,
    rateLimitPerMinute: rateLimitPerMinute, rateLimitPerDay: rateLimitPerDay,
    costPer1kInputTokens: costPer1kInputTokens, costPer1kOutputTokens: costPer1kOutputTokens,
    monthlyBudget: monthlyBudget, currentMonthSpend: currentMonthSpend, priority: priority,
    failoverProviderId: failoverProviderId, healthCheckUrl: healthCheckUrl,
    lastHealthCheckAt: lastHealthCheckAt, configuration: configuration,
    metadata: metadata, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI Request Log Model
// ═══════════════════════════════════════════════════════════════════════════════

class AIRequestLogModel {
  const AIRequestLogModel({
    required this.id, required this.providerId, this.userId, this.schoolId,
    required this.model, required this.requestType, this.inputTokens = 0,
    this.outputTokens = 0, this.totalTokens = 0, this.cost = 0,
    this.latencyMs = 0, this.isSuccess = true, this.errorMessage,
    this.errorCode, this.requestMetadata, required this.createdAt,
  });
  final String id; final String providerId; final String? userId; final String? schoolId;
  final String model; final String requestType; final int inputTokens; final int outputTokens;
  final int totalTokens; final double cost; final int latencyMs; final bool isSuccess;
  final String? errorMessage; final String? errorCode; final Map<String, dynamic>? requestMetadata;
  final DateTime createdAt;

  factory AIRequestLogModel.fromJson(Map<String, dynamic> json) => AIRequestLogModel(
    id: json['id'] as String, providerId: json['provider_id'] as String,
    userId: json['user_id'] as String?, schoolId: json['school_id'] as String?,
    model: json['model'] as String, requestType: json['request_type'] as String,
    inputTokens: json['input_tokens'] as int? ?? 0, outputTokens: json['output_tokens'] as int? ?? 0,
    totalTokens: json['total_tokens'] as int? ?? 0, cost: (json['cost'] as num?)?.toDouble() ?? 0,
    latencyMs: json['latency_ms'] as int? ?? 0, isSuccess: json['is_success'] as bool? ?? true,
    errorMessage: json['error_message'] as String?, errorCode: json['error_code'] as String?,
    requestMetadata: json['request_metadata'] as Map<String, dynamic>?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'provider_id': providerId, 'user_id': userId, 'school_id': schoolId,
    'model': model, 'request_type': requestType, 'input_tokens': inputTokens,
    'output_tokens': outputTokens, 'total_tokens': totalTokens, 'cost': cost,
    'latency_ms': latencyMs, 'is_success': isSuccess, 'error_message': errorMessage,
    'error_code': errorCode, 'request_metadata': requestMetadata,
    'created_at': createdAt.toIso8601String(),
  };

  AIRequestLog toEntity() => AIRequestLog(
    id: id, providerId: providerId, userId: userId, schoolId: schoolId,
    model: model, requestType: requestType, inputTokens: inputTokens,
    outputTokens: outputTokens, totalTokens: totalTokens, cost: cost,
    latencyMs: latencyMs, isSuccess: isSuccess, errorMessage: errorMessage,
    errorCode: errorCode, requestMetadata: requestMetadata, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Infrastructure Service Model
// ═══════════════════════════════════════════════════════════════════════════════

class InfrastructureServiceModel {
  const InfrastructureServiceModel({
    required this.id, required this.serviceName, required this.serviceType,
    this.endpointUrl, required this.healthStatus, this.lastCheckAt,
    this.lastHealthyAt, this.responseTimeMs, this.uptimePercentage = 100,
    this.errorRate = 0, this.configuration, this.metadata, this.isCritical = false,
    this.alertThresholdResponseMs = 5000, this.alertThresholdErrorRate = 5,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String serviceName; final String serviceType;
  final String? endpointUrl; final String healthStatus; final DateTime? lastCheckAt;
  final DateTime? lastHealthyAt; final int? responseTimeMs; final double uptimePercentage;
  final double errorRate; final Map<String, dynamic>? configuration;
  final Map<String, dynamic>? metadata; final bool isCritical;
  final int alertThresholdResponseMs; final double alertThresholdErrorRate;
  final DateTime createdAt; final DateTime updatedAt;

  factory InfrastructureServiceModel.fromJson(Map<String, dynamic> json) => InfrastructureServiceModel(
    id: json['id'] as String, serviceName: json['service_name'] as String,
    serviceType: json['service_type'] as String, endpointUrl: json['endpoint_url'] as String?,
    healthStatus: json['health_status'] as String? ?? 'healthy',
    lastCheckAt: json['last_check_at'] != null ? DateTime.parse(json['last_check_at'] as String) : null,
    lastHealthyAt: json['last_healthy_at'] != null ? DateTime.parse(json['last_healthy_at'] as String) : null,
    responseTimeMs: json['response_time_ms'] as int?,
    uptimePercentage: (json['uptime_percentage'] as num?)?.toDouble() ?? 100,
    errorRate: (json['error_rate'] as num?)?.toDouble() ?? 0,
    configuration: json['configuration'] as Map<String, dynamic>?, metadata: json['metadata'] as Map<String, dynamic>?,
    isCritical: json['is_critical'] as bool? ?? false,
    alertThresholdResponseMs: json['alert_threshold_response_ms'] as int? ?? 5000,
    alertThresholdErrorRate: (json['alert_threshold_error_rate'] as num?)?.toDouble() ?? 5.0,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'service_name': serviceName, 'service_type': serviceType,
    'endpoint_url': endpointUrl, 'health_status': healthStatus,
    'last_check_at': lastCheckAt?.toIso8601String(), 'last_healthy_at': lastHealthyAt?.toIso8601String(),
    'response_time_ms': responseTimeMs, 'uptime_percentage': uptimePercentage,
    'error_rate': errorRate, 'configuration': configuration, 'metadata': metadata,
    'is_critical': isCritical, 'alert_threshold_response_ms': alertThresholdResponseMs,
    'alert_threshold_error_rate': alertThresholdErrorRate,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  InfrastructureService toEntity() => InfrastructureService(
    id: id, serviceName: serviceName, serviceType: serviceType,
    endpointUrl: endpointUrl, healthStatus: HealthStatus.fromString(healthStatus),
    lastCheckAt: lastCheckAt, lastHealthyAt: lastHealthyAt, responseTimeMs: responseTimeMs,
    uptimePercentage: uptimePercentage, errorRate: errorRate, configuration: configuration,
    metadata: metadata, isCritical: isCritical, alertThresholdResponseMs: alertThresholdResponseMs,
    alertThresholdErrorRate: alertThresholdErrorRate, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Marketplace Content Model
// ═══════════════════════════════════════════════════════════════════════════════

class MarketplaceContentModel {
  const MarketplaceContentModel({
    required this.id, required this.authorId, this.schoolId, required this.title,
    required this.description, required this.contentType, required this.status,
    this.subject, this.classLevel, this.curriculum, this.tags, this.thumbnailUrl,
    this.contentUrls, this.price = 0, this.isFree = true, this.downloadCount = 0,
    this.ratingAverage = 0, this.ratingCount = 0, this.reviewNotes, this.reviewedBy,
    this.reviewedAt, this.featuredUntil, this.isFlagged = false, this.flagReason,
    this.flaggedBy, this.flaggedAt, this.metadata, required this.createdAt, required this.updatedAt,
  });
  final String id; final String authorId; final String? schoolId; final String title;
  final String description; final String contentType; final String status;
  final String? subject; final String? classLevel; final String? curriculum;
  final List<String>? tags; final String? thumbnailUrl; final List<String>? contentUrls;
  final double price; final bool isFree; final int downloadCount; final double ratingAverage;
  final int ratingCount; final String? reviewNotes; final String? reviewedBy;
  final DateTime? reviewedAt; final DateTime? featuredUntil; final bool isFlagged;
  final String? flagReason; final String? flaggedBy; final DateTime? flaggedAt;
  final Map<String, dynamic>? metadata; final DateTime createdAt; final DateTime updatedAt;

  factory MarketplaceContentModel.fromJson(Map<String, dynamic> json) => MarketplaceContentModel(
    id: json['id'] as String, authorId: json['author_id'] as String, schoolId: json['school_id'] as String?,
    title: json['title'] as String, description: json['description'] as String,
    contentType: json['content_type'] as String? ?? 'resource', status: json['status'] as String? ?? 'pending_review',
    subject: json['subject'] as String?, classLevel: json['class_level'] as String?,
    curriculum: json['curriculum'] as String?, tags: (json['tags'] as List?)?.cast<String>(),
    thumbnailUrl: json['thumbnail_url'] as String?, contentUrls: (json['content_urls'] as List?)?.cast<String>(),
    price: (json['price'] as num?)?.toDouble() ?? 0, isFree: json['is_free'] as bool? ?? true,
    downloadCount: json['download_count'] as int? ?? 0, ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
    ratingCount: json['rating_count'] as int? ?? 0, reviewNotes: json['review_notes'] as String?,
    reviewedBy: json['reviewed_by'] as String?,
    reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
    featuredUntil: json['featured_until'] != null ? DateTime.parse(json['featured_until'] as String) : null,
    isFlagged: json['is_flagged'] as bool? ?? false, flagReason: json['flag_reason'] as String?,
    flaggedBy: json['flagged_by'] as String?,
    flaggedAt: json['flagged_at'] != null ? DateTime.parse(json['flagged_at'] as String) : null,
    metadata: json['metadata'] as Map<String, dynamic>?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'author_id': authorId, 'school_id': schoolId, 'title': title,
    'description': description, 'content_type': contentType, 'status': status,
    'subject': subject, 'class_level': classLevel, 'curriculum': curriculum, 'tags': tags,
    'thumbnail_url': thumbnailUrl, 'content_urls': contentUrls, 'price': price,
    'is_free': isFree, 'download_count': downloadCount, 'rating_average': ratingAverage,
    'rating_count': ratingCount, 'review_notes': reviewNotes, 'reviewed_by': reviewedBy,
    'reviewed_at': reviewedAt?.toIso8601String(), 'featured_until': featuredUntil?.toIso8601String(),
    'is_flagged': isFlagged, 'flag_reason': flagReason, 'flagged_by': flaggedBy,
    'flagged_at': flaggedAt?.toIso8601String(), 'metadata': metadata,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  MarketplaceContent toEntity() => MarketplaceContent(
    id: id, authorId: authorId, schoolId: schoolId, title: title, description: description,
    contentType: MarketplaceContentType.fromString(contentType), status: MarketplaceStatus.fromString(status),
    subject: subject, classLevel: classLevel, curriculum: curriculum, tags: tags,
    thumbnailUrl: thumbnailUrl, contentUrls: contentUrls, price: price, isFree: isFree,
    downloadCount: downloadCount, ratingAverage: ratingAverage, ratingCount: ratingCount,
    reviewNotes: reviewNotes, reviewedBy: reviewedBy, reviewedAt: reviewedAt,
    featuredUntil: featuredUntil, isFlagged: isFlagged, flagReason: flagReason,
    flaggedBy: flaggedBy, flaggedAt: flaggedAt, metadata: metadata, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Platform Notification Model
// ═══════════════════════════════════════════════════════════════════════════════

class PlatformNotificationModel {
  const PlatformNotificationModel({
    required this.id, this.recipientId, required this.category, required this.priority,
    required this.title, required this.message, this.actionUrl, this.actionLabel,
    this.isRead = false, this.readAt, this.isDismissed = false, this.dismissedAt,
    this.relatedEntityType, this.relatedEntityId, this.metadata, this.expiresAt, required this.createdAt,
  });
  final String id; final String? recipientId; final String category; final String priority;
  final String title; final String message; final String? actionUrl; final String? actionLabel;
  final bool isRead; final DateTime? readAt; final bool isDismissed; final DateTime? dismissedAt;
  final String? relatedEntityType; final String? relatedEntityId; final Map<String, dynamic>? metadata;
  final DateTime? expiresAt; final DateTime createdAt;

  factory PlatformNotificationModel.fromJson(Map<String, dynamic> json) => PlatformNotificationModel(
    id: json['id'] as String, recipientId: json['recipient_id'] as String?,
    category: json['category'] as String? ?? 'system_error', priority: json['priority'] as String? ?? 'normal',
    title: json['title'] as String, message: json['message'] as String,
    actionUrl: json['action_url'] as String?, actionLabel: json['action_label'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    isDismissed: json['is_dismissed'] as bool? ?? false,
    dismissedAt: json['dismissed_at'] != null ? DateTime.parse(json['dismissed_at'] as String) : null,
    relatedEntityType: json['related_entity_type'] as String?, relatedEntityId: json['related_entity_id'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'recipient_id': recipientId, 'category': category, 'priority': priority,
    'title': title, 'message': message, 'action_url': actionUrl, 'action_label': actionLabel,
    'is_read': isRead, 'read_at': readAt?.toIso8601String(), 'is_dismissed': isDismissed,
    'dismissed_at': dismissedAt?.toIso8601String(), 'related_entity_type': relatedEntityType,
    'related_entity_id': relatedEntityId, 'metadata': metadata,
    'expires_at': expiresAt?.toIso8601String(), 'created_at': createdAt.toIso8601String(),
  };

  PlatformNotification toEntity() => PlatformNotification(
    id: id, recipientId: recipientId, category: NotificationCategory.fromString(category),
    priority: NotificationPriority.fromString(priority), title: title, message: message,
    actionUrl: actionUrl, actionLabel: actionLabel, isRead: isRead, readAt: readAt,
    isDismissed: isDismissed, dismissedAt: dismissedAt, relatedEntityType: relatedEntityType,
    relatedEntityId: relatedEntityId, metadata: metadata, expiresAt: expiresAt, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Intelligence Alert Model
// ═══════════════════════════════════════════════════════════════════════════════

class IntelligenceAlertModel {
  const IntelligenceAlertModel({
    required this.id, required this.alertType, required this.severity, required this.title,
    required this.description, this.affectedEntityType, this.affectedEntityId,
    this.affectedSchoolId, this.predictedValue, this.predictedDate, this.confidenceScore,
    this.supportingData, this.recommendedActions, this.isAcknowledged = false,
    this.acknowledgedBy, this.acknowledgedAt, this.isResolved = false, this.resolvedBy,
    this.resolvedAt, this.resolutionNotes, this.expiresAt, this.modelVersion,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String alertType; final String severity; final String title;
  final String description; final String? affectedEntityType; final String? affectedEntityId;
  final String? affectedSchoolId; final double? predictedValue; final DateTime? predictedDate;
  final double? confidenceScore; final Map<String, dynamic>? supportingData;
  final List<Map<String, dynamic>>? recommendedActions; final bool isAcknowledged;
  final String? acknowledgedBy; final DateTime? acknowledgedAt; final bool isResolved;
  final String? resolvedBy; final DateTime? resolvedAt; final String? resolutionNotes;
  final DateTime? expiresAt; final String? modelVersion; final DateTime createdAt; final DateTime updatedAt;

  factory IntelligenceAlertModel.fromJson(Map<String, dynamic> json) => IntelligenceAlertModel(
    id: json['id'] as String, alertType: json['alert_type'] as String? ?? 'anomaly_detection',
    severity: json['severity'] as String? ?? 'attention', title: json['title'] as String,
    description: json['description'] as String, affectedEntityType: json['affected_entity_type'] as String?,
    affectedEntityId: json['affected_entity_id'] as String?, affectedSchoolId: json['affected_school_id'] as String?,
    predictedValue: (json['predicted_value'] as num?)?.toDouble(),
    predictedDate: json['predicted_date'] != null ? DateTime.parse(json['predicted_date'] as String) : null,
    confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
    supportingData: json['supporting_data'] as Map<String, dynamic>?,
    recommendedActions: (json['recommended_actions'] as List?)?.cast<Map<String, dynamic>>(),
    isAcknowledged: json['is_acknowledged'] as bool? ?? false, acknowledgedBy: json['acknowledged_by'] as String?,
    acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at'] as String) : null,
    isResolved: json['is_resolved'] as bool? ?? false, resolvedBy: json['resolved_by'] as String?,
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    resolutionNotes: json['resolution_notes'] as String?,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    modelVersion: json['model_version'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'alert_type': alertType, 'severity': severity, 'title': title,
    'description': description, 'affected_entity_type': affectedEntityType,
    'affected_entity_id': affectedEntityId, 'affected_school_id': affectedSchoolId,
    'predicted_value': predictedValue, 'predicted_date': predictedDate?.toIso8601String(),
    'confidence_score': confidenceScore, 'supporting_data': supportingData,
    'recommended_actions': recommendedActions, 'is_acknowledged': isAcknowledged,
    'acknowledged_by': acknowledgedBy, 'acknowledged_at': acknowledgedAt?.toIso8601String(),
    'is_resolved': isResolved, 'resolved_by': resolvedBy, 'resolved_at': resolvedAt?.toIso8601String(),
    'resolution_notes': resolutionNotes, 'expires_at': expiresAt?.toIso8601String(),
    'model_version': modelVersion, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  IntelligenceAlert toEntity() => IntelligenceAlert(
    id: id, alertType: IntelligenceAlertType.fromString(alertType), severity: IntelligenceSeverity.fromString(severity),
    title: title, description: description, affectedEntityType: affectedEntityType,
    affectedEntityId: affectedEntityId, affectedSchoolId: affectedSchoolId,
    predictedValue: predictedValue, predictedDate: predictedDate, confidenceScore: confidenceScore,
    supportingData: supportingData, recommendedActions: recommendedActions,
    isAcknowledged: isAcknowledged, acknowledgedBy: acknowledgedBy, acknowledgedAt: acknowledgedAt,
    isResolved: isResolved, resolvedBy: resolvedBy, resolvedAt: resolvedAt,
    resolutionNotes: resolutionNotes, expiresAt: expiresAt, modelVersion: modelVersion,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dashboard Metrics Model (from RPC)
// ═══════════════════════════════════════════════════════════════════════════════

class DashboardMetricsModel {
  const DashboardMetricsModel({
    this.totalSchools = 0, this.totalTeachers = 0, this.totalStudents = 0,
    this.totalParents = 0, this.activeExams = 0, this.dailyActiveUsers = 0,
    this.monthlyActiveUsers = 0, this.aiRequestsToday = 0, this.revenueToday = 0,
    this.monthlyRevenue = 0, this.annualRevenue = 0, this.activeSubscriptions = 0,
    this.trialAccounts = 0, this.systemHealth = 'healthy', this.apiStatus = 'healthy',
    this.backgroundJobsPending = 0, this.backgroundJobsRunning = 0,
    this.recentActivities = const [], this.computedAt,
  });
  final int totalSchools; final int totalTeachers; final int totalStudents;
  final int totalParents; final int activeExams; final int dailyActiveUsers;
  final int monthlyActiveUsers; final int aiRequestsToday; final double revenueToday;
  final double monthlyRevenue; final double annualRevenue; final int activeSubscriptions;
  final int trialAccounts; final String systemHealth; final String apiStatus;
  final int backgroundJobsPending; final int backgroundJobsRunning;
  final List<Map<String, dynamic>> recentActivities; final DateTime? computedAt;

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) => DashboardMetricsModel(
    totalSchools: json['total_schools'] as int? ?? 0, totalTeachers: json['total_teachers'] as int? ?? 0,
    totalStudents: json['total_students'] as int? ?? 0, totalParents: json['total_parents'] as int? ?? 0,
    activeExams: json['active_exams'] as int? ?? 0, dailyActiveUsers: json['daily_active_users'] as int? ?? 0,
    monthlyActiveUsers: json['monthly_active_users'] as int? ?? 0, aiRequestsToday: json['ai_requests_today'] as int? ?? 0,
    revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0,
    monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0,
    annualRevenue: (json['annual_revenue'] as num?)?.toDouble() ?? 0,
    activeSubscriptions: json['active_subscriptions'] as int? ?? 0,
    trialAccounts: json['trial_accounts'] as int? ?? 0,
    systemHealth: json['system_health'] as String? ?? 'healthy', apiStatus: json['api_status'] as String? ?? 'healthy',
    backgroundJobsPending: json['background_jobs_pending'] as int? ?? 0,
    backgroundJobsRunning: json['background_jobs_running'] as int? ?? 0,
    recentActivities: (json['recent_activities'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    computedAt: json['computed_at'] != null ? DateTime.parse(json['computed_at'] as String) : null,
  );

  DashboardMetrics toEntity() => DashboardMetrics(
    totalSchools: totalSchools, totalTeachers: totalTeachers, totalStudents: totalStudents,
    totalParents: totalParents, activeExams: activeExams, dailyActiveUsers: dailyActiveUsers,
    monthlyActiveUsers: monthlyActiveUsers, aiRequestsToday: aiRequestsToday,
    revenueToday: revenueToday, monthlyRevenue: monthlyRevenue, annualRevenue: annualRevenue,
    activeSubscriptions: activeSubscriptions, trialAccounts: trialAccounts,
    systemHealth: systemHealth, apiStatus: apiStatus,
    backgroundJobsPending: backgroundJobsPending, backgroundJobsRunning: backgroundJobsRunning,
    recentActivities: recentActivities, computedAt: computedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// School Management Detail Model
// ═══════════════════════════════════════════════════════════════════════════════

class SchoolManagementDetailModel {
  const SchoolManagementDetailModel({
    required this.id, required this.name, this.domain, this.logoUrl,
    this.isActive = true, this.isVerified = false, this.subscriptionStatus,
    this.studentCount = 0, this.teacherCount = 0, this.storageUsedMb = 0,
    this.storageLimitMb = 0, this.studentLimit = 0, this.teacherLimit = 0,
    this.createdAt, this.updatedAt,
  });
  final String id; final String name; final String? domain; final String? logoUrl;
  final bool isActive; final bool isVerified; final String? subscriptionStatus;
  final int studentCount; final int teacherCount; final double storageUsedMb;
  final double storageLimitMb; final int studentLimit; final int teacherLimit;
  final DateTime? createdAt; final DateTime? updatedAt;

  factory SchoolManagementDetailModel.fromJson(Map<String, dynamic> json) => SchoolManagementDetailModel(
    id: json['id'] as String, name: json['name'] as String, domain: json['domain'] as String?,
    logoUrl: json['logo_url'] as String?, isActive: json['is_active'] as bool? ?? true,
    isVerified: json['is_verified'] as bool? ?? false, subscriptionStatus: json['subscription_status'] as String?,
    studentCount: json['student_count'] as int? ?? 0, teacherCount: json['teacher_count'] as int? ?? 0,
    storageUsedMb: (json['storage_used_mb'] as num?)?.toDouble() ?? 0,
    storageLimitMb: (json['storage_limit_mb'] as num?)?.toDouble() ?? 0,
    studentLimit: json['student_limit'] as int? ?? 0, teacherLimit: json['teacher_limit'] as int? ?? 0,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
  );

  SchoolManagementDetail toEntity() => SchoolManagementDetail(
    id: id, name: name, domain: domain, logoUrl: logoUrl, isActive: isActive,
    isVerified: isVerified, subscriptionStatus: subscriptionStatus, studentCount: studentCount,
    teacherCount: teacherCount, storageUsedMb: storageUsedMb, storageLimitMb: storageLimitMb,
    studentLimit: studentLimit, teacherLimit: teacherLimit, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// User Management Detail Model
// ═══════════════════════════════════════════════════════════════════════════════

class UserManagementDetailModel {
  const UserManagementDetailModel({
    required this.id, required this.email, required this.fullName, required this.role,
    this.schoolId, this.schoolName, this.isActive = true, this.isEmailVerified = false,
    this.lastLoginAt, this.loginCount = 0, this.createdAt,
  });
  final String id; final String email; final String fullName; final String role;
  final String? schoolId; final String? schoolName; final bool isActive;
  final bool isEmailVerified; final DateTime? lastLoginAt; final int loginCount;
  final DateTime? createdAt;

  factory UserManagementDetailModel.fromJson(Map<String, dynamic> json) => UserManagementDetailModel(
    id: json['id'] as String, email: json['email'] as String,
    fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
    role: json['role'] as String, schoolId: json['school_id'] as String?,
    schoolName: json['school_name'] as String?, isActive: json['is_active'] as bool? ?? true,
    isEmailVerified: json['is_email_verified'] as bool? ?? false,
    lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at'] as String) : null,
    loginCount: json['login_count'] as int? ?? 0,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
  );

  UserManagementDetail toEntity() => UserManagementDetail(
    id: id, email: email, fullName: fullName, role: role, schoolId: schoolId,
    schoolName: schoolName, isActive: isActive, isEmailVerified: isEmailVerified,
    lastLoginAt: lastLoginAt, loginCount: loginCount, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Revenue Analytics Model
// ═══════════════════════════════════════════════════════════════════════════════

class RevenueAnalyticsModel {
  const RevenueAnalyticsModel({
    this.totalRevenue = 0, this.monthlyRecurringRevenue = 0, this.averageRevenuePerUser = 0,
    this.averageRevenuePerSchool = 0, this.churnRate = 0, this.growthRate = 0,
    this.failedPayments = 0, this.refundsThisMonth = 0, this.pendingInvoices = 0,
    this.revenueByMonth = const [], this.revenueByBillingModel = const {},
  });
  final double totalRevenue; final double monthlyRecurringRevenue; final double averageRevenuePerUser;
  final double averageRevenuePerSchool; final double churnRate; final double growthRate;
  final int failedPayments; final double refundsThisMonth; final int pendingInvoices;
  final List<Map<String, dynamic>> revenueByMonth; final Map<String, dynamic> revenueByBillingModel;

  factory RevenueAnalyticsModel.fromJson(Map<String, dynamic> json) => RevenueAnalyticsModel(
    totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
    monthlyRecurringRevenue: (json['monthly_recurring_revenue'] as num?)?.toDouble() ?? 0,
    averageRevenuePerUser: (json['average_revenue_per_user'] as num?)?.toDouble() ?? 0,
    averageRevenuePerSchool: (json['average_revenue_per_school'] as num?)?.toDouble() ?? 0,
    churnRate: (json['churn_rate'] as num?)?.toDouble() ?? 0,
    growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 0,
    failedPayments: json['failed_payments'] as int? ?? 0,
    refundsThisMonth: (json['refunds_this_month'] as num?)?.toDouble() ?? 0,
    pendingInvoices: json['pending_invoices'] as int? ?? 0,
    revenueByMonth: (json['revenue_by_month'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    revenueByBillingModel: (json['revenue_by_billing_model'] as Map<String, dynamic>?) ?? {},
  );

  RevenueAnalytics toEntity() => RevenueAnalytics(
    totalRevenue: totalRevenue, monthlyRecurringRevenue: monthlyRecurringRevenue,
    averageRevenuePerUser: averageRevenuePerUser, averageRevenuePerSchool: averageRevenuePerSchool,
    churnRate: churnRate, growthRate: growthRate, failedPayments: failedPayments,
    refundsThisMonth: refundsThisMonth, pendingInvoices: pendingInvoices,
    revenueByMonth: revenueByMonth, revenueByBillingModel: revenueByBillingModel,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Login Monitoring Model
// ═══════════════════════════════════════════════════════════════════════════════

class LoginMonitoringEntryModel {
  const LoginMonitoringEntryModel({
    required this.id, this.userId, this.email, this.role, this.schoolId,
    required this.isSuccess, this.failureReason, this.ipAddress, this.userAgent,
    this.deviceFingerprint, this.country, this.city, this.sessionId, required this.createdAt,
  });
  final String id; final String? userId; final String? email; final String? role;
  final String? schoolId; final bool isSuccess; final String? failureReason;
  final String? ipAddress; final String? userAgent; final String? deviceFingerprint;
  final String? country; final String? city; final String? sessionId; final DateTime createdAt;

  factory LoginMonitoringEntryModel.fromJson(Map<String, dynamic> json) => LoginMonitoringEntryModel(
    id: json['id'] as String, userId: json['user_id'] as String?, email: json['email'] as String?,
    role: json['role'] as String?, schoolId: json['school_id'] as String?,
    isSuccess: json['is_success'] as bool? ?? true, failureReason: json['failure_reason'] as String?,
    ipAddress: json['ip_address'] as String?, userAgent: json['user_agent'] as String?,
    deviceFingerprint: json['device_fingerprint'] as String?, country: json['country'] as String?,
    city: json['city'] as String?, sessionId: json['session_id'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  LoginMonitoringEntry toEntity() => LoginMonitoringEntry(
    id: id, userId: userId, email: email, role: role, schoolId: schoolId,
    isSuccess: isSuccess, failureReason: failureReason, ipAddress: ipAddress,
    userAgent: userAgent, deviceFingerprint: deviceFingerprint, country: country,
    city: city, sessionId: sessionId, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Active Session Model
// ═══════════════════════════════════════════════════════════════════════════════

class ActiveSessionModel {
  const ActiveSessionModel({
    required this.id, required this.userId, required this.sessionTokenHash,
    this.deviceInfo, this.ipAddress, this.userAgent, this.country, this.city,
    this.isCurrent = false, required this.lastActivityAt, required this.expiresAt, required this.createdAt,
  });
  final String id; final String userId; final String sessionTokenHash;
  final Map<String, dynamic>? deviceInfo; final String? ipAddress; final String? userAgent;
  final String? country; final String? city; final bool isCurrent;
  final DateTime lastActivityAt; final DateTime expiresAt; final DateTime createdAt;

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) => ActiveSessionModel(
    id: json['id'] as String, userId: json['user_id'] as String,
    sessionTokenHash: json['session_token_hash'] as String, deviceInfo: json['device_info'] as Map<String, dynamic>?,
    ipAddress: json['ip_address'] as String?, userAgent: json['user_agent'] as String?,
    country: json['country'] as String?, city: json['city'] as String?,
    isCurrent: json['is_current'] as bool? ?? false,
    lastActivityAt: json['last_activity_at'] != null ? DateTime.parse(json['last_activity_at'] as String) : DateTime.now(),
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  ActiveSession toEntity() => ActiveSession(
    id: id, userId: userId, sessionTokenHash: sessionTokenHash, deviceInfo: deviceInfo,
    ipAddress: ipAddress, userAgent: userAgent, country: country, city: city,
    isCurrent: isCurrent, lastActivityAt: lastActivityAt, expiresAt: expiresAt, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// System Report Model
// ═══════════════════════════════════════════════════════════════════════════════

class SystemReportModel {
  const SystemReportModel({
    required this.id, required this.reportType, required this.title, this.description,
    required this.format, required this.status, this.parameters, this.fileUrl,
    this.fileSizeBytes, this.generatedBy, this.startedAt, this.completedAt,
    this.errorMessage, this.isScheduled = false, this.scheduleCron, this.nextRunAt,
    this.recipients, required this.createdAt, required this.updatedAt,
  });
  final String id; final String reportType; final String title; final String? description;
  final String format; final String status; final Map<String, dynamic>? parameters;
  final String? fileUrl; final int? fileSizeBytes; final String? generatedBy;
  final DateTime? startedAt; final DateTime? completedAt; final String? errorMessage;
  final bool isScheduled; final String? scheduleCron; final DateTime? nextRunAt;
  final List<String>? recipients; final DateTime createdAt; final DateTime updatedAt;

  factory SystemReportModel.fromJson(Map<String, dynamic> json) => SystemReportModel(
    id: json['id'] as String, reportType: json['report_type'] as String, title: json['title'] as String,
    description: json['description'] as String?, format: json['format'] as String? ?? 'pdf',
    status: json['status'] as String? ?? 'pending', parameters: json['parameters'] as Map<String, dynamic>?,
    fileUrl: json['file_url'] as String?, fileSizeBytes: json['file_size_bytes'] as int?,
    generatedBy: json['generated_by'] as String?,
    startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
    completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    errorMessage: json['error_message'] as String?, isScheduled: json['is_scheduled'] as bool? ?? false,
    scheduleCron: json['schedule_cron'] as String?,
    nextRunAt: json['next_run_at'] != null ? DateTime.parse(json['next_run_at'] as String) : null,
    recipients: (json['recipients'] as List?)?.cast<String>(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  SystemReport toEntity() => SystemReport(
    id: id, reportType: ReportType.fromString(reportType), title: title, description: description,
    format: format, status: status, parameters: parameters, fileUrl: fileUrl,
    fileSizeBytes: fileSizeBytes, generatedBy: generatedBy, startedAt: startedAt,
    completedAt: completedAt, errorMessage: errorMessage, isScheduled: isScheduled,
    scheduleCron: scheduleCron, nextRunAt: nextRunAt, recipients: recipients,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Maintenance Window Model
// ═══════════════════════════════════════════════════════════════════════════════

class MaintenanceWindowModel {
  const MaintenanceWindowModel({
    required this.id, required this.title, this.description, required this.status,
    this.affectedServices, required this.startAt, required this.endAt, this.actualStartAt,
    this.actualEndAt, this.isPlanned = true, this.notificationSent = false,
    this.createdBy, required this.createdAt, required this.updatedAt,
  });
  final String id; final String title; final String? description; final String status;
  final List<String>? affectedServices; final DateTime startAt; final DateTime endAt;
  final DateTime? actualStartAt; final DateTime? actualEndAt; final bool isPlanned;
  final bool notificationSent; final String? createdBy; final DateTime createdAt; final DateTime updatedAt;

  factory MaintenanceWindowModel.fromJson(Map<String, dynamic> json) => MaintenanceWindowModel(
    id: json['id'] as String, title: json['title'] as String, description: json['description'] as String?,
    status: json['status'] as String? ?? 'scheduled',
    affectedServices: (json['affected_services'] as List?)?.cast<String>(),
    startAt: json['start_at'] != null ? DateTime.parse(json['start_at'] as String) : DateTime.now(),
    endAt: json['end_at'] != null ? DateTime.parse(json['end_at'] as String) : DateTime.now(),
    actualStartAt: json['actual_start_at'] != null ? DateTime.parse(json['actual_start_at'] as String) : null,
    actualEndAt: json['actual_end_at'] != null ? DateTime.parse(json['actual_end_at'] as String) : null,
    isPlanned: json['is_planned'] as bool? ?? true, notificationSent: json['notification_sent'] as bool? ?? false,
    createdBy: json['created_by'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description, 'status': status,
    'affected_services': affectedServices, 'start_at': startAt.toIso8601String(),
    'end_at': endAt.toIso8601String(), 'actual_start_at': actualStartAt?.toIso8601String(),
    'actual_end_at': actualEndAt?.toIso8601String(), 'is_planned': isPlanned,
    'notification_sent': notificationSent, 'created_by': createdBy,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  MaintenanceWindow toEntity() => MaintenanceWindow(
    id: id, title: title, description: description, status: MaintenanceStatus.fromString(status),
    affectedServices: affectedServices, startAt: startAt, endAt: endAt,
    actualStartAt: actualStartAt, actualEndAt: actualEndAt, isPlanned: isPlanned,
    notificationSent: notificationSent, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Impersonation Session Model
// ═══════════════════════════════════════════════════════════════════════════════

class ImpersonationSessionModel {
  const ImpersonationSessionModel({
    required this.id, required this.adminId, required this.targetUserId,
    required this.targetUserRole, this.targetSchoolId, required this.reason,
    required this.status, required this.startedAt, required this.expiresAt,
    this.endedAt, this.endReason, this.ipAddress, this.userAgent,
    this.actionsTaken, required this.createdAt,
  });
  final String id; final String adminId; final String targetUserId; final String targetUserRole;
  final String? targetSchoolId; final String reason; final String status;
  final DateTime startedAt; final DateTime expiresAt; final DateTime? endedAt;
  final String? endReason; final String? ipAddress; final String? userAgent;
  final List<Map<String, dynamic>>? actionsTaken; final DateTime createdAt;

  factory ImpersonationSessionModel.fromJson(Map<String, dynamic> json) => ImpersonationSessionModel(
    id: json['id'] as String, adminId: json['admin_id'] as String,
    targetUserId: json['target_user_id'] as String, targetUserRole: json['target_user_role'] as String,
    targetSchoolId: json['target_school_id'] as String?, reason: json['reason'] as String,
    status: json['status'] as String? ?? 'active',
    startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : DateTime.now(),
    endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
    endReason: json['end_reason'] as String?, ipAddress: json['ip_address'] as String?,
    userAgent: json['user_agent'] as String?,
    actionsTaken: (json['actions_taken'] as List?)?.cast<Map<String, dynamic>>(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  ImpersonationSession toEntity() => ImpersonationSession(
    id: id, adminId: adminId, targetUserId: targetUserId, targetUserRole: targetUserRole,
    targetSchoolId: targetSchoolId, reason: reason, status: status,
    startedAt: startedAt, expiresAt: expiresAt, endedAt: endedAt, endReason: endReason,
    ipAddress: ipAddress, userAgent: userAgent, actionsTaken: actionsTaken, createdAt: createdAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Platform Policy Model
// ═══════════════════════════════════════════════════════════════════════════════

class PlatformPolicyModel {
  const PlatformPolicyModel({
    required this.id, required this.policyKey, required this.title, required this.content,
    this.version = 1, this.isActive = true, required this.effectiveDate, this.createdBy,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String policyKey; final String title; final String content;
  final int version; final bool isActive; final DateTime effectiveDate; final String? createdBy;
  final DateTime createdAt; final DateTime updatedAt;

  factory PlatformPolicyModel.fromJson(Map<String, dynamic> json) => PlatformPolicyModel(
    id: json['id'] as String, policyKey: json['policy_key'] as String, title: json['title'] as String,
    content: json['content'] as String, version: json['version'] as int? ?? 1,
    isActive: json['is_active'] as bool? ?? true,
    effectiveDate: json['effective_date'] != null ? DateTime.parse(json['effective_date'] as String) : DateTime.now(),
    createdBy: json['created_by'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'policy_key': policyKey, 'title': title, 'content': content,
    'version': version, 'is_active': isActive, 'effective_date': effectiveDate.toIso8601String(),
    'created_by': createdBy, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  PlatformPolicy toEntity() => PlatformPolicy(
    id: id, policyKey: policyKey, title: title, content: content, version: version,
    isActive: isActive, effectiveDate: effectiveDate, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Email Template Model
// ═══════════════════════════════════════════════════════════════════════════════

class EmailTemplateModel {
  const EmailTemplateModel({
    required this.id, required this.templateKey, required this.name, required this.subject,
    required this.htmlBody, this.textBody, this.category, this.variables, this.isActive = true,
    required this.createdAt, required this.updatedAt,
  });
  final String id; final String templateKey; final String name; final String subject;
  final String htmlBody; final String? textBody; final String? category;
  final List<String>? variables; final bool isActive; final DateTime createdAt; final DateTime updatedAt;

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) => EmailTemplateModel(
    id: json['id'] as String, templateKey: json['template_key'] as String, name: json['name'] as String,
    subject: json['subject'] as String, htmlBody: json['html_body'] as String, textBody: json['text_body'] as String?,
    category: json['category'] as String?, variables: (json['variables'] as List?)?.cast<String>(),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'template_key': templateKey, 'name': name, 'subject': subject,
    'html_body': htmlBody, 'text_body': textBody, 'category': category, 'variables': variables,
    'is_active': isActive, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  EmailTemplate toEntity() => EmailTemplate(
    id: id, templateKey: templateKey, name: name, subject: subject, htmlBody: htmlBody,
    textBody: textBody, category: category, variables: variables, isActive: isActive,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}
