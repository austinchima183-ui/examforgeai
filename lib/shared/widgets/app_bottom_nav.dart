import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';

// ─── AppBottomNavItem ─────────────────────────────────────────────────────────

/// Model class representing a single item in the bottom navigation bar.
///
/// ```dart
/// AppBottomNavItem(
///   icon: Icons.home_outlined,
///   selectedIcon: Icons.home,
///   label: 'Home',
///   badgeCount: 3,
/// )
/// ```
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badgeCount,
    this.showBadge = false,
    this.tooltip,
  });

  /// Icon shown when the item is not selected.
  final IconData icon;

  /// Icon shown when the item is selected. Falls back to [icon].
  final IconData? selectedIcon;

  /// Text label displayed below the icon.
  final String label;

  /// Optional numeric badge count. Shown only when > 0.
  final int? badgeCount;

  /// When `true`, shows a small dot badge regardless of [badgeCount].
  final bool showBadge;

  /// Optional tooltip shown on long press.
  final String? tooltip;
}

// ─── AppBottomNavBar ──────────────────────────────────────────────────────────

/// A Material 3 [NavigationBar] wrapper with badge support, animated
/// transitions, and theme-aware styling.
///
/// ```dart
/// AppBottomNavBar(
///   items: [
///     AppBottomNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
///     AppBottomNavItem(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
///     AppBottomNavItem(icon: Icons.person_outlined, selectedIcon: Icons.person, label: 'Profile'),
///   ],
///   currentIndex: 0,
///   onTap: (i) => setState(() => _currentIndex = i),
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height,
    this.backgroundColor,
    this.elevation,
  });

  /// Navigation items to display.
  final List<AppBottomNavItem> items;

  /// Index of the currently selected item.
  final int currentIndex;

  /// Callback when an item is tapped.
  final ValueChanged<int> onTap;

  /// Optional height override. Defaults to 80 (theme default).
  final double? height;

  /// Background colour override.
  final Color? backgroundColor;

  /// Elevation override.
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: height ?? 80,
      elevation: elevation ?? 0,
      backgroundColor: backgroundColor ?? cs.surface,
      surfaceTintColor: cs.surfaceTint,
      indicatorColor: cs.primaryContainer,
      animationDuration: const Duration(milliseconds: 300),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = index == currentIndex;

        return NavigationDestination(
          icon: _NavItemIcon(
            item: item,
            isSelected: isSelected,
          ),
          selectedIcon: _NavItemIcon(
            item: item,
            isSelected: true,
          ),
          label: item.label,
          tooltip: item.tooltip,
        );
      }).toList(),
    );
  }
}

// ─── Private: Nav Item Icon with Badge ────────────────────────────────────────

class _NavItemIcon extends StatelessWidget {
  const _NavItemIcon({
    required this.item,
    required this.isSelected,
  });

  final AppBottomNavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final iconData = isSelected
        ? (item.selectedIcon ?? item.icon)
        : item.icon;
    final iconColor = isSelected
        ? cs.onSecondaryContainer
        : cs.onSurfaceVariant;

    final showBadge = item.showBadge || (item.badgeCount != null && item.badgeCount! > 0);

    if (showBadge) {
      return Badge(
        isLabelVisible: true,
        label: item.badgeCount != null && item.badgeCount! > 0
            ? Text(
                item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: AppTypography.wSemiBold,
                  color: AppColors.onErrorOf(cs.brightness),
                ),
              )
            : null,
        backgroundColor: AppColors.errorOf(cs.brightness),
        child: Icon(iconData, color: iconColor, size: Spacings.mdIcon),
      );
    }

    return Icon(iconData, color: iconColor, size: Spacings.mdIcon);
  }
}
