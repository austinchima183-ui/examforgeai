import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateWorksheetUseCase].
class CreateWorksheetParams {
  const CreateWorksheetParams({required this.worksheet});
  final WorksheetEntity worksheet;
}

class CreateWorksheetUseCase {
  CreateWorksheetUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<WorksheetEntity>> call(CreateWorksheetParams params) async {
    if (params.worksheet.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Worksheet title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createWorksheet(params.worksheet);
  }
}
