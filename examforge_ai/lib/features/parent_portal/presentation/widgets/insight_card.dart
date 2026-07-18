import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// INSIGHT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card widget for displaying an AI-generated insight.
///
/// Shows a coloured left bar based on severity, an insight type badge,
/// title, description (2 lines max), a preview of recommendations,
/// a dismiss button, and the creation date.
///
/// ```dart
/// InsightCard(
///   insight: myInsight,
///   onTap: () => showInsightDetail(insight),
///   onDismiss: () => dismissInsight(insight.id),
/// )
/// ```
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  /// The AI insight data to display.
  final ParentAiInsightEntity insight;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the dismiss button is pressed.
  final VoidCallback? onDismiss;

  // ─── Severity → Colour Mapping ────────────────────────────────────

  Color _severityColor() {
    return switch (insight.severity) {
      InsightSeverity.info => AppColors.info,
      InsightSeverity.warning => AppColors.warning,
      InsightSeverity.concern => AppColors.error,
      InsightSeverity.positive => AppColors.success,
    };
  }

  // ─── Insight Type → Icon ──────────────────────────────────────────

  IconData _typeIcon() {
    return switch (insight.insightType) {
      ParentInsightType.performanceTrend => Icons.trending_up_rounded,
      ParentInsightType.attendanceAlert => Icons.event_busy_rounded,
      ParentInsightType.studyRecommendation => Icons.menu_book_rounded,
      ParentInsightType.engagementTip => Icons.tips_and_updates_rounded,
      ParentInsightType.milestone => Icons.emoji_events_rounded,
      ParentInsightType.concern => Icons.warning_amber_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final barColor = _severityColor();

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // ── Left Colour Bar ────────────────────────────────────
            Positioned.fill(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    color: barColor,
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg,
                Spacings.md,
                Spacings.lg,
                Spacings.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Row: Badge + Dismiss ───────────────────────
                  Row(
                    children: [
                      _buildTypeBadge(cs, tt, isDark, barColor),
                      const Spacer(),
                      if (onDismiss != null)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            onPressed: onDismiss,
                            icon: Icon(
                              Icons.close_rounded,
                              size: Spacings.mdIcon - 4,
                              color: cs.onSurfaceVariant,
                            ),
                            padding: EdgeInsets.zero,
                            splashRadius: 14,
                            tooltip: 'Dismiss',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacings.sm),

                  // ── Title ──────────────────────────────────────────
                  Text(
                    insight.title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),

                  // ── Description ────────────────────────────────────
                  Text(
                    insight.description,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── Recommendations Preview ────────────────────────
                  if (insight.recommendations.isNotEmpty) ...[
                    const SizedBox(height: Spacings.sm),
                    _buildRecommendationsPreview(cs, tt, isDark),
                  ],

                  // ── Date ───────────────────────────────────────────
                  const SizedBox(height: Spacings.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (insight.isAiGenerated) ...[
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: Spacings.xs),
                      ],
                      Text(
                        insight.createdAt.timeAgo,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Type Badge ───────────────────────────────────────────────────

  Widget _buildTypeBadge(
    ColorScheme cs,
    TextTheme tt,
    bool isDark,
    Color barColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _typeIcon(),
            size: 14,
            color: barColor,
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            insight.insightType.label,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recommendations Preview ──────────────────────────────────────

  Widget _buildRecommendationsPreview(
    ColorScheme cs,
    TextTheme tt,
    bool isDark,
  ) {
    final previewItems = insight.recommendations.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: previewItems.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  rec,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
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
}
