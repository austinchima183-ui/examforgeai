import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/exam_template_entities.dart';
import '../../domain/usecases/manage_exam_templates_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TEMPLATE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the exam template browsing and management
/// feature.
///
/// Tracks the current list of templates, the selected template for detail
/// view, loading flags, pagination state, category filter, and messages.
class ExamTemplateState {
  const ExamTemplateState({
    this.templates = const [],
    this.selectedTemplate,
    this.isLoading = false,
    this.isSaving = false,
    this.isCreating = false,
    this.error,
    this.successMessage,
    this.categoryFilter,
    this.currentPage = 1,
    this.totalCount = 0,
  });

  /// The current page of exam templates.
  final List<ExamTemplateEntity> templates;

  /// The template currently selected for detail view, or `null`.
  final ExamTemplateEntity? selectedTemplate;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a save-as-template operation is in progress.
  final bool isSaving;

  /// Whether a create-exam-from-template operation is in progress.
  final bool isCreating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Filter by template category.
  final TemplateCategory? categoryFilter;

  /// The current page number (1-based).
  final int currentPage;

  /// Total number of templates matching the current filter.
  final int totalCount;

  // ── Convenience getters ──────────────────────────────────────────────

  /// Number of templates currently loaded.
  int get loadedCount => templates.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSaving || isCreating;

  /// Whether there are more pages to load.
  bool get hasMore => loadedCount < totalCount;

  // ── copyWith ─────────────────────────────────────────────────────────

  ExamTemplateState copyWith({
    List<ExamTemplateEntity>? templates,
    ExamTemplateEntity? selectedTemplate,
    bool? isLoading,
    bool? isSaving,
    bool? isCreating,
    String? error,
    String? successMessage,
    TemplateCategory? categoryFilter,
    int? currentPage,
    int? totalCount,
  }) {
    return ExamTemplateState(
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      successMessage: successMessage,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  /// Clears the current error message.
  ExamTemplateState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ExamTemplateState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM TEMPLATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the exam template feature's state.
///
/// Provides methods for loading, filtering, paginating, saving, deleting,
/// and creating exams from templates.
class ExamTemplateNotifier extends StateNotifier<ExamTemplateState> {
  ExamTemplateNotifier({
    required SaveAsTemplateUseCase saveAsTemplateUseCase,
    required GetExamTemplatesUseCase getExamTemplatesUseCase,
    required GetExamTemplateDetailUseCase getExamTemplateDetailUseCase,
    required DeleteExamTemplateUseCase deleteExamTemplateUseCase,
    required CreateExamFromTemplateUseCase createExamFromTemplateUseCase,
  })  : _saveAsTemplateUseCase = saveAsTemplateUseCase,
        _getExamTemplatesUseCase = getExamTemplatesUseCase,
        _getExamTemplateDetailUseCase = getExamTemplateDetailUseCase,
        _deleteExamTemplateUseCase = deleteExamTemplateUseCase,
        _createExamFromTemplateUseCase = createExamFromTemplateUseCase,
        super(const ExamTemplateState());

  final SaveAsTemplateUseCase _saveAsTemplateUseCase;
  final GetExamTemplatesUseCase _getExamTemplatesUseCase;
  final GetExamTemplateDetailUseCase _getExamTemplateDetailUseCase;
  final DeleteExamTemplateUseCase _deleteExamTemplateUseCase;
  final CreateExamFromTemplateUseCase _createExamFromTemplateUseCase;

  static const int _perPage = 20;

  // ─── Load Templates (first page) ─────────────────────────────────────

  /// Loads the first page of exam templates using the current filter.
  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getExamTemplatesUseCase(
      GetTemplatesParams(
        category: state.categoryFilter,
        page: 1,
        perPage: _perPage,
      ),
    );

    result.fold(
      onSuccess: (templates) {
        state = state.copyWith(
          isLoading: false,
          templates: templates,
          currentPage: 1,
          totalCount: templates.length >= _perPage
              ? templates.length * state.currentPage
              : templates.length,
          error: null,
        );
        AppLogger.info('Loaded ${templates.length} exam templates (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load exam templates: $failure');
      },
    );
  }

  // ─── Load More (pagination) ──────────────────────────────────────────

  /// Loads the next page of templates and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _getExamTemplatesUseCase(
      GetTemplatesParams(
        category: state.categoryFilter,
        page: nextPage,
        perPage: _perPage,
      ),
    );

    result.fold(
      onSuccess: (templates) {
        final updatedList = [...state.templates, ...templates];
        state = state.copyWith(
          templates: updatedList,
          currentPage: nextPage,
          totalCount: templates.length >= _perPage
              ? updatedList.length + templates.length
              : updatedList.length,
          error: null,
        );
        AppLogger.info(
          'Loaded ${templates.length} more exam templates (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more templates: $failure');
      },
    );
  }

