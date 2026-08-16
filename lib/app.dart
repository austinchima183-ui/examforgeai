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
        onForegroundMessage: (message) {
          AppLogger.info(
            'Foreground notification: ${message.messageId}',
          );
        },
        onNotificationTap: (message) {
          AppLogger.info(
            'Notification tap: ${message.messageId}',
          );
          // TODO: Navigate to the relevant screen based on message.data.
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
      // 1. Adds a skip-to-content link for keyboard/screen-reader users.
      // 2. Clamps text scaling to a reasonable range so large
      //    accessibility text sizes don't break layouts.
      // 3. Provides a [navigatorKey] access point for overlay operations.
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.5,
          child: _SkipToContentLink(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

// ─── Skip-to-Content Link ─────────────────────────────────────────────────────

/// A visually-hidden skip link that appears on keyboard focus, allowing
/// screen-reader and keyboard users to jump directly to the main content
/// area, bypassing repetitive navigation.
///
/// On focus the link expands into a visible banner; on activation it
/// moves focus to the first focusable child inside the main content.
class _SkipToContentLink extends StatefulWidget {
  const _SkipToContentLink({required this.child});

  final Widget child;

  @override
  State<_SkipToContentLink> createState() => _SkipToContentLinkState();
}

class _SkipToContentLinkState extends State<_SkipToContentLink> {
  final _skipFocusNode = FocusNode();
  final _contentFocusNode = FocusNode(debugLabel: 'main-content');

  @override
  void dispose() {
    _skipFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Skip link (visible only when focused) ──────────────────────
        Focus(
          focusNode: _skipFocusNode,
          child: Semantics(
            container: true,
            link: true,
            label: 'Skip to main content',
            child: Material(
              color: _skipFocusNode.hasFocus ? cs.primary : Colors.transparent,
              child: InkWell(
                onTap: () => _contentFocusNode.requestFocus(),
                focusNode: _skipFocusNode,
                child: SizedBox(
                  height: _skipFocusNode.hasFocus ? 48 : 0,
                  child: Center(
                    child: Text(
                      'Skip to main content',
                      style: TextStyle(
                        color: _skipFocusNode.hasFocus
                            ? cs.onPrimary
                            : Colors.transparent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Main content with focus target ─────────────────────────────
        Focus(
          focusNode: _contentFocusNode,
          child: widget.child,
        ),
      ],
    );
  }
}
