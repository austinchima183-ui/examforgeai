import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/usecases/create_exam_usecase.dart';
import '../../domain/usecases/manage_exam_status_usecase.dart';
import '../../domain/usecases/update_exam_usecase.dart';
import '../../domain/repositories/cbt_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM BUILDER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the exam creation/editing feature.
///
/// Tracks the exam being built or edited, its sections, questions,
/// assigned students, loading flags, form field values, and messages.
class ExamBuilderState {
  const ExamBuilderState({
    this.exam,
    this.sections = const [],
    this.questions = const [],
    this.availableQuestions = const [],
    this.assignedStudents = const [],
    this.isSaving = false,
    this.isLoading = false,
    this.isPublishing = false,
    this.error,
    this.successMessage,
    // Form fields
    this.title = '',
    this.description = '',
    this.subjectId,
    this.classId,
    this.academicSessionId,
    this.examType = ExamType.schoolExam,
    this.status = ExamStatus.draft,
    this.startTime,
    this.endTime,
    this.timeLimitMinutes = 60,
    this.passMark = 50.0,
    this.passMarkType = 'percentage',
    this.instructions = '',
    this.allowedAttempts = 1,
    this.negativeMarkingEnabled = false,
    this.negativeMarkValue = 0.0,
    this.gracePeriodMinutes = 0,
    this.autoSubmit = true,
    this.randomizeQuestions = false,
    this.randomizeOptions = false,
    this.showResults = 'after_submission',
    this.showCorrectAnswers = false,
    this.showExplanations = false,
    this.maxStudents,
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
  });

  /// The exam entity when editing; `null` when creating.
  final ExamEntity? exam;

  /// Sections within the exam.
  final List<ExamSectionEntity> sections;

  /// Questions added to the exam.
  final List<ExamQuestionEntity> questions;

  /// Questions available from the Question Bank for selection.
  final List<QuestionEntity> availableQuestions;

  /// Student IDs assigned to this exam.
  final List<String> assignedStudents;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// Whether an initial load is in progress.
  final bool isLoading;

  /// Whether a publish operation is in progress.
  final bool isPublishing;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  // ── Form fields ──────────────────────────────────────────────────────

  final String title;
  final String description;
  final String? subjectId;
  final String? classId;
  final String? academicSessionId;
  final ExamType examType;
  final ExamStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int timeLimitMinutes;
  final double passMark;
  final String passMarkType;
  final String instructions;
  final int allowedAttempts;
  final bool negativeMarkingEnabled;
  final double negativeMarkValue;
  final int gracePeriodMinutes;
  final bool autoSubmit;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final String showResults;
  final bool showCorrectAnswers;
  final bool showExplanations;
  final int? maxStudents;
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;

  // ── Convenience getters ──────────────────────────────────────────────

  /// Whether the form is in edit mode (editing an existing exam).
  bool get isEditMode => exam != null && exam!.id.isNotEmpty;

  /// Total marks computed from exam questions.
  double get totalMarks => questions.fold(0.0, (sum, q) => sum + q.marks);

  /// Whether any async operation is in progress.
  bool get isBusy => isSaving || isLoading || isPublishing;

  /// Whether the form has enough data to save.
  bool get canSave =>
      title.trim().isNotEmpty &&
      subjectId != null &&
      classId != null &&
      academicSessionId != null &&
      startTime != null &&
      endTime != null;

  /// Whether the form has enough data to publish.
  bool get canPublish => canSave && questions.isNotEmpty;

  // ── copyWith ─────────────────────────────────────────────────────────

