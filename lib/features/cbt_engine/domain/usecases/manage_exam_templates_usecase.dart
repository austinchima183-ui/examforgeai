import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../entities/exam_template_entities.dart';
import '../repositories/exam_template_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// SAVE AS TEMPLATE
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [SaveAsTemplateUseCase].
class SaveAsTemplateParams {
  const SaveAsTemplateParams({
    required this.template,
  });

  /// The exam template entity to persist.
  final ExamTemplateEntity template;
}

/// Use case that saves an exam configuration as a reusable template.
///
/// Validates that the template has a name, subject, and class before
/// delegating to the repository. Templates allow teachers to quickly
/// recreate exams with the same configuration without re-entering
/// all settings.
class SaveAsTemplateUseCase {
  SaveAsTemplateUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<ExamTemplateEntity>> call(SaveAsTemplateParams params) async {
    // ── Validate template name ────────────────────────────────────────
    if (params.template.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template name is required',
          fieldErrors: {'name': 'Please provide a name for the template'},
        ),
      );
    }

    // ── Validate subject ──────────────────────────────────────────────
    if (params.template.subjectId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Subject is required',
          fieldErrors: {'subjectId': 'Please select a subject for the template'},
        ),
      );
    }

    // ── Validate class ────────────────────────────────────────────────
    if (params.template.classId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Class is required',
          fieldErrors: {'classId': 'Please select a class for the template'},
        ),
      );
    }

    // ── Validate time limit ───────────────────────────────────────────
    if (params.template.timeLimitMinutes <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Time limit must be greater than zero',
          fieldErrors: {
            'timeLimitMinutes': 'Set a time limit of at least 1 minute',
          },
        ),
      );
    }

    // ── Validate scoring ──────────────────────────────────────────────
    if (params.template.passMark < 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Pass mark cannot be negative',
          fieldErrors: {'passMark': 'Pass mark must be zero or positive'},
        ),
      );
    }

    if (params.template.passMarkType == 'percentage' &&
        params.template.passMark > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Pass mark percentage cannot exceed 100',
          fieldErrors: {
            'passMark': 'Percentage pass mark must be between 0 and 100',
          },
        ),
      );
    }

    // ── Validate negative marking ─────────────────────────────────────
    if (params.template.negativeMarkingEnabled &&
        params.template.negativeMarkValue < 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Negative mark value cannot be negative',
          fieldErrors: {
            'negativeMarkValue': 'Set a positive value for negative marking',
          },
        ),
      );
    }

    // ── Validate attempt rules ────────────────────────────────────────
    if (params.template.allowedAttempts < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'At least one attempt must be allowed',
          fieldErrors: {
            'allowedAttempts': 'Allow at least 1 attempt',
          },
        ),
      );
    }

    // ── Validate sections have titles ─────────────────────────────────
    for (final section in params.template.sections) {
      if (section.title.trim().isEmpty) {
        return const FailureResult(
          Failure.validation(
            message: 'All template sections must have a title',
            fieldErrors: {'sections': 'Each section must have a title'},
          ),
        );
      }
    }

    // ── Validate question selection rules ─────────────────────────────
    for (final rule in params.template.questionSelectionRules) {
      if (rule.minQuestions < 1) {
        return FailureResult(
          Failure.validation(
            message: 'Question selection rule must require at least 1 question',
            fieldErrors: {
              'questionSelectionRules':
                  'Rule "${rule.id}" has minQuestions = ${rule.minQuestions}',
            },
          ),
        );
      }

      if (rule.maxQuestions < rule.minQuestions) {
        return FailureResult(
          Failure.validation(
            message:
                'Question selection rule maxQuestions cannot be less than minQuestions',
            fieldErrors: {
              'questionSelectionRules':
                  'Rule "${rule.id}" has maxQuestions < minQuestions',
            },
          ),
        );
      }

      if (rule.marksPerQuestion <= 0) {
        return FailureResult(
          Failure.validation(
            message: 'Marks per question must be greater than zero',
            fieldErrors: {
              'questionSelectionRules':
                  'Rule "${rule.id}" has marksPerQuestion = ${rule.marksPerQuestion}',
            },
          ),
        );
      }
    }

    // ── Validate showResults value ────────────────────────────────────
    const validShowResults = [
      'immediate',
      'after_submission',
      'after_grading',
      'manual',
    ];
    if (!validShowResults.contains(params.template.showResults)) {
      return const FailureResult(
        Failure.validation(
          message: 'Invalid show results setting',
          fieldErrors: {
            'showResults':
                'Must be one of: immediate, after_submission, after_grading, manual',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.saveAsTemplate(params.template);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET EXAM TEMPLATES
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [GetExamTemplatesUseCase].
class GetTemplatesParams {
  const GetTemplatesParams({
    this.schoolId,
    this.category,
    this.page = 1,
    this.perPage = 20,
  });

  /// Filter templates by school ID.
  final String? schoolId;

  /// Filter templates by category.
  final TemplateCategory? category;

  /// Page number for pagination (1-based).
  final int page;

  /// Number of templates per page.
  final int perPage;
}

/// Use case that retrieves a filtered, paginated list of exam templates.
///
/// Supports filtering by school and category. Returns both school-specific
/// templates and public templates when no school filter is applied.
class GetExamTemplatesUseCase {
  GetExamTemplatesUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<List<ExamTemplateEntity>>> call(
    GetTemplatesParams params,
  ) async {
    // ── Validate pagination ───────────────────────────────────────────
    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page number must be at least 1',
          fieldErrors: {'page': 'Page number starts at 1'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Per page must be between 1 and 100',
          fieldErrors: {'perPage': 'Choose a value between 1 and 100'},
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getTemplates(
      schoolId: params.schoolId,
      category: params.category,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET EXAM TEMPLATE DETAIL
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [GetExamTemplateDetailUseCase].
class GetTemplateDetailParams {
  const GetTemplateDetailParams({
    required this.templateId,
  });

  /// The ID of the template to retrieve.
  final String templateId;
}

/// Use case that retrieves a single exam template with full details.
///
/// Returns the template entity including all sections and question
/// selection rules. Validates that a template ID is provided.
class GetExamTemplateDetailUseCase {
  GetExamTemplateDetailUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<ExamTemplateEntity>> call(
    GetTemplateDetailParams params,
  ) async {
    // ── Validate template ID ──────────────────────────────────────────
    if (params.templateId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required',
          fieldErrors: {'templateId': 'Please provide a template ID'},
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getTemplate(params.templateId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DELETE EXAM TEMPLATE
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [DeleteExamTemplateUseCase].
class DeleteTemplateParams {
  const DeleteTemplateParams({
    required this.templateId,
  });

  /// The ID of the template to delete.
  final String templateId;
}

/// Use case that permanently deletes an exam template.
///
/// Validates that a template ID is provided before delegating
/// to the repository. Only the creator or an admin should be
/// able to delete a template (enforced at the repository level).
class DeleteExamTemplateUseCase {
  DeleteExamTemplateUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<void>> call(DeleteTemplateParams params) async {
    // ── Validate template ID ──────────────────────────────────────────
    if (params.templateId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required',
          fieldErrors: {'templateId': 'Please provide a template ID'},
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.deleteTemplate(params.templateId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE EXAM FROM TEMPLATE
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [CreateExamFromTemplateUseCase].
class CreateExamFromTemplateParams {
  const CreateExamFromTemplateParams({
    required this.templateId,
    this.overrides = const {},
  });

  /// The ID of the template to base the new exam on.
  final String templateId;

  /// Optional field overrides applied to the new exam.
  ///
  /// Supported keys include: 'title', 'description', 'startTime',
  /// 'endTime', 'academicSessionId', 'timeLimitMinutes', 'passMark',
  /// and any other exam configuration field.
  final Map<String, dynamic> overrides;
}

/// Use case that creates a new exam from an existing template.
///
/// The template provides the base configuration, and [overrides]
/// allow customizing specific fields (e.g., title, time window)
/// without modifying the template itself. Question selection rules
/// in the template are executed to auto-populate questions from
/// the question bank.
class CreateExamFromTemplateUseCase {
  CreateExamFromTemplateUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<ExamEntity>> call(
    CreateExamFromTemplateParams params,
  ) async {
    // ── Validate template ID ──────────────────────────────────────────
    if (params.templateId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required',
          fieldErrors: {'templateId': 'Please provide a template ID'},
        ),
      );
    }

    // ── Validate overrides if title is provided ───────────────────────
    final titleOverride = params.overrides['title'];
    if (titleOverride is String && titleOverride.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Title override cannot be empty',
          fieldErrors: {'title': 'Provide a non-empty title or omit override'},
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.createExamFromTemplate(
      params.templateId,
      params.overrides,
    );
  }
}
