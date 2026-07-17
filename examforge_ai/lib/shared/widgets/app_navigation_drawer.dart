import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';

// ─── AppDrawerItem ────────────────────────────────────────────────────────────

/// Model class representing a single item in the navigation drawer.
///
/// ```dart
/// AppDrawerItem(
///   title: 'Dashboard',
///   icon: Icons.dashboard_outlined,
///   route: '/dashboard',
///   roles: {'student', 'teacher', 'admin'},
/// )
/// ```
class AppDrawerItem {
  const AppDrawerItem({
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
    this.selectedIcon,
    this.badge,
    this.roles = const {},
    this.isDivider = false,
    this.isHeader = false,
    this.children = const [],
  });

  /// Display title.
  final String title;

  /// Leading icon.
  final IconData icon;

  /// Navigation route (used for current-route highlighting).
  final String? route;

  /// Optional tap handler. Overrides route navigation when provided.
  final VoidCallback? onTap;

  /// Icon shown when the item is selected. Falls back to [icon].
  final IconData? selectedIcon;

  /// Optional badge count displayed on the item.
  final int? badge;

  /// Set of user roles that can see this item. Empty = visible to all.
  final Set<String> roles;

  /// When `true`, this item is rendered as a [Divider] instead.
  final bool isDivider;

  /// When `true`, this item is rendered as a group header label.
  final bool isHeader;

  /// Sub-items for expandable groups.
  final List<AppDrawerItem> children;

  /// Convenience factory for a divider item.
  static AppDrawerItem divider() =>
      const AppDrawerItem(title: '', icon: Icons.circle, isDivider: true);

  /// Convenience factory for a section header.
  static AppDrawerItem header(String title) =>
      AppDrawerItem(title: title, icon: Icons.circle, isHeader: true);
}

// ─── AppDrawerUserInfo ────────────────────────────────────────────────────────

/// Data model for the user info displayed at the top of the drawer.
class AppDrawerUserInfo {
  const AppDrawerUserInfo({
    this.name,
    this.email,
    this.avatarUrl,
    this.role,
    this.avatarInitials,
  });

  /// Display name.
  final String? name;

  /// Email address.
  final String? email;

  /// URL for the avatar image.
  final String? avatarUrl;

  /// Display role label.
  final String? role;

  /// Fallback initials shown when [avatarUrl] is not provided.
  final String? avatarInitials;
}

// ─── AppNavigationDrawer ──────────────────────────────────────────────────────

