import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../providers/student_exams_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT EXAMS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Student's exam list page with tabs for Upcoming, Active, and Completed.
class StudentExamsPage extends ConsumerStatefulWidget {
  const StudentExamsPage({super.key});

  @override
  ConsumerState<StudentExamsPage> createState() => _StudentExamsPageState();
}

class _StudentExamsPageState extends ConsumerState<StudentExamsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(studentExamsProvider.notifier).loadExams();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(studentExamsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'My Exams',
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          labelStyle: tt.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: tt.labelLarge,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Failed to Load',
                    subtitle: state.error,
                    actionLabel: 'Retry',
                    onAction: () {
                      ref.read(studentExamsProvider.notifier).refreshExams();
                    },
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamList(
                      context,
                      exams: state.upcomingExams,
                      emptyIcon: Icons.event_upcoming_rounded,
                      emptyTitle: 'No Upcoming Exams',
                      emptySubtitle: 'You don\'t have any exams scheduled.',
                      isUpcoming: true,
                    ),
                    _buildExamList(
                      context,
                      exams: state.activeExams,
                      emptyIcon: Icons.play_circle_outline_rounded,
                      emptyTitle: 'No Active Exams',
                      emptySubtitle: 'There are no exams available to take right now.',
                      isActive: true,
                    ),
                    _buildExamList(
                      context,
                      exams: state.completedExams,
                      emptyIcon: Icons.check_circle_outline_rounded,
                      emptyTitle: 'No Completed Exams',
                      emptySubtitle: 'You haven\'t completed any exams yet.',
                      isCompleted: true,
                    ),
                  ],
                ),
    );
  }

  Widget _buildExamList(
    BuildContext context, {
    required List<ExamEntity> exams,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    bool isUpcoming = false,
    bool isActive = false,
    bool isCompleted = false,
  }) {
    if (exams.isEmpty) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(studentExamsProvider.notifier).refreshExams(),
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacings.md),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: _StudentExamCard(
              exam: exam,
              isUpcoming: isUpcoming,
              isActive: isActive,
              isCompleted: isCompleted,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT EXAM CARD
// ═══════════════════════════════════════════════════════════════════════

class _StudentExamCard extends StatelessWidget {
  const _StudentExamCard({
    required this.exam,
    this.isUpcoming = false,
    this.isActive = false,
    this.isCompleted = false,
  });

  final ExamEntity exam;
  final bool isUpcoming;
  final bool isActive;
  final bool isCompleted;

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _countdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    if (days > 0) return '$days day${days > 1 ? 's' : ''} $hours hr';
    if (hours > 0) return '$hours hr $minutes min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    Color accentColor;
    IconData statusIcon;
    String statusLabel;

    if (isActive) {
      accentColor = AppColors.successOf(cs.brightness);
      statusIcon = Icons.play_circle_rounded;
      statusLabel = 'Active Now';
    } else if (isUpcoming) {
      accentColor = AppColors.infoOf(cs.brightness);
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Upcoming';
    } else {
      accentColor = cs.onSurfaceVariant;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Completed';
    }

    return AppCard(
      onTap: isActive
          ? () {
              // Navigate to exam take page
            }
          : isCompleted
              ? () {
                  // Navigate to result view
                }
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: accentColor),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      statusLabel,
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Info chips
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            children: [
              _infoRow(context, Icons.subject_rounded, exam.subjectId),
              _infoRow(context, Icons.calendar_today_rounded, _formatDate(exam.startTime)),
              _infoRow(context, Icons.access_time_rounded, _formatTime(exam.startTime)),
              _infoRow(context, Icons.timer_rounded, '${exam.timeLimitMinutes} min'),
              _infoRow(context, Icons.quiz_rounded, '${exam.questions.length} questions'),
            ],
          ),

          // Countdown for upcoming
          if (isUpcoming && exam.startTime.isAfter(DateTime.now())) ...[
            const SizedBox(height: Spacings.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: AppColors.infoOf(cs.brightness)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.infoOf(cs.brightness)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'Starts in ${_countdown(exam.startTime)}',
                    style: tt.bodySmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: AppColors.infoOf(cs.brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: Spacings.md),

          // Action button
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Start Exam',
                onPressed: () {
                  // Navigate to exam take page
                },
                variant: AppButtonVariant.elevated,
                icon: Icons.play_arrow_rounded,
                fullWidth: true,
              ),
            )
          else if (isCompleted)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'View Result',
                onPressed: () {
                  // Navigate to result view
                },
                variant: AppButtonVariant.tonal,
                icon: Icons.bar_chart_rounded,
                fullWidth: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Flexible(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
