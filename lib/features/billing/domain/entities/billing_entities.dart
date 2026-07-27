import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Who is the subscriber? Three independent billing models.
enum BillingModel {
  teacherSaas(value: 'teacher_saas', label: 'Teacher SaaS'),
  schoolSaas(value: 'school_saas', label: 'School SaaS'),
  enterpriseSaas(value: 'enterprise_saas', label: 'Enterprise SaaS');

  const BillingModel({required this.value, required this.label});
  final String value;
  final String label;

  static BillingModel? fromString(String? value) {
    if (value == null) return null;
    return BillingModel.values.cast<BillingModel?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Subscription plan tier.
enum PlanTier {
  free(value: 'free', label: 'Free', color: '#9CA3AF'),
  starter(value: 'starter', label: 'Starter', color: '#3B82F6'),
  professional(value: 'professional', label: 'Professional', color: '#8B5CF6'),
  enterprise(value: 'enterprise', label: 'Enterprise', color: '#F59E0B');

  const PlanTier({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final String color;

  static PlanTier? fromString(String? value) {
    if (value == null) return null;
    return PlanTier.values.cast<PlanTier?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Subscription status lifecycle.
enum SubscriptionStatus {
  trial(value: 'trial', label: 'Trial', color: '#3B82F6'),
  active(value: 'active', label: 'Active', color: '#22C55E'),
  pastDue(value: 'past_due', label: 'Past Due', color: '#EF4444'),
  paused(value: 'paused', label: 'Paused', color: '#F59E0B'),
  cancelled(value: 'cancelled', label: 'Cancelled', color: '#6B7280'),
  expired(value: 'expired', label: 'Expired', color: '#78716C'),
  pendingActivation(value: 'pending_activation', label: 'Pending', color: '#9CA3AF');

  const SubscriptionStatus({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final String color;

  static SubscriptionStatus? fromString(String? value) {
    if (value == null) return null;
    return SubscriptionStatus.values.cast<SubscriptionStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trial;
}

/// Transaction/payment status.
enum TransactionStatus {
  pending(value: 'pending', label: 'Pending', color: '#F59E0B'),
  processing(value: 'processing', label: 'Processing', color: '#3B82F6'),
  successful(value: 'successful', label: 'Successful', color: '#22C55E'),
  failed(value: 'failed', label: 'Failed', color: '#EF4444'),
  refunded(value: 'refunded', label: 'Refunded', color: '#8B5CF6'),
  partiallyRefunded(value: 'partially_refunded', label: 'Partially Refunded', color: '#F97316'),
  disputed(value: 'disputed', label: 'Disputed', color: '#DC2626'),
  voided(value: 'voided', label: 'Voided', color: '#6B7280');

  const TransactionStatus({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final String color;

  static TransactionStatus? fromString(String? value) {
    if (value == null) return null;
    return TransactionStatus.values.cast<TransactionStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Payment channel.
enum PaymentChannel {
  card(value: 'card', label: 'Card'),
  bankTransfer(value: 'bank_transfer', label: 'Bank Transfer'),
  ussd(value: 'ussd', label: 'USSD'),
  mobileMoney(value: 'mobile_money', label: 'Mobile Money'),
  qrCode(value: 'qr_code', label: 'QR Code'),
  credit(value: 'credit', label: 'Credit'),
  coupon(value: 'coupon', label: 'Coupon'),
  refund(value: 'refund', label: 'Refund');

  const PaymentChannel({required this.value, required this.label});
  final String value;
  final String label;

  static PaymentChannel? fromString(String? value) {
    if (value == null) return null;
    return PaymentChannel.values.cast<PaymentChannel?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Coupon discount type.
enum CouponDiscountType {
  percentage(value: 'percentage', label: 'Percentage'),
  fixedAmount(value: 'fixed_amount', label: 'Fixed Amount'),
  freeTrial(value: 'free_trial', label: 'Free Trial'),
  fixedPerSeat(value: 'fixed_per_seat', label: 'Fixed Per Seat');

  const CouponDiscountType({required this.value, required this.label});
  final String value;
  final String label;

  static CouponDiscountType? fromString(String? value) {
    if (value == null) return null;
    return CouponDiscountType.values.cast<CouponDiscountType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Referral reward type.
enum ReferralRewardType {
  creditDays(value: 'credit_days', label: 'Credit Days'),
  percentageDiscount(value: 'percentage_discount', label: 'Percentage Discount'),
  fixedCredit(value: 'fixed_credit', label: 'Fixed Credit'),
  aiCredits(value: 'ai_credits', label: 'AI Credits');

  const ReferralRewardType({required this.value, required this.label});
  final String value;
  final String label;

  static ReferralRewardType? fromString(String? value) {
    if (value == null) return null;
    return ReferralRewardType.values.cast<ReferralRewardType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// AI credit transaction type.
enum CreditTransactionType {
  monthlyAllocation(value: 'monthly_allocation', label: 'Monthly Allocation'),
  purchase(value: 'purchase', label: 'Purchase'),
  usage(value: 'usage', label: 'Usage'),
  expiration(value: 'expiration', label: 'Expiration'),
  bonus(value: 'bonus', label: 'Bonus'),
  referralReward(value: 'referral_reward', label: 'Referral Reward'),
  adminAdjustment(value: 'admin_adjustment', label: 'Admin Adjustment'),
  refund(value: 'refund', label: 'Refund');

  const CreditTransactionType({required this.value, required this.label});
  final String value;
  final String label;

  static CreditTransactionType? fromString(String? value) {
    if (value == null) return null;
    return CreditTransactionType.values.cast<CreditTransactionType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// License type.
enum LicenseType {
  school(value: 'school', label: 'School'),
  teacher(value: 'teacher', label: 'Teacher'),
  branch(value: 'branch', label: 'Branch'),
  seat(value: 'seat', label: 'Seat'),
  custom(value: 'custom', label: 'Custom');

  const LicenseType({required this.value, required this.label});
  final String value;
  final String label;

  static LicenseType? fromString(String? value) {
    if (value == null) return null;
    return LicenseType.values.cast<LicenseType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Invoice status.
enum InvoiceStatus {
  draft(value: 'draft', label: 'Draft'),
  issued(value: 'issued', label: 'Issued'),
  paid(value: 'paid', label: 'Paid'),
  partiallyPaid(value: 'partially_paid', label: 'Partially Paid'),
  overdue(value: 'overdue', label: 'Overdue'),
  cancelled(value: 'cancelled', label: 'Cancelled'),
  void_(value: 'void', label: 'Void'),
  creditNote(value: 'credit_note', label: 'Credit Note');

  const InvoiceStatus({required this.value, required this.label});
  final String value;
  final String label;

  static InvoiceStatus? fromString(String? value) {
    if (value == null) return null;
    return InvoiceStatus.values.cast<InvoiceStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Billing notification type.
enum BillingNotificationType {
  paymentSuccess(value: 'payment_success', label: 'Payment Successful'),
  paymentFailed(value: 'payment_failed', label: 'Payment Failed'),
  trialEnding(value: 'trial_ending', label: 'Trial Ending'),
  subscriptionRenewal(value: 'subscription_renewal', label: 'Subscription Renewal'),
  planExpiring(value: 'plan_expiring', label: 'Plan Expiring'),
  lowAiCredits(value: 'low_ai_credits', label: 'Low AI Credits'),
  invoiceGenerated(value: 'invoice_generated', label: 'Invoice Generated'),
  refundStatus(value: 'refund_status', label: 'Refund Status'),
  cardExpiring(value: 'card_expiring', label: 'Card Expiring'),
  subscriptionCancelled(value: 'subscription_cancelled', label: 'Subscription Cancelled'),
  upgradeAvailable(value: 'upgrade_available', label: 'Upgrade Available');

  const BillingNotificationType({required this.value, required this.label});
  final String value;
  final String label;

  static BillingNotificationType? fromString(String? value) {
    if (value == null) return null;
    return BillingNotificationType.values.cast<BillingNotificationType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

// ============================================================================
// ENTITIES
// ============================================================================

/// Subscription plan definition (configurable by Super Admin).
class SubscriptionPlanEntity extends Equatable {
  const SubscriptionPlanEntity({
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

  /// Computed: annual savings percentage vs monthly billing
  double get annualSavingsPercent {
    if (monthlyPrice == 0) return 0;
    final monthlyAnnual = monthlyPrice * 12;
    if (monthlyAnnual == 0) return 0;
    return ((monthlyAnnual - annualPrice) / monthlyAnnual) * 100;
  }

  /// Computed: is this the free tier?
  bool get isFree => tier == PlanTier.free;

  /// Computed: price for a given billing cycle
  double priceForCycle(String cycle) =>
      cycle == 'annual' ? annualPrice : monthlyPrice;

  SubscriptionPlanEntity copyWith({
    String? id, String? name, PlanTier? tier, BillingModel? billingModel,
    String? description, double? monthlyPrice, double? annualPrice,
    String? currency, double? setupFee, int? maxStudents, int? maxTeachers,
    int? maxSchools, int? maxStorageMb, int? maxExamsPerMonth,
    int? aiCreditsMonthly, bool? includesAiWorkspace, bool? includesParentPortal,
    bool? includesCommunication, bool? includesAdvancedAnalytics,
    bool? includesApiAccess, bool? includesWhiteLabel,
    bool? includesPrioritySupport, bool? includesDedicatedManager,
    int? trialDays, bool? isActive, bool? isPopular, int? sortOrder,
    List<String>? featuresList, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SubscriptionPlanEntity(
      id: id ?? this.id, name: name ?? this.name, tier: tier ?? this.tier,
      billingModel: billingModel ?? this.billingModel,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      annualPrice: annualPrice ?? this.annualPrice,
      currency: currency ?? this.currency, setupFee: setupFee ?? this.setupFee,
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
      trialDays: trialDays ?? this.trialDays, isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular, sortOrder: sortOrder ?? this.sortOrder,
      featuresList: featuresList ?? this.featuresList,
      metadata: metadata ?? this.metadata, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, tier, billingModel, description,
    monthlyPrice, annualPrice, currency, setupFee, maxStudents, maxTeachers,
    maxSchools, maxStorageMb, maxExamsPerMonth, aiCreditsMonthly,
    includesAiWorkspace, includesParentPortal, includesCommunication,
    includesAdvancedAnalytics, includesApiAccess, includesWhiteLabel,
    includesPrioritySupport, includesDedicatedManager, trialDays, isActive,
    isPopular, sortOrder, featuresList, metadata, createdAt, updatedAt,];
}

/// Active subscription for a teacher, school, or enterprise.
class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({
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
  final SubscriptionPlanEntity? plan;
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

  /// Computed: is the subscription currently active or in trial?
  bool get isActive => status.isActive;

  /// Computed: is the subscription in trial period?
  bool get isTrial => status == SubscriptionStatus.trial;

  /// Computed: days remaining in current period
  int get daysRemaining {
    final now = DateTime.now();
    if (currentPeriodEnd.isBefore(now)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }

  /// Computed: available seats
  int get availableSeats => seatsPurchased - seatsUsed;

  SubscriptionEntity copyWith({
    String? id, String? subscriberId, BillingModel? subscriberType,
    String? schoolId, String? planId, SubscriptionPlanEntity? plan,
    SubscriptionStatus? status, String? billingCycle,
    DateTime? currentPeriodStart, DateTime? currentPeriodEnd,
    DateTime? trialStart, DateTime? trialEnd,
    String? flutterwaveSubscriptionId, String? flutterwavePlanCode,
    String? couponId, double? couponDiscountApplied,
    double? priceAtSubscription, String? currency,
    int? seatsPurchased, int? seatsUsed, bool? autoRenew,
    DateTime? cancelledAt, String? cancellationReason,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SubscriptionEntity(
      id: id ?? this.id, subscriberId: subscriberId ?? this.subscriberId,
      subscriberType: subscriberType ?? this.subscriberType,
      schoolId: schoolId ?? this.schoolId, planId: planId ?? this.planId,
      plan: plan ?? this.plan, status: status ?? this.status,
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
      seatsUsed: seatsUsed ?? this.seatsUsed, autoRenew: autoRenew ?? this.autoRenew,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, subscriberId, subscriberType, schoolId, planId,
    status, billingCycle, currentPeriodStart, currentPeriodEnd, trialStart,
    trialEnd, flutterwaveSubscriptionId, flutterwavePlanCode, couponId,
    couponDiscountApplied, priceAtSubscription, currency, seatsPurchased,
    seatsUsed, autoRenew, cancelledAt, cancellationReason, metadata,
    createdAt, updatedAt,];
}

/// Payment transaction record.
class TransactionEntity extends Equatable {
  const TransactionEntity({
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

  /// Computed: is the transaction successful?
  bool get isSuccessful => status == TransactionStatus.successful;

  /// Computed: can the transaction be refunded?
  bool get canRefund =>
      status == TransactionStatus.successful &&
      refundAmount < amount;

  TransactionEntity copyWith({
    String? id, String? subscriptionId, String? userId, String? schoolId,
    String? flutterwaveTxRef, String? flutterwaveTransactionId,
    String? flutterwaveFlwRef, double? amount, String? currency,
    PaymentChannel? channel, TransactionStatus? status,
    double? flutterwaveFee, double? appFee, double? netAmount,
    String? paymentMethodSummary, Map<String, dynamic>? processorResponse,
    double? refundAmount, String? refundReason, DateTime? refundedAt,
    int? riskScore, bool? fraudFlagged, String? fraudNotes,
    String? description, Map<String, dynamic>? metadata,
    DateTime? initiatedAt, DateTime? completedAt, DateTime? verifiedAt,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id, subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId, schoolId: schoolId ?? this.schoolId,
      flutterwaveTxRef: flutterwaveTxRef ?? this.flutterwaveTxRef,
      flutterwaveTransactionId: flutterwaveTransactionId ?? this.flutterwaveTransactionId,
      flutterwaveFlwRef: flutterwaveFlwRef ?? this.flutterwaveFlwRef,
      amount: amount ?? this.amount, currency: currency ?? this.currency,
      channel: channel ?? this.channel, status: status ?? this.status,
      flutterwaveFee: flutterwaveFee ?? this.flutterwaveFee,
      appFee: appFee ?? this.appFee, netAmount: netAmount ?? this.netAmount,
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
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, subscriptionId, userId, schoolId,
    flutterwaveTxRef, flutterwaveTransactionId, flutterwaveFlwRef,
    amount, currency, channel, status, flutterwaveFee, appFee, netAmount,
    paymentMethodSummary, processorResponse, refundAmount, refundReason,
    refundedAt, riskScore, fraudFlagged, fraudNotes, description, metadata,
    initiatedAt, completedAt, verifiedAt, createdAt, updatedAt,];
}

/// Invoice entity with line items.
class InvoiceEntity extends Equatable {
  const InvoiceEntity({
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
  final List<InvoiceLineItem> lineItems;
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

  /// Computed: is the invoice overdue?
  bool get isOverdue => invoiceType == InvoiceStatus.issued &&
      dueDate.isBefore(DateTime.now());

  /// Computed: is this a credit note?
  bool get isCreditNote => invoiceType == InvoiceStatus.creditNote;

  InvoiceEntity copyWith({
    String? id, String? subscriptionId, String? transactionId,
    String? schoolId, String? userId, String? invoiceNumber,
    InvoiceStatus? invoiceType, String? billToName, String? billToEmail,
    String? billToAddress, String? billToTaxId,
    List<InvoiceLineItem>? lineItems, double? subtotal, double? taxAmount,
    double? discountAmount, double? totalAmount, String? currency,
    String? creditNoteFor, DateTime? issueDate, DateTime? dueDate,
    DateTime? paidAt, String? pdfUrl, bool? emailSent,
    DateTime? emailSentAt, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return InvoiceEntity(
      id: id ?? this.id, subscriptionId: subscriptionId ?? this.subscriptionId,
      transactionId: transactionId ?? this.transactionId,
      schoolId: schoolId ?? this.schoolId, userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceType: invoiceType ?? this.invoiceType,
      billToName: billToName ?? this.billToName,
      billToEmail: billToEmail ?? this.billToEmail,
      billToAddress: billToAddress ?? this.billToAddress,
      billToTaxId: billToTaxId ?? this.billToTaxId,
      lineItems: lineItems ?? this.lineItems, subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      creditNoteFor: creditNoteFor ?? this.creditNoteFor,
      issueDate: issueDate ?? this.issueDate, dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt, pdfUrl: pdfUrl ?? this.pdfUrl,
      emailSent: emailSent ?? this.emailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, subscriptionId, transactionId, schoolId,
    userId, invoiceNumber, invoiceType, billToName, billToEmail,
    billToAddress, billToTaxId, lineItems, subtotal, taxAmount,
    discountAmount, totalAmount, currency, creditNoteFor, issueDate,
    dueDate, paidAt, pdfUrl, emailSent, emailSentAt, metadata,
    createdAt, updatedAt,];
}

/// Invoice line item.
class InvoiceLineItem extends Equatable {
  const InvoiceLineItem({
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

  @override
  List<Object?> get props => [description, quantity, unitPrice, total, taxRate, taxAmount];
}

/// Receipt entity.
class ReceiptEntity extends Equatable {
  const ReceiptEntity({
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

  @override
  List<Object?> get props => [id, transactionId, invoiceId, userId, schoolId,
    receiptNumber, amountPaid, currency, paymentMethod, paymentDate, pdfUrl,
    emailSent, emailSentAt, metadata, createdAt,];
}

/// AI Credit balance for a teacher or school.
class AiCreditBalanceEntity extends Equatable {
  const AiCreditBalanceEntity({
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

  /// Computed: usage percentage
  double get usagePercent =>
      totalCredits > 0 ? (usedCredits / totalCredits) * 100 : 0;

  /// Computed: are credits running low (below 20%)?
  bool get isLow => remainingCredits > 0 && remainingCredits < (totalCredits * 0.2);

  /// Computed: are credits exhausted?
  bool get isExhausted => remainingCredits <= 0;

  AiCreditBalanceEntity copyWith({
    String? id, String? ownerId, BillingModel? ownerType,
    String? schoolId, int? totalCredits, int? usedCredits,
    int? remainingCredits, DateTime? currentCycleStart,
    DateTime? currentCycleEnd, bool? creditsExpire,
    DateTime? expirationDate, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AiCreditBalanceEntity(
      id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
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
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, ownerType, schoolId, totalCredits,
    usedCredits, remainingCredits, currentCycleStart, currentCycleEnd,
    creditsExpire, expirationDate, metadata, createdAt, updatedAt,];
}

/// AI Credit transaction (audit trail).
class AiCreditTransactionEntity extends Equatable {
  const AiCreditTransactionEntity({
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

  /// Computed: is this a credit (positive) or debit (negative)?
  bool get isCredit => credits > 0;

  @override
  List<Object?> get props => [id, balanceId, ownerId, ownerType, schoolId,
    transactionType, credits, balanceBefore, balanceAfter, featureName,
    referenceId, estimatedCostUsd, description, metadata, createdAt,];
}

/// Coupon / discount code.
class CouponEntity extends Equatable {
  const CouponEntity({
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

  /// Computed: is the coupon currently valid?
  bool get isValid {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(validFrom)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (maxRedemptions > 0 && currentRedemptions >= maxRedemptions) return false;
    return true;
  }

  CouponEntity copyWith({
    String? id, String? code, String? name, String? description,
    CouponDiscountType? discountType, double? discountValue,
    double? discountPercent, double? maxDiscountAmount,
    List<String>? applicableTiers, List<String>? applicableBillingModels,
    List<String>? applicablePlans, int? maxRedemptions,
    int? currentRedemptions, int? maxRedemptionsPerUser,
    int? durationMonths, DateTime? validFrom, DateTime? validUntil,
    int? trialDays, bool? isActive, String? createdBy,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return CouponEntity(
      id: id ?? this.id, code: code ?? this.code, name: name ?? this.name,
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
      isActive: isActive ?? this.isActive, createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, code, name, description, discountType,
    discountValue, discountPercent, maxDiscountAmount, applicableTiers,
    applicableBillingModels, applicablePlans, maxRedemptions,
    currentRedemptions, maxRedemptionsPerUser, durationMonths, validFrom,
    validUntil, trialDays, isActive, createdBy, metadata, createdAt, updatedAt,];
}

/// Referral code entity.
class ReferralCodeEntity extends Equatable {
  const ReferralCodeEntity({
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

  ReferralCodeEntity copyWith({
    String? id, String? referrerId, BillingModel? referrerType,
    String? schoolId, String? code, bool? isActive,
    ReferralRewardType? rewardType, double? rewardValue,
    String? rewardDescription, ReferralRewardType? refereeRewardType,
    double? refereeRewardValue, int? totalReferrals,
    int? successfulReferrals, double? totalRewardsEarned,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ReferralCodeEntity(
      id: id ?? this.id, referrerId: referrerId ?? this.referrerId,
      referrerType: referrerType ?? this.referrerType,
      schoolId: schoolId ?? this.schoolId, code: code ?? this.code,
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
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, referrerId, referrerType, schoolId, code,
    isActive, rewardType, rewardValue, rewardDescription, refereeRewardType,
    refereeRewardValue, totalReferrals, successfulReferrals, totalRewardsEarned,
    metadata, createdAt, updatedAt,];
}

/// License entity.
class LicenseEntity extends Equatable {
  const LicenseEntity({
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

  /// Computed: is the license expired?
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// Computed: days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// Computed: available seats
  int get availableSeats => seatsTotal - seatsUsed;

  LicenseEntity copyWith({
    String? id, String? subscriptionId, String? schoolId, String? userId,
    LicenseType? licenseType, String? licenseKey, int? seatsTotal,
    int? seatsUsed, DateTime? issuedAt, DateTime? expiresAt,
    bool? isActive, DateTime? revokedAt, String? revokeReason,
    bool? autoRenew, bool? renewalReminderSent,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return LicenseEntity(
      id: id ?? this.id, subscriptionId: subscriptionId ?? this.subscriptionId,
      schoolId: schoolId ?? this.schoolId, userId: userId ?? this.userId,
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
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, subscriptionId, schoolId, userId, licenseType,
    licenseKey, seatsTotal, seatsUsed, issuedAt, expiresAt, isActive,
    revokedAt, revokeReason, autoRenew, renewalReminderSent, metadata,
    createdAt, updatedAt,];
}

/// AI Credit pack (purchasable bundle).
class AiCreditPackEntity extends Equatable {
  const AiCreditPackEntity({
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

  /// Computed: price per credit
  double get pricePerCredit => credits > 0 ? price / credits : 0;

  @override
  List<Object?> get props => [id, name, description, credits, price, currency,
    validityDays, isActive, sortOrder, applicableBillingModels, metadata,
    createdAt, updatedAt,];
}

/// School billing profile.
class SchoolBillingProfileEntity extends Equatable {
  const SchoolBillingProfileEntity({
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

  @override
  List<Object?> get props => [id, schoolId, billingContactName,
    billingContactEmail, billingContactPhone, billingAddress,
    taxIdNumber, taxExempt, defaultPaymentMethod, paymentMethods,
    autoRenew, renewalReminderDays, currentStudentCount,
    currentTeacherCount, currentStorageUsedMb, currentAiCreditsUsed,
    metadata, createdAt, updatedAt,];
}

/// Revenue analytics data point.
class RevenueDataPoint extends Equatable {
  const RevenueDataPoint({
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

  @override
  List<Object?> get props => [period, totalRevenue, subscriptionRevenue,
    aiCreditRevenue, setupFeeRevenue, refundAmount, netRevenue,
    processorFees, activeSubscriptions, newSubscriptions,
    cancelledSubscriptions, churnRate, trialConversions,
    teacherSaasRevenue, schoolSaasRevenue, enterpriseSaasRevenue,
    aiCreditsSold, aiCreditsUsed, currency,];
}

/// Billing notification entity.
class BillingNotificationEntity extends Equatable {
  const BillingNotificationEntity({
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

  @override
  List<Object?> get props => [id, userId, schoolId, subscriptionId,
    transactionId, notificationType, title, message, inAppSent, pushSent,
    emailSent, smsSent, isRead, readAt, scheduledAt, sentAt, metadata, createdAt,];
}
