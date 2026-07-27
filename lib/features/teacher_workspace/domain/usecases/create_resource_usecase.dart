import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateResourceUseCase].
class CreateResourceParams {
  const CreateResourceParams({required this.resource});
  final TeachingResourceEntity resource;
}

class CreateResourceUseCase {
  CreateResourceUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<TeachingResourceEntity>> call(
    CreateResourceParams params,
  ) async {
    if (params.resource.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createResource(params.resource);
  }
}
