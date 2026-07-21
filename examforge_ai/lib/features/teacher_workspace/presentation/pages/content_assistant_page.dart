import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../providers/content_assistant_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONTENT ASSISTANT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Content Assistant page where teachers can ask AI to explain, simplify,
/// expand, rewrite, translate content, generate examples, analogies,
/// discussion prompts, and activities.
class ContentAssistantPage extends ConsumerStatefulWidget {
  const ContentAssistantPage({super.key});

  @override
  ConsumerState<ContentAssistantPage> createState() =>
      _ContentAssistantPageState();
}

class _ContentAssistantPageState extends ConsumerState<ContentAssistantPage> {
  final _sourceCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  ContentAction? _selectedAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentAssistantProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(contentAssistantProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(contentAssistantProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(contentAssistantProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleGenerate() {
    if (_selectedAction == null) {
      _showSnackBar('Please select an action first', isError: true);
      return;
    }
    if (_sourceCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter source content', isError: true);
      return;
    }

    // Sync content and action to the notifier, then generate
    ref.read(contentAssistantProvider.notifier).setContent(_sourceCtrl.text.trim());
    ref.read(contentAssistantProvider.notifier).setAction(_selectedAction!);
    ref.read(contentAssistantProvider.notifier).generateContent();
    _listenForMessages();
  }

  void _handleCopyGeneratedContent() {
    final state = ref.read(contentAssistantProvider);
    if (state.generatedContent != null) {
      Clipboard.setData(
        ClipboardData(text: state.generatedContent!.generatedContent),
      );
      _showSnackBar('Content copied to clipboard', isError: false);
    }
  }

  void _handleSaveAsResource() {
    final state = ref.read(contentAssistantProvider);
    if (state.generatedContent == null) return;
    ref.read(contentAssistantProvider.notifier).saveContentAs('resource');
    _listenForMessages();
  }

  void _handleSaveAsNote() {
    final state = ref.read(contentAssistantProvider);
    if (state.generatedContent == null) return;
    ref.read(contentAssistantProvider.notifier).saveContentAs('note');
    _listenForMessages();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentAssistantProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Content Assistant',
      ),
      body: state.isLoadingHistory && state.history.isEmpty
          ? _buildLoadingShimmer()
          : state.error != null && state.history.isEmpty && state.generatedContent == null
              ? _buildErrorState()
              : _buildContent(state),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(ContentAssistantState state) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(contentAssistantProvider.notifier).loadHistory(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action selector grid
            _buildActionSelector(),
            const SizedBox(height: Spacings.lg),

            // Source content input
            AppTextField(
              label: 'Source Content',
              hint: 'Paste your content here...',
              controller: _sourceCtrl,
              maxLines: 6,
              minLines: 4,
            ),
            const SizedBox(height: Spacings.md),

            // Subject & Topic (optional)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Subject (optional)',
                    hint: 'e.g. Physics',
                    controller: _subjectCtrl,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppTextField(
                    label: 'Topic (optional)',
                    hint: 'e.g. Newton\'s Laws',
                    controller: _topicCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.lg),

            // Generate button
            AppButton(
              label: 'Generate',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: state.isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xl),

            // Generated result card
            if (state.isGenerating)
              _buildGeneratingShimmer()
            else if (state.generatedContent != null)
              _buildGeneratedResultCard(state),
            const SizedBox(height: Spacings.xl),

            // History section
            _buildHistorySection(state),
          ],
        ),
      ),
    );
  }

  // ─── Action Selector Grid ────────────────────────────────────────────

  Widget _buildActionSelector() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final actions = ContentAction.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Action',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: actions.map((action) {
            final isSelected = _selectedAction == action;
            final icon = _actionIcon(action);
            final color = _actionColor(action);

            return ChoiceChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? cs.onPrimary : color,
              ),
              label: Text(
                action.label,
                style: tt.labelMedium?.copyWith(
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: isSelected
                      ? AppTypography.wSemiBold
                      : AppTypography.wRegular,
                ),
              ),
              selected: isSelected,
              selectedColor: cs.primary,
              backgroundColor: isDark
                  ? cs.surfaceContainerLow
                  : cs.surfaceContainerHighest,
              side: BorderSide(
                color: isSelected ? cs.primary : cs.outlineVariant,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedAction = isSelected ? null : action;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Generating Shimmer ──────────────────────────────────────────────

  Widget _buildGeneratingShimmer() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLoadingShimmer.box(width: 100, height: 20),
              const Spacer(),
              const AppLoadingShimmer.box(width: 80, height: 20),
            ],
          ),
          const SizedBox(height: Spacings.md),
          const AppLoadingShimmer.box(width: double.infinity, height: 14),
          const SizedBox(height: Spacings.sm),
          const AppLoadingShimmer.box(width: double.infinity, height: 14),
          const SizedBox(height: Spacings.sm),
          const AppLoadingShimmer.box(width: 250, height: 14),
          const SizedBox(height: Spacings.md),
          const AppLoadingShimmer.box(width: double.infinity, height: 14),
          const SizedBox(height: Spacings.sm),
          const AppLoadingShimmer.box(width: 200, height: 14),
        ],
      ),
    );
  }

  // ─── Generated Result Card ───────────────────────────────────────────

  Widget _buildGeneratedResultCard(ContentAssistantState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final content = state.generatedContent!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Action type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _actionIcon(content.actionType),
                      size: 12,
                      color: cs.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      content.actionType.label,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Copy button
              AppIconButton(
                icon: Icons.copy_rounded,
                onPressed: _handleCopyGeneratedContent,
                tooltip: 'Copy to clipboard',
                variant: AppIconButtonVariant.standard,
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Generated content text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: SelectableText(
              content.generatedContent,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // Action buttons on result
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              AppButton(
                label: 'Save as Resource',
                onPressed: _handleSaveAsResource,
                variant: AppButtonVariant.tonal,
                icon: Icons.save_outlined,
                size: AppButtonSize.small,
                isLoading: state.isSaving,
              ),
              AppButton(
                label: 'Save as Note',
                onPressed: _handleSaveAsNote,
                variant: AppButtonVariant.tonal,
                icon: Icons.note_add_outlined,
                size: AppButtonSize.small,
              ),
              GenerateQuestionsButton(
                resourceType: 'content_assistant',
                resourceId: content.id,
                resourceName:
                    '${content.actionType.label} - ${content.sourceContent.substring(0, content.sourceContent.length > 30 ? 30 : content.sourceContent.length)}...',
                subject: content.subject,
                topic: content.topic,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── History Section ─────────────────────────────────────────────────

  Widget _buildHistorySection(ContentAssistantState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final history = state.history.take(10).toList();

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Generations',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...history.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppCard(
                onTap: () {
                  // Load this entry as the current generated content
                  // and populate source content
                  _sourceCtrl.text = entry.sourceContent;
                  if (entry.subject != null) {
                    _subjectCtrl.text = entry.subject!;
                  }
                  if (entry.topic != null) {
                    _topicCtrl.text = entry.topic!;
                  }
                  setState(() => _selectedAction = entry.actionType);
                  ref.read(contentAssistantProvider.notifier).setContent(
                        entry.sourceContent,
                      );
                  ref.read(contentAssistantProvider.notifier).setAction(
                        entry.actionType,
                      );
                },
                child: Row(
                  children: [
                    // Action type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _actionColor(entry.actionType).withOpacity(isDark ? 0.20 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _actionIcon(entry.actionType),
                            size: 12,
                            color: _actionColor(entry.actionType),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.actionType.label,
                            style: tt.labelSmall?.copyWith(
                              color: _actionColor(entry.actionType),
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacings.md),

                    // Source preview (first 100 chars)
                    Expanded(
                      child: Text(
                        entry.sourceContent.length > 100
                            ? '${entry.sourceContent.substring(0, 100)}...'
                            : entry.sourceContent,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: Spacings.sm),

                    // Date
                    Text(
                      _formatDate(entry.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),

                    // Saved indicator
                    if (entry.isSaved) ...[
                      const SizedBox(width: Spacings.xs),
                      Icon(
                        Icons.bookmark_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ─── States ──────────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLoadingShimmer.box(width: 120, height: 20),
              const SizedBox(height: Spacings.md),
              const AppLoadingShimmer.box(width: double.infinity, height: 14),
              const SizedBox(height: Spacings.sm),
              const AppLoadingShimmer.box(width: 200, height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(contentAssistantProvider).error,
      onRetry: () =>
          ref.read(contentAssistantProvider.notifier).loadHistory(),
    );
  }

  // ─── Action Icon / Color Helpers ─────────────────────────────────────

  IconData _actionIcon(ContentAction action) {
    return switch (action) {
      ContentAction.explain => Icons.lightbulb_outline_rounded,
      ContentAction.simplify => Icons.compress_rounded,
      ContentAction.expand => Icons.expand_rounded,
      ContentAction.rewrite => Icons.edit_note_rounded,
      ContentAction.translate => Icons.translate_rounded,
      ContentAction.generateExamples => Icons.format_list_bulleted_rounded,
      ContentAction.generateAnalogies => Icons.compare_arrows_rounded,
      ContentAction.createDiscussion => Icons.forum_outlined,
      ContentAction.createActivity => Icons.sports_esports_outlined,
    };
  }

  Color _actionColor(ContentAction action) {
    final cs = context.colorScheme;
    return switch (action) {
      ContentAction.explain => cs.primary,
      ContentAction.simplify => cs.secondary,
      ContentAction.expand => cs.tertiary,
      ContentAction.rewrite => cs.primary,
      ContentAction.translate => cs.secondary,
      ContentAction.generateExamples => cs.tertiary,
      ContentAction.generateAnalogies => cs.primary,
      ContentAction.createDiscussion => cs.secondary,
      ContentAction.createActivity => cs.tertiary,
    };
  }

  // ─── Date Formatting ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
