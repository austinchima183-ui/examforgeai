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
// GENERATED QUESTION CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for displaying a generated question with metadata, badges,
/// confidence indicator, review status, validation issues, and action
/// buttons. Expandable to show full details.
///
/// ```dart
/// GeneratedQuestionCard(
///   question: myQuestion,
///   validationResults: validationList,
///   onApprove: () => approve(q.id),
///   onReject: () => reject(q.id),
///   onImprove: () => improve(q.id),
///   onSaveToQb: () => save(q.id),
///   onReview: () => review(q.id),
/// )
/// ```
class GeneratedQuestionCard extends StatefulWidget {
  const GeneratedQuestionCard({
    super.key,
    required this.question,
    this.validationResults = const [],
    this.onApprove,
    this.onReject,
    this.onImprove,
    this.onSaveToQb,
    this.onReview,
    this.isActionLoading = false,
  });

  /// The generated question to display.
  final GeneratedQuestionEntity question;

  /// Validation results for this question.
  final List<ValidationResultEntity> validationResults;

  /// Callback when the Approve button is pressed.
  final VoidCallback? onApprove;

  /// Callback when the Reject button is pressed.
  final VoidCallback? onReject;

  /// Callback when the Improve button is pressed.
  final VoidCallback? onImprove;

  /// Callback when the Save to Question Bank button is pressed.
  final VoidCallback? onSaveToQb;

  /// Callback when the Review button is pressed.
  final VoidCallback? onReview;

  /// Whether an action is currently loading.
  final bool isActionLoading;

  @override
  State<GeneratedQuestionCard> createState() => _GeneratedQuestionCardState();
}

