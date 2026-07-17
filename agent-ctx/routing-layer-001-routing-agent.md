# Task: ExamForge AI Routing Layer Implementation

## Task ID: routing-layer-001

## Summary
Implemented the complete Routing layer with GoRouter for the ExamForge AI Flutter project, including all 3 required files plus 15 supporting page files for import resolution.

## Files Created

### Core Routing Files (3)
1. **`lib/routing/route_names.dart`** — Centralized route name constants with helper sets (`publicRoutes`, `dashboardRoutes`, `protectedRoutes`)
2. **`lib/routing/route_guards.dart`** — Full guard system with `UserRole` enum, `AuthGuard`, `OnboardingGuard`, `RoleBasedGuard`, `RouteGuardEvaluator`, `currentRoleProvider`, `onboardingCompleteProvider`
3. **`lib/routing/app_router.dart`** — Complete GoRouter configuration with `appRouterProvider`, `ShellRoute` for dashboard layout, global redirect logic, inline `NotFoundPage`, and `DashboardRedirector` reference

### Supporting Page Files (15)
- `lib/features/splash/presentation/splash_page.dart`
- `lib/features/onboarding/presentation/onboarding_page.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/register_page.dart`
- `lib/features/auth/presentation/forgot_password_page.dart`
- `lib/features/auth/presentation/verify_email_page.dart`
- `lib/features/auth/presentation/reset_password_page.dart`
- `lib/features/dashboard/presentation/dashboard_redirector.dart`
- `lib/features/dashboard/presentation/dashboard_shell.dart`
- `lib/features/dashboard/presentation/teacher_dashboard_page.dart`
- `lib/features/dashboard/presentation/student_dashboard_page.dart`
- `lib/features/dashboard/presentation/school_admin_dashboard_page.dart`
- `lib/features/dashboard/presentation/super_admin_dashboard_page.dart`
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/settings/presentation/settings_page.dart`
- `lib/features/notifications/presentation/notifications_page.dart`

## Architecture Decisions
- **Guard ordering**: Auth → Onboarding → Role-based (in priority order)
- **ShellRoute**: Used for dashboard layout with NavigationRail (desktop ≥600px) / NavigationBar (mobile) / Drawer
- **DashboardRedirector**: Reads user role from `userRoleProvider` and navigates to role-specific dashboard using `addPostFrameCallback`
- **Role hierarchy**: student (0) < teacher (1) < school-admin (2) < super-admin (3) with cascading dashboard access
- **Onboarding guard**: Defaults to `true` during loading to avoid onboarding flicker on app restart
- **Auth loading**: Redirects to splash during auth state loading to prevent login page flash

## Provider Dependencies
- `authStateProvider` (from `dependency_injection.dart`) — watched by router for reactive redirects
- `isAuthenticatedProvider` (from `dependency_injection.dart`) — used in NotFoundPage
- `userRoleProvider` (from `dependency_injection.dart`) — watched by router and DashboardRedirector
- `onboardingCompleteProvider` (from `route_guards.dart`) — FutureProvider reading from StorageService
- `currentRoleProvider` (from `route_guards.dart`) — convenience Provider wrapping userRoleProvider
