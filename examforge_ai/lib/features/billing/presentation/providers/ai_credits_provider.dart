import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_ai_credits_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI CREDITS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI credits feature.
///
/// Tracks the credit balance, credit transaction history, available
/// credit packs, and loading/error states.
class AiCreditsState {
  const AiCreditsState({
    this.isLoading = false,
    this.creditBalance,
    this.creditTransactions = const [],
    this.creditPacks = const [],
    this.error,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The current AI credit balance, or `null`.
  final AiCreditBalanceEntity? creditBalance;

  /// The list of credit transactions.
  final List<AiCreditTransactionEntity> creditTransactions;

  /// The list of available credit packs.
  final List<AiCreditPackEntity> creditPacks;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the credit balance is available.
  bool get hasCreditBalance => creditBalance != null;

  /// The remaining credits, or `0` if no balance is loaded.
  int get remainingCredits => creditBalance?.remainingCredits ?? 0;

  /// Whether credits are running low (below 20%).
  bool get isLowOnCredits => creditBalance?.isLow ?? false;

  /// Whether credits are exhausted.
  bool get isExhausted => creditBalance?.isExhausted ?? true;

  /// Creates a copy of this state with the given fields replaced.
  AiCreditsState copyWith({
    bool? isLoading,
    AiCreditBalanceEntity? creditBalance,
    List<AiCreditTransactionEntity>? creditTransactions,
    List<AiCreditPackEntity>? creditPacks,
    String? error,
  }) {
    return AiCreditsState(
      isLoading: isLoading ?? this.isLoading,
      creditBalance: creditBalance ?? this.creditBalance,
      creditTransactions: creditTransactions ?? this.creditTransactions,
      creditPacks: creditPacks ?? this.creditPacks,
      error: error,
    );
  }

  /// Clears the current error message.
  AiCreditsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI CREDITS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI credits feature's state.
///
/// Supports loading credit balance, transaction history, consuming
/// credits, purchasing credits, and loading available credit packs.
class AiCreditsNotifier extends StateNotifier<AiCreditsState> {
  AiCreditsNotifier({
    required GetCreditBalanceUseCase getCreditBalanceUseCase,
    required GetCreditTransactionsUseCase getCreditTransactionsUseCase,
    required ConsumeCreditsUseCase consumeCreditsUseCase,
    required PurchaseCreditsUseCase purchaseCreditsUseCase,
    required GetCreditPacksUseCase getCreditPacksUseCase,
  })  : _getCreditBalanceUseCase = getCreditBalanceUseCase,
        _getCreditTransactionsUseCase = getCreditTransactionsUseCase,
        _consumeCreditsUseCase = consumeCreditsUseCase,
        _purchaseCreditsUseCase = purchaseCreditsUseCase,
        _getCreditPacksUseCase = getCreditPacksUseCase,
        super(const AiCreditsState());

  final GetCreditBalanceUseCase _getCreditBalanceUseCase;
  final GetCreditTransactionsUseCase _getCreditTransactionsUseCase;
  final ConsumeCreditsUseCase _consumeCreditsUseCase;
  final PurchaseCreditsUseCase _purchaseCreditsUseCase;
  final GetCreditPacksUseCase _getCreditPacksUseCase;

  // ─── Load Credit Balance ───────────────────────────────────────────

  /// Loads the AI credit balance for the given owner.
  Future<void> loadCreditBalance({
    required String ownerId,
    required BillingModel ownerType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCreditBalanceUseCase(
      GetCreditBalanceParams(
        ownerId: ownerId,
        ownerType: ownerType,
      ),
    );

    result.fold(
      onSuccess: (balance) {
        state = state.copyWith(
          isLoading: false,
          creditBalance: balance,
          error: null,
        );
        AppLogger.info(
          'Loaded credit balance: ${balance.remainingCredits} remaining',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load credit balance: $failure');
      },
    );
  }

  // ─── Load Credit Transactions ──────────────────────────────────────

  /// Loads the credit transaction history.
  Future<void> loadCreditTransactions({
    required String ownerId,
    required BillingModel ownerType,
    CreditTransactionType? type,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCreditTransactionsUseCase(
      GetCreditTransactionsParams(
        ownerId: ownerId,
        ownerType: ownerType,
        type: type,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          creditTransactions: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} credit transactions',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load credit transactions: $failure',
        );
      },
    );
  }

  // ─── Consume Credits ───────────────────────────────────────────────

  /// Consumes AI credits for a feature usage.
  Future<void> consumeCredits({
    required String ownerId,
    required BillingModel ownerType,
    required int credits,
    required String featureName,
    String? referenceId,
    required double estimatedCostUsd,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _consumeCreditsUseCase(
      ConsumeCreditsParams(
        ownerId: ownerId,
        ownerType: ownerType,
        credits: credits,
        featureName: featureName,
        referenceId: referenceId,
        estimatedCostUsd: estimatedCostUsd,
      ),
    );

    result.fold(
      onSuccess: (transaction) {
        // Update the credit balance locally if available.
        final updatedBalance = state.creditBalance?.copyWith(
          usedCredits: state.creditBalance!.usedCredits + credits,
          remainingCredits:
              state.creditBalance!.remainingCredits - credits,
        );
        state = state.copyWith(
          isLoading: false,
          creditBalance: updatedBalance,
          error: null,
        );
        AppLogger.info('Consumed $credits credits for $featureName');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to consume credits: $failure');
      },
    );
  }

  // ─── Purchase Credits ──────────────────────────────────────────────

  /// Purchases a credit pack.
  Future<void> purchaseCredits({
    required String ownerId,
    required BillingModel ownerType,
    required String creditPackId,
    String? couponCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _purchaseCreditsUseCase(
      PurchaseCreditsParams(
        ownerId: ownerId,
        ownerType: ownerType,
        creditPackId: creditPackId,
        couponCode: couponCode,
      ),
    );

    result.fold(
      onSuccess: (transaction) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        AppLogger.info(
          'Purchased credit pack: $creditPackId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to purchase credits: $failure');
      },
    );
  }

  // ─── Load Credit Packs ─────────────────────────────────────────────

  /// Loads available credit packs.
  Future<void> loadCreditPacks({BillingModel? billingModel}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCreditPacksUseCase(
      GetCreditPacksParams(billingModel: billingModel),
    );

    result.fold(
      onSuccess: (packs) {
        state = state.copyWith(
          isLoading: false,
          creditPacks: packs,
          error: null,
        );
        AppLogger.info('Loaded ${packs.length} credit packs');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load credit packs: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// AI CREDITS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the AI credits feature.
///
/// The factory accepts all required use cases via named parameters.
final aiCreditsProvider =
    StateNotifierProvider<AiCreditsNotifier, AiCreditsState>(
  (ref) => AiCreditsNotifier(
    getCreditBalanceUseCase: ref.watch(getCreditBalanceUseCaseProvider),
    getCreditTransactionsUseCase:
        ref.watch(getCreditTransactionsUseCaseProvider),
    consumeCreditsUseCase: ref.watch(consumeCreditsUseCaseProvider),
    purchaseCreditsUseCase: ref.watch(purchaseCreditsUseCaseProvider),
    getCreditPacksUseCase: ref.watch(getCreditPacksUseCaseProvider),
  ),
);
