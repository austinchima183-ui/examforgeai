import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateLessonPlanUseCase].
class CreateLessonPlanParams {
  const CreateLessonPlanParams({required this.plan});
  final LessonPlanEntity plan;
}

class CreateLessonPlanUseCase {
  CreateLessonPlanUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<LessonPlanEntity>> call(CreateLessonPlanParams params) async {
    if (params.plan.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Lesson plan title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    return _repository.createLessonPlan(params.plan);
  }
}
