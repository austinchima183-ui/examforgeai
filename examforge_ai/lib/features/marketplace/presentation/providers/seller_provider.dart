import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/get_commission_records_usecase.dart';
import '../../domain/usecases/get_seller_analytics_usecase.dart';
import '../../domain/usecases/get_seller_products_usecase.dart';
import '../../domain/usecases/get_seller_profile_usecase.dart';
import '../../domain/usecases/update_product_status_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/upsert_seller_profile_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// SELLER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the seller dashboard feature.
///
/// Tracks seller profile, products, analytics, revenue, and loading/error states.
class SellerState {
  const SellerState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.sellerProfile,
    this.products = const [],
    this.analytics = const [],
    this.totalRevenue = 0,
    this.totalSales = 0,
    this.averageRating = 0,
    this.totalProducts = 0,
    this.commissionRecords = const [],
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The seller's profile information.
  final SellerProfileEntity? sellerProfile;

  /// The seller's published products.
  final List<MarketplaceProductEntity> products;

  /// Analytics data for the seller.
  final List<SellerAnalyticsEntity> analytics;

  /// Total revenue across all products.
  final double totalRevenue;

  /// Total sales count across all products.
  final int totalSales;

  /// Average rating across all products.
  final double averageRating;

  /// Total number of products.
  final int totalProducts;

  /// Commission records for the seller.
  final List<CommissionRecordEntity> commissionRecords;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether the seller profile is loaded and active.
  bool get hasActiveProfile =>
      sellerProfile != null && sellerProfile!.isActive;

  /// Whether the seller has any products.
  bool get hasProducts => products.isNotEmpty;

  /// Creates a copy of this state with the given fields replaced.
  SellerState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    SellerProfileEntity? sellerProfile,
    List<MarketplaceProductEntity>? products,
    List<SellerAnalyticsEntity>? analytics,
    double? totalRevenue,
    int? totalSales,
    double? averageRating,
    int? totalProducts,
    List<CommissionRecordEntity>? commissionRecords,
  }) {
    return SellerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      sellerProfile: sellerProfile ?? this.sellerProfile,
      products: products ?? this.products,
      analytics: analytics ?? this.analytics,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalSales: totalSales ?? this.totalSales,
      averageRating: averageRating ?? this.averageRating,
      totalProducts: totalProducts ?? this.totalProducts,
      commissionRecords: commissionRecords ?? this.commissionRecords,
    );
  }

  /// Clears the current error message.
  SellerState clearError() => copyWith(error: null);

  /// Clears the current success message.
  SellerState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SELLER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the seller dashboard state.
///
/// Supports loading profile, products, analytics, and performing
/// CRUD operations on products and the seller profile.
class SellerNotifier extends StateNotifier<SellerState> {
  SellerNotifier({
    required GetSellerProfileUseCase getSellerProfileUseCase,
    required GetSellerProductsUseCase getSellerProductsUseCase,
    required GetSellerAnalyticsUseCase getSellerAnalyticsUseCase,
    required CreateProductUseCase createProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required DeleteProductUseCase deleteProductUseCase,
    required UpdateProductStatusUseCase updateProductStatusUseCase,
    required UpsertSellerProfileUseCase upsertSellerProfileUseCase,
    required GetCommissionRecordsUseCase getCommissionRecordsUseCase,
  })  : _getSellerProfileUseCase = getSellerProfileUseCase,
        _getSellerProductsUseCase = getSellerProductsUseCase,
        _getSellerAnalyticsUseCase = getSellerAnalyticsUseCase,
        _createProductUseCase = createProductUseCase,
        _updateProductUseCase = updateProductUseCase,
        _deleteProductUseCase = deleteProductUseCase,
        _updateProductStatusUseCase = updateProductStatusUseCase,
        _upsertSellerProfileUseCase = upsertSellerProfileUseCase,
        _getCommissionRecordsUseCase = getCommissionRecordsUseCase,
        super(const SellerState());

  final GetSellerProfileUseCase _getSellerProfileUseCase;
  final GetSellerProductsUseCase _getSellerProductsUseCase;
  final GetSellerAnalyticsUseCase _getSellerAnalyticsUseCase;
  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final UpdateProductStatusUseCase _updateProductStatusUseCase;
  final UpsertSellerProfileUseCase _upsertSellerProfileUseCase;
  final GetCommissionRecordsUseCase _getCommissionRecordsUseCase;

  // ─── Load Seller Profile ────────────────────────────────────────────

  /// Loads the seller profile for the given seller or user ID.
  Future<void> loadSellerProfile({
    String? sellerId,
    String? userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSellerProfileUseCase(
      GetSellerProfileParams(sellerId: sellerId, userId: userId),
    );

    result.fold(
      onSuccess: (profile) {
        state = state.copyWith(
          isLoading: false,
          sellerProfile: profile,
          totalRevenue: profile.totalRevenue,
          totalSales: profile.totalSales,
          averageRating: profile.averageRating,
          totalProducts: profile.totalProducts,
        );
        AppLogger.info('Loaded seller profile: ${profile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load seller profile: $failure');
      },
    );
  }

  // ─── Load Seller Products ───────────────────────────────────────────

  /// Loads the seller's products.
  Future<void> loadSellerProducts({
    required String sellerId,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSellerProductsUseCase(
      GetSellerProductsParams(sellerId: sellerId, limit: limit, offset: offset),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          products: products,
          totalProducts: products.length,
        );
        AppLogger.info('Loaded ${products.length} seller products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load seller products: $failure');
      },
    );
  }

