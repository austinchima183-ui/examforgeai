import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_assistant_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT ASSISTANT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Parent Assistant chat interface.
///
/// Provides a chat-style interface where parents can ask questions about
/// their child's academic progress, get study tips, and receive general
/// educational guidance. Includes suggested question chips, a disclaimer
/// banner, and a child selector dropdown.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentAssistantPage extends ConsumerStatefulWidget {
  const ParentAssistantPage({super.key});

  @override
  ConsumerState<ParentAssistantPage> createState() => _State();
}

class _State extends ConsumerState<ParentAssistantPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// Controller for the question input field.
  final TextEditingController _questionController = TextEditingController();

  /// Scroll controller for the chat messages list.
  final ScrollController _scrollController = ScrollController();

  /// The selected child to ask about, or `null`.
  String? _selectedChildId;

  /// Whether the disclaimer has been shown on first use.
  bool _hasShownDisclaimer = false;

  /// Suggested question chips.
  static const _suggestedQuestions = [
    'Explain my child\'s report card',
    'How can I help with math?',
    'What does this grade mean?',
    'Study tips for exams',
    'Attendance impact on learning',
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownDisclaimer) {
        _showDisclaimerDialog();
        _hasShownDisclaimer = true;
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(parentAssistantProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Parent Assistant',
        actions: [
          // Info button → disclaimer dialog
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About this assistant',
            onPressed: _showDisclaimerDialog,
          ),
          // Child selector
          _buildChildSelector(context),
        ],
      ),
      body: Column(
        children: [
          // ─── Disclaimer Banner ───────────────────────────────────
          _buildDisclaimerBanner(context),

          // ─── Chat Messages ───────────────────────────────────────
          Expanded(
            child: _buildChatMessages(context, assistantState),
          ),

          // ─── Suggested Questions ─────────────────────────────────
          _buildSuggestedQuestions(context, assistantState),

          // ─── Input Bar ───────────────────────────────────────────
          _buildInputBar(context, assistantState),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCLAIMER BANNER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDisclaimerBanner(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      color: AppColors.warningOf(cs.brightness).withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: Spacings.smIcon,
            color: AppColors.warningOf(cs.brightness),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Text(
              'This AI assistant provides general guidance and does not replace teacher advice.',
              style: tt.labelSmall?.copyWith(
                color: AppColors.warningOf(cs.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChildSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: Spacings.sm),
      child: DropdownButton<String>(
        value: _selectedChildId,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: cs.onSurface,
          size: Spacings.mdIcon,
        ),
        underline: const SizedBox.shrink(),
        style: tt.labelMedium?.copyWith(color: cs.onSurface),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Children'),
          ),
          // TODO: Populate with actual children from dashboard state
        ],
        onChanged: (value) {
          setState(() => _selectedChildId = value);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAT MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChatMessages(
    BuildContext context,
    ParentAssistantState state,
  ) {
    final history = state.conversationHistory;

    if (history.isEmpty) {
      return AppEmptyState.noData(
        title: 'Ask a Question',
        subtitle:
            'Use the suggestions below or type your own question about your child\'s education.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      itemCount: history.length + (state.isLoading ? 1 : 0),
      itemBuilder: (_, index) {
        // Show typing indicator when loading
        if (index == history.length && state.isLoading) {
          return _buildTypingIndicator(context);
        }

        final entry = history[index];
        final isUser = entry['role'] == 'user';
        return _buildChatBubble(context, entry['content']!, isUser);
      },
    );
  }

  // ─── Chat Bubble ────────────────────────────────────────────────────

  Widget _buildChatBubble(
    BuildContext context,
    String content,
    bool isUser,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? cs.primary
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(Spacings.mdRadius),
                topRight: const Radius.circular(Spacings.mdRadius),
                bottomLeft: Radius.circular(
                  isUser ? Spacings.mdRadius : Spacings.xs,
                ),
                bottomRight: Radius.circular(
                  isUser ? Spacings.xs : Spacings.mdRadius,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sparkle icon for AI responses
                if (!isUser)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: Spacings.smIcon,
                        color: cs.primary,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'AI Assistant',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                if (!isUser) const SizedBox(height: Spacings.xs),
                // Message content
                Text(
                  content,
                  style: tt.bodyMedium?.copyWith(
                    color: isUser ? cs.onPrimary : cs.onSurface,
                  ),
                ),
                // "Talk to Teacher" button for AI responses
                if (!isUser) ...[
                  const SizedBox(height: Spacings.sm),
                  SizedBox(
                    height: 32,
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to messaging with teacher
                      },
                      icon: Icon(
                        Icons.chat_outlined,
                        size: Spacings.smIcon,
                        color: cs.primary,
                      ),
                      label: Text(
                        'Talk to Teacher',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Typing Indicator ───────────────────────────────────────────────

  Widget _buildTypingIndicator(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Spacings.mdRadius),
              topRight: Radius.circular(Spacings.mdRadius),
              bottomRight: Radius.circular(Spacings.mdRadius),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: Spacings.smIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Thinking…',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUGGESTED QUESTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSuggestedQuestions(
    BuildContext context,
    ParentAssistantState state,
  ) {
    if (state.isLoading) return const SizedBox.shrink();

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.xs,
        ),
        children: _suggestedQuestions.map((question) {
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: ActionChip(
              label: Text(
                question,
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                ),
              ),
              avatar: Icon(
                Icons.auto_awesome_outlined,
                size: Spacings.smIcon,
                color: cs.primary,
              ),
              onPressed: () => _askQuestion(question),
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusSm,
                side: BorderSide(
                  color: cs.primary.withOpacity(0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INPUT BAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInputBar(
    BuildContext context,
    ParentAssistantState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: Spacings.lg,
        right: Spacings.lg,
        top: Spacings.sm,
        bottom: Spacings.lg + context.mediaQuery.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask about your child\'s education…',
                hintStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askQuestion(_questionController.text.trim()),
            ),
          ),
          const SizedBox(width: Spacings.xs),
          // Send button
          IconButton(
            icon: Icon(
              Icons.send,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
            onPressed: state.isLoading
                ? null
                : () => _askQuestion(_questionController.text.trim()),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCLAIMER DIALOG
  // ═══════════════════════════════════════════════════════════════════════

  void _showDisclaimerDialog() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.auto_awesome_outlined,
          color: cs.primary,
          size: Spacings.xlIcon,
        ),
        title: Text(
          'AI Parent Assistant',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        content: Text(
          'The AI assistant provides general educational guidance. '
          'It does not make academic decisions or replace direct '
          'communication with teachers.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Submits a question to the AI assistant.
  void _askQuestion(String question) {
    if (question.isEmpty) return;

    _questionController.clear();
    ref.read(parentAssistantProvider.notifier).askQuestion(
      question,
      _selectedChildId,
    );

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
