import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateOralQuestionsUseCase].
class GenerateOralQuestionsParams extends Equatable {
  const GenerateOralQuestionsParams({
    this.subjectId,
    required this.topic,
    this.questionCount,
    this.difficulty,
    this.curriculum,
  });

  final String? subjectId;
  final String topic;
  final int? questionCount;
  final String? difficulty;
  final String? curriculum;

  @override
  List<Object?> get props => [
        subjectId,
        topic,
        questionCount,
        difficulty,
        curriculum,
      ];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.generateOralQuestions].
  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'topic': topic,
    'questionCount': questionCount,
    'difficulty': difficulty,
    'curriculum': curriculum,
  };
}

/// Use case for generating oral questions using AI.
///
/// Validates that the [GenerateOralQuestionsParams.topic] is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class GenerateOralQuestionsUseCase {
  GenerateOralQuestionsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Generates oral questions based on the provided [params].
  ///
  /// Returns a [Result] containing the generated [OralQuestionEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<OralQuestionEntity>> call(
    GenerateOralQuestionsParams params,
  ) async {
    if (params.topic.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Topic is required',
        fieldErrors: {'topic': 'Topic cannot be empty'},
      ),);
    }
    return _repository.generateOralQuestions(params.toMap());
  }
}
