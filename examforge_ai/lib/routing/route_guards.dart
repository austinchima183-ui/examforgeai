import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dependency_injection.dart';
import '../core/utils/logger.dart';
import 'route_names.dart';

// ═══════════════════════════════════════════════════════════════════════
// USER ROLE ENUM
// ═══════════════════════════════════════════════════════════════════════

/// Represents every possible user role in ExamForge AI.
///
/// The [value] property matches the string stored in Supabase
/// `raw_user_meta_data.role` and in [StorageService] so that
/// serialization / deserialization is trivial.
enum UserRole {
  teacher('teacher'),
  student('student'),
  schoolAdmin('school-admin'),
  superAdmin('super-admin');

  const UserRole(this.value);

  /// The string representation stored in the backend and secure storage.
  final String value;

  /// Parses a raw [value] string into a [UserRole].
  ///
  /// Returns `null` if the value does not match any known role.
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    return UserRole.values.cast<UserRole?>().firstWhere(
          (role) => role?.value == value,
          orElse: () => null,
        );
  }

  /// Returns the dashboard route associated with this role.
  String get dashboardRoute => switch (this) {
        UserRole.teacher => RouteNames.teacherDashboard,
        UserRole.student => RouteNames.studentDashboard,
        UserRole.schoolAdmin => RouteNames.schoolAdminDashboard,
        UserRole.superAdmin => RouteNames.superAdminDashboard,
      };

  /// A human-readable label for display in the UI.
  String get label => switch (this) {
        UserRole.teacher => 'Teacher',
        UserRole.student => 'Student',
        UserRole.schoolAdmin => 'School Admin',
        UserRole.superAdmin => 'Super Admin',
      };

  /// The privilege level of this role, where a higher number means
  /// more permissions. Useful for hierarchical access checks.
  int get privilegeLevel => switch (this) {
        UserRole.student => 0,
        UserRole.teacher => 1,
        UserRole.schoolAdmin => 2,
        UserRole.superAdmin => 3,
      };
}

// ═══════════════════════════════════════════════════════════════════════
// ROLE-BASED ACCESS MAP
// ═══════════════════════════════════════════════════════════════════════

/// Maps each [UserRole] to the set of routes that the role is allowed
/// to access. Routes not listed here are accessible to all
/// authenticated users.
///
/// Routes inside the [ShellRoute] that are **not** in any role's
/// restricted set are considered universally accessible (e.g.
/// [RouteNames.profile], [RouteNames.settings]).
final Map<UserRole, Set<String>> _roleRestrictedRoutes = {
  UserRole.teacher: {
    RouteNames.teacherDashboard,
  },
  UserRole.student: {
    RouteNames.studentDashboard,
  },
  UserRole.schoolAdmin: {
    RouteNames.schoolAdminDashboard,
    RouteNames.teacherDashboard,
    RouteNames.studentDashboard,
  },
  UserRole.superAdmin: {
    RouteNames.superAdminDashboard,
    RouteNames.schoolAdminDashboard,
    RouteNames.teacherDashboard,
    RouteNames.studentDashboard,
  },
};

// ═══════════════════════════════════════════════════════════════════════
// AUTH GUARD
// ═══════════════════════════════════════════════════════════════════════

/// Guard that enforces authentication requirements for routes.
///
/// Unauthenticated users attempting to visit a protected route are
/// redirected to the login page. Authenticated users on a public
/// route (except splash) are redirected to the dashboard.
class AuthGuard {
  AuthGuard._();

