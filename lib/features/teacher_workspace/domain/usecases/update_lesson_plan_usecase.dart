import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [UpdateLessonPlanUseCase].
class UpdateLessonPlanParams {
  const UpdateLessonPlanParams({required this.plan});
  final LessonPlanEntity plan;
}

class UpdateLessonPlanUseCase {
  UpdateLessonPlanUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<LessonPlanEntity>> call(UpdateLessonPlanParams params) async {
    if (params.plan.id.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Lesson plan ID is required',
        fieldErrors: {'id': 'ID cannot be empty'},
      ),);
    }
    return _repository.updateLessonPlan(params.plan);
  }
}
