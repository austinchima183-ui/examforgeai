import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/widgets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE ANALYTICS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Platform analytics page with tab-based navigation for Revenue, Products,
/// Sellers, and Users analytics.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => MarketplaceAnalyticsPage()),
/// );
/// ```
class MarketplaceAnalyticsPage extends ConsumerStatefulWidget {
  const MarketplaceAnalyticsPage({super.key});

  @override
  ConsumerState<MarketplaceAnalyticsPage> createState() =>
      _MarketplaceAnalyticsPageState();
}

class _MarketplaceAnalyticsPageState
    extends ConsumerState<MarketplaceAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _DateRange _selectedRange = _DateRange.days30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _AnalyticsTab.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Marketplace Analytics',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: context.isMobile,
          tabs: _AnalyticsTab.values
              .map((tab) => Tab(
                    text: tab.label,
                    icon: Icon(tab.icon),
                  ),)
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Date Range Selector ──────────────────────────────────────
          _DateRangeSelector(
            selectedRange: _selectedRange,
            onRangeChanged: (range) =>
                setState(() => _selectedRange = range),
          ),

          // ── Overview Stats ───────────────────────────────────────────
          const _OverviewStatsBar(),

          // ── Tab Content ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _RevenueTab(),
                _ProductsTab(),
                _SellersTab(),
                _UsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS & HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

enum _AnalyticsTab {
  revenue(label: 'Revenue', icon: Icons.attach_money_outlined),
  products(label: 'Products', icon: Icons.inventory_2_outlined),
  sellers(label: 'Sellers', icon: Icons.store_outlined),
  users(label: 'Users', icon: Icons.people_outlined);

