import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Abstract interface for remote authentication data operations.
///
/// Implementations handle all network communication with the Supabase
/// Auth API and return plain [UserModel] instances. Exceptions are
/// allowed to propagate so the repository layer can catch and convert
/// them to domain [Failure] types.
abstract class AuthRemoteDataSource {
  /// Authenticates a user with [email] and [password].
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Registers a new user account.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  });

  /// Sends a password-reset email to [email].
  Future<void> forgotPassword({required String email});

  /// Resets the user's password using a recovery [token].
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Verifies the user's email address using a verification [token].
  Future<void> verifyEmail({required String token});

  /// Resends the email verification link to [email].
  Future<void> resendVerification({required String email});

  /// Returns the currently authenticated user, or `null`.
  UserModel? getCurrentUser();

  /// Signs the user out from Supabase.
  Future<void> logout();
}

/// Supabase-backed implementation of [AuthRemoteDataSource].
///
/// Every method maps Supabase-specific responses and errors into the
/// domain-agnostic types defined in the data layer. Supabase
/// [sb.AuthException] instances are converted to our [AuthException]
/// with user-friendly messages.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required sb.SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Login ──────────────────────────────────────────────────────

  @override
  Future<UserModel> login({
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

      AppLogger.info('User logged in: ${user.id}');
      return _mapSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
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

  // ─── Sign Up ────────────────────────────────────────────────────

  /// SECURITY: The [role] parameter is accepted for interface compatibility
  /// but is **always overridden to 'student'**. Self-service registration
  /// can only create student accounts. Role elevation (teacher, schoolAdmin)
  /// must happen through invite codes or admin approval — never via
  /// self-service registration.
  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  }) async {
    try {
      // SECURITY: Force role to 'student' regardless of what the client sends.
      // The server should also enforce this, but we hardcode it here as a
      // defense-in-depth measure.
      const enforcedRole = 'student';

      final metadata = <String, dynamic>{
        'full_name': fullName,
        'role': enforcedRole,
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

      AppLogger.info('User signed up: ${user.id}');
      return _mapSupabaseUser(user);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected sign-up error', error: e);
      throw const AuthException(
        message: 'An unexpected error occurred during sign-up.',
        code: 'sign_up_failed',
      );
    }
  }

  // ─── Forgot Password ────────────────────────────────────────────

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.examforge.ai://reset-password',
      );
      AppLogger.info('Password reset email sent to: $email');
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
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

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw const AuthException(
          message: 'Password reset failed — no user in session.',
          code: 'reset_password_failed',
        );
      }

      AppLogger.info(
          'Password reset successful for user: ${response.user!.id}');
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
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

  @override
  Future<void> verifyEmail({required String token}) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw const AuthException(
          message:
              'No active session. Please open the verification link from your email.',
          code: 'no_session',
        );
      }

      final user = session.user;
      if (user.emailConfirmedAt == null) {
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

  @override
  Future<void> resendVerification({required String email}) async {
    try {
      await _supabase.auth.resend(
        type: sb.OtpType.signup,
        email: email,
      );
      AppLogger.info('Verification email resent to: $email');
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
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

  // ─── Current User ───────────────────────────────────────────────

  @override
  UserModel? getCurrentUser() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      return _mapSupabaseUser(user);
    } catch (e) {
      AppLogger.error('Failed to get current user', error: e);
      return null;
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.info('User signed out via Supabase');
    } on sb.AuthException catch (e) {
      AppLogger.warning(
          'Supabase sign-out failed, clearing local: ${e.message}');
    } catch (e) {
      AppLogger.warning('Unexpected sign-out error, clearing local: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a Supabase [sb.User] to our [UserModel].
  UserModel _mapSupabaseUser(sb.User user) {
    return UserModel.fromSupabaseUser(
      user.id,
      user.email ?? '',
      userMetadata: user.userMetadata,
      emailConfirmedAt: user.emailConfirmedAt,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
    );
  }

  /// Maps a Supabase [sb.AuthException] to a domain [AuthException].
  AuthException _mapAuthException(sb.AuthException e) {
    final code = e.code ?? 'unknown';
    final message = _friendlyMessage(code, e.message);

    AppLogger.warning('Auth error — code: $code, message: ${e.message}');
    return AuthException(message: message, code: code);
  }

  /// Converts Supabase error codes into human-readable messages.
  String _friendlyMessage(String code, String original) {
    return switch (code) {
      'invalid_credentials' || 'invalid_grant' =>
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
      'refresh_token_not_found' || 'refresh_token_invalid' =>
        'Your session is no longer valid. Please sign in again.',
      'network_request_failed' =>
        'Network error. Please check your connection and try again.',
      'reauthentication_required' =>
        'Please sign in again to confirm your identity.',
      'same_password' =>
        'The new password must be different from the current one.',
      'password_strength' =>
        'Password does not meet the required strength.',
      _ => original.isNotEmpty
          ? original
          : 'An authentication error occurred. Please try again.',
    };
  }
}
