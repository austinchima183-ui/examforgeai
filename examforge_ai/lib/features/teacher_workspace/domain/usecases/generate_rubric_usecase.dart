import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateRubricUseCase].
class GenerateRubricParams extends Equatable {
  const GenerateRubricParams({
    this.subjectId,
    required this.topic,
    this.criteriaCount,
    this.totalPoints,
  });

  final String? subjectId;
  final String topic;
  final int? criteriaCount;
  final double? totalPoints;

  @override
  List<Object?> get props => [subjectId, topic, criteriaCount, totalPoints];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.generateRubric].
  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'topic': topic,
    'criteriaCount': criteriaCount,
    'totalPoints': totalPoints,
  };
}

/// Use case for generating a rubric using AI.
///
/// Validates that the [GenerateRubricParams.topic] is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class GenerateRubricUseCase {
  GenerateRubricUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Generates a rubric based on the provided [params].
  ///
  /// Returns a [Result] containing the generated [RubricEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<RubricEntity>> call(GenerateRubricParams params) async {
    if (params.topic.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Topic is required',
        fieldErrors: {'topic': 'Topic cannot be empty'},
      ));
    }
    return _repository.generateRubric(params.toMap());
  }
}
