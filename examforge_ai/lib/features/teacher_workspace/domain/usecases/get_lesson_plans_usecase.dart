import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetLessonPlansUseCase].
class GetLessonPlansParams {
  const GetLessonPlansParams({required this.filter});
  final WorkspaceFilterEntity filter;
}

class GetLessonPlansUseCase {
  GetLessonPlansUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<LessonPlanEntity>>> call(
    GetLessonPlansParams params,
  ) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getLessonPlans(params.filter);
  }
}
