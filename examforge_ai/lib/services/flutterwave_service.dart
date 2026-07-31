// ============================================================================
// ExamForge AI — Flutterwave Payment Service
// ============================================================================
// Client-side service that delegates all sensitive Flutterwave operations
// to Supabase Edge Functions. The secret key is NEVER exposed to the client.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/utils/logger.dart';

/// Payment plan interval options.
enum PaymentPlanInterval {
  daily,
  weekly,
  monthly,
  quarterly,
  biannually,
  annually,
}

/// Result of a checkout initialization.
class CheckoutResult {
  const CheckoutResult({
    required this.checkoutUrl,
    required this.txRef,
    this.transactionId,
  });

  final String checkoutUrl;
  final String txRef;
  final String? transactionId;
}

/// Result of a payment verification.
class VerificationResult {
  const VerificationResult({
    required this.status,
    required this.txRef,
    this.amount,
    this.currency,
    this.flwTransactionId,
    this.paymentMethod,
  });

  final String status;
  final String txRef;
  final double? amount;
  final String? currency;
  final String? flwTransactionId;
  final String? paymentMethod;

  bool get isSuccessful => status == 'successful';
}

/// Result of a refund request.
class RefundResult {
  const RefundResult({
    required this.success,
    this.refundId,
    this.transactionId,
    this.refundAmount,
    this.newRefundedAmount,
    this.transactionStatus,
    this.error,
  });

  final bool success;
  final String? refundId;
  final String? transactionId;
  final double? refundAmount;
  final double? newRefundedAmount;
  final String? transactionStatus;
  final String? error;
}

/// Result of a payment plan creation.
class PaymentPlanResult {
  const PaymentPlanResult({
    required this.planId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.interval,
    this.planCode,
  });

  final int? planId;
  final String name;
  final double amount;
  final String currency;
  final String interval;
  final String? planCode;
}

/// Result of a transaction fee query.
class TransactionFeeResult {
  const TransactionFeeResult({
    required this.fee,
    required this.currency,
    this.chargeAmount,
  });

  final double? fee;
  final String? currency;
  final double? chargeAmount;
}

