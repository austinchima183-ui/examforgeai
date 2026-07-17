import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/question_entities.dart';
import '../providers/question_provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/question_type_badge.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/question_content_renderer.dart';
import '../widgets/collection_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Full detail view for a single question.
///
/// Displays the question content, answer section (type-specific rendering),
/// collapsible explanation, teacher notes, metadata, tags, attachments,
/// stats, timestamps, version history, and action sheets for sharing and
/// adding to collections.
class QuestionDetailPage extends ConsumerStatefulWidget {
  const QuestionDetailPage({
    super.key,
    required this.questionId,
  });

  /// The ID of the question to display.
  final String questionId;

  @override
  ConsumerState<QuestionDetailPage> createState() =>
      _QuestionDetailPageState();
}

class _QuestionDetailPageState extends ConsumerState<QuestionDetailPage> {
  bool _isExplanationExpanded = false;
  bool _isVersionHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestion();
    });
  }

  Future<void> _loadQuestion() async {
    await ref
        .read(questionBankProvider.notifier)
        .getQuestionDetail(widget.questionId);
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionBankProvider);
    final question = questionState.currentQuestion;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Question Details',
        actions: [
          if (question != null) ...[
            AppIconButton(
              icon: Icons.edit_outlined,
              onPressed: () => context.go(
                '${RouteNames.questionBankEdit}?id=${question.id}',
              ),
              tooltip: 'Edit',
            ),
            AppIconButton(
              icon: Icons.content_copy_rounded,
              onPressed: () {
                ref
                    .read(questionBankProvider.notifier)
                    .duplicateQuestion(question.id);
              },
              tooltip: 'Duplicate',
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: Spacings.mdIcon,
                color: context.colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _showShareSheet(question);
                  case 'archive':
                    ref
                        .read(questionBankProvider.notifier)
                        .archiveQuestion(question.id);
                  case 'delete':
                    _confirmDelete(question.id);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: Spacings.md),
                    Text('Share'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        question.isArchived
                            ? Icons.unarchive_rounded
                            : Icons.archive_outlined,
                      ),
                      const SizedBox(width: Spacings.md),
                      Text(question.isArchived ? 'Restore' : 'Archive'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.errorOf(ctx.colorScheme.brightness),
                      ),
                      const SizedBox(width: Spacings.md),
                      Text(
                        'Delete',
                        style: ctx.textTheme.bodyMedium?.copyWith(
                          color: AppColors.errorOf(ctx.colorScheme.brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(context, questionState, question),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    QuestionBankState questionState,
    QuestionEntity? question,
  ) {
    if (questionState.isLoading && question == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (questionState.error != null && question == null) {
      return AppErrorState.genericError(
        message: questionState.error,
        onRetry: _loadQuestion,
      );
    }

    if (question == null) {
      return AppEmptyState.noData(
        title: 'Question Not Found',
        subtitle: 'The question you are looking for does not exist.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuestion,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Type + Difficulty + Status ────────────────
            _buildHeader(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Question Content ──────────────────────────────────
            _buildQuestionContent(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Answer Section ────────────────────────────────────
            _buildAnswerSection(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Explanation (Collapsible) ─────────────────────────
            if (question.explanation != null &&
                question.explanation!.isNotEmpty)
              _buildExplanationSection(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Teacher Notes (only for teachers/admins) ──────────
            if (question.teacherNotes != null &&
                question.teacherNotes!.isNotEmpty)
              _buildTeacherNotes(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Metadata Card ─────────────────────────────────────
            _buildMetadataCard(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Tags ──────────────────────────────────────────────
            if (question.tags.isNotEmpty) _buildTags(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Attachments ───────────────────────────────────────
            if (question.attachments.isNotEmpty)
              _buildAttachments(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Stats Row ─────────────────────────────────────────
            _buildStatsRow(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Timestamps ────────────────────────────────────────
            _buildTimestamps(context, question),

            const SizedBox(height: Spacings.xl),

            // ── Version History ────────────────────────────────────
            _buildVersionHistory(context, question),

            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionTypeBadge(
          type: question.questionType,
          variant: QuestionTypeBadgeVariant.both,
          size: QuestionTypeBadgeSize.large,
        ),
        const SizedBox(width: Spacings.sm),
        DifficultyBadge(difficulty: question.difficulty),
        const Spacer(),
        // Status badge
        if (question.isArchived)
          _buildStatusChip(context, 'Archived', const Color(0xFF6B7280))
        else if (question.isPublished)
          _buildStatusChip(context, 'Published', AppColors.success)
        else
          _buildStatusChip(context, 'Draft', AppColors.warning),
        // Marks badge
        const SizedBox(width: Spacings.sm),
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
            '${question.marks} mark${question.marks == 1 ? '' : 's'}',
            style: tt.labelMedium?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11.0,
          fontWeight: AppTypography.wSemiBold,
          color: isDark ? color.withValues(alpha: 0.9) : color,
        ),
      ),
    );
  }

  // ─── Question Content ───────────────────────────────────────────────

  Widget _buildQuestionContent(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionContentRenderer(
            content: question.content,
            attachments: question.attachments,
            isPreviewMode: true,
          ),
          if (question.negativeMarks > 0) ...[
            const SizedBox(height: Spacings.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.08,
                ),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                'Negative marks: -${question.negativeMarks}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
          if (question.timeAllowedSeconds != null) ...[
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
                  'Time: ${_formatDuration(question.timeAllowedSeconds!)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Answer Section ─────────────────────────────────────────────────

  Widget _buildAnswerSection(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: Spacings.mdIcon,
                color: AppColors.success,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Correct Answer',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // Type-specific answer rendering
          if (question.questionType == QuestionType.multipleChoice ||
              question.questionType == QuestionType.multipleResponse ||
              question.questionType == QuestionType.trueFalse ||
              question.questionType == QuestionType.imageBased ||
              question.questionType == QuestionType.audioBased ||
              question.questionType == QuestionType.videoBased)
            _buildChoiceAnswers(context, question)
          else if (question.questionType == QuestionType.matching)
            _buildMatchingAnswers(context, question)
          else if (question.questionType == QuestionType.ordering)
            _buildOrderingAnswers(context, question)
          else if (question.questionType == QuestionType.fillInBlank)
            _buildFillInBlankAnswers(context, question)
          else if (question.questionType == QuestionType.trueFalse)
            _buildTrueFalseAnswer(context, question)
          else
            _buildTextAnswer(context, question),
        ],
      ),
    );
  }

  Widget _buildChoiceAnswers(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMultiple =
        question.questionType == QuestionType.multipleResponse;

    return Column(
      children: question.answerOptions.map((option) {
        final letter = String.fromCharCode(65 + option.sortOrder);
        final isCorrect = option.isCorrect;

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.success.withValues(
                      alpha: context.isDarkMode ? 0.15 : 0.06,
                    )
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.4)
                    : cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMultiple)
                  Icon(
                    isCorrect
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: Spacings.mdIcon,
                    color: isCorrect ? AppColors.success : cs.onSurfaceVariant,
                  )
                else
                  Icon(
                    isCorrect
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: Spacings.mdIcon,
                    color: isCorrect ? AppColors.success : cs.onSurfaceVariant,
                  ),
                const SizedBox(width: Spacings.sm),
                Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.15)
                        : cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: tt.labelSmall?.copyWith(
                        color: isCorrect ? AppColors.success : cs.onSecondaryContainer,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    option.content,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight:
                          isCorrect ? AppTypography.wSemiBold : null,
                    ),
                  ),
                ),
                if (isCorrect)
                  Icon(
                    Icons.check_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.success,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchingAnswers(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      children: question.matchingPairs.map((pair) {
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
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      pair.rightContent,
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderingAnswers(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final sortedItems = List<OrderingItemEntity>.from(question.orderingItems)
      ..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));

    return Column(
      children: sortedItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

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
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.md),
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
      }).toList(),
    );
  }

  Widget _buildFillInBlankAnswers(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      children: question.fillInBlankAnswers.map((blank) {
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
                  child: Wrap(
                    spacing: Spacings.xs,
                    runSpacing: Spacings.xs,
                    children: blank.acceptableAnswers
                        .map((answer) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.md,
                                vertical: Spacings.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(Spacings.smRadius),
                                border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                answer,
                                style: tt.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: AppTypography.wMedium,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseAnswer(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final correctOption = question.answerOptions
        .firstWhere((o) => o.isCorrect, orElse: () => question.answerOptions.first);

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: Spacings.lgIcon,
            color: AppColors.success,
          ),
          const SizedBox(width: Spacings.md),
          Text(
            correctOption.content,
            style: tt.titleMedium?.copyWith(
              color: AppColors.success,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAnswer(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Answer',
            style: tt.labelMedium?.copyWith(
              color: AppColors.success,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            question.explanation ?? 'No model answer provided.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Explanation Section ────────────────────────────────────────────

  Widget _buildExplanationSection(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isExplanationExpanded = !_isExplanationExpanded,
            ),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.warningOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Explanation',
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
                question.explanation ?? '',
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

  // ─── Teacher Notes ──────────────────────────────────────────────────

  Widget _buildTeacherNotes(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      borderColor: AppColors.warningOf(cs.brightness).withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: Spacings.mdIcon,
                color: AppColors.warningOf(cs.brightness),
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Teacher Notes',
                style: tt.labelMedium?.copyWith(
                  color: AppColors.warningOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Text(
            question.teacherNotes!,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metadata Card ──────────────────────────────────────────────────

  Widget _buildMetadataCard(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Metadata',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          Wrap(
            spacing: Spacings.xl,
            runSpacing: Spacings.md,
            children: [
              _metadataItem(Icons.book_outlined, 'Subject',
                  question.subjectId.isNotEmpty ? question.subjectId : 'N/A'),
              if (question.topicId != null)
                _metadataItem(Icons.topic_outlined, 'Topic', question.topicId!),
              if (question.subtopicId != null)
                _metadataItem(
                    Icons.subdirectory_arrow_right_rounded, 'Subtopic', question.subtopicId!),
              _metadataItem(
                  Icons.signal_cellular_alt_rounded, 'Difficulty', question.difficulty.label),
              if (question.examType != null)
                _metadataItem(Icons.school_outlined, 'Exam Type', question.examType!.label),
              _metadataItem(Icons.star_outline_rounded, 'Marks', '${question.marks}'),
              if (question.negativeMarks > 0)
                _metadataItem(
                    Icons.remove_circle_outline_rounded, 'Negative', '-${question.negativeMarks}'),
              if (question.timeAllowedSeconds != null)
                _metadataItem(Icons.timer_outlined, 'Time',
                    _formatDuration(question.timeAllowedSeconds!)),
            ],
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
        Text(value, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
      ],
    );
  }

  // ─── Tags ───────────────────────────────────────────────────────────

  Widget _buildTags(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label_outline_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Tags',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        Wrap(
          spacing: Spacings.xs,
          runSpacing: Spacings.xs,
          children: question.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                tag.name,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Attachments ────────────────────────────────────────────────────

  Widget _buildAttachments(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final imageAttachments =
        question.attachments.where((a) => a.contentType == 'image').toList();
    final otherAttachments =
        question.attachments.where((a) => a.contentType != 'image').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Attachments',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        // Image preview
        if (imageAttachments.isNotEmpty)
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: imageAttachments.map((att) {
              return Container(
                width: 120.0,
                height: 90.0,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 28.0,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      att.altText ?? att.fileName ?? 'Image',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        // Other files
        if (otherAttachments.isNotEmpty) ...[
          if (imageAttachments.isNotEmpty)
            const SizedBox(height: Spacings.sm),
          ...otherAttachments.map((att) {
            final icon = _attachmentIcon(att.contentType);
            final color = _attachmentColor(att.contentType, cs);
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16.0, color: color),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        att.fileName ?? att.contentType,
                        style: tt.bodySmall?.copyWith(
                          color: color,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.download_rounded,
                      size: Spacings.smIcon,
                      color: color,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  IconData _attachmentIcon(String contentType) {
    return switch (contentType) {
      'audio' => Icons.audiotrack_outlined,
      'video' => Icons.videocam_outlined,
      'document' => Icons.description_outlined,
      _ => Icons.attach_file_rounded,
    };
  }

  Color _attachmentColor(String contentType, ColorScheme cs) {
    return switch (contentType) {
      'audio' => const Color(0xFFCA8A04),
      'video' => const Color(0xFFBE185D),
      'document' => const Color(0xFF059669),
      _ => cs.onSurfaceVariant,
    };
  }

  // ─── Stats Row ──────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        _statChip(
          Icons.bar_chart_outlined,
          'Used ${question.usageCount}×',
          cs.onSurfaceVariant,
        ),
        const SizedBox(width: Spacings.lg),
        _statChip(
          Icons.trending_up_rounded,
          'Avg score: ${question.avgScore.toStringAsFixed(1)}%',
          cs.onSurfaceVariant,
        ),
        const SizedBox(width: Spacings.lg),
        _statChip(
          Icons.tag_outlined,
          'v${question.version}',
          cs.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
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

  // ─── Timestamps ─────────────────────────────────────────────────────

  Widget _buildTimestamps(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: Spacings.smIcon,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            'Created: ${_formatDate(question.createdAt)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: Spacings.xl),
          Icon(
            Icons.update_rounded,
            size: Spacings.smIcon,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            'Updated: ${_formatDate(question.updatedAt)}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: Spacings.xl),
          if (question.createdBy != null) ...[
            Icon(
              Icons.person_outline_rounded,
              size: Spacings.smIcon,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: Spacings.xs),
            Flexible(
              child: Text(
                'By: ${question.createdBy}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Version History ────────────────────────────────────────────────

  Widget _buildVersionHistory(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isVersionHistoryExpanded = !_isVersionHistoryExpanded,
            ),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Version History',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Text(
                      'v${question.version}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  AnimatedRotation(
                    turns: _isVersionHistoryExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg,
                0,
                Spacings.lg,
                Spacings.lg,
              ),
              child: _buildVersionTimeline(context, question),
            ),
            crossFadeState: _isVersionHistoryExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTimeline(BuildContext context, QuestionEntity question) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Show current version + placeholder for past versions
    final versions = List.generate(question.version, (index) {
      final versionNum = question.version - index;
      return _VersionEntry(
        version: versionNum,
        isCurrent: versionNum == question.version,
        date: versionNum == question.version
            ? question.updatedAt
            : question.createdAt,
        author: versionNum == question.version
            ? question.updatedBy ?? question.createdBy ?? 'Unknown'
            : question.createdBy ?? 'Unknown',
      );
    });

    return Column(
      children: versions.map((entry) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: entry.isCurrent ? cs.primary : cs.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2.0,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Spacings.md),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Version ${entry.version}',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: entry.isCurrent
                                  ? AppTypography.wSemiBold
                                  : null,
                            ),
                          ),
                          if (entry.isCurrent) ...[
                            const SizedBox(width: Spacings.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(Spacings.smRadius),
                              ),
                              child: Text(
                                'Current',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: AppTypography.wBold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${entry.author} · ${_formatDate(entry.date)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Share Bottom Sheet ─────────────────────────────────────────────

  void _showShareSheet(QuestionEntity question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => _ShareBottomSheet(question: question),
    );
  }

  // ─── Add to Collection Bottom Sheet ─────────────────────────────────

  void _showAddToCollectionSheet(QuestionEntity question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => _AddToCollectionSheet(question: question),
    );
  }

  // ─── Confirm Delete ─────────────────────────────────────────────────

  Future<void> _confirmDelete(String questionId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Question?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref.read(questionBankProvider.notifier).deleteQuestion(questionId);
      if (mounted) context.pop();
    }
  }

  // ─── Date Formatter ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds sec';
    if (seconds < 3600) return '${seconds ~/ 60} min';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════

class _ShareBottomSheet extends ConsumerStatefulWidget {
  const _ShareBottomSheet({required this.question});

  final QuestionEntity question;

  @override
  ConsumerState<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<_ShareBottomSheet> {
  String _selectedPermission = 'read';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.lg,
        Spacings.lg,
        MediaQuery.of(context).viewInsets.bottom + Spacings.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            'Share Question',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xl),
          AppTextField(
            label: 'Email Address',
            hint: 'Enter email to share with',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: Spacings.md),
          Text(
            'Permission',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'read', label: Text('View Only')),
              ButtonSegment(value: 'edit', label: Text('Can Edit')),
              ButtonSegment(value: 'admin', label: Text('Admin')),
            ],
            selected: {_selectedPermission},
            onSelectionChanged: (selection) {
              setState(() => _selectedPermission = selection.first);
            },
          ),
          const SizedBox(height: Spacings.md),
          AppTextField(
            label: 'Message (Optional)',
            hint: 'Add a message for the recipient',
            controller: _messageController,
            maxLines: 3,
          ),
          const SizedBox(height: Spacings.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Share',
              onPressed: () {
                // TODO: call share use case
                Navigator.pop(context);
              },
              variant: AppButtonVariant.elevated,
              icon: Icons.share_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADD TO COLLECTION BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════

class _AddToCollectionSheet extends ConsumerWidget {
  const _AddToCollectionSheet({required this.question});

  final QuestionEntity question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final collectionState = ref.watch(collectionProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.lg,
        Spacings.lg,
        MediaQuery.of(context).viewInsets.bottom + Spacings.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            'Add to Collection',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          if (collectionState.isLoading)
            const Center(child: AppLoadingSpinner())
          else if (collectionState.collections.isEmpty)
            AppEmptyState.noData(
              title: 'No Collections',
              subtitle: 'Create a collection first.',
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: collectionState.collections.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Spacings.sm),
                itemBuilder: (context, index) {
                  final collection = collectionState.collections[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Icon(
                        Icons.collections_bookmark_outlined,
                        size: Spacings.mdIcon,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      collection.name,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    subtitle: Text(
                      '${collection.questionCount} questions',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.add_circle_outline_rounded,
                      color: cs.primary,
                    ),
                    onTap: () {
                      ref.read(collectionProvider.notifier).addQuestionToCollection(
                            collection.id,
                            question.id,
                          );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _VersionEntry {
  const _VersionEntry({
    required this.version,
    required this.isCurrent,
    required this.date,
    required this.author,
  });

  final int version;
  final bool isCurrent;
  final DateTime date;
  final String author;
}
