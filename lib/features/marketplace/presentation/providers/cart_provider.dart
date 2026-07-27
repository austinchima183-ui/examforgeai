import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_item_usecase.dart';
import '../../domain/usecases/validate_promo_code_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CART STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the shopping cart feature.
///
/// Tracks cart contents, promo code, discount, and loading/error states.
class CartState {
  const CartState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.cart,
    this.promoCode,
    this.promoDiscount = 0,
    this.isApplyingPromo = false,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The current shopping cart.
  final CartEntity? cart;

  /// The currently applied promo code.
  final PromoCodeEntity? promoCode;

  /// The discount amount from the applied promo code.
  final double promoDiscount;

  /// Whether a promo code is being validated.
  final bool isApplyingPromo;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// The subtotal before discount.
  double get subtotal => cart?.totalPrice ?? 0;

  /// The discount amount from promo code.
  double get discount => promoDiscount;

  /// The total after discount.
  double get total => subtotal - discount;

  /// Whether the cart has items.
  bool get hasItems => cart != null && cart!.items.isNotEmpty;

  /// The number of items in the cart.
  int get itemCount => cart?.totalItems ?? 0;

  /// Whether a promo code is applied.
  bool get hasPromoCode => promoCode != null;

  /// Creates a copy of this state with the given fields replaced.
  CartState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    CartEntity? cart,
    PromoCodeEntity? promoCode,
    double? promoDiscount,
    bool? isApplyingPromo,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      cart: cart ?? this.cart,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      isApplyingPromo: isApplyingPromo ?? this.isApplyingPromo,
    );
  }

  /// Clears the current error message.
  CartState clearError() => copyWith(error: null);

  /// Clears the current success message.
  CartState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CART NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the shopping cart state.