  ExamBuilderState copyWith({
    ExamEntity? exam,
    List<ExamSectionEntity>? sections,
    List<ExamQuestionEntity>? questions,
    List<QuestionEntity>? availableQuestions,
    List<String>? assignedStudents,
    bool? isSaving,
    bool? isLoading,
    bool? isPublishing,
    String? error,
    String? successMessage,
    String? title,
    String? description,
    String? subjectId,
    String? classId,
    String? academicSessionId,
    ExamType? examType,
    ExamStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? timeLimitMinutes,
    double? passMark,
    String? passMarkType,
    String? instructions,
    int? allowedAttempts,
    bool? negativeMarkingEnabled,
    double? negativeMarkValue,
    int? gracePeriodMinutes,
    bool? autoSubmit,
    bool? randomizeQuestions,
    bool? randomizeOptions,
    String? showResults,
    bool? showCorrectAnswers,
    bool? showExplanations,
    int? maxStudents,
    bool? requireFullScreen,
    bool? allowResume,
    bool? browserLockdown,
  }) {
    return ExamBuilderState(
      exam: exam ?? this.exam,
      sections: sections ?? this.sections,
      questions: questions ?? this.questions,
      availableQuestions: availableQuestions ?? this.availableQuestions,
      assignedStudents: assignedStudents ?? this.assignedStudents,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
      error: error,
      successMessage: successMessage,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      examType: examType ?? this.examType,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      passMark: passMark ?? this.passMark,
      passMarkType: passMarkType ?? this.passMarkType,
      instructions: instructions ?? this.instructions,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      negativeMarkingEnabled:
          negativeMarkingEnabled ?? this.negativeMarkingEnabled,
      negativeMarkValue: negativeMarkValue ?? this.negativeMarkValue,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      autoSubmit: autoSubmit ?? this.autoSubmit,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      randomizeOptions: randomizeOptions ?? this.randomizeOptions,
      showResults: showResults ?? this.showResults,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      showExplanations: showExplanations ?? this.showExplanations,
      maxStudents: maxStudents ?? this.maxStudents,
      requireFullScreen: requireFullScreen ?? this.requireFullScreen,
      allowResume: allowResume ?? this.allowResume,
      browserLockdown: browserLockdown ?? this.browserLockdown,
    );
  }

  /// Clears the current error message.
  ExamBuilderState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ExamBuilderState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM BUILDER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages exam creation/editing state.
///
/// Provides methods for all form field updates, question/section
/// management, student assignment, and save/publish operations.
class ExamBuilderNotifier extends StateNotifier<ExamBuilderState> {
  ExamBuilderNotifier({
    required CreateExamUseCase createExamUseCase,
    required UpdateExamUseCase updateExamUseCase,
    required ManageExamStatusUseCase manageExamStatusUseCase,
    required CbtRepository cbtRepository,
  })  : _createExamUseCase = createExamUseCase,
        _updateExamUseCase = updateExamUseCase,
        _manageExamStatusUseCase = manageExamStatusUseCase,
        _cbtRepository = cbtRepository,
        super(const ExamBuilderState());

  final CreateExamUseCase _createExamUseCase;
  final UpdateExamUseCase _updateExamUseCase;
  final ManageExamStatusUseCase _manageExamStatusUseCase;
  final CbtRepository _cbtRepository;

  // ═══════════════════════════════════════════════════════════════════════
  // FORM FIELD SETTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Updates the exam title.
  void setTitle(String value) => state = state.copyWith(title: value);

  /// Updates the exam description.
  void setDescription(String value) =>
      state = state.copyWith(description: value);

  /// Updates the subject ID.
  void setSubjectId(String? value) =>
      state = state.copyWith(subjectId: value);

  /// Updates the class ID.
  void setClassId(String? value) => state = state.copyWith(classId: value);

  /// Updates the academic session ID.
  void setAcademicSessionId(String? value) =>
      state = state.copyWith(academicSessionId: value);

  /// Updates the exam type.
  void setExamType(ExamType value) =>
      state = state.copyWith(examType: value);

  /// Updates the start time.
  void setStartTime(DateTime? value) =>
      state = state.copyWith(startTime: value);

  /// Updates the end time.
  void setEndTime(DateTime? value) => state = state.copyWith(endTime: value);

  /// Updates the time limit in minutes.
  void setTimeLimitMinutes(int value) =>
      state = state.copyWith(timeLimitMinutes: value);

  /// Updates the pass mark.
  void setPassMark(double value) => state = state.copyWith(passMark: value);

  /// Updates the pass mark type ('percentage' or 'absolute').
  void setPassMarkType(String value) =>
      state = state.copyWith(passMarkType: value);

  /// Updates the instructions.
  void setInstructions(String value) =>
      state = state.copyWith(instructions: value);

