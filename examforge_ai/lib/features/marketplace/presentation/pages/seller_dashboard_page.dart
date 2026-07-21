import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/seller_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/marketplace_notification_provider.dart';
import '../widgets/marketplace_widgets.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// SELLER DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Seller's control center with tabs for Overview, Products, Analytics,
/// and Earnings.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => SellerDashboardPage()));
/// ```
class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
    Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
    Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
    Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Earnings'),
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
    final sellerNotifier = ref.read(sellerProvider.notifier);
    await Future.wait([
      sellerNotifier.loadSellerProfile(userId: 'current_user'),
      sellerNotifier.loadSellerProducts(sellerId: 'current_seller'),
      sellerNotifier.loadSellerAnalytics(sellerId: 'current_seller'),
      ref
          .read(marketplaceNotificationProvider.notifier)
          .loadNotifications(userId: 'current_user'),
    ]);
  }

  Future<void> _refresh() async {
    final sellerNotifier = ref.read(sellerProvider.notifier);
    await Future.wait([
      sellerNotifier.loadSellerProfile(userId: 'current_user'),
      sellerNotifier.loadSellerProducts(sellerId: 'current_seller'),
      sellerNotifier.loadSellerAnalytics(sellerId: 'current_seller'),
      ref
          .read(marketplaceNotificationProvider.notifier)
          .loadNotifications(userId: 'current_user'),
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
    final sellerState = ref.watch(sellerProvider);
    final notifState = ref.watch(marketplaceNotificationProvider);

    // Listen for error/success messages
    ref.listen<SellerState>(sellerProvider, (prev, next) {
      if (next.error != null && (prev?.error != next.error)) {
        _showSnackBar(next.error!, isError: true);
        ref.read(sellerProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          (prev?.successMessage != next.successMessage)) {
        _showSnackBar(next.successMessage!);
        ref.read(sellerProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Seller Dashboard',
        actions: [
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
      body: sellerState.isLoading && sellerState.products.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : sellerState.error != null && sellerState.products.isEmpty
              ? AppErrorState.serverError(onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(state: sellerState),
                      _ProductsTab(state: sellerState),
                      _AnalyticsTab(state: sellerState),
                      _EarningsTab(state: sellerState),
                    ],
                  ),
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});

  final SellerState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      children: [
        const SizedBox(height: Spacings.lg),

        // Seller profile section
        _SellerProfileHeader(profile: state.sellerProfile),

        const SizedBox(height: Spacings.xl),

        // Stats row
        _buildStatsRow(context),

        const SizedBox(height: Spacings.xl),

        // Revenue chart placeholder
        _buildRevenueChartPlaceholder(context),

        const SizedBox(height: Spacings.xl),

        // Recent orders
        _buildRecentOrdersSection(context),

        const SizedBox(height: Spacings.xl),

        // Recent reviews
        _buildRecentReviewsSection(context),

        const SizedBox(height: Spacings.xl),

        // Quick actions
        _buildQuickActionsSection(context),

        const SizedBox(height: Spacings.xxl),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppStatCard(
                  title: 'Total Revenue',
                  value: '₦${_formatNumber(state.totalRevenue)}',
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppStatCard(
                  title: 'Total Sales',
                  value: '${state.totalSales}',
                  icon: Icons.shopping_cart_rounded,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Expanded(
                child: AppStatCard(
                  title: 'Active Products',
                  value: '${state.totalProducts}',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppStatCard(
                  title: 'Avg. Rating',
                  value: state.averageRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: AppColors.error,
                  trendValue: state.averageRating >= 4.0
                      ? 'Great'
                      : 'Needs work',
                  trend: state.averageRating >= 4.0
                      ? TrendDirection.up
                      : TrendDirection.neutral,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'Total Revenue',
            value: '₦${_formatNumber(state.totalRevenue)}',
            icon: Icons.payments_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Total Sales',
            value: '${state.totalSales}',
            icon: Icons.shopping_cart_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Active Products',
            value: '${state.totalProducts}',
            icon: Icons.inventory_2_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Avg. Rating',
            value: state.averageRating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChartPlaceholder(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Simple bar chart using containers
    final bars = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 1.0];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue This Week',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xl),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (index) {
                final isHighest = bars[index] == bars.reduce(
                  (a, b) => a > b ? a : b,
                );
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: bars[index],
                            child: Container(
                              decoration: BoxDecoration(
                                color: isHighest
                                    ? cs.primary
                                    : cs.primary.withOpacity(isDark ? 0.30 : 0.20,
                                      ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(Spacings.smRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        Text(
                          labels[index],
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all orders
              },
              child: Text(
                'View All',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        // Placeholder for recent orders (would come from order provider)
        AppInfoCard(
          icon: Icons.receipt_long_rounded,
          title: 'No Recent Orders',
          subtitle: 'Orders will appear here when customers purchase your products.',
        ),
      ],
    );
  }

  Widget _buildRecentReviewsSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        AppInfoCard(
          icon: Icons.rate_review_rounded,
          title: 'No Reviews Yet',
          subtitle: 'Reviews from buyers will appear here.',
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: AppActionCard(
                title: 'Add New Product',
                subtitle: 'Create a new listing',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.info,
                onTap: () {
                  // Navigate to create product page
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Row(
          children: [
            Expanded(
              child: AppActionCard(
                title: 'View All Products',
                subtitle: 'Manage your listings',
                icon: Icons.inventory_2_outlined,
                color: AppColors.warning,
                onTap: () {
                  // Switch to products tab
                },
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppActionCard(
                title: 'Quality Check',
                subtitle: 'Run AI quality review',
                icon: Icons.verified_outlined,
                color: AppColors.success,
                onTap: () {
                  // Navigate to quality check
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLER PROFILE HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SellerProfileHeader extends StatelessWidget {
  const _SellerProfileHeader({this.profile});

  final SellerProfileEntity? profile;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final displayName = profile?.displayName ?? 'Seller';
    final isVerified = profile?.isVerified ?? false;
    final avatarUrl = profile?.avatarUrl;

    return AppCard(
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor:
                cs.primary.withOpacity(isDark ? 0.20 : 0.12),
            child: avatarUrl == null
                ? Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: tt.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wBold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: Spacings.lg),
          // Name and verification
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: Spacings.sm),
                      Icon(
                        Icons.verified_rounded,
                        size: Spacings.mdIcon,
                        color: AppColors.info,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  isVerified
                      ? 'Verified Seller'
                      : profile?.isPendingVerification == true
                          ? 'Pending Verification'
                          : 'Seller',
                  style: tt.bodySmall?.copyWith(
                    color: isVerified ? AppColors.info : cs.onSurfaceVariant,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ],
            ),
          ),
          // Edit Profile button
          AppButton(
            label: 'Edit Profile',
            onPressed: () {
              // Navigate to edit profile
            },
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
            icon: Icons.edit_rounded,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab({required this.state});

  final SellerState state;

  @override
  ConsumerState<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  /// `null` means "All" (no filter); otherwise filter by specific status.
  MarketplaceProductStatus? _filter;

  static const _filterOptions = <(MarketplaceProductStatus?, String, IconData)>[
    (null, 'All', Icons.list_rounded),
    (MarketplaceProductStatus.draft, 'Draft', Icons.edit_note_rounded),
    (MarketplaceProductStatus.pendingReview, 'Pending', Icons.hourglass_top_rounded),
    (MarketplaceProductStatus.approved, 'Approved', Icons.check_circle_rounded),
    (MarketplaceProductStatus.rejected, 'Rejected', Icons.cancel_rounded),
  ];

  List<MarketplaceProductEntity> get _filteredProducts {
    if (_filter == null) return widget.state.products;
    return widget.state.products
        .where((p) => p.status == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final products = _filteredProducts;

    return Scaffold(
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
              itemBuilder: (context, index) {
                final (status, label, icon) = _filterOptions[index];
                final isSelected = _filter == status;

                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: Spacings.smIcon),
                      const SizedBox(width: Spacings.xs),
                      Text(label),
                    ],
                  ),
                  onSelected: (_) {
                    setState(() => _filter = status);
                  },
                );
              },
            ),
          ),

          // Product list
          Expanded(
            child: products.isEmpty
                ? AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Products Found',
                    subtitle: 'Add your first product to start selling.',
                    actionLabel: 'Add Product',
                    onAction: () {
                      // Navigate to create product
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.lg,
                      vertical: Spacings.md,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.md),
                    itemBuilder: (context, index) {
                      return _SellerProductCard(product: products[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: AppFloatingActionButton(
        icon: Icons.add_rounded,
        label: 'Add Product',
        onPressed: () {
          // Navigate to create product page
        },
        extended: true,
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLER PRODUCT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SellerProductCard extends ConsumerWidget {
  const _SellerProductCard({required this.product});

  final MarketplaceProductEntity product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _statusColor;
    final typeColor = _productTypeColor(cs);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product type icon
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: ProductTypeIcon(
              type: product.productType,
              size: Spacings.lgIcon,
              color: typeColor,
            ),
          ),
          const SizedBox(width: Spacings.md),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(
                        product.status.label,
                        style: tt.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),

                // Price, sales, rating row
                Row(
                  children: [
                    Text(
                      product.isFree
                          ? 'Free'
                          : '₦${_formatNumber(product.price)}',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Icon(
                      Icons.shopping_cart_rounded,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${product.totalSales}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Icon(
                      Icons.star_rounded,
                      size: Spacings.smIcon,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),

                // Date
                Text(
                  'Updated ${_formatDate(product.updatedAt)}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Action overflow menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: cs.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusMd,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // Navigate to edit product
                  break;
                case 'status':
                  // Change product status
                  break;
                case 'quality':
                  // Run quality check
                  break;
                case 'delete':
                  _confirmDelete(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: Spacings.mdIcon),
                    SizedBox(width: Spacings.sm),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: Spacings.mdIcon),
                    SizedBox(width: Spacings.sm),
                    Text('Change Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quality',
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: Spacings.mdIcon),
                    SizedBox(width: Spacings.sm),
                    Text('Run Quality Check'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: Spacings.mdIcon,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Product',
      message:
          'Are you sure you want to delete "${product.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ref
          .read(sellerProvider.notifier)
          .deleteProduct(productId: product.id);
    }
  }

  Color get _statusColor {
    return switch (product.status) {
      MarketplaceProductStatus.draft => AppColors.onSurfaceVariant,
      MarketplaceProductStatus.pendingReview => AppColors.warning,
      MarketplaceProductStatus.approved => AppColors.success,
      MarketplaceProductStatus.rejected => AppColors.error,
      MarketplaceProductStatus.suspended => AppColors.error,
      MarketplaceProductStatus.archived => AppColors.onSurfaceVariant,
    };
  }

  Color _productTypeColor(ColorScheme cs) {
    return switch (product.productType) {
      MarketplaceProductType.questionBank => AppColors.info,
      MarketplaceProductType.examTemplate => AppColors.warning,
      MarketplaceProductType.lessonNote => AppColors.success,
      MarketplaceProductType.schemeOfWork => cs.primary,
      MarketplaceProductType.worksheet => AppColors.info,
      MarketplaceProductType.powerpoint => AppColors.error,
      MarketplaceProductType.teachingSlides => AppColors.warning,
      MarketplaceProductType.flashcards => AppColors.success,
      MarketplaceProductType.studyGuide => cs.primary,
      MarketplaceProductType.practicalManual => AppColors.info,
      MarketplaceProductType.laboratoryGuide => AppColors.success,
      MarketplaceProductType.curriculumPack => AppColors.warning,
      MarketplaceProductType.assessmentRubric => AppColors.error,
      MarketplaceProductType.homeworkPack => cs.primary,
      MarketplaceProductType.classroomActivity => AppColors.info,
      MarketplaceProductType.educationalImage => AppColors.success,
      MarketplaceProductType.educationalVideo => AppColors.error,
      MarketplaceProductType.educationalAudio => AppColors.warning,
      MarketplaceProductType.printableResource => cs.primary,
      MarketplaceProductType.other => AppColors.info,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANALYTICS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab({required this.state});

  final SellerState state;

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  int _dateRangeIndex = 1; // 0: 7d, 1: 30d, 2: 90d, 3: 1y
  static const _dateRangeLabels = ['7 Days', '30 Days', '90 Days', '1 Year'];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final analytics = widget.state.analytics;

    // Aggregate analytics values
    final totalViews = analytics.fold<int>(0, (sum, a) => sum + a.views);
    final totalSales = analytics.fold<int>(0, (sum, a) => sum + a.sales);
    final totalRevenue = analytics.fold<double>(0, (sum, a) => sum + a.revenue);
    final avgConversion = analytics.isEmpty
        ? 0.0
        : analytics.fold<double>(0, (sum, a) => sum + a.conversionRate) /
            analytics.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      children: [
        const SizedBox(height: Spacings.lg),

        // Date range selector
        SegmentedButton<int>(
          segments: List.generate(
            _dateRangeLabels.length,
            (i) => ButtonSegment(
              value: i,
              label: Text(_dateRangeLabels[i]),
            ),
          ),
          selected: {_dateRangeIndex},
          onSelectionChanged: (selected) {
            setState(() => _dateRangeIndex = selected.first);
          },
        ),

        const SizedBox(height: Spacings.xl),

        // Stats cards
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                title: 'Views',
                value: _formatNumber(totalViews.toDouble()),
                icon: Icons.visibility_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppStatCard(
                title: 'Sales',
                value: '$totalSales',
                icon: Icons.shopping_cart_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                title: 'Revenue',
                value: '₦${_formatNumber(totalRevenue)}',
                icon: Icons.payments_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppStatCard(
                title: 'Conversion Rate',
                value: '${avgConversion.toStringAsFixed(1)}%',
                icon: Icons.trending_up_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacings.xl),

        // Revenue trend chart placeholder
        AppCard(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Trend',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (index) {
                    final heights = [
                      0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.5, 0.9, 0.7, 1.0, 0.6, 0.8,
                    ];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.xs,
                        ),
                        child: FractionallySizedBox(
                          heightFactor: heights[index],
                          child: Container(
                            decoration: BoxDecoration(
                              color: heights[index] >= 0.9
                                  ? cs.primary
                                  : cs.primary.withOpacity(isDark ? 0.30 : 0.20,
                                    ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(Spacings.smRadius),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: Spacings.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  12,
                  (i) => Text(
                    'W${i + 1}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.xl),

        // Top performing products
        Text(
          'Top Performing Products',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        if (widget.state.products.isEmpty)
          AppInfoCard(
            icon: Icons.trending_up_rounded,
            title: 'No Data Yet',
            subtitle: 'Analytics data will appear once you have sales.',
          )
        else
          ...widget.state.products
              .take(5)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _TopProductRow(
              rank: index + 1,
              product: product,
            );
          }),

        const SizedBox(height: Spacings.xl),

        // Sales by product type breakdown
        Text(
          'Sales by Product Type',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        _ProductTypeBreakdown(products: widget.state.products),

        const SizedBox(height: Spacings.xxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP PRODUCT ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.rank,
    required this.product,
  });

  final int rank;
  final MarketplaceProductEntity product;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: AppInfoCard(
        icon: rank <= 3 ? Icons.emoji_events_rounded : Icons.inventory_2_rounded,
        iconColor: rank == 1
            ? AppColors.warning
            : rank == 2
                ? cs.onSurfaceVariant
                : rank == 3
                    ? AppColors.error
                    : cs.primary,
        title: '#$rank ${product.title}',
        subtitle:
            '${product.viewCount} views • ${product.totalSales} sales • ₦${_formatNumber(product.totalRevenue)}',
        trailing: Text(
          product.averageRating.toStringAsFixed(1),
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCT TYPE BREAKDOWN
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductTypeBreakdown extends StatelessWidget {
  const _ProductTypeBreakdown({required this.products});

  final List<MarketplaceProductEntity> products;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (products.isEmpty) {
      return AppInfoCard(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No Data',
        subtitle: 'Product type breakdown will appear with more products.',
      );
    }

    // Count products by type
    final typeCounts = <MarketplaceProductType, int>{};
    for (final p in products) {
      typeCounts[p.productType] = (typeCounts[p.productType] ?? 0) + 1;
    }

    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = sortedTypes.first.value;

    return AppCard(
      child: Column(
        children: sortedTypes.take(6).map((entry) {
          final percent = (entry.value / maxCount).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key.label,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: Spacings.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  '${entry.value}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EARNINGS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _EarningsTab extends StatelessWidget {
  const _EarningsTab({required this.state});

  final SellerState state;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final totalEarnings = state.totalRevenue;
    final commissionRecords = state.commissionRecords;
    final totalCommission = commissionRecords.fold<double>(
      0,
      (sum, r) => sum + r.commissionAmount,
    );
    final sellerRevenue = commissionRecords.fold<double>(
      0,
      (sum, r) => sum + r.sellerRevenue,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      children: [
        const SizedBox(height: Spacings.lg),

        // Total earnings card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.xl),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: Spacings.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Earnings',
                style: tt.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                '₦${_formatNumber(totalEarnings)}',
                style: tt.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.lg),

        // Available for withdrawal card
        AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(isDark ? 0.20 : 0.12,
                  ),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: Spacings.lgIcon,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available for Withdrawal',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      '₦${_formatNumber(sellerRevenue)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Withdraw',
                onPressed: null,
                variant: AppButtonVariant.tonal,
                size: AppButtonSize.small,
                icon: Icons.payment_rounded,
                isDisabled: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.xl),

        // Earnings breakdown
        Text(
          'Earnings Breakdown',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: AppCard(
                color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceVariantLight,
                child: Column(
                  children: [
                    Text(
                      'Platform Commission',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      '₦${_formatNumber(totalCommission)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppCard(
                color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceVariantLight,
                child: Column(
                  children: [
                    Text(
                      'Your Revenue',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      '₦${_formatNumber(sellerRevenue)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacings.xl),

        // Commission records
        Text(
          'Commission Records',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        if (commissionRecords.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No Commission Records',
            subtitle: 'Records will appear when you make sales.',
          )
        else
          ...commissionRecords.map((record) => _CommissionRecordCard(
                record: record,
              )),

        const SizedBox(height: Spacings.xl),

        // Withdraw button (disabled / coming soon)
        AppButton(
          label: 'Withdraw Funds (Coming Soon)',
          onPressed: null,
          variant: AppButtonVariant.elevated,
          fullWidth: true,
          icon: Icons.payment_rounded,
          isDisabled: true,
        ),

        const SizedBox(height: Spacings.xl),

        // Tax summary section
        Text(
          'Tax Summary',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        AppCard(
          child: Column(
            children: [
              _TaxSummaryRow(
                label: 'Year-to-Date Earnings',
                value: '₦${_formatNumber(totalEarnings)}',
              ),
              const SizedBox(height: Spacings.sm),
              _TaxSummaryRow(
                label: 'Commission Paid',
                value: '₦${_formatNumber(totalCommission)}',
              ),
              const SizedBox(height: Spacings.sm),
              _TaxSummaryRow(
                label: 'Net Earnings',
                value: '₦${_formatNumber(totalEarnings - totalCommission)}',
                isBold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.xxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMMISSION RECORD CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CommissionRecordCard extends StatelessWidget {
  const _CommissionRecordCard({required this.record});

  final CommissionRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.createdAt),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'Order #${record.orderItemId.substring(0, 8)}...',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₦${_formatNumber(record.commissionAmount)}',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                '+₦${_formatNumber(record.sellerRevenue)}',
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: AppTypography.wSemiBold,
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
// TAX SUMMARY ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _TaxSummaryRow extends StatelessWidget {
  const _TaxSummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: isBold ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: isBold ? AppTypography.wSemiBold : AppTypography.wRegular,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: isBold ? cs.onSurface : cs.onSurface,
            fontWeight: isBold ? AppTypography.wBold : AppTypography.wMedium,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Formats a numeric value with comma separators for thousands.
String _formatNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toInt().toString();
}

/// Formats a [DateTime] as a relative or short date string.
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
