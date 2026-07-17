import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_stat_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/cbt_entities.dart';
import '../providers/exam_monitor_provider.dart';
import '../widgets/exam_timer_widget.dart';
import '../widgets/student_progress_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM MONITOR PAGE (Teacher) - Live monitoring dashboard
// ═══════════════════════════════════════════════════════════════════════

/// Live monitoring dashboard for an active exam with real-time updates.
class ExamMonitorPage extends ConsumerStatefulWidget {
  const ExamMonitorPage({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamMonitorPage> createState() => _ExamMonitorPageState();
}

class _ExamMonitorPageState extends ConsumerState<ExamMonitorPage> {
  Timer? _refreshTimer;
  MonitorFilter _filter = MonitorFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(examMonitorProvider.notifier).loadExamForMonitoring(widget.examId);
      ref.read(examMonitorProvider.notifier).startWatching(widget.examId);
    });

    // Auto-refresh stats every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(examMonitorProvider.notifier).refreshStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    ref.read(examMonitorProvider.notifier).stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examMonitorProvider);
    final exam = state.exam;
    final liveStats = state.liveStats;

    return Scaffold(
      appBar: AppAppBar(
        title: exam?.title ?? 'Exam Monitor',
        actions: [
          if (state.isWatching)
            Container(
              margin: const EdgeInsets.only(right: Spacings.md),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.successOf(cs.brightness)
                    .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.successOf(cs.brightness),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'LIVE',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: AppColors.successOf(cs.brightness),
                      letterSpacing: AppTypography.lsLabel,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: state.error != null && exam == null
          ? Center(
              child: AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to Load',
                subtitle: state.error,
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(examMonitorProvider.notifier).loadExamForMonitoring(widget.examId);
                },
              ),
            )
          : exam == null
              ? const Center(
                  child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(examMonitorProvider.notifier).refreshStats(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Spacings.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Exam Timer ──────────────────────────────────
                        if (exam.isWithinTimeWindow)
                          Center(
                            child: ExamTimerWidget(
                              timeRemaining: _calculateRemaining(exam),
                              totalDuration: Duration(minutes: exam.timeLimitMinutes),
                            ),
                          ),
                        const SizedBox(height: Spacings.xl),

                        // ── Summary Cards ───────────────────────────────
                        _buildSummaryCards(context, liveStats, state),
                        const SizedBox(height: Spacings.xl),

                        // ── Filter Tabs ─────────────────────────────────
                        _buildFilterTabs(context, cs, tt),
                        const SizedBox(height: Spacings.md),

                        // ── Student Progress Grid ───────────────────────
                        _buildStudentGrid(context, state),

                        const SizedBox(height: Spacings.xl),

                        // ── Monitoring Events Log ───────────────────────
                        _buildEventsLog(context, state),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    LiveExamStats? stats,
    ExamMonitorState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
          childAspectRatio: 1.4,
          children: [
            AppStatCard(
              title: 'Active Now',
              value: '${stats?.activeNow ?? state.activeCount}',
              icon: Icons.play_circle_rounded,
              color: AppColors.successOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Completed',
              value: '${stats?.completed ?? 0}',
              icon: Icons.check_circle_rounded,
              color: AppColors.infoOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Not Started',
              value: '${stats?.notStarted ?? 0}',
              icon: Icons.pending_rounded,
              color: context.colorScheme.onSurfaceVariant,
            ),
            AppStatCard(
              title: 'Suspicious',
              value: '${state.unresolvedEventCount}',
              icon: Icons.warning_rounded,
              color: state.unresolvedEventCount > 0
                  ? AppColors.errorOf(context.colorScheme.brightness)
                  : context.colorScheme.onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTabs(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Text(
          'Students',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        SegmentedButton<MonitorFilter>(
          segments: const [
            ButtonSegment(value: MonitorFilter.all, label: Text('All')),
            ButtonSegment(value: MonitorFilter.active, label: Text('Active')),
            ButtonSegment(
                value: MonitorFilter.disconnected, label: Text('Offline')),
            ButtonSegment(value: MonitorFilter.flagged, label: Text('Flagged')),
          ],
          selected: {_filter},
          onSelectionChanged: (modes) {
            setState(() => _filter = modes.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(tt.labelSmall),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentGrid(BuildContext context, ExamMonitorState state) {
    var sessions = state.activeSessions;

    // Apply filter
    sessions = switch (_filter) {
      MonitorFilter.active => sessions.where((s) => s.isActive && s.connectionStatus == 'connected').toList(),
      MonitorFilter.disconnected => sessions.where((s) => s.connectionStatus == 'disconnected').toList(),
      MonitorFilter.flagged => sessions.where((s) => s.tabSwitchCount > 0 || s.focusLostCount > 0).toList(),
      MonitorFilter.all => sessions,
    };

    if (sessions.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Students',
        subtitle: _filter == MonitorFilter.all
            ? 'No active student sessions.'
            : 'No students match this filter.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final violations = state.monitoringEvents
                .where((e) => e.attemptId == session.attemptId && !e.isResolved)
                .length;
            final isSuspicious = session.tabSwitchCount > 2 || violations > 0;

            return StudentProgressCard(
              session: session,
              studentName: 'Student ${session.studentId.substring(0, 6)}',
              totalQuestions: state.exam?.questions.length ?? 0,
              violationCount: violations,
              isSuspicious: isSuspicious,
              onForceSubmit: () => _confirmForceSubmit(session.attemptId),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsLog(BuildContext context, ExamMonitorState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final events = state.monitoringEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Monitoring Events',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            if (events.isNotEmpty)
              Text(
                '${state.unresolvedEventCount} unresolved',
                style: tt.bodySmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: state.unresolvedEventCount > 0
                      ? AppColors.warningOf(cs.brightness)
                      : AppColors.successOf(cs.brightness),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        if (events.isEmpty)
          AppEmptyState(
            icon: Icons.shield_outlined,
            title: 'No Events',
            subtitle: 'No monitoring events detected so far.',
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventItem(context, event);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEventItem(BuildContext context, MonitoringLogEntity event) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final severityColor = switch (event.severity) {
      'critical' => AppColors.errorOf(cs.brightness),
      'warning' => AppColors.warningOf(cs.brightness),
      _ => AppColors.infoOf(cs.brightness),
    };

    return ListTile(
      dense: true,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: event.isResolved ? cs.onSurfaceVariant : severityColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        event.eventType.label,
        style: tt.bodyMedium?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: cs.onSurface,
          decoration: event.isResolved ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        'Student: ${event.studentId.substring(0, 6)} · ${event.severity.toUpperCase()}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: event.isResolved
          ? Icon(Icons.check_circle_rounded, color: cs.onSurfaceVariant, size: 18)
          : TextButton(
              onPressed: () {
                ref.read(examMonitorProvider.notifier).resolveMonitoringEvent(event.id);
              },
              child: Text(
                'Resolve',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
    );
  }

  Duration _calculateRemaining(ExamEntity exam) {
    if (exam.endTime.isAfter(DateTime.now())) {
      return exam.endTime.difference(DateTime.now());
    }
    return Duration.zero;
  }

  Future<void> _confirmForceSubmit(String attemptId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Force Submit?',
      message:
          'This will force-submit the student\'s exam. This action cannot be undone.',
      isDestructive: true,
      confirmText: 'Force Submit',
    );

    if (confirmed == true) {
      ref.read(examMonitorProvider.notifier).forceSubmitStudent(attemptId);
    }
  }
}

enum MonitorFilter { all, active, disconnected, flagged }
