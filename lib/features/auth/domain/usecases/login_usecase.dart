import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Parameters for the [LoginUseCase].
class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Use case that authenticates a user with email and password.
///
/// Encapsulates the login business rule: validate inputs are non-empty,
/// delegate to [AuthRepository.login], and return the result.
///
/// ```dart
/// final result = await loginUseCase(LoginParams(
///   email: 'user@example.com',
///   password: 'secret123',
/// ));
/// result.fold(
///   onSuccess: (user) => navigateToDashboard(user),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call(LoginParams params) async {
    // Basic input guard — detailed validation lives in the presentation layer.
    if (params.email.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Email is required',
          fieldErrors: {'email': 'Email cannot be empty'},
        ),
      );
    }
    if (params.password.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Password is required',
          fieldErrors: {'password': 'Password cannot be empty'},
        ),
      );
    }

    return _repository.login(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