///
/// Supports loading the cart, adding/updating/removing items, clearing
/// the cart, and validating/applying promo codes.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier({
    required GetCartUseCase getCartUseCase,
    required AddToCartUseCase addToCartUseCase,
    required UpdateCartItemUseCase updateCartItemUseCase,
    required RemoveFromCartUseCase removeFromCartUseCase,
    required ClearCartUseCase clearCartUseCase,
    required ValidatePromoCodeUseCase validatePromoCodeUseCase,
  })  : _getCartUseCase = getCartUseCase,
        _addToCartUseCase = addToCartUseCase,
        _updateCartItemUseCase = updateCartItemUseCase,
        _removeFromCartUseCase = removeFromCartUseCase,
        _clearCartUseCase = clearCartUseCase,
        _validatePromoCodeUseCase = validatePromoCodeUseCase,
        super(const CartState());

  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateCartItemUseCase _updateCartItemUseCase;
  final RemoveFromCartUseCase _removeFromCartUseCase;
  final ClearCartUseCase _clearCartUseCase;
  final ValidatePromoCodeUseCase _validatePromoCodeUseCase;

  // ─── Load Cart ──────────────────────────────────────────────────────

  /// Loads the current user's shopping cart.
  Future<void> loadCart({required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCartUseCase(
      GetCartParams(userId: userId),
    );

    result.fold(
      onSuccess: (cart) {
        state = state.copyWith(isLoading: false, cart: cart);
        AppLogger.info('Loaded cart with ${cart.items.length} items');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load cart: $failure');
      },
    );
  }

  // ─── Add to Cart ────────────────────────────────────────────────────

  /// Adds an item to the shopping cart.
  Future<void> addToCart({
    required String userId,
    required CartItemEntity item,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _addToCartUseCase(
      AddToCartParams(userId: userId, item: item),
    );

    result.fold(
      onSuccess: (cart) {
        state = state.copyWith(
          isLoading: false,
          cart: cart,
          successMessage: 'Item added to cart',
        );
        AppLogger.info('Item added to cart');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to add item to cart: $failure');
      },
    );
  }

  // ─── Update Cart Item ───────────────────────────────────────────────

  /// Updates a cart item (e.g., change quantity or license type).
  Future<void> updateCartItem({required CartItemEntity item}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateCartItemUseCase(
      UpdateCartItemParams(item: item),
    );

    result.fold(
      onSuccess: (updatedItem) {
        final updatedCart = state.cart?.copyWith(
          items: state.cart!.items
              .map((i) => i.id == updatedItem.id ? updatedItem : i)
              .toList(),
        );
        state = state.copyWith(
          isLoading: false,
          cart: updatedCart,
          successMessage: 'Cart item updated',
        );
        AppLogger.info('Cart item updated: ${updatedItem.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update cart item: $failure');
      },
    );
  }

  // ─── Remove from Cart ───────────────────────────────────────────────

  /// Removes an item from the shopping cart.
  Future<void> removeFromCart({required String cartItemId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _removeFromCartUseCase(
      RemoveFromCartParams(cartItemId: cartItemId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedCart = state.cart?.copyWith(
          items:
              state.cart!.items.where((i) => i.id != cartItemId).toList(),
        );
        state = state.copyWith(
          isLoading: false,
          cart: updatedCart,
          successMessage: 'Item removed from cart',
        );
        AppLogger.info('Item removed from cart: $cartItemId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to remove item from cart: $failure');
      },
    );
  }

  // ─── Clear Cart ─────────────────────────────────────────────────────

  /// Clears all items from the shopping cart.
  Future<void> clearCart({required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _clearCartUseCase(
      ClearCartParams(userId: userId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          promoCode: null,
          promoDiscount: 0,
          successMessage: 'Cart cleared',
        );
        AppLogger.info('Cart cleared');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to clear cart: $failure');
      },
    );
  }

  // ─── Apply Promo Code ───────────────────────────────────────────────

  /// Validates and applies a promo code to the cart.
  Future<void> applyPromoCode({
    required String code,
    double? orderAmount,
    List<MarketplaceProductType>? productTypes,
  }) async {
    state = state.copyWith(isApplyingPromo: true, error: null);

    final result = await _validatePromoCodeUseCase(
      ValidatePromoCodeParams(
        code: code,
        orderAmount: orderAmount ?? state.subtotal,
        productTypes: productTypes,
      ),
    );

    result.fold(
      onSuccess: (promoCode) {
        final discountAmount = _calculateDiscount(promoCode);
        state = state.copyWith(
          isApplyingPromo: false,
          promoCode: promoCode,
          promoDiscount: discountAmount,
          successMessage: 'Promo code applied',
        );
        AppLogger.info('Promo code applied: ${promoCode.code}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isApplyingPromo: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to apply promo code: $failure');
      },
    );
  }

  // ─── Remove Promo Code ──────────────────────────────────────────────

  /// Removes the currently applied promo code.
  void removePromoCode() {
    state = state.copyWith(
      promoCode: null,
      promoDiscount: 0,
      successMessage: 'Promo code removed',
    );
    AppLogger.info('Promo code removed');
  }

  // ─── Clear Error ────────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success ──────────────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccess() {
    state = state.clearSuccess();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Calculates the discount amount from a promo code.
  double _calculateDiscount(PromoCodeEntity promoCode) {
    if (promoCode.discountType == DiscountType.percentage) {
      final discount = state.subtotal * (promoCode.discountValue / 100);
      return promoCode.maxDiscountAmount > 0
          ? discount.clamp(0, promoCode.maxDiscountAmount)
          : discount;
    } else {
      return promoCode.discountValue.clamp(0, state.subtotal);
    }
  }

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
// CART PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the shopping cart feature.
///
/// The factory accepts all required use cases via named parameters.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(
    getCartUseCase: ref.watch(getCartUseCaseProvider),
    addToCartUseCase: ref.watch(addToCartUseCaseProvider),
    updateCartItemUseCase: ref.watch(updateCartItemUseCaseProvider),
    removeFromCartUseCase: ref.watch(removeFromCartUseCaseProvider),
    clearCartUseCase: ref.watch(clearCartUseCaseProvider),
    validatePromoCodeUseCase: ref.watch(validatePromoCodeUseCaseProvider),
  ),
);
