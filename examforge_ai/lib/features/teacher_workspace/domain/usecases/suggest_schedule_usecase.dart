import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [SuggestScheduleUseCase].
class SuggestScheduleParams {
  const SuggestScheduleParams({required this.preferences});
  final Map<String, dynamic> preferences;
}

class SuggestScheduleUseCase {
  SuggestScheduleUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<CalendarEventEntity>>> call(
    SuggestScheduleParams params,
  ) async {
    if (params.preferences.isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Schedule preferences are required',
        fieldErrors: {'preferences': 'Preferences cannot be empty'},
      ),);
    }
    return _repository.suggestSchedule(params.preferences);
  }
}
