import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Types of examination bodies in the Nigerian/African education system.
enum ExamBodyType {
  waec(value: 'waec', label: 'WAEC'),
  neco(value: 'neco', label: 'NECO'),
  nabteb(value: 'nabteb', label: 'NABTEB'),
  jambUme(value: 'jamb_ume', label: 'JAMB UTME'),
  postUtme(value: 'post_utme', label: 'Post-UTME'),
  bece(value: 'bece', label: 'BECE'),
  commonEntrance(value: 'common_entrance', label: 'Common Entrance'),
  jupeb(value: 'jupeb', label: 'JUPEB'),
  ijmb(value: 'ijmb', label: 'IJMB'),
  custom(value: 'custom', label: 'Custom');

  const ExamBodyType({required this.value, required this.label});
  final String value;
  final String label;

  static ExamBodyType? fromString(String? value) {
    if (value == null) return null;
    return ExamBodyType.values.cast<ExamBodyType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Categories of examinations.
enum ExamCategoryType {
  internal(value: 'internal', label: 'Internal'),
  mock(value: 'mock', label: 'Mock'),
  practice(value: 'practice', label: 'Practice'),
  pastPaper(value: 'past_paper', label: 'Past Paper'),
  certification(value: 'certification', label: 'Certification'),
  entrance(value: 'entrance', label: 'Entrance');

  const ExamCategoryType({required this.value, required this.label});
  final String value;
  final String label;

  static ExamCategoryType? fromString(String? value) {
    if (value == null) return null;
    return ExamCategoryType.values.cast<ExamCategoryType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Types of exam preparation modes.
enum PreparationType {
  practiceQuestions(value: 'practice_questions', label: 'Practice Questions'),
  mockCbt(value: 'mock_cbt', label: 'Mock CBT'),
  aiRevision(value: 'ai_revision', label: 'AI Revision'),
  topicPractice(value: 'topic_practice', label: 'Topic Practice'),
  timedPractice(value: 'timed_practice', label: 'Timed Practice'),
  fullMock(value: 'full_mock', label: 'Full Mock');

  const PreparationType({required this.value, required this.label});
  final String value;
  final String label;

  static PreparationType? fromString(String? value) {
    if (value == null) return null;
    return PreparationType.values.cast<PreparationType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Student readiness levels for examinations.
enum ReadinessLevel {
  notStarted(value: 'not_started', label: 'Not Started'),
  beginning(value: 'beginning', label: 'Beginning'),
  developing(value: 'developing', label: 'Developing'),
  proficient(value: 'proficient', label: 'Proficient'),
  advanced(value: 'advanced', label: 'Advanced'),
  examReady(value: 'exam_ready', label: 'Exam Ready');

  const ReadinessLevel({required this.value, required this.label});
  final String value;
  final String label;

  static ReadinessLevel? fromString(String? value) {
    if (value == null) return null;
    return ReadinessLevel.values.cast<ReadinessLevel?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Mock exam status lifecycle.
enum MockExamStatus {
  draft(value: 'draft', label: 'Draft'),
  published(value: 'published', label: 'Published'),
  inProgress(value: 'in_progress', label: 'In Progress'),
  completed(value: 'completed', label: 'Completed'),
  archived(value: 'archived', label: 'Archived');

  const MockExamStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MockExamStatus? fromString(String? value) {
    if (value == null) return null;
    return MockExamStatus.values.cast<MockExamStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Mock exam attempt status.
enum MockExamAttemptStatus {
  inProgress(value: 'in_progress', label: 'In Progress'),
  submitted(value: 'submitted', label: 'Submitted'),
  timedOut(value: 'timed_out', label: 'Timed Out'),
  graded(value: 'graded', label: 'Graded');

  const MockExamAttemptStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MockExamAttemptStatus? fromString(String? value) {
    if (value == null) return null;
    return MockExamAttemptStatus.values.cast<MockExamAttemptStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Study plan type.
enum StudyPlanType {
  aiGenerated(value: 'ai_generated', label: 'AI Generated'),
  custom(value: 'custom', label: 'Custom'),
  template(value: 'template', label: 'Template');

  const StudyPlanType({required this.value, required this.label});
  final String value;
  final String label;

  static StudyPlanType? fromString(String? value) {
    if (value == null) return null;
    return StudyPlanType.values.cast<StudyPlanType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Study plan activity types.
enum StudyActivityType {
  practice(value: 'practice', label: 'Practice'),
  reading(value: 'reading', label: 'Reading'),
  video(value: 'video', label: 'Video'),
  quiz(value: 'quiz', label: 'Quiz'),
  revision(value: 'revision', label: 'Revision'),
  mockExam(value: 'mock_exam', label: 'Mock Exam'),
  topicReview(value: 'topic_review', label: 'Topic Review');

  const StudyActivityType({required this.value, required this.label});
  final String value;
  final String label;

  static StudyActivityType? fromString(String? value) {
    if (value == null) return null;
    return StudyActivityType.values.cast<StudyActivityType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════

// ─── 1. ExaminationBody ────────────────────────────────────────────

/// Represents an examination body (e.g., WAEC, NECO, JAMB).
class ExaminationBody extends Equatable {
  const ExaminationBody({
    required this.id,
    required this.name,
    required this.code,
    required this.examBodyType,
    required this.countryCode,
    this.description,
    this.logoUrl,
    this.websiteUrl,
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final ExamBodyType examBodyType;
  final String countryCode;
  final String? description;
  final String? logoUrl;
  final String? websiteUrl;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExaminationBody copyWith({
    String? id,
    String? name,
    String? code,
    ExamBodyType? examBodyType,
    String? countryCode,
    String? description,
    String? logoUrl,
    String? websiteUrl,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExaminationBody(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      examBodyType: examBodyType ?? this.examBodyType,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        examBodyType,
        countryCode,
        description,
        logoUrl,
        websiteUrl,
        isActive,
        metadata,
        createdAt,
        updatedAt,
      ];
}

// ─── 2. ExaminationProduct ─────────────────────────────────────────

/// A specific exam product offered by an examination body
/// (e.g., WAEC May/June, JAMB UTME 2025).
class ExaminationProduct extends Equatable {
  const ExaminationProduct({
    required this.id,
    required this.examBodyId,
    required this.name,
    required this.code,
    required this.examCategory,
    required this.preparationType,
    this.educationalLevelId,
    this.subjectId,
    this.description,
    this.durationMinutes,
    this.totalMarks,
    this.passMark,
    this.instructions = const [],
    this.isTimed = true,
    this.allowsNegativeMarking = false,
    this.negativeMarkRatio,
    this.questionCount,
    this.isActive = true,
    this.isPremium = false,
    this.metadata = const {},
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examBodyId;
  final String name;
  final String code;
  final ExamCategoryType examCategory;
  final PreparationType preparationType;
  final String? educationalLevelId;
  final String? subjectId;
  final String? description;
  final int? durationMinutes;
  final int? totalMarks;
  final int? passMark;
  final List<String> instructions;
  final bool isTimed;
  final bool allowsNegativeMarking;
  final double? negativeMarkRatio;
  final int? questionCount;
  final bool isActive;
  final bool isPremium;
  final Map<String, dynamic> metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExaminationProduct copyWith({
    String? id,
    String? examBodyId,
    String? name,
    String? code,
    ExamCategoryType? examCategory,
    PreparationType? preparationType,
    String? educationalLevelId,
    String? subjectId,
    String? description,
    int? durationMinutes,
    int? totalMarks,
    int? passMark,
    List<String>? instructions,
    bool? isTimed,
    bool? allowsNegativeMarking,
    double? negativeMarkRatio,
    int? questionCount,
    bool? isActive,
    bool? isPremium,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExaminationProduct(
      id: id ?? this.id,
      examBodyId: examBodyId ?? this.examBodyId,
      name: name ?? this.name,
      code: code ?? this.code,
      examCategory: examCategory ?? this.examCategory,
      preparationType: preparationType ?? this.preparationType,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      subjectId: subjectId ?? this.subjectId,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      passMark: passMark ?? this.passMark,
      instructions: instructions ?? this.instructions,
      isTimed: isTimed ?? this.isTimed,
      allowsNegativeMarking: allowsNegativeMarking ?? this.allowsNegativeMarking,
      negativeMarkRatio: negativeMarkRatio ?? this.negativeMarkRatio,
      questionCount: questionCount ?? this.questionCount,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examBodyId,
        name,
        code,
        examCategory,
        preparationType,
        educationalLevelId,
        subjectId,
        description,
        durationMinutes,
        totalMarks,
        passMark,
        instructions,
        isTimed,
        allowsNegativeMarking,
        negativeMarkRatio,
        questionCount,
        isActive,
        isPremium,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

// ─── 3. MockExam ───────────────────────────────────────────────────

/// A mock examination created from an examination product,
/// typically within a school context.
class MockExam extends Equatable {
  const MockExam({
    required this.id,
    required this.examinationProductId,
    this.schoolId,
    required this.title,
    this.description,
    required this.examBodyType,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.totalMarks,
    this.passMark,
    this.instructions = const [],
    this.settings = const {},
    this.status = MockExamStatus.draft,
    this.startedAt,
    this.endedAt,
    this.resultsPublishedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examinationProductId;
  final String? schoolId;
  final String title;
  final String? description;
  final ExamBodyType examBodyType;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final int? passMark;
  final List<String> instructions;
  final Map<String, dynamic> settings;
  final MockExamStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? resultsPublishedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublished => status == MockExamStatus.published;
  bool get isDraft => status == MockExamStatus.draft;
  bool get isCompleted => status == MockExamStatus.completed;

  MockExam copyWith({
    String? id,
    String? examinationProductId,
    String? schoolId,
    String? title,
    String? description,
    ExamBodyType? examBodyType,
    int? durationMinutes,
    int? totalQuestions,
    int? totalMarks,
    int? passMark,
    List<String>? instructions,
    Map<String, dynamic>? settings,
    MockExamStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? resultsPublishedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearStartedAt = false,
    bool clearEndedAt = false,
    bool clearResultsPublishedAt = false,
  }) {
    return MockExam(
      id: id ?? this.id,
      examinationProductId: examinationProductId ?? this.examinationProductId,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      description: description ?? this.description,
      examBodyType: examBodyType ?? this.examBodyType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalMarks: totalMarks ?? this.totalMarks,
      passMark: passMark ?? this.passMark,
      instructions: instructions ?? this.instructions,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      resultsPublishedAt:
          clearResultsPublishedAt ? null : (resultsPublishedAt ?? this.resultsPublishedAt),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examinationProductId,
        schoolId,
        title,
        description,
        examBodyType,
        durationMinutes,
        totalQuestions,
        totalMarks,
        passMark,
        instructions,
        settings,
        status,
        startedAt,
        endedAt,
        resultsPublishedAt,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

// ─── 4. MockExamQuestion ───────────────────────────────────────────

/// A single question within a mock exam.
class MockExamQuestion extends Equatable {
  const MockExamQuestion({
    required this.id,
    required this.mockExamId,
    this.contentItemId,
    required this.questionNumber,
    this.sectionLabel,
    required this.marksAllocated,
    this.isCompulsory = true,
    required this.sortOrder,
  });

  final String id;
  final String mockExamId;
  final String? contentItemId;
  final int questionNumber;
  final String? sectionLabel;
  final int marksAllocated;
  final bool isCompulsory;
  final int sortOrder;

  MockExamQuestion copyWith({
    String? id,
    String? mockExamId,
    String? contentItemId,
    int? questionNumber,
    String? sectionLabel,
    int? marksAllocated,
    bool? isCompulsory,
    int? sortOrder,
  }) {
    return MockExamQuestion(
      id: id ?? this.id,
      mockExamId: mockExamId ?? this.mockExamId,
      contentItemId: contentItemId ?? this.contentItemId,
      questionNumber: questionNumber ?? this.questionNumber,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      marksAllocated: marksAllocated ?? this.marksAllocated,
      isCompulsory: isCompulsory ?? this.isCompulsory,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mockExamId,
        contentItemId,
        questionNumber,
        sectionLabel,
        marksAllocated,
        isCompulsory,
        sortOrder,
      ];
}

// ─── 5. MockExamAttempt ────────────────────────────────────────────

/// A student's attempt at a mock exam.
class MockExamAttempt extends Equatable {
  const MockExamAttempt({
    required this.id,
    required this.mockExamId,
    required this.userId,
    required this.startedAt,
    this.submittedAt,
    this.isCompleted = false,
    this.isTimedOut = false,
    this.totalScore = 0,
    required this.maxScore,
    this.percentage = 0.0,
    this.grade,
    this.timeTakenSeconds,
    this.status = MockExamAttemptStatus.inProgress,
    this.deviceInfo = const {},
    this.metadata = const {},
  });

  final String id;
  final String mockExamId;
  final String userId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final bool isCompleted;
  final bool isTimedOut;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final String? grade;
  final int? timeTakenSeconds;
  final MockExamAttemptStatus status;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> metadata;

  bool get isPassed => percentage >= 50.0;
  Duration? get timeTaken => timeTakenSeconds != null
      ? Duration(seconds: timeTakenSeconds!)
      : null;

  MockExamAttempt copyWith({
    String? id,
    String? mockExamId,
    String? userId,
    DateTime? startedAt,
    DateTime? submittedAt,
    bool? isCompleted,
    bool? isTimedOut,
    int? totalScore,
    int? maxScore,
    double? percentage,
    String? grade,
    int? timeTakenSeconds,
    MockExamAttemptStatus? status,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? metadata,
    bool clearSubmittedAt = false,
  }) {
    return MockExamAttempt(
      id: id ?? this.id,
      mockExamId: mockExamId ?? this.mockExamId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: clearSubmittedAt ? null : (submittedAt ?? this.submittedAt),
      isCompleted: isCompleted ?? this.isCompleted,
      isTimedOut: isTimedOut ?? this.isTimedOut,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      status: status ?? this.status,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mockExamId,
        userId,
        startedAt,
        submittedAt,
        isCompleted,
        isTimedOut,
        totalScore,
        maxScore,
        percentage,
        grade,
        timeTakenSeconds,
        status,
        deviceInfo,
        metadata,
      ];
}

// ─── 6. ReadinessAssessment ────────────────────────────────────────

/// Assessment of a student's readiness for a particular examination.
class ReadinessAssessment extends Equatable {
  const ReadinessAssessment({
    required this.id,
    required this.userId,
    required this.examBodyId,
    this.subjectId,
    required this.readinessLevel,
    required this.readinessScore,
    this.topicsMastered = 0,
    this.topicsTotal = 0,
    this.weakTopics = const [],
    this.strongTopics = const [],
    this.recommendations = const [],
    required this.assessedAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String examBodyId;
  final String? subjectId;
  final ReadinessLevel readinessLevel;
  final double readinessScore;
  final int topicsMastered;
  final int topicsTotal;
  final List<String> weakTopics;
  final List<String> strongTopics;
  final List<String> recommendations;
  final DateTime assessedAt;
  final DateTime? expiresAt;

  double get masteryPercentage =>
      topicsTotal > 0 ? (topicsMastered / topicsTotal) * 100 : 0.0;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  ReadinessAssessment copyWith({
    String? id,
    String? userId,
    String? examBodyId,
    String? subjectId,
    ReadinessLevel? readinessLevel,
    double? readinessScore,
    int? topicsMastered,
    int? topicsTotal,
    List<String>? weakTopics,
    List<String>? strongTopics,
    List<String>? recommendations,
    DateTime? assessedAt,
    DateTime? expiresAt,
    bool clearSubjectId = false,
    bool clearExpiresAt = false,
  }) {
    return ReadinessAssessment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examBodyId: examBodyId ?? this.examBodyId,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      readinessLevel: readinessLevel ?? this.readinessLevel,
      readinessScore: readinessScore ?? this.readinessScore,
      topicsMastered: topicsMastered ?? this.topicsMastered,
      topicsTotal: topicsTotal ?? this.topicsTotal,
      weakTopics: weakTopics ?? this.weakTopics,
      strongTopics: strongTopics ?? this.strongTopics,
      recommendations: recommendations ?? this.recommendations,
      assessedAt: assessedAt ?? this.assessedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        examBodyId,
        subjectId,
        readinessLevel,
        readinessScore,
        topicsMastered,
        topicsTotal,
        weakTopics,
        strongTopics,
        recommendations,
        assessedAt,
        expiresAt,
      ];
}

// ─── 7. StudyPlan ──────────────────────────────────────────────────

/// A structured study plan for exam preparation.
class StudyPlan extends Equatable {
  const StudyPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.examBodyId,
    this.educationalLevelId,
    this.subjectId,
    this.targetDate,
    this.dailyStudyMinutes = 60,
    this.planType = StudyPlanType.custom,
    this.planSchedule = const [],
    this.milestones = const [],
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.totalStudyMinutes = 0,
    this.isActive = true,
    this.aiGenerated = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String examBodyId;
  final String? educationalLevelId;
  final String? subjectId;
  final DateTime? targetDate;
  final int dailyStudyMinutes;
  final StudyPlanType planType;
  final List<Map<String, dynamic>> planSchedule;
  final List<Map<String, dynamic>> milestones;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalStudyMinutes;
  final bool isActive;
  final bool aiGenerated;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progressPercentage {
    if (targetDate == null || !isActive) return 0.0;
    final totalDays = targetDate!.difference(createdAt).inDays;
    final daysElapsed = DateTime.now().difference(createdAt).inDays;
    if (totalDays <= 0) return 100.0;
    return (daysElapsed / totalDays * 100).clamp(0.0, 100.0);
  }

  int get studyHours => totalStudyMinutes ~/ 60;
  int get studyMinutesRemainder => totalStudyMinutes % 60;

  StudyPlan copyWith({
    String? id,
    String? userId,
    String? title,
    String? examBodyId,
    String? educationalLevelId,
    String? subjectId,
    DateTime? targetDate,
    int? dailyStudyMinutes,
    StudyPlanType? planType,
    List<Map<String, dynamic>>? planSchedule,
    List<Map<String, dynamic>>? milestones,
    int? currentStreakDays,
    int? longestStreakDays,
    int? totalStudyMinutes,
    bool? isActive,
    bool? aiGenerated,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearEducationalLevelId = false,
    bool clearSubjectId = false,
    bool clearTargetDate = false,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      examBodyId: examBodyId ?? this.examBodyId,
      educationalLevelId:
          clearEducationalLevelId ? null : (educationalLevelId ?? this.educationalLevelId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      planType: planType ?? this.planType,
      planSchedule: planSchedule ?? this.planSchedule,
      milestones: milestones ?? this.milestones,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      isActive: isActive ?? this.isActive,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        examBodyId,
        educationalLevelId,
        subjectId,
        targetDate,
        dailyStudyMinutes,
        planType,
        planSchedule,
        milestones,
        currentStreakDays,
        longestStreakDays,
        totalStudyMinutes,
        isActive,
        aiGenerated,
        metadata,
        createdAt,
        updatedAt,
      ];
}

// ─── 8. StudyPlanActivity ──────────────────────────────────────────

/// A single activity within a study plan.
class StudyPlanActivity extends Equatable {
  const StudyPlanActivity({
    required this.id,
    required this.studyPlanId,
    required this.activityType,
    required this.title,
    this.description,
    this.subjectId,
    this.topicId,
    this.contentItemId,
    this.durationMinutes,
    required this.scheduledDate,
    this.completedAt,
    this.isCompleted = false,
    this.performanceScore,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String studyPlanId;
  final StudyActivityType activityType;
  final String title;
  final String? description;
  final String? subjectId;
  final String? topicId;
  final String? contentItemId;
  final int? durationMinutes;
  final DateTime scheduledDate;
  final DateTime? completedAt;
  final bool isCompleted;
  final double? performanceScore;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  bool get isOverdue =>
      !isCompleted && DateTime.now().isAfter(scheduledDate);

  bool get isScheduledToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  StudyPlanActivity copyWith({
    String? id,
    String? studyPlanId,
    StudyActivityType? activityType,
    String? title,
    String? description,
    String? subjectId,
    String? topicId,
    String? contentItemId,
    int? durationMinutes,
    DateTime? scheduledDate,
    DateTime? completedAt,
    bool? isCompleted,
    double? performanceScore,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearContentItemId = false,
    bool clearDurationMinutes = false,
    bool clearCompletedAt = false,
    bool clearPerformanceScore = false,
  }) {
    return StudyPlanActivity(
      id: id ?? this.id,
      studyPlanId: studyPlanId ?? this.studyPlanId,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      contentItemId:
          clearContentItemId ? null : (contentItemId ?? this.contentItemId),
      durationMinutes:
          clearDurationMinutes ? null : (durationMinutes ?? this.durationMinutes),
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isCompleted: isCompleted ?? this.isCompleted,
      performanceScore:
          clearPerformanceScore ? null : (performanceScore ?? this.performanceScore),
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studyPlanId,
        activityType,
        title,
        description,
        subjectId,
        topicId,
        contentItemId,
        durationMinutes,
        scheduledDate,
        completedAt,
        isCompleted,
        performanceScore,
        metadata,
        createdAt,
      ];
}
