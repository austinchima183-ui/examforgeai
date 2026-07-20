import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/security/constant_time_comparison.dart';
import '../../../../../core/utils/logger.dart';

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
// DIO IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Dio-backed implementation of [FlutterwaveDataSource].
///
/// Communicates with the Flutterwave v3 REST API for payment
/// processing. All HTTP errors are mapped to domain-specific
/// [ServerException] instances.
///
/// **Security improvements over the original implementation:**
/// - Constant-time HMAC comparison for webhook signatures (prevents
///   timing attacks).
/// - Server-side amount verification during `verifyTransaction`
///   (prevents payment spoofing where an attacker pays a different
///   amount than expected).
/// - Webhook idempotency tracking to prevent duplicate event processing.
class FlutterwaveDataSourceImpl implements FlutterwaveDataSource {
  FlutterwaveDataSourceImpl({
    required String secretKey,
    required String publicKey,
    required String webhookSecretHash,
    Dio? dio,
    WebhookIdempotencyTracker? idempotencyTracker,
  })  : _secretKey = secretKey,
        _publicKey = publicKey,
        _webhookSecretHash = webhookSecretHash,
        _dio = dio ?? _createDio(secretKey),
        _idempotencyTracker = idempotencyTracker ?? WebhookIdempotencyTracker();

  final String _secretKey;
  final String _publicKey;
  final String _webhookSecretHash;
  final Dio _dio;
  final WebhookIdempotencyTracker _idempotencyTracker;

  // ─── Base URL ─────────────────────────────────────────────────────
  static const _baseUrl = 'https://api.flutterwave.com/v3';

  // ─── Dio Factory ──────────────────────────────────────────────────

