import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetResourcesUseCase].
class GetResourcesParams {
  const GetResourcesParams({required this.filter});
  final WorkspaceFilterEntity filter;
}

class GetResourcesUseCase {
  GetResourcesUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<TeachingResourceEntity>>> call(
    GetResourcesParams params,
  ) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getResources(params.filter);
  }
}
