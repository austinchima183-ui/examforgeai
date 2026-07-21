import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Comprehensive student dashboard page for the Student Portal.
///
/// Displays:
/// - Welcome section with student name and learning streak
/// - Stat cards row: Upcoming Exams, Pending Assignments, Average Score, Practice Sessions
/// - Quick Actions grid: AI Tutor, Practice Mode, Assignments, Flashcards, Study Planner, Resources
/// - Today's Schedule section
/// - Recent Activity list
/// - Notifications summary
/// - AI Study Suggestions section
/// - Pull-to-refresh with [RefreshIndicator]
/// - Loading skeleton state
class StudentPortalDashboardPage extends ConsumerStatefulWidget {
  const StudentPortalDashboardPage({super.key});

  @override
  ConsumerState<StudentPortalDashboardPage> createState() =>
      _StudentPortalDashboardPageState();
}

class _StudentPortalDashboardPageState
    extends ConsumerState<StudentPortalDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentDashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(studentDashboardProvider);

    if (dashboardState.isLoading && dashboardState.stats.upcomingExams == 0) {
      return const _DashboardLoadingSkeleton();
    }

    if (dashboardState.error != null &&
        dashboardState.stats.upcomingExams == 0) {
      return AppErrorState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load Dashboard',
        message: dashboardState.error,
        onRetry: () =>
            ref.read(studentDashboardProvider.notifier).refresh(),
      );
    }

    final stats = dashboardState.stats;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(studentDashboardProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: context.isDesktop
            ? _buildDesktopLayout(context, ref, dashboardState, stats)
            : _buildMobileLayout(context, ref, dashboardState, stats),
      ),
    );
  }

  // ─── Mobile Layout ──────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    StudentDashboardState state,
    StudentDashboardStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(context, stats),
        Spacings.sectionGap,
        _buildStatCards(context, stats),
        Spacings.sectionGap,
        _buildQuickActions(context),
        Spacings.sectionGap,
        _buildTodaySchedule(context, state),
        Spacings.sectionGap,
        _buildRecentActivity(context, state),
        Spacings.sectionGap,
        _buildNotificationsSummary(context, state),
        Spacings.sectionGap,
        _buildAiSuggestions(context, state),
        const SizedBox(height: Spacings.xl),
      ],
    );
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    StudentDashboardState state,
    StudentDashboardStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeSection(context, stats),
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
                  _buildTodaySchedule(context, state),
                  Spacings.sectionGap,
                  _buildRecentActivity(context, state),
                ],
              ),
            ),
            const SizedBox(width: Spacings.xl),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationsSummary(context, state),
                  Spacings.sectionGap,
                  _buildAiSuggestions(context, state),
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

  Widget _buildWelcomeSection(BuildContext context, StudentDashboardStats stats) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  'Keep up the great work on your learning journey.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (stats.learningStreak > 0) ...[
            const SizedBox(width: Spacings.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(Spacings.lgRadius),
              ),
              child: Column(
                children: [
                  Text(
                    '${stats.learningStreak}',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Day Streak 🔥',
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stat Cards ─────────────────────────────────────────────────────

  Widget _buildStatCards(BuildContext context, StudentDashboardStats stats) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            title: 'Upcoming Exams',
            value: '${stats.upcomingExams}',
            icon: Icons.event_upcoming_outlined,
            color: AppColors.info,
          ),
          const SizedBox(width: Spacings.md),
          _StatCard(
            title: 'Pending Assignments',
            value: '${stats.pendingAssignments}',
            icon: Icons.assignment_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(width: Spacings.md),
          _StatCard(
            title: 'Average Score',
            value: '${stats.recentAvgScore.toStringAsFixed(1)}%',
            icon: Icons.trending_up_outlined,
            color: AppColors.success,
          ),
          const SizedBox(width: Spacings.md),
          _StatCard(
            title: 'Practice Sessions',
            value: '${stats.practiceThisWeek}',
            icon: Icons.auto_awesome_outlined,
            color: context.colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final cs = context.colorScheme;
    final actions = [
      _QuickActionData(
        title: 'AI Tutor',
        subtitle: 'Get help studying',
        icon: Icons.smart_toy_outlined,
        color: cs.primary,
        onTap: () => context.go(RouteNames.dashboard),
      ),
      _QuickActionData(
        title: 'Practice Mode',
        subtitle: 'Test your knowledge',
        icon: Icons.quiz_outlined,
        color: AppColors.info,
        onTap: () => context.go(RouteNames.dashboard),
      ),
      _QuickActionData(
        title: 'Assignments',
        subtitle: 'View & submit work',
        icon: Icons.assignment_outlined,
        color: AppColors.warning,
        onTap: () => context.go(RouteNames.dashboard),
      ),
      _QuickActionData(
        title: 'Flashcards',
        subtitle: 'Spaced repetition',
        icon: Icons.style_outlined,
        color: AppColors.success,
        onTap: () => context.go(RouteNames.dashboard),
      ),
      _QuickActionData(
        title: 'Study Planner',
        subtitle: 'Plan your study time',
        icon: Icons.calendar_month_outlined,
        color: cs.tertiary,
        onTap: () => context.go(RouteNames.dashboard),
      ),
      _QuickActionData(
        title: 'Resources',
        subtitle: 'Learning materials',
        icon: Icons.folder_open_outlined,
        color: AppColors.error,
        onTap: () => context.go(RouteNames.dashboard),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, 'Quick Actions'),
        const SizedBox(height: Spacings.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.isMobile ? 2 : 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionCard(action: action);
          },
        ),
      ],
    );
  }

  // ─── Today's Schedule ───────────────────────────────────────────────

  Widget _buildTodaySchedule(
      BuildContext context, StudentDashboardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final pendingAssignments = state.pendingAssignments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, "Today's Schedule"),
        const SizedBox(height: Spacings.sm),
        if (pendingAssignments.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Text(
                  'No pending tasks for today! 🎉',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...pendingAssignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppInfoCard(
                title: assignment.assignmentTitle ?? 'Untitled Assignment',
                subtitle:
                    '${assignment.subjectName ?? 'No Subject'} · Due ${_formatDate(assignment.dueDate)}',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.warning,
                trailing: _buildStatusBadge(context, assignment.status),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Recent Activity ────────────────────────────────────────────────

  Widget _buildRecentActivity(
      BuildContext context, StudentDashboardState state) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    final recentPractice = state.recentPractice.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(context, 'Recent Activity'),
        const SizedBox(height: Spacings.sm),
        if (recentPractice.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Text(
                  'No recent activity yet.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...recentPractice.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppInfoCard(
                title:
                    '${session.subjectName ?? 'Practice'} - ${session.topicName ?? 'Mixed Topics'}',
                subtitle:
                    'Score: ${session.scorePct.toStringAsFixed(0)}% · ${session.totalQuestions} questions',
                icon: Icons.quiz_outlined,
                iconColor: session.scorePct >= 70
                    ? AppColors.success
                    : AppColors.warning,
                trailing: Text(
                  _formatDate(session.createdAt),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Notifications Summary ──────────────────────────────────────────

  Widget _buildNotificationsSummary(
      BuildContext context, StudentDashboardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final notifications = state.recentNotifications.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle(context, 'Notifications'),
            if (state.unreadNotificationCount > 0)
              Badge(
                label: Text('${state.unreadNotificationCount}'),
                child: const SizedBox.shrink(),
              ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        if (notifications.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Text(
                  "You're all caught up! 🎉",
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppInfoCard(
                title: notification.title,
                subtitle: notification.message,
                icon: _notificationIcon(notification.type),
                iconColor: _notificationColor(notification.type),
                onTap: () {
                  // Navigate to notifications page
                },
              ),
            ),
          ),
        const SizedBox(height: Spacings.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Navigate to full notifications
            },
            child: const Text('View All Notifications'),
          ),
        ),
      ],
    );
  }

  // ─── AI Study Suggestions ───────────────────────────────────────────

  Widget _buildAiSuggestions(
      BuildContext context, StudentDashboardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final suggestions = [
      _AiSuggestion(
        icon: Icons.auto_awesome_outlined,
        title: 'Focus on Weak Topics',
        description:
            'Based on your recent practice, consider reviewing topics where your score was below 60%.',
        actionLabel: 'Start Practice',
        color: AppColors.info,
      ),
      _AiSuggestion(
        icon: Icons.style_outlined,
        title: 'Review Flashcards',
        description:
            'You have ${state.stats.pendingAssignments} pending assignments. Review key concepts first.',
        actionLabel: 'Review Now',
        color: AppColors.success,
      ),
      _AiSuggestion(
        icon: Icons.timer_outlined,
        title: 'Study Time Goal',
        description:
            'You\'ve studied ${state.stats.studyTimeThisWeekMin} minutes this week. Try to reach 5 hours!',
        actionLabel: 'Plan Study',
        color: AppColors.warning,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            _sectionTitle(context, 'AI Study Suggestions'),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        ...suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacings.md),
                    decoration: BoxDecoration(
                      color: suggestion.color.withOpacity(context.isDarkMode ? 0.20 : 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(Spacings.mdRadius),
                    ),
                    child: Icon(
                      suggestion.icon,
                      size: Spacings.lgIcon,
                      color: suggestion.color,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.title,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          suggestion.description,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  FilledButton.tonal(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.md,
                        vertical: Spacings.sm,
                      ),
                    ),
                    child: Text(
                      suggestion.actionLabel,
                      style: tt.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildStatusBadge(BuildContext context, SubmissionStatus status) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final (color, label) = switch (status) {
      SubmissionStatus.draft => (AppColors.warning, 'Draft'),
      SubmissionStatus.submitted => (AppColors.info, 'Submitted'),
      SubmissionStatus.graded => (AppColors.success, 'Graded'),
      SubmissionStatus.returned => (AppColors.error, 'Returned'),
      SubmissionStatus.lateSubmitted => (AppColors.warning, 'Late'),
      SubmissionStatus.resubmitted => (AppColors.info, 'Resubmitted'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }

  IconData _notificationIcon(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment => Icons.assignment_outlined,
      StudentNotificationType.upcomingExam => Icons.event_upcoming_outlined,
      StudentNotificationType.resultPublished => Icons.assessment_outlined,
      StudentNotificationType.teacherAnnouncement =>
        Icons.campaign_outlined,
      StudentNotificationType.studyReminder => Icons.alarm_outlined,
      StudentNotificationType.deadlineApproaching =>
        Icons.schedule_outlined,
      StudentNotificationType.feedbackReceived =>
        Icons.feedback_outlined,
    };
  }

  Color _notificationColor(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment => AppColors.info,
      StudentNotificationType.upcomingExam => AppColors.warning,
      StudentNotificationType.resultPublished => AppColors.success,
      StudentNotificationType.teacherAnnouncement => AppColors.info,
      StudentNotificationType.studyReminder => AppColors.warning,
      StudentNotificationType.deadlineApproaching => AppColors.error,
      StudentNotificationType.feedbackReceived => AppColors.success,
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff > 0 && diff <= 7) return 'In $diff days';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      width: 160,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(icon, size: Spacings.mdIcon, color: color),
          ),
          const SizedBox(height: Spacings.md),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: action.color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              action.icon,
              size: Spacings.lgIcon,
              color: action.color,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            action.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            action.subtitle,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AiSuggestion {
  const _AiSuggestion({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Color color;
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
          // Welcome section skeleton
          AppLoadingShimmer(
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(Spacings.lgRadius),
              ),
            ),
          ),
          Spacings.sectionGap,
          // Stat cards skeleton
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: Spacings.md),
                  child: AppLoadingShimmer(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            context.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                            Spacings.mdRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Spacings.sectionGap,
          // Quick actions skeleton
          AppLoadingShimmer(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(Spacings.mdRadius),
              ),
            ),
          ),
          Spacings.sectionGap,
          // Recent activity skeleton
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: AppLoadingShimmer(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color:
                        context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                        Spacings.mdRadius),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
