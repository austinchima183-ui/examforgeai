import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/logger.dart';
import '../../../../routing/route_guards.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROFILE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the profile feature.
class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.updateSuccess = false,
  });

  /// The current user's Supabase user object.
  final sb.User? user;

  /// Whether the profile is being loaded.
  final bool isLoading;

  /// Whether a profile update is in progress.
  final bool isUpdating;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the last update operation was successful.
  final bool updateSuccess;

  /// Derived display name from user metadata.
  String get displayName =>
      user?.userMetadata?['full_name'] as String? ?? 'User';

  /// Derived email address.
  String get email => user?.email ?? 'No email';

  /// Derived phone number.
  String get phone => user?.userMetadata?['phone'] as String? ?? '';

  /// Derived avatar URL.
  String? get avatarUrl =>
      user?.userMetadata?['avatar_url'] as String?;

  /// Derived role string.
  String get role {
    final roleStr = user?.userMetadata?['role'] as String?;
    if (roleStr == null) return 'Unknown';
    final userRole = UserRole.fromString(roleStr);
    return userRole?.label ?? roleStr;
  }

  /// Creates a copy of this state with the given fields replaced.
  ProfileState copyWith({
    sb.User? user,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool? updateSuccess,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      updateSuccess: updateSuccess ?? this.updateSuccess,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROFILE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the profile feature's state.
///
/// Handles loading the current user profile, updating profile fields,
/// and changing the password through [AuthService].
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required Ref ref,
  })  : _ref = ref,
        super(const ProfileState()) {
    _loadProfile();
  }

  final Ref _ref;

  // ─── Load Profile ────────────────────────────────────────────────

  /// Loads the current user profile from the auth service.
  void _loadProfile() {
    try {
      final authService = _ref.read(authServiceProvider);
      final user = authService.getCurrentUser();
      state = state.copyWith(user: user);
      AppLogger.info('Profile loaded for user: ${user?.id}');
    } catch (e) {
      AppLogger.error('Failed to load profile', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile.',
      );
    }
  }

  /// Reloads the profile from the auth service.
  void reloadProfile() {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = _ref.read(authServiceProvider);
      final user = authService.getCurrentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
      AppLogger.info('Profile reloaded');
    } catch (e) {
      AppLogger.error('Failed to reload profile', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reload profile.',
      );
    }
  }

  // ─── Update Profile ──────────────────────────────────────────────

  /// Updates the user's profile metadata (name, phone, avatar).
  ///
  /// Only non-null fields will be updated on the server.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isUpdating: true, error: null, updateSuccess: false);

    try {
      final authService = _ref.read(authServiceProvider);
      final updatedUser = await authService.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        user: updatedUser,
        isUpdating: false,
        updateSuccess: true,
        error: null,
      );

      AppLogger.info('Profile updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update profile', error: e);
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update profile. Please try again.',
        updateSuccess: false,
      );
    }
  }

  // ─── Change Password ─────────────────────────────────────────────

  /// Changes the user's password after verifying the current password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final authService = _ref.read(authServiceProvider);
      await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(
        isUpdating: false,
        updateSuccess: true,
        error: null,
      );

      AppLogger.info('Password changed successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to change password', error: e);
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to change password. Please verify your current password.',
        updateSuccess: false,
      );
      return false;
    }
  }

  // ─── Clear State ─────────────────────────────────────────────────

  /// Clears the error and update success flags.
  void clearStatus() {
    state = state.copyWith(error: null, updateSuccess: false);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider that holds the current [ProfileState].
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref: ref),
);

/// Convenience provider that watches the current user's display name.
final profileDisplayNameProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).displayName;
});
