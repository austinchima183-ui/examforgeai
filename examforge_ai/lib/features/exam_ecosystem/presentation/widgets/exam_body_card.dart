import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';

/// Card widget showing an examination body with logo, name, and type badge.
///
/// Displays:
/// - Exam body logo (or initials placeholder)
/// - Exam body name
/// - Exam body type badge
/// - Country code indicator
/// - Active/inactive status
///
/// ```dart
/// ExamBodyCard(
///   body: examinationBody,
///   onTap: () => selectBody(body.id),
/// )
/// ```
class ExamBodyCard extends StatelessWidget {
  const ExamBodyCard({
    super.key,
    required this.body,
    this.onTap,
    this.compact = false,
  });

  /// The examination body to display.
  final ExaminationBody body;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to show a compact version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: compact
              ? const EdgeInsets.all(Spacings.sm)
              : Spacings.paddingCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Logo / Initials ──────────────────────────────────
              _buildLogo(context),
              if (!compact) ...[
                const SizedBox(height: Spacings.sm),

                // ─── Name ────────────────────────────────────────────
                Text(
                  body.name,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),

                // ─── Type Badge ──────────────────────────────────────
                _buildTypeBadge(context),
              ] else ...[
                const SizedBox(height: Spacings.xs),
                Text(
                  body.code,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = compact ? 32.0 : 48.0;

    if (body.logoUrl != null && body.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: Spacings.borderRadiusSm,
        child: Image.network(
          body.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsPlaceholder(context, size);
          },
        ),
      );
    }

    return _buildInitialsPlaceholder(context, size);
  }

  Widget _buildInitialsPlaceholder(BuildContext context, double size) {
    final color = _bodyTypeColor(body.examBodyType);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Center(
        child: Text(
          _getInitials(body.name),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: AppTypography.wBold,
            color: color,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    final color = _bodyTypeColor(body.examBodyType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: Spacings.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _bodyTypeIcon(body.examBodyType),
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              body.examBodyType.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: color,
                    fontSize: 9,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Extract initials from a name (e.g., "WAEC" → "WA", "JAMB UTME" → "JU").
  String _getInitials(String name) {
    final words = name.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  /// Get a color for the exam body type.
  Color _bodyTypeColor(ExamBodyType type) {
    switch (type) {
      case ExamBodyType.waec:
        return const Color(0xFF16A34A); // Green
      case ExamBodyType.neco:
        return const Color(0xFF2563EB); // Blue
      case ExamBodyType.nabteb:
        return const Color(0xFFEA580C); // Orange
      case ExamBodyType.jambUme:
        return const Color(0xFF1E40AF); // Dark blue
      case ExamBodyType.postUtme:
        return const Color(0xFF7C3AED); // Purple
      case ExamBodyType.bece:
        return const Color(0xFF0891B2); // Cyan
      case ExamBodyType.commonEntrance:
        return const Color(0xFFDB2777); // Pink
      case ExamBodyType.jupeb:
        return const Color(0xFF059669); // Emerald
      case ExamBodyType.ijmb:
        return const Color(0xFFD97706); // Amber
      case ExamBodyType.custom:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Get an icon for the exam body type.
  IconData _bodyTypeIcon(ExamBodyType type) {
    switch (type) {
      case ExamBodyType.waec:
      case ExamBodyType.neco:
      case ExamBodyType.nabteb:
        return Icons.school_rounded;
      case ExamBodyType.jambUme:
        return Icons.computer_rounded;
      case ExamBodyType.postUtme:
        return Icons.school_rounded;
      case ExamBodyType.bece:
      case ExamBodyType.commonEntrance:
        return Icons.menu_book_rounded;
      case ExamBodyType.jupeb:
      case ExamBodyType.ijmb:
        return Icons.auto_stories_rounded;
      case ExamBodyType.custom:
        return Icons.more_horiz_rounded;
    }
  }
}
