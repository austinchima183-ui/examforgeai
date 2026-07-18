import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/ai_entities.dart';
import 'validation_badge.dart';

// ═══════════════════════════════════════════════════════════════════════
// REVIEW QUESTION CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for the review workflow showing full question content, answer
/// options with correct answer highlighted, explanation, validation
/// results, confidence score, and teacher action buttons with inline
/// edit capability.
///
/// ```dart
/// ReviewQuestionCard(
///   question: question,
///   validationResults: results,
///   onApprove: () => approve(q.id),
///   onReject: () => reject(q.id),
///   onRequestRevision: () => revision(q.id),
///   onImprove: () => improve(q.id),
///   onSaveToQb: () => saveToQb(q.id),
/// )
/// ```
class ReviewQuestionCard extends StatefulWidget {
  const ReviewQuestionCard({
    super.key,
    required this.question,
    this.validationResults = const [],
    this.improvementResult,
    this.onApprove,
    this.onReject,
    this.onRequestRevision,
    this.onImprove,
    this.onSaveToQb,
    this.isActionLoading = false,
  });

  final GeneratedQuestionEntity question;
  final List<ValidationResultEntity> validationResults;
  final QuestionImprovementEntity? improvementResult;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRequestRevision;
  final VoidCallback? onImprove;
  final VoidCallback? onSaveToQb;
  final bool isActionLoading;

  @override
  State<ReviewQuestionCard> createState() => _ReviewQuestionCardState();
}