  const _AnalyticsTab({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

enum _DateRange {
  days7(label: '7d', days: 7),
  days30(label: '30d', days: 30),
  days90(label: '90d', days: 90),
  days365(label: '1y', days: 365),
  custom(label: 'Custom', days: 0);

  const _DateRange({required this.label, required this.days});
  final String label;
  final int days;
}

String _formatCompactCurrency(double amount) {
  if (amount >= 1000000) return '₦${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '₦${(amount / 1000).toStringAsFixed(1)}K';
  return '₦${amount.toStringAsFixed(0)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATE RANGE SELECTOR
// ═══════════════════════════════════════════════════════════════════════════════

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final _DateRange selectedRange;
  final ValueChanged<_DateRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      color: cs.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _DateRange.values.map((range) {
            final isSelected = range == selectedRange;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ChoiceChip(
                label: Text(range.label),
                selected: isSelected,
                onSelected: (_) => onRangeChanged(range),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW STATS BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _OverviewStatsBar extends StatelessWidget {
  const _OverviewStatsBar();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: isMobile
          ? const Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        title: 'Total Products',
                        value: '1,247',
                        icon: Icons.inventory_2_outlined,
                        trend: TrendDirection.up,
                        trendValue: '+8.2%',
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(width: Spacings.sm),
                    Expanded(
                      child: AppStatCard(
                        title: 'Total Sellers',
                        value: '342',
                        icon: Icons.store_outlined,
                        trend: TrendDirection.up,
                        trendValue: '+12',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        title: 'Total Revenue',
                        value: '₦4.8M',
                        icon: Icons.attach_money_outlined,
                        trend: TrendDirection.up,
                        trendValue: '+15.3%',
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(width: Spacings.sm),
                    Expanded(
                      child: AppStatCard(
                        title: 'Total Orders',
                        value: '8,932',
                        icon: Icons.shopping_cart_outlined,
                        trend: TrendDirection.up,
                        trendValue: '+5.7%',
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        title: 'Avg. Rating',
                        value: '4.6',
                        icon: Icons.star_outlined,
                        trend: TrendDirection.neutral,
                        trendValue: '+0.1',
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(width: Spacings.sm),
                    Expanded(
                      child: AppStatCard(
                        title: 'Active Users',
                        value: '12.5K',
                        icon: Icons.people_outlined,
                        trend: TrendDirection.up,
                        trendValue: '+3.2%',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const Row(
              children: [
                Expanded(
                  child: AppStatCard(
                    title: 'Total Products',
                    value: '1,247',
                    icon: Icons.inventory_2_outlined,
                    trend: TrendDirection.up,
                    trendValue: '+8.2%',
                    color: AppColors.info,
                  ),
                ),
                SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppStatCard(
                    title: 'Total Sellers',
                    value: '342',
                    icon: Icons.store_outlined,
                    trend: TrendDirection.up,
                    trendValue: '+12',
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppStatCard(
                    title: 'Total Revenue',
                    value: '₦4.8M',
                    icon: Icons.attach_money_outlined,
                    trend: TrendDirection.up,
                    trendValue: '+15.3%',
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppStatCard(
                    title: 'Total Orders',
                    value: '8,932',
                    icon: Icons.shopping_cart_outlined,
                    trend: TrendDirection.up,
                    trendValue: '+5.7%',
                    color: AppColors.info,
                  ),
                ),
                SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppStatCard(
                    title: 'Avg. Rating',
                    value: '4.6',
                    icon: Icons.star_outlined,
                    trend: TrendDirection.neutral,
                    trendValue: '+0.1',
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppStatCard(
                    title: 'Active Users',
                    value: '12.5K',
                    icon: Icons.people_outlined,
                    trend: TrendDirection.up,
                    trendValue: '+3.2%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHART PLACEHOLDER WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

/// A colored container placeholder for chart sections.
class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.title,
    required this.height,
    this.child,
  }) : color = null;

  final String title;
  final double height;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final chartColor = color ?? cs.primaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: chartColor.withValues(alpha: context.isDarkMode ? 0.30 : 0.15),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: child ??
              Center(
                child: Text(
                  '$title Chart',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVENUE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Revenue Trend Chart ────────────────────────────────────
          _ChartPlaceholder(
            title: 'Revenue Trend (Monthly)',
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: _BarChartPlaceholder(
                values: const [0.4, 0.55, 0.65, 0.5, 0.75, 0.85],
                labels: const ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'],
                color: cs.primary,
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Revenue by Source ─────────────────────────────────────
          Text(
            'Revenue by Source',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          const _RevenueSourceCard(
            label: 'Product Sales',
            amount: 3200000,
            percentage: 66.7,
            color: AppColors.info,
          ),
          const SizedBox(height: Spacings.sm),
          const _RevenueSourceCard(
            label: 'AI Credits',
            amount: 960000,
            percentage: 20.0,
            color: AppColors.success,
          ),
          const SizedBox(height: Spacings.sm),
          const _RevenueSourceCard(
            label: 'Commissions',
            amount: 640000,
            percentage: 13.3,
            color: AppColors.warning,
          ),
          Spacings.sectionGap,

          // ── Top Earning Categories ────────────────────────────────
          Text(
            'Top Earning Categories',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('Question Banks', '₦1.2M', 0.38),
            ('Exam Templates', '₦980K', 0.31),
            ('Lesson Notes', '₦640K', 0.20),
            ('Worksheets', '₦320K', 0.10),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: _CategoryBar(
                  label: item.$1,
                  value: item.$2,
                  fraction: item.$3,
                  color: cs.primary,
                ),
              ),),
          Spacings.sectionGap,

          // ── Revenue by License Type ───────────────────────────────
          const _ChartPlaceholder(
            title: 'Revenue by License Type',
            height: 120,
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LicenseTypeChip(
                    label: 'Personal',
                    value: '₦1.4M',
                    color: AppColors.info,
                  ),
                  _LicenseTypeChip(
                    label: 'Teacher',
                    value: '₦1.2M',
                    color: AppColors.success,
                  ),
                  _LicenseTypeChip(
                    label: 'School',
                    value: '₦1.1M',
                    color: AppColors.warning,
                  ),
                  _LicenseTypeChip(
                    label: 'Enterprise',
                    value: '₦1.0M',
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }
}

class _RevenueSourceCard extends StatelessWidget {
  const _RevenueSourceCard({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double amount;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                _formatCompactCurrency(amount),
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6.0,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            '${percentage.toStringAsFixed(1)}% of total revenue',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6.0,
                backgroundColor: cs.surfaceContainerHighest,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          SizedBox(
            width: 60,
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseTypeChip extends StatelessWidget {
  const _LicenseTypeChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          child: Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: Spacings.xs),
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
// PRODUCTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Products by Type Distribution ──────────────────────────
          _ChartPlaceholder(
            title: 'Products by Type',
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: _DonutPlaceholder(
                segments: [
                  const _DonutSegment(label: 'Question Banks', value: 0.30, color: AppColors.info),
                  const _DonutSegment(label: 'Exam Templates', value: 0.25, color: AppColors.success),
                  const _DonutSegment(label: 'Lesson Notes', value: 0.20, color: AppColors.warning),
                  const _DonutSegment(label: 'Worksheets', value: 0.15, color: AppColors.error),
                  _DonutSegment(label: 'Other', value: 0.10, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Products by Status ─────────────────────────────────────
          Text(
            'Products by Status',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              const _StatusChip(
                label: 'Approved',
                count: 892,
                color: AppColors.success,
              ),
              const _StatusChip(
                label: 'Pending',
                count: 156,
                color: AppColors.warning,
              ),
              const _StatusChip(
                label: 'Rejected',
                count: 43,
                color: AppColors.error,
              ),
              _StatusChip(
                label: 'Draft',
                count: 156,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
          Spacings.sectionGap,

          // ── Most Viewed Products ───────────────────────────────────
          Text(
            'Most Viewed Products',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('WAEC Physics Question Bank', '3,240 views', Icons.visibility_outlined),
            ('JAMB Maths Prep Pack', '2,891 views', Icons.visibility_outlined),
            ('NECO Biology Study Guide', '2,156 views', Icons.visibility_outlined),
            ('SSCE Chemistry Exam Pack', '1,987 views', Icons.visibility_outlined),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppInfoCard(
                  title: item.$1,
                  subtitle: item.$2,
                  icon: item.$3,
                  iconColor: AppColors.info,
                ),
              ),),
          Spacings.sectionGap,

          // ── Most Downloaded Products ───────────────────────────────
          Text(
            'Most Downloaded Products',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('WAEC Physics Question Bank', '1,452 downloads', Icons.download_outlined),
            ('JAMB Maths Prep Pack', '1,203 downloads', Icons.download_outlined),
            ('Primary 5 Math Worksheets', '987 downloads', Icons.download_outlined),
            ('SSCE English Past Questions', '876 downloads', Icons.download_outlined),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppInfoCard(
                  title: item.$1,
                  subtitle: item.$2,
                  icon: item.$3,
                  iconColor: AppColors.success,
                ),
              ),),
          Spacings.sectionGap,

          // ── Category Performance ───────────────────────────────────
          Text(
            'Category Performance',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('Science', '₦1.8M', 0.45),
            ('Mathematics', '₦1.4M', 0.35),
            ('English', '₦980K', 0.24),
            ('Social Studies', '₦420K', 0.11),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: _CategoryBar(
                  label: item.$1,
                  value: item.$2,
                  fraction: item.$3,
                  color: cs.primary,
                ),
              ),),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            count.toString(),
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SellersTab extends StatelessWidget {
  const _SellersTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller Growth Chart ────────────────────────────────────
          const _ChartPlaceholder(
            title: 'Seller Growth',
            height: 180,
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: _BarChartPlaceholder(
                values: [0.3, 0.4, 0.5, 0.55, 0.65, 0.8],
                labels: ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'],
                color: AppColors.success,
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Top Sellers by Revenue ─────────────────────────────────
          Text(
            'Top Sellers by Revenue',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('Dr. Adebayo Ogundimu', '₦842K', '156 products', 1),
            ('Prof. Chika Nwosu', '₦654K', '98 products', 2),
            ('Mrs. Funke Alakija', '₦523K', '72 products', 3),
            ('Mr. Emeka Eze', '₦412K', '65 products', 4),
            ('Dr. Ngozi Okafor', '₦389K', '58 products', 5),
          ].map((seller) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppInfoCard(
                  title: '${seller.$4}. ${seller.$1}',
                  subtitle: '${seller.$3} · ${seller.$2}',
                  icon: Icons.store_outlined,
                  iconColor: seller.$4 <= 3
                      ? AppColors.warning
                      : cs.onSurfaceVariant,
                ),
              ),),
          Spacings.sectionGap,

          // ── Seller Status Distribution ─────────────────────────────
          Text(
            'Seller Status Distribution',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          const Row(
            children: [
              Expanded(
                child: AppStatCard(
                  title: 'Active',
                  value: '285',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: Spacings.sm),
              Expanded(
                child: AppStatCard(
                  title: 'Suspended',
                  value: '12',
                  icon: Icons.block_outlined,
                  color: AppColors.error,
                ),
              ),
              SizedBox(width: Spacings.sm),
              Expanded(
                child: AppStatCard(
                  title: 'Pending',
                  value: '45',
                  icon: Icons.schedule_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          Spacings.sectionGap,

          // ── Average Seller Metrics ─────────────────────────────────
          Text(
            'Average Seller Metrics',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          const AppCard(
            child: Column(
              children: [
                _MetricRow(
                  label: 'Avg. Products per Seller',
                  value: '3.6',
                ),
                Divider(height: Spacings.lg),
                _MetricRow(
                  label: 'Avg. Revenue per Seller',
                  value: '₦14.0K',
                ),
                Divider(height: Spacings.lg),
                _MetricRow(
                  label: 'Avg. Rating',
                  value: '4.4 ★',
                ),
                Divider(height: Spacings.lg),
                _MetricRow(
                  label: 'Avg. Response Time',
                  value: '2.3 hrs',
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buyer Growth Chart ─────────────────────────────────────
          const _ChartPlaceholder(
            title: 'Buyer Growth',
            height: 180,
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: _BarChartPlaceholder(
                values: [0.35, 0.5, 0.6, 0.7, 0.8, 0.9],
                labels: ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'],
                color: AppColors.info,
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Purchase Frequency ─────────────────────────────────────
          const _ChartPlaceholder(
            title: 'Purchase Frequency Distribution',
            height: 140,
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FrequencyBar(label: '1', fraction: 0.45, color: AppColors.info),
                  _FrequencyBar(label: '2-3', fraction: 0.30, color: AppColors.success),
                  _FrequencyBar(label: '4-5', fraction: 0.15, color: AppColors.warning),
                  _FrequencyBar(label: '6+', fraction: 0.10, color: AppColors.error),
                ],
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Average Order Value Trend ──────────────────────────────
          const _ChartPlaceholder(
            title: 'Average Order Value Trend',
            height: 140,
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: _BarChartPlaceholder(
                values: [0.6, 0.55, 0.65, 0.7, 0.68, 0.75],
                labels: ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'],
                color: AppColors.warning,
              ),
            ),
          ),
          Spacings.sectionGap,

          // ── Top Buyers ─────────────────────────────────────────────
          Text(
            'Top Buyers',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            ('Lagos State School District', '₦342K', '28 orders'),
            ('Abuja Federal College', '₦256K', '19 orders'),
            ('River State Academy', '₦198K', '15 orders'),
            ('Ogun State Schools', '₦145K', '12 orders'),
            ('Kano Education Board', '₦124K', '10 orders'),
          ].map((buyer) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppInfoCard(
                  title: buyer.$1,
                  subtitle: '${buyer.$3} · ${buyer.$2}',
                  icon: Icons.person_outlined,
                  iconColor: AppColors.info,
                ),
              ),),
          Spacings.sectionGap,

          // ── Retention Rate ─────────────────────────────────────────
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Retention Rate',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      '72.3%',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: AppColors.successOf(cs.brightness),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  child: LinearProgressIndicator(
                    value: 0.723,
                    minHeight: 10.0,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: AppColors.successOf(cs.brightness),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MetricRow(
                      label: '30-Day Retention',
                      value: '72.3%',
                    ),
                    _MetricRow(
                      label: '90-Day Retention',
                      value: '58.1%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHART PLACEHOLDER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Simple bar chart placeholder using containers.
class _BarChartPlaceholder extends StatelessWidget {
  const _BarChartPlaceholder({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: values.map((v) {
              return Container(
                width: 32,
                height: (v * 120).clamp(8, 120).toDouble(),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Spacings.smRadius),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels
              .map((l) => SizedBox(
                    width: 32,
                    child: Text(
                      l,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),)
              .toList(),
        ),
      ],
    );
  }
}

/// Simple donut chart placeholder using containers.
class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _DonutPlaceholder extends StatelessWidget {
  const _DonutPlaceholder({required this.segments});

  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Row(
      children: [
        // ── Donut circle ───────────────────────────────────────────
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments),
          ),
        ),
        const SizedBox(width: Spacings.lg),

        // ── Legend ──────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((seg) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.xs),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: seg.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        '${seg.label} (${(seg.value * 100).toStringAsFixed(0)}%)',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = -3.141592653589793 / 2; // Start from top

    for (final seg in segments) {
      final sweepAngle = seg.value * 2 * 3.141592653589793;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      segments != oldDelegate.segments;
}

/// Simple frequency bar for purchase distribution.
class _FrequencyBar extends StatelessWidget {
  const _FrequencyBar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final barHeight = (fraction * 80).clamp(8, 80).toDouble();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Spacings.smRadius),
            ),
          ),
        ),
        const SizedBox(height: Spacings.xs),
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
