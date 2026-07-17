import 'package:flutter/material.dart';

import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';
import 'app_button.dart';

// ─── AppEmptyState ────────────────────────────────────────────────────────────

/// A reusable empty-state widget displaying an icon, title, subtitle, and
/// optional action button. Pre-built variants are provided for common cases.
///
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No Messages',
///   subtitle: 'Your inbox is empty',
///   actionLabel: 'Compose',
///   onAction: () => composeMessage(),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  /// Leading icon displayed above the title.
  final IconData? icon;

  /// Primary title text.
  final String? title;

  /// Secondary subtitle text.
  final String? subtitle;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback for the optional action button.
  final VoidCallback? onAction;

  /// Optional custom illustration widget replacing the default icon.
  final Widget? illustration;

  // ─── Pre-built Variants ─────────────────────────────────────────────

  /// Empty state for when there is no data at all.
  static AppEmptyState noData({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.folder_open_outlined,
      title: title ?? 'No Data',
      subtitle: subtitle ?? 'There is nothing to show right now.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Empty state for search with no results.
  static AppEmptyState noResults({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: title ?? 'No Results',
      subtitle: subtitle ?? 'Try adjusting your search or filters.',
      actionLabel: actionLabel ?? 'Clear Filters',
      onAction: onAction,
    );
  }

  /// Empty state for no notifications.
  static AppEmptyState noNotifications({
    String? title,
    String? subtitle,
  }) {
    return AppEmptyState(
      icon: Icons.notifications_none_rounded,
      title: title ?? 'No Notifications',
      subtitle: subtitle ?? "You're all caught up!",
    );
  }

  /// Empty state for no messages.
  static AppEmptyState noMessages({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: title ?? 'No Messages',
      subtitle: subtitle ?? 'Start a conversation.',
      actionLabel: actionLabel ?? 'New Message',
      onAction: onAction,
    );
  }

  /// Empty state for no internet connection.
  static AppEmptyState noConnection({
    String? title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      title: title ?? 'No Connection',
      subtitle: subtitle ?? 'Check your internet and try again.',
      actionLabel: actionLabel ?? 'Retry',
      onAction: onAction,
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;

    // Responsive icon sizing
    final iconSize = isMobile ? Spacings.xlIcon : 64.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.xl,
        vertical: Spacings.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),

            const SizedBox(height: Spacings.xl),

            // Title
            if (title != null)
              Text(
                title!,
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

            if (subtitle != null) ...[
              const SizedBox(height: Spacings.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Spacings.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
