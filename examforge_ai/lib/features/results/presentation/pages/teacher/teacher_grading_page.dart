import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../../providers/results_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHER GRADING PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page where teachers review and grade subjective answers with AI
/// grading suggestions.
///
/// Shows a list of pending AI grading suggestions, allows the teacher
/// to accept, override, or add comments, and supports batch grading.
class TeacherGradingPage extends ConsumerStatefulWidget {
  const TeacherGradingPage({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<TeacherGradingPage> createState() =>
      _TeacherGradingPageState();
}

class _TeacherGradingPageState extends ConsumerState<TeacherGradingPage> {
  /// Map of answerId → override score controller.
  final Map<String, TextEditingController> _overrideControllers = {};

  /// Map of answerId → comment controller.
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(aiGradingProvider.notifier)
          .loadPendingGradings(widget.examId);
      ref.read(teacherGradingProvider.notifier).loadExamFeedback(
            examId: widget.examId,
            teacherId: 'current_teacher', // TODO: inject from auth
          );
    });
  }

  @override
  void dispose() {
    for (final c in _overrideControllers.values) {
      c.dispose();
    }
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final aiState = ref.watch(aiGradingProvider);
    final teacherState = ref.watch(teacherGradingProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Grading Review',
        actions: [
          AppButton(
            label: 'Batch Grade All',
            onPressed: aiState.isGrading
                ? null
                : () => _batchGradeAll(context),
            variant: AppButtonVariant.elevated,
            size: AppButtonSize.small,
            icon: Icons.auto_fix_high_rounded,
            isLoading: aiState.isGrading,
          ),
          const SizedBox(width: Spacings.md),
        ],
      ),
      body: aiState.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : _buildBody(context, aiState, teacherState),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    AiGradingState aiState,
    TeacherGradingState teacherState,
  ) {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Batch grading progress ───────────────────────────
              if (aiState.isGrading) ...[
                _buildBatchGradingProgress(context, aiState),
                const SizedBox(height: Spacings.xl),
              ],

              // ── Summary row ──────────────────────────────────────
              _buildSummaryRow(context, aiState, teacherState),
              const SizedBox(height: Spacings.xl),

              // ── Error state ──────────────────────────────────────
              if (aiState.error != null)
                _buildErrorBanner(context, aiState.error!, onRetry: () {
                  ref
                      .read(aiGradingProvider.notifier)
                      .loadPendingGradings(widget.examId);
                }),

              // ── Success message ──────────────────────────────────
              if (aiState.successMessage != null)
                _buildSuccessBanner(context, aiState.successMessage!),

              // ── Pending gradings list ────────────────────────────
              if (aiState.pendingGradings.isEmpty)
                AppEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All Graded!',
                  subtitle:
                      'There are no pending AI grading suggestions to review.',
                )
              else
                ...aiState.pendingGradings.map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _GradingCard(
                      result: result,
                      isSaving: teacherState.isSaving,
                      onAccept: () => _acceptGrading(result),
                      onOverride: () => _overrideGrading(result),
                      overrideController:
                          _controllerFor(_overrideControllers, result.id),
                      commentController:
                          _controllerFor(_commentControllers, result.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Batch Grading Progress ────────────────────────────────────────

  Widget _buildBatchGradingProgress(
      BuildContext context, AiGradingState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Text(
                'AI is grading answers…',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: const LinearProgressIndicator(
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Row ───────────────────────────────────────────────────

  Widget _buildSummaryRow(
    BuildContext context,
    AiGradingState aiState,
    TeacherGradingState teacherState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      children: [
        _summaryChip(
          context,
          icon: Icons.pending_actions_rounded,
          label: 'Pending',
          value: '${aiState.pendingCount}',
          color: AppColors.warningOf(cs.brightness),
        ),
        const SizedBox(width: Spacings.md),
        _summaryChip(
          context,
          icon: Icons.check_circle_rounded,
          label: 'Reviewed',
          value: '${aiState.completedCount}',
          color: AppColors.successOf(cs.brightness),
        ),
        const SizedBox(width: Spacings.md),
        _summaryChip(
          context,
          icon: Icons.rate_review_rounded,
          label: 'My Feedback',
          value: '${teacherState.gradedCount}',
          color: cs.primary,
        ),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Spacings.mdIcon, color: color),
          const SizedBox(width: Spacings.sm),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ─── Error Banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner(BuildContext context, String error,
      {required VoidCallback onRetry}) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.errorOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.errorOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                error,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            AppButton(
              label: 'Retry',
              onPressed: onRetry,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success Banner ────────────────────────────────────────────────

  Widget _buildSuccessBanner(BuildContext context, String message) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.successOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.successOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.successOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _acceptGrading(AiGradingResultEntity result) async {
    await ref.read(aiGradingProvider.notifier).reviewGrading(
          aiGradingId: result.id,
          finalScore: result.suggestedScore,
          isAccepted: true,
        );
  }

  Future<void> _overrideGrading(AiGradingResultEntity result) async {
    final overrideCtrl = _controllerFor(_overrideControllers, result.id);
    final commentCtrl = _controllerFor(_commentControllers, result.id);

    final overrideText = overrideCtrl.text.trim();
    final overrideScore = double.tryParse(overrideText);

    if (overrideScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid score')),
      );
      return;
    }

    if (overrideScore < 0 || overrideScore > result.maxPossible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Score must be between 0 and ${result.maxPossible}'),
        ),
      );
      return;
    }

    await ref.read(aiGradingProvider.notifier).reviewGrading(
          aiGradingId: result.id,
          finalScore: overrideScore,
          isAccepted: false,
          reviewComment: commentCtrl.text.trim().isNotEmpty
              ? commentCtrl.text.trim()
              : null,
        );

    overrideCtrl.clear();
    commentCtrl.clear();
  }

  Future<void> _batchGradeAll(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Batch Grade All?',
      message:
          'This will request AI grading for all ungraded subjective answers in this exam. This may take a while.',
      confirmText: 'Start Grading',
    );

    if (confirmed == true) {
      ref.read(aiGradingProvider.notifier).batchGradeExam(widget.examId);
    }
  }

  // ─── Controller Helper ─────────────────────────────────────────────

  TextEditingController _controllerFor(
    Map<String, TextEditingController> map,
    String key,
  ) {
    return map.putIfAbsent(key, TextEditingController.new);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GRADING CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// A card displaying a single AI grading suggestion with accept/override
/// actions.
class _GradingCard extends StatelessWidget {
  const _GradingCard({
    required this.result,
    required this.isSaving,
    required this.onAccept,
    required this.onOverride,
    required this.overrideController,
    required this.commentController,
  });

  final AiGradingResultEntity result;
  final bool isSaving;
  final VoidCallback onAccept;
  final VoidCallback onOverride;
  final TextEditingController overrideController;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────
          Row(
            children: [
              _statusChip(context, result.status),
              const Spacer(),
              Text(
                'Student ${result.studentId.substring(0, 6)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Question & Answer ────────────────────────────────────
          _buildLabeledSection(
            context,
            label: 'Question',
            icon: Icons.help_outline_rounded,
            child: Text(
              result.explanation ?? 'Question content not available',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: Spacings.md),

          _buildLabeledSection(
            context,
            label: 'Student Answer',
            icon: Icons.edit_note_rounded,
            child: Text(
              result.explanation ?? 'Student answer not available',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // ── AI Suggested Score & Confidence ──────────────────────
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Suggested Score',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                          letterSpacing: AppTypography.lsLabel,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${result.suggestedScore.toStringAsFixed(1)} / ${result.maxPossible.toStringAsFixed(0)}',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                          letterSpacing: AppTypography.lsLabel,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Row(
                        children: [
                          _confidenceIndicator(context, result.confidenceScore),
                          const SizedBox(width: Spacings.sm),
                          Text(
                            result.confidenceLabel,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: _confidenceColor(
                                  context, result.confidenceScore),
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
          const SizedBox(height: Spacings.lg),

          // ── AI Explanation ───────────────────────────────────────
          if (result.explanation != null) ...[
            _buildLabeledSection(
              context,
              label: 'AI Explanation',
              icon: Icons.psychology_rounded,
              child: Text(
                result.explanation!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Spacings.md),
          ],

          // ── Strengths & Weaknesses ───────────────────────────────
          if (result.strengths.isNotEmpty || result.weaknesses.isNotEmpty)
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: [
                ...result.strengths.map(
                  (s) => Chip(
                    avatar: Icon(Icons.add_circle_outline_rounded,
                        size: Spacings.smIcon,
                        color: AppColors.successOf(cs.brightness)),
                    label: Text(s,
                        style: tt.bodySmall?.copyWith(
                            color: AppColors.successOf(cs.brightness))),
                    side: BorderSide.none,
                    backgroundColor: AppColors.successOf(cs.brightness)
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                ),
                ...result.weaknesses.map(
                  (w) => Chip(
                    avatar: Icon(Icons.remove_circle_outline_rounded,
                        size: Spacings.smIcon,
                        color: AppColors.warningOf(cs.brightness)),
                    label: Text(w,
                        style: tt.bodySmall?.copyWith(
                            color: AppColors.warningOf(cs.brightness))),
                    side: BorderSide.none,
                    backgroundColor: AppColors.warningOf(cs.brightness)
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                ),
              ],
            ),

          const Divider(height: Spacings.xl),

          // ── Override Score Input ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: overrideController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Override Score',
                    hintText: '0 – ${result.maxPossible.toStringAsFixed(0)}',
                    prefixIcon: const Icon(Icons.edit_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Spacings.smRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment (optional)',
                    prefixIcon: const Icon(Icons.comment_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Spacings.smRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Action Buttons ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Accept AI Score',
                onPressed: isSaving ? null : onAccept,
                variant: AppButtonVariant.tonal,
                size: AppButtonSize.small,
                icon: Icons.check_rounded,
                isLoading: isSaving,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Override',
                onPressed: isSaving ? null : onOverride,
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                icon: Icons.edit_rounded,
                isLoading: isSaving,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Widget _buildLabeledSection(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wSemiBold,
                letterSpacing: AppTypography.lsLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        child,
      ],
    );
  }

  Widget _statusChip(BuildContext context, AiGradingStatus status) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final color = switch (status) {
      AiGradingStatus.completed => AppColors.successOf(cs.brightness),
      AiGradingStatus.failed => AppColors.errorOf(cs.brightness),
      AiGradingStatus.processing => AppColors.infoOf(cs.brightness),
      AiGradingStatus.pending => AppColors.warningOf(cs.brightness),
      AiGradingStatus.overridden => cs.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        status.label,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
      ),
    );
  }

  Widget _confidenceIndicator(BuildContext context, double? confidence) {
    final cs = context.colorScheme;
    if (confidence == null) return const SizedBox.shrink();

    return SizedBox(
      width: 48,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: confidence,
          backgroundColor: cs.surfaceContainerHighest,
          color: _confidenceColor(context, confidence),
        ),
      ),
    );
  }

  Color _confidenceColor(BuildContext context, double? confidence) {
    if (confidence == null) return context.colorScheme.onSurfaceVariant;
    if (confidence >= 0.8) return AppColors.successOf(context.colorScheme.brightness);
    if (confidence >= 0.5) return AppColors.warningOf(context.colorScheme.brightness);
    return AppColors.errorOf(context.colorScheme.brightness);
  }
}
