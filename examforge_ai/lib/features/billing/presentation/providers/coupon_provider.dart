import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_coupons_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// COUPON STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the coupon feature.
///
/// Tracks the validated coupon, available coupons, and
/// loading/error/success states for coupon operations.
class CouponState {
  const CouponState({
    this.isLoading = false,
    this.validatedCoupon,
    this.coupons = const [],
    this.error,
    this.successMessage,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The currently validated coupon, or `null`.
  final CouponEntity? validatedCoupon;

  /// The list of available coupons.
  final List<CouponEntity> coupons;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether a coupon has been validated.
  bool get hasValidatedCoupon => validatedCoupon != null;

  /// Creates a copy of this state with the given fields replaced.
  CouponState copyWith({
    bool? isLoading,
    CouponEntity? validatedCoupon,
    List<CouponEntity>? coupons,
    String? error,
    String? successMessage,
  }) {
    return CouponState(
      isLoading: isLoading ?? this.isLoading,
      validatedCoupon: validatedCoupon ?? this.validatedCoupon,
      coupons: coupons ?? this.coupons,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  CouponState clearError() => copyWith(error: null);

  /// Clears the current success message.
  CouponState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// COUPON NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the coupon feature's state.
///
/// Supports validating, redeeming, loading, creating, and updating
/// coupons.
class CouponNotifier extends StateNotifier<CouponState> {
  CouponNotifier({
    required ValidateCouponUseCase validateCouponUseCase,
    required RedeemCouponUseCase redeemCouponUseCase,
    required GetCouponsUseCase getCouponsUseCase,
    required CreateCouponUseCase createCouponUseCase,
    required UpdateCouponUseCase updateCouponUseCase,
  })  : _validateCouponUseCase = validateCouponUseCase,
        _redeemCouponUseCase = redeemCouponUseCase,
        _getCouponsUseCase = getCouponsUseCase,
        _createCouponUseCase = createCouponUseCase,
        _updateCouponUseCase = updateCouponUseCase,
        super(const CouponState());

  final ValidateCouponUseCase _validateCouponUseCase;
  final RedeemCouponUseCase _redeemCouponUseCase;
  final GetCouponsUseCase _getCouponsUseCase;
  final CreateCouponUseCase _createCouponUseCase;
  final UpdateCouponUseCase _updateCouponUseCase;

  // ─── Validate Coupon ───────────────────────────────────────────────

  /// Validates a coupon code.
  Future<void> validateCoupon({
    required String code,
    required BillingModel billingModel,
    String? planId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _validateCouponUseCase(
      ValidateCouponParams(
        code: code,
        billingModel: billingModel,
        planId: planId,
      ),
    );

    result.fold(
      onSuccess: (coupon) {
        state = state.copyWith(
          isLoading: false,
          validatedCoupon: coupon,
          successMessage: 'Coupon validated successfully',
          error: null,
        );
        AppLogger.info('Coupon validated: ${coupon.code}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to validate coupon: $failure');
      },
    );
  }

  // ─── Redeem Coupon ─────────────────────────────────────────────────

  /// Redeems a coupon for the given user.
  Future<void> redeemCoupon({
    required String couponId,
    required String userId,
    String? schoolId,
    String? subscriptionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _redeemCouponUseCase(
      RedeemCouponParams(
        couponId: couponId,
        userId: userId,
        schoolId: schoolId,
        subscriptionId: subscriptionId,
      ),
    );

    result.fold(
      onSuccess: (coupon) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Coupon redeemed successfully',
          error: null,
        );
        AppLogger.info('Coupon redeemed: $couponId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to redeem coupon: $failure');
      },
    );
  }

  // ─── Load Coupons ──────────────────────────────────────────────────

  /// Loads available coupons.
  Future<void> loadCoupons({
    required bool activeOnly,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCouponsUseCase(
      GetCouponsParams(
        activeOnly: activeOnly,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          coupons: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} coupons',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load coupons: $failure');
      },
    );
  }

  // ─── Create Coupon ─────────────────────────────────────────────────

  /// Creates a new coupon.
  Future<void> createCoupon({required CouponEntity coupon}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createCouponUseCase(
      CreateCouponParams(coupon: coupon),
    );

    result.fold(
      onSuccess: (createdCoupon) {
        final updatedList = [createdCoupon, ...state.coupons];
        state = state.copyWith(
          isLoading: false,
          coupons: updatedList,
          successMessage: 'Coupon created successfully',
          error: null,
        );
        AppLogger.info('Coupon created: ${createdCoupon.code}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create coupon: $failure');
      },
    );
  }

  // ─── Update Coupon ─────────────────────────────────────────────────

  /// Updates an existing coupon.
  Future<void> updateCoupon({required CouponEntity coupon}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateCouponUseCase(
      UpdateCouponParams(coupon: coupon),
    );

    result.fold(
      onSuccess: (updatedCoupon) {
        final updatedList = state.coupons
            .map((c) => c.id == updatedCoupon.id ? updatedCoupon : c)
            .toList();
        state = state.copyWith(
          isLoading: false,
          coupons: updatedList,
          validatedCoupon: state.validatedCoupon?.id == updatedCoupon.id
              ? updatedCoupon
              : state.validatedCoupon,
          successMessage: 'Coupon updated successfully',
          error: null,
        );
        AppLogger.info('Coupon updated: ${updatedCoupon.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update coupon: $failure');
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
// COUPON PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the coupon feature.
///
/// The factory accepts all required use cases via named parameters.
final couponProvider =
    StateNotifierProvider<CouponNotifier, CouponState>(
  (ref) => CouponNotifier(
    validateCouponUseCase: ref.watch(validateCouponUseCaseProvider),
    redeemCouponUseCase: ref.watch(redeemCouponUseCaseProvider),
    getCouponsUseCase: ref.watch(getCouponsUseCaseProvider),
    createCouponUseCase: ref.watch(createCouponUseCaseProvider),
    updateCouponUseCase: ref.watch(updateCouponUseCaseProvider),
  ),
);
