import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Parameters for the [SignUpUseCase].
class SignUpParams {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.schoolId,
  });

  final String email;
  final String password;
  final String fullName;
  final String role;
  final String? schoolId;
}

/// Use case that registers a new user account.
///
/// Validates that required fields are non-empty and delegates to
/// [AuthRepository.signUp].
class SignUpUseCase {
  SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call(SignUpParams params) async {
    // Input guards
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
    if (params.fullName.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Full name is required',
          fieldErrors: {'fullName': 'Name cannot be empty'},
        ),
      );
    }
    if (params.role.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Role is required',
          fieldErrors: {'role': 'Please select a role'},
        ),
      );
    }

    return _repository.signUp(
      email: params.email.trim(),
      password: params.password,
      fullName: params.fullName.trim(),
      role: params.role,
      schoolId: params.schoolId?.trim(),
    );
  }
}
