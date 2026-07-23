import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the presentation feature.
class PresentationState {
  const PresentationState({
    this.presentations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.error,
    this.currentPresentation,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.successMessage,
  });

  /// The current page of presentations.
  final List<PresentationEntity> presentations;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a pagination (load-more) request is in progress.
  final bool isLoadingMore;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected presentation with full details, or `null`.
  final PresentationEntity? currentPresentation;

  /// Total number of presentations matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isLoadingMore || isCreating || isUpdating || isDeleting || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  PresentationState copyWith({
    List<PresentationEntity>? presentations,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    String? error,
    PresentationEntity? currentPresentation,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    String? successMessage,
  }) {
    return PresentationState(
      presentations: presentations ?? this.presentations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentPresentation: currentPresentation ?? this.currentPresentation,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  PresentationState clearError() => copyWith(error: null);

  /// Clears the current success message.
  PresentationState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the presentation feature's state.
class PresentationNotifier extends StateNotifier<PresentationState> {
  PresentationNotifier() : super(const PresentationState());

  // ─── Load Presentations ─────────────────────────────────────────────

  /// Loads the first page of presentations.
  Future<void> loadPresentations() async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Replace with actual use case call
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      isLoading: false,
      presentations: [],
      currentPage: 1,
      hasMore: false,
      error: null,
    );
    AppLogger.info('Loaded presentations (page 1)');
  }

  // ─── Generate Presentation (AI) ─────────────────────────────────────

  /// Generates a presentation using AI with the provided parameters.
  Future<void> generatePresentation({
    required String subject,
    String? className,
    required String topic,
    required PresentationType presentationType,
    required CurriculumType curriculum,
    required StudentLevel difficulty,
    required int slideCount,
    String? customInstructions,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);

    // TODO: Replace with actual AI generation use case call
    await Future.delayed(const Duration(seconds: 3));

    final now = DateTime.now();
    final slides = List<Map<String, dynamic>>.generate(
      slideCount,
      (i) => {
        'title': 'Slide ${i + 1}: ${_getSlideTitle(i, topic)}',
        'body': _getSlideBody(i, topic, subject),
        'speaker_notes': _getSpeakerNotes(i, topic),
      },
    );

    final presentation = PresentationEntity(
      id: 'gen_${now.millisecondsSinceEpoch}',
      teacherId: 'current_teacher',
      title: '$topic - $presentationType Presentation',
      presentationType: presentationType,
      slides: slides,
      totalSlides: slideCount,
      topic: topic,
      curriculum: curriculum,
      difficulty: difficulty,
      customInstructions: customInstructions,
      isAiGenerated: true,
      isPublished: false,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      isGenerating: false,
      currentPresentation: presentation,
      successMessage: 'Presentation generated successfully',
      error: null,
    );
    AppLogger.info('Presentation generated: ${presentation.id}');
  }

  // ─── Update Presentation ────────────────────────────────────────────

  /// Updates an existing presentation.
  Future<void> updatePresentation(PresentationEntity presentation) async {
    state = state.copyWith(isUpdating: true, error: null);

    // TODO: Replace with actual update use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.presentations
        .map((p) => p.id == presentation.id ? presentation : p)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      presentations: updatedList,
      currentPresentation: presentation,
      successMessage: 'Presentation updated successfully',
      error: null,
    );
    AppLogger.info('Presentation updated: ${presentation.id}');
  }

  // ─── Delete Presentation ────────────────────────────────────────────

  /// Deletes a presentation by [presentationId].
  Future<void> deletePresentation(String presentationId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // TODO: Replace with actual delete use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList =
        state.presentations.where((p) => p.id != presentationId).toList();

    state = state.copyWith(
      isDeleting: false,
      presentations: updatedList,
      currentPresentation: state.currentPresentation?.id == presentationId
          ? null
          : state.currentPresentation,
      successMessage: 'Presentation deleted successfully',
      error: null,
    );
    AppLogger.info('Presentation deleted: $presentationId');
  }

  // ─── Save Presentation ──────────────────────────────────────────────

  /// Saves a presentation (as draft or published).
  Future<void> savePresentation(PresentationEntity presentation, {required bool isDraft}) async {
    state = state.copyWith(isCreating: true, error: null);

    // TODO: Replace with actual create use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final savedPresentation = presentation.copyWith(
      isPublished: !isDraft,
    );

    final updatedList = [savedPresentation, ...state.presentations];

    state = state.copyWith(
      isCreating: false,
      presentations: updatedList,
      successMessage: isDraft ? 'Presentation saved as draft' : 'Presentation saved & published',
      error: null,
    );
    AppLogger.info('Presentation saved: ${presentation.id}');
  }

  // ─── Toggle Favorite ────────────────────────────────────────────────

  /// Toggles the favorite status of a presentation.
  Future<void> toggleFavorite(String presentationId) async {
    // Optimistically update
    final updatedList = state.presentations.map((p) {
      if (p.id == presentationId) {
        return p.copyWith(isFavorite: !p.isFavorite);
      }
      return p;
    }).toList();

    state = state.copyWith(
      presentations: updatedList,
      currentPresentation: state.currentPresentation?.id == presentationId
          ? state.currentPresentation!.copyWith(
              isFavorite: !state.currentPresentation!.isFavorite,)
          : state.currentPresentation,
      successMessage: 'Favorite updated',
      error: null,
    );
  }

  // ─── Share Presentation ─────────────────────────────────────────────

  /// Shares a presentation with colleagues.
  Future<void> sharePresentation(String presentationId) async {
    // TODO: Replace with actual share use case call
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      successMessage: 'Presentation shared with colleagues',
      error: null,
    );
    AppLogger.info('Presentation shared: $presentationId');
  }

  // ─── Export Presentation ────────────────────────────────────────────

  /// Exports a presentation in the specified format.
  Future<void> exportPresentation({
    required String presentationId,
    required String format,
  }) async {
    // TODO: Replace with actual export use case call
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      successMessage: 'Presentation exported as $format',
      error: null,
    );
    AppLogger.info('Presentation exported: $presentationId ($format)');
  }

  // ─── Set Current Presentation ───────────────────────────────────────

  /// Sets the currently selected presentation.
  void setCurrentPresentation(PresentationEntity? presentation) {
    state = state.copyWith(currentPresentation: presentation);
  }

  // ─── Clear Error / Success ──────────────────────────────────────────

  void clearError() => state = state.clearError();
  void clearSuccessMessage() => state = state.clearSuccessMessage();

  // ─── Private Helpers ────────────────────────────────────────────────

  String _getSlideTitle(int index, String topic) {
    const titles = [
      'Introduction', 'Learning Objectives', 'Key Concepts',
      'Detailed Explanation', 'Examples', 'Practice Problems',
      'Common Mistakes', 'Summary', 'Assessment', 'Further Reading',
    ];
    return titles[index % titles.length];
  }

  String _getSlideBody(int index, String topic, String subject) {
    return 'This slide covers key aspects of $topic in $subject. '
        'Students will learn the fundamental principles and apply them '
        'through practical exercises and examples.';
  }

  String _getSpeakerNotes(int index, String topic) {
    return 'Remember to engage students with questions about $topic. '
        'Use real-world examples to illustrate the concepts.';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final presentationProvider =
    StateNotifierProvider<PresentationNotifier, PresentationState>((ref) {
  return PresentationNotifier();
});
