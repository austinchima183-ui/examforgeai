import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/enhanced_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENHANCED WORKSPACE DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// The enhanced Teacher Workspace Dashboard page.
///
/// This is a significantly upgraded version of the standard dashboard,
/// presenting a modern SaaS-style layout with:
/// - Welcome section with time-of-day greeting and quick stats
/// - AI Quick Actions grid (12 action buttons)
/// - Today's Timetable
/// - Pending Tasks & Assignments
/// - Teaching Statistics
/// - Recent Documents
/// - Saved Templates
/// - Upcoming Events
/// - Notifications
/// - Recently Generated AI Content
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [CustomScrollView] with slivers.
class EnhancedWorkspaceDashboardPage extends ConsumerStatefulWidget {
  const EnhancedWorkspaceDashboardPage({super.key});

  @override
  ConsumerState<EnhancedWorkspaceDashboardPage> createState() => _State();
}

class _State extends ConsumerState<EnhancedWorkspaceDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enhancedDashboardProvider.notifier).loadDashboard();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(enhancedDashboardProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Workspace'),
      body: _buildBody(context, dashboardState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, EnhancedDashboardState state) {
    // Loading state
    if (state.isLoading && state.dashboard == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.dashboard == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(enhancedDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Empty state
    final dashboard = state.dashboard;
    if (dashboard == null) {
      return AppEmptyState.noData(
        title: 'No Workspace Data',
        subtitle: 'Your workspace dashboard will appear here once loaded.',
        actionLabel: 'Refresh',
        onAction: () =>
            ref.read(enhancedDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Success — render dashboard
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(enhancedDashboardProvider.notifier).refreshDashboard(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Welcome Section ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildWelcomeSection(context, dashboard)),

          // ─── AI Quick Actions ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildQuickActionsSection(context)),

          // ─── Today's Timetable ────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildTodayTimetable(context, dashboard),
          ),

          // ─── Pending Tasks & Assignments ──────────────────────────
          SliverToBoxAdapter(
            child: _buildPendingTasks(context, dashboard),
          ),

          // ─── Teaching Statistics ──────────────────────────────────
          SliverToBoxAdapter(
            child: _buildTeachingStatistics(context, dashboard),
          ),

          // ─── Recent Documents ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildRecentDocuments(context, dashboard),
          ),

          // ─── Saved Templates ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSavedTemplates(context, dashboard),
          ),

          // ─── Upcoming Events ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildUpcomingEvents(context, dashboard),
          ),

          // ─── Notifications ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildNotifications(context, dashboard),
          ),

          // ─── Recently Generated AI Content ────────────────────────
          SliverToBoxAdapter(
            child: _buildRecentAiContent(context, dashboard),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacings.xxl)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome shimmer
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLoadingShimmer.box(
                    width: 220,
                    height: 24,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  const SizedBox(height: Spacings.sm),
                  AppLoadingShimmer.box(
                    width: 180,
                    height: 16,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  const SizedBox(height: Spacings.lg),
                  // Stats row shimmer
                  Row(
                    children: List.generate(
                      4,
                      (_) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.xs,
                          ),
                          child: AppLoadingShimmer.box(
                            height: 88,
                            borderRadius: Spacings.borderRadiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quick actions shimmer
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLoadingShimmer.box(
                    width: 160,
                    height: 18,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  const SizedBox(height: Spacings.md),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Spacings.md,
                    crossAxisSpacing: Spacings.md,
                    childAspectRatio: 1.2,
                    children: List.generate(
                      12,
                      (_) => AppLoadingShimmer.box(
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Timeline shimmer
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLoadingShimmer.box(
                    width: 140,
                    height: 18,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  const SizedBox(height: Spacings.md),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: Spacings.md),
                      itemBuilder: (_, __) => AppLoadingShimmer.box(
                        width: 160,
                        borderRadius: Spacings.borderRadiusLg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WELCOME SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeSection(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final userName = ref.watch(userFullNameProvider) ?? 'Teacher';
    final now = DateTime.now();
    final greeting = _timeOfDayGreeting(now.hour);
    final dateStr =
        '${_weekdayName(now.weekday)}, ${_monthName(now.month)} ${now.day}, ${now.year}';

    final stats = dashboard.stats;

    final quickStats = [
      _QuickStatEntry(
        title: 'Lesson Plans',
        value: stats.lessonPlans,
        icon: Icons.auto_stories_outlined,
        color: cs.primary,
        route: RouteNames.lessonPlanList,
      ),
      _QuickStatEntry(
        title: 'Presentations',
        value: stats.presentations,
        icon: Icons.slideshow_outlined,
        color: AppColors.success,
        route: RouteNames.workspace,
      ),
      _QuickStatEntry(
        title: 'Pending Tasks',
        value: stats.pendingTasks,
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
        route: RouteNames.workspace,
      ),
      _QuickStatEntry(
        title: 'AI Generations',
        value: stats.aiGenerations,
        icon: Icons.auto_awesome_outlined,
        color: AppColors.info,
        route: RouteNames.aiGenerator,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.lg,
        Spacings.lg,
        Spacings.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $userName!',
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            dateStr,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          // Quick stats row
          Row(
            children: quickStats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
                      child: _QuickStatCard(stat: stat),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      QuickActionData(
        icon: Icons.auto_stories_rounded,
        label: 'Lesson Plan',
        route: RouteNames.lessonPlanCreate,
        color: theme.colorScheme.primary,
      ),
      QuickActionData(
        icon: Icons.calendar_month_rounded,
        label: 'Scheme of Work',
        route: RouteNames.schemeOfWorkCreate,
        color: theme.colorScheme.tertiary,
      ),
      QuickActionData(
        icon: Icons.assignment_rounded,
        label: 'Worksheet',
        route: RouteNames.worksheetCreate,
        color: theme.colorScheme.secondary,
      ),
      QuickActionData(
        icon: Icons.task_rounded,
        label: 'Assignment',
        route: RouteNames.assignmentCreate,
        color: Colors.orange,
      ),
      QuickActionData(
        icon: Icons.rate_review_rounded,
        label: 'Comments',
        route: RouteNames.reportCommentGenerator,
        color: Colors.teal,
      ),
      QuickActionData(
        icon: Icons.psychology_rounded,
        label: 'AI Assistant',
        route: RouteNames.contentAssistant,
        color: Colors.purple,
      ),
      QuickActionData(
        icon: Icons.folder_rounded,
        label: 'Resources',
        route: RouteNames.teachingResources,
        color: Colors.blueGrey,
      ),
      QuickActionData(
        icon: Icons.calendar_today_rounded,
        label: 'Planner',
        route: RouteNames.calendarPlanner,
        color: Colors.indigo,
      ),
      // NEW: Expansion quick actions
      QuickActionData(
        icon: Icons.slideshow_rounded,
        label: 'Presentation',
        route: '/workspace/presentations/create',
        color: Colors.deepPurple,
      ),
      QuickActionData(
        icon: Icons.mail_rounded,
        label: 'Communication',
        route: '/workspace/communications/create',
        color: Colors.pink,
      ),
      QuickActionData(
        icon: Icons.grading_rounded,
        label: 'Rubric',
        route: '/workspace/rubrics/create',
        color: Colors.amber,
      ),
      QuickActionData(
        icon: Icons.checklist_rounded,
        label: 'Task',
        route: '/workspace/tasks',
        color: Colors.cyan,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Quick AI Actions'),
          const SizedBox(height: Spacings.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: Spacings.md,
              crossAxisSpacing: Spacings.md,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionCard(action: action);
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TODAY'S TIMETABLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTodayTimetable(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classes = dashboard.todayClasses;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithLink(
            context,
            title: "Today's Classes",
            linkLabel: 'View Full',
            onTap: () => context.go(RouteNames.calendarPlanner),
          ),
          const SizedBox(height: Spacings.md),
          if (classes.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No classes today',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: classes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Spacings.md),
                itemBuilder: (context, index) {
                  final event = classes[index];
                  return _TodayClassCard(event: event);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PENDING TASKS & ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPendingTasks(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final stats = dashboard.stats;
    final assignments = dashboard.pendingAssignments;

    // Show at most 3 upcoming assignments
    final upcomingAssignments = assignments.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithLink(
            context,
            title: 'Pending Tasks & Assignments',
            linkLabel: 'View All',
            onTap: () => context.go(RouteNames.workspace),
          ),
          const SizedBox(height: Spacings.md),
          // Row 1: Overdue + Pending badges
          Row(
            children: [
              if (stats.overdueTasks > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: Spacings.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '${stats.overdueTasks} Overdue',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.errorDark,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacings.sm),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: Spacings.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${stats.pendingTasks} Pending',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.warningDark,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Row 2: Next 3 upcoming assignments
          if (upcomingAssignments.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            ...upcomingAssignments.map(
              (assignment) => _AssignmentCard(assignment: assignment),
            ),
          ] else ...[
            const SizedBox(height: Spacings.md),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Center(
                  child: Text(
                    'No pending assignments',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHING STATISTICS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTeachingStatistics(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final teachingStats = dashboard.teachingStatistics;

    final statCards = [
      _TeachingStatEntry(
        label: 'Total Students',
        value: teachingStats.totalStudents,
        icon: Icons.groups_rounded,
        color: AppColors.info,
      ),
      _TeachingStatEntry(
        label: 'Classes Taught',
        value: teachingStats.classesTaught,
        icon: Icons.school_rounded,
        color: AppColors.success,
      ),
      _TeachingStatEntry(
        label: 'Questions Generated',
        value: teachingStats.questionsGenerated,
        icon: Icons.quiz_rounded,
        color: AppColors.warning,
      ),
      _TeachingStatEntry(
        label: 'Resources Shared',
        value: teachingStats.resourcesShared,
        icon: Icons.share_rounded,
        color: Colors.purple,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Your Teaching Stats'),
          const SizedBox(height: Spacings.md),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statCards.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: Spacings.md),
              itemBuilder: (context, index) {
                return _TeachingStatCard(stat: statCards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECENT DOCUMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildRecentDocuments(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final documents = dashboard.recentDocuments;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithLink(
            context,
            title: 'Recent Documents',
            linkLabel: 'View All',
            onTap: () => context.go(RouteNames.resourceLibrary),
          ),
          const SizedBox(height: Spacings.md),
          if (documents.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No recent documents',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: documents.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Spacings.md),
                itemBuilder: (context, index) {
                  return _RecentDocumentCard(document: documents[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SAVED TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSavedTemplates(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final templates = dashboard.savedTemplates;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithLink(
            context,
            title: 'Saved Templates',
            linkLabel: 'Browse All',
            onTap: () => context.go(RouteNames.resourceLibrary),
          ),
          const SizedBox(height: Spacings.md),
          if (templates.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No saved templates yet',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Spacings.md),
                itemBuilder: (context, index) {
                  return _TemplateCard(template: templates[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUpcomingEvents(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final events = dashboard.upcomingEvents.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderWithLink(
            context,
            title: 'Upcoming Events',
            linkLabel: 'View Calendar',
            onTap: () => context.go(RouteNames.calendarPlanner),
          ),
          const SizedBox(height: Spacings.md),
          if (events.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No upcoming events',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...events.map((event) => _UpcomingEventCard(event: event)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildNotifications(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final count = dashboard.notificationsCount;

    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Pending Notifications'),
          const SizedBox(height: Spacings.md),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: Spacings.elevationNone,
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusLg,
              side: BorderSide(
                color: cs.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: InkWell(
              onTap: () => context.go(RouteNames.teachingResources),
              borderRadius: Spacings.borderRadiusLg,
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count resources shared with you are waiting for review',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: AppTypography.wMedium,
                            ),
                          ),
                          const SizedBox(height: Spacings.xs),
                          Text(
                            'Tap to review shared resources',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECENTLY GENERATED AI CONTENT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildRecentAiContent(
    BuildContext context,
    EnhancedWorkspaceDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    // Use recentDocuments as AI content source
    final aiContent = dashboard.recentDocuments.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Recent AI Creations'),
          const SizedBox(height: Spacings.md),
          if (aiContent.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No AI-generated content yet. Start by creating a lesson plan!',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...aiContent.map((doc) => _AiContentCard(document: doc)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Renders a section title with consistent styling.
  Widget _sectionTitle(BuildContext context, String title) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: cs.onSurface,
      ),
    );
  }

  /// Renders a section title with a trailing link action.
  Widget _sectionHeaderWithLink(
    BuildContext context, {
    required String title,
    required String linkLabel,
    required VoidCallback onTap,
  }) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: Spacings.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            child: Text(
              linkLabel,
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a time-of-day greeting based on the [hour].
  String _timeOfDayGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns the short weekday name for [weekday] (1 = Monday).
  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  /// Returns the month name for [month] (1 = January).
  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  /// Returns the icon for a given document/event type string.
  IconData _typeIcon(String type) {
    switch (type) {
      case 'lesson_plan':
        return Icons.auto_stories_rounded;
      case 'worksheet':
        return Icons.assignment_rounded;
      case 'scheme_of_work':
        return Icons.calendar_month_rounded;
      case 'assignment':
        return Icons.task_rounded;
      case 'presentation':
        return Icons.slideshow_rounded;
      case 'communication':
        return Icons.mail_rounded;
      case 'rubric':
        return Icons.grading_rounded;
      case 'task':
        return Icons.checklist_rounded;
      case 'class':
        return Icons.school_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }

  /// Returns a color for a given document/event type string.
  Color _typeColor(String type) {
    switch (type) {
      case 'lesson_plan':
        return AppColors.info;
      case 'worksheet':
        return AppColors.success;
      case 'scheme_of_work':
        return Colors.teal;
      case 'assignment':
        return AppColors.warning;
      case 'presentation':
        return Colors.deepPurple;
      case 'communication':
        return Colors.pink;
      case 'rubric':
        return Colors.amber;
      case 'task':
        return Colors.cyan;
      default:
        return AppColors.info;
    }
  }

  /// Formats a [DateTime] as a short time string (e.g. "2:30 PM").
  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  /// Formats a [DateTime] relative to now (e.g. "2h ago", "3d ago").
  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Returns a human-readable label for a document type string.
  String _typeLabel(String type) {
    switch (type) {
      case 'lesson_plan':
        return 'Lesson Plan';
      case 'worksheet':
        return 'Worksheet';
      case 'scheme_of_work':
        return 'Scheme of Work';
      case 'assignment':
        return 'Assignment';
      case 'presentation':
        return 'Presentation';
      case 'communication':
        return 'Communication';
      case 'rubric':
        return 'Rubric';
      case 'task':
        return 'Task';
      default:
        return type.replaceAll('_', ' ').split(' ').map(
          (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
        ).join(' ');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK STAT CARD (Welcome Section)
// ═══════════════════════════════════════════════════════════════════════

/// Data model for a single quick stat entry in the welcome section.
class _QuickStatEntry {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickStatEntry({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// A compact stat card displaying an icon, value, and title; tappable.
class _QuickStatCard extends StatelessWidget {
  final _QuickStatEntry stat;

  const _QuickStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.go(stat.route),
        borderRadius: Spacings.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                '${stat.value}',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xxs),
              Text(
                stat.title,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK ACTION CARD
// ═══════════════════════════════════════════════════════════════════════

/// Data model for a single quick action entry.
class QuickActionData {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const QuickActionData({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

/// A single quick-action card with an icon and label.
class _QuickActionCard extends StatelessWidget {
  final QuickActionData action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                action.label,
                style: theme.textTheme.labelSmall,
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

// ═══════════════════════════════════════════════════════════════════════
// TODAY'S CLASS CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a single today's class in the horizontal timetable.
class _TodayClassCard extends StatelessWidget {
  final DashboardEventEntity event;

  const _TodayClassCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    // Access private helpers from parent via a closure-style approach
    // by extracting time formatting here.
    final startTime = _formatTime(event.startTime);
    final endTime = _formatTime(event.endTime);
    final typeColor = _typeColor(event.eventType);
    final typeIcon = _typeIcon(event.eventType);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(Spacings.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.xs),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 16),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    event.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              '$startTime – $endTime',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lesson_plan':
        return AppColors.info;
      case 'class':
        return AppColors.success;
      case 'meeting':
        return Colors.purple;
      case 'deadline':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lesson_plan':
        return Icons.auto_stories_rounded;
      case 'class':
        return Icons.school_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      default:
        return Icons.event_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT CARD (Pending Tasks)
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a pending assignment with deadline and priority.
class _AssignmentCard extends StatelessWidget {
  final DashboardAssignmentEntity assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final isOverdue = assignment.deadline != null &&
        assignment.deadline!.isBefore(DateTime.now());
    final priorityColor = isOverdue ? AppColors.error : AppColors.warning;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: Spacings.borderRadiusFull,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (assignment.deadline != null) ...[
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Due ${_formatDate(assignment.deadline!)}',
                      style: tt.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: Spacings.borderRadiusFull,
              ),
              child: Text(
                isOverdue ? 'OVERDUE' : assignment.status.toUpperCase(),
                style: tt.labelSmall?.copyWith(
                  color: priorityColor,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TEACHING STAT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Data model for a single teaching stat entry.
class _TeachingStatEntry {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _TeachingStatEntry({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// A compact horizontal scrollable stat card for teaching statistics.
class _TeachingStatCard extends StatelessWidget {
  final _TeachingStatEntry stat;

  const _TeachingStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: stat.color.withOpacity(0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(stat.icon, color: stat.color, size: 20),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              '${stat.value}',
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              stat.label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RECENT DOCUMENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a recently accessed document in horizontal scroll.
class _RecentDocumentCard extends StatelessWidget {
  final RecentDocumentEntity document;

  const _RecentDocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _typeColor(document.type);
    final typeIcon = _typeIcon(document.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 18),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: Spacings.borderRadiusFull,
                    ),
                    child: Text(
                      _typeLabel(document.type),
                      style: tt.labelSmall?.copyWith(
                        color: typeColor,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              document.title,
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              _formatRelativeTime(document.updatedAt),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lesson_plan':
        return Icons.auto_stories_rounded;
      case 'worksheet':
        return Icons.assignment_rounded;
      case 'scheme_of_work':
        return Icons.calendar_month_rounded;
      case 'assignment':
        return Icons.task_rounded;
      case 'presentation':
        return Icons.slideshow_rounded;
      case 'communication':
        return Icons.mail_rounded;
      case 'rubric':
        return Icons.grading_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lesson_plan':
        return AppColors.info;
      case 'worksheet':
        return AppColors.success;
      case 'scheme_of_work':
        return Colors.teal;
      case 'assignment':
        return AppColors.warning;
      case 'presentation':
        return Colors.deepPurple;
      case 'communication':
        return Colors.pink;
      case 'rubric':
        return Colors.amber;
      default:
        return AppColors.info;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'lesson_plan':
        return 'Lesson Plan';
      case 'worksheet':
        return 'Worksheet';
      case 'scheme_of_work':
        return 'Scheme of Work';
      case 'assignment':
        return 'Assignment';
      case 'presentation':
        return 'Presentation';
      case 'communication':
        return 'Communication';
      case 'rubric':
        return 'Rubric';
      default:
        return type.replaceAll('_', ' ').split(' ').map(
          (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
        ).join(' ');
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TEMPLATE CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a saved template in horizontal scroll.
class _TemplateCard extends StatelessWidget {
  final DashboardTemplateEntity template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _typeColor(template.templateType);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: Spacings.borderRadiusFull,
                    ),
                    child: Text(
                      _typeLabel(template.templateType),
                      style: tt.labelSmall?.copyWith(
                        color: typeColor,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              template.name,
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.xs),
            Row(
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Used ${template.usageCount} ${template.usageCount == 1 ? 'time' : 'times'}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lesson_plan':
        return AppColors.info;
      case 'worksheet':
        return AppColors.success;
      case 'scheme_of_work':
        return Colors.teal;
      case 'assignment':
        return AppColors.warning;
      case 'presentation':
        return Colors.deepPurple;
      case 'communication':
        return Colors.pink;
      case 'rubric':
        return Colors.amber;
      default:
        return AppColors.info;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'lesson_plan':
        return 'Lesson Plan';
      case 'worksheet':
        return 'Worksheet';
      case 'scheme_of_work':
        return 'Scheme of Work';
      case 'assignment':
        return 'Assignment';
      case 'presentation':
        return 'Presentation';
      case 'communication':
        return 'Communication';
      case 'rubric':
        return 'Rubric';
      default:
        return type.replaceAll('_', ' ').split(' ').map(
          (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
        ).join(' ');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPCOMING EVENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a single upcoming event.
class _UpcomingEventCard extends StatelessWidget {
  final DashboardEventEntity event;

  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _typeColor(event.eventType);
    final typeIcon = _typeIcon(event.eventType);
    final timeStr = _formatTime(event.startTime);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    timeStr,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'class':
        return Icons.school_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'class':
        return AppColors.success;
      case 'meeting':
        return Colors.purple;
      case 'deadline':
        return AppColors.error;
      case 'event':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  String _formatTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day} · $hour:$minute $amPm';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AI CONTENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a recently AI-generated content item.
class _AiContentCard extends StatelessWidget {
  final RecentDocumentEntity document;

  const _AiContentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _typeColor(document.type);
    final typeIcon = _typeIcon(document.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: Spacings.md),
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    _formatRelativeTime(document.updatedAt),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                borderRadius: Spacings.borderRadiusFull,
              ),
              child: Text(
                _typeLabel(document.type),
                style: tt.labelSmall?.copyWith(
                  color: typeColor,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lesson_plan':
        return Icons.auto_stories_rounded;
      case 'worksheet':
        return Icons.assignment_rounded;
      case 'scheme_of_work':
        return Icons.calendar_month_rounded;
      case 'assignment':
        return Icons.task_rounded;
      case 'presentation':
        return Icons.slideshow_rounded;
      case 'communication':
        return Icons.mail_rounded;
      case 'rubric':
        return Icons.grading_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lesson_plan':
        return AppColors.info;
      case 'worksheet':
        return AppColors.success;
      case 'scheme_of_work':
        return Colors.teal;
      case 'assignment':
        return AppColors.warning;
      case 'presentation':
        return Colors.deepPurple;
      case 'communication':
        return Colors.pink;
      case 'rubric':
        return Colors.amber;
      default:
        return AppColors.info;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'lesson_plan':
        return 'Lesson Plan';
      case 'worksheet':
        return 'Worksheet';
      case 'scheme_of_work':
        return 'Scheme of Work';
      case 'assignment':
        return 'Assignment';
      case 'presentation':
        return 'Presentation';
      case 'communication':
        return 'Communication';
      case 'rubric':
        return 'Rubric';
      default:
        return type.replaceAll('_', ' ').split(' ').map(
          (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
        ).join(' ');
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
