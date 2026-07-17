import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [PublishAssignmentUseCase].
class PublishAssignmentParams {
  const PublishAssignmentParams({required this.assignmentId});
  final String assignmentId;
}

class PublishAssignmentUseCase {
  PublishAssignmentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<void>> call(PublishAssignmentParams params) async {
    if (params.assignmentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Assignment ID is required',
        fieldErrors: {'assignmentId': 'Assignment ID cannot be empty'},
      ));
    }
    return _repository.publishAssignment(params.assignmentId);
  }
}
