import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

/// Password strength level enumeration.
enum PasswordStrengthLevel {
  /// No password entered.
  none,

  /// Fails most criteria — very weak.
  weak,

  /// Meets some criteria.
  fair,

  /// Meets most criteria.
  good,

  /// Meets all criteria — strong password.
  strong,
}

/// Visual password strength indicator with animated bar and criteria list.
///
/// Displays:
/// - A segmented bar showing the current strength level
/// - Color-coded segments (red, orange, yellow, green)
/// - A list of criteria with check/cross icons
/// - Animated transitions between strength levels
///
/// ```dart
/// PasswordStrengthIndicator(password: myController.text)
/// ```
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showCriteria = true,
  });

  /// The password string to evaluate.
  final String password;

  /// Whether to show the detailed criteria list below the bar.
  final bool showCriteria;

  // ─── Strength Computation ─────────────────────────────────────────

  /// Computes the current password strength level.
  PasswordStrengthLevel _computeStrength() {
    if (password.isEmpty) return PasswordStrengthLevel.none;

    int score = 0;

    // Length checks
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;

    // Map score to strength level
    if (score <= 2) return PasswordStrengthLevel.weak;
    if (score <= 3) return PasswordStrengthLevel.fair;
    if (score <= 5) return PasswordStrengthLevel.good;
    return PasswordStrengthLevel.strong;
  }

  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get _hasDigit => RegExp(r'\d').hasMatch(password);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password);
  bool get _hasMinLength => password.length >= 8;

  // ─── Color Mapping ────────────────────────────────────────────────

  Color _strengthColor(PasswordStrengthLevel level) {
    return switch (level) {
      PasswordStrengthLevel.none => Colors.grey.shade300,
      PasswordStrengthLevel.weak => AppColors.error,
      PasswordStrengthLevel.fair => AppColors.warning,
      PasswordStrengthLevel.good => const Color(0xFFEAB308),
      PasswordStrengthLevel.strong => AppColors.success,
    };
  }

  String _strengthLabel(PasswordStrengthLevel level) {
    return switch (level) {
      PasswordStrengthLevel.none => '',
      PasswordStrengthLevel.weak => 'Weak',
      PasswordStrengthLevel.fair => 'Fair',
      PasswordStrengthLevel.good => 'Good',
      PasswordStrengthLevel.strong => 'Strong',
    };
  }

  int _strengthSegments(PasswordStrengthLevel level) {
    return switch (level) {
      PasswordStrengthLevel.none => 0,
      PasswordStrengthLevel.weak => 1,
      PasswordStrengthLevel.fair => 2,
      PasswordStrengthLevel.good => 3,
      PasswordStrengthLevel.strong => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strength = _computeStrength();
    final activeColor = _strengthColor(strength);
    final label = _strengthLabel(strength);
    final filledSegments = _strengthSegments(strength);
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Strength Bar ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StrengthBar(
                filledSegments: filledSegments,
                activeColor: activeColor,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: Spacings.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: tt.labelSmall?.copyWith(
                    color: activeColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),

        // ── Criteria List ──────────────────────────────────────────
        if (showCriteria && password.isNotEmpty) ...[
          const SizedBox(height: Spacings.sm),
          _CriteriaList(
            hasMinLength: _hasMinLength,
            hasUppercase: _hasUppercase,
            hasLowercase: _hasLowercase,
            hasDigit: _hasDigit,
            hasSpecialChar: _hasSpecialChar,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STRENGTH BAR WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// A segmented bar that fills up based on password strength.
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.filledSegments,
    required this.activeColor,
  });

  final int filledSegments;
  final Color activeColor;

  static const int _totalSegments = 4;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Row(
      children: List.generate(_totalSegments, (index) {
        final isFilled = index < filledSegments;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(
              right: index < _totalSegments - 1 ? 4 : 0,
            ),
            height: 4,
            decoration: BoxDecoration(
              color: isFilled ? activeColor : cs.outlineVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CRITERIA LIST WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// A list of password criteria with visual check/cross indicators.
class _CriteriaList extends StatelessWidget {
  const _CriteriaList({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Wrap(
      spacing: Spacings.md,
      runSpacing: Spacings.xs,
      children: [
        _CriteriaChip(
          label: '8+ characters',
          isMet: hasMinLength,
          textStyle: tt,
          colorScheme: cs,
        ),
        _CriteriaChip(
          label: 'Uppercase',
          isMet: hasUppercase,
          textStyle: tt,
          colorScheme: cs,
        ),
        _CriteriaChip(
          label: 'Lowercase',
          isMet: hasLowercase,
          textStyle: tt,
          colorScheme: cs,
        ),
        _CriteriaChip(
          label: 'Number',
          isMet: hasDigit,
          textStyle: tt,
          colorScheme: cs,
        ),
        _CriteriaChip(
          label: 'Special char',
          isMet: hasSpecialChar,
          textStyle: tt,
          colorScheme: cs,
        ),
      ],
    );
  }
}

/// A single criteria indicator chip with a checkmark or cross icon.
class _CriteriaChip extends StatelessWidget {
  const _CriteriaChip({
    required this.label,
    required this.isMet,
    required this.textStyle,
    required this.colorScheme,
  });

  final String label;
  final bool isMet;
  final TextTheme textStyle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = isMet ? AppColors.success : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.successLight.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(
          color: isMet
              ? AppColors.success.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isMet ? Icons.check_circle_rounded : Icons.cancel_outlined,
              key: ValueKey(isMet),
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textStyle.labelSmall?.copyWith(
              color: color,
              fontWeight: isMet ? AppTypography.wSemiBold : AppTypography.wRegular,
            ),
          ),
        ],
      ),
    );
  }
}
