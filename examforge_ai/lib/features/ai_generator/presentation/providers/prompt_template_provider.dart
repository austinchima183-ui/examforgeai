import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/usecases/manage_prompt_templates_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROMPT TEMPLATE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the prompt template management feature.
///
/// Tracks the list of templates, the currently selected template,
/// loading/saving flags, and filter state.
class PromptTemplateState {
  const PromptTemplateState({
    this.templates = const [],
    this.currentTemplate,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.filter,
  });

  /// The current list of prompt templates, optionally filtered.
  final List<PromptTemplateEntity> templates;

  /// The currently selected template for viewing/editing.
  final PromptTemplateEntity? currentTemplate;

  /// Whether templates are being loaded.
  final bool isLoading;

  /// Whether a template is being created or updated.
  final bool isSaving;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Optional filter on [PromptType] for the templates list.
  final PromptType? filter;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSaving;

  /// Number of templates currently loaded.
  int get templateCount => templates.length;

  /// Active templates (not soft-deleted).
  List<PromptTemplateEntity> get activeTemplates =>
      templates.where((t) => t.isActive).toList();

  /// Default templates.
  List<PromptTemplateEntity> get defaultTemplates =>
      templates.where((t) => t.isDefault).toList();

  /// Creates a copy of this state with the given fields replaced.
  PromptTemplateState copyWith({
    List<PromptTemplateEntity>? templates,
    PromptTemplateEntity? currentTemplate,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    PromptType? filter,
  }) {
    return PromptTemplateState(
      templates: templates ?? this.templates,
      currentTemplate: currentTemplate ?? this.currentTemplate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
      filter: filter ?? this.filter,
    );
  }

  /// Clears the current error message.
  PromptTemplateState clearError() => copyWith(error: null);

  /// Clears the current success message.
  PromptTemplateState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PROMPT TEMPLATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the prompt template
/// management feature's state.
///
/// Provides CRUD operations on prompt templates and listing with
/// optional filters.
class PromptTemplateNotifier extends StateNotifier<PromptTemplateState> {
  PromptTemplateNotifier({
    required ManagePromptTemplatesUseCase managePromptTemplatesUseCase,
  })  : _managePromptTemplatesUseCase = managePromptTemplatesUseCase,
        super(const PromptTemplateState());

  final ManagePromptTemplatesUseCase _managePromptTemplatesUseCase;

  // ─── Load Templates ──────────────────────────────────────────────

  /// Loads prompt templates, optionally filtered by [type] and
  /// [subjectId].
  Future<void> loadTemplates({PromptType? type, String? subjectId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _managePromptTemplatesUseCase(
      ManagePromptParams(
        action: PromptAction.list,
        promptType: type ?? state.filter,
        subjectId: subjectId,
      ),
    );

    result.fold(
      onSuccess: (data) {
        final List<PromptTemplateEntity> templates = [];
        if (data is List<PromptTemplateEntity>) {
          templates.addAll(data);
        }
        state = state.copyWith(
          isLoading: false,
          templates: templates,
          filter: type ?? state.filter,
          error: null,
        );
        AppLogger.info('Loaded ${templates.length} prompt templates');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load templates: $failure');
      },
    );
  }

  // ─── Load Single Template ────────────────────────────────────────

  /// Loads a single prompt template by [templateId].
  Future<void> loadTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _managePromptTemplatesUseCase(
      ManagePromptParams(
        action: PromptAction.get,
        templateId: templateId,
      ),
    );

    result.fold(
      onSuccess: (data) {
        if (data is PromptTemplateEntity) {
          state = state.copyWith(
            isLoading: false,
            currentTemplate: data,
            error: null,
          );
          AppLogger.info('Loaded template: ${data.name}');
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Unexpected response type',
          );
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load template: $failure');
      },
    );
  }

  // ─── Create Template ─────────────────────────────────────────────

  /// Creates a new prompt template.
  Future<void> createTemplate(PromptTemplateEntity template) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _managePromptTemplatesUseCase(
      ManagePromptParams(
        action: PromptAction.create,
        template: template,
      ),
    );

    result.fold(
      onSuccess: (data) {
        if (data is PromptTemplateEntity) {
          final updatedTemplates = [data, ...state.templates];
          state = state.copyWith(
            isSaving: false,
            templates: updatedTemplates,
            currentTemplate: data,
            successMessage: 'Template created successfully',
            error: null,
          );
          AppLogger.info('Template created: ${data.name}');
        } else {
          state = state.copyWith(
            isSaving: false,
            successMessage: 'Template created successfully',
            error: null,
          );
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create template: $failure');
      },
    );
  }

  // ─── Update Template ─────────────────────────────────────────────

  /// Updates an existing prompt template.
  Future<void> updateTemplate(PromptTemplateEntity template) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _managePromptTemplatesUseCase(
      ManagePromptParams(
        action: PromptAction.update,
        template: template,
      ),
    );

    result.fold(
      onSuccess: (data) {
        if (data is PromptTemplateEntity) {
          final updatedTemplates = state.templates
              .map((t) => t.id == data.id ? data : t)
              .toList();
          state = state.copyWith(
            isSaving: false,
            templates: updatedTemplates,
            currentTemplate: state.currentTemplate?.id == data.id
                ? data
                : state.currentTemplate,
            successMessage: 'Template updated successfully',
            error: null,
          );
          AppLogger.info('Template updated: ${data.name}');
        } else {
          state = state.copyWith(
            isSaving: false,
            successMessage: 'Template updated successfully',
            error: null,
          );
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update template: $failure');
      },
    );
  }

  // ─── Delete Template ─────────────────────────────────────────────

  /// Soft-deletes a prompt template by setting `isActive` to `false`.
  Future<void> deleteTemplate(String templateId) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _managePromptTemplatesUseCase(
      ManagePromptParams(
        action: PromptAction.delete,
        templateId: templateId,
      ),
    );

    result.fold(
      onSuccess: (_) {
        // Soft-delete means the template is still in the list but
        // isActive = false. Refresh to reflect the change.
        final updatedTemplates = state.templates
            .where((t) => t.id != templateId)
            .toList();
        state = state.copyWith(
          isSaving: false,
          templates: updatedTemplates,
          currentTemplate: state.currentTemplate?.id == templateId
              ? null
              : state.currentTemplate,
          successMessage: 'Template deleted',
          error: null,
        );
        AppLogger.info('Template deleted: $templateId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete template: $failure');
      },
    );
  }

  // ─── Filter ──────────────────────────────────────────────────────

  /// Sets the prompt type filter and reloads templates.
  void setFilter(PromptType? filter) {
    state = state.copyWith(filter: filter);
    loadTemplates(type: filter);
  }

  // ─── Clear Error ─────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}
