import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/revenue_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// REVENUE DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Revenue analytics page (Super Admin).
///
/// Features metric cards, revenue chart placeholder, billing model
/// breakdown, and monthly trend data.
class RevenueDashboardPage extends ConsumerStatefulWidget {
  const RevenueDashboardPage({super.key});

  @override
  ConsumerState<RevenueDashboardPage> createState() =>
      _RevenueDashboardPageState();
}

class _RevenueDashboardPageState extends ConsumerState<RevenueDashboardPage> {
  String _periodType = 'monthly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    await Future.wait([
      ref.read(revenueProvider.notifier).loadDashboardSummary(),
      ref.read(revenueProvider.notifier).loadRevenueData(
            periodType: _periodType,
            startDate: startDate,
            endDate: endDate,
          ),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final revenueState = ref.watch(revenueProvider);

    return Scaffold(
      appBar: AppAppBar(title: 'Revenue Dashboard'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Period Selector ─────────────────────────────────────
              _buildPeriodSelector(),

              const SizedBox(height: Spacings.xl),

              // ── Metric Cards Grid ───────────────────────────────────
              _buildMetricCards(revenueState),

              const SizedBox(height: Spacings.xl),

              // ── Revenue Chart Placeholder ───────────────────────────
              _buildRevenueChart(revenueState),

              const SizedBox(height: Spacings.xl),

              // ── Billing Model Breakdown ─────────────────────────────
              _buildBillingModelBreakdown(revenueState),

              const SizedBox(height: Spacings.xl),

              // ── Monthly Trend Data ──────────────────────────────────
              _buildMonthlyTrend(revenueState),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Period Selector ─────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Text(
          'Period:',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'weekly', label: Text('Weekly')),
            ButtonSegment(value: 'monthly', label: Text('Monthly')),
            ButtonSegment(value: 'yearly', label: Text('Yearly')),
          ],
          selected: {_periodType},
          onSelectionChanged: (selection) {
            setState(() => _periodType = selection.first);
            _loadData();
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              AppTypography.buttonSmall.copyWith(fontFamily: AppTypography.fontFamily),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Metric Cards ────────────────────────────────────────────────────

  Widget _buildMetricCards(RevenueState revenueState) {
    if (revenueState.isLoading && !revenueState.hasRevenueData) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (revenueState.error != null && !revenueState.hasRevenueData) {
      return AppErrorState.genericError(
        message: revenueState.error,
        onRetry: _refresh,
      );
    }

    final latestData = revenueState.revenueData.isNotEmpty
        ? revenueState.revenueData.last
        : null;

    // Calculate totals from data
    double totalMrr = 0;
    double totalArr = 0;
    int activeSubs = 0;
    double avgChurn = 0;
    int trialConvs = 0;
    int aiCreditsSold = 0;

    if (latestData != null) {
      totalMrr = latestData.subscriptionRevenue;
      totalArr = totalMrr * 12;
      activeSubs = latestData.activeSubscriptions;
      avgChurn = latestData.churnRate;
      trialConvs = latestData.trialConversions;
      aiCreditsSold = latestData.aiCreditsSold;
    }

    final metrics = <_MetricData>[
      _MetricData(
        title: 'MRR',
        value: _formatCurrency(totalMrr),
        subtitle: 'Monthly Recurring Revenue',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      _MetricData(
        title: 'ARR',
        value: _formatCurrency(totalArr),
        subtitle: 'Annual Recurring Revenue',
        icon: Icons.show_chart_rounded,
        color: AppColors.info,
      ),
      _MetricData(
        title: 'Active Subscriptions',
        value: '$activeSubs',
        subtitle: 'Currently active',
        icon: Icons.subscriptions_rounded,
        color: AppColors.success,
      ),
      _MetricData(
        title: 'Churn Rate',
        value: '${avgChurn.toStringAsFixed(1)}%',
        subtitle: 'Monthly average',
        icon: Icons.trending_down_rounded,
        color: avgChurn > 5 ? AppColors.error : AppColors.warning,
      ),
      _MetricData(
        title: 'Trial Conversions',
        value: '$trialConvs',
        subtitle: 'This period',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _MetricData(
        title: 'AI Credits Sold',
        value: '$aiCreditsSold',
        subtitle: 'Credits sold this period',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFF97316),
      ),
      _MetricData(
        title: 'Total Revenue',
        value: _formatCurrency(latestData?.totalRevenue ?? 0),
        subtitle: 'Including all sources',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
      _MetricData(
        title: 'Net Revenue',
        value: _formatCurrency(latestData?.netRevenue ?? 0),
        subtitle: 'After fees & refunds',
        icon: Icons.savings_rounded,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return RevenueMetricCard(
          title: m.title,
          value: m.value,
          subtitle: m.subtitle,
          icon: m.icon,
          color: m.color,
        );
      },
    );
  }

  // ─── Revenue Chart Placeholder ───────────────────────────────────────

  Widget _buildRevenueChart(RevenueState revenueState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Trend',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Card(
          elevation: Spacings.elevationSm,
          shadowColor: cs.shadow.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusLg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              children: [
                if (revenueState.revenueData.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No revenue data available',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: _buildSimpleBarChart(revenueState),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Simple Bar Chart ────────────────────────────────────────────────

  Widget _buildSimpleBarChart(RevenueState revenueState) {
    final cs = context.colorScheme;
    final data = revenueState.revenueData.take(12).toList();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxRevenue =
        data.map((d) => d.totalRevenue).reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((point) {
        final height = (point.totalRevenue / maxRevenue) * 160;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height.clamp(4.0, 160.0),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  point.period.length > 3
                      ? point.period.substring(0, 3)
                      : point.period,
                  style: cs.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Billing Model Breakdown ─────────────────────────────────────────

  Widget _buildBillingModelBreakdown(RevenueState revenueState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final latestData = revenueState.revenueData.isNotEmpty
        ? revenueState.revenueData.last
        : null;

    if (latestData == null) return const SizedBox.shrink();

    final total = latestData.teacherSaasRevenue +
        latestData.schoolSaasRevenue +
        latestData.enterpriseSaasRevenue;

    if (total == 0) return const SizedBox.shrink();

    final models = <_BillingModelData>[
      _BillingModelData(
        label: 'Teacher SaaS',
        revenue: latestData.teacherSaasRevenue,
        color: AppColors.success,
      ),
      _BillingModelData(
        label: 'School SaaS',
        revenue: latestData.schoolSaasRevenue,
        color: AppColors.info,
      ),
      _BillingModelData(
        label: 'Enterprise SaaS',
        revenue: latestData.enterpriseSaasRevenue,
        color: const Color(0xFFF97316),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue by Billing Model',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Card(
          elevation: Spacings.elevationNone,
          shape: RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusLg,
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: Spacings.borderRadiusFull,
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: models.map((m) {
                        final width = m.revenue / total;
                        return Expanded(
                          flex: (width * 1000).round().clamp(1, 1000),
                          child: Container(
                            color: m.color,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: Spacings.md),

                // Legend
                ...models.map((m) {
                  final percent = (m.revenue / total * 100);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: m.color,
                            borderRadius: Spacings.borderRadiusXs,
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        Expanded(
                          child: Text(
                            m.label,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        Text(
                          _formatCurrency(m.revenue),
                          style: tt.bodySmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Monthly Trend ───────────────────────────────────────────────────

  Widget _buildMonthlyTrend(RevenueState revenueState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (revenueState.revenueData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trend',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Card(
          elevation: Spacings.elevationNone,
          shape: RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusLg,
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.lg,
                  vertical: Spacings.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Period',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Revenue',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Subs',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Churn',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),

              // Rows
              ...revenueState.revenueData.take(12).map(
                    (point) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.lg,
                        vertical: Spacings.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              point.period,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatCurrency(point.totalRevenue),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: AppTypography.wMedium,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${point.activeSubscriptions}',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${point.churnRate.toStringAsFixed(1)}%',
                              style: tt.bodySmall?.copyWith(
                                color: point.churnRate > 5
                                    ? AppColors.error
                                    : cs.onSurface,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    const symbol = '\u20A6'; // NGN
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
}

class _BillingModelData {
  const _BillingModelData({
    required this.label,
    required this.revenue,
    required this.color,
  });

  final String label;
  final double revenue;
  final Color color;
}
