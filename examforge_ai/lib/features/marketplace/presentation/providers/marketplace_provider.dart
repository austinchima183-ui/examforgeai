import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_featured_products_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_recommendations_usecase.dart';
import '../../domain/usecases/get_trending_products_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// MARKETPLACE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the marketplace browsing/search/discovery feature.
///
/// Tracks products, featured/trending/recommended lists, categories,
/// search and filter state, pagination, and loading/error states.
class MarketplaceState {
  const MarketplaceState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.products = const [],
    this.featuredProducts = const [],
    this.trendingProducts = const [],
    this.recommendedProducts = const [],
    this.categories = const [],
    this.searchQuery,
    this.selectedCategory,
    this.selectedProductType,
    this.selectedSubject,
    this.selectedClassLevel,
    this.selectedCurriculum,
    this.sortBy,
    this.currentPage = 0,
    this.hasMore = true,
    this.searchResults = const [],
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The main list of marketplace products.
  final List<MarketplaceProductEntity> products;

  /// Featured products highlighted by admins.
  final List<MarketplaceProductEntity> featuredProducts;

  /// Trending products based on sales/views.
  final List<MarketplaceProductEntity> trendingProducts;

  /// AI-recommended products for the current user.
  final List<MarketplaceProductEntity> recommendedProducts;

  /// Available marketplace categories.
  final List<MarketplaceCategoryEntity> categories;

  /// The current search query string.
  final String? searchQuery;

  /// The currently selected category filter.
  final String? selectedCategory;

  /// The currently selected product type filter.
  final MarketplaceProductType? selectedProductType;

  /// The currently selected subject filter.
  final String? selectedSubject;

  /// The currently selected class level filter.
  final String? selectedClassLevel;

  /// The currently selected curriculum filter.
  final String? selectedCurriculum;

  /// The current sort field.
  final String? sortBy;

  /// The current pagination page index.
  final int currentPage;

  /// Whether more products are available for pagination.
  final bool hasMore;

  /// Search results for the current query.
  final List<MarketplaceProductEntity> searchResults;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether any filter is currently active.
  bool get hasActiveFilters =>
      selectedCategory != null ||
      selectedProductType != null ||
      selectedSubject != null ||
      selectedClassLevel != null ||
      selectedCurriculum != null;

  /// Whether a search is in progress.
  bool get isSearching => searchQuery != null && searchQuery!.isNotEmpty;