  /// Updates the allowed attempts.
  void setAllowedAttempts(int value) =>
      state = state.copyWith(allowedAttempts: value);

  /// Toggles negative marking.
  void setNegativeMarkingEnabled(bool value) =>
      state = state.copyWith(negativeMarkingEnabled: value);

  /// Updates the negative mark value.
  void setNegativeMarkValue(double value) =>
      state = state.copyWith(negativeMarkValue: value);

  /// Updates the grace period in minutes.
  void setGracePeriodMinutes(int value) =>
      state = state.copyWith(gracePeriodMinutes: value);

  /// Toggles auto-submit.
  void setAutoSubmit(bool value) => state = state.copyWith(autoSubmit: value);

  /// Toggles question randomization.
  void setRandomizeQuestions(bool value) =>
      state = state.copyWith(randomizeQuestions: value);

  /// Toggles option randomization.
  void setRandomizeOptions(bool value) =>
      state = state.copyWith(randomizeOptions: value);

  /// Updates the show results setting.
  void setShowResults(String value) =>
      state = state.copyWith(showResults: value);

  /// Toggles showing correct answers.
  void setShowCorrectAnswers(bool value) =>
      state = state.copyWith(showCorrectAnswers: value);

  /// Toggles showing explanations.
  void setShowExplanations(bool value) =>
      state = state.copyWith(showExplanations: value);

  /// Updates the max students limit.
  void setMaxStudents(int? value) =>
      state = state.copyWith(maxStudents: value);

  /// Toggles full screen requirement.
  void setRequireFullScreen(bool value) =>
      state = state.copyWith(requireFullScreen: value);

  /// Toggles resume allowance.
  void setAllowResume(bool value) =>
      state = state.copyWith(allowResume: value);

  /// Toggles browser lockdown.
  void setBrowserLockdown(bool value) =>
      state = state.copyWith(browserLockdown: value);

  // ═══════════════════════════════════════════════════════════════════════
  // QUESTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Adds a question to the exam.
  void addQuestion(ExamQuestionEntity question) {
    final updated = [...state.questions, question];
    state = state.copyWith(questions: updated);
    AppLogger.info('Question added to exam: ${question.questionId}');
  }

  /// Removes a question from the exam by its ID.
  void removeQuestion(String questionId) {
    final updated =
        state.questions.where((q) => q.questionId != questionId).toList();
    state = state.copyWith(questions: updated);
    AppLogger.info('Question removed from exam: $questionId');
  }

