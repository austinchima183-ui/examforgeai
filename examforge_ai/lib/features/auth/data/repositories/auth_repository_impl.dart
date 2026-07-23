import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../services/storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete implementation of [AuthRepository] that coordinates
/// between the remote data source and local storage.
///
/// Responsibilities:
/// - Delegates auth operations to [AuthRemoteDataSource]
/// - Caches the current user data locally via [StorageService]
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Manages token persistence for session continuity
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService;

  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  // Cached current user to avoid repeated secure-storage reads.
  UserEntity? _cachedUser;

  // ─── Login ──────────────────────────────────────────────────────

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final entity = userModel.toEntity();
      await _cacheUser(entity);
      _cachedUser = entity;

      return Success(entity);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected login error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Sign Up ────────────────────────────────────────────────────

  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? schoolId,
  }) async {
    try {
      final userModel = await _remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        schoolId: schoolId,
      );

      final entity = userModel.toEntity();
      await _cacheUser(entity);
      _cachedUser = entity;

      return Success(entity);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected sign-up error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Forgot Password ────────────────────────────────────────────

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected forgot-password error in repository',
          error: e,);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Reset Password ─────────────────────────────────────────────

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected reset-password error in repository',
          error: e,);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Verify Email ───────────────────────────────────────────────

  @override
  Future<Result<void>> verifyEmail({required String token}) async {
    try {
      await _remoteDataSource.verifyEmail(token: token);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected verify-email error in repository',
          error: e,);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Resend Verification ────────────────────────────────────────

  @override
  Future<Result<void>> resendVerification({required String email}) async {
    try {
      await _remoteDataSource.resendVerification(email: email);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: e.code,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected resend-verification error in repository',
          error: e,);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Current User ───────────────────────────────────────────────

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      // Return cached user if available.
      if (_cachedUser != null) {
        return Success(_cachedUser);
      }

      // Try to get user from remote data source.
      final userModel = _remoteDataSource.getCurrentUser();
      if (userModel == null) {
        // No active session — check storage for persisted data.
        final hasToken = await _storageService.hasToken();
        if (!hasToken) {
          return const Success(null);
        }
        // Token exists but no Supabase user — session may have expired.
        return const Success(null);
      }

      final entity = userModel.toEntity();
      _cachedUser = entity;
      return Success(entity);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected get-current-user error in repository',
          error: e,);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ),);
    }
  }

  // ─── Is Authenticated ──────────────────────────────────────────

  @override
  bool isAuthenticated() {
    return _remoteDataSource.getCurrentUser() != null;
  }

  // ─── Logout ─────────────────────────────────────────────────────

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      _cachedUser = null;
      await _storageService.clearSensitiveData();
      return const Success(null);
    } on CacheException catch (e) {
      // Even if clearing storage fails, remote logout succeeded.
      _cachedUser = null;
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected logout error in repository', error: e);
      // Clear local state regardless.
      _cachedUser = null;
      try {
        await _storageService.clearSensitiveData();
      } catch (_) {
        // Best-effort: ignore storage errors during cleanup.
      }
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred during logout.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Persists essential user data to secure storage for session
  /// continuity across app restarts.
  Future<void> _cacheUser(UserEntity user) async {
    try {
      await _storageService.saveUserId(user.id);
      await _storageService.saveUserRole(user.role);
    } catch (e) {
      AppLogger.warning('Failed to cache user data: $e');
      // Don't throw — caching failure should not break auth flow.
    }
  }
}
