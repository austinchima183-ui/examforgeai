import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ─── OnlineStatusIndicator ────────────────────────────────────────────────────

/// A small dot indicator showing online/offline status.
/// Green for online, grey for offline.
///
/// ```dart
/// OnlineStatusIndicator(isOnline: true, size: 12)
/// ```
class OnlineStatusIndicator extends StatelessWidget {
  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 10,
  });

  /// Whether the user is online.
  final bool isOnline;

  /// Diameter of the dot in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final dotColor = isOnline
        ? AppColors.success
        : isDark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF);

    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: size > 8 ? 2.0 : 1.5,
        ),
      ),
    );
  }
}
