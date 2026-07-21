import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Visual variant for [AppButton].
enum AppButtonVariant {
  /// Filled / elevated button with a solid background.
  elevated,

  /// Outlined button with a border and no fill.
  outlined,

  /// Text-only button with no background or border.
  text,

  /// Tonal / filled-tonal button (secondary container background).
  tonal,
}

/// Size preset for [AppButton].
enum AppButtonSize {
  /// Compact button with smaller padding and text.
  small,

  /// Default button size.
  medium,

  /// Large button with extra padding.
  large,
}

/// Visual variant for [AppIconButton].
enum AppIconButtonVariant {
  /// Standard filled icon button.
  filled,

  /// Tonal filled icon button.
  tonal,

  /// Outlined icon button.
  outlined,

  /// Standard (no background) icon button.
  standard,
}

// ─── AppButton ────────────────────────────────────────────────────────────────

/// A comprehensive, theme-aware button widget supporting multiple variants,
/// sizes, loading state, icon positioning, and full-width layout.
///
/// ```dart
/// AppButton(
///   label: 'Submit',
///   onPressed: () => handleSubmit(),
///   variant: AppButtonVariant.elevated,
///   icon: Icons.send,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.elevated,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
    this.semanticLabel,
    this.isDestructive = false,
  });

  /// The text displayed inside the button.
  final String label;

  /// Callback invoked when the button is pressed.
  ///
  /// Ignored when [isLoading] or [isDisabled] is `true`.
  final VoidCallback? onPressed;

  /// Visual style variant of the button.
  final AppButtonVariant variant;

  /// Size preset controlling padding, text style, and minimum dimensions.
  final AppButtonSize size;

  /// Optional icon displayed alongside [label].
  final IconData? icon;

  /// Position of the icon relative to the label.
  final IconAlignment iconAlignment;

  /// When `true`, shows a loading spinner and disables interaction.
  final bool isLoading;

  /// When `true`, the button is non-interactive and visually dimmed.
  final bool isDisabled;

  /// When `true`, the button expands to fill available horizontal space.
  final bool fullWidth;

  /// Optional semantic label for accessibility. If null, [label] is used.
  final String? semanticLabel;

  /// When `true`, indicates this button performs a destructive action.
  /// Affects semantics and may affect visual styling (e.g., red color for destructive actions).
  final bool isDestructive;

  // ─── Helpers ──────────────────────────────────────────────────────────

  bool get _effectiveDisabled => isDisabled || isLoading;

  EdgeInsetsGeometry _paddingForSize(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.sm);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: Spacings.xl, vertical: Spacings.md);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: Spacings.xl, vertical: Spacings.lg);
    }
  }

  TextStyle _textStyleForSize(AppButtonSize s, ColorScheme cs) {
    final base = switch (variant) {
      AppButtonVariant.elevated => AppTypography.button.copyWith(color: cs.onPrimary),
      AppButtonVariant.outlined => AppTypography.button.copyWith(color: cs.primary),
      AppButtonVariant.text => AppTypography.button.copyWith(color: cs.primary),
      AppButtonVariant.tonal => AppTypography.button.copyWith(color: cs.onSecondaryContainer),
    };
    switch (s) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall.copyWith(color: base.color);
      case AppButtonSize.medium:
        return base;
      case AppButtonSize.large:
        return base.copyWith(fontSize: 16);
    }
  }

  double _iconSizeForSize(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return Spacings.smIcon;
      case AppButtonSize.medium:
        return Spacings.mdIcon;
      case AppButtonSize.large:
        return Spacings.lgIcon;
    }
  }

  Size _minimumSizeForSize(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return const Size(48, 36);
      case AppButtonSize.medium:
        return const Size(64, 48);
      case AppButtonSize.large:
        return const Size(64, 56);
    }
  }

  double _loadingIndicatorSize(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return 14.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 22.0;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final effectiveOnPressed = _effectiveDisabled ? null : onPressed;

    // Loading indicator widget
    Widget? loadingWidget;
    if (isLoading) {
      final indicatorColor = switch (variant) {
        AppButtonVariant.elevated => cs.onPrimary,
        AppButtonVariant.outlined => cs.primary,
        AppButtonVariant.text => cs.primary,
        AppButtonVariant.tonal => cs.onSecondaryContainer,
      };
      loadingWidget = SizedBox(
        width: _loadingIndicatorSize(size),
        height: _loadingIndicatorSize(size),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: indicatorColor,
        ),
      );
    }

    // Icon widget (or loading replaces icon area when loading)
    Widget? iconWidget;
    if (isLoading && icon != null) {
      iconWidget = loadingWidget;
    } else if (isLoading) {
      iconWidget = loadingWidget;
    } else if (icon != null) {
      iconWidget = Icon(icon, size: _iconSizeForSize(size));
    }

    // Label with optional loading indicator beside it
    Widget labelWidget;
    if (isLoading && icon == null) {
      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loadingWidget != null) ...[
            loadingWidget,
            const SizedBox(width: Spacings.sm),
          ],
          Text(label, style: _textStyleForSize(size, cs)),
        ],
      );
    } else {
      labelWidget = Text(label, style: _textStyleForSize(size, cs));
    }

    // Common shape
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
    );

    // Build button by variant
    final button = switch (variant) {
      AppButtonVariant.elevated => SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              elevation: 0,
              padding: _paddingForSize(size),
              minimumSize: _minimumSizeForSize(size),
              shape: shape,
              textStyle: _textStyleForSize(size, cs),
            ),
            child: _buildButtonChild(iconWidget, labelWidget),
          ),
        ),
      AppButtonVariant.outlined =>
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              padding: _paddingForSize(size),
              minimumSize: _minimumSizeForSize(size),
              shape: shape,
              side: BorderSide(
                color: _effectiveDisabled
                    ? cs.onSurface.withValues(alpha: 0.12)
                    : cs.outline,
              ),
              textStyle: _textStyleForSize(size, cs),
            ),
            child: iconWidget != null
                ? Row(
                    mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: iconAlignment == IconAlignment.start
                        ? [iconWidget, const SizedBox(width: Spacings.sm), Flexible(child: labelWidget)]
                        : [Flexible(child: labelWidget), const SizedBox(width: Spacings.sm), iconWidget],
                  )
                : labelWidget,
          ),
        );

      case AppButtonVariant.text:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              padding: _paddingForSize(size),
              minimumSize: _minimumSizeForSize(size),
              shape: shape,
              textStyle: _textStyleForSize(size, cs),
            ),
            child: iconWidget != null
                ? Row(
                    mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: iconAlignment == IconAlignment.start
                        ? [iconWidget, const SizedBox(width: Spacings.sm), Flexible(child: labelWidget)]
                        : [Flexible(child: labelWidget), const SizedBox(width: Spacings.sm), iconWidget],
                  )
                : labelWidget,
          ),
        );

      case AppButtonVariant.tonal:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
              disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              elevation: 0,
              padding: _paddingForSize(size),
              minimumSize: _minimumSizeForSize(size),
              shape: shape,
              textStyle: _textStyleForSize(size, cs),
            ),
            child: iconWidget != null
                ? Row(
                    mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: iconAlignment == IconAlignment.start
                        ? [iconWidget, const SizedBox(width: Spacings.sm), Flexible(child: labelWidget)]
                        : [Flexible(child: labelWidget), const SizedBox(width: Spacings.sm), iconWidget],
                  )
                : labelWidget,
          ),
        );
    }
  }
}

