import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetWorksheetsUseCase].
class GetWorksheetsParams {
  const GetWorksheetsParams({required this.filter});
  final WorkspaceFilterEntity filter;
}

class GetWorksheetsUseCase {
  GetWorksheetsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<WorksheetEntity>>> call(GetWorksheetsParams params) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getWorksheets(params.filter);
  }
}