/// Flutterwave payment service that routes all sensitive operations
/// through Supabase Edge Functions.
class FlutterwaveService {
  FlutterwaveService({required sb.SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Edge Function Names ──────────────────────────────────────────
  static const _checkoutFunction = 'flutterwave-checkout';
  static const _verifyFunction = 'flutterwave-verify';
  static const _refundFunction = 'process-refund';
  static const _createPlanFunction = 'flutterwave-create-plan';
  static const _subscribePlanFunction = 'flutterwave-subscribe-plan';
  static const _transactionFeeFunction = 'flutterwave-transaction-fee';

  // ─── Initialize Checkout ──────────────────────────────────────────

  /// Initializes a Flutterwave checkout session.
  ///
  /// Returns a [CheckoutResult] with the checkout URL to redirect the user to.
  /// All sensitive operations (secret key, integrity hash) are handled
  /// server-side by the Edge Function.
  Future<CheckoutResult> initializeCheckout({
    required double amount,
    required String currency,
    required String email,
    required String txRef,
    String? subscriptionId,
    String? planId,
    String? couponCode,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'email': email,
        'txRef': txRef,
      };

      if (subscriptionId != null) body['subscription_id'] = subscriptionId;
      if (planId != null) body['plan_id'] = planId;
      if (couponCode != null) body['coupon_code'] = couponCode;
      if (meta != null) body['meta'] = meta;

      final response = await _supabaseClient.functions.invoke(
        _checkoutFunction,
        body: body,
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Checkout initialization failed'
            : 'Checkout initialization failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Flutterwave checkout initialized: $txRef');

      return CheckoutResult(
        checkoutUrl: data['checkoutUrl'] as String? ?? data['checkout_url'] as String? ?? '',
        txRef: data['txRef'] as String? ?? data['tx_ref'] as String? ?? txRef,
        transactionId: data['transactionId'] as String? ?? data['transaction_id'] as String?,
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected checkout error', error: e);
      throw const FlutterwaveException(message: 'Failed to initialize checkout');
    }
  }

  // ─── Verify Payment ───────────────────────────────────────────────

  /// Verifies a payment by transaction reference.
  ///
  /// Amount and currency verification is performed server-side by the
  /// Edge Function, preventing payment spoofing.
  Future<VerificationResult> verifyPayment({
    required String txRef,
    double? expectedAmount,
    String? expectedCurrency,
  }) async {
    try {
      final body = <String, dynamic>{'txRef': txRef};
      if (expectedAmount != null) body['expectedAmount'] = expectedAmount;
      if (expectedCurrency != null) body['expectedCurrency'] = expectedCurrency;

      final response = await _supabaseClient.functions.invoke(
        _verifyFunction,
        body: body,
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Verification failed'
            : 'Verification failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Payment verified: $txRef — status: ${data['status']}');

      return VerificationResult(
        status: data['status'] as String? ?? 'unknown',
        txRef: data['txRef'] as String? ?? txRef,
        amount: (data['amount'] as num?)?.toDouble(),
        currency: data['currency'] as String?,
        flwTransactionId: data['flwTransactionId']?.toString() ?? data['flw_transaction_id']?.toString(),
        paymentMethod: data['paymentMethod'] as String? ?? data['payment_type'] as String?,
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected verification error', error: e);
      throw const FlutterwaveException(message: 'Failed to verify payment');
    }
  }

  // ─── Process Refund ───────────────────────────────────────────────

  /// Processes a refund for a transaction.
  ///
  /// Only admins can process refunds. The Edge Function validates:
  /// - User authorization (super_admin or school_admin)
  /// - Transaction ownership (school admin can only refund own school)
  /// - Refund amount doesn't exceed original
  /// - No duplicate refunds
  Future<RefundResult> processRefund({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        _refundFunction,
        body: {
          'transactionId': transactionId,
          'amount': amount,
          'reason': reason ?? 'No reason provided',
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Refund failed'
            : 'Refund failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Refund processed: $transactionId — amount: $amount');

      return RefundResult(
        success: data['success'] as bool? ?? false,
        refundId: data['refundId']?.toString() ?? data['refund_id']?.toString(),
        transactionId: data['transactionId'] as String? ?? transactionId,
        refundAmount: (data['refundAmount'] as num?)?.toDouble() ?? amount,
        newRefundedAmount: (data['newRefundedAmount'] as num?)?.toDouble() ?? (data['new_refunded_amount'] as num?)?.toDouble(),
        transactionStatus: data['transactionStatus'] as String? ?? data['transaction_status'] as String?,
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected refund error', error: e);
      throw const FlutterwaveException(message: 'Failed to process refund');
    }
  }

  // ─── Create Payment Plan ──────────────────────────────────────────

  /// Creates a recurring payment plan.
  ///
  /// Only admins can create payment plans. The Edge Function validates
  /// authorization and calls the Flutterwave API with the secret key.
  Future<PaymentPlanResult> createPaymentPlan({
    required String name,
    required double amount,
    required String currency,
    required PaymentPlanInterval interval,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        _createPlanFunction,
        body: {
          'name': name,
          'amount': amount,
          'currency': currency,
          'interval': interval.name,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Plan creation failed'
            : 'Plan creation failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Payment plan created: ${data['planId']}');

      return PaymentPlanResult(
        planId: data['planId'] as int?,
        name: data['name'] as String? ?? name,
        amount: (data['amount'] as num?)?.toDouble() ?? amount,
        currency: data['currency'] as String? ?? currency,
        interval: data['interval'] as String? ?? interval.name,
        planCode: data['planCode'] as String?,
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected plan creation error', error: e);
      throw const FlutterwaveException(message: 'Failed to create payment plan');
    }
  }

  // ─── Subscribe to Plan ────────────────────────────────────────────

  /// Subscribes a customer to a payment plan.
  ///
  /// Returns a checkout URL for the subscription payment.
  Future<CheckoutResult> subscribeToPlan({
    required String email,
    required String planCode,
    double? amount,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'planCode': planCode,
      };
      if (amount != null) body['amount'] = amount;

      final response = await _supabaseClient.functions.invoke(
        _subscribePlanFunction,
        body: body,
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Subscription failed'
            : 'Subscription failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Subscription initialized: $planCode');

      return CheckoutResult(
        checkoutUrl: data['checkoutUrl'] as String? ?? '',
        txRef: data['txRef'] as String? ?? '',
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected subscription error', error: e);
      throw const FlutterwaveException(message: 'Failed to subscribe to plan');
    }
  }

  // ─── Get Transaction Fee ──────────────────────────────────────────

  /// Gets the transaction fee for a given amount and currency.
  Future<TransactionFeeResult> getTransactionFee({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        _transactionFeeFunction,
        body: {'amount': amount, 'currency': currency},
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Fee query failed'
            : 'Fee query failed';
        throw FlutterwaveException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      return TransactionFeeResult(
        fee: (data['fee'] as num?)?.toDouble(),
        currency: data['currency'] as String?,
        chargeAmount: (data['chargeAmount'] as num?)?.toDouble() ?? (data['charge_amount'] as num?)?.toDouble(),
      );
    } on FlutterwaveException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected fee query error', error: e);
      throw const FlutterwaveException(message: 'Failed to get transaction fee');
    }
  }
}

/// Exception thrown by Flutterwave operations.
class FlutterwaveException implements Exception {
  const FlutterwaveException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => 'FlutterwaveException: $message (status: $statusCode)';
}
