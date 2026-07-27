import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class CreateCalendarEventParams extends Equatable {
  const CreateCalendarEventParams({
    required this.title,
    this.description,
    this.eventType = CalendarEventType.custom,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
    this.meetingLink,
    this.attendeeIds,
    this.rsvpRequired = false,
  });

  final String title;
  final String? description;
  final CalendarEventType eventType;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? location;
  final String? meetingLink;
  final List<String>? attendeeIds;
  final bool rsvpRequired;

  @override
  List<Object?> get props => [
        title,
        description,
        eventType,
        startTime,
        endTime,
        isAllDay,
        location,
        meetingLink,
        attendeeIds,
        rsvpRequired,
      ];
}

class CreateCalendarEventUseCase {
  CreateCalendarEventUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<CalendarEventEntity>> call(
    CreateCalendarEventParams params,
  ) async {
    if (params.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Event title cannot be empty',
          fieldErrors: {'title': 'Title is required'},
        ),
      );
    }

    if (params.endTime.isBefore(params.startTime) && !params.isAllDay) {
      return const FailureResult(
        Failure.validation(
          message: 'End time cannot be before start time',
          fieldErrors: {'endTime': 'Must be after startTime'},
        ),
      );
    }

    return _repository.createCalendarEvent(
      title: params.title,
      description: params.description,
      eventType: params.eventType,
      startTime: params.startTime,
      endTime: params.endTime,
      isAllDay: params.isAllDay,
      location: params.location,
      meetingLink: params.meetingLink,
      attendeeIds: params.attendeeIds,
      rsvpRequired: params.rsvpRequired,
    );
  }
}
