import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// The type of prompt template action to perform.
enum PromptAction {
  create('create'),
  update('update'),
  delete('delete'),
  get('get'),
  list('list');

  const PromptAction(this.value);

  /// The string representation stored in the backend.
  final String value;

  /// Parses a raw [value] string into a [PromptAction].
  ///
  /// Returns `null` if the value does not match any known action.
  static PromptAction? fromString(String? value) {
    if (value == null) return null;
    return PromptAction.values.cast<PromptAction?>().firstWhere(
          (action) => action?.value == value,
          orElse: () => null,
        );
  }
}

/// Parameters for the [ManagePromptTemplatesUseCase].
///
/// Different fields are required depending on [action]:
/// - **create / update**: [template] is required.
/// - **delete / get**: [templateId] is required.
/// - **list**: [promptType], [subjectId], and [curriculum] are optional
///   filters.
class ManagePromptParams {
  const ManagePromptParams({
    required this.action,
    this.template,
    this.templateId,
    this.promptType,
    this.subjectId,
    this.curriculum,
  });

  /// The action to perform.
  final PromptAction action;

  /// The template entity (required for create and update actions).
  final PromptTemplateEntity? template;

  /// The template ID (required for delete and get actions).
  final String? templateId;

  /// Optional filter by prompt type (for list action).
  final PromptType? promptType;

  /// Optional filter by subject ID (for list action).
  final String? subjectId;

  /// Optional filter by curriculum (for list action).
  final String? curriculum;
}

/// Use case that manages prompt templates through a unified interface.
///
/// Supports CRUD operations on prompt templates and listing with
/// filters. Validates that required fields are present based on the
/// requested [PromptAction], then delegates to the appropriate
/// repository method.
///
/// ```dart
/// // Create a template
/// final result = await managePromptTemplatesUseCase(
///   ManagePromptParams(
///     action: PromptAction.create,
///     template: PromptTemplateEntity(...),
///   ),
/// );
///
/// // List templates filtered by type
/// final result = await managePromptTemplatesUseCase(
///   ManagePromptParams(
///     action: PromptAction.list,
///     promptType: PromptType.questionGeneration,
///   ),
/// );
/// ```
class ManagePromptTemplatesUseCase {
  ManagePromptTemplatesUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<dynamic>> call(ManagePromptParams params) async {
    switch (params.action) {
      case PromptAction.create:
        return _handleCreate(params);
      case PromptAction.update:
        return _handleUpdate(params);
      case PromptAction.delete:
        return _handleDelete(params);
      case PromptAction.get:
        return _handleGet(params);
      case PromptAction.list:
        return _handleList(params);
    }
  }

  // ── Private Handlers ──────────────────────────────────────────────

  Future<Result<PromptTemplateEntity>> _handleCreate(
    ManagePromptParams params,
  ) async {
    if (params.template == null) {
      return const FailureResult(
        Failure.validation(
          message: 'Template data is required for creation',
          fieldErrors: {'template': 'Provide template details'},
        ),
      );
    }

    if (params.template!.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template name is required',
          fieldErrors: {'name': 'Enter a name for the template'},
        ),
      );
    }

    if (params.template!.systemPrompt.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'System prompt is required',
          fieldErrors: {'systemPrompt': 'Provide a system prompt'},
        ),
      );
    }

    if (params.template!.userPromptTemplate.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'User prompt template is required',
          fieldErrors: {
            'userPromptTemplate': 'Provide a user prompt template',
          },
        ),
      );
    }

    return _repository.createPromptTemplate(params.template!);
  }

  Future<Result<PromptTemplateEntity>> _handleUpdate(
    ManagePromptParams params,
  ) async {
    if (params.template == null) {
      return const FailureResult(
        Failure.validation(
          message: 'Template data is required for update',
          fieldErrors: {'template': 'Provide template details'},
        ),
      );
    }

    if (params.template!.id.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required for update',
          fieldErrors: {'id': 'Cannot update a template without an ID'},
        ),
      );
    }

    if (params.template!.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template name is required',
          fieldErrors: {'name': 'Template name cannot be empty'},
        ),
      );
    }

    return _repository.updatePromptTemplate(params.template!);
  }

  Future<Result<void>> _handleDelete(
    ManagePromptParams params,
  ) async {
    if (params.templateId == null || params.templateId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required for deletion',
          fieldErrors: {'templateId': 'Provide the template to delete'},
        ),
      );
    }

    // Delete is not directly supported by the repository, so we use
    // update with isActive = false (soft delete). This requires
    // fetching the template first.
    final templateResult = await _repository.getPromptTemplate(
      params.templateId!,
    );

    return templateResult.fold(
      onSuccess: (template) {
        return _repository.updatePromptTemplate(
          template.copyWith(isActive: false),
        );
      },
      onFailure: (failure) => FailureResult<void>(failure),
    );
  }

  Future<Result<PromptTemplateEntity>> _handleGet(
    ManagePromptParams params,
  ) async {
    if (params.templateId == null || params.templateId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Template ID is required',
          fieldErrors: {'templateId': 'Provide a template ID'},
        ),
      );
    }

    return _repository.getPromptTemplate(params.templateId!);
  }

  Future<Result<List<PromptTemplateEntity>>> _handleList(
    ManagePromptParams params,
  ) async {
    return _repository.getPromptTemplates(
      type: params.promptType,
      subjectId: params.subjectId,
      curriculum: params.curriculum,
    );
  }
}
