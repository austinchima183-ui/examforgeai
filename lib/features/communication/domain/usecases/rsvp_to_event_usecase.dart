import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class RsvpToEventParams extends Equatable {
  const RsvpToEventParams({
    required this.eventId,
    required this.status,
  });

  final String eventId;
  final String status;

  @override
  List<Object?> get props => [eventId, status];
}

class RsvpToEventUseCase {
  RsvpToEventUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(RsvpToEventParams params) async {
    if (params.eventId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Event ID cannot be empty',
          fieldErrors: {'eventId': 'Required'},
        ),
      );
    }

    if (params.status.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'RSVP status cannot be empty',
          fieldErrors: {'status': 'Status is required'},
        ),
      );
    }

    const validStatuses = {'accepted', 'declined', 'tentative'};
    if (!validStatuses.contains(params.status.toLowerCase())) {
      return FailureResult(
        Failure.validation(
          message:
              'Invalid RSVP status: "${params.status}". Must be one of: ${validStatuses.join(', ')}',
          fieldErrors: {'status': 'Invalid status'},
        ),
      );
    }

    return _repository.rsvpToEvent(
      eventId: params.eventId,
      status: params.status,
    );
  }
}