// ─── AppIconButton ────────────────────────────────────────────────────────────

/// A theme-aware icon button supporting filled, tonal, outlined, and standard
/// variants with optional tooltip.
///
/// ```dart
/// AppIconButton(
///   icon: Icons.delete,
///   onPressed: () => deleteItem(),
///   variant: AppIconButtonVariant.tonal,
///   tooltip: 'Delete',
/// )
/// ```
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.size = AppButtonSize.medium,
    this.tooltip,
    this.isDisabled = false,
    this.isLoading = false,
    this.color,
  });

  /// The icon to display.
  final IconData icon;

  /// Callback invoked on press.
  final VoidCallback? onPressed;

  /// Visual variant.
  final AppIconButtonVariant variant;

  /// Size preset controlling icon size and tap target.
  final AppButtonSize size;

  /// Optional tooltip displayed on long-press.
  final String? tooltip;

  /// When `true`, the button is non-interactive.
  final bool isDisabled;

  /// When `true`, replaces icon with a loading spinner.
  final bool isLoading;

  /// Optional override for the icon colour.
  final Color? color;

  bool get _effectiveDisabled => isDisabled || isLoading;

  double _iconSize() {
    switch (size) {
      case AppButtonSize.small:
        return Spacings.smIcon;
      case AppButtonSize.medium:
        return Spacings.mdIcon;
      case AppButtonSize.large:
        return Spacings.lgIcon;
    }
  }

  double _buttonSize() {
    switch (size) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return 48.0;
      case AppButtonSize.large:
        return 56.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final effectiveOnPressed = _effectiveDisabled ? null : onPressed;
    final iconColor = color ??
        switch (variant) {
          AppIconButtonVariant.filled => cs.onPrimary,
          AppIconButtonVariant.tonal => cs.onSecondaryContainer,
          AppIconButtonVariant.outlined => cs.primary,
          AppIconButtonVariant.standard => cs.onSurfaceVariant,
        };

    final child = isLoading
        ? SizedBox(
            width: _iconSize(),
            height: _iconSize(),
            child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
          )
        : Icon(icon, size: _iconSize(), color: iconColor);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
    );

    Widget button;
    switch (variant) {
      case AppIconButtonVariant.filled:
        button = SizedBox(
          width: _buttonSize(),
          height: _buttonSize(),
          child: IconButton(
            onPressed: effectiveOnPressed,
            style: IconButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              shape: shape,
              iconSize: _iconSize(),
            ),
            icon: child,
          ),
        );
        break;
      case AppIconButtonVariant.tonal:
        button = SizedBox(
          width: _buttonSize(),
          height: _buttonSize(),
          child: IconButton(
            onPressed: effectiveOnPressed,
            style: IconButton.styleFrom(
              backgroundColor: cs.secondaryContainer,
              foregroundColor: cs.onSecondaryContainer,
              disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              shape: shape,
              iconSize: _iconSize(),
            ),
            icon: child,
          ),
        );
        break;
      case AppIconButtonVariant.outlined:
        button = SizedBox(
          width: _buttonSize(),
          height: _buttonSize(),
          child: IconButton(
            onPressed: effectiveOnPressed,
            style: IconButton.styleFrom(
              foregroundColor: cs.primary,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              side: BorderSide(
                color: _effectiveDisabled
                    ? cs.onSurface.withValues(alpha: 0.12)
                    : cs.outline,
              ),
              shape: shape,
              iconSize: _iconSize(),
            ),
            icon: child,
          ),
        );
        break;
      case AppIconButtonVariant.standard:
        button = SizedBox(
          width: _buttonSize(),
          height: _buttonSize(),
          child: IconButton(
            onPressed: effectiveOnPressed,
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
              shape: shape,
              iconSize: _iconSize(),
            ),
            icon: child,
          ),
        );
        break;
    }

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    return button;
  }
}

