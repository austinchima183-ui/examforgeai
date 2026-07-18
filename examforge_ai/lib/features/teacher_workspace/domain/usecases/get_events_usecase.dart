import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetEventsUseCase].
class GetEventsParams {
  const GetEventsParams({this.startDate, this.endDate});
  final DateTime? startDate;
  final DateTime? endDate;
}

class GetEventsUseCase {
  GetEventsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<CalendarEventEntity>>> call(GetEventsParams params) {
    return _repository.getEvents(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
