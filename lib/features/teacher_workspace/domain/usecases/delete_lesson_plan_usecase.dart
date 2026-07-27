import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [DeleteLessonPlanUseCase].
class DeleteLessonPlanParams {
  const DeleteLessonPlanParams({required this.planId});
  final String planId;
}

class DeleteLessonPlanUseCase {
  DeleteLessonPlanUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<void>> call(DeleteLessonPlanParams params) async {
    if (params.planId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Lesson plan ID is required',
        fieldErrors: {'planId': 'Plan ID cannot be empty'},
      ),);
    }
    return _repository.deleteLessonPlan(params.planId);
  }
}
