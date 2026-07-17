import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHAT MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════════

/// Chat message bubble for the AI Tutor interface.
///
/// User messages are right-aligned with the primary color background.
/// AI messages are left-aligned with the surface color and an AI avatar icon.
/// Supports basic markdown rendering: bold, italic, code blocks, and lists.
/// The timestamp is displayed below the bubble.
///
/// ```dart
/// ChatMessageBubble(
///   content: 'Hello! How can I help you?',
///   isUser: false,
///   timestamp: DateTime.now(),
/// )
/// ```
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  /// The message text content (may contain markdown).
  final String content;

  /// Whether this message was sent by the user (true) or AI (false).
  final bool isUser;

  /// When the message was sent.
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? Spacings.xxl : Spacings.sm,
        right: isUser ? Spacings.sm : Spacings.xxl,
        top: Spacings.sm,
        bottom: Spacings.sm,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ── Avatar + Bubble Row ─────────────────────────────────────
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _buildAiAvatar(context),
                const SizedBox(width: Spacings.sm),
              ],
              Flexible(child: _buildBubble(context)),
              if (isUser) ...[
                const SizedBox(width: Spacings.sm),
                _buildUserAvatar(context),
              ],
            ],
          ),

          const SizedBox(height: Spacings.xs),

          // ── Timestamp ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : Spacings.xl + Spacings.md,
              right: isUser ? Spacings.xl + Spacings.md : 0,
            ),
            child: Text(
              _formatTimestamp(timestamp),
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Avatar ─────────────────────────────────────────────────────

  Widget _buildAiAvatar(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        size: 18,
        color: cs.primary,
      ),
    );
  }

  // ─── User Avatar ───────────────────────────────────────────────────

  Widget _buildUserAvatar(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: 18,
        color: cs.onPrimaryContainer,
      ),
    );
  }

  // ─── Bubble ────────────────────────────────────────────────────────

  Widget _buildBubble(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    final bgColor = isUser
        ? cs.primary
        : isDark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLow;
    final textColor = isUser ? cs.onPrimary : cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Spacings.lgRadius),
          topRight: const Radius.circular(Spacings.lgRadius),
          bottomLeft: isUser
              ? const Radius.circular(Spacings.lgRadius)
              : const Radius.circular(Spacings.xs),
          bottomRight: isUser
              ? const Radius.circular(Spacings.xs)
              : const Radius.circular(Spacings.lgRadius),
        ),
      ),
      child: _buildMarkdownContent(context, textColor),
    );
  }

  // ─── Simple Markdown Renderer ──────────────────────────────────────

  Widget _buildMarkdownContent(BuildContext context, Color textColor) {
    final spans = _parseMarkdown(content, textColor);
    return RichText(
      text: TextSpan(
        style: context.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  /// Parses simple markdown patterns into TextSpans.
  /// Supports: **bold**, *italic*, `code`, - list items.
  List<TextSpan> _parseMarkdown(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      if (lineIdx > 0) {
        spans.add(const TextSpan(text: '\n'));
      }

      // Handle list items
      String trimmedLine = line;
      bool isListItem = false;
      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('• ')) {
        isListItem = true;
        trimmedLine = trimmedLine.substring(2);
      } else if (trimmedLine.startsWith(RegExp(r'\d+\.\s'))) {
        isListItem = true;
        final match = RegExp(r'\d+\.\s').firstMatch(trimmedLine);
        if (match != null) {
          trimmedLine = trimmedLine.substring(match.end);
        }
      }

      if (isListItem) {
        spans.add(TextSpan(
          text: '• ',
          style: TextStyle(
            fontWeight: AppTypography.wBold,
            color: baseColor,
          ),
        ));
      }

      // Parse inline formatting: **bold**, *italic*, `code`
      _parseInline(trimmedLine, spans, baseColor);
    }

    return spans;
  }

  void _parseInline(String text, List<TextSpan> spans, Color baseColor) {
    final regex = RegExp(r'(\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      if (match.group(2) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontWeight: AppTypography.wBold,
            color: baseColor,
          ),
        ));
      } else if (match.group(3) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor,
          ),
        ));
      } else if (match.group(4) != null) {
        // Inline code
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            backgroundColor: baseColor.withValues(alpha: 0.12),
            color: baseColor,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
  }

  // ─── Timestamp Formatting ──────────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
