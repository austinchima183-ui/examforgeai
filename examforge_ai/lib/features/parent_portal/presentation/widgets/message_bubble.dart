import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════════

/// Chat message bubble widget for the parent messaging system.
///
/// Sent messages (isMe = true) are right-aligned with the primary color
/// background and white text. Received messages are left-aligned with
/// surface variant background. Includes message body, time display,
/// read status indicators (double checks), and attachment indicators.
///
/// ```dart
/// MessageBubble(
///   message: myMessage,
///   isMe: true,
/// )
/// ```
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  /// The message entity to display.
  final ParentMessageEntity message;

  /// True if this message was sent by the current user.
  final bool isMe;

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

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? Spacings.xxl : Spacings.sm,
        right: isMe ? Spacings.sm : Spacings.xxl,
        top: Spacings.sm,
        bottom: Spacings.sm,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ── Sender name (for received messages) ────────────────────
          if (!isMe && message.senderName != null)
            Padding(
              padding: const EdgeInsets.only(
                left: Spacings.md,
                bottom: Spacings.xs,
              ),
              child: Text(
                message.senderName!,
                style: tt.labelSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.primary,
                ),
              ),
            ),

          // ── Bubble ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                _buildAvatar(cs, isDark),
                const SizedBox(width: Spacings.sm),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.md,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(Spacings.lgRadius),
                      topRight: const Radius.circular(Spacings.lgRadius),
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
                      // ── Message Body ────────────────────────────────
                      Text(
                        message.body,
                        style: tt.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.5,
                        ),
                      ),

                      // ── Attachment Indicator ────────────────────────
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: Spacings.sm),
                        _buildAttachmentIndicator(cs, tt, isDark, textColor),
                      ],

                      // ── Time + Read Status ──────────────────────────
                      const SizedBox(height: Spacings.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: tt.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: Spacings.xs),
                            _buildReadStatus(cs, textColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: Spacings.sm),
                _buildAvatar(cs, isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Avatar ───────────────────────────────────────────────────────

  Widget _buildAvatar(ColorScheme cs, bool isDark) {
    final name = isMe
        ? (message.senderName ?? 'You')
        : (message.senderName ?? '?');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isMe
            ? cs.primaryContainer
            : cs.primary.withOpacity(isDark ? 0.25 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 12,
            fontWeight: AppTypography.wBold,
            color: isMe ? cs.onPrimaryContainer : cs.primary,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ─── Attachment Indicator ─────────────────────────────────────────

  Widget _buildAttachmentIndicator(
    ColorScheme cs,
    TextTheme tt,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: Spacings.smIcon,
            color: textColor.withOpacity(0.8),
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            '${message.attachments.length} attachment${message.attachments.length == 1 ? '' : 's'}',
            style: tt.labelSmall?.copyWith(
              color: textColor.withOpacity(0.8),
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Read Status (Double Check) ───────────────────────────────────

  Widget _buildReadStatus(ColorScheme cs, Color textColor) {
    final isRead = message.status == MessageStatus.read;
    final isDelivered = message.status == MessageStatus.delivered ||
        message.status == MessageStatus.read;

    if (!isDelivered) {
      // Single check — sent
      return Icon(
        Icons.check_rounded,
        size: 14,
        color: textColor.withOpacity(0.5),
      );
    }

    // Double check
    return Icon(
      Icons.done_all_rounded,
      size: 14,
      color: isRead
          ? Colors.lightBlueAccent
          : textColor.withOpacity(0.5),
    );
  }

  // ─── Time Formatting ──────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
