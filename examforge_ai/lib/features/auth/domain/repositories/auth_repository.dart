import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';

/// Abstract contract for authentication operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class AuthRepository {
  /// Authenticates a user with [email] and [password].
  ///
  /// Returns [Result.success] with the authenticated [UserEntity],
  /// or [Result.failure] with an appropriate [Failure].
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  /// Registers a new user account.
  ///
  /// [role] must be a valid [UserRole] value string.
  /// [schoolId] is required for non-student roles.
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  });

  /// Sends a password-reset email to the given [email].
  Future<Result<void>> forgotPassword({required String email});

  /// Resets the user's password using a recovery [token].
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Verifies the user's email address using a verification [token].
  Future<Result<void>> verifyEmail({required String token});

  /// Resends the email verification link to [email].
  Future<Result<void>> resendVerification({required String email});

  /// Returns the currently authenticated user, or `null` if not signed in.
  Future<Result<UserEntity?>> getCurrentUser();

  /// Returns `true` if there is an active, non-expired session.
  bool isAuthenticated();

  /// Signs the user out and clears all locally stored sensitive data.
  Future<Result<void>> logout();

  /// Signs in the user with an OAuth provider (e.g., Google, Apple).
  ///
  /// On web, this opens a popup window for the OAuth flow.
  /// On native, this uses the device's browser for the OAuth redirect.
  Future<void> signInWithOAuth({required String provider});
}
