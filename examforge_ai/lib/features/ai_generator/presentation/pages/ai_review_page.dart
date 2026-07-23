import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../providers/ai_review_provider.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI REVIEW PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Review & Approve page with tab bar for different review statuses,
/// list of ReviewQuestionCard widgets, filtering, and batch actions.
///
/// ```dart
/// AiReviewPage()
/// ```
class AiReviewPage extends ConsumerStatefulWidget {
  const AiReviewPage({super.key});

  @override
  ConsumerState<AiReviewPage> createState() => _AiReviewPageState();
}

class _AiReviewPageState extends ConsumerState<AiReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    Tab(text: 'Pending'),
    Tab(text: 'Approved'),
    Tab(text: 'Rejected'),
    Tab(text: 'Needs Revision'),
  ];

  static const _tabStatuses = [
    ReviewStatus.pending,
    ReviewStatus.approved,
    ReviewStatus.rejected,
    ReviewStatus.needsRevision,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiReviewProvider.notifier).loadPendingQuestions(
            filter: ReviewStatus.pending,
          );
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _tabStatuses[_tabController.index];
    ref.read(aiReviewProvider.notifier).setFilter(status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiReviewProvider);
    final notifier = ref.read(aiReviewProvider.notifier);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Review & Approve',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
            onSelected: (value) {
              // Apply filter
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'all', child: Text('All Subjects')),
              const PopupMenuItem(value: 'mcq', child: Text('Multiple Choice')),
              const PopupMenuItem(value: 'tf', child: Text('True/False')),
            ],
          ),
          if (state.pendingQuestions.isNotEmpty &&
              state.filter == ReviewStatus.pending)
            AppIconButton(
              icon: Icons.done_all_rounded,
              onPressed: () => _batchApprove(state, notifier),
              tooltip: 'Approve All',
            ),
        ],
      ),
      body: state.isLoading && state.pendingQuestions.isEmpty
          ? const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null && state.pendingQuestions.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to load questions',
                  message: state.error,
                  onRetry: () => notifier.loadPendingQuestions(
                    filter: _tabStatuses[_tabController.index],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabStatuses.map((status) {
                    return _buildQuestionList(
                      state: state,
                      notifier: notifier,
                      status: status,
                    );
                  }).toList(),
                ),
    );
  }

  // ── Question List ──────────────────────────────────────────────────

  Widget _buildQuestionList({
    required AiReviewState state,
    required AiReviewNotifier notifier,
    required ReviewStatus status,
  }) {
    final questions = state.pendingQuestions
        .where((q) => q.reviewStatus == status)
        .toList();

    if (questions.isEmpty) {
      return AppEmptyState(
        icon: _emptyIcon(status),
        title: _emptyTitle(status),
        subtitle: _emptySubtitle(status),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadPendingQuestions(filter: status),
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacings.lg),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
        itemBuilder: (context, index) {
          final question = questions[index];
          return ReviewQuestionCard(
            question: question,
            onApprove: status != ReviewStatus.approved
                ? () => notifier.approve(question.id)
                : null,
            onReject: status != ReviewStatus.rejected
                ? () => _showRejectDialog(question.id, notifier)
                : null,
            onRequestRevision: status != ReviewStatus.needsRevision
                ? () => _showRevisionDialog(question.id, notifier)
                : null,
            onImprove: () => _showImproveSheet(question.id, notifier),
            onSaveToQb: question.reviewStatus == ReviewStatus.approved &&
                    question.questionBankId == null
                ? () => notifier.saveApprovedToQuestionBank(question.id)
                : null,
            isActionLoading: state.isReviewing,
          );
        },
      ),
    );
  }

  IconData _emptyIcon(ReviewStatus status) {
    return switch (status) {
      ReviewStatus.pending => Icons.schedule_rounded,
      ReviewStatus.approved => Icons.check_circle_outline_rounded,
      ReviewStatus.rejected => Icons.cancel_outlined,
      ReviewStatus.needsRevision => Icons.edit_note_rounded,
    };
  }

  String _emptyTitle(ReviewStatus status) {
    return switch (status) {
      ReviewStatus.pending => 'No Pending Questions',
      ReviewStatus.approved => 'No Approved Questions',
      ReviewStatus.rejected => 'No Rejected Questions',
      ReviewStatus.needsRevision => 'No Questions Need Revision',
    };
  }

  String _emptySubtitle(ReviewStatus status) {
    return switch (status) {
      ReviewStatus.pending => 'Generate questions to start the review process.',
      ReviewStatus.approved => 'Approved questions will appear here.',
      ReviewStatus.rejected => 'Rejected questions will appear here.',
      ReviewStatus.needsRevision => 'Questions needing revision will appear here.',
    };
  }

  // ── Batch Actions ──────────────────────────────────────────────────

  Future<void> _batchApprove(
    AiReviewState state,
    AiReviewNotifier notifier,
  ) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Approve All Pending?',
      message:
          'This will approve ${state.pendingQuestions.where((q) => q.reviewStatus == ReviewStatus.pending).length} pending questions. This action cannot be undone.',
      confirmText: 'Approve All',
      isDestructive: false,
    );

    if (confirmed == true) {
      final pending = state.pendingQuestions
          .where((q) => q.reviewStatus == ReviewStatus.pending)
          .toList();
      for (final q in pending) {
        await notifier.approve(q.id);
      }
    }
  }

  // ── Dialogs & Bottom Sheets ────────────────────────────────────────

  Future<void> _showRejectDialog(
    String questionId,
    AiReviewNotifier notifier,
  ) async {
    final reason = await AppDialog.showCustom<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject Question',
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.md),
            AppTextField(
              controller: controller,
              label: 'Reason',
              hint: 'Why is this question being rejected?',
              maxLines: 3,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(null),
                  variant: AppButtonVariant.text,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Reject',
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                  variant: AppButtonVariant.elevated,
                ),
              ],
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      await notifier.reject(questionId, reason);
    }
  }

  Future<void> _showRevisionDialog(
    String questionId,
    AiReviewNotifier notifier,
  ) async {
    final notes = await AppDialog.showCustom<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Revision',
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.md),
            AppTextField(
              controller: controller,
              label: 'Revision Notes',
              hint: 'What changes are needed?',
              maxLines: 3,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(null),
                  variant: AppButtonVariant.text,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Request',
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                  variant: AppButtonVariant.tonal,
                ),
              ],
            ),
          ],
        );
      },
    );

    if (notes != null && notes.isNotEmpty) {
      await notifier.requestRevision(questionId, notes);
    }
  }

  void _showImproveSheet(String questionId, AiReviewNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Improve Question',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                  Wrap(
                    spacing: Spacings.sm,
                    runSpacing: Spacings.sm,
                    children: [
                      'Rewrite',
                      'Simplify',
                      'Make Difficult',
                      'New Distractors',
                      'Improve Explanation',
                      'Translate',
                    ].map((type) {
                      return ActionChip(
                        label: Text(type),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          notifier.improveAndPreview(questionId, type);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
