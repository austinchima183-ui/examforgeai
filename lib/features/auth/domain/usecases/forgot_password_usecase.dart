import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case that sends a password-reset email.
///
/// Validates that the email is non-empty before delegating to
/// [AuthRepository.forgotPassword].
class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) async {
    if (email.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Email is required',
          fieldErrors: {'email': 'Please enter your email address'},
        ),
      );
    }

    return _repository.forgotPassword(email: email.trim());
  }
}
