import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/repositories/question_bank_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION FILTER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the question filter panel.
///
/// Tracks the active filter as well as the available metadata options
/// (subjects, topics, categories, tags, sessions) that populate the
/// filter dropdowns.
class QuestionFilterState {
  const QuestionFilterState({
    this.filter = const QuestionFilterEntity(),
    this.availableSubjects = const [],
    this.availableTopics = const [],
    this.availableSubtopics = const [],
    this.availableCategories = const [],
    this.availableTags = const [],
    this.availableSessions = const [],
    this.isLoadingMetadata = false,
  });

  /// The currently applied filter criteria.
  final QuestionFilterEntity filter;

  /// Subjects available for the filter dropdown.
  final List<TopicEntity> availableSubjects;

  /// Topics available for the current subject.
  final List<TopicEntity> availableTopics;

  /// Subtopics available for the current topic.
  final List<SubtopicEntity> availableSubtopics;

  /// Categories available for the filter dropdown.
  final List<QuestionCategoryEntity> availableCategories;

  /// Tags available for the filter dropdown.
  final List<QuestionTagEntity> availableTags;

  /// Academic sessions available for the filter dropdown.
  final List<AcademicSessionEntity> availableSessions;

  /// Whether filter metadata is currently being loaded.
  final bool isLoadingMetadata;

