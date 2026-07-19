import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/marketplace_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'marketplace_search_page.dart';
import 'category_products_page.dart';
import 'product_detail_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE HOME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Main marketplace browsing page featuring a hero banner, featured products,
/// trending products, categories grid, and AI-recommended products.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceHomePage()));
/// ```
class MarketplaceHomePage extends ConsumerStatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  ConsumerState<MarketplaceHomePage> createState() =>
      _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends ConsumerState<MarketplaceHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final notifier = ref.read(marketplaceProvider.notifier);
    await Future.wait([
      notifier.loadFeaturedProducts(),
      notifier.loadTrendingProducts(),
      notifier.loadCategories(),
      notifier.loadProducts(),
    ]);
    // Load recommendations asynchronously (non-blocking)
    notifier.loadRecommendations(userId: 'current_user');
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

  Future<void> _refresh() async {
    final notifier = ref.read(marketplaceProvider.notifier);
    await Future.wait([
      notifier.loadFeaturedProducts(),
      notifier.loadTrendingProducts(),
      notifier.loadCategories(),
      notifier.loadProducts(),
      notifier.loadRecommendations(userId: 'current_user'),
    ]);
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceSearchPage()),
    );
  }

  void _navigateToCategory(String categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  void _navigateToProduct(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final cartState = ref.watch(cartProvider);

    // Listen for error/success messages
    ref.listen<MarketplaceState>(marketplaceProvider, (prev, next) {
      if (next.error != null && (prev?.error != next.error)) {
        _showSnackBar(next.error!, isError: true);
        ref.read(marketplaceProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Marketplace',
        actions: [
          // Cart icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              AppIconButton(
                icon: Icons.shopping_cart_outlined,
                onPressed: () {
                  // Navigate to cart page
                },
                tooltip: 'Cart',
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: AppTypography.wBold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          AppIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {
              // Navigate to notifications
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: state.isLoading && state.featuredProducts.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.featuredProducts.isEmpty
              ? AppErrorState.serverError(onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
                      // ── Hero Banner ───────────────────────────────────────
                      SliverToBoxAdapter(child: _buildHeroBanner()),

                      // ── Featured Products ─────────────────────────────────
                      if (state.featuredProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildFeaturedSection(state),
                        ),

                      // ── Trending Products ─────────────────────────────────
                      if (state.trendingProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildTrendingSection(state),
                        ),

                      // ── Categories ────────────────────────────────────────
                      if (state.categories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildCategoriesSection(state),
                        ),

                      // ── Recommended for You ──────────────────────────────
                      if (state.recommendedProducts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildRecommendedSection(state),
                        ),

                      // Bottom padding
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: Spacings.xxl),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─── Hero Banner ────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      margin: const EdgeInsets.all(Spacings.lg),
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover Educational\nResources',
            style: tt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.wBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Find question banks, lesson notes, exam templates, and more from trusted educators.',
            style: tt.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Spacings.lg),
          // Search bar
          GestureDetector(
            onTap: _navigateToSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: Spacings.borderRadiusLg,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: Spacings.mdIcon,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Search resources...',
                    style: tt.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.xl,
        Spacings.lg,
        Spacings.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Featured Products ──────────────────────────────────────────────────

  Widget _buildFeaturedSection(MarketplaceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Featured Products', onSeeAll: () {
          // Navigate to all featured
        }),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            itemCount: state.featuredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
            itemBuilder: (context, index) {
              final product = state.featuredProducts[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => _navigateToProduct(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Trending Products ──────────────────────────────────────────────────

  Widget _buildTrendingSection(MarketplaceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Trending Now', onSeeAll: () {
          // Navigate to all trending
        }),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            itemCount: state.trendingProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
            itemBuilder: (context, index) {
              final product = state.trendingProducts[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => _navigateToProduct(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Categories Grid ────────────────────────────────────────────────────

  Widget _buildCategoriesSection(MarketplaceState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Browse Categories', onSeeAll: () {
          // Show all categories
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isMobile ? 2 : 4,
              mainAxisSpacing: Spacings.md,
              crossAxisSpacing: Spacings.md,
              childAspectRatio: 1.8,
            ),
            itemCount: state.categories.length > 8
                ? 8
                : state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return _CategoryCard(
                category: category,
                isDark: isDark,
                cs: cs,
                tt: tt,
                onTap: () =>
                    _navigateToCategory(category.id, category.name),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Recommended Products ───────────────────────────────────────────────

  Widget _buildRecommendedSection(MarketplaceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recommended for You', onSeeAll: () {
          // Navigate to all recommended
        }),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          itemCount: state.recommendedProducts.length > 5
              ? 5
              : state.recommendedProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
          itemBuilder: (context, index) {
            final product = state.recommendedProducts[index];
            return ProductCard(
              product: product,
              onTap: () => _navigateToProduct(product.id),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CATEGORY CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.cs,
    required this.tt,
    required this.onTap,
  });

  final MarketplaceCategoryEntity category;
  final bool isDark;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _categoryIcon,
            size: Spacings.lgIcon,
            color: cs.primary,
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            category.name,
            style: tt.labelMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData get _categoryIcon {
    final name = category.name.toLowerCase();
    if (name.contains('question') || name.contains('exam')) {
      return Icons.quiz_rounded;
    }
    if (name.contains('lesson') || name.contains('note')) {
      return Icons.note_rounded;
    }
    if (name.contains('template')) {
      return Icons.assignment_rounded;
    }
    if (name.contains('worksheet')) {
      return Icons.table_chart_rounded;
    }
    if (name.contains('video') || name.contains('media')) {
      return Icons.play_circle_rounded;
    }
    if (name.contains('science') || name.contains('lab')) {
      return Icons.science_rounded;
    }
    if (name.contains('curriculum')) {
      return Icons.folder_special_rounded;
    }
    if (name.contains('flashcard')) {
      return Icons.style_rounded;
    }
    return Icons.category_rounded;
  }
}
