import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateOralQuestionsUseCase].
class CreateOralQuestionsParams extends Equatable {
  const CreateOralQuestionsParams({required this.oralQuestion});
  final OralQuestionEntity oralQuestion;

  @override
  List<Object?> get props => [oralQuestion];
}

/// Use case for creating a new oral question set.
///
/// Validates that the [CreateOralQuestionsParams.oralQuestion] title
/// is not empty before delegating to the [TeacherWorkspaceRepository].
class CreateOralQuestionsUseCase {
  CreateOralQuestionsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new oral question set from the provided [params].
  ///
  /// Returns a [Result] containing the persisted [OralQuestionEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<OralQuestionEntity>> call(
    CreateOralQuestionsParams params,
  ) async {
    if (params.oralQuestion.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Oral question title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createOralQuestions(params.oralQuestion);
  }
}
