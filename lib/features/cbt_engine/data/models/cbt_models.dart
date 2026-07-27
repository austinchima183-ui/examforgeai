import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/cbt_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// CBT ENGINE DATA MODELS
// ═══════════════════════════════════════════════════════════════════════
// Plain class models (NOT Equatable) for the CBT Engine data layer.
// Pattern: fromJson (snake_case & camelCase), toJson (snake_case for
// Supabase), fromEntity, toEntity, copyWith, manual == and hashCode.
// ═══════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────────
// Helper: parse DateTime accepting both snake_case and camelCase keys
// ───────────────────────────────────────────────────────────────────────

DateTime _parseDateTime(dynamic value) {
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return DateTime.now();
}

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return null;
}

// ═══════════════════════════════════════════════════════════════════════
// ExamSectionModel
// ═══════════════════════════════════════════════════════════════════════

class ExamSectionModel {
  const ExamSectionModel({
    required this.id,
    required this.examId,
    required this.title,
    this.description,
    this.instructions,
    required this.sortOrder,
    this.timeLimitMinutes,
    this.randomizeQuestions = false,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String title;
  final String? description;
  final String? instructions;
  final int sortOrder;
  final int? timeLimitMinutes;
  final bool randomizeQuestions;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamSectionModel.fromJson(Map<String, dynamic> json) {
    return ExamSectionModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      timeLimitMinutes:
          json['time_limit_minutes'] as int? ?? json['timeLimitMinutes'] as int?,
      randomizeQuestions: json['randomize_questions'] as bool? ??
          json['randomizeQuestions'] as bool? ??
          false,
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'sort_order': sortOrder,
      'time_limit_minutes': timeLimitMinutes,
      'randomize_questions': randomizeQuestions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamSectionModel.fromEntity(ExamSectionEntity entity) {
    return ExamSectionModel(
      id: entity.id,
      examId: entity.examId,
      title: entity.title,
      description: entity.description,
      instructions: entity.instructions,
      sortOrder: entity.sortOrder,
      timeLimitMinutes: entity.timeLimitMinutes,
      randomizeQuestions: entity.randomizeQuestions,
      createdAt: entity.createdAt,
    );
  }

  ExamSectionEntity toEntity() {
    return ExamSectionEntity(
      id: id,
      examId: examId,
      title: title,
      description: description,
      instructions: instructions,
      sortOrder: sortOrder,
      timeLimitMinutes: timeLimitMinutes,
      randomizeQuestions: randomizeQuestions,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamSectionModel copyWith({
    String? id,
    String? examId,
    String? title,
    String? description,
    String? instructions,
    int? sortOrder,
    int? timeLimitMinutes,
    bool? randomizeQuestions,
    DateTime? createdAt,
  }) {
    return ExamSectionModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sortOrder: sortOrder ?? this.sortOrder,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamSectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          title == other.title &&
          description == other.description &&
          instructions == other.instructions &&
          sortOrder == other.sortOrder &&
          timeLimitMinutes == other.timeLimitMinutes &&
          randomizeQuestions == other.randomizeQuestions &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        title,
        description,
        instructions,
        sortOrder,
        timeLimitMinutes,
        randomizeQuestions,
        createdAt,
      );

  @override
  String toString() =>
      'ExamSectionModel(id: $id, title: $title, examId: $examId)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamQuestionModel
// ═══════════════════════════════════════════════════════════════════════

class ExamQuestionModel {
  const ExamQuestionModel({
    required this.id,
    required this.examId,
    this.sectionId,
    required this.questionId,
    required this.sortOrder,
    required this.marks,
    this.negativeMarks = 0.0,
    this.isCompulsory = true,
    this.question,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String? sectionId;
  final String questionId;
  final int sortOrder;
  final double marks;
  final double negativeMarks;
  final bool isCompulsory;

  /// Full question data loaded from a join, stored as JSON map.
  final Map<String, dynamic>? question;

  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    return ExamQuestionModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      sectionId: json['section_id'] as String? ?? json['sectionId'] as String?,
      questionId:
          json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      negativeMarks:
          (json['negative_marks'] as num?)?.toDouble() ??
              (json['negativeMarks'] as num?)?.toDouble() ??
              0.0,
      isCompulsory: json['is_compulsory'] as bool? ??
          json['isCompulsory'] as bool? ??
          true,
      question: json['question'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'section_id': sectionId,
      'question_id': questionId,
      'sort_order': sortOrder,
      'marks': marks,
      'negative_marks': negativeMarks,
      'is_compulsory': isCompulsory,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamQuestionModel.fromEntity(ExamQuestionEntity entity) {
    return ExamQuestionModel(
      id: entity.id,
      examId: entity.examId,
      sectionId: entity.sectionId,
      questionId: entity.questionId,
      sortOrder: entity.sortOrder,
      marks: entity.marks,
      negativeMarks: entity.negativeMarks,
      isCompulsory: entity.isCompulsory,
      question: entity.question != null ? _questionEntityToJson(entity.question!) : null,
      createdAt: entity.createdAt,
    );
  }

  ExamQuestionEntity toEntity() {
    return ExamQuestionEntity(
      id: id,
      examId: examId,
      sectionId: sectionId,
      questionId: questionId,
      sortOrder: sortOrder,
      marks: marks,
      negativeMarks: negativeMarks,
      isCompulsory: isCompulsory,
      question: question != null ? _questionJsonToEntity(question!) : null,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamQuestionModel copyWith({
    String? id,
    String? examId,
    String? sectionId,
    String? questionId,
    int? sortOrder,
    double? marks,
    double? negativeMarks,
    bool? isCompulsory,
    Map<String, dynamic>? question,
    DateTime? createdAt,
  }) {
    return ExamQuestionModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      sectionId: sectionId ?? this.sectionId,
      questionId: questionId ?? this.questionId,
      sortOrder: sortOrder ?? this.sortOrder,
      marks: marks ?? this.marks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      isCompulsory: isCompulsory ?? this.isCompulsory,
      question: question ?? this.question,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamQuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          sectionId == other.sectionId &&
          questionId == other.questionId &&
          sortOrder == other.sortOrder &&
          marks == other.marks &&
          negativeMarks == other.negativeMarks &&
          isCompulsory == other.isCompulsory &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        sectionId,
        questionId,
        sortOrder,
        marks,
        negativeMarks,
        isCompulsory,
        createdAt,
      );

  @override
  String toString() =>
      'ExamQuestionModel(id: $id, questionId: $questionId, marks: $marks)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamStudentModel
// ═══════════════════════════════════════════════════════════════════════

class ExamStudentModel {
  const ExamStudentModel({
    required this.id,
    required this.examId,
    required this.studentId,
    this.allowedAttempts,
    this.extraTimeMinutes = 0,
    this.isExempt = false,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final int? allowedAttempts;
  final int extraTimeMinutes;
  final bool isExempt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamStudentModel.fromJson(Map<String, dynamic> json) {
    return ExamStudentModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      allowedAttempts: json['allowed_attempts'] as int? ??
          json['allowedAttempts'] as int?,
      extraTimeMinutes: json['extra_time_minutes'] as int? ??
          json['extraTimeMinutes'] as int? ??
          0,
      isExempt: json['is_exempt'] as bool? ??
          json['isExempt'] as bool? ??
          false,
      startedAt: _parseDateTimeNullable(
        json['started_at'] ?? json['startedAt'],
      ),
      completedAt: _parseDateTimeNullable(
        json['completed_at'] ?? json['completedAt'],
      ),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'allowed_attempts': allowedAttempts,
      'extra_time_minutes': extraTimeMinutes,
      'is_exempt': isExempt,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamStudentModel.fromEntity(ExamStudentEntity entity) {
    return ExamStudentModel(
      id: entity.id,
      examId: entity.examId,
      studentId: entity.studentId,
      allowedAttempts: entity.allowedAttempts,
      extraTimeMinutes: entity.extraTimeMinutes,
      isExempt: entity.isExempt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
    );
  }

  ExamStudentEntity toEntity() {
    return ExamStudentEntity(
      id: id,
      examId: examId,
      studentId: studentId,
      allowedAttempts: allowedAttempts,
      extraTimeMinutes: extraTimeMinutes,
      isExempt: isExempt,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamStudentModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    int? allowedAttempts,
    int? extraTimeMinutes,
    bool? isExempt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return ExamStudentModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      extraTimeMinutes: extraTimeMinutes ?? this.extraTimeMinutes,
      isExempt: isExempt ?? this.isExempt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamStudentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          studentId == other.studentId &&
          allowedAttempts == other.allowedAttempts &&
          extraTimeMinutes == other.extraTimeMinutes &&
          isExempt == other.isExempt &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        examId,
        studentId,
        allowedAttempts,
        extraTimeMinutes,
        isExempt,
        startedAt,
        completedAt,
        createdAt,
      );

  @override
  String toString() =>
      'ExamStudentModel(id: $id, studentId: $studentId, examId: $examId)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamModel
// ═══════════════════════════════════════════════════════════════════════

class ExamModel {
  const ExamModel({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.subjectId,
    required this.classId,
    required this.academicSessionId,
    required this.examType,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.timeLimitMinutes,
    required this.totalMarks,
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
    this.isTemplate = false,
    this.templateId,
    this.maxStudents,
    this.ipRestriction,
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
    this.metadata,
    this.publishedAt,
    this.sections = const [],
    this.questions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String createdBy;
  final String title;
  final String? description;
  final String subjectId;
  final String classId;
  final String academicSessionId;
  final String examType;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final int timeLimitMinutes;
  final double totalMarks;
  final double passMark;
  final String passMarkType;
  final String? instructions;
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
  final bool isTemplate;
  final String? templateId;
  final int? maxStudents;
  final List<String>? ipRestriction;
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;
  final Map<String, dynamic>? metadata;
  final DateTime? publishedAt;
  final List<ExamSectionModel> sections;
  final List<ExamQuestionModel> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      subjectId:
          json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      classId:
          json['class_id'] as String? ?? json['classId'] as String? ?? '',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      examType: json['exam_type'] as String? ?? json['examType'] as String? ?? 'custom',
      status: json['status'] as String? ?? json['status'] as String? ?? 'draft',
      startTime: _parseDateTime(json['start_time'] ?? json['startTime']),
      endTime: _parseDateTime(json['end_time'] ?? json['endTime']),
      timeLimitMinutes: json['time_limit_minutes'] as int? ??
          json['timeLimitMinutes'] as int? ??
          0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      passMark: (json['pass_mark'] as num?)?.toDouble() ??
          (json['passMark'] as num?)?.toDouble() ??
          0.0,
      passMarkType: json['pass_mark_type'] as String? ??
          json['passMarkType'] as String? ??
          'percentage',
      instructions: json['instructions'] as String?,
      allowedAttempts: json['allowed_attempts'] as int? ??
          json['allowedAttempts'] as int? ??
          1,
      negativeMarkingEnabled: json['negative_marking_enabled'] as bool? ??
          json['negativeMarkingEnabled'] as bool? ??
          false,
      negativeMarkValue:
          (json['negative_mark_value'] as num?)?.toDouble() ??
              (json['negativeMarkValue'] as num?)?.toDouble() ??
              0.0,
      gracePeriodMinutes: json['grace_period_minutes'] as int? ??
          json['gracePeriodMinutes'] as int? ??
          0,
      autoSubmit: json['auto_submit'] as bool? ??
          json['autoSubmit'] as bool? ??
          true,
      randomizeQuestions: json['randomize_questions'] as bool? ??
          json['randomizeQuestions'] as bool? ??
          false,
      randomizeOptions: json['randomize_options'] as bool? ??
          json['randomizeOptions'] as bool? ??
          false,
      showResults: json['show_results'] as String? ??
          json['showResults'] as String? ??
          'after_submission',
      showCorrectAnswers: json['show_correct_answers'] as bool? ??
          json['showCorrectAnswers'] as bool? ??
          false,
      showExplanations: json['show_explanations'] as bool? ??
          json['showExplanations'] as bool? ??
          false,
      isTemplate: json['is_template'] as bool? ??
          json['isTemplate'] as bool? ??
          false,
      templateId:
          json['template_id'] as String? ?? json['templateId'] as String?,
      maxStudents:
          json['max_students'] as int? ?? json['maxStudents'] as int?,
      ipRestriction: _parseIpRestriction(
        json['ip_restriction'] ?? json['ipRestriction'],
      ),
      requireFullScreen: json['require_full_screen'] as bool? ??
          json['requireFullScreen'] as bool? ??
          false,
      allowResume: json['allow_resume'] as bool? ??
          json['allowResume'] as bool? ??
          true,
      browserLockdown: json['browser_lockdown'] as bool? ??
          json['browserLockdown'] as bool? ??
          false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      publishedAt: _parseDateTimeNullable(
        json['published_at'] ?? json['publishedAt'],
      ),
      sections: _parseSections(json['sections'] ?? json['exam_sections']),
      questions: _parseExamQuestions(json['questions'] ?? json['exam_questions']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'class_id': classId,
      'academic_session_id': academicSessionId,
      'exam_type': examType,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'time_limit_minutes': timeLimitMinutes,
      'total_marks': totalMarks,
      'pass_mark': passMark,
      'pass_mark_type': passMarkType,
      'instructions': instructions,
      'allowed_attempts': allowedAttempts,
      'negative_marking_enabled': negativeMarkingEnabled,
      'negative_mark_value': negativeMarkValue,
      'grace_period_minutes': gracePeriodMinutes,
      'auto_submit': autoSubmit,
      'randomize_questions': randomizeQuestions,
      'randomize_options': randomizeOptions,
      'show_results': showResults,
      'show_correct_answers': showCorrectAnswers,
      'show_explanations': showExplanations,
      'is_template': isTemplate,
      'template_id': templateId,
      'max_students': maxStudents,
      'ip_restriction': ipRestriction,
      'require_full_screen': requireFullScreen,
      'allow_resume': allowResume,
      'browser_lockdown': browserLockdown,
      'metadata': metadata,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamModel.fromEntity(ExamEntity entity) {
    return ExamModel(
      id: entity.id,
      schoolId: entity.schoolId,
      createdBy: entity.createdBy,
      title: entity.title,
      description: entity.description,
      subjectId: entity.subjectId,
      classId: entity.classId,
      academicSessionId: entity.academicSessionId,
      examType: entity.examType.value,
      status: entity.status.value,
      startTime: entity.startTime,
      endTime: entity.endTime,
      timeLimitMinutes: entity.timeLimitMinutes,
      totalMarks: entity.totalMarks,
      passMark: entity.passMark,
      passMarkType: entity.passMarkType,
      instructions: entity.instructions,
      allowedAttempts: entity.allowedAttempts,
      negativeMarkingEnabled: entity.negativeMarkingEnabled,
      negativeMarkValue: entity.negativeMarkValue,
      gracePeriodMinutes: entity.gracePeriodMinutes,
      autoSubmit: entity.autoSubmit,
      randomizeQuestions: entity.randomizeQuestions,
      randomizeOptions: entity.randomizeOptions,
      showResults: entity.showResults,
      showCorrectAnswers: entity.showCorrectAnswers,
      showExplanations: entity.showExplanations,
      isTemplate: entity.isTemplate,
      templateId: entity.templateId,
      maxStudents: entity.maxStudents,
      ipRestriction: entity.ipRestriction,
      requireFullScreen: entity.requireFullScreen,
      allowResume: entity.allowResume,
      browserLockdown: entity.browserLockdown,
      metadata: entity.metadata,
      publishedAt: entity.publishedAt,
      sections: entity.sections
          .map((s) => ExamSectionModel.fromEntity(s))
          .toList(),
      questions: entity.questions
          .map((q) => ExamQuestionModel.fromEntity(q))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExamEntity toEntity() {
    return ExamEntity(
      id: id,
      schoolId: schoolId,
      createdBy: createdBy,
      title: title,
      description: description,
      subjectId: subjectId,
      classId: classId,
      academicSessionId: academicSessionId,
      examType: ExamType.fromString(examType) ?? ExamType.custom,
      status: ExamStatus.fromString(status) ?? ExamStatus.draft,
      startTime: startTime,
      endTime: endTime,
      timeLimitMinutes: timeLimitMinutes,
      totalMarks: totalMarks,
      passMark: passMark,
      passMarkType: passMarkType,
      instructions: instructions,
      allowedAttempts: allowedAttempts,
      negativeMarkingEnabled: negativeMarkingEnabled,
      negativeMarkValue: negativeMarkValue,
      gracePeriodMinutes: gracePeriodMinutes,
      autoSubmit: autoSubmit,
      randomizeQuestions: randomizeQuestions,
      randomizeOptions: randomizeOptions,
      showResults: showResults,
      showCorrectAnswers: showCorrectAnswers,
      showExplanations: showExplanations,
      isTemplate: isTemplate,
      templateId: templateId,
      maxStudents: maxStudents,
      ipRestriction: ipRestriction,
      requireFullScreen: requireFullScreen,
      allowResume: allowResume,
      browserLockdown: browserLockdown,
      metadata: metadata,
      publishedAt: publishedAt,
      sections: sections.map((s) => s.toEntity()).toList(),
      questions: questions.map((q) => q.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamModel copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? title,
    String? description,
    String? subjectId,
    String? classId,
    String? academicSessionId,
    String? examType,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    int? timeLimitMinutes,
    double? totalMarks,
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
    bool? isTemplate,
    String? templateId,
    int? maxStudents,
    List<String>? ipRestriction,
    bool? requireFullScreen,
    bool? allowResume,
    bool? browserLockdown,
    Map<String, dynamic>? metadata,
    DateTime? publishedAt,
    List<ExamSectionModel>? sections,
    List<ExamQuestionModel>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
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
      totalMarks: totalMarks ?? this.totalMarks,
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
      isTemplate: isTemplate ?? this.isTemplate,
      templateId: templateId ?? this.templateId,
      maxStudents: maxStudents ?? this.maxStudents,
      ipRestriction: ipRestriction ?? this.ipRestriction,
      requireFullScreen: requireFullScreen ?? this.requireFullScreen,
      allowResume: allowResume ?? this.allowResume,
      browserLockdown: browserLockdown ?? this.browserLockdown,
      metadata: metadata ?? this.metadata,
      publishedAt: publishedAt ?? this.publishedAt,
      sections: sections ?? this.sections,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          createdBy == other.createdBy &&
          title == other.title &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, schoolId, createdBy, title, status);

  @override
  String toString() => 'ExamModel(id: $id, title: $title, status: $status)';
}

// ═══════════════════════════════════════════════════════════════════════
// StudentAnswerModel
// ═══════════════════════════════════════════════════════════════════════

class StudentAnswerModel {
  const StudentAnswerModel({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.examQuestionId,
    required this.answerData,
    this.isCorrect,
    this.marksAwarded = 0.0,
    this.marksDeducted = 0.0,
    this.timeSpentSeconds = 0,
    this.isFlagged = false,
    this.teacherComment,
    this.gradedBy,
    this.gradedAt,
    this.answeredAt,
    this.updatedAt,
  });

  final String id;
  final String attemptId;
  final String questionId;
  final String? examQuestionId;
  final Map<String, dynamic> answerData;
  final bool? isCorrect;
  final double marksAwarded;
  final double marksDeducted;
  final int timeSpentSeconds;
  final bool isFlagged;
  final String? teacherComment;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime? answeredAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory StudentAnswerModel.fromJson(Map<String, dynamic> json) {
    return StudentAnswerModel(
      id: json['id'] as String,
      attemptId:
          json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      questionId:
          json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      examQuestionId: json['exam_question_id'] as String? ??
          json['examQuestionId'] as String?,
      answerData: _parseMap(json['answer_data'] ?? json['answerData']),
      isCorrect: json['is_correct'] as bool? ?? json['isCorrect'] as bool?,
      marksAwarded: (json['marks_awarded'] as num?)?.toDouble() ??
          (json['marksAwarded'] as num?)?.toDouble() ??
          0.0,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble() ??
          (json['marksDeducted'] as num?)?.toDouble() ??
          0.0,
      timeSpentSeconds: json['time_spent_seconds'] as int? ??
          json['timeSpentSeconds'] as int? ??
          0,
      isFlagged: json['is_flagged'] as bool? ??
          json['isFlagged'] as bool? ??
          false,
      teacherComment: json['teacher_comment'] as String? ??
          json['teacherComment'] as String?,
      gradedBy:
          json['graded_by'] as String? ?? json['gradedBy'] as String?,
      gradedAt: _parseDateTimeNullable(
        json['graded_at'] ?? json['gradedAt'],
      ),
      answeredAt: _parseDateTimeNullable(
        json['answered_at'] ?? json['answeredAt'],
      ),
      updatedAt: _parseDateTimeNullable(
        json['updated_at'] ?? json['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'exam_question_id': examQuestionId,
      'answer_data': answerData,
      'is_correct': isCorrect,
      'marks_awarded': marksAwarded,
      'marks_deducted': marksDeducted,
      'time_spent_seconds': timeSpentSeconds,
      'is_flagged': isFlagged,
      'teacher_comment': teacherComment,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory StudentAnswerModel.fromEntity(StudentAnswerEntity entity) {
    return StudentAnswerModel(
      id: entity.id,
      attemptId: entity.attemptId,
      questionId: entity.questionId,
      examQuestionId: entity.examQuestionId,
      answerData: Map<String, dynamic>.from(entity.answerData),
      isCorrect: entity.isCorrect,
      marksAwarded: entity.marksAwarded,
      marksDeducted: entity.marksDeducted,
      timeSpentSeconds: entity.timeSpentSeconds,
      isFlagged: entity.isFlagged,
      teacherComment: entity.teacherComment,
      gradedBy: entity.gradedBy,
      gradedAt: entity.gradedAt,
      answeredAt: entity.answeredAt,
      updatedAt: entity.updatedAt,
    );
  }

  StudentAnswerEntity toEntity() {
    return StudentAnswerEntity(
      id: id,
      attemptId: attemptId,
      questionId: questionId,
      examQuestionId: examQuestionId,
      answerData: answerData,
      isCorrect: isCorrect,
      marksAwarded: marksAwarded,
      marksDeducted: marksDeducted,
      timeSpentSeconds: timeSpentSeconds,
      isFlagged: isFlagged,
      teacherComment: teacherComment,
      gradedBy: gradedBy,
      gradedAt: gradedAt,
      answeredAt: answeredAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  StudentAnswerModel copyWith({
    String? id,
    String? attemptId,
    String? questionId,
    String? examQuestionId,
    Map<String, dynamic>? answerData,
    bool? isCorrect,
    double? marksAwarded,
    double? marksDeducted,
    int? timeSpentSeconds,
    bool? isFlagged,
    String? teacherComment,
    String? gradedBy,
    DateTime? gradedAt,
    DateTime? answeredAt,
    DateTime? updatedAt,
  }) {
    return StudentAnswerModel(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      examQuestionId: examQuestionId ?? this.examQuestionId,
      answerData: answerData ?? this.answerData,
      isCorrect: isCorrect ?? this.isCorrect,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      marksDeducted: marksDeducted ?? this.marksDeducted,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      isFlagged: isFlagged ?? this.isFlagged,
      teacherComment: teacherComment ?? this.teacherComment,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAnswerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attemptId == other.attemptId &&
          questionId == other.questionId &&
          marksAwarded == other.marksAwarded &&
          isFlagged == other.isFlagged;

  @override
  int get hashCode =>
      Object.hash(id, attemptId, questionId, marksAwarded, isFlagged);

  @override
  String toString() =>
      'StudentAnswerModel(id: $id, questionId: $questionId, marks: $marksAwarded)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamAttemptModel
// ═══════════════════════════════════════════════════════════════════════

class ExamAttemptModel {
  const ExamAttemptModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptNumber,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    this.submissionType,
    this.timeSpentSeconds = 0,
    this.totalMarks = 0.0,
    this.scorePercentage = 0.0,
    this.isPassed = false,
    required this.gradingStatus,
    this.gradedBy,
    this.gradedAt,
    this.deviceInfo,
    this.ipAddress,
    this.userAgent,
    this.lastActivityAt,
    this.autoSaveData,
    this.metadata,
    this.answers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final int attemptNumber;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final String? submissionType;
  final int timeSpentSeconds;
  final double totalMarks;
  final double scorePercentage;
  final bool isPassed;
  final String gradingStatus;
  final String? gradedBy;
  final DateTime? gradedAt;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? lastActivityAt;
  final Map<String, dynamic>? autoSaveData;
  final Map<String, dynamic>? metadata;
  final List<StudentAnswerModel> answers;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json) {
    return ExamAttemptModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      attemptNumber: json['attempt_number'] as int? ??
          json['attemptNumber'] as int? ??
          1,
      status: json['status'] as String? ?? 'not_started',
      startedAt: _parseDateTime(json['started_at'] ?? json['startedAt']),
      submittedAt: _parseDateTimeNullable(
        json['submitted_at'] ?? json['submittedAt'],
      ),
      submissionType: json['submission_type'] as String? ??
          json['submissionType'] as String?,
      timeSpentSeconds: json['time_spent_seconds'] as int? ??
          json['timeSpentSeconds'] as int? ??
          0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble() ??
          (json['scorePercentage'] as num?)?.toDouble() ??
          0.0,
      isPassed:
          json['is_passed'] as bool? ?? json['isPassed'] as bool? ?? false,
      gradingStatus: json['grading_status'] as String? ??
          json['gradingStatus'] as String? ??
          'pending',
      gradedBy:
          json['graded_by'] as String? ?? json['gradedBy'] as String?,
      gradedAt: _parseDateTimeNullable(
        json['graded_at'] ?? json['gradedAt'],
      ),
      deviceInfo: json['device_info'] as Map<String, dynamic>? ??
          json['deviceInfo'] as Map<String, dynamic>?,
      ipAddress:
          json['ip_address'] as String? ?? json['ipAddress'] as String?,
      userAgent:
          json['user_agent'] as String? ?? json['userAgent'] as String?,
      lastActivityAt: _parseDateTimeNullable(
        json['last_activity_at'] ?? json['lastActivityAt'],
      ),
      autoSaveData: json['auto_save_data'] as Map<String, dynamic>? ??
          json['autoSaveData'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      answers: _parseAnswers(json['answers'] ?? json['student_answers']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'attempt_number': attemptNumber,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'submission_type': submissionType,
      'time_spent_seconds': timeSpentSeconds,
      'total_marks': totalMarks,
      'score_percentage': scorePercentage,
      'is_passed': isPassed,
      'grading_status': gradingStatus,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'auto_save_data': autoSaveData,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamAttemptModel.fromEntity(ExamAttemptEntity entity) {
    return ExamAttemptModel(
      id: entity.id,
      examId: entity.examId,
      studentId: entity.studentId,
      attemptNumber: entity.attemptNumber,
      status: entity.status.value,
      startedAt: entity.startedAt,
      submittedAt: entity.submittedAt,
      submissionType: entity.submissionType?.value,
      timeSpentSeconds: entity.timeSpentSeconds,
      totalMarks: entity.totalMarks,
      scorePercentage: entity.scorePercentage,
      isPassed: entity.isPassed,
      gradingStatus: entity.gradingStatus.value,
      gradedBy: entity.gradedBy,
      gradedAt: entity.gradedAt,
      deviceInfo: entity.deviceInfo != null
          ? Map<String, dynamic>.from(entity.deviceInfo!)
          : null,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      lastActivityAt: entity.lastActivityAt,
      autoSaveData: entity.autoSaveData != null
          ? Map<String, dynamic>.from(entity.autoSaveData!)
          : null,
      metadata: entity.metadata != null
          ? Map<String, dynamic>.from(entity.metadata!)
          : null,
      answers: entity.answers
          .map((a) => StudentAnswerModel.fromEntity(a))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExamAttemptEntity toEntity() {
    return ExamAttemptEntity(
      id: id,
      examId: examId,
      studentId: studentId,
      attemptNumber: attemptNumber,
      status: AttemptStatus.fromString(status) ?? AttemptStatus.notStarted,
      startedAt: startedAt,
      submittedAt: submittedAt,
      submissionType: SubmissionType.fromString(submissionType),
      timeSpentSeconds: timeSpentSeconds,
      totalMarks: totalMarks,
      scorePercentage: scorePercentage,
      isPassed: isPassed,
      gradingStatus:
          GradingStatus.fromString(gradingStatus) ?? GradingStatus.pending,
      gradedBy: gradedBy,
      gradedAt: gradedAt,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      userAgent: userAgent,
      lastActivityAt: lastActivityAt,
      autoSaveData: autoSaveData,
      metadata: metadata,
      answers: answers.map((a) => a.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamAttemptModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    int? attemptNumber,
    String? status,
    DateTime? startedAt,
    DateTime? submittedAt,
    String? submissionType,
    int? timeSpentSeconds,
    double? totalMarks,
    double? scorePercentage,
    bool? isPassed,
    String? gradingStatus,
    String? gradedBy,
    DateTime? gradedAt,
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? userAgent,
    DateTime? lastActivityAt,
    Map<String, dynamic>? autoSaveData,
    Map<String, dynamic>? metadata,
    List<StudentAnswerModel>? answers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamAttemptModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionType: submissionType ?? this.submissionType,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      totalMarks: totalMarks ?? this.totalMarks,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      isPassed: isPassed ?? this.isPassed,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      autoSaveData: autoSaveData ?? this.autoSaveData,
      metadata: metadata ?? this.metadata,
      answers: answers ?? this.answers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAttemptModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          studentId == other.studentId &&
          attemptNumber == other.attemptNumber &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(id, examId, studentId, attemptNumber, status);

  @override
  String toString() =>
      'ExamAttemptModel(id: $id, examId: $examId, status: $status)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamSessionModel (REALTIME model)
// ═══════════════════════════════════════════════════════════════════════

class ExamSessionModel {
  const ExamSessionModel({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    this.isActive = true,
    this.currentQuestionIndex = 0,
    this.questionsAnswered = 0,
    this.questionsFlagged = 0,
    required this.lastHeartbeat,
    this.connectionStatus = 'connected',
    this.ipAddress,
    this.deviceFingerprint,
    this.tabSwitchCount = 0,
    this.focusLostCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final bool isActive;
  final int currentQuestionIndex;
  final int questionsAnswered;
  final int questionsFlagged;
  final DateTime lastHeartbeat;
  final String connectionStatus;
  final String? ipAddress;
  final String? deviceFingerprint;
  final int tabSwitchCount;
  final int focusLostCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamSessionModel.fromJson(Map<String, dynamic> json) {
    return ExamSessionModel(
      id: json['id'] as String,
      attemptId:
          json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      currentQuestionIndex: json['current_question_index'] as int? ??
          json['currentQuestionIndex'] as int? ??
          0,
      questionsAnswered: json['questions_answered'] as int? ??
          json['questionsAnswered'] as int? ??
          0,
      questionsFlagged: json['questions_flagged'] as int? ??
          json['questionsFlagged'] as int? ??
          0,
      lastHeartbeat: _parseDateTime(
        json['last_heartbeat'] ?? json['lastHeartbeat'],
      ),
      connectionStatus: json['connection_status'] as String? ??
          json['connectionStatus'] as String? ??
          'connected',
      ipAddress:
          json['ip_address'] as String? ?? json['ipAddress'] as String?,
      deviceFingerprint: json['device_fingerprint'] as String? ??
          json['deviceFingerprint'] as String?,
      tabSwitchCount: json['tab_switch_count'] as int? ??
          json['tabSwitchCount'] as int? ??
          0,
      focusLostCount: json['focus_lost_count'] as int? ??
          json['focusLostCount'] as int? ??
          0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'exam_id': examId,
      'student_id': studentId,
      'is_active': isActive,
      'current_question_index': currentQuestionIndex,
      'questions_answered': questionsAnswered,
      'questions_flagged': questionsFlagged,
      'last_heartbeat': lastHeartbeat.toIso8601String(),
      'connection_status': connectionStatus,
      'ip_address': ipAddress,
      'device_fingerprint': deviceFingerprint,
      'tab_switch_count': tabSwitchCount,
      'focus_lost_count': focusLostCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamSessionModel.fromEntity(ExamSessionEntity entity) {
    return ExamSessionModel(
      id: entity.id,
      attemptId: entity.attemptId,
      examId: entity.examId,
      studentId: entity.studentId,
      isActive: entity.isActive,
      currentQuestionIndex: entity.currentQuestionIndex,
      questionsAnswered: entity.questionsAnswered,
      questionsFlagged: entity.questionsFlagged,
      lastHeartbeat: entity.lastHeartbeat,
      connectionStatus: entity.connectionStatus,
      ipAddress: entity.ipAddress,
      deviceFingerprint: entity.deviceFingerprint,
      tabSwitchCount: entity.tabSwitchCount,
      focusLostCount: entity.focusLostCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExamSessionEntity toEntity() {
    return ExamSessionEntity(
      id: id,
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      isActive: isActive,
      currentQuestionIndex: currentQuestionIndex,
      questionsAnswered: questionsAnswered,
      questionsFlagged: questionsFlagged,
      lastHeartbeat: lastHeartbeat,
      connectionStatus: connectionStatus,
      ipAddress: ipAddress,
      deviceFingerprint: deviceFingerprint,
      tabSwitchCount: tabSwitchCount,
      focusLostCount: focusLostCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamSessionModel copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    bool? isActive,
    int? currentQuestionIndex,
    int? questionsAnswered,
    int? questionsFlagged,
    DateTime? lastHeartbeat,
    String? connectionStatus,
    String? ipAddress,
    String? deviceFingerprint,
    int? tabSwitchCount,
    int? focusLostCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamSessionModel(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      isActive: isActive ?? this.isActive,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      questionsFlagged: questionsFlagged ?? this.questionsFlagged,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      tabSwitchCount: tabSwitchCount ?? this.tabSwitchCount,
      focusLostCount: focusLostCount ?? this.focusLostCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attemptId == other.attemptId &&
          examId == other.examId &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, attemptId, examId, isActive);

  @override
  String toString() =>
      'ExamSessionModel(id: $id, examId: $examId, active: $isActive)';
}

// ═══════════════════════════════════════════════════════════════════════
// MonitoringLogModel
// ═══════════════════════════════════════════════════════════════════════

class MonitoringLogModel {
  const MonitoringLogModel({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.eventType,
    this.eventData,
    required this.severity,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final String eventType;
  final Map<String, dynamic>? eventData;
  final String severity;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory MonitoringLogModel.fromJson(Map<String, dynamic> json) {
    return MonitoringLogModel(
      id: json['id'] as String,
      attemptId:
          json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      eventType: json['event_type'] as String? ??
          json['eventType'] as String? ??
          'suspicious_activity',
      eventData: json['event_data'] as Map<String, dynamic>? ??
          json['eventData'] as Map<String, dynamic>?,
      severity: json['severity'] as String? ?? 'info',
      isResolved: json['is_resolved'] as bool? ??
          json['isResolved'] as bool? ??
          false,
      resolvedBy:
          json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolvedAt: _parseDateTimeNullable(
        json['resolved_at'] ?? json['resolvedAt'],
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'exam_id': examId,
      'student_id': studentId,
      'event_type': eventType,
      'event_data': eventData,
      'severity': severity,
      'is_resolved': isResolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory MonitoringLogModel.fromEntity(MonitoringLogEntity entity) {
    return MonitoringLogModel(
      id: entity.id,
      attemptId: entity.attemptId,
      examId: entity.examId,
      studentId: entity.studentId,
      eventType: entity.eventType.value,
      eventData: entity.eventData != null
          ? Map<String, dynamic>.from(entity.eventData!)
          : null,
      severity: entity.severity,
      isResolved: entity.isResolved,
      resolvedBy: entity.resolvedBy,
      resolvedAt: entity.resolvedAt,
      createdAt: entity.createdAt,
    );
  }

  MonitoringLogEntity toEntity() {
    return MonitoringLogEntity(
      id: id,
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      eventType: MonitoringEventType.fromString(eventType) ??
          MonitoringEventType.suspiciousActivity,
      eventData: eventData,
      severity: severity,
      isResolved: isResolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  MonitoringLogModel copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    String? eventType,
    Map<String, dynamic>? eventData,
    String? severity,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return MonitoringLogModel(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      eventType: eventType ?? this.eventType,
      eventData: eventData ?? this.eventData,
      severity: severity ?? this.severity,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitoringLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventType == other.eventType &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(id, eventType, severity);

  @override
  String toString() =>
      'MonitoringLogModel(id: $id, eventType: $eventType, severity: $severity)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamResultModel
// ═══════════════════════════════════════════════════════════════════════

class ExamResultModel {
  const ExamResultModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptId,
    required this.totalMarks,
    required this.totalPossible,
    required this.scorePercentage,
    this.grade,
    required this.isPassed,
    this.rank,
    this.subjectAverage,
    required this.timeSpentSeconds,
    required this.gradingStatus,
    this.releasedAt,
    this.isReleased = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final String attemptId;
  final double totalMarks;
  final double totalPossible;
  final double scorePercentage;
  final String? grade;
  final bool isPassed;
  final int? rank;
  final double? subjectAverage;
  final int timeSpentSeconds;
  final String gradingStatus;
  final DateTime? releasedAt;
  final bool isReleased;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    return ExamResultModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      attemptId:
          json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      totalPossible: (json['total_possible'] as num?)?.toDouble() ??
          (json['totalPossible'] as num?)?.toDouble() ??
          0.0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble() ??
          (json['scorePercentage'] as num?)?.toDouble() ??
          0.0,
      grade: json['grade'] as String?,
      isPassed:
          json['is_passed'] as bool? ?? json['isPassed'] as bool? ?? false,
      rank: json['rank'] as int?,
      subjectAverage: (json['subject_average'] as num?)?.toDouble() ??
          (json['subjectAverage'] as num?)?.toDouble(),
      timeSpentSeconds: json['time_spent_seconds'] as int? ??
          json['timeSpentSeconds'] as int? ??
          0,
      gradingStatus: json['grading_status'] as String? ??
          json['gradingStatus'] as String? ??
          'pending',
      releasedAt: _parseDateTimeNullable(
        json['released_at'] ?? json['releasedAt'],
      ),
      isReleased: json['is_released'] as bool? ??
          json['isReleased'] as bool? ??
          false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'attempt_id': attemptId,
      'total_marks': totalMarks,
      'total_possible': totalPossible,
      'score_percentage': scorePercentage,
      'grade': grade,
      'is_passed': isPassed,
      'rank': rank,
      'subject_average': subjectAverage,
      'time_spent_seconds': timeSpentSeconds,
      'grading_status': gradingStatus,
      'released_at': releasedAt?.toIso8601String(),
      'is_released': isReleased,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamResultModel.fromEntity(ExamResultEntity entity) {
    return ExamResultModel(
      id: entity.id,
      examId: entity.examId,
      studentId: entity.studentId,
      attemptId: entity.attemptId,
      totalMarks: entity.totalMarks,
      totalPossible: entity.totalPossible,
      scorePercentage: entity.scorePercentage,
      grade: entity.grade,
      isPassed: entity.isPassed,
      rank: entity.rank,
      subjectAverage: entity.subjectAverage,
      timeSpentSeconds: entity.timeSpentSeconds,
      gradingStatus: entity.gradingStatus.value,
      releasedAt: entity.releasedAt,
      isReleased: entity.isReleased,
      metadata: entity.metadata != null
          ? Map<String, dynamic>.from(entity.metadata!)
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExamResultEntity toEntity() {
    return ExamResultEntity(
      id: id,
      examId: examId,
      studentId: studentId,
      attemptId: attemptId,
      totalMarks: totalMarks,
      totalPossible: totalPossible,
      scorePercentage: scorePercentage,
      grade: grade,
      isPassed: isPassed,
      rank: rank,
      subjectAverage: subjectAverage,
      timeSpentSeconds: timeSpentSeconds,
      gradingStatus:
          GradingStatus.fromString(gradingStatus) ?? GradingStatus.pending,
      releasedAt: releasedAt,
      isReleased: isReleased,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamResultModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? attemptId,
    double? totalMarks,
    double? totalPossible,
    double? scorePercentage,
    String? grade,
    bool? isPassed,
    int? rank,
    double? subjectAverage,
    int? timeSpentSeconds,
    String? gradingStatus,
    DateTime? releasedAt,
    bool? isReleased,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamResultModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptId: attemptId ?? this.attemptId,
      totalMarks: totalMarks ?? this.totalMarks,
      totalPossible: totalPossible ?? this.totalPossible,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      grade: grade ?? this.grade,
      isPassed: isPassed ?? this.isPassed,
      rank: rank ?? this.rank,
      subjectAverage: subjectAverage ?? this.subjectAverage,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      releasedAt: releasedAt ?? this.releasedAt,
      isReleased: isReleased ?? this.isReleased,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          examId == other.examId &&
          studentId == other.studentId &&
          totalMarks == other.totalMarks &&
          scorePercentage == other.scorePercentage;

  @override
  int get hashCode =>
      Object.hash(id, examId, studentId, totalMarks, scorePercentage);

  @override
  String toString() =>
      'ExamResultModel(id: $id, score: $scorePercentage%, passed: $isPassed)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamRankingModel
// ═══════════════════════════════════════════════════════════════════════

class ExamRankingModel {
  const ExamRankingModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptId,
    required this.rank,
    required this.totalMarks,
    required this.scorePercentage,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final String attemptId;
  final int rank;
  final double totalMarks;
  final double scorePercentage;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamRankingModel.fromJson(Map<String, dynamic> json) {
    return ExamRankingModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      attemptId:
          json['attempt_id'] as String? ?? json['attemptId'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble() ??
          (json['scorePercentage'] as num?)?.toDouble() ??
          0.0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'attempt_id': attemptId,
      'rank': rank,
      'total_marks': totalMarks,
      'score_percentage': scorePercentage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamRankingModel.fromEntity(ExamRankingEntity entity) {
    return ExamRankingModel(
      id: entity.id,
      examId: entity.examId,
      studentId: entity.studentId,
      attemptId: entity.attemptId,
      rank: entity.rank,
      totalMarks: entity.totalMarks,
      scorePercentage: entity.scorePercentage,
      createdAt: entity.createdAt,
    );
  }

  ExamRankingEntity toEntity() {
    return ExamRankingEntity(
      id: id,
      examId: examId,
      studentId: studentId,
      attemptId: attemptId,
      rank: rank,
      totalMarks: totalMarks,
      scorePercentage: scorePercentage,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamRankingModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? attemptId,
    int? rank,
    double? totalMarks,
    double? scorePercentage,
    DateTime? createdAt,
  }) {
    return ExamRankingModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptId: attemptId ?? this.attemptId,
      rank: rank ?? this.rank,
      totalMarks: totalMarks ?? this.totalMarks,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamRankingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rank == other.rank;

  @override
  int get hashCode => Object.hash(id, rank);

  @override
  String toString() =>
      'ExamRankingModel(id: $id, rank: $rank, score: $scorePercentage%)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamNotificationModel
// ═══════════════════════════════════════════════════════════════════════

class ExamNotificationModel {
  const ExamNotificationModel({
    required this.id,
    this.examId,
    this.studentId,
    required this.category,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    this.readAt,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String? examId;
  final String? studentId;
  final String category;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamNotificationModel.fromJson(Map<String, dynamic> json) {
    return ExamNotificationModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String? ?? json['examId'] as String?,
      studentId:
          json['student_id'] as String? ?? json['studentId'] as String?,
      category: json['category'] as String? ?? 'exam_available',
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead:
          json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      readAt: _parseDateTimeNullable(
        json['read_at'] ?? json['readAt'],
      ),
      scheduledFor: _parseDateTimeNullable(
        json['scheduled_for'] ?? json['scheduledFor'],
      ),
      sentAt: _parseDateTimeNullable(
        json['sent_at'] ?? json['sentAt'],
      ),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'category': category,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamNotificationModel.fromEntity(ExamNotificationEntity entity) {
    return ExamNotificationModel(
      id: entity.id,
      examId: entity.examId,
      studentId: entity.studentId,
      category: entity.category.value,
      title: entity.title,
      message: entity.message,
      data: entity.data != null
          ? Map<String, dynamic>.from(entity.data!)
          : null,
      isRead: entity.isRead,
      readAt: entity.readAt,
      scheduledFor: entity.scheduledFor,
      sentAt: entity.sentAt,
      createdAt: entity.createdAt,
    );
  }

  ExamNotificationEntity toEntity() {
    return ExamNotificationEntity(
      id: id,
      examId: examId,
      studentId: studentId,
      category: NotificationCategory.fromString(category) ??
          NotificationCategory.examAvailable,
      title: title,
      message: message,
      data: data,
      isRead: isRead,
      readAt: readAt,
      scheduledFor: scheduledFor,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamNotificationModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? category,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return ExamNotificationModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamNotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, title);

  @override
  String toString() =>
      'ExamNotificationModel(id: $id, title: $title, category: $category)';
}

// ═══════════════════════════════════════════════════════════════════════
// GradeScaleEntryModel
// ═══════════════════════════════════════════════════════════════════════

class GradeScaleEntryModel {
  const GradeScaleEntryModel({
    required this.minPercentage,
    required this.maxPercentage,
    required this.grade,
    this.description,
    required this.isPassing,
  });

  final double minPercentage;
  final double maxPercentage;
  final String grade;
  final String? description;
  final bool isPassing;

  factory GradeScaleEntryModel.fromJson(Map<String, dynamic> json) {
    return GradeScaleEntryModel(
      minPercentage: (json['min_percentage'] as num?)?.toDouble() ??
          (json['minPercentage'] as num?)?.toDouble() ??
          0.0,
      maxPercentage: (json['max_percentage'] as num?)?.toDouble() ??
          (json['maxPercentage'] as num?)?.toDouble() ??
          100.0,
      grade: json['grade'] as String,
      description: json['description'] as String?,
      isPassing: json['is_passing'] as bool? ??
          json['isPassing'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_percentage': minPercentage,
      'max_percentage': maxPercentage,
      'grade': grade,
      'description': description,
      'is_passing': isPassing,
    };
  }

  factory GradeScaleEntryModel.fromEntity(GradeScaleEntry entity) {
    return GradeScaleEntryModel(
      minPercentage: entity.minPercentage,
      maxPercentage: entity.maxPercentage,
      grade: entity.grade,
      description: entity.description,
      isPassing: entity.isPassing,
    );
  }

  GradeScaleEntry toEntity() {
    return GradeScaleEntry(
      minPercentage: minPercentage,
      maxPercentage: maxPercentage,
      grade: grade,
      description: description,
      isPassing: isPassing,
    );
  }

  GradeScaleEntryModel copyWith({
    double? minPercentage,
    double? maxPercentage,
    String? grade,
    String? description,
    bool? isPassing,
  }) {
    return GradeScaleEntryModel(
      minPercentage: minPercentage ?? this.minPercentage,
      maxPercentage: maxPercentage ?? this.maxPercentage,
      grade: grade ?? this.grade,
      description: description ?? this.description,
      isPassing: isPassing ?? this.isPassing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeScaleEntryModel &&
          runtimeType == other.runtimeType &&
          grade == other.grade &&
          minPercentage == other.minPercentage &&
          maxPercentage == other.maxPercentage;

  @override
  int get hashCode => Object.hash(grade, minPercentage, maxPercentage);

  @override
  String toString() =>
      'GradeScaleEntryModel(grade: $grade, $minPercentage-$maxPercentage%)';
}

// ═══════════════════════════════════════════════════════════════════════
// GradeScaleModel
// ═══════════════════════════════════════════════════════════════════════

class GradeScaleModel {
  const GradeScaleModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.isDefault = false,
    this.scaleEntries = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final bool isDefault;
  final List<GradeScaleEntryModel> scaleEntries;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory GradeScaleModel.fromJson(Map<String, dynamic> json) {
    return GradeScaleModel(
      id: json['id'] as String,
      schoolId:
          json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ??
          json['isDefault'] as bool? ??
          false,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      scaleEntries: _parseScaleEntries(
        json['scale_entries'] ?? json['scaleEntries'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'is_default': isDefault,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'scale_entries': scaleEntries.map((e) => e.toJson()).toList(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory GradeScaleModel.fromEntity(GradeScaleEntity entity) {
    return GradeScaleModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      isDefault: entity.isDefault,
      scaleEntries: entity.scaleEntries
          .map((e) => GradeScaleEntryModel.fromEntity(e))
          .toList(),
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GradeScaleEntity toEntity() {
    return GradeScaleEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      isDefault: isDefault,
      scaleEntries: scaleEntries.map((e) => e.toEntity()).toList(),
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  GradeScaleModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    bool? isDefault,
    List<GradeScaleEntryModel>? scaleEntries,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeScaleModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      scaleEntries: scaleEntries ?? this.scaleEntries,
      createdBy: createdBy ?? this.createdBy,
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
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'GradeScaleModel(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamStatisticsModel
// ═══════════════════════════════════════════════════════════════════════

class ExamStatisticsModel {
  const ExamStatisticsModel({
    required this.examId,
    required this.totalStudents,
    required this.startedStudents,
    required this.completedStudents,
    required this.submittedStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.medianScore,
    required this.passRate,
    required this.questionsByCorrectRate,
    required this.averageTimeSpentSeconds,
    required this.gradingCompletionPercentage,
  });

  final String examId;
  final int totalStudents;
  final int startedStudents;
  final int completedStudents;
  final int submittedStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double medianScore;
  final double passRate;
  final Map<String, double> questionsByCorrectRate;
  final int averageTimeSpentSeconds;
  final double gradingCompletionPercentage;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ExamStatisticsModel(
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      totalStudents: json['total_students'] as int? ??
          json['totalStudents'] as int? ??
          0,
      startedStudents: json['started_students'] as int? ??
          json['startedStudents'] as int? ??
          0,
      completedStudents: json['completed_students'] as int? ??
          json['completedStudents'] as int? ??
          0,
      submittedStudents: json['submitted_students'] as int? ??
          json['submittedStudents'] as int? ??
          0,
      averageScore: (json['average_score'] as num?)?.toDouble() ??
          (json['averageScore'] as num?)?.toDouble() ??
          0.0,
      highestScore: (json['highest_score'] as num?)?.toDouble() ??
          (json['highestScore'] as num?)?.toDouble() ??
          0.0,
      lowestScore: (json['lowest_score'] as num?)?.toDouble() ??
          (json['lowestScore'] as num?)?.toDouble() ??
          0.0,
      medianScore: (json['median_score'] as num?)?.toDouble() ??
          (json['medianScore'] as num?)?.toDouble() ??
          0.0,
      passRate: (json['pass_rate'] as num?)?.toDouble() ??
          (json['passRate'] as num?)?.toDouble() ??
          0.0,
      questionsByCorrectRate: _parseCorrectRateMap(
        json['questions_by_correct_rate'] ??
            json['questionsByCorrectRate'],
      ),
      averageTimeSpentSeconds: json['average_time_spent_seconds'] as int? ??
          json['averageTimeSpentSeconds'] as int? ??
          0,
      gradingCompletionPercentage:
          (json['grading_completion_percentage'] as num?)?.toDouble() ??
              (json['gradingCompletionPercentage'] as num?)?.toDouble() ??
              0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'total_students': totalStudents,
      'started_students': startedStudents,
      'completed_students': completedStudents,
      'submitted_students': submittedStudents,
      'average_score': averageScore,
      'highest_score': highestScore,
      'lowest_score': lowestScore,
      'median_score': medianScore,
      'pass_rate': passRate,
      'questions_by_correct_rate': questionsByCorrectRate,
      'average_time_spent_seconds': averageTimeSpentSeconds,
      'grading_completion_percentage': gradingCompletionPercentage,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamStatisticsModel.fromEntity(ExamStatistics entity) {
    return ExamStatisticsModel(
      examId: entity.examId,
      totalStudents: entity.totalStudents,
      startedStudents: entity.startedStudents,
      completedStudents: entity.completedStudents,
      submittedStudents: entity.submittedStudents,
      averageScore: entity.averageScore,
      highestScore: entity.highestScore,
      lowestScore: entity.lowestScore,
      medianScore: entity.medianScore,
      passRate: entity.passRate,
      questionsByCorrectRate: Map<String, double>.from(
        entity.questionsByCorrectRate,
      ),
      averageTimeSpentSeconds: entity.averageTimeSpentSeconds,
      gradingCompletionPercentage: entity.gradingCompletionPercentage,
    );
  }

  ExamStatistics toEntity() {
    return ExamStatistics(
      examId: examId,
      totalStudents: totalStudents,
      startedStudents: startedStudents,
      completedStudents: completedStudents,
      submittedStudents: submittedStudents,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      medianScore: medianScore,
      passRate: passRate,
      questionsByCorrectRate: questionsByCorrectRate,
      averageTimeSpentSeconds: averageTimeSpentSeconds,
      gradingCompletionPercentage: gradingCompletionPercentage,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamStatisticsModel copyWith({
    String? examId,
    int? totalStudents,
    int? startedStudents,
    int? completedStudents,
    int? submittedStudents,
    double? averageScore,
    double? highestScore,
    double? lowestScore,
    double? medianScore,
    double? passRate,
    Map<String, double>? questionsByCorrectRate,
    int? averageTimeSpentSeconds,
    double? gradingCompletionPercentage,
  }) {
    return ExamStatisticsModel(
      examId: examId ?? this.examId,
      totalStudents: totalStudents ?? this.totalStudents,
      startedStudents: startedStudents ?? this.startedStudents,
      completedStudents: completedStudents ?? this.completedStudents,
      submittedStudents: submittedStudents ?? this.submittedStudents,
      averageScore: averageScore ?? this.averageScore,
      highestScore: highestScore ?? this.highestScore,
      lowestScore: lowestScore ?? this.lowestScore,
      medianScore: medianScore ?? this.medianScore,
      passRate: passRate ?? this.passRate,
      questionsByCorrectRate:
          questionsByCorrectRate ?? this.questionsByCorrectRate,
      averageTimeSpentSeconds:
          averageTimeSpentSeconds ?? this.averageTimeSpentSeconds,
      gradingCompletionPercentage:
          gradingCompletionPercentage ?? this.gradingCompletionPercentage,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamStatisticsModel &&
          runtimeType == other.runtimeType &&
          examId == other.examId &&
          averageScore == other.averageScore &&
          passRate == other.passRate;

  @override
  int get hashCode => Object.hash(examId, averageScore, passRate);

  @override
  String toString() =>
      'ExamStatisticsModel(examId: $examId, avg: $averageScore, passRate: $passRate)';
}

// ═══════════════════════════════════════════════════════════════════════
// LiveExamStatsModel
// ═══════════════════════════════════════════════════════════════════════

class LiveExamStatsModel {
  const LiveExamStatsModel({
    required this.examId,
    required this.totalEligible,
    required this.activeNow,
    required this.completed,
    required this.notStarted,
    required this.averageProgress,
    this.recentSubmissions = const [],
    this.activeSessions = const [],
    this.recentMonitoringEvents = const [],
  });

  final String examId;
  final int totalEligible;
  final int activeNow;
  final int completed;
  final int notStarted;
  final double averageProgress;
  final List<ExamAttemptModel> recentSubmissions;
  final List<ExamSessionModel> activeSessions;
  final List<MonitoringLogModel> recentMonitoringEvents;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory LiveExamStatsModel.fromJson(Map<String, dynamic> json) {
    return LiveExamStatsModel(
      examId: json['exam_id'] as String? ?? json['examId'] as String? ?? '',
      totalEligible: json['total_eligible'] as int? ??
          json['totalEligible'] as int? ??
          0,
      activeNow: json['active_now'] as int? ??
          json['activeNow'] as int? ??
          0,
      completed:
          json['completed'] as int? ?? 0,
      notStarted: json['not_started'] as int? ??
          json['notStarted'] as int? ??
          0,
      averageProgress: (json['average_progress'] as num?)?.toDouble() ??
          (json['averageProgress'] as num?)?.toDouble() ??
          0.0,
      recentSubmissions: _parseAttemptList(
        json['recent_submissions'] ?? json['recentSubmissions'],
      ),
      activeSessions: _parseSessionList(
        json['active_sessions'] ?? json['activeSessions'],
      ),
      recentMonitoringEvents: _parseMonitoringList(
        json['recent_monitoring_events'] ??
            json['recentMonitoringEvents'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'total_eligible': totalEligible,
      'active_now': activeNow,
      'completed': completed,
      'not_started': notStarted,
      'average_progress': averageProgress,
      'recent_submissions':
          recentSubmissions.map((a) => a.toJson()).toList(),
      'active_sessions': activeSessions.map((s) => s.toJson()).toList(),
      'recent_monitoring_events':
          recentMonitoringEvents.map((e) => e.toJson()).toList(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory LiveExamStatsModel.fromEntity(LiveExamStats entity) {
    return LiveExamStatsModel(
      examId: entity.examId,
      totalEligible: entity.totalEligible,
      activeNow: entity.activeNow,
      completed: entity.completed,
      notStarted: entity.notStarted,
      averageProgress: entity.averageProgress,
      recentSubmissions: entity.recentSubmissions
          .map((a) => ExamAttemptModel.fromEntity(a))
          .toList(),
      activeSessions: entity.activeSessions
          .map((s) => ExamSessionModel.fromEntity(s))
          .toList(),
      recentMonitoringEvents: entity.recentMonitoringEvents
          .map((e) => MonitoringLogModel.fromEntity(e))
          .toList(),
    );
  }

  LiveExamStats toEntity() {
    return LiveExamStats(
      examId: examId,
      totalEligible: totalEligible,
      activeNow: activeNow,
      completed: completed,
      notStarted: notStarted,
      averageProgress: averageProgress,
      recentSubmissions:
          recentSubmissions.map((a) => a.toEntity()).toList(),
      activeSessions: activeSessions.map((s) => s.toEntity()).toList(),
      recentMonitoringEvents:
          recentMonitoringEvents.map((e) => e.toEntity()).toList(),
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  LiveExamStatsModel copyWith({
    String? examId,
    int? totalEligible,
    int? activeNow,
    int? completed,
    int? notStarted,
    double? averageProgress,
    List<ExamAttemptModel>? recentSubmissions,
    List<ExamSessionModel>? activeSessions,
    List<MonitoringLogModel>? recentMonitoringEvents,
  }) {
    return LiveExamStatsModel(
      examId: examId ?? this.examId,
      totalEligible: totalEligible ?? this.totalEligible,
      activeNow: activeNow ?? this.activeNow,
      completed: completed ?? this.completed,
      notStarted: notStarted ?? this.notStarted,
      averageProgress: averageProgress ?? this.averageProgress,
      recentSubmissions: recentSubmissions ?? this.recentSubmissions,
      activeSessions: activeSessions ?? this.activeSessions,
      recentMonitoringEvents:
          recentMonitoringEvents ?? this.recentMonitoringEvents,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveExamStatsModel &&
          runtimeType == other.runtimeType &&
          examId == other.examId &&
          activeNow == other.activeNow;

  @override
  int get hashCode => Object.hash(examId, activeNow);

  @override
  String toString() =>
      'LiveExamStatsModel(examId: $examId, active: $activeNow, completed: $completed)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamCreateInputModel
// ═══════════════════════════════════════════════════════════════════════

class ExamCreateInputModel {
  const ExamCreateInputModel({
    required this.title,
    this.description,
    required this.subjectId,
    required this.classId,
    required this.academicSessionId,
    required this.examType,
    required this.startTime,
    required this.endTime,
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
    this.maxStudents,
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
  });

  final String title;
  final String? description;
  final String subjectId;
  final String classId;
  final String academicSessionId;
  final String examType;
  final DateTime startTime;
  final DateTime endTime;
  final int timeLimitMinutes;
  final double passMark;
  final String passMarkType;
  final String? instructions;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamCreateInputModel.fromJson(Map<String, dynamic> json) {
    return ExamCreateInputModel(
      title: json['title'] as String,
      description: json['description'] as String?,
      subjectId:
          json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      classId:
          json['class_id'] as String? ?? json['classId'] as String? ?? '',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String? ??
          '',
      examType: json['exam_type'] as String? ?? json['examType'] as String? ?? 'custom',
      startTime: _parseDateTime(json['start_time'] ?? json['startTime']),
      endTime: _parseDateTime(json['end_time'] ?? json['endTime']),
      timeLimitMinutes: json['time_limit_minutes'] as int? ??
          json['timeLimitMinutes'] as int? ??
          0,
      passMark: (json['pass_mark'] as num?)?.toDouble() ??
          (json['passMark'] as num?)?.toDouble() ??
          0.0,
      passMarkType: json['pass_mark_type'] as String? ??
          json['passMarkType'] as String? ??
          'percentage',
      instructions: json['instructions'] as String?,
      allowedAttempts: json['allowed_attempts'] as int? ??
          json['allowedAttempts'] as int? ??
          1,
      negativeMarkingEnabled: json['negative_marking_enabled'] as bool? ??
          json['negativeMarkingEnabled'] as bool? ??
          false,
      negativeMarkValue:
          (json['negative_mark_value'] as num?)?.toDouble() ??
              (json['negativeMarkValue'] as num?)?.toDouble() ??
              0.0,
      gracePeriodMinutes: json['grace_period_minutes'] as int? ??
          json['gracePeriodMinutes'] as int? ??
          0,
      autoSubmit: json['auto_submit'] as bool? ??
          json['autoSubmit'] as bool? ??
          true,
      randomizeQuestions: json['randomize_questions'] as bool? ??
          json['randomizeQuestions'] as bool? ??
          false,
      randomizeOptions: json['randomize_options'] as bool? ??
          json['randomizeOptions'] as bool? ??
          false,
      showResults: json['show_results'] as String? ??
          json['showResults'] as String? ??
          'after_submission',
      showCorrectAnswers: json['show_correct_answers'] as bool? ??
          json['showCorrectAnswers'] as bool? ??
          false,
      showExplanations: json['show_explanations'] as bool? ??
          json['showExplanations'] as bool? ??
          false,
      maxStudents:
          json['max_students'] as int? ?? json['maxStudents'] as int?,
      requireFullScreen: json['require_full_screen'] as bool? ??
          json['requireFullScreen'] as bool? ??
          false,
      allowResume: json['allow_resume'] as bool? ??
          json['allowResume'] as bool? ??
          true,
      browserLockdown: json['browser_lockdown'] as bool? ??
          json['browserLockdown'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'class_id': classId,
      'academic_session_id': academicSessionId,
      'exam_type': examType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'time_limit_minutes': timeLimitMinutes,
      'pass_mark': passMark,
      'pass_mark_type': passMarkType,
      'instructions': instructions,
      'allowed_attempts': allowedAttempts,
      'negative_marking_enabled': negativeMarkingEnabled,
      'negative_mark_value': negativeMarkValue,
      'grace_period_minutes': gracePeriodMinutes,
      'auto_submit': autoSubmit,
      'randomize_questions': randomizeQuestions,
      'randomize_options': randomizeOptions,
      'show_results': showResults,
      'show_correct_answers': showCorrectAnswers,
      'show_explanations': showExplanations,
      'max_students': maxStudents,
      'require_full_screen': requireFullScreen,
      'allow_resume': allowResume,
      'browser_lockdown': browserLockdown,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamCreateInputModel.fromEntity(ExamCreateInput entity) {
    return ExamCreateInputModel(
      title: entity.title,
      description: entity.description,
      subjectId: entity.subjectId,
      classId: entity.classId,
      academicSessionId: entity.academicSessionId,
      examType: entity.examType.value,
      startTime: entity.startTime,
      endTime: entity.endTime,
      timeLimitMinutes: entity.timeLimitMinutes,
      passMark: entity.passMark,
      passMarkType: entity.passMarkType,
      instructions: entity.instructions,
      allowedAttempts: entity.allowedAttempts,
      negativeMarkingEnabled: entity.negativeMarkingEnabled,
      negativeMarkValue: entity.negativeMarkValue,
      gracePeriodMinutes: entity.gracePeriodMinutes,
      autoSubmit: entity.autoSubmit,
      randomizeQuestions: entity.randomizeQuestions,
      randomizeOptions: entity.randomizeOptions,
      showResults: entity.showResults,
      showCorrectAnswers: entity.showCorrectAnswers,
      showExplanations: entity.showExplanations,
      maxStudents: entity.maxStudents,
      requireFullScreen: entity.requireFullScreen,
      allowResume: entity.allowResume,
      browserLockdown: entity.browserLockdown,
    );
  }

  ExamCreateInput toEntity() {
    return ExamCreateInput(
      title: title,
      description: description,
      subjectId: subjectId,
      classId: classId,
      academicSessionId: academicSessionId,
      examType: ExamType.fromString(examType) ?? ExamType.custom,
      startTime: startTime,
      endTime: endTime,
      timeLimitMinutes: timeLimitMinutes,
      passMark: passMark,
      passMarkType: passMarkType,
      instructions: instructions,
      allowedAttempts: allowedAttempts,
      negativeMarkingEnabled: negativeMarkingEnabled,
      negativeMarkValue: negativeMarkValue,
      gracePeriodMinutes: gracePeriodMinutes,
      autoSubmit: autoSubmit,
      randomizeQuestions: randomizeQuestions,
      randomizeOptions: randomizeOptions,
      showResults: showResults,
      showCorrectAnswers: showCorrectAnswers,
      showExplanations: showExplanations,
      maxStudents: maxStudents,
      requireFullScreen: requireFullScreen,
      allowResume: allowResume,
      browserLockdown: browserLockdown,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamCreateInputModel copyWith({
    String? title,
    String? description,
    String? subjectId,
    String? classId,
    String? academicSessionId,
    String? examType,
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
    return ExamCreateInputModel(
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      examType: examType ?? this.examType,
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamCreateInputModel &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subjectId == other.subjectId &&
          examType == other.examType;

  @override
  int get hashCode => Object.hash(title, subjectId, examType);

  @override
  String toString() =>
      'ExamCreateInputModel(title: $title, examType: $examType)';
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════

List<ExamSectionModel> _parseSections(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamSectionModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<ExamQuestionModel> _parseExamQuestions(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamQuestionModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<StudentAnswerModel> _parseAnswers(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => StudentAnswerModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<ExamAttemptModel> _parseAttemptList(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamAttemptModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<ExamSessionModel> _parseSessionList(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamSessionModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<MonitoringLogModel> _parseMonitoringList(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => MonitoringLogModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<GradeScaleEntryModel> _parseScaleEntries(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => GradeScaleEntryModel.fromJson(e))
        .toList();
  }
  return const [];
}

Map<String, dynamic> _parseMap(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}

Map<String, double> _parseCorrectRateMap(dynamic data) {
  if (data == null) return {};
  if (data is Map) {
    return data.map((k, v) {
      if (v is num) return MapEntry(k.toString(), v.toDouble());
      return MapEntry(k.toString(), 0.0);
    });
  }
  return {};
}

List<String>? _parseIpRestriction(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    return data.map((e) => e.toString()).toList();
  }
  return null;
}

/// Converts a QuestionEntity to a JSON map for nested storage.
Map<String, dynamic> _questionEntityToJson(QuestionEntity entity) {
  return {
    'id': entity.id,
    'school_id': entity.schoolId,
    'subject_id': entity.subjectId,
    'topic_id': entity.topicId,
    'question_type': entity.questionType.value,
    'difficulty': entity.difficulty.value,
    'content': entity.content,
    'explanation': entity.explanation,
    'marks': entity.marks,
    'negative_marks': entity.negativeMarks,
  };
}

/// Converts a JSON map back to a QuestionEntity (minimal version for
/// display purposes — full question details require a separate fetch).
QuestionEntity? _questionJsonToEntity(Map<String, dynamic> json) {
  try {
    return QuestionEntity(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? json['topicId'] as String?,
      questionType: QuestionType.fromString(
            json['question_type'] as String? ?? json['questionType'] as String?,
          ) ??
          QuestionType.multipleChoice,
      difficulty: DifficultyLevel.fromString(
            json['difficulty'] as String? ?? json['difficulty_level'] as String?,
          ) ??
          DifficultyLevel.medium,
      content: json['content'] as String? ?? '',
      explanation: json['explanation'] as String?,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ??
          (json['negativeMarks'] as num?)?.toDouble() ??
          0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  } catch (_) {
    return null;
  }
}
