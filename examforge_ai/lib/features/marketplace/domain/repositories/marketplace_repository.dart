import '../../../../core/utils/result.dart';
import '../entities/marketplace_entities.dart';

/// Abstract contract for the marketplace repository.
///
/// All marketplace operations flow through this interface, enabling
/// Clean Architecture separation and testability.
abstract class MarketplaceRepository {
  // ─── Categories ──────────────────────────────────────────────────────

  /// Get all categories, optionally filtered to active only.
  Future<Result<List<MarketplaceCategoryEntity>>> getCategories({
    bool activeOnly = true,
  });

  /// Get a single category by ID.
  Future<Result<MarketplaceCategoryEntity>> getCategory(String categoryId);

  /// Create or update a category.
  Future<Result<MarketplaceCategoryEntity>> upsertCategory(
    MarketplaceCategoryEntity category,
  );

  /// Delete a category by ID.
  Future<Result<bool>> deleteCategory(String categoryId);

  // ─── Seller Profiles ─────────────────────────────────────────────────

  /// Get a seller profile by seller ID.
  Future<Result<SellerProfileEntity>> getSellerProfile(String sellerId);

  /// Get a seller profile by user ID.
  Future<Result<SellerProfileEntity>> getSellerProfileByUserId(String userId);

  /// Create or update a seller profile.
  Future<Result<SellerProfileEntity>> upsertSellerProfile(
    SellerProfileEntity profile,
  );

  /// Update a seller's status (e.g. active, suspended).
  Future<Result<SellerProfileEntity>> updateSellerStatus(
    String sellerId,
    MarketplaceSellerStatus status,
  );

  /// Get sellers with optional filtering and pagination.
  Future<Result<List<SellerProfileEntity>>> getSellers({
    MarketplaceSellerStatus? status,
    int limit = 20,
    int offset = 0,
  });

  // ─── Products ────────────────────────────────────────────────────────

  /// Get products with filtering, searching, and pagination.
  Future<Result<List<MarketplaceProductEntity>>> getProducts({
    MarketplaceProductStatus? status,
    MarketplaceProductType? productType,
    String? categoryId,
    String? sellerId,
    String? subject,
    String? classLevel,
    String? curriculum,
    String? search,
    String? sortBy,
    int limit = 20,
    int offset = 0,
  });

  /// Get a single product by ID.
  Future<Result<MarketplaceProductEntity>> getProduct(String productId);

  /// Get a single product by its URL slug.
  Future<Result<MarketplaceProductEntity>> getProductBySlug(String slug);

  /// Create a new product.
  Future<Result<MarketplaceProductEntity>> createProduct(
    MarketplaceProductEntity product,
  );

  /// Update an existing product.
  Future<Result<MarketplaceProductEntity>> updateProduct(
    MarketplaceProductEntity product,
  );

  /// Delete a product by ID.
  Future<Result<bool>> deleteProduct(String productId);

  /// Update the status of a product (e.g. published, draft, archived).
  Future<Result<MarketplaceProductEntity>> updateProductStatus(
    String productId,
    MarketplaceProductStatus status,
  );

  /// Set or remove the featured flag on a product.
  Future<Result<MarketplaceProductEntity>> featureProduct(
    String productId,
    bool featured,
  );

  /// Increment the view count for a product.
  Future<Result<bool>> incrementProductView(String productId);

