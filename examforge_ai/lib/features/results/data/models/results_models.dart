import '../../domain/entities/results_entities.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/results/domain/entities/results_entities.dart';
import '../../../../features/student_portal/domain/entities/student_portal_entities.dart';




// ═══════════════════════════════════════════════════════════════════════
// SUPPORTING MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a single entry within a grade scale.
class GradeScaleEntryModel {
  const GradeScaleEntryModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory GradeScaleEntryModel.fromJson(Map<String, dynamic> json) {
    return GradeScaleEntryModel(
      id: json['id'] as String? ?? '',
      minPercentage:
          (json['min_percentage'] as num?)?.toDouble() ??
          (json['minPercentage'] as num?)?.toDouble() ??
          0,
      maxPercentage:
          (json['max_percentage'] as num?)?.toDouble() ??
          (json['maxPercentage'] as num?)?.toDouble() ??
          0,
      grade: json['grade'] as String? ?? '',
      gpaValue:
          (json['gpa_value'] as num?)?.toDouble() ??
          (json['gpaValue'] as num?)?.toDouble(),
      description: json['description'] as String?,
      isPassing:
          json['is_passing'] as bool? ?? json['isPassing'] as bool? ?? false,
      color: json['color'] as String?,
      sortOrder:
          json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'min_percentage': minPercentage,
      'max_percentage': maxPercentage,
      'grade': grade,
      'gpa_value': gpaValue,
      'description': description,
      'is_passing': isPassing,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory GradeScaleEntryModel.fromEntity(GradeScaleEntryEntity entity) {
    return GradeScaleEntryModel(
      id: entity.id,
      minPercentage: entity.minPercentage,
      maxPercentage: entity.maxPercentage,
      grade: entity.grade,
      gpaValue: entity.gpaValue,
      description: entity.description,
      isPassing: entity.isPassing,
      color: entity.color,
      sortOrder: entity.sortOrder,
    );
  }

  GradeScaleEntryEntity toEntity() {
    return GradeScaleEntryEntity(
      id: id,
      minPercentage: minPercentage,
      maxPercentage: maxPercentage,
      grade: grade,
      gpaValue: gpaValue,
      description: description,
      isPassing: isPassing,
      color: color,
      sortOrder: sortOrder,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  GradeScaleEntryModel copyWith({
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
    return GradeScaleEntryModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeScaleEntryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          minPercentage == other.minPercentage &&
          maxPercentage == other.maxPercentage &&
          grade == other.grade &&
          gpaValue == other.gpaValue &&
          description == other.description &&
          isPassing == other.isPassing &&
          color == other.color &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        minPercentage,
        maxPercentage,
        grade,
        gpaValue,
        description,
        isPassing,
        color,
        sortOrder,
      );

  @override
  String toString() =>
      'GradeScaleEntryModel(id: $id, grade: $grade, min: $minPercentage, max: $maxPercentage)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a configurable grading scale.
class GradeScaleModel {
  const GradeScaleModel({
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
  final String gradeType;
  final bool isDefault;
  final bool isActive;
  final List<GradeScaleEntryModel> scaleEntries;
  final String? createdBy;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory GradeScaleModel.fromJson(Map<String, dynamic> json) {
    // Parse nested scale entries
    final rawEntries = json['scale_entries'] ?? json['scaleEntries'];
    final List<GradeScaleEntryModel> entries = rawEntries is List
        ? rawEntries
            .map(
                (e) => GradeScaleEntryModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <GradeScaleEntryModel>[];

    return GradeScaleModel(
      id: json['id'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gradeType: json['grade_type'] as String? ??
          json['gradeType'] as String? ??
          'percentage',
      isDefault:
          json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      scaleEntries: entries,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String?,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade_type': gradeType,
      'is_default': isDefault,
      'is_active': isActive,
      'scale_entries': scaleEntries.map((e) => e.toJson()).toList(),
      'created_by': createdBy,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory GradeScaleModel.fromEntity(GradeScaleEntity entity) {
    return GradeScaleModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      gradeType: entity.gradeType.value,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      scaleEntries:
          entity.scaleEntries.map(GradeScaleEntryModel.fromEntity).toList(),
      createdBy: entity.createdBy,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GradeScaleEntity toEntity() {
    return GradeScaleEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      gradeType: GradeType.fromString(gradeType) ?? GradeType.percentage,
      isDefault: isDefault,
      isActive: isActive,
      scaleEntries: scaleEntries.map((e) => e.toEntity()).toList(),
      createdBy: createdBy,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  GradeScaleModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? gradeType,
    bool? isDefault,
    bool? isActive,
    List<GradeScaleEntryModel>? scaleEntries,
    String? createdBy,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeScaleModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeScaleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name &&
          gradeType == other.gradeType &&
          isDefault == other.isDefault &&
          isActive == other.isActive &&
          scaleEntries == other.scaleEntries &&
          createdBy == other.createdBy &&
          settings == other.settings &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        name,
        gradeType,
        isDefault,
        isActive,
        scaleEntries,
        createdBy,
        settings,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'GradeScaleModel(id: $id, name: $name, gradeType: $gradeType)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an AI grading result.
class AiGradingResultModel {
  const AiGradingResultModel({
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
  final String status;
  final int? inputTokens;
  final int? outputTokens;
  final int? processingTimeMs;
  final String? errorMessage;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final double? finalScore;
  final String? reviewComment;
  final bool isAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AiGradingResultModel.fromJson(Map<String, dynamic> json) {
    return AiGradingResultModel(
      id: json['id'] as String? ?? '',
      answerId:
          json['answer_id'] as String? ?? json['answerId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      aiProvider: json['ai_provider'] as String? ??
          json['aiProvider'] as String? ??
          '',
      suggestedScore:
          (json['suggested_score'] as num?)?.toDouble() ??
          (json['suggestedScore'] as num?)?.toDouble() ??
          0,
      maxPossible:
          (json['max_possible'] as num?)?.toDouble() ??
          (json['maxPossible'] as num?)?.toDouble() ??
          0,
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble() ??
          (json['confidenceScore'] as num?)?.toDouble(),
      gradingRubric: json['grading_rubric'] as Map<String, dynamic>? ??
          json['gradingRubric'] as Map<String, dynamic>? ??
          {},
      explanation: json['explanation'] as String?,
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      inputTokens:
          json['input_tokens'] as int? ?? json['inputTokens'] as int?,
      outputTokens:
          json['output_tokens'] as int? ?? json['outputTokens'] as int?,
      processingTimeMs: json['processing_time_ms'] as int? ??
          json['processingTimeMs'] as int?,
      errorMessage:
          json['error_message'] as String? ?? json['errorMessage'] as String?,
      reviewedBy:
          json['reviewed_by'] as String? ?? json['reviewedBy'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : json['reviewedAt'] != null
              ? DateTime.parse(json['reviewedAt'] as String)
              : null,
      finalScore:
          (json['final_score'] as num?)?.toDouble() ??
          (json['finalScore'] as num?)?.toDouble(),
      reviewComment: json['review_comment'] as String? ??
          json['reviewComment'] as String?,
      isAccepted:
          json['is_accepted'] as bool? ?? json['isAccepted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer_id': answerId,
      'exam_id': examId,
      'student_id': studentId,
      'ai_provider': aiProvider,
      'suggested_score': suggestedScore,
      'max_possible': maxPossible,
      'confidence_score': confidenceScore,
      'grading_rubric': gradingRubric,
      'explanation': explanation,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'suggestions': suggestions,
      'status': status,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'processing_time_ms': processingTimeMs,
      'error_message': errorMessage,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'final_score': finalScore,
      'review_comment': reviewComment,
      'is_accepted': isAccepted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AiGradingResultModel.fromEntity(AiGradingResultEntity entity) {
    return AiGradingResultModel(
      id: entity.id,
      answerId: entity.answerId,
      examId: entity.examId,
      studentId: entity.studentId,
      aiProvider: entity.aiProvider,
      suggestedScore: entity.suggestedScore,
      maxPossible: entity.maxPossible,
      confidenceScore: entity.confidenceScore,
      gradingRubric: entity.gradingRubric,
      explanation: entity.explanation,
      strengths: entity.strengths,
      weaknesses: entity.weaknesses,
      suggestions: entity.suggestions,
      status: entity.status.value,
      inputTokens: entity.inputTokens,
      outputTokens: entity.outputTokens,
      processingTimeMs: entity.processingTimeMs,
      errorMessage: entity.errorMessage,
      reviewedBy: entity.reviewedBy,
      reviewedAt: entity.reviewedAt,
      finalScore: entity.finalScore,
      reviewComment: entity.reviewComment,
      isAccepted: entity.isAccepted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiGradingResultEntity toEntity() {
    return AiGradingResultEntity(
      id: id,
      answerId: answerId,
      examId: examId,
      studentId: studentId,
      aiProvider: aiProvider,
      suggestedScore: suggestedScore,
      maxPossible: maxPossible,
      confidenceScore: confidenceScore,
      gradingRubric: gradingRubric,
      explanation: explanation,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
      status:
          AiGradingStatus.fromString(status) ?? AiGradingStatus.pending,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      processingTimeMs: processingTimeMs,
      errorMessage: errorMessage,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      finalScore: finalScore,
      reviewComment: reviewComment,
      isAccepted: isAccepted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AiGradingResultModel copyWith({
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
    String? status,
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
    return AiGradingResultModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiGradingResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          answerId == other.answerId &&
          examId == other.examId &&
          studentId == other.studentId &&
          aiProvider == other.aiProvider &&
          suggestedScore == other.suggestedScore &&
          maxPossible == other.maxPossible &&
          confidenceScore == other.confidenceScore &&
          gradingRubric == other.gradingRubric &&
          explanation == other.explanation &&
          strengths == other.strengths &&
          weaknesses == other.weaknesses &&
          suggestions == other.suggestions &&
          status == other.status &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          processingTimeMs == other.processingTimeMs &&
          errorMessage == other.errorMessage &&
          reviewedBy == other.reviewedBy &&
          reviewedAt == other.reviewedAt &&
          finalScore == other.finalScore &&
          reviewComment == other.reviewComment &&
          isAccepted == other.isAccepted &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        answerId,
        examId,
        studentId,
        aiProvider,
        suggestedScore,
        maxPossible,
        confidenceScore,
        gradingRubric,
        explanation,
        strengths,
        weaknesses,
        suggestions,
        status,
        inputTokens,
        outputTokens,
        processingTimeMs,
        errorMessage,
        reviewedBy,
        reviewedAt,
        finalScore,
        reviewComment,
        isAccepted,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'AiGradingResultModel(id: $id, status: $status, suggestedScore: $suggestedScore)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of teacher feedback on a student answer.
class TeacherFeedbackModel {
  const TeacherFeedbackModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TeacherFeedbackModel.fromJson(Map<String, dynamic> json) {
    return TeacherFeedbackModel(
      id: json['id'] as String? ?? '',
      answerId:
          json['answer_id'] as String? ?? json['answerId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      teacherId:
          json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      marksAwarded:
          (json['marks_awarded'] as num?)?.toDouble() ??
          (json['marksAwarded'] as num?)?.toDouble() ??
          0,
      maxMarks:
          (json['max_marks'] as num?)?.toDouble() ??
          (json['maxMarks'] as num?)?.toDouble() ??
          0,
      comment: json['comment'] as String?,
      aiGradingId: json['ai_grading_id'] as String? ??
          json['aiGradingId'] as String?,
      overrodeAi:
          json['overrode_ai'] as bool? ?? json['overrodeAi'] as bool? ?? false,
      isPrivate:
          json['is_private'] as bool? ?? json['isPrivate'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer_id': answerId,
      'exam_id': examId,
      'student_id': studentId,
      'teacher_id': teacherId,
      'marks_awarded': marksAwarded,
      'max_marks': maxMarks,
      'comment': comment,
      'ai_grading_id': aiGradingId,
      'overrode_ai': overrodeAi,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TeacherFeedbackModel.fromEntity(TeacherFeedbackEntity entity) {
    return TeacherFeedbackModel(
      id: entity.id,
      answerId: entity.answerId,
      examId: entity.examId,
      studentId: entity.studentId,
      teacherId: entity.teacherId,
      marksAwarded: entity.marksAwarded,
      maxMarks: entity.maxMarks,
      comment: entity.comment,
      aiGradingId: entity.aiGradingId,
      overrodeAi: entity.overrodeAi,
      isPrivate: entity.isPrivate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TeacherFeedbackEntity toEntity() {
    return TeacherFeedbackEntity(
      id: id,
      answerId: answerId,
      examId: examId,
      studentId: studentId,
      teacherId: teacherId,
      marksAwarded: marksAwarded,
      maxMarks: maxMarks,
      comment: comment,
      aiGradingId: aiGradingId,
      overrodeAi: overrodeAi,
      isPrivate: isPrivate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TeacherFeedbackModel copyWith({
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
    return TeacherFeedbackModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherFeedbackModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          answerId == other.answerId &&
          examId == other.examId &&
          studentId == other.studentId &&
          teacherId == other.teacherId &&
          marksAwarded == other.marksAwarded &&
          maxMarks == other.maxMarks &&
          comment == other.comment &&
          aiGradingId == other.aiGradingId &&
          overrodeAi == other.overrodeAi &&
          isPrivate == other.isPrivate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        answerId,
        examId,
        studentId,
        teacherId,
        marksAwarded,
        maxMarks,
        comment,
        aiGradingId,
        overrodeAi,
        isPrivate,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'TeacherFeedbackModel(id: $id, marksAwarded: $marksAwarded/$maxMarks)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a student's aggregated result for a subject.
class StudentSubjectResultModel {
  const StudentSubjectResultModel({
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
    this.performanceTrend = 'stable',
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
  final String performanceTrend;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> aiRecommendations;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory StudentSubjectResultModel.fromJson(Map<String, dynamic> json) {
    return StudentSubjectResultModel(
      id: json['id'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      subjectId:
          json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      classId: json['class_id'] as String? ?? json['classId'] as String? ?? '',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      examCount:
          json['exam_count'] as int? ?? json['examCount'] as int? ?? 0,
      totalMarksObtained:
          (json['total_marks_obtained'] as num?)?.toDouble() ??
          (json['totalMarksObtained'] as num?)?.toDouble() ??
          0,
      totalMarksPossible:
          (json['total_marks_possible'] as num?)?.toDouble() ??
          (json['totalMarksPossible'] as num?)?.toDouble() ??
          0,
      percentage:
          (json['percentage'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String?,
      gpaValue:
          (json['gpa_value'] as num?)?.toDouble() ??
          (json['gpaValue'] as num?)?.toDouble(),
      classAverage:
          (json['class_average'] as num?)?.toDouble() ??
          (json['classAverage'] as num?)?.toDouble(),
      classPosition:
          json['class_position'] as int? ?? json['classPosition'] as int?,
      classSize: json['class_size'] as int? ?? json['classSize'] as int?,
      subjectAverage:
          (json['subject_average'] as num?)?.toDouble() ??
          (json['subjectAverage'] as num?)?.toDouble(),
      isPassed:
          json['is_passed'] as bool? ?? json['isPassed'] as bool? ?? false,
      performanceTrend: json['performance_trend'] as String? ??
          json['performanceTrend'] as String? ??
          'stable',
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiRecommendations: (json['ai_recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'subject_id': subjectId,
      'class_id': classId,
      'academic_session_id': academicSessionId,
      'exam_count': examCount,
      'total_marks_obtained': totalMarksObtained,
      'total_marks_possible': totalMarksPossible,
      'percentage': percentage,
      'grade': grade,
      'gpa_value': gpaValue,
      'class_average': classAverage,
      'class_position': classPosition,
      'class_size': classSize,
      'subject_average': subjectAverage,
      'is_passed': isPassed,
      'performance_trend': performanceTrend,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'ai_recommendations': aiRecommendations,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory StudentSubjectResultModel.fromEntity(
      StudentSubjectResultEntity entity) {
    return StudentSubjectResultModel(
      id: entity.id,
      studentId: entity.studentId,
      schoolId: entity.schoolId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      academicSessionId: entity.academicSessionId,
      examCount: entity.examCount,
      totalMarksObtained: entity.totalMarksObtained,
      totalMarksPossible: entity.totalMarksPossible,
      percentage: entity.percentage,
      grade: entity.grade,
      gpaValue: entity.gpaValue,
      classAverage: entity.classAverage,
      classPosition: entity.classPosition,
      classSize: entity.classSize,
      subjectAverage: entity.subjectAverage,
      isPassed: entity.isPassed,
      performanceTrend: entity.performanceTrend.value,
      strengths: entity.strengths,
      weaknesses: entity.weaknesses,
      aiRecommendations: entity.aiRecommendations,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  StudentSubjectResultEntity toEntity() {
    return StudentSubjectResultEntity(
      id: id,
      studentId: studentId,
      schoolId: schoolId,
      subjectId: subjectId,
      classId: classId,
      academicSessionId: academicSessionId,
      examCount: examCount,
      totalMarksObtained: totalMarksObtained,
      totalMarksPossible: totalMarksPossible,
      percentage: percentage,
      grade: grade,
      gpaValue: gpaValue,
      classAverage: classAverage,
      classPosition: classPosition,
      classSize: classSize,
      subjectAverage: subjectAverage,
      isPassed: isPassed,
      performanceTrend: PerformanceTrend.fromString(performanceTrend) ??
          PerformanceTrend.stable,
      strengths: strengths,
      weaknesses: weaknesses,
      aiRecommendations: aiRecommendations,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  StudentSubjectResultModel copyWith({
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
    String? performanceTrend,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? aiRecommendations,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentSubjectResultModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentSubjectResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          schoolId == other.schoolId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          academicSessionId == other.academicSessionId &&
          examCount == other.examCount &&
          totalMarksObtained == other.totalMarksObtained &&
          totalMarksPossible == other.totalMarksPossible &&
          percentage == other.percentage &&
          grade == other.grade &&
          gpaValue == other.gpaValue &&
          classAverage == other.classAverage &&
          classPosition == other.classPosition &&
          classSize == other.classSize &&
          subjectAverage == other.subjectAverage &&
          isPassed == other.isPassed &&
          performanceTrend == other.performanceTrend &&
          strengths == other.strengths &&
          weaknesses == other.weaknesses &&
          aiRecommendations == other.aiRecommendations &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        studentId,
        schoolId,
        subjectId,
        classId,
        academicSessionId,
        examCount,
        totalMarksObtained,
        totalMarksPossible,
        percentage,
        grade,
        gpaValue,
        classAverage,
        classPosition,
        classSize,
        subjectAverage,
        isPassed,
        performanceTrend,
        strengths,
        weaknesses,
        aiRecommendations,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'StudentSubjectResultModel(id: $id, subjectId: $subjectId, percentage: $percentage)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a student's overall result across all subjects.
class StudentOverallResultModel {
  const StudentOverallResultModel({
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
    this.performanceTrend = 'stable',
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
  final String performanceTrend;
  final String? bestSubjectId;
  final String? worstSubjectId;
  final List<String> aiStudyRecommendations;
  final String? teacherComment;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory StudentOverallResultModel.fromJson(Map<String, dynamic> json) {
    return StudentOverallResultModel(
      id: json['id'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      classId: json['class_id'] as String? ?? json['classId'] as String? ?? '',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      totalSubjects:
          json['total_subjects'] as int? ?? json['totalSubjects'] as int? ?? 0,
      totalMarksObtained:
          (json['total_marks_obtained'] as num?)?.toDouble() ??
          (json['totalMarksObtained'] as num?)?.toDouble() ??
          0,
      totalMarksPossible:
          (json['total_marks_possible'] as num?)?.toDouble() ??
          (json['totalMarksPossible'] as num?)?.toDouble() ??
          0,
      overallPercentage:
          (json['overall_percentage'] as num?)?.toDouble() ??
          (json['overallPercentage'] as num?)?.toDouble() ??
          0,
      overallGrade: json['overall_grade'] as String? ??
          json['overallGrade'] as String?,
      overallGpa:
          (json['overall_gpa'] as num?)?.toDouble() ??
          (json['overallGpa'] as num?)?.toDouble(),
      classAverage:
          (json['class_average'] as num?)?.toDouble() ??
          (json['classAverage'] as num?)?.toDouble(),
      classPosition:
          json['class_position'] as int? ?? json['classPosition'] as int?,
      classSize: json['class_size'] as int? ?? json['classSize'] as int?,
      subjectsPassed:
          json['subjects_passed'] as int? ?? json['subjectsPassed'] as int? ?? 0,
      subjectsFailed:
          json['subjects_failed'] as int? ?? json['subjectsFailed'] as int? ?? 0,
      isPromoted:
          json['is_promoted'] as bool? ?? json['isPromoted'] as bool?,
      performanceTrend: json['performance_trend'] as String? ??
          json['performanceTrend'] as String? ??
          'stable',
      bestSubjectId: json['best_subject_id'] as String? ??
          json['bestSubjectId'] as String?,
      worstSubjectId: json['worst_subject_id'] as String? ??
          json['worstSubjectId'] as String?,
      aiStudyRecommendations: (json['ai_study_recommendations']
                  as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      teacherComment: json['teacher_comment'] as String? ??
          json['teacherComment'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'class_id': classId,
      'academic_session_id': academicSessionId,
      'total_subjects': totalSubjects,
      'total_marks_obtained': totalMarksObtained,
      'total_marks_possible': totalMarksPossible,
      'overall_percentage': overallPercentage,
      'overall_grade': overallGrade,
      'overall_gpa': overallGpa,
      'class_average': classAverage,
      'class_position': classPosition,
      'class_size': classSize,
      'subjects_passed': subjectsPassed,
      'subjects_failed': subjectsFailed,
      'is_promoted': isPromoted,
      'performance_trend': performanceTrend,
      'best_subject_id': bestSubjectId,
      'worst_subject_id': worstSubjectId,
      'ai_study_recommendations': aiStudyRecommendations,
      'teacher_comment': teacherComment,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory StudentOverallResultModel.fromEntity(
      StudentOverallResultEntity entity) {
    return StudentOverallResultModel(
      id: entity.id,
      studentId: entity.studentId,
      schoolId: entity.schoolId,
      classId: entity.classId,
      academicSessionId: entity.academicSessionId,
      totalSubjects: entity.totalSubjects,
      totalMarksObtained: entity.totalMarksObtained,
      totalMarksPossible: entity.totalMarksPossible,
      overallPercentage: entity.overallPercentage,
      overallGrade: entity.overallGrade,
      overallGpa: entity.overallGpa,
      classAverage: entity.classAverage,
      classPosition: entity.classPosition,
      classSize: entity.classSize,
      subjectsPassed: entity.subjectsPassed,
      subjectsFailed: entity.subjectsFailed,
      isPromoted: entity.isPromoted,
      performanceTrend: entity.performanceTrend.value,
      bestSubjectId: entity.bestSubjectId,
      worstSubjectId: entity.worstSubjectId,
      aiStudyRecommendations: entity.aiStudyRecommendations,
      teacherComment: entity.teacherComment,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  StudentOverallResultEntity toEntity() {
    return StudentOverallResultEntity(
      id: id,
      studentId: studentId,
      schoolId: schoolId,
      classId: classId,
      academicSessionId: academicSessionId,
      totalSubjects: totalSubjects,
      totalMarksObtained: totalMarksObtained,
      totalMarksPossible: totalMarksPossible,
      overallPercentage: overallPercentage,
      overallGrade: overallGrade,
      overallGpa: overallGpa,
      classAverage: classAverage,
      classPosition: classPosition,
      classSize: classSize,
      subjectsPassed: subjectsPassed,
      subjectsFailed: subjectsFailed,
      isPromoted: isPromoted,
      performanceTrend: PerformanceTrend.fromString(performanceTrend) ??
          PerformanceTrend.stable,
      bestSubjectId: bestSubjectId,
      worstSubjectId: worstSubjectId,
      aiStudyRecommendations: aiStudyRecommendations,
      teacherComment: teacherComment,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  StudentOverallResultModel copyWith({
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
    String? performanceTrend,
    String? bestSubjectId,
    String? worstSubjectId,
    List<String>? aiStudyRecommendations,
    String? teacherComment,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentOverallResultModel(
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
      aiStudyRecommendations:
          aiStudyRecommendations ?? this.aiStudyRecommendations,
      teacherComment: teacherComment ?? this.teacherComment,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentOverallResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          schoolId == other.schoolId &&
          classId == other.classId &&
          academicSessionId == other.academicSessionId &&
          totalSubjects == other.totalSubjects &&
          totalMarksObtained == other.totalMarksObtained &&
          totalMarksPossible == other.totalMarksPossible &&
          overallPercentage == other.overallPercentage &&
          overallGrade == other.overallGrade &&
          overallGpa == other.overallGpa &&
          classAverage == other.classAverage &&
          classPosition == other.classPosition &&
          classSize == other.classSize &&
          subjectsPassed == other.subjectsPassed &&
          subjectsFailed == other.subjectsFailed &&
          isPromoted == other.isPromoted &&
          performanceTrend == other.performanceTrend &&
          bestSubjectId == other.bestSubjectId &&
          worstSubjectId == other.worstSubjectId &&
          aiStudyRecommendations == other.aiStudyRecommendations &&
          teacherComment == other.teacherComment &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        studentId,
        schoolId,
        classId,
        academicSessionId,
        totalSubjects,
        totalMarksObtained,
        totalMarksPossible,
        overallPercentage,
        overallGrade,
        overallGpa,
        classAverage,
        classPosition,
        classSize,
        subjectsPassed,
        subjectsFailed,
        isPromoted,
        performanceTrend,
        bestSubjectId,
        worstSubjectId,
        aiStudyRecommendations,
        teacherComment,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'StudentOverallResultModel(id: $id, overallPercentage: $overallPercentage)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of topic mastery tracking for a student.
class TopicMasteryModel {
  const TopicMasteryModel({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.topicId,
    required this.subjectId,
    this.masteryLevel = 'not_started',
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
  final String masteryLevel;
  final int questionsAttempted;
  final int questionsCorrect;
  final double accuracyPercentage;
  final int avgTimePerQuestion;
  final DateTime? lastPracticedAt;
  final int improvementStreak;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TopicMasteryModel.fromJson(Map<String, dynamic> json) {
    return TopicMasteryModel(
      id: json['id'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? json['topicId'] as String? ?? '',
      subjectId:
          json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      masteryLevel: json['mastery_level'] as String? ??
          json['masteryLevel'] as String? ??
          'not_started',
      questionsAttempted: json['questions_attempted'] as int? ??
          json['questionsAttempted'] as int? ??
          0,
      questionsCorrect: json['questions_correct'] as int? ??
          json['questionsCorrect'] as int? ??
          0,
      accuracyPercentage:
          (json['accuracy_percentage'] as num?)?.toDouble() ??
          (json['accuracyPercentage'] as num?)?.toDouble() ??
          0,
      avgTimePerQuestion: json['avg_time_per_question'] as int? ??
          json['avgTimePerQuestion'] as int? ??
          0,
      lastPracticedAt: json['last_practiced_at'] != null
          ? DateTime.parse(json['last_practiced_at'] as String)
          : json['lastPracticedAt'] != null
              ? DateTime.parse(json['lastPracticedAt'] as String)
              : null,
      improvementStreak: json['improvement_streak'] as int? ??
          json['improvementStreak'] as int? ??
          0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'topic_id': topicId,
      'subject_id': subjectId,
      'mastery_level': masteryLevel,
      'questions_attempted': questionsAttempted,
      'questions_correct': questionsCorrect,
      'accuracy_percentage': accuracyPercentage,
      'avg_time_per_question': avgTimePerQuestion,
      'last_practiced_at': lastPracticedAt?.toIso8601String(),
      'improvement_streak': improvementStreak,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TopicMasteryModel.fromEntity(TopicMasteryEntity entity) {
    return TopicMasteryModel(
      id: entity.id,
      studentId: entity.studentId,
      schoolId: entity.schoolId,
      topicId: entity.topicId,
      subjectId: entity.subjectId,
      masteryLevel: entity.masteryLevel.value,
      questionsAttempted: entity.questionsAttempted,
      questionsCorrect: entity.questionsCorrect,
      accuracyPercentage: entity.accuracyPercentage,
      avgTimePerQuestion: entity.avgTimePerQuestion,
      lastPracticedAt: entity.lastPracticedAt,
      improvementStreak: entity.improvementStreak,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TopicMasteryEntity toEntity() {
    return TopicMasteryEntity(
      id: id,
      studentId: studentId,
      schoolId: schoolId,
      topicId: topicId,
      subjectId: subjectId,
      masteryLevel: MasteryLevel.fromString(masteryLevel) ??
          MasteryLevel.notStarted,
      questionsAttempted: questionsAttempted,
      questionsCorrect: questionsCorrect,
      accuracyPercentage: accuracyPercentage,
      avgTimePerQuestion: avgTimePerQuestion,
      lastPracticedAt: lastPracticedAt,
      improvementStreak: improvementStreak,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TopicMasteryModel copyWith({
    String? id,
    String? studentId,
    String? schoolId,
    String? topicId,
    String? subjectId,
    String? masteryLevel,
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
    return TopicMasteryModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMasteryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          schoolId == other.schoolId &&
          topicId == other.topicId &&
          subjectId == other.subjectId &&
          masteryLevel == other.masteryLevel &&
          questionsAttempted == other.questionsAttempted &&
          questionsCorrect == other.questionsCorrect &&
          accuracyPercentage == other.accuracyPercentage &&
          avgTimePerQuestion == other.avgTimePerQuestion &&
          lastPracticedAt == other.lastPracticedAt &&
          improvementStreak == other.improvementStreak &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        studentId,
        schoolId,
        topicId,
        subjectId,
        masteryLevel,
        questionsAttempted,
        questionsCorrect,
        accuracyPercentage,
        avgTimePerQuestion,
        lastPracticedAt,
        improvementStreak,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'TopicMasteryModel(id: $id, topicId: $topicId, masteryLevel: $masteryLevel)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a dashboard widget configuration.
class DashboardWidgetConfigModel {
  const DashboardWidgetConfigModel({
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
  final String widgetType;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory DashboardWidgetConfigModel.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfigModel(
      id: json['id'] as String? ?? '',
      dashboardId: json['dashboard_id'] as String? ??
          json['dashboardId'] as String? ??
          '',
      widgetType: json['widget_type'] as String? ??
          json['widgetType'] as String? ??
          'pass_rate',
      title: json['title'] as String? ?? '',
      positionRow:
          json['position_row'] as int? ?? json['positionRow'] as int? ?? 0,
      positionCol:
          json['position_col'] as int? ?? json['positionCol'] as int? ?? 0,
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
      isVisible:
          json['is_visible'] as bool? ?? json['isVisible'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
      dataSource: json['data_source'] as Map<String, dynamic>? ??
          json['dataSource'] as Map<String, dynamic>? ??
          {},
      refreshInterval: json['refresh_interval'] as int? ??
          json['refreshInterval'] as int? ??
          300,
      sortOrder:
          json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dashboard_id': dashboardId,
      'widget_type': widgetType,
      'title': title,
      'position_row': positionRow,
      'position_col': positionCol,
      'width': width,
      'height': height,
      'is_visible': isVisible,
      'config': config,
      'data_source': dataSource,
      'refresh_interval': refreshInterval,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory DashboardWidgetConfigModel.fromEntity(
      DashboardWidgetConfigEntity entity) {
    return DashboardWidgetConfigModel(
      id: entity.id,
      dashboardId: entity.dashboardId,
      widgetType: entity.widgetType.value,
      title: entity.title,
      positionRow: entity.positionRow,
      positionCol: entity.positionCol,
      width: entity.width,
      height: entity.height,
      isVisible: entity.isVisible,
      config: entity.config,
      dataSource: entity.dataSource,
      refreshInterval: entity.refreshInterval,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DashboardWidgetConfigEntity toEntity() {
    return DashboardWidgetConfigEntity(
      id: id,
      dashboardId: dashboardId,
      widgetType: DashboardWidgetType.fromString(widgetType) ??
          DashboardWidgetType.passRate,
      title: title,
      positionRow: positionRow,
      positionCol: positionCol,
      width: width,
      height: height,
      isVisible: isVisible,
      config: config,
      dataSource: dataSource,
      refreshInterval: refreshInterval,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  DashboardWidgetConfigModel copyWith({
    String? id,
    String? dashboardId,
    String? widgetType,
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
    return DashboardWidgetConfigModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardWidgetConfigModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dashboardId == other.dashboardId &&
          widgetType == other.widgetType &&
          title == other.title &&
          positionRow == other.positionRow &&
          positionCol == other.positionCol &&
          width == other.width &&
          height == other.height &&
          isVisible == other.isVisible &&
          config == other.config &&
          dataSource == other.dataSource &&
          refreshInterval == other.refreshInterval &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        dashboardId,
        widgetType,
        title,
        positionRow,
        positionCol,
        width,
        height,
        isVisible,
        config,
        dataSource,
        refreshInterval,
        sortOrder,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'DashboardWidgetConfigModel(id: $id, widgetType: $widgetType, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a configurable analytics dashboard.
class DashboardConfigurationModel {
  const DashboardConfigurationModel({
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
  final List<DashboardWidgetConfigModel> widgets;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory DashboardConfigurationModel.fromJson(Map<String, dynamic> json) {
    // Parse nested widgets
    final rawWidgets = json['widgets'];
    final List<DashboardWidgetConfigModel> widgetList = rawWidgets is List
        ? rawWidgets
            .map((e) =>
                DashboardWidgetConfigModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DashboardWidgetConfigModel>[];

    return DashboardConfigurationModel(
      id: json['id'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isDefault:
          json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      layout: json['layout'] as Map<String, dynamic>? ?? {},
      widgets: widgetList,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'role': role,
      'name': name,
      'is_default': isDefault,
      'is_active': isActive,
      'layout': layout,
      'widgets': widgets.map((e) => e.toJson()).toList(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory DashboardConfigurationModel.fromEntity(
      DashboardConfigurationEntity entity) {
    return DashboardConfigurationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      role: entity.role,
      name: entity.name,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      layout: entity.layout,
      widgets:
          entity.widgets.map(DashboardWidgetConfigModel.fromEntity).toList(),
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DashboardConfigurationEntity toEntity() {
    return DashboardConfigurationEntity(
      id: id,
      schoolId: schoolId,
      role: role,
      name: name,
      isDefault: isDefault,
      isActive: isActive,
      layout: layout,
      widgets: widgets.map((e) => e.toEntity()).toList(),
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  DashboardConfigurationModel copyWith({
    String? id,
    String? schoolId,
    String? role,
    String? name,
    bool? isDefault,
    bool? isActive,
    Map<String, dynamic>? layout,
    List<DashboardWidgetConfigModel>? widgets,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DashboardConfigurationModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardConfigurationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          role == other.role &&
          name == other.name &&
          isDefault == other.isDefault &&
          isActive == other.isActive &&
          layout == other.layout &&
          widgets == other.widgets &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        role,
        name,
        isDefault,
        isActive,
        layout,
        widgets,
        createdBy,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'DashboardConfigurationModel(id: $id, name: $name, role: $role)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a report export record.
class ReportExportModel {
  const ReportExportModel({
    required this.id,
    required this.schoolId,
    required this.requestedBy,
    required this.reportType,
    required this.reportFormat,
    this.status = 'pending',
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
  final String reportType;
  final String reportFormat;
  final String status;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ReportExportModel.fromJson(Map<String, dynamic> json) {
    return ReportExportModel(
      id: json['id'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      requestedBy: json['requested_by'] as String? ??
          json['requestedBy'] as String? ??
          '',
      reportType: json['report_type'] as String? ??
          json['reportType'] as String? ??
          'student',
      reportFormat: json['report_format'] as String? ??
          json['reportFormat'] as String? ??
          'pdf',
      status: json['status'] as String? ?? 'pending',
      title: json['title'] as String? ?? '',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      filters: json['filters'] as Map<String, dynamic>? ?? {},
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int? ??
          json['fileSizeBytes'] as int?,
      rowCount: json['row_count'] as int? ?? json['rowCount'] as int?,
      errorMessage:
          json['error_message'] as String? ?? json['errorMessage'] as String?,
      processingTimeMs: json['processing_time_ms'] as int? ??
          json['processingTimeMs'] as int?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.parse(json['downloaded_at'] as String)
          : json['downloadedAt'] != null
              ? DateTime.parse(json['downloadedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'requested_by': requestedBy,
      'report_type': reportType,
      'report_format': reportFormat,
      'status': status,
      'title': title,
      'parameters': parameters,
      'filters': filters,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'row_count': rowCount,
      'error_message': errorMessage,
      'processing_time_ms': processingTimeMs,
      'expires_at': expiresAt?.toIso8601String(),
      'downloaded_at': downloadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ReportExportModel.fromEntity(ReportExportEntity entity) {
    return ReportExportModel(
      id: entity.id,
      schoolId: entity.schoolId,
      requestedBy: entity.requestedBy,
      reportType: entity.reportType.value,
      reportFormat: entity.reportFormat.value,
      status: entity.status.value,
      title: entity.title,
      parameters: entity.parameters,
      filters: entity.filters,
      fileUrl: entity.fileUrl,
      fileSizeBytes: entity.fileSizeBytes,
      rowCount: entity.rowCount,
      errorMessage: entity.errorMessage,
      processingTimeMs: entity.processingTimeMs,
      expiresAt: entity.expiresAt,
      downloadedAt: entity.downloadedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ReportExportEntity toEntity() {
    return ReportExportEntity(
      id: id,
      schoolId: schoolId,
      requestedBy: requestedBy,
      reportType: ReportType.fromString(reportType) ?? ReportType.student,
      reportFormat:
          ReportFormat.fromString(reportFormat) ?? ReportFormat.pdf,
      status: ReportStatus.fromString(status) ?? ReportStatus.pending,
      title: title,
      parameters: parameters,
      filters: filters,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      rowCount: rowCount,
      errorMessage: errorMessage,
      processingTimeMs: processingTimeMs,
      expiresAt: expiresAt,
      downloadedAt: downloadedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ReportExportModel copyWith({
    String? id,
    String? schoolId,
    String? requestedBy,
    String? reportType,
    String? reportFormat,
    String? status,
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
    return ReportExportModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportExportModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          requestedBy == other.requestedBy &&
          reportType == other.reportType &&
          reportFormat == other.reportFormat &&
          status == other.status &&
          title == other.title &&
          parameters == other.parameters &&
          filters == other.filters &&
          fileUrl == other.fileUrl &&
          fileSizeBytes == other.fileSizeBytes &&
          rowCount == other.rowCount &&
          errorMessage == other.errorMessage &&
          processingTimeMs == other.processingTimeMs &&
          expiresAt == other.expiresAt &&
          downloadedAt == other.downloadedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        requestedBy,
        reportType,
        reportFormat,
        status,
        title,
        parameters,
        filters,
        fileUrl,
        fileSizeBytes,
        rowCount,
        errorMessage,
        processingTimeMs,
        expiresAt,
        downloadedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ReportExportModel(id: $id, title: $title, status: $status)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a result lock for an exam.
class ResultLockModel {
  const ResultLockModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ResultLockModel.fromJson(Map<String, dynamic> json) {
    return ResultLockModel(
      id: json['id'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      lockedBy:
          json['locked_by'] as String? ?? json['lockedBy'] as String? ?? '',
      lockedAt: json['locked_at'] != null
          ? DateTime.parse(json['locked_at'] as String)
          : json['lockedAt'] != null
              ? DateTime.parse(json['lockedAt'] as String)
              : DateTime.now(),
      reason: json['reason'] as String?,
      isLocked:
          json['is_locked'] as bool? ?? json['isLocked'] as bool? ?? true,
      unlockedBy:
          json['unlocked_by'] as String? ?? json['unlockedBy'] as String?,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : json['unlockedAt'] != null
              ? DateTime.parse(json['unlockedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'school_id': schoolId,
      'locked_by': lockedBy,
      'locked_at': lockedAt.toIso8601String(),
      'reason': reason,
      'is_locked': isLocked,
      'unlocked_by': unlockedBy,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ResultLockModel.fromEntity(ResultLockEntity entity) {
    return ResultLockModel(
      id: entity.id,
      examId: entity.examId,
      schoolId: entity.schoolId,
      lockedBy: entity.lockedBy,
      lockedAt: entity.lockedAt,
      reason: entity.reason,
      isLocked: entity.isLocked,
      unlockedBy: entity.unlockedBy,
      unlockedAt: entity.unlockedAt,
      createdAt: entity.createdAt,
    );
  }

  ResultLockEntity toEntity() {
    return ResultLockEntity(
      id: id,
      examId: examId,
      schoolId: schoolId,
      lockedBy: lockedBy,
      lockedAt: lockedAt,
      reason: reason,
      isLocked: isLocked,
      unlockedBy: unlockedBy,
      unlockedAt: unlockedAt,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ResultLockModel copyWith({
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
    return ResultLockModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultLockModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          schoolId == other.schoolId &&
          lockedBy == other.lockedBy &&
          lockedAt == other.lockedAt &&
          reason == other.reason &&
          isLocked == other.isLocked &&
          unlockedBy == other.unlockedBy &&
          unlockedAt == other.unlockedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        schoolId,
        lockedBy,
        lockedAt,
        reason,
        isLocked,
        unlockedBy,
        unlockedAt,
        createdAt,
      );

  @override
  String toString() =>
      'ResultLockModel(id: $id, examId: $examId, isLocked: $isLocked)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a pre-computed analytics snapshot.
class AnalyticsSnapshotModel {
  const AnalyticsSnapshotModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AnalyticsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSnapshotModel(
      id: json['id'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      snapshotType: json['snapshot_type'] as String? ??
          json['snapshotType'] as String? ??
          '',
      entityId:
          json['entity_id'] as String? ?? json['entityId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : json['periodStart'] != null
              ? DateTime.parse(json['periodStart'] as String)
              : DateTime.now(),
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : json['periodEnd'] != null
              ? DateTime.parse(json['periodEnd'] as String)
              : DateTime.now(),
      data: json['data'] as Map<String, dynamic>? ?? {},
      computedAt: json['computed_at'] != null
          ? DateTime.parse(json['computed_at'] as String)
          : json['computedAt'] != null
              ? DateTime.parse(json['computedAt'] as String)
              : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'snapshot_type': snapshotType,
      'entity_id': entityId,
      'academic_session_id': academicSessionId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'data': data,
      'computed_at': computedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AnalyticsSnapshotModel.fromEntity(AnalyticsSnapshotEntity entity) {
    return AnalyticsSnapshotModel(
      id: entity.id,
      schoolId: entity.schoolId,
      snapshotType: entity.snapshotType,
      entityId: entity.entityId,
      academicSessionId: entity.academicSessionId,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      data: entity.data,
      computedAt: entity.computedAt,
      expiresAt: entity.expiresAt,
    );
  }

  AnalyticsSnapshotEntity toEntity() {
    return AnalyticsSnapshotEntity(
      id: id,
      schoolId: schoolId,
      snapshotType: snapshotType,
      entityId: entityId,
      academicSessionId: academicSessionId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      data: data,
      computedAt: computedAt,
      expiresAt: expiresAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AnalyticsSnapshotModel copyWith({
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
    return AnalyticsSnapshotModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSnapshotModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          snapshotType == other.snapshotType &&
          entityId == other.entityId &&
          academicSessionId == other.academicSessionId &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          data == other.data &&
          computedAt == other.computedAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        snapshotType,
        entityId,
        academicSessionId,
        periodStart,
        periodEnd,
        data,
        computedAt,
        expiresAt,
      );

  @override
  String toString() =>
      'AnalyticsSnapshotModel(id: $id, snapshotType: $snapshotType)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a class-level performance summary.
class ClassPerformanceModel {
  const ClassPerformanceModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ClassPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ClassPerformanceModel(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? json['classId'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      subjectId:
          json['subject_id'] as String? ?? json['subjectId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      totalStudents:
          json['total_students'] as int? ?? json['totalStudents'] as int? ?? 0,
      averageScore:
          (json['average_score'] as num?)?.toDouble() ??
          (json['averageScore'] as num?)?.toDouble() ??
          0,
      highestScore:
          (json['highest_score'] as num?)?.toDouble() ??
          (json['highestScore'] as num?)?.toDouble() ??
          0,
      lowestScore:
          (json['lowest_score'] as num?)?.toDouble() ??
          (json['lowestScore'] as num?)?.toDouble() ??
          0,
      medianScore:
          (json['median_score'] as num?)?.toDouble() ??
          (json['medianScore'] as num?)?.toDouble() ??
          0,
      passRate:
          (json['pass_rate'] as num?)?.toDouble() ??
          (json['passRate'] as num?)?.toDouble() ??
          0,
      distinctionRate:
          (json['distinction_rate'] as num?)?.toDouble() ??
          (json['distinctionRate'] as num?)?.toDouble() ??
          0,
      gradeDistribution:
          json['grade_distribution'] as Map<String, dynamic>? ??
              json['gradeDistribution'] as Map<String, dynamic>? ??
              {},
      scoreDistribution: json['score_distribution'] as List<dynamic>? ??
          json['scoreDistribution'] as List<dynamic>? ??
          [],
      topicPerformance: json['topic_performance'] as Map<String, dynamic>? ??
          json['topicPerformance'] as Map<String, dynamic>? ??
          {},
      improvementRate:
          (json['improvement_rate'] as num?)?.toDouble() ??
          (json['improvementRate'] as num?)?.toDouble() ??
          0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'school_id': schoolId,
      'subject_id': subjectId,
      'academic_session_id': academicSessionId,
      'total_students': totalStudents,
      'average_score': averageScore,
      'highest_score': highestScore,
      'lowest_score': lowestScore,
      'median_score': medianScore,
      'pass_rate': passRate,
      'distinction_rate': distinctionRate,
      'grade_distribution': gradeDistribution,
      'score_distribution': scoreDistribution,
      'topic_performance': topicPerformance,
      'improvement_rate': improvementRate,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ClassPerformanceModel.fromEntity(ClassPerformanceEntity entity) {
    return ClassPerformanceModel(
      id: entity.id,
      classId: entity.classId,
      schoolId: entity.schoolId,
      subjectId: entity.subjectId,
      academicSessionId: entity.academicSessionId,
      totalStudents: entity.totalStudents,
      averageScore: entity.averageScore,
      highestScore: entity.highestScore,
      lowestScore: entity.lowestScore,
      medianScore: entity.medianScore,
      passRate: entity.passRate,
      distinctionRate: entity.distinctionRate,
      gradeDistribution: entity.gradeDistribution,
      scoreDistribution: entity.scoreDistribution,
      topicPerformance: entity.topicPerformance,
      improvementRate: entity.improvementRate,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ClassPerformanceEntity toEntity() {
    return ClassPerformanceEntity(
      id: id,
      classId: classId,
      schoolId: schoolId,
      subjectId: subjectId,
      academicSessionId: academicSessionId,
      totalStudents: totalStudents,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      medianScore: medianScore,
      passRate: passRate,
      distinctionRate: distinctionRate,
      gradeDistribution: gradeDistribution,
      scoreDistribution: scoreDistribution,
      topicPerformance: topicPerformance,
      improvementRate: improvementRate,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ClassPerformanceModel copyWith({
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
    return ClassPerformanceModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassPerformanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          classId == other.classId &&
          schoolId == other.schoolId &&
          subjectId == other.subjectId &&
          academicSessionId == other.academicSessionId &&
          totalStudents == other.totalStudents &&
          averageScore == other.averageScore &&
          highestScore == other.highestScore &&
          lowestScore == other.lowestScore &&
          medianScore == other.medianScore &&
          passRate == other.passRate &&
          distinctionRate == other.distinctionRate &&
          gradeDistribution == other.gradeDistribution &&
          scoreDistribution == other.scoreDistribution &&
          topicPerformance == other.topicPerformance &&
          improvementRate == other.improvementRate &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        classId,
        schoolId,
        subjectId,
        academicSessionId,
        totalStudents,
        averageScore,
        highestScore,
        lowestScore,
        medianScore,
        passRate,
        distinctionRate,
        gradeDistribution,
        scoreDistribution,
        topicPerformance,
        improvementRate,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ClassPerformanceModel(id: $id, classId: $classId, averageScore: $averageScore)';
}

// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a school-level performance summary.
class SchoolPerformanceModel {
  const SchoolPerformanceModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SchoolPerformanceModel.fromJson(Map<String, dynamic> json) {
    return SchoolPerformanceModel(
      id: json['id'] as String? ?? '',
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      totalStudents:
          json['total_students'] as int? ?? json['totalStudents'] as int? ?? 0,
      totalClasses:
          json['total_classes'] as int? ?? json['totalClasses'] as int? ?? 0,
      totalExams:
          json['total_exams'] as int? ?? json['totalExams'] as int? ?? 0,
      averageScore:
          (json['average_score'] as num?)?.toDouble() ??
          (json['averageScore'] as num?)?.toDouble() ??
          0,
      passRate:
          (json['pass_rate'] as num?)?.toDouble() ??
          (json['passRate'] as num?)?.toDouble() ??
          0,
      distinctionRate:
          (json['distinction_rate'] as num?)?.toDouble() ??
          (json['distinctionRate'] as num?)?.toDouble() ??
          0,
      bestClassId: json['best_class_id'] as String? ??
          json['bestClassId'] as String?,
      bestSubjectId: json['best_subject_id'] as String? ??
          json['bestSubjectId'] as String?,
      mostDifficultTopicId: json['most_difficult_topic_id'] as String? ??
          json['mostDifficultTopicId'] as String?,
      classRankings: json['class_rankings'] as List<dynamic>? ??
          json['classRankings'] as List<dynamic>? ??
          [],
      subjectRankings: json['subject_rankings'] as List<dynamic>? ??
          json['subjectRankings'] as List<dynamic>? ??
          [],
      gradeDistribution:
          json['grade_distribution'] as Map<String, dynamic>? ??
              json['gradeDistribution'] as Map<String, dynamic>? ??
              {},
      trendData: json['trend_data'] as List<dynamic>? ??
          json['trendData'] as List<dynamic>? ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'academic_session_id': academicSessionId,
      'total_students': totalStudents,
      'total_classes': totalClasses,
      'total_exams': totalExams,
      'average_score': averageScore,
      'pass_rate': passRate,
      'distinction_rate': distinctionRate,
      'best_class_id': bestClassId,
      'best_subject_id': bestSubjectId,
      'most_difficult_topic_id': mostDifficultTopicId,
      'class_rankings': classRankings,
      'subject_rankings': subjectRankings,
      'grade_distribution': gradeDistribution,
      'trend_data': trendData,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SchoolPerformanceModel.fromEntity(SchoolPerformanceEntity entity) {
    return SchoolPerformanceModel(
      id: entity.id,
      schoolId: entity.schoolId,
      academicSessionId: entity.academicSessionId,
      totalStudents: entity.totalStudents,
      totalClasses: entity.totalClasses,
      totalExams: entity.totalExams,
      averageScore: entity.averageScore,
      passRate: entity.passRate,
      distinctionRate: entity.distinctionRate,
      bestClassId: entity.bestClassId,
      bestSubjectId: entity.bestSubjectId,
      mostDifficultTopicId: entity.mostDifficultTopicId,
      classRankings: entity.classRankings,
      subjectRankings: entity.subjectRankings,
      gradeDistribution: entity.gradeDistribution,
      trendData: entity.trendData,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolPerformanceEntity toEntity() {
    return SchoolPerformanceEntity(
      id: id,
      schoolId: schoolId,
      academicSessionId: academicSessionId,
      totalStudents: totalStudents,
      totalClasses: totalClasses,
      totalExams: totalExams,
      averageScore: averageScore,
      passRate: passRate,
      distinctionRate: distinctionRate,
      bestClassId: bestClassId,
      bestSubjectId: bestSubjectId,
      mostDifficultTopicId: mostDifficultTopicId,
      classRankings: classRankings,
      subjectRankings: subjectRankings,
      gradeDistribution: gradeDistribution,
      trendData: trendData,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SchoolPerformanceModel copyWith({
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
    return SchoolPerformanceModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolPerformanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          academicSessionId == other.academicSessionId &&
          totalStudents == other.totalStudents &&
          totalClasses == other.totalClasses &&
          totalExams == other.totalExams &&
          averageScore == other.averageScore &&
          passRate == other.passRate &&
          distinctionRate == other.distinctionRate &&
          bestClassId == other.bestClassId &&
          bestSubjectId == other.bestSubjectId &&
          mostDifficultTopicId == other.mostDifficultTopicId &&
          classRankings == other.classRankings &&
          subjectRankings == other.subjectRankings &&
          gradeDistribution == other.gradeDistribution &&
          trendData == other.trendData &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        academicSessionId,
        totalStudents,
        totalClasses,
        totalExams,
        averageScore,
        passRate,
        distinctionRate,
        bestClassId,
        bestSubjectId,
        mostDifficultTopicId,
        classRankings,
        subjectRankings,
        gradeDistribution,
        trendData,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'SchoolPerformanceModel(id: $id, schoolId: $schoolId, averageScore: $averageScore)';
}