  /// Evaluates the authentication redirect logic.
  ///
  /// Returns a redirect path if a redirect is needed, or `null` if
  /// the current navigation should proceed unchanged.
  ///
  /// [isAuthenticated] — whether the user has a valid session.
  /// [currentPath] — the `matchedLocation` from [GoRouterState].
  static String? evaluate({
    required bool isAuthenticated,
    required String currentPath,
  }) {
    final isPublicRoute = RouteNames.publicRoutes.contains(currentPath);

    // Unauthenticated users must go to a public route.
    if (!isAuthenticated && !isPublicRoute) {
      AppLogger.info('AuthGuard: unauthenticated user redirected to login '
          'from $currentPath');
      return RouteNames.login;
    }

    // Authenticated users on a public route (except splash) should go
    // to the dashboard. Splash is allowed so the splash screen can
    // run its animation before navigating.
    if (isAuthenticated && isPublicRoute && currentPath != RouteNames.splash) {
      AppLogger.info('AuthGuard: authenticated user redirected to dashboard '
          'from $currentPath');
      return RouteNames.dashboard;
    }

    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING GUARD
// ═══════════════════════════════════════════════════════════════════════

/// Guard that enforces onboarding completion before accessing
/// protected routes.
///
/// Newly registered users must complete the onboarding flow before
/// they can reach the dashboard or any other authenticated page.
class OnboardingGuard {
  OnboardingGuard._();

  /// Evaluates the onboarding redirect logic.
  ///
  /// Returns a redirect path if a redirect is needed, or `null` if
  /// the current navigation should proceed unchanged.
  ///
  /// [isAuthenticated] — whether the user has a valid session.
  /// [isOnboardingComplete] — whether the user has finished onboarding.
  /// [currentPath] — the `matchedLocation` from [GoRouterState].
  static String? evaluate({
    required bool isAuthenticated,
    required bool isOnboardingComplete,
    required String currentPath,
  }) {
    // Only evaluate after the user is authenticated.
    if (!isAuthenticated) return null;

    // If onboarding is not complete, force the onboarding route.
    if (!isOnboardingComplete && currentPath != RouteNames.onboarding) {
      AppLogger.info('OnboardingGuard: user redirected to onboarding '
          'from $currentPath');
      return RouteNames.onboarding;
    }

    // If onboarding IS complete and user is still on the onboarding
    // route, redirect to the dashboard.
    if (isOnboardingComplete && currentPath == RouteNames.onboarding) {
      AppLogger.info('OnboardingGuard: onboarding complete, '
          'redirecting to dashboard');
      return RouteNames.dashboard;
    }

    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ROLE-BASED GUARD
// ═══════════════════════════════════════════════════════════════════════

/// Guard that enforces role-based access control on routes.
///
/// Certain routes (e.g. dashboard sub-routes) are restricted to users
/// with the appropriate role. This guard checks whether the current
/// user's role grants access to the requested route and redirects to
/// the user's own dashboard if not.
class RoleBasedGuard {
  RoleBasedGuard._();

  /// Evaluates the role-based redirect logic.
  ///
  /// Returns a redirect path if a redirect is needed, or `null` if
  /// the current navigation should proceed unchanged.
  ///
  /// [userRole] — the current user's role, or `null` if unknown.
  /// [currentPath] — the `matchedLocation` from [GoRouterState].
  static String? evaluate({
    required UserRole? userRole,
    required String currentPath,
  }) {
    // If we can't determine the role, allow navigation but log a
    // warning. The auth guard will handle unauthenticated users.
    if (userRole == null) {
      AppLogger.warning('RoleBasedGuard: user role is null, '
          'allowing access to $currentPath');
      return null;
    }

    // If the route is not role-restricted, allow access.
    if (!canAccess(userRole, currentPath)) {
      AppLogger.info('RoleBasedGuard: ${userRole.value} denied access to '
          '$currentPath, redirecting to ${userRole.dashboardRoute}');
      return userRole.dashboardRoute;
    }

    return null;
  }

  /// Returns `true` if [role] is allowed to access [route].
  ///
  /// Non-restricted routes (those not listed in any role's restricted
  /// set) are accessible to all authenticated users.
  static bool canAccess(UserRole role, String route) {
    // Check if this route is in anyone's restricted list.
    final isRestricted = _roleRestrictedRoutes.values
        .any((routes) => routes.contains(route));

    // If the route is not restricted, anyone can access it.
    if (!isRestricted) return true;

    // Otherwise, check whether this role's set includes the route.
    final allowedRoutes = _roleRestrictedRoutes[role];
    return allowedRoutes != null && allowedRoutes.contains(route);
  }

  /// Returns the set of routes accessible to [role].
  static Set<String> accessibleRoutes(UserRole role) {
    final restricted = _roleRestrictedRoutes[role] ?? <String>{};
    // All non-restricted routes + role-specific restricted routes.
    final nonRestricted = RouteNames.protectedRoutes.where(
      (route) => !_roleRestrictedRoutes.values
          .expand((routes) => routes)
          .toSet()
          .contains(route),
    );
    return {...nonRestricted, ...restricted};
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COMPOSITE GUARD EVALUATOR
// ═══════════════════════════════════════════════════════════════════════

/// Runs all guards in priority order and returns the first non-null
/// redirect, or `null` if no redirect is needed.
///
/// Guard evaluation order matters:
/// 1. [AuthGuard] — authentication is the most fundamental check.
/// 2. [OnboardingGuard] — onboarding must complete before any
///    protected content is shown.
/// 3. [RoleBasedGuard] — role checks only make sense for
///    authenticated, onboarded users.
class RouteGuardEvaluator {
  RouteGuardEvaluator._();

  /// Runs the full guard pipeline.
  ///
  /// [ref] is the Riverpod [Ref] used to read providers.
  /// [currentPath] is the `matchedLocation` from [GoRouterState].
  static String? evaluateAll(Ref ref, String currentPath) {
    // ── 1. Auth Guard ──────────────────────────────────────────────
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final authRedirect = AuthGuard.evaluate(
      isAuthenticated: isAuthenticated,
      currentPath: currentPath,
    );
    if (authRedirect != null) return authRedirect;

    // Only run the remaining guards if the user is authenticated.
    if (!isAuthenticated) return null;

    // ── 2. Onboarding Guard ────────────────────────────────────────
    final onboardingAsync = ref.read(onboardingCompleteProvider);
    final isOnboardingComplete = onboardingAsync.when(
      data: (complete) => complete,
      loading: () => false,
      error: (_, __) => false,
    );

    final onboardingRedirect = OnboardingGuard.evaluate(
      isAuthenticated: isAuthenticated,
      isOnboardingComplete: isOnboardingComplete,
      currentPath: currentPath,
    );
    if (onboardingRedirect != null) return onboardingRedirect;

    // ── 3. Role-Based Guard ────────────────────────────────────────
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

    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS FOR GUARD DATA
// ═══════════════════════════════════════════════════════════════════════

/// Provider that resolves the current user's [UserRole] from secure
/// storage. Returns `null` if the role cannot be determined.
final currentRoleProvider = Provider<UserRole?>((ref) {
  final roleAsync = ref.watch(userRoleProvider);
  return roleAsync.when(
    data: UserRole.fromString,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider that checks whether the onboarding flow has been completed.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.isOnboardingComplete();
});
