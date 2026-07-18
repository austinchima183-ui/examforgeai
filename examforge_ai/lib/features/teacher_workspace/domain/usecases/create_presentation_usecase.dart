import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreatePresentationUseCase].
class CreatePresentationParams extends Equatable {
  const CreatePresentationParams({required this.presentation});
  final PresentationEntity presentation;

  @override
  List<Object?> get props => [presentation];
}

/// Use case for creating a new presentation.
///
/// Validates that the [CreatePresentationParams.presentation] title
/// is not empty before delegating to the [TeacherWorkspaceRepository].
class CreatePresentationUseCase {
  CreatePresentationUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new presentation from the provided [params].
  ///
  /// Returns a [Result] containing the persisted [PresentationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<PresentationEntity>> call(
    CreatePresentationParams params,
  ) async {
    if (params.presentation.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Presentation title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    return _repository.createPresentation(params.presentation);
  }
}
