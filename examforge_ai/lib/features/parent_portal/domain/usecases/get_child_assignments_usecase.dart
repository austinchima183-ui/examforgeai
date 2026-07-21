import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetChildAssignmentsUseCase].
class GetChildAssignmentsParams extends Equatable {
  const GetChildAssignmentsParams({
    required this.studentId,
    this.status,
  });

  final String studentId;
  final String? status;

  @override
  List<Object?> get props => [studentId, status];
}

/// Use case for retrieving a child's assignments.
///
/// Validates that the [GetChildAssignmentsParams.studentId] is not
/// empty before delegating to the [ParentPortalRepository].
class GetChildAssignmentsUseCase {
  GetChildAssignmentsUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves assignments for the specified child.
  ///
  /// Returns a [Result] containing a list of [ChildAssignmentEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<ChildAssignmentEntity>>> call(
    GetChildAssignmentsParams params,
  ) async {
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ));
    }
    return _repository.getChildAssignments(
      params.studentId,
      status: params.status,
    );
  }
}
