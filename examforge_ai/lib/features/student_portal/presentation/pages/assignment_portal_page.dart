import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Assignment portal page with list and detail views.
///
/// Features:
/// - Assignment list with status tabs (All, Pending, Submitted, Graded)
/// - Assignment cards showing: Title, Subject, Due date, Status badge, Score
/// - Assignment detail: Instructions, Submit area, Save draft / Submit buttons
/// - Teacher feedback section (for graded assignments)
/// - File attachment list with download
class AssignmentPortalPage extends ConsumerStatefulWidget {
  const AssignmentPortalPage({super.key});

  @override
  ConsumerState<AssignmentPortalPage> createState() =>
      _AssignmentPortalPageState();
}

class _AssignmentPortalPageState
    extends ConsumerState<AssignmentPortalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentAssignmentProvider.notifier).loadSubmissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(studentAssignmentProvider);

    if (assignmentState.currentSubmission != null) {
      return _buildAssignmentDetail(context, assignmentState);
    }

    return _buildAssignmentList(context, assignmentState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAssignmentList(
      BuildContext context, AssignmentState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
          ],
          onTap: (index) {
            final statusFilter = switch (index) {
              1 => SubmissionStatus.draft,
              2 => SubmissionStatus.submitted,
              3 => SubmissionStatus.graded,
              _ => null,
            };
            ref
                .read(studentAssignmentProvider.notifier)
                .filterByStatus(statusFilter);
          },
        ),
      ),
      body: state.isLoading && state.submissions.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.submissions.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Assignments',
                  message: state.error,
                  onRetry: () => ref
                      .read(studentAssignmentProvider.notifier)
                      .loadSubmissions(),
                )
              : state.submissions.isEmpty
                  ? AppEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Assignments',
                      subtitle:
                          'You have no assignments matching this filter.',
                    )
                  : ListView.builder(
                      padding: Spacings.paddingScreen,
                      itemCount: state.submissions.length,
                      itemBuilder: (context, index) {
                        final submission = state.submissions[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: Spacings.md),
                          child: _AssignmentCard(
                            submission: submission,
                            onTap: () {
                              ref
                                  .read(studentAssignmentProvider.notifier)
                                  .openSubmission(submission.id);
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAssignmentDetail(
      BuildContext context, AssignmentState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final submission = state.currentSubmission!;

    return Scaffold(
      appBar: AppBar(
        title: Text(submission.assignmentTitle ?? 'Assignment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear current submission to go back to list
            ref.read(studentAssignmentProvider.notifier).clearError();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          submission.assignmentTitle ?? 'Untitled',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      _buildStatusBadge(context, submission.status),
                    ],
                  ),
                  const SizedBox(height: Spacings.md),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.menu_book_outlined,
                        label: submission.subjectName ?? 'N/A',
                      ),
                      const SizedBox(width: Spacings.lg),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: _formatDate(submission.dueDate),
                      ),
                      if (submission.teacherName != null) ...[
                        const SizedBox(width: Spacings.lg),
                        _InfoChip(
                          icon: Icons.person_outline,
                          label: submission.teacherName!,
                        ),
                      ],
                    ],
                  ),
                  if (submission.score != null) ...[
                    const SizedBox(height: Spacings.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.lg,
                        vertical: Spacings.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: context.isDarkMode ? 0.20 : 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(Spacings.mdRadius),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assessment_outlined,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: Spacings.sm),
                          Text(
                            'Score: ${submission.score}/${submission.maxScore ?? 100}',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Spacings.sectionGap,

            // Instructions
            _buildSectionTitle(context, 'Instructions'),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Text(
                'Complete the assignment and submit your work before the due date. '
                'Make sure to follow the guidelines provided by your teacher. '
                'You can save a draft and come back to finish later.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
            Spacings.sectionGap,

            // Submit area
            _buildSectionTitle(context, 'Your Work'),
            const SizedBox(height: Spacings.sm),
            TextField(
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: cs.surfaceContainerLow,
                enabled: submission.status == SubmissionStatus.draft ||
                    submission.status == SubmissionStatus.returned,
              ),
            ),
            const SizedBox(height: Spacings.md),

            // File attachments
            _buildSectionTitle(context, 'Attachments'),
            const SizedBox(height: Spacings.sm),
            if (submission.attachments.isEmpty)
              Text(
                'No attachments yet.',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              ...submission.attachments.map(
                (attachment) => _AttachmentTile(attachment: attachment),
              ),
            const SizedBox(height: Spacings.md),
            if (submission.status == SubmissionStatus.draft ||
                submission.status == SubmissionStatus.returned)
              OutlinedButton.icon(
                onPressed: () {
                  // File picker
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Attachment'),
              ),
            Spacings.sectionGap,

            // Teacher feedback
            if (submission.teacherFeedback != null) ...[
              _buildSectionTitle(context, 'Teacher Feedback'),
              const SizedBox(height: Spacings.sm),
              AppCard(
                borderColor: AppColors.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.feedback_outlined,
                          color: AppColors.info,
                          size: Spacings.mdIcon,
                        ),
                        const SizedBox(width: Spacings.sm),
                        Text(
                          'Teacher Feedback',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.md),
                    Text(
                      submission.teacherFeedback!,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Spacings.sectionGap,
            ],

            // Action buttons
            if (submission.status == SubmissionStatus.draft ||
                submission.status == SubmissionStatus.returned)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Save draft
                      },
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              ref
                                  .read(studentAssignmentProvider.notifier)
                                  .submitAssignment(submission.id);
                            },
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SubmissionStatus status) {
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
        color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.submission,
    required this.onTap,
  });

  final AssignmentSubmissionEntity submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final (statusColor, statusLabel) = switch (submission.status) {
      SubmissionStatus.draft => (AppColors.warning, 'Draft'),
      SubmissionStatus.submitted => (AppColors.info, 'Submitted'),
      SubmissionStatus.graded => (AppColors.success, 'Graded'),
      SubmissionStatus.returned => (AppColors.error, 'Returned'),
      SubmissionStatus.lateSubmitted => (AppColors.warning, 'Late'),
      SubmissionStatus.resubmitted => (AppColors.info, 'Resubmitted'),
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  submission.assignmentTitle ?? 'Untitled Assignment',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  statusLabel,
                  style: tt.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                submission.subjectName ?? 'No Subject',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacings.lg),
              Icon(
                Icons.calendar_today_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                submission.dueDate != null
                    ? 'Due ${_formatDateShort(submission.dueDate!)}'
                    : 'No due date',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (submission.score != null) ...[
                const SizedBox(width: Spacings.lg),
                Icon(
                  Icons.assessment_outlined,
                  size: Spacings.smIcon,
                  color: AppColors.success,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${submission.score}/${submission.maxScore ?? 100}',
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
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Flexible(
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final AttachmentInfo attachment;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.attach_file),
      title: Text(
        attachment.filename,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurface,
        ),
      ),
      subtitle: attachment.size != null
          ? Text(
              _formatFileSize(attachment.size!),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.download_outlined, size: 20),
        onPressed: () {
          // Download file
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}
