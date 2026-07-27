import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/get_user_orders_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/usecases/verify_payment_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// ORDER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the order management feature.
///
/// Tracks order list, current order, payment processing, and loading/error states.
class OrderState {
  const OrderState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.orders = const [],
    this.currentOrder,
    this.isProcessingPayment = false,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The list of user orders.
  final List<MarketplaceOrderEntity> orders;

  /// The currently viewed order.
  final MarketplaceOrderEntity? currentOrder;

  /// Whether a payment is being processed.
  final bool isProcessingPayment;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether the user has any orders.
  bool get hasOrders => orders.isNotEmpty;

  /// Whether a current order is loaded.
  bool get hasCurrentOrder => currentOrder != null;

  /// Creates a copy of this state with the given fields replaced.
  OrderState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<MarketplaceOrderEntity>? orders,
    MarketplaceOrderEntity? currentOrder,
    bool? isProcessingPayment,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
    );
  }

  /// Clears the current error message.
  OrderState clearError() => copyWith(error: null);

  /// Clears the current success message.
  OrderState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ORDER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the order management state.
///
/// Supports creating orders, loading order lists and details,
/// verifying payments, and updating order status.
class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier({
    required CreateOrderUseCase createOrderUseCase,
    required GetUserOrdersUseCase getUserOrdersUseCase,
    required GetOrderUseCase getOrderUseCase,
    required VerifyPaymentUseCase verifyPaymentUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
  })  : _createOrderUseCase = createOrderUseCase,
        _getUserOrdersUseCase = getUserOrdersUseCase,
        _getOrderUseCase = getOrderUseCase,
        _verifyPaymentUseCase = verifyPaymentUseCase,
        _updateOrderStatusUseCase = updateOrderStatusUseCase,
        super(const OrderState());

  final CreateOrderUseCase _createOrderUseCase;
  final GetUserOrdersUseCase _getUserOrdersUseCase;
  final GetOrderUseCase _getOrderUseCase;
  final VerifyPaymentUseCase _verifyPaymentUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  // ─── Create Order ───────────────────────────────────────────────────

  /// Creates a new order from the current cart.
  Future<void> createOrder({
    required MarketplaceOrderEntity order,
  }) async {
    state = state.copyWith(isProcessingPayment: true, error: null);

    final result = await _createOrderUseCase(
      CreateOrderParams(order: order),
    );

    result.fold(
      onSuccess: (createdOrder) {
        state = state.copyWith(
          isProcessingPayment: false,
          currentOrder: createdOrder,
          orders: [createdOrder, ...state.orders],
          successMessage: 'Order created successfully',
        );
        AppLogger.info('Order created: ${createdOrder.orderNumber}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isProcessingPayment: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create order: $failure');
      },
    );
  }

  // ─── Load Orders ────────────────────────────────────────────────────

  /// Loads the list of orders for the given buyer.
  Future<void> loadOrders({
    required String buyerId,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUserOrdersUseCase(
      GetUserOrdersParams(buyerId: buyerId, limit: limit, offset: offset),
    );

    result.fold(
      onSuccess: (orders) {
        state = state.copyWith(isLoading: false, orders: orders);
        AppLogger.info('Loaded ${orders.length} orders');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load orders: $failure');
      },
    );
  }

  // ─── Load Order ─────────────────────────────────────────────────────

  /// Loads a single order by ID or order number.
  Future<void> loadOrder({String? orderId, String? orderNumber}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getOrderUseCase(
      GetOrderParams(orderId: orderId, orderNumber: orderNumber),
    );

    result.fold(
      onSuccess: (order) {
        state = state.copyWith(isLoading: false, currentOrder: order);
        AppLogger.info('Loaded order: ${order.orderNumber}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load order: $failure');
      },
    );
  }

  // ─── Verify Payment ─────────────────────────────────────────────────

  /// Verifies a payment transaction reference.
  Future<void> verifyPayment({required String txRef}) async {
    state = state.copyWith(isProcessingPayment: true, error: null);

    final result = await _verifyPaymentUseCase(
      VerifyPaymentParams(txRef: txRef),
    );

    result.fold(
      onSuccess: (order) {
        state = state.copyWith(
          isProcessingPayment: false,
          currentOrder: order,
          orders: state.orders
              .map((o) => o.id == order.id ? order : o)
              .toList(),
          successMessage: 'Payment verified successfully',
        );
        AppLogger.info('Payment verified for order: ${order.orderNumber}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isProcessingPayment: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to verify payment: $failure');
      },
    );
  }

  // ─── Update Order Status ────────────────────────────────────────────

  /// Updates the status of an order (e.g., refund, cancel).
  Future<void> updateOrderStatus({
    required String orderId,
    required MarketplaceOrderStatus status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateOrderStatusUseCase(
      UpdateOrderStatusParams(orderId: orderId, status: status),
    );

    result.fold(
      onSuccess: (updatedOrder) {
        state = state.copyWith(
          isLoading: false,
          currentOrder: updatedOrder,
          orders: state.orders
              .map((o) => o.id == updatedOrder.id ? updatedOrder : o)
              .toList(),
          successMessage: 'Order status updated',
        );
        AppLogger.info('Order status updated: ${updatedOrder.orderNumber}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update order status: $failure');
      },
    );
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
// ORDER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the order management feature.
///
/// The factory accepts all required use cases via named parameters.
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(
    createOrderUseCase: ref.watch(createOrderUseCaseProvider),
    getUserOrdersUseCase: ref.watch(getUserOrdersUseCaseProvider),
    getOrderUseCase: ref.watch(getOrderUseCaseProvider),
    verifyPaymentUseCase: ref.watch(verifyPaymentUseCaseProvider),
    updateOrderStatusUseCase: ref.watch(updateOrderStatusUseCaseProvider),
  ),
);
