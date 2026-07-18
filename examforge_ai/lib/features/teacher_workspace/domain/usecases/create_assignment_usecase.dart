import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateAssignmentUseCase].
class CreateAssignmentParams {
  const CreateAssignmentParams({required this.assignment});
  final WorkspaceAssignmentEntity assignment;
}

class CreateAssignmentUseCase {
  CreateAssignmentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<WorkspaceAssignmentEntity>> call(
    CreateAssignmentParams params,
  ) async {
    if (params.assignment.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Assignment title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    return _repository.createAssignment(params.assignment);
  }
}
