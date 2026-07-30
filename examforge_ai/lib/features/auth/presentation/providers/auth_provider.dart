import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the auth feature.
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.emailVerificationSent = false,
    this.passwordResetSent = false,
    this.passwordResetComplete = false,
    this.emailVerified = false,
  });

  /// Whether an async auth operation is in progress.
  final bool isLoading;

  /// Whether the user is currently authenticated.
  final bool isAuthenticated;

  /// The currently authenticated user, or `null`.
  final UserEntity? user;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether a verification email was successfully sent.
  final bool emailVerificationSent;

  /// Whether a password reset email was successfully sent.
  final bool passwordResetSent;

  /// Whether the password reset was completed successfully.
  final bool passwordResetComplete;

  /// Whether email verification completed successfully.
  final bool emailVerified;

  /// Creates a copy of this state with the given fields replaced.
  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserEntity? user,
    String? error,
    bool? emailVerificationSent,
    bool? passwordResetSent,
    bool? passwordResetComplete,
    bool? emailVerified,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      emailVerificationSent:
          emailVerificationSent ?? this.emailVerificationSent,
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
      passwordResetComplete:
          passwordResetComplete ?? this.passwordResetComplete,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  /// Clears the current error message.
  AuthState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the auth feature's state.
///
/// All auth operations flow through this notifier, which:
/// 1. Sets [isLoading] to `true` before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates [isAuthenticated] and [user] on success
/// 4. Sets [error] on failure
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _signUpUseCase = signUpUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _authRepository = authRepository,
        super(const AuthState());

  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository;

  // ─── Login ──────────────────────────────────────────────────────

  /// Authenticates the user with [email] and [password].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _loginUseCase(LoginParams(
      email: email,
      password: password,
    ),);

    result.fold(
      onSuccess: (user) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: null,
        );
        AppLogger.info('Login successful: ${_redactEmail(user.email)}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Login failed: $failure');
      },
    );
  }

  // ─── Sign Up ────────────────────────────────────────────────────

  /// Registers a new user account.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _signUpUseCase(SignUpParams(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      schoolId: schoolId,
    ),);

    result.fold(
      onSuccess: (user) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: null,
          emailVerificationSent: !user.isEmailVerified,
        );
        AppLogger.info('Sign-up successful: ${user.email}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Sign-up failed: $failure');
      },
    );
  }

  // ─── OAuth Sign-In ──────────────────────────────────────────────

  /// Signs in the user with an OAuth provider (e.g., Google, Apple).
  ///
  /// Uses Supabase's `signInWithOAuth()` to redirect the user to the
  /// provider's login page. On web, this opens a popup window.
  Future<void> signInWithProvider(String provider) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signInWithOAuth(provider: provider);
      // OAuth flow redirects the user — the auth state will be updated
      // when the user returns via the callback URL.
      AppLogger.info('OAuth sign-in initiated with provider: $provider');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in with $provider. Please try again.',
      );
      AppLogger.warning('OAuth sign-in failed: $e');
    }
  }

  // ─── Forgot Password ────────────────────────────────────────────

  /// Sends a password-reset email.
  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, passwordResetSent: false);

    final result = await _forgotPasswordUseCase(email);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          passwordResetSent: true,
          error: null,
        );
        AppLogger.info('Password reset email sent');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
      },
    );
  }

  // ─── Reset Password ─────────────────────────────────────────────

  /// Resets the password using the provided [token] and [newPassword].
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, passwordResetComplete: false);

    final result = await _authRepository.resetPassword(
      token: token,
      newPassword: newPassword,
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          passwordResetComplete: true,
          error: null,
        );
        AppLogger.info('Password reset successful');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
      },
    );
  }

  // ─── Verify Email ───────────────────────────────────────────────

  /// Verifies the user's email with the given [token].
  Future<void> verifyEmail({required String token}) async {
    state = state.copyWith(isLoading: true, error: null, emailVerified: false);

    final result = await _authRepository.verifyEmail(token: token);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          emailVerified: true,
          error: null,
        );
        AppLogger.info('Email verified successfully');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
      },
    );
  }

  // ─── Resend Verification ────────────────────────────────────────

  /// Resends the email verification link.
  Future<void> resendVerification({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, emailVerificationSent: false);

    final result = await _authRepository.resendVerification(email: email);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          emailVerificationSent: true,
          error: null,
        );
        AppLogger.info('Verification email resent');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
      },
    );
  }

  // ─── Logout ─────────────────────────────────────────────────────

  /// Signs the user out and clears local data.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _logoutUseCase();

    result.fold(
      onSuccess: (_) {
        state = const AuthState();
        AppLogger.info('Logout successful');
      },
      onFailure: (failure) {
        // Even on failure, reset local state since the session may be invalid.
        state = const AuthState();
        AppLogger.warning('Logout had errors but local state was cleared');
      },
    );
  }

  // ─── Check Auth ─────────────────────────────────────────────────

  /// Checks the current authentication state on app startup.
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCurrentUserUseCase();

    result.fold(
      onSuccess: (user) {
        if (user != null) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
          );
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: _mapFailureToMessage(failure),
        );
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }

  /// Redacts email addresses for logging: "user@example.com" → "u***@example.com"
  static String _redactEmail(String? email) {
    if (email == null || email.isEmpty) return '[null]';
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '[REDACTED]';
    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    if (local.length <= 1) return '*$domain';
    return '${local[0]}***$domain';
  }
}