  /// Reorders questions according to the given list of question IDs.
  void reorderQuestions(List<String> questionIds) {
    final reordered = <ExamQuestionEntity>[];
    for (var i = 0; i < questionIds.length; i++) {
      final question = state.questions
          .where((q) => q.questionId == questionIds[i])
          .firstOrNull;
      if (question != null) {
        reordered.add(question.copyWith(sortOrder: i));
      }
    }
    state = state.copyWith(questions: reordered);
    AppLogger.info('Questions reordered: ${questionIds.length} items');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Adds a section to the exam.
  void addSection(ExamSectionEntity section) {
    final updated = [...state.sections, section];
    state = state.copyWith(sections: updated);
    AppLogger.info('Section added: ${section.title}');
  }

  /// Removes a section by its ID.
  void removeSection(String sectionId) {
    final updated =
        state.sections.where((s) => s.id != sectionId).toList();
    state = state.copyWith(sections: updated);
    AppLogger.info('Section removed: $sectionId');
  }

  /// Updates a section by its ID.
  void updateSection(ExamSectionEntity updatedSection) {
    final updated = state.sections
        .map((s) => s.id == updatedSection.id ? updatedSection : s)
        .toList();
    state = state.copyWith(sections: updated);
    AppLogger.info('Section updated: ${updatedSection.id}');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT ASSIGNMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Assigns students to the exam.
  void assignStudents(List<String> studentIds) {
    final existing = state.assignedStudents.toSet();
    existing.addAll(studentIds);
    state = state.copyWith(assignedStudents: existing.toList());
    AppLogger.info('${studentIds.length} students assigned');
  }

  /// Removes students from the exam.
  void removeStudents(List<String> studentIds) {
    final existing = state.assignedStudents.toSet();
    existing.removeAll(studentIds);
    state = state.copyWith(assignedStudents: existing.toList());
    AppLogger.info('${studentIds.length} students removed');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD AVAILABLE QUESTIONS (from Question Bank)
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads questions from the Question Bank for selection.
  Future<void> loadAvailableQuestions() async {
    // This delegates to the question bank repository through the
    // CBT repository's data sources. A full implementation would
    // use the question bank repository directly.
    AppLogger.info('Loading available questions from Question Bank');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SAVE EXAM (create or update)
  // ═══════════════════════════════════════════════════════════════════════

  /// Saves the exam — creates if new, updates if editing.
  Future<void> saveExam() async {
    if (state.isSaving) return;

    state = state.copyWith(isSaving: true, error: null);

    if (state.isEditMode) {
      await _updateExam();
    } else {
      await _createExam();
    }
  }

  Future<void> _createExam() async {
    if (state.startTime == null || state.endTime == null) {
      state = state.copyWith(
        isSaving: false,
        error: 'Start time and end time are required',
      );
      return;
    }

    final input = ExamCreateInput(
      title: state.title,
      description:
          state.description.trim().isEmpty ? null : state.description,
      subjectId: state.subjectId ?? '',
      classId: state.classId ?? '',
      academicSessionId: state.academicSessionId ?? '',
      examType: state.examType,
      startTime: state.startTime!,
      endTime: state.endTime!,
      timeLimitMinutes: state.timeLimitMinutes,
      passMark: state.passMark,
      passMarkType: state.passMarkType,
      instructions:
          state.instructions.trim().isEmpty ? null : state.instructions,
      allowedAttempts: state.allowedAttempts,
      negativeMarkingEnabled: state.negativeMarkingEnabled,
      negativeMarkValue: state.negativeMarkValue,
      gracePeriodMinutes: state.gracePeriodMinutes,
      autoSubmit: state.autoSubmit,
      randomizeQuestions: state.randomizeQuestions,
      randomizeOptions: state.randomizeOptions,
      showResults: state.showResults,
      showCorrectAnswers: state.showCorrectAnswers,
      showExplanations: state.showExplanations,
      maxStudents: state.maxStudents,
      requireFullScreen: state.requireFullScreen,
      allowResume: state.allowResume,
      browserLockdown: state.browserLockdown,
    );

    final result = await _createExamUseCase(
      CreateExamParams(
        exam: input,
        sections: state.sections,
        questions: state.questions,
        studentIds: state.assignedStudents,
      ),
    );

    result.fold(
      onSuccess: (exam) {
        state = state.copyWith(
          isSaving: false,
          exam: exam,
          status: exam.status,
          successMessage: 'Exam created successfully',
          error: null,
        );
        AppLogger.info('Exam created: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create exam: $failure');
      },
    );
  }

  Future<void> _updateExam() async {
    if (state.exam == null) return;

    final updatedExam = state.exam!.copyWith(
      title: state.title,
      description:
          state.description.trim().isEmpty ? null : state.description,
      subjectId: state.subjectId ?? state.exam!.subjectId,
      classId: state.classId ?? state.exam!.classId,
      academicSessionId:
          state.academicSessionId ?? state.exam!.academicSessionId,
      examType: state.examType,
      startTime: state.startTime ?? state.exam!.startTime,
      endTime: state.endTime ?? state.exam!.endTime,
      timeLimitMinutes: state.timeLimitMinutes,
      totalMarks: state.totalMarks,
      passMark: state.passMark,
      passMarkType: state.passMarkType,
      instructions:
          state.instructions.trim().isEmpty ? null : state.instructions,
      allowedAttempts: state.allowedAttempts,
      negativeMarkingEnabled: state.negativeMarkingEnabled,
      negativeMarkValue: state.negativeMarkValue,
      gracePeriodMinutes: state.gracePeriodMinutes,
      autoSubmit: state.autoSubmit,
      randomizeQuestions: state.randomizeQuestions,
      randomizeOptions: state.randomizeOptions,
      showResults: state.showResults,
      showCorrectAnswers: state.showCorrectAnswers,
      showExplanations: state.showExplanations,
      maxStudents: state.maxStudents,
      requireFullScreen: state.requireFullScreen,
      allowResume: state.allowResume,
      browserLockdown: state.browserLockdown,
      sections: state.sections,
      questions: state.questions,
      updatedAt: DateTime.now(),
    );

    final result = await _updateExamUseCase(
      UpdateExamParams(
        exam: updatedExam,
        sections: state.sections,
        questions: state.questions,
        studentIds: state.assignedStudents,
      ),
    );

    result.fold(
      onSuccess: (exam) {
        state = state.copyWith(
          isSaving: false,
          exam: exam,
          status: exam.status,
          successMessage: 'Exam updated successfully',
          error: null,
        );
        AppLogger.info('Exam updated: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update exam: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLISH EXAM
  // ═══════════════════════════════════════════════════════════════════════

  /// Publishes the exam, making it visible to assigned students.
  ///
  /// Must be called after saving the exam.
  Future<void> publishExam() async {
    if (state.isPublishing) return;
    if (state.exam == null) {
      state = state.copyWith(error: 'Please save the exam first');
      return;
    }

    state = state.copyWith(isPublishing: true, error: null);

    final result = await _manageExamStatusUseCase(
      ManageStatusParams(
        examId: state.exam!.id,
        action: ManageStatusAction.publish,
      ),
    );

    result.fold(
      onSuccess: (exam) {
        state = state.copyWith(
          isPublishing: false,
          exam: exam,
          status: exam.status,
          successMessage: 'Exam published successfully',
          error: null,
        );
        AppLogger.info('Exam published: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isPublishing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish exam: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLONE EXAM
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a deep copy of the current exam with a new ID and draft status.
  Future<void> cloneExam() async {
    if (state.exam == null) return;

    state = state.copyWith(isSaving: true, error: null);

    final result = await _manageExamStatusUseCase(
      ManageStatusParams(
        examId: state.exam!.id,
        action: ManageStatusAction.clone,
      ),
    );

    result.fold(
      onSuccess: (exam) {
        state = state.copyWith(
          isSaving: false,
          exam: exam,
          status: exam.status,
          successMessage: 'Exam cloned successfully',
          error: null,
        );
        AppLogger.info('Exam cloned: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to clone exam: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD EXAM FOR EDIT
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads an existing exam into the form for editing.
  Future<void> loadExamForEdit(String examId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _cbtRepository.getExamWithDetails(examId);

    result.fold(
      onSuccess: (exam) {
        state = ExamBuilderState(
          exam: exam,
          sections: exam.sections,
          questions: exam.questions,
          isLoading: false,
          // Populate form fields from entity
          title: exam.title,
          description: exam.description ?? '',
          subjectId: exam.subjectId,
          classId: exam.classId,
          academicSessionId: exam.academicSessionId,
          examType: exam.examType,
          status: exam.status,
          startTime: exam.startTime,
          endTime: exam.endTime,
          timeLimitMinutes: exam.timeLimitMinutes,
          passMark: exam.passMark,
          passMarkType: exam.passMarkType,
          instructions: exam.instructions ?? '',
          allowedAttempts: exam.allowedAttempts,
          negativeMarkingEnabled: exam.negativeMarkingEnabled,
          negativeMarkValue: exam.negativeMarkValue,
          gracePeriodMinutes: exam.gracePeriodMinutes,
          autoSubmit: exam.autoSubmit,
          randomizeQuestions: exam.randomizeQuestions,
          randomizeOptions: exam.randomizeOptions,
          showResults: exam.showResults,
          showCorrectAnswers: exam.showCorrectAnswers,
          showExplanations: exam.showExplanations,
          maxStudents: exam.maxStudents,
          requireFullScreen: exam.requireFullScreen,
          allowResume: exam.allowResume,
          browserLockdown: exam.browserLockdown,
        );
        AppLogger.info('Exam loaded for edit: ${exam.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load exam for edit: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESET FORM
  // ═══════════════════════════════════════════════════════════════════════

  /// Resets the form to its initial state.
  void resetForm() {
    state = const ExamBuilderState();
    AppLogger.info('Exam builder form reset');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message from the state.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
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
