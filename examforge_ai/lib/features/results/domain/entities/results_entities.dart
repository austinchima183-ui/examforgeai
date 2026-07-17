import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// The type of grading system used.
enum GradeType {
  percentage(value: 'percentage', label: 'Percentage'),
  letter(value: 'letter', label: 'Letter Grade'),
  gpa(value: 'gpa', label: 'GPA Scale'),
  custom(value: 'custom', label: 'Custom');

  const GradeType({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static GradeType? fromString(String? value) {
    if (value == null) return null;
    return GradeType.values.cast<GradeType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Status of an AI grading request.
enum AiGradingStatus {
  pending(value: 'pending', label: 'Pending', isTerminal: false),
  processing(value: 'processing', label: 'Processing', isTerminal: false),
  completed(value: 'completed', label: 'Completed', isTerminal: true),
  failed(value: 'failed', label: 'Failed', isTerminal: true),
  overridden(value: 'overridden', label: 'Overridden', isTerminal: true);

  const AiGradingStatus({
    required this.value,
    required this.label,
    required this.isTerminal,
  });

  final String value;
  final String label;
  final bool isTerminal;

  static AiGradingStatus? fromString(String? value) {
    if (value == null) return null;
    return AiGradingStatus.values.cast<AiGradingStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Export format for reports.
enum ReportFormat {
  pdf(value: 'pdf', label: 'PDF', extension: '.pdf'),
  excel(value: 'excel', label: 'Excel', extension: '.xlsx'),
  csv(value: 'csv', label: 'CSV', extension: '.csv');

  const ReportFormat({
    required this.value,
    required this.label,
    required this.extension,
  });

  final String value;
  final String label;
  final String extension;

  static ReportFormat? fromString(String? value) {
    if (value == null) return null;
    return ReportFormat.values.cast<ReportFormat?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Type of report to generate.
enum ReportType {
  student(value: 'student', label: 'Student Report'),
  classReport(value: 'class', label: 'Class Report'),
  school(value: 'school', label: 'School Report'),
  subject(value: 'subject', label: 'Subject Report'),
  examSummary(value: 'exam_summary', label: 'Exam Summary');

  const ReportType({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static ReportType? fromString(String? value) {
    if (value == null) return null;
    return ReportType.values.cast<ReportType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Status of a report export.
enum ReportStatus {
  pending(value: 'pending', label: 'Pending'),
  processing(value: 'processing', label: 'Processing'),
  completed(value: 'completed', label: 'Completed'),
  failed(value: 'failed', label: 'Failed');

  const ReportStatus({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  bool get isTerminal => this == completed || this == failed;

  static ReportStatus? fromString(String? value) {
    if (value == null) return null;
    return ReportStatus.values.cast<ReportStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Widget types available for configurable dashboards.
enum DashboardWidgetType {
  passRate(value: 'pass_rate', label: 'Pass Rate', icon: 'percent'),
  scoreDistribution(value: 'score_distribution', label: 'Score Distribution', icon: 'bar_chart'),
  subjectComparison(value: 'subject_comparison', label: 'Subject Comparison', icon: 'compare'),
  topPerformers(value: 'top_performers', label: 'Top Performers', icon: 'trophy'),
  difficultTopics(value: 'difficult_topics', label: 'Difficult Topics', icon: 'warning'),
  gradeDistribution(value: 'grade_distribution', label: 'Grade Distribution', icon: 'pie_chart'),
  attendanceVsPerformance(value: 'attendance_vs_performance', label: 'Attendance vs Performance', icon: 'people'),
  historicalTrend(value: 'historical_trend', label: 'Historical Trend', icon: 'trending_up'),
  classRanking(value: 'class_ranking', label: 'Class Ranking', icon: 'leaderboard'),
  examParticipation(value: 'exam_participation', label: 'Exam Participation', icon: 'how_to_reg'),
  gpaDistribution(value: 'gpa_distribution', label: 'GPA Distribution', icon: 'school'),
  improvementTracking(value: 'improvement_tracking', label: 'Improvement Tracking', icon: 'speed');

  const DashboardWidgetType({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final String icon;

  static DashboardWidgetType? fromString(String? value) {
    if (value == null) return null;
    return DashboardWidgetType.values.cast<DashboardWidgetType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Access level for result data.
enum ResultAccessLevel {
  full(value: 'full', label: 'Full Access'),
  limited(value: 'limited', label: 'Limited Access'),
  restricted(value: 'restricted', label: 'Restricted Access');

  const ResultAccessLevel({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static ResultAccessLevel? fromString(String? value) {
    if (value == null) return null;
    return ResultAccessLevel.values.cast<ResultAccessLevel?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Performance trend direction.
enum PerformanceTrend {
  improving(value: 'improving', label: 'Improving', icon: 'trending_up', color: '#22C55E'),
  stable(value: 'stable', label: 'Stable', icon: 'trending_flat', color: '#3B82F6'),
  declining(value: 'declining', label: 'Declining', icon: 'trending_down', color: '#EF4444');

  const PerformanceTrend({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final String icon;
  final String color;

  static PerformanceTrend? fromString(String? value) {
    if (value == null) return null;
    return PerformanceTrend.values.cast<PerformanceTrend?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Mastery level for topics.
enum MasteryLevel {
  notStarted(value: 'not_started', label: 'Not Started', percentage: 0, color: '#9CA3AF'),
  beginner(value: 'beginner', label: 'Beginner', percentage: 20, color: '#EF4444'),
  developing(value: 'developing', label: 'Developing', percentage: 40, color: '#F97316'),
  proficient(value: 'proficient', label: 'Proficient', percentage: 60, color: '#FACC15'),
  advanced(value: 'advanced', label: 'Advanced', percentage: 80, color: '#84CC16'),
  expert(value: 'expert', label: 'Expert', percentage: 100, color: '#22C55E');

  const MasteryLevel({
    required this.value,
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String value;
  final String label;
  final int percentage;
  final String color;

  static MasteryLevel? fromString(String? value) {
    if (value == null) return null;
    return MasteryLevel.values.cast<MasteryLevel?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }

  /// Derive mastery level from an accuracy percentage.
  static MasteryLevel fromAccuracy(double accuracy) {
    if (accuracy < 5) return notStarted;
    if (accuracy < 30) return beginner;
    if (accuracy < 50) return developing;
    if (accuracy < 70) return proficient;
    if (accuracy < 90) return advanced;
    return expert;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// A single entry within a grade scale (e.g., A: 70-100, B: 60-69).
class GradeScaleEntryEntity extends Equatable {
  const GradeScaleEntryEntity({
    required this.id,
    required this.minPercentage,
    required this.maxPercentage,
    required this.grade,
    this.gpaValue,
    this.description,
    required this.isPassing,
    this.color,
    required this.sortOrder,
  });

  final String id;
  final double minPercentage;
  final double maxPercentage;
  final String grade;
  final double? gpaValue;
  final String? description;
  final bool isPassing;
  final String? color;
  final int sortOrder;

  GradeScaleEntryEntity copyWith({
    String? id,
    double? minPercentage,
    double? maxPercentage,
    String? grade,
    double? gpaValue,
    String? description,
    bool? isPassing,
    String? color,
    int? sortOrder,
  }) {
    return GradeScaleEntryEntity(
      id: id ?? this.id,
      minPercentage: minPercentage ?? this.minPercentage,
      maxPercentage: maxPercentage ?? this.maxPercentage,
      grade: grade ?? this.grade,
      gpaValue: gpaValue ?? this.gpaValue,
      description: description ?? this.description,
      isPassing: isPassing ?? this.isPassing,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id, minPercentage, maxPercentage, grade, gpaValue,
        description, isPassing, color, sortOrder,
      ];
}

/// A configurable grading scale for converting percentage scores to grades.
class GradeScaleEntity extends Equatable {
  const GradeScaleEntity({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.gradeType,
    this.isDefault = false,
    this.isActive = true,
    this.scaleEntries = const [],
    this.createdBy,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final GradeType gradeType;
  final bool isDefault;
  final bool isActive;
  final List<GradeScaleEntryEntity> scaleEntries;
  final String? createdBy;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Apply this grade scale to a percentage and return the matching entry.
  GradeScaleEntryEntity? applyToPercentage(double percentage) {
    for (final entry in scaleEntries) {
      if (percentage >= entry.minPercentage && percentage <= entry.maxPercentage) {
        return entry;
      }
    }
    return null;
  }

  GradeScaleEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    GradeType? gradeType,
    bool? isDefault,
    bool? isActive,
    List<GradeScaleEntryEntity>? scaleEntries,
    String? createdBy,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeScaleEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      gradeType: gradeType ?? this.gradeType,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      scaleEntries: scaleEntries ?? this.scaleEntries,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, schoolId, name, gradeType, isDefault, isActive,
        scaleEntries, createdBy, settings, createdAt, updatedAt,
      ];
}

/// AI grading result for subjective question answers.
class AiGradingResultEntity extends Equatable {
  const AiGradingResultEntity({
    required this.id,
    required this.answerId,
    required this.examId,
    required this.studentId,
    required this.aiProvider,
    required this.suggestedScore,
    required this.maxPossible,
    this.confidenceScore,
    this.gradingRubric = const {},
    this.explanation,
    this.strengths = const [],
    this.weaknesses = const [],
    this.suggestions = const [],
    required this.status,
    this.inputTokens,
    this.outputTokens,
    this.processingTimeMs,
    this.errorMessage,
    this.reviewedBy,
    this.reviewedAt,
    this.finalScore,
    this.reviewComment,
    this.isAccepted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String answerId;
  final String examId;
  final String studentId;
  final String aiProvider;
  final double suggestedScore;
  final double maxPossible;
  final double? confidenceScore;
  final Map<String, dynamic> gradingRubric;
  final String? explanation;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final AiGradingStatus status;
  final int? inputTokens;
  final int? outputTokens;
  final int? processingTimeMs;
  final String? errorMessage;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final double? finalScore;
  final String? reviewComment;
  final bool isAccepted;

  /// The effective score: if a teacher accepted/overrode, use finalScore;
  /// otherwise use the AI suggested score.
  double get effectiveScore => finalScore ?? suggestedScore;

  /// Confidence as a percentage string.
  String get confidenceLabel =>
      confidenceScore != null ? '${(confidenceScore! * 100).toStringAsFixed(0)}%' : 'N/A';

  final DateTime createdAt;
  final DateTime updatedAt;

  AiGradingResultEntity copyWith({
    String? id,
    String? answerId,
    String? examId,
    String? studentId,
    String? aiProvider,
    double? suggestedScore,
    double? maxPossible,
    double? confidenceScore,
    Map<String, dynamic>? gradingRubric,
    String? explanation,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? suggestions,
    AiGradingStatus? status,
    int? inputTokens,
    int? outputTokens,
    int? processingTimeMs,
    String? errorMessage,
    String? reviewedBy,
    DateTime? reviewedAt,
    double? finalScore,
    String? reviewComment,
    bool? isAccepted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiGradingResultEntity(
      id: id ?? this.id,
      answerId: answerId ?? this.answerId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      aiProvider: aiProvider ?? this.aiProvider,
      suggestedScore: suggestedScore ?? this.suggestedScore,
      maxPossible: maxPossible ?? this.maxPossible,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      gradingRubric: gradingRubric ?? this.gradingRubric,
      explanation: explanation ?? this.explanation,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      suggestions: suggestions ?? this.suggestions,
      status: status ?? this.status,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      finalScore: finalScore ?? this.finalScore,
      reviewComment: reviewComment ?? this.reviewComment,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, answerId, examId, studentId, aiProvider, suggestedScore,
        maxPossible, confidenceScore, gradingRubric, explanation,
        strengths, weaknesses, suggestions, status, inputTokens,
        outputTokens, processingTimeMs, errorMessage, reviewedBy,
        reviewedAt, finalScore, reviewComment, isAccepted,
        createdAt, updatedAt,
      ];
}

/// Teacher feedback on a student answer (manual grading).
class TeacherFeedbackEntity extends Equatable {
  const TeacherFeedbackEntity({
    required this.id,
    required this.answerId,
    required this.examId,
    required this.studentId,
    required this.teacherId,
    required this.marksAwarded,
    required this.maxMarks,
    this.comment,
    this.aiGradingId,
    this.overrodeAi = false,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String answerId;
  final String examId;
  final String studentId;
  final String teacherId;
  final double marksAwarded;
  final double maxMarks;
  final String? comment;
  final String? aiGradingId;
  final bool overrodeAi;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The percentage score for this feedback.
  double get percentage => maxMarks > 0 ? (marksAwarded / maxMarks) * 100 : 0;

  TeacherFeedbackEntity copyWith({
    String? id,
    String? answerId,
    String? examId,
    String? studentId,
    String? teacherId,
    double? marksAwarded,
    double? maxMarks,
    String? comment,
    String? aiGradingId,
    bool? overrodeAi,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherFeedbackEntity(
      id: id ?? this.id,
      answerId: answerId ?? this.answerId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      maxMarks: maxMarks ?? this.maxMarks,
      comment: comment ?? this.comment,
      aiGradingId: aiGradingId ?? this.aiGradingId,
      overrodeAi: overrodeAi ?? this.overrodeAi,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, answerId, examId, studentId, teacherId, marksAwarded,
        maxMarks, comment, aiGradingId, overrodeAi, isPrivate,
        createdAt, updatedAt,
      ];
}

/// Student's aggregated result for a specific subject.
class StudentSubjectResultEntity extends Equatable {
  const StudentSubjectResultEntity({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.subjectId,
    required this.classId,
    required this.academicSessionId,
    this.examCount = 0,
    this.totalMarksObtained = 0,
    this.totalMarksPossible = 0,
    this.percentage = 0,
    this.grade,
    this.gpaValue,
    this.classAverage,
    this.classPosition,
    this.classSize,
    this.subjectAverage,
    this.isPassed = false,
    this.performanceTrend = PerformanceTrend.stable,
    this.strengths = const [],
    this.weaknesses = const [],
    this.aiRecommendations = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String subjectId;
  final String classId;
  final String academicSessionId;
  final int examCount;
  final double totalMarksObtained;
  final double totalMarksPossible;
  final double percentage;
  final String? grade;
  final double? gpaValue;
  final double? classAverage;
  final int? classPosition;
  final int? classSize;
  final double? subjectAverage;
  final bool isPassed;
  final PerformanceTrend performanceTrend;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> aiRecommendations;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Position string like "5th of 30".
  String get positionLabel =>
      classPosition != null && classSize != null
          ? '${classPosition} of $classSize'
          : 'N/A';

  /// Deviation from class average.
  double? get deviationFromClassAverage =>
      classAverage != null ? percentage - classAverage! : null;

  StudentSubjectResultEntity copyWith({
    String? id,
    String? studentId,
    String? schoolId,
    String? subjectId,
    String? classId,
    String? academicSessionId,
    int? examCount,
    double? totalMarksObtained,
    double? totalMarksPossible,
    double? percentage,
    String? grade,
    double? gpaValue,
    double? classAverage,
    int? classPosition,
    int? classSize,
    double? subjectAverage,
    bool? isPassed,
    PerformanceTrend? performanceTrend,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? aiRecommendations,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentSubjectResultEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      examCount: examCount ?? this.examCount,
      totalMarksObtained: totalMarksObtained ?? this.totalMarksObtained,
      totalMarksPossible: totalMarksPossible ?? this.totalMarksPossible,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      gpaValue: gpaValue ?? this.gpaValue,
      classAverage: classAverage ?? this.classAverage,
      classPosition: classPosition ?? this.classPosition,
      classSize: classSize ?? this.classSize,
      subjectAverage: subjectAverage ?? this.subjectAverage,
      isPassed: isPassed ?? this.isPassed,
      performanceTrend: performanceTrend ?? this.performanceTrend,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, studentId, schoolId, subjectId, classId, academicSessionId,
        examCount, totalMarksObtained, totalMarksPossible, percentage,
        grade, gpaValue, classAverage, classPosition, classSize,
        subjectAverage, isPassed, performanceTrend, strengths,
        weaknesses, aiRecommendations, metadata, createdAt, updatedAt,
      ];
}

/// Student's overall result across all subjects for a session.
class StudentOverallResultEntity extends Equatable {
  const StudentOverallResultEntity({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.classId,
    required this.academicSessionId,
    this.totalSubjects = 0,
    this.totalMarksObtained = 0,
    this.totalMarksPossible = 0,
    this.overallPercentage = 0,
    this.overallGrade,
    this.overallGpa,
    this.classAverage,
    this.classPosition,
    this.classSize,
    this.subjectsPassed = 0,
    this.subjectsFailed = 0,
    this.isPromoted,
    this.performanceTrend = PerformanceTrend.stable,
    this.bestSubjectId,
    this.worstSubjectId,
    this.aiStudyRecommendations = const [],
    this.teacherComment,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String classId;
  final String academicSessionId;
  final int totalSubjects;
  final double totalMarksObtained;
  final double totalMarksPossible;
  final double overallPercentage;
  final String? overallGrade;
  final double? overallGpa;
  final double? classAverage;
  final int? classPosition;
  final int? classSize;
  final int subjectsPassed;
  final int subjectsFailed;
  final bool? isPromoted;
  final PerformanceTrend performanceTrend;
  final String? bestSubjectId;
  final String? worstSubjectId;
  final List<String> aiStudyRecommendations;
  final String? teacherComment;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Pass rate across subjects.
  double get subjectPassRate =>
      totalSubjects > 0 ? (subjectsPassed / totalSubjects) * 100 : 0;

  /// Position string like "3rd of 45".
  String get positionLabel =>
      classPosition != null && classSize != null
          ? '$classPosition of $classSize'
          : 'N/A';

  StudentOverallResultEntity copyWith({
    String? id,
    String? studentId,
    String? schoolId,
    String? classId,
    String? academicSessionId,
    int? totalSubjects,
    double? totalMarksObtained,
    double? totalMarksPossible,
    double? overallPercentage,
    String? overallGrade,
    double? overallGpa,
    double? classAverage,
    int? classPosition,
    int? classSize,
    int? subjectsPassed,
    int? subjectsFailed,
    bool? isPromoted,
    PerformanceTrend? performanceTrend,
    String? bestSubjectId,
    String? worstSubjectId,
    List<String>? aiStudyRecommendations,
    String? teacherComment,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentOverallResultEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalMarksObtained: totalMarksObtained ?? this.totalMarksObtained,
      totalMarksPossible: totalMarksPossible ?? this.totalMarksPossible,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      overallGrade: overallGrade ?? this.overallGrade,
      overallGpa: overallGpa ?? this.overallGpa,
      classAverage: classAverage ?? this.classAverage,
      classPosition: classPosition ?? this.classPosition,
      classSize: classSize ?? this.classSize,
      subjectsPassed: subjectsPassed ?? this.subjectsPassed,
      subjectsFailed: subjectsFailed ?? this.subjectsFailed,
      isPromoted: isPromoted ?? this.isPromoted,
      performanceTrend: performanceTrend ?? this.performanceTrend,
      bestSubjectId: bestSubjectId ?? this.bestSubjectId,
      worstSubjectId: worstSubjectId ?? this.worstSubjectId,
      aiStudyRecommendations: aiStudyRecommendations ?? this.aiStudyRecommendations,
      teacherComment: teacherComment ?? this.teacherComment,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, studentId, schoolId, classId, academicSessionId,
        totalSubjects, totalMarksObtained, totalMarksPossible,
        overallPercentage, overallGrade, overallGpa, classAverage,
        classPosition, classSize, subjectsPassed, subjectsFailed,
        isPromoted, performanceTrend, bestSubjectId, worstSubjectId,
        aiStudyRecommendations, teacherComment, metadata,
        createdAt, updatedAt,
      ];
}

/// Topic mastery tracking for a student.
class TopicMasteryEntity extends Equatable {
  const TopicMasteryEntity({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.topicId,
    required this.subjectId,
    this.masteryLevel = MasteryLevel.notStarted,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.accuracyPercentage = 0,
    this.avgTimePerQuestion = 0,
    this.lastPracticedAt,
    this.improvementStreak = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String topicId;
  final String subjectId;
  final MasteryLevel masteryLevel;
  final int questionsAttempted;
  final int questionsCorrect;
  final double accuracyPercentage;
  final int avgTimePerQuestion;
  final DateTime? lastPracticedAt;
  final int improvementStreak;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicMasteryEntity copyWith({
    String? id,
    String? studentId,
    String? schoolId,
    String? topicId,
    String? subjectId,
    MasteryLevel? masteryLevel,
    int? questionsAttempted,
    int? questionsCorrect,
    double? accuracyPercentage,
    int? avgTimePerQuestion,
    DateTime? lastPracticedAt,
    int? improvementStreak,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicMasteryEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      topicId: topicId ?? this.topicId,
      subjectId: subjectId ?? this.subjectId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      avgTimePerQuestion: avgTimePerQuestion ?? this.avgTimePerQuestion,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      improvementStreak: improvementStreak ?? this.improvementStreak,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, studentId, schoolId, topicId, subjectId, masteryLevel,
        questionsAttempted, questionsCorrect, accuracyPercentage,
        avgTimePerQuestion, lastPracticedAt, improvementStreak,
        metadata, createdAt, updatedAt,
      ];
}

/// A dashboard widget configuration.
class DashboardWidgetConfigEntity extends Equatable {
  const DashboardWidgetConfigEntity({
    required this.id,
    required this.dashboardId,
    required this.widgetType,
    required this.title,
    this.positionRow = 0,
    this.positionCol = 0,
    this.width = 1,
    this.height = 1,
    this.isVisible = true,
    this.config = const {},
    this.dataSource = const {},
    this.refreshInterval = 300,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String dashboardId;
  final DashboardWidgetType widgetType;
  final String title;
  final int positionRow;
  final int positionCol;
  final int width;
  final int height;
  final bool isVisible;
  final Map<String, dynamic> config;
  final Map<String, dynamic> dataSource;
  final int refreshInterval;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardWidgetConfigEntity copyWith({
    String? id,
    String? dashboardId,
    DashboardWidgetType? widgetType,
    String? title,
    int? positionRow,
    int? positionCol,
    int? width,
    int? height,
    bool? isVisible,
    Map<String, dynamic>? config,
    Map<String, dynamic>? dataSource,
    int? refreshInterval,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DashboardWidgetConfigEntity(
      id: id ?? this.id,
      dashboardId: dashboardId ?? this.dashboardId,
      widgetType: widgetType ?? this.widgetType,
      title: title ?? this.title,
      positionRow: positionRow ?? this.positionRow,
      positionCol: positionCol ?? this.positionCol,
      width: width ?? this.width,
      height: height ?? this.height,
      isVisible: isVisible ?? this.isVisible,
      config: config ?? this.config,
      dataSource: dataSource ?? this.dataSource,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, dashboardId, widgetType, title, positionRow, positionCol,
        width, height, isVisible, config, dataSource, refreshInterval,
        sortOrder, createdAt, updatedAt,
      ];
}

/// A configurable analytics dashboard for a school/role.
class DashboardConfigurationEntity extends Equatable {
  const DashboardConfigurationEntity({
    required this.id,
    required this.schoolId,
    required this.role,
    required this.name,
    this.isDefault = false,
    this.isActive = true,
    this.layout = const {},
    this.widgets = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String role;
  final String name;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic> layout;
  final List<DashboardWidgetConfigEntity> widgets;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardConfigurationEntity copyWith({
    String? id,
    String? schoolId,
    String? role,
    String? name,
    bool? isDefault,
    bool? isActive,
    Map<String, dynamic>? layout,
    List<DashboardWidgetConfigEntity>? widgets,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DashboardConfigurationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      layout: layout ?? this.layout,
      widgets: widgets ?? this.widgets,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, schoolId, role, name, isDefault, isActive, layout,
        widgets, createdBy, createdAt, updatedAt,
      ];
}

/// A report export record.
class ReportExportEntity extends Equatable {
  const ReportExportEntity({
    required this.id,
    required this.schoolId,
    required this.requestedBy,
    required this.reportType,
    required this.reportFormat,
    this.status = ReportStatus.pending,
    required this.title,
    this.parameters = const {},
    this.filters = const {},
    this.fileUrl,
    this.fileSizeBytes,
    this.rowCount,
    this.errorMessage,
    this.processingTimeMs,
    this.expiresAt,
    this.downloadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String requestedBy;
  final ReportType reportType;
  final ReportFormat reportFormat;
  final ReportStatus status;
  final String title;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> filters;
  final String? fileUrl;
  final int? fileSizeBytes;
  final int? rowCount;
  final String? errorMessage;
  final int? processingTimeMs;
  final DateTime? expiresAt;
  final DateTime? downloadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportExportEntity copyWith({
    String? id,
    String? schoolId,
    String? requestedBy,
    ReportType? reportType,
    ReportFormat? reportFormat,
    ReportStatus? status,
    String? title,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? filters,
    String? fileUrl,
    int? fileSizeBytes,
    int? rowCount,
    String? errorMessage,
    int? processingTimeMs,
    DateTime? expiresAt,
    DateTime? downloadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportExportEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      requestedBy: requestedBy ?? this.requestedBy,
      reportType: reportType ?? this.reportType,
      reportFormat: reportFormat ?? this.reportFormat,
      status: status ?? this.status,
      title: title ?? this.title,
      parameters: parameters ?? this.parameters,
      filters: filters ?? this.filters,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      rowCount: rowCount ?? this.rowCount,
      errorMessage: errorMessage ?? this.errorMessage,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      expiresAt: expiresAt ?? this.expiresAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, schoolId, requestedBy, reportType, reportFormat, status,
        title, parameters, filters, fileUrl, fileSizeBytes, rowCount,
        errorMessage, processingTimeMs, expiresAt, downloadedAt,
        createdAt, updatedAt,
      ];
}

/// Result lock status for an exam.
class ResultLockEntity extends Equatable {
  const ResultLockEntity({
    required this.id,
    required this.examId,
    required this.schoolId,
    required this.lockedBy,
    required this.lockedAt,
    this.reason,
    this.isLocked = true,
    this.unlockedBy,
    this.unlockedAt,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String schoolId;
  final String lockedBy;
  final DateTime lockedAt;
  final String? reason;
  final bool isLocked;
  final String? unlockedBy;
  final DateTime? unlockedAt;
  final DateTime createdAt;

  ResultLockEntity copyWith({
    String? id,
    String? examId,
    String? schoolId,
    String? lockedBy,
    DateTime? lockedAt,
    String? reason,
    bool? isLocked,
    String? unlockedBy,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) {
    return ResultLockEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      schoolId: schoolId ?? this.schoolId,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      reason: reason ?? this.reason,
      isLocked: isLocked ?? this.isLocked,
      unlockedBy: unlockedBy ?? this.unlockedBy,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, examId, schoolId, lockedBy, lockedAt, reason, isLocked,
        unlockedBy, unlockedAt, createdAt,
      ];
}

/// Pre-computed analytics snapshot.
class AnalyticsSnapshotEntity extends Equatable {
  const AnalyticsSnapshotEntity({
    required this.id,
    required this.schoolId,
    required this.snapshotType,
    this.entityId,
    this.academicSessionId,
    required this.periodStart,
    required this.periodEnd,
    this.data = const {},
    required this.computedAt,
    this.expiresAt,
  });

  final String id;
  final String schoolId;
  final String snapshotType;
  final String? entityId;
  final String? academicSessionId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> data;
  final DateTime computedAt;
  final DateTime? expiresAt;

  /// Whether this snapshot has expired.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  AnalyticsSnapshotEntity copyWith({
    String? id,
    String? schoolId,
    String? snapshotType,
    String? entityId,
    String? academicSessionId,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, dynamic>? data,
    DateTime? computedAt,
    DateTime? expiresAt,
  }) {
    return AnalyticsSnapshotEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      snapshotType: snapshotType ?? this.snapshotType,
      entityId: entityId ?? this.entityId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      data: data ?? this.data,
      computedAt: computedAt ?? this.computedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id, schoolId, snapshotType, entityId, academicSessionId,
        periodStart, periodEnd, data, computedAt, expiresAt,
      ];
}

/// Class-level performance summary.
class ClassPerformanceEntity extends Equatable {
  const ClassPerformanceEntity({
    required this.id,
    required this.classId,
    required this.schoolId,
    this.subjectId,
    required this.academicSessionId,
    this.totalStudents = 0,
    this.averageScore = 0,
    this.highestScore = 0,
    this.lowestScore = 0,
    this.medianScore = 0,
    this.passRate = 0,
    this.distinctionRate = 0,
    this.gradeDistribution = const {},
    this.scoreDistribution = const [],
    this.topicPerformance = const {},
    this.improvementRate = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  final String schoolId;
  final String? subjectId;
  final String academicSessionId;
  final int totalStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double medianScore;
  final double passRate;
  final double distinctionRate;
  final Map<String, dynamic> gradeDistribution;
  final List<dynamic> scoreDistribution;
  final Map<String, dynamic> topicPerformance;
  final double improvementRate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassPerformanceEntity copyWith({
    String? id,
    String? classId,
    String? schoolId,
    String? subjectId,
    String? academicSessionId,
    int? totalStudents,
    double? averageScore,
    double? highestScore,
    double? lowestScore,
    double? medianScore,
    double? passRate,
    double? distinctionRate,
    Map<String, dynamic>? gradeDistribution,
    List<dynamic>? scoreDistribution,
    Map<String, dynamic>? topicPerformance,
    double? improvementRate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassPerformanceEntity(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      totalStudents: totalStudents ?? this.totalStudents,
      averageScore: averageScore ?? this.averageScore,
      highestScore: highestScore ?? this.highestScore,
      lowestScore: lowestScore ?? this.lowestScore,
      medianScore: medianScore ?? this.medianScore,
      passRate: passRate ?? this.passRate,
      distinctionRate: distinctionRate ?? this.distinctionRate,
      gradeDistribution: gradeDistribution ?? this.gradeDistribution,
      scoreDistribution: scoreDistribution ?? this.scoreDistribution,
      topicPerformance: topicPerformance ?? this.topicPerformance,
      improvementRate: improvementRate ?? this.improvementRate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, classId, schoolId, subjectId, academicSessionId,
        totalStudents, averageScore, highestScore, lowestScore,
        medianScore, passRate, distinctionRate, gradeDistribution,
        scoreDistribution, topicPerformance, improvementRate,
        metadata, createdAt, updatedAt,
      ];
}

/// School-level performance summary.
class SchoolPerformanceEntity extends Equatable {
  const SchoolPerformanceEntity({
    required this.id,
    required this.schoolId,
    required this.academicSessionId,
    this.totalStudents = 0,
    this.totalClasses = 0,
    this.totalExams = 0,
    this.averageScore = 0,
    this.passRate = 0,
    this.distinctionRate = 0,
    this.bestClassId,
    this.bestSubjectId,
    this.mostDifficultTopicId,
    this.classRankings = const [],
    this.subjectRankings = const [],
    this.gradeDistribution = const {},
    this.trendData = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String academicSessionId;
  final int totalStudents;
  final int totalClasses;
  final int totalExams;
  final double averageScore;
  final double passRate;
  final double distinctionRate;
  final String? bestClassId;
  final String? bestSubjectId;
  final String? mostDifficultTopicId;
  final List<dynamic> classRankings;
  final List<dynamic> subjectRankings;
  final Map<String, dynamic> gradeDistribution;
  final List<dynamic> trendData;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolPerformanceEntity copyWith({
    String? id,
    String? schoolId,
    String? academicSessionId,
    int? totalStudents,
    int? totalClasses,
    int? totalExams,
    double? averageScore,
    double? passRate,
    double? distinctionRate,
    String? bestClassId,
    String? bestSubjectId,
    String? mostDifficultTopicId,
    List<dynamic>? classRankings,
    List<dynamic>? subjectRankings,
    Map<String, dynamic>? gradeDistribution,
    List<dynamic>? trendData,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolPerformanceEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      totalStudents: totalStudents ?? this.totalStudents,
      totalClasses: totalClasses ?? this.totalClasses,
      totalExams: totalExams ?? this.totalExams,
      averageScore: averageScore ?? this.averageScore,
      passRate: passRate ?? this.passRate,
      distinctionRate: distinctionRate ?? this.distinctionRate,
      bestClassId: bestClassId ?? this.bestClassId,
      bestSubjectId: bestSubjectId ?? this.bestSubjectId,
      mostDifficultTopicId: mostDifficultTopicId ?? this.mostDifficultTopicId,
      classRankings: classRankings ?? this.classRankings,
      subjectRankings: subjectRankings ?? this.subjectRankings,
      gradeDistribution: gradeDistribution ?? this.gradeDistribution,
      trendData: trendData ?? this.trendData,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, schoolId, academicSessionId, totalStudents, totalClasses,
        totalExams, averageScore, passRate, distinctionRate, bestClassId,
        bestSubjectId, mostDifficultTopicId, classRankings,
        subjectRankings, gradeDistribution, trendData, metadata,
        createdAt, updatedAt,
      ];
}
