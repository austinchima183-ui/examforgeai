import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../config/dependency_injection.dart' hide dashboardProvider;
import '../../../../routing/route_guards.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/notification_summary.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/stat_card_row.dart';
import '../widgets/welcome_section.dart';
import 'teacher_dashboard_page.dart' show ResponsiveLayout;
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


/// Dashboard for users with the **student** role.
///
/// Displays:
/// - [WelcomeSection]
/// - Stat cards: Upcoming Exams, Completed Exams, Average Score, Subjects
/// - Quick Actions: Take Exam, View Results, Practice Mode, View Schedule
/// - Recent Activity: Recent exam results, upcoming exams
/// - Notification Summary
/// - Responsive layout
class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    if (dashboardState.isLoading &&
        dashboardState.stats.completedExams == 0) {
      return const _StudentLoadingSkeleton();
    }

    if (dashboardState.error != null &&
        dashboardState.stats.completedExams == 0) {
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
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context, ref, dashboardState, stats),
          desktop:
              _buildDesktopLayout(context, ref, dashboardState, stats),
        ),
      ),
    );
  }

  List<Widget> _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardStats stats,
  ) {
    return [
      _buildWelcomeSection(ref),
      Spacings.sectionGap,
      _buildStatCards(context, stats),
      Spacings.sectionGap,
      _buildQuickActions(context),
      Spacings.sectionGap,
      _buildRecentActivity(context, state),
      Spacings.sectionGap,
      _buildNotificationSummary(state),
      const SizedBox(height: Spacings.xl),
    ];
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(ref),
        Spacings.sectionGap,
        _buildStatCards(context, stats),
        Spacings.sectionGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(context),
                  Spacings.sectionGap,
                  _buildRecentActivity(context, state),
                ],
              ),
            ),
            const SizedBox(width: Spacings.xl),
            Expanded(
              flex: 2,
              child: _buildNotificationSummary(state),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xl),
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
          title: 'Upcoming Exams',
          value: '${stats.upcomingExams}',
          icon: Icons.event_upcoming_outlined,
          trend: stats.upcomingExams > 0
              ? TrendDirection.up
              : TrendDirection.neutral,
          trendValue: stats.upcomingExams > 0 ? 'Soon' : null,
          color: AppColors.info,
        ),
        StatItem(
          title: 'Completed Exams',
          value: '${stats.completedExams}',
          icon: Icons.task_alt_outlined,
          trend: TrendDirection.up,
          trendValue: '+3',
          color: AppColors.success,
        ),
        StatItem(
          title: 'Average Score',
          value: '${stats.averageScore.toStringAsFixed(1)}%',
          icon: Icons.trending_up_outlined,
          trend: TrendDirection.up,
          trendValue: '+5.2%',
          color: AppColors.warning,
        ),
        StatItem(
          title: 'Subjects',
          value: '${stats.totalSubjects}',
          icon: Icons.menu_book_outlined,
          trend: TrendDirection.neutral,
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
              title: 'Take Exam',
              subtitle: 'Start an assigned exam',
              icon: Icons.play_circle_outline_rounded,
              color: cs.primary,
            ),
            QuickAction(
              title: 'View Results',
              subtitle: 'Check your exam scores',
              icon: Icons.assessment_outlined,
              color: AppColors.success,
            ),
            QuickAction(
              title: 'Practice Mode',
              subtitle: 'AI-powered study sessions',
              icon: Icons.auto_awesome_outlined,
              color: AppColors.info,
            ),
            QuickAction(
              title: 'View Schedule',
              subtitle: 'Upcoming exams & deadlines',
              icon: Icons.calendar_month_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, DashboardState state) {
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
    return authState.user?.fullName ?? 'Student';
  }
}

class _StudentLoadingSkeleton extends StatelessWidget {
  const _StudentLoadingSkeleton();

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
