import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION BADGE ICON
// ═══════════════════════════════════════════════════════════════════════

/// Icon with a notification count badge.
///
/// Shows a red circular badge with the count when [count] > 0.
/// When count is 0, no badge is displayed. Supports "99+" for large counts.
///
/// ```dart
/// NotificationBadgeIcon(
///   icon: Icons.notifications_rounded,
///   count: 5,
///   onTap: () => openNotifications(),
/// )
/// ```
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    this.onTap,
    this.iconSize,
    this.iconColor,
  });

  /// The icon to display.
  final IconData icon;

  /// The notification count.
  final int count;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Custom icon size (defaults to Spacings.mdIcon).
  final double? iconSize;

  /// Custom icon color (defaults to colorScheme.onSurfaceVariant).
  final Color? iconColor;

  String get _badgeText => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final effectiveIconSize = iconSize ?? Spacings.mdIcon;
    final effectiveIconColor = iconColor ?? cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: SizedBox(
        width: effectiveIconSize + Spacings.lg,
        height: effectiveIconSize + Spacings.lg,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Icon
            Icon(
              icon,
              size: effectiveIconSize,
              color: effectiveIconColor,
            ),

            // Badge
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? Spacings.xs : 3.0,
                    vertical: 1.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: cs.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 16.0),
                  child: Center(
                    child: Text(
                      _badgeText,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: count > 9 ? 9.0 : 10.0,
                        fontWeight: AppTypography.wBold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
