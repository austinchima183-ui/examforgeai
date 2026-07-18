import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetCalendarEventsParams extends Equatable {
  const GetCalendarEventsParams({
    this.type,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.perPage = 20,
  });

  final CalendarEventType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [type, startDate, endDate, page, perPage];
}

class GetCalendarEventsUseCase {
  GetCalendarEventsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<CalendarEventEntity>>> call(
    GetCalendarEventsParams params,
  ) async {
    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page must be >= 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'PerPage must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid perPage'},
        ),
      );
    }

    if (params.startDate != null &&
        params.endDate != null &&
        params.endDate!.isBefore(params.startDate!)) {
      return const FailureResult(
        Failure.validation(
          message: 'End date cannot be before start date',
          fieldErrors: {'endDate': 'Must be after startDate'},
        ),
      );
    }

    return _repository.getCalendarEvents(
      type: params.type,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
