import 'package:equatable/equatable.dart';

import '../../../question_bank/domain/entities/question_entities.dart';
import 'cbt_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the category of an exam template.
///
/// Categories help teachers find templates relevant to the exam
/// they are preparing for, whether it's an internal school exam
/// or a standardized national exam.
enum TemplateCategory {
  schoolExam(
    value: 'school_exam',
    label: 'School Exam',
    icon: 'school',
  ),
  waecPrep(
    value: 'waec_prep',
    label: 'WAEC Prep',
    icon: 'award',
  ),
  necoPrep(
    value: 'neco_prep',
    label: 'NECO Prep',
    icon: 'badge',
  ),
  jambPrep(
    value: 'jamb_prep',
    label: 'JAMB Prep',
    icon: 'target',
  ),
  becePrep(
    value: 'bece_prep',
    label: 'BECE Prep',
    icon: 'book_open',
  ),
  certification(
    value: 'certification',
    label: 'Certification',
    icon: 'shield_check',
  ),
  custom(
    value: 'custom',
    label: 'Custom',
    icon: 'settings',
  );

  const TemplateCategory({
    required this.value,
    required this.label,
    required this.icon,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Icon identifier for UI rendering.
  final String icon;

  /// Parses a raw [value] string into a [TemplateCategory].
  ///
  /// Returns `null` if the value does not match any known category.
  static TemplateCategory? fromString(String? value) {
    if (value == null) return null;
    return TemplateCategory.values.cast<TemplateCategory?>().firstWhere(
          (category) => category?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the strategy for auto-selecting questions from the
/// question bank when creating an exam from a template.
enum QuestionSelectionMode {
  random(
    value: 'random',
    label: 'Random',
  ),
  balanced(
    value: 'balanced',
    label: 'Balanced',
  ),
  progressive(
    value: 'progressive',
    label: 'Progressive',
  );

  const QuestionSelectionMode({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [QuestionSelectionMode].
  ///
  /// Returns `null` if the value does not match any known mode.
  static QuestionSelectionMode? fromString(String? value) {
    if (value == null) return null;
    return QuestionSelectionMode.values.cast<QuestionSelectionMode?>().firstWhere(
          (mode) => mode?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a rule for auto-selecting questions from the question bank.
///
/// When an exam is created from a template, these rules determine which
/// questions are automatically pulled based on subject, topic, difficulty,
/// question type, and curriculum alignment. The selection mode controls
/// how questions are distributed.
class QuestionSelectionRuleEntity extends Equatable {
  const QuestionSelectionRuleEntity({
    required this.id,
    required this.subjectId,
    this.topicIds = const [],
    this.difficultyLevels = const [],
    this.questionTypes = const [],
    this.curriculumTypes = const [],
    required this.minQuestions,
    required this.maxQuestions,
    required this.marksPerQuestion,
    this.selectionMode = QuestionSelectionMode.random,
    this.includeImages = false,
    this.includeAudio = false,
    this.includeVideo = false,
  });

  final String id;

  /// The subject to select questions from.
  final String subjectId;

  /// Optional list of topic IDs to filter questions.
  final List<String> topicIds;

  /// Optional difficulty levels to filter by.
  final List<DifficultyLevel> difficultyLevels;

  /// Optional question types to filter by.
  final List<QuestionType> questionTypes;

  /// Optional curriculum types to filter by (e.g., WAEC, NECO).
  final List<String> curriculumTypes;

  /// Minimum number of questions to select.
  final int minQuestions;

  /// Maximum number of questions to select.
  final int maxQuestions;

  /// Marks awarded per question selected by this rule.
  final double marksPerQuestion;

  /// How questions are distributed when selected.
  final QuestionSelectionMode selectionMode;

  /// Whether to include questions with images.
  final bool includeImages;

  /// Whether to include questions with audio.
  final bool includeAudio;

  /// Whether to include questions with video.
  final bool includeVideo;

  QuestionSelectionRuleEntity copyWith({
    String? id,
    String? subjectId,
    List<String>? topicIds,
    List<DifficultyLevel>? difficultyLevels,
    List<QuestionType>? questionTypes,
    List<String>? curriculumTypes,
    int? minQuestions,
    int? maxQuestions,
    double? marksPerQuestion,
    QuestionSelectionMode? selectionMode,
    bool? includeImages,
    bool? includeAudio,
    bool? includeVideo,
  }) {
    return QuestionSelectionRuleEntity(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      topicIds: topicIds ?? this.topicIds,
      difficultyLevels: difficultyLevels ?? this.difficultyLevels,
      questionTypes: questionTypes ?? this.questionTypes,
      curriculumTypes: curriculumTypes ?? this.curriculumTypes,
      minQuestions: minQuestions ?? this.minQuestions,
      maxQuestions: maxQuestions ?? this.maxQuestions,
      marksPerQuestion: marksPerQuestion ?? this.marksPerQuestion,
      selectionMode: selectionMode ?? this.selectionMode,
      includeImages: includeImages ?? this.includeImages,
      includeAudio: includeAudio ?? this.includeAudio,
      includeVideo: includeVideo ?? this.includeVideo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subjectId,
        topicIds,
        difficultyLevels,
        questionTypes,
        curriculumTypes,
        minQuestions,
        maxQuestions,
        marksPerQuestion,
        selectionMode,
        includeImages,
        includeAudio,
        includeVideo,
      ];
}

/// Represents a section within an exam template.
///
/// Templates can be divided into sections (e.g., Section A - Objective,
/// Section B - Theory) each with its own instructions, optional time
/// limits, and an optional question selection rule for auto-populating
/// questions from the question bank.
class ExamTemplateSectionEntity extends Equatable {
  const ExamTemplateSectionEntity({
    required this.id,
    required this.templateId,
    required this.title,
    this.description,
    this.instructions,
    required this.sortOrder,
    this.timeLimitMinutes,
    this.randomizeQuestions = false,
    this.questionSelectionRule,
    this.marksPerQuestion = 1.0,
  });

  final String id;
  final String templateId;
  final String title;
  final String? description;
  final String? instructions;
  final int sortOrder;
  final int? timeLimitMinutes;
  final bool randomizeQuestions;

  /// Optional rule for auto-selecting questions into this section.
  final QuestionSelectionRuleEntity? questionSelectionRule;

  /// Default marks per question for this section.
  final double marksPerQuestion;

  ExamTemplateSectionEntity copyWith({
    String? id,
    String? templateId,
    String? title,
    String? description,
    String? instructions,
    int? sortOrder,
    int? timeLimitMinutes,
    bool? randomizeQuestions,
    QuestionSelectionRuleEntity? questionSelectionRule,
    double? marksPerQuestion,
  }) {
    return ExamTemplateSectionEntity(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sortOrder: sortOrder ?? this.sortOrder,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      questionSelectionRule:
          questionSelectionRule ?? this.questionSelectionRule,
      marksPerQuestion: marksPerQuestion ?? this.marksPerQuestion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        templateId,
        title,
        description,
        instructions,
        sortOrder,
        timeLimitMinutes,
        randomizeQuestions,
        questionSelectionRule,
        marksPerQuestion,
      ];
}

/// Represents a reusable exam template for creating exams quickly.
///
/// Templates capture the configuration of an exam — timing, scoring,
/// security, sections, and question selection rules — so that teachers
/// can create similar exams without re-entering all settings.
///
/// Templates can be shared publicly across schools or kept private
/// within a school. Usage tracking helps surface popular templates.
class ExamTemplateEntity extends Equatable {
  const ExamTemplateEntity({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.name,
    this.description,
    required this.subjectId,
    required this.classId,
    required this.examType,
    required this.timeLimitMinutes,
    required this.passMark,
    this.passMarkType = 'percentage',
    this.instructions,
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
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
    this.sections = const [],
    this.questionSelectionRules = const [],
    this.metadata,
    this.usageCount = 0,
    this.isPublic = false,
    this.category = TemplateCategory.custom,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Identifiers ─────────────────────────────────────────────────────
  final String id;
  final String schoolId;
  final String createdBy;

  // ── Content ─────────────────────────────────────────────────────────
  final String name;
  final String? description;

  // ── Classification ──────────────────────────────────────────────────
  final String subjectId;
  final String classId;
  final ExamType examType;

  // ── Timing ──────────────────────────────────────────────────────────
  final int timeLimitMinutes;

  // ── Scoring ─────────────────────────────────────────────────────────
  final double passMark;

  /// Either 'percentage' or 'absolute'.
  final String passMarkType;

  // ── Instructions ────────────────────────────────────────────────────
  final String? instructions;

  // ── Attempt Rules ───────────────────────────────────────────────────
  final int allowedAttempts;

  // ── Negative Marking ────────────────────────────────────────────────
  final bool negativeMarkingEnabled;
  final double negativeMarkValue;

  // ── Grace Period & Auto Submit ──────────────────────────────────────
  final int gracePeriodMinutes;
  final bool autoSubmit;

  // ── Randomization ───────────────────────────────────────────────────
  final bool randomizeQuestions;
  final bool randomizeOptions;

  // ── Result Visibility ───────────────────────────────────────────────
  /// One of: 'immediate', 'after_submission', 'after_grading', 'manual'.
  final String showResults;
  final bool showCorrectAnswers;
  final bool showExplanations;

  // ── Security ────────────────────────────────────────────────────────
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;

  // ── Structure ───────────────────────────────────────────────────────
  final List<ExamTemplateSectionEntity> sections;
  final List<QuestionSelectionRuleEntity> questionSelectionRules;

  // ── Extensibility ───────────────────────────────────────────────────
  final Map<String, dynamic>? metadata;

  // ── Usage & Sharing ─────────────────────────────────────────────────
  final int usageCount;
  final bool isPublic;
  final TemplateCategory category;
  final List<String> tags;

  // ── Timestamps ──────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamTemplateEntity copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? name,
    String? description,
    String? subjectId,
    String? classId,
    ExamType? examType,
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
    bool? requireFullScreen,
    bool? allowResume,
    bool? browserLockdown,
    List<ExamTemplateSectionEntity>? sections,
    List<QuestionSelectionRuleEntity>? questionSelectionRules,
    Map<String, dynamic>? metadata,
    int? usageCount,
    bool? isPublic,
    TemplateCategory? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamTemplateEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      examType: examType ?? this.examType,
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
      requireFullScreen: requireFullScreen ?? this.requireFullScreen,
      allowResume: allowResume ?? this.allowResume,
      browserLockdown: browserLockdown ?? this.browserLockdown,
      sections: sections ?? this.sections,
      questionSelectionRules:
          questionSelectionRules ?? this.questionSelectionRules,
      metadata: metadata ?? this.metadata,
      usageCount: usageCount ?? this.usageCount,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        createdBy,
        name,
        description,
        subjectId,
        classId,
        examType,
        timeLimitMinutes,
        passMark,
        passMarkType,
        instructions,
        allowedAttempts,
        negativeMarkingEnabled,
        negativeMarkValue,
        gracePeriodMinutes,
        autoSubmit,
        randomizeQuestions,
        randomizeOptions,
        showResults,
        showCorrectAnswers,
        showExplanations,
        requireFullScreen,
        allowResume,
        browserLockdown,
        sections,
        questionSelectionRules,
        metadata,
        usageCount,
        isPublic,
        category,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents a receipt generated after an exam submission.
///
/// Submission receipts provide verifiable proof that a student
/// submitted their exam, including metadata like submission type,
/// question counts, time spent, and device information. Receipts
/// can be verified by their unique receipt number.
class SubmissionReceiptEntity extends Equatable {
  const SubmissionReceiptEntity({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.examTitle,
    required this.submittedAt,
    required this.submissionType,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.flaggedQuestions,
    required this.timeSpentMinutes,
    this.ipAddress,
    this.deviceInfo,
    required this.receiptNumber,
    this.isVerified = false,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final String examTitle;
  final DateTime submittedAt;
  final SubmissionType submissionType;
  final int totalQuestions;
  final int answeredQuestions;
  final int unansweredQuestions;
  final int flaggedQuestions;
  final int timeSpentMinutes;
  final String? ipAddress;
  final Map<String, dynamic>? deviceInfo;
  final String receiptNumber;
  final bool isVerified;

  SubmissionReceiptEntity copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    String? examTitle,
    DateTime? submittedAt,
    SubmissionType? submissionType,
    int? totalQuestions,
    int? answeredQuestions,
    int? unansweredQuestions,
    int? flaggedQuestions,
    int? timeSpentMinutes,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
    String? receiptNumber,
    bool? isVerified,
  }) {
    return SubmissionReceiptEntity(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      examTitle: examTitle ?? this.examTitle,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionType: submissionType ?? this.submissionType,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
      flaggedQuestions: flaggedQuestions ?? this.flaggedQuestions,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attemptId,
        examId,
        studentId,
        examTitle,
        submittedAt,
        submissionType,
        totalQuestions,
        answeredQuestions,
        unansweredQuestions,
        flaggedQuestions,
        timeSpentMinutes,
        ipAddress,
        deviceInfo,
        receiptNumber,
        isVerified,
      ];
}
