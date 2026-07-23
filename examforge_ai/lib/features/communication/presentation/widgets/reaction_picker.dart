import 'package:flutter/material.dart';

import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ─── ReactionPicker ───────────────────────────────────────────────────────────

/// Emoji reaction picker displayed as a bottom sheet. Shows a horizontal
/// row of common emojis that users can tap to add a reaction to a message.
///
/// Common emojis: ❤️ 👍 👎 😂 😮 😢 🎉 🔥
///
/// ```dart
/// ReactionPicker(onEmojiSelected: (emoji) => addReaction(emoji))
/// ```
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  /// Callback with the selected emoji string.
  final ValueChanged<String> onEmojiSelected;

  /// The standard set of reaction emojis.
  static const List<String> defaultEmojis = [
    '❤️',
    '👍',
    '👎',
    '😂',
    '😮',
    '😢',
    '🎉',
    '🔥',
  ];

  // ─── Show as Bottom Sheet ─────────────────────────────────────────────

  /// Convenience method to show the picker as a modal bottom sheet.
  static Future<String?> show(
    BuildContext context, {
    List<String>? emojis,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ReactionPicker(
        onEmojiSelected: (emoji) => Navigator.of(context).pop(emoji),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(Spacings.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Add Reaction',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurfaceVariant,
              letterSpacing: AppTypography.lsLabel,
            ),
          ),
          const SizedBox(height: Spacings.md),

          // Emoji row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: defaultEmojis.map((emoji) {
              return GestureDetector(
                onTap: () => onEmojiSelected(emoji),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacings.sm),
        ],
      ),
    );
  }
}
