import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateWorksheetUseCase].
class GenerateWorksheetParams {
  const GenerateWorksheetParams({
    required this.subject,
    this.className,
    this.topic,
    required this.worksheetType,
    this.difficulty,
    this.questionCount,
  });

  final String subject;
  final String? className;
  final String? topic;
  final WorksheetType worksheetType;
  final String? difficulty;
  final int? questionCount;
}

class GenerateWorksheetUseCase {
  GenerateWorksheetUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<WorksheetEntity>> call(GenerateWorksheetParams params) async {
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ),);
    }
    return _repository.generateWorksheet({
      'subject': params.subject,
      if (params.className != null) 'className': params.className,
      if (params.topic != null) 'topic': params.topic,
      'worksheetType': params.worksheetType.value,
      if (params.difficulty != null) 'difficulty': params.difficulty,
      if (params.questionCount != null)
        'questionCount': params.questionCount,
    });
  }
}
