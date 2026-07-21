import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BILLING MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Revenue and billing oversight page for the Enterprise Super Admin Platform.
///
/// Displays revenue overview KPIs, revenue by billing model breakdown,
/// failed payments, refunds, pending invoices, revenue trends, and
/// recent transactions.
///
/// Follows the standard ExamForge AI page pattern:
/// - [ConsumerStatefulWidget] + private state class
/// - `initState` → `addPostFrameCallback` → `_loadData()` via `ref.read`
/// - `ref.watch(provider)` in `build()` for reactive rebuilds
/// - Loading → Error → Content pattern
/// - Design tokens everywhere
class BillingManagementPage extends ConsumerStatefulWidget {
  const BillingManagementPage({super.key});

  @override
  ConsumerState<BillingManagementPage> createState() =>
      _BillingManagementPageState();
}

class _BillingManagementPageState
    extends ConsumerState<BillingManagementPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(billingManagementProvider.notifier).loadRevenueAnalytics();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingManagementProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Billing & Revenue'),
      body: _buildBody(context, billingState, cs),
    );
  }

  // ─── Body: Loading → Error → Content ────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    BillingManagementState state,
    ColorScheme cs,
  ) {
    // Loading state
    if (state.isLoading && state.revenueAnalytics == null) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    // Error state
    if (state.error != null && state.revenueAnalytics == null) {
      return _buildErrorState(state);
    }

    // Content
    final analytics = state.revenueAnalytics;
    if (analytics == null) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(billingManagementProvider.notifier)
          .loadRevenueAnalytics(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Overview
            SectionHeader(title: 'Revenue Overview'),
            Spacings.itemGap,
            _buildRevenueOverview(analytics, cs),
            Spacings.sectionGap,

            // Revenue by Billing Model
            SectionHeader(title: 'Revenue by Billing Model'),
            Spacings.itemGap,
            _buildRevenueByBillingModel(analytics, cs),
            Spacings.sectionGap,

            // Billing Alerts Row
            SectionHeader(title: 'Billing Alerts'),
            Spacings.itemGap,
            _buildBillingAlerts(analytics, cs),
            Spacings.sectionGap,

            // Revenue Trends
            SectionHeader(title: 'Revenue Trends'),
            Spacings.itemGap,
            _buildRevenueTrends(analytics, cs),
            Spacings.sectionGap,

            // Recent Transactions
            SectionHeader(title: 'Recent Transactions'),
            Spacings.itemGap,
            _buildRecentTransactions(analytics, cs),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(BillingManagementState state) {
    return Center(
      child: Padding(
        padding: Spacings.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: Spacings.lg),
            Text(
              'Failed to load billing data',
              style: AppTypography.wSemiBold.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              state.error ?? 'An unexpected error occurred.',
              style: AppTypography.wRegular.copyWith(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.xl),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Revenue Overview ───────────────────────────────────────────────────

  Widget _buildRevenueOverview(RevenueAnalytics analytics, ColorScheme cs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 3;
        } else if (width >= 700) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final cards = <Widget>[
          MetricCard(
            title: 'Total Revenue',
            value: _formatCurrency(analytics.totalRevenue),
            icon: Icons.account_balance_wallet,
            color: AppColors.success,
            trend: analytics.growthRate > 0
                ? '+${analytics.growthRate.toStringAsFixed(1)}%'
                : '${analytics.growthRate.toStringAsFixed(1)}%',
            trendIsUp: analytics.growthRate > 0,
          ),
          MetricCard(
            title: 'Monthly Recurring Revenue',
            value: _formatCurrency(analytics.monthlyRecurringRevenue),
            icon: Icons.trending_up,
            color: cs.primary,
            subtitle: 'MRR',
          ),
          MetricCard(
            title: 'ARPU',
            value: _formatCurrency(analytics.averageRevenuePerUser),
            icon: Icons.person_outline,
            color: Colors.teal,
            subtitle: 'Average Revenue Per User',
          ),
          MetricCard(
            title: 'ARPS',
            value: _formatCurrency(analytics.averageRevenuePerSchool),
            icon: Icons.school_outlined,
            color: Colors.deepPurple,
            subtitle: 'Average Revenue Per School',
          ),
          MetricCard(
            title: 'Churn Rate',
            value: '${analytics.churnRate.toStringAsFixed(1)}%',
            icon: Icons.person_off,
            color: analytics.churnRate > 5 ? AppColors.error : AppColors.warning,
            trend: analytics.churnRate <= 2 ? 'Low' : analytics.churnRate <= 5 ? 'Medium' : 'High',
            trendIsUp: analytics.churnRate <= 2,
          ),
          MetricCard(
            title: 'Growth Rate',
            value: '${analytics.growthRate.toStringAsFixed(1)}%',
            icon: Icons.rocket_launch,
            color: analytics.growthRate > 0 ? AppColors.success : AppColors.error,
            trend: analytics.growthRate > 0 ? 'Growing' : 'Declining',
            trendIsUp: analytics.growthRate > 0,
          ),
        ];

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.1,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          children: cards,
        );
      },
    );
  }

  // ─── Revenue by Billing Model ───────────────────────────────────────────

  Widget _buildRevenueByBillingModel(RevenueAnalytics analytics, ColorScheme cs) {
    final modelData = analytics.revenueByBillingModel;
    if (modelData.isEmpty) {
      return const AdminEmptyState(
        message: 'No billing model data available.',
        icon: Icons.pie_chart_outline,
      );
    }

    // Extract billing model entries
    final entries = <_BillingModelEntry>[];
    double maxValue = 0;

    modelData.forEach((key, value) {
      final amount = (value is num) ? value.toDouble() : 0.0;
      if (amount > maxValue) maxValue = amount;
      entries.add(_BillingModelEntry(
        name: _formatModelName(key),
        revenue: amount,
        color: _modelColor(entries.length),
      ));
    });

    if (maxValue == 0) maxValue = 1; // Prevent division by zero

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          children: entries.map((entry) {
            final percentage = (entry.revenue / maxValue * 100).clamp(0, 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: entry.color,
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: AppTypography.wSemiBold.copyWith(fontSize: 13),
                        ),
                      ),
                      Text(
                        _formatCurrency(entry.revenue),
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.sm),
                  ClipRRect(
                    borderRadius: Spacings.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: entry.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _modelColor(int index) {
    const colors = [
      AppColors.success,
      AppColors.info,
      Colors.deepPurple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  String _formatModelName(String key) {
    // Convert snake_case or camelCase to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'[_\s]|(?<=[a-z])(?=[A-Z])'),
          (match) => ' ',
        )
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }

  // ─── Billing Alerts ─────────────────────────────────────────────────────

  Widget _buildBillingAlerts(RevenueAnalytics analytics, ColorScheme cs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = width >= 900 ? 3 : (width >= 500 ? 2 : 1);

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.3,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          children: [
            _buildAlertCard(
              title: 'Failed Payments',
              value: '${analytics.failedPayments}',
              icon: Icons.error_outline,
              color: analytics.failedPayments > 0 ? AppColors.error : AppColors.success,
              subtitle: analytics.failedPayments > 0
                  ? 'Requires attention'
                  : 'No issues',
              cs: cs,
            ),
            _buildAlertCard(
              title: 'Refunds This Month',
              value: _formatCurrency(analytics.refundsThisMonth),
              icon: Icons.money_off,
              color: analytics.refundsThisMonth > 0
                  ? AppColors.warning
                  : AppColors.success,
              subtitle: analytics.refundsThisMonth > 0
                  ? 'Total refund amount'
                  : 'No refunds',
              cs: cs,
            ),
            _buildAlertCard(
              title: 'Pending Invoices',
              value: '${analytics.pendingInvoices}',
              icon: Icons.receipt_long,
              color: analytics.pendingInvoices > 10
                  ? AppColors.warning
                  : cs.primary,
              subtitle: analytics.pendingInvoices > 0
                  ? 'Awaiting payment'
                  : 'All cleared',
              cs: cs,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(icon, color: color, size: Spacings.mdIcon),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              value,
              style: AppTypography.wBold.copyWith(
                fontSize: 22,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              title,
              style: AppTypography.wSemiBold.copyWith(
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              subtitle,
              style: AppTypography.wRegular.copyWith(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Revenue Trends ─────────────────────────────────────────────────────

  Widget _buildRevenueTrends(RevenueAnalytics analytics, ColorScheme cs) {
    final monthlyData = analytics.revenueByMonth;
    if (monthlyData.isEmpty) {
      return const AdminEmptyState(
        message: 'No revenue trend data available.',
        icon: Icons.show_chart,
      );
    }

    // Find max revenue for scaling bars
    double maxRevenue = 0;
    for (final entry in monthlyData) {
      final revenue = (entry['revenue'] is num)
          ? (entry['revenue'] as num).toDouble()
          : 0.0;
      if (revenue > maxRevenue) maxRevenue = revenue;
    }
    if (maxRevenue == 0) maxRevenue = 1;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar chart visualization
            SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barCount = monthlyData.length;
                  final barWidth =
                      (constraints.maxWidth - (barCount - 1) * Spacings.sm) /
                          barCount;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyData.map((entry) {
                      final revenue = (entry['revenue'] is num)
                          ? (entry['revenue'] as num).toDouble()
                          : 0.0;
                      final heightPercent =
                          (revenue / maxRevenue).clamp(0.05, 1.0);
                      final month =
                          (entry['month'] as String?) ?? '—';

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.xs),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Revenue label
                              Text(
                                _formatCompactCurrency(revenue),
                                style: AppTypography.wSemiBold.copyWith(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: Spacings.xs),
                              // Bar
                              Container(
                                height: heightPercent * 140,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.8),
                                  borderRadius: const BorderRadius.only(
                                    topLeft:
                                        Radius.circular(Spacings.smRadius / 2),
                                    topRight:
                                        Radius.circular(Spacings.smRadius / 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacings.xs),
                              // Month label
                              Text(
                                _shortMonth(month),
                                style: AppTypography.wRegular.copyWith(
                                  fontSize: 10,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortMonth(String month) {
    // Expecting format like "2024-01" or "Jan 2024"
    if (month.length >= 7 && month.contains('-')) {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final parts = month.split('-');
      final m = int.tryParse(parts[1]) ?? 0;
      return m > 0 && m < 13 ? '${months[m]} ${parts[0].substring(2)}' : month;
    }
    return month.length > 6 ? month.substring(0, 6) : month;
  }

  // ─── Recent Transactions ────────────────────────────────────────────────

  Widget _buildRecentTransactions(RevenueAnalytics analytics, ColorScheme cs) {
    final monthlyData = analytics.revenueByMonth;
    if (monthlyData.isEmpty) {
      return const AdminEmptyState(
        message: 'No transaction data available.',
        icon: Icons.receipt,
      );
    }

    // Show recent monthly entries as a transaction-like table
    final recentEntries = monthlyData.length > 12
        ? monthlyData.sublist(monthlyData.length - 12)
        : monthlyData;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: Spacings.xl,
          headingRowHeight: 48,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          columns: [
            DataColumn(
              label: Text('Period',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12)),
            ),
            DataColumn(
              label: Text('Revenue',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Growth',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Status',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12)),
            ),
          ],
          rows: recentEntries.map((entry) {
            final revenue = (entry['revenue'] is num)
                ? (entry['revenue'] as num).toDouble()
                : 0.0;
            final month = (entry['month'] as String?) ?? '—';
            final growth = (entry['growth'] is num)
                ? (entry['growth'] as num).toDouble()
                : null;
            final transactionCount = (entry['transaction_count'] is num)
                ? (entry['transaction_count'] as num).toInt()
                : null;

            final isPositive = growth != null && growth >= 0;
            final statusColor =
                isPositive ? AppColors.success : AppColors.error;

            return DataRow(cells: [
              DataCell(
                Text(month,
                    style:
                        AppTypography.wRegular.copyWith(fontSize: 13)),
              ),
              DataCell(
                Text(_formatCurrency(revenue),
                    style: AppTypography.wSemiBold.copyWith(
                        fontSize: 13, color: cs.onSurface)),
              ),
              DataCell(
                Text(
                  growth != null
                      ? '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%'
                      : '—',
                  style: AppTypography.wSemiBold.copyWith(
                    fontSize: 13,
                    color: growth != null ? statusColor : cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.check_circle : Icons.warning_amber,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      transactionCount != null
                          ? '$transactionCount txn'
                          : (isPositive ? 'Healthy' : 'Review'),
                      style: AppTypography.wRegular.copyWith(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─── Formatting Helpers ─────────────────────────────────────────────────

  /// Formats a double as Naira currency with comma separators.
  static String _formatCurrency(double n) {
    final formatted = n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₦$formatted';
  }

  /// Compact currency format for bar chart labels (e.g. "₦1.2M").
  static String _formatCompactCurrency(double n) {
    if (n >= 1000000) {
      return '₦${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '₦${(n / 1000).toStringAsFixed(0)}K';
    }
    return '₦${n.toStringAsFixed(0)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BILLING MODEL ENTRY — Data class for billing model bars
// ═══════════════════════════════════════════════════════════════════════════════

class _BillingModelEntry {
  const _BillingModelEntry({
    required this.name,
    required this.revenue,
    required this.color,
  });

  final String name;
  final double revenue;
  final Color color;
}
