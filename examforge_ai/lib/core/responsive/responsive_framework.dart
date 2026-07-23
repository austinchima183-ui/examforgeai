/// Responsive / Adaptive UI Framework for ExamForge AI.
///
/// Provides a complete set of primitives for building layouts that adapt
/// gracefully across mobile, tablet, desktop, and large-desktop viewports.
///
/// **Key concepts:**
/// - [ScreenBreakpoint] – declarative breakpoint definition with grid metadata
/// - [ScreenSize] – enum representation of the current size class
/// - [ResponsiveLayout] – widget that picks a builder per breakpoint
/// - [AdaptiveScaffold] – scaffold whose navigation adapts automatically
/// - [AdaptiveGrid] – responsive grid based on breakpoint columns
/// - [ResponsiveValue] – value resolution per screen size
/// - [ResponsivePadding] – EdgeInsets that adapts per screen size
/// - [AdaptiveDialog] – dialog / bottom-sheet selection per form-factor
/// - [AdaptiveCard] – card layout that reflows by breakpoint
/// - [screenSizeProvider] – Riverpod provider for the current [ScreenSize]
///
/// All breakpoints follow Material 3 adaptive layout guidance and are
/// customisable through the [ScreenBreakpoint] predefined constants.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../themes/app_colors.dart';
import '../themes/app_typography.dart';
import '../themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ScreenSize Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Enumerates the four adaptive size-classes used throughout ExamForge AI.
///
/// Each value maps to a [ScreenBreakpoint] that defines its pixel range,
/// column count, margin, and gutter.
enum ScreenSize {
  /// Handset / small phone – width < 600 px
  mobile,

  /// Tablet / small laptop – 600–1023 px
  tablet,

  /// Standard desktop – 1024–1439 px
  desktop,

  /// Wide desktop / ultra-wide – >= 1440 px
  largeDesktop;

