import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetAssignmentsUseCase].
class GetAssignmentsParams {
  const GetAssignmentsParams({required this.filter});
  final WorkspaceFilterEntity filter;
}

class GetAssignmentsUseCase {
  GetAssignmentsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<WorkspaceAssignmentEntity>>> call(
    GetAssignmentsParams params,
  ) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getAssignments(params.filter);
  }
}
