import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/question_entities.dart';

// ─── Badge Variant ────────────────────────────────────────────────────────────

/// Visual variant for [QuestionTypeBadge].
enum QuestionTypeBadgeVariant {
  /// Shows both icon and label.
  both,

  /// Shows only the icon.
  iconOnly,

  /// Shows only the label text.
  labelOnly,
}

// ─── Badge Size ───────────────────────────────────────────────────────────────

/// Size preset for [QuestionTypeBadge].
enum QuestionTypeBadgeSize {
  /// Compact chip style for list views.
  small,

  /// Standard chip for cards and detail views.
  large,
}

// ─── QuestionTypeBadge ────────────────────────────────────────────────────────

/// Displays a question type as a colored chip/badge with a unique icon and
/// optional label for each [QuestionType].
///
/// ```dart
/// QuestionTypeBadge(type: QuestionType.multipleChoice)
/// QuestionTypeBadge(type: QuestionType.matching, variant: QuestionTypeBadgeVariant.iconOnly)
/// QuestionTypeBadge(type: QuestionType.essay, size: QuestionTypeBadgeSize.large)
/// ```
class QuestionTypeBadge extends StatelessWidget {
  const QuestionTypeBadge({
    super.key,
    required this.type,
    this.variant = QuestionTypeBadgeVariant.both,
    this.size = QuestionTypeBadgeSize.small,
  });

  /// The question type to display.
  final QuestionType type;

  /// What to show: icon, label, or both.
  final QuestionTypeBadgeVariant variant;

  /// Size preset: small or large.
  final QuestionTypeBadgeSize size;

  // ─── Color Mapping ──────────────────────────────────────────────────

  /// Returns a unique color for each question type.
  Color _backgroundColor(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _typeColor();
    return color.withValues(alpha: isDark ? 0.25 : 0.12);
  }

  Color _foregroundColor(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _typeColor();
    return isDark ? color.withValues(alpha: 0.9) : color;
  }

  Color _typeColor() {
    return switch (type) {
      QuestionType.multipleChoice => const Color(0xFF2563EB), // Blue
      QuestionType.multipleResponse => const Color(0xFF7C3AED), // Violet
      QuestionType.trueFalse => const Color(0xFF059669), // Emerald
      QuestionType.fillInBlank => const Color(0xFFD97706), // Amber
      QuestionType.matching => const Color(0xFFDC2626), // Red
      QuestionType.ordering => const Color(0xFF0891B2), // Cyan
      QuestionType.shortAnswer => const Color(0xFF4F46E5), // Indigo
      QuestionType.essay => const Color(0xFF9333EA), // Purple
      QuestionType.numerical => const Color(0xFF0D9488), // Teal
      QuestionType.imageBased => const Color(0xFFE11D48), // Rose
      QuestionType.audioBased => const Color(0xFFCA8A04), // Yellow
      QuestionType.videoBased => const Color(0xFFBE185D), // Pink
      QuestionType.practical => const Color(0xFF65A30D), // Lime
      QuestionType.caseStudy => const Color(0xFF9A3412), // Orange dark
    };
  }

  // ─── Icon Mapping ───────────────────────────────────────────────────

  IconData _typeIcon() {
    return switch (type) {
      QuestionType.multipleChoice => Icons.radio_button_checked_rounded,
      QuestionType.multipleResponse => Icons.check_box_rounded,
      QuestionType.trueFalse => Icons.toggle_on_rounded,
      QuestionType.fillInBlank => Icons.edit_note_rounded,
      QuestionType.matching => Icons.compare_arrows_rounded,
      QuestionType.ordering => Icons.reorder_rounded,
      QuestionType.shortAnswer => Icons.short_text_rounded,
      QuestionType.essay => Icons.article_rounded,
      QuestionType.numerical => Icons.calculate_rounded,
      QuestionType.imageBased => Icons.image_rounded,
      QuestionType.audioBased => Icons.audiotrack_rounded,
      QuestionType.videoBased => Icons.videocam_rounded,
      QuestionType.practical => Icons.science_rounded,
      QuestionType.caseStudy => Icons.folder_special_rounded,
    };
  }

  // ─── Sizing ─────────────────────────────────────────────────────────

  double _iconSize() {
    return size == QuestionTypeBadgeSize.small ? 14.0 : 18.0;
  }

  double _fontSize() {
    return size == QuestionTypeBadgeSize.small ? 11.0 : 13.0;
  }

  EdgeInsetsGeometry _padding() {
    return size == QuestionTypeBadgeSize.small
        ? const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs)
        : const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm);
  }

  double _borderRadius() {
    return size == QuestionTypeBadgeSize.small ? Spacings.smRadius : Spacings.mdRadius;
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor(context);
    final fgColor = _foregroundColor(context);
    final iconData = _typeIcon();
    final label = type.label;

    final List<Widget> children = [];

    if (variant == QuestionTypeBadgeVariant.both ||
        variant == QuestionTypeBadgeVariant.iconOnly) {
      children.add(Icon(iconData, size: _iconSize(), color: fgColor));
    }

    if (variant == QuestionTypeBadgeVariant.both ||
        variant == QuestionTypeBadgeVariant.labelOnly) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: Spacings.xs));
      }
      children.add(
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: _fontSize(),
            fontWeight: AppTypography.wSemiBold,
            letterSpacing: AppTypography.lsLabel,
            height: 1.33,
            color: fgColor,
          ),
        ),
      );
    }

    return Container(
      padding: _padding(),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_borderRadius()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
