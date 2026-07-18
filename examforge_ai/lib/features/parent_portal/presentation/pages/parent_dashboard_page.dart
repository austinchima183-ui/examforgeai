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
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// The main Parent Portal Dashboard page.
///
/// Presents a modern, information-dense layout with:
/// - Welcome section with parent name and current date
/// - Child summary cards (horizontal scrollable)
/// - Quick stats row (messages, notifications, events, insights)
/// - AI Insights section (severity color-coded)
/// - Upcoming events section
/// - Recent announcements section
/// - Pending assignments section (grouped by child)
/// - Notifications preview section
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [CustomScrollView] with slivers.
class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() => _State();
}

class _State extends ConsumerState<ParentDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentDashboardProvider.notifier).loadDashboard();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(parentDashboardProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Parent Portal',
        actions: [
          _buildNotificationBell(context, dashboardState),
        ],
      ),
      body: _buildBody(context, dashboardState),
    );
  }

  // ─── Notification Bell ─────────────────────────────────────────────

  /// Builds the notification bell icon with an unread count badge.
  Widget _buildNotificationBell(
    BuildContext context,
    ParentDashboardState state,
  ) {
    final cs = context.colorScheme;
    final unreadCount = state.dashboard?.unreadNotifications ?? 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: cs.onSurface,
            size: Spacings.mdIcon,
          ),
          onPressed: () => context.go(RouteNames.notifications),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(Spacings.xs),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: Spacings.lg,
                minHeight: Spacings.lg,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: AppTypography.wBold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ParentDashboardState state) {
    // Loading state
    if (state.isLoading && state.dashboard == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.dashboard == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(parentDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Empty state
    final dashboard = state.dashboard;
    if (dashboard == null) {
      return AppEmptyState.noData(
        title: 'No Dashboard Data',
        subtitle: 'Your parent portal dashboard will appear here once loaded.',
        actionLabel: 'Refresh',
        onAction: () =>
            ref.read(parentDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Success — render dashboard
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(parentDashboardProvider.notifier).refreshDashboard(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── Welcome Section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildWelcomeSection(context, dashboard),
          ),

          // ─── Child Summary Cards ──────────────────────────────────
          SliverToBoxAdapter(
            child: _buildChildSummaryCards(context, dashboard),
          ),

          // ─── Quick Stats Row ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildQuickStatsRow(context, dashboard),
          ),

          // ─── AI Insights Section ─────────────────────────────────
          SliverToBoxAdapter(
            child: _buildAiInsightsSection(context),
          ),

          // ─── Upcoming Events Section ─────────────────────────────
          SliverToBoxAdapter(
            child: _buildUpcomingEventsSection(context, dashboard),
          ),

          // ─── Recent Announcements Section ────────────────────────
          SliverToBoxAdapter(
            child: _buildAnnouncementsSection(context, dashboard),
          ),

          // ─── Pending Assignments Section ─────────────────────────
          SliverToBoxAdapter(
            child: _buildPendingAssignmentsSection(context, dashboard),
          ),

          // ─── Notifications Preview ───────────────────────────────
          SliverToBoxAdapter(
            child: _buildNotificationsPreview(context, dashboard),
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
                  // Child card shimmer
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: Spacings.md),
                      itemBuilder: (_, __) => AppLoadingShimmer.box(
                        width: 200,
                        borderRadius: Spacings.borderRadiusLg,
                      ),
                    ),
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
    ParentDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final parentName = dashboard.parentName ??
        ref.watch(userFullNameProvider) ??
        'Parent';
    final now = DateTime.now();
    final greeting = _timeOfDayGreeting(now.hour);
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
            '$greeting, $parentName!',
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
  // CHILD SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChildSummaryCards(
    BuildContext context,
    ParentDashboardEntity dashboard,
  ) {
    final children = dashboard.children;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (children.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Text(
                'My Children',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          SizedBox(
            height: children.length == 1 ? null : 170,
            child: children.length == 1
                ? _buildChildCard(context, children.first)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: children.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: Spacings.md),
                    itemBuilder: (_, index) =>
                        _buildChildCard(context, children[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummaryEntity child) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final attendancePct = (child.attendanceSummary.attendanceRate * 100)
        .round();
    final initial = child.studentName.isNotEmpty
        ? child.studentName[0].toUpperCase()
        : '?';

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
      child: InkWell(
        onTap: () => context.go(
          '${RouteNames.parentPortal}/child/${child.studentId}',
        ),
        borderRadius: Spacings.borderRadiusLg,
        child: Container(
          width: 200,
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      initial,
                      style: tt.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.studentName,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (child.className != null)
                          Text(
                            child.className!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              // Relationship badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Text(
                  child.relationship,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ),
              const Spacer(),
              // Attendance rate
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: Spacings.smIcon,
                    color: AppColors.successOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '$attendancePct% Present',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xs),
              // Pending assignments
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: Spacings.smIcon,
                    color: AppColors.warningOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '${child.pendingAssignmentsCount} Pending',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK STATS ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickStatsRow(
    BuildContext context,
    ParentDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final stats = [
      _QuickStat(
        title: 'Messages',
        value: dashboard.unreadMessages,
        icon: Icons.mail_outline,
        color: cs.primary,
      ),
      _QuickStat(
        title: 'Notifications',
        value: dashboard.unreadNotifications,
        icon: Icons.notifications_outlined,
        color: AppColors.infoOf(cs.brightness),
      ),
      _QuickStat(
        title: 'Upcoming',
        value: dashboard.upcomingEvents.length,
        icon: Icons.event_outlined,
        color: AppColors.successOf(cs.brightness),
      ),
      _QuickStat(
        title: 'Insights',
        value: dashboard.activeInsights,
        icon: Icons.auto_awesome_outlined,
        color: AppColors.warningOf(cs.brightness),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
              child: Card(
                elevation: Spacings.elevationNone,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacings.md),
                  child: Column(
                    children: [
                      Icon(stat.icon, color: stat.color, size: Spacings.lgIcon),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${stat.value}',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        stat.title,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI INSIGHTS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAiInsightsSection(BuildContext context) {
    final insights = ref.watch(parentDashboardProvider).insights;
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Insights for You',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to insights list
                },
                child: Text(
                  'View All Insights',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          if (insights.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No insights available yet',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...insights.take(3).map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: _buildInsightCard(context, insight),
                )),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    ParentAiInsightEntity insight,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final severityColor = _severityColor(insight.severity, cs.brightness);
    final severityBg =
        _severityBackgroundColor(insight.severity, cs.brightness);

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: severityBg,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text(
                    insight.severity.label,
                    style: tt.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
                const Spacer(),
                if (insight.isAiGenerated)
                  Icon(
                    Icons.auto_awesome,
                    size: Spacings.smIcon,
                    color: cs.primary,
                  ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              insight.title,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              insight.description,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to insight detail
                },
                child: Text(
                  'View Details',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPCOMING EVENTS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUpcomingEventsSection(
    BuildContext context,
    ParentDashboardEntity dashboard,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to calendar
                },
                child: Text(
                  'View Calendar',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          if (events.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No upcoming events',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: _buildEventCard(context, event),
                )),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    ParentCalendarEventEntity event,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final eventIcon = _calendarEventIcon(event.eventType);
    final eventColor = _calendarEventColor(event.eventType, cs.brightness);

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Row(
          children: [
            // Date column
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(
                vertical: Spacings.sm,
              ),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.1),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Column(
                children: [
                  Text(
                    '${event.startTime.day}',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: eventColor,
                    ),
                  ),
                  Text(
                    _monthAbbr(event.startTime.month),
                    style: tt.labelSmall?.copyWith(
                      color: eventColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacings.md),
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      Icon(eventIcon, size: Spacings.smIcon, color: eventColor),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        event.isAllDay
                            ? 'All Day'
                            : '${_formatTime(event.startTime)} – ${_formatTime(event.endTime)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
  // ANNOUNCEMENTS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAnnouncementsSection(
    BuildContext context,
    ParentDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final announcements = dashboard.recentAnnouncements.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'School Announcements',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.announcementList),
                child: Text(
                  'View All',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          if (announcements.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No announcements',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...announcements.map((announcement) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: _buildAnnouncementCard(context, announcement),
                )),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementSummaryEntity announcement,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: cs.primary,
              size: Spacings.lgIcon,
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          announcement.type,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _priorityColor(
                            announcement.priority,
                            cs.brightness,
                          ).withValues(alpha: 0.15),
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          announcement.priority,
                          style: tt.labelSmall?.copyWith(
                            color: _priorityColor(
                              announcement.priority,
                              cs.brightness,
                            ),
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
  // PENDING ASSIGNMENTS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPendingAssignmentsSection(
    BuildContext context,
    ParentDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Collect children with pending assignments
    final childrenWithPending = dashboard.children
        .where((c) => c.pendingAssignmentsCount > 0)
        .toList();

    if (childrenWithPending.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Assignments',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...childrenWithPending.map((child) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Card(
                  elevation: Spacings.elevationNone,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.warningOf(cs.brightness)
                          .withValues(alpha: 0.15),
                      child: Text(
                        '${child.pendingAssignmentsCount}',
                        style: tt.labelLarge?.copyWith(
                          color: AppColors.warningOf(cs.brightness),
                          fontWeight: AppTypography.wBold,
                        ),
                      ),
                    ),
                    title: Text(
                      child.studentName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${child.pendingAssignmentsCount} assignment${child.pendingAssignmentsCount > 1 ? 's' : ''} pending',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => context.go(
                      '${RouteNames.parentPortal}/child/${child.studentId}/assignments',
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS PREVIEW SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildNotificationsPreview(
    BuildContext context,
    ParentDashboardEntity dashboard,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final unreadCount = dashboard.unreadNotifications;

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Card(
        elevation: Spacings.elevationSm,
        color: cs.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: InkWell(
          onTap: () => context.go(RouteNames.notifications),
          borderRadius: Spacings.borderRadiusLg,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: cs.onPrimaryContainer,
                  size: Spacings.lgIcon,
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    'You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: Spacings.smIcon,
                  color: cs.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a time-of-day greeting based on the [hour].
  String _timeOfDayGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns the weekday name for the given [weekday] (1 = Monday).
  String _weekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday];
  }

  /// Returns the month name for the given [month] (1 = January).
  String _monthName(int month) {
    const names = [
      '',
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
    return names[month];
  }

  /// Returns the abbreviated month name for the given [month].
  String _monthAbbr(int month) {
    const abbrs = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return abbrs[month];
  }

  /// Formats a [DateTime] as a short time string (e.g., "2:30 PM").
  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  /// Formats a [DateTime] as a short date string.
  String _formatDate(DateTime dt) {
    return '${_monthAbbr(dt.month)} ${dt.day}';
  }

  /// Returns the color for a given [InsightSeverity].
  Color _severityColor(InsightSeverity severity, Brightness brightness) {
    switch (severity) {
      case InsightSeverity.info:
        return AppColors.infoOf(brightness);
      case InsightSeverity.warning:
        return AppColors.warningOf(brightness);
      case InsightSeverity.concern:
        return AppColors.errorOf(brightness);
      case InsightSeverity.positive:
        return AppColors.successOf(brightness);
    }
  }

  /// Returns the background color for a given [InsightSeverity].
  Color _severityBackgroundColor(
    InsightSeverity severity,
    Brightness brightness,
  ) {
    switch (severity) {
      case InsightSeverity.info:
        return AppColors.infoLight;
      case InsightSeverity.warning:
        return AppColors.warningLight;
      case InsightSeverity.concern:
        return AppColors.errorLight;
      case InsightSeverity.positive:
        return AppColors.successLight;
    }
  }

  /// Returns the icon for a given [CalendarEventType].
  IconData _calendarEventIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.school:
        return Icons.school_outlined;
      case CalendarEventType.holiday:
        return Icons.celebration_outlined;
      case CalendarEventType.meeting:
        return Icons.people_outlined;
      case CalendarEventType.exam:
        return Icons.quiz_outlined;
      case CalendarEventType.event:
        return Icons.event_outlined;
      case CalendarEventType.deadline:
        return Icons.schedule_outlined;
    }
  }

  /// Returns the color for a given [CalendarEventType].
  Color _calendarEventColor(CalendarEventType type, Brightness brightness) {
    switch (type) {
      case CalendarEventType.school:
        return AppColors.infoOf(brightness);
      case CalendarEventType.holiday:
        return AppColors.successOf(brightness);
      case CalendarEventType.meeting:
        return AppColors.warningOf(brightness);
      case CalendarEventType.exam:
        return AppColors.errorOf(brightness);
      case CalendarEventType.event:
        return AppColors.infoOf(brightness);
      case CalendarEventType.deadline:
        return AppColors.warningOf(brightness);
    }
  }

  /// Returns the color for a given priority string.
  Color _priorityColor(String priority, Brightness brightness) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return AppColors.errorOf(brightness);
      case 'medium':
        return AppColors.warningOf(brightness);
      case 'low':
        return AppColors.successOf(brightness);
      default:
        return AppColors.infoOf(brightness);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// A data holder for a single quick-stat entry on the dashboard.
class _QuickStat {
  const _QuickStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  /// Label displayed below the value.
  final String title;

  /// Numeric value displayed prominently.
  final int value;

  /// Icon displayed above the value.
  final IconData icon;

  /// Tint colour for the icon.
  final Color color;
}