class _GeneratedQuestionCardState extends State<GeneratedQuestionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final q = widget.question;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Badges row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg, Spacings.lg, Spacings.lg, Spacings.sm,
            ),
            child: Row(
              children: [
                _QuestionTypeBadge(type: q.questionType),
                const SizedBox(width: Spacings.sm),
                _DifficultyBadge(difficulty: q.difficulty),
                if (q.bloomLevel != null) ...[
                  const SizedBox(width: Spacings.sm),
                  _BloomBadge(level: q.bloomLevel!),
                ],
                const Spacer(),
                _ReviewStatusBadge(status: q.reviewStatus),
              ],
            ),
          ),

          // ── Question content (truncated) ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Text(
              q.content,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
          ),

          // ── Confidence score indicator ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg, Spacings.md, Spacings.lg, Spacings.sm,
            ),
            child: _ConfidenceIndicator(score: q.confidenceScore),
          ),

          // ── Validation issues count badge ───────────────────────────
          if (widget.validationResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: ValidationBadge(
                results: widget.validationResults,
                isCompact: true,
              ),
            ),

          const SizedBox(height: Spacings.sm),

          // ── Saved to QB indicator ───────────────────────────────────
          if (q.questionBankId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.successOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'Saved to Question Bank',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.successOf(cs.brightness),
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ],
              ),
            ),

          // ── Expand / Collapse toggle ────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ────────────────────────────────────────
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Answer options
                  if (q.answerOptions.isNotEmpty) ...[
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
                        padding: const EdgeInsets.only(bottom: Spacings.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? AppColors.successOf(cs.brightness)
                                        .withValues(alpha: 0.15)
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  Spacings.xs,
                                ),
                                border: Border.all(
                                  color: isCorrect
                                      ? AppColors.successOf(cs.brightness)
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: tt.labelSmall?.copyWith(
                                    color: isCorrect
                                        ? AppColors.successOf(cs.brightness)
                                        : cs.onSurfaceVariant,
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacings.sm),
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
                            if (isCorrect)
                              Icon(
                                Icons.check_circle_rounded,
                                size: Spacings.smIcon,
                                color: AppColors.successOf(cs.brightness),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: Spacings.md),
                  ],

                  // Explanation
                  if (q.explanation != null) ...[
                    Text(
                      'Explanation',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacings.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          Spacings.smRadius,
                        ),
                      ),
                      child: Text(
                        q.explanation!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacings.md),
                  ],

                  // Metadata row
                  Wrap(
                    spacing: Spacings.lg,
                    runSpacing: Spacings.sm,
                    children: [
                      _MetadataChip(
                        icon: Icons.star_outline_rounded,
                        label: '${q.marks} mark${q.marks != 1 ? 's' : ''}',
                      ),
                      if (q.bloomLevel != null)
                        _MetadataChip(
                          icon: Icons.psychology_outlined,
                          label: q.bloomLevel!.label,
                        ),
                      _MetadataChip(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: q.difficulty.label,
                      ),
                      if (q.confidenceScore != null)
                        _MetadataChip(
                          icon: Icons.speed_rounded,
                          label:
                              '${(q.confidenceScore! * 100).toStringAsFixed(0)}%',
                        ),
                    ],
                  ),

                  // Validation details
                  if (widget.validationResults.isNotEmpty) ...[
                    const SizedBox(height: Spacings.lg),
                    ValidationBadge(
                      results: widget.validationResults,
                      isCompact: false,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Action buttons ──────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.md, Spacings.sm, Spacings.md, Spacings.sm,
            ),
            child: Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: [
                if (widget.onReview != null &&
                    q.reviewStatus == ReviewStatus.pending)
                  AppButton(
                    label: 'Review',
                    onPressed: widget.onReview,
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.small,
                    icon: Icons.rate_review_outlined,
                    isLoading: widget.isActionLoading,
                  ),
                if (widget.onApprove != null &&
                    q.reviewStatus != ReviewStatus.approved)
                  AppButton(
                    label: 'Approve',
                    onPressed: widget.onApprove,
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.small,
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: widget.isActionLoading,
                  ),
                if (widget.onReject != null &&
                    q.reviewStatus != ReviewStatus.rejected)
                  AppButton(
                    label: 'Reject',
                    onPressed: widget.onReject,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    icon: Icons.cancel_outlined,
                    isLoading: widget.isActionLoading,
                  ),
                if (widget.onImprove != null)
                  AppButton(
                    label: 'Improve',
                    onPressed: widget.onImprove,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    icon: Icons.auto_fix_high_outlined,
                  ),
                if (widget.onSaveToQb != null &&
                    q.reviewStatus == ReviewStatus.approved &&
                    q.questionBankId == null)
                  AppButton(
                    label: 'Save to QB',
                    onPressed: widget.onSaveToQb,
                    variant: AppButtonVariant.elevated,
                    size: AppButtonSize.small,
                    icon: Icons.save_outlined,
                    isLoading: widget.isActionLoading,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _QuestionTypeBadge extends StatelessWidget {
  const _QuestionTypeBadge({required this.type});
  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        type.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final DifficultyLevel difficulty;

  Color _color(BuildContext context) {
    final hex = difficulty.color;
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        difficulty.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

class _BloomBadge extends StatelessWidget {
  const _BloomBadge({required this.level});
  final BloomTaxonomy level;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    // Use tertiary color for Bloom badges
    final color = cs.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        level.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

class _ReviewStatusBadge extends StatelessWidget {
  const _ReviewStatusBadge({required this.status});
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
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
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

class _ConfidenceIndicator extends StatelessWidget {
  const _ConfidenceIndicator({this.score});
  final double? score;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    if (score == null) return const SizedBox.shrink();

    final clamped = score!.clamp(0.0, 1.0);
    final percent = (clamped * 100).toStringAsFixed(0);

    Color barColor;
    if (clamped >= 0.8) {
      barColor = AppColors.successOf(cs.brightness);
    } else if (clamped >= 0.6) {
      barColor = AppColors.warningOf(cs.brightness);
    } else {
      barColor = AppColors.errorOf(cs.brightness);
    }

    return Row(
      children: [
        Text(
          'Confidence: $percent%',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: AppTypography.wMedium,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.xs),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: barColor,
              borderRadius: BorderRadius.circular(Spacings.xs),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