/// A fully-featured Material 3 navigation drawer with:
/// - User info header
/// - Grouped menu items with role-based visibility
/// - Current route highlighting
/// - Badge support
/// - Footer with logout
/// - Responsive: drawer on mobile, rail on tablet, sidebar on desktop
///
/// ```dart
/// AppNavigationDrawer(
///   userInfo: AppDrawerUserInfo(name: 'John', email: 'john@school.com'),
///   items: [
///     AppDrawerItem(title: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
///     AppDrawerItem.header('Exams'),
///     AppDrawerItem(title: 'My Exams', icon: Icons.quiz, route: '/exams', roles: {'teacher'}),
///   ],
///   currentRoute: '/dashboard',
///   userRole: 'teacher',
///   onLogout: () => authService.signOut(),
/// )
/// ```
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    this.userInfo,
    required this.items,
    this.currentRoute,
    this.userRole,
    this.onLogout,
    this.onItemTap,
    this.footer,
    this.selectedIndex,
  });

  /// User information displayed in the drawer header.
  final AppDrawerUserInfo? userInfo;

  /// List of drawer items (including dividers and headers).
  final List<AppDrawerItem> items;

  /// The current navigation route for highlighting.
  final String? currentRoute;

  /// The current user's role for filtering items.
  final String? userRole;

  /// Logout callback.
  final VoidCallback? onLogout;

  /// Optional override for item tap handling.
  final ValueChanged<AppDrawerItem>? onItemTap;

  /// Optional footer widget.
  final Widget? footer;

  /// Optional explicit selected index override.
  final int? selectedIndex;

  // ─── Responsive Helper ──────────────────────────────────────────────

  /// Returns the appropriate navigation widget based on screen size:
  /// - Mobile  → [NavigationDrawer]
  /// - Tablet  → [NavigationRail]
  /// - Desktop → permanent sidebar
  static Widget responsive({
    required List<AppDrawerItem> items,
    AppDrawerUserInfo? userInfo,
    String? currentRoute,
    String? userRole,
    VoidCallback? onLogout,
    ValueChanged<AppDrawerItem>? onItemTap,
    int? selectedIndex,
  }) {
    return LayoutBuilder(
      builder: (context, _) {
        if (context.isDesktop) {
          return _DesktopSidebar(
            userInfo: userInfo,
            items: items,
            currentRoute: currentRoute,
            userRole: userRole,
            onLogout: onLogout,
            onItemTap: onItemTap,
            selectedIndex: selectedIndex,
          );
        }
        if (context.isTablet) {
          return _TabletRail(
            items: items,
            currentRoute: currentRoute,
            userRole: userRole,
            onItemTap: onItemTap,
            selectedIndex: selectedIndex,
          );
        }
        return AppNavigationDrawer(
          userInfo: userInfo,
          items: items,
          currentRoute: currentRoute,
          userRole: userRole,
          onLogout: onLogout,
          onItemTap: onItemTap,
          selectedIndex: selectedIndex,
        );
      },
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final visibleItems = _filterItems(items, userRole);

    return NavigationDrawer(
      selectedIndex: selectedIndex ?? _computeSelectedIndex(visibleItems),
      onDestinationSelected: (index) {
        final actionableItems = visibleItems
            .where((i) => !i.isDivider && !i.isHeader)
            .toList();
        if (index < actionableItems.length) {
          final item = actionableItems[index];
          if (item.onTap != null) {
            item.onTap!();
          } else {
            onItemTap?.call(item);
          }
        }
      },
      backgroundColor: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      indicatorColor: cs.primaryContainer,
      children: [
        // ── User Info Header ─────────────────────────────────────────
        if (userInfo != null) _buildUserHeader(context, userInfo!),

        const SizedBox(height: Spacings.sm),

        // ── Menu Items ───────────────────────────────────────────────
        for (final item in visibleItems) ...[
          if (item.isDivider)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Spacings.xl,
                vertical: Spacings.sm,
              ),
              child: Divider(),
            )
          else if (item.isHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.xl,
                Spacings.lg,
                Spacings.xl,
                Spacings.sm,
              ),
              child: Text(
                item.title.toUpperCase(),
                style: AppTypography.overline.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            _buildDrawerDestination(context, item),
        ],

        // ── Footer ──────────────────────────────────────────────────
        if (footer != null) ...[
          const Divider(),
          footer!,
        ],

        if (onLogout != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.sm,
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: AppColors.errorOf(cs.brightness),
                size: Spacings.mdIcon,
              ),
              title: Text(
                'Log Out',
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: Spacings.lg),
        ],
      ],
    );
  }

  // ─── Private Helpers ─────────────────────────────────────────────────

  List<AppDrawerItem> _filterItems(List<AppDrawerItem> items, String? role) {
    return items.where((item) {
      if (item.isDivider || item.isHeader) return true;
      if (item.roles.isEmpty) return true;
      if (role == null) return false;
      return item.roles.contains(role);
    }).toList();
  }

  int _computeSelectedIndex(List<AppDrawerItem> visibleItems) {
    if (currentRoute == null) return -1;
    final actionable = visibleItems
        .where((i) => !i.isDivider && !i.isHeader)
        .toList();
    for (int i = 0; i < actionable.length; i++) {
      if (actionable[i].route == currentRoute) return i;
    }
    return -1;
  }

  NavigationDrawerDestination _buildDrawerDestination(
    BuildContext context,
    AppDrawerItem item,
  ) {
    final isSelected = item.route == currentRoute;
    final cs = context.colorScheme;

    return NavigationDrawerDestination(
      icon: Badge(
        isLabelVisible: item.badge != null && item.badge! > 0,
        label: Text('${item.badge ?? 0}'),
        backgroundColor: AppColors.errorOf(cs.brightness),
        child: Icon(item.icon),
      ),
      selectedIcon: Icon(item.selectedIcon ?? item.icon),
      label: Text(item.title),
    );
  }

  Widget _buildUserHeader(BuildContext context, AppDrawerUserInfo info) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.xxl,
        Spacings.lg,
        Spacings.lg,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            backgroundImage:
                info.avatarUrl != null ? NetworkImage(info.avatarUrl!) : null,
            child: info.avatarUrl == null
                ? Text(
                    info.avatarInitials ??
                        (info.name != null
                            ? _getInitials(info.name!)
                            : '?'),
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (info.name != null)
                  Text(
                    info.name!,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (info.email != null)
                  Text(
                    info.email!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (info.role != null)
                  Container(
                    margin: const EdgeInsets.only(top: Spacings.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      info.role!,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Tablet Rail ──────────────────────────────────────────────────────────────

class _TabletRail extends StatelessWidget {
  const _TabletRail({
    required this.items,
    this.currentRoute,
    this.userRole,
    this.onItemTap,
    this.selectedIndex,
  });

  final List<AppDrawerItem> items;
  final String? currentRoute;
  final String? userRole;
  final ValueChanged<AppDrawerItem>? onItemTap;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final visibleItems = items
        .where((i) => !i.isDivider && !i.isHeader)
        .where((i) {
      if (i.roles.isEmpty) return true;
      if (userRole == null) return false;
      return i.roles.contains(userRole);
    }).toList();

    final selectedIdx = selectedIndex ?? _computeSelectedIndex(visibleItems);

    return NavigationRail(
      selectedIndex: selectedIdx >= 0 ? selectedIdx : null,
      onDestinationSelected: (index) {
        if (index < visibleItems.length) {
          final item = visibleItems[index];
          if (item.onTap != null) {
            item.onTap!();
          } else {
            onItemTap?.call(item);
          }
        }
      },
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
      leading: const SizedBox.shrink(),
      trailing: Expanded(child: const SizedBox.shrink()),
      destinations: visibleItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon ?? item.icon),
          label: Text(item.title),
        );
      }).toList(),
    );
  }

  int _computeSelectedIndex(List<AppDrawerItem> visibleItems) {
    if (currentRoute == null) return -1;
    for (int i = 0; i < visibleItems.length; i++) {
      if (visibleItems[i].route == currentRoute) return i;
    }
    return -1;
  }
}

