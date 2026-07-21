import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetChildProfileUseCase].
class GetChildProfileParams extends Equatable {
  const GetChildProfileParams({required this.studentId});
  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// Use case for retrieving a child's profile.
///
/// Validates that the [GetChildProfileParams.studentId] is not
/// empty before delegating to the [ParentPortalRepository].
class GetChildProfileUseCase {
  GetChildProfileUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves the profile for the specified child.
  ///
  /// Returns a [Result] containing the [ChildProfileEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ChildProfileEntity>> call(GetChildProfileParams params) async {
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ));
    }
    return _repository.getChildProfile(params.studentId);
  }
}
