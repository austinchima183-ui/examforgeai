import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreatePracticalAssessmentUseCase].
class CreatePracticalAssessmentParams extends Equatable {
  const CreatePracticalAssessmentParams({required this.assessment});
  final PracticalAssessmentEntity assessment;

  @override
  List<Object?> get props => [assessment];
}

/// Use case for creating a new practical assessment.
///
/// Validates that the [CreatePracticalAssessmentParams.assessment] title
/// is not empty before delegating to the [TeacherWorkspaceRepository].
class CreatePracticalAssessmentUseCase {
  CreatePracticalAssessmentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new practical assessment from the provided [params].
  ///
  /// Returns a [Result] containing the persisted
  /// [PracticalAssessmentEntity] on success, or a [FailureResult]
  /// if validation fails or the repository encounters an error.
  Future<Result<PracticalAssessmentEntity>> call(
    CreatePracticalAssessmentParams params,
  ) async {
    if (params.assessment.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Practical assessment title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createPracticalAssessment(params.assessment);
  }
}
