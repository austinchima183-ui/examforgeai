import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/billing_entities.dart';
import '../../repositories/billing_repository.dart';

// ─── Initialize Payment ──────────────────────────────────────────────────────

class InitializePaymentParams {
  const InitializePaymentParams({
    required this.amount,
    required this.currency,
    required this.email,
    required this.txRef,
    this.subscriptionId,
    this.planId,
    this.couponCode,
    this.metadata,
  });

  final double amount;
  final String currency;
  final String email;
  final String txRef;
  final String? subscriptionId;
  final String? planId;
  final String? couponCode;
  final Map<String, dynamic>? metadata;
}

class InitializePaymentUseCase {
  InitializePaymentUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaymentInitializationEntity>> call(
    InitializePaymentParams params,
  ) async {
    if (params.amount <= 0) {
      return FailureResult(
        Failure.validation(message: 'Amount must be greater than 0'),
      );
    }
    if (params.email.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Email cannot be empty'),
      );
    }
    if (params.txRef.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Transaction reference cannot be empty'),
      );
    }

    return _repository.initializePayment(
      amount: params.amount,
      currency: params.currency,
      email: params.email,
      txRef: params.txRef,
      subscriptionId: params.subscriptionId,
      planId: params.planId,
      couponCode: params.couponCode,
      metadata: params.metadata,
    );
  }
}

// ─── Verify Payment ──────────────────────────────────────────────────────────

class VerifyPaymentParams {
  const VerifyPaymentParams({required this.txRef});
  final String txRef;
}

class VerifyPaymentUseCase {
  VerifyPaymentUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaymentVerificationEntity>> call(
    VerifyPaymentParams params,
  ) async {
    if (params.txRef.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Transaction reference cannot be empty'),
      );
    }

    return _repository.verifyPayment(txRef: params.txRef);
  }
}

// ─── Process Webhook ─────────────────────────────────────────────────────────

class ProcessWebhookParams {
  const ProcessWebhookParams({required this.payload});
  final Map<String, dynamic> payload;
}

class ProcessWebhookUseCase {
  ProcessWebhookUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<void>> call(ProcessWebhookParams params) async {
    if (params.payload.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Webhook payload cannot be empty'),
      );
    }

    return _repository.processWebhook(payload: params.payload);
  }
}

// ─── Request Refund ──────────────────────────────────────────────────────────

class RequestRefundParams {
  const RequestRefundParams({
    required this.transactionId,
    required this.amount,
    this.reason,
  });

  final String transactionId;
  final double amount;
  final String? reason;
}

class RequestRefundUseCase {
  RequestRefundUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<RefundEntity>> call(RequestRefundParams params) async {
    if (params.transactionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Transaction ID cannot be empty'),
      );
    }
    if (params.amount <= 0) {
      return FailureResult(
        Failure.validation(message: 'Refund amount must be greater than 0'),
      );
    }

    return _repository.requestRefund(
      transactionId: params.transactionId,
      amount: params.amount,
      reason: params.reason,
    );
  }
}

// ─── Get Transactions ────────────────────────────────────────────────────────

class GetTransactionsParams {
  const GetTransactionsParams({
    this.userId,
    this.schoolId,
    this.status,
    required this.page,
    required this.perPage,
  });

  final String? userId;
  final String? schoolId;
  final TransactionStatus? status;
  final int page;
  final int perPage;
}

class GetTransactionsUseCase {
  GetTransactionsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaginatedResult<TransactionEntity>>> call(
    GetTransactionsParams params,
  ) async {
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(message: 'Per page must be at least 1'),
      );
    }

    return _repository.getTransactions(
      userId: params.userId,
      schoolId: params.schoolId,
      status: params.status,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
