import '../../domain/entities/edu_os_entities.dart';

class EduosModuleModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String version;
  final String moduleTier;
  final String moduleStatus;
  final String? iconUrl;
  final String? colorCode;
  final int sortOrder;
  final Map<String, dynamic> features;
  final List<String> dependencies;
  final Map<String, dynamic> apiEndpoints;
  final bool isCore;
  final bool isPremium;
  final double pricingMonthly;
  final double pricingYearly;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EduosModuleModel({
    required this.id, required this.code, required this.name, required this.description,
    required this.version, required this.moduleTier, required this.moduleStatus,
    this.iconUrl, this.colorCode, required this.sortOrder, required this.features,
    required this.dependencies, required this.apiEndpoints, required this.isCore,
    required this.isPremium, required this.pricingMonthly, required this.pricingYearly,
    required this.metadata, required this.createdAt, required this.updatedAt,
  });

  factory EduosModuleModel.fromJson(Map<String, dynamic> json) => EduosModuleModel(
    id: json['id'] as String, code: json['code'] as String, name: json['name'] as String,
    description: json['description'] as String, version: json['version'] as String,
    moduleTier: json['module_tier'] as String, moduleStatus: json['module_status'] as String,
    iconUrl: json['icon_url'] as String?, colorCode: json['color_code'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    features: Map<String, dynamic>.from(json['features'] as Map? ?? {}),
    dependencies: (json['dependencies'] as List?)?.map((e) => e as String).toList() ?? [],
    apiEndpoints: Map<String, dynamic>.from(json['api_endpoints'] as Map? ?? {}),
    isCore: json['is_core'] as bool? ?? false, isPremium: json['is_premium'] as bool? ?? false,
    pricingMonthly: (json['pricing_monthly'] as num?)?.toDouble() ?? 0.0,
    pricingYearly: (json['pricing_yearly'] as num?)?.toDouble() ?? 0.0,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'name': name, 'description': description, 'version': version,
    'module_tier': moduleTier, 'module_status': moduleStatus, 'icon_url': iconUrl,
    'color_code': colorCode, 'sort_order': sortOrder, 'features': features,
    'dependencies': dependencies, 'api_endpoints': apiEndpoints, 'is_core': isCore,
    'is_premium': isPremium, 'pricing_monthly': pricingMonthly, 'pricing_yearly': pricingYearly,
    'metadata': metadata, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  EduosModule toEntity() => EduosModule(
    id: id, code: code, name: name, description: description, version: version,
    moduleTier: ModuleTier.fromString(moduleTier), moduleStatus: ModuleStatus.fromString(moduleStatus),
    iconUrl: iconUrl, colorCode: colorCode, sortOrder: sortOrder, features: features,
    dependencies: dependencies, apiEndpoints: apiEndpoints, isCore: isCore, isPremium: isPremium,
    pricingMonthly: pricingMonthly, pricingYearly: pricingYearly, metadata: metadata,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

class EduosModuleSubscriptionModel {
  final String id;
  final String schoolId;
  final String moduleId;
  final String moduleTier;
  final bool isEnabled;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> configuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EduosModuleSubscriptionModel({
    required this.id, required this.schoolId, required this.moduleId, required this.moduleTier,
    required this.isEnabled, this.activatedAt, this.expiresAt, required this.configuration,
    required this.createdAt, required this.updatedAt,
  });

  factory EduosModuleSubscriptionModel.fromJson(Map<String, dynamic> json) => EduosModuleSubscriptionModel(
    id: json['id'] as String, schoolId: json['school_id'] as String, moduleId: json['module_id'] as String,
    moduleTier: json['module_tier'] as String, isEnabled: json['is_enabled'] as bool? ?? false,
    activatedAt: json['activated_at'] != null ? DateTime.parse(json['activated_at'] as String) : null,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    configuration: Map<String, dynamic>.from(json['configuration'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String), updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'school_id': schoolId, 'module_id': moduleId, 'module_tier': moduleTier,
    'is_enabled': isEnabled, 'activated_at': activatedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(), 'configuration': configuration,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  EduosModuleSubscription toEntity() => EduosModuleSubscription(
    id: id, schoolId: schoolId, moduleId: moduleId, moduleTier: ModuleTier.fromString(moduleTier),
    isEnabled: isEnabled, activatedAt: activatedAt, expiresAt: expiresAt,
    configuration: configuration, createdAt: createdAt, updatedAt: updatedAt,
  );
}

class EduosModuleApiModel {
  final String id;
  final String moduleId;
  final String endpoint;
  final String method;
  final String description;
  final bool authRequired;
  final int rateLimit;
  final Map<String, dynamic> requestSchema;
  final Map<String, dynamic> responseSchema;
  final bool isActive;
  final DateTime createdAt;

  const EduosModuleApiModel({
    required this.id, required this.moduleId, required this.endpoint, required this.method,
    required this.description, required this.authRequired, required this.rateLimit,
    required this.requestSchema, required this.responseSchema, required this.isActive,
    required this.createdAt,
  });

  factory EduosModuleApiModel.fromJson(Map<String, dynamic> json) => EduosModuleApiModel(
    id: json['id'] as String, moduleId: json['module_id'] as String, endpoint: json['endpoint'] as String,
    method: json['method'] as String, description: json['description'] as String,
    authRequired: json['auth_required'] as bool? ?? true, rateLimit: json['rate_limit'] as int? ?? 100,
    requestSchema: Map<String, dynamic>.from(json['request_schema'] as Map? ?? {}),
    responseSchema: Map<String, dynamic>.from(json['response_schema'] as Map? ?? {}),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'module_id': moduleId, 'endpoint': endpoint, 'method': method,
    'description': description, 'auth_required': authRequired, 'rate_limit': rateLimit,
    'request_schema': requestSchema, 'response_schema': responseSchema,
    'is_active': isActive, 'created_at': createdAt.toIso8601String(),
  };

  EduosModuleApi toEntity() => EduosModuleApi(
    id: id, moduleId: moduleId, endpoint: endpoint, method: method,
    description: description, authRequired: authRequired, rateLimit: rateLimit,
    requestSchema: requestSchema, responseSchema: responseSchema,
    isActive: isActive, createdAt: createdAt,
  );
}
