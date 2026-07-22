import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetChildAttendanceUseCase].
class GetChildAttendanceParams extends Equatable {
  const GetChildAttendanceParams({
    required this.studentId,
    this.startDate,
    this.endDate,
  });

  final String studentId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [studentId, startDate, endDate];
}

/// Use case for retrieving a child's attendance records.
///
/// Validates that the [GetChildAttendanceParams.studentId] is not
/// empty before delegating to the [ParentPortalRepository].
class GetChildAttendanceUseCase {
  GetChildAttendanceUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves attendance data for the specified child.
  ///
  /// Returns a [Result] containing the [ChildAttendanceEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ChildAttendanceEntity>> call(
    GetChildAttendanceParams params,
  ) async {
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ));
    }
    return _repository.getChildAttendance(
      studentId: params.studentId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
