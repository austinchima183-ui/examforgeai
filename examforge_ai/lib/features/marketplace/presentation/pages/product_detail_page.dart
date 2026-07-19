import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/product_detail_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/marketplace_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Single product detail page with full product information, reviews,
/// quality checks, related products, and purchase actions.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => ProductDetailPage(productId: '123')),
/// );
/// ```
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  MarketplaceLicenseType _selectedLicense = MarketplaceLicenseType.personal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final notifier = ref.read(productDetailProvider.notifier);
    await notifier.loadProduct(productId: widget.productId);
    // Load supplementary data
    notifier.loadReviews(productId: widget.productId);
    notifier.loadQualityCheck(productId: widget.productId);
    notifier.loadRelatedProducts(productId: widget.productId);
    notifier.recordView(productId: widget.productId);
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

  Future<void> _addToCart() async {
    final product = ref.read(productDetailProvider).product;
    if (product == null) return;

    await ref.read(cartProvider.notifier).addToCart(
      userId: 'current_user',
      item: CartItemEntity(
        id: '',
        cartId: '',
        productId: product.id,
        licenseType: _selectedLicense,
        addedAt: DateTime.now(),
        product: product,
      ),
    );

    final cartState = ref.read(cartProvider);
    if (cartState.error != null) {
      _showSnackBar(cartState.error!, isError: true);
    } else if (cartState.successMessage != null) {
      _showSnackBar(cartState.successMessage!);
    }
  }

  void _buyNow() {
    // Navigate to checkout with this product
    _showSnackBar('Proceeding to checkout...');
  }

  void _toggleWishlist() {
    final product = ref.read(productDetailProvider).product;
    if (product == null) return;

    ref.read(productDetailProvider.notifier).toggleWishlist(
      userId: 'current_user',
      productId: product.id,
    );

    final state = ref.read(productDetailProvider);
    _showSnackBar(
      state.isInWishlist
          ? 'Added to wishlist'
          : 'Removed from wishlist',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider);

    // Listen for errors
    ref.listen<ProductDetailState>(productDetailProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(productDetailProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Product Details',
        actions: [
          AppIconButton(
            icon: Icons.share_rounded,
            onPressed: () {
              // Share product
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && !state.hasProduct
              ? AppErrorState.serverError(onRetry: _loadData)
              : state.hasProduct
                  ? _buildContent(state)
                  : AppErrorState.notFoundError(onRetry: _loadData),
      bottomNavigationBar:
          state.hasProduct ? _buildBottomBar(state) : null,
    );
  }

  // ─── Main Content ───────────────────────────────────────────────────────

  Widget _buildContent(ProductDetailState state) {
    final product = state.product!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Preview ──────────────────────────────────────────────
          _buildHeroPreview(product),

          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title & Badges ───────────────────────────────────────
                _buildTitleSection(product),

                const SizedBox(height: Spacings.lg),

                // ── Seller Info ──────────────────────────────────────────
                _buildSellerRow(product),

                const SizedBox(height: Spacings.lg),

                // ── Price & License Selector ─────────────────────────────
                _buildPriceAndLicense(product),

                const SizedBox(height: Spacings.lg),

                // ── Rating ───────────────────────────────────────────────
                _buildRatingSection(product),

                Spacings.sectionGap,

                // ── Description ──────────────────────────────────────────
                _buildDescription(product),

                Spacings.sectionGap,

                // ── Product Details ──────────────────────────────────────
                _buildProductDetails(product),

                Spacings.sectionGap,

                // ── Tags ─────────────────────────────────────────────────
                if (product.tags.isNotEmpty) ...[
                  _buildTags(product),
                  Spacings.sectionGap,
                ],

                // ── AI Summary ───────────────────────────────────────────
                if (product.aiGeneratedSummary != null) ...[
                  _buildAiSummary(product),
                  Spacings.sectionGap,
                ],

                // ── Quality Check ────────────────────────────────────────
                if (state.hasQualityCheck) ...[
                  QualityScoreCard(qualityCheck: state.qualityCheck!),
                  Spacings.sectionGap,
                ],

                // ── Preview Section ──────────────────────────────────────
                if (product.previewImages.isNotEmpty ||
                    product.previewDocuments.isNotEmpty) ...[
                  _buildPreviewSection(product),
                  Spacings.sectionGap,
                ],

                // ── Related Products ─────────────────────────────────────
                if (state.relatedProducts.isNotEmpty) ...[
                  _buildRelatedProducts(state),
                  Spacings.sectionGap,
                ],

                // ── Reviews ──────────────────────────────────────────────
                _buildReviewsSection(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Preview ───────────────────────────────────────────────────────

  Widget _buildHeroPreview(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final typeColor = _productTypeColor(product.productType, cs);

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: isDark ? 0.20 : 0.12),
      ),
      child: Stack(
        children: [
          Center(
            child: ProductTypeIcon(
              type: product.productType,
              size: 64,
              color: typeColor,
            ),
          ),
          // Badges
          Positioned(
            top: Spacings.md,
            left: Spacings.md,
            child: Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: [
                if (product.isFeatured)
                  _buildBadge('Featured', AppColors.warning, Colors.white),
                if (product.isFree)
                  _buildBadge('Free', AppColors.success, Colors.white),
                if (product.isAiGenerated)
                  _buildBadge('AI Generated', AppColors.info, Colors.white),
                if (product.isDiscounted)
                  _buildBadge(
                    '-${product.discountPercentage.toStringAsFixed(0)}%',
                    AppColors.error,
                    Colors.white,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: AppTypography.wBold,
          color: fg,
        ),
      ),
    );
  }

  // ─── Title Section ──────────────────────────────────────────────────────

  Widget _buildTitleSection(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product type badge
        Row(
          children: [
            ProductTypeIcon(type: product.productType, size: Spacings.smIcon),
            const SizedBox(width: Spacings.xs),
            Text(
              product.productType.label,
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            LicenseBadge(licenseType: product.licenseType),
          ],
        ),
        const SizedBox(height: Spacings.sm),

        // Title
        Text(
          product.title,
          style: tt.headlineSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Seller Row ─────────────────────────────────────────────────────────

  Widget _buildSellerRow(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.primary.withValues(alpha: isDark ? 0.30 : 0.15),
          child: Icon(
            Icons.person_rounded,
            size: Spacings.lgIcon,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      product.sellerId, // Placeholder for real seller name
                      style: tt.labelLarge?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Icon(
                    Icons.verified_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'View Profile',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Price & License Selector ────────────────────────────────────────────

  Widget _buildPriceAndLicense(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price display
        Row(
          children: [
            PriceDisplay(
              price: product.price,
              originalPrice: product.isDiscounted ? product.originalPrice : null,
              currency: product.currency,
              isFree: product.isFree,
              fontSize: 24,
            ),
            const Spacer(),
            if (product.downloadCount > 0) ...[
              Icon(
                Icons.download_rounded,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                _formatCount(product.downloadCount),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacings.lg),

        // License type selector
        Text(
          'License Type',
          style: tt.labelMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: MarketplaceLicenseType.values.map((type) {
            final isSelected = _selectedLicense == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedLicense = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: Text(
                  type.label,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: isSelected
                        ? AppTypography.wSemiBold
                        : AppTypography.wMedium,
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Rating Section ─────────────────────────────────────────────────────

  Widget _buildRatingSection(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        StarRating(
          rating: product.averageRating,
          totalReviews: product.totalReviews,
          starSize: Spacings.mdIcon,
          showCount: true,
        ),
        const SizedBox(width: Spacings.sm),
        Text(
          product.averageRating.toStringAsFixed(1),
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Description ────────────────────────────────────────────────────────

  Widget _buildDescription(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          product.description ?? 'No description available.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─── Product Details ────────────────────────────────────────────────────

  Widget _buildProductDetails(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        AppCard(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              _buildDetailRow('Type', product.productType.label, cs, tt),
              if (product.subject != null)
                _buildDetailRow('Subject', product.subject!, cs, tt),
              if (product.classLevel != null)
                _buildDetailRow('Class Level', product.classLevel!, cs, tt),
              if (product.curriculum != null)
                _buildDetailRow('Curriculum', product.curriculum!, cs, tt),
              if (product.language != null)
                _buildDetailRow('Language', product.language!, cs, tt),
              _buildDetailRow('Version', product.version, cs, tt),
              _buildDetailRow(
                'File Size',
                '${product.fullDocumentUrls.length} file(s)',
                cs,
                tt,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tags ───────────────────────────────────────────────────────────────

  Widget _buildTags(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: product.tags.map((tag) {
            return Chip(
              label: Text(tag),
              labelStyle: tt.labelSmall?.copyWith(color: cs.onSurface),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── AI Summary ─────────────────────────────────────────────────────────

  Widget _buildAiSummary(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'AI Summary',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.3),
            borderRadius: Spacings.borderRadiusMd,
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            product.aiGeneratedSummary!,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  // ─── Preview Section ────────────────────────────────────────────────────

  Widget _buildPreviewSection(MarketplaceProductEntity product) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        if (product.previewImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: product.previewImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: Spacings.xlIcon,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          'Preview ${index + 1}',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (product.previewDocuments.isNotEmpty) ...[
          const SizedBox(height: Spacings.md),
          ...product.previewDocuments.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: ListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: cs.primary,
                ),
                title: Text(
                  'Document Preview',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                ),
                trailing: Icon(
                  Icons.visibility_rounded,
                  color: cs.primary,
                  size: Spacings.mdIcon,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusSm,
                  side: BorderSide(color: cs.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ─── Related Products ───────────────────────────────────────────────────

  Widget _buildRelatedProducts(ProductDetailState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Products',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.relatedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
            itemBuilder: (context, index) {
              final product = state.relatedProducts[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () {
                    // Navigate to this related product
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          productId: product.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Reviews Section ────────────────────────────────────────────────────

  Widget _buildReviewsSection(ProductDetailState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final product = state.product!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with See All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            if (state.hasReviews)
              TextButton(
                onPressed: () {
                  // Navigate to full reviews page
                },
                child: Text(
                  'See All (${product.totalReviews})',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // Rating summary
        _buildRatingSummary(product, cs, tt),

        const SizedBox(height: Spacings.lg),

        // Individual reviews (show first 3)
        if (state.hasReviews)
          ...state.reviews.take(3).map((review) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: ReviewCard(
                review: review,
                onHelpful: () {
                  ref.read(productDetailProvider.notifier).voteReviewHelpful(
                    reviewId: review.id,
                    userId: 'current_user',
                  );
                },
              ),
            );
          })
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSummary(
    MarketplaceProductEntity product,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Row(
        children: [
          // Average rating circle
          Column(
            children: [
              Text(
                product.averageRating.toStringAsFixed(1),
                style: tt.headlineMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              StarRating(
                rating: product.averageRating,
                starSize: Spacings.smIcon,
                showCount: false,
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                '${product.totalReviews} reviews',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: Spacings.xl),

          // Rating bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                // Simplified: even distribution for demo
                final percentage = star == 5
                    ? 0.6
                    : star == 4
                        ? 0.25
                        : star == 3
                            ? 0.1
                            : star == 2
                                ? 0.03
                                : 0.02;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: Spacings.xs),
                      Icon(
                        Icons.star_rounded,
                        size: Spacings.smIcon,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHighest,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(ProductDetailState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Wishlist toggle
            GestureDetector(
              onTap: _toggleWishlist,
              child: Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Icon(
                  state.isInWishlist
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: state.isInWishlist ? AppColors.error : cs.onSurfaceVariant,
                  size: Spacings.mdIcon,
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),

            // Add to Cart
            Expanded(
              child: OutlinedButton(
                onPressed: state.product!.isFree ? null : _addToCart,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacings.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                ),
                child: Text(
                  state.product!.isFree ? 'Free' : 'Add to Cart',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),

            // Buy Now
            Expanded(
              child: FilledButton(
                onPressed: _buyNow,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacings.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                ),
                child: Text(
                  state.product!.isFree ? 'Download' : 'Buy Now',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Methods ─────────────────────────────────────────────────────

  Color _productTypeColor(MarketplaceProductType type, ColorScheme cs) {
    return switch (type) {
      MarketplaceProductType.questionBank ||
      MarketplaceProductType.examTemplate ||
      MarketplaceProductType.assessmentRubric =>
        AppColors.info,
      MarketplaceProductType.lessonNote ||
      MarketplaceProductType.schemeOfWork ||
      MarketplaceProductType.studyGuide =>
        AppColors.success,
      MarketplaceProductType.powerpoint ||
      MarketplaceProductType.teachingSlides =>
        AppColors.warning,
      MarketplaceProductType.flashcards ||
      MarketplaceProductType.worksheet ||
      MarketplaceProductType.homeworkPack =>
        cs.primary,
      MarketplaceProductType.practicalManual ||
      MarketplaceProductType.laboratoryGuide =>
        cs.tertiary,
      MarketplaceProductType.curriculumPack ||
      MarketplaceProductType.classroomActivity =>
        cs.secondary,
      MarketplaceProductType.educationalImage ||
      MarketplaceProductType.educationalVideo ||
      MarketplaceProductType.educationalAudio =>
        AppColors.error,
      MarketplaceProductType.printableResource => cs.primaryContainer,
      MarketplaceProductType.other => cs.onSurfaceVariant,
    };
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
