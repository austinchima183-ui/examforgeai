import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'spacings.dart';

/// Returns the target platform for theme configuration.
///
/// On web, defaults to [TargetPlatform.android] (Material design).
/// On native iOS, returns [TargetPlatform.iOS] for Cupertino design.
/// On all other native platforms, returns [TargetPlatform.android].
TargetPlatform _resolveTargetPlatform() {
  // On web, Platform is not available, so default to Android (Material).
  if (kIsWeb) return TargetPlatform.android;
  // On native platforms, detect iOS for Cupertino transitions.
  // The `defaultTargetPlatform` from Flutter is safe on all platforms.
  return defaultTargetPlatform == TargetPlatform.iOS
      ? TargetPlatform.iOS
      : TargetPlatform.android;
}

/// Root theme configuration for ExamForge AI.
///
/// Provides [lightTheme] and [darkTheme] as fully-configured Material 3
/// [ThemeData] objects. Every component theme is explicitly set to ensure
/// visual consistency across the entire app.
class AppTheme {
  AppTheme._();

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Light theme ready for `MaterialApp.theme`.
  static ThemeData lightTheme() => _buildTheme(
        colorScheme: AppColors.lightScheme,
        textTheme: AppTypography.lightTextTheme,
      );

  /// Dark theme ready for `MaterialApp.darkTheme`.
  static ThemeData darkTheme() => _buildTheme(
        colorScheme: AppColors.darkScheme,
        textTheme: AppTypography.darkTextTheme,
      );

  // ─── Core Builder ─────────────────────────────────────────────────────────

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: colorScheme.surface,
      platform: _resolveTargetPlatform(),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1.0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: AppTypography.wSemiBold,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: Spacings.mdIcon,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: Colors.transparent,
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.xl,
            vertical: Spacings.md,
          ),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          textStyle: AppTypography.button.copyWith(
            color: colorScheme.onPrimary,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.xl,
            vertical: Spacings.md,
          ),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.button.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          textStyle: AppTypography.button.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: AppTypography.wMedium,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        iconColor: colorScheme.onSurfaceVariant,
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          Spacings.xl,
          0,
          Spacings.xl,
          Spacings.lg,
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Spacings.lgRadius),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
      ),

      // ── Navigation Bar (Bottom) ─────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorColor: colorScheme.primaryContainer,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: Spacings.mdIcon,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: Spacings.mdIcon,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(
              color: colorScheme.onSurface,
              fontWeight: AppTypography.wSemiBold,
            );
          }
          return AppTypography.navLabel.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // ── Navigation Rail ─────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
        minExtendedWidth: 80,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
          size: Spacings.mdIcon,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: Spacings.mdIcon,
        ),
        selectedLabelTextStyle: AppTypography.navLabel.copyWith(
          color: colorScheme.onSurface,
          fontWeight: AppTypography.wSemiBold,
        ),
        unselectedLabelTextStyle: AppTypography.navLabel.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Drawer ──────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(Spacings.lgRadius),
          ),
        ),
        width: 304,
      ),

      // ── Snack Bar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.onSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.surface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        dismissDirection: DismissDirection.horizontal,
        insetPadding: const EdgeInsets.fromLTRB(
          Spacings.lg,
          0,
          Spacings.lg,
          Spacings.lg,
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        checkmarkColor: colorScheme.primary,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: Spacings.elevationMd,
        focusElevation: Spacings.elevationMd,
        hoverElevation: Spacings.elevationLg,
        highlightElevation: Spacings.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        extendedSizeConstraints: const BoxConstraints(minHeight: 56),
        largeSizeConstraints: const BoxConstraints(minHeight: 56),
        smallSizeConstraints: const BoxConstraints(minHeight: 40),
      ),

      // ── Tab Bar ─────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: AppTypography.wMedium,
        ),
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant,
        dividerHeight: 1,
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        // Using outline color (higher contrast than outlineVariant) to meet
        // WCAG 1.4.11 Non-text Contrast (3:1 minimum for UI components).
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ── List Tile ───────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.xs,
        ),
        minLeadingWidth: Spacings.xl,
        horizontalTitleGap: Spacings.lg,
        minVerticalPadding: Spacings.md,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Bottom Navigation Bar (Legacy M2 compat) ────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.navLabel.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
        unselectedLabelStyle: AppTypography.navLabel,
      ),

      // ── Icon Theme ──────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: Spacings.mdIcon,
      ),

      // ── Primary Icon Theme ──────────────────────────────────────────────
      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: Spacings.mdIcon,
      ),

      // ── Progress Indicator ──────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.surface;
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // ── Checkbox ────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return Colors.transparent;
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.surface;
            }
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onPrimary;
        }),
        side: BorderSide(color: colorScheme.onSurfaceVariant, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.xs / 2),
        ),
      ),

      // ── Radio ───────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSurface.withValues(alpha: 0.38);
            }
            return colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // ── Popup Menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: Spacings.elevationLg.toInt().toDouble(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(Spacings.xs),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.inversePrimary,
        ),
        waitDuration: const Duration(milliseconds: 500),
        preferBelow: true,
      ),

      // ── Scrollbar ───────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return colorScheme.primary.withValues(alpha: 0.6);
          }
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
        }),
        radius: const Radius.circular(Spacings.smRadius),
        thickness: WidgetStateProperty.all(6),
        thumbVisibility: WidgetStateProperty.all(false),
      ),

      // ── Page transitions (Cupertino on iOS) ─────────────────────────────
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _buildAndroidTransition(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Transition Helpers ───────────────────────────────────────────────────

  static PageTransitionsBuilder _buildAndroidTransition() {
    // Material 3 zoom transition on Android (shared-axis removed from Flutter)
    return const ZoomPageTransitionsBuilder();
  }
}