  // ─── Load Seller Analytics ──────────────────────────────────────────

  /// Loads analytics data for the seller.
  Future<void> loadSellerAnalytics({
    required String sellerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSellerAnalyticsUseCase(
      GetSellerAnalyticsParams(
        sellerId: sellerId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    result.fold(
      onSuccess: (analytics) {
        state = state.copyWith(
          isLoading: false,
          analytics: [analytics],
        );
        AppLogger.info('Loaded seller analytics');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load seller analytics: $failure');
      },
    );
  }

  // ─── Create Product ─────────────────────────────────────────────────

  /// Creates a new product listing.
  Future<void> createProduct({
    required MarketplaceProductEntity product,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createProductUseCase(
      CreateProductParams(product: product),
    );

    result.fold(
      onSuccess: (createdProduct) {
        state = state.copyWith(
          isLoading: false,
          products: [createdProduct, ...state.products],
          totalProducts: state.totalProducts + 1,
          successMessage: 'Product created successfully',
        );
        AppLogger.info('Product created: ${createdProduct.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create product: $failure');
      },
    );
  }

  // ─── Update Product ─────────────────────────────────────────────────

  /// Updates an existing product listing.
  Future<void> updateProduct({
    required MarketplaceProductEntity product,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateProductUseCase(
      UpdateProductParams(product: product),
    );

    result.fold(
      onSuccess: (updatedProduct) {
        state = state.copyWith(
          isLoading: false,
          products: state.products
              .map((p) => p.id == updatedProduct.id ? updatedProduct : p)
              .toList(),
          successMessage: 'Product updated successfully',
        );
        AppLogger.info('Product updated: ${updatedProduct.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update product: $failure');
      },
    );
  }

  // ─── Delete Product ─────────────────────────────────────────────────

  /// Deletes a product listing.
  Future<void> deleteProduct({required String productId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteProductUseCase(
      DeleteProductParams(productId: productId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          products: state.products.where((p) => p.id != productId).toList(),
          totalProducts: state.totalProducts - 1,
          successMessage: 'Product deleted successfully',
        );
        AppLogger.info('Product deleted: $productId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete product: $failure');
      },
    );
  }

  // ─── Update Product Status ──────────────────────────────────────────

  /// Updates the status of a product (e.g., publish, unpublish).
  Future<void> updateProductStatus({
    required String productId,
    required MarketplaceProductStatus status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateProductStatusUseCase(
      UpdateProductStatusParams(productId: productId, status: status),
    );

    result.fold(
      onSuccess: (updatedProduct) {
        state = state.copyWith(
          isLoading: false,
          products: state.products
              .map((p) => p.id == updatedProduct.id ? updatedProduct : p)
              .toList(),
          successMessage: 'Product status updated successfully',
        );
        AppLogger.info('Product status updated: ${updatedProduct.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update product status: $failure');
      },
    );
  }

  // ─── Upsert Seller Profile ──────────────────────────────────────────

  /// Creates or updates the seller profile.
  Future<void> upsertSellerProfile({
    required SellerProfileEntity profile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _upsertSellerProfileUseCase(
      UpsertSellerProfileParams(profile: profile),
    );

    result.fold(
      onSuccess: (updatedProfile) {
        state = state.copyWith(
          isLoading: false,
          sellerProfile: updatedProfile,
          successMessage: 'Seller profile updated successfully',
        );
        AppLogger.info('Seller profile upserted: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upsert seller profile: $failure');
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
// SELLER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the seller dashboard feature.
///
/// The factory accepts all required use cases via named parameters.
final sellerProvider = StateNotifierProvider<SellerNotifier, SellerState>(
  (ref) => SellerNotifier(
    getSellerProfileUseCase: ref.watch(getSellerProfileUseCaseProvider),
    getSellerProductsUseCase: ref.watch(getSellerProductsUseCaseProvider),
    getSellerAnalyticsUseCase: ref.watch(getSellerAnalyticsUseCaseProvider),
    createProductUseCase: ref.watch(createProductUseCaseProvider),
    updateProductUseCase: ref.watch(updateProductUseCaseProvider),
    deleteProductUseCase: ref.watch(deleteProductUseCaseProvider),
    updateProductStatusUseCase: ref.watch(updateProductStatusUseCaseProvider),
    upsertSellerProfileUseCase: ref.watch(upsertSellerProfileUseCaseProvider),
    getCommissionRecordsUseCase:
        ref.watch(getCommissionRecordsUseCaseProvider),
  ),
);
