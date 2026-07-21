import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SUPER ADMIN DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Executive dashboard for the Enterprise Super Admin Platform.
///
/// Displays platform-wide KPIs across three metric rows, a quick-navigation
/// grid to every admin section, and a recent-activity feed. Follows the
/// standard ExamForge AI page pattern:
/// - [ConsumerStatefulWidget] + private state class
/// - `initState` → `addPostFrameCallback` → `_loadData()` via `ref.read`
/// - `ref.watch(provider)` in `build()` for reactive rebuilds
/// - Loading → Error → Content pattern
/// - Design tokens everywhere
/// - Navigation via `context.push(RouteNames.xxx)` (GoRouter)
class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState
    extends ConsumerState<SuperAdminDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(dashboardProvider.notifier).loadMetrics();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Super Admin Dashboard'),
      body: _buildBody(context, dashboardState, cs),
    );
  }

  // ─── Body: Loading → Error → Content ────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    DashboardState state,
    ColorScheme cs,
  ) {
    // Loading state
    if (state.isLoading && state.metrics == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    // Error state
    if (state.error != null && state.metrics == null) {
      return _buildErrorState(state);
    }

    // Content
    final metrics = state.metrics;
    if (metrics == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).loadMetrics(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 — Platform Users & Exams
            _buildSectionHeader(context, 'Platform Overview'),
            Spacings.itemGap,
            _buildMetricRow1(metrics, cs),
            Spacings.sectionGap,

            // Row 2 — Engagement & Revenue
            _buildSectionHeader(context, 'Engagement & Revenue'),
            Spacings.itemGap,
            _buildMetricRow2(metrics, cs),
            Spacings.sectionGap,

            // Row 3 — Subscriptions & System Health
            _buildSectionHeader(context, 'Subscriptions & System Health'),
            Spacings.itemGap,
            _buildMetricRow3(metrics, cs),
            Spacings.sectionGap,

            // Quick Navigation Grid
            _buildSectionHeader(context, 'Quick Navigation'),
            Spacings.itemGap,
            _buildQuickNavigationGrid(cs),
            Spacings.sectionGap,

            // Recent Activity
            _buildSectionHeader(context, 'Recent Activity'),
            Spacings.itemGap,
            _buildRecentActivity(metrics, cs),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(DashboardState state) {
    return Center(
      child: Padding(
        padding: Spacings.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              'Failed to load dashboard',
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  // ─── Section Header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SectionHeader(title: title);
  }

  // ─── Metric Row 1 — Platform Users & Exams ──────────────────────────────

  Widget _buildMetricRow1(DashboardMetrics m, ColorScheme cs) {
    return _responsiveGrid(
      children: [
        MetricCard(
          title: 'Total Schools',
          value: _formatNumber(m.totalSchools),
          icon: Icons.school,
          color: cs.primary,
        ),
        MetricCard(
          title: 'Total Teachers',
          value: _formatNumber(m.totalTeachers),
          icon: Icons.person,
          color: Colors.teal,
        ),
        MetricCard(
          title: 'Total Students',
          value: _formatNumber(m.totalStudents),
          icon: Icons.groups,
          color: AppColors.info,
        ),
        MetricCard(
          title: 'Total Parents',
          value: _formatNumber(m.totalParents),
          icon: Icons.family_restroom,
          color: Colors.purple,
        ),
        MetricCard(
          title: 'Active Exams',
          value: _formatNumber(m.activeExams),
          icon: Icons.quiz,
          color: Colors.orange,
        ),
      ],
    );
  }

  // ─── Metric Row 2 — Engagement & Revenue ────────────────────────────────

  Widget _buildMetricRow2(DashboardMetrics m, ColorScheme cs) {
    return _responsiveGrid(
      children: [
        MetricCard(
          title: 'Daily Active Users',
          value: _formatNumber(m.dailyActiveUsers),
          icon: Icons.today,
          color: cs.primary,
        ),
        MetricCard(
          title: 'Monthly Active Users',
          value: _formatNumber(m.monthlyActiveUsers),
          icon: Icons.calendar_month,
          color: cs.primary,
        ),
        MetricCard(
          title: 'AI Requests Today',
          value: _formatNumber(m.aiRequestsToday),
          icon: Icons.auto_awesome,
          color: Colors.deepPurple,
        ),
        MetricCard(
          title: 'Revenue Today',
          value: _formatCurrency(m.revenueToday),
          icon: Icons.attach_money,
          color: AppColors.success,
        ),
        MetricCard(
          title: 'Monthly Revenue',
          value: _formatCurrency(m.monthlyRevenue),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
      ],
    );
  }

  // ─── Metric Row 3 — Subscriptions & System Health ───────────────────────

  Widget _buildMetricRow3(DashboardMetrics m, ColorScheme cs) {
    return _responsiveGrid(
      children: [
        MetricCard(
          title: 'Annual Revenue',
          value: _formatCurrency(m.annualRevenue),
          icon: Icons.account_balance,
          color: AppColors.success,
        ),
        MetricCard(
          title: 'Active Subscriptions',
          value: _formatNumber(m.activeSubscriptions),
          icon: Icons.card_membership,
          color: cs.primary,
        ),
        MetricCard(
          title: 'Trial Accounts',
          value: _formatNumber(m.trialAccounts),
          icon: Icons.hourglass_empty,
          color: AppColors.warning,
        ),
        MetricCard(
          title: 'System Health',
          value: _healthLabel(m.systemHealth),
          icon: Icons.health_and_safety,
          color: _healthColor(m.systemHealth),
          subtitle: '${m.backgroundJobsRunning} running / ${m.backgroundJobsPending} pending',
        ),
        MetricCard(
          title: 'API Status',
          value: _apiStatusLabel(m.apiStatus),
          icon: Icons.api,
          color: _apiStatusColor(m.apiStatus),
        ),
      ],
    );
  }

  // ─── Quick Navigation Grid ──────────────────────────────────────────────

  Widget _buildQuickNavigationGrid(ColorScheme cs) {
    final navItems = <_NavItem>[
      _NavItem(
        title: 'School Management',
        icon: Icons.school,
        color: cs.primary,
        route: RouteNames.superAdminSchools,
      ),
      _NavItem(
        title: 'User Management',
        icon: Icons.people,
        color: Colors.teal,
        route: RouteNames.superAdminUsers,
      ),
      _NavItem(
        title: 'AI Management',
        icon: Icons.smart_toy,
        color: Colors.deepPurple,
        route: RouteNames.superAdminAI,
      ),
      _NavItem(
        title: 'Billing & Revenue',
        icon: Icons.payment,
        color: AppColors.success,
        route: RouteNames.superAdminBilling,
      ),
      _NavItem(
        title: 'Support Center',
        icon: Icons.support_agent,
        color: AppColors.info,
        route: RouteNames.superAdminSupport,
      ),
      _NavItem(
        title: 'Security Center',
        icon: Icons.security,
        color: AppColors.error,
        route: RouteNames.superAdminSecurity,
      ),
      _NavItem(
        title: 'Infrastructure',
        icon: Icons.dns,
        color: Colors.brown,
        route: RouteNames.superAdminInfrastructure,
      ),
      _NavItem(
        title: 'Intelligence Center',
        icon: Icons.psychology,
        color: Colors.indigo,
        route: RouteNames.superAdminIntelligence,
      ),
      _NavItem(
        title: 'Marketplace',
        icon: Icons.store,
        color: Colors.orange,
        route: RouteNames.superAdminMarketplace,
      ),
      _NavItem(
        title: 'Analytics',
        icon: Icons.bar_chart,
        color: AppColors.info,
        route: RouteNames.superAdminAnalytics,
      ),
      _NavItem(
        title: 'Settings',
        icon: Icons.settings,
        color: cs.onSurface.withOpacity(0.6),
        route: RouteNames.superAdminSettings,
      ),
    ];

    return _responsiveGrid(
      maxCrossAxisCount: 6,
      childAspectRatio: 1.4,
      children: navItems.map((item) {
        return _NavigationCard(
          title: item.title,
          icon: item.icon,
          color: item.color,
          onTap: () => context.push(item.route),
        );
      }).toList(),
    );
  }

  // ─── Recent Activity ────────────────────────────────────────────────────

  Widget _buildRecentActivity(DashboardMetrics m, ColorScheme cs) {
    final activities = m.recentActivities;

    if (activities.isEmpty) {
      return const AdminEmptyState(
        message: 'No recent activity to display.',
        icon: Icons.history,
      );
    }

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: Spacings.paddingAll,
        itemCount: activities.length > 10 ? 10 : activities.length,
        separatorBuilder: (_, __) => const Divider(height: Spacings.lg),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _ActivityTile(activity: activity, cs: cs);
        },
      ),
    );
  }

  // ─── Responsive Grid Helper ─────────────────────────────────────────────

  Widget _responsiveGrid({
    required List<Widget> children,
    int maxCrossAxisCount = 5,
    double childAspectRatio = 1.1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width >= 1400) {
          crossAxisCount = maxCrossAxisCount;
        } else if (width >= 1100) {
          crossAxisCount = maxCrossAxisCount > 4 ? 4 : maxCrossAxisCount;
        } else if (width >= 800) {
          crossAxisCount = 3;
        } else if (width >= 500) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          children: children,
        );
      },
    );
  }

  // ─── Number & Currency Formatting ───────────────────────────────────────

  /// Formats an integer with comma separators for readability.
  /// e.g. `1234` → `"1,234"`
  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Formats a double as Naira currency with comma separators.
  /// e.g. `1234567.0` → `"₦1,234,567"`
  static String _formatCurrency(double n) {
    final formatted = n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₦$formatted';
  }

  // ─── Health & API Status Helpers ────────────────────────────────────────

  Color _healthColor(String status) {
    final hs = HealthStatus.fromString(status);
    switch (hs) {
      case HealthStatus.healthy:
        return AppColors.success;
      case HealthStatus.degraded:
        return AppColors.warning;
      case HealthStatus.unhealthy:
      case HealthStatus.down:
        return AppColors.error;
      case HealthStatus.maintenance:
        return AppColors.info;
    }
  }

  String _healthLabel(String status) {
    return HealthStatus.fromString(status).label;
  }

  Color _apiStatusColor(String status) {
    final hs = HealthStatus.fromString(status);
    switch (hs) {
      case HealthStatus.healthy:
        return AppColors.success;
      case HealthStatus.degraded:
        return AppColors.warning;
      case HealthStatus.unhealthy:
      case HealthStatus.down:
        return AppColors.error;
      case HealthStatus.maintenance:
        return AppColors.info;
    }
  }

  String _apiStatusLabel(String status) {
    return HealthStatus.fromString(status).label;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NAVIGATION CARD — Quick-nav tile for each admin section
// ═══════════════════════════════════════════════════════════════════════════════

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(icon, color: color, size: Spacings.lgIcon),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                title,
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 12,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVITY TILE — Single recent-activity row
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.cs});

  final Map<String, dynamic> activity;
  final ColorScheme cs;

  IconData _iconFor(String? type) {
    switch (type) {
      case 'school_registered':
        return Icons.school_outlined;
      case 'user_created':
        return Icons.person_add_outlined;
      case 'subscription_activated':
        return Icons.card_membership_outlined;
      case 'exam_completed':
        return Icons.quiz_outlined;
      case 'payment_received':
        return Icons.payment_outlined;
      case 'alert_triggered':
        return Icons.warning_amber_outlined;
      case 'system_update':
        return Icons.system_update_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = activity['title'] as String? ?? 'Activity';
    final description = activity['description'] as String?;
    final type = activity['type'] as String?;
    final timestamp = activity['timestamp'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.sm),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Icon(_iconFor(type), size: Spacings.mdIcon, color: cs.primary),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 13,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (description != null) ...[
                const SizedBox(height: Spacings.xs),
                Text(
                  description,
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(width: Spacings.sm),
          Text(
            timestamp,
            style: AppTypography.wRegular.copyWith(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NAV ITEM — Data class for quick-navigation entries
// ═══════════════════════════════════════════════════════════════════════════════

class _NavItem {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
}
