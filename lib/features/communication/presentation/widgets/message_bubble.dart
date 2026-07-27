import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/communication_entities.dart';
import 'attachment_preview.dart';

// ─── MessageBubble ────────────────────────────────────────────────────────────

/// Chat message bubble widget for the communication module.
///
/// Sent messages (`isMe = true`) are right-aligned with primary color
/// background. Received messages are left-aligned with surface variant.
/// Supports reply previews, reactions, attachments, read receipts, and
/// a long-press context menu.
///
/// ```dart
/// MessageBubble(
///   message: msg,
///   isMe: true,
///   onReply: () => replyTo(msg.id),
///   onDelete: () => deleteMsg(msg.id),
/// )
/// ```
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onReact,
    this.onForward,
  });

  final MessageEntity message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onReact;
  final VoidCallback? onForward;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // ─── Reply Preview ────────────────────────────────────────────────────

  Widget _buildReplyPreview(BuildContext context, Color textColor) {
    final reply = message.replyTo;
    if (reply == null) return const SizedBox.shrink();
    final cs = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      padding: const EdgeInsets.all(Spacings.sm),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border(
          left: BorderSide(color: cs.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.wSemiBold,
              color: cs.primary,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            reply.body,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Reactions Row ────────────────────────────────────────────────────

  Widget _buildReactionsRow(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final cs = context.colorScheme;

    // Group reactions by emoji
    final grouped = <String, int>{};
    for (final r in message.reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: Spacings.xs),
      child: Wrap(
        spacing: Spacings.xs,
        children: grouped.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${e.key} ${e.value}',
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
        ),).toList(),
      ),
    );
  }

  // ─── Attachment Previews ──────────────────────────────────────────────

  Widget _buildAttachmentPreviews(BuildContext context, Color textColor) {
    if (message.attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.attachments
            .map((a) => AttachmentPreview(
                  attachment: a,
                  textColor: textColor,
                ),)
            .toList(),
      ),
    );
  }

  // ─── Context Menu ─────────────────────────────────────────────────────

  void _showContextMenu(BuildContext context) {
    final cs = context.colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: Icon(Icons.reply_rounded, color: cs.onSurface),
                title: Text('Reply', style: context.textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); onReply!(); },
              ),
            if (onForward != null)
              ListTile(
                leading: Icon(Icons.forward_rounded, color: cs.onSurface),
                title: Text('Forward', style: context.textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); onForward!(); },
              ),
            if (isMe && onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_outlined, color: cs.onSurface),
                title: Text('Edit', style: context.textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); onEdit!(); },
              ),
            if (onPin != null)
              ListTile(
                leading: Icon(
                  message.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: cs.onSurface,
                ),
                title: Text(
                  message.isPinned ? 'Unpin' : 'Pin',
                  style: context.textTheme.bodyMedium,
                ),
                onTap: () { Navigator.pop(context); onPin!(); },
              ),
            if (onReact != null)
              ListTile(
                leading: Icon(Icons.emoji_emotions_outlined, color: cs.onSurface),
                title: Text('React', style: context.textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); onReact!(); },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: AppColors.errorOf(cs.brightness),),
                title: Text('Delete',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.errorOf(cs.brightness),
                    ),),
                onTap: () { Navigator.pop(context); onDelete!(); },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final bgColor = isMe
        ? cs.primary
        : isDark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLow;
    final textColor = isMe ? cs.onPrimary : cs.onSurface;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? Spacings.xxl : Spacings.sm,
          right: isMe ? Spacings.sm : Spacings.xxl,
          top: Spacings.xs,
          bottom: Spacings.xs,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (for group chats)
            if (!isMe && message.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: Spacings.md,
                  bottom: Spacings.xs,
                ),
                child: Text(
                  message.senderName,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.primary,
                  ),
                ),
              ),

            // Bubble
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.md,
                      vertical: Spacings.md,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.only(
                        topLeft:
                            const Radius.circular(Spacings.lgRadius),
                        topRight:
                            const Radius.circular(Spacings.lgRadius),
                        bottomLeft: isMe
                            ? const Radius.circular(Spacings.lgRadius)
                            : const Radius.circular(Spacings.xs),
                        bottomRight: isMe
                            ? const Radius.circular(Spacings.xs)
                            : const Radius.circular(Spacings.lgRadius),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply preview
                        _buildReplyPreview(context, textColor),

                        // Attachments
                        _buildAttachmentPreviews(context, textColor),

                        // Message body
                        Text(
                          message.body,
                          style: tt.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.5,
                          ),
                        ),

                        // Time + edited + read receipts
                        const SizedBox(height: Spacings.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.isEdited) ...[
                              Text(
                                'edited',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      textColor.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(width: Spacings.xs),
                            ],
                            Text(
                              _formatTime(message.createdAt),
                              style: tt.labelSmall?.copyWith(
                                color:
                                    textColor.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: Spacings.xs),
                              Icon(
                                message.readBy.isNotEmpty
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded,
                                size: 14,
                                color: message.readBy.isNotEmpty
                                    ? Colors.lightBlueAccent
                                    : textColor.withValues(alpha: 0.5),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Reactions
            _buildReactionsRow(context),
          ],
        ),
      ),
    );
  }
}
