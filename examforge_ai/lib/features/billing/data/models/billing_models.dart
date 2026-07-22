import '../../domain/entities/billing_entities.dart';

// ============================================================================
// SUPPORTING MODELS
// ============================================================================

/// Data-layer representation of an invoice line item.
class InvoiceLineItemModel {
  const InvoiceLineItemModel({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
  });

  final String description;
  final int quantity;
  final double unitPrice;
  final double total;
  final double taxRate;
  final double taxAmount;

  factory InvoiceLineItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItemModel(
      description: json['description'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num? ?? json['unitPrice'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num? ?? json['taxRate'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num? ?? json['taxAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
      };

  factory InvoiceLineItemModel.fromEntity(InvoiceLineItem entity) {
    return InvoiceLineItemModel(
      description: entity.description,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      total: entity.total,
      taxRate: entity.taxRate,
      taxAmount: entity.taxAmount,
    );
  }

  InvoiceLineItem toEntity() {
    return InvoiceLineItem(
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
      taxRate: taxRate,
      taxAmount: taxAmount,
    );
  }

  InvoiceLineItemModel copyWith({
    String? description,
    int? quantity,
    double? unitPrice,
    double? total,
    double? taxRate,
    double? taxAmount,
  }) {
    return InvoiceLineItemModel(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceLineItemModel &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          total == other.total &&
          taxRate == other.taxRate &&
          taxAmount == other.taxAmount;

  @override
  int get hashCode => Object.hash(description, quantity, unitPrice, total, taxRate, taxAmount);
}

// ============================================================================
// MAIN MODELS
// ============================================================================

/// Data-layer representation of a subscription plan.
class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.billingModel,
    this.description,
    this.monthlyPrice = 0,
    this.annualPrice = 0,
    this.currency = 'NGN',
    this.setupFee = 0,
    this.maxStudents = 0,
    this.maxTeachers = 0,
    this.maxSchools = 1,
    this.maxStorageMb = 100,
    this.maxExamsPerMonth = 0,
    this.aiCreditsMonthly = 0,
    this.includesAiWorkspace = false,
    this.includesParentPortal = false,
    this.includesCommunication = false,
    this.includesAdvancedAnalytics = false,
    this.includesApiAccess = false,
    this.includesWhiteLabel = false,
    this.includesPrioritySupport = false,
    this.includesDedicatedManager = false,
    this.trialDays = 0,
    this.isActive = true,
    this.isPopular = false,
    this.sortOrder = 0,
    this.featuresList = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final PlanTier tier;
  final BillingModel billingModel;
  final String? description;
  final double monthlyPrice;
  final double annualPrice;
  final String currency;
  final double setupFee;
  final int maxStudents;
  final int maxTeachers;
  final int maxSchools;
  final int maxStorageMb;
  final int maxExamsPerMonth;
  final int aiCreditsMonthly;
  final bool includesAiWorkspace;
  final bool includesParentPortal;
  final bool includesCommunication;
  final bool includesAdvancedAnalytics;
  final bool includesApiAccess;
  final bool includesWhiteLabel;
  final bool includesPrioritySupport;
  final bool includesDedicatedManager;
  final int trialDays;
  final bool isActive;
  final bool isPopular;
  final int sortOrder;
  final List<String> featuresList;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: PlanTier.fromString(json['tier'] as String?) ?? PlanTier.free,
      billingModel: BillingModel.fromString(json['billing_model'] as String? ?? json['billingModel'] as String?) ?? BillingModel.schoolSaas,
      description: json['description'] as String?,
      monthlyPrice: (json['monthly_price'] as num? ?? json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      annualPrice: (json['annual_price'] as num? ?? json['annualPrice'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      setupFee: (json['setup_fee'] as num? ?? json['setupFee'] as num?)?.toDouble() ?? 0,
      maxStudents: json['max_students'] as int? ?? json['maxStudents'] as int? ?? 0,
      maxTeachers: json['max_teachers'] as int? ?? json['maxTeachers'] as int? ?? 0,
      maxSchools: json['max_schools'] as int? ?? json['maxSchools'] as int? ?? 1,
      maxStorageMb: json['max_storage_mb'] as int? ?? json['maxStorageMb'] as int? ?? 100,
      maxExamsPerMonth: json['max_exams_per_month'] as int? ?? json['maxExamsPerMonth'] as int? ?? 0,
      aiCreditsMonthly: json['ai_credits_monthly'] as int? ?? json['aiCreditsMonthly'] as int? ?? 0,
      includesAiWorkspace: json['includes_ai_workspace'] as bool? ?? json['includesAiWorkspace'] as bool? ?? false,
      includesParentPortal: json['includes_parent_portal'] as bool? ?? json['includesParentPortal'] as bool? ?? false,
      includesCommunication: json['includes_communication'] as bool? ?? json['includesCommunication'] as bool? ?? false,
      includesAdvancedAnalytics: json['includes_advanced_analytics'] as bool? ?? json['includesAdvancedAnalytics'] as bool? ?? false,
      includesApiAccess: json['includes_api_access'] as bool? ?? json['includesApiAccess'] as bool? ?? false,
      includesWhiteLabel: json['includes_white_label'] as bool? ?? json['includesWhiteLabel'] as bool? ?? false,
      includesPrioritySupport: json['includes_priority_support'] as bool? ?? json['includesPrioritySupport'] as bool? ?? false,
      includesDedicatedManager: json['includes_dedicated_manager'] as bool? ?? json['includesDedicatedManager'] as bool? ?? false,
      trialDays: json['trial_days'] as int? ?? json['trialDays'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? json['isPopular'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      featuresList: (json['features_list'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tier': tier.value,
        'billing_model': billingModel.value,
        'description': description,
        'monthly_price': monthlyPrice,
        'annual_price': annualPrice,
        'currency': currency,
        'setup_fee': setupFee,
        'max_students': maxStudents,
        'max_teachers': maxTeachers,
        'max_schools': maxSchools,
        'max_storage_mb': maxStorageMb,
        'max_exams_per_month': maxExamsPerMonth,
        'ai_credits_monthly': aiCreditsMonthly,
        'includes_ai_workspace': includesAiWorkspace,
        'includes_parent_portal': includesParentPortal,
        'includes_communication': includesCommunication,
        'includes_advanced_analytics': includesAdvancedAnalytics,
        'includes_api_access': includesApiAccess,
        'includes_white_label': includesWhiteLabel,
        'includes_priority_support': includesPrioritySupport,
        'includes_dedicated_manager': includesDedicatedManager,
        'trial_days': trialDays,
        'is_active': isActive,
        'is_popular': isPopular,
        'sort_order': sortOrder,
        'features_list': featuresList,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SubscriptionPlanModel.fromEntity(SubscriptionPlanEntity entity) {
    return SubscriptionPlanModel(
      id: entity.id,
      name: entity.name,
      tier: entity.tier,
      billingModel: entity.billingModel,
      description: entity.description,
      monthlyPrice: entity.monthlyPrice,
      annualPrice: entity.annualPrice,
      currency: entity.currency,
      setupFee: entity.setupFee,
      maxStudents: entity.maxStudents,
      maxTeachers: entity.maxTeachers,
      maxSchools: entity.maxSchools,
      maxStorageMb: entity.maxStorageMb,
      maxExamsPerMonth: entity.maxExamsPerMonth,
      aiCreditsMonthly: entity.aiCreditsMonthly,
      includesAiWorkspace: entity.includesAiWorkspace,
      includesParentPortal: entity.includesParentPortal,
      includesCommunication: entity.includesCommunication,
      includesAdvancedAnalytics: entity.includesAdvancedAnalytics,
      includesApiAccess: entity.includesApiAccess,
      includesWhiteLabel: entity.includesWhiteLabel,
      includesPrioritySupport: entity.includesPrioritySupport,
      includesDedicatedManager: entity.includesDedicatedManager,
      trialDays: entity.trialDays,
      isActive: entity.isActive,
      isPopular: entity.isPopular,
      sortOrder: entity.sortOrder,
      featuresList: entity.featuresList,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SubscriptionPlanEntity toEntity() {
    return SubscriptionPlanEntity(
      id: id,
      name: name,
      tier: tier,
      billingModel: billingModel,
      description: description,
      monthlyPrice: monthlyPrice,
      annualPrice: annualPrice,
      currency: currency,
      setupFee: setupFee,
      maxStudents: maxStudents,
      maxTeachers: maxTeachers,
      maxSchools: maxSchools,
      maxStorageMb: maxStorageMb,
      maxExamsPerMonth: maxExamsPerMonth,
      aiCreditsMonthly: aiCreditsMonthly,
      includesAiWorkspace: includesAiWorkspace,
      includesParentPortal: includesParentPortal,
      includesCommunication: includesCommunication,
      includesAdvancedAnalytics: includesAdvancedAnalytics,
      includesApiAccess: includesApiAccess,
      includesWhiteLabel: includesWhiteLabel,
      includesPrioritySupport: includesPrioritySupport,
      includesDedicatedManager: includesDedicatedManager,
      trialDays: trialDays,
      isActive: isActive,
      isPopular: isPopular,
      sortOrder: sortOrder,
      featuresList: featuresList,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    PlanTier? tier,
    BillingModel? billingModel,
    String? description,
    double? monthlyPrice,
    double? annualPrice,
    String? currency,
    double? setupFee,
    int? maxStudents,
    int? maxTeachers,
    int? maxSchools,
    int? maxStorageMb,
    int? maxExamsPerMonth,
    int? aiCreditsMonthly,
    bool? includesAiWorkspace,
    bool? includesParentPortal,
    bool? includesCommunication,
    bool? includesAdvancedAnalytics,
    bool? includesApiAccess,
    bool? includesWhiteLabel,
    bool? includesPrioritySupport,
    bool? includesDedicatedManager,
    int? trialDays,
    bool? isActive,
    bool? isPopular,
    int? sortOrder,
    List<String>? featuresList,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      billingModel: billingModel ?? this.billingModel,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      annualPrice: annualPrice ?? this.annualPrice,
      currency: currency ?? this.currency,
      setupFee: setupFee ?? this.setupFee,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      maxSchools: maxSchools ?? this.maxSchools,
      maxStorageMb: maxStorageMb ?? this.maxStorageMb,
      maxExamsPerMonth: maxExamsPerMonth ?? this.maxExamsPerMonth,
      aiCreditsMonthly: aiCreditsMonthly ?? this.aiCreditsMonthly,
      includesAiWorkspace: includesAiWorkspace ?? this.includesAiWorkspace,
      includesParentPortal: includesParentPortal ?? this.includesParentPortal,
      includesCommunication: includesCommunication ?? this.includesCommunication,
      includesAdvancedAnalytics: includesAdvancedAnalytics ?? this.includesAdvancedAnalytics,
      includesApiAccess: includesApiAccess ?? this.includesApiAccess,
      includesWhiteLabel: includesWhiteLabel ?? this.includesWhiteLabel,
      includesPrioritySupport: includesPrioritySupport ?? this.includesPrioritySupport,
      includesDedicatedManager: includesDedicatedManager ?? this.includesDedicatedManager,
      trialDays: trialDays ?? this.trialDays,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      sortOrder: sortOrder ?? this.sortOrder,
      featuresList: featuresList ?? this.featuresList,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          tier == other.tier &&
          billingModel == other.billingModel &&
          description == other.description &&
          monthlyPrice == other.monthlyPrice &&
          annualPrice == other.annualPrice &&
          currency == other.currency &&
          setupFee == other.setupFee &&
          maxStudents == other.maxStudents &&
          maxTeachers == other.maxTeachers &&
          maxSchools == other.maxSchools &&
          maxStorageMb == other.maxStorageMb &&
          maxExamsPerMonth == other.maxExamsPerMonth &&
          aiCreditsMonthly == other.aiCreditsMonthly &&
          includesAiWorkspace == other.includesAiWorkspace &&
          includesParentPortal == other.includesParentPortal &&
          includesCommunication == other.includesCommunication &&
          includesAdvancedAnalytics == other.includesAdvancedAnalytics &&
          includesApiAccess == other.includesApiAccess &&
          includesWhiteLabel == other.includesWhiteLabel &&
          includesPrioritySupport == other.includesPrioritySupport &&
          includesDedicatedManager == other.includesDedicatedManager &&
          trialDays == other.trialDays &&
          isActive == other.isActive &&
          isPopular == other.isPopular &&
          sortOrder == other.sortOrder &&
          _listEquals(featuresList, other.featuresList) &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id, name, tier, billingModel, description, monthlyPrice, annualPrice,
        currency, setupFee, maxStudents, maxTeachers, maxSchools, maxStorageMb,
        maxExamsPerMonth, aiCreditsMonthly, includesAiWorkspace,
        includesParentPortal, includesCommunication, includesAdvancedAnalytics,
        includesApiAccess, includesWhiteLabel, includesPrioritySupport,
        includesDedicatedManager, trialDays, isActive, isPopular, sortOrder,
        ...featuresList, metadata, createdAt, updatedAt,
      ]);
}

/// Data-layer representation of a subscription.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.subscriberId,
    required this.subscriberType,
    this.schoolId,
    required this.planId,
    this.plan,
    this.status = SubscriptionStatus.trial,
    this.billingCycle = 'monthly',
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialStart,
    this.trialEnd,
    this.flutterwaveSubscriptionId,
    this.flutterwavePlanCode,
    this.couponId,
    this.couponDiscountApplied = 0,
    this.priceAtSubscription = 0,
    this.currency = 'NGN',
    this.seatsPurchased = 1,
    this.seatsUsed = 0,
    this.autoRenew = true,
    this.cancelledAt,
    this.cancellationReason,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subscriberId;
  final BillingModel subscriberType;
  final String? schoolId;
  final String planId;
  final SubscriptionPlanModel? plan;
  final SubscriptionStatus status;
  final String billingCycle;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final String? flutterwaveSubscriptionId;
  final String? flutterwavePlanCode;
  final String? couponId;
  final double couponDiscountApplied;
  final double priceAtSubscription;
  final String currency;
  final int seatsPurchased;
  final int seatsUsed;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      subscriberId: json['subscriber_id'] as String? ?? json['subscriberId'] as String? ?? '',
      subscriberType: BillingModel.fromString(json['subscriber_type'] as String? ?? json['subscriberType'] as String?) ?? BillingModel.schoolSaas,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      planId: json['plan_id'] as String? ?? json['planId'] as String? ?? '',
      plan: json['plan'] != null ? SubscriptionPlanModel.fromJson(json['plan'] as Map<String, dynamic>) : null,
      status: SubscriptionStatus.fromString(json['status'] as String?) ?? SubscriptionStatus.trial,
      billingCycle: json['billing_cycle'] as String? ?? json['billingCycle'] as String? ?? 'monthly',
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : json['currentPeriodStart'] != null
              ? DateTime.parse(json['currentPeriodStart'] as String)
              : DateTime.now(),
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : json['currentPeriodEnd'] != null
              ? DateTime.parse(json['currentPeriodEnd'] as String)
              : DateTime.now(),
      trialStart: json['trial_start'] != null
          ? DateTime.parse(json['trial_start'] as String)
          : json['trialStart'] != null
              ? DateTime.parse(json['trialStart'] as String)
              : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'] as String)
          : json['trialEnd'] != null
              ? DateTime.parse(json['trialEnd'] as String)
              : null,
      flutterwaveSubscriptionId: json['flutterwave_subscription_id'] as String? ?? json['flutterwaveSubscriptionId'] as String?,
      flutterwavePlanCode: json['flutterwave_plan_code'] as String? ?? json['flutterwavePlanCode'] as String?,
      couponId: json['coupon_id'] as String? ?? json['couponId'] as String?,
      couponDiscountApplied: (json['coupon_discount_applied'] as num? ?? json['couponDiscountApplied'] as num?)?.toDouble() ?? 0,
      priceAtSubscription: (json['price_at_subscription'] as num? ?? json['priceAtSubscription'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      seatsPurchased: json['seats_purchased'] as int? ?? json['seatsPurchased'] as int? ?? 1,
      seatsUsed: json['seats_used'] as int? ?? json['seatsUsed'] as int? ?? 0,
      autoRenew: json['auto_renew'] as bool? ?? json['autoRenew'] as bool? ?? true,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String? ?? json['cancellationReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriber_id': subscriberId,
        'subscriber_type': subscriberType.value,
        'school_id': schoolId,
        'plan_id': planId,
        'plan': plan?.toJson(),
        'status': status.value,
        'billing_cycle': billingCycle,
        'current_period_start': currentPeriodStart.toIso8601String(),
        'current_period_end': currentPeriodEnd.toIso8601String(),
        'trial_start': trialStart?.toIso8601String(),
        'trial_end': trialEnd?.toIso8601String(),
        'flutterwave_subscription_id': flutterwaveSubscriptionId,
        'flutterwave_plan_code': flutterwavePlanCode,
        'coupon_id': couponId,
        'coupon_discount_applied': couponDiscountApplied,
        'price_at_subscription': priceAtSubscription,
        'currency': currency,
        'seats_purchased': seatsPurchased,
        'seats_used': seatsUsed,
        'auto_renew': autoRenew,
        'cancelled_at': cancelledAt?.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SubscriptionModel.fromEntity(SubscriptionEntity entity) {
    return SubscriptionModel(
      id: entity.id,
      subscriberId: entity.subscriberId,
      subscriberType: entity.subscriberType,
      schoolId: entity.schoolId,
      planId: entity.planId,
      plan: entity.plan != null ? SubscriptionPlanModel.fromEntity(entity.plan!) : null,
      status: entity.status,
      billingCycle: entity.billingCycle,
      currentPeriodStart: entity.currentPeriodStart,
      currentPeriodEnd: entity.currentPeriodEnd,
      trialStart: entity.trialStart,
      trialEnd: entity.trialEnd,
      flutterwaveSubscriptionId: entity.flutterwaveSubscriptionId,
      flutterwavePlanCode: entity.flutterwavePlanCode,
      couponId: entity.couponId,
      couponDiscountApplied: entity.couponDiscountApplied,
      priceAtSubscription: entity.priceAtSubscription,
      currency: entity.currency,
      seatsPurchased: entity.seatsPurchased,
      seatsUsed: entity.seatsUsed,
      autoRenew: entity.autoRenew,
      cancelledAt: entity.cancelledAt,
      cancellationReason: entity.cancellationReason,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SubscriptionEntity toEntity() {
    return SubscriptionEntity(
      id: id,
      subscriberId: subscriberId,
      subscriberType: subscriberType,
      schoolId: schoolId,
      planId: planId,
      plan: plan?.toEntity(),
      status: status,
      billingCycle: billingCycle,
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      trialStart: trialStart,
      trialEnd: trialEnd,
      flutterwaveSubscriptionId: flutterwaveSubscriptionId,
      flutterwavePlanCode: flutterwavePlanCode,
      couponId: couponId,
      couponDiscountApplied: couponDiscountApplied,
      priceAtSubscription: priceAtSubscription,
      currency: currency,
      seatsPurchased: seatsPurchased,
      seatsUsed: seatsUsed,
      autoRenew: autoRenew,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? subscriberId,
    BillingModel? subscriberType,
    String? schoolId,
    String? planId,
    SubscriptionPlanModel? plan,
    SubscriptionStatus? status,
    String? billingCycle,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialStart,
    DateTime? trialEnd,
    String? flutterwaveSubscriptionId,
    String? flutterwavePlanCode,
    String? couponId,
    double? couponDiscountApplied,
    double? priceAtSubscription,
    String? currency,
    int? seatsPurchased,
    int? seatsUsed,
    bool? autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      subscriberId: subscriberId ?? this.subscriberId,
      subscriberType: subscriberType ?? this.subscriberType,
      schoolId: schoolId ?? this.schoolId,
      planId: planId ?? this.planId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      billingCycle: billingCycle ?? this.billingCycle,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      flutterwaveSubscriptionId: flutterwaveSubscriptionId ?? this.flutterwaveSubscriptionId,
      flutterwavePlanCode: flutterwavePlanCode ?? this.flutterwavePlanCode,
      couponId: couponId ?? this.couponId,
      couponDiscountApplied: couponDiscountApplied ?? this.couponDiscountApplied,
      priceAtSubscription: priceAtSubscription ?? this.priceAtSubscription,
      currency: currency ?? this.currency,
      seatsPurchased: seatsPurchased ?? this.seatsPurchased,
      seatsUsed: seatsUsed ?? this.seatsUsed,
      autoRenew: autoRenew ?? this.autoRenew,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subscriberId == other.subscriberId &&
          subscriberType == other.subscriberType &&
          schoolId == other.schoolId &&
          planId == other.planId &&
          plan == other.plan &&
          status == other.status &&
          billingCycle == other.billingCycle &&
          currentPeriodStart == other.currentPeriodStart &&
          currentPeriodEnd == other.currentPeriodEnd &&
          trialStart == other.trialStart &&
          trialEnd == other.trialEnd &&
          flutterwaveSubscriptionId == other.flutterwaveSubscriptionId &&
          flutterwavePlanCode == other.flutterwavePlanCode &&
          couponId == other.couponId &&
          couponDiscountApplied == other.couponDiscountApplied &&
          priceAtSubscription == other.priceAtSubscription &&
          currency == other.currency &&
          seatsPurchased == other.seatsPurchased &&
          seatsUsed == other.seatsUsed &&
          autoRenew == other.autoRenew &&
          cancelledAt == other.cancelledAt &&
          cancellationReason == other.cancellationReason &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id, subscriberId, subscriberType, schoolId, planId, plan, status,
        billingCycle, currentPeriodStart, currentPeriodEnd, trialStart,
        trialEnd, flutterwaveSubscriptionId, flutterwavePlanCode, couponId,
        couponDiscountApplied, priceAtSubscription, currency, seatsPurchased,
        seatsUsed, autoRenew, cancelledAt, cancellationReason,
        metadata, createdAt, updatedAt,
      ]);
}

/// Data-layer representation of a transaction.
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.subscriptionId,
    required this.userId,
    this.schoolId,
    this.flutterwaveTxRef,
    this.flutterwaveTransactionId,
    this.flutterwaveFlwRef,
    required this.amount,
    this.currency = 'NGN',
    this.channel = PaymentChannel.card,
    this.status = TransactionStatus.pending,
    this.flutterwaveFee = 0,
    this.appFee = 0,
    this.netAmount = 0,
    this.paymentMethodSummary,
    this.processorResponse = const {},
    this.refundAmount = 0,
    this.refundReason,
    this.refundedAt,
    this.riskScore = 0,
    this.fraudFlagged = false,
    this.fraudNotes,
    this.description,
    this.metadata = const {},
    required this.initiatedAt,
    this.completedAt,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? subscriptionId;
  final String userId;
  final String? schoolId;
  final String? flutterwaveTxRef;
  final String? flutterwaveTransactionId;
  final String? flutterwaveFlwRef;
  final double amount;
  final String currency;
  final PaymentChannel channel;
  final TransactionStatus status;
  final double flutterwaveFee;
  final double appFee;
  final double netAmount;
  final String? paymentMethodSummary;
  final Map<String, dynamic> processorResponse;
  final double refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;
  final int riskScore;
  final bool fraudFlagged;
  final String? fraudNotes;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String? ?? json['subscriptionId'] as String?,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      flutterwaveTxRef: json['flutterwave_tx_ref'] as String? ?? json['flutterwaveTxRef'] as String?,
      flutterwaveTransactionId: json['flutterwave_transaction_id'] as String? ?? json['flutterwaveTransactionId'] as String?,
      flutterwaveFlwRef: json['flutterwave_flw_ref'] as String? ?? json['flutterwaveFlwRef'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      channel: PaymentChannel.fromString(json['channel'] as String?) ?? PaymentChannel.card,
      status: TransactionStatus.fromString(json['status'] as String?) ?? TransactionStatus.pending,
      flutterwaveFee: (json['flutterwave_fee'] as num? ?? json['flutterwaveFee'] as num?)?.toDouble() ?? 0,
      appFee: (json['app_fee'] as num? ?? json['appFee'] as num?)?.toDouble() ?? 0,
      netAmount: (json['net_amount'] as num? ?? json['netAmount'] as num?)?.toDouble() ?? 0,
      paymentMethodSummary: json['payment_method_summary'] as String? ?? json['paymentMethodSummary'] as String?,
      processorResponse: json['processor_response'] as Map<String, dynamic>? ?? json['processorResponse'] as Map<String, dynamic>? ?? {},
      refundAmount: (json['refund_amount'] as num? ?? json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundReason: json['refund_reason'] as String? ?? json['refundReason'] as String?,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : json['refundedAt'] != null
              ? DateTime.parse(json['refundedAt'] as String)
              : null,
      riskScore: json['risk_score'] as int? ?? json['riskScore'] as int? ?? 0,
      fraudFlagged: json['fraud_flagged'] as bool? ?? json['fraudFlagged'] as bool? ?? false,
      fraudNotes: json['fraud_notes'] as String? ?? json['fraudNotes'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      initiatedAt: json['initiated_at'] != null
          ? DateTime.parse(json['initiated_at'] as String)
          : json['initiatedAt'] != null
              ? DateTime.parse(json['initiatedAt'] as String)
              : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : json['verifiedAt'] != null
              ? DateTime.parse(json['verifiedAt'] as String)
              : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscription_id': subscriptionId,
        'user_id': userId,
        'school_id': schoolId,
        'flutterwave_tx_ref': flutterwaveTxRef,
        'flutterwave_transaction_id': flutterwaveTransactionId,
        'flutterwave_flw_ref': flutterwaveFlwRef,
        'amount': amount,
        'currency': currency,
        'channel': channel.value,
        'status': status.value,
        'flutterwave_fee': flutterwaveFee,
        'app_fee': appFee,
        'net_amount': netAmount,
        'payment_method_summary': paymentMethodSummary,
        'processor_response': processorResponse,
        'refund_amount': refundAmount,
        'refund_reason': refundReason,
        'refunded_at': refundedAt?.toIso8601String(),
        'risk_score': riskScore,
        'fraud_flagged': fraudFlagged,
        'fraud_notes': fraudNotes,
        'description': description,
        'metadata': metadata,
        'initiated_at': initiatedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'verified_at': verifiedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      subscriptionId: entity.subscriptionId,
      userId: entity.userId,
      schoolId: entity.schoolId,
      flutterwaveTxRef: entity.flutterwaveTxRef,
      flutterwaveTransactionId: entity.flutterwaveTransactionId,
      flutterwaveFlwRef: entity.flutterwaveFlwRef,
      amount: entity.amount,
      currency: entity.currency,
      channel: entity.channel,
      status: entity.status,
      flutterwaveFee: entity.flutterwaveFee,
      appFee: entity.appFee,
      netAmount: entity.netAmount,
      paymentMethodSummary: entity.paymentMethodSummary,
      processorResponse: entity.processorResponse,
      refundAmount: entity.refundAmount,
      refundReason: entity.refundReason,
      refundedAt: entity.refundedAt,
      riskScore: entity.riskScore,
      fraudFlagged: entity.fraudFlagged,
      fraudNotes: entity.fraudNotes,
      description: entity.description,
      metadata: entity.metadata,
      initiatedAt: entity.initiatedAt,
      completedAt: entity.completedAt,
      verifiedAt: entity.verifiedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      subscriptionId: subscriptionId,
      userId: userId,
      schoolId: schoolId,
      flutterwaveTxRef: flutterwaveTxRef,
      flutterwaveTransactionId: flutterwaveTransactionId,
      flutterwaveFlwRef: flutterwaveFlwRef,
      amount: amount,
      currency: currency,
      channel: channel,
      status: status,
      flutterwaveFee: flutterwaveFee,
      appFee: appFee,
      netAmount: netAmount,
      paymentMethodSummary: paymentMethodSummary,
      processorResponse: processorResponse,
      refundAmount: refundAmount,
      refundReason: refundReason,
      refundedAt: refundedAt,
      riskScore: riskScore,
      fraudFlagged: fraudFlagged,
      fraudNotes: fraudNotes,
      description: description,
      metadata: metadata,
      initiatedAt: initiatedAt,
      completedAt: completedAt,
      verifiedAt: verifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? subscriptionId,
    String? userId,
    String? schoolId,
    String? flutterwaveTxRef,
    String? flutterwaveTransactionId,
    String? flutterwaveFlwRef,
    double? amount,
    String? currency,
    PaymentChannel? channel,
    TransactionStatus? status,
    double? flutterwaveFee,
    double? appFee,
    double? netAmount,
    String? paymentMethodSummary,
    Map<String, dynamic>? processorResponse,
    double? refundAmount,
    String? refundReason,
    DateTime? refundedAt,
    int? riskScore,
    bool? fraudFlagged,
    String? fraudNotes,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? initiatedAt,
    DateTime? completedAt,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      flutterwaveTxRef: flutterwaveTxRef ?? this.flutterwaveTxRef,
      flutterwaveTransactionId: flutterwaveTransactionId ?? this.flutterwaveTransactionId,
      flutterwaveFlwRef: flutterwaveFlwRef ?? this.flutterwaveFlwRef,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      flutterwaveFee: flutterwaveFee ?? this.flutterwaveFee,
      appFee: appFee ?? this.appFee,
      netAmount: netAmount ?? this.netAmount,
      paymentMethodSummary: paymentMethodSummary ?? this.paymentMethodSummary,
      processorResponse: processorResponse ?? this.processorResponse,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
      refundedAt: refundedAt ?? this.refundedAt,
      riskScore: riskScore ?? this.riskScore,
      fraudFlagged: fraudFlagged ?? this.fraudFlagged,
      fraudNotes: fraudNotes ?? this.fraudNotes,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      completedAt: completedAt ?? this.completedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subscriptionId == other.subscriptionId &&
          userId == other.userId &&
          schoolId == other.schoolId &&
          flutterwaveTxRef == other.flutterwaveTxRef &&
          flutterwaveTransactionId == other.flutterwaveTransactionId &&
          flutterwaveFlwRef == other.flutterwaveFlwRef &&
          amount == other.amount &&
          currency == other.currency &&
          channel == other.channel &&
          status == other.status &&
          flutterwaveFee == other.flutterwaveFee &&
          appFee == other.appFee &&
          netAmount == other.netAmount &&
          paymentMethodSummary == other.paymentMethodSummary &&
          _mapEquals(processorResponse, other.processorResponse) &&
          refundAmount == other.refundAmount &&
          refundReason == other.refundReason &&
          refundedAt == other.refundedAt &&
          riskScore == other.riskScore &&
          fraudFlagged == other.fraudFlagged &&
          fraudNotes == other.fraudNotes &&
          description == other.description &&
          _mapEquals(metadata, other.metadata) &&
          initiatedAt == other.initiatedAt &&
          completedAt == other.completedAt &&
          verifiedAt == other.verifiedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id, subscriptionId, userId, schoolId, flutterwaveTxRef,
        flutterwaveTransactionId, flutterwaveFlwRef, amount, currency,
        channel, status, flutterwaveFee, appFee, netAmount,
        paymentMethodSummary, processorResponse, refundAmount,
        refundReason, refundedAt, riskScore, fraudFlagged, fraudNotes,
        description, metadata, initiatedAt, completedAt,
        verifiedAt, createdAt, updatedAt,
      ]);
}

/// Data-layer representation of an invoice.
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    this.subscriptionId,
    this.transactionId,
    this.schoolId,
    required this.userId,
    required this.invoiceNumber,
    this.invoiceType = InvoiceStatus.draft,
    required this.billToName,
    this.billToEmail,
    this.billToAddress,
    this.billToTaxId,
    this.lineItems = const [],
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.currency = 'NGN',
    this.creditNoteFor,
    required this.issueDate,
    required this.dueDate,
    this.paidAt,
    this.pdfUrl,
    this.emailSent = false,
    this.emailSentAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? subscriptionId;
  final String? transactionId;
  final String? schoolId;
  final String userId;
  final String invoiceNumber;
  final InvoiceStatus invoiceType;
  final String billToName;
  final String? billToEmail;
  final String? billToAddress;
  final String? billToTaxId;
  final List<InvoiceLineItemModel> lineItems;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String? creditNoteFor;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? pdfUrl;
  final bool emailSent;
  final DateTime? emailSentAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String? ?? json['subscriptionId'] as String?,
      transactionId: json['transaction_id'] as String? ?? json['transactionId'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? json['invoiceNumber'] as String? ?? '',
      invoiceType: InvoiceStatus.fromString(json['invoice_type'] as String? ?? json['invoiceType'] as String?) ?? InvoiceStatus.draft,
      billToName: json['bill_to_name'] as String? ?? json['billToName'] as String? ?? '',
      billToEmail: json['bill_to_email'] as String? ?? json['billToEmail'] as String?,
      billToAddress: json['bill_to_address'] as String? ?? json['billToAddress'] as String?,
      billToTaxId: json['bill_to_tax_id'] as String? ?? json['billToTaxId'] as String?,
      lineItems: (json['line_items'] as List<dynamic>? ?? json['lineItems'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num? ?? json['taxAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num? ?? json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num? ?? json['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      creditNoteFor: json['credit_note_for'] as String? ?? json['creditNoteFor'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'] as String)
          : json['issueDate'] != null
              ? DateTime.parse(json['issueDate'] as String)
              : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : json['paidAt'] != null
              ? DateTime.parse(json['paidAt'] as String)
              : null,
      pdfUrl: json['pdf_url'] as String? ?? json['pdfUrl'] as String?,
      emailSent: json['email_sent'] as bool? ?? json['emailSent'] as bool? ?? false,
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'] as String)
          : json['emailSentAt'] != null
              ? DateTime.parse(json['emailSentAt'] as String)
              : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscription_id': subscriptionId,
        'transaction_id': transactionId,
        'school_id': schoolId,
        'user_id': userId,
        'invoice_number': invoiceNumber,
        'invoice_type': invoiceType.value,
        'bill_to_name': billToName,
        'bill_to_email': billToEmail,
        'bill_to_address': billToAddress,
        'bill_to_tax_id': billToTaxId,
        'line_items': lineItems.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'currency': currency,
        'credit_note_for': creditNoteFor,
        'issue_date': issueDate.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
        'pdf_url': pdfUrl,
        'email_sent': emailSent,
        'email_sent_at': emailSentAt?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      id: entity.id,
      subscriptionId: entity.subscriptionId,
      transactionId: entity.transactionId,
      schoolId: entity.schoolId,
      userId: entity.userId,
      invoiceNumber: entity.invoiceNumber,
      invoiceType: entity.invoiceType,
      billToName: entity.billToName,
      billToEmail: entity.billToEmail,
      billToAddress: entity.billToAddress,
      billToTaxId: entity.billToTaxId,
      lineItems: entity.lineItems.map((e) => InvoiceLineItemModel.fromEntity(e)).toList(),
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      totalAmount: entity.totalAmount,
      currency: entity.currency,
      creditNoteFor: entity.creditNoteFor,
      issueDate: entity.issueDate,
      dueDate: entity.dueDate,
      paidAt: entity.paidAt,
      pdfUrl: entity.pdfUrl,
      emailSent: entity.emailSent,
      emailSentAt: entity.emailSentAt,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  InvoiceEntity toEntity() {
    return InvoiceEntity(
      id: id,
      subscriptionId: subscriptionId,
      transactionId: transactionId,
      schoolId: schoolId,
      userId: userId,
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      billToName: billToName,
      billToEmail: billToEmail,
      billToAddress: billToAddress,
      billToTaxId: billToTaxId,
      lineItems: lineItems.map((e) => e.toEntity()).toList(),
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      currency: currency,
      creditNoteFor: creditNoteFor,
      issueDate: issueDate,
      dueDate: dueDate,
      paidAt: paidAt,
      pdfUrl: pdfUrl,
      emailSent: emailSent,
      emailSentAt: emailSentAt,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? subscriptionId,
    String? transactionId,
    String? schoolId,
    String? userId,
    String? invoiceNumber,
    InvoiceStatus? invoiceType,
    String? billToName,
    String? billToEmail,
    String? billToAddress,
    String? billToTaxId,
    List<InvoiceLineItemModel>? lineItems,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? currency,
    String? creditNoteFor,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidAt,
    String? pdfUrl,
    bool? emailSent,
    DateTime? emailSentAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      transactionId: transactionId ?? this.transactionId,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceType: invoiceType ?? this.invoiceType,
      billToName: billToName ?? this.billToName,
      billToEmail: billToEmail ?? this.billToEmail,
      billToAddress: billToAddress ?? this.billToAddress,
      billToTaxId: billToTaxId ?? this.billToTaxId,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      creditNoteFor: creditNoteFor ?? this.creditNoteFor,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subscriptionId == other.subscriptionId &&
          transactionId == other.transactionId &&
          schoolId == other.schoolId &&
          userId == other.userId &&
          invoiceNumber == other.invoiceNumber &&
          invoiceType == other.invoiceType &&
          billToName == other.billToName &&
          billToEmail == other.billToEmail &&
          billToAddress == other.billToAddress &&
          billToTaxId == other.billToTaxId &&
          _listEquals(lineItems, other.lineItems) &&
          subtotal == other.subtotal &&
          taxAmount == other.taxAmount &&
          discountAmount == other.discountAmount &&
          totalAmount == other.totalAmount &&
          currency == other.currency &&
          creditNoteFor == other.creditNoteFor &&
          issueDate == other.issueDate &&
          dueDate == other.dueDate &&
          paidAt == other.paidAt &&
          pdfUrl == other.pdfUrl &&
          emailSent == other.emailSent &&
          emailSentAt == other.emailSentAt &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id, subscriptionId, transactionId, schoolId, userId, invoiceNumber,
        invoiceType, billToName, billToEmail, billToAddress, billToTaxId,
        ...lineItems, subtotal, taxAmount, discountAmount,
        totalAmount, currency, creditNoteFor, issueDate, dueDate, paidAt,
        pdfUrl, emailSent, emailSentAt, metadata, createdAt, updatedAt,
      ]);
}

/// Data-layer representation of a receipt.
class ReceiptModel {
  const ReceiptModel({
    required this.id,
    required this.transactionId,
    this.invoiceId,
    required this.userId,
    this.schoolId,
    required this.receiptNumber,
    required this.amountPaid,
    this.currency = 'NGN',
    required this.paymentMethod,
    required this.paymentDate,
    this.pdfUrl,
    this.emailSent = false,
    this.emailSentAt,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String transactionId;
  final String? invoiceId;
  final String userId;
  final String? schoolId;
  final String receiptNumber;
  final double amountPaid;
  final String currency;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? pdfUrl;
  final bool emailSent;
  final DateTime? emailSentAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String? ?? json['transactionId'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? json['invoiceId'] as String?,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      receiptNumber: json['receipt_number'] as String? ?? json['receiptNumber'] as String? ?? '',
      amountPaid: (json['amount_paid'] as num? ?? json['amountPaid'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? '',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : json['paymentDate'] != null
              ? DateTime.parse(json['paymentDate'] as String)
              : DateTime.now(),
      pdfUrl: json['pdf_url'] as String? ?? json['pdfUrl'] as String?,
      emailSent: json['email_sent'] as bool? ?? json['emailSent'] as bool? ?? false,
      emailSentAt: json['email_sent_at'] != null
          ? DateTime.parse(json['email_sent_at'] as String)
          : json['emailSentAt'] != null
              ? DateTime.parse(json['emailSentAt'] as String)
              : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'invoice_id': invoiceId,
        'user_id': userId,
        'school_id': schoolId,
        'receipt_number': receiptNumber,
        'amount_paid': amountPaid,
        'currency': currency,
        'payment_method': paymentMethod,
        'payment_date': paymentDate.toIso8601String(),
        'pdf_url': pdfUrl,
        'email_sent': emailSent,
        'email_sent_at': emailSentAt?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReceiptModel.fromEntity(ReceiptEntity entity) {
    return ReceiptModel(
      id: entity.id,
      transactionId: entity.transactionId,
      invoiceId: entity.invoiceId,
      userId: entity.userId,
      schoolId: entity.schoolId,
      receiptNumber: entity.receiptNumber,
      amountPaid: entity.amountPaid,
      currency: entity.currency,
      paymentMethod: entity.paymentMethod,
      paymentDate: entity.paymentDate,
      pdfUrl: entity.pdfUrl,
      emailSent: entity.emailSent,
      emailSentAt: entity.emailSentAt,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  ReceiptEntity toEntity() {
    return ReceiptEntity(
      id: id,
      transactionId: transactionId,
      invoiceId: invoiceId,
      userId: userId,
      schoolId: schoolId,
      receiptNumber: receiptNumber,
      amountPaid: amountPaid,
      currency: currency,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      pdfUrl: pdfUrl,
      emailSent: emailSent,
      emailSentAt: emailSentAt,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  ReceiptModel copyWith({
    String? id,
    String? transactionId,
    String? invoiceId,
    String? userId,
    String? schoolId,
    String? receiptNumber,
    double? amountPaid,
    String? currency,
    String? paymentMethod,
    DateTime? paymentDate,
    String? pdfUrl,
    bool? emailSent,
    DateTime? emailSentAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      invoiceId: invoiceId ?? this.invoiceId,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          transactionId == other.transactionId &&
          invoiceId == other.invoiceId &&
          userId == other.userId &&
          schoolId == other.schoolId &&
          receiptNumber == other.receiptNumber &&
          amountPaid == other.amountPaid &&
          currency == other.currency &&
          paymentMethod == other.paymentMethod &&
          paymentDate == other.paymentDate &&
          pdfUrl == other.pdfUrl &&
          emailSent == other.emailSent &&
          emailSentAt == other.emailSentAt &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id, transactionId, invoiceId, userId, schoolId, receiptNumber,
        amountPaid, currency, paymentMethod, paymentDate, pdfUrl, emailSent,
        emailSentAt, metadata.hashCode, createdAt,
      );
}

/// Data-layer representation of an AI credit balance.
class AiCreditBalanceModel {
  const AiCreditBalanceModel({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    this.schoolId,
    this.totalCredits = 0,
    this.usedCredits = 0,
    this.remainingCredits = 0,
    required this.currentCycleStart,
    required this.currentCycleEnd,
    this.creditsExpire = true,
    this.expirationDate,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final BillingModel ownerType;
  final String? schoolId;
  final int totalCredits;
  final int usedCredits;
  final int remainingCredits;
  final DateTime currentCycleStart;
  final DateTime currentCycleEnd;
  final bool creditsExpire;
  final DateTime? expirationDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AiCreditBalanceModel.fromJson(Map<String, dynamic> json) {
    return AiCreditBalanceModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? json['ownerId'] as String? ?? '',
      ownerType: BillingModel.fromString(json['owner_type'] as String? ?? json['ownerType'] as String?) ?? BillingModel.schoolSaas,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      totalCredits: json['total_credits'] as int? ?? json['totalCredits'] as int? ?? 0,
      usedCredits: json['used_credits'] as int? ?? json['usedCredits'] as int? ?? 0,
      remainingCredits: json['remaining_credits'] as int? ?? json['remainingCredits'] as int? ?? 0,
      currentCycleStart: json['current_cycle_start'] != null
          ? DateTime.parse(json['current_cycle_start'] as String)
          : json['currentCycleStart'] != null
              ? DateTime.parse(json['currentCycleStart'] as String)
              : DateTime.now(),
      currentCycleEnd: json['current_cycle_end'] != null
          ? DateTime.parse(json['current_cycle_end'] as String)
          : json['currentCycleEnd'] != null
              ? DateTime.parse(json['currentCycleEnd'] as String)
              : DateTime.now(),
      creditsExpire: json['credits_expire'] as bool? ?? json['creditsExpire'] as bool? ?? true,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : json['expirationDate'] != null
              ? DateTime.parse(json['expirationDate'] as String)
              : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'owner_type': ownerType.value,
        'school_id': schoolId,
        'total_credits': totalCredits,
        'used_credits': usedCredits,
        'remaining_credits': remainingCredits,
        'current_cycle_start': currentCycleStart.toIso8601String(),
        'current_cycle_end': currentCycleEnd.toIso8601String(),
        'credits_expire': creditsExpire,
        'expiration_date': expirationDate?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AiCreditBalanceModel.fromEntity(AiCreditBalanceEntity entity) {
    return AiCreditBalanceModel(
      id: entity.id,
      ownerId: entity.ownerId,
      ownerType: entity.ownerType,
      schoolId: entity.schoolId,
      totalCredits: entity.totalCredits,
      usedCredits: entity.usedCredits,
      remainingCredits: entity.remainingCredits,
      currentCycleStart: entity.currentCycleStart,
      currentCycleEnd: entity.currentCycleEnd,
      creditsExpire: entity.creditsExpire,
      expirationDate: entity.expirationDate,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiCreditBalanceEntity toEntity() {
    return AiCreditBalanceEntity(
      id: id,
      ownerId: ownerId,
      ownerType: ownerType,
      schoolId: schoolId,
      totalCredits: totalCredits,
      usedCredits: usedCredits,
      remainingCredits: remainingCredits,
      currentCycleStart: currentCycleStart,
      currentCycleEnd: currentCycleEnd,
      creditsExpire: creditsExpire,
      expirationDate: expirationDate,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AiCreditBalanceModel copyWith({
    String? id,
    String? ownerId,
    BillingModel? ownerType,
    String? schoolId,
    int? totalCredits,
    int? usedCredits,
    int? remainingCredits,
    DateTime? currentCycleStart,
    DateTime? currentCycleEnd,
    bool? creditsExpire,
    DateTime? expirationDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiCreditBalanceModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerType: ownerType ?? this.ownerType,
      schoolId: schoolId ?? this.schoolId,
      totalCredits: totalCredits ?? this.totalCredits,
      usedCredits: usedCredits ?? this.usedCredits,
      remainingCredits: remainingCredits ?? this.remainingCredits,
      currentCycleStart: currentCycleStart ?? this.currentCycleStart,
      currentCycleEnd: currentCycleEnd ?? this.currentCycleEnd,
      creditsExpire: creditsExpire ?? this.creditsExpire,
      expirationDate: expirationDate ?? this.expirationDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCreditBalanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          ownerType == other.ownerType &&
          schoolId == other.schoolId &&
          totalCredits == other.totalCredits &&
          usedCredits == other.usedCredits &&
          remainingCredits == other.remainingCredits &&
          currentCycleStart == other.currentCycleStart &&
          currentCycleEnd == other.currentCycleEnd &&
          creditsExpire == other.creditsExpire &&
          expirationDate == other.expirationDate &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, ownerId, ownerType, schoolId, totalCredits, usedCredits,
        remainingCredits, currentCycleStart, currentCycleEnd, creditsExpire,
        expirationDate, metadata.hashCode, createdAt, updatedAt,
      );
}

/// Data-layer representation of an AI credit transaction.
class AiCreditTransactionModel {
  const AiCreditTransactionModel({
    required this.id,
    required this.balanceId,
    required this.ownerId,
    required this.ownerType,
    this.schoolId,
    required this.transactionType,
    required this.credits,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.featureName,
    this.referenceId,
    this.estimatedCostUsd = 0,
    this.description,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String balanceId;
  final String ownerId;
  final BillingModel ownerType;
  final String? schoolId;
  final CreditTransactionType transactionType;
  final int credits;
  final int balanceBefore;
  final int balanceAfter;
  final String? featureName;
  final String? referenceId;
  final double estimatedCostUsd;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory AiCreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return AiCreditTransactionModel(
      id: json['id'] as String,
      balanceId: json['balance_id'] as String? ?? json['balanceId'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? json['ownerId'] as String? ?? '',
      ownerType: BillingModel.fromString(json['owner_type'] as String? ?? json['ownerType'] as String?) ?? BillingModel.schoolSaas,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      transactionType: CreditTransactionType.fromString(json['transaction_type'] as String? ?? json['transactionType'] as String?) ?? CreditTransactionType.usage,
      credits: json['credits'] as int? ?? 0,
      balanceBefore: json['balance_before'] as int? ?? json['balanceBefore'] as int? ?? 0,
      balanceAfter: json['balance_after'] as int? ?? json['balanceAfter'] as int? ?? 0,
      featureName: json['feature_name'] as String? ?? json['featureName'] as String?,
      referenceId: json['reference_id'] as String? ?? json['referenceId'] as String?,
      estimatedCostUsd: (json['estimated_cost_usd'] as num? ?? json['estimatedCostUsd'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'balance_id': balanceId,
        'owner_id': ownerId,
        'owner_type': ownerType.value,
        'school_id': schoolId,
        'transaction_type': transactionType.value,
        'credits': credits,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'feature_name': featureName,
        'reference_id': referenceId,
        'estimated_cost_usd': estimatedCostUsd,
        'description': description,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiCreditTransactionModel.fromEntity(AiCreditTransactionEntity entity) {
    return AiCreditTransactionModel(
      id: entity.id,
      balanceId: entity.balanceId,
      ownerId: entity.ownerId,
      ownerType: entity.ownerType,
      schoolId: entity.schoolId,
      transactionType: entity.transactionType,
      credits: entity.credits,
      balanceBefore: entity.balanceBefore,
      balanceAfter: entity.balanceAfter,
      featureName: entity.featureName,
      referenceId: entity.referenceId,
      estimatedCostUsd: entity.estimatedCostUsd,
      description: entity.description,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  AiCreditTransactionEntity toEntity() {
    return AiCreditTransactionEntity(
      id: id,
      balanceId: balanceId,
      ownerId: ownerId,
      ownerType: ownerType,
      schoolId: schoolId,
      transactionType: transactionType,
      credits: credits,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      featureName: featureName,
      referenceId: referenceId,
      estimatedCostUsd: estimatedCostUsd,
      description: description,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  AiCreditTransactionModel copyWith({
    String? id,
    String? balanceId,
    String? ownerId,
    BillingModel? ownerType,
    String? schoolId,
    CreditTransactionType? transactionType,
    int? credits,
    int? balanceBefore,
    int? balanceAfter,
    String? featureName,
    String? referenceId,
    double? estimatedCostUsd,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AiCreditTransactionModel(
      id: id ?? this.id,
      balanceId: balanceId ?? this.balanceId,
      ownerId: ownerId ?? this.ownerId,
      ownerType: ownerType ?? this.ownerType,
      schoolId: schoolId ?? this.schoolId,
      transactionType: transactionType ?? this.transactionType,
      credits: credits ?? this.credits,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      featureName: featureName ?? this.featureName,
      referenceId: referenceId ?? this.referenceId,
      estimatedCostUsd: estimatedCostUsd ?? this.estimatedCostUsd,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCreditTransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          balanceId == other.balanceId &&
          ownerId == other.ownerId &&
          ownerType == other.ownerType &&
          schoolId == other.schoolId &&
          transactionType == other.transactionType &&
          credits == other.credits &&
          balanceBefore == other.balanceBefore &&
          balanceAfter == other.balanceAfter &&
          featureName == other.featureName &&
          referenceId == other.referenceId &&
          estimatedCostUsd == other.estimatedCostUsd &&
          description == other.description &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id, balanceId, ownerId, ownerType, schoolId, transactionType,
        credits, balanceBefore, balanceAfter, featureName, referenceId,
        estimatedCostUsd, description, metadata.hashCode, createdAt,
      );
}

/// Data-layer representation of a coupon.
class CouponModel {
  const CouponModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.discountPercent,
    this.maxDiscountAmount,
    this.applicableTiers = const [],
    this.applicableBillingModels = const [],
    this.applicablePlans = const [],
    this.maxRedemptions = 0,
    this.currentRedemptions = 0,
    this.maxRedemptionsPerUser = 1,
    this.durationMonths = 1,
    required this.validFrom,
    this.validUntil,
    this.trialDays,
    this.isActive = true,
    this.createdBy,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final CouponDiscountType discountType;
  final double discountValue;
  final double? discountPercent;
  final double? maxDiscountAmount;
  final List<String> applicableTiers;
  final List<String> applicableBillingModels;
  final List<String> applicablePlans;
  final int maxRedemptions;
  final int currentRedemptions;
  final int maxRedemptionsPerUser;
  final int durationMonths;
  final DateTime validFrom;
  final DateTime? validUntil;
  final int? trialDays;
  final bool isActive;
  final String? createdBy;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      discountType: CouponDiscountType.fromString(json['discount_type'] as String? ?? json['discountType'] as String?) ?? CouponDiscountType.percentage,
      discountValue: (json['discount_value'] as num? ?? json['discountValue'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discount_percent'] as num? ?? json['discountPercent'] as num?)?.toDouble(),
      maxDiscountAmount: (json['max_discount_amount'] as num? ?? json['maxDiscountAmount'] as num?)?.toDouble(),
      applicableTiers: (json['applicable_tiers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      applicableBillingModels: (json['applicable_billing_models'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      applicablePlans: (json['applicable_plans'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      maxRedemptions: json['max_redemptions'] as int? ?? json['maxRedemptions'] as int? ?? 0,
      currentRedemptions: json['current_redemptions'] as int? ?? json['currentRedemptions'] as int? ?? 0,
      maxRedemptionsPerUser: json['max_redemptions_per_user'] as int? ?? json['maxRedemptionsPerUser'] as int? ?? 1,
      durationMonths: json['duration_months'] as int? ?? json['durationMonths'] as int? ?? 1,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : json['validFrom'] != null
              ? DateTime.parse(json['validFrom'] as String)
              : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : json['validUntil'] != null
              ? DateTime.parse(json['validUntil'] as String)
              : null,
      trialDays: json['trial_days'] as int? ?? json['trialDays'] as int?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'discount_type': discountType.value,
        'discount_value': discountValue,
        'discount_percent': discountPercent,
        'max_discount_amount': maxDiscountAmount,
        'applicable_tiers': applicableTiers,
        'applicable_billing_models': applicableBillingModels,
        'applicable_plans': applicablePlans,
        'max_redemptions': maxRedemptions,
        'current_redemptions': currentRedemptions,
        'max_redemptions_per_user': maxRedemptionsPerUser,
        'duration_months': durationMonths,
        'valid_from': validFrom.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'trial_days': trialDays,
        'is_active': isActive,
        'created_by': createdBy,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CouponModel.fromEntity(CouponEntity entity) {
    return CouponModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      description: entity.description,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      discountPercent: entity.discountPercent,
      maxDiscountAmount: entity.maxDiscountAmount,
      applicableTiers: entity.applicableTiers,
      applicableBillingModels: entity.applicableBillingModels,
      applicablePlans: entity.applicablePlans,
      maxRedemptions: entity.maxRedemptions,
      currentRedemptions: entity.currentRedemptions,
      maxRedemptionsPerUser: entity.maxRedemptionsPerUser,
      durationMonths: entity.durationMonths,
      validFrom: entity.validFrom,
      validUntil: entity.validUntil,
      trialDays: entity.trialDays,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CouponEntity toEntity() {
    return CouponEntity(
      id: id,
      code: code,
      name: name,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      discountPercent: discountPercent,
      maxDiscountAmount: maxDiscountAmount,
      applicableTiers: applicableTiers,
      applicableBillingModels: applicableBillingModels,
      applicablePlans: applicablePlans,
      maxRedemptions: maxRedemptions,
      currentRedemptions: currentRedemptions,
      maxRedemptionsPerUser: maxRedemptionsPerUser,
      durationMonths: durationMonths,
      validFrom: validFrom,
      validUntil: validUntil,
      trialDays: trialDays,
      isActive: isActive,
      createdBy: createdBy,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CouponModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    CouponDiscountType? discountType,
    double? discountValue,
    double? discountPercent,
    double? maxDiscountAmount,
    List<String>? applicableTiers,
    List<String>? applicableBillingModels,
    List<String>? applicablePlans,
    int? maxRedemptions,
    int? currentRedemptions,
    int? maxRedemptionsPerUser,
    int? durationMonths,
    DateTime? validFrom,
    DateTime? validUntil,
    int? trialDays,
    bool? isActive,
    String? createdBy,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      applicableTiers: applicableTiers ?? this.applicableTiers,
      applicableBillingModels: applicableBillingModels ?? this.applicableBillingModels,
      applicablePlans: applicablePlans ?? this.applicablePlans,
      maxRedemptions: maxRedemptions ?? this.maxRedemptions,
      currentRedemptions: currentRedemptions ?? this.currentRedemptions,
      maxRedemptionsPerUser: maxRedemptionsPerUser ?? this.maxRedemptionsPerUser,
      durationMonths: durationMonths ?? this.durationMonths,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      trialDays: trialDays ?? this.trialDays,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouponModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          description == other.description &&
          discountType == other.discountType &&
          discountValue == other.discountValue &&
          discountPercent == other.discountPercent &&
          maxDiscountAmount == other.maxDiscountAmount &&
          _listEquals(applicableTiers, other.applicableTiers) &&
          _listEquals(applicableBillingModels, other.applicableBillingModels) &&
          _listEquals(applicablePlans, other.applicablePlans) &&
          maxRedemptions == other.maxRedemptions &&
          currentRedemptions == other.currentRedemptions &&
          maxRedemptionsPerUser == other.maxRedemptionsPerUser &&
          durationMonths == other.durationMonths &&
          validFrom == other.validFrom &&
          validUntil == other.validUntil &&
          trialDays == other.trialDays &&
          isActive == other.isActive &&
          createdBy == other.createdBy &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id, code, name, description, discountType, discountValue,
        discountPercent, maxDiscountAmount,
        ...applicableTiers, ...applicableBillingModels,
        ...applicablePlans, maxRedemptions, currentRedemptions,
        maxRedemptionsPerUser, durationMonths, validFrom, validUntil,
        trialDays, isActive, createdBy, metadata, createdAt, updatedAt,
      ]);
}

/// Data-layer representation of a referral code.
class ReferralCodeModel {
  const ReferralCodeModel({
    required this.id,
    required this.referrerId,
    required this.referrerType,
    this.schoolId,
    required this.code,
    this.isActive = true,
    this.rewardType = ReferralRewardType.creditDays,
    this.rewardValue = 0,
    this.rewardDescription,
    this.refereeRewardType = ReferralRewardType.aiCredits,
    this.refereeRewardValue = 0,
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.totalRewardsEarned = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String referrerId;
  final BillingModel referrerType;
  final String? schoolId;
  final String code;
  final bool isActive;
  final ReferralRewardType rewardType;
  final double rewardValue;
  final String? rewardDescription;
  final ReferralRewardType refereeRewardType;
  final double refereeRewardValue;
  final int totalReferrals;
  final int successfulReferrals;
  final double totalRewardsEarned;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return ReferralCodeModel(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String? ?? json['referrerId'] as String? ?? '',
      referrerType: BillingModel.fromString(json['referrer_type'] as String? ?? json['referrerType'] as String?) ?? BillingModel.schoolSaas,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      rewardType: ReferralRewardType.fromString(json['reward_type'] as String? ?? json['rewardType'] as String?) ?? ReferralRewardType.creditDays,
      rewardValue: (json['reward_value'] as num? ?? json['rewardValue'] as num?)?.toDouble() ?? 0,
      rewardDescription: json['reward_description'] as String? ?? json['rewardDescription'] as String?,
      refereeRewardType: ReferralRewardType.fromString(json['referee_reward_type'] as String? ?? json['refereeRewardType'] as String?) ?? ReferralRewardType.aiCredits,
      refereeRewardValue: (json['referee_reward_value'] as num? ?? json['refereeRewardValue'] as num?)?.toDouble() ?? 0,
      totalReferrals: json['total_referrals'] as int? ?? json['totalReferrals'] as int? ?? 0,
      successfulReferrals: json['successful_referrals'] as int? ?? json['successfulReferrals'] as int? ?? 0,
      totalRewardsEarned: (json['total_rewards_earned'] as num? ?? json['totalRewardsEarned'] as num?)?.toDouble() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referrer_id': referrerId,
        'referrer_type': referrerType.value,
        'school_id': schoolId,
        'code': code,
        'is_active': isActive,
        'reward_type': rewardType.value,
        'reward_value': rewardValue,
        'reward_description': rewardDescription,
        'referee_reward_type': refereeRewardType.value,
        'referee_reward_value': refereeRewardValue,
        'total_referrals': totalReferrals,
        'successful_referrals': successfulReferrals,
        'total_rewards_earned': totalRewardsEarned,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ReferralCodeModel.fromEntity(ReferralCodeEntity entity) {
    return ReferralCodeModel(
      id: entity.id,
      referrerId: entity.referrerId,
      referrerType: entity.referrerType,
      schoolId: entity.schoolId,
      code: entity.code,
      isActive: entity.isActive,
      rewardType: entity.rewardType,
      rewardValue: entity.rewardValue,
      rewardDescription: entity.rewardDescription,
      refereeRewardType: entity.refereeRewardType,
      refereeRewardValue: entity.refereeRewardValue,
      totalReferrals: entity.totalReferrals,
      successfulReferrals: entity.successfulReferrals,
      totalRewardsEarned: entity.totalRewardsEarned,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ReferralCodeEntity toEntity() {
    return ReferralCodeEntity(
      id: id,
      referrerId: referrerId,
      referrerType: referrerType,
      schoolId: schoolId,
      code: code,
      isActive: isActive,
      rewardType: rewardType,
      rewardValue: rewardValue,
      rewardDescription: rewardDescription,
      refereeRewardType: refereeRewardType,
      refereeRewardValue: refereeRewardValue,
      totalReferrals: totalReferrals,
      successfulReferrals: successfulReferrals,
      totalRewardsEarned: totalRewardsEarned,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ReferralCodeModel copyWith({
    String? id,
    String? referrerId,
    BillingModel? referrerType,
    String? schoolId,
    String? code,
    bool? isActive,
    ReferralRewardType? rewardType,
    double? rewardValue,
    String? rewardDescription,
    ReferralRewardType? refereeRewardType,
    double? refereeRewardValue,
    int? totalReferrals,
    int? successfulReferrals,
    double? totalRewardsEarned,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralCodeModel(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referrerType: referrerType ?? this.referrerType,
      schoolId: schoolId ?? this.schoolId,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      rewardType: rewardType ?? this.rewardType,
      rewardValue: rewardValue ?? this.rewardValue,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      refereeRewardType: refereeRewardType ?? this.refereeRewardType,
      refereeRewardValue: refereeRewardValue ?? this.refereeRewardValue,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      totalRewardsEarned: totalRewardsEarned ?? this.totalRewardsEarned,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralCodeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          referrerId == other.referrerId &&
          referrerType == other.referrerType &&
          schoolId == other.schoolId &&
          code == other.code &&
          isActive == other.isActive &&
          rewardType == other.rewardType &&
          rewardValue == other.rewardValue &&
          rewardDescription == other.rewardDescription &&
          refereeRewardType == other.refereeRewardType &&
          refereeRewardValue == other.refereeRewardValue &&
          totalReferrals == other.totalReferrals &&
          successfulReferrals == other.successfulReferrals &&
          totalRewardsEarned == other.totalRewardsEarned &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, referrerId, referrerType, schoolId, code, isActive, rewardType,
        rewardValue, rewardDescription, refereeRewardType, refereeRewardValue,
        totalReferrals, successfulReferrals, totalRewardsEarned,
        metadata.hashCode, createdAt, updatedAt,
      );
}

/// Data-layer representation of a license.
class LicenseModel {
  const LicenseModel({
    required this.id,
    required this.subscriptionId,
    this.schoolId,
    this.userId,
    required this.licenseType,
    required this.licenseKey,
    this.seatsTotal = 1,
    this.seatsUsed = 0,
    required this.issuedAt,
    required this.expiresAt,
    this.isActive = true,
    this.revokedAt,
    this.revokeReason,
    this.autoRenew = true,
    this.renewalReminderSent = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subscriptionId;
  final String? schoolId;
  final String? userId;
  final LicenseType licenseType;
  final String licenseKey;
  final int seatsTotal;
  final int seatsUsed;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? revokedAt;
  final String? revokeReason;
  final bool autoRenew;
  final bool renewalReminderSent;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String? ?? json['subscriptionId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      licenseType: LicenseType.fromString(json['license_type'] as String? ?? json['licenseType'] as String?) ?? LicenseType.school,
      licenseKey: json['license_key'] as String? ?? json['licenseKey'] as String? ?? '',
      seatsTotal: json['seats_total'] as int? ?? json['seatsTotal'] as int? ?? 1,
      seatsUsed: json['seats_used'] as int? ?? json['seatsUsed'] as int? ?? 0,
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'] as String)
          : json['issuedAt'] != null
              ? DateTime.parse(json['issuedAt'] as String)
              : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : DateTime.now(),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
      revokeReason: json['revoke_reason'] as String? ?? json['revokeReason'] as String?,
      autoRenew: json['auto_renew'] as bool? ?? json['autoRenew'] as bool? ?? true,
      renewalReminderSent: json['renewal_reminder_sent'] as bool? ?? json['renewalReminderSent'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscription_id': subscriptionId,
        'school_id': schoolId,
        'user_id': userId,
        'license_type': licenseType.value,
        'license_key': licenseKey,
        'seats_total': seatsTotal,
        'seats_used': seatsUsed,
        'issued_at': issuedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': isActive,
        'revoked_at': revokedAt?.toIso8601String(),
        'revoke_reason': revokeReason,
        'auto_renew': autoRenew,
        'renewal_reminder_sent': renewalReminderSent,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory LicenseModel.fromEntity(LicenseEntity entity) {
    return LicenseModel(
      id: entity.id,
      subscriptionId: entity.subscriptionId,
      schoolId: entity.schoolId,
      userId: entity.userId,
      licenseType: entity.licenseType,
      licenseKey: entity.licenseKey,
      seatsTotal: entity.seatsTotal,
      seatsUsed: entity.seatsUsed,
      issuedAt: entity.issuedAt,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      revokedAt: entity.revokedAt,
      revokeReason: entity.revokeReason,
      autoRenew: entity.autoRenew,
      renewalReminderSent: entity.renewalReminderSent,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LicenseEntity toEntity() {
    return LicenseEntity(
      id: id,
      subscriptionId: subscriptionId,
      schoolId: schoolId,
      userId: userId,
      licenseType: licenseType,
      licenseKey: licenseKey,
      seatsTotal: seatsTotal,
      seatsUsed: seatsUsed,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      isActive: isActive,
      revokedAt: revokedAt,
      revokeReason: revokeReason,
      autoRenew: autoRenew,
      renewalReminderSent: renewalReminderSent,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  LicenseModel copyWith({
    String? id,
    String? subscriptionId,
    String? schoolId,
    String? userId,
    LicenseType? licenseType,
    String? licenseKey,
    int? seatsTotal,
    int? seatsUsed,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? revokedAt,
    String? revokeReason,
    bool? autoRenew,
    bool? renewalReminderSent,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      licenseType: licenseType ?? this.licenseType,
      licenseKey: licenseKey ?? this.licenseKey,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsUsed: seatsUsed ?? this.seatsUsed,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      revokedAt: revokedAt ?? this.revokedAt,
      revokeReason: revokeReason ?? this.revokeReason,
      autoRenew: autoRenew ?? this.autoRenew,
      renewalReminderSent: renewalReminderSent ?? this.renewalReminderSent,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subscriptionId == other.subscriptionId &&
          schoolId == other.schoolId &&
          userId == other.userId &&
          licenseType == other.licenseType &&
          licenseKey == other.licenseKey &&
          seatsTotal == other.seatsTotal &&
          seatsUsed == other.seatsUsed &&
          issuedAt == other.issuedAt &&
          expiresAt == other.expiresAt &&
          isActive == other.isActive &&
          revokedAt == other.revokedAt &&
          revokeReason == other.revokeReason &&
          autoRenew == other.autoRenew &&
          renewalReminderSent == other.renewalReminderSent &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, subscriptionId, schoolId, userId, licenseType, licenseKey,
        seatsTotal, seatsUsed, issuedAt, expiresAt, isActive, revokedAt,
        revokeReason, autoRenew, renewalReminderSent, metadata.hashCode,
        createdAt, updatedAt,
      );
}

/// Data-layer representation of an AI credit pack.
class AiCreditPackModel {
  const AiCreditPackModel({
    required this.id,
    required this.name,
    this.description,
    required this.credits,
    required this.price,
    this.currency = 'NGN',
    this.validityDays = 365,
    this.isActive = true,
    this.sortOrder = 0,
    this.applicableBillingModels = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final int credits;
  final double price;
  final String currency;
  final int validityDays;
  final bool isActive;
  final int sortOrder;
  final List<String> applicableBillingModels;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AiCreditPackModel.fromJson(Map<String, dynamic> json) {
    return AiCreditPackModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      credits: json['credits'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      validityDays: json['validity_days'] as int? ?? json['validityDays'] as int? ?? 365,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      applicableBillingModels: (json['applicable_billing_models'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'credits': credits,
        'price': price,
        'currency': currency,
        'validity_days': validityDays,
        'is_active': isActive,
        'sort_order': sortOrder,
        'applicable_billing_models': applicableBillingModels,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AiCreditPackModel.fromEntity(AiCreditPackEntity entity) {
    return AiCreditPackModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      credits: entity.credits,
      price: entity.price,
      currency: entity.currency,
      validityDays: entity.validityDays,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      applicableBillingModels: entity.applicableBillingModels,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiCreditPackEntity toEntity() {
    return AiCreditPackEntity(
      id: id,
      name: name,
      description: description,
      credits: credits,
      price: price,
      currency: currency,
      validityDays: validityDays,
      isActive: isActive,
      sortOrder: sortOrder,
      applicableBillingModels: applicableBillingModels,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AiCreditPackModel copyWith({
    String? id,
    String? name,
    String? description,
    int? credits,
    double? price,
    String? currency,
    int? validityDays,
    bool? isActive,
    int? sortOrder,
    List<String>? applicableBillingModels,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiCreditPackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      credits: credits ?? this.credits,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      validityDays: validityDays ?? this.validityDays,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      applicableBillingModels: applicableBillingModels ?? this.applicableBillingModels,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCreditPackModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          credits == other.credits &&
          price == other.price &&
          currency == other.currency &&
          validityDays == other.validityDays &&
          isActive == other.isActive &&
          sortOrder == other.sortOrder &&
          _listEquals(applicableBillingModels, other.applicableBillingModels) &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, name, description, credits, price, currency, validityDays,
        isActive, sortOrder, Object.hashAll(applicableBillingModels),
        metadata.hashCode, createdAt, updatedAt,
      );
}

/// Data-layer representation of a school billing profile.
class SchoolBillingProfileModel {
  const SchoolBillingProfileModel({
    required this.id,
    required this.schoolId,
    this.billingContactName,
    this.billingContactEmail,
    this.billingContactPhone,
    this.billingAddress,
    this.taxIdNumber,
    this.taxExempt = false,
    this.defaultPaymentMethod,
    this.paymentMethods = const [],
    this.autoRenew = true,
    this.renewalReminderDays = 14,
    this.currentStudentCount = 0,
    this.currentTeacherCount = 0,
    this.currentStorageUsedMb = 0,
    this.currentAiCreditsUsed = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String? billingContactName;
  final String? billingContactEmail;
  final String? billingContactPhone;
  final String? billingAddress;
  final String? taxIdNumber;
  final bool taxExempt;
  final String? defaultPaymentMethod;
  final List<Map<String, dynamic>> paymentMethods;
  final bool autoRenew;
  final int renewalReminderDays;
  final int currentStudentCount;
  final int currentTeacherCount;
  final double currentStorageUsedMb;
  final int currentAiCreditsUsed;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SchoolBillingProfileModel.fromJson(Map<String, dynamic> json) {
    return SchoolBillingProfileModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      billingContactName: json['billing_contact_name'] as String? ?? json['billingContactName'] as String?,
      billingContactEmail: json['billing_contact_email'] as String? ?? json['billingContactEmail'] as String?,
      billingContactPhone: json['billing_contact_phone'] as String? ?? json['billingContactPhone'] as String?,
      billingAddress: json['billing_address'] as String? ?? json['billingAddress'] as String?,
      taxIdNumber: json['tax_id_number'] as String? ?? json['taxIdNumber'] as String?,
      taxExempt: json['tax_exempt'] as bool? ?? json['taxExempt'] as bool? ?? false,
      defaultPaymentMethod: json['default_payment_method'] as String? ?? json['defaultPaymentMethod'] as String?,
      paymentMethods: (json['payment_methods'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      autoRenew: json['auto_renew'] as bool? ?? json['autoRenew'] as bool? ?? true,
      renewalReminderDays: json['renewal_reminder_days'] as int? ?? json['renewalReminderDays'] as int? ?? 14,
      currentStudentCount: json['current_student_count'] as int? ?? json['currentStudentCount'] as int? ?? 0,
      currentTeacherCount: json['current_teacher_count'] as int? ?? json['currentTeacherCount'] as int? ?? 0,
      currentStorageUsedMb: (json['current_storage_used_mb'] as num? ?? json['currentStorageUsedMb'] as num?)?.toDouble() ?? 0,
      currentAiCreditsUsed: json['current_ai_credits_used'] as int? ?? json['currentAiCreditsUsed'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'billing_contact_name': billingContactName,
        'billing_contact_email': billingContactEmail,
        'billing_contact_phone': billingContactPhone,
        'billing_address': billingAddress,
        'tax_id_number': taxIdNumber,
        'tax_exempt': taxExempt,
        'default_payment_method': defaultPaymentMethod,
        'payment_methods': paymentMethods,
        'auto_renew': autoRenew,
        'renewal_reminder_days': renewalReminderDays,
        'current_student_count': currentStudentCount,
        'current_teacher_count': currentTeacherCount,
        'current_storage_used_mb': currentStorageUsedMb,
        'current_ai_credits_used': currentAiCreditsUsed,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SchoolBillingProfileModel.fromEntity(SchoolBillingProfileEntity entity) {
    return SchoolBillingProfileModel(
      id: entity.id,
      schoolId: entity.schoolId,
      billingContactName: entity.billingContactName,
      billingContactEmail: entity.billingContactEmail,
      billingContactPhone: entity.billingContactPhone,
      billingAddress: entity.billingAddress,
      taxIdNumber: entity.taxIdNumber,
      taxExempt: entity.taxExempt,
      defaultPaymentMethod: entity.defaultPaymentMethod,
      paymentMethods: entity.paymentMethods,
      autoRenew: entity.autoRenew,
      renewalReminderDays: entity.renewalReminderDays,
      currentStudentCount: entity.currentStudentCount,
      currentTeacherCount: entity.currentTeacherCount,
      currentStorageUsedMb: entity.currentStorageUsedMb,
      currentAiCreditsUsed: entity.currentAiCreditsUsed,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolBillingProfileEntity toEntity() {
    return SchoolBillingProfileEntity(
      id: id,
      schoolId: schoolId,
      billingContactName: billingContactName,
      billingContactEmail: billingContactEmail,
      billingContactPhone: billingContactPhone,
      billingAddress: billingAddress,
      taxIdNumber: taxIdNumber,
      taxExempt: taxExempt,
      defaultPaymentMethod: defaultPaymentMethod,
      paymentMethods: paymentMethods,
      autoRenew: autoRenew,
      renewalReminderDays: renewalReminderDays,
      currentStudentCount: currentStudentCount,
      currentTeacherCount: currentTeacherCount,
      currentStorageUsedMb: currentStorageUsedMb,
      currentAiCreditsUsed: currentAiCreditsUsed,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SchoolBillingProfileModel copyWith({
    String? id,
    String? schoolId,
    String? billingContactName,
    String? billingContactEmail,
    String? billingContactPhone,
    String? billingAddress,
    String? taxIdNumber,
    bool? taxExempt,
    String? defaultPaymentMethod,
    List<Map<String, dynamic>>? paymentMethods,
    bool? autoRenew,
    int? renewalReminderDays,
    int? currentStudentCount,
    int? currentTeacherCount,
    double? currentStorageUsedMb,
    int? currentAiCreditsUsed,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolBillingProfileModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      billingContactName: billingContactName ?? this.billingContactName,
      billingContactEmail: billingContactEmail ?? this.billingContactEmail,
      billingContactPhone: billingContactPhone ?? this.billingContactPhone,
      billingAddress: billingAddress ?? this.billingAddress,
      taxIdNumber: taxIdNumber ?? this.taxIdNumber,
      taxExempt: taxExempt ?? this.taxExempt,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      autoRenew: autoRenew ?? this.autoRenew,
      renewalReminderDays: renewalReminderDays ?? this.renewalReminderDays,
      currentStudentCount: currentStudentCount ?? this.currentStudentCount,
      currentTeacherCount: currentTeacherCount ?? this.currentTeacherCount,
      currentStorageUsedMb: currentStorageUsedMb ?? this.currentStorageUsedMb,
      currentAiCreditsUsed: currentAiCreditsUsed ?? this.currentAiCreditsUsed,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolBillingProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          billingContactName == other.billingContactName &&
          billingContactEmail == other.billingContactEmail &&
          billingContactPhone == other.billingContactPhone &&
          billingAddress == other.billingAddress &&
          taxIdNumber == other.taxIdNumber &&
          taxExempt == other.taxExempt &&
          defaultPaymentMethod == other.defaultPaymentMethod &&
          _listMapEquals(paymentMethods, other.paymentMethods) &&
          autoRenew == other.autoRenew &&
          renewalReminderDays == other.renewalReminderDays &&
          currentStudentCount == other.currentStudentCount &&
          currentTeacherCount == other.currentTeacherCount &&
          currentStorageUsedMb == other.currentStorageUsedMb &&
          currentAiCreditsUsed == other.currentAiCreditsUsed &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, schoolId, billingContactName, billingContactEmail,
        billingContactPhone, billingAddress, taxIdNumber, taxExempt,
        defaultPaymentMethod, paymentMethods.hashCode, autoRenew,
        renewalReminderDays, currentStudentCount, currentTeacherCount,
        currentStorageUsedMb, currentAiCreditsUsed, metadata.hashCode,
        createdAt, updatedAt,
      );
}

/// Data-layer representation of a revenue data point.
class RevenueDataPointModel {
  const RevenueDataPointModel({
    required this.period,
    this.totalRevenue = 0,
    this.subscriptionRevenue = 0,
    this.aiCreditRevenue = 0,
    this.setupFeeRevenue = 0,
    this.refundAmount = 0,
    this.netRevenue = 0,
    this.processorFees = 0,
    this.activeSubscriptions = 0,
    this.newSubscriptions = 0,
    this.cancelledSubscriptions = 0,
    this.churnRate = 0,
    this.trialConversions = 0,
    this.teacherSaasRevenue = 0,
    this.schoolSaasRevenue = 0,
    this.enterpriseSaasRevenue = 0,
    this.aiCreditsSold = 0,
    this.aiCreditsUsed = 0,
    this.currency = 'NGN',
  });

  final String period;
  final double totalRevenue;
  final double subscriptionRevenue;
  final double aiCreditRevenue;
  final double setupFeeRevenue;
  final double refundAmount;
  final double netRevenue;
  final double processorFees;
  final int activeSubscriptions;
  final int newSubscriptions;
  final int cancelledSubscriptions;
  final double churnRate;
  final int trialConversions;
  final double teacherSaasRevenue;
  final double schoolSaasRevenue;
  final double enterpriseSaasRevenue;
  final int aiCreditsSold;
  final int aiCreditsUsed;
  final String currency;

  factory RevenueDataPointModel.fromJson(Map<String, dynamic> json) {
    return RevenueDataPointModel(
      period: json['period'] as String? ?? json['period_start'] as String? ?? '',
      totalRevenue: (json['total_revenue'] as num? ?? json['totalRevenue'] as num?)?.toDouble() ?? 0,
      subscriptionRevenue: (json['subscription_revenue'] as num? ?? json['subscriptionRevenue'] as num?)?.toDouble() ?? 0,
      aiCreditRevenue: (json['ai_credit_revenue'] as num? ?? json['aiCreditRevenue'] as num?)?.toDouble() ?? 0,
      setupFeeRevenue: (json['setup_fee_revenue'] as num? ?? json['setupFeeRevenue'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refund_amount'] as num? ?? json['refundAmount'] as num?)?.toDouble() ?? 0,
      netRevenue: (json['net_revenue'] as num? ?? json['netRevenue'] as num?)?.toDouble() ?? 0,
      processorFees: (json['processor_fees'] as num? ?? json['processorFees'] as num?)?.toDouble() ?? 0,
      activeSubscriptions: json['active_subscriptions'] as int? ?? json['activeSubscriptions'] as int? ?? 0,
      newSubscriptions: json['new_subscriptions'] as int? ?? json['newSubscriptions'] as int? ?? 0,
      cancelledSubscriptions: json['cancelled_subscriptions'] as int? ?? json['cancelledSubscriptions'] as int? ?? 0,
      churnRate: (json['churn_rate'] as num? ?? json['churnRate'] as num?)?.toDouble() ?? 0,
      trialConversions: json['trial_conversions'] as int? ?? json['trialConversions'] as int? ?? 0,
      teacherSaasRevenue: (json['teacher_saas_revenue'] as num? ?? json['teacherSaasRevenue'] as num?)?.toDouble() ?? 0,
      schoolSaasRevenue: (json['school_saas_revenue'] as num? ?? json['schoolSaasRevenue'] as num?)?.toDouble() ?? 0,
      enterpriseSaasRevenue: (json['enterprise_saas_revenue'] as num? ?? json['enterpriseSaasRevenue'] as num?)?.toDouble() ?? 0,
      aiCreditsSold: json['ai_credits_sold'] as int? ?? json['aiCreditsSold'] as int? ?? 0,
      aiCreditsUsed: json['ai_credits_used'] as int? ?? json['aiCreditsUsed'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
    );
  }

  Map<String, dynamic> toJson() => {
        'period_start': period,
        'total_revenue': totalRevenue,
        'subscription_revenue': subscriptionRevenue,
        'ai_credit_revenue': aiCreditRevenue,
        'setup_fee_revenue': setupFeeRevenue,
        'refund_amount': refundAmount,
        'net_revenue': netRevenue,
        'processor_fees': processorFees,
        'active_subscriptions': activeSubscriptions,
        'new_subscriptions': newSubscriptions,
        'cancelled_subscriptions': cancelledSubscriptions,
        'churn_rate': churnRate,
        'trial_conversions': trialConversions,
        'teacher_saas_revenue': teacherSaasRevenue,
        'school_saas_revenue': schoolSaasRevenue,
        'enterprise_saas_revenue': enterpriseSaasRevenue,
        'ai_credits_sold': aiCreditsSold,
        'ai_credits_used': aiCreditsUsed,
        'currency': currency,
      };

  factory RevenueDataPointModel.fromEntity(RevenueDataPoint entity) {
    return RevenueDataPointModel(
      period: entity.period,
      totalRevenue: entity.totalRevenue,
      subscriptionRevenue: entity.subscriptionRevenue,
      aiCreditRevenue: entity.aiCreditRevenue,
      setupFeeRevenue: entity.setupFeeRevenue,
      refundAmount: entity.refundAmount,
      netRevenue: entity.netRevenue,
      processorFees: entity.processorFees,
      activeSubscriptions: entity.activeSubscriptions,
      newSubscriptions: entity.newSubscriptions,
      cancelledSubscriptions: entity.cancelledSubscriptions,
      churnRate: entity.churnRate,
      trialConversions: entity.trialConversions,
      teacherSaasRevenue: entity.teacherSaasRevenue,
      schoolSaasRevenue: entity.schoolSaasRevenue,
      enterpriseSaasRevenue: entity.enterpriseSaasRevenue,
      aiCreditsSold: entity.aiCreditsSold,
      aiCreditsUsed: entity.aiCreditsUsed,
      currency: entity.currency,
    );
  }

  RevenueDataPoint toEntity() {
    return RevenueDataPoint(
      period: period,
      totalRevenue: totalRevenue,
      subscriptionRevenue: subscriptionRevenue,
      aiCreditRevenue: aiCreditRevenue,
      setupFeeRevenue: setupFeeRevenue,
      refundAmount: refundAmount,
      netRevenue: netRevenue,
      processorFees: processorFees,
      activeSubscriptions: activeSubscriptions,
      newSubscriptions: newSubscriptions,
      cancelledSubscriptions: cancelledSubscriptions,
      churnRate: churnRate,
      trialConversions: trialConversions,
      teacherSaasRevenue: teacherSaasRevenue,
      schoolSaasRevenue: schoolSaasRevenue,
      enterpriseSaasRevenue: enterpriseSaasRevenue,
      aiCreditsSold: aiCreditsSold,
      aiCreditsUsed: aiCreditsUsed,
      currency: currency,
    );
  }

  RevenueDataPointModel copyWith({
    String? period,
    double? totalRevenue,
    double? subscriptionRevenue,
    double? aiCreditRevenue,
    double? setupFeeRevenue,
    double? refundAmount,
    double? netRevenue,
    double? processorFees,
    int? activeSubscriptions,
    int? newSubscriptions,
    int? cancelledSubscriptions,
    double? churnRate,
    int? trialConversions,
    double? teacherSaasRevenue,
    double? schoolSaasRevenue,
    double? enterpriseSaasRevenue,
    int? aiCreditsSold,
    int? aiCreditsUsed,
    String? currency,
  }) {
    return RevenueDataPointModel(
      period: period ?? this.period,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      subscriptionRevenue: subscriptionRevenue ?? this.subscriptionRevenue,
      aiCreditRevenue: aiCreditRevenue ?? this.aiCreditRevenue,
      setupFeeRevenue: setupFeeRevenue ?? this.setupFeeRevenue,
      refundAmount: refundAmount ?? this.refundAmount,
      netRevenue: netRevenue ?? this.netRevenue,
      processorFees: processorFees ?? this.processorFees,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      newSubscriptions: newSubscriptions ?? this.newSubscriptions,
      cancelledSubscriptions: cancelledSubscriptions ?? this.cancelledSubscriptions,
      churnRate: churnRate ?? this.churnRate,
      trialConversions: trialConversions ?? this.trialConversions,
      teacherSaasRevenue: teacherSaasRevenue ?? this.teacherSaasRevenue,
      schoolSaasRevenue: schoolSaasRevenue ?? this.schoolSaasRevenue,
      enterpriseSaasRevenue: enterpriseSaasRevenue ?? this.enterpriseSaasRevenue,
      aiCreditsSold: aiCreditsSold ?? this.aiCreditsSold,
      aiCreditsUsed: aiCreditsUsed ?? this.aiCreditsUsed,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevenueDataPointModel &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          totalRevenue == other.totalRevenue &&
          subscriptionRevenue == other.subscriptionRevenue &&
          aiCreditRevenue == other.aiCreditRevenue &&
          setupFeeRevenue == other.setupFeeRevenue &&
          refundAmount == other.refundAmount &&
          netRevenue == other.netRevenue &&
          processorFees == other.processorFees &&
          activeSubscriptions == other.activeSubscriptions &&
          newSubscriptions == other.newSubscriptions &&
          cancelledSubscriptions == other.cancelledSubscriptions &&
          churnRate == other.churnRate &&
          trialConversions == other.trialConversions &&
          teacherSaasRevenue == other.teacherSaasRevenue &&
          schoolSaasRevenue == other.schoolSaasRevenue &&
          enterpriseSaasRevenue == other.enterpriseSaasRevenue &&
          aiCreditsSold == other.aiCreditsSold &&
          aiCreditsUsed == other.aiCreditsUsed &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(
        period, totalRevenue, subscriptionRevenue, aiCreditRevenue,
        setupFeeRevenue, refundAmount, netRevenue, processorFees,
        activeSubscriptions, newSubscriptions, cancelledSubscriptions,
        churnRate, trialConversions, teacherSaasRevenue, schoolSaasRevenue,
        enterpriseSaasRevenue, aiCreditsSold, aiCreditsUsed, currency,
      );
}

/// Data-layer representation of a billing notification.
class BillingNotificationModel {
  const BillingNotificationModel({
    required this.id,
    required this.userId,
    this.schoolId,
    this.subscriptionId,
    this.transactionId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.inAppSent = false,
    this.pushSent = false,
    this.emailSent = false,
    this.smsSent = false,
    this.isRead = false,
    this.readAt,
    required this.scheduledAt,
    this.sentAt,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? schoolId;
  final String? subscriptionId;
  final String? transactionId;
  final BillingNotificationType notificationType;
  final String title;
  final String message;
  final bool inAppSent;
  final bool pushSent;
  final bool emailSent;
  final bool smsSent;
  final bool isRead;
  final DateTime? readAt;
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory BillingNotificationModel.fromJson(Map<String, dynamic> json) {
    return BillingNotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      subscriptionId: json['subscription_id'] as String? ?? json['subscriptionId'] as String?,
      transactionId: json['transaction_id'] as String? ?? json['transactionId'] as String?,
      notificationType: BillingNotificationType.fromString(json['notification_type'] as String? ?? json['notificationType'] as String?) ?? BillingNotificationType.paymentSuccess,
      title: json['title'] as String,
      message: json['message'] as String,
      inAppSent: json['in_app_sent'] as bool? ?? json['inAppSent'] as bool? ?? false,
      pushSent: json['push_sent'] as bool? ?? json['pushSent'] as bool? ?? false,
      emailSent: json['email_sent'] as bool? ?? json['emailSent'] as bool? ?? false,
      smsSent: json['sms_sent'] as bool? ?? json['smsSent'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : json['scheduledAt'] != null
              ? DateTime.parse(json['scheduledAt'] as String)
              : DateTime.now(),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'school_id': schoolId,
        'subscription_id': subscriptionId,
        'transaction_id': transactionId,
        'notification_type': notificationType.value,
        'title': title,
        'message': message,
        'in_app_sent': inAppSent,
        'push_sent': pushSent,
        'email_sent': emailSent,
        'sms_sent': smsSent,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'scheduled_at': scheduledAt.toIso8601String(),
        'sent_at': sentAt?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  factory BillingNotificationModel.fromEntity(BillingNotificationEntity entity) {
    return BillingNotificationModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      subscriptionId: entity.subscriptionId,
      transactionId: entity.transactionId,
      notificationType: entity.notificationType,
      title: entity.title,
      message: entity.message,
      inAppSent: entity.inAppSent,
      pushSent: entity.pushSent,
      emailSent: entity.emailSent,
      smsSent: entity.smsSent,
      isRead: entity.isRead,
      readAt: entity.readAt,
      scheduledAt: entity.scheduledAt,
      sentAt: entity.sentAt,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  BillingNotificationEntity toEntity() {
    return BillingNotificationEntity(
      id: id,
      userId: userId,
      schoolId: schoolId,
      subscriptionId: subscriptionId,
      transactionId: transactionId,
      notificationType: notificationType,
      title: title,
      message: message,
      inAppSent: inAppSent,
      pushSent: pushSent,
      emailSent: emailSent,
      smsSent: smsSent,
      isRead: isRead,
      readAt: readAt,
      scheduledAt: scheduledAt,
      sentAt: sentAt,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  BillingNotificationModel copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? subscriptionId,
    String? transactionId,
    BillingNotificationType? notificationType,
    String? title,
    String? message,
    bool? inAppSent,
    bool? pushSent,
    bool? emailSent,
    bool? smsSent,
    bool? isRead,
    DateTime? readAt,
    DateTime? scheduledAt,
    DateTime? sentAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return BillingNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      transactionId: transactionId ?? this.transactionId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      inAppSent: inAppSent ?? this.inAppSent,
      pushSent: pushSent ?? this.pushSent,
      emailSent: emailSent ?? this.emailSent,
      smsSent: smsSent ?? this.smsSent,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingNotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          schoolId == other.schoolId &&
          subscriptionId == other.subscriptionId &&
          transactionId == other.transactionId &&
          notificationType == other.notificationType &&
          title == other.title &&
          message == other.message &&
          inAppSent == other.inAppSent &&
          pushSent == other.pushSent &&
          emailSent == other.emailSent &&
          smsSent == other.smsSent &&
          isRead == other.isRead &&
          readAt == other.readAt &&
          scheduledAt == other.scheduledAt &&
          sentAt == other.sentAt &&
          _mapEquals(metadata, other.metadata) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id, userId, schoolId, subscriptionId, transactionId,
        notificationType, title, message, inAppSent, pushSent, emailSent,
        smsSent, isRead, readAt, scheduledAt, sentAt, metadata.hashCode,
        createdAt,
      );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final aVal = a[key];
    final bVal = b[key];
    if (aVal is Map<String, dynamic> && bVal is Map<String, dynamic>) {
      if (!_mapEquals(aVal, bVal)) return false;
    } else if (aVal is List && bVal is List) {
      if (aVal.length != bVal.length) return false;
      for (var i = 0; i < aVal.length; i++) {
        if (aVal[i] is Map<String, dynamic> && bVal[i] is Map<String, dynamic>) {
          if (!_mapEquals(aVal[i] as Map<String, dynamic>, bVal[i] as Map<String, dynamic>)) return false;
        } else if (aVal[i] != bVal[i]) {
          return false;
        }
      }
    } else if (aVal != bVal) {
      return false;
    }
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] is Map<String, dynamic> && b[i] is Map<String, dynamic>) {
      if (!_mapEquals(a[i] as Map<String, dynamic>, b[i] as Map<String, dynamic>)) return false;
    } else if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _listMapEquals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_mapEquals(a[i], b[i])) return false;
  }
  return true;
}
