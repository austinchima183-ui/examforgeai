import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/moderation_provider.dart';
import '../widgets/marketplace_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE MODERATION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin moderation page with tab-based navigation for managing
/// pending products, reported reviews, sellers, and disputes.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => MarketplaceModerationPage()),
/// );
/// ```
class MarketplaceModerationPage extends ConsumerStatefulWidget {
  const MarketplaceModerationPage({super.key});

  @override
  ConsumerState<MarketplaceModerationPage> createState() =>
      _MarketplaceModerationPageState();
}

class _MarketplaceModerationPageState
    extends ConsumerState<MarketplaceModerationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _ModerationTab.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final notifier = ref.read(moderationProvider.notifier);
    await Future.wait([
      notifier.loadPendingProducts(),
      notifier.loadSellers(),
      notifier.loadDisputes(),
    ]);
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

  // ─── Stats Bar ────────────────────────────────────────────────────────

  Widget _buildStatsBar(ModerationState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          _StatChip(
            label: 'Pending Products',
            count: state.pendingProducts.length,
            color: AppColors.warning,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(width: Spacings.lg),
          _StatChip(
            label: 'Open Disputes',
            count: state.openDisputeCount,
            color: AppColors.error,
            icon: Icons.gavel_outlined,
          ),
          const SizedBox(width: Spacings.lg),
          _StatChip(
            label: 'Reported Reviews',
            count: state.reportedReviews.length,
            color: AppColors.info,
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationProvider);

    // Listen for error/success messages
    ref.listen<ModerationState>(moderationProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(moderationProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        _showSnackBar(next.successMessage!);
        ref.read(moderationProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Moderation',
        bottom: TabBar(
          controller: _tabController,
          tabs: _ModerationTab.values
              .map((tab) => Tab(
                    text: tab.label,
                    icon: Icon(tab.icon),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Stats bar ───────────────────────────────────────────────
          _buildStatsBar(state),

          // ── Tab content ─────────────────────────────────────────────
          Expanded(
            child: state.isLoading && state.pendingProducts.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Pending Products ────────────────────────────
                      _PendingProductsTab(
                        products: state.pendingProducts,
                        isLoading: state.isLoading,
                      ),

                      // ── Reported Reviews ────────────────────────────
                      _ReportedReviewsTab(
                        reviews: state.reportedReviews,
                        isLoading: state.isLoading,
                      ),

                      // ── Sellers ─────────────────────────────────────
                      _SellersTab(
                        sellers: state.sellers,
                        isLoading: state.isLoading,
                      ),

                      // ── Disputes ────────────────────────────────────
                      _DisputesTab(
                        disputes: state.disputes,
                        isLoading: state.isLoading,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODERATION TAB ENUM (internal)
// ═══════════════════════════════════════════════════════════════════════════════

enum _ModerationTab {
  pendingProducts(label: 'Products', icon: Icons.inventory_2_outlined),
  reportedReviews(label: 'Reviews', icon: Icons.rate_review_outlined),
  sellers(label: 'Sellers', icon: Icons.storefront_outlined),
  disputes(label: 'Disputes', icon: Icons.gavel_outlined);

  const _ModerationTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CHIP (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.20 : 0.12),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Icon(icon, size: Spacings.smIcon, color: color),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          '$count',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PENDING PRODUCTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PendingProductsTab extends ConsumerWidget {
  const _PendingProductsTab({
    required this.products,
    required this.isLoading,
  });

  final List<MarketplaceProductEntity> products;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty && !isLoading) {
      return AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Pending Products',
        subtitle: 'All products have been reviewed.',
      );
    }

    return Column(
      children: [
        // Bulk actions
        if (products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Approve All',
                    onPressed: () async {
                      final confirmed = await AppDialog.showConfirm(
                        context: context,
                        title: 'Approve All Products?',
                        message:
                            'This will approve ${products.length} pending products.',
                        confirmText: 'Approve All',
                      );
                      if (confirmed == true) {
                        for (final p in products) {
                          await ref
                              .read(moderationProvider.notifier)
                              .approveProduct(
                                productId: p.id,
                                moderatorId: 'admin',
                              );
                        }
                      }
                    },
                    variant: AppButtonVariant.tonal,
                    icon: Icons.check_circle_outline,
                    size: AppButtonSize.small,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppButton(
                    label: 'Reject All',
                    onPressed: () async {
                      final confirmed = await AppDialog.showConfirm(
                        context: context,
                        title: 'Reject All Products?',
                        message:
                            'This will reject ${products.length} pending products.',
                        confirmText: 'Reject All',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        for (final p in products) {
                          await ref
                              .read(moderationProvider.notifier)
                              .rejectProduct(
                                productId: p.id,
                                reason: 'Bulk rejection',
                                moderatorId: 'admin',
                              );
                        }
                      }
                    },
                    variant: AppButtonVariant.outlined,
                    icon: Icons.cancel_outlined,
                    size: AppButtonSize.small,
                  ),
                ),
              ],
            ),
          ),

        // Product list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(moderationProvider.notifier).loadPendingProducts(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Spacings.md),
              itemBuilder: (context, index) {
                final product = products[index];
                return _PendingProductCard(product: product);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PENDING PRODUCT CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _PendingProductCard extends ConsumerWidget {
  const _PendingProductCard({required this.product});

  final MarketplaceProductEntity product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: info ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: ProductTypeIcon(
                  type: product.productType,
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: Spacings.smIcon,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          product.sellerId,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        LicenseBadge(licenseType: product.licenseType),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceDisplay(
                    price: product.price,
                    currency: product.currency,
                    isFree: product.isFree,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    _formatDate(product.createdAt),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Product type badge ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.infoLight.withOpacity(isDark ? 0.15 : 1.0),
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Text(
              product.productType.label,
              style: tt.labelSmall?.copyWith(
                color: AppColors.info,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              AppIconButton(
                icon: Icons.visibility_outlined,
                onPressed: () {
                  // Open product detail preview
                },
                tooltip: 'Preview',
                variant: AppIconButtonVariant.outlined,
              ),
              const Spacer(),
              AppButton(
                label: 'Approve',
                onPressed: () async {
                  final confirmed = await AppDialog.showConfirm(
                    context: context,
                    title: 'Approve Product?',
                    message:
                        '"${product.title}" will be published to the marketplace.',
                    confirmText: 'Approve',
                  );
                  if (confirmed == true) {
                    ref.read(moderationProvider.notifier).approveProduct(
                          productId: product.id,
                          moderatorId: 'admin',
                        );
                  }
                },
                variant: AppButtonVariant.tonal,
                icon: Icons.check_rounded,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Reject',
                onPressed: () => _showRejectDialog(context, ref),
                variant: AppButtonVariant.outlined,
                icon: Icons.close_rounded,
                size: AppButtonSize.small,
                // Red-tinted outlined button
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    AppDialog.showCustom(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject Product',
              style: ctx.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: ctx.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'Provide a reason for rejecting "${product.title}":',
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.md),
            AppTextField(
              controller: reasonController,
              label: 'Reason',
              hint: 'Enter rejection reason',
              maxLines: 3,
              minLines: 2,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(),
                  variant: AppButtonVariant.text,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Reject',
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;
                    Navigator.of(ctx).pop();
                    ref.read(moderationProvider.notifier).rejectProduct(
                          productId: product.id,
                          reason: reason,
                          moderatorId: 'admin',
                        );
                  },
                  variant: AppButtonVariant.elevated,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTED REVIEWS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportedReviewsTab extends ConsumerWidget {
  const _ReportedReviewsTab({
    required this.reviews,
    required this.isLoading,
  });

  final List<MarketplaceReviewEntity> reviews;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reviews.isEmpty && !isLoading) {
      return AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Reported Reviews',
        subtitle: 'All reviews are in good standing.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Reload moderation data
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacings.lg),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return _ReportedReviewCard(review: review);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPORTED REVIEW CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportedReviewCard extends ConsumerWidget {
  const _ReportedReviewCard({required this.review});

  final MarketplaceReviewEntity review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reviewer row ───────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    cs.primary.withOpacity(isDark ? 0.30 : 0.15),
                child: Text(
                  review.buyerId.isNotEmpty
                      ? review.buyerId[0].toUpperCase()
                      : '?',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.buyerId,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    StarRating(
                      rating: review.rating.toDouble(),
                      starSize: Spacings.smIcon,
                      showCount: false,
                    ),
                  ],
                ),
              ),
              // Report count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorLight.withOpacity(isDark ? 0.15 : 1.0),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: Spacings.smIcon,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${review.reportCount}',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Review excerpt ─────────────────────────────────────────
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Text(
              review.content!,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: Spacings.lg),

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Keep',
                  onPressed: () {
                    ref.read(moderationProvider.notifier).moderateReview(
                          reviewId: review.id,
                          status: MarketplaceReviewStatus.published,
                        );
                  },
                  variant: AppButtonVariant.tonal,
                  icon: Icons.check_rounded,
                  size: AppButtonSize.small,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppButton(
                  label: 'Hide',
                  onPressed: () {
                    ref.read(moderationProvider.notifier).moderateReview(
                          reviewId: review.id,
                          status: MarketplaceReviewStatus.hidden,
                        );
                  },
                  variant: AppButtonVariant.outlined,
                  icon: Icons.visibility_off_rounded,
                  size: AppButtonSize.small,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppButton(
                  label: 'Remove',
                  onPressed: () async {
                    final confirmed = await AppDialog.showConfirm(
                      context: context,
                      title: 'Remove Review?',
                      message:
                          'This review will be permanently removed.',
                      confirmText: 'Remove',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      ref.read(moderationProvider.notifier).moderateReview(
                            reviewId: review.id,
                            status: MarketplaceReviewStatus.hidden,
                          );
                    }
                  },
                  variant: AppButtonVariant.outlined,
                  icon: Icons.delete_outline_rounded,
                  size: AppButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SellersTab extends ConsumerStatefulWidget {
  const _SellersTab({
    required this.sellers,
    required this.isLoading,
  });

  final List<SellerProfileEntity> sellers;
  final bool isLoading;

  @override
  ConsumerState<_SellersTab> createState() => _SellersTabState();
}

class _SellersTabState extends ConsumerState<_SellersTab> {
  final _searchController = TextEditingController();
  _SellerFilter _filter = _SellerFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SellerProfileEntity> get _filteredSellers {
    var sellers = widget.sellers;

    // Filter by status
    if (_filter != _SellerFilter.all) {
      sellers = sellers.where((s) => s.status == _filter.status).toList();
    }

    // Filter by search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      sellers = sellers
          .where((s) => s.displayName.toLowerCase().contains(query))
          .toList();
    }

    return sellers;
  }

  @override
  Widget build(BuildContext context) {
    final sellers = _filteredSellers;

    return Column(
      children: [
        // ── Search bar & filters ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              AppSearchField(
                controller: _searchController,
                hint: 'Search sellers...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Spacings.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _SellerFilter.values.map((filter) {
                    final isSelected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: Spacings.sm),
                      child: FilterChip(
                        label: Text(filter.label),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _filter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Seller list ──────────────────────────────────────────────
        Expanded(
          child: sellers.isEmpty && !widget.isLoading
              ? AppEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No Sellers Found',
                  subtitle: 'Try adjusting your search or filter.',
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(moderationProvider.notifier)
                      .loadSellers(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.lg),
                    itemCount: sellers.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.md),
                    itemBuilder: (context, index) {
                      return _SellerCard(seller: sellers[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLER FILTER ENUM (internal)
// ═══════════════════════════════════════════════════════════════════════════════

enum _SellerFilter {
  all(label: 'All', status: null),
  active(label: 'Active', status: MarketplaceSellerStatus.active),
  suspended(label: 'Suspended', status: MarketplaceSellerStatus.suspended),
  pending(label: 'Pending', status: MarketplaceSellerStatus.pendingVerification);

  const _SellerFilter({required this.label, required this.status});

  final String label;
  final MarketplaceSellerStatus? status;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLER CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _SellerCard extends ConsumerWidget {
  const _SellerCard({required this.seller});

  final SellerProfileEntity seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _statusColor(seller.status, cs);

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────────────────────
          CircleAvatar(
            radius: 24,
            backgroundColor:
                cs.primary.withOpacity(isDark ? 0.30 : 0.15),
            child: seller.displayName.isNotEmpty
                ? Text(
                    seller.displayName[0].toUpperCase(),
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wBold,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: cs.primary,
                  ),
          ),
          const SizedBox(width: Spacings.md),

          // ── Info column ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        seller.displayName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    _StatusBadge(status: seller.status, color: statusColor),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    _infoChip(
                      Icons.inventory_2_outlined,
                      '${seller.totalProducts} products',
                      cs.onSurfaceVariant,
                      tt,
                    ),
                    const SizedBox(width: Spacings.md),
                    _infoChip(
                      Icons.shopping_bag_outlined,
                      '${seller.totalSales} sales',
                      cs.onSurfaceVariant,
                      tt,
                    ),
                    const SizedBox(width: Spacings.md),
                    _infoChip(
                      Icons.star_rounded,
                      seller.averageRating.toStringAsFixed(1),
                      AppColors.warning,
                      tt,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Color _statusColor(MarketplaceSellerStatus status, ColorScheme cs) {
    switch (status) {
      case MarketplaceSellerStatus.active:
        return AppColors.success;
      case MarketplaceSellerStatus.suspended:
        return AppColors.error;
      case MarketplaceSellerStatus.pendingVerification:
        return AppColors.warning;
      case MarketplaceSellerStatus.deactivated:
        return cs.onSurfaceVariant;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
  });

  final MarketplaceSellerStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISPUTES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _DisputesTab extends ConsumerWidget {
  const _DisputesTab({
    required this.disputes,
    required this.isLoading,
  });

  final List<DisputeEntity> disputes;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (disputes.isEmpty && !isLoading) {
      return AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Open Disputes',
        subtitle: 'All disputes have been resolved.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(moderationProvider.notifier).loadDisputes(),
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacings.lg),
        itemCount: disputes.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
        itemBuilder: (context, index) {
          final dispute = disputes[index];
          return _DisputeCard(dispute: dispute);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISPUTE CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _DisputeCard extends ConsumerWidget {
  const _DisputeCard({required this.dispute});

  final DisputeEntity dispute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _disputeStatusColor(dispute.status, cs);

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Icon(
                  Icons.gavel_outlined,
                  size: Spacings.mdIcon,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${dispute.orderId.substring(0, 8)}',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      dispute.reason,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _DisputeStatusBadge(status: dispute.status, color: statusColor),
            ],
          ),

          // ── Description ────────────────────────────────────────────
          if (dispute.description != null &&
              dispute.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Text(
              dispute.description!,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Buyer / Seller row ─────────────────────────────────────
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              _infoChip(
                Icons.person_outline_rounded,
                'Buyer: ${dispute.buyerId.substring(0, 8)}',
                cs.onSurfaceVariant,
                tt,
              ),
              const SizedBox(width: Spacings.lg),
              _infoChip(
                Icons.storefront_outlined,
                'Seller: ${dispute.sellerId.substring(0, 8)}',
                cs.onSurfaceVariant,
                tt,
              ),
              const Spacer(),
              _infoChip(
                Icons.calendar_today_outlined,
                _formatDate(dispute.createdAt),
                cs.onSurfaceVariant,
                tt,
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              AppButton(
                label: 'View Details',
                onPressed: () {
                  // Navigate to dispute detail
                },
                variant: AppButtonVariant.text,
                icon: Icons.visibility_outlined,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              if (dispute.isOpen)
                AppButton(
                  label: 'Resolve',
                  onPressed: () =>
                      _showResolveDialog(context, ref),
                  variant: AppButtonVariant.tonal,
                  icon: Icons.check_circle_outline,
                  size: AppButtonSize.small,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Color _disputeStatusColor(DisputeStatus status, ColorScheme cs) {
    switch (status) {
      case DisputeStatus.open:
        return AppColors.error;
      case DisputeStatus.underReview:
        return AppColors.warning;
      case DisputeStatus.resolved:
        return AppColors.success;
      case DisputeStatus.closed:
        return cs.onSurfaceVariant;
    }
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    final resolutionController = TextEditingController();

    AppDialog.showCustom(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resolve Dispute',
              style: ctx.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: ctx.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'Enter the resolution for Order #${dispute.orderId.substring(0, 8)}:',
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.md),
            AppTextField(
              controller: resolutionController,
              label: 'Resolution',
              hint: 'Describe the resolution',
              maxLines: 4,
              minLines: 2,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(),
                  variant: AppButtonVariant.text,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Resolve',
                  onPressed: () {
                    final resolution = resolutionController.text.trim();
                    if (resolution.isEmpty) return;
                    Navigator.of(ctx).pop();
                    ref.read(moderationProvider.notifier).resolveDispute(
                          disputeId: dispute.id,
                          resolution: resolution,
                          resolvedBy: 'admin',
                        );
                  },
                  variant: AppButtonVariant.elevated,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISPUTE STATUS BADGE (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _DisputeStatusBadge extends StatelessWidget {
  const _DisputeStatusBadge({
    required this.status,
    required this.color,
  });

  final DisputeStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

String _formatDate(DateTime date) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}
