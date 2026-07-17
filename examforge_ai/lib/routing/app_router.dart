import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/dependency_injection.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/dashboard/presentation/pages/dashboard_redirector.dart';
import '../features/dashboard/presentation/pages/dashboard_shell.dart';
import '../features/dashboard/presentation/pages/school_admin_dashboard_page.dart';
import '../features/dashboard/presentation/pages/student_dashboard_page.dart';
import '../features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import '../features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/question_bank/presentation/pages/question_bank_dashboard_page.dart';
import '../features/question_bank/presentation/pages/question_list_page.dart';
import '../features/question_bank/presentation/pages/question_editor_page.dart';
import '../features/question_bank/presentation/pages/question_detail_page.dart';
import '../features/question_bank/presentation/pages/question_import_page.dart';
import '../features/question_bank/presentation/pages/question_export_page.dart';
import '../features/question_bank/presentation/pages/collections_page.dart';
import 'route_guards.dart';
import 'route_names.dart';

// ═══════════════════════════════════════════════════════════════════════
// NAVIGATOR KEYS
// ═══════════════════════════════════════════════════════════════════════

/// Root navigator key — owns the top-level navigation stack.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key — owns the nested navigation stack inside the
/// [DashboardShell]. This allows the shell (sidebar / bottom nav) to
/// remain mounted while inner pages transition.
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ═══════════════════════════════════════════════════════════════════════
// APP ROUTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the application's [GoRouter].
///
/// Watches [authStateProvider] so that the router automatically
/// re-evaluates its [redirect] callback whenever the authentication
/// state changes (sign-in, sign-out, token refresh).
///
/// Usage in `main.dart`:
/// ```dart
/// final router = ref.read(appRouterProvider);
/// MaterialApp.router(routerConfig: router);
/// ```
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state so the router re-evaluates redirects on change.
  final authState = ref.watch(authStateProvider);

  // Also watch onboarding state and role so those redirects stay live.
  ref.watch(onboardingCompleteProvider);
  ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,

    // ─── Global Redirect ──────────────────────────────────────────
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      final isAuthenticated = authState.when(
        data: (authData) => authData.session != null,
        loading: () {
          // While loading, only allow splash. Everything else redirects
          // to splash so we don't flash the login page briefly.
          if (currentPath != RouteNames.splash) {
            return RouteNames.splash;
          }
          return null;
        },
        error: (_, __) => false,
      );

      // ── Auth Guard ────────────────────────────────────────────
      final authRedirect = AuthGuard.evaluate(
        isAuthenticated: isAuthenticated,
        currentPath: currentPath,
      );
      if (authRedirect != null) return authRedirect;

      // ── Onboarding Guard ─────────────────────────────────────
      final onboardingAsync = ref.read(onboardingCompleteProvider);
      final isOnboardingComplete = onboardingAsync.when(
        data: (complete) => complete,
        loading: () => true, // Assume complete while loading to avoid flicker.
        error: (_, __) => true,
      );

      final onboardingRedirect = OnboardingGuard.evaluate(
        isAuthenticated: isAuthenticated,
        isOnboardingComplete: isOnboardingComplete,
        currentPath: currentPath,
      );
      if (onboardingRedirect != null) return onboardingRedirect;

      // ── Role-Based Guard ─────────────────────────────────────
      final roleAsync = ref.read(userRoleProvider);
      final userRole = roleAsync.when(
        data: UserRole.fromString,
        loading: () => null,
        error: (_, __) => null,
      );

      final roleRedirect = RoleBasedGuard.evaluate(
        userRole: userRole,
        currentPath: currentPath,
      );
      if (roleRedirect != null) return roleRedirect;

      // No redirect needed — proceed as requested.
      return null;
    },

    // ─── Route Tree ───────────────────────────────────────────────
    routes: [
      // ── Splash ────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Onboarding ───────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Auth Routes ──────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // ── Protected Shell Route ─────────────────────────────────
      // All routes inside this shell share the [DashboardShell]
      // wrapper which provides the sidebar / bottom nav and app bar.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          // Dashboard with role-based sub-routes.
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardRedirector(),
            routes: [
              GoRoute(
                path: 'teacher',
                name: 'teacherDashboard',
                builder: (context, state) => const TeacherDashboardPage(),
              ),
              GoRoute(
                path: 'student',
                name: 'studentDashboard',
                builder: (context, state) => const StudentDashboardPage(),
              ),
              GoRoute(
                path: 'school-admin',
                name: 'schoolAdminDashboard',
                builder: (context, state) => const SchoolAdminDashboardPage(),
              ),
              GoRoute(
                path: 'super-admin',
                name: 'superAdminDashboard',
                builder: (context, state) => const SuperAdminDashboardPage(),
              ),
            ],
          ),

          // Profile.
          GoRoute(
            path: RouteNames.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),

          // Settings.
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),

          // Notifications.
          GoRoute(
            path: RouteNames.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),

          // ── Question Bank Routes ──────────────────────────────────
          GoRoute(
            path: RouteNames.questionBank,
            name: 'questionBank',
            builder: (context, state) => const QuestionBankDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankList,
            name: 'questionBankList',
            builder: (context, state) => const QuestionListPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankCreate,
            name: 'questionBankCreate',
            builder: (context, state) => const QuestionEditorPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankDetail,
            name: 'questionBankDetail',
            builder: (context, state) {
              final questionId = state.uri.queryParameters['id'] ?? '';
              return QuestionDetailPage(questionId: questionId);
            },
          ),
          GoRoute(
            path: RouteNames.questionBankEdit,
            name: 'questionBankEdit',
            builder: (context, state) {
              final questionId = state.uri.queryParameters['id'] ?? '';
              return QuestionEditorPage(questionId: questionId);
            },
          ),
          GoRoute(
            path: RouteNames.questionBankImport,
            name: 'questionBankImport',
            builder: (context, state) => const QuestionImportPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankExport,
            name: 'questionBankExport',
            builder: (context, state) => const QuestionExportPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankCollections,
            name: 'questionBankCollections',
            builder: (context, state) => const CollectionsPage(),
          ),
        ],
      ),
    ],

    // ─── Error / 404 Handler ──────────────────────────────────────
    errorBuilder: (context, state) => NotFoundPage(
      error: state.error,
      path: state.matchedLocation,
    ),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// NOT FOUND PAGE (404)
// ═══════════════════════════════════════════════════════════════════════

/// Shown when the user navigates to a route that does not exist in
/// the route tree.
///
/// Provides a friendly message and a button to navigate back to the
/// dashboard (or login if unauthenticated).
class NotFoundPage extends ConsumerWidget {
  const NotFoundPage({
    required this.error,
    this.path,
    super.key,
  });

  /// The [GoException] from GoRouter describing the error.
  final GoException? error;

  /// The unmatched path the user attempted to visit.
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (path != null)
                Text(
                  'The page "$path" does not exist.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(
                  isAuthenticated
                      ? RouteNames.dashboard
                      : RouteNames.login,
                ),
                icon: const Icon(Icons.home),
                label: Text(
                  isAuthenticated ? 'Go to Dashboard' : 'Go to Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