// ─── Desktop Sidebar ──────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.items,
    this.userInfo,
    this.currentRoute,
    this.userRole,
    this.onLogout,
    this.onItemTap,
    this.selectedIndex,
  });

  final List<AppDrawerItem> items;
  final AppDrawerUserInfo? userInfo;
  final String? currentRoute;
  final String? userRole;
  final VoidCallback? onLogout;
  final ValueChanged<AppDrawerItem>? onItemTap;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final visibleItems = items.where((i) {
      if (i.isDivider || i.isHeader) return true;
      if (i.roles.isEmpty) return true;
      if (userRole == null) return false;
      return i.roles.contains(userRole);
    }).toList();

    final actionableItems = visibleItems
        .where((i) => !i.isDivider && !i.isHeader)
        .toList();
    final effectiveSelected = selectedIndex ?? _computeSelectedIndex(actionableItems);

    return Drawer(
      backgroundColor: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(Spacings.lgRadius),
        ),
      ),
      child: Column(
        children: [
          // ── User Header ───────────────────────────────────────────
          if (userInfo != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg,
                Spacings.xxl,
                Spacings.lg,
                Spacings.lg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: userInfo!.avatarUrl != null
                        ? NetworkImage(userInfo!.avatarUrl!)
                        : null,
                    child: userInfo!.avatarUrl == null
                        ? Text(
                            userInfo!.avatarInitials ??
                                (userInfo!.name != null
                                    ? _getInitials(userInfo!.name!)
                                    : '?'),
                            style: tt.titleSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (userInfo!.name != null)
                          Text(
                            userInfo!.name!,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (userInfo!.email != null)
                          Text(
                            userInfo!.email!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],

          // ── Menu Items ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final item in visibleItems) ...[
                  if (item.isDivider)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacings.lg,
                        vertical: Spacings.sm,
                      ),
                      child: Divider(),
                    )
                  else if (item.isHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacings.xl,
                        Spacings.lg,
                        Spacings.xl,
                        Spacings.sm,
                      ),
                      child: Text(
                        item.title.toUpperCase(),
                        style: AppTypography.overline.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else ...[
                    _buildSidebarItem(
                      context,
                      item,
                      actionableItems.indexOf(item) == effectiveSelected,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // ── Footer / Logout ───────────────────────────────────────
          if (onLogout != null) ...[
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: AppColors.errorOf(cs.brightness),
                size: Spacings.mdIcon,
              ),
              title: Text(
                'Log Out',
                style: tt.bodyLarge?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              onTap: onLogout,
            ),
            const SizedBox(height: Spacings.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    AppDrawerItem item,
    bool isSelected,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs / 2,
      ),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
        leading: Icon(
          isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
          size: Spacings.mdIcon,
        ),
        title: Text(
          item.title,
          style: tt.bodyLarge?.copyWith(
            color: isSelected ? cs.primary : cs.onSurface,
            fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        onTap: () {
          if (item.onTap != null) {
            item.onTap!();
          } else {
            onItemTap?.call(item);
          }
        },
      ),
    );
  }

  int _computeSelectedIndex(List<AppDrawerItem> actionableItems) {
    if (currentRoute == null) return -1;
    for (int i = 0; i < actionableItems.length; i++) {
      if (actionableItems[i].route == currentRoute) return i;
    }
    return -1;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