  /// Creates a copy of this state with the given fields replaced.
  MarketplaceState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<MarketplaceProductEntity>? products,
    List<MarketplaceProductEntity>? featuredProducts,
    List<MarketplaceProductEntity>? trendingProducts,
    List<MarketplaceProductEntity>? recommendedProducts,
    List<MarketplaceCategoryEntity>? categories,
    String? searchQuery,
    String? selectedCategory,
    MarketplaceProductType? selectedProductType,
    String? selectedSubject,
    String? selectedClassLevel,
    String? selectedCurriculum,
    String? sortBy,
    int? currentPage,
    bool? hasMore,
    List<MarketplaceProductEntity>? searchResults,
  }) {
    return MarketplaceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      products: products ?? this.products,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      trendingProducts: trendingProducts ?? this.trendingProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedProductType: selectedProductType ?? this.selectedProductType,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      selectedClassLevel: selectedClassLevel ?? this.selectedClassLevel,
      selectedCurriculum: selectedCurriculum ?? this.selectedCurriculum,
      sortBy: sortBy ?? this.sortBy,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  /// Clears the current error message.
  MarketplaceState clearError() => copyWith(error: null);

  /// Clears the current success message.
  MarketplaceState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// MARKETPLACE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the marketplace browsing state.
///
/// Supports loading products, featured/trending/recommended products,
/// categories, search, filtering, sorting, and pagination.
class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  MarketplaceNotifier({
    required GetProductsUseCase getProductsUseCase,
    required GetFeaturedProductsUseCase getFeaturedProductsUseCase,
    required GetTrendingProductsUseCase getTrendingProductsUseCase,
    required GetRecommendationsUseCase getRecommendationsUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _getProductsUseCase = getProductsUseCase,
        _getFeaturedProductsUseCase = getFeaturedProductsUseCase,
        _getTrendingProductsUseCase = getTrendingProductsUseCase,
        _getRecommendationsUseCase = getRecommendationsUseCase,
        _getCategoriesUseCase = getCategoriesUseCase,
        super(const MarketplaceState());

  final GetProductsUseCase _getProductsUseCase;
  final GetFeaturedProductsUseCase _getFeaturedProductsUseCase;
  final GetTrendingProductsUseCase _getTrendingProductsUseCase;
  final GetRecommendationsUseCase _getRecommendationsUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  // ─── Load Products ──────────────────────────────────────────────────

  /// Loads the main product list with current filters.
  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getProductsUseCase(
      GetProductsParams(
        categoryId: state.selectedCategory,
        productType: state.selectedProductType,
        subject: state.selectedSubject,
        classLevel: state.selectedClassLevel,
        curriculum: state.selectedCurriculum,
        sortBy: state.sortBy,
        search: state.searchQuery,
        limit: 20,
        offset: 0,
      ),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          products: products,
          currentPage: 0,
          hasMore: products.length >= 20,
        );
        AppLogger.info('Loaded ${products.length} marketplace products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load marketplace products: $failure');
      },
    );
  }

  // ─── Load Featured Products ─────────────────────────────────────────

  /// Loads featured products.
  Future<void> loadFeaturedProducts({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getFeaturedProductsUseCase(
      GetFeaturedProductsParams(limit: limit),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          featuredProducts: products,
        );
        AppLogger.info('Loaded ${products.length} featured products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load featured products: $failure');
      },
    );
  }

  // ─── Load Trending Products ─────────────────────────────────────────

  /// Loads trending products.
  Future<void> loadTrendingProducts({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTrendingProductsUseCase(
      GetTrendingProductsParams(limit: limit),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          trendingProducts: products,
        );
        AppLogger.info('Loaded ${products.length} trending products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load trending products: $failure');
      },
    );
  }

  // ─── Load Recommendations ───────────────────────────────────────────

  /// Loads AI-powered product recommendations for the given user.
  Future<void> loadRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getRecommendationsUseCase(
      GetRecommendationsParams(userId: userId, limit: limit),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          recommendedProducts: products,
        );
        AppLogger.info('Loaded ${products.length} recommended products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load recommendations: $failure');
      },
    );
  }

  // ─── Load Categories ────────────────────────────────────────────────

  /// Loads available marketplace categories.
  Future<void> loadCategories({bool activeOnly = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCategoriesUseCase(
      GetCategoriesParams(activeOnly: activeOnly),
    );

    result.fold(
      onSuccess: (categories) {
        state = state.copyWith(
          isLoading: false,
          categories: categories,
        );
        AppLogger.info('Loaded ${categories.length} categories');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load categories: $failure');
      },
    );
  }

  // ─── Search Products ────────────────────────────────────────────────

  /// Searches products by query string.
  Future<void> searchProducts(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    final result = await _getProductsUseCase(
      GetProductsParams(
        search: query,
        categoryId: state.selectedCategory,
        productType: state.selectedProductType,
        subject: state.selectedSubject,
        classLevel: state.selectedClassLevel,
        curriculum: state.selectedCurriculum,
        sortBy: state.sortBy,
        limit: 20,
        offset: 0,
      ),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          searchResults: products,
          currentPage: 0,
          hasMore: products.length >= 20,
        );
        AppLogger.info('Search returned ${products.length} results');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to search products: $failure');
      },
    );
  }

  // ─── Filter by Category ─────────────────────────────────────────────

  /// Filters products by category.
  Future<void> filterByCategory(String? categoryId) async {
    state = state.copyWith(selectedCategory: categoryId);
    await loadProducts();
  }

  // ─── Filter by Type ─────────────────────────────────────────────────

  /// Filters products by product type.
  Future<void> filterByType(MarketplaceProductType? productType) async {
    state = state.copyWith(selectedProductType: productType);
    await loadProducts();
  }

  // ─── Filter by Subject ──────────────────────────────────────────────

  /// Filters products by subject.
  Future<void> filterBySubject(String? subject) async {
    state = state.copyWith(selectedSubject: subject);
    await loadProducts();
  }

  // ─── Sort by Field ──────────────────────────────────────────────────

  /// Sorts products by the specified field.
  Future<void> sortByField(String? sortBy) async {
    state = state.copyWith(sortBy: sortBy);
    await loadProducts();
  }

  // ─── Load More ──────────────────────────────────────────────────────

  /// Loads the next page of products for infinite scrolling.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getProductsUseCase(
      GetProductsParams(
        categoryId: state.selectedCategory,
        productType: state.selectedProductType,
        subject: state.selectedSubject,
        classLevel: state.selectedClassLevel,
        curriculum: state.selectedCurriculum,
        sortBy: state.sortBy,
        search: state.searchQuery,
        limit: 20,
        offset: nextPage * 20,
      ),
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoading: false,
          products: [...state.products, ...products],
          currentPage: nextPage,
          hasMore: products.length >= 20,
        );
        AppLogger.info('Loaded ${products.length} more products');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more products: $failure');
      },
    );
  }

  // ─── Refresh ────────────────────────────────────────────────────────

  /// Refreshes all marketplace data.
  Future<void> refresh() async {
    state = state.copyWith(currentPage: 0, hasMore: true);
    await loadProducts();
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
// MARKETPLACE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the marketplace browsing feature.
///
/// The factory accepts all required use cases via named parameters.
final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
  (ref) => MarketplaceNotifier(
    getProductsUseCase: ref.watch(getProductsUseCaseProvider),
    getFeaturedProductsUseCase: ref.watch(getFeaturedProductsUseCaseProvider),
    getTrendingProductsUseCase: ref.watch(getTrendingProductsUseCaseProvider),
    getRecommendationsUseCase: ref.watch(getRecommendationsUseCaseProvider),
    getCategoriesUseCase: ref.watch(getCategoriesUseCaseProvider),
  ),
);
