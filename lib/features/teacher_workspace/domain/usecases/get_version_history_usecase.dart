import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetVersionHistoryUseCase].
class GetVersionHistoryParams {
  const GetVersionHistoryParams({
    required this.resourceType,
    required this.resourceId,
  });

  final String resourceType;
  final String resourceId;
}

class GetVersionHistoryUseCase {
  GetVersionHistoryUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<WorkspaceVersionEntity>>> call(
    GetVersionHistoryParams params,
  ) async {
    if (params.resourceType.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource type is required',
        fieldErrors: {'resourceType': 'Resource type cannot be empty'},
      ),);
    }
    if (params.resourceId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource ID is required',
        fieldErrors: {'resourceId': 'Resource ID cannot be empty'},
      ),);
    }
    return _repository.getVersionHistory(
      params.resourceType,
      params.resourceId,
    );
  }
}
