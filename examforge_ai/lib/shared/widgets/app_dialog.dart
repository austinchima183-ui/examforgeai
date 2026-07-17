import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';
import 'app_button.dart';

// ─── AppDialog ────────────────────────────────────────────────────────────────

/// Static utility class for showing Material 3 styled dialogs with consistent
/// theming, responsive sizing, and smooth animations.
///
/// All methods return a `Future<T?>` — typically the result of
/// `showDialog<T>(…)`.
///
/// ```dart
/// final confirmed = await AppDialog.showConfirm(
///   context,
///   title: 'Delete Exam?',
///   message: 'This action cannot be undone.',
///   isDestructive: true,
/// );
/// ```
class AppDialog {
  AppDialog._();

  // ─── Responsive constraints ──────────────────────────────────────────

  /// Returns a [BoxConstraints] appropriate for the current screen size.
  static BoxConstraints _constraintsFor(BuildContext context) {
    if (context.isDesktop) {
      return const BoxConstraints(maxWidth: 480);
    }
    if (context.isTablet) {
      return const BoxConstraints(maxWidth: 420);
    }
    return const BoxConstraints(maxWidth: 360);
  }

  // ─── Confirm ─────────────────────────────────────────────────────────

  /// Shows a confirmation dialog with [title], [message], confirm / cancel
  /// buttons, and an optional destructive action style.
  ///
  /// Returns `true` if the confirm button was pressed, `false` or `null`
  /// otherwise.
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppDialogShell(
        constraints: _constraintsFor(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.md),
            // Message
            Text(
              message,
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.xl),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: cancelText,
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: confirmText,
                  variant: isDestructive
                      ? AppButtonVariant.elevated
                      : AppButtonVariant.tonal,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  // Override colour for destructive action
                  // (handled via custom styling inside button)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info ────────────────────────────────────────────────────────────

  /// Shows an informational dialog with an info icon, [title], [message],
  /// and a single dismiss button.
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String dismissText = 'OK',
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppDialogShell(
        constraints: _constraintsFor(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: Spacings.xlIcon,
              color: AppColors.infoOf(ctx.colorScheme.brightness),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              title,
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              message,
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: dismissText,
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(ctx).pop(),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error ───────────────────────────────────────────────────────────

  /// Shows an error dialog with an error icon, [title], [message], and a
  /// dismiss button.
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String dismissText = 'OK',
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppDialogShell(
        constraints: _constraintsFor(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: Spacings.xlIcon,
              color: AppColors.errorOf(ctx.colorScheme.brightness),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              title,
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              message,
              style: ctx.textTheme.bodyMedium?.copyWith(
                color: ctx.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: dismissText,
                variant: AppButtonVariant.elevated,
                onPressed: () => Navigator.of(ctx).pop(),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading ─────────────────────────────────────────────────────────

  /// Shows a non-dismissible loading dialog with an optional [message].
  ///
  /// Returns a [BuildContext] that should be used to pop the dialog when
  /// loading completes: `Navigator.of(loadingContext).pop()`.
  static Future<BuildContext> showLoading({
    required BuildContext context,
    String? message,
  }) async {
    late BuildContext dialogContext;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return _AppDialogShell(
          constraints: _constraintsFor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: ctx.colorScheme.primary,
                ),
                if (message != null) ...[
                  const SizedBox(height: Spacings.lg),
                  Text(
                    message,
                    style: ctx.textTheme.bodyMedium?.copyWith(
                      color: ctx.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    // Allow a frame for the dialog to render.
    await Future.delayed(const Duration(milliseconds: 50));
    return dialogContext;
  }

  // ─── Success ─────────────────────────────────────────────────────────

  /// Shows a success dialog with a check icon, [title], optional [message],
  /// and an auto-dismiss option.
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? message,
    String dismissText = 'OK',
    bool barrierDismissible = true,
    Duration? autoDismissDuration,
  }) {
    if (autoDismissDuration != null) {
      Future.delayed(autoDismissDuration, () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _AppDialogShell(
        constraints: _constraintsFor(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: Spacings.xlIcon,
              color: AppColors.successOf(ctx.colorScheme.brightness),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              title,
              style: ctx.textTheme.titleLarge?.copyWith(
                color: ctx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Spacings.sm),
              Text(
                message,
                style: ctx.textTheme.bodyMedium?.copyWith(
                  color: ctx.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: Spacings.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: dismissText,
                variant: AppButtonVariant.tonal,
                onPressed: () => Navigator.of(ctx).pop(),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Custom ──────────────────────────────────────────────────────────

  /// Shows a fully custom dialog built by [builder], wrapped in the standard
  /// Material 3 dialog shell with responsive constraints.
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (ctx) => _AppDialogShell(
        constraints: _constraintsFor(context),
        child: builder(ctx),
      ),
    );
  }
}

// ─── Private Dialog Shell ─────────────────────────────────────────────────────

/// Internal wrapper that applies consistent Material 3 dialog styling,
/// responsive constraints, and smooth scale + fade animation.
class _AppDialogShell extends StatelessWidget {
  const _AppDialogShell({
    required this.constraints,
    required this.child,
  });

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: constraints,
        child: Dialog(
          backgroundColor: cs.surface,
          surfaceTintColor: cs.surfaceTint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
