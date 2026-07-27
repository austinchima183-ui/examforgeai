import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetCommunicationsUseCase].
class GetCommunicationsParams extends Equatable {
  const GetCommunicationsParams({required this.filter});
  final WorkspaceFilterEntity filter;

  @override
  List<Object?> get props => [filter];
}

/// Use case for retrieving a filtered list of communications.
///
/// Validates that the [GetCommunicationsParams.filter] page is at least 1
/// before delegating to the [TeacherWorkspaceRepository].
class GetCommunicationsUseCase {
  GetCommunicationsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Retrieves a list of communications matching the filter criteria.
  ///
  /// Returns a [Result] containing a list of [CommunicationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<CommunicationEntity>>> call(
    GetCommunicationsParams params,
  ) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getCommunications(params.filter);
  }
}
