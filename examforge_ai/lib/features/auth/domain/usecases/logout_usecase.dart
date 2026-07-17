import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case that signs the user out and clears local data.
///
/// Delegates entirely to [AuthRepository.logout]. Even if the remote
/// sign-out call fails, the repository implementation guarantees that
/// local sensitive data is cleared.
class LogoutUseCase {
  LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() async {
    return _repository.logout();
  }
}
