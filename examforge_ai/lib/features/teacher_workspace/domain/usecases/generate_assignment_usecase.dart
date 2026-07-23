import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateAssignmentUseCase].
class GenerateAssignmentParams {
  const GenerateAssignmentParams({
    required this.subject,
    this.className,
    this.topic,
    this.difficulty,
    this.totalMarks,
    this.deadline,
  });

  final String subject;
  final String? className;
  final String? topic;
  final String? difficulty;
  final int? totalMarks;
  final DateTime? deadline;
}

class GenerateAssignmentUseCase {
  GenerateAssignmentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<WorkspaceAssignmentEntity>> call(
    GenerateAssignmentParams params,
  ) async {
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ),);
    }
    return _repository.generateAssignment({
      'subject': params.subject,
      if (params.className != null) 'className': params.className,
      if (params.topic != null) 'topic': params.topic,
      if (params.difficulty != null) 'difficulty': params.difficulty,
      if (params.totalMarks != null) 'totalMarks': params.totalMarks,
      if (params.deadline != null)
        'deadline': params.deadline!.toIso8601String(),
    });
  }
}
