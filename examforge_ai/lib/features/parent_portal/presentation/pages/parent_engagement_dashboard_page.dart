import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_engagement_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT ENGAGEMENT DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Parent Engagement Dashboard for school administrators.
///
/// Provides a comprehensive view of parent engagement across the school
/// with three tabs: Overview (metrics grid and summary cards), Students
/// Needing Support (inactive parents list), and Trends (weekly engagement
/// chart and month-over-month comparison).
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentEngagementDashboardPage extends ConsumerStatefulWidget {
  const ParentEngagementDashboardPage({super.key});

  @override
  ConsumerState<ParentEngagementDashboardPage> createState() => _State();
}

class _State extends ConsumerState<ParentEngagementDashboardPage>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────

  late TabController _tabController;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engagementState = ref.watch(parentEngagementProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Parent Engagement',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Support'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: _buildBody(context, engagementState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(BuildContext context, ParentEngagementState state) {
    // Loading state
    if (state.isLoading && state.analytics == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.analytics == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => _loadAnalytics(),
      );
    }

    final analytics = state.analytics;
    if (analytics == null) {
      return AppEmptyState.noData(
        title: 'No Data',
        subtitle: 'Engagement analytics have not been loaded yet.',
        actionLabel: 'Retry',
        onAction: () => _loadAnalytics(),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(parentEngagementProvider.notifier).refreshAnalytics(),
      child: TabBarView(
        controller: _tabController,
        children: [
          // ─── Overview Tab ───────────────────────────────────────
          _buildOverviewTab(context, analytics),

          // ─── Students Needing Support Tab ───────────────────────
          _buildSupportTab(context, analytics),

          // ─── Trends Tab ─────────────────────────────────────────
          _buildTrendsTab(context, analytics),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Spacings.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Cards ──────────────────────────────────────
          _buildSummaryCards(context, analytics),

          const SizedBox(height: Spacings.xl),

          // ─── Engagement Metrics Grid ────────────────────────────
          _buildMetricsGrid(context, analytics),

          const SizedBox(height: Spacings.xl),

          // ─── Parents Not Viewing Report Cards ───────────────────
          _buildReportCardNotViewedCard(context, analytics),

          const SizedBox(height: Spacings.lg),

          // ─── Average Message Response Time ──────────────────────
          _buildAvgResponseTimeCard(context, analytics),

          const SizedBox(height: Spacings.lg),

          // ─── Unread Announcements ───────────────────────────────
          _buildUnreadAnnouncementsCard(context, analytics),
        ],
      ),
    );
  }

  // ─── Summary Cards ──────────────────────────────────────────────────

  Widget _buildSummaryCards(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        children: [
          // Total Parents
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Total Parents',
              value: '${analytics.totalParents}',
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Active
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Active',
              value: '${analytics.activeParents}',
              color: AppColors.successOf(context.colorScheme.brightness),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Moderate
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Moderate',
              value: '${analytics.moderateParents}',
              color: AppColors.warningOf(context.colorScheme.brightness),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Inactive
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Inactive',
              value: '${analytics.inactiveParents}',
              color: AppColors.errorOf(context.colorScheme.brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.md),
        child: Column(
          children: [
            Text(
              value,
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: color,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Metrics Grid ───────────────────────────────────────────────────

  Widget _buildMetricsGrid(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final metrics = analytics.engagementByMetric;

    final metricEntries = [
      _MetricEntry(
        label: 'Report Card Views',
        icon: Icons.description_outlined,
        value: metrics['report_card_viewed'] ?? 0,
        color: AppColors.successOf(cs.brightness),
      ),
      _MetricEntry(
        label: 'Announcements Read',
        icon: Icons.campaign_outlined,
        value: metrics['announcement_read'] ?? 0,
        color: AppColors.infoOf(cs.brightness),
      ),
      _MetricEntry(
        label: 'Messages Sent',
        icon: Icons.chat_outlined,
        value: metrics['message_sent'] ?? 0,
        color: const Color(0xFF7C3AED),
      ),
      _MetricEntry(
        label: 'Meetings Attended',
        icon: Icons.people_outlined,
        value: metrics['meeting_attended'] ?? 0,
        color: const Color(0xFFF97316),
      ),
      _MetricEntry(
        label: 'Assignment Checks',
        icon: Icons.assignment_outlined,
        value: metrics['assignment_checked'] ?? 0,
        color: AppColors.warningOf(cs.brightness),
      ),
      _MetricEntry(
        label: 'AI Assistant Uses',
        icon: Icons.auto_awesome_outlined,
        value: metrics['ai_assistant_used'] ?? 0,
        color: const Color(0xFF06B6D4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Metrics',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacings.sm,
            crossAxisSpacing: Spacings.sm,
            childAspectRatio: 2.0,
            children: metricEntries.map((entry) {
              return Card(
                elevation: Spacings.elevationNone,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacings.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: entry.color.withValues(alpha: 0.12),
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Icon(
                          entry.icon,
                          color: entry.color,
                          size: Spacings.mdIcon,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${entry.value}',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: AppTypography.wBold,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              entry.label,
                              style: tt.labelSmall?.copyWith(
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
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Report Card Not Viewed Card ────────────────────────────────────

  Widget _buildReportCardNotViewedCard(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: AppColors.warningOf(cs.brightness).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
          side: BorderSide(
            color: AppColors.warningOf(cs.brightness).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                color: AppColors.warningOf(cs.brightness),
                size: Spacings.lgIcon,
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parents Not Viewing Report Cards',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      '${analytics.reportCardNotViewed} parents have not viewed the latest report card.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacings.sm),
              FilledButton.tonal(
                onPressed: () {
                  // TODO: Show list of parents
                },
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'View List',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Average Response Time Card ─────────────────────────────────────

  Widget _buildAvgResponseTimeCard(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final hours = analytics.avgMessageResponseHours;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.infoOf(cs.brightness).withValues(alpha: 0.12),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  color: AppColors.infoOf(cs.brightness),
                  size: Spacings.mdIcon,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Message Response Time',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      hours != null
                          ? '${hours.toStringAsFixed(1)} hours'
                          : 'No data',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Unread Announcements Card ──────────────────────────────────────

  Widget _buildUnreadAnnouncementsCard(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final count = analytics.unreadAnnouncementCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: const Color(0xFF7C3AED),
                  size: Spacings.mdIcon,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unread Announcements',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      count != null
                          ? '$count parents have unread announcements'
                          : 'No data',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENTS NEEDING SUPPORT TAB
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSupportTab(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final students = analytics.studentsNeedingSupport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          child: Text(
            'Students with Inactive Parent Engagement',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
        ),

        // Students list
        Expanded(
          child: students.isEmpty
              ? AppEmptyState.noData(
                  title: 'No Students Needing Support',
                  subtitle:
                      'All parents are actively engaged with the portal.',
                  icon: Icons.check_circle_outline,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: Spacings.xxl),
                  itemCount: students.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.sm),
                  itemBuilder: (_, index) =>
                      _buildStudentSupportCard(context, students[index]),
                ),
        ),
      ],
    );
  }

  // ─── Student Support Card ───────────────────────────────────────────

  Widget _buildStudentSupportCard(
    BuildContext context,
    StudentSupportEntity student,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final engagementColor =
        _engagementLevelColor(student.engagementLevel, cs.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student name + engagement badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      student.studentName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // Engagement level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: engagementColor.withValues(alpha: 0.12),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text(
                      _engagementLevelLabel(student.engagementLevel),
                      style: tt.labelSmall?.copyWith(
                        color: engagementColor,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xs),

              // Parent name
              if (student.parentName != null)
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'Parent: ${student.parentName}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

              // Last active
              if (student.lastActive != null) ...[
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'Last active: ${_formatTimeAgo(student.lastActive!)}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: Spacings.md),

              // Action buttons
              Row(
                children: [
                  // Contact Parent
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to messaging
                      },
                      icon: Icon(
                        Icons.chat_outlined,
                        size: Spacings.smIcon,
                      ),
                      label: Text(
                        'Contact Parent',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  // Schedule Meeting
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to schedule meeting
                      },
                      icon: Icon(
                        Icons.event_outlined,
                        size: Spacings.smIcon,
                      ),
                      label: Text(
                        'Schedule Meeting',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
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
  // TRENDS TAB
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrendsTab(
    BuildContext context,
    EngagementAnalyticsEntity analytics,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final trends = analytics.engagementTrends;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Spacings.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Weekly Engagement Trend Chart ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            child: Text(
              'Weekly Engagement Trend',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
              ),
              child: Padding(
                padding: Spacings.paddingCard,
                child: trends.isEmpty
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No trend data available',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : _buildTrendChart(context, trends),
              ),
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // ─── Legend ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: Spacings.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metrics Legend',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    _legendRow(
                      context,
                      color: AppColors.successOf(cs.brightness),
                      label: 'Report Card Views',
                    ),
                    _legendRow(
                      context,
                      color: AppColors.infoOf(cs.brightness),
                      label: 'Announcements Read',
                    ),
                    _legendRow(
                      context,
                      color: const Color(0xFF7C3AED),
                      label: 'Messages Sent',
                    ),
                    _legendRow(
                      context,
                      color: const Color(0xFFF97316),
                      label: 'Meetings Attended',
                    ),
                    _legendRow(
                      context,
                      color: AppColors.warningOf(cs.brightness),
                      label: 'Assignment Checks',
                    ),
                    _legendRow(
                      context,
                      color: const Color(0xFF06B6D4),
                      label: 'AI Assistant Uses',
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // ─── Comparison ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: Spacings.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month vs Last Month',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.md),
                    Row(
                      children: [
                        // This month
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'This Month',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                              const SizedBox(height: Spacings.xs),
                              Text(
                                '${analytics.activeParents + analytics.moderateParents}',
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: AppTypography.wBold,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                'engaged parents',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // VS divider
                        Container(
                          width: 1,
                          height: 60,
                          color: cs.outlineVariant,
                        ),
                        // Last month
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Last Month',
                                style: tt.labelMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                              const SizedBox(height: Spacings.xs),
                              Text(
                                '—',
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: AppTypography.wBold,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'engaged parents',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ─── Trend Chart (Simple Bar Chart) ─────────────────────────────────

  Widget _buildTrendChart(
    BuildContext context,
    List<EngagementTrendEntity> trends,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final maxInteractions =
        trends.map((t) => t.interactions).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trends.map((trend) {
          final heightRatio = maxInteractions > 0
              ? trend.interactions / maxInteractions
              : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value label
                  Text(
                    '${trend.interactions}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  // Bar
                  Container(
                    height: (heightRatio * 140).clamp(4, 140),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(Spacings.xs),
                        topRight: Radius.circular(Spacings.xs),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  // Day label
                  Text(
                    '${trend.date.day}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Legend Row ─────────────────────────────────────────────────────

  Widget _legendRow(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.xs),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: Spacings.borderRadiusSm,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              // Summary cards
              Row(
                children: List.generate(
                  4,
                  (_) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Spacings.sm),
                      child: AppLoadingShimmer.box(
                        height: 80,
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacings.xl),
              // Metrics grid
              AppLoadingShimmer.box(
                height: 200,
                borderRadius: Spacings.borderRadiusMd,
              ),
              const SizedBox(height: Spacings.lg),
              // Cards
              AppLoadingShimmer.box(
                height: 100,
                borderRadius: Spacings.borderRadiusMd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads engagement analytics.
  void _loadAnalytics() {
    // In production, the school ID comes from the auth state.
    // Using a placeholder for now.
    const schoolId = 'current_school';
    ref.read(parentEngagementProvider.notifier).loadAnalytics(schoolId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the colour for an engagement level.
  Color _engagementLevelColor(String? level, Brightness brightness) {
    switch (level?.toLowerCase()) {
      case 'active':
      case 'high':
        return AppColors.successOf(brightness);
      case 'moderate':
      case 'medium':
        return AppColors.warningOf(brightness);
      case 'inactive':
      case 'low':
        return AppColors.errorOf(brightness);
      default:
        return AppColors.infoOf(brightness);
    }
  }

  /// Returns the label for an engagement level.
  String _engagementLevelLabel(String? level) {
    switch (level?.toLowerCase()) {
      case 'active':
      case 'high':
        return 'Active';
      case 'moderate':
      case 'medium':
        return 'Moderate';
      case 'inactive':
      case 'low':
        return 'Inactive';
      default:
        return level ?? 'Unknown';
    }
  }

  /// Formats a [DateTime] as a relative time-ago string.
  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} months ago';
    return '${diff.inDays ~/ 365} years ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// A data holder for an engagement metric display entry.
class _MetricEntry {
  const _MetricEntry({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
  });

  /// Display label for the metric.
  final String label;

  /// Icon for the metric.
  final IconData icon;

  /// Numeric value of the metric.
  final int value;

  /// Tint colour for the metric icon and background.
  final Color color;
}
