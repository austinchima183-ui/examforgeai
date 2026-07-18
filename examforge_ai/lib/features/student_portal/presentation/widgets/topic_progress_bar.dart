import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// TOPIC PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════════

/// Horizontal progress bar for topic mastery.
///
/// Displays a colored progress bar (red for weak, green for strong) with
/// the topic name and percentage. Includes a small indicator icon: warning
/// for weak topics, star for strong topics.
///
/// ```dart
/// TopicProgressBar(topicName: 'Algebra', scorePct: 45.0, isWeak: true)
/// TopicProgressBar(topicName: 'Geometry', scorePct: 92.0, isWeak: false)
/// ```
class TopicProgressBar extends StatelessWidget {
  const TopicProgressBar({
    super.key,
    required this.topicName,
    required this.scorePct,
    required this.isWeak,
    this.onTap,
  });

  /// Name of the topic.
  final String topicName;

  /// Mastery score as a percentage (0–100).
  final double scorePct;

  /// Whether this is a weak topic requiring attention.
  final bool isWeak;

  /// Optional tap handler.
  final VoidCallback? onTap;

  Color _barColor() {
    if (isWeak) return AppColors.error;
    if (scorePct >= 80) return AppColors.success;
    if (scorePct >= 60) return AppColors.warning;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final barColor = _barColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.smRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label Row ────────────────────────────────────────────
            Row(
              children: [
                // Indicator icon
                Icon(
                  isWeak
                      ? Icons.warning_amber_rounded
                      : Icons.star_rounded,
                  size: Spacings.mdIcon,
                  color: isWeak
                      ? AppColors.errorOf(cs.brightness)
                      : AppColors.successOf(cs.brightness),
                ),
                const SizedBox(width: Spacings.sm),

                // Topic name
                Expanded(
                  child: Text(
                    topicName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    '${scorePct.round()}%',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: AppTypography.wBold,
                      color: isDark ? barColor.withValues(alpha: 0.9) : barColor,
                      letterSpacing: AppTypography.lsLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // ── Progress Bar ─────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                  ),
                  // Foreground
                  FractionallySizedBox(
                    widthFactor: (scorePct / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
