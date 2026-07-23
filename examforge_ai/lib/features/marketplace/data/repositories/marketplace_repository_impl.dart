import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_datasource.dart';
import '../models/marketplace_models.dart';


class MarketplaceRepositoryImpl implements MarketplaceRepository {
  MarketplaceRepositoryImpl({required this.remoteDataSource});
  final MarketplaceRemoteDataSource remoteDataSource;

  // ─── Categories ──────────────────────────────────────────────────────

  @override
  Future<Result<List<MarketplaceCategoryEntity>>> getCategories({
    bool activeOnly = true,
  }) async {
    try {
      final models = await remoteDataSource.getCategories(activeOnly: activeOnly);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceCategoryEntity>> getCategory(String categoryId) async {
    try {
      final model = await remoteDataSource.getCategory(categoryId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceCategoryEntity>> upsertCategory(
    MarketplaceCategoryEntity category,
  ) async {
    try {
      final model = MarketplaceCategoryModel.fromEntity(category);
      final result = await remoteDataSource.upsertCategory(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> deleteCategory(String categoryId) async {
    try {
      final result = await remoteDataSource.deleteCategory(categoryId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Seller Profiles ─────────────────────────────────────────────────

  @override
  Future<Result<SellerProfileEntity>> getSellerProfile(String sellerId) async {
    try {
      final model = await remoteDataSource.getSellerProfile(sellerId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<SellerProfileEntity>> getSellerProfileByUserId(String userId) async {
    try {
      final model = await remoteDataSource.getSellerProfileByUserId(userId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<SellerProfileEntity>> upsertSellerProfile(
    SellerProfileEntity profile,
  ) async {
    try {
      final model = SellerProfileModel.fromEntity(profile);
      final result = await remoteDataSource.upsertSellerProfile(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<SellerProfileEntity>> updateSellerStatus(
    String sellerId,
    MarketplaceSellerStatus status,
  ) async {
    try {
      final model = await remoteDataSource.updateSellerStatus(
        sellerId,
        status.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<SellerProfileEntity>>> getSellers({
    MarketplaceSellerStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getSellers(
        status: status?.value,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Products ────────────────────────────────────────────────────────

  @override
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
  }) async {
    try {
      final models = await remoteDataSource.getProducts(
        status: status?.value,
        productType: productType?.value,
        categoryId: categoryId,
        sellerId: sellerId,
        subject: subject,
        classLevel: classLevel,
        curriculum: curriculum,
        search: search,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> getProduct(String productId) async {
    try {
      final model = await remoteDataSource.getProduct(productId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> getProductBySlug(String slug) async {
    try {
      final model = await remoteDataSource.getProductBySlug(slug);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> createProduct(
    MarketplaceProductEntity product,
  ) async {
    try {
      final model = MarketplaceProductModel.fromEntity(product);
      final result = await remoteDataSource.createProduct(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> updateProduct(
    MarketplaceProductEntity product,
  ) async {
    try {
      final model = MarketplaceProductModel.fromEntity(product);
      final result = await remoteDataSource.updateProduct(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> deleteProduct(String productId) async {
    try {
      final result = await remoteDataSource.deleteProduct(productId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> updateProductStatus(
    String productId,
    MarketplaceProductStatus status,
  ) async {
    try {
      final model = await remoteDataSource.updateProductStatus(
        productId,
        status.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> featureProduct(
    String productId,
    bool featured,
  ) async {
    try {
      final model = await remoteDataSource.featureProduct(productId, featured);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> incrementProductView(String productId) async {
    try {
      final result = await remoteDataSource.incrementProductView(productId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<MarketplaceProductEntity>>> getSellerProducts(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getSellerProducts(
        sellerId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<MarketplaceProductEntity>>> getFeaturedProducts({
    int limit = 10,
  }) async {
    try {
      final models = await remoteDataSource.getFeaturedProducts(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<MarketplaceProductEntity>>> getRelatedProducts(
    String productId, {
    int limit = 10,
  }) async {
    try {
      final models = await remoteDataSource.getRelatedProducts(
        productId,
        limit: limit,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Product Versions ────────────────────────────────────────────────

  @override
  Future<Result<List<ProductVersionEntity>>> getProductVersions(
    String productId,
  ) async {
    try {
      final models = await remoteDataSource.getProductVersions(productId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<ProductVersionEntity>> createProductVersion(
    ProductVersionEntity version,
  ) async {
    try {
      final model = ProductVersionModel.fromEntity(version);
      final result = await remoteDataSource.createProductVersion(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Shopping Cart ───────────────────────────────────────────────────

  @override
  Future<Result<CartEntity>> getCart(String userId) async {
    try {
      final model = await remoteDataSource.getCart(userId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<CartEntity>> addToCart(
    String userId,
    CartItemEntity item,
  ) async {
    try {
      final itemModel = CartItemModel.fromEntity(item);
      final cartItemModel = await remoteDataSource.addToCart(userId, itemModel);
      // Re-fetch the full cart after adding an item to return the complete cart
      final cartModel = await remoteDataSource.getCart(userId);
      return Success(cartModel.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<CartItemEntity>> updateCartItem(CartItemEntity item) async {
    try {
      final model = CartItemModel.fromEntity(item);
      final result = await remoteDataSource.updateCartItem(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> removeFromCart(String cartItemId) async {
    try {
      final result = await remoteDataSource.removeFromCart(cartItemId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> clearCart(String userId) async {
    try {
      final result = await remoteDataSource.clearCart(userId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Orders ──────────────────────────────────────────────────────────

  @override
  Future<Result<MarketplaceOrderEntity>> createOrder(
    MarketplaceOrderEntity order,
  ) async {
    try {
      final model = MarketplaceOrderModel.fromEntity(order);
      final result = await remoteDataSource.createOrder(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceOrderEntity>> getOrder(String orderId) async {
    try {
      final model = await remoteDataSource.getOrder(orderId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceOrderEntity>> getOrderByNumber(
    String orderNumber,
  ) async {
    try {
      final model = await remoteDataSource.getOrderByNumber(orderNumber);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<MarketplaceOrderEntity>>> getUserOrders(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getUserOrders(
        buyerId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceOrderEntity>> updateOrderStatus(
    String orderId,
    MarketplaceOrderStatus status,
  ) async {
    try {
      final model = await remoteDataSource.updateOrderStatus(
        orderId,
        status.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceOrderEntity>> verifyPayment(String txRef) async {
    try {
      final model = await remoteDataSource.verifyPayment(txRef);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Purchases ───────────────────────────────────────────────────────

  @override
  Future<Result<List<MarketplacePurchaseEntity>>> getUserPurchases(
    String buyerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getUserPurchases(
        buyerId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplacePurchaseEntity>> getPurchase(
    String purchaseId,
  ) async {
    try {
      final model = await remoteDataSource.getPurchase(purchaseId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> verifyPurchase(
    String buyerId,
    String productId,
  ) async {
    try {
      final result = await remoteDataSource.verifyPurchase(buyerId, productId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> recordDownload(String purchaseId) async {
    try {
      await remoteDataSource.recordDownload(purchaseId);
      return const Success(true);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Reviews & Ratings ───────────────────────────────────────────────

  @override
  Future<Result<List<MarketplaceReviewEntity>>> getProductReviews(
    String productId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getProductReviews(
        productId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceReviewEntity>> createReview(
    MarketplaceReviewEntity review,
  ) async {
    try {
      final model = MarketplaceReviewModel.fromEntity(review);
      final result = await remoteDataSource.createReview(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceReviewEntity>> updateReview(
    MarketplaceReviewEntity review,
  ) async {
    try {
      final model = MarketplaceReviewModel.fromEntity(review);
      final result = await remoteDataSource.updateReview(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> deleteReview(String reviewId) async {
    try {
      final result = await remoteDataSource.deleteReview(reviewId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceReviewEntity>> respondToReview(
    String reviewId,
    String response,
  ) async {
    try {
      final model = await remoteDataSource.respondToReview(reviewId, response);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> voteReviewHelpful(
    String reviewId,
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.voteReviewHelpful(reviewId, userId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> reportReview(
    String reviewId,
    String reason,
  ) async {
    try {
      final result = await remoteDataSource.reportReview(reviewId, reason);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Wishlist ────────────────────────────────────────────────────────

  @override
  Future<Result<List<WishlistEntity>>> getUserWishlist(String userId) async {
    try {
      final models = await remoteDataSource.getUserWishlist(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<WishlistEntity>> addToWishlist(
    String userId,
    String productId,
  ) async {
    try {
      final model = await remoteDataSource.addToWishlist(userId, productId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> removeFromWishlist(String wishlistId) async {
    try {
      final result = await remoteDataSource.removeFromWishlist(wishlistId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> isInWishlist(
    String userId,
    String productId,
  ) async {
    try {
      final result = await remoteDataSource.isInWishlist(userId, productId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Promo Codes ─────────────────────────────────────────────────────

  @override
  Future<Result<PromoCodeEntity>> validatePromoCode(
    String code, {
    double? orderAmount,
    List<MarketplaceProductType>? productTypes,
  }) async {
    try {
      final model = await remoteDataSource.validatePromoCode(
        code,
        orderAmount: orderAmount,
        productTypes: productTypes?.map((e) => e.value).toList(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> applyPromoCode(String promoCodeId) async {
    try {
      final result = await remoteDataSource.applyPromoCode(promoCodeId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<PromoCodeEntity>>> getPromoCodes({
    bool activeOnly = true,
  }) async {
    try {
      final models = await remoteDataSource.getPromoCodes(activeOnly: activeOnly);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<PromoCodeEntity>> createPromoCode(
    PromoCodeEntity promoCode,
  ) async {
    try {
      final model = PromoCodeModel.fromEntity(promoCode);
      final result = await remoteDataSource.createPromoCode(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<PromoCodeEntity>> updatePromoCode(
    PromoCodeEntity promoCode,
  ) async {
    try {
      final model = PromoCodeModel.fromEntity(promoCode);
      final result = await remoteDataSource.updatePromoCode(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Commissions ─────────────────────────────────────────────────────

  @override
  Future<Result<List<CommissionRateEntity>>> getCommissionRates({
    MarketplaceProductType? productType,
    MarketplaceLicenseType? licenseType,
  }) async {
    try {
      final models = await remoteDataSource.getCommissionRates(
        productType: productType?.value,
        licenseType: licenseType?.value,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<CommissionRateEntity>> upsertCommissionRate(
    CommissionRateEntity rate,
  ) async {
    try {
      final model = CommissionRateModel.fromEntity(rate);
      final result = await remoteDataSource.upsertCommissionRate(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<CommissionRecordEntity>>> getCommissionRecords(
    String sellerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getCommissionRecords(
        sellerId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Analytics ───────────────────────────────────────────────────────

  @override
  Future<Result<SellerAnalyticsEntity>> getSellerAnalytics(
    String sellerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final models = await remoteDataSource.getSellerAnalytics(
        sellerId,
        startDate: startDate,
        endDate: endDate,
      );
      if (models.isEmpty) {
        return const FailureResult(Failure.notFound(
          message: 'No seller analytics data found.',
        ),);
      }
      return Success(models.first.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<ProductAnalyticsEntity>> getProductAnalytics(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final models = await remoteDataSource.getProductAnalytics(
        productId,
        startDate: startDate,
        endDate: endDate,
      );
      if (models.isEmpty) {
        return const FailureResult(Failure.notFound(
          message: 'No product analytics data found.',
        ),);
      }
      return Success(models.first.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> recordSearchEvent(
    MarketplaceSearchLogEntity searchLog,
  ) async {
    try {
      final model = MarketplaceSearchLogModel.fromEntity(searchLog);
      final result = await remoteDataSource.recordSearchEvent(model);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> recordAIRecommendation(
    AIRecommendationEntity recommendation,
  ) async {
    try {
      final model = AIRecommendationModel.fromEntity(recommendation);
      final result = await remoteDataSource.recordAIRecommendation(model);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Quality Checks ──────────────────────────────────────────────────

  @override
  Future<Result<QualityCheckEntity>> runQualityCheck(String productId) async {
    try {
      final model = await remoteDataSource.runQualityCheck(productId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<QualityCheckEntity>> getQualityCheck(String productId) async {
    try {
      final model = await remoteDataSource.getQualityCheck(productId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<QualityCheckEntity>>> getProductQualityHistory(
    String productId,
  ) async {
    try {
      final models = await remoteDataSource.getProductQualityHistory(productId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Disputes ────────────────────────────────────────────────────────

  @override
  Future<Result<DisputeEntity>> createDispute(DisputeEntity dispute) async {
    try {
      final model = DisputeModel.fromEntity(dispute);
      final result = await remoteDataSource.createDispute(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<DisputeEntity>> getDispute(String disputeId) async {
    try {
      final model = await remoteDataSource.getDispute(disputeId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<DisputeEntity>>> getDisputes({
    String? orderId,
    String? buyerId,
    String? sellerId,
    DisputeStatus? status,
  }) async {
    try {
      final models = await remoteDataSource.getDisputes(
        orderId: orderId,
        buyerId: buyerId,
        sellerId: sellerId,
        status: status?.value,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<DisputeEntity>> resolveDispute(
    String disputeId,
    String resolution,
    String resolvedBy,
  ) async {
    try {
      final model = await remoteDataSource.resolveDispute(
        disputeId,
        resolution,
        resolvedBy,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Notifications ───────────────────────────────────────────────────

  @override
  Future<Result<List<MarketplaceNotificationEntity>>> getUserNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 20,
  }) async {
    try {
      final models = await remoteDataSource.getUserNotifications(
        userId,
        unreadOnly: unreadOnly,
        limit: limit,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> markNotificationRead(String notificationId) async {
    try {
      final result = await remoteDataSource.markNotificationRead(notificationId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> markAllNotificationsRead(String userId) async {
    try {
      final result = await remoteDataSource.markAllNotificationsRead(userId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceNotificationEntity>> createNotification(
    MarketplaceNotificationEntity notification,
  ) async {
    try {
      final model = MarketplaceNotificationModel.fromEntity(notification);
      final result = await remoteDataSource.createNotification(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Saved Searches ──────────────────────────────────────────────────

  @override
  Future<Result<List<SavedSearchEntity>>> getSavedSearches(
    String userId,
  ) async {
    try {
      final models = await remoteDataSource.getSavedSearches(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<SavedSearchEntity>> createSavedSearch(
    SavedSearchEntity savedSearch,
  ) async {
    try {
      final model = SavedSearchModel.fromEntity(savedSearch);
      final result = await remoteDataSource.createSavedSearch(model);
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<bool>> deleteSavedSearch(String savedSearchId) async {
    try {
      final result = await remoteDataSource.deleteSavedSearch(savedSearchId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── AI Recommendations ──────────────────────────────────────────────

  @override
  Future<Result<List<MarketplaceProductEntity>>> getRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final models = await remoteDataSource.getRecommendations(
        userId,
        limit: limit,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<List<MarketplaceProductEntity>>> getTrendingProducts({
    int limit = 10,
  }) async {
    try {
      final models = await remoteDataSource.getTrendingProducts(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  // ─── Marketplace Moderation ──────────────────────────────────────────

  @override
  Future<Result<List<MarketplaceProductEntity>>> getPendingProducts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final models = await remoteDataSource.getPendingProducts(
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> approveProduct(
    String productId,
    String moderatorId,
  ) async {
    try {
      final model = await remoteDataSource.approveProduct(productId, moderatorId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceProductEntity>> rejectProduct(
    String productId,
    String reason,
    String moderatorId,
  ) async {
    try {
      final model = await remoteDataSource.rejectProduct(
        productId,
        reason,
        moderatorId,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceReviewEntity>> moderateReview(
    String reviewId,
    MarketplaceReviewStatus status,
  ) async {
    try {
      final model = await remoteDataSource.moderateReview(
        reviewId,
        status.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }

  @override
  Future<Result<SellerProfileEntity>> suspendSeller(
    String sellerId,
    String reason,
  ) async {
    try {
      final model = await remoteDataSource.suspendSeller(sellerId, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode ?? 500));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: 'Unexpected error: $e', statusCode: 500));
    }
  }
}
