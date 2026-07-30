import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/dependency_injection.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/theme_provider.dart';
import 'core/utils/logger.dart';
import 'routing/app_router.dart';

/// Root widget for the ExamForge AI application.
///
/// Extends [ConsumerStatefulWidget] so it can:
/// - Initialize the [NotificationService] once in [initState].
/// - Reactively rebuild when the [themeModeProvider] or
///   [appRouterProvider] change.
/// - Apply responsive text scaling and overlay adjustments via the
///   [MaterialApp.builder].
class ExamForgeApp extends ConsumerStatefulWidget {
  const ExamForgeApp({super.key});

  @override
  ConsumerState<ExamForgeApp> createState() => _ExamForgeAppState();
}

class _ExamForgeAppState extends ConsumerState<ExamForgeApp>
    with WidgetsBindingObserver {
  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Register for app lifecycle changes (paused, resumed, etc.)
    WidgetsBinding.instance.addObserver(this);

    // Initialize the notification service.
    // This is intentionally fire-and-forget — notifications are a
    // non-critical feature and should not block app startup.
    _initializeNotificationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh auth state when the app comes back to the foreground
    // so that expired sessions are detected promptly.
    if (state == AppLifecycleState.resumed) {
      AppLogger.debug('App resumed — checking auth state freshness');
    }
  }

  // ─── Notification Service Initialization ──────────────────────────────

  Future<void> _initializeNotificationService() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize(
        onForegroundNotification: (notification) {
          AppLogger.info(
            'Foreground notification: ${notification.id} — ${notification.title}',
          );
        },
        onNotificationTap: (notification) {
          AppLogger.info(
            'Notification tap: ${notification.id} — ${notification.title}',
          );
          // Navigate to the relevant screen based on notification data.
          // The router handles deep-link navigation from notification payloads.
          try {
            final router = ref.read(appRouterProvider);
            final data = notification.data;
            if (data != null && data.containsKey('route')) {
              router.go(data['route'] as String);
            }
          } catch (e) {
            AppLogger.warning('Failed to navigate from notification tap: $e');
          }
        },
      );
      AppLogger.info('NotificationService initialized from App widget');
    } catch (e) {
      // Notification initialization failure must not crash the app.
      AppLogger.error(
        'Failed to initialize NotificationService',
        error: e,
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch theme mode for reactive theme switching.
    final themeMode = ref.watch(themeModeProvider);

    // Watch theme state for optional dynamic seed color.
    final themeState = ref.watch(themeProvider);

    // Watch the router so it rebuilds when auth state changes.
    final router = ref.watch(appRouterProvider);

    // Determine light and dark themes — if a dynamic seed color is set,
    // use the ThemeState's generated themes; otherwise, use the defaults.
    final lightTheme = themeState.seedColor != null
        ? themeState.lightTheme
        : AppTheme.lightTheme();
    final darkTheme = themeState.seedColor != null
        ? themeState.darkTheme
        : AppTheme.darkTheme();

    return MaterialApp.router(
      // ─── Identity ───────────────────────────────────────────────────
      title: 'ExamForge AI',
      debugShowCheckedModeBanner: false,

      // ─── Theming ────────────────────────────────────────────────────
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,

      // ─── Routing ────────────────────────────────────────────────────
      routerConfig: router,

      // ─── Builder ────────────────────────────────────────────────────
      // Applies global adjustments to every page:
      // 1. Clamps text scaling to a reasonable range so large
      //    accessibility text sizes don't break layouts.
      // 2. Provides a [navigatorKey] access point for overlay operations.
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.5,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
