import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/errors/exceptions.dart';
import '../core/utils/logger.dart';
import 'storage_service.dart';

/// High-level authentication service that wraps Supabase Auth and
/// coordinates with [StorageService] for token / user persistence.
///
/// Every method maps low-level Supabase exceptions into domain-level
/// exceptions from the core error hierarchy, so callers never need
/// to deal with Supabase-specific error codes.
///
/// ```dart
/// final authService = AuthService(supabaseClient, storageService);
/// final user = await authService.signUp(
///   email: 'user@example.com',
///   password: 'secret123',
///   fullName: 'Jane Doe',
///   role: 'student',
/// );
/// ```
class AuthService {
  AuthService({
    required sb.SupabaseClient supabaseClient,
    required StorageService storageService,
  })  : _supabase = supabaseClient,
        _storage = storageService;

  final sb.SupabaseClient _supabase;
  final StorageService _storage;

  // ─── Sign Up ────────────────────────────────────────────────────

  /// Registers a new user with [email] and [password].
  ///
  /// [fullName] and [role] are stored in the user's `raw_user_meta_data`
  /// so they are available immediately after sign-up. [schoolId] is
  /// optional and links the user to a specific school.
  ///
  /// On success, persists the session tokens and user metadata to
  /// secure storage and returns the [sb.User].
  ///
  /// Throws [AuthException] on Supabase auth errors, or
  /// [ServerException] on unexpected failures.
  Future<sb.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  }) async {
    try {
      final metadata = <String, dynamic>{
        'full_name': fullName,
        'role': role,
      };
      if (schoolId != null) {
        metadata['school_id'] = schoolId;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          message: 'Sign-up succeeded but no user was returned.',
          code: 'no_user_returned',
        );
      }

      // Persist session data.
      await _persistSession(response.session);

      AppLogger.info('User signed up: ${user.id}');
      return user;
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } on FormatException catch (e) {
      throw AuthException(
        message: e.message,
        code: 'invalid_format',
      );
    } catch (e) {
      AppLogger.error('Unexpected sign-up error', error: e);
      throw const AuthException(
        message: 'An unexpected error occurred during sign-up.',
        code: 'sign_up_failed',
      );
    }
  }

  // ─── Login ──────────────────────────────────────────────────────

  /// Authenticates an existing user with [email] and [password].
  ///
  /// On success, persists the session and returns the [sb.User].
  Future<sb.User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          message: 'Login succeeded but no user was returned.',
          code: 'no_user_returned',
        );
      }

      await _persistSession(response.session);

      AppLogger.info('User logged in: ${user.id}');
      return user;
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected login error', error: e);
      throw const AuthException(
        message: 'An unexpected error occurred during login.',
        code: 'login_failed',
      );
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────

  /// Signs the user out and clears all locally stored sensitive data.
  ///
  /// Even if the Supabase sign-out call fails, local data is still
  /// cleared so the device is in a clean state.
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.info('User signed out via Supabase');
    } on sb.AuthException catch (e) {
      AppLogger.warning('Supabase sign-out failed, clearing local: ${e.message}');
    } catch (e) {
      AppLogger.warning('Unexpected sign-out error, clearing local: $e');
    } finally {
      // Always clear local storage regardless of Supabase result.
      await _storage.clearSensitiveData();
    }
  }

  // ─── Forgot Password ────────────────────────────────────────────

  /// Sends a password-reset email to [email].
  ///
  /// The email contains a deep link that directs the user to the
  /// reset-password screen in the app.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.examforge.ai://reset-password',
      );
      AppLogger.info('Password reset email sent');
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected forgot-password error', error: e);
      throw const AuthException(
        message: 'Failed to send password reset email.',
        code: 'forgot_password_failed',
      );
    }
  }

  // ─── Reset Password ─────────────────────────────────────────────

  /// Resets the user's password to [newPassword] using the recovery
  /// [token] that was embedded in the password-reset deep link.
  ///
  /// Supabase handles the token verification internally when the
  /// session is already established via the deep link. If the session
  /// is not yet available, call [verifyEmail] first or rely on the
  /// deep-link handler to establish the session.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // In the Supabase Flutter SDK, the session is already established
      // when the user taps the deep link. We just need to update the
      // password.
      final response = await _supabase.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw const AuthException(
          message: 'Password reset failed — no user in session.',
          code: 'reset_password_failed',
        );
      }

      AppLogger.info('Password reset successful for user: ${response.user!.id}');
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected reset-password error', error: e);
      throw const AuthException(
        message: 'Failed to reset password.',
        code: 'reset_password_failed',
      );
    }
  }

  // ─── Verify Email ───────────────────────────────────────────────

  /// Verifies the user's email address using the [token] from the
  /// verification deep link.
  ///
  /// In the Supabase Flutter SDK, the token exchange happens
  /// automatically when the deep link is processed. This method
  /// confirms that the current session has a verified email.
  Future<void> verifyEmail({required String token}) async {
    try {
      // The Supabase SDK handles PKCE token exchange via
      // `session.fromUri()`. We verify the result here.
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw const AuthException(
          message: 'No active session. Please open the verification link from your email.',
          code: 'no_session',
        );
      }

      final user = session.user;
      final confirmedAt = user.emailConfirmedAt;
      if (confirmedAt == null) {
        throw const AuthException(
          message: 'Email verification is still pending.',
          code: 'email_not_verified',
        );
      }

      AppLogger.info('Email verified for user: ${user.id}');
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected email verification error', error: e);
      throw const AuthException(
        message: 'Failed to verify email.',
        code: 'verify_email_failed',
      );
    }
  }

  // ─── Resend Verification ────────────────────────────────────────

  /// Resends the email verification link to [email].
  Future<void> resendVerification({required String email}) async {
    try {
      await _supabase.auth.resend(
        type: sb.OtpType.signup,
        email: email,
      );
      AppLogger.info('Verification email resent');
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected resend verification error', error: e);
      throw const AuthException(
        message: 'Failed to resend verification email.',
        code: 'resend_verification_failed',
      );
    }
  }

  // ─── Current User / Session ─────────────────────────────────────

  /// Returns the currently authenticated [sb.User], or `null`.
  sb.User? getCurrentUser() {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      AppLogger.error('Failed to get current user', error: e);
      return null;
    }
  }

  /// Returns the current [sb.Session], or `null`.
  sb.Session? getCurrentSession() {
    try {
      return _supabase.auth.currentSession;
    } catch (e) {
      AppLogger.error('Failed to get current session', error: e);
      return null;
    }
  }

  /// `true` if there is an active, non-expired session.
  bool get isAuthenticated {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < expiresAt;
  }

  // ─── Auth State Stream ──────────────────────────────────────────

  /// A stream of [sb.AuthState] changes (sign-in, sign-out, token refresh).
  ///
  /// Use this to reactively update UI based on auth status.
  Stream<sb.AuthState> get onAuthStateChanged =>
      _supabase.auth.onAuthStateChange;

  // ─── Update Profile ─────────────────────────────────────────────

  /// Updates the current user's profile metadata.
  ///
  /// Only non-null fields will be updated.
  Future<sb.User> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (phone != null) data['phone'] = phone;

      final response = await _supabase.auth.updateUser(
        sb.UserAttributes(data: data),
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          message: 'Profile update succeeded but no user was returned.',
          code: 'no_user_returned',
        );
      }

      AppLogger.info('Profile updated for user: ${user.id}');
      return user;
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected profile update error', error: e);
      throw const AuthException(
        message: 'Failed to update profile.',
        code: 'update_profile_failed',
      );
    }
  }

  // ─── Change Password ────────────────────────────────────────────

  /// Changes the current user's password from [currentPassword] to
  /// [newPassword].
  ///
  /// First validates [currentPassword] by re-authenticating, then
  /// updates to [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw const AuthException(
          message: 'You must be logged in to change your password.',
          code: 'not_authenticated',
        );
      }

      // Re-authenticate to verify the current password.
      final email = session.user.email;
      if (email == null) {
        throw const AuthException(
          message: 'No email associated with this account.',
          code: 'no_email',
        );
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update to the new password.
      await _supabase.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      AppLogger.info('Password changed for user: ${session.user.id}');
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected change-password error', error: e);
      throw const AuthException(
        message: 'Failed to change password.',
        code: 'change_password_failed',
      );
    }
  }

  // ─── Magic Link / OTP ───────────────────────────────────────────

  /// Sends a magic link (passwordless sign-in) to [email].
  Future<void> sendMagicLink({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.examforge.ai://login-callback',
      );
      AppLogger.info('Magic link sent');
    } on sb.AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected magic-link error', error: e);
      throw const AuthException(
        message: 'Failed to send magic link.',
        code: 'magic_link_failed',
      );
    }
  }

  // ─── Refresh Session ────────────────────────────────────────────

  /// Refreshes the current session using the stored refresh token.
  ///
  /// Returns the refreshed [sb.Session], or `null` on failure.
  Future<sb.Session?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      final session = response.session;
      if (session != null) {
        await _persistSession(session);
      }
      AppLogger.info('Session refreshed');
      return session;
    } on sb.AuthException catch (e) {
      AppLogger.error('Session refresh failed', error: e);
      await _storage.clearSensitiveData();
      return null;
    } catch (e) {
      AppLogger.error('Unexpected session refresh error', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Persists the relevant session data to secure storage.
  Future<void> _persistSession(sb.Session? session) async {
    if (session == null) return;

    await _storage.saveTokenPair(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    await _storage.saveUserId(session.user.id);

    final role = session.user.userMetadata?['role'] as String?;
    if (role != null) {
      await _storage.saveUserRole(role);
    }
  }

  /// Maps a Supabase [sb.AuthException] to a domain [AuthException] with
  /// a user-friendly message and a stable error code.
  AuthException _mapSupabaseAuthException(sb.AuthException e) {
    final code = e.code ?? 'unknown';
    final message = _friendlyMessage(code, e.message);

    AppLogger.warning('Auth error — code: $code, message: ${e.message}');
    return AuthException(message: message, code: code);
  }

  /// Converts Supabase error codes into human-readable messages.
  String _friendlyMessage(String code, String original) {
    return switch (code) {
      'invalid_credentials' ||
      'invalid_grant' =>
        'Invalid email or password. Please try again.',
      'email_not_confirmed' =>
        'Your email has not been verified. Please check your inbox.',
      'user_already_exists' =>
        'An account with this email already exists.',
      'weak_password' =>
        'Your password is too weak. Please choose a stronger password.',
      'email_address_invalid' =>
        'The email address format is invalid.',
      'too_many_requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'signup_disabled' =>
        'New account registration is currently disabled.',
      'session_expired' =>
        'Your session has expired. Please sign in again.',
      'refresh_token_not_found' ||
      'refresh_token_invalid' =>
        'Your session is no longer valid. Please sign in again.',
      'network_request_failed' =>
        'Network error. Please check your connection and try again.',
      'reauthentication_required' =>
        'Please sign in again to confirm your identity.',
      'same_password' =>
        'The new password must be different from the current one.',
      'password_strength' =>
        'Password does not meet the required strength.',
      _ => 'An authentication error occurred. Please try again.',
    };
  }
}
