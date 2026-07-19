import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/create_review_usecase.dart';
import '../../domain/usecases/get_product_reviews_usecase.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../domain/usecases/get_quality_check_usecase.dart';
import '../../domain/usecases/get_related_products_usecase.dart';
import '../../domain/usecases/increment_product_view_usecase.dart';
import '../../domain/usecases/toggle_wishlist_usecase.dart';
import '../../domain/usecases/verify_purchase_usecase.dart';
import '../../domain/usecases/vote_review_helpful_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRODUCT DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the product detail page.
///
/// Tracks the current product, reviews, quality check, related products,
/// wishlist status, purchase status, and loading/error states.
class ProductDetailState {
  const ProductDetailState({
    this.isLoading = false,
    this.error,
    this.product,
    this.reviews = const [],
    this.qualityCheck,
    this.relatedProducts = const [],
    this.isInWishlist = false,
    this.hasPurchased = false,
    this.currentVersion,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently viewed product.
  final MarketplaceProductEntity? product;

  /// Reviews for the current product.
  final List<MarketplaceReviewEntity> reviews;

  /// The quality check result for the current product.
  final QualityCheckEntity? qualityCheck;

  /// Related products for cross-selling.
  final List<MarketplaceProductEntity> relatedProducts;

  /// Whether the product is in the user's wishlist.
  final bool isInWishlist;

  /// Whether the user has purchased this product.
  final bool hasPurchased;

  /// The current version details of the product.
  final ProductVersionEntity? currentVersion;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether a product is currently loaded.
  bool get hasProduct => product != null;

  /// Whether the product has reviews.
  bool get hasReviews => reviews.isNotEmpty;

  /// Whether the product has a quality check result.
  bool get hasQualityCheck => qualityCheck != null;

  /// Creates a copy of this state with the given fields replaced.
  ProductDetailState copyWith({
    bool? isLoading,
    String? error,
    MarketplaceProductEntity? product,
    List<MarketplaceReviewEntity>? reviews,
    QualityCheckEntity? qualityCheck,
    List<MarketplaceProductEntity>? relatedProducts,
    bool? isInWishlist,
    bool? hasPurchased,
    ProductVersionEntity? currentVersion,
  }) {
    return ProductDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      product: product ?? this.product,
      reviews: reviews ?? this.reviews,
      qualityCheck: qualityCheck ?? this.qualityCheck,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      isInWishlist: isInWishlist ?? this.isInWishlist,
      hasPurchased: hasPurchased ?? this.hasPurchased,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }

  /// Clears the current error message.
  ProductDetailState clearError() => copyWith(error: null);

  /// Clears the current success message (no-op, included for consistency).
  ProductDetailState clearSuccess() => copyWith();
}

// ═══════════════════════════════════════════════════════════════════════
// PRODUCT DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the product detail page state.
///
/// Supports loading product details, reviews, quality checks, related
/// products, wishlist toggling, view recording, and review management.
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier({
    required GetProductUseCase getProductUseCase,
    required GetProductReviewsUseCase getProductReviewsUseCase,
    required GetQualityCheckUseCase getQualityCheckUseCase,
    required GetRelatedProductsUseCase getRelatedProductsUseCase,
    required ToggleWishlistUseCase toggleWishlistUseCase,
    required IncrementProductViewUseCase incrementProductViewUseCase,
    required CreateReviewUseCase createReviewUseCase,
    required VoteReviewHelpfulUseCase voteReviewHelpfulUseCase,
    required VerifyPurchaseUseCase verifyPurchaseUseCase,
  })  : _getProductUseCase = getProductUseCase,
        _getProductReviewsUseCase = getProductReviewsUseCase,
        _getQualityCheckUseCase = getQualityCheckUseCase,
        _getRelatedProductsUseCase = getRelatedProductsUseCase,
        _toggleWishlistUseCase = toggleWishlistUseCase,
        _incrementProductViewUseCase = incrementProductViewUseCase,
        _createReviewUseCase = createReviewUseCase,
        _voteReviewHelpfulUseCase = voteReviewHelpfulUseCase,
        _verifyPurchaseUseCase = verifyPurchaseUseCase,
        super(const ProductDetailState());

  final GetProductUseCase _getProductUseCase;
  final GetProductReviewsUseCase _getProductReviewsUseCase;
  final GetQualityCheckUseCase _getQualityCheckUseCase;
  final GetRelatedProductsUseCase _getRelatedProductsUseCase;
  final ToggleWishlistUseCase _toggleWishlistUseCase;
  final IncrementProductViewUseCase _incrementProductViewUseCase;
  final CreateReviewUseCase _createReviewUseCase;
  final VoteReviewHelpfulUseCase _voteReviewHelpfulUseCase;
  final VerifyPurchaseUseCase _verifyPurchaseUseCase;

  // ─── Load Product ───────────────────────────────────────────────────

  /// Loads a product by ID or slug.
  Future<void> loadProduct({String? productId, String? slug}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getProductUseCase(
      GetProductParams(productId: productId, slug: slug),
    );

    result.fold(
      onSuccess: (product) {
        state = state.copyWith(
          isLoading: false,
          product: product,
        );
        AppLogger.info('Loaded product: ${product.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load product: $failure');
      },
    );
  }

  // ─── Load Reviews ───────────────────────────────────────────────────

  /// Loads reviews for the current product.
  Future<void> loadReviews({
    required String productId,
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _getProductReviewsUseCase(
      GetProductReviewsParams(
        productId: productId,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      onSuccess: (reviews) {
        state = state.copyWith(reviews: reviews);
        AppLogger.info('Loaded ${reviews.length} reviews');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load reviews: $failure');
      },
    );
  }

  // ─── Load Quality Check ─────────────────────────────────────────────

  /// Loads the quality check result for the current product.
  Future<void> loadQualityCheck({required String productId}) async {
    final result = await _getQualityCheckUseCase(
      GetQualityCheckParams(productId: productId),
    );

    result.fold(
      onSuccess: (qualityCheck) {
        state = state.copyWith(qualityCheck: qualityCheck);
        AppLogger.info('Loaded quality check for product: $productId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load quality check: $failure');
      },
    );
  }

  // ─── Load Related Products ──────────────────────────────────────────

  /// Loads related products for cross-selling.
  Future<void> loadRelatedProducts({
    required String productId,
    int limit = 10,
  }) async {
    final result = await _getRelatedProductsUseCase(
      GetRelatedProductsParams(productId: productId, limit: limit),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(relatedProducts: products);
        AppLogger.info('Loaded ${products.length} related products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load related products: $failure');
      },
    );
  }

  // ─── Toggle Wishlist ────────────────────────────────────────────────

  /// Toggles the product in the user's wishlist.
  Future<void> toggleWishlist({
    required String userId,
    required String productId,
  }) async {
    final result = await _toggleWishlistUseCase(
      ToggleWishlistParams(userId: userId, productId: productId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(isInWishlist: !state.isInWishlist);
        AppLogger.info(
          'Toggled wishlist for product: $productId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to toggle wishlist: $failure');
      },
    );
  }

  // ─── Record View ────────────────────────────────────────────────────

  /// Records a view for the current product.
  Future<void> recordView({required String productId}) async {
    final result = await _incrementProductViewUseCase(
      IncrementProductViewParams(productId: productId),
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Recorded view for product: $productId');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to record view: $failure');
      },
    );
  }

