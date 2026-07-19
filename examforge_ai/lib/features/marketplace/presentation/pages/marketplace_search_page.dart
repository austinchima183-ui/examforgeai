import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'product_detail_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE SEARCH PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Search and filter page for marketplace products.
///
/// Features auto-focus search bar, debounced search (300ms), filter chips,
/// sort dropdown, responsive results grid, and bottom sheet filter panel.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceSearchPage()));
/// ```
class MarketplaceSearchPage extends ConsumerStatefulWidget {
  const MarketplaceSearchPage({super.key});

  @override
  ConsumerState<MarketplaceSearchPage> createState() =>
      _MarketplaceSearchPageState();
}

class _MarketplaceSearchPageState extends ConsumerState<MarketplaceSearchPage> {
  late TextEditingController _searchController;
  Timer? _debounce;
  String _selectedSortBy = 'relevance';

  // Filter state
  MarketplaceProductType? _selectedType;
  String? _selectedSubject;
  String? _selectedClassLevel;
  String? _selectedCurriculum;

  static const List<String> _sortOptions = [
    'relevance',
    'newest',
    'price_low',
    'price_high',
    'rating',
    'popular',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  void _loadInitialData() {
    ref.read(marketplaceProvider.notifier).loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        ref.read(marketplaceProvider.notifier).searchProducts(query.trim());
      } else {
        // Clear search results when query is empty
        ref.read(marketplaceProvider.notifier).loadProducts();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    _debounce?.cancel();
    if (query.trim().isNotEmpty) {
      ref.read(marketplaceProvider.notifier).searchProducts(query.trim());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(marketplaceProvider.notifier).loadProducts();
  }

  void _showFilterBottomSheet() {
    final state = ref.read(marketplaceProvider);
    FilterBottomSheet.show(
      context,
      categories: state.categories,
      selectedType: _selectedType,
      selectedSubject: _selectedSubject,
      selectedClassLevel: _selectedClassLevel,
      selectedCurriculum: _selectedCurriculum,
      onApply: (category, type, subject, classLevel, curriculum, minPrice, maxPrice) {
        setState(() {
          _selectedType = type;
          _selectedSubject = subject;
          _selectedClassLevel = classLevel;
          _selectedCurriculum = curriculum;
        });
        // Apply filters and search
        final notifier = ref.read(marketplaceProvider.notifier);
        if (category != null) {
          notifier.filterByCategory(category.id);
        }
        if (type != null) {
          notifier.filterByType(type);
        }
        // Re-trigger search with current query
        if (_searchController.text.trim().isNotEmpty) {
          notifier.searchProducts(_searchController.text.trim());
        }
      },
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

    final searchResults = state.isSearching
        ? state.searchResults
        : state.products;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Search',
        isSearchMode: true,
        searchController: _searchController,
        searchHint: 'Search resources, subjects, types...',
        onSearchChanged: _onSearchChanged,
        onSearchSubmitted: _onSearchSubmitted,
        onSearchToggle: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // ── Filter Chips Row ───────────────────────────────────────────
          _buildFilterChipsRow(state, cs, tt),

          // ── Results ────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? _buildShimmerGrid()
                : searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsGrid(searchResults),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips Row ───────────────────────────────────────────────────

  Widget _buildFilterChipsRow(
    MarketplaceState state,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filter button
            GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: Spacings.smIcon,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'Filters',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacings.sm),

            // Category chips
            ...state.categories.take(5).map((category) {
              final isSelected = state.selectedCategory == category.id;
              return Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(marketplaceProvider.notifier).filterByCategory(
                      isSelected ? null : category.id,
                    );
                  },
                ),
              );
            }),

            // Type chip
            if (_selectedType != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: Chip(
                  label: Text(_selectedType!.label),
                  onDeleted: () {
                    setState(() => _selectedType = null);
                    ref.read(marketplaceProvider.notifier).filterByType(null);
                  },
                  deleteIconColor: cs.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),

            // Class level chip
            if (_selectedClassLevel != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: Chip(
                  label: Text(_selectedClassLevel!),
                  onDeleted: () {
                    setState(() => _selectedClassLevel = null);
                  },
                  deleteIconColor: cs.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),

            // Curriculum chip
            if (_selectedCurriculum != null)
              Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: Chip(
                  label: Text(_selectedCurriculum!),
                  onDeleted: () {
                    setState(() => _selectedCurriculum = null);
                  },
                  deleteIconColor: cs.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Sort & Results Header ──────────────────────────────────────────────

  Widget _buildSortHeader(int resultCount) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$resultCount result${resultCount != 1 ? 's' : ''}',
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
      'relevance' => 'Relevance',
      'newest' => 'Newest',
      'price_low' => 'Price: Low to High',
      'price_high' => 'Price: High to Low',
      'rating' => 'Highest Rated',
      'popular' => 'Most Popular',
      _ => key,
    };
  }

  // ─── Shimmer Grid ──────────────────────────────────────────────────────

  Widget _buildShimmerGrid() {
    final crossAxisCount = context.isMobile ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Spacings.md,
        crossAxisSpacing: Spacings.md,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const AppLoadingShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLoadingShimmer.box(height: 140),
              SizedBox(height: Spacings.sm),
              AppLoadingShimmer.box(height: 14, width: 160),
              SizedBox(height: Spacings.xs),
              AppLoadingShimmer.box(height: 12, width: 100),
              SizedBox(height: Spacings.sm),
              AppLoadingShimmer.box(height: 14, width: 80),
            ],
          ),
        );
      },
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return EmptyMarketplaceState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      subtitle: _searchController.text.trim().isNotEmpty
          ? 'No products match "${_searchController.text.trim()}". Try different keywords or filters.'
          : 'Try adjusting your search or filters.',
      actionLabel: _searchController.text.trim().isNotEmpty ? 'Clear Search' : null,
      onAction: _searchController.text.trim().isNotEmpty ? _clearSearch : null,
    );
  }

  // ─── Results Grid ───────────────────────────────────────────────────────

  Widget _buildResultsGrid(List<MarketplaceProductEntity> results) {
    final crossAxisCount = context.isMobile ? 2 : 3;

    return Column(
      children: [
        _buildSortHeader(results.length),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(Spacings.lg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: Spacings.md,
              crossAxisSpacing: Spacings.md,
              childAspectRatio: 0.65,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final product = results[index];
              return ProductCard(
                product: product,
                onTap: () => _navigateToProduct(product.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