class _ReviewQuestionCardState extends State<ReviewQuestionCard> {
  bool _isEditing = false;
  late TextEditingController _contentController;
  late TextEditingController _explanationController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.question.content);
    _explanationController = TextEditingController(
      text: widget.question.explanation ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ReviewQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question.content != oldWidget.question.content) {
      _contentController.text = widget.question.content;
    }
    if (widget.question.explanation != oldWidget.question.explanation) {
      _explanationController.text = widget.question.explanation ?? '';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final q = widget.question;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Status + badges ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Spacings.mdRadius),
                topRight: Radius.circular(Spacings.mdRadius),
              ),
            ),
            child: Row(
              children: [
                _ReviewStatusChip(status: q.reviewStatus),
                const SizedBox(width: Spacings.sm),
                _TypeChip(label: q.questionType.label),
                const SizedBox(width: Spacings.sm),
                _TypeChip(label: q.difficulty.label),
                if (q.bloomLevel != null) ...[
                  const SizedBox(width: Spacings.sm),
                  _TypeChip(label: q.bloomLevel!.label),
                ],
                const Spacer(),
                if (q.isEdited)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoOf(cs.brightness).withValues(
                        alpha: isDark ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: Spacings.smIcon,
                          color: AppColors.infoOf(cs.brightness),
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Edited',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.infoOf(cs.brightness),
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Question content ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content header with edit toggle
                Row(
                  children: [
                    Text(
                      'Question',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (!_isEditing)
                      AppIconButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => setState(() => _isEditing = true),
                        variant: AppIconButtonVariant.standard,
                        size: AppButtonSize.small,
                        tooltip: 'Edit question',
                      )
                    else
                      AppButton(
                        label: 'Done',
                        onPressed: () => setState(() => _isEditing = false),
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.small,
                      ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),

                if (_isEditing)
                  AppTextField(
                    controller: _contentController,
                    maxLines: 5,
                    minLines: 3,
                    onChanged: (_) {},
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacings.md),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      q.content,
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  ),

                // ── Answer options ───────────────────────────────────
                if (q.answerOptions.isNotEmpty) ...[
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Answer Options',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  ...q.answerOptions.map((opt) {
                    final label = opt['label'] as String? ?? '';
                    final text = opt['text'] as String? ?? '';
                    final isCorrect = opt['is_correct'] as bool? ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.sm),
                      child: Container(
                        padding: const EdgeInsets.all(Spacings.md),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.successOf(cs.brightness).withValues(
                                  alpha: isDark ? 0.15 : 0.08,
                                )
                              : cs.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                ),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                          border: isCorrect
                              ? Border.all(
                                  color: AppColors.successOf(cs.brightness)
                                      .withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCorrect
                                    ? AppColors.successOf(cs.brightness)
                                    : cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: isCorrect
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: Spacings.smIcon,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        label,
                                        style: tt.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: AppTypography.wSemiBold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: Spacings.md),
                            Expanded(
                              child: Text(
                                text,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: isCorrect
                                      ? AppTypography.wSemiBold
                                      : AppTypography.wRegular,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // ── Explanation ──────────────────────────────────────
                if (q.explanation != null) ...[
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Explanation',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  if (_isEditing)
                    AppTextField(
                      controller: _explanationController,
                      maxLines: 4,
                      minLines: 2,
                      onChanged: (_) {},
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacings.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        q.explanation!,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],

                // ── Confidence score + metadata ─────────────────────
                const SizedBox(height: Spacings.lg),
                Container(
                  padding: const EdgeInsets.all(Spacings.md),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Column(
                    children: [
                      // Confidence
                      if (q.confidenceScore != null)
                        Row(
                          children: [
                            Text(
                              'Confidence',
                              style: tt.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: Spacings.md),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Spacings.xs),
                                child: LinearProgressIndicator(
                                  value: q.confidenceScore!.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  color: _confidenceColor(
                                    q.confidenceScore!,
                                    cs.brightness,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacings.sm),
                            Text(
                              '${(q.confidenceScore! * 100).toStringAsFixed(0)}%',
                              style: tt.labelMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: _confidenceColor(
                                  q.confidenceScore!,
                                  cs.brightness,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: Spacings.sm),

                      // Metadata row
                      Wrap(
                        spacing: Spacings.lg,
                        runSpacing: Spacings.sm,
                        children: [
                          _MetaItem(
                            icon: Icons.star_outline_rounded,
                            label: '${q.marks} mark${q.marks != 1 ? 's' : ''}',
                            color: cs.onSurfaceVariant,
                          ),
                          if (q.bloomLevel != null)
                            _MetaItem(
                              icon: Icons.psychology_outlined,
                              label: q.bloomLevel!.label,
                              color: cs.tertiary,
                            ),
                          _MetaItem(
                            icon: Icons.signal_cellular_alt_rounded,
                            label: q.difficulty.label,
                            color: _difficultyColor(q.difficulty, cs.brightness),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Validation results ──────────────────────────────
                if (widget.validationResults.isNotEmpty) ...[
                  const SizedBox(height: Spacings.lg),
                  ValidationBadge(results: widget.validationResults),
                ],

                // ── Improvement preview ─────────────────────────────
                if (widget.improvementResult != null) ...[
                  const SizedBox(height: Spacings.lg),
                  _ImprovementPreview(improvement: widget.improvementResult!),
                ],
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Row(
              children: [
                if (widget.onApprove != null)
                  Expanded(
                    child: AppButton(
                      label: 'Approve',
                      onPressed: widget.onApprove,
                      variant: AppButtonVariant.elevated,
                      size: AppButtonSize.small,
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: widget.isActionLoading,
                    ),
                  ),
                if (widget.onApprove != null && widget.onReject != null)
                  const SizedBox(width: Spacings.sm),
                if (widget.onReject != null)
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      onPressed: widget.onReject,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      icon: Icons.cancel_outlined,
                      isLoading: widget.isActionLoading,
                    ),
                  ),
                const SizedBox(width: Spacings.sm),
                if (widget.onRequestRevision != null)
                  AppButton(
                    label: 'Revise',
                    onPressed: widget.onRequestRevision,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    icon: Icons.edit_note_rounded,
                  ),
                if (widget.onImprove != null)
                  AppIconButton(
                    icon: Icons.auto_fix_high_outlined,
                    onPressed: widget.onImprove,
                    variant: AppIconButtonVariant.tonal,
                    tooltip: 'Improve with AI',
                  ),
                if (widget.onSaveToQb != null &&
                    q.reviewStatus == ReviewStatus.approved &&
                    q.questionBankId == null)
                  AppIconButton(
                    icon: Icons.save_outlined,
                    onPressed: widget.onSaveToQb,
                    variant: AppIconButtonVariant.filled,
                    tooltip: 'Save to Question Bank',
                    isLoading: widget.isActionLoading,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double score, Brightness brightness) {
    if (score >= 0.8) return AppColors.successOf(brightness);
    if (score >= 0.6) return AppColors.warningOf(brightness);
    return AppColors.errorOf(brightness);
  }

  Color _difficultyColor(DifficultyLevel difficulty, Brightness brightness) {
    final hex = difficulty.color;
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════

class _ReviewStatusChip extends StatelessWidget {
  const _ReviewStatusChip({required this.status});
  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    final (Color color, IconData icon, String label) = switch (status) {
      ReviewStatus.pending => (
          AppColors.warningOf(cs.brightness),
          Icons.schedule_rounded,
          'Pending',
        ),
      ReviewStatus.approved => (
          AppColors.successOf(cs.brightness),
          Icons.check_circle_rounded,
          'Approved',
        ),
      ReviewStatus.rejected => (
          AppColors.errorOf(cs.brightness),
          Icons.cancel_rounded,
          'Rejected',
        ),
      ReviewStatus.needsRevision => (
          AppColors.infoOf(cs.brightness),
          Icons.edit_note_rounded,
          'Needs Revision',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: AppTypography.wMedium,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ImprovementPreview extends StatelessWidget {
  const _ImprovementPreview({required this.improvement});
  final QuestionImprovementEntity improvement;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.infoOf(cs.brightness).withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(
          color: AppColors.infoOf(cs.brightness).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                size: Spacings.mdIcon,
                color: AppColors.infoOf(cs.brightness),
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'AI Improvement Preview',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: AppColors.infoOf(cs.brightness),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
                decoration: BoxDecoration(
                  color: AppColors.infoOf(cs.brightness).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacings.xs),
                ),
                child: Text(
                  improvement.improvementType,
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.infoOf(cs.brightness),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Text(
            'Improved Content:',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            improvement.improvedContent,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
