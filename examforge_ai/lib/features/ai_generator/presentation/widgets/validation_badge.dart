import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/ai_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// VALIDATION BADGE
// ═══════════════════════════════════════════════════════════════════════

/// Badge showing validation results with severity colors, issue count,
/// and an expandable list of validation issues with resolved/unresolved
/// indicators.
///
/// In compact mode, it shows only a summary chip. When expanded, it
/// displays each issue with its severity color and resolution status.
///
/// ```dart
/// ValidationBadge(
///   results: validationResults,
///   isCompact: true,
/// )
/// ```
class ValidationBadge extends StatefulWidget {
  const ValidationBadge({
    super.key,
    required this.results,
    this.isCompact = false,
  });

  /// The list of validation results to display.
  final List<ValidationResultEntity> results;

  /// When `true`, shows only a summary chip. When `false`, shows the
  /// full expandable list.
  final bool isCompact;

  @override
  State<ValidationBadge> createState() => _ValidationBadgeState();
}

class _ValidationBadgeState extends State<ValidationBadge> {
  bool _isExpanded = false;

  // ─── Severity helpers ───────────────────────────────────────────────

  Color _severityColor(ValidationSeverity severity, Brightness brightness) {
    return switch (severity) {
      ValidationSeverity.info => AppColors.infoOf(brightness),
      ValidationSeverity.warning => AppColors.warningOf(brightness),
      ValidationSeverity.error => AppColors.errorOf(brightness),
      ValidationSeverity.critical => const Color(0xFFDC2626),
    };
  }

  IconData _severityIcon(ValidationSeverity severity) {
    return switch (severity) {
      ValidationSeverity.info => Icons.info_outline_rounded,
      ValidationSeverity.warning => Icons.warning_amber_rounded,
      ValidationSeverity.error => Icons.error_outline_rounded,
      ValidationSeverity.critical => Icons.dangerous_outlined,
    };
  }

  String _severityLabel(ValidationSeverity severity) {
    return severity.label;
  }

  int get _issueCount => widget.results.length;

  int get _unresolvedCount =>
      widget.results.where((r) => !r.isResolved).length;

  int get _resolvedCount => widget.results.where((r) => r.isResolved).length;

  bool get _hasCritical =>
      widget.results.any((r) => r.severity == ValidationSeverity.critical);

  bool get _hasError =>
      widget.results.any((r) => r.severity == ValidationSeverity.error);

  /// The dominant severity used for the badge color in compact mode.
  ValidationSeverity get _dominantSeverity {
    if (widget.results.any((r) => r.severity == ValidationSeverity.critical)) {
      return ValidationSeverity.critical;
    }
    if (widget.results.any((r) => r.severity == ValidationSeverity.error)) {
      return ValidationSeverity.error;
    }
    if (widget.results.any((r) => r.severity == ValidationSeverity.warning)) {
      return ValidationSeverity.warning;
    }
    return ValidationSeverity.info;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) return const SizedBox.shrink();

    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final dominantColor = _severityColor(_dominantSeverity, cs.brightness);

    // ── Compact mode: single chip ───────────────────────────────────
    if (widget.isCompact) {
      return InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: dominantColor.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _severityIcon(_dominantSeverity),
                size: Spacings.smIcon,
                color: dominantColor,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '$_issueCount issue${_issueCount != 1 ? 's' : ''}',
                style: tt.labelSmall?.copyWith(
                  color: dominantColor,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              if (_unresolvedCount > 0) ...[
                const SizedBox(width: Spacings.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorOf(cs.brightness).withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.xs),
                  ),
                  child: Text(
                    '$_unresolvedCount unresolved',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.errorOf(cs.brightness),
                      fontWeight: AppTypography.wSemiBold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: Spacings.xs),
              Icon(
                _isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: Spacings.smIcon,
                color: dominantColor,
              ),
            ],
          ),
        ),
      );
    }

    // ── Full mode: expandable list ──────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Icon(
                _hasCritical || _hasError
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                size: Spacings.mdIcon,
                color: dominantColor,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Validation Results',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: dominantColor.withValues(
                    alpha: isDark ? 0.20 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '$_issueCount',
                  style: tt.labelSmall?.copyWith(
                    color: dominantColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              if (_resolvedCount > 0) ...[
                const SizedBox(width: Spacings.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successOf(cs.brightness).withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: Spacings.smIcon,
                        color: AppColors.successOf(cs.brightness),
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '$_resolvedCount resolved',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.successOf(cs.brightness),
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                _isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),

        // Expandable issues list
        if (_isExpanded) ...[
          const SizedBox(height: Spacings.sm),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Column(
              children: widget.results.map((result) {
                final severityColor = _severityColor(
                  result.severity,
                  cs.brightness,
                );
                return Container(
                  padding: const EdgeInsets.all(Spacings.md),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity icon
                      Container(
                        padding: const EdgeInsets.all(Spacings.xs),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            Spacings.xs,
                          ),
                        ),
                        child: Icon(
                          _severityIcon(result.severity),
                          size: Spacings.smIcon,
                          color: severityColor,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),

                      // Issue details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacings.xs,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor.withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Spacings.xs,
                                    ),
                                  ),
                                  child: Text(
                                    _severityLabel(result.severity),
                                    style: tt.labelSmall?.copyWith(
                                      color: severityColor,
                                      fontWeight: AppTypography.wSemiBold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacings.sm),
                                Text(
                                  result.validationType,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacings.xs),
                            Text(
                              result.message,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                            if (result.suggestion != null) ...[
                              const SizedBox(height: Spacings.xs),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: Spacings.smIcon,
                                    color: AppColors.warningOf(
                                      cs.brightness,
                                    ),
                                  ),
                                  const SizedBox(width: Spacings.xs),
                                  Expanded(
                                    child: Text(
                                      result.suggestion!,
                                      style: tt.bodySmall?.copyWith(
                                        color: AppColors.warningOf(
                                          cs.brightness,
                                        ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Resolved indicator
                      if (result.isResolved)
                        Icon(
                          Icons.check_circle_rounded,
                          size: Spacings.mdIcon,
                          color: AppColors.successOf(cs.brightness),
                        )
                      else
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: Spacings.mdIcon,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
