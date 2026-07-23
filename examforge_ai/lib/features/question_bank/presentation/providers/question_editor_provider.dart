import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../../domain/usecases/create_question_usecase.dart';
import '../../domain/usecases/manage_question_status_usecase.dart';
import '../../domain/usecases/update_question_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION EDITOR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the question editor form.
///
/// Holds all form fields, type-specific answer data (answer options,
/// matching pairs, ordering items, fill-in-blank answers), attachments,
/// tags, and loading/error state for the editor.
class QuestionEditorState {
  const QuestionEditorState({
    this.question,
    this.answerOptions = const [],
    this.matchingPairs = const [],
    this.orderingItems = const [],
    this.fillInBlankAnswers = const [],
    this.attachments = const [],
    this.selectedTags = const [],
    this.isSaving = false,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.isPreviewMode = false,
    // Form fields
    this.content = '',
    this.explanation = '',
    this.teacherNotes = '',
    this.referenceMaterials = '',
    this.selectedQuestionType = QuestionType.multipleChoice,
    this.selectedDifficulty = DifficultyLevel.medium,
    this.selectedExamType = ExamType.schoolExam,
    this.selectedSubjectId,
    this.selectedTopicId,
    this.selectedSubtopicId,
    this.selectedClassId,
    this.selectedCategoryId,
    this.marks = 1.0,
    this.negativeMarks = 0.0,
    this.timeAllowedSeconds,
    // Loaded metadata for dropdowns
    this.availableTopics = const [],
    this.availableSubtopics = const [],
    this.isLoadingTopics = false,
    this.isLoadingSubtopics = false,
  });

  /// The original question being edited, or `null` for create mode.
  final QuestionEntity? question;

  /// Answer options for choice-based questions.
  final List<AnswerOptionEntity> answerOptions;

  /// Matching pairs for matching-type questions.
  final List<MatchingPairEntity> matchingPairs;

  /// Ordering items for ordering-type questions.
  final List<OrderingItemEntity> orderingItems;

  /// Fill-in-the-blank answers for fill-in-blank questions.
  final List<FillInBlankAnswerEntity> fillInBlankAnswers;

  /// Attachments (images, audio, video, documents).
  final List<QuestionAttachmentEntity> attachments;

  /// Tags selected for this question.
  final List<QuestionTagEntity> selectedTags;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// Whether the question is being loaded for edit mode.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A success message after a save operation, or `null`.
  final String? successMessage;

  /// Whether the editor is in preview mode.
  final bool isPreviewMode;

  // ── Form Fields ──────────────────────────────────────────────────────

  /// The question content / stem text.
  final String content;

  /// The explanation for the correct answer.
  final String explanation;

  /// Teacher-only notes (not visible to students).
  final String teacherNotes;

  /// Reference materials or source attribution.
  final String referenceMaterials;

  /// The selected question type.
  final QuestionType selectedQuestionType;

  /// The selected difficulty level.
  final DifficultyLevel selectedDifficulty;

  /// The selected exam type.
  final ExamType selectedExamType;

  /// The selected subject ID.
  final String? selectedSubjectId;

  /// The selected topic ID.
  final String? selectedTopicId;

  /// The selected subtopic ID.
  final String? selectedSubtopicId;

  /// The selected class ID.
  final String? selectedClassId;

  /// The selected category ID.
  final String? selectedCategoryId;

  /// The marks allocated to this question.
  final double marks;

  /// The negative marks for incorrect answers.
  final double negativeMarks;

  /// The time allowed for this question in seconds.
  final int? timeAllowedSeconds;

  // ── Loaded Metadata ──────────────────────────────────────────────────

  /// Topics available for the selected subject.
  final List<TopicEntity> availableTopics;

  /// Subtopics available for the selected topic.
  final List<SubtopicEntity> availableSubtopics;

  /// Whether topics are being loaded.
  final bool isLoadingTopics;

  /// Whether subtopics are being loaded.
  final bool isLoadingSubtopics;

  // ── Computed Properties ──────────────────────────────────────────────

