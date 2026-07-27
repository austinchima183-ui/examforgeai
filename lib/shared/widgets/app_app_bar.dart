import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import 'app_button.dart';
import 'app_text_field.dart';

// ─── AppAppBar ────────────────────────────────────────────────────────────────

/// A custom app bar supporting a title, leading widget, actions, search mode
/// toggle, and responsive height.
///
/// When [isSearchMode] is `true`, the title area is replaced with a search
/// text field. The search mode can be toggled via [onSearchToggle].
///
/// ```dart
/// AppAppBar(
///   title: 'Dashboard',
///   actions: [Icon(Icons.settings)],
///   isSearchMode: _isSearching,
///   onSearchToggle: () => setState(() => _isSearching = !_isSearching),
///   onSearchChanged: (q) => filter(q),
/// )
/// ```
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.elevation,
    this.isSearchMode = false,
    this.searchHint,
    this.searchController,
    this.onSearchToggle,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.bottom,
    this.flexibleSpace,
  });

  /// Title text displayed in the app bar.
  final String? title;

  /// Leading widget (overrides default back button).
  final Widget? leading;

  /// Action widgets displayed at the trailing edge.
  final List<Widget>? actions;

  /// Whether to centre the title. Defaults to the theme's setting.
  final bool? centerTitle;

  /// Background colour override.
  final Color? backgroundColor;

  /// Elevation override.
  final double? elevation;

  /// When `true`, replaces the title with a search text field.
  final bool isSearchMode;

  /// Hint text for the search field.
  final String? searchHint;

  /// Controller for the search text field.
  final TextEditingController? searchController;

  /// Callback to toggle search mode on / off.
  final VoidCallback? onSearchToggle;

  /// Callback when the search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Callback when the search is submitted.
  final ValueChanged<String>? onSearchSubmitted;

  /// Optional bottom widget (e.g. [TabBar], [PreferredSize]).
  final PreferredSizeWidget? bottom;

  /// Optional flexible space widget.
  final Widget? flexibleSpace;

  @override
  Size get preferredSize {
    // Base height 56 (default AppBar) + bottom if present
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(56.0 + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;

    // Responsive height is handled via preferredSize; we adjust content
    // padding on wider screens.
    final horizontalPadding = isDesktop ? Spacings.xl : 0.0;

    return AppBar(
      title: isSearchMode
          ? Padding(
              padding: EdgeInsets.only(right: horizontalPadding),
              child: AppSearchField(
                hint: searchHint ?? 'Search…',
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                autofocus: true,
              ),
            )
          : title != null
              ? Padding(
                  padding: EdgeInsets.only(left: horizontalPadding),
                  child: Text(
                    title!,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                )
              : null,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? cs.surface,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1.0,
      surfaceTintColor: cs.surfaceTint,
      foregroundColor: cs.onSurface,
      actions: [
        if (onSearchToggle != null && !isSearchMode)
          AppIconButton(
            icon: Icons.search,
            onPressed: onSearchToggle,
            tooltip: 'Search',
          ),
        if (isSearchMode)
          AppIconButton(
            icon: Icons.close,
            onPressed: onSearchToggle,
            tooltip: 'Close search',
          ),
        if (actions != null) ...actions!,
        SizedBox(width: horizontalPadding),
      ],
      bottom: bottom,
      flexibleSpace: flexibleSpace,
    );
  }
}

// ─── AppSliverAppBar ──────────────────────────────────────────────────────────

/// A sliver app bar variant for use in [CustomScrollView] with support for
/// expanded / collapsed states, flexible space, and search mode.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AppSliverAppBar(
///       title: 'Exams',
///       expandedHeight: 200,
///       flexibleSpace: _buildHeader(),
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.elevation,
    this.expandedHeight,
    this.flexibleSpace,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.stretch = false,
    this.bottom,
    this.isSearchMode = false,
    this.searchHint,
    this.searchController,
    this.onSearchToggle,
    this.onSearchChanged,
    this.onSearchSubmitted,
  });

  /// Title text.
  final String? title;

  /// Leading widget.
  final Widget? leading;

  /// Action widgets.
  final List<Widget>? actions;

  /// Whether to centre the title.
  final bool? centerTitle;

  /// Background colour override.
  final Color? backgroundColor;

  /// Elevation override.
  final double? elevation;

  /// Height of the app bar when fully expanded.
  final double? expandedHeight;

  /// Flexible space widget (shown in expanded state).
  final Widget? flexibleSpace;

  /// Whether the app bar floats (becomes visible when scrolling up).
  final bool floating;

  /// Whether the app bar remains pinned at the top when collapsed.
  final bool pinned;

  /// Whether the app bar snaps into view (requires [floating]).
  final bool snap;

  /// Whether the app bar stretches when over-scrolled.
  final bool stretch;

  /// Optional bottom widget (e.g. [TabBar]).
  final PreferredSizeWidget? bottom;

  /// When `true`, replaces the collapsed title with a search field.
  final bool isSearchMode;

  /// Hint text for the search field.
  final String? searchHint;

  /// Controller for the search text field.
  final TextEditingController? searchController;

  /// Callback to toggle search mode.
  final VoidCallback? onSearchToggle;

  /// Callback when the search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Callback when the search is submitted.
  final ValueChanged<String>? onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SliverAppBar(
      title: isSearchMode
          ? AppSearchField(
              hint: searchHint ?? 'Search…',
              controller: searchController,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              autofocus: true,
            )
          : title != null
              ? Text(
                  title!,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                )
              : null,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? cs.surface,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1.0,
      surfaceTintColor: cs.surfaceTint,
      foregroundColor: cs.onSurface,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      floating: floating,
      pinned: pinned,
      snap: snap,
      stretch: stretch,
      bottom: bottom,
      actions: [
        if (onSearchToggle != null && !isSearchMode)
          AppIconButton(
            icon: Icons.search,
            onPressed: onSearchToggle,
            tooltip: 'Search',
          ),
        if (isSearchMode)
          AppIconButton(
            icon: Icons.close,
            onPressed: onSearchToggle,
            tooltip: 'Close search',
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
