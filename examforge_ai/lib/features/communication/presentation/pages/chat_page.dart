import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/message_provider.dart';
import '../providers/conversation_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHAT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Full chat interface for a conversation.
///
/// Features:
/// - App bar with conversation name, online status, member count
/// - Message list with text bubbles (sent/received), image/file attachments,
///   system messages, emoji reactions
/// - Reply preview bar when replying
/// - Input area: text field, attachment, send, voice note (placeholder)
/// - Message long-press menu: reply, forward, pin, edit, delete, react
/// - Typing indicator
/// - Scroll-to-bottom FAB
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    this.conversationName,
  });

  final String conversationId;
  final String? conversationName;

  @override
  ConsumerState<ChatPage> createState() => _State();
}

class _State extends ConsumerState<ChatPage> {
  // ─── State ──────────────────────────────────────────────────────────

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  MessageEntity? _replyTo;
  bool _showScrollToBottom = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider.notifier).loadMessages(widget.conversationId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageProvider);
    final convState = ref.watch(conversationProvider);
    final conv = convState.currentConversation;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.conversationName ?? conv?.name ?? 'Chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {/* TODO: conversation options */},
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Online Status Bar ──────────────────────────────────
          if (conv != null) _buildStatusBar(conv),

          // ─── Messages List ──────────────────────────────────────
          Expanded(child: _buildMessagesList(messageState)),

          // ─── Reply Preview ──────────────────────────────────────
          if (_replyTo != null) _buildReplyPreview(),

          // ─── Input Area ─────────────────────────────────────────
          _buildInputArea(messageState),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.keyboard_arrow_down),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATUS BAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatusBar(ConversationEntity conv) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final onlineCount = conv.participants.where((p) => p.isOnline).length;
    final totalMembers = conv.participants.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs, horizontal: Spacings.lg),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: onlineCount > 1 ? AppColors.success : cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            '$onlineCount online · $totalMembers members',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMessagesList(MessageState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (state.error != null && state.messages.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(messageProvider.notifier).loadMessages(widget.conversationId),
      );
    }

    if (state.messages.isEmpty) {
      return AppEmptyState.noMessages(subtitle: 'Send the first message in this conversation.');
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      itemCount: state.messages.length,
      itemBuilder: (_, index) => _buildMessageBubble(state.messages[index]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE BUBBLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMessageBubble(MessageEntity message) {
    final cs = Theme.of(context).colorScheme;
    final isSent = message.senderId == 'current_user'; // TODO: replace with actual user ID
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ─── Reply Reference ────────────────────────────────────
          if (message.replyTo != null) _buildReplyReference(message.replyTo!, isSent),

          // ─── Bubble ────────────────────────────────────────────
          GestureDetector(
            onLongPress: () => _showMessageMenu(message),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.md),
              decoration: BoxDecoration(
                color: isSent ? cs.primary : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(Spacings.mdRadius),
                  topRight: const Radius.circular(Spacings.mdRadius),
                  bottomLeft: Radius.circular(isSent ? Spacings.mdRadius : Spacings.xs),
                  bottomRight: Radius.circular(isSent ? Spacings.xs : Spacings.mdRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Attachments ────────────────────────────────
                  if (message.attachments.isNotEmpty)
                    _buildAttachments(message.attachments, isSent),

                  // ─── Text Body ──────────────────────────────────
                  if (message.body.isNotEmpty)
                    Text(
                      message.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSent ? cs.onPrimary : cs.onSurface,
                      ),
                    ),

                  // ─── Edited Indicator ────────────────────────────
                  if (message.isEdited)
                    Text(
                      ' (edited)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSent ? cs.onPrimary.withValues(alpha: 0.7) : cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // ─── Time ────────────────────────────────────────
                  const SizedBox(height: Spacings.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSent ? cs.onPrimary.withValues(alpha: 0.7) : cs.onSurfaceVariant,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: Spacings.xs),
                        Icon(
                          message.readBy.length > 1 ? Icons.done_all : Icons.done,
                          size: Spacings.smIcon,
                          color: isSent ? cs.onPrimary.withValues(alpha: 0.7) : cs.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Reactions ──────────────────────────────────────────
          if (message.reactions.isNotEmpty) _buildReactions(message, isSent),
        ],
      ),
    );
  }

  // ─── System Message ─────────────────────────────────────────────────

  Widget _buildSystemMessage(MessageEntity message) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.xs),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: Spacings.borderRadiusFull,
          ),
          child: Text(
            message.body,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reply Reference ────────────────────────────────────────────────

  Widget _buildReplyReference(MessageEntity replyTo, bool isSent) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacings.xs),
      padding: const EdgeInsets.all(Spacings.sm),
      decoration: BoxDecoration(
        color: (isSent ? cs.onPrimary : cs.primary).withValues(alpha: 0.1),
        borderRadius: Spacings.borderRadiusSm,
        border: Border(left: BorderSide(color: isSent ? cs.onPrimary : cs.primary, width: 3)),
      ),
      child: Text(
        '${replyTo.senderName}: ${replyTo.body}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSent ? cs.onPrimary.withValues(alpha: 0.8) : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Attachments ────────────────────────────────────────────────────

  Widget _buildAttachments(List<MessageAttachmentEntity> attachments, bool isSent) {
    return Column(
      children: attachments.map((att) {
        return Container(
          margin: const EdgeInsets.only(bottom: Spacings.sm),
          padding: const EdgeInsets.all(Spacings.sm),
          decoration: BoxDecoration(
            borderRadius: Spacings.borderRadiusSm,
            border: Border.all(
              color: (isSent ? AppColors.seed : AppColors.info).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_attachmentIcon(att.fileType), size: Spacings.mdIcon, color: isSent ? AppColors.seed : AppColors.info),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  att.fileName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSent ? AppColors.seed : AppColors.info,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Reactions ──────────────────────────────────────────────────────

  Widget _buildReactions(MessageEntity message, bool isSent) {
    final grouped = <String, int>{};
    for (final r in message.reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: Spacings.xs),
      child: Wrap(
        spacing: Spacings.xs,
        children: grouped.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: Spacings.borderRadiusFull,
          ),
          child: Text('${e.key} ${e.value}', style: Theme.of(context).textTheme.labelSmall),
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPLY PREVIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildReplyPreview() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 32, color: cs.primary),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reply to ${_replyTo!.senderName}', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wSemiBold)),
                Text(_replyTo!.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: Spacings.mdIcon),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INPUT AREA
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInputArea(MessageState state) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment
            IconButton(
              icon: const Icon(Icons.attach_file_outlined),
              onPressed: () {/* TODO: pick attachment */},
              color: cs.onSurfaceVariant,
            ),
            // Text Field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusXl,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            // Voice Note (disabled placeholder)
            IconButton(
              icon: const Icon(Icons.mic_none_outlined),
              onPressed: null,
              color: cs.onSurfaceVariant,
            ),
            // Send
            IconButton(
              icon: state.isSending
                  ? const SizedBox(width: 24, height: 24, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small))
                  : const Icon(Icons.send_rounded),
              onPressed: state.isSending ? null : _sendMessage,
              color: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE MENU
  // ═══════════════════════════════════════════════════════════════════════

  void _showMessageMenu(MessageEntity message) {
    final cs = Theme.of(context).colorScheme;
    final isOwn = message.senderId == 'current_user';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () { Navigator.pop(ctx); setState(() => _replyTo = message); },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(message.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(message.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(messageProvider.notifier).pinMessage(message.id, !message.isPinned);
              },
            ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.errorOf(cs.brightness)),
                title: Text('Delete', style: TextStyle(color: AppColors.errorOf(cs.brightness))),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(messageProvider.notifier).deleteMessage(message.id);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(MessageEntity message) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((e) => GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              ref.read(messageProvider.notifier).addReaction(message.id, e);
            },
            child: Text(e, style: const TextStyle(fontSize: 28)),
          )).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(messageProvider.notifier).sendMessage(
      SendMessageParams(
        conversationId: widget.conversationId,
        type: 'text',
        body: text,
        replyToId: _replyTo?.id,
      ),
    );
    _messageController.clear();
    setState(() => _replyTo = null);
    _scrollToBottom();
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

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  IconData _attachmentIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case AttachmentType.video:
        return Icons.videocam_outlined;
      case AttachmentType.audio:
        return Icons.audiotrack_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatMessageTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
