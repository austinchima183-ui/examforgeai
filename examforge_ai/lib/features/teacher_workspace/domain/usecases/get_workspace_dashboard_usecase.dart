import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetWorkspaceDashboardUseCase].
///
/// No parameters are required — the repository infers the current
/// teacher from the authenticated session.
class GetWorkspaceDashboardParams {
  const GetWorkspaceDashboardParams();
}

class GetWorkspaceDashboardUseCase {
  GetWorkspaceDashboardUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<WorkspaceDashboardEntity>> call(
    GetWorkspaceDashboardParams params,
  ) {
    return _repository.getDashboardSummary();
  }
}