// ─── AppFloatingActionButton ──────────────────────────────────────────────────

/// A Material 3 floating action button with optional extended label,
/// mini mode, and loading state.
///
/// ```dart
/// AppFloatingActionButton(
///   label: 'Add Exam',
///   icon: Icons.add,
///   onPressed: () => createExam(),
///   extended: true,
/// )
/// ```
class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    this.label,
    required this.icon,
    required this.onPressed,
    this.extended = false,
    this.mini = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  /// Optional label text shown when [extended] is `true`.
  final String? label;

  /// The icon displayed inside the FAB.
  final IconData icon;

  /// Callback invoked on press.
  final VoidCallback? onPressed;

  /// When `true`, the FAB shows the [label] beside the icon.
  final bool extended;

  /// When `true`, uses a small FAB size.
  final bool mini;

  /// When `true`, shows a loading spinner.
  final bool isLoading;

  /// When `true`, the FAB is non-interactive.
  final bool isDisabled;

  bool get _effectiveDisabled => isDisabled || isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final effectiveOnPressed = _effectiveDisabled ? null : onPressed;

    final iconWidget = isLoading
        ? SizedBox(
            width: mini ? 18.0 : Spacings.mdIcon,
            height: mini ? 18.0 : Spacings.mdIcon,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onPrimaryContainer,
            ),
          )
        : Icon(icon);

    if (extended && label != null && !isLoading) {
      return FloatingActionButton.extended(
        onPressed: effectiveOnPressed,
        icon: iconWidget,
        label: Text(
          label!,
          style: AppTypography.button.copyWith(color: cs.onPrimaryContainer),
        ),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: effectiveOnPressed,
      mini: mini,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
      ),
      child: iconWidget,
    );
  }
}
