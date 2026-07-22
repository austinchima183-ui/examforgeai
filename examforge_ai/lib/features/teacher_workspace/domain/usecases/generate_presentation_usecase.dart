import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GeneratePresentationUseCase].
class GeneratePresentationParams extends Equatable {
  const GeneratePresentationParams({
    required this.subjectId,
    required this.className,
    required this.topic,
    required this.presentationType,
    this.curriculum,
    this.difficulty,
    this.customInstructions,
    this.slideCount,
  });

  final String subjectId;
  final String className;
  final String topic;
  final String presentationType;
  final String? curriculum;
  final String? difficulty;
  final String? customInstructions;
  final int? slideCount;

  @override
  List<Object?> get props => [
        subjectId,
        className,
        topic,
        presentationType,
        curriculum,
        difficulty,
        customInstructions,
        slideCount,
      ];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.generatePresentation].
  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'className': className,
    'topic': topic,
    'presentationType': presentationType,
    'curriculum': curriculum,
    'difficulty': difficulty,
    'customInstructions': customInstructions,
    'slideCount': slideCount,
  };
}

/// Use case for generating a presentation using AI.
///
/// Validates that the [GeneratePresentationParams.subjectId] is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class GeneratePresentationUseCase {
  GeneratePresentationUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Generates a presentation based on the provided [params].
  ///
  /// Returns a [Result] containing the generated [PresentationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<PresentationEntity>> call(
    GeneratePresentationParams params,
  ) async {
    if (params.subjectId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject ID is required',
        fieldErrors: {'subjectId': 'Subject ID cannot be empty'},
      ));
    }
    return _repository.generatePresentation(params.toMap());
  }
}
