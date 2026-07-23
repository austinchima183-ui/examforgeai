import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/homework_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK SUBMISSIONS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Displays submissions for a specific homework, with grading dialog.
///
/// Takes [homeworkId] to load the homework and its submissions.
/// Shows stats: total submitted, graded, pending, average marks.
class HomeworkSubmissionsPage extends ConsumerStatefulWidget {
  const HomeworkSubmissionsPage({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  ConsumerState<HomeworkSubmissionsPage> createState() =>
      _HomeworkSubmissionsPageState();
}

class _HomeworkSubmissionsPageState
    extends ConsumerState<HomeworkSubmissionsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(homeworkDetailProvider.notifier)
          .loadHomework(widget.homeworkId);
    });
  }

  // ─── Computed stats ────────────────────────────────────────────────

  int get _totalSubmitted => _submissions
      .where((s) => s.status != SubmissionStatus.pending)
      .length;

  int get _totalGraded => _submissions
      .where((s) => s.status == SubmissionStatus.graded)
      .length;

  int get _totalPending => _submissions
      .where((s) => s.status == SubmissionStatus.submitted ||
          s.status == SubmissionStatus.lateSubmitted,)
      .length;

  double get _averageMarks {
    final graded = _submissions
        .where((s) => s.marksAwarded != null)
        .toList();
    if (graded.isEmpty) return 0.0;
    return graded.map((s) => s.marksAwarded!).reduce((a, b) => a + b) /
        graded.length;
  }

  List<HomeworkSubmissionEntity> get _submissions =>
      ref.read(homeworkDetailProvider).submissions;

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(homeworkDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submissions',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, HomeworkDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref
            .read(homeworkDetailProvider.notifier)
            .loadHomework(widget.homeworkId),
      );
    }

    if (state.homework == null) {
      return const Center(child: Text('Homework not found'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(homeworkDetailProvider.notifier)
          .loadHomework(widget.homeworkId),
      child: CustomScrollView(
        slivers: [
          // ─── Homework Info Header ─────────────────────────────────
          SliverToBoxAdapter(child: _buildHomeworkHeader(state.homework!)),

          // ─── Stats Row ───────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsRow(context)),

          // ─── Submissions List ────────────────────────────────────
          _buildSubmissionsList(context, state),
        ],
      ),
    );
  }

  // ─── Homework Header ───────────────────────────────────────────────

  Widget _buildHomeworkHeader(HomeworkEntity homework) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      margin: const EdgeInsets.all(Spacings.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            homework.title,
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              _InfoChip(
                icon: Icons.book_outlined,
                label: homework.subjectName ?? 'Subject',
                color: cs.primary,
                isDark: isDark,
              ),
              const SizedBox(width: Spacings.sm),
              _InfoChip(
                icon: Icons.class_outlined,
                label: homework.className ?? 'Class',
                color: AppColors.info,
                isDark: isDark,
              ),
              const SizedBox(width: Spacings.sm),
              _InfoChip(
                icon: Icons.grade_outlined,
                label: '${homework.totalMarks.toInt()} marks',
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
          ),
          if (homework.deadline != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Deadline: ${_formatDateTime(homework.deadline!)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Submitted',
              value: '$_totalSubmitted',
              color: AppColors.info,
              isDark: isDark,
              cs: cs,
              tt: tt,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _StatCard(
              label: 'Graded',
              value: '$_totalGraded',
              color: AppColors.success,
              isDark: isDark,
              cs: cs,
              tt: tt,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _StatCard(
              label: 'Pending',
              value: '$_totalPending',
              color: AppColors.warning,
              isDark: isDark,
              cs: cs,
              tt: tt,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _StatCard(
              label: 'Avg Marks',
              value: _averageMarks.toStringAsFixed(1),
              color: cs.primary,
              isDark: isDark,
              cs: cs,
              tt: tt,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submissions List ──────────────────────────────────────────────

  Widget _buildSubmissionsList(BuildContext context, HomeworkDetailState state) {
    final submissions = state.submissions;

    if (submissions.isEmpty) {
      return const SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No Submissions Yet',
          subtitle: 'Students have not submitted their work yet.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(Spacings.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sub = submissions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: _SubmissionCard(
                submission: sub,
                totalMarks: state.homework?.totalMarks ?? 100,
                onTap: () => _showGradeDialog(context, sub),
              ),
            );
          },
          childCount: submissions.length,
        ),
      ),
    );
  }

  // ─── Grade Dialog ──────────────────────────────────────────────────

  void _showGradeDialog(
    BuildContext context,
    HomeworkSubmissionEntity submission,
  ) {
    final marksController = TextEditingController(
      text: submission.marksAwarded?.toStringAsFixed(1) ?? '',
    );
    final commentController = TextEditingController(
      text: submission.teacherComment ?? '',
    );
    bool isGrading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Grade Submission',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student name
                Text(
                  submission.studentName ?? 'Student',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
                if (submission.isLate)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacings.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        'Late Submission',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: Spacings.lg),
                // Marks input
                TextField(
                  controller: marksController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    hintText: 'Out of ${submission.maxMarks?.toInt() ?? 100}',
                    prefixIcon: const Icon(Icons.grade_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacings.md),
                // Comment input
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Teacher Comment',
                    hintText: 'Optional feedback...',
                    prefixIcon: Icon(Icons.comment_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Grade',
              onPressed: isGrading
                  ? null
                  : () async {
                      final marks = double.tryParse(marksController.text.trim());
                      if (marks == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter valid marks.')),
                        );
                        return;
                      }
                      setDialogState(() => isGrading = true);
                      final graded = submission.copyWith(
                        marksAwarded: marks,
                        teacherComment: commentController.text.trim().isNotEmpty
                            ? commentController.text.trim()
                            : null,
                        status: SubmissionStatus.graded,
                        gradedAt: DateTime.now(),
                      );
                      await ref
                          .read(homeworkDetailProvider.notifier)
                          .gradeSubmission(graded);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
              variant: AppButtonVariant.elevated,
              size: AppButtonSize.small,
              isLoading: isGrading,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} $h:$m';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Spacings.smIcon, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.cs,
    required this.tt,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.totalMarks,
    this.onTap,
  });

  final HomeworkSubmissionEntity submission;
  final double totalMarks;
  final VoidCallback? onTap;

  Color _statusColor(SubmissionStatus status) {
    return switch (status) {
      SubmissionStatus.pending => AppColors.info,
      SubmissionStatus.submitted => const Color(0xFF3B82F6),
      SubmissionStatus.lateSubmitted => AppColors.warning,
      SubmissionStatus.graded => AppColors.success,
      SubmissionStatus.returned => const Color(0xFF8B5CF6),
    };
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final statusColor = _statusColor(submission.status);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: submission.studentAvatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    child: Image.network(
                      submission.studentAvatarUrl!,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: cs.primary,
                      ),
                    ),
                  )
                : Icon(Icons.person_rounded, color: cs.primary),
          ),
          const SizedBox(width: Spacings.md),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        submission.studentName ?? 'Student',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (submission.isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(Spacings.fullRadius),
                        ),
                        child: Text(
                          'Late',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Text(
                      'Submitted: ${_formatDateTime(submission.submittedAt)}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (submission.marksAwarded != null) ...[
                      const Spacer(),
                      Text(
                        '${submission.marksAwarded!.toStringAsFixed(1)}/${submission.maxMarks?.toStringAsFixed(0) ?? totalMarks.toStringAsFixed(0)}',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
            ),
            child: Text(
              submission.status.label,
              style: tt.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
