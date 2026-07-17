import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateLessonPlanUseCase].
class GenerateLessonPlanParams {
  const GenerateLessonPlanParams({
    required this.subject,
    required this.className,
    required this.topic,
    this.subtopic,
    required this.curriculum,
    this.learningObjectives,
    this.durationMinutes,
    this.teachingStyle,
    this.studentLevel,
  });

  final String subject;
  final String className;
  final String topic;
  final String? subtopic;
  final CurriculumType curriculum;
  final List<String>? learningObjectives;
  final int? durationMinutes;
  final TeachingStyle? teachingStyle;
  final StudentLevel? studentLevel;
}

class GenerateLessonPlanUseCase {
  GenerateLessonPlanUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<LessonPlanEntity>> call(
    GenerateLessonPlanParams params,
  ) async {
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ));
    }
    return _repository.generateLessonPlan({
      'subject': params.subject,
      'className': params.className,
      'topic': params.topic,
      if (params.subtopic != null) 'subtopic': params.subtopic,
      'curriculum': params.curriculum.value,
      if (params.learningObjectives != null)
        'learningObjectives': params.learningObjectives,
      if (params.durationMinutes != null)
        'durationMinutes': params.durationMinutes,
      if (params.teachingStyle != null)
        'teachingStyle': params.teachingStyle!.value,
      if (params.studentLevel != null)
        'studentLevel': params.studentLevel!.value,
    });
  }
}
