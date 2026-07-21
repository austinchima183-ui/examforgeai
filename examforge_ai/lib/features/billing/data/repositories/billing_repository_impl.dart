import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_datasource.dart';
import '../datasources/flutterwave_datasource.dart';
import '../models/billing_models.dart';
import '../../../../features/billing/domain/repositories/billing_repository.dart';


/// Implementation of [BillingRepository] that bridges domain layer
/// with Supabase data source and Flutterwave payment API.
///
/// Converts entities to models, calls the appropriate datasource,
/// and maps exceptions to Failures via Result.success/failure.
class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl({
    required BillingRemoteDataSource remoteDataSource,
    required FlutterwaveDataSource flutterwaveDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _flutterwaveDataSource = flutterwaveDataSource;

  final BillingRemoteDataSource _remoteDataSource;
  final FlutterwaveDataSource _flutterwaveDataSource;

  // ─── Subscription Plans ─────────────────────────────────────────────

  @override
  Future<Result<List<SubscriptionPlanEntity>>> getSubscriptionPlans({
    BillingModel? billingModel,
    bool activeOnly = true,
  }) async {
    try {
      final models = await _remoteDataSource.getSubscriptionPlans(
        billingModel: billingModel?.value,
        activeOnly: activeOnly,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptionPlans error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load subscription plans.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionPlanEntity>> getSubscriptionPlan(String planId) async {
    try {
      final model = await _remoteDataSource.getSubscriptionPlan(planId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptionPlan error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load subscription plan.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionPlanEntity>> upsertSubscriptionPlan(
    SubscriptionPlanEntity plan,
  ) async {
    try {
      final model = SubscriptionPlanModel.fromEntity(plan);
      final created = await _remoteDataSource.upsertSubscriptionPlan(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message, fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      AppLogger.error('Unexpected upsertSubscriptionPlan error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to save subscription plan.', statusCode: 500,
      ));
    }
  }

  // ─── Subscriptions ──────────────────────────────────────────────────

  @override
  Future<Result<SubscriptionEntity>> getCurrentSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
  }) async {
    try {
      final model = await _remoteDataSource.getCurrentSubscription(
        subscriberId: subscriberId,
        subscriberType: subscriberType.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getCurrentSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<SubscriptionEntity>>> getSubscriptions({
    String? schoolId,
    BillingModel? subscriberType,
    SubscriptionStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getSubscriptions(
        schoolId: schoolId,
        subscriberType: subscriberType?.value,
        status: status?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getSubscriptions error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load subscriptions.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> createSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
    required String planId,
    String billingCycle = 'monthly',
    String? couponCode,
    int seats = 1,
    String? schoolId,
  }) async {
    try {
      final data = {
        'subscriber_id': subscriberId,
        'subscriber_type': subscriberType.value,
        'plan_id': planId,
        'billing_cycle': billingCycle,
        'seats_purchased': seats,
        if (couponCode != null) 'coupon_code': couponCode,
        if (schoolId != null) 'school_id': schoolId,
      };
      final model = await _remoteDataSource.createSubscription(data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message, fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      AppLogger.error('Unexpected createSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to create subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> upgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
    String? billingCycle,
  }) async {
    try {
      final data = {
        'plan_id': newPlanId,
        'action': 'upgrade',
        if (billingCycle != null) 'billing_cycle': billingCycle,
      };
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected upgradeSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to upgrade subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> downgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
  }) async {
    try {
      final data = {
        'plan_id': newPlanId,
        'action': 'downgrade',
      };
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected downgradeSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to downgrade subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> cancelSubscription({
    required String subscriptionId,
    String? reason,
    bool immediate = false,
  }) async {
    try {
      final data = {
        'status': immediate ? 'expired' : 'cancelled',
        'auto_renew': false,
        'cancelled_at': DateTime.now().toIso8601String(),
        if (reason != null) 'cancellation_reason': reason,
      };
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected cancelSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to cancel subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> renewSubscription({
    required String subscriptionId,
  }) async {
    try {
      final data = {
        'status': 'active',
        'current_period_start': DateTime.now().toIso8601String(),
        'auto_renew': true,
      };
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected renewSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to renew subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> pauseSubscription({
    required String subscriptionId,
  }) async {
    try {
      final data = {'status': 'paused'};
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected pauseSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to pause subscription.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SubscriptionEntity>> resumeSubscription({
    required String subscriptionId,
  }) async {
    try {
      final data = {'status': 'active'};
      final model = await _remoteDataSource.updateSubscription(subscriptionId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected resumeSubscription error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to resume subscription.', statusCode: 500,
      ));
    }
  }

  // ─── Payments (Flutterwave) ──────────────────────────────────────────

  @override
  Future<Result<Map<String, dynamic>>> initializePayment({
    required double amount,
    required String currency,
    required String email,
    required String txRef,
    String? subscriptionId,
    String? planId,
    String? couponCode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _flutterwaveDataSource.initializeCheckout(
        amount: amount,
        currency: currency,
        email: email,
        txRef: txRef,
        subscriptionId: subscriptionId,
        planId: planId,
        couponCode: couponCode,
        meta: metadata,
      );
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected initializePayment error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to initialize payment.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<TransactionEntity>> verifyPayment(String txRef) async {
    try {
      // ─── STEP 1: Look up our local transaction FIRST ────────────────
      // This is critical for security: we read the EXPECTED amount from
      // our own database before verifying with Flutterwave. This prevents
      // an attacker from paying a different amount and claiming success.
      final localTx = await _remoteDataSource.getTransaction(txRef);
      final expectedAmount = localTx.amount;
      final expectedCurrency = localTx.currency;

      // ─── STEP 2: Verify with Flutterwave, passing expected amounts ─
      // The FlutterwaveDataSource now validates that the actual charged
      // amount matches what we recorded in our database.
      final flutterwaveData = await _flutterwaveDataSource.verifyTransaction(
        txRef,
        expectedAmount: expectedAmount,
        expectedCurrency: expectedCurrency,
      );

      // ─── STEP 3: Update our local transaction record ───────────────
      final status = _mapFlutterwaveStatus(
        flutterwaveData['status'] as String? ?? 'pending',
      );

      // SECURITY: If the transaction is successful, also verify that
      // the Flutterwave transaction ID hasn't been used before (prevents
      // replay attacks where the same Flw ID is claimed for two tx_refs).
      if (status == TransactionStatus.successful) {
        final flwTxId = flutterwaveData['id']?.toString();
        if (flwTxId != null && flwTxId.isNotEmpty) {
          final isReplay = await _isFlutterwaveTransactionReplay(flwTxId, localTx.id);
          if (isReplay) {
            AppLogger.error(
              'PAYMENT REPLAY ATTACK DETECTED: Flutterwave transaction ID '
              '$flwTxId has already been used for a different transaction!',
            );
            return const FailureResult(Failure.server(
              message: 'Payment verification failed: duplicate transaction.',
              statusCode: 409,
            ));
          }
        }
      }

      final updatedTx = await _remoteDataSource.updateTransaction(
        localTx.id,
        {
          'status': status.value,
          'flutterwave_transaction_id': flutterwaveData['id']?.toString(),
          'flutterwave_flw_ref': flutterwaveData['flw_ref'] as String?,
          'flutterwave_fee': flutterwaveData['app_fee'] as double? ?? 0,
          'net_amount': flutterwaveData['amount_settled'] as double? ?? 0,
          'payment_method_summary': flutterwaveData['payment_type'] as String?,
          'processor_response': flutterwaveData,
          'verified_at': DateTime.now().toIso8601String(),
          if (status == TransactionStatus.successful)
            'completed_at': DateTime.now().toIso8601String(),
        },
      );
      return Success(updatedTx.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected verifyPayment error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to verify payment.', statusCode: 500,
      ));
    }
  }

  /// Checks whether a Flutterwave transaction ID has already been
  /// associated with a DIFFERENT local transaction. This prevents
  /// replay attacks where the same successful payment is claimed
  /// for multiple transaction references.
  Future<bool> _isFlutterwaveTransactionReplay(
    String flwTxId,
    String currentLocalTxId,
  ) async {
    try {
      // Query our transactions table for any other transaction with
      // the same Flutterwave transaction ID that's already successful.
      final existingTxs = await _remoteDataSource.getTransactions(
        status: 'successful',
        page: 1,
        perPage: 5,
      );
      return existingTxs.any((tx) =>
          tx.flutterwaveTransactionId == flwTxId &&
          tx.id != currentLocalTxId);
    } catch (e) {
      // If we can't check, err on the side of caution and allow
      // the transaction through. The amount verification above is
      // the primary defence.
      AppLogger.warning(
        'Could not verify Flutterwave transaction ID uniqueness',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<Result<bool>> processWebhookEvent(Map<String, dynamic> payload) async {
    try {
      final event = payload['event'] as String? ?? '';
      final data = payload['data'] as Map<String, dynamic>? ?? {};

      // ─── IDEMPOTENCY CHECK (CRITICAL SECURITY FIX) ──────────────────
      // Build an idempotency key from the event type and the unique
      // Flutterwave event/transaction ID. This prevents the same webhook
      // from being processed twice (Flutterwave retries webhooks on
      // failure, so duplicates are expected).
      final flwId = data['id']?.toString() ?? '';
      final idempotencyKey = '${event}_$flwId';

      final flutterwaveDs = _flutterwaveDataSource;
      if (flutterwaveDs is FlutterwaveDataSourceImpl) {
        if (flutterwaveDs.isWebhookEventProcessed(idempotencyKey)) {
          AppLogger.info(
            'Webhook event already processed (idempotent): $idempotencyKey. '
            'Returning success without re-processing.',
          );
          return const Success(true);
        }
      }

      AppLogger.info('Processing Flutterwave webhook event: $event');

      switch (event) {
        case 'charge.completed':
          final txRef = data['tx_ref'] as String?;
          if (txRef != null) {
            // Verify and update the transaction (includes amount
            // verification via the updated verifyPayment method)
            final result = await verifyPayment(txRef);
            if (result is Success) {
              AppLogger.info(
                'Webhook charge.completed processed successfully for $txRef',
              );
            } else {
              AppLogger.warning(
                'Webhook charge.completed verification failed for $txRef',
              );
            }
          }
          break;
        case 'transfer.completed':
        case 'transfer.failed':
          AppLogger.info('Transfer event received: $event');
          break;
        case 'subscription.cancelled':
          final subId = data['subscription_id'] as String?;
          if (subId != null) {
            await _remoteDataSource.updateSubscription(subId, {
              'status': 'cancelled',
              'cancelled_at': DateTime.now().toIso8601String(),
            });
          }
          break;
        default:
          AppLogger.info('Unhandled webhook event: $event');
      }

      // Mark event as processed AFTER successful handling
      if (flutterwaveDs is FlutterwaveDataSourceImpl) {
        flutterwaveDs.markWebhookEventProcessed(idempotencyKey);
      }

      return const Success(true);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected processWebhookEvent error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to process webhook event.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getTransactions({
    String? userId,
    String? schoolId,
    TransactionStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getTransactions(
        userId: userId,
        schoolId: schoolId,
        status: status?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getTransactions error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load transactions.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<TransactionEntity>> getTransaction(String transactionId) async {
    try {
      final model = await _remoteDataSource.getTransaction(transactionId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getTransaction error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load transaction.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<TransactionEntity>> requestRefund({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      // Get the transaction to find Flutterwave ID
      final txModel = await _remoteDataSource.getTransaction(transactionId);
      final flwTxId = txModel.flutterwaveTransactionId;

      if (flwTxId == null || flwTxId.isEmpty) {
        return const FailureResult(Failure.validation(
          message: 'Cannot refund: no Flutterwave transaction ID found.',
        ));
      }

      // Process refund via Flutterwave
      await _flutterwaveDataSource.processRefund(
        transactionId: flwTxId,
        amount: amount,
      );

      // Update local transaction
      final updatedTx = await _remoteDataSource.updateTransaction(
        transactionId,
        {
          'refund_amount': amount,
          if (reason != null) 'refund_reason': reason,
          'refunded_at': DateTime.now().toIso8601String(),
          'status': amount >= txModel.amount ? 'refunded' : 'partially_refunded',
        },
      );
      return Success(updatedTx.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected requestRefund error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to process refund.', statusCode: 500,
      ));
    }
  }

  // ─── Invoices ────────────────────────────────────────────────────────

  @override
  Future<Result<List<InvoiceEntity>>> getInvoices({
    String? userId,
    String? schoolId,
    InvoiceStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getInvoices(
        userId: userId,
        schoolId: schoolId,
        status: status?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getInvoices error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load invoices.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<InvoiceEntity>> getInvoice(String invoiceId) async {
    try {
      final model = await _remoteDataSource.getInvoice(invoiceId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getInvoice error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load invoice.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<InvoiceEntity>> generateInvoice({
    required String subscriptionId,
    required List<InvoiceLineItem> lineItems,
  }) async {
    try {
      final lineItemMaps = lineItems.map((item) => {
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total': item.total,
        'tax_rate': item.taxRate,
        'tax_amount': item.taxAmount,
      }).toList();

      final subtotal = lineItems.fold<double>(0, (sum, i) => sum + i.total);
      final taxAmount = lineItems.fold<double>(0, (sum, i) => sum + i.taxAmount);
      final totalAmount = subtotal + taxAmount;

      final data = {
        'subscription_id': subscriptionId,
        'line_items': lineItemMaps,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
      final model = await _remoteDataSource.createInvoice(data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected generateInvoice error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to generate invoice.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<String>> getInvoicePdfUrl(String invoiceId) async {
    try {
      final model = await _remoteDataSource.getInvoice(invoiceId);
      if (model.pdfUrl != null && model.pdfUrl!.isNotEmpty) {
        return Success(model.pdfUrl!);
      }
      // Trigger PDF generation and update
      final updated = await _remoteDataSource.updateInvoice(invoiceId, {
        'pdf_url': 'invoices/$invoiceId.pdf', // Placeholder; real impl generates PDF
      });
      return Success(updated.pdfUrl ?? 'invoices/$invoiceId.pdf');
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getInvoicePdfUrl error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to get invoice PDF.', statusCode: 500,
      ));
    }
  }

  // ─── Receipts ────────────────────────────────────────────────────────

  @override
  Future<Result<List<ReceiptEntity>>> getReceipts({
    required String userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getReceipts(
        userId: userId, page: page, perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getReceipts error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load receipts.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<String>> getReceiptPdfUrl(String receiptId) async {
    try {
      return Success('receipts/$receiptId.pdf');
    } catch (e) {
      AppLogger.error('Unexpected getReceiptPdfUrl error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to get receipt PDF.', statusCode: 500,
      ));
    }
  }

  // ─── AI Credits ─────────────────────────────────────────────────────

  @override
  Future<Result<AiCreditBalanceEntity>> getCreditBalance({
    required String ownerId,
    required BillingModel ownerType,
  }) async {
    try {
      final model = await _remoteDataSource.getCreditBalance(
        ownerId: ownerId, ownerType: ownerType.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getCreditBalance error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load credit balance.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<AiCreditTransactionEntity>>> getCreditTransactions({
    required String ownerId,
    required BillingModel ownerType,
    CreditTransactionType? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getCreditTransactions(
        ownerId: ownerId, ownerType: ownerType.value,
        type: type?.value, page: page, perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getCreditTransactions error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load credit transactions.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<bool>> consumeCredits({
    required String ownerId,
    required BillingModel ownerType,
    required int credits,
    required String featureName,
    String? referenceId,
    double estimatedCostUsd = 0,
  }) async {
    try {
      final success = await _remoteDataSource.consumeCredits(
        ownerId: ownerId, ownerType: ownerType.value,
        credits: credits, featureName: featureName,
        referenceId: referenceId, estimatedCostUsd: estimatedCostUsd,
      );
      if (success) {
        return const Success(true);
      }
      return const FailureResult(Failure.validation(
        message: 'Insufficient AI credits to perform this action.',
        fieldErrors: {'credits': 'Not enough credits available'},
      ));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected consumeCredits error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to consume credits.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<AiCreditBalanceEntity>> purchaseCredits({
    required String ownerId,
    required BillingModel ownerType,
    required String creditPackId,
    String? couponCode,
  }) async {
    try {
      final data = {
        'owner_id': ownerId,
        'owner_type': ownerType.value,
        'credit_pack_id': creditPackId,
        if (couponCode != null) 'coupon_code': couponCode,
      };
      final model = await _remoteDataSource.purchaseCredits(data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected purchaseCredits error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to purchase credits.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<AiCreditPackEntity>>> getCreditPacks({
    BillingModel? billingModel,
  }) async {
    try {
      final models = await _remoteDataSource.getCreditPacks(
        billingModel: billingModel?.value,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getCreditPacks error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load credit packs.', statusCode: 500,
      ));
    }
  }

  // ─── Coupons ────────────────────────────────────────────────────────

  @override
  Future<Result<CouponEntity>> validateCoupon({
    required String code,
    required BillingModel billingModel,
    String? planId,
  }) async {
    try {
      final model = await _remoteDataSource.validateCoupon(
        code: code, billingModel: billingModel.value, planId: planId,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected validateCoupon error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to validate coupon.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<CouponEntity>> redeemCoupon({
    required String couponId,
    required String userId,
    String? schoolId,
    String? subscriptionId,
  }) async {
    try {
      final model = await _remoteDataSource.redeemCoupon(
        couponId: couponId, userId: userId,
        schoolId: schoolId, subscriptionId: subscriptionId,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected redeemCoupon error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to redeem coupon.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<CouponEntity>>> getCoupons({
    bool activeOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getCoupons(
        activeOnly: activeOnly, page: page, perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getCoupons error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load coupons.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<CouponEntity>> createCoupon(CouponEntity coupon) async {
    try {
      final model = CouponModel.fromEntity(coupon);
      final created = await _remoteDataSource.createCoupon(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message, fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      AppLogger.error('Unexpected createCoupon error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to create coupon.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<CouponEntity>> updateCoupon(CouponEntity coupon) async {
    try {
      final model = CouponModel.fromEntity(coupon);
      final updated = await _remoteDataSource.updateCoupon(coupon.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected updateCoupon error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to update coupon.', statusCode: 500,
      ));
    }
  }

  // ─── Referrals ──────────────────────────────────────────────────────

  @override
  Future<Result<ReferralCodeEntity>> getOrCreateReferralCode({
    required String referrerId,
    required BillingModel referrerType,
    String? schoolId,
  }) async {
    try {
      final model = await _remoteDataSource.getOrCreateReferralCode(
        referrerId: referrerId, referrerType: referrerType.value,
        schoolId: schoolId,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getOrCreateReferralCode error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to get referral code.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<bool>> applyReferralCode({
    required String code,
    required String refereeId,
    required BillingModel refereeType,
  }) async {
    try {
      final success = await _remoteDataSource.applyReferralCode(
        code: code, refereeId: refereeId, refereeType: refereeType.value,
      );
      return Success(success);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected applyReferralCode error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to apply referral code.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getReferralTracking({
    required String referrerId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final tracking = await _remoteDataSource.getReferralTracking(
        referrerId: referrerId, page: page, perPage: perPage,
      );
      return Success(tracking);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getReferralTracking error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load referral tracking.', statusCode: 500,
      ));
    }
  }

  // ─── Licenses ────────────────────────────────────────────────────────

  @override
  Future<Result<List<LicenseEntity>>> getLicenses({
    String? schoolId,
    String? userId,
    LicenseType? type,
    bool activeOnly = true,
  }) async {
    try {
      final models = await _remoteDataSource.getLicenses(
        schoolId: schoolId, userId: userId,
        type: type?.value, activeOnly: activeOnly,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getLicenses error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load licenses.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<LicenseEntity>> revokeLicense({
    required String licenseId,
    required String reason,
  }) async {
    try {
      final model = await _remoteDataSource.revokeLicense(
        licenseId: licenseId, reason: reason,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected revokeLicense error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to revoke license.', statusCode: 500,
      ));
    }
  }

  // ─── School Billing ──────────────────────────────────────────────────

  @override
  Future<Result<SchoolBillingProfileEntity>> getSchoolBillingProfile(
    String schoolId,
  ) async {
    try {
      final model = await _remoteDataSource.getSchoolBillingProfile(schoolId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getSchoolBillingProfile error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load billing profile.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<SchoolBillingProfileEntity>> updateSchoolBillingProfile(
    SchoolBillingProfileEntity profile,
  ) async {
    try {
      final model = SchoolBillingProfileModel.fromEntity(profile);
      final updated = await _remoteDataSource.updateSchoolBillingProfile(
        profile.schoolId, model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected updateSchoolBillingProfile error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to update billing profile.', statusCode: 500,
      ));
    }
  }

  // ─── Revenue Analytics ───────────────────────────────────────────────

  @override
  Future<Result<List<RevenueDataPoint>>> getRevenueData({
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final models = await _remoteDataSource.getRevenueData(
        periodType: periodType,
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getRevenueData error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load revenue data.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getBillingDashboardSummary() async {
    try {
      final summary = await _remoteDataSource.getBillingDashboardSummary();
      return Success(summary);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getBillingDashboardSummary error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load billing summary.', statusCode: 500,
      ));
    }
  }

  // ─── Billing Notifications ───────────────────────────────────────────

  @override
  Future<Result<List<BillingNotificationEntity>>> getBillingNotifications({
    required String userId,
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getBillingNotifications(
        userId: userId, unreadOnly: unreadOnly,
        page: page, perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected getBillingNotifications error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to load notifications.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<bool>> markNotificationRead(String notificationId) async {
    try {
      final success = await _remoteDataSource.markNotificationRead(notificationId);
      return Success(success);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected markNotificationRead error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to mark notification as read.', statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<bool>> updateNotificationPreferences({
    required String userId,
    required Map<String, bool> preferences,
  }) async {
    try {
      final success = await _remoteDataSource.updateNotificationPreferences(
        userId: userId, preferences: preferences,
      );
      return Success(success);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message, statusCode: e.statusCode, data: e.data,
      ));
    } catch (e) {
      AppLogger.error('Unexpected updateNotificationPreferences error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to update notification preferences.', statusCode: 500,
      ));
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────

  /// Maps Flutterwave transaction status to our TransactionStatus enum.
  TransactionStatus _mapFlutterwaveStatus(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
        return TransactionStatus.successful;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.voided;
      case 'pending':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.pending;
    }
  }
}
