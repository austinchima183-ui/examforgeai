import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD FLIP CARD
// ═══════════════════════════════════════════════════════════════════════

/// Animated flip card for flashcard study.
///
/// Tap to flip with a 3D rotation animation. The front displays the
/// question/concept with a "Tap to reveal" hint. The back shows the
/// answer/explanation. An optional hint button shows a hint overlay.
///
/// ```dart
/// FlashcardFlipCard(
///   frontContent: 'What is photosynthesis?',
///   backContent: 'The process by which plants convert light energy...',
///   hint: 'Think about sunlight and plants',
/// )
/// ```
class FlashcardFlipCard extends StatefulWidget {
  const FlashcardFlipCard({
    super.key,
    required this.frontContent,
    required this.backContent,
    this.hint,
  });

  /// Question or concept shown on the front.
  final String frontContent;

  /// Answer or explanation shown on the back.
  final String backContent;

  /// Optional hint text.
  final String? hint;

  @override
  State<FlashcardFlipCard> createState() => _FlashcardFlipCardState();
}

class _FlashcardFlipCardState extends State<FlashcardFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  bool _showHint = false;

  static const _flipDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: _flipDuration,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  void _flip() {
    if (_flipController.isAnimating) return;

    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _toggleHint() {
    setState(() => _showHint = !_showHint);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Flip Card ─────────────────────────────────────────────────
        GestureDetector(
          onTap: _flip,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, _) {
              final angle = _flipAnimation.value * math.pi;
              final isShowingFront = _flipAnimation.value <= 0.5;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(angle),
                child: isShowingFront
                    ? _buildFront(context, cs, tt)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildBack(context, cs, tt),
                      ),
              );
            },
          ),
        ),

        // ── Hint Button ───────────────────────────────────────────────
        if (widget.hint != null) ...[
          const SizedBox(height: Spacings.md),
          TextButton.icon(
            onPressed: _toggleHint,
            icon: Icon(
              _showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
              size: Spacings.mdIcon,
            ),
            label: Text(
              _showHint ? 'Hide Hint' : 'Show Hint',
              style: tt.labelLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
          if (_showHint) ...[
            const SizedBox(height: Spacings.sm),
            _buildHintOverlay(context, cs, tt),
          ],
        ],
      ],
    );
  }

  // ─── Front Side ────────────────────────────────────────────────────

  Widget _buildFront(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: context.isDarkMode ? 0.25 : 0.08),
            cs.secondaryContainer.withValues(alpha: context.isDarkMode ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Type indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_rounded, size: 14, color: cs.primary),
                const SizedBox(width: Spacings.xs),
                Text(
                  'QUESTION',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.primary,
                    letterSpacing: AppTypography.lsLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Question text
          SelectableText(
            widget.frontContent,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Tap to reveal hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                'Tap to reveal answer',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Back Side ─────────────────────────────────────────────────────

  Widget _buildBack(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: context.isDarkMode ? 0.20 : 0.08),
            AppColors.successLight.withValues(alpha: context.isDarkMode ? 0.10 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Type indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: Spacings.xs),
                Text(
                  'ANSWER',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: AppColors.success,
                    letterSpacing: AppTypography.lsLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Answer text
          SelectableText(
            widget.backContent,
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurface,
              height: 1.7,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Tap to flip back
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flip_rounded,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                'Tap to flip back',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Hint Overlay ──────────────────────────────────────────────────

  Widget _buildHintOverlay(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: context.isDarkMode ? 0.25 : 1.0),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            size: Spacings.mdIcon,
            color: AppColors.warning,
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Text(
              widget.hint!,
              style: tt.bodyMedium?.copyWith(
                color: context.isDarkMode ? AppColors.warning : AppColors.warningDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
