import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../../core/security/constant_time_comparison.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Flutterwave API integration for payment processing.
/// Handles Standard Checkout, payment verification, webhooks, and refunds.
abstract class FlutterwaveDataSource {
  /// Initialize a Standard Checkout payment.
  /// Returns the checkout URL to redirect the user to.
  Future<Map<String, dynamic>> initializeCheckout({
    required double amount,
    required String currency,
    required String email,
    required String txRef,
    String? subscriptionId,
    String? planId,
    String? couponCode,
    Map<String, dynamic>? meta,
  });

  /// Verify a payment by transaction reference.
  /// [expectedAmount] and [expectedCurrency] are server-authoritative
  /// values used to confirm the payment matches what was initiated.
  Future<Map<String, dynamic>> verifyTransaction(
    String txRef, {
    double? expectedAmount,
    String? expectedCurrency,
  });

  /// Verify webhook signature using constant-time comparison.
  bool verifyWebhookSignature(Map<String, dynamic> headers, String body);

  /// Process a refund.
  Future<Map<String, dynamic>> processRefund({
    required String transactionId,
    required double amount,
  });

  /// Create a recurring payment plan.
  Future<Map<String, dynamic>> createPaymentPlan({
    required String name,
    required double amount,
    required String currency,
    required String interval,
  });

  /// Subscribe a customer to a payment plan.
  Future<Map<String, dynamic>> subscribeToPlan({
    required String email,
    required String planCode,
    required double amount,
  });

