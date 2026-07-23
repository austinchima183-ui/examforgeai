import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetPresentationsUseCase].
class GetPresentationsParams extends Equatable {
  const GetPresentationsParams({required this.filter});
  final WorkspaceFilterEntity filter;

  @override
  List<Object?> get props => [filter];
}

/// Use case for retrieving a filtered list of presentations.
///
/// Validates that the [GetPresentationsParams.filter] page is at least 1
/// before delegating to the [TeacherWorkspaceRepository].
class GetPresentationsUseCase {
  GetPresentationsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Retrieves a list of presentations matching the filter criteria.
  ///
  /// Returns a [Result] containing a list of [PresentationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<PresentationEntity>>> call(
    GetPresentationsParams params,
  ) async {
    if (params.filter.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be at least 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ),);
    }
    return _repository.getPresentations(params.filter);
  }
}
