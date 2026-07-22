import 'dart:ui';
import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum ModuleStatus {
  active(value: 'active', label: 'Active'),
  inactive(value: 'inactive', label: 'Inactive'),
  beta(value: 'beta', label: 'Beta'),
  deprecated(value: 'deprecated', label: 'Deprecated'),
  comingSoon(value: 'coming_soon', label: 'Coming Soon');

  const ModuleStatus({required this.value, required this.label});
  final String value;
  final String label;

  static ModuleStatus fromString(String value) {
    return ModuleStatus.values.firstWhere((e) => e.value == value, orElse: () => ModuleStatus.inactive);
  }

  bool get isActive => this == ModuleStatus.active || this == ModuleStatus.beta;
}

enum ModuleTier {
  free(value: 'free', label: 'Free'),
  starter(value: 'starter', label: 'Starter'),
  professional(value: 'professional', label: 'Professional'),
  enterprise(value: 'enterprise', label: 'Enterprise');

  const ModuleTier({required this.value, required this.label});
  final String value;
  final String label;

  static ModuleTier fromString(String value) {
    return ModuleTier.values.firstWhere((e) => e.value == value, orElse: () => ModuleTier.free);
  }

  Color get displayColor {
    switch (this) {
      case ModuleTier.free: return const Color(0xFF9CA3AF);
      case ModuleTier.starter: return const Color(0xFF22C55E);
      case ModuleTier.professional: return const Color(0xFF8B5CF6);
      case ModuleTier.enterprise: return const Color(0xFFF59E0B);
    }
  }
}

// ============================================================================
// ENTITIES
// ============================================================================

class EduosModule extends Equatable {
  final String id;
  final String code;
  final String name;
  final String description;
  final String version;
  final ModuleTier moduleTier;
  final ModuleStatus moduleStatus;
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

  const EduosModule({
    required this.id, required this.code, required this.name, required this.description,
    required this.version, required this.moduleTier, required this.moduleStatus,
    this.iconUrl, this.colorCode, required this.sortOrder, required this.features,
    required this.dependencies, required this.apiEndpoints, required this.isCore,
    required this.isPremium, required this.pricingMonthly, required this.pricingYearly,
    required this.metadata, required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, code, name, description, version, moduleTier, moduleStatus, iconUrl, colorCode, sortOrder, features, dependencies, apiEndpoints, isCore, isPremium, pricingMonthly, pricingYearly, metadata, createdAt, updatedAt];

  EduosModule copyWith({
    String? id, String? code, String? name, String? description, String? version,
    ModuleTier? moduleTier, ModuleStatus? moduleStatus, String? iconUrl, String? colorCode,
    int? sortOrder, Map<String, dynamic>? features, List<String>? dependencies,
    Map<String, dynamic>? apiEndpoints, bool? isCore, bool? isPremium,
    double? pricingMonthly, double? pricingYearly, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) => EduosModule(
    id: id ?? this.id, code: code ?? this.code, name: name ?? this.name,
    description: description ?? this.description, version: version ?? this.version,
    moduleTier: moduleTier ?? this.moduleTier, moduleStatus: moduleStatus ?? this.moduleStatus,
    iconUrl: iconUrl ?? this.iconUrl, colorCode: colorCode ?? this.colorCode,
    sortOrder: sortOrder ?? this.sortOrder, features: features ?? this.features,
    dependencies: dependencies ?? this.dependencies, apiEndpoints: apiEndpoints ?? this.apiEndpoints,
    isCore: isCore ?? this.isCore, isPremium: isPremium ?? this.isPremium,
    pricingMonthly: pricingMonthly ?? this.pricingMonthly, pricingYearly: pricingYearly ?? this.pricingYearly,
    metadata: metadata ?? this.metadata, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class EduosModuleSubscription extends Equatable {
  final String id;
  final String schoolId;
  final String moduleId;
  final ModuleTier moduleTier;
  final bool isEnabled;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> configuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EduosModuleSubscription({
    required this.id, required this.schoolId, required this.moduleId,
    required this.moduleTier, required this.isEnabled, this.activatedAt,
    this.expiresAt, required this.configuration, required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, schoolId, moduleId, moduleTier, isEnabled, activatedAt, expiresAt, configuration, createdAt, updatedAt];

  EduosModuleSubscription copyWith({
    String? id, String? schoolId, String? moduleId, ModuleTier? moduleTier,
    bool? isEnabled, DateTime? activatedAt, DateTime? expiresAt,
    Map<String, dynamic>? configuration, DateTime? createdAt, DateTime? updatedAt,
  }) => EduosModuleSubscription(
    id: id ?? this.id, schoolId: schoolId ?? this.schoolId, moduleId: moduleId ?? this.moduleId,
    moduleTier: moduleTier ?? this.moduleTier, isEnabled: isEnabled ?? this.isEnabled,
    activatedAt: activatedAt ?? this.activatedAt, expiresAt: expiresAt ?? this.expiresAt,
    configuration: configuration ?? this.configuration, createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class EduosModuleApi extends Equatable {
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

  const EduosModuleApi({
    required this.id, required this.moduleId, required this.endpoint,
    required this.method, required this.description, required this.authRequired,
    required this.rateLimit, required this.requestSchema, required this.responseSchema,
    required this.isActive, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, moduleId, endpoint, method, description, authRequired, rateLimit, requestSchema, responseSchema, isActive, createdAt];
}
