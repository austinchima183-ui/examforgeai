import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/question_entities.dart';
import 'question_type_badge.dart';
import 'difficulty_badge.dart';
import 'question_content_renderer.dart';

// ─── QuestionPreviewCard ──────────────────────────────────────────────────────

/// A full question display card as it would appear to students, used in the
/// editor's preview mode. Shows content, attachments, answer options, a
/// collapsible explanation section (marked as "Teacher Only"), marks
/// allocation, and metadata.
///
/// ```dart
/// QuestionPreviewCard(question: myQuestion)
/// ```
class QuestionPreviewCard extends StatefulWidget {
  const QuestionPreviewCard({
    super.key,
    required this.question,
    this.subjectName,
    this.topicName,
  });

  /// The question entity to preview.
  final QuestionEntity question;

  /// Display name for the question's subject.
  final String? subjectName;

  /// Display name for the question's topic.
  final String? topicName;

  @override
  State<QuestionPreviewCard> createState() => _QuestionPreviewCardState();
}

class _QuestionPreviewCardState extends State<QuestionPreviewCard> {
  bool _isExplanationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final q = widget.question;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Type + Difficulty + Marks ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionTypeBadge(
                type: q.questionType,
                variant: QuestionTypeBadgeVariant.both,
                size: QuestionTypeBadgeSize.large,
              ),
              const SizedBox(width: Spacings.sm),
              DifficultyBadge(difficulty: q.difficulty),
              const Spacer(),
              // Marks badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '${q.marks} mark${q.marks == 1 ? '' : 's'}',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),

          // ── Negative Marks ────────────────────────────────────────
          if (q.negativeMarks > 0) ...[
            const SizedBox(height: Spacings.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.25 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                'Negative marks: -${q.negativeMarks}',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],

          // ── Time Allowed ──────────────────────────────────────────
          if (q.timeAllowedSeconds != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Time: ${_formatDuration(q.timeAllowedSeconds!)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],

          const SizedBox(height: Spacings.lg),

          // ── Question Content ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: QuestionContentRenderer(
              content: q.content,
              attachments: q.attachments,
              isPreviewMode: true,
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // ── Answer Options (as student would see them) ────────────
          if (q.questionType.hasOptions && q.answerOptions.isNotEmpty)
            _buildAnswerOptions(context),

          // ── Matching Pairs ────────────────────────────────────────
          if (q.questionType == QuestionType.matching &&
              q.matchingPairs.isNotEmpty)
            _buildMatchingPairs(context),

          // ── Ordering Items ────────────────────────────────────────
          if (q.questionType == QuestionType.ordering &&
              q.orderingItems.isNotEmpty)
            _buildOrderingItems(context),

          // ── Fill in Blanks ────────────────────────────────────────
          if (q.questionType == QuestionType.fillInBlank &&
              q.fillInBlankAnswers.isNotEmpty)
            _buildFillInBlanks(context),

          const SizedBox(height: Spacings.xl),

          // ── Explanation (Collapsible, Teacher Only) ───────────────
          if (q.explanation != null && q.explanation!.isNotEmpty)
            _buildExplanationSection(context),

          const SizedBox(height: Spacings.lg),

          // ── Metadata Footer ───────────────────────────────────────
          _buildMetadataFooter(context),
        ],
      ),
    );
  }

  // ─── Answer Options ────────────────────────────────────────────────

  Widget _buildAnswerOptions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final q = widget.question;
    final isMultiple = q.questionType == QuestionType.multipleResponse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Options',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...q.answerOptions.map((option) {
          final letter = String.fromCharCode(65 + option.sortOrder);
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator
                  if (isMultiple)
                    Checkbox(
                      value: false,
                      onChanged: null, // Read-only preview
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    Radio<bool>(
                      value: false,
                      groupValue: true,
                      onChanged: null, // Read-only preview
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  const SizedBox(width: Spacings.sm),

                  // Letter badge
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: AppTypography.wBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),

                  // Content
                  Expanded(
                    child: Text(
                      option.content,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Matching Pairs ────────────────────────────────────────────────

  Widget _buildMatchingPairs(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matching Pairs',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...widget.question.matchingPairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        pair.leftContent,
                        style: tt.bodyMedium?.copyWith(
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        pair.rightContent,
                        style: tt.bodyMedium?.copyWith(
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Ordering Items ────────────────────────────────────────────────

  Widget _buildOrderingItems(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Display in scrambled order (not correct position)
    final items = List<OrderingItemEntity>.from(widget.question.orderingItems)
      ..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arrange in Correct Order',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: Spacings.mdIcon,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      item.content,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Fill in Blanks ────────────────────────────────────────────────

  Widget _buildFillInBlanks(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill in the Blanks',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...widget.question.fillInBlankAnswers.map((blank) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      'Blank ${blank.blankIndex + 1}',
                      style: tt.labelSmall?.copyWith(
                        color: const Color(0xFFD97706),
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Container(
                      height: 36.0,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Explanation Section ───────────────────────────────────────────

  Widget _buildExplanationSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExplanationExpanded = !_isExplanationExpanded),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.warningOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Explanation (Teacher Only)',
                    style: tt.labelMedium?.copyWith(
                      color: AppColors.warningOf(cs.brightness),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExplanationExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: Spacings.mdIcon,
                      color: AppColors.warningOf(cs.brightness),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg,
                0,
                Spacings.lg,
                Spacings.lg,
              ),
              child: Text(
                widget.question.explanation ?? '',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: _isExplanationExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ─── Metadata Footer ───────────────────────────────────────────────

  Widget _buildMetadataFooter(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      child: Wrap(
        spacing: Spacings.xl,
        runSpacing: Spacings.sm,
        children: [
          if (widget.subjectName != null)
            _metadataItem(Icons.book_outlined, 'Subject', widget.subjectName!),
          if (widget.topicName != null)
            _metadataItem(Icons.topic_outlined, 'Topic', widget.topicName!),
          if (widget.question.examType != null)
            _metadataItem(
              Icons.school_outlined,
              'Exam',
              widget.question.examType!.label,
            ),
          _metadataItem(
            Icons.star_outline_rounded,
            'Marks',
            '${widget.question.marks}',
          ),
          _metadataItem(
            Icons.tag_outlined,
            'Version',
            'v${widget.question.version}',
          ),
          if (widget.question.usageCount > 0)
            _metadataItem(
              Icons.bar_chart_outlined,
              'Used',
              '${widget.question.usageCount}×',
            ),
        ],
      ),
    );
  }

  Widget _metadataItem(IconData icon, String label, String value) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text(
          '$label: ',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: AppTypography.wMedium,
          ),
        ),
        Text(
          value,
          style: tt.bodySmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  // ─── Duration Formatter ────────────────────────────────────────────

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds sec';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}
