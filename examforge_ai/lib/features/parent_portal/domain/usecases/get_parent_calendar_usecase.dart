import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetParentCalendarUseCase].
class GetParentCalendarParams extends Equatable {
  const GetParentCalendarParams({
    required this.startDate,
    required this.endDate,
    this.studentId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? studentId;

  @override
  List<Object?> get props => [startDate, endDate, studentId];
}

/// Use case for retrieving the parent calendar.
///
/// Validates that [GetParentCalendarParams.startDate] is before
/// [GetParentCalendarParams.endDate] before delegating to the
/// [ParentPortalRepository].
class GetParentCalendarUseCase {
  GetParentCalendarUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves calendar events for the specified date range.
  ///
  /// Returns a [Result] containing a list of [ParentCalendarEventEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<ParentCalendarEventEntity>>> call(
    GetParentCalendarParams params,
  ) async {
    if (params.startDate.isAfter(params.endDate)) {
      return const FailureResult(Failure.validation(
        message: 'Start date must be before end date',
        fieldErrors: {
          'startDate': 'Start date must be before end date',
          'endDate': 'End date must be after start date',
        },
      ));
    }
    return _repository.getParentCalendar(
      startDate: params.startDate,
      endDate: params.endDate,
      studentId: params.studentId,
    );
  }
}