  /// Creates a copy of this state with the given fields replaced.
  QuestionFilterState copyWith({
    QuestionFilterEntity? filter,
    List<TopicEntity>? availableSubjects,
    List<TopicEntity>? availableTopics,
    List<SubtopicEntity>? availableSubtopics,
    List<QuestionCategoryEntity>? availableCategories,
    List<QuestionTagEntity>? availableTags,
    List<AcademicSessionEntity>? availableSessions,
    bool? isLoadingMetadata,
  }) {
    return QuestionFilterState(
      filter: filter ?? this.filter,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      availableTopics: availableTopics ?? this.availableTopics,
      availableSubtopics: availableSubtopics ?? this.availableSubtopics,
      availableCategories: availableCategories ?? this.availableCategories,
      availableTags: availableTags ?? this.availableTags,
      availableSessions: availableSessions ?? this.availableSessions,
      isLoadingMetadata: isLoadingMetadata ?? this.isLoadingMetadata,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUESTION FILTER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the question filter state.
///
/// Handles loading filter metadata (subjects, topics, categories, tags,
/// sessions) from the repository and provides methods to update individual
/// filter fields. When a parent-level selection changes (e.g. subject),
/// child-level options are automatically reloaded (e.g. topics for the
/// selected subject).
class QuestionFilterNotifier extends StateNotifier<QuestionFilterState> {
  QuestionFilterNotifier({
    required QuestionBankRepository repository,
  })  : _repository = repository,
        super(const QuestionFilterState());

  final QuestionBankRepository _repository;

  // ─── Load Filter Metadata ───────────────────────────────────────────

  /// Loads all available metadata for the filter panel (subjects,
  /// categories, tags, sessions). Topics and subtopics are loaded
  /// separately when a subject or topic is selected.
  Future<void> loadFilterMetadata() async {
    state = state.copyWith(isLoadingMetadata: true);

    // Load categories, tags, and sessions in parallel.
    final categoriesResult = await _repository.getCategories();
    final tagsResult = await _repository.getTags();
    final sessionsResult = await _repository.getAcademicSessions();

    List<QuestionCategoryEntity> categories = [];
    List<QuestionTagEntity> tags = [];
    List<AcademicSessionEntity> sessions = [];

    categoriesResult.fold(
      onSuccess: (data) => categories = data,
      onFailure: (failure) =>
          AppLogger.warning('Failed to load categories: $failure'),
    );

    tagsResult.fold(
      onSuccess: (data) => tags = data,
      onFailure: (failure) =>
          AppLogger.warning('Failed to load tags: $failure'),
    );

    sessionsResult.fold(
      onSuccess: (data) => sessions = data,
      onFailure: (failure) =>
          AppLogger.warning('Failed to load sessions: $failure'),
    );

    state = state.copyWith(
      isLoadingMetadata: false,
      availableCategories: categories,
      availableTags: tags,
      availableSessions: sessions,
    );

    AppLogger.info('Filter metadata loaded');
  }

  // ─── Update Subject ─────────────────────────────────────────────────

  /// Updates the selected subject and reloads the topics for that subject.
  ///
  /// When the subject changes, the topic and subtopic selections are
  /// automatically cleared since they are no longer valid.
  Future<void> updateSubject(String? subjectId) async {
    final updatedFilter = state.filter.copyWith(
      subjectId: subjectId,
      topicId: null,
      subtopicId: null,
    );

    state = state.copyWith(
      filter: updatedFilter,
      availableTopics: [],
      availableSubtopics: [],
    );

    if (subjectId != null && subjectId.isNotEmpty) {
      final result = await _repository.getTopics(subjectId);
      result.fold(
        onSuccess: (topics) {
          state = state.copyWith(availableTopics: topics);
          AppLogger.info(
            'Loaded ${topics.length} topics for subject $subjectId',
          );
        },
        onFailure: (failure) {
          AppLogger.warning('Failed to load topics: $failure');
        },
      );
    }
  }

  // ─── Update Topic ───────────────────────────────────────────────────

  /// Updates the selected topic and reloads the subtopics for that topic.
  ///
  /// When the topic changes, the subtopic selection is automatically
  /// cleared since it is no longer valid.
  Future<void> updateTopic(String? topicId) async {
    final updatedFilter = state.filter.copyWith(
      topicId: topicId,
      subtopicId: null,
    );

    state = state.copyWith(
      filter: updatedFilter,
      availableSubtopics: [],
    );

    if (topicId != null && topicId.isNotEmpty) {
      final result = await _repository.getSubtopics(topicId);
      result.fold(
        onSuccess: (subtopics) {
          state = state.copyWith(availableSubtopics: subtopics);
          AppLogger.info(
            'Loaded ${subtopics.length} subtopics for topic $topicId',
          );
        },
        onFailure: (failure) {
          AppLogger.warning('Failed to load subtopics: $failure');
        },
      );
    }
  }

  // ─── Update Difficulty ──────────────────────────────────────────────

  /// Updates the selected difficulty level filter.
  void updateDifficulty(DifficultyLevel? difficulty) {
    state = state.copyWith(
      filter: state.filter.copyWith(difficulty: difficulty),
    );
  }

  // ─── Update Question Type ───────────────────────────────────────────

  /// Updates the selected question type filter.
  void updateQuestionType(QuestionType? questionType) {
    state = state.copyWith(
      filter: state.filter.copyWith(questionType: questionType),
    );
  }

  // ─── Update Exam Type ───────────────────────────────────────────────

  /// Updates the selected exam type filter.
  void updateExamType(ExamType? examType) {
    state = state.copyWith(
      filter: state.filter.copyWith(examType: examType),
    );
  }

  // ─── Update Subtopic ────────────────────────────────────────────────

  /// Updates the selected subtopic in the filter.
  void updateSubtopic(String? subtopicId) {
    state = state.copyWith(
      filter: state.filter.copyWith(subtopicId: subtopicId),
    );
  }

  // ─── Update Category ────────────────────────────────────────────────

  /// Updates the selected category in the filter.
  void updateCategory(String? categoryId) {
    state = state.copyWith(
      filter: state.filter.copyWith(categoryId: categoryId),
    );
  }

  // ─── Update Academic Session ────────────────────────────────────────

  /// Updates the selected academic session in the filter.
  void updateAcademicSession(String? sessionId) {
    state = state.copyWith(
      filter: state.filter.copyWith(academicSessionId: sessionId),
    );
  }

  // ─── Update Search Query ────────────────────────────────────────────

  /// Updates the search query string in the filter.
  void updateSearchQuery(String? query) {
    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: query),
    );
  }

  // ─── Update Sort By ─────────────────────────────────────────────────

  /// Updates the sort-by option in the filter.
  void updateSortBy(String sortBy) {
    state = state.copyWith(
      filter: state.filter.copyWith(sortBy: sortBy),
    );
  }

  // ─── Add Tag ────────────────────────────────────────────────────────

  /// Adds a tag to the filter's tag list.
  void addTag(String tag) {
    if (state.filter.tags.contains(tag)) return;
    final updatedTags = [...state.filter.tags, tag];
    state = state.copyWith(
      filter: state.filter.copyWith(tags: updatedTags),
    );
  }

  // ─── Remove Tag ─────────────────────────────────────────────────────

  /// Removes a tag from the filter's tag list.
  void removeTag(String tag) {
    final updatedTags = state.filter.tags.where((t) => t != tag).toList();
    state = state.copyWith(
      filter: state.filter.copyWith(tags: updatedTags),
    );
  }

  // ─── Clear All Filters ──────────────────────────────────────────────

  /// Resets all filter criteria to their default values and clears
  /// topic/subtopic metadata lists.
  void clearAllFilters() {
    state = const QuestionFilterState();
  }

  // ─── Getters ────────────────────────────────────────────────────────

  /// Returns the currently active filter entity.
  QuestionFilterEntity get currentFilter => state.filter;

  /// Whether any filter field is set to a non-default value.
  bool get hasActiveFilters {
    final f = state.filter;
    return f.subjectId != null ||
        f.topicId != null ||
        f.subtopicId != null ||
        f.classId != null ||
        f.categoryId != null ||
        f.difficulty != null ||
        f.questionType != null ||
        f.examType != null ||
        f.academicSessionId != null ||
        f.isPublished != null ||
        f.isArchived != null ||
        f.isFeatured != null ||
        f.createdBy != null ||
        (f.searchQuery != null && f.searchQuery!.isNotEmpty) ||
        f.tags.isNotEmpty ||
        f.sortBy != 'newest' ||
        f.page != 1 ||
        f.perPage != 20;
  }
}
