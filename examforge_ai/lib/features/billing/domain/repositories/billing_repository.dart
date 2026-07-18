import '../../../../core/utils/result.dart';
import '../entities/billing_entities.dart';

/// Abstract contract for the billing repository.
///
/// All billing operations flow through this interface, enabling
/// Clean Architecture separation and testability.
abstract class BillingRepository {
  // ─── Subscription Plans ─────────────────────────────────────────────

  /// Get all available subscription plans, optionally filtered by billing model.
  Future<Result<List<SubscriptionPlanEntity>>> getSubscriptionPlans({
    BillingModel? billingModel,
    bool activeOnly = true,
  });

  /// Get a single subscription plan by ID.
  Future<Result<SubscriptionPlanEntity>> getSubscriptionPlan(String planId);

  /// Create or update a subscription plan (Super Admin only).
  Future<Result<SubscriptionPlanEntity>> upsertSubscriptionPlan(
    SubscriptionPlanEntity plan,
  );

  // ─── Subscriptions ──────────────────────────────────────────────────

  /// Get the current subscription for a subscriber (teacher, school, enterprise).
  Future<Result<SubscriptionEntity>> getCurrentSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
  });

  /// Get all subscriptions (Super Admin / School Admin).
  Future<Result<List<SubscriptionEntity>>> getSubscriptions({
    String? schoolId,
    BillingModel? subscriberType,
    SubscriptionStatus? status,
    int page = 1,
    int perPage = 20,
  });

  /// Create a new subscription (initiates checkout).
  Future<Result<SubscriptionEntity>> createSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
    required String planId,
    String billingCycle = 'monthly',
    String? couponCode,
    int seats = 1,
    String? schoolId,
  });

  /// Upgrade a subscription to a higher plan.
  Future<Result<SubscriptionEntity>> upgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
    String? billingCycle,
  });

  /// Downgrade a subscription to a lower plan.
  Future<Result<SubscriptionEntity>> downgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
  });

  /// Cancel a subscription.
  Future<Result<SubscriptionEntity>> cancelSubscription({
    required String subscriptionId,
    String? reason,
    bool immediate = false,
  });

  /// Renew a subscription.
  Future<Result<SubscriptionEntity>> renewSubscription({
    required String subscriptionId,
  });

  /// Pause a subscription.
  Future<Result<SubscriptionEntity>> pauseSubscription({
    required String subscriptionId,
  });

  /// Resume a paused subscription.
  Future<Result<SubscriptionEntity>> resumeSubscription({
    required String subscriptionId,
  });

  // ─── Payments (Flutterwave) ──────────────────────────────────────────

  /// Initialize a Flutterwave Standard Checkout payment.
  Future<Result<Map<String, dynamic>>> initializePayment({
    required double amount,
    required String currency,
    required String email,
    required String txRef,
    String? subscriptionId,
    String? planId,
    String? couponCode,
    Map<String, dynamic>? metadata,
  });

  /// Verify a Flutterwave payment by transaction reference.
  Future<Result<TransactionEntity>> verifyPayment(String txRef);

  /// Process a Flutterwave webhook event.
  Future<Result<bool>> processWebhookEvent(Map<String, dynamic> payload);

  /// Get transaction history.
  Future<Result<List<TransactionEntity>>> getTransactions({
    String? userId,
    String? schoolId,
    TransactionStatus? status,
    int page = 1,
    int perPage = 20,
  });

  /// Get a single transaction.
  Future<Result<TransactionEntity>> getTransaction(String transactionId);

  /// Request a refund for a transaction.
  Future<Result<TransactionEntity>> requestRefund({
    required String transactionId,
    required double amount,
    String? reason,
  });

  // ─── Invoices ────────────────────────────────────────────────────────

  /// Get invoices for a user or school.
  Future<Result<List<InvoiceEntity>>> getInvoices({
    String? userId,
    String? schoolId,
    InvoiceStatus? status,
    int page = 1,
    int perPage = 20,
  });

  /// Get a single invoice.
  Future<Result<InvoiceEntity>> getInvoice(String invoiceId);

  /// Generate an invoice for a subscription.
  Future<Result<InvoiceEntity>> generateInvoice({
    required String subscriptionId,
    required List<InvoiceLineItem> lineItems,
  });

  /// Download invoice PDF URL.
  Future<Result<String>> getInvoicePdfUrl(String invoiceId);

  // ─── Receipts ────────────────────────────────────────────────────────

  /// Get receipts for a user.
  Future<Result<List<ReceiptEntity>>> getReceipts({
    required String userId,
    int page = 1,
    int perPage = 20,
  });

  /// Download receipt PDF URL.
  Future<Result<String>> getReceiptPdfUrl(String receiptId);

  // ─── AI Credits ─────────────────────────────────────────────────────

  /// Get the current AI credit balance for an owner.
  Future<Result<AiCreditBalanceEntity>> getCreditBalance({
    required String ownerId,
    required BillingModel ownerType,
  });

  /// Get AI credit transaction history.
  Future<Result<List<AiCreditTransactionEntity>>> getCreditTransactions({
    required String ownerId,
    required BillingModel ownerType,
    CreditTransactionType? type,
    int page = 1,
    int perPage = 20,
  });

  /// Consume AI credits for a feature.
  Future<Result<bool>> consumeCredits({
    required String ownerId,
    required BillingModel ownerType,
    required int credits,
    required String featureName,
    String? referenceId,
    double estimatedCostUsd = 0,
  });

  /// Purchase additional AI credits.
  Future<Result<AiCreditBalanceEntity>> purchaseCredits({
    required String ownerId,
    required BillingModel ownerType,
    required String creditPackId,
    String? couponCode,
  });

  /// Get available AI credit packs.
  Future<Result<List<AiCreditPackEntity>>> getCreditPacks({
    BillingModel? billingModel,
  });

  // ─── Coupons ────────────────────────────────────────────────────────

  /// Validate a coupon code and return the coupon if valid.
  Future<Result<CouponEntity>> validateCoupon({
    required String code,
    required BillingModel billingModel,
    String? planId,
  });

  /// Redeem a coupon code.
  Future<Result<CouponEntity>> redeemCoupon({
    required String couponId,
    required String userId,
    String? schoolId,
    String? subscriptionId,
  });

  /// Get all coupons (Super Admin).
  Future<Result<List<CouponEntity>>> getCoupons({
    bool activeOnly = false,
    int page = 1,
    int perPage = 20,
  });

  /// Create a coupon (Super Admin).
  Future<Result<CouponEntity>> createCoupon(CouponEntity coupon);

  /// Update a coupon (Super Admin).
  Future<Result<CouponEntity>> updateCoupon(CouponEntity coupon);

  // ─── Referrals ──────────────────────────────────────────────────────

  /// Get or create a referral code for a user.
  Future<Result<ReferralCodeEntity>> getOrCreateReferralCode({
    required String referrerId,
    required BillingModel referrerType,
    String? schoolId,
  });

  /// Apply a referral code during signup/subscription.
  Future<Result<bool>> applyReferralCode({
    required String code,
    required String refereeId,
    required BillingModel refereeType,
  });

  /// Get referral tracking for a referrer.
  Future<Result<List<Map<String, dynamic>>>> getReferralTracking({
    required String referrerId,
    int page = 1,
    int perPage = 20,
  });

  // ─── Licenses ────────────────────────────────────────────────────────

  /// Get licenses for a school or user.
  Future<Result<List<LicenseEntity>>> getLicenses({
    String? schoolId,
    String? userId,
    LicenseType? type,
    bool activeOnly = true,
  });

  /// Revoke a license.
  Future<Result<LicenseEntity>> revokeLicense({
    required String licenseId,
    required String reason,
  });

  // ─── School Billing ──────────────────────────────────────────────────

  /// Get the billing profile for a school.
  Future<Result<SchoolBillingProfileEntity>> getSchoolBillingProfile(
    String schoolId,
  );

  /// Update the billing profile for a school.
  Future<Result<SchoolBillingProfileEntity>> updateSchoolBillingProfile(
    SchoolBillingProfileEntity profile,
  );

  // ─── Revenue Analytics ───────────────────────────────────────────────

  /// Get revenue data for a period (Super Admin).
  Future<Result<List<RevenueDataPoint>>> getRevenueData({
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get billing dashboard summary (Super Admin).
  Future<Result<Map<String, dynamic>>> getBillingDashboardSummary();

  // ─── Billing Notifications ───────────────────────────────────────────

  /// Get billing notifications for a user.
  Future<Result<List<BillingNotificationEntity>>> getBillingNotifications({
    required String userId,
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  });

  /// Mark a billing notification as read.
  Future<Result<bool>> markNotificationRead(String notificationId);

  /// Update billing notification preferences.
  Future<Result<bool>> updateNotificationPreferences({
    required String userId,
    required Map<String, bool> preferences,
  });
}
