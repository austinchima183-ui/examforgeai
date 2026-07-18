import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [ShareResourceUseCase].
class ShareResourceParams extends Equatable {
  const ShareResourceParams({
    required this.resourceType,
    required this.resourceId,
    required this.sharedWith,
    required this.canEdit,
    this.message,
  });

  final String resourceType;
  final String resourceId;
  final String sharedWith;
  final bool canEdit;
  final String? message;

  @override
  List<Object?> get props => [resourceType, resourceId, sharedWith, canEdit, message];
}

/// Use case for sharing a workspace resource with another user.
///
/// Validates that both [ShareResourceParams.resourceId] and
/// [ShareResourceParams.sharedWith] are not empty before delegating
/// to the [TeacherWorkspaceRepository].
class ShareResourceUseCase {
  ShareResourceUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Shares a resource based on the provided [params].
  ///
  /// Returns a [Result] containing the [SharedResourceEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<SharedResourceEntity>> call(ShareResourceParams params) async {
    if (params.resourceId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource ID is required',
        fieldErrors: {'resourceId': 'Resource ID cannot be empty'},
      ));
    }
    if (params.sharedWith.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Shared with is required',
        fieldErrors: {'sharedWith': 'Shared with cannot be empty'},
      ));
    }
    return _repository.shareResource(params);
  }
}
