import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart' hide dashboardProvider;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';
import '../../../../routing/route_guards.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/notification_summary.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/stat_card_row.dart';
import '../widgets/welcome_section.dart';


/// Dashboard for users with the **super-admin** role.
///
/// Displays:
/// - [WelcomeSection]
/// - Stat cards: Total Schools, Total Users, Total Exams, Platform Revenue
/// - Quick Actions: Manage Schools, System Reports, Platform Settings, User Management
/// - Recent Activity: New school registrations, platform metrics
/// - Notification Summary
/// - Responsive layout (3 column on large desktop)
class SuperAdminDashboardPage extends ConsumerWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    if (dashboardState.isLoading &&
        dashboardState.stats.totalSchools == 0) {
      return const _SuperAdminLoadingSkeleton();
    }

    if (dashboardState.error != null &&
        dashboardState.stats.totalSchools == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              dashboardState.error!,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.lg),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(dashboardProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = dashboardState.stats;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: _buildLayout(context, ref, dashboardState, stats),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardStats stats,
  ) {
    final isLargeDesktop = context.width >= 1280;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(ref),
        Spacings.sectionGap,
        _buildStatCards(context, stats),
        Spacings.sectionGap,
        if (isLargeDesktop)
          _buildThreeColumnLayout(context, state)
        else
          _buildTwoColumnLayout(context, state),
        const SizedBox(height: Spacings.xl),
      ],
    );
  }

  // ─── Three-Column Layout (Large Desktop ≥ 1280px) ──────────────────

  Widget _buildThreeColumnLayout(BuildContext context, DashboardState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Quick Actions
        Expanded(
          child: _buildQuickActions(context),
        ),
        const SizedBox(width: Spacings.xl),
        // Column 2: Recent Activity
        Expanded(
          child: _buildRecentActivity(context, state),
        ),
        const SizedBox(width: Spacings.xl),
        // Column 3: Notifications
        Expanded(
          child: _buildNotificationSummary(state),
        ),
      ],
    );
  }

  // ─── Two-Column Layout (Desktop / Tablet) ───────────────────────────

  Widget _buildTwoColumnLayout(BuildContext context, DashboardState state) {
    final isDesktop = context.isDesktop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickActions(context),
        Spacings.sectionGap,
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRecentActivity(context, state),
              ),
              const SizedBox(width: Spacings.xl),
              Expanded(
                flex: 2,
                child: _buildNotificationSummary(state),
              ),
            ],
          )
        else ...[
          _buildRecentActivity(context, state),
          Spacings.sectionGap,
          _buildNotificationSummary(state),
        ],
      ],
    );
  }

  Widget _buildWelcomeSection(WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final userName = _getUserName(ref);
    return WelcomeSection(userName: userName, role: role);
  }

  Widget _buildStatCards(BuildContext context, DashboardStats stats) {
    final cs = context.colorScheme;
    return StatCardRow(
      items: [
        StatItem(
          title: 'Total Schools',
          value: '${stats.totalSchools}',
          icon: Icons.domain_outlined,
          trend: TrendDirection.up,
          trendValue: '+2',
          color: AppColors.info,
        ),
        StatItem(
          title: 'Total Users',
          value: _formatNumber(stats.totalUsers),
          icon: Icons.people_outline_rounded,
          trend: TrendDirection.up,
          trendValue: '+18%',
          color: AppColors.success,
        ),
        StatItem(
          title: 'Total Exams',
          value: _formatNumber(stats.totalExams),
          icon: Icons.quiz_outlined,
          trend: TrendDirection.up,
          trendValue: '+24%',
          color: AppColors.warning,
        ),
        StatItem(
          title: 'Platform Revenue',
          value: '\$${_formatRevenue(stats.platformRevenue)}',
          icon: Icons.attach_money,
          trend: TrendDirection.up,
          trendValue: '+18%',
          color: cs.tertiary,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, 'Quick Actions'),
        const SizedBox(height: Spacings.md),
        QuickActionsGrid(
          actions: [
            QuickAction(
              title: 'Manage Schools',
              subtitle: 'Add and configure schools',
              icon: Icons.domain_outlined,
              color: cs.primary,
            ),
            const QuickAction(
              title: 'System Reports',
              subtitle: 'Platform-wide analytics',
              icon: Icons.analytics_outlined,
              color: AppColors.info,
            ),
            const QuickAction(
              title: 'Platform Settings',
              subtitle: 'Configure global settings',
              icon: Icons.settings_outlined,
              color: AppColors.warning,
            ),
            const QuickAction(
              title: 'User Management',
              subtitle: 'Administer all platform users',
              icon: Icons.admin_panel_settings_outlined,
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, DashboardState state,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, 'Recent Activity'),
        const SizedBox(height: Spacings.sm),
        RecentActivityList(
          activities: state.recentActivity,
          onViewAll: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationSummary(DashboardState state) {
    return NotificationSummary(
      notifications: state.notifications,
      onViewAll: () {},
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  String _getUserName(WidgetRef ref) {
    final authState = ref.read(authProvider);
    return authState.user?.fullName ?? 'Super Admin';
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return n.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return n.toString();
  }

  String _formatRevenue(double n) {
    if (n >= 1000) {
      final formatted = n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      return formatted;
    }
    return n.toStringAsFixed(2);
  }
}

class _SuperAdminLoadingSkeleton extends StatelessWidget {
  const _SuperAdminLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
          Spacings.sectionGap,
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.only(right: Spacings.md),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(Spacings.mdRadius),
                  ),
                ),
              ),
            ),
          ),
          Spacings.sectionGap,
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
          ),
        ],
      ),
    );
  }
}
