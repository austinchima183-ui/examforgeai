import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/seller_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/marketplace_notification_provider.dart';
import '../widgets/marketplace_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BUYER DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Buyer's personal dashboard with tabs for Purchases, Wishlist, Downloads,
/// and Saved items.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerDashboardPage()));
/// ```
class BuyerDashboardPage extends ConsumerStatefulWidget {
  const BuyerDashboardPage({super.key});

  @override
  ConsumerState<BuyerDashboardPage> createState() =>
      _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends ConsumerState<BuyerDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Purchases'),
    Tab(icon: Icon(Icons.favorite_outline), text: 'Wishlist'),
    Tab(icon: Icon(Icons.download_outlined), text: 'Downloads'),
    Tab(icon: Icon(Icons.bookmark_outline), text: 'Saved'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(purchaseProvider.notifier).loadPurchases(buyerId: 'current_user'),
      ref.read(marketplaceNotificationProvider.notifier).loadNotifications(userId: 'current_user'),
    ]);
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(purchaseProvider.notifier).loadPurchases(buyerId: 'current_user'),
      ref.read(marketplaceNotificationProvider.notifier).loadNotifications(userId: 'current_user'),
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

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final notifState = ref.watch(marketplaceNotificationProvider);

    // Listen for error/success messages
    ref.listen<PurchaseState>(purchaseProvider, (prev, next) {
      if (next.error != null && (prev?.error != next.error)) {
        _showSnackBar(next.error!, isError: true);
        ref.read(purchaseProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'My Dashboard',
        actions: [
          // Notification bell with unread count badge
          Stack(
            alignment: Alignment.center,
            children: [
              AppIconButton(
                icon: Icons.notifications_outlined,
                onPressed: () {
                  // Navigate to notifications
                },
                tooltip: 'Notifications',
              ),
              if (notifState.hasUnread)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifState.unreadCount}',
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: context.isMobile,
          labelStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: context.textTheme.labelMedium,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: purchaseState.isLoading && purchaseState.purchases.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PurchasesTab(purchases: purchaseState.purchases),
                  const _WishlistTab(),
                  _DownloadsTab(purchases: purchaseState.purchases),
                  const _SavedTab(),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PURCHASES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab({required this.purchases});

  final List<MarketplacePurchaseEntity> purchases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (purchases.isEmpty) {
      return AppEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Purchases Yet',
        subtitle: 'Browse the marketplace to find educational resources.',
        actionLabel: 'Browse Marketplace',
        onAction: () {
          // Navigate to marketplace
        },
      );
    }

    return CustomScrollView(
      slivers: [
        // Stats row
        SliverToBoxAdapter(child: _buildStatsRow(context)),
        // Purchase list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          sliver: SliverList.separated(
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
            itemBuilder: (context, index) {
              return _PurchaseCard(purchase: purchases[index]);
            },
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: Spacings.xxl),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final activeLicenses = purchases.where((p) => p.isAccessible).length;
    final totalDownloads = purchases.fold<int>(
      0,
      (sum, p) => sum + p.downloadCount,
    );

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Row(
        children: [
          Expanded(
            child: AppStatCard(
              title: 'Total Purchases',
              value: '${purchases.length}',
              icon: Icons.shopping_bag_rounded,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: AppStatCard(
              title: 'Active Licenses',
              value: '$activeLicenses',
              icon: Icons.verified_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: AppStatCard(
              title: 'Downloads',
              value: '$totalDownloads',
              icon: Icons.download_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PURCHASE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.purchase});

  final MarketplacePurchaseEntity purchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final licenseBadgeColor = _licenseBadgeColor;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: product type icon + title + license badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Icon(
                  Icons.description_rounded,
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
                      'Product ${purchase.productId.substring(0, 8)}...',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: Spacings.xs,
                          ),
                          decoration: BoxDecoration(
                            color: licenseBadgeColor.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          child: Text(
                            purchase.licenseType.label,
                            style: tt.labelSmall?.copyWith(
                              color: licenseBadgeColor,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        Text(
                          'Purchased ${_formatDate(purchase.createdAt)}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Download count and expiry
          Row(
            children: [
              Icon(
                Icons.download_rounded,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '${purchase.downloadCount} downloads',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (purchase.expiresAt != null) ...[
                Icon(
                  purchase.isExpired
                      ? Icons.event_busy_rounded
                      : Icons.event_available_rounded,
                  size: Spacings.smIcon,
                  color: purchase.isExpired ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  purchase.isExpired
                      ? 'Expired ${_formatDate(purchase.expiresAt!)}'
                      : 'Expires ${_formatDate(purchase.expiresAt!)}',
                  style: tt.bodySmall?.copyWith(
                    color: purchase.isExpired ? AppColors.error : AppColors.success,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.all_inclusive_rounded,
                  size: Spacings.smIcon,
                  color: AppColors.success,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Lifetime access',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ],
            ],
          ),

          // License key display (if available)
          if (purchase.licenseKey != null) ...[
            const SizedBox(height: Spacings.md),
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: Spacings.borderRadiusSm,
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: Spacings.smIcon,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      'License: ${purchase.licenseKey!}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      // Copy license key to clipboard
                    },
                    size: AppButtonSize.small,
                    tooltip: 'Copy',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: Spacings.md),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'View License',
                onPressed: () {
                  // Show license details
                },
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                icon: Icons.vpn_key_rounded,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Download',
                onPressed: purchase.isAccessible
                    ? () {
                        ref
                            .read(purchaseProvider.notifier)
                            .recordDownload(purchaseId: purchase.id);
                      }
                    : null,
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                icon: Icons.download_rounded,
                isDisabled: !purchase.isAccessible,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _licenseBadgeColor {
    return switch (purchase.licenseType) {
      MarketplaceLicenseType.personal => AppColors.info,
      MarketplaceLicenseType.teacher => AppColors.success,
      MarketplaceLicenseType.school => AppColors.warning,
      MarketplaceLicenseType.department => AppColors.warning,
      MarketplaceLicenseType.enterprise => AppColors.error,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WISHLIST TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _WishlistTab extends StatelessWidget {
  const _WishlistTab();

  @override
  Widget build(BuildContext context) {
    // Placeholder: in a real app, this would be wired to a wishlist provider.
    // Using an empty list for now; the provider integration would populate this.
    const wishlistItems = <MarketplaceProductEntity>[];

    if (wishlistItems.isEmpty) {
      return AppEmptyState(
        icon: Icons.favorite_outline,
        title: 'Your Wishlist is Empty',
        subtitle: 'Save products you love and get notified when prices drop.',
        actionLabel: 'Browse Products',
        onAction: () {
          // Navigate to marketplace
        },
      );
    }

    return CustomScrollView(
      slivers: [
        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: AppStatCard(
              title: 'Wishlist Items',
              value: '${wishlistItems.length}',
              icon: Icons.favorite_rounded,
              color: AppColors.error,
            ),
          ),
        ),
        // Grid of wishlisted products
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isMobile ? 2 : 3,
              mainAxisSpacing: Spacings.md,
              crossAxisSpacing: Spacings.md,
              childAspectRatio: 0.65,
            ),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final product = wishlistItems[index];
              return Stack(
                children: [
                  ProductCard(
                    product: product,
                    onTap: () {
                      // Navigate to product detail
                    },
                  ),
                  // Remove from wishlist button
                  Positioned(
                    top: Spacings.sm,
                    right: Spacings.sm,
                    child: AppIconButton(
                      icon: Icons.favorite_rounded,
                      onPressed: () {
                        // Remove from wishlist
                      },
                      variant: AppIconButtonVariant.tonal,
                      size: AppButtonSize.small,
                      color: AppColors.error,
                      tooltip: 'Remove from wishlist',
                    ),
                  ),
                  // Price drop indicator
                  if (product.isDiscounted)
                    Positioned(
                      bottom: Spacings.sm,
                      left: Spacings.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: Spacings.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          'Price dropped!',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: Spacings.xxl),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DOWNLOADS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _DownloadsTab extends StatelessWidget {
  const _DownloadsTab({required this.purchases});

  final List<MarketplacePurchaseEntity> purchases;

  @override
  Widget build(BuildContext context) {
    // Filter purchases that have been downloaded at least once
    final downloadedPurchases =
        purchases.where((p) => p.downloadCount > 0).toList();

    if (downloadedPurchases.isEmpty) {
      return AppEmptyState(
        icon: Icons.download_outlined,
        title: 'No Downloads Yet',
        subtitle: 'Download your purchased resources to view them here.',
        actionLabel: 'View Purchases',
        onAction: () {
          // Switch to purchases tab
        },
      );
    }

    // Group by date period
    final today = <MarketplacePurchaseEntity>[];
    final thisWeek = <MarketplacePurchaseEntity>[];
    final thisMonth = <MarketplacePurchaseEntity>[];
    final earlier = <MarketplacePurchaseEntity>[];
    final now = DateTime.now();

    for (final p in downloadedPurchases) {
      final downloadedAt = p.lastDownloadedAt ?? p.createdAt;
      final diff = now.difference(downloadedAt);

      if (diff.inDays == 0) {
        today.add(p);
      } else if (diff.inDays < 7) {
        thisWeek.add(p);
      } else if (diff.inDays < 30) {
        thisMonth.add(p);
      } else {
        earlier.add(p);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionHeader(context, 'Today'),
          ...today.map((p) => _DownloadItem(purchase: p)),
          const SizedBox(height: Spacings.lg),
        ],
        if (thisWeek.isNotEmpty) ...[
          _buildSectionHeader(context, 'This Week'),
          ...thisWeek.map((p) => _DownloadItem(purchase: p)),
          const SizedBox(height: Spacings.lg),
        ],
        if (thisMonth.isNotEmpty) ...[
          _buildSectionHeader(context, 'This Month'),
          ...thisMonth.map((p) => _DownloadItem(purchase: p)),
          const SizedBox(height: Spacings.lg),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionHeader(context, 'Earlier'),
          ...earlier.map((p) => _DownloadItem(purchase: p)),
        ],
        const SizedBox(height: Spacings.xxl),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Spacings.md,
        bottom: Spacings.sm,
      ),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DOWNLOAD ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class _DownloadItem extends StatelessWidget {
  const _DownloadItem({required this.purchase});

  final MarketplacePurchaseEntity purchase;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Icon(
              Icons.insert_drive_file_rounded,
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
                  'Product ${purchase.productId.substring(0, 8)}...',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Text(
                      _formatDate(
                        purchase.lastDownloadedAt ?? purchase.createdAt,
                      ),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      '•',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      '${purchase.downloadCount}x downloaded',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.download_rounded,
            onPressed: () {
              // Re-download
            },
            variant: AppIconButtonVariant.tonal,
            size: AppButtonSize.small,
            tooltip: 'Download again',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SAVED TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    // Placeholder: saved searches and recently viewed products.
    // In a real app, this would be wired to saved-search and recently-viewed providers.
    const savedSearches = <_SavedSearch>[];
    const recentlyViewed = <MarketplaceProductEntity>[];

    if (savedSearches.isEmpty && recentlyViewed.isEmpty) {
      return AppEmptyState(
        icon: Icons.bookmark_outline,
        title: 'Nothing Saved Yet',
        subtitle: 'Save searches and browse products to see them here.',
        actionLabel: 'Explore Marketplace',
        onAction: () {
          // Navigate to marketplace
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      children: [
        if (savedSearches.isNotEmpty) ...[
          _buildSectionHeader(context, 'Saved Searches'),
          ...savedSearches.map((s) => _SavedSearchCard(search: s)),
          const SizedBox(height: Spacings.xl),
        ],
        if (recentlyViewed.isNotEmpty) ...[
          _buildSectionHeader(context, 'Recently Viewed'),
          const SizedBox(height: Spacings.sm),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewed.length,
              separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: ProductCard(
                    product: recentlyViewed[index],
                    onTap: () {
                      // Navigate to product detail
                    },
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: Spacings.xxl),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Spacings.lg,
        bottom: Spacings.md,
      ),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SAVED SEARCH CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _SavedSearchCard extends StatelessWidget {
  const _SavedSearchCard({required this.search});

  final _SavedSearch search;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: Icon(
              Icons.search_rounded,
              size: Spacings.lgIcon,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  search.query,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  '${search.resultCount} results • Saved ${_formatDate(search.savedAt)}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Run Search',
            onPressed: () {
              // Execute the saved search
            },
            variant: AppButtonVariant.tonal,
            size: AppButtonSize.small,
            icon: Icons.search_rounded,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER: SAVED SEARCH DATA
// ═══════════════════════════════════════════════════════════════════════════════

/// Lightweight placeholder for saved search data.
/// In a real app, this would be a full entity from the domain layer.
class _SavedSearch {
  const _SavedSearch({
    required this.query,
    required this.resultCount,
    required this.savedAt,
  });

  final String query;
  final int resultCount;
  final DateTime savedAt;
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER: DATE FORMATTING
// ═══════════════════════════════════════════════════════════════════════════════

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays == 0) {
    if (diff.inHours == 0) {
      if (diff.inMinutes == 0) return 'Just now';
      return '${diff.inMinutes}m ago';
    }
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '${weeks}w ago';
  }
  return '${date.day}/${date.month}/${date.year}';
}
