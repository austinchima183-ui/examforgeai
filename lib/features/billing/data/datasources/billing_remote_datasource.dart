import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/billing_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote billing data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class BillingRemoteDataSource {
  // ─── Plans ──────────────────────────────────────────────────────────

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans({
    String? billingModel,
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<SubscriptionPlanModel> getSubscriptionPlan(String planId);
  Future<SubscriptionPlanModel> upsertSubscriptionPlan(
    Map<String, dynamic> planData,
  );

  // ─── Subscriptions ─────────────────────────────────────────────────

  Future<SubscriptionModel> getCurrentSubscription({
    required String subscriberId,
    required String subscriberType,
  });
  Future<List<SubscriptionModel>> getSubscriptions({
    String? schoolId,
    String? subscriberType,
    String? status,
    int page = 1,
    int perPage = 20,
  });
  Future<SubscriptionModel> createSubscription(Map<String, dynamic> data);
  Future<SubscriptionModel> updateSubscription(
    String subscriptionId,
    Map<String, dynamic> data,
  );
  Future<void> deleteSubscription(String subscriptionId);

  // ─── Transactions ──────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions({
    String? userId,
    String? schoolId,
    String? status,
    int page = 1,
    int perPage = 20,
  });
  Future<TransactionModel> getTransaction(String transactionId);
  Future<TransactionModel> createTransaction(Map<String, dynamic> data);
  Future<TransactionModel> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  );

  // ─── Invoices ──────────────────────────────────────────────────────

  Future<List<InvoiceModel>> getInvoices({
    String? userId,
    String? schoolId,
    String? status,
    int page = 1,
    int perPage = 20,
  });
  Future<InvoiceModel> getInvoice(String invoiceId);
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data);
  Future<InvoiceModel> updateInvoice(
    String invoiceId,
    Map<String, dynamic> data,
  );

  // ─── Receipts ──────────────────────────────────────────────────────

  Future<List<ReceiptModel>> getReceipts({
    required String userId,
    int page = 1,
    int perPage = 20,
  });
  Future<ReceiptModel> createReceipt(Map<String, dynamic> data);

  // ─── AI Credits ────────────────────────────────────────────────────

  Future<AiCreditBalanceModel> getCreditBalance({
    required String ownerId,
    required String ownerType,
  });
  Future<List<AiCreditTransactionModel>> getCreditTransactions({
    required String ownerId,
    required String ownerType,
    String? type,
    int page = 1,
    int perPage = 20,
  });
  Future<bool> consumeCredits({
    required String ownerId,
    required String ownerType,
    required int credits,
    required String featureName,
    String? referenceId,
    double estimatedCostUsd = 0,
  });
  Future<AiCreditBalanceModel> purchaseCredits(Map<String, dynamic> data);
  Future<List<AiCreditPackModel>> getCreditPacks({
    String? billingModel,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Coupons ───────────────────────────────────────────────────────

  Future<CouponModel> validateCoupon({
    required String code,
    required String billingModel,
    String? planId,
  });
  Future<CouponModel> redeemCoupon({
    required String couponId,
    required String userId,
    String? schoolId,
    String? subscriptionId,
  });
  Future<List<CouponModel>> getCoupons({
    bool activeOnly = false,
    int page = 1,
    int perPage = 20,
  });
  Future<CouponModel> createCoupon(Map<String, dynamic> data);
  Future<CouponModel> updateCoupon(
    String couponId,
    Map<String, dynamic> data,
  );

  // ─── Referrals ─────────────────────────────────────────────────────

  Future<ReferralCodeModel> getOrCreateReferralCode({
    required String referrerId,
    required String referrerType,
    String? schoolId,
  });
  Future<bool> applyReferralCode({
    required String code,
    required String refereeId,
    required String refereeType,
  });
  Future<List<Map<String, dynamic>>> getReferralTracking({
    required String referrerId,
    int page = 1,
    int perPage = 20,
  });

  // ─── Licenses ──────────────────────────────────────────────────────

  Future<List<LicenseModel>> getLicenses({
    String? schoolId,
    String? userId,
    String? type,
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<LicenseModel> revokeLicense({
    required String licenseId,
    required String reason,
  });

  // ─── School Billing ────────────────────────────────────────────────

  Future<SchoolBillingProfileModel> getSchoolBillingProfile(String schoolId);
  Future<SchoolBillingProfileModel> updateSchoolBillingProfile(
    String schoolId,
    Map<String, dynamic> data,
  );

  // ─── Revenue ───────────────────────────────────────────────────────

  Future<List<RevenueDataPointModel>> getRevenueData({
    required String periodType,
    required String startDate,
    required String endDate,
  });
  Future<Map<String, dynamic>> getBillingDashboardSummary();

  // ─── Notifications ─────────────────────────────────────────────────

  Future<List<BillingNotificationModel>> getBillingNotifications({
    required String userId,
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  });
  Future<bool> markNotificationRead(String notificationId);
  Future<bool> updateNotificationPreferences({
    required String userId,
    required Map<String, bool> preferences,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Supabase-backed implementation of [BillingRemoteDataSource].
///
/// Every method maps Supabase-specific responses and errors into the
/// domain-agnostic types defined in the data layer. Supabase
/// [sb.PostgrestException] instances are converted to our custom
/// exceptions with user-friendly messages.
class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  BillingRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ───────────────────────────────────────────────────
  static const _plansTable = 'subscription_plans';
  static const _subscriptionsTable = 'subscriptions';
  static const _transactionsTable = 'transactions';
  static const _invoicesTable = 'invoices';
  static const _receiptsTable = 'receipts';
  static const _creditBalancesTable = 'ai_credit_balances';
  static const _creditTransactionsTable = 'ai_credit_transactions';
  static const _couponsTable = 'coupons';
  static const _couponRedemptionsTable = 'coupon_redemptions';
  static const _referralCodesTable = 'referral_codes';
  static const _referralTrackingTable = 'referral_tracking';
  static const _licensesTable = 'licenses';
  static const _schoolBillingTable = 'school_billing_profiles';
  static const _revenueTable = 'revenue_reports';
  static const _creditPacksTable = 'ai_credit_packs';
  static const _notificationsTable = 'billing_notifications';
  static const _notificationPrefsTable = 'billing_notification_preferences';

  // ═══════════════════════════════════════════════════════════════════
  // PLANS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans({
    String? billingModel,
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase.from(_plansTable).select();

      if (billingModel != null) {
        query = query.eq('billing_model', billingModel);
      }
      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // PERF: Added limit to prevent unbounded query on subscription_plans
      final response = query.order('sort_order', ascending: true).limit(limit);

      final list = await response;
      AppLogger.info('Fetched ${list.length} subscription plans');
      return list
          .map<SubscriptionPlanModel>(
            (row) => SubscriptionPlanModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptionPlans error', error: e);
      throw const ServerException(
        message: 'Failed to fetch subscription plans.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubscriptionPlanModel> getSubscriptionPlan(String planId) async {
    try {
      final response = await _supabase
          .from(_plansTable)
          .select()
          .eq('id', planId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Subscription plan not found.');
      }

      return SubscriptionPlanModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptionPlan error', error: e);
      throw const ServerException(
        message: 'Failed to fetch subscription plan.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubscriptionPlanModel> upsertSubscriptionPlan(
    Map<String, dynamic> planData,
  ) async {
    try {
      planData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_plansTable)
          .upsert(planData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Subscription plan upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Subscription plan upserted: ${response.first['id']}');
      return SubscriptionPlanModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertSubscriptionPlan error', error: e);
      throw const ServerException(
        message: 'Failed to upsert subscription plan.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SubscriptionModel> getCurrentSubscription({
    required String subscriberId,
    required String subscriberType,
  }) async {
    try {
      final response = await _supabase
          .from(_subscriptionsTable)
          .select()
          .eq('subscriber_id', subscriberId)
          .eq('subscriber_type', subscriberType)
          .inFilter('status', ['active', 'trial'])
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'No active subscription found.');
      }

      return SubscriptionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getCurrentSubscription error', error: e);
      throw const ServerException(
        message: 'Failed to fetch current subscription.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions({
    String? schoolId,
    String? subscriberType,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // PERF: Fix duplicate filter application bug
      // Previous code applied filters TWICE: once inline (lines 394-402)
      // then again via _applyFilters (lines 404-408). Now uses only _applyFilters.
      var query = _supabase.from(_subscriptionsTable).select(
        'id, subscriber_id, subscriber_type, plan_id, '
        'status, current_period_start, current_period_end, created_at',
      );

      final filters = <String, String>{};
      if (schoolId != null) filters['school_id'] = schoolId;
      if (subscriberType != null) filters['subscriber_type'] = subscriberType;
      if (status != null) filters['status'] = status;

      final filtered = _applyFilters(query, filters);

      var transformed =
          filtered.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info('Fetched ${list.length} subscriptions');
      return list
          .map<SubscriptionModel>(
            (row) => SubscriptionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch subscriptions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubscriptionModel> createSubscription(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(_subscriptionsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Subscription creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Subscription created: ${response.first['id']}');
      return SubscriptionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createSubscription error', error: e);
      throw const ServerException(
        message: 'Failed to create subscription.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubscriptionModel> updateSubscription(
    String subscriptionId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_subscriptionsTable)
          .update(data)
          .eq('id', subscriptionId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Subscription not found for update.');
      }

      AppLogger.info('Subscription updated: $subscriptionId');
      return SubscriptionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateSubscription error', error: e);
      throw const ServerException(
        message: 'Failed to update subscription.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      await _supabase
          .from(_subscriptionsTable)
          .delete()
          .eq('id', subscriptionId);

      AppLogger.info('Subscription deleted: $subscriptionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteSubscription error', error: e);
      throw const ServerException(
        message: 'Failed to delete subscription.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<TransactionModel>> getTransactions({
    String? userId,
    String? schoolId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // PERF: Fix duplicate filter application bug — use only _applyFilters
      var query = _supabase.from(_transactionsTable).select(
        'id, user_id, school_id, amount, currency, '
        'status, transaction_type, flutterwave_tx_ref, created_at',
      );

      final filters = <String, String>{};
      if (userId != null) filters['user_id'] = userId;
      if (schoolId != null) filters['school_id'] = schoolId;
      if (status != null) filters['status'] = status;

      final filtered = _applyFilters(query, filters);

      var transformed =
          filtered.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info('Fetched ${list.length} transactions');
      return list
          .map<TransactionModel>(
            (row) => TransactionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTransactions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch transactions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> getTransaction(String transactionId) async {
    try {
      final response = await _supabase
          .from(_transactionsTable)
          .select()
          .eq('id', transactionId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Transaction not found.');
      }

      return TransactionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getTransaction error', error: e);
      throw const ServerException(
        message: 'Failed to fetch transaction.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(_transactionsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Transaction creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Transaction created: ${response.first['id']}');
      return TransactionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createTransaction error', error: e);
      throw const ServerException(
        message: 'Failed to create transaction.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_transactionsTable)
          .update(data)
          .eq('id', transactionId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Transaction not found for update.');
      }

      AppLogger.info('Transaction updated: $transactionId');
      return TransactionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateTransaction error', error: e);
      throw const ServerException(
        message: 'Failed to update transaction.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // INVOICES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<InvoiceModel>> getInvoices({
    String? userId,
    String? schoolId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // PERF: Fix duplicate filter application bug — use only _applyFilters
      var query = _supabase.from(_invoicesTable).select(
        'id, user_id, school_id, invoice_number, '
        'amount_due, amount_paid, status, due_date, created_at',
      );

      final filters = <String, String>{};
      if (userId != null) filters['user_id'] = userId;
      if (schoolId != null) filters['school_id'] = schoolId;
      if (status != null) filters['status'] = status;

      final filtered = _applyFilters(query, filters);

      var transformed =
          filtered.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info('Fetched ${list.length} invoices');
      return list
          .map<InvoiceModel>((row) => InvoiceModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getInvoices error', error: e);
      throw const ServerException(
        message: 'Failed to fetch invoices.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InvoiceModel> getInvoice(String invoiceId) async {
    try {
      final response = await _supabase
          .from(_invoicesTable)
          .select()
          .eq('id', invoiceId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Invoice not found.');
      }

      return InvoiceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getInvoice error', error: e);
      throw const ServerException(
        message: 'Failed to fetch invoice.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(_invoicesTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Invoice creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Invoice created: ${response.first['id']}');
      return InvoiceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createInvoice error', error: e);
      throw const ServerException(
        message: 'Failed to create invoice.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InvoiceModel> updateInvoice(
    String invoiceId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_invoicesTable)
          .update(data)
          .eq('id', invoiceId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Invoice not found for update.');
      }

      AppLogger.info('Invoice updated: $invoiceId');
      return InvoiceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateInvoice error', error: e);
      throw const ServerException(
        message: 'Failed to update invoice.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECEIPTS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<ReceiptModel>> getReceipts({
    required String userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabase
          .from(_receiptsTable)
          .select()
          .eq('user_id', userId) as sb.PostgrestTransformBuilder<dynamic>;

      query = _applyPagination(query, page: page, perPage: perPage);

      final list = await query;
      AppLogger.info('Fetched ${list.length} receipts for user $userId');
      return list
          .map<ReceiptModel>((row) => ReceiptModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getReceipts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch receipts.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ReceiptModel> createReceipt(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(_receiptsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Receipt creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Receipt created: ${response.first['id']}');
      return ReceiptModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createReceipt error', error: e);
      throw const ServerException(
        message: 'Failed to create receipt.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI CREDITS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AiCreditBalanceModel> getCreditBalance({
    required String ownerId,
    required String ownerType,
  }) async {
    try {
      final response = await _supabase
          .from(_creditBalancesTable)
          .select()
          .eq('owner_id', ownerId)
          .eq('owner_type', ownerType)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Credit balance not found.');
      }

      return AiCreditBalanceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getCreditBalance error', error: e);
      throw const ServerException(
        message: 'Failed to fetch credit balance.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AiCreditTransactionModel>> getCreditTransactions({
    required String ownerId,
    required String ownerType,
    String? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabase
          .from(_creditTransactionsTable)
          .select()
          .eq('owner_id', ownerId)
          .eq('owner_type', ownerType) as sb.PostgrestFilterBuilder<dynamic>;

      if (type != null) {
        query = query.eq('type', type);
      }

      var transformed =
          query.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info(
        'Fetched ${list.length} credit transactions for $ownerId',
      );
      return list
          .map<AiCreditTransactionModel>(
            (row) => AiCreditTransactionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCreditTransactions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch credit transactions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> consumeCredits({
    required String ownerId,
    required String ownerType,
    required int credits,
    required String featureName,
    String? referenceId,
    double estimatedCostUsd = 0,
  }) async {
    try {
      final result = await _supabase.rpc(
        'consume_ai_credits',
        params: {
          'p_owner_id': ownerId,
          'p_owner_type': ownerType,
          'p_credits': credits,
          'p_feature_name': featureName,
          'p_reference_id': referenceId,
          'p_estimated_cost_usd': estimatedCostUsd,
        },
      );

      final success = result as bool? ?? false;
      AppLogger.info(
        'consume_ai_credits for $ownerId: credits=$credits, success=$success',
      );
      return success;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected consumeCredits error', error: e);
      throw const ServerException(
        message: 'Failed to consume credits.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiCreditBalanceModel> purchaseCredits(
    Map<String, dynamic> data,
  ) async {
    try {
      // Insert the credit transaction record
      final txResponse = await _supabase
          .from(_creditTransactionsTable)
          .insert(data)
          .select();

      if (txResponse.isEmpty) {
        throw const ServerException(
          message: 'Credit purchase returned no data.',
          statusCode: 500,
        );
      }

      // Fetch the updated balance
      final ownerId = data['owner_id'] as String;
      final ownerType = data['owner_type'] as String;

      final balanceResponse = await _supabase
          .from(_creditBalancesTable)
          .select()
          .eq('owner_id', ownerId)
          .eq('owner_type', ownerType)
          .limit(1);

      if (balanceResponse.isEmpty) {
        throw const ServerException(
          message: 'Credit balance not found after purchase.',
          statusCode: 500,
        );
      }

      AppLogger.info('Credits purchased for $ownerId');
      return AiCreditBalanceModel.fromJson(balanceResponse.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected purchaseCredits error', error: e);
      throw const ServerException(
        message: 'Failed to purchase credits.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AiCreditPackModel>> getCreditPacks({
    String? billingModel,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase
          .from(_creditPacksTable)
          .select()
          .eq('is_active', true) as sb.PostgrestFilterBuilder<dynamic>;

      if (billingModel != null) {
        query = query.eq('billing_model', billingModel);
      }

      // PERF: Added limit to prevent unbounded query on credit_packs
      final list = await query.order('sort_order', ascending: true).limit(limit);
      AppLogger.info('Fetched ${list.length} credit packs');
      return list
          .map<AiCreditPackModel>(
            (row) => AiCreditPackModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCreditPacks error', error: e);
      throw const ServerException(
        message: 'Failed to fetch credit packs.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // COUPONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<CouponModel> validateCoupon({
    required String code,
    required String billingModel,
    String? planId,
  }) async {
    try {
      var query = _supabase
          .from(_couponsTable)
          .select()
          .eq('code', code)
          .eq('billing_model', billingModel)
          .eq('is_active', true) as sb.PostgrestFilterBuilder<dynamic>;

      if (planId != null) {
        query = query.eq('plan_id', planId);
      }

      final response = await query.limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Invalid or expired coupon code.');
      }

      final couponData = response.first;

      // Validate expiry
      final validUntil = couponData['valid_until'] != null
          ? DateTime.tryParse(couponData['valid_until'] as String)
          : null;
      if (validUntil != null && validUntil.isBefore(DateTime.now())) {
        throw const ValidationException(
          message: 'This coupon has expired.',
          fieldErrors: {'code': 'Coupon has expired.'},
        );
      }

      final validFrom = couponData['valid_from'] != null
          ? DateTime.tryParse(couponData['valid_from'] as String)
          : null;
      if (validFrom != null && validFrom.isAfter(DateTime.now())) {
        throw const ValidationException(
          message: 'This coupon is not yet valid.',
          fieldErrors: {'code': 'Coupon is not yet valid.'},
        );
      }

      // Validate redemption count
      final maxRedemptions = couponData['max_redemptions'] as int?;
      final currentRedemptions =
          couponData['current_redemptions'] as int? ?? 0;
      if (maxRedemptions != null &&
          currentRedemptions >= maxRedemptions) {
        throw const ValidationException(
          message: 'This coupon has reached its maximum redemptions.',
          fieldErrors: {'code': 'Coupon redemption limit reached.'},
        );
      }

      AppLogger.info('Coupon validated: $code');
      return CouponModel.fromJson(couponData);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected validateCoupon error', error: e);
      throw const ServerException(
        message: 'Failed to validate coupon.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CouponModel> redeemCoupon({
    required String couponId,
    required String userId,
    String? schoolId,
    String? subscriptionId,
  }) async {
    try {
      // Insert a redemption record
      await _supabase.from(_couponRedemptionsTable).insert({
        'coupon_id': couponId,
        'user_id': userId,
        'school_id': schoolId,
        'subscription_id': subscriptionId,
        'redeemed_at': DateTime.now().toIso8601String(),
      });

      // Increment the coupon's current_redemptions counter
      final couponResponse = await _supabase
          .from(_couponsTable)
          .select('current_redemptions')
          .eq('id', couponId)
          .limit(1);

      if (couponResponse.isEmpty) {
        throw const NotFoundException(message: 'Coupon not found for redemption.');
      }

      final currentCount =
          couponResponse.first['current_redemptions'] as int? ?? 0;

      final updateResponse = await _supabase
          .from(_couponsTable)
          .update({
            'current_redemptions': currentCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', couponId)
          .select();

      if (updateResponse.isEmpty) {
        throw const ServerException(
          message: 'Coupon redemption update failed.',
          statusCode: 500,
        );
      }

      AppLogger.info('Coupon redeemed: $couponId by user $userId');
      return CouponModel.fromJson(updateResponse.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected redeemCoupon error', error: e);
      throw const ServerException(
        message: 'Failed to redeem coupon.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<CouponModel>> getCoupons({
    bool activeOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query =
          _supabase.from(_couponsTable).select() as sb.PostgrestFilterBuilder<dynamic>;

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      var transformed =
          query.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info('Fetched ${list.length} coupons');
      return list
          .map<CouponModel>((row) => CouponModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCoupons error', error: e);
      throw const ServerException(
        message: 'Failed to fetch coupons.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CouponModel> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from(_couponsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Coupon creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Coupon created: ${response.first['id']}');
      return CouponModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createCoupon error', error: e);
      throw const ServerException(
        message: 'Failed to create coupon.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CouponModel> updateCoupon(
    String couponId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_couponsTable)
          .update(data)
          .eq('id', couponId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Coupon not found for update.');
      }

      AppLogger.info('Coupon updated: $couponId');
      return CouponModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateCoupon error', error: e);
      throw const ServerException(
        message: 'Failed to update coupon.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REFERRALS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ReferralCodeModel> getOrCreateReferralCode({
    required String referrerId,
    required String referrerType,
    String? schoolId,
  }) async {
    try {
      // First, try to select an existing code
      var query = _supabase
          .from(_referralCodesTable)
          .select()
          .eq('referrer_id', referrerId)
          .eq('referrer_type', referrerType) as sb.PostgrestFilterBuilder<dynamic>;

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }

      final existing = await query.eq('is_active', true).limit(1);

      if (existing.isNotEmpty) {
        AppLogger.info('Found existing referral code for $referrerId');
        return ReferralCodeModel.fromJson(existing.first);
      }

      // Not found — generate a new code and insert
      final code = _generateReferralCode(referrerId, referrerType);

      final insertData = <String, dynamic>{
        'code': code,
        'referrer_id': referrerId,
        'referrer_type': referrerType,
        'school_id': schoolId,
        'is_active': true,
        'reward_type': 'credit_days',
        'reward_value': 7,
        'max_uses': 0,
        'current_uses': 0,
      };

      final response = await _supabase
          .from(_referralCodesTable)
          .insert(insertData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Referral code creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Referral code created for $referrerId: $code');
      return ReferralCodeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getOrCreateReferralCode error', error: e);
      throw const ServerException(
        message: 'Failed to get or create referral code.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> applyReferralCode({
    required String code,
    required String refereeId,
    required String refereeType,
  }) async {
    try {
      // Look up the referral code
      final codeResponse = await _supabase
          .from(_referralCodesTable)
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .limit(1);

      if (codeResponse.isEmpty) {
        throw const NotFoundException(message: 'Referral code not found or inactive.');
      }

      final referrerId = codeResponse.first['referrer_id'] as String;

      // Prevent self-referral
      if (referrerId == refereeId) {
        throw const ValidationException(
          message: 'You cannot use your own referral code.',
          fieldErrors: {'code': 'Self-referral is not allowed.'},
        );
      }

      // Insert into referral_tracking
      await _supabase.from(_referralTrackingTable).insert({
        'referral_code_id': codeResponse.first['id'],
        'referrer_id': referrerId,
        'referee_id': refereeId,
        'referee_type': refereeType,
        'code_used': code,
        'applied_at': DateTime.now().toIso8601String(),
        'reward_granted': false,
      });

      // Increment the referral code usage
      final currentUses =
          codeResponse.first['current_uses'] as int? ?? 0;
      await _supabase
          .from(_referralCodesTable)
          .update({
            'current_uses': currentUses + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', codeResponse.first['id']);

      AppLogger.info('Referral code applied: $code by $refereeId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected applyReferralCode error', error: e);
      throw const ServerException(
        message: 'Failed to apply referral code.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getReferralTracking({
    required String referrerId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabase
          .from(_referralTrackingTable)
          .select()
          .eq('referrer_id', referrerId) as sb.PostgrestTransformBuilder<dynamic>;

      query = _applyPagination(query, page: page, perPage: perPage);

      final list = await query;
      AppLogger.info(
        'Fetched ${list.length} referral tracking records for $referrerId',
      );
      return List<Map<String, dynamic>>.from(list);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getReferralTracking error', error: e);
      throw const ServerException(
        message: 'Failed to fetch referral tracking.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LICENSES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<LicenseModel>> getLicenses({
    String? schoolId,
    String? userId,
    String? type,
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_licensesTable).select() as sb.PostgrestFilterBuilder<dynamic>;

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (type != null) {
        query = query.eq('type', type);
      }
      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final list = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      AppLogger.info('Fetched ${list.length} licenses');
      return list
          .map<LicenseModel>((row) => LicenseModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getLicenses error', error: e);
      throw const ServerException(
        message: 'Failed to fetch licenses.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<LicenseModel> revokeLicense({
    required String licenseId,
    required String reason,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_licensesTable)
          .update({
            'is_active': false,
            'revoked_at': now,
            'revoke_reason': reason,
            'updated_at': now,
          })
          .eq('id', licenseId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'License not found for revocation.');
      }

      AppLogger.info('License revoked: $licenseId');
      return LicenseModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected revokeLicense error', error: e);
      throw const ServerException(
        message: 'Failed to revoke license.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCHOOL BILLING
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SchoolBillingProfileModel> getSchoolBillingProfile(
    String schoolId,
  ) async {
    try {
      final response = await _supabase
          .from(_schoolBillingTable)
          .select()
          .eq('school_id', schoolId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'School billing profile not found.');
      }

      return SchoolBillingProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSchoolBillingProfile error', error: e);
      throw const ServerException(
        message: 'Failed to fetch school billing profile.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolBillingProfileModel> updateSchoolBillingProfile(
    String schoolId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_schoolBillingTable)
          .update(data)
          .eq('school_id', schoolId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(
          message: 'School billing profile not found for update.',
        );
      }

      AppLogger.info('School billing profile updated for: $schoolId');
      return SchoolBillingProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateSchoolBillingProfile error', error: e);
      throw const ServerException(
        message: 'Failed to update school billing profile.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVENUE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<RevenueDataPointModel>> getRevenueData({
    required String periodType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on revenue data
      final response = await _supabase
          .from(_revenueTable)
          .select()
          .eq('period_type', periodType)
          .gte('period_start', startDate)
          .lte('period_end', endDate)
          .order('period_start', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      AppLogger.info('Fetched ${response.length} revenue data points');
      return response
          .map<RevenueDataPointModel>(
            (row) => RevenueDataPointModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRevenueData error', error: e);
      throw const ServerException(
        message: 'Failed to fetch revenue data.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getBillingDashboardSummary() async {
    try {
      // Aggregate from multiple tables for the dashboard summary

      // Active subscriptions count
      final activeSubs = await _supabase
          .from(_subscriptionsTable)
          .select('id')
          .inFilter('status', ['active', 'trial']);

      // Total revenue from transactions
      final successfulTx = await _supabase
          .from(_transactionsTable)
          .select('amount')
          .eq('status', 'successful');

      final totalRevenue = successfulTx.fold<double>(
        0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
      );

      // MRR — sum of active subscription prices
      final activeSubDetails = await _supabase
          .from(_subscriptionsTable)
          .select('price_at_subscription, billing_cycle')
          .inFilter('status', ['active', 'trial']);

      double mrr = 0;
      for (final sub in activeSubDetails) {
        final price = (sub['price_at_subscription'] as num?)?.toDouble() ?? 0;
        final cycle = sub['billing_cycle'] as String? ?? 'monthly';
        if (cycle == 'annual') {
          mrr += price / 12;
        } else {
          mrr += price;
        }
      }

      // Pending transactions
      final pendingTx = await _supabase
          .from(_transactionsTable)
          .select('id')
          .eq('status', 'pending');

      // Trial subscriptions
      final trialSubs = await _supabase
          .from(_subscriptionsTable)
          .select('id')
          .eq('status', 'trial');

      // Cancelled subscriptions
      final cancelledSubs = await _supabase
          .from(_subscriptionsTable)
          .select('id')
          .eq('status', 'cancelled');

      // Overdue invoices
      final overdueInvoices = await _supabase
          .from(_invoicesTable)
          .select('id')
          .eq('status', 'overdue');

      final summary = <String, dynamic>{
        'active_subscriptions': activeSubs.length,
        'trial_subscriptions': trialSubs.length,
        'cancelled_subscriptions': cancelledSubs.length,
        'total_revenue': totalRevenue,
        'mrr': mrr,
        'arr': mrr * 12,
        'pending_transactions': pendingTx.length,
        'overdue_invoices': overdueInvoices.length,
        'total_transactions': successfulTx.length,
      };

      AppLogger.info('Billing dashboard summary compiled');
      return summary;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getBillingDashboardSummary error', error: e);
      throw const ServerException(
        message: 'Failed to fetch billing dashboard summary.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<BillingNotificationModel>> getBillingNotifications({
    required String userId,
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabase
          .from(_notificationsTable)
          .select()
          .eq('user_id', userId) as sb.PostgrestFilterBuilder<dynamic>;

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      var transformed =
          query.order('created_at', ascending: false);
      transformed = _applyPagination(transformed, page: page, perPage: perPage);

      final list = await transformed;
      AppLogger.info(
        'Fetched ${list.length} billing notifications for $userId',
      );
      return list
          .map<BillingNotificationModel>(
            (row) => BillingNotificationModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getBillingNotifications error', error: e);
      throw const ServerException(
        message: 'Failed to fetch billing notifications.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
          })
          .eq('id', notificationId);

      AppLogger.info('Billing notification marked read: $notificationId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected markNotificationRead error', error: e);
      throw const ServerException(
        message: 'Failed to mark notification as read.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> updateNotificationPreferences({
    required String userId,
    required Map<String, bool> preferences,
  }) async {
    try {
      // Try to update existing preferences first
      final existing = await _supabase
          .from(_notificationPrefsTable)
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (existing.isNotEmpty) {
        await _supabase
            .from(_notificationPrefsTable)
            .update({
              'preferences': preferences,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await _supabase.from(_notificationPrefsTable).insert({
          'user_id': userId,
          'preferences': preferences,
        });
      }

      AppLogger.info('Notification preferences updated for $userId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Unexpected updateNotificationPreferences error',
        error: e,
      );
      throw const ServerException(
        message: 'Failed to update notification preferences.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Returns the current authenticated user ID, or `null` if not signed in.
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Applies filter criteria from a filter map to a Supabase query.
  sb.PostgrestFilterBuilder<dynamic> _applyFilters(
    sb.PostgrestFilterBuilder<dynamic> query,
    Map<String, dynamic> filters,
  ) {
    var q = query;

    for (final entry in filters.entries) {
      q = q.eq(entry.key, entry.value as String);
    }

    return q;
  }

  /// Applies pagination using Supabase range.
  sb.PostgrestTransformBuilder<dynamic> _applyPagination(
    sb.PostgrestTransformBuilder<dynamic> query, {
    int? page,
    int? perPage,
  }) {
    final p = page ?? 1;
    final pp = perPage ?? 20;
    final from = (p - 1) * pp;
    final to = from + pp - 1;
    return query.range(from, to);
  }

  /// Maps a Supabase [sb.PostgrestException] to a domain exception.
  Exception _mapPostgrestException(sb.PostgrestException e) {
    final statusCode = e.code != null ? int.tryParse(e.code!) ?? 0 : 0;
    final message = e.message ?? 'An unexpected database error occurred.';

    AppLogger.warning(
      'Supabase PostgrestException — code: ${e.code}, message: $message',
    );

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
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

  /// Generates a unique referral code from the referrer ID and type.
  String _generateReferralCode(String referrerId, String referrerType) {
    final prefix = referrerType == 'teacher_saas'
        ? 'TCH'
        : referrerType == 'school_saas'
            ? 'SCH'
            : 'ENT';
    final suffix = referrerId.substring(0, referrerId.length > 8 ? 8 : referrerId.length).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return '$prefix-$suffix-$timestamp';
  }
}