  // ─── Refresh ─────────────────────────────────────────────────────────

  /// Refreshes the template list by reloading the first page.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getExamTemplatesUseCase(
      GetTemplatesParams(
        category: state.categoryFilter,
        page: 1,
        perPage: _perPage,
      ),
    );

    result.fold(
      onSuccess: (templates) {
        state = state.copyWith(
          isLoading: false,
          templates: templates,
          currentPage: 1,
          totalCount: templates.length,
          error: null,
        );
        AppLogger.info('Refreshed exam templates list');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to refresh exam templates: $failure');
      },
    );
  }

  // ─── Set Category Filter ─────────────────────────────────────────────

  /// Updates the category filter and reloads the template list.
  Future<void> setCategoryFilter(TemplateCategory? category) async {
    state = state.copyWith(categoryFilter: category);
    await loadTemplates();
  }

  // ─── Clear Filters ───────────────────────────────────────────────────

  /// Resets all filters and reloads the template list.
  Future<void> clearFilters() async {
    state = state.copyWith(categoryFilter: null);
    await loadTemplates();
  }

  // ─── Get Template Detail ─────────────────────────────────────────────

  /// Loads a single template's full detail.
  Future<void> loadTemplateDetail(String templateId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getExamTemplateDetailUseCase(
      GetTemplateDetailParams(templateId: templateId),
    );

    result.fold(
      onSuccess: (template) {
        state = state.copyWith(
          isLoading: false,
          selectedTemplate: template,
          error: null,
        );
        AppLogger.info('Loaded template detail: $templateId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load template detail: $failure');
      },
    );
  }

  // ─── Save As Template ────────────────────────────────────────────────

  /// Saves an exam configuration as a reusable template.
  Future<void> saveAsTemplate(ExamTemplateEntity template) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);

    final result = await _saveAsTemplateUseCase(
      SaveAsTemplateParams(template: template),
    );

    result.fold(
      onSuccess: (savedTemplate) {
        final updatedList = [savedTemplate, ...state.templates];
        state = state.copyWith(
          isSaving: false,
          templates: updatedList,
          successMessage:
              'Template "${savedTemplate.name}" saved successfully!',
        );
        AppLogger.info('Template saved: ${savedTemplate.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to save as template: $failure');
      },
    );
  }

  // ─── Delete Template ─────────────────────────────────────────────────

  /// Deletes an exam template by its ID.
  Future<void> deleteTemplate(String templateId) async {
    final result = await _deleteExamTemplateUseCase(
      DeleteTemplateParams(templateId: templateId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.templates.where((t) => t.id != templateId).toList();
        state = state.copyWith(
          templates: updatedList,
          selectedTemplate: state.selectedTemplate?.id == templateId
              ? null
              : state.selectedTemplate,
          successMessage: 'Template deleted successfully.',
        );
        AppLogger.info('Template deleted: $templateId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete template: $failure');
      },
    );
  }

  // ─── Create Exam From Template ───────────────────────────────────────

  /// Creates a new exam from an existing template with optional overrides.
  Future<void> createExamFromTemplate(
    String templateId, {
    Map<String, dynamic> overrides = const {},
  }) async {
    state =
        state.copyWith(isCreating: true, error: null, successMessage: null);

    final result = await _createExamFromTemplateUseCase(
      CreateExamFromTemplateParams(
        templateId: templateId,
        overrides: overrides,
      ),
    );

    result.fold(
      onSuccess: (exam) {
        // Increment usage count for the used template in the local list
        final updatedList = state.templates
            .map((t) => t.id == templateId
                ? t.copyWith(usageCount: t.usageCount + 1)
                : t)
            .toList();
        state = state.copyWith(
          isCreating: false,
          templates: updatedList,
          successMessage: 'Exam "${exam.title}" created from template!',
        );
        AppLogger.info('Exam created from template: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create exam from template: $failure');
      },
    );
  }

  // ─── Clear Error ─────────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success ───────────────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccess() {
    state = state.clearSuccess();
  }

  // ─── Clear Selected Template ─────────────────────────────────────────

  /// Clears the currently selected template detail.
  void clearSelectedTemplate() {
    state = state.copyWith(selectedTemplate: null);
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
