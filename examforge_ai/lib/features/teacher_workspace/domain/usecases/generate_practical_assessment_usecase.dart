import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GeneratePracticalAssessmentUseCase].
class GeneratePracticalAssessmentParams extends Equatable {
  const GeneratePracticalAssessmentParams({
    this.subjectId,
    required this.topic,
    this.difficulty,
    this.estimatedDuration,
  });

  final String? subjectId;
  final String topic;
  final String? difficulty;
  final int? estimatedDuration;

  @override
  List<Object?> get props => [subjectId, topic, difficulty, estimatedDuration];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.generatePracticalAssessment].
  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'topic': topic,
    'difficulty': difficulty,
    'estimatedDuration': estimatedDuration,
  };
}

/// Use case for generating a practical assessment using AI.
///
/// Validates that the [GeneratePracticalAssessmentParams.topic] is not
/// empty before delegating to the [TeacherWorkspaceRepository].
class GeneratePracticalAssessmentUseCase {
  GeneratePracticalAssessmentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Generates a practical assessment based on the provided [params].
  ///
  /// Returns a [Result] containing the generated
  /// [PracticalAssessmentEntity] on success, or a [FailureResult]
  /// if validation fails or the repository encounters an error.
  Future<Result<PracticalAssessmentEntity>> call(
    GeneratePracticalAssessmentParams params,
  ) async {
    if (params.topic.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Topic is required',
        fieldErrors: {'topic': 'Topic cannot be empty'},
      ));
    }
    return _repository.generatePracticalAssessment(params.toMap());
  }
}