  /// Creates a pre-configured [Dio] instance with authorization headers.
  static Dio _createDio(String secretKey) {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    return dio;
  }

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
      final payload = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'email': email,
        'tx_ref': txRef,
        'redirect_url': '', // Configured server-side or via env
        'payment_options': 'card,banktransfer,ussd,mobilemoney',
        'customizations': {
          'title': 'ExamForge AI',
          'description': 'Subscription payment',
          'logo': '',
        },
      };

      if (subscriptionId != null) {
        payload['subaccounts'] = [];
        payload['meta'] = {
          'subscription_id': subscriptionId,
          if (planId != null) 'plan_id': planId,
          if (couponCode != null) 'coupon_code': couponCode,
          if (meta != null) ...meta,
        };
      } else if (meta != null) {
        payload['meta'] = meta;
      }

      if (planId != null) {
        payload['payment_plan'] = planId;
      }

      final response = await _dio.post('/payments', data: payload);

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Flutterwave checkout initialization failed.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final checkoutUrl = data['data']?['link'] as String?;
      if (checkoutUrl == null) {
        throw const ServerException(
          message: 'No checkout URL returned by Flutterwave.',
          statusCode: 500,
        );
      }

      AppLogger.info('Flutterwave checkout initialized: $txRef');
      return {
        'checkout_url': checkoutUrl,
        'tx_ref': txRef,
        'data': data['data'],
      };
    } on DioException catch (e) {
      throw _mapDioException(e);
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
      final response = await _dio.get(
        '/transactions/verify_by_reference',
        queryParameters: {'tx_ref': txRef},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Transaction verification failed.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final txData = data['data'] as Map<String, dynamic>? ?? {};

      // ─── AMOUNT VERIFICATION (CRITICAL SECURITY FIX) ───────────────
      // Compare the actual charged amount against the expected amount
      // from our database. The Flutterwave `charged_amount` is what was
      // actually debited from the customer's account. An attacker who
      // pays a different amount should NOT get credit for the full amount.
      if (expectedAmount != null) {
        final chargedAmount = (txData['charged_amount'] as num?)?.toDouble() ?? 0.0;
        // Allow a small tolerance (1.0) to account for rounding and
        // currency conversion differences. For NGN, this is less than
        // N1 difference which is acceptable.
        const tolerance = 1.0;
        if ((chargedAmount - expectedAmount).abs() > tolerance) {
          AppLogger.error(
            'PAYMENT AMOUNT MISMATCH: expected=$expectedAmount, '
            'charged=$chargedAmount, txRef=$txRef. '
            'Possible payment spoofing attempt!',
          );
          throw ServerException(
            message: 'Payment amount verification failed. '
                'Expected $expectedAmount but received $chargedAmount.',
            statusCode: 400,
            data: {
              'expected_amount': expectedAmount,
              'charged_amount': chargedAmount,
              'tx_ref': txRef,
            },
          );
        }
      }

      // ─── CURRENCY VERIFICATION ─────────────────────────────────────
      if (expectedCurrency != null) {
        final actualCurrency = txData['currency'] as String? ?? '';
        if (actualCurrency.toUpperCase() != expectedCurrency.toUpperCase()) {
          AppLogger.error(
            'PAYMENT CURRENCY MISMATCH: expected=$expectedCurrency, '
            'actual=$actualCurrency, txRef=$txRef',
          );
          throw ServerException(
            message: 'Payment currency verification failed. '
                'Expected $expectedCurrency but received $actualCurrency.',
            statusCode: 400,
            data: {
              'expected_currency': expectedCurrency,
              'actual_currency': actualCurrency,
              'tx_ref': txRef,
            },
          );
        }
      }

      AppLogger.info(
        'Flutterwave transaction verified: $txRef — status: ${txData['status']}',
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
    } on DioException catch (e) {
      throw _mapDioException(e);
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
    try {
      // Flutterwave sends the webhook signature in the 'verif-hash' header
      final incomingHash = headers['verif-hash'] as String? ??
          headers['Verif-Hash'] as String? ??
          '';

      if (incomingHash.isEmpty || _webhookSecretHash.isEmpty) {
        AppLogger.warning(
          'Webhook signature verification failed: missing hash(es)',
        );
        return false;
      }

      // ─── CONSTANT-TIME COMPARISON ──────────────────────────────────
      // Convert both strings to UTF-8 bytes and compare every byte,
      // accumulating the XOR of all byte pairs. The result is true
      // only if ALL bytes match (accumulated XOR == 0) AND the lengths
      // match. This eliminates timing side-channels.
      final isValid = _constantTimeEquals(incomingHash, _webhookSecretHash);

      if (!isValid) {
        // WARNING: Do NOT log the actual hash values in production.
        // Only log a generic mismatch message.
        AppLogger.warning(
          'Webhook signature mismatch for incoming hash (length: '
          '${incomingHash.length})',
        );
      }
      return isValid;
    } catch (e) {
      AppLogger.error('Webhook signature verification error', error: e);
      return false;
    }
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
      final payload = <String, dynamic>{
        'amount': amount,
      };

      final response = await _dio.post(
        '/transactions/$transactionId/refund',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Flutterwave refund failed.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final refundData = data['data'] as Map<String, dynamic>? ?? {};
      AppLogger.info(
        'Flutterwave refund processed: tx=$transactionId, amount=$amount',
      );
      return {
        'refund_id': refundData['id'],
        'transaction_id': transactionId,
        'amount': refundData['amount'],
        'status': refundData['status'],
        'data': refundData,
      };
    } on DioException catch (e) {
      throw _mapDioException(e);
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
      final payload = <String, dynamic>{
        'name': name,
        'amount': amount,
        'currency': currency,
        'interval': interval,
      };

      final response = await _dio.post('/payment-plans', data: payload);

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Flutterwave payment plan creation failed.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final planData = data['data'] as Map<String, dynamic>? ?? {};
      AppLogger.info(
        'Flutterwave payment plan created: ${planData['id']} — $name',
      );
      return {
        'plan_id': planData['id'],
        'plan_code': planData['plan_code'],
        'name': planData['name'],
        'amount': planData['amount'],
        'currency': planData['currency'],
        'interval': planData['interval'],
        'data': planData,
      };
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createPaymentPlan error', error: e);
      throw const ServerException(
        message: 'Failed to create Flutterwave payment plan.',
        statusCode: 500,
      );
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
      final payload = <String, dynamic>{
        'email': email,
        'plan': planCode,
        'amount': amount,
      };

      final response = await _dio.post(
        '/payment-plans/$planCode/subscribe',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Flutterwave plan subscription failed.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final subData = data['data'] as Map<String, dynamic>? ?? {};
      AppLogger.info(
        'Flutterwave plan subscription created: ${subData['id']} for $email',
      );
      return {
        'subscription_id': subData['id'],
        'plan_code': planCode,
        'email': email,
        'status': subData['status'],
        'data': subData,
      };
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected subscribeToPlan error', error: e);
      throw const ServerException(
        message: 'Failed to subscribe to Flutterwave payment plan.',
        statusCode: 500,
      );
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
      final response = await _dio.get(
        '/transactions/fee',
        queryParameters: {
          'amount': amount,
          'currency': currency,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        throw ServerException(
          message: data['message'] as String? ??
              'Failed to fetch Flutterwave transaction fee.',
          statusCode: response.statusCode ?? 500,
          data: data,
        );
      }

      final feeData = data['data'] as Map<String, dynamic>? ?? {};
      AppLogger.info(
        'Flutterwave transaction fee fetched: $amount $currency',
      );
      return {
        'charge_amount': feeData['charge_amount'],
        'fee': feeData['fee'],
        'merchant_fee': feeData['merchant_fee'],
        'data': feeData,
      };
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getTransactionFee error', error: e);
      throw const ServerException(
        message: 'Failed to fetch Flutterwave transaction fee.',
        statusCode: 500,
      );
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

  /// Maps a [DioException] to a domain [ServerException].
  ServerException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection to Flutterwave timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.badResponse:
        final responseBody = e.response?.data;
        if (responseBody is Map<String, dynamic>) {
          message = responseBody['message'] as String? ??
              'Flutterwave API returned an error.';
        } else {
          message = 'Flutterwave API returned an error (HTTP $statusCode).';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request to Flutterwave was cancelled.';
        break;
      case DioExceptionType.badCertificate:
        message = 'SSL certificate verification failed.';
        break;
      case DioExceptionType.unknown:
        message = 'An unexpected error occurred communicating with Flutterwave.';
        break;
    }

    AppLogger.warning(
      'DioException — type: ${e.type}, statusCode: $statusCode, message: $message',
    );

    return ServerException(
      message: message,
      statusCode: statusCode,
      data: e.response?.data,
    );
  }
}
