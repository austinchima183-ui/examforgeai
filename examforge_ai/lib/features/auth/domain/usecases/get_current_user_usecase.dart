import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case that retrieves the currently authenticated user.
///
/// Returns [Result.success] with a [UserEntity] if authenticated,
/// or [Result.success] with `null` if no session exists.
/// A [Result.failure] is only returned on unexpected errors.
class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity?>> call() async {
    return _repository.getCurrentUser();
  }
}
