import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [ToggleFavoriteUseCase].
class ToggleFavoriteParams {
  const ToggleFavoriteParams({required this.resourceId});
  final String resourceId;
}

class ToggleFavoriteUseCase {
  ToggleFavoriteUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<void>> call(ToggleFavoriteParams params) async {
    if (params.resourceId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource ID is required',
        fieldErrors: {'resourceId': 'Resource ID cannot be empty'},
      ));
    }
    return _repository.toggleFavorite(params.resourceId);
  }
}
