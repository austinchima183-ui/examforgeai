import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ─── TypingIndicator ──────────────────────────────────────────────────────────

/// Animated typing dots indicator that shows which users are currently typing.
/// Three bouncing dots animate sequentially to simulate a typing effect.
///
/// ```dart
/// TypingIndicator(typingUserNames: ['Alice', 'Bob'])
/// ```
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    required this.typingUserNames,
  });

  /// Names of users who are currently typing.
  final List<String> typingUserNames;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Label ─────────────────────────────────────────────────────────────

  String _typingLabel() {
    final names = widget.typingUserNames;
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names[0]} is typing';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing';
    return '${names[0]} and ${names.length - 1} others are typing';
  }

  // ─── Bouncing Dot ─────────────────────────────────────────────────────

  Widget _buildDot(int index) {
    final cs = context.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Stagger each dot by 0.2s (200ms)
        final delay = index * 0.2;
        final t = (_controller.value - delay) % 1.0;
        // Bounce up during the first half, down during second half
        final bounce = sin(t * pi * 2) * 0.5 + 0.5;
        final yOffset = -bounce * 4.0;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: child,
        );
      },
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.typingUserNames.isEmpty) return const SizedBox.shrink();

    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          _buildDot(0),
          const SizedBox(width: 3),
          _buildDot(1),
          const SizedBox(width: 3),
          _buildDot(2),
          const SizedBox(width: Spacings.sm),

          // Label
          Flexible(
            child: Text(
              _typingLabel(),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
