/// Centralized authentication state providers for ExamForge AI.
///
/// This file is the **canonical import** for anything that needs to know
/// whether a user is signed in, who they are, or what role they have.
///
/// ```dart
/// import '../../shared/providers/auth_state_provider.dart';
///
/// final isAuth = ref.watch(isAuthenticatedProvider);
/// final user   = ref.watch(currentUserProvider);
/// final role   = ref.watch(resolvedUserRoleProvider);
/// ```
///
/// The core providers ([authStateProvider], [currentUserProvider],
/// [isAuthenticatedProvider], [userRoleProvider]) are defined in
/// [dependency_injection.dart] because they are needed during router
/// construction. This file **re-exports** them so that feature modules
/// have a single, semantic import path for all auth state, and adds
/// additional convenience providers on top.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../config/dependency_injection.dart';
import '../../config/supabase_config.dart';
import '../models/user_role.dart';

// ═══════════════════════════════════════════════════════════════════════
// RE-EXPORTS — Core Auth Providers from DI
// ═══════════════════════════════════════════════════════════════════════
// These four providers are the backbone of auth state across the app.
// They are re-exported here so that feature modules only need one import.

// ─── Auth State Stream ─────────────────────────────────────────────────

/// Stream provider that emits the current Supabase [sb.AuthState].
///
/// Automatically reconnects on transient failures and emits the latest
/// state to any listener. This is the foundation upon which all other
/// auth providers are built.
///
/// Emits a new value whenever the user:
/// - Signs in
/// - Signs out
/// - The access token is refreshed
/// - The session expires
///
/// Re-exported from [dependency_injection.dart].
export '../../config/dependency_injection.dart'
    show authStateProvider, currentUserProvider, isAuthenticatedProvider, userRoleProvider;

// ─── Current User (re-exported) ────────────────────────────────────────

/// The currently authenticated [sb.User], or `null` if not signed in.
///
/// While the [authStateProvider] stream is loading, this falls back to
/// the synchronous [SupabaseConfig.currentUser] getter so that the UI
/// never flashes an incorrect logged-out state during a hot restart.
///
/// Re-exported from [dependency_injection.dart].
// (Documentation only — provider is re-exported above.)

// ─── Is Authenticated (re-exported) ────────────────────────────────────

/// `true` when the user has a valid, non-expired session.
///
/// This is the simplest way to gate UI behind authentication:
/// ```dart
/// if (ref.watch(isAuthenticatedProvider)) { ... }
/// ```
///
/// Re-exported from [dependency_injection.dart].
// (Documentation only — provider is re-exported above.)

// ─── User Role — raw string from storage (re-exported) ────────────────

/// The user's role string as stored in secure storage.
///
/// Returns `'student'` as the default if no role is found (e.g. the
/// user signed up before role selection was implemented).
///
/// Because this reads from [StorageService] (async I/O), it is a
/// [FutureProvider]. For a synchronous, parsed [UserRole] see
/// [resolvedUserRoleProvider].
///
/// Re-exported from [dependency_injection.dart].
// (Documentation only — provider is re-exported above.)

// ═══════════════════════════════════════════════════════════════════════
// ADDITIONAL CONVENIENCE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// The user's [UserRole] resolved synchronously, or `null` if the role
/// is still loading or could not be parsed.
///
/// This is the provider that the router and route guards use for
/// role-based redirects. It combines the async [userRoleProvider] with
/// a synchronous fallback so that the router never has to `await`.
///
/// While [userRoleProvider] is loading, this attempts a quick lookup
/// from the Supabase user metadata `role` field as a fallback.
final resolvedUserRoleProvider = Provider<UserRole?>((ref) {
  final roleAsync = ref.watch(userRoleProvider);
  return roleAsync.when(
    data: UserRole.fromString,
    loading: () {
      // While storage is being read, attempt a quick lookup from the
      // Supabase user metadata as a fallback.
      final user = ref.read(currentUserProvider);
      final metaRole = user?.userMetadata?['role'] as String?;
      return UserRole.fromString(metaRole);
    },
    error: (_, __) => null,
  );
});

/// The current user's email address, or `null` if not signed in.
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// The current user's unique ID, or `null` if not signed in.
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

/// Whether the current user's email has been verified.
///
/// Returns `false` if the user is not authenticated or if
/// [sb.User.emailConfirmedAt] is `null`.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.emailConfirmedAt != null;
});

/// The user's full name from Supabase user metadata, or `null`.
final userFullNameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.userMetadata?['full_name'] as String?;
});

/// The user's avatar URL from Supabase user metadata, or `null`.
final userAvatarUrlProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.userMetadata?['avatar_url'] as String?;
});

/// The user's school ID from Supabase user metadata, or `null`.
final userSchoolIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.userMetadata?['school_id'] as String?;
});

/// The current Supabase session's access token, or `null` if not
/// authenticated.
///
/// Useful for constructing authenticated API requests outside of the
/// Supabase client (e.g. direct HTTP calls with [Dio]).
final accessTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.accessToken,
    loading: () => SupabaseConfig.accessToken,
    error: (_, __) => null,
  );
});

// ═══════════════════════════════════════════════════════════════════════
// AUTH STATE CHANGE EVENT HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// The most recent [sb.AuthChangeEvent] that fired.
///
/// Useful for one-shot side effects like:
/// - Navigating after sign-in
/// - Clearing caches on sign-out
/// - Triggering a token-refresh refresh
final lastAuthEventProvider = Provider<sb.AuthChangeEvent?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.event,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Whether the auth layer is currently in a loading state (i.e. the
/// initial auth state stream has not yet emitted a value).
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});