  /// Whether the editor is in edit mode (editing an existing question).
  bool get isEditMode => question != null;

  /// Whether any async operation is in progress.
  bool get isBusy => isSaving || isLoading;

  /// Whether the current question type requires answer options.
  bool get requiresAnswerOptions => selectedQuestionType.hasOptions;

  /// Whether the current question type requires matching pairs.
  bool get requiresMatchingPairs => selectedQuestionType == QuestionType.matching;

  /// Whether the current question type requires ordering items.
  bool get requiresOrderingItems => selectedQuestionType == QuestionType.ordering;

  /// Whether the current question type requires fill-in-blank answers.
  bool get requiresFillInBlank => selectedQuestionType == QuestionType.fillInBlank;

  /// Creates a copy of this state with the given fields replaced.
  QuestionEditorState copyWith({
    QuestionEntity? question,
    List<AnswerOptionEntity>? answerOptions,
    List<MatchingPairEntity>? matchingPairs,
    List<OrderingItemEntity>? orderingItems,
    List<FillInBlankAnswerEntity>? fillInBlankAnswers,
    List<QuestionAttachmentEntity>? attachments,
    List<QuestionTagEntity>? selectedTags,
    bool? isSaving,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? isPreviewMode,
    String? content,
    String? explanation,
    String? teacherNotes,
    String? referenceMaterials,
    QuestionType? selectedQuestionType,
    DifficultyLevel? selectedDifficulty,
    ExamType? selectedExamType,
    String? selectedSubjectId,
    String? selectedTopicId,
    String? selectedSubtopicId,
    String? selectedClassId,
    String? selectedCategoryId,
    double? marks,
    double? negativeMarks,
    int? timeAllowedSeconds,
    List<TopicEntity>? availableTopics,
    List<SubtopicEntity>? availableSubtopics,
    bool? isLoadingTopics,
    bool? isLoadingSubtopics,
  }) {
    return QuestionEditorState(
      question: question ?? this.question,
      answerOptions: answerOptions ?? this.answerOptions,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      orderingItems: orderingItems ?? this.orderingItems,
      fillInBlankAnswers: fillInBlankAnswers ?? this.fillInBlankAnswers,
      attachments: attachments ?? this.attachments,
      selectedTags: selectedTags ?? this.selectedTags,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      content: content ?? this.content,
      explanation: explanation ?? this.explanation,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      referenceMaterials: referenceMaterials ?? this.referenceMaterials,
      selectedQuestionType: selectedQuestionType ?? this.selectedQuestionType,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      selectedExamType: selectedExamType ?? this.selectedExamType,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedTopicId: selectedTopicId ?? this.selectedTopicId,
      selectedSubtopicId: selectedSubtopicId ?? this.selectedSubtopicId,
      selectedClassId: selectedClassId ?? this.selectedClassId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      marks: marks ?? this.marks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      timeAllowedSeconds: timeAllowedSeconds ?? this.timeAllowedSeconds,
      availableTopics: availableTopics ?? this.availableTopics,
      availableSubtopics: availableSubtopics ?? this.availableSubtopics,
      isLoadingTopics: isLoadingTopics ?? this.isLoadingTopics,
      isLoadingSubtopics: isLoadingSubtopics ?? this.isLoadingSubtopics,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUESTION EDITOR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the question editor form state.
///
/// Handles loading an existing question for editing, managing all form
/// fields and type-specific answer data, and creating/updating questions
/// through the use cases.
class QuestionEditorNotifier extends StateNotifier<QuestionEditorState> {
  QuestionEditorNotifier({
    required CreateQuestionUseCase createQuestionUseCase,
    required UpdateQuestionUseCase updateQuestionUseCase,
    required ManageQuestionStatusUseCase manageQuestionStatusUseCase,
    required QuestionBankRepository repository,
  })  : _createQuestionUseCase = createQuestionUseCase,
        _updateQuestionUseCase = updateQuestionUseCase,
        _manageQuestionStatusUseCase = manageQuestionStatusUseCase,
        _repository = repository,
        super(const QuestionEditorState());

  final CreateQuestionUseCase _createQuestionUseCase;
  final UpdateQuestionUseCase _updateQuestionUseCase;
  final ManageQuestionStatusUseCase _manageQuestionStatusUseCase;
  final QuestionBankRepository _repository;

  // ─── Load Question for Edit ─────────────────────────────────────────

  /// Loads a question by [questionId] and populates all form fields.
  ///
  /// Used when editing an existing question. The form fields are
  /// populated from the loaded entity.
  Future<void> loadQuestionForEdit(String questionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getQuestionWithDetails(questionId);

    result.fold(
      onSuccess: (question) {
        state = state.copyWith(
          isLoading: false,
          question: question,
          content: question.content,
          explanation: question.explanation ?? '',
          teacherNotes: question.teacherNotes ?? '',
          referenceMaterials: question.referenceMaterials ?? '',
          selectedQuestionType: question.questionType,
          selectedDifficulty: question.difficulty,
          selectedExamType: question.examType ?? ExamType.schoolExam,
          selectedSubjectId: question.subjectId,
          selectedTopicId: question.topicId,
          selectedSubtopicId: question.subtopicId,
          selectedClassId: question.classId,
          selectedCategoryId: question.categoryId,
          marks: question.marks,
          negativeMarks: question.negativeMarks,
          timeAllowedSeconds: question.timeAllowedSeconds,
          answerOptions: question.answerOptions,
          matchingPairs: question.matchingPairs,
          orderingItems: question.orderingItems,
          fillInBlankAnswers: question.fillInBlankAnswers,
          attachments: question.attachments,
          selectedTags: question.tags,
          error: null,
        );

        // Load topics for the selected subject.
        if (question.subjectId.isNotEmpty) {
          _loadTopicsForSubject(question.subjectId);
        }
        // Load subtopics for the selected topic.
        if (question.topicId != null && question.topicId!.isNotEmpty) {
          _loadSubtopicsForTopic(question.topicId!);
        }

        AppLogger.info('Loaded question for edit: ${question.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load question for edit: $failure');
      },
    );
  }

  // ─── Form Field Setters ─────────────────────────────────────────────

  /// Sets the question content / stem text.
  void setContent(String content) {
    state = state.copyWith(content: content);
  }

  /// Sets the explanation for the correct answer.
  void setExplanation(String explanation) {
    state = state.copyWith(explanation: explanation);
  }

  /// Sets the teacher-only notes.
  void setTeacherNotes(String notes) {
    state = state.copyWith(teacherNotes: notes);
  }

  /// Sets the reference materials.
  void setReferenceMaterials(String materials) {
    state = state.copyWith(referenceMaterials: materials);
  }

  /// Sets the question type and resets type-specific fields.
  ///
  /// When the question type changes, answer options, matching pairs,
  /// ordering items, and fill-in-blank answers are reset to empty lists
  /// to prevent stale data from being submitted.
  void setQuestionType(QuestionType type) {
    state = state.copyWith(
      selectedQuestionType: type,
      // Reset type-specific fields to avoid stale data.
      answerOptions: [],
      matchingPairs: [],
      orderingItems: [],
      fillInBlankAnswers: [],
    );

    // Add default answer options for choice-based types.
    if (type.hasOptions) {
      _addDefaultAnswerOptions(type);
    }
  }

  /// Sets the difficulty level.
  void setDifficulty(DifficultyLevel difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
  }

  /// Sets the exam type.
  void setExamType(ExamType examType) {
    state = state.copyWith(selectedExamType: examType);
  }

  /// Sets the subject and loads the available topics.
  Future<void> setSubject(String? subjectId) async {
    state = state.copyWith(
      selectedSubjectId: subjectId,
      selectedTopicId: null,
      selectedSubtopicId: null,
      availableTopics: [],
      availableSubtopics: [],
    );

    if (subjectId != null && subjectId.isNotEmpty) {
      await _loadTopicsForSubject(subjectId);
    }
  }

  /// Sets the topic and loads the available subtopics.
  Future<void> setTopic(String? topicId) async {
    state = state.copyWith(
      selectedTopicId: topicId,
      selectedSubtopicId: null,
      availableSubtopics: [],
    );

    if (topicId != null && topicId.isNotEmpty) {
      await _loadSubtopicsForTopic(topicId);
    }
  }

  /// Sets the subtopic.
  void setSubtopic(String? subtopicId) {
    state = state.copyWith(selectedSubtopicId: subtopicId);
  }

  /// Sets the class.
  void setClass(String? classId) {
    state = state.copyWith(selectedClassId: classId);
  }

  /// Sets the category.
  void setCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  /// Sets the marks allocated to the question.
  void setMarks(double marks) {
    state = state.copyWith(marks: marks);
  }

  /// Sets the negative marks for incorrect answers.
  void setNegativeMarks(double negativeMarks) {
    state = state.copyWith(negativeMarks: negativeMarks);
  }

  /// Sets the time allowed for the question in seconds.
  void setTimeAllowed(int? seconds) {
    state = state.copyWith(timeAllowedSeconds: seconds);
  }

  // ─── Answer Options Management ──────────────────────────────────────

  /// Adds a new blank answer option.
  void addAnswerOption() {
    final now = DateTime.now();
    final index = state.answerOptions.length;
    final option = AnswerOptionEntity(
      id: 'new-${index + 1}',
      questionId: state.question?.id ?? '',
      content: '',
      isCorrect: false,
      marks: 0.0,
      sortOrder: index,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(
      answerOptions: [...state.answerOptions, option],
    );
  }

  /// Removes the answer option at [index].
  void removeAnswerOption(int index) {
    if (index < 0 || index >= state.answerOptions.length) return;
    final updated = [...state.answerOptions];
    updated.removeAt(index);
    // Re-sort remaining options.
    final reindexed = updated
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();
    state = state.copyWith(answerOptions: reindexed);
  }

  /// Updates the answer option at [index] with the provided [option].
  void updateAnswerOption(int index, AnswerOptionEntity option) {
    if (index < 0 || index >= state.answerOptions.length) return;
    final updated = [...state.answerOptions];
    updated[index] = option;
    state = state.copyWith(answerOptions: updated);
  }

  /// Marks the answer option at [index] as the single correct answer.
  ///
  /// All other options are set to `isCorrect: false`.
  void setCorrectAnswer(int index) {
    final updated = state.answerOptions.asMap().entries.map((e) {
      return e.value.copyWith(isCorrect: e.key == index);
    }).toList();
    state = state.copyWith(answerOptions: updated);
  }

  /// Marks multiple answer options as correct (for multiple response).
  ///
  /// The options at the given [indices] are set to `isCorrect: true`,
  /// and all others are set to `isCorrect: false`.
  void setCorrectAnswers(List<int> indices) {
    final updated = state.answerOptions.asMap().entries.map((e) {
      return e.value.copyWith(isCorrect: indices.contains(e.key));
    }).toList();
    state = state.copyWith(answerOptions: updated);
  }

  // ─── Matching Pairs Management ──────────────────────────────────────

  /// Adds a new blank matching pair.
  void addMatchingPair() {
    final now = DateTime.now();
    final index = state.matchingPairs.length;
    final pair = MatchingPairEntity(
      id: 'new-mp-${index + 1}',
      questionId: state.question?.id ?? '',
      leftContent: '',
      rightContent: '',
      sortOrder: index,
      createdAt: now,
    );
    state = state.copyWith(
      matchingPairs: [...state.matchingPairs, pair],
    );
  }

  /// Removes the matching pair at [index].
  void removeMatchingPair(int index) {
    if (index < 0 || index >= state.matchingPairs.length) return;
    final updated = [...state.matchingPairs];
    updated.removeAt(index);
    final reindexed = updated
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();
    state = state.copyWith(matchingPairs: reindexed);
  }

  /// Updates the matching pair at [index] with the provided [pair].
  void updateMatchingPair(int index, MatchingPairEntity pair) {
    if (index < 0 || index >= state.matchingPairs.length) return;
    final updated = [...state.matchingPairs];
    updated[index] = pair;
    state = state.copyWith(matchingPairs: updated);
  }

  // ─── Ordering Items Management ──────────────────────────────────────

  /// Adds a new blank ordering item.
  void addOrderingItem() {
    final now = DateTime.now();
    final index = state.orderingItems.length;
    final item = OrderingItemEntity(
      id: 'new-oi-${index + 1}',
      questionId: state.question?.id ?? '',
      content: '',
      correctPosition: index,
      createdAt: now,
    );
    state = state.copyWith(
      orderingItems: [...state.orderingItems, item],
    );
  }

  /// Removes the ordering item at [index].
  void removeOrderingItem(int index) {
    if (index < 0 || index >= state.orderingItems.length) return;
    final updated = [...state.orderingItems];
    updated.removeAt(index);
    // Re-index correct positions.
    final reindexed = updated.asMap().entries.map((e) {
      return e.value.copyWith(correctPosition: e.key);
    }).toList();
    state = state.copyWith(orderingItems: reindexed);
  }

  /// Updates the ordering item at [index] with the provided [item].
  void updateOrderingItem(int index, OrderingItemEntity item) {
    if (index < 0 || index >= state.orderingItems.length) return;
    final updated = [...state.orderingItems];
    updated[index] = item;
    state = state.copyWith(orderingItems: updated);
  }

  /// Reorders ordering items by moving an item from [oldIndex] to
  /// [newIndex].
  void reorderOrderingItems(int oldIndex, int newIndex) {
    final items = [...state.orderingItems];
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex >= items.length) {
      return;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    // Re-index correct positions.
    final reindexed = items.asMap().entries.map((e) {
      return e.value.copyWith(correctPosition: e.key);
    }).toList();
    state = state.copyWith(orderingItems: reindexed);
  }

  // ─── Fill in Blank Management ───────────────────────────────────────

  /// Adds a new fill-in-the-blank answer entry.
  void addFillInBlank() {
    final now = DateTime.now();
    final index = state.fillInBlankAnswers.length;
    final answer = FillInBlankAnswerEntity(
      id: 'new-fib-${index + 1}',
      questionId: state.question?.id ?? '',
      blankIndex: index,
      acceptableAnswers: const [''],
      isCaseSensitive: false,
      marks: 0.0,
      createdAt: now,
    );
    state = state.copyWith(
      fillInBlankAnswers: [...state.fillInBlankAnswers, answer],
    );
  }

  /// Removes the fill-in-the-blank answer at [index].
  void removeFillInBlank(int index) {
    if (index < 0 || index >= state.fillInBlankAnswers.length) return;
    final updated = [...state.fillInBlankAnswers];
    updated.removeAt(index);
    // Re-index blanks.
    final reindexed = updated.asMap().entries.map((e) {
      return e.value.copyWith(blankIndex: e.key);
    }).toList();
    state = state.copyWith(fillInBlankAnswers: reindexed);
  }

  /// Updates the fill-in-the-blank answer at [index] with the provided
  /// [answer].
  void updateFillInBlank(int index, FillInBlankAnswerEntity answer) {
    if (index < 0 || index >= state.fillInBlankAnswers.length) return;
    final updated = [...state.fillInBlankAnswers];
    updated[index] = answer;
    state = state.copyWith(fillInBlankAnswers: updated);
  }

  // ─── Attachments Management ─────────────────────────────────────────

  /// Adds an attachment to the question.
  void addAttachment(QuestionAttachmentEntity attachment) {
    state = state.copyWith(
      attachments: [...state.attachments, attachment],
    );
  }

  /// Removes an attachment by its [attachmentId].
  void removeAttachment(String attachmentId) {
    final updated = state.attachments.where((a) => a.id != attachmentId).toList();
    state = state.copyWith(attachments: updated);
  }

  /// Replaces the entire answer options list.
  void updateAnswerOptions(List<AnswerOptionEntity> options) {
    state = state.copyWith(answerOptions: options);
  }

  /// Replaces the entire matching pairs list.
  void updateMatchingPairs(List<MatchingPairEntity> pairs) {
    state = state.copyWith(matchingPairs: pairs);
  }

  /// Replaces the entire ordering items list.
  void updateOrderingItems(List<OrderingItemEntity> items) {
    state = state.copyWith(orderingItems: items);
  }

  /// Replaces the entire fill-in-blank answers list.
  void updateFillInBlankAnswers(List<FillInBlankAnswerEntity> answers) {
    state = state.copyWith(fillInBlankAnswers: answers);
  }

  // ─── Tags Management ────────────────────────────────────────────────

  /// Adds a tag to the question.
  void addTag(QuestionTagEntity tag) {
    if (state.selectedTags.any((t) => t.id == tag.id)) return;
    state = state.copyWith(
      selectedTags: [...state.selectedTags, tag],
    );
  }

  /// Removes a tag by [tagId].
  void removeTag(String tagId) {
    final updated = state.selectedTags.where((t) => t.id != tagId).toList();
    state = state.copyWith(selectedTags: updated);
  }

  // ─── Save Question ──────────────────────────────────────────────────

  /// Saves the question by creating a new one or updating an existing one,
  /// depending on whether a question ID exists.
  ///
  /// Validates all required fields before saving.
  Future<void> saveQuestion() async {
    if (!validateForm()) return;

    state = state.copyWith(isSaving: true, error: null);

    final now = DateTime.now();
    final questionEntity = QuestionEntity(
      id: state.question?.id ?? '',
      schoolId: state.question?.schoolId,
      subjectId: state.selectedSubjectId ?? '',
      topicId: state.selectedTopicId,
      subtopicId: state.selectedSubtopicId,
      classId: state.selectedClassId,
      categoryId: state.selectedCategoryId,
      questionType: state.selectedQuestionType,
      difficulty: state.selectedDifficulty,
      examType: state.selectedExamType,
      content: state.content,
      explanation: state.explanation.isNotEmpty ? state.explanation : null,
      teacherNotes:
          state.teacherNotes.isNotEmpty ? state.teacherNotes : null,
      referenceMaterials: state.referenceMaterials.isNotEmpty
          ? state.referenceMaterials
          : null,
      marks: state.marks,
      negativeMarks: state.negativeMarks,
      timeAllowedSeconds: state.timeAllowedSeconds,
      isPublished: state.question?.isPublished ?? false,
      isArchived: state.question?.isArchived ?? false,
      isFeatured: state.question?.isFeatured ?? false,
      version: state.question?.version ?? 1,
      createdBy: state.question?.createdBy,
      updatedBy: state.question?.updatedBy,
      createdAt: state.question?.createdAt ?? now,
      updatedAt: now,
      answerOptions: state.answerOptions,
      matchingPairs: state.matchingPairs,
      orderingItems: state.orderingItems,
      fillInBlankAnswers: state.fillInBlankAnswers,
      attachments: state.attachments,
      tags: state.selectedTags,
    );

    if (state.isEditMode) {
      final result = await _updateQuestionUseCase(
        UpdateQuestionParams(
          question: questionEntity,
          answerOptions: state.answerOptions,
          matchingPairs: state.matchingPairs,
          orderingItems: state.orderingItems,
          fillInBlankAnswers: state.fillInBlankAnswers,
          attachments: state.attachments,
          tagIds: state.selectedTags.map((t) => t.id).toList(),
        ),
      );

      result.fold(
        onSuccess: (updatedQuestion) {
          state = state.copyWith(
            isSaving: false,
            question: updatedQuestion,
            error: null,
            successMessage: 'Question updated successfully',
          );
          AppLogger.info('Question updated: ${updatedQuestion.id}');
        },
        onFailure: (failure) {
          state = state.copyWith(
            isSaving: false,
            error: _mapFailureToMessage(failure),
          );
          AppLogger.warning('Failed to update question: $failure');
        },
      );
    } else {
      final result = await _createQuestionUseCase(
        CreateQuestionParams(
          question: questionEntity,
          answerOptions: state.answerOptions,
          matchingPairs: state.matchingPairs,
          orderingItems: state.orderingItems,
          fillInBlankAnswers: state.fillInBlankAnswers,
          attachments: state.attachments,
          tagIds: state.selectedTags.map((t) => t.id).toList(),
        ),
      );

      result.fold(
        onSuccess: (createdQuestion) {
          state = state.copyWith(
            isSaving: false,
            question: createdQuestion,
            error: null,
            successMessage: 'Question created successfully',
          );
          AppLogger.info('Question created: ${createdQuestion.id}');
        },
        onFailure: (failure) {
          state = state.copyWith(
            isSaving: false,
            error: _mapFailureToMessage(failure),
          );
          AppLogger.warning('Failed to create question: $failure');
        },
      );
    }
  }

  /// Saves the question as a draft (not published).
  Future<void> saveAsDraft() async {
    await saveQuestion();
  }

  // ─── Save and Publish ───────────────────────────────────────────────

  /// Saves the question and then publishes it.
  Future<void> saveAndPublish() async {
    await saveQuestion();

    // Only publish if the save succeeded (no error and question has an ID).
    if (state.error == null && state.question != null) {
      final questionId = state.question!.id;
      if (questionId.isNotEmpty) {
        final result = await _manageQuestionStatusUseCase(
          ManageQuestionStatusParams(
            questionId: questionId,
            action: QuestionStatusAction.publish,
          ),
        );

        result.fold(
          onSuccess: (_) {
            state = state.copyWith(
              question: state.question?.copyWith(isPublished: true),
            );
            AppLogger.info('Question published: $questionId');
          },
          onFailure: (failure) {
            state = state.copyWith(
              error: _mapFailureToMessage(failure),
            );
            AppLogger.warning('Failed to publish question: $failure');
          },
        );
      }
    }
  }

  // ─── Toggle Preview Mode ────────────────────────────────────────────

  /// Toggles the preview mode state.
  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  // ─── Reset Form ─────────────────────────────────────────────────────

  /// Resets all form fields and state to their default values.
  void resetForm() {
    state = const QuestionEditorState();
  }

  // ─── Validate Form ──────────────────────────────────────────────────

  /// Validates all required form fields and type-specific data.
  ///
  /// Returns `true` if the form is valid, `false` otherwise.
  /// Sets the [error] field with a validation message when invalid.
  bool validateForm() {
    // ── Content ────────────────────────────────────────────────────────
    if (state.content.trim().isEmpty) {
      state = state.copyWith(error: 'Question content is required');
      return false;
    }

    // ── Subject ────────────────────────────────────────────────────────
    if (state.selectedSubjectId == null ||
        state.selectedSubjectId!.isEmpty) {
      state = state.copyWith(error: 'Please select a subject');
      return false;
    }

    // ── Marks ──────────────────────────────────────────────────────────
    if (state.marks <= 0) {
      state = state.copyWith(error: 'Marks must be greater than zero');
      return false;
    }

    // ── Type-specific validation ───────────────────────────────────────
    final type = state.selectedQuestionType;

    // Answer options for choice-based types.
    if (type.hasOptions && state.answerOptions.isEmpty) {
      state = state.copyWith(
        error: '${type.label} questions require at least one answer option',
      );
      return false;
    }

    if (type.hasOptions && type.hasCorrectAnswer) {
      final hasCorrect = state.answerOptions.any((o) => o.isCorrect);
      if (!hasCorrect) {
        state = state.copyWith(
          error: 'At least one answer option must be marked as correct',
        );
        return false;
      }
    }

    // Non-empty content for answer options.
    if (type.hasOptions) {
      final emptyOption = state.answerOptions.any(
        (o) => o.content.trim().isEmpty,
      );
      if (emptyOption) {
        state = state.copyWith(
          error: 'All answer options must have content',
        );
        return false;
      }
    }

    // Matching pairs.
    if (type == QuestionType.matching && state.matchingPairs.isEmpty) {
      state = state.copyWith(
        error: 'Matching questions require at least one matching pair',
      );
      return false;
    }

    if (type == QuestionType.matching) {
      final incompletePair = state.matchingPairs.any(
        (p) => p.leftContent.trim().isEmpty || p.rightContent.trim().isEmpty,
      );
      if (incompletePair) {
        state = state.copyWith(
          error: 'All matching pairs must have both left and right content',
        );
        return false;
      }
    }

    // Ordering items.
    if (type == QuestionType.ordering && state.orderingItems.isEmpty) {
      state = state.copyWith(
        error: 'Ordering questions require at least one ordering item',
      );
      return false;
    }

    if (type == QuestionType.ordering) {
      final emptyItem = state.orderingItems.any(
        (i) => i.content.trim().isEmpty,
      );
      if (emptyItem) {
        state = state.copyWith(
          error: 'All ordering items must have content',
        );
        return false;
      }
    }

    // Fill-in-blank answers.
    if (type == QuestionType.fillInBlank &&
        state.fillInBlankAnswers.isEmpty) {
      state = state.copyWith(
        error: 'Fill-in-the-blank questions require at least one blank',
      );
      return false;
    }

    if (type == QuestionType.fillInBlank) {
      final emptyBlank = state.fillInBlankAnswers.any(
        (a) => a.acceptableAnswers.isEmpty ||
            a.acceptableAnswers.every((s) => s.trim().isEmpty),
      );
      if (emptyBlank) {
        state = state.copyWith(
          error: 'Each blank must have at least one acceptable answer',
        );
        return false;
      }
    }

    // Clear any previous error since form is valid.
    state = state.copyWith(error: null);
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Adds default answer options for a given question type.
  void _addDefaultAnswerOptions(QuestionType type) {
    final now = DateTime.now();
    if (type == QuestionType.trueFalse) {
      state = state.copyWith(
        answerOptions: [
          AnswerOptionEntity(
            id: 'new-tf-1',
            questionId: state.question?.id ?? '',
            content: 'True',
            isCorrect: true,
            marks: state.marks,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now,
          ),
          AnswerOptionEntity(
            id: 'new-tf-2',
            questionId: state.question?.id ?? '',
            content: 'False',
            isCorrect: false,
            marks: 0.0,
            sortOrder: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
    } else {
      // Default: 4 blank options for MCQ / MRQ / image / audio / video.
      state = state.copyWith(
        answerOptions: List.generate(
          4,
          (index) => AnswerOptionEntity(
            id: 'new-opt-${index + 1}',
            questionId: state.question?.id ?? '',
            content: '',
            isCorrect: false,
            marks: 0.0,
            sortOrder: index,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }
  }

  /// Loads topics for the given [subjectId].
  Future<void> _loadTopicsForSubject(String subjectId) async {
    state = state.copyWith(isLoadingTopics: true);

    final result = await _repository.getTopics(subjectId);

    result.fold(
      onSuccess: (topics) {
        state = state.copyWith(
          availableTopics: topics,
          isLoadingTopics: false,
        );
        AppLogger.info(
          'Loaded ${topics.length} topics for subject $subjectId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoadingTopics: false);
        AppLogger.warning('Failed to load topics: $failure');
      },
    );
  }

  /// Loads subtopics for the given [topicId].
  Future<void> _loadSubtopicsForTopic(String topicId) async {
    state = state.copyWith(isLoadingSubtopics: true);

    final result = await _repository.getSubtopics(topicId);

    result.fold(
      onSuccess: (subtopics) {
        state = state.copyWith(
          availableSubtopics: subtopics,
          isLoadingSubtopics: false,
        );
        AppLogger.info(
          'Loaded ${subtopics.length} subtopics for topic $topicId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoadingSubtopics: false);
        AppLogger.warning('Failed to load subtopics: $failure');
      },
    );
  }

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
