import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/spacings.dart';

// ─── MessageInput ─────────────────────────────────────────────────────────────

/// Chat message input widget with auto-growing text field, send button,
/// attachment icon, voice note icon, and an optional reply preview bar.
///
/// ```dart
/// MessageInput(
///   onSend: (text) => sendMessage(text),
///   onAttachment: () => pickAttachment(),
///   onVoiceNote: () => recordVoice(),
///   replyToPreview: 'Replying to Alice: Hello!',
///   onCancelReply: () => clearReply(),
/// )
/// ```
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.onVoiceNote,
    this.replyToPreview,
    this.onCancelReply,
    this.isEnabled = true,
  });

  /// Callback when the user sends a message.
  final ValueChanged<String> onSend;

  /// Callback for the attachment button.
  final VoidCallback? onAttachment;

  /// Callback for the voice note button.
  final VoidCallback? onVoiceNote;

  /// Preview text for the message being replied to.
  final String? replyToPreview;

  /// Callback to cancel the reply.
  final VoidCallback? onCancelReply;

  /// Whether the input is enabled.
  final bool isEnabled;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {}); // Refresh send button state
  }

  // ─── Reply Preview Bar ────────────────────────────────────────────────

  Widget _buildReplyPreview(BuildContext context) {
    if (widget.replyToPreview == null) return const SizedBox.shrink();
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Text(
              widget.replyToPreview!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Icon(
              Icons.close_rounded,
              size: Spacings.mdIcon,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview
        _buildReplyPreview(context),

        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              IconButton(
                onPressed: widget.isEnabled ? widget.onAttachment : null,
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: widget.isEnabled
                      ? cs.onSurfaceVariant
                      : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  size: Spacings.mdIcon,
                ),
                padding: const EdgeInsets.all(Spacings.sm),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                tooltip: 'Attach file',
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => setState(() {}),
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Spacings.xlRadius),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacings.lg,
                      vertical: Spacings.md,
                    ),
                    isDense: true,
                  ),
                ),
              ),

              // Voice note button (when no text) / Send button
              if (_hasText)
                IconButton(
                  onPressed: widget.isEnabled ? _handleSend : null,
                  icon: Container(
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(
                      color: widget.isEnabled
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: cs.onPrimary,
                      size: Spacings.mdIcon - 4,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  tooltip: 'Send',
                )
              else
                IconButton(
                  onPressed:
                      widget.isEnabled ? widget.onVoiceNote : null,
                  icon: Icon(
                    Icons.mic_rounded,
                    color: widget.isEnabled
                        ? cs.onSurfaceVariant
                        : cs.onSurfaceVariant.withValues(alpha: 0.4),
                    size: Spacings.mdIcon,
                  ),
                  padding: const EdgeInsets.all(Spacings.sm),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: 'Voice note',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
