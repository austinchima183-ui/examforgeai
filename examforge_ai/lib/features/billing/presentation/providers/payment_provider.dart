import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/process_payment_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PAYMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the payment feature.
///
/// Tracks the checkout URL, current transaction, transaction history,
/// and loading/error states for payment operations.
class PaymentState {
  const PaymentState({
    this.isLoading = false,
    this.checkoutUrl,
    this.currentTransaction,
    this.transactions = const [],
    this.error,
    this.successMessage,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The checkout URL from payment initialization, or `null`.
  final String? checkoutUrl;

  /// The current transaction being processed, or `null`.
  final TransactionEntity? currentTransaction;

  /// The list of payment transactions.
  final List<TransactionEntity> transactions;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether a checkout URL is available.
  bool get hasCheckoutUrl => checkoutUrl != null;

  /// Creates a copy of this state with the given fields replaced.
  PaymentState copyWith({
    bool? isLoading,
    String? checkoutUrl,
    TransactionEntity? currentTransaction,
    List<TransactionEntity>? transactions,
    String? error,
    String? successMessage,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      currentTransaction: currentTransaction ?? this.currentTransaction,
      transactions: transactions ?? this.transactions,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  PaymentState clearError() => copyWith(error: null);

  /// Clears the current success message.
  PaymentState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PAYMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the payment feature's state.
///
/// Supports initializing payments, verifying payments, loading
/// transaction history, and requesting refunds.
class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier({
    required InitializePaymentUseCase initializePaymentUseCase,
    required VerifyPaymentUseCase verifyPaymentUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
    required RequestRefundUseCase requestRefundUseCase,
  })  : _initializePaymentUseCase = initializePaymentUseCase,
        _verifyPaymentUseCase = verifyPaymentUseCase,
        _getTransactionsUseCase = getTransactionsUseCase,
        _requestRefundUseCase = requestRefundUseCase,
        super(const PaymentState());

  final InitializePaymentUseCase _initializePaymentUseCase;
  final VerifyPaymentUseCase _verifyPaymentUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;
  final RequestRefundUseCase _requestRefundUseCase;

  // ─── Initialize Payment ────────────────────────────────────────────

  /// Initializes a payment and returns a checkout URL.
  Future<void> initializePayment({
    required double amount,
    required String currency,
    required String email,
    required String txRef,
    String? subscriptionId,
    String? planId,
    String? couponCode,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _initializePaymentUseCase(
      InitializePaymentParams(
        amount: amount,
        currency: currency,
        email: email,
        txRef: txRef,
        subscriptionId: subscriptionId,
        planId: planId,
        couponCode: couponCode,
        metadata: metadata,
      ),
    );

    result.fold(
      onSuccess: (paymentInit) {
        state = state.copyWith(
          isLoading: false,
          checkoutUrl: paymentInit.checkoutUrl,
          successMessage: 'Payment initialized successfully',
          error: null,
        );
        AppLogger.info('Payment initialized: $txRef');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to initialize payment: $failure');
      },
    );
  }

  // ─── Verify Payment ────────────────────────────────────────────────

  /// Verifies a payment using the transaction reference.
  Future<void> verifyPayment({required String txRef}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _verifyPaymentUseCase(
      VerifyPaymentParams(txRef: txRef),
    );

    result.fold(
      onSuccess: (verification) {
        state = state.copyWith(
          isLoading: false,
          currentTransaction: verification.transaction,
          successMessage: verification.status == 'successful'
              ? 'Payment verified successfully'
              : 'Payment verification returned: ${verification.status}',
          error: null,
        );
        AppLogger.info('Payment verified: $txRef');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to verify payment: $failure');
      },
    );
  }

  // ─── Load Transactions ─────────────────────────────────────────────

  /// Loads the transaction history.
  Future<void> loadTransactions({
    String? userId,
    String? schoolId,
    TransactionStatus? status,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTransactionsUseCase(
      GetTransactionsParams(
        userId: userId,
        schoolId: schoolId,
        status: status,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          transactions: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} transactions',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load transactions: $failure');
      },
    );
  }

  // ─── Request Refund ────────────────────────────────────────────────

  /// Requests a refund for a transaction.
  Future<void> requestRefund({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _requestRefundUseCase(
      RequestRefundParams(
        transactionId: transactionId,
        amount: amount,
        reason: reason,
      ),
    );

    result.fold(
      onSuccess: (refund) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Refund requested successfully',
          error: null,
        );
        AppLogger.info('Refund requested for transaction: $transactionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to request refund: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PAYMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the payment feature.
///
/// The factory accepts all required use cases via named parameters.
final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(
    initializePaymentUseCase: ref.watch(initializePaymentUseCaseProvider),
    verifyPaymentUseCase: ref.watch(verifyPaymentUseCaseProvider),
    getTransactionsUseCase: ref.watch(getTransactionsUseCaseProvider),
    requestRefundUseCase: ref.watch(requestRefundUseCaseProvider),
  ),
);
