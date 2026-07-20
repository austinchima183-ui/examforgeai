import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_coach_entities.dart';
import '../providers/ai_coach_provider.dart';

/// AI Coach conversation/chat interface page.
///
/// Features:
/// - Chat message list with user and AI bubbles
/// - Message input with send button
/// - Session type selector
/// - Auto-scroll on new messages
/// - Typing indicator for AI responses
/// - Markdown rendering for AI responses
/// - Session creation on first message
class CoachChatPage extends ConsumerStatefulWidget {
  const CoachChatPage({super.key});

  @override
  ConsumerState<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends ConsumerState<CoachChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  CoachSessionType _selectedSessionType = CoachSessionType.general;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
    final state = ref.watch(aiCoachProvider);
    final session = state.currentSession;
    final messages = session?.messages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Coach'),
            if (session != null)
              Text(
                session.sessionType.label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (session != null)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new_session',
                  child: Text('New Session'),
                ),
                const PopupMenuItem(
                  value: 'generate_plan',
                  child: Text('Generate Study Plan'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'new_session':
                    ref.read(aiCoachProvider.notifier).clearCurrentSession();
                    break;
                  case 'generate_plan':
                    ref.read(aiCoachProvider.notifier).generateStudyPlan();
                    break;
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Session Type Selector (when no active session) ──────────
          if (session == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: context.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What would you like help with?',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CoachSessionType.values.map((type) {
                      final isSelected = _selectedSessionType == type;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSessionType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // ─── Messages List ───────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final role = message['role'] as String? ?? 'user';
                      final content = message['content'] as String? ?? '';
                      final isUser = role == 'user';

                      return _ChatBubble(
                        content: content,
                        isUser: isUser,
                      );
                    },
                  ),
          ),

          // ─── Typing Indicator ────────────────────────────────────────
          if (state.isSendingMessage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Coach is thinking...',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Message Input ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ask your AI Coach...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: state.isSendingMessage ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI Coach is Ready',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything about your studies, get personalized recommendations, '
              'or let me help you identify your weak areas.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Suggested prompts
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestedPrompt(
                  label: 'What should I study today?',
                  onTap: () => _sendSuggested('What should I study today?'),
                ),
                _SuggestedPrompt(
                  label: 'Help me with my weak topics',
                  onTap: () =>
                      _sendSuggested('Help me identify and improve my weak topics'),
                ),
                _SuggestedPrompt(
                  label: 'Create a study plan for me',
                  onTap: () =>
                      _sendSuggested('Create a personalized study plan for me'),
                ),
                _SuggestedPrompt(
                  label: 'Am I ready for my exam?',
                  onTap: () =>
                      _sendSuggested('Am I ready for my upcoming exam?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.requestFocus();

    final state = ref.read(aiCoachProvider);
    final session = state.currentSession;

    if (session == null) {
      // Create a new session first
      ref.read(aiCoachProvider.notifier).createSession(
            sessionType: _selectedSessionType,
            context: content,
          );
    } else {
      ref.read(aiCoachProvider.notifier).sendMessage(content);
    }

    _scrollToBottom();
  }

  void _sendSuggested(String prompt) {
    _messageController.text = prompt;
    _sendMessage();
  }
}

/// Chat bubble widget for messages.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.content,
    required this.isUser,
  });

  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: context.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'AI Coach',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              content,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suggested prompt chip.
class _SuggestedPrompt extends StatelessWidget {
  const _SuggestedPrompt({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
    );
  }
}