  /// Get products belonging to a specific seller.
  Future<Result<List<MarketplaceProductEntity>>> getSellerProducts(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  });

  /// Get featured products.
  Future<Result<List<MarketplaceProductEntity>>> getFeaturedProducts({
    int limit = 10,
  });

  /// Get products related to a given product.
  Future<Result<List<MarketplaceProductEntity>>> getRelatedProducts(
    String productId, {
    int limit = 10,
  });

  // ─── Product Versions ────────────────────────────────────────────────

  /// Get all versions for a product.
  Future<Result<List<ProductVersionEntity>>> getProductVersions(
    String productId,
  );

  /// Create a new product version.
  Future<Result<ProductVersionEntity>> createProductVersion(
    ProductVersionEntity version,
  );

  // ─── Shopping Cart ───────────────────────────────────────────────────

  /// Get the shopping cart for a user.
  Future<Result<CartEntity>> getCart(String userId);

  /// Add an item to the user's cart.
  Future<Result<CartEntity>> addToCart(
    String userId,
    CartItemEntity item,
  );

  /// Update a cart item (e.g. change quantity).
  Future<Result<CartItemEntity>> updateCartItem(CartItemEntity item);

  /// Remove an item from the cart.
  Future<Result<bool>> removeFromCart(String cartItemId);

  /// Clear all items from the user's cart.
  Future<Result<bool>> clearCart(String userId);

  // ─── Orders ──────────────────────────────────────────────────────────

  /// Create a new order.
  Future<Result<MarketplaceOrderEntity>> createOrder(
    MarketplaceOrderEntity order,
  );

  /// Get an order by ID.
  Future<Result<MarketplaceOrderEntity>> getOrder(String orderId);

  /// Get an order by its order number.
  Future<Result<MarketplaceOrderEntity>> getOrderByNumber(String orderNumber);

  /// Get orders for a buyer with pagination.
  Future<Result<List<MarketplaceOrderEntity>>> getUserOrders(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  });

  /// Update the status of an order.
  Future<Result<MarketplaceOrderEntity>> updateOrderStatus(
    String orderId,
    MarketplaceOrderStatus status,
  );

  /// Verify a payment by transaction reference.
  Future<Result<MarketplaceOrderEntity>> verifyPayment(String txRef);

  // ─── Purchases ───────────────────────────────────────────────────────

  /// Get purchases for a buyer with pagination.
  Future<Result<List<MarketplacePurchaseEntity>>> getUserPurchases(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  });

  /// Get a single purchase by ID.
  Future<Result<MarketplacePurchaseEntity>> getPurchase(String purchaseId);

  /// Verify that a buyer has purchased a specific product.
  Future<Result<bool>> verifyPurchase(
    String buyerId,
    String productId,
  );

  /// Record a download event for a purchase.
  Future<Result<bool>> recordDownload(String purchaseId);

  // ─── Reviews & Ratings ───────────────────────────────────────────────

  /// Get reviews for a product with pagination.
  Future<Result<List<MarketplaceReviewEntity>>> getProductReviews(
    String productId, {
    int limit = 20,
    int offset = 0,
  });

  /// Create a new review.
  Future<Result<MarketplaceReviewEntity>> createReview(
    MarketplaceReviewEntity review,
  );

  /// Update an existing review.
  Future<Result<MarketplaceReviewEntity>> updateReview(
    MarketplaceReviewEntity review,
  );

  /// Delete a review by ID.
  Future<Result<bool>> deleteReview(String reviewId);

  /// Respond to a review as the seller.
  Future<Result<MarketplaceReviewEntity>> respondToReview(
    String reviewId,
    String response,
  );

  /// Vote a review as helpful.
  Future<Result<bool>> voteReviewHelpful(
    String reviewId,
    String userId,
  );

  /// Report a review for inappropriate content.
  Future<Result<bool>> reportReview(
    String reviewId,
    String reason,
  );

  // ─── Wishlist ────────────────────────────────────────────────────────

  /// Get the wishlist for a user.
  Future<Result<List<WishlistEntity>>> getUserWishlist(String userId);

  /// Add a product to the user's wishlist.
  Future<Result<WishlistEntity>> addToWishlist(
    String userId,
    String productId,
  );

  /// Remove an item from the wishlist.
  Future<Result<bool>> removeFromWishlist(String wishlistId);

  /// Check if a product is in the user's wishlist.
  Future<Result<bool>> isInWishlist(
    String userId,
    String productId,
  );

  // ─── Promo Codes ─────────────────────────────────────────────────────

  /// Validate a promo code and return it if valid.
  Future<Result<PromoCodeEntity>> validatePromoCode(
    String code, {
    double? orderAmount,
    List<MarketplaceProductType>? productTypes,
  });

  /// Apply / increment usage of a promo code.
  Future<Result<bool>> applyPromoCode(String promoCodeId);

  /// Get promo codes, optionally filtered to active only.
  Future<Result<List<PromoCodeEntity>>> getPromoCodes({
    bool activeOnly = true,
  });

  /// Create a new promo code.
  Future<Result<PromoCodeEntity>> createPromoCode(PromoCodeEntity promoCode);

  /// Update an existing promo code.
  Future<Result<PromoCodeEntity>> updatePromoCode(PromoCodeEntity promoCode);

  // ─── Commissions ─────────────────────────────────────────────────────

  /// Get commission rates with optional filtering.
  Future<Result<List<CommissionRateEntity>>> getCommissionRates({
    MarketplaceProductType? productType,
    MarketplaceLicenseType? licenseType,
  });

  /// Create or update a commission rate.
  Future<Result<CommissionRateEntity>> upsertCommissionRate(
    CommissionRateEntity rate,
  );

  /// Get commission records for a seller with pagination.
  Future<Result<List<CommissionRecordEntity>>> getCommissionRecords(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  });

  // ─── Analytics ───────────────────────────────────────────────────────

  /// Get analytics for a seller within an optional date range.
  Future<Result<SellerAnalyticsEntity>> getSellerAnalytics(
    String sellerId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get analytics for a product within an optional date range.
  Future<Result<ProductAnalyticsEntity>> getProductAnalytics(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Record a search event for analytics.
  Future<Result<bool>> recordSearchEvent(
    MarketplaceSearchLogEntity searchLog,
  );

  /// Record an AI recommendation event for analytics.
  Future<Result<bool>> recordAIRecommendation(
    AIRecommendationEntity recommendation,
  );

  // ─── Quality Checks ──────────────────────────────────────────────────

  /// Run a quality check on a product.
  Future<Result<QualityCheckEntity>> runQualityCheck(String productId);

  /// Get the latest quality check for a product.
  Future<Result<QualityCheckEntity>> getQualityCheck(String productId);

  /// Get the full quality check history for a product.
  Future<Result<List<QualityCheckEntity>>> getProductQualityHistory(
    String productId,
  );

  // ─── Disputes ────────────────────────────────────────────────────────

  /// Create a new dispute.
  Future<Result<DisputeEntity>> createDispute(DisputeEntity dispute);

  /// Get a single dispute by ID.
  Future<Result<DisputeEntity>> getDispute(String disputeId);

  /// Get disputes with optional filtering.
  Future<Result<List<DisputeEntity>>> getDisputes({
    String? orderId,
    String? buyerId,
    String? sellerId,
    DisputeStatus? status,
  });

  /// Resolve a dispute.
  Future<Result<DisputeEntity>> resolveDispute(
    String disputeId,
    String resolution,
    String resolvedBy,
  );

  // ─── Notifications ───────────────────────────────────────────────────

  /// Get notifications for a user with optional filtering.
  Future<Result<List<MarketplaceNotificationEntity>>> getUserNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 20,
  });

  /// Mark a single notification as read.
  Future<Result<bool>> markNotificationRead(String notificationId);

  /// Mark all notifications as read for a user.
  Future<Result<bool>> markAllNotificationsRead(String userId);

  /// Create a new notification.
  Future<Result<MarketplaceNotificationEntity>> createNotification(
    MarketplaceNotificationEntity notification,
  );

  // ─── Saved Searches ──────────────────────────────────────────────────

  /// Get saved searches for a user.
  Future<Result<List<SavedSearchEntity>>> getSavedSearches(String userId);

  /// Create a new saved search.
  Future<Result<SavedSearchEntity>> createSavedSearch(
    SavedSearchEntity savedSearch,
  );

  /// Delete a saved search by ID.
  Future<Result<bool>> deleteSavedSearch(String savedSearchId);

  // ─── AI Recommendations ──────────────────────────────────────────────

  /// Get personalized product recommendations for a user.
  Future<Result<List<MarketplaceProductEntity>>> getRecommendations(
    String userId, {
    int limit = 10,
  });

  /// Get trending products across the marketplace.
  Future<Result<List<MarketplaceProductEntity>>> getTrendingProducts({
    int limit = 10,
  });

  // ─── Marketplace Moderation ──────────────────────────────────────────

  /// Get products pending moderation review.
  Future<Result<List<MarketplaceProductEntity>>> getPendingProducts({
    int limit = 20,
    int offset = 0,
  });

  /// Approve a product after moderation.
  Future<Result<MarketplaceProductEntity>> approveProduct(
    String productId,
    String moderatorId,
  );

  /// Reject a product after moderation.
  Future<Result<MarketplaceProductEntity>> rejectProduct(
    String productId,
    String reason,
    String moderatorId,
  );

  /// Moderate a review by updating its status.
  Future<Result<MarketplaceReviewEntity>> moderateReview(
    String reviewId,
    MarketplaceReviewStatus status,
  );

  /// Suspend a seller account.
  Future<Result<SellerProfileEntity>> suspendSeller(
    String sellerId,
    String reason,
  );
}