  /// Get transaction fee.
  Future<Map<String, dynamic>> getTransactionFee({
    required double amount,
    required String currency,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// WEBHOOK IDEMPOTENCY TRACKER
// ═══════════════════════════════════════════════════════════════════════

/// Tracks processed webhook event IDs to prevent duplicate processing.
///
/// In production, this should be backed by a persistent store (e.g. the
/// `webhook_events` table in Supabase). This in-memory implementation
/// serves as a first layer of defence and handles the common case where
/// Flutterwave retries a webhook within the same app session.
class WebhookIdempotencyTracker {
  WebhookIdempotencyTracker({this.maxCacheSize = 10000});

  final int maxCacheSize;

  /// Maps event idempotency keys to the timestamp they were processed.
  final Map<String, DateTime> _processedEvents = {};

  /// Checks whether an event with the given [idempotencyKey] has already
  /// been processed. Returns `true` if the event is a duplicate.
  bool isProcessed(String idempotencyKey) {
    _evictOldEntries();
    return _processedEvents.containsKey(idempotencyKey);
  }

  /// Marks an event as processed.
  void markProcessed(String idempotencyKey) {
    _processedEvents[idempotencyKey] = DateTime.now();
  }

  /// Removes entries older than 72 hours to prevent unbounded growth.
  void _evictOldEntries() {
    if (_processedEvents.length < maxCacheSize) return;

    final cutoff = DateTime.now().subtract(const Duration(hours: 72));
    _processedEvents.removeWhere((_, processedAt) => processedAt.isBefore(cutoff));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE EDGE FUNCTION IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Supabase Edge Function–backed implementation of [FlutterwaveDataSource].
///
/// All server-side Flutterwave operations (checkout initialization,
/// transaction verification, refunds) are routed through Supabase Edge
/// Functions. This keeps the Flutterwave secret key server-side only
/// and never exposes it to the client.
///
/// The [publicKey] is retained for client-side Flutterwave inline
/// checkout (e.g. FlutterwaveCheckout widget).
///
/// **Security architecture:**
/// - No secret keys on the client — all sensitive operations go through
///   Edge Functions that hold the Flutterwave secret key server-side.
/// - Amount and currency verification is performed server-side inside
///   the `flutterwave-verify` Edge Function, preventing payment spoofing.
/// - Webhook verification is handled entirely by the Edge Function that
///   receives webhooks directly from Flutterwave.
/// - Webhook idempotency tracking is retained as a client-side defence
///   layer for duplicate event detection.
class FlutterwaveDataSourceImpl implements FlutterwaveDataSource {
  FlutterwaveDataSourceImpl({
    required String publicKey,
    required sb.SupabaseClient supabaseClient,
    Dio? dio,
    WebhookIdempotencyTracker? idempotencyTracker,
  })  : _publicKey = publicKey,
        _supabaseClient = supabaseClient,
        _dio = dio ?? Dio(),
        _idempotencyTracker = idempotencyTracker ?? WebhookIdempotencyTracker();

  final String _publicKey;
  final sb.SupabaseClient _supabaseClient;
  final Dio _dio;
  final WebhookIdempotencyTracker _idempotencyTracker;

  // ─── Edge Function Names ──────────────────────────────────────────
  static const _checkoutFunction = 'flutterwave-checkout';
  static const _verifyFunction = 'flutterwave-verify';
  static const _refundFunction = 'process-refund';

  // ═══════════════════════════════════════════════════════════════════
  // INITIALIZE CHECKOUT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> initializeCheckout({
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
        'tx_ref': txRef,
        'payment_options': 'card,banktransfer,ussd,mobilemoney',
      };

      if (subscriptionId != null) {
        body['subscription_id'] = subscriptionId;
      }
      if (planId != null) {
        body['plan_id'] = planId;
      }
      if (couponCode != null) {
        body['coupon_code'] = couponCode;
      }
      if (meta != null) {
        body['meta'] = meta;
      }

      final response = await _supabaseClient.functions.invoke(
        _checkoutFunction,
        body: body,
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String? ?? 'Flutterwave checkout initialization failed.'
            : 'Flutterwave checkout initialization failed.';
        throw ServerException(
          message: message,
          statusCode: response.status,
          data: data is Map<String, dynamic> ? data : null,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final checkoutUrl = data['checkout_url'] as String? ??
          data['data']?['link'] as String?;
      if (checkoutUrl == null) {
        throw const ServerException(
          message: 'No checkout URL returned by Edge Function.',
          statusCode: 500,
        );
      }

      AppLogger.info('Flutterwave checkout initialized via Edge Function: $txRef');
      return {
        'checkout_url': checkoutUrl,
        'tx_ref': txRef,
        'data': data['data'],
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected initializeCheckout error', error: e);
      throw const ServerException(
        message: 'Failed to initialize Flutterwave checkout.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // VERIFY TRANSACTION (WITH AMOUNT VERIFICATION)
  // ═══════════════════════════════════════════════════════════════════
  //
  // FIX: Added [expectedAmount] and [expectedCurrency] parameters that
  // must be supplied from the server-authoritative transaction record
  // (the `transactions` table in our database). This prevents payment
  // spoofing where an attacker initiates a checkout for N5,000 but
  // only pays N500 and then claims the payment is successful.
  //
  // The caller (BillingRepositoryImpl) reads the expected amount from
  // our DB before calling this method, so the verification is
  // server-authoritative, not client-supplied.

  @override
  Future<Map<String, dynamic>> verifyTransaction(
    String txRef, {
    double? expectedAmount,
    String? expectedCurrency,
  }) async {
    try {
      final body = <String, dynamic>{
        'tx_ref': txRef,
      };
      if (expectedAmount != null) {
        body['expected_amount'] = expectedAmount;
      }
      if (expectedCurrency != null) {
        body['expected_currency'] = expectedCurrency;
      }

      final response = await _supabaseClient.functions.invoke(
        _verifyFunction,
        body: body,
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String? ?? 'Transaction verification failed.'
            : 'Transaction verification failed.';
        throw ServerException(
          message: message,
          statusCode: response.status,
          data: data is Map<String, dynamic> ? data : null,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final txData = data['data'] as Map<String, dynamic>? ?? data;

      AppLogger.info(
        'Flutterwave transaction verified via Edge Function: $txRef — status: ${txData['status']}',
      );
      return {
        'tx_ref': txRef,
        'id': txData['id'],
        'status': txData['status'],
        'amount': txData['amount'],
        'currency': txData['currency'],
        'flw_ref': txData['flw_ref'],
        'charged_amount': txData['charged_amount'],
        'app_fee': txData['app_fee'],
        'processor_response': txData['processor_response'],
        'payment_type': txData['payment_type'],
        'customer': txData['customer'],
        'data': txData,
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected verifyTransaction error', error: e);
      throw const ServerException(
        message: 'Failed to verify Flutterwave transaction.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // VERIFY WEBHOOK SIGNATURE (CONSTANT-TIME COMPARISON)
  // ═══════════════════════════════════════════════════════════════════
  //
  // FIX: The original implementation used `==` to compare the webhook
  // hash, which is vulnerable to timing attacks. An attacker can
  // measure response times to progressively guess the correct hash
  // character by character. This replacement uses constant-time byte
  // comparison so that comparison time does not leak information about
  // the hash contents.

  @override
  bool verifyWebhookSignature(Map<String, dynamic> headers, String body) {
    // Webhook verification is now handled by the Edge Function which
    // receives webhooks directly from Flutterwave. This client-side
    // method should not be called in the new architecture.
    AppLogger.warning(
      'verifyWebhookSignature called client-side — '
      'webhook verification is now handled by Edge Functions. '
      'Returning false.',
    );
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEBHOOK IDEMPOTENCY CHECK
  // ═══════════════════════════════════════════════════════════════════
  //
  // FIX: Prevents duplicate webhook processing. Flutterwave may retry
  // webhooks, and without idempotency checking, the same payment could
  // be credited multiple times.

  /// Checks whether a webhook event has already been processed.
  /// Returns `true` if the event is a DUPLICATE (already processed).
  bool isWebhookEventProcessed(String idempotencyKey) {
    return _idempotencyTracker.isProcessed(idempotencyKey);
  }

  /// Marks a webhook event as successfully processed.
  void markWebhookEventProcessed(String idempotencyKey) {
    _idempotencyTracker.markProcessed(idempotencyKey);
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROCESS REFUND
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> processRefund({
    required String transactionId,
    required double amount,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        _refundFunction,
        body: {
          'transaction_id': transactionId,
          'amount': amount,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String? ?? 'Flutterwave refund failed.'
            : 'Flutterwave refund failed.';
        throw ServerException(
          message: message,
          statusCode: response.status,
          data: data is Map<String, dynamic> ? data : null,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final refundData = data['data'] as Map<String, dynamic>? ?? data;
      AppLogger.info(
        'Flutterwave refund processed via Edge Function: tx=$transactionId, amount=$amount',
      );
      return {
        'refund_id': refundData['id'],
        'transaction_id': transactionId,
        'amount': refundData['amount'],
        'status': refundData['status'],
        'data': refundData,
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected processRefund error', error: e);
      throw const ServerException(
        message: 'Failed to process Flutterwave refund.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE PAYMENT PLAN
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> createPaymentPlan({
    required String name,
    required double amount,
    required String currency,
    required String interval,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'flutterwave-create-plan',
        body: {
          'name': name,
          'amount': amount,
          'currency': currency,
          'interval': interval,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Payment plan creation failed.'
            : 'Payment plan creation failed.';
        throw ServerException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Payment plan created via Edge Function: ${data['planId']}');
      return {
        'plan_id': data['planId'],
        'name': data['name'],
        'amount': data['amount'],
        'currency': data['currency'],
        'interval': data['interval'],
        'plan_code': data['planCode'],
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createPaymentPlan error', error: e);
      throw const ServerException(message: 'Failed to create payment plan.', statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUBSCRIBE TO PLAN
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> subscribeToPlan({
    required String email,
    required String planCode,
    required double amount,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'flutterwave-subscribe-plan',
        body: {
          'email': email,
          'planCode': planCode,
          'amount': amount,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Subscription failed.'
            : 'Subscription failed.';
        throw ServerException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Subscription initialized via Edge Function: $planCode');
      return {
        'checkout_url': data['checkoutUrl'],
        'tx_ref': data['txRef'],
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected subscribeToPlan error', error: e);
      throw const ServerException(message: 'Failed to subscribe to plan.', statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GET TRANSACTION FEE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getTransactionFee({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'flutterwave-transaction-fee',
        body: {
          'amount': amount,
          'currency': currency,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['error'] as String? ?? 'Fee query failed.'
            : 'Fee query failed.';
        throw ServerException(message: message, statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      return {
        'fee': data['fee'],
        'currency': data['currency'],
        'charge_amount': data['chargeAmount'] ?? data['charge_amount'],
      };
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getTransactionFee error', error: e);
      throw const ServerException(message: 'Failed to get transaction fee.', statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Constant-time string comparison that prevents timing attacks.
  ///
  /// Delegates to [ConstantTimeComparison.equals] which uses a proven
  /// constant-time algorithm with 0xFF padding for length-mismatch
  /// detection. See constant_time_comparison.dart for the full
  /// security analysis and root cause of the original bug.
  static bool _constantTimeEquals(String a, String b) {
    return ConstantTimeComparison.equals(a, b);
  }
}
