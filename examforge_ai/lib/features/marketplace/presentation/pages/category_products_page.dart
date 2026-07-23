import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/widgets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'product_detail_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CATEGORY PRODUCTS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Products filtered by a specific category with sort/filter options,
/// pull-to-refresh, and pagination.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CategoryProductsPage(
///       categoryId: 'cat-123',
///       categoryName: 'Question Banks',
///     ),
///   ),
/// );
/// ```
class CategoryProductsPage extends ConsumerStatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  ConsumerState<CategoryProductsPage> createState() =>
      _CategoryProductsPageState();
}

class _CategoryProductsPageState extends ConsumerState<CategoryProductsPage> {
  String _selectedSortBy = 'newest';
  final ScrollController _scrollController = ScrollController();

  static const List<String> _sortOptions = [
    'newest',
    'price_low',
    'price_high',
    'rating',
    'popular',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Set the category filter and load products
    final notifier = ref.read(marketplaceProvider.notifier);
    await notifier.filterByCategory(widget.categoryId);
  }

  Future<void> _refresh() async {
    await ref.read(marketplaceProvider.notifier).refresh();
    await ref.read(marketplaceProvider.notifier).filterByCategory(
      widget.categoryId,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(marketplaceProvider.notifier).loadMore();
    }
  }

  void _navigateToProduct(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: productId),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final state = ref.read(marketplaceProvider);
    FilterBottomSheet.show(
      context,
      categories: state.categories,
      selectedType: state.selectedProductType,
      onApply: (category, type, subject, classLevel, curriculum, minPrice, maxPrice) {
        final notifier = ref.read(marketplaceProvider.notifier);
        if (type != null) {
          notifier.filterByType(type);
        }
        // Reload with filters
        notifier.loadProducts();
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Listen for errors
    ref.listen<MarketplaceState>(marketplaceProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(marketplaceProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: widget.categoryName,
        actions: [
          AppIconButton(
            icon: Icons.tune_rounded,
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: state.isLoading && state.products.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.products.isEmpty
              ? AppErrorState.serverError(onRetry: _loadData)
              : state.products.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // ── Sort & Filter Header ─────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSortHeader(state, cs, tt),
                          ),

                          // ── Products Grid ────────────────────────────────
                          _buildProductsGrid(state),

                          // ── Loading more indicator ───────────────────────
                          if (state.hasMore && state.products.isNotEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(Spacings.lg),
                                child: Center(
                                  child: AppLoadingSpinner(
                                    size: AppLoadingSpinnerSize.small,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  // ─── Sort Header ────────────────────────────────────────────────────────

  Widget _buildSortHeader(
    MarketplaceState state,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final resultCount = state.products.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$resultCount product${resultCount != 1 ? 's' : ''}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSortBy,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                style: tt.labelMedium?.copyWith(color: cs.onSurface),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(_sortLabel(option)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSortBy = value);
                    ref.read(marketplaceProvider.notifier).sortByField(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(String key) {
    return switch (key) {
      'newest' => 'Newest',
      'price_low' => 'Price: Low to High',
      'price_high' => 'Price: High to Low',
      'rating' => 'Highest Rated',
      'popular' => 'Most Popular',
      _ => key,
    };
  }

  // ─── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return EmptyMarketplaceState(
      icon: Icons.category_outlined,
      title: 'No Products in ${widget.categoryName}',
      subtitle: 'There are no products available in this category yet. Check back later or browse other categories.',
      actionLabel: 'Browse All',
      onAction: () => Navigator.pop(context),
    );
  }

  // ─── Products Grid ──────────────────────────────────────────────────────

  Widget _buildProductsGrid(MarketplaceState state) {
    final crossAxisCount = context.isMobile ? 2 : 3;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = state.products[index];
            return ProductCard(
              product: product,
              onTap: () => _navigateToProduct(product.id),
            );
          },
          childCount: state.products.length,
        ),
      ),
    );
  }
}