  // ─── Create Review ──────────────────────────────────────────────────

  /// Submits a new review for the current product.
  Future<void> createReview({
    required MarketplaceReviewEntity review,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createReviewUseCase(
      CreateReviewParams(review: review),
    );

    result.fold(
      onSuccess: (createdReview) {
        state = state.copyWith(
          isLoading: false,
          reviews: [createdReview, ...state.reviews],
        );
        AppLogger.info('Review created: ${createdReview.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create review: $failure');
      },
    );
  }

  // ─── Vote Review Helpful ────────────────────────────────────────────

  /// Votes a review as helpful.
  Future<void> voteReviewHelpful({
    required String reviewId,
    required String userId,
  }) async {
    final result = await _voteReviewHelpfulUseCase(
      VoteReviewHelpfulParams(reviewId: reviewId, userId: userId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          reviews: state.reviews
              .map((r) => r.id == reviewId
                  ? r.copyWith(helpfulCount: r.helpfulCount + 1)
                  : r)
              .toList(),
        );
        AppLogger.info('Voted review helpful: $reviewId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to vote review helpful: $failure');
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
// PRODUCT DETAIL PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the product detail feature.
///
/// The factory accepts all required use cases via named parameters.
final productDetailProvider =
    StateNotifierProvider<ProductDetailNotifier, ProductDetailState>(
  (ref) => ProductDetailNotifier(
    getProductUseCase: ref.watch(getProductUseCaseProvider),
    getProductReviewsUseCase: ref.watch(getProductReviewsUseCaseProvider),
    getQualityCheckUseCase: ref.watch(getQualityCheckUseCaseProvider),
    getRelatedProductsUseCase: ref.watch(getRelatedProductsUseCaseProvider),
    toggleWishlistUseCase: ref.watch(toggleWishlistUseCaseProvider),
    incrementProductViewUseCase:
        ref.watch(incrementProductViewUseCaseProvider),
    createReviewUseCase: ref.watch(createReviewUseCaseProvider),
    voteReviewHelpfulUseCase: ref.watch(voteReviewHelpfulUseCaseProvider),
    verifyPurchaseUseCase: ref.watch(verifyPurchaseUseCaseProvider),
  ),
);
