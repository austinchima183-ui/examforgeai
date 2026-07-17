# Task: Create Main Entry Points - ExamForge AI Flutter

## Task ID: main-entry-points-001
## Agent: main-agent

## Summary
Created the 4 main entry point files that wire together the ExamForge AI Flutter application:

### Files Created

1. **`lib/main.dart`** (3,308 bytes)
   - `WidgetsFlutterBinding.ensureInitialized()` 
   - `SystemChrome.setPreferredOrientations()` for all 4 orientations
   - `SystemChrome.setSystemUIOverlayStyle()` for transparent status bar
   - Bootstrap sequence: EnvConfig → SupabaseConfig → AppConfig (with try-catch for graceful degradation)
   - Global `ProviderContainer` via `UncontrolledProviderScope`
   - `globalContainer` late field for out-of-widget-tree access

2. **`lib/app.dart`** (5,333 bytes)
   - `ConsumerStatefulWidget` with `WidgetsBindingObserver`
   - `_initializeNotificationService()` in `initState` (fire-and-forget, non-blocking)
   - `didChangeAppLifecycleState` for auth state freshness on resume
   - Watches `themeModeProvider` + `themeProvider` for reactive theme/dynamic seed color
   - Watches `appRouterProvider` for GoRouter rebuilds on auth state changes
   - `MaterialApp.router` with title, debug banner off, theme/darkTheme/themeMode, routerConfig
   - `MediaQuery.withClampedTextScaling` builder (0.8–1.5 range)

3. **`lib/shared/models/user_role.dart`** (4,653 bytes)
   - Re-exports `UserRole` and `currentRoleProvider` from `route_guards.dart`
   - `UserRoleX` extension: `storageKey`, `isAdmin`, `isTeacher`, `canManageUsers`, `canManageExams`, `canViewAnalytics`, `canTakeExams`, `description`
   - Helper functions: `parseUserRoleOrDefault()`, `rolesByPrivilege`, `rolesAtOrAbove()`

4. **`lib/shared/providers/auth_state_provider.dart`** (8,666 bytes)
   - Re-exports 4 core providers from `dependency_injection.dart`: `authStateProvider`, `currentUserProvider`, `isAuthenticatedProvider`, `userRoleProvider`
   - Additional convenience providers:
     - `resolvedUserRoleProvider` — synchronous UserRole? with metadata fallback
     - `userEmailProvider`, `userIdProvider`
     - `isEmailVerifiedProvider`
     - `userFullNameProvider`, `userAvatarUrlProvider`, `userSchoolIdProvider`
     - `accessTokenProvider`
     - `lastAuthEventProvider`, `authLoadingProvider`

### Bug Fix Applied
- Renamed `networkInfoProvider` → `coreNetworkInfoProvider` in `core/network/network_info.dart` to fix the missing reference in `dependency_injection.dart` that was referencing `coreNetworkInfoProvider` which didn't exist.
