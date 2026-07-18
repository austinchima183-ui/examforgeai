import 'package:dio/dio.dart';

import '../../../../../core/errors/exceptions.dart';
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
  Future<Map<String, dynamic>> verifyTransaction(String txRef);

  /// Verify webhook signature.
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
// DIO IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Dio-backed implementation of [FlutterwaveDataSource].
///
/// Communicates with the Flutterwave v3 REST API for payment
/// processing. All HTTP errors are mapped to domain-specific
/// [ServerException] instances.
class FlutterwaveDataSourceImpl implements FlutterwaveDataSource {
  FlutterwaveDataSourceImpl({
    required String secretKey,
    required String publicKey,
    required String webhookSecretHash,
    Dio? dio,
  })  : _secretKey = secretKey,
        _publicKey = publicKey,
        _webhookSecretHash = webhookSecretHash,
        _dio = dio ?? _createDio(secretKey);

  final String _secretKey;
  final String _publicKey;
  final String _webhookSecretHash;
  final Dio _dio;

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
  // VERIFY TRANSACTION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> verifyTransaction(String txRef) async {
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
  // VERIFY WEBHOOK SIGNATURE
  // ═══════════════════════════════════════════════════════════════════

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

      final isValid = incomingHash == _webhookSecretHash;
      if (!isValid) {
        AppLogger.warning(
          'Webhook signature mismatch: expected=$_webhookSecretHash, got=$incomingHash',
        );
      }
      return isValid;
    } catch (e) {
      AppLogger.error('Webhook signature verification error', error: e);
      return false;
    }
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
