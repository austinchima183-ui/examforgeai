import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../routing/route_guards.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/notification_summary.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/stat_card_row.dart';
import '../widgets/welcome_section.dart';

/// Dashboard for users with the **teacher** role.
///
/// Displays:
/// - [WelcomeSection] with "Good morning, [Name]"
/// - Stat cards: Total Students, Total Classes, Total Subjects, Pending Exams
/// - Quick Actions: Create Exam, View Question Bank, Grade Exams, View Reports
/// - Recent Activity: Recent exam submissions, grading tasks
/// - Notification Summary
/// - Responsive layout (2 column on desktop)
class TeacherDashboardPage extends ConsumerWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    if (dashboardState.isLoading && dashboardState.stats.totalStudents == 0) {
      return const _DashboardLoadingSkeleton();
    }

    if (dashboardState.error != null &&
        dashboardState.stats.totalStudents == 0) {
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

  // ─── Mobile Layout ──────────────────────────────────────────────────

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
      _buildQuickActions(context, ref),
      Spacings.sectionGap,
      _buildRecentActivity(context, state),
      Spacings.sectionGap,
      _buildNotificationSummary(state),
      const SizedBox(height: Spacings.xl),
    ];
  }

  // ─── Desktop Layout (2 columns) ─────────────────────────────────────

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
            // Left column: Quick actions + Activity
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(context, ref),
                  Spacings.sectionGap,
                  _buildRecentActivity(context, state),
                ],
              ),
            ),
            const SizedBox(width: Spacings.xl),
            // Right column: Notifications
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationSummary(state),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xl),
      ],
    );
  }

  // ─── Welcome Section ────────────────────────────────────────────────

  Widget _buildWelcomeSection(WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final userName = _getUserName(ref);
    return WelcomeSection(userName: userName, role: role);
  }

  // ─── Stat Cards ─────────────────────────────────────────────────────

  Widget _buildStatCards(BuildContext context, DashboardStats stats) {
    final cs = context.colorScheme;
    return StatCardRow(
      items: [
        StatItem(
          title: 'Total Students',
          value: '${stats.totalStudents}',
          icon: Icons.people_outline_rounded,
          trend: TrendDirection.up,
          trendValue: '+8%',
          color: AppColors.info,
        ),
        StatItem(
          title: 'Total Classes',
          value: '${stats.totalClasses}',
          icon: Icons.class_outlined,
          trend: TrendDirection.neutral,
          color: AppColors.success,
        ),
        StatItem(
          title: 'Total Subjects',
          value: '${stats.totalSubjects}',
          icon: Icons.menu_book_outlined,
          trend: TrendDirection.up,
          trendValue: '+1',
          color: AppColors.warning,
        ),
        StatItem(
          title: 'Pending Exams',
          value: '${stats.pendingExams}',
          icon: Icons.pending_actions_outlined,
          trend: TrendDirection.down,
          trendValue: '-2',
          color: cs.error,
        ),
      ],
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
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
              title: 'Create Exam',
              subtitle: 'Build a new exam with AI',
              icon: Icons.add_circle_outline_rounded,
              color: cs.primary,
            ),
            QuickAction(
              title: 'Question Bank',
              subtitle: 'Browse and manage questions',
              icon: Icons.library_books_outlined,
              color: AppColors.info,
            ),
            QuickAction(
              title: 'Grade Exams',
              subtitle: 'Review and grade submissions',
              icon: Icons.grading_outlined,
              color: AppColors.success,
            ),
            QuickAction(
              title: 'View Reports',
              subtitle: 'Student performance analytics',
              icon: Icons.analytics_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Recent Activity ────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context, DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, 'Recent Activity'),
        const SizedBox(height: Spacings.sm),
        RecentActivityList(
          activities: state.recentActivity,
          onViewAll: () {
            // Navigate to full activity log
          },
        ),
      ],
    );
  }

  // ─── Notification Summary ───────────────────────────────────────────

  Widget _buildNotificationSummary(DashboardState state) {
    return NotificationSummary(
      notifications: state.notifications,
      onViewAll: () {
        // Navigate to full notifications page
      },
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

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
    return authState.user?.fullName ?? 'Teacher';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RESPONSIVE LAYOUT HELPER
// ═══════════════════════════════════════════════════════════════════════

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    required this.desktop,
    super.key,
  });

  final List<Widget> mobile;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktop;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mobile,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LOADING SKELETON
// ═══════════════════════════════════════════════════════════════════════

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome skeleton
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
          Spacings.sectionGap,
          // Stat cards skeleton
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
          // Quick actions skeleton
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
          ),
          const SizedBox(height: Spacings.md),
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
