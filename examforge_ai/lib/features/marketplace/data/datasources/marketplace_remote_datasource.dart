import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';
import '../models/marketplace_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote marketplace data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class MarketplaceRemoteDataSource {
  // ─── Categories ────────────────────────────────────────────────────

  Future<List<MarketplaceCategoryModel>> getCategories({
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<MarketplaceCategoryModel> getCategory(String categoryId);
  Future<MarketplaceCategoryModel> upsertCategory(
    MarketplaceCategoryModel category,
  );
  Future<bool> deleteCategory(String categoryId);

  // ─── Seller Profiles ──────────────────────────────────────────────

  Future<SellerProfileModel> getSellerProfile(String sellerId);
  Future<SellerProfileModel> getSellerProfileByUserId(String userId);
  Future<SellerProfileModel> upsertSellerProfile(
    SellerProfileModel profile,
  );
  Future<SellerProfileModel> updateSellerStatus(
    String sellerId,
    String status,
  );
  Future<List<SellerProfileModel>> getSellers({
    String? status,
    int limit = 20,
    int offset = 0,
  });

  // ─── Products ─────────────────────────────────────────────────────

  Future<List<MarketplaceProductModel>> getProducts({
    String? status,
    String? productType,
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
  Future<MarketplaceProductModel> getProduct(String productId);
  Future<MarketplaceProductModel> getProductBySlug(String slug);
  Future<MarketplaceProductModel> createProduct(
    MarketplaceProductModel product,
  );
  Future<MarketplaceProductModel> updateProduct(
    MarketplaceProductModel product,
  );
  Future<bool> deleteProduct(String productId);
  Future<MarketplaceProductModel> updateProductStatus(
    String productId,
    String status,
  );
  Future<MarketplaceProductModel> featureProduct(
    String productId,
    bool featured,
  );
  Future<bool> incrementProductView(String productId);
  Future<List<MarketplaceProductModel>> getSellerProducts(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  });
  Future<List<MarketplaceProductModel>> getFeaturedProducts({
    int limit = 10,
  });
  Future<List<MarketplaceProductModel>> getRelatedProducts(
    String productId, {
    int limit = 10,
  });

  // ─── Product Versions ─────────────────────────────────────────────

  Future<List<ProductVersionModel>> getProductVersions(
    String productId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<ProductVersionModel> createProductVersion(
    ProductVersionModel version,
  );

  // ─── Shopping Cart ────────────────────────────────────────────────

  Future<CartModel> getCart(String userId);
  Future<CartItemModel> addToCart(String userId, CartItemModel item);
  Future<CartItemModel> updateCartItem(CartItemModel item);
  Future<bool> removeFromCart(String cartItemId);
  Future<bool> clearCart(String userId);

  // ─── Orders ───────────────────────────────────────────────────────

  Future<MarketplaceOrderModel> createOrder(MarketplaceOrderModel order);
  Future<MarketplaceOrderModel> getOrder(String orderId);
  Future<MarketplaceOrderModel> getOrderByNumber(String orderNumber);
  Future<List<MarketplaceOrderModel>> getUserOrders(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  });
  Future<MarketplaceOrderModel> updateOrderStatus(
    String orderId,
    String status,
  );
  Future<MarketplaceOrderModel> verifyPayment(String txRef);

  // ─── Purchases ────────────────────────────────────────────────────

  Future<List<MarketplacePurchaseModel>> getUserPurchases(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  });
  Future<MarketplacePurchaseModel> getPurchase(String purchaseId);
  Future<bool> verifyPurchase(String buyerId, String productId);
  Future<MarketplacePurchaseModel> recordDownload(String purchaseId);

  // ─── Reviews & Ratings ────────────────────────────────────────────

  Future<List<MarketplaceReviewModel>> getProductReviews(
    String productId, {
    int limit = 20,
    int offset = 0,
  });
  Future<MarketplaceReviewModel> createReview(MarketplaceReviewModel review);
  Future<MarketplaceReviewModel> updateReview(MarketplaceReviewModel review);
  Future<bool> deleteReview(String reviewId);
  Future<MarketplaceReviewModel> respondToReview(
    String reviewId,
    String response,
  );
  Future<bool> voteReviewHelpful(String reviewId, String userId);
  Future<bool> reportReview(String reviewId, String reason);

  // ─── Wishlist ─────────────────────────────────────────────────────

  Future<List<WishlistModel>> getUserWishlist(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<WishlistModel> addToWishlist(String userId, String productId);
  Future<bool> removeFromWishlist(String wishlistId);
  Future<bool> isInWishlist(String userId, String productId);

  // ─── Promo Codes ──────────────────────────────────────────────────

  Future<PromoCodeModel> validatePromoCode(
    String code, {
    double? orderAmount,
    List<String>? productTypes,
  });
  Future<bool> applyPromoCode(String promoCodeId);
  Future<List<PromoCodeModel>> getPromoCodes({
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<PromoCodeModel> createPromoCode(PromoCodeModel promoCode);
  Future<PromoCodeModel> updatePromoCode(PromoCodeModel promoCode);

  // ─── Commissions ──────────────────────────────────────────────────

  Future<List<CommissionRateModel>> getCommissionRates({
    String? productType,
    String? licenseType,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<CommissionRateModel> upsertCommissionRate(
    CommissionRateModel rate,
  );
  Future<List<CommissionRecordModel>> getCommissionRecords(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  });

  // ─── Analytics ────────────────────────────────────────────────────

  Future<List<SellerAnalyticsModel>> getSellerAnalytics(
    String sellerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<List<ProductAnalyticsModel>> getProductAnalytics(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<bool> recordSearchEvent(MarketplaceSearchLogModel searchLog);
  Future<bool> recordAIRecommendation(AIRecommendationModel recommendation);

  // ─── Quality Checks ───────────────────────────────────────────────

  Future<QualityCheckModel> runQualityCheck(String productId);
  Future<QualityCheckModel> getQualityCheck(String productId);
  Future<List<QualityCheckModel>> getProductQualityHistory(
    String productId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Disputes ─────────────────────────────────────────────────────

  Future<DisputeModel> createDispute(DisputeModel dispute);
  Future<DisputeModel> getDispute(String disputeId);
  Future<List<DisputeModel>> getDisputes({
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? status,
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<DisputeModel> resolveDispute(
    String disputeId,
    String resolution,
    String resolvedBy,
  );

  // ─── Notifications ────────────────────────────────────────────────

  Future<List<MarketplaceNotificationModel>> getUserNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 20,
  });
  Future<bool> markNotificationRead(String notificationId);
  Future<bool> markAllNotificationsRead(String userId);
  Future<MarketplaceNotificationModel> createNotification(
    MarketplaceNotificationModel notification,
  );

  // ─── Saved Searches ───────────────────────────────────────────────

  Future<List<SavedSearchModel>> getSavedSearches(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<SavedSearchModel> createSavedSearch(SavedSearchModel savedSearch);
  Future<bool> deleteSavedSearch(String savedSearchId);

  // ─── AI Recommendations ───────────────────────────────────────────

  Future<List<MarketplaceProductModel>> getRecommendations(
    String userId, {
    int limit = 10,
  });
  Future<List<MarketplaceProductModel>> getTrendingProducts({int limit = 10});

  // ─── Marketplace Moderation ───────────────────────────────────────

  Future<List<MarketplaceProductModel>> getPendingProducts({
    int limit = 20,
    int offset = 0,
  });
  Future<MarketplaceProductModel> approveProduct(
    String productId,
    String moderatorId,
  );
  Future<MarketplaceProductModel> rejectProduct(
    String productId,
    String reason,
    String moderatorId,
  );
  Future<MarketplaceReviewModel> moderateReview(
    String reviewId,
    String status,
  );
  Future<SellerProfileModel> suspendSeller(
    String sellerId,
    String reason,
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Supabase-backed implementation of [MarketplaceRemoteDataSource].
///
/// Every method maps Supabase-specific responses and errors into the
/// domain-agnostic types defined in the data layer. Supabase
/// [sb.PostgrestException] instances are converted to our custom
/// exceptions with user-friendly messages.
class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  MarketplaceRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ──────────────────────────────────────────────────
  static const _categoriesTable = 'marketplace_categories';
  static const _sellerProfilesTable = 'seller_profiles';
  static const _productsTable = 'marketplace_products';
  static const _productVersionsTable = 'product_versions';
  static const _cartItemsTable = 'cart_items';
  static const _cartsTable = 'shopping_carts';
  static const _ordersTable = 'marketplace_orders';
  static const _orderItemsTable = 'order_items';
  static const _purchasesTable = 'marketplace_purchases';
  static const _reviewsTable = 'marketplace_reviews';
  static const _reviewHelpfulTable = 'review_helpful_votes';
  static const _reviewReportsTable = 'review_reports';
  static const _wishlistTable = 'marketplace_wishlist';
  static const _promoCodesTable = 'promo_codes';
  static const _commissionRatesTable = 'commission_rates';
  static const _commissionRecordsTable = 'commission_records';
  static const _sellerAnalyticsTable = 'seller_analytics';
  static const _productAnalyticsTable = 'product_analytics';
  static const _searchLogsTable = 'marketplace_search_logs';
  static const _aiRecommendationsTable = 'ai_recommendations';
  static const _qualityChecksTable = 'quality_checks';
  static const _disputesTable = 'marketplace_disputes';
  static const _notificationsTable = 'marketplace_notifications';
  static const _savedSearchesTable = 'saved_searches';

  // ═══════════════════════════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceCategoryModel>> getCategories({
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase.from(_categoriesTable).select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // PERF: Added limit to prevent unbounded query on marketplace_categories
      final response = await query.order('sort_order', ascending: true).limit(limit);

      AppLogger.info('Fetched ${response.length} marketplace categories');
      return response
          .map<MarketplaceCategoryModel>(
            (row) => MarketplaceCategoryModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCategories error', error: e);
      throw const ServerException(
        message: 'Failed to fetch marketplace categories.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceCategoryModel> getCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from(_categoriesTable)
          .select()
          .eq('id', categoryId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Category not found.');
      }

      return MarketplaceCategoryModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getCategory error', error: e);
      throw const ServerException(
        message: 'Failed to fetch category.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceCategoryModel> upsertCategory(
    MarketplaceCategoryModel category,
  ) async {
    try {
      final data = category.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_categoriesTable)
          .upsert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Category upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Category upserted: ${response.first['id']}');
      return MarketplaceCategoryModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertCategory error', error: e);
      throw const ServerException(
        message: 'Failed to upsert category.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabase
          .from(_categoriesTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId);

      AppLogger.info('Category soft-deleted: $categoryId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteCategory error', error: e);
      throw const ServerException(
        message: 'Failed to delete category.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SELLER PROFILES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SellerProfileModel> getSellerProfile(String sellerId) async {
    try {
      final response = await _supabase
          .from(_sellerProfilesTable)
          .select()
          .eq('id', sellerId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Seller profile not found.');
      }

      return SellerProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSellerProfile error', error: e);
      throw const ServerException(
        message: 'Failed to fetch seller profile.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SellerProfileModel> getSellerProfileByUserId(String userId) async {
    try {
      final response = await _supabase
          .from(_sellerProfilesTable)
          .select()
          .eq('user_id', userId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Seller profile not found for user.');
      }

      return SellerProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getSellerProfileByUserId error', error: e);
      throw const ServerException(
        message: 'Failed to fetch seller profile by user ID.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SellerProfileModel> upsertSellerProfile(
    SellerProfileModel profile,
  ) async {
    try {
      final data = profile.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_sellerProfilesTable)
          .upsert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Seller profile upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Seller profile upserted: ${response.first['id']}');
      return SellerProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertSellerProfile error', error: e);
      throw const ServerException(
        message: 'Failed to upsert seller profile.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SellerProfileModel> updateSellerStatus(
    String sellerId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from(_sellerProfilesTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Seller status update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Seller status updated: $sellerId → $status');
      return SellerProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateSellerStatus error', error: e);
      throw const ServerException(
        message: 'Failed to update seller status.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SellerProfileModel>> getSellers({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_sellerProfilesTable).select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} sellers');
      return response
          .map<SellerProfileModel>(
            (row) => SellerProfileModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSellers error', error: e);
      throw const ServerException(
        message: 'Failed to fetch sellers.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceProductModel>> getProducts({
    String? status,
    String? productType,
    String? categoryId,
    String? sellerId,
    String? subject,
    String? classLevel,
    String? curriculum,
    String? search,
    String? sortBy,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Use RPC for full-text search when a search query is provided
      if (search != null && search.isNotEmpty) {
        final response = await _supabase.rpc(
          'marketplace_search',
          params: {
            'search_query': search,
            'p_status': status,
            'p_product_type': productType,
            'p_category_id': categoryId,
            'p_seller_id': sellerId,
            'p_subject': subject,
            'p_class_level': classLevel,
            'p_curriculum': curriculum,
            'p_sort_by': sortBy ?? 'newest',
            'p_limit': limit,
            'p_offset': offset,
          },
        );

        final list = response as List<dynamic>;
        AppLogger.info('Search returned ${list.length} products');
        return list
            .map<MarketplaceProductModel>(
              (row) => MarketplaceProductModel.fromJson(row as Map<String, dynamic>),
            )
            .toList();
      }

      // Standard query builder when no search
      var filterQuery = _supabase.from(_productsTable).select();

      filterQuery = filterQuery.filter('deleted_at', 'is', null); // exclude soft-deleted

      if (status != null) {
        filterQuery = filterQuery.eq('status', status);
      }
      if (productType != null) {
        filterQuery = filterQuery.eq('product_type', productType);
      }
      if (categoryId != null) {
        filterQuery = filterQuery.eq('category_id', categoryId);
      }
      if (sellerId != null) {
        filterQuery = filterQuery.eq('seller_id', sellerId);
      }
      if (subject != null) {
        filterQuery = filterQuery.eq('subject', subject);
      }
      if (classLevel != null) {
        filterQuery = filterQuery.eq('class_level', classLevel);
      }
      if (curriculum != null) {
        filterQuery = filterQuery.eq('curriculum', curriculum);
      }

      // Apply sort
      var transformQuery = _applySortBy(filterQuery, sortBy);

      final response = await transformQuery.range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} products');
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch products.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> getProduct(String productId) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('id', productId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Product not found.');
      }

      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getProduct error', error: e);
      throw const ServerException(
        message: 'Failed to fetch product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> getProductBySlug(String slug) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('slug', slug)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Product not found by slug.');
      }

      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getProductBySlug error', error: e);
      throw const ServerException(
        message: 'Failed to fetch product by slug.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> createProduct(
    MarketplaceProductModel product,
  ) async {
    try {
      final data = product.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_productsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product created: ${response.first['id']}');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createProduct error', error: e);
      throw const ServerException(
        message: 'Failed to create product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> updateProduct(
    MarketplaceProductModel product,
  ) async {
    try {
      final data = product.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_productsTable)
          .update(data)
          .eq('id', product.id)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product updated: ${product.id}');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateProduct error', error: e);
      throw const ServerException(
        message: 'Failed to update product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deleteProduct(String productId) async {
    try {
      await _supabase
          .from(_productsTable)
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      AppLogger.info('Product soft-deleted: $productId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteProduct error', error: e);
      throw const ServerException(
        message: 'Failed to delete product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> updateProductStatus(
    String productId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product status update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product status updated: $productId → $status');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateProductStatus error', error: e);
      throw const ServerException(
        message: 'Failed to update product status.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> featureProduct(
    String productId,
    bool featured,
  ) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .update({
            'is_featured': featured,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product feature update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product featured: $productId → $featured');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected featureProduct error', error: e);
      throw const ServerException(
        message: 'Failed to update product feature status.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> incrementProductView(String productId) async {
    try {
      await _supabase.rpc(
        'record_product_view',
        params: {'p_product_id': productId},
      );

      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected incrementProductView error', error: e);
      throw const ServerException(
        message: 'Failed to increment product view.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MarketplaceProductModel>> getSellerProducts(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('seller_id', sellerId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info(
        'Fetched ${response.length} products for seller $sellerId',
      );
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSellerProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch seller products.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MarketplaceProductModel>> getFeaturedProducts({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('is_featured', true)
          .eq('status', 'published')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info('Fetched ${response.length} featured products');
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getFeaturedProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch featured products.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MarketplaceProductModel>> getRelatedProducts(
    String productId, {
    int limit = 10,
  }) async {
    try {
      // First, get the product to find its category
      final productResponse = await _supabase
          .from(_productsTable)
          .select('category_id')
          .eq('id', productId)
          .limit(1);

      if (productResponse.isEmpty) {
        return [];
      }

      final categoryId = productResponse.first['category_id'] as String;

      // Then fetch products in the same category, excluding the current one
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('category_id', categoryId)
          .eq('status', 'published')
          .neq('id', productId)
          .filter('deleted_at', 'is', null)
          .order('total_sales', ascending: false)
          .limit(limit);

      AppLogger.info('Fetched ${response.length} related products');
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRelatedProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch related products.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRODUCT VERSIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<ProductVersionModel>> getProductVersions(
    String productId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on product_versions
      final response = await _supabase
          .from(_productVersionsTable)
          .select()
          .eq('product_id', productId)
          .order('version_number', ascending: false)
          .limit(limit);

      AppLogger.info(
        'Fetched ${response.length} versions for product $productId',
      );
      return response
          .map<ProductVersionModel>(
            (row) => ProductVersionModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProductVersions error', error: e);
      throw const ServerException(
        message: 'Failed to fetch product versions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ProductVersionModel> createProductVersion(
    ProductVersionModel version,
  ) async {
    try {
      final data = version.toJson();
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_productVersionsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product version creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product version created: ${response.first['id']}');
      return ProductVersionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createProductVersion error', error: e);
      throw const ServerException(
        message: 'Failed to create product version.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHOPPING CART
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      // Fetch cart items with product details via join
      final response = await _supabase
          .from(_cartItemsTable)
          .select('*, marketplace_products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final cartItems = response
          .map<CartItemModel>((row) => CartItemModel.fromJson(row))
          .toList();

      // Build a CartModel from the cart items
      return CartModel(
        id: userId, // cart identified by userId
        userId: userId,
        items: cartItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCart error', error: e);
      throw const ServerException(
        message: 'Failed to fetch cart.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CartItemModel> addToCart(String userId, CartItemModel item) async {
    try {
      final data = item.toJson();
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_cartItemsTable)
          .upsert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Add to cart returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Item added to cart for user $userId');
      return CartItemModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected addToCart error', error: e);
      throw const ServerException(
        message: 'Failed to add item to cart.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CartItemModel> updateCartItem(CartItemModel item) async {
    try {
      final data = item.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_cartItemsTable)
          .update(data)
          .eq('id', item.id)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Cart item update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Cart item updated: ${item.id}');
      return CartItemModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateCartItem error', error: e);
      throw const ServerException(
        message: 'Failed to update cart item.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _supabase
          .from(_cartItemsTable)
          .delete()
          .eq('id', cartItemId);

      AppLogger.info('Cart item removed: $cartItemId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected removeFromCart error', error: e);
      throw const ServerException(
        message: 'Failed to remove item from cart.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> clearCart(String userId) async {
    try {
      await _supabase
          .from(_cartItemsTable)
          .delete()
          .eq('user_id', userId);

      AppLogger.info('Cart cleared for user $userId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected clearCart error', error: e);
      throw const ServerException(
        message: 'Failed to clear cart.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ORDERS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<MarketplaceOrderModel> createOrder(MarketplaceOrderModel order) async {
    try {
      final orderData = order.toJson();
      orderData['created_at'] = DateTime.now().toIso8601String();
      orderData['updated_at'] = DateTime.now().toIso8601String();

      // Extract order items for nested insert
      final itemsJson = orderData.remove('items') as List<dynamic>? ?? [];

      // Insert the order
      final orderResponse = await _supabase
          .from(_ordersTable)
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // Insert order items with the order reference
      if (itemsJson.isNotEmpty) {
        final orderItems = itemsJson.map((item) {
          final itemMap = Map<String, dynamic>.from(item as Map<String, dynamic>);
          itemMap['order_id'] = orderId;
          itemMap['created_at'] = DateTime.now().toIso8601String();
          return itemMap;
        }).toList();

        await _supabase.from(_orderItemsTable).insert(orderItems);
      }

      AppLogger.info('Order created: $orderId');

      // Fetch the complete order with items
      return getOrder(orderId);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createOrder error', error: e);
      throw const ServerException(
        message: 'Failed to create order.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceOrderModel> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from(_ordersTable)
          .select('*, order_items(*)')
          .eq('id', orderId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Order not found.');
      }

      return MarketplaceOrderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getOrder error', error: e);
      throw const ServerException(
        message: 'Failed to fetch order.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceOrderModel> getOrderByNumber(String orderNumber) async {
    try {
      final response = await _supabase
          .from(_ordersTable)
          .select('*, order_items(*)')
          .eq('order_number', orderNumber)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Order not found by number.');
      }

      return MarketplaceOrderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getOrderByNumber error', error: e);
      throw const ServerException(
        message: 'Failed to fetch order by number.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MarketplaceOrderModel>> getUserOrders(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_ordersTable)
          .select('*, order_items(*)')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} orders for buyer $buyerId');
      return response
          .map<MarketplaceOrderModel>(
            (row) => MarketplaceOrderModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserOrders error', error: e);
      throw const ServerException(
        message: 'Failed to fetch user orders.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceOrderModel> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from(_ordersTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('*, order_items(*)');

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Order status update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Order status updated: $orderId → $status');
      return MarketplaceOrderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateOrderStatus error', error: e);
      throw const ServerException(
        message: 'Failed to update order status.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceOrderModel> verifyPayment(String txRef) async {
    try {
      final result = await _supabase.rpc(
        'verify_marketplace_payment',
        params: {'p_tx_ref': txRef},
      );

      final orderId = result['order_id'] as String?;
      if (orderId == null) {
        throw const ServerException(
          message: 'Payment verification returned no order ID.',
          statusCode: 500,
        );
      }

      return getOrder(orderId);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected verifyPayment error', error: e);
      throw const ServerException(
        message: 'Failed to verify payment.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PURCHASES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplacePurchaseModel>> getUserPurchases(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_purchasesTable)
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info(
        'Fetched ${response.length} purchases for buyer $buyerId',
      );
      return response
          .map<MarketplacePurchaseModel>(
            (row) => MarketplacePurchaseModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserPurchases error', error: e);
      throw const ServerException(
        message: 'Failed to fetch user purchases.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplacePurchaseModel> getPurchase(String purchaseId) async {
    try {
      final response = await _supabase
          .from(_purchasesTable)
          .select()
          .eq('id', purchaseId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Purchase not found.');
      }

      return MarketplacePurchaseModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getPurchase error', error: e);
      throw const ServerException(
        message: 'Failed to fetch purchase.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> verifyPurchase(String buyerId, String productId) async {
    try {
      final response = await _supabase
          .from(_purchasesTable)
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('product_id', productId)
          .limit(1);

      return response.isNotEmpty;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected verifyPurchase error', error: e);
      throw const ServerException(
        message: 'Failed to verify purchase.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplacePurchaseModel> recordDownload(String purchaseId) async {
    try {
      final response = await _supabase
          .from(_purchasesTable)
          .update({
            'download_count': 1, // Supabase will use the stored increment
            'last_downloaded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', purchaseId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Record download returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Download recorded for purchase $purchaseId');
      return MarketplacePurchaseModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected recordDownload error', error: e);
      throw const ServerException(
        message: 'Failed to record download.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVIEWS & RATINGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceReviewModel>> getProductReviews(
    String productId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info(
        'Fetched ${response.length} reviews for product $productId',
      );
      return response
          .map<MarketplaceReviewModel>(
            (row) => MarketplaceReviewModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProductReviews error', error: e);
      throw const ServerException(
        message: 'Failed to fetch product reviews.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceReviewModel> createReview(
    MarketplaceReviewModel review,
  ) async {
    try {
      final data = review.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_reviewsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Review creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Review created: ${response.first['id']}');
      return MarketplaceReviewModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createReview error', error: e);
      throw const ServerException(
        message: 'Failed to create review.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceReviewModel> updateReview(
    MarketplaceReviewModel review,
  ) async {
    try {
      final data = review.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_reviewsTable)
          .update(data)
          .eq('id', review.id)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Review update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Review updated: ${review.id}');
      return MarketplaceReviewModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateReview error', error: e);
      throw const ServerException(
        message: 'Failed to update review.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _supabase.from(_reviewsTable).delete().eq('id', reviewId);

      AppLogger.info('Review deleted: $reviewId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteReview error', error: e);
      throw const ServerException(
        message: 'Failed to delete review.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceReviewModel> respondToReview(
    String reviewId,
    String response,
  ) async {
    try {
      final result = await _supabase
          .from(_reviewsTable)
          .update({
            'seller_response': response,
            'seller_response_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select();

      if (result.isEmpty) {
        throw const ServerException(
          message: 'Review response returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Response added to review: $reviewId');
      return MarketplaceReviewModel.fromJson(result.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected respondToReview error', error: e);
      throw const ServerException(
        message: 'Failed to respond to review.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> voteReviewHelpful(String reviewId, String userId) async {
    try {
      await _supabase.from(_reviewHelpfulTable).upsert({
        'review_id': reviewId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Helpful vote recorded for review $reviewId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected voteReviewHelpful error', error: e);
      throw const ServerException(
        message: 'Failed to vote review helpful.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      await _supabase.from(_reviewReportsTable).insert({
        'review_id': reviewId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Review reported: $reviewId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected reportReview error', error: e);
      throw const ServerException(
        message: 'Failed to report review.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // WISHLIST
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<WishlistModel>> getUserWishlist(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on wishlist
      final response = await _supabase
          .from(_wishlistTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info('Fetched ${response.length} wishlist items for user $userId');
      return response
          .map<WishlistModel>((row) => WishlistModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserWishlist error', error: e);
      throw const ServerException(
        message: 'Failed to fetch wishlist.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<WishlistModel> addToWishlist(String userId, String productId) async {
    try {
      final response = await _supabase
          .from(_wishlistTable)
          .insert({
            'user_id': userId,
            'product_id': productId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Add to wishlist returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Added to wishlist: product $productId for user $userId');
      return WishlistModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected addToWishlist error', error: e);
      throw const ServerException(
        message: 'Failed to add to wishlist.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> removeFromWishlist(String wishlistId) async {
    try {
      await _supabase
          .from(_wishlistTable)
          .delete()
          .eq('id', wishlistId);

      AppLogger.info('Removed from wishlist: $wishlistId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected removeFromWishlist error', error: e);
      throw const ServerException(
        message: 'Failed to remove from wishlist.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final response = await _supabase
          .from(_wishlistTable)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .limit(1);

      return response.isNotEmpty;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected isInWishlist error', error: e);
      throw const ServerException(
        message: 'Failed to check wishlist status.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROMO CODES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<PromoCodeModel> validatePromoCode(
    String code, {
    double? orderAmount,
    List<String>? productTypes,
  }) async {
    try {
      final result = await _supabase.rpc(
        'validate_promo_code',
        params: {
          'p_code': code,
          'p_order_amount': orderAmount,
          'p_product_types': productTypes,
        },
      );

      if (result == null) {
        throw const NotFoundException(message: 'Invalid or expired promo code.');
      }

      return PromoCodeModel.fromJson(result as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected validatePromoCode error', error: e);
      throw const ServerException(
        message: 'Failed to validate promo code.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> applyPromoCode(String promoCodeId) async {
    try {
      await _supabase.rpc(
        'apply_promo_code',
        params: {'p_promo_code_id': promoCodeId},
      );

      AppLogger.info('Promo code applied: $promoCodeId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected applyPromoCode error', error: e);
      throw const ServerException(
        message: 'Failed to apply promo code.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PromoCodeModel>> getPromoCodes({
    bool activeOnly = true,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase.from(_promoCodesTable).select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // PERF: Added limit to prevent unbounded query on promo_codes
      final response = await query.order('created_at', ascending: false).limit(limit);

      AppLogger.info('Fetched ${response.length} promo codes');
      return response
          .map<PromoCodeModel>((row) => PromoCodeModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPromoCodes error', error: e);
      throw const ServerException(
        message: 'Failed to fetch promo codes.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PromoCodeModel> createPromoCode(PromoCodeModel promoCode) async {
    try {
      final data = promoCode.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_promoCodesTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Promo code creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Promo code created: ${response.first['id']}');
      return PromoCodeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createPromoCode error', error: e);
      throw const ServerException(
        message: 'Failed to create promo code.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PromoCodeModel> updatePromoCode(PromoCodeModel promoCode) async {
    try {
      final data = promoCode.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_promoCodesTable)
          .update(data)
          .eq('id', promoCode.id)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Promo code update returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Promo code updated: ${promoCode.id}');
      return PromoCodeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updatePromoCode error', error: e);
      throw const ServerException(
        message: 'Failed to update promo code.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMMISSIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<CommissionRateModel>> getCommissionRates({
    String? productType,
    String? licenseType,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase.from(_commissionRatesTable).select();

      if (productType != null) {
        query = query.eq('product_type', productType);
      }
      if (licenseType != null) {
        query = query.eq('license_type', licenseType);
      }

      // PERF: Added limit to prevent unbounded query on commission_rates
      final response = await query.order('created_at', ascending: false).limit(limit);

      AppLogger.info('Fetched ${response.length} commission rates');
      return response
          .map<CommissionRateModel>(
            (row) => CommissionRateModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCommissionRates error', error: e);
      throw const ServerException(
        message: 'Failed to fetch commission rates.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CommissionRateModel> upsertCommissionRate(
    CommissionRateModel rate,
  ) async {
    try {
      final data = rate.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_commissionRatesTable)
          .upsert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Commission rate upsert returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Commission rate upserted: ${response.first['id']}');
      return CommissionRateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertCommissionRate error', error: e);
      throw const ServerException(
        message: 'Failed to upsert commission rate.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<CommissionRecordModel>> getCommissionRecords(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_commissionRecordsTable)
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info(
        'Fetched ${response.length} commission records for seller $sellerId',
      );
      return response
          .map<CommissionRecordModel>(
            (row) => CommissionRecordModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCommissionRecords error', error: e);
      throw const ServerException(
        message: 'Failed to fetch commission records.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SellerAnalyticsModel>> getSellerAnalytics(
    String sellerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase
          .from(_sellerAnalyticsTable)
          .select()
          .eq('seller_id', sellerId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      // PERF: Added limit to prevent unbounded query on seller_analytics
      final response = await query.order('date', ascending: false).limit(limit);

      AppLogger.info(
        'Fetched ${response.length} seller analytics for $sellerId',
      );
      return response
          .map<SellerAnalyticsModel>(
            (row) => SellerAnalyticsModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSellerAnalytics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch seller analytics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ProductAnalyticsModel>> getProductAnalytics(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      var query = _supabase
          .from(_productAnalyticsTable)
          .select()
          .eq('product_id', productId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      // PERF: Added limit to prevent unbounded query on product_analytics
      final response = await query.order('date', ascending: false).limit(limit);

      AppLogger.info(
        'Fetched ${response.length} product analytics for $productId',
      );
      return response
          .map<ProductAnalyticsModel>(
            (row) => ProductAnalyticsModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProductAnalytics error', error: e);
      throw const ServerException(
        message: 'Failed to fetch product analytics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> recordSearchEvent(MarketplaceSearchLogModel searchLog) async {
    try {
      await _supabase.from(_searchLogsTable).insert(searchLog.toJson());

      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected recordSearchEvent error', error: e);
      throw const ServerException(
        message: 'Failed to record search event.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> recordAIRecommendation(
    AIRecommendationModel recommendation,
  ) async {
    try {
      await _supabase
          .from(_aiRecommendationsTable)
          .insert(recommendation.toJson());

      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected recordAIRecommendation error', error: e);
      throw const ServerException(
        message: 'Failed to record AI recommendation.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUALITY CHECKS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QualityCheckModel> runQualityCheck(String productId) async {
    try {
      final result = await _supabase.rpc(
        'run_product_quality_check',
        params: {'p_product_id': productId},
      );

      if (result == null) {
        throw const ServerException(
          message: 'Quality check returned no result.',
          statusCode: 500,
        );
      }

      AppLogger.info('Quality check run for product $productId');
      return QualityCheckModel.fromJson(result as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected runQualityCheck error', error: e);
      throw const ServerException(
        message: 'Failed to run quality check.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QualityCheckModel> getQualityCheck(String productId) async {
    try {
      final response = await _supabase
          .from(_qualityChecksTable)
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Quality check not found.');
      }

      return QualityCheckModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getQualityCheck error', error: e);
      throw const ServerException(
        message: 'Failed to fetch quality check.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QualityCheckModel>> getProductQualityHistory(
    String productId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on quality_checks
      final response = await _supabase
          .from(_qualityChecksTable)
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info(
        'Fetched ${response.length} quality checks for product $productId',
      );
      return response
          .map<QualityCheckModel>(
            (row) => QualityCheckModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProductQualityHistory error', error: e);
      throw const ServerException(
        message: 'Failed to fetch quality check history.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISPUTES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DisputeModel> createDispute(DisputeModel dispute) async {
    try {
      final data = dispute.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_disputesTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Dispute creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Dispute created: ${response.first['id']}');
      return DisputeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createDispute error', error: e);
      throw const ServerException(
        message: 'Failed to create dispute.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DisputeModel> getDispute(String disputeId) async {
    try {
      final response = await _supabase
          .from(_disputesTable)
          .select()
          .eq('id', disputeId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Dispute not found.');
      }

      return DisputeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getDispute error', error: e);
      throw const ServerException(
        message: 'Failed to fetch dispute.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<DisputeModel>> getDisputes({
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? status,
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from(_disputesTable).select();

      if (orderId != null) {
        query = query.eq('order_id', orderId);
      }
      if (buyerId != null) {
        query = query.eq('buyer_id', buyerId);
      }
      if (sellerId != null) {
        query = query.eq('seller_id', sellerId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} disputes');
      return response
          .map<DisputeModel>((row) => DisputeModel.fromJson(row))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getDisputes error', error: e);
      throw const ServerException(
        message: 'Failed to fetch disputes.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DisputeModel> resolveDispute(
    String disputeId,
    String resolution,
    String resolvedBy,
  ) async {
    try {
      final response = await _supabase
          .from(_disputesTable)
          .update({
            'status': 'resolved',
            'resolution': resolution,
            'resolved_by': resolvedBy,
            'resolved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', disputeId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Dispute resolution returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Dispute resolved: $disputeId');
      return DisputeModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected resolveDispute error', error: e);
      throw const ServerException(
        message: 'Failed to resolve dispute.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceNotificationModel>> getUserNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from(_notificationsTable)
          .select()
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info(
        'Fetched ${response.length} notifications for user $userId',
      );
      return response
          .map<MarketplaceNotificationModel>(
            (row) => MarketplaceNotificationModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUserNotifications error', error: e);
      throw const ServerException(
        message: 'Failed to fetch notifications.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      AppLogger.info('Notification marked read: $notificationId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected markNotificationRead error', error: e);
      throw const ServerException(
        message: 'Failed to mark notification as read.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> markAllNotificationsRead(String userId) async {
    try {
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      AppLogger.info('All notifications marked read for user $userId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected markAllNotificationsRead error', error: e);
      throw const ServerException(
        message: 'Failed to mark all notifications as read.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceNotificationModel> createNotification(
    MarketplaceNotificationModel notification,
  ) async {
    try {
      final data = notification.toJson();
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_notificationsTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Notification creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Notification created: ${response.first['id']}');
      return MarketplaceNotificationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createNotification error', error: e);
      throw const ServerException(
        message: 'Failed to create notification.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SAVED SEARCHES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<SavedSearchModel>> getSavedSearches(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on saved_searches
      final response = await _supabase
          .from(_savedSearchesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      AppLogger.info(
        'Fetched ${response.length} saved searches for user $userId',
      );
      return response
          .map<SavedSearchModel>(
            (row) => SavedSearchModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSavedSearches error', error: e);
      throw const ServerException(
        message: 'Failed to fetch saved searches.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SavedSearchModel> createSavedSearch(
    SavedSearchModel savedSearch,
  ) async {
    try {
      final data = savedSearch.toJson();
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_savedSearchesTable)
          .insert(data)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Saved search creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Saved search created: ${response.first['id']}');
      return SavedSearchModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createSavedSearch error', error: e);
      throw const ServerException(
        message: 'Failed to create saved search.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deleteSavedSearch(String savedSearchId) async {
    try {
      await _supabase
          .from(_savedSearchesTable)
          .delete()
          .eq('id', savedSearchId);

      AppLogger.info('Saved search deleted: $savedSearchId');
      return true;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteSavedSearch error', error: e);
      throw const ServerException(
        message: 'Failed to delete saved search.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceProductModel>> getRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final result = await _supabase.rpc(
        'get_marketplace_recommendations',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      final list = result as List<dynamic>;
      AppLogger.info('Fetched ${list.length} recommendations for user $userId');
      return list
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getRecommendations error', error: e);
      throw const ServerException(
        message: 'Failed to fetch recommendations.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MarketplaceProductModel>> getTrendingProducts({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('status', 'published')
          .filter('deleted_at', 'is', null)
          .order('total_sales', ascending: false)
          .limit(limit);

      AppLogger.info('Fetched ${response.length} trending products');
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTrendingProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch trending products.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MARKETPLACE MODERATION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MarketplaceProductModel>> getPendingProducts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('status', 'pending_review')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.info('Fetched ${response.length} pending products');
      return response
          .map<MarketplaceProductModel>(
            (row) => MarketplaceProductModel.fromJson(row),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPendingProducts error', error: e);
      throw const ServerException(
        message: 'Failed to fetch pending products.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> approveProduct(
    String productId,
    String moderatorId,
  ) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .update({
            'status': 'published',
            'moderated_by': moderatorId,
            'moderated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product approval returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product approved: $productId by $moderatorId');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected approveProduct error', error: e);
      throw const ServerException(
        message: 'Failed to approve product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceProductModel> rejectProduct(
    String productId,
    String reason,
    String moderatorId,
  ) async {
    try {
      final response = await _supabase
          .from(_productsTable)
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'moderated_by': moderatorId,
            'moderated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Product rejection returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Product rejected: $productId by $moderatorId');
      return MarketplaceProductModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected rejectProduct error', error: e);
      throw const ServerException(
        message: 'Failed to reject product.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<MarketplaceReviewModel> moderateReview(
    String reviewId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from(_reviewsTable)
          .update({
            'moderation_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Review moderation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Review moderated: $reviewId → $status');
      return MarketplaceReviewModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected moderateReview error', error: e);
      throw const ServerException(
        message: 'Failed to moderate review.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SellerProfileModel> suspendSeller(
    String sellerId,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_sellerProfilesTable)
          .update({
            'status': 'suspended',
            'suspension_reason': reason,
            'suspended_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Seller suspension returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Seller suspended: $sellerId — $reason');
      return SellerProfileModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected suspendSeller error', error: e);
      throw const ServerException(
        message: 'Failed to suspend seller.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Applies sort ordering based on the [sortBy] string.
  ///
  /// Maps:
  /// - 'newest' → order by created_at descending
  /// - 'popular' → order by total_sales descending
  /// - 'rating' → order by average_rating descending
  /// - 'price_low' → order by price ascending
  /// - 'price_high' → order by price descending
  sb.PostgrestTransformBuilder<dynamic> _applySortBy(
    sb.PostgrestFilterBuilder<dynamic> query,
    String? sortBy,
  ) {
    switch (sortBy) {
      case 'popular':
        return query.order('total_sales', ascending: false);
      case 'rating':
        return query.order('average_rating', ascending: false);
      case 'price_low':
        return query.order('price', ascending: true);
      case 'price_high':
        return query.order('price', ascending: false);
      case 'newest':
      default:
        return query.order('created_at', ascending: false);
    }
  }

  /// Maps a Supabase [sb.PostgrestException] to a domain exception.
  Exception _mapPostgrestException(sb.PostgrestException e) {
    final statusCode = e.code != null ? int.tryParse(e.code!) ?? 0 : 0;
    final message = e.message ?? 'An unexpected database error occurred.';

    AppLogger.warning(
      'Supabase PostgrestException — code: ${e.code}, message: $message',
    );

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 422:
        return ValidationException(
          message: message,
          fieldErrors: e.details is Map<String, dynamic>
              ? e.details as Map<String, String>
              : {},
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: e.details,
        );
    }
  }
}
