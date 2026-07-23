import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/get_user_purchases_usecase.dart';
import '../../domain/usecases/record_download_usecase.dart';
import '../../domain/usecases/verify_purchase_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PURCHASE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the purchase/access management feature.
///
/// Tracks user purchases, current purchase details, and loading/error states.
class PurchaseState {
  const PurchaseState({
    this.isLoading = false,
    this.error,
    this.purchases = const [],
    this.currentPurchase,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The list of user purchases.
  final List<MarketplacePurchaseEntity> purchases;

  /// The currently viewed purchase.
  final MarketplacePurchaseEntity? currentPurchase;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether the user has any purchases.
  bool get hasPurchases => purchases.isNotEmpty;

  /// Whether a current purchase is loaded.
  bool get hasCurrentPurchase => currentPurchase != null;

  /// The number of active (accessible) purchases.
  int get activePurchaseCount =>
      purchases.where((p) => p.isAccessible).length;

  /// Creates a copy of this state with the given fields replaced.
  PurchaseState copyWith({
    bool? isLoading,
    String? error,
    List<MarketplacePurchaseEntity>? purchases,
    MarketplacePurchaseEntity? currentPurchase,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      purchases: purchases ?? this.purchases,
      currentPurchase: currentPurchase ?? this.currentPurchase,
    );
  }

  /// Clears the current error message.
  PurchaseState clearError() => copyWith(error: null);

  /// Clears the current success message (no-op, included for consistency).
  PurchaseState clearSuccess() => copyWith();
}

// ═══════════════════════════════════════════════════════════════════════
// PURCHASE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the purchase/access state.
///
/// Supports loading purchases, verifying purchase access, and
/// recording downloads.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  PurchaseNotifier({
    required GetUserPurchasesUseCase getUserPurchasesUseCase,
    required VerifyPurchaseUseCase verifyPurchaseUseCase,
    required RecordDownloadUseCase recordDownloadUseCase,
  })  : _getUserPurchasesUseCase = getUserPurchasesUseCase,
        _verifyPurchaseUseCase = verifyPurchaseUseCase,
        _recordDownloadUseCase = recordDownloadUseCase,
        super(const PurchaseState());

  final GetUserPurchasesUseCase _getUserPurchasesUseCase;
  final VerifyPurchaseUseCase _verifyPurchaseUseCase;
  final RecordDownloadUseCase _recordDownloadUseCase;

  // ─── Load Purchases ─────────────────────────────────────────────────

  /// Loads the list of purchases for the given buyer.
  Future<void> loadPurchases({
    required String buyerId,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUserPurchasesUseCase(
      GetUserPurchasesParams(buyerId: buyerId, limit: limit, offset: offset),
    );

    result.fold(
      onSuccess: (purchases) {
        state = state.copyWith(isLoading: false, purchases: purchases);
        AppLogger.info('Loaded ${purchases.length} purchases');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load purchases: $failure');
      },
    );
  }

  // ─── Verify Purchase ────────────────────────────────────────────────

  /// Verifies whether a buyer has purchased a specific product.
  Future<bool> verifyPurchase({
    required String buyerId,
    required String productId,
  }) async {
    final result = await _verifyPurchaseUseCase(
      VerifyPurchaseParams(buyerId: buyerId, productId: productId),
    );

    return result.fold(
      onSuccess: (hasPurchased) {
        AppLogger.info(
          'Purchase verification for $productId: $hasPurchased',
        );
        return hasPurchased;
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to verify purchase: $failure');
        return false;
      },
    );
  }

  // ─── Record Download ────────────────────────────────────────────────

  /// Records a download event for a purchase.
  Future<void> recordDownload({required String purchaseId}) async {
    final result = await _recordDownloadUseCase(
      RecordDownloadParams(purchaseId: purchaseId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          purchases: state.purchases
              .map((p) => p.id == purchaseId
                  ? p.copyWith(
                      downloadCount: p.downloadCount + 1,
                      lastDownloadedAt: DateTime.now(),
                    )
                  : p,)
              .toList(),
        );
        AppLogger.info('Download recorded for purchase: $purchaseId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to record download: $failure');
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────────

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
// PURCHASE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the purchase/access management feature.
///
/// The factory accepts all required use cases via named parameters.
final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) => PurchaseNotifier(
    getUserPurchasesUseCase: ref.watch(getUserPurchasesUseCaseProvider),
    verifyPurchaseUseCase: ref.watch(verifyPurchaseUseCaseProvider),
    recordDownloadUseCase: ref.watch(recordDownloadUseCaseProvider),
  ),
);
