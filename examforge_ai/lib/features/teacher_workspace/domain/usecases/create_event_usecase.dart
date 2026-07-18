import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateEventUseCase].
class CreateEventParams {
  const CreateEventParams({required this.event});
  final CalendarEventEntity event;
}

class CreateEventUseCase {
  CreateEventUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<CalendarEventEntity>> call(CreateEventParams params) async {
    if (params.event.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Event title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    if (params.event.endTime.isBefore(params.event.startTime) ||
        params.event.endTime.isAtSameMomentAs(params.event.startTime)) {
      return const FailureResult(Failure.validation(
        message: 'End time must be after start time',
        fieldErrors: {
          'endTime': 'End time must be after start time',
        },
      ));
    }
    return _repository.createEvent(params.event);
  }
}
