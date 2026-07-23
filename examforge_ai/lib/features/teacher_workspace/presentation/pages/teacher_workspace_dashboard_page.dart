import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../providers/workspace_dashboard_provider.dart';
import '../widgets/workspace_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHER WORKSPACE DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// The main Teacher Workspace Dashboard page.
///
/// This is the entry point for the workspace module, presenting a modern
/// SaaS-style dashboard with:
/// - Welcome section with teacher name and current date
/// - Stats cards row (Lesson Plans, Worksheets, Assignments, Resources)
/// - Quick AI Actions grid (8 action buttons)
/// - Today's Schedule timeline
/// - Upcoming Events
/// - Recently Generated AI Content
/// - Draft Lesson Plans with "Generate Questions" buttons
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [CustomScrollView] with slivers.
class TeacherWorkspaceDashboardPage extends ConsumerStatefulWidget {
  const TeacherWorkspaceDashboardPage({super.key});

  @override
  ConsumerState<TeacherWorkspaceDashboardPage> createState() => _State();
}

class _State extends ConsumerState<TeacherWorkspaceDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceDashboardProvider.notifier).loadDashboard();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(workspaceDashboardProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Workspace'),
      body: _buildBody(context, dashboardState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, WorkspaceDashboardState state) {
    // Loading state
    if (state.isLoading && state.dashboardSummary == null) {
      return const Center(child: AppLoadingSpinner());
    }

    // Error state
    if (state.error != null && state.dashboardSummary == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(workspaceDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Empty state
    final summary = state.dashboardSummary;
    if (summary == null) {
      return AppEmptyState.noData(
        title: 'No Workspace Data',
        subtitle: 'Your workspace dashboard will appear here once loaded.',
        actionLabel: 'Refresh',
        onAction: () =>
            ref.read(workspaceDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Success — render dashboard
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(workspaceDashboardProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Welcome Section ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildWelcomeSection(context)),

          // ─── Stats Cards ──────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsCards(context, summary)),

          // ─── Quick AI Actions ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildQuickActionsSection(context)),

          // ─── Schedule & Events (2-column on desktop) ──────────────
          SliverToBoxAdapter(
            child: _buildScheduleAndEvents(context, summary),
          ),

          // ─── Recently Generated AI Content ────────────────────────
          SliverToBoxAdapter(
            child: _buildRecentAiContent(context, summary),
          ),

          // ─── Draft Lesson Plans ───────────────────────────────────
          SliverToBoxAdapter(
            child: _buildDraftLessonPlans(context, summary),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacings.xxl)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WELCOME SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final userName = ref.watch(userFullNameProvider) ?? 'Teacher';
    final now = DateTime.now();
    final dateStr =
        '${_weekdayName(now.weekday)}, ${_monthName(now.month)} ${now.day}, ${now.year}';

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
            'Welcome back, $userName!',
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
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS CARDS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatsCards(
    BuildContext context,
    WorkspaceDashboardEntity summary,
  ) {
    final isDesktop = context.isDesktop;
    final crossAxisCount = isDesktop ? 4 : 2;

    final stats = [
      _StatEntry(
        title: 'Lesson Plans',
        value: summary.totalLessonPlans,
        icon: Icons.auto_stories_outlined,
        color: context.colorScheme.primary,
      ),
      _StatEntry(
        title: 'Worksheets',
        value: summary.totalWorksheets,
        icon: Icons.assignment_outlined,
        color: AppColors.success,
      ),
      _StatEntry(
        title: 'Assignments',
        value: summary.totalAssignments,
        icon: Icons.task_outlined,
        color: AppColors.warning,
      ),
      _StatEntry(
        title: 'Resources',
        value: summary.totalResources,
        icon: Icons.folder_outlined,
        color: AppColors.info,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 2.0 : 1.6,
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _StatCard(stat: stats[index]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK AI ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection(BuildContext context) {
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
          const WorkspaceQuickActions(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHEDULE & EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildScheduleAndEvents(
    BuildContext context,
    WorkspaceDashboardEntity summary,
  ) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ScheduleTimeline(
                events: summary.todayEvents,
                title: "Today's Schedule",
              ),
            ),
            const SizedBox(width: Spacings.lg),
            Expanded(
              child: ScheduleTimeline(
                events: summary.upcomingEvents,
                title: 'Upcoming Events',
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        children: [
          ScheduleTimeline(
            events: summary.todayEvents,
            title: "Today's Schedule",
          ),
          const SizedBox(height: Spacings.md),
          ScheduleTimeline(
            events: summary.upcomingEvents,
            title: 'Upcoming Events',
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
    WorkspaceDashboardEntity summary,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Recently Generated AI Content'),
          const SizedBox(height: Spacings.md),
          if (summary.recentAiContent.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
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
            ...summary.recentAiContent.map(
              (item) => _AiContentCard(data: item),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DRAFT LESSON PLANS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDraftLessonPlans(
    BuildContext context,
    WorkspaceDashboardEntity summary,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Draft Lesson Plans'),
          const SizedBox(height: Spacings.md),
          if (summary.draftLessonPlans.isEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No draft lesson plans. Create one to get started!',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...summary.draftLessonPlans.map(
              (item) => _DraftLessonPlanCard(data: item),
            ),
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
}

// ═══════════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Data model for a single stat entry.
class _StatEntry {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatEntry({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// A compact stat card displaying an icon, value, and title.
class _StatCard extends StatelessWidget {
  final _StatEntry stat;

  const _StatCard({required this.stat});

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
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(stat.icon, color: stat.color, size: 20),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              '${stat.value}',
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              stat.title,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AI CONTENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a recently AI-generated content item.
class _AiContentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AiContentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final type = data['resource_type'] as String? ?? 'content';
    final title = data['title'] as String? ?? 'Untitled';
    final createdAt = data['created_at'] as String?;
    final resourceId = data['id'] as String? ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: Spacings.md),
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(
                _typeIcon(type),
                color: cs.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null)
                    Text(
                      _formatRelativeTime(createdAt),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            GenerateQuestionsButton(
              resourceType: type,
              resourceId: resourceId,
              resourceName: title,
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
      default:
        return Icons.smart_toy_rounded;
    }
  }

  String _formatRelativeTime(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DRAFT LESSON PLAN CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card showing a draft lesson plan with a "Generate Questions" button.
class _DraftLessonPlanCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DraftLessonPlanCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final title = data['title'] as String? ?? 'Untitled Lesson Plan';
    final subject = data['subject'] as String?;
    final topic = data['topic'] as String?;
    final resourceId = data['id'] as String? ?? '';
    final updatedAt = data['updated_at'] as String?;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: Spacings.md),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: cs.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subject != null || topic != null)
                        Text(
                          [subject, topic].whereType<String>().join(' · '),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Draft badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: Spacings.borderRadiusFull,
                  ),
                  child: Text(
                    'DRAFT',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.warningDark,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: Spacings.sm),
              Text(
                'Updated ${_formatRelativeTime(updatedAt)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Spacings.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GenerateQuestionsButton(
                  resourceType: 'lesson_plan',
                  resourceId: resourceId,
                  resourceName: title,
                  subject: subject,
                  topic: topic,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
