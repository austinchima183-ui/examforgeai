import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetChildPerformanceUseCase].
class GetChildPerformanceParams extends Equatable {
  const GetChildPerformanceParams({
    required this.studentId,
    this.academicSessionId,
  });

  final String studentId;
  final String? academicSessionId;

  @override
  List<Object?> get props => [studentId, academicSessionId];
}

/// Use case for retrieving a child's academic performance.
///
/// Validates that the [GetChildPerformanceParams.studentId] is not
/// empty before delegating to the [ParentPortalRepository].
class GetChildPerformanceUseCase {
  GetChildPerformanceUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves performance data for the specified child.
  ///
  /// Returns a [Result] containing the [ChildPerformanceEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ChildPerformanceEntity>> call(
    GetChildPerformanceParams params,
  ) async {
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ),);
    }
    return _repository.getChildPerformance(
      studentId: params.studentId,
      academicSessionId: params.academicSessionId,
    );
  }
}
