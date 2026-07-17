import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_guards.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_navigation_drawer.dart';

/// Shell widget that wraps all authenticated routes with a shared
/// responsive navigation layout and top app bar.
///
/// **Responsive behaviour:**
/// - **Mobile** (< 600 px): Bottom navigation bar, no drawer/rail.
/// - **Tablet** (600–1023 px): Navigation rail on the left + content.
/// - **Desktop** (≥ 1024 px): Permanent sidebar drawer + content area.
///
/// **Top app bar** includes: search toggle, notifications bell with
/// unread badge, and user avatar dropdown.
class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({required this.child, super.key});

  /// The page content rendered by the current shell route.
  final Widget child;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  // ─── Navigation Items ──────────────────────────────────────────────

  List<AppDrawerItem> _buildNavItems(UserRole? role) {
    return [
      AppDrawerItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        route: role?.dashboardRoute ?? RouteNames.dashboard,
      ),
      AppDrawerItem.header('Manage'),
      AppDrawerItem(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        route: RouteNames.profile,
      ),
      AppDrawerItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        route: RouteNames.settings,
      ),
      AppDrawerItem.divider(),
      AppDrawerItem(
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_rounded,
        route: RouteNames.notifications,
        badge: 2,
      ),
    ];
  }

  List<AppBottomNavItem> _buildBottomNavItems() {
    return const [
      AppBottomNavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      AppBottomNavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
      AppBottomNavItem(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_rounded,
        label: 'Alerts',
        showBadge: true,
      ),
      AppBottomNavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];
  }

  int _computeBottomNavIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.contains('dashboard')) return 0;
    if (location.contains('profile')) return 1;
    if (location.contains('notifications')) return 2;
    if (location.contains('settings')) return 3;
    return 0;
  }

  void _onBottomNavTap(int index) {
    final roleAsync = ref.read(userRoleProvider);
    final role = roleAsync.when(
      data: UserRole.fromString,
      loading: () => null,
      error: (_, __) => null,
    );
    switch (index) {
      case 0:
        context.go(role?.dashboardRoute ?? RouteNames.dashboard);
      case 1:
        context.go(RouteNames.profile);
      case 2:
        context.go(RouteNames.notifications);
      case 3:
        context.go(RouteNames.settings);
    }
  }

  void _onDrawerItemTap(AppDrawerItem item) {
    if (item.route != null) {
      context.go(item.route!);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final role = roleAsync.when(
      data: UserRole.fromString,
      loading: () => null,
      error: (_, __) => null,
    );

    final currentLocation = GoRouterState.of(context).matchedLocation;
    final navItems = _buildNavItems(role);
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: _buildAppBar(context, role),
      drawer: isMobile ? _buildMobileDrawer(navItems, role) : null,
      body: Row(
        children: [
          // ── Desktop: Permanent Sidebar ──────────────────────────
          if (isDesktop)
            SizedBox(
              width: 280,
              child: AppNavigationDrawer(
                userInfo: _buildUserInfo(role),
                items: navItems,
                currentRoute: currentLocation,
                userRole: role?.value,
                onLogout: _handleLogout,
                onItemTap: _onDrawerItemTap,
              ),
            ),
          // ── Tablet: Navigation Rail ─────────────────────────────
          if (isTablet)
            _buildNavigationRail(navItems, currentLocation, role),
          // ── Main Content Area ──────────────────────────────────
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              items: _buildBottomNavItems(),
              currentIndex: _computeBottomNavIndex(),
              onTap: _onBottomNavTap,
            )
          : null,
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, UserRole? role) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppBar(
      title: _isSearchMode
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: tt.bodyLarge?.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search exams, questions, students...',
                hintStyle: tt.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.md,
                ),
                isDense: true,
              ),
            )
          : Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  'ExamForge AI',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
      actions: [
        // Search toggle
        if (!_isSearchMode)
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            tooltip: 'Search',
            onPressed: () =>
                setState(() => _isSearchMode = true),
          ),
        if (_isSearchMode)
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: cs.onSurfaceVariant,
            ),
            tooltip: 'Close search',
            onPressed: () {
              _searchController.clear();
              setState(() => _isSearchMode = false);
            },
          ),
        // Notifications bell
        _NotificationBell(
          onTap: () => context.go(RouteNames.notifications),
        ),
        // User avatar dropdown
        _UserAvatarDropdown(
          role: role,
          onLogout: _handleLogout,
        ),
        const SizedBox(width: Spacings.sm),
      ],
    );
  }

  // ─── Mobile Drawer ─────────────────────────────────────────────────

  Widget _buildMobileDrawer(
      List<AppDrawerItem> navItems, UserRole? role) {
    return AppNavigationDrawer(
      userInfo: _buildUserInfo(role),
      items: navItems,
      currentRoute: GoRouterState.of(context).matchedLocation,
      userRole: role?.value,
      onLogout: _handleLogout,
      onItemTap: (item) {
        Navigator.of(context).pop(); // Close drawer
        _onDrawerItemTap(item);
      },
    );
  }

  // ─── Tablet Navigation Rail ────────────────────────────────────────

  Widget _buildNavigationRail(
    List<AppDrawerItem> navItems,
    String currentLocation,
    UserRole? role,
  ) {
    final cs = context.colorScheme;
    final actionableItems =
        navItems.where((i) => !i.isDivider && !i.isHeader).toList();

    int selectedIndex = -1;
    for (int i = 0; i < actionableItems.length; i++) {
      if (actionableItems[i].route != null &&
          currentLocation.startsWith(actionableItems[i].route!)) {
        selectedIndex = i;
        break;
      }
    }

    return NavigationRail(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) {
        if (index < actionableItems.length) {
          final item = actionableItems[index];
          _onDrawerItemTap(item);
        }
      },
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacings.lg),
        child: Icon(
          Icons.school_rounded,
          size: Spacings.lgIcon,
          color: cs.primary,
        ),
      ),
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: AppColors.errorOf(cs.brightness),
              ),
              tooltip: 'Sign Out',
              onPressed: _handleLogout,
            ),
            const SizedBox(height: Spacings.lg),
          ],
        ),
      ),
      destinations: actionableItems
          .map((item) => NavigationRailDestination(
                icon: Badge(
                  isLabelVisible:
                      item.badge != null && item.badge! > 0,
                  label: Text('${item.badge ?? 0}'),
                  child: Icon(item.icon),
                ),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.title),
              ))
          .toList(),
    );
  }

  // ─── User Info ─────────────────────────────────────────────────────

  AppDrawerUserInfo _buildUserInfo(UserRole? role) {
    final authState = ref.read(authProvider);
    final user = authState.user;
    return AppDrawerUserInfo(
      name: user?.fullName ?? 'User',
      email: user?.email ?? 'user@examforge.ai',
      role: role?.label,
      avatarUrl: user?.avatarUrl,
      avatarInitials: user?.fullName != null
          ? _getInitials(user!.fullName)
          : null,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ─── Logout ────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    if (!mounted) return;
    context.go(RouteNames.login);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION BELL (private)
// ═══════════════════════════════════════════════════════════════════════

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    // In production, this would read from a notifications provider.
    // For now, always show a dot indicator.
    return IconButton(
      icon: Badge(
        isLabelVisible: true,
        smallSize: 8,
        backgroundColor: AppColors.errorOf(cs.brightness),
        child: Icon(
          Icons.notifications_outlined,
          color: cs.onSurfaceVariant,
        ),
      ),
      tooltip: 'Notifications',
      onPressed: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// USER AVATAR DROPDOWN (private)
// ═══════════════════════════════════════════════════════════════════════

class _UserAvatarDropdown extends StatelessWidget {
  const _UserAvatarDropdown({
    required this.role,
    required this.onLogout,
  });

  final UserRole? role;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      position: PopupMenuPosition.under,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            size: Spacings.mdIcon,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go(RouteNames.profile);
          case 'settings':
            context.go(RouteNames.settings);
          case 'logout':
            onLogout();
        }
      },
      itemBuilder: (context) => [
        if (role != null)
          PopupMenuItem<String>(
            enabled: false,
            height: 48,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    role!.label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.md),
              Text('Profile', style: tt.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.settings_outlined,
                  size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.md),
              Text('Settings', style: tt.bodyMedium),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.logout_rounded,
                  size: Spacings.mdIcon,
                  color: AppColors.errorOf(cs.brightness)),
              const SizedBox(width: Spacings.md),
              Text(
                'Sign Out',
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
