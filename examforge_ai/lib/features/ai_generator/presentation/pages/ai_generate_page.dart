import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../providers/ai_generator_provider.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI GENERATE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Question Generation page with two-column layout on desktop:
/// left = GenerationInputForm, right = generated questions list.
///
/// ```dart
/// AiGeneratePage()
/// ```
class AiGeneratePage extends ConsumerStatefulWidget {
  const AiGeneratePage({super.key});

  @override
  ConsumerState<AiGeneratePage> createState() => _AiGeneratePageState();
}

class _AiGeneratePageState extends ConsumerState<AiGeneratePage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGeneratorProvider);
    final notifier = ref.read(aiGeneratorProvider.notifier);
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Generate Questions',
        actions: [
          if (state.isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Generating…',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          AppIconButton(
            icon: Icons.history_rounded,
            onPressed: () {
              // Navigate to history
            },
            tooltip: 'History',
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(state, notifier)
          : _buildMobileLayout(state, notifier, isMobile),
    );
  }

  // ── Desktop Layout: Two columns ────────────────────────────────────

  Widget _buildDesktopLayout(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Input form
        SizedBox(
          width: 420,
          child: _buildInputForm(state, notifier),
        ),
        const VerticalDivider(width: 1),

        // Right: Generated questions
        Expanded(
          child: _buildResultsPanel(state, notifier),
        ),
      ],
    );
  }

  // ── Mobile Layout: Stacked ─────────────────────────────────────────

  Widget _buildMobileLayout(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input form
          _buildInputForm(state, notifier),

          Spacings.sectionGap,

          // Results
          _buildResultsPanel(state, notifier),
        ],
      ),
    );
  }

  // ── Input Form ─────────────────────────────────────────────────────

  Widget _buildInputForm(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
  ) {
    return GenerationInputForm(
      input: state.input,
      onInputChanged: (input) => notifier.setInput(input),
      onGenerate: () => _handleGenerate(notifier, state),
      isGenerating: state.isGenerating,
      promptTemplates: const [], // Would be populated from prompt provider
    );
  }

  // ── Results Panel ──────────────────────────────────────────────────

  Widget _buildResultsPanel(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Row(
            children: [
              Text(
                'Generated Questions',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              if (state.generatedQuestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    '${state.generatedQuestions.length}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              const Spacer(),
              if (state.generatedQuestions.isNotEmpty) ...[
                AppButton(
                  label: 'Generate More',
                  onPressed: state.isGenerating
                      ? null
                      : () => _handleGenerate(notifier, state),
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  icon: Icons.add_rounded,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Save All to QB',
                  onPressed: () => _saveAllToQb(state, notifier),
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  icon: Icons.save_outlined,
                ),
              ],
            ],
          ),
        ),

        // Streaming progress indicator
        if (state.isGenerating && state.generationProgress != null)
          _buildStreamingProgress(state),

        // Error state
        if (state.error != null && state.generatedQuestions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: AppErrorState(
              icon: Icons.error_outline_rounded,
              title: 'Generation Failed',
              message: state.error,
              onRetry: () => _handleGenerate(notifier, state),
            ),
          ),

        // Empty state
        if (!state.isGenerating &&
            state.error == null &&
            state.generatedQuestions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Spacings.xxl),
            child: AppEmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'No Questions Generated',
              subtitle: 'Configure your parameters and click Generate to create questions with AI.',
              actionLabel: 'Generate Questions',
              onAction: () => _handleGenerate(notifier, state),
            ),
          ),

        // Generated questions list
        if (state.generatedQuestions.isNotEmpty)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg, 0, Spacings.lg, Spacings.xxl,
              ),
              itemCount: state.generatedQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
              itemBuilder: (context, index) {
                final question = state.generatedQuestions[index];
                return GeneratedQuestionCard(
                  question: question,
                  onApprove: () =>
                      notifier.approveQuestion(question.id),
                  onReject: () => _showRejectDialog(question.id, notifier),
                  onImprove: () {
                    // Navigate to improve page
                  },
                  onSaveToQb: () =>
                      notifier.saveToQuestionBank(question.id),
                  onReview: () {
                    // Navigate to review page
                  },
                );
              },
            ),
          ),

        // Success message
        if (state.successMessage != null)
          _buildSuccessBanner(state.successMessage!, notifier),
      ],
    );
  }

  // ── Streaming Progress ─────────────────────────────────────────────

  Widget _buildStreamingProgress(AiGeneratorState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final progress = state.generationProgress!;

    final completedCount = progress.questionsCompleted;
    final totalCount = progress.questionsTotal;
    final progressValue =
        totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(context.isDarkMode ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                'Generating questions…',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount / $totalCount',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.xs),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
              borderRadius: BorderRadius.circular(Spacings.xs),
            ),
          ),
          if (progress.partialContent != null &&
              progress.partialContent!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                progress.partialContent!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Success Banner ─────────────────────────────────────────────────

  Widget _buildSuccessBanner(
    String message,
    AiGeneratorNotifier notifier,
  ) {
    final cs = context.colorScheme;

    return Container(
      margin: const EdgeInsets.all(Spacings.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.successOf(cs.brightness).withOpacity(context.isDarkMode ? 0.15 : 0.10,
        ),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.successOf(cs.brightness).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.successOf(cs.brightness),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.successOf(cs.brightness),
                fontWeight: AppTypography.wMedium,
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.close_rounded,
            onPressed: () => notifier.clearSuccessMessage(),
            variant: AppIconButtonVariant.standard,
            size: AppButtonSize.small,
            color: AppColors.successOf(cs.brightness),
          ),
        ],
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────

  void _handleGenerate(
    AiGeneratorNotifier notifier,
    AiGeneratorState state,
  ) {
    if (state.isGenerating) return;

    // Ensure we have an input
    if (state.input == null) {
      // Set a default input if none provided
      notifier.setInput(const GenerationInputEntity(
        subjectId: '',
        topicId: '',
        difficulty: DifficultyLevel.medium,
      ));
    }

    notifier.generateQuestions();
  }

  Future<void> _saveAllToQb(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
  ) async {
    final approved = state.generatedQuestions
        .where((q) =>
            q.reviewStatus == ReviewStatus.approved && q.questionBankId == null)
        .toList();

    if (approved.isEmpty) {
      if (mounted) {
        AppDialog.showInfo(
          context: context,
          title: 'No Approved Questions',
          message: 'Approve questions before saving them to the Question Bank.',
        );
      }
      return;
    }

    for (final q in approved) {
      await notifier.saveToQuestionBank(q.id);
    }
  }

  Future<void> _showRejectDialog(
    String questionId,
    AiGeneratorNotifier notifier,
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
              label: 'Reason for rejection',
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
      await notifier.rejectQuestion(questionId, reason);
    }
  }
}
