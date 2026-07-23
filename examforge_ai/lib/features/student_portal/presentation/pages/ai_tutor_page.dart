import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../providers/student_portal_providers.dart';

/// AI Tutor chat interface page.
///
/// Features:
/// - Conversation list sidebar (desktop) / drawer (mobile)
/// - Chat area with message bubbles
/// - Input field with send button at bottom
/// - New conversation FAB
/// - Subject/topic selection when creating new conversation
/// - Auto-scroll to bottom on new messages
/// - Typing indicator for AI responses
/// - Markdown rendering for AI responses
/// - Empty state for no conversations
class AiTutorPage extends ConsumerStatefulWidget {
  const AiTutorPage({super.key});

  @override
  ConsumerState<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends ConsumerState<AiTutorPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiTutorProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(aiTutorProvider);

    if (tutorState.isLoading && tutorState.conversations.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (tutorState.error != null && tutorState.conversations.isEmpty) {
      return AppErrorState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load Conversations',
        message: tutorState.error,
        onRetry: () =>
            ref.read(aiTutorProvider.notifier).loadConversations(),
      );
    }

    if (context.isDesktop) {
      return _buildDesktopLayout(context, tutorState);
    }
    return _buildMobileLayout(context, tutorState);
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, AiTutorState state) {
    return Row(
      children: [
        // Sidebar - conversation list
        SizedBox(
          width: 300,
          child: _buildConversationList(context, state),
        ),
        const VerticalDivider(width: 1),
        // Chat area
        Expanded(
          child: state.currentConversation == null
              ? _buildEmptyChatState(context)
              : _buildChatArea(context, state),
        ),
      ],
    );
  }

  // ─── Mobile Layout ──────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, AiTutorState state) {
    if (state.currentConversation == null) {
      return _buildConversationList(context, state);
    }
    return _buildChatArea(context, state);
  }

  // ─── Conversation List ──────────────────────────────────────────────

  Widget _buildConversationList(BuildContext context, AiTutorState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Tutor',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _showNewConversationDialog(context),
            tooltip: 'New Conversation',
          ),
        ],
      ),
      body: state.conversations.isEmpty
          ? AppEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No Conversations',
              subtitle: 'Start a new conversation with the AI Tutor.',
              actionLabel: 'New Chat',
              onAction: () => _showNewConversationDialog(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: Spacings.sm,
              ),
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final isSelected =
                    state.currentConversation?.id == conversation.id;

                return _ConversationTile(
                  conversation: conversation,
                  isSelected: isSelected,
                  onTap: () {
                    ref
                        .read(aiTutorProvider.notifier)
                        .openConversation(conversation.id);
                    _scrollToBottom();
                  },
                  onDelete: () {
                    ref
                        .read(aiTutorProvider.notifier)
                        .deleteConversation(conversation.id);
                  },
                );
              },
            ),
      floatingActionButton: state.conversations.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showNewConversationDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  // ─── Empty Chat State ───────────────────────────────────────────────

  Widget _buildEmptyChatState(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.xl),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: Spacings.xl),
            Text(
              'AI Study Assistant',
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Ask me anything about your subjects, get explanations, practice problems, and study tips.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.xl),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: [
                _SuggestionChip(
                  label: 'Explain a concept',
                  onTap: () => _sendMessage('Can you explain a concept to me?'),
                ),
                _SuggestionChip(
                  label: 'Help me practice',
                  onTap: () => _sendMessage('Can you give me some practice questions?'),
                ),
                _SuggestionChip(
                  label: 'Study tips',
                  onTap: () => _sendMessage('Give me some study tips for my upcoming exams.'),
                ),
                _SuggestionChip(
                  label: 'Review my answer',
                  onTap: () => _sendMessage('I\'d like you to review my answer to a question.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chat Area ──────────────────────────────────────────────────────

  Widget _buildChatArea(BuildContext context, AiTutorState state) {
    final cs = context.colorScheme;

    return Column(
      children: [
        // Chat header
        _buildChatHeader(context, state),

        // Messages
        Expanded(
          child: state.messages.isEmpty
              ? _buildWelcomeMessages(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(Spacings.lg),
                  itemCount: state.messages.length +
                      (state.isSendingMessage ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return _buildTypingIndicator(context);
                    }
                    final message = state.messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),

        // Input area
        _buildInputArea(context, state),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, AiTutorState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final conversation = state.currentConversation;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (context.isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ref.read(aiTutorProvider.notifier).clearError();
                // Navigate back to conversation list
              },
            ),
          CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Icon(
              Icons.smart_toy_rounded,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation?.title ?? 'AI Tutor',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                if (conversation?.topic != null)
                  Text(
                    conversation!.topic!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                ref
                    .read(aiTutorProvider.notifier)
                    .deleteConversation(conversation!.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Conversation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessages(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: Spacings.xlIcon,
              color: cs.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              'Start the conversation!',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Ask any question about your subjects and I\'ll help you learn.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final cs = context.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacings.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoadingDot(
              color: cs.onSurfaceVariant,
              size: 6,
              spacing: 4,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'AI is thinking...',
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AiTutorState state) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Spacings.xlRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.md,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: state.isSendingMessage
                    ? null
                    : (_) => _sendCurrentMessage(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            IconButton.filled(
              onPressed: state.isSendingMessage
                  ? null
                  : _sendCurrentMessage,
              icon: state.isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  void _sendCurrentMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(aiTutorProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    _messageController.text = text;
    _sendCurrentMessage();
  }

  // ─── New Conversation Dialog ────────────────────────────────────────

  void _showNewConversationDialog(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final titleController = TextEditingController();
    final topicController = TextEditingController();
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'New Conversation',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              content: SizedBox(
                width: context.isMobile ? double.maxFinite : 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Biology Review',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: Spacings.md),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'mathematics',
                          child: Text('Mathematics'),
                        ),
                        DropdownMenuItem(
                          value: 'english',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'biology',
                          child: Text('Biology'),
                        ),
                        DropdownMenuItem(
                          value: 'physics',
                          child: Text('Physics'),
                        ),
                        DropdownMenuItem(
                          value: 'chemistry',
                          child: Text('Chemistry'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedSubject = value);
                      },
                    ),
                    const SizedBox(height: Spacings.md),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic (optional)',
                        hintText: 'e.g., Photosynthesis',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ref.read(aiTutorProvider.notifier).createConversation(
                      title: titleController.text.trim().isEmpty
                          ? 'New Conversation'
                          : titleController.text.trim(),
                      subjectId: selectedSubject,
                      topic: topicController.text.trim().isEmpty
                          ? null
                          : topicController.text.trim(),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final AiTutorConversationEntity conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return ListTile(
      selected: isSelected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
      leading: CircleAvatar(
        backgroundColor:
            cs.primaryContainer.withValues(alpha: isSelected ? 1.0 : 0.5),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: Spacings.mdIcon,
          color: cs.primary,
        ),
      ),
      title: Text(
        conversation.title,
        style: tt.titleSmall?.copyWith(
          fontWeight:
              isSelected ? AppTypography.wSemiBold : AppTypography.wMedium,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiTutorMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isUser = message.role == TutorMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacings.xs),
        constraints: BoxConstraints(
          maxWidth: context.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? cs.primary
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Spacings.lgRadius),
            topRight: const Radius.circular(Spacings.lgRadius),
            bottomLeft: isUser
                ? const Radius.circular(Spacings.lgRadius)
                : Radius.zero,
            bottomRight: isUser
                ? Radius.zero
                : const Radius.circular(Spacings.lgRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacings.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: Spacings.smIcon,
                      color: cs.primary,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'AI Tutor',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.content,
              style: tt.bodyMedium?.copyWith(
                color: isUser ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: Icon(
        Icons.auto_awesome_outlined,
        size: Spacings.smIcon,
        color: cs.primary,
      ),
    );
  }
}