  /// Determines the [ScreenSize] from a raw [width] value.
  ///
  /// ```dart
  /// final size = ScreenSize.fromWidth(MediaQuery.of(context).size.width);
  /// ```
  static ScreenSize fromWidth(double width) {
    if (width >= 1440) return ScreenSize.largeDesktop;
    if (width >= 1024) return ScreenSize.desktop;
    if (width >= 600) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ScreenBreakpoint
// ═══════════════════════════════════════════════════════════════════════════════

/// A declarative breakpoint definition with grid-layout metadata.
///
/// Each breakpoint carries its own column count, margin, and gutter so that
/// grid-based layouts can be driven entirely by the active breakpoint.
///
/// ```dart
/// final bp = ScreenBreakpoint.mobile;
/// print(bp.columns); // 4
/// ```
class ScreenBreakpoint extends Equatable {
  /// Human-readable name (e.g. "mobile", "tablet").
  final String name;

  /// Minimum inclusive width in logical pixels.
  final double minWidth;

  /// Maximum exclusive width in logical pixels.
  ///
  /// `null` means unbounded (applies to the largest breakpoint).
  final double? maxWidth;

  /// Number of grid columns at this breakpoint.
  final int columns;

  /// Outer margin in logical pixels.
  final double margin;

  /// Gutter between columns in logical pixels.
  final double gutter;

  const ScreenBreakpoint({
    required this.name,
    required this.minWidth,
    this.maxWidth,
    required this.columns,
    required this.margin,
    required this.gutter,
  });

  // ─── Predefined Breakpoints ─────────────────────────────────────────────

  /// Mobile: 0–599 px, 4 columns, 16 px margin, 8 px gutter.
  static const ScreenBreakpoint mobile = ScreenBreakpoint(
    name: 'mobile',
    minWidth: 0,
    maxWidth: 599,
    columns: 4,
    margin: 16,
    gutter: 8,
  );

  /// Tablet: 600–1023 px, 8 columns, 32 px margin, 16 px gutter.
  static const ScreenBreakpoint tablet = ScreenBreakpoint(
    name: 'tablet',
    minWidth: 600,
    maxWidth: 1023,
    columns: 8,
    margin: 32,
    gutter: 16,
  );

  /// Desktop: 1024–1439 px, 12 columns, 64 px margin, 24 px gutter.
  static const ScreenBreakpoint desktop = ScreenBreakpoint(
    name: 'desktop',
    minWidth: 1024,
    maxWidth: 1439,
    columns: 12,
    margin: 64,
    gutter: 24,
  );

  /// Large desktop: 1440+ px, 12 columns, 80 px margin, 24 px gutter.
  static const ScreenBreakpoint largeDesktop = ScreenBreakpoint(
    name: 'largeDesktop',
    minWidth: 1440,
    maxWidth: null,
    columns: 12,
    margin: 80,
    gutter: 24,
  );

  /// All predefined breakpoints in ascending order.
  static const List<ScreenBreakpoint> values = [
    mobile,
    tablet,
    desktop,
    largeDesktop,
  ];

  /// Returns `true` if [width] falls within this breakpoint's range.
  bool contains(double width) {
    if (width < minWidth) return false;
    if (maxWidth != null && width > maxWidth!) return false;
    return true;
  }

  /// Resolves the matching [ScreenBreakpoint] for the given [width].
  static ScreenBreakpoint fromWidth(double width) {
    for (final bp in values.reversed) {
      if (width >= bp.minWidth) return bp;
    }
    return mobile;
  }

  /// Maps this breakpoint to its corresponding [ScreenSize] enum value.
  ScreenSize get screenSize {
    switch (name) {
      case 'mobile':
        return ScreenSize.mobile;
      case 'tablet':
        return ScreenSize.tablet;
      case 'desktop':
        return ScreenSize.desktop;
      case 'largeDesktop':
        return ScreenSize.largeDesktop;
      default:
        return ScreenSize.mobile;
    }
  }

  @override
  List<Object?> get props => [name, minWidth, maxWidth, columns, margin, gutter];

  @override
  String toString() =>
      'ScreenBreakpoint($name, $minWidth-${maxWidth ?? '∞'}, '
      'cols=$columns, margin=$margin, gutter=$gutter)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// screenSizeProvider
// ═══════════════════════════════════════════════════════════════════════════════

/// Riverpod provider that exposes the current [ScreenSize].
///
/// Reads [MediaQuery] width and maps it via [ScreenSize.fromWidth].
/// Use this provider whenever you need the current size class outside
/// of a widget build method.
///
/// ```dart
/// final size = ref.watch(screenSizeProvider);
/// if (size == ScreenSize.mobile) { … }
/// ```
final screenSizeProvider = Provider<ScreenSize>((ref) {
  // This provider requires a [MediaQuery] ancestor. In widget tests,
  // wrap with [MediaQuery] or override this provider.
  // We use `ref.watch` on nothing – the value is computed per-read.
  // For real reactivity, wrap this in a ConsumerWidget that watches
  // MediaQuery, or use a StateProvider that is updated on layout change.
  //
  // In practice, use [ScreenSize.fromWidth] directly inside build methods
  // with [MediaQuery.of(context).size.width], or use [ResponsiveLayout].
  return ScreenSize.mobile; // default; override in ProviderScope overrides
});

/// Provider that returns the active [ScreenBreakpoint] for a given width.
///
/// Override in your `ProviderScope` with the actual screen width:
/// ```dart
/// ProviderScope(
///   overrides: [
///     screenBreakpointProvider.overrideWith((ref) {
///       final width = MediaQuery.of(context).size.width;
///       return ScreenBreakpoint.fromWidth(width);
///     }),
///   ],
/// )
/// ```
final screenBreakpointProvider = Provider<ScreenBreakpoint>((ref) {
  return ScreenBreakpoint.mobile;
});

// ═══════════════════════════════════════════════════════════════════════════════
// ResponsiveLayout
// ═══════════════════════════════════════════════════════════════════════════════

/// A widget that selects a layout builder based on the current screen width.
///
/// Uses [LayoutBuilder] and [MediaQuery] to determine the active
/// [ScreenBreakpoint] and invokes the matching builder.
///
/// If a builder for the current size class is not provided, the next
/// smaller builder is used as a fallback chain:
/// `largeDesktop → desktop → tablet → mobile`.
///
/// ```dart
/// ResponsiveLayout(
///   mobile: () => const MobileView(),
///   tablet: () => const TabletView(),
///   desktop: () => const DesktopView(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Builder invoked when the viewport is mobile-sized.
  final WidgetBuilder mobile;

  /// Builder invoked when the viewport is tablet-sized.
  ///
  /// Falls back to [mobile] if null.
  final WidgetBuilder? tablet;

  /// Builder invoked when the viewport is desktop-sized.
  ///
  /// Falls back to [tablet] then [mobile] if null.
  final WidgetBuilder? desktop;

  /// Builder invoked when the viewport is large-desktop-sized.
  ///
  /// Falls back to [desktop] → [tablet] → [mobile] if null.
  final WidgetBuilder? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final screenSize = ScreenSize.fromWidth(width);
        final builder = _resolveBuilder(screenSize);
        return builder(context);
      },
    );
  }

  /// Resolves the correct builder using a fallback chain.
  WidgetBuilder _resolveBuilder(ScreenSize size) {
    switch (size) {
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdaptiveScaffold
// ═══════════════════════════════════════════════════════════════════════════════

/// A responsive scaffold that automatically adapts its navigation pattern.
///
/// - **Mobile** (< 600 px): [BottomNavigationBar]
/// - **Tablet** (600–1023 px): [NavigationRail]
/// - **Desktop / Large** (>= 1024 px): Permanent [NavigationDrawer]
///
/// The scaffold follows Material 3 navigation guidelines and ensures
/// consistent destination selection across all navigation types.
///
/// ```dart
/// AdaptiveScaffold(
///   destinations: [
///     NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
///     NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
///   ],
///   selectedIndex: 0,
///   onDestinationSelected: (i) => setState(() => _index = i),
///   body: const HomeView(),
/// )
/// ```
class AdaptiveScaffold extends StatelessWidget {
  /// The navigation destinations shared across all navigation types.
  final List<NavigationDestination> destinations;

  /// The widget displayed as the scaffold body.
  final Widget body;

  /// Currently selected destination index.
  final int selectedIndex;

  /// Callback when the user selects a different destination.
  final ValueChanged<int> onDestinationSelected;

  /// Optional [AppBar] displayed at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);

    switch (screenSize) {
      case ScreenSize.mobile:
        return _buildMobileScaffold();
      case ScreenSize.tablet:
        return _buildTabletScaffold();
      case ScreenSize.desktop:
      case ScreenSize.largeDesktop:
        return _buildDesktopScaffold();
    }
  }

  // ─── Mobile: BottomNavigationBar ───────────────────────────────────────

  Widget _buildMobileScaffold() {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ─── Tablet: NavigationRail ────────────────────────────────────────────

  Widget _buildTabletScaffold() {
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),)
                .toList(),
            leading: floatingActionButton,
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  // ─── Desktop/Large: NavigationDrawer (permanent) ──────────────────────

  Widget _buildDesktopScaffold() {
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacings.lg,
                  Spacings.lg,
                  Spacings.lg,
                  Spacings.md,
                ),
                child: Text(
                  'ExamForge AI',
                  style: AppTypography.lightTextTheme.titleMedium?.copyWith(
                    color: AppColors.seed,
                  ),
                ),
              ),
              const Divider(),
              ...destinations,
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdaptiveGrid
// ═══════════════════════════════════════════════════════════════════════════════

/// A responsive grid layout that derives its column count from the
/// active [ScreenBreakpoint].
///
/// Internally uses [SliverGridDelegateWithFixedCrossAxisCount] with column
/// count, spacing, and aspect ratio driven by the current viewport width.
///
/// ```dart
/// AdaptiveGrid(
///   children: [
///     GridTile(child: Card(child: Text('A'))),
///     GridTile(child: Card(child: Text('B'))),
///   ],
/// )
/// ```
class AdaptiveGrid extends StatelessWidget {
  /// The grid children.
  final List<Widget> children;

  /// Horizontal spacing between grid items.
  ///
  /// Defaults to the gutter of the active breakpoint.
  final double? crossAxisSpacing;

  /// Vertical spacing between grid items.
  ///
  /// Defaults to the gutter of the active breakpoint.
  final double? mainAxisSpacing;

  /// Aspect ratio of each grid tile.
  ///
  /// Defaults to 1.0 (square tiles).
  final double childAspectRatio;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = ScreenBreakpoint.fromWidth(width);

    return GridView.count(
      crossAxisCount: breakpoint.columns,
      crossAxisSpacing: crossAxisSpacing ?? breakpoint.gutter,
      mainAxisSpacing: mainAxisSpacing ?? breakpoint.gutter,
      childAspectRatio: childAspectRatio,
      padding: EdgeInsets.symmetric(horizontal: breakpoint.margin),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ResponsiveValue<T>
// ═══════════════════════════════════════════════════════════════════════════════

/// Returns a different value of type [T] based on the current screen size.
///
/// Uses a fallback chain so you only need to specify values where they
/// differ from the next-smaller size class:
/// `largeDesktop → desktop → tablet → mobile`.
///
/// ```dart
/// final columns = ResponsiveValue<int>(
///   mobile: 1,
///   tablet: 2,
///   desktop: 3,
/// ).resolve(context);
/// ```
class ResponsiveValue<T> {
  /// Value used on mobile-sized viewports. **Required** – serves as the
  /// ultimate fallback.
  final T mobile;

  /// Value used on tablet-sized viewports. Falls back to [mobile].
  final T? tablet;

  /// Value used on desktop-sized viewports. Falls back to [tablet] → [mobile].
  final T? desktop;

  /// Value used on large-desktop-sized viewports.
  /// Falls back to [desktop] → [tablet] → [mobile].
  final T? largeDesktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  /// Resolves the appropriate value for the current screen size.
  ///
  /// Uses [MediaQuery.of(context)] to determine width and maps it to
  /// a [ScreenSize], then walks the fallback chain.
  T resolve(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);
    return resolveForSize(screenSize);
  }

  /// Resolves the value for a specific [ScreenSize] without a context.
  T resolveForSize(ScreenSize size) {
    switch (size) {
      case ScreenSize.largeDesktop:
        return largeDesktop ?? resolveForSize(ScreenSize.desktop);
      case ScreenSize.desktop:
        return desktop ?? resolveForSize(ScreenSize.tablet);
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ResponsivePadding
// ═══════════════════════════════════════════════════════════════════════════════

/// An [EdgeInsets] that adapts to the current screen size.
///
/// Provides per-breakpoint padding values with a fallback chain:
/// unspecified values default to the next-smaller breakpoint's value.
///
/// ```dart
/// ResponsivePadding(
///   mobile: EdgeInsets.all(16),
///   tablet: EdgeInsets.all(24),
///   desktop: EdgeInsets.all(32),
/// ).resolve(context)
/// ```
class ResponsivePadding {
  /// Padding for mobile-sized viewports.
  final EdgeInsets mobile;

  /// Padding for tablet-sized viewports. Defaults to [mobile].
  final EdgeInsets? tablet;

  /// Padding for desktop-sized viewports. Defaults to [tablet] → [mobile].
  final EdgeInsets? desktop;

  /// Padding for large-desktop-sized viewports.
  /// Defaults to [desktop] → [tablet] → [mobile].
  final EdgeInsets? largeDesktop;

  const ResponsivePadding({
    this.mobile = const EdgeInsets.all(16),
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  /// Resolves the appropriate [EdgeInsets] for the current screen size.
  EdgeInsets resolve(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);
    return resolveForSize(screenSize);
  }

  /// Resolves the padding for a specific [ScreenSize] without a context.
  EdgeInsets resolveForSize(ScreenSize size) {
    switch (size) {
      case ScreenSize.largeDesktop:
        return largeDesktop ?? resolveForSize(ScreenSize.desktop);
      case ScreenSize.desktop:
        return desktop ?? resolveForSize(ScreenSize.tablet);
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdaptiveDialog
// ═══════════════════════════════════════════════════════════════════════════════

/// Shows dialog content appropriately for the current form-factor.
///
/// - **Mobile**: Material bottom sheet (easier thumb reach)
/// - **Tablet / Desktop / Large**: Centered Material dialog
///
/// ```dart
/// AdaptiveDialog.show(
///   context: context,
///   title: 'Confirm',
///   content: Text('Delete this item?'),
///   actions: [
///     TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
///     FilledButton(onPressed: () => handleDelete(), child: Text('Delete')),
///   ],
/// );
/// ```
class AdaptiveDialog {
  AdaptiveDialog._();

  /// Shows an adaptive dialog or bottom sheet.
  ///
  /// [context] – the parent [BuildContext].
  /// [title] – optional dialog title.
  /// [content] – the dialog body widget.
  /// [actions] – optional action buttons (placed at the bottom).
  /// [isDismissible] – whether the user can dismiss by tapping outside.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool useRootNavigator = true,
  }) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);

    if (screenSize == ScreenSize.mobile) {
      return _showBottomSheet<T>(
        context: context,
        title: title,
        content: content,
        actions: actions,
        isDismissible: isDismissible,
        useRootNavigator: useRootNavigator,
      );
    } else {
      return _showDialog<T>(
        context: context,
        title: title,
        content: content,
        actions: actions,
        isDismissible: isDismissible,
        useRootNavigator: useRootNavigator,
      );
    }
  }

  // ─── Mobile: BottomSheet ───────────────────────────────────────────────

  static Future<T?> _showBottomSheet<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: Spacings.md),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: Spacings.borderRadiusFull,
                    ),
                  ),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacings.xl,
                    Spacings.lg,
                    Spacings.xl,
                    Spacings.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacings.xl,
                  title == null ? Spacings.lg : 0,
                  Spacings.xl,
                  Spacings.lg,
                ),
                child: content,
              ),
              if (actions != null && actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacings.xl,
                    0,
                    Spacings.xl,
                    Spacings.xl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tablet/Desktop: Center Dialog ─────────────────────────────────────

  static Future<T?> _showDialog<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      builder: (context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: content,
          actions: actions,
          actionsAlignment: MainAxisAlignment.end,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AdaptiveCard
// ═══════════════════════════════════════════════════════════════════════════════

/// A card that adjusts its internal layout based on screen size.
///
/// - **Mobile**: Full-width vertical layout (image on top, content below)
/// - **Tablet**: 2-column horizontal layout
/// - **Desktop / Large**: 3-column horizontal layout
///
/// ```dart
/// AdaptiveCard(
///   imageUrl: 'https://example.com/image.png',
///   title: 'Exam Tips',
///   subtitle: 'Top 10 strategies',
///   content: Text('Detailed description...'),
///   onTap: () => navigateToDetail(),
/// )
/// ```
class AdaptiveCard extends StatelessWidget {
  /// Optional leading image URL.
  final String? imageUrl;

  /// Card title.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Content widget displayed in the body area.
  final Widget? content;

  /// Optional trailing action widget (e.g. icon button).
  final Widget? trailing;

  /// Optional tap handler – wraps the card in an [InkWell].
  final VoidCallback? onTap;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  const AdaptiveCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.content,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);

    switch (screenSize) {
      case ScreenSize.mobile:
        return _buildVerticalCard(context, 1);
      case ScreenSize.tablet:
        return _buildHorizontalCard(context, 2);
      case ScreenSize.desktop:
      case ScreenSize.largeDesktop:
        return _buildHorizontalCard(context, 3);
    }
  }

  // ─── Vertical Card (Mobile) ────────────────────────────────────────────

  Widget _buildVerticalCard(BuildContext context, int flex) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: Spacings.elevationSm,
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Spacings.borderRadiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                _buildImage(context, height: 160),
              Padding(
                padding: Spacings.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: Spacings.sm),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyMedium!,
                        child: content!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Horizontal Card (Tablet/Desktop) ──────────────────────────────────

  Widget _buildHorizontalCard(BuildContext context, int imageFlex) {
    final contentFlex = imageFlex == 2 ? 3 : 4;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: Spacings.elevationSm,
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Spacings.borderRadiusLg,
          child: Row(
            children: [
              if (imageUrl != null)
                Expanded(
                  flex: imageFlex,
                  child: _buildImage(context, height: null),
                ),
              Expanded(
                flex: contentFlex,
                child: Padding(
                  padding: Spacings.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: Spacings.xs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (content != null) ...[
                        const SizedBox(height: Spacings.sm),
                        DefaultTextStyle(
                          style: Theme.of(context).textTheme.bodyMedium!,
                          child: content!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Image ─────────────────────────────────────────────────────────────

  Widget _buildImage(BuildContext context, {required double? height}) {
    // Placeholder – in production replace with CachedNetworkImage.
    return Container(
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(
        Icons.image_outlined,
        size: Spacings.xlIcon,
      ),
    );
  }
}
