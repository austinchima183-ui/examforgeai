import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/communication_entities.dart';

// ─── KnowledgeSourceCard ──────────────────────────────────────────────────────

/// Source citation card for the AI Knowledge Assistant. Displays document
/// title, document type, relevance score bar, and snippet text.
///
/// ```dart
/// KnowledgeSourceCard(
///   source: knowledgeSource,
///   onTap: () => openDocument(source.documentId),
/// )
/// ```
class KnowledgeSourceCard extends StatelessWidget {
  const KnowledgeSourceCard({
    super.key,
    required this.source,
    this.onTap,
  });

  final KnowledgeSourceEntity source;
  final VoidCallback? onTap;

  // ─── Document Type Icon ───────────────────────────────────────────────

  IconData _docTypeIcon(String type) {
    return switch (type.toLowerCase()) {
      'policy' => Icons.gavel_outlined,
      'handbook' => Icons.menu_book_outlined,
      'curriculum' => Icons.school_outlined,
      'guideline' => Icons.rule_outlined,
      'report' => Icons.assessment_outlined,
      'form' => Icons.description_outlined,
      'circular' => Icons.campaign_outlined,
      _ => Icons.article_outlined,
    };
  }

  Color _docTypeColor(String type) {
    return switch (type.toLowerCase()) {
      'policy' => AppColors.seed,
      'handbook' => const Color(0xFF7C3AED),
      'curriculum' => const Color(0xFF0891B2),
      'guideline' => const Color(0xFF16A34A),
      'report' => const Color(0xFFEA580C),
      'form' => const Color(0xFFCA8A04),
      'circular' => AppColors.info,
      _ => const Color(0xFF6B7280),
    };
  }

  // ─── Relevance Score Bar ──────────────────────────────────────────────

  Widget _buildRelevanceBar(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final score = source.relevance.clamp(0.0, 1.0);
    final percent = (score * 100).round();

    Color barColor;
    if (score >= 0.8) {
      barColor = AppColors.success;
    } else if (score >= 0.5) {
      barColor = AppColors.warning;
    } else {
      barColor = const Color(0xFF6B7280);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Relevance',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                fontWeight: AppTypography.wMedium,
                color: cs.onSurfaceVariant,
                letterSpacing: AppTypography.lsCaption,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                fontWeight: AppTypography.wSemiBold,
                color: barColor,
                letterSpacing: AppTypography.lsCaption,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(Spacings.fullRadius),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: isDark
                ? cs.surfaceContainerHighest
                : cs.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final docColor = _docTypeColor(source.documentType);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Doc icon + Type badge ────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: docColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Center(
                  child: Icon(
                    _docTypeIcon(source.documentType),
                    size: Spacings.mdIcon - 4,
                    color: docColor,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.documentType.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10,
                        fontWeight: AppTypography.wSemiBold,
                        letterSpacing: 0.5,
                        color: docColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Snippet ───────────────────────────────────────────────
          if (source.snippet != null && source.snippet!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                '"${source.snippet}"',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // ── Relevance Bar ─────────────────────────────────────────
          const SizedBox(height: Spacings.md),
          _buildRelevanceBar(context),
        ],
      ),
    );
  }
}
