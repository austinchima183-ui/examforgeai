import '../../domain/entities/exam_ecosystem_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// HELPER EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════

/// Helper to read a field from JSON that may be in snake_case (Supabase)
/// or camelCase (internal).
T? _readField<T>(Map<String, dynamic> json, String snakeKey, String camelKey) {
  return json[snakeKey] as T? ?? json[camelKey] as T?;
}

/// Helper to read a DateTime field from JSON (snake_case or camelCase).
DateTime _readDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  final raw = json[snakeKey] as String? ?? json[camelKey] as String;
  return DateTime.parse(raw);
}

/// Helper to read a nullable DateTime field from JSON.
DateTime? _readNullableDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  final raw = json[snakeKey] as String? ?? json[camelKey] as String?;
  if (raw == null) return null;
  return DateTime.parse(raw);
}

/// Helper to read a List<String> from JSON.
List<String> _readListOfStrings(dynamic value) {
  if (value == null) return [];
  return (value as List).cast<String>();
}

/// Helper to read a Map<String, dynamic> from JSON.
Map<String, dynamic> _readMap(dynamic value) {
  if (value == null) return {};
  return Map<String, dynamic>.from(value as Map);
}

/// Helper to read a List<Map<String, dynamic>> from JSON.
List<Map<String, dynamic>> _readListOfMaps(dynamic value) {
  if (value == null) return [];
  return (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

// ═══════════════════════════════════════════════════════════════════════
// MODEL CLASSES
// ═══════════════════════════════════════════════════════════════════════

// ─── 1. ExaminationBodyModel ───────────────────────────────────────

class ExaminationBodyModel {
  const ExaminationBodyModel({
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

  factory ExaminationBodyModel.fromJson(Map<String, dynamic> json) {
    return ExaminationBodyModel(
      id: _readField<String>(json, 'id', 'id')!,
      name: _readField<String>(json, 'name', 'name')!,
      code: _readField<String>(json, 'code', 'code')!,
      examBodyType: ExamBodyType.fromString(
            _readField<String>(json, 'exam_body_type', 'examBodyType'),
          ) ??
          ExamBodyType.custom,
      countryCode: _readField<String>(json, 'country_code', 'countryCode')!,
      description: _readField<String>(json, 'description', 'description'),
      logoUrl: _readField<String>(json, 'logo_url', 'logoUrl'),
      websiteUrl: _readField<String>(json, 'website_url', 'websiteUrl'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      metadata: _readMap(json['metadata'] ?? json['metadata']),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'exam_body_type': examBodyType.value,
      'country_code': countryCode,
      'description': description,
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'is_active': isActive,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExaminationBodyModel.fromEntity(ExaminationBody entity) {
    return ExaminationBodyModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      examBodyType: entity.examBodyType,
      countryCode: entity.countryCode,
      description: entity.description,
      logoUrl: entity.logoUrl,
      websiteUrl: entity.websiteUrl,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExaminationBody toEntity() {
    return ExaminationBody(
      id: id,
      name: name,
      code: code,
      examBodyType: examBodyType,
      countryCode: countryCode,
      description: description,
      logoUrl: logoUrl,
      websiteUrl: websiteUrl,
      isActive: isActive,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─── 2. ExaminationProductModel ────────────────────────────────────

class ExaminationProductModel {
  const ExaminationProductModel({
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

  factory ExaminationProductModel.fromJson(Map<String, dynamic> json) {
    return ExaminationProductModel(
      id: _readField<String>(json, 'id', 'id')!,
      examBodyId: _readField<String>(json, 'exam_body_id', 'examBodyId')!,
      name: _readField<String>(json, 'name', 'name')!,
      code: _readField<String>(json, 'code', 'code')!,
      examCategory: ExamCategoryType.fromString(
            _readField<String>(json, 'exam_category', 'examCategory'),
          ) ??
          ExamCategoryType.practice,
      preparationType: PreparationType.fromString(
            _readField<String>(json, 'preparation_type', 'preparationType'),
          ) ??
          PreparationType.practiceQuestions,
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId'),
      subjectId: _readField<String>(json, 'subject_id', 'subjectId'),
      description: _readField<String>(json, 'description', 'description'),
      durationMinutes: _readField<int>(json, 'duration_minutes', 'durationMinutes'),
      totalMarks: _readField<int>(json, 'total_marks', 'totalMarks'),
      passMark: _readField<int>(json, 'pass_mark', 'passMark'),
      instructions: _readListOfStrings(json['instructions'] ?? json['instructions']),
      isTimed: _readField<bool>(json, 'is_timed', 'isTimed') ?? true,
      allowsNegativeMarking:
          _readField<bool>(json, 'allows_negative_marking', 'allowsNegativeMarking') ??
              false,
      negativeMarkRatio:
          (_readField<num>(json, 'negative_mark_ratio', 'negativeMarkRatio'))
              ?.toDouble(),
      questionCount: _readField<int>(json, 'question_count', 'questionCount'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      isPremium: _readField<bool>(json, 'is_premium', 'isPremium') ?? false,
      metadata: _readMap(json['metadata'] ?? json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_body_id': examBodyId,
      'name': name,
      'code': code,
      'exam_category': examCategory.value,
      'preparation_type': preparationType.value,
      'educational_level_id': educationalLevelId,
      'subject_id': subjectId,
      'description': description,
      'duration_minutes': durationMinutes,
      'total_marks': totalMarks,
      'pass_mark': passMark,
      'instructions': instructions,
      'is_timed': isTimed,
      'allows_negative_marking': allowsNegativeMarking,
      'negative_mark_ratio': negativeMarkRatio,
      'question_count': questionCount,
      'is_active': isActive,
      'is_premium': isPremium,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExaminationProductModel.fromEntity(ExaminationProduct entity) {
    return ExaminationProductModel(
      id: entity.id,
      examBodyId: entity.examBodyId,
      name: entity.name,
      code: entity.code,
      examCategory: entity.examCategory,
      preparationType: entity.preparationType,
      educationalLevelId: entity.educationalLevelId,
      subjectId: entity.subjectId,
      description: entity.description,
      durationMinutes: entity.durationMinutes,
      totalMarks: entity.totalMarks,
      passMark: entity.passMark,
      instructions: entity.instructions,
      isTimed: entity.isTimed,
      allowsNegativeMarking: entity.allowsNegativeMarking,
      negativeMarkRatio: entity.negativeMarkRatio,
      questionCount: entity.questionCount,
      isActive: entity.isActive,
      isPremium: entity.isPremium,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExaminationProduct toEntity() {
    return ExaminationProduct(
      id: id,
      examBodyId: examBodyId,
      name: name,
      code: code,
      examCategory: examCategory,
      preparationType: preparationType,
      educationalLevelId: educationalLevelId,
      subjectId: subjectId,
      description: description,
      durationMinutes: durationMinutes,
      totalMarks: totalMarks,
      passMark: passMark,
      instructions: instructions,
      isTimed: isTimed,
      allowsNegativeMarking: allowsNegativeMarking,
      negativeMarkRatio: negativeMarkRatio,
      questionCount: questionCount,
      isActive: isActive,
      isPremium: isPremium,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─── 3. MockExamModel ──────────────────────────────────────────────

class MockExamModel {
  const MockExamModel({
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

  factory MockExamModel.fromJson(Map<String, dynamic> json) {
    return MockExamModel(
      id: _readField<String>(json, 'id', 'id')!,
      examinationProductId:
          _readField<String>(json, 'examination_product_id', 'examinationProductId')!,
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      title: _readField<String>(json, 'title', 'title')!,
      description: _readField<String>(json, 'description', 'description'),
      examBodyType: ExamBodyType.fromString(
            _readField<String>(json, 'exam_body_type', 'examBodyType'),
          ) ??
          ExamBodyType.custom,
      durationMinutes: _readField<int>(json, 'duration_minutes', 'durationMinutes')!,
      totalQuestions: _readField<int>(json, 'total_questions', 'totalQuestions')!,
      totalMarks: _readField<int>(json, 'total_marks', 'totalMarks')!,
      passMark: _readField<int>(json, 'pass_mark', 'passMark'),
      instructions: _readListOfStrings(json['instructions'] ?? json['instructions']),
      settings: _readMap(json['settings'] ?? json['settings']),
      status: MockExamStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          MockExamStatus.draft,
      startedAt: _readNullableDateTime(json, 'started_at', 'startedAt'),
      endedAt: _readNullableDateTime(json, 'ended_at', 'endedAt'),
      resultsPublishedAt:
          _readNullableDateTime(json, 'results_published_at', 'resultsPublishedAt'),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examination_product_id': examinationProductId,
      'school_id': schoolId,
      'title': title,
      'description': description,
      'exam_body_type': examBodyType.value,
      'duration_minutes': durationMinutes,
      'total_questions': totalQuestions,
      'total_marks': totalMarks,
      'pass_mark': passMark,
      'instructions': instructions,
      'settings': settings,
      'status': status.value,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'results_published_at': resultsPublishedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MockExamModel.fromEntity(MockExam entity) {
    return MockExamModel(
      id: entity.id,
      examinationProductId: entity.examinationProductId,
      schoolId: entity.schoolId,
      title: entity.title,
      description: entity.description,
      examBodyType: entity.examBodyType,
      durationMinutes: entity.durationMinutes,
      totalQuestions: entity.totalQuestions,
      totalMarks: entity.totalMarks,
      passMark: entity.passMark,
      instructions: entity.instructions,
      settings: entity.settings,
      status: entity.status,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      resultsPublishedAt: entity.resultsPublishedAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MockExam toEntity() {
    return MockExam(
      id: id,
      examinationProductId: examinationProductId,
      schoolId: schoolId,
      title: title,
      description: description,
      examBodyType: examBodyType,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      totalMarks: totalMarks,
      passMark: passMark,
      instructions: instructions,
      settings: settings,
      status: status,
      startedAt: startedAt,
      endedAt: endedAt,
      resultsPublishedAt: resultsPublishedAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─── 4. MockExamQuestionModel ──────────────────────────────────────

class MockExamQuestionModel {
  const MockExamQuestionModel({
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

  factory MockExamQuestionModel.fromJson(Map<String, dynamic> json) {
    return MockExamQuestionModel(
      id: _readField<String>(json, 'id', 'id')!,
      mockExamId: _readField<String>(json, 'mock_exam_id', 'mockExamId')!,
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId'),
      questionNumber: _readField<int>(json, 'question_number', 'questionNumber')!,
      sectionLabel: _readField<String>(json, 'section_label', 'sectionLabel'),
      marksAllocated: _readField<int>(json, 'marks_allocated', 'marksAllocated')!,
      isCompulsory: _readField<bool>(json, 'is_compulsory', 'isCompulsory') ?? true,
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder')!,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mock_exam_id': mockExamId,
      'content_item_id': contentItemId,
      'question_number': questionNumber,
      'section_label': sectionLabel,
      'marks_allocated': marksAllocated,
      'is_compulsory': isCompulsory,
      'sort_order': sortOrder,
    };
  }

  factory MockExamQuestionModel.fromEntity(MockExamQuestion entity) {
    return MockExamQuestionModel(
      id: entity.id,
      mockExamId: entity.mockExamId,
      contentItemId: entity.contentItemId,
      questionNumber: entity.questionNumber,
      sectionLabel: entity.sectionLabel,
      marksAllocated: entity.marksAllocated,
      isCompulsory: entity.isCompulsory,
      sortOrder: entity.sortOrder,
    );
  }

  MockExamQuestion toEntity() {
    return MockExamQuestion(
      id: id,
      mockExamId: mockExamId,
      contentItemId: contentItemId,
      questionNumber: questionNumber,
      sectionLabel: sectionLabel,
      marksAllocated: marksAllocated,
      isCompulsory: isCompulsory,
      sortOrder: sortOrder,
    );
  }
}

// ─── 5. MockExamAttemptModel ───────────────────────────────────────

class MockExamAttemptModel {
  const MockExamAttemptModel({
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

  factory MockExamAttemptModel.fromJson(Map<String, dynamic> json) {
    return MockExamAttemptModel(
      id: _readField<String>(json, 'id', 'id')!,
      mockExamId: _readField<String>(json, 'mock_exam_id', 'mockExamId')!,
      userId: _readField<String>(json, 'user_id', 'userId')!,
      startedAt: _readDateTime(json, 'started_at', 'startedAt'),
      submittedAt: _readNullableDateTime(json, 'submitted_at', 'submittedAt'),
      isCompleted: _readField<bool>(json, 'is_completed', 'isCompleted') ?? false,
      isTimedOut: _readField<bool>(json, 'is_timed_out', 'isTimedOut') ?? false,
      totalScore: _readField<int>(json, 'total_score', 'totalScore') ?? 0,
      maxScore: _readField<int>(json, 'max_score', 'maxScore')!,
      percentage: (_readField<num>(json, 'percentage', 'percentage') ?? 0.0)
          .toDouble(),
      grade: _readField<String>(json, 'grade', 'grade'),
      timeTakenSeconds:
          _readField<int>(json, 'time_taken_seconds', 'timeTakenSeconds'),
      status: MockExamAttemptStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          MockExamAttemptStatus.inProgress,
      deviceInfo: _readMap(json['device_info'] ?? json['deviceInfo']),
      metadata: _readMap(json['metadata'] ?? json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mock_exam_id': mockExamId,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'is_completed': isCompleted,
      'is_timed_out': isTimedOut,
      'total_score': totalScore,
      'max_score': maxScore,
      'percentage': percentage,
      'grade': grade,
      'time_taken_seconds': timeTakenSeconds,
      'status': status.value,
      'device_info': deviceInfo,
      'metadata': metadata,
    };
  }

  factory MockExamAttemptModel.fromEntity(MockExamAttempt entity) {
    return MockExamAttemptModel(
      id: entity.id,
      mockExamId: entity.mockExamId,
      userId: entity.userId,
      startedAt: entity.startedAt,
      submittedAt: entity.submittedAt,
      isCompleted: entity.isCompleted,
      isTimedOut: entity.isTimedOut,
      totalScore: entity.totalScore,
      maxScore: entity.maxScore,
      percentage: entity.percentage,
      grade: entity.grade,
      timeTakenSeconds: entity.timeTakenSeconds,
      status: entity.status,
      deviceInfo: entity.deviceInfo,
      metadata: entity.metadata,
    );
  }

  MockExamAttempt toEntity() {
    return MockExamAttempt(
      id: id,
      mockExamId: mockExamId,
      userId: userId,
      startedAt: startedAt,
      submittedAt: submittedAt,
      isCompleted: isCompleted,
      isTimedOut: isTimedOut,
      totalScore: totalScore,
      maxScore: maxScore,
      percentage: percentage,
      grade: grade,
      timeTakenSeconds: timeTakenSeconds,
      status: status,
      deviceInfo: deviceInfo,
      metadata: metadata,
    );
  }
}

// ─── 6. ReadinessAssessmentModel ───────────────────────────────────

class ReadinessAssessmentModel {
  const ReadinessAssessmentModel({
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

  factory ReadinessAssessmentModel.fromJson(Map<String, dynamic> json) {
    return ReadinessAssessmentModel(
      id: _readField<String>(json, 'id', 'id')!,
      userId: _readField<String>(json, 'user_id', 'userId')!,
      examBodyId: _readField<String>(json, 'exam_body_id', 'examBodyId')!,
      subjectId: _readField<String>(json, 'subject_id', 'subjectId'),
      readinessLevel: ReadinessLevel.fromString(
            _readField<String>(json, 'readiness_level', 'readinessLevel'),
          ) ??
          ReadinessLevel.notStarted,
      readinessScore:
          (_readField<num>(json, 'readiness_score', 'readinessScore') ?? 0.0)
              .toDouble(),
      topicsMastered:
          _readField<int>(json, 'topics_mastered', 'topicsMastered') ?? 0,
      topicsTotal: _readField<int>(json, 'topics_total', 'topicsTotal') ?? 0,
      weakTopics: _readListOfStrings(json['weak_topics'] ?? json['weakTopics']),
      strongTopics:
          _readListOfStrings(json['strong_topics'] ?? json['strongTopics']),
      recommendations: _readListOfStrings(
        json['recommendations'] ?? json['recommendations'],
      ),
      assessedAt: _readDateTime(json, 'assessed_at', 'assessedAt'),
      expiresAt: _readNullableDateTime(json, 'expires_at', 'expiresAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exam_body_id': examBodyId,
      'subject_id': subjectId,
      'readiness_level': readinessLevel.value,
      'readiness_score': readinessScore,
      'topics_mastered': topicsMastered,
      'topics_total': topicsTotal,
      'weak_topics': weakTopics,
      'strong_topics': strongTopics,
      'recommendations': recommendations,
      'assessed_at': assessedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory ReadinessAssessmentModel.fromEntity(ReadinessAssessment entity) {
    return ReadinessAssessmentModel(
      id: entity.id,
      userId: entity.userId,
      examBodyId: entity.examBodyId,
      subjectId: entity.subjectId,
      readinessLevel: entity.readinessLevel,
      readinessScore: entity.readinessScore,
      topicsMastered: entity.topicsMastered,
      topicsTotal: entity.topicsTotal,
      weakTopics: entity.weakTopics,
      strongTopics: entity.strongTopics,
      recommendations: entity.recommendations,
      assessedAt: entity.assessedAt,
      expiresAt: entity.expiresAt,
    );
  }

  ReadinessAssessment toEntity() {
    return ReadinessAssessment(
      id: id,
      userId: userId,
      examBodyId: examBodyId,
      subjectId: subjectId,
      readinessLevel: readinessLevel,
      readinessScore: readinessScore,
      topicsMastered: topicsMastered,
      topicsTotal: topicsTotal,
      weakTopics: weakTopics,
      strongTopics: strongTopics,
      recommendations: recommendations,
      assessedAt: assessedAt,
      expiresAt: expiresAt,
    );
  }
}

// ─── 7. StudyPlanModel ─────────────────────────────────────────────

class StudyPlanModel {
  const StudyPlanModel({
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

  factory StudyPlanModel.fromJson(Map<String, dynamic> json) {
    return StudyPlanModel(
      id: _readField<String>(json, 'id', 'id')!,
      userId: _readField<String>(json, 'user_id', 'userId')!,
      title: _readField<String>(json, 'title', 'title')!,
      examBodyId: _readField<String>(json, 'exam_body_id', 'examBodyId')!,
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId'),
      subjectId: _readField<String>(json, 'subject_id', 'subjectId'),
      targetDate: _readNullableDateTime(json, 'target_date', 'targetDate'),
      dailyStudyMinutes:
          _readField<int>(json, 'daily_study_minutes', 'dailyStudyMinutes') ?? 60,
      planType: StudyPlanType.fromString(
            _readField<String>(json, 'plan_type', 'planType'),
          ) ??
          StudyPlanType.custom,
      planSchedule: _readListOfMaps(json['plan_schedule'] ?? json['planSchedule']),
      milestones: _readListOfMaps(json['milestones'] ?? json['milestones']),
      currentStreakDays:
          _readField<int>(json, 'current_streak_days', 'currentStreakDays') ?? 0,
      longestStreakDays:
          _readField<int>(json, 'longest_streak_days', 'longestStreakDays') ?? 0,
      totalStudyMinutes:
          _readField<int>(json, 'total_study_minutes', 'totalStudyMinutes') ?? 0,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      aiGenerated: _readField<bool>(json, 'ai_generated', 'aiGenerated') ?? false,
      metadata: _readMap(json['metadata'] ?? json['metadata']),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'exam_body_id': examBodyId,
      'educational_level_id': educationalLevelId,
      'subject_id': subjectId,
      'target_date': targetDate?.toIso8601String(),
      'daily_study_minutes': dailyStudyMinutes,
      'plan_type': planType.value,
      'plan_schedule': planSchedule,
      'milestones': milestones,
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'total_study_minutes': totalStudyMinutes,
      'is_active': isActive,
      'ai_generated': aiGenerated,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudyPlanModel.fromEntity(StudyPlan entity) {
    return StudyPlanModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      examBodyId: entity.examBodyId,
      educationalLevelId: entity.educationalLevelId,
      subjectId: entity.subjectId,
      targetDate: entity.targetDate,
      dailyStudyMinutes: entity.dailyStudyMinutes,
      planType: entity.planType,
      planSchedule: entity.planSchedule,
      milestones: entity.milestones,
      currentStreakDays: entity.currentStreakDays,
      longestStreakDays: entity.longestStreakDays,
      totalStudyMinutes: entity.totalStudyMinutes,
      isActive: entity.isActive,
      aiGenerated: entity.aiGenerated,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  StudyPlan toEntity() {
    return StudyPlan(
      id: id,
      userId: userId,
      title: title,
      examBodyId: examBodyId,
      educationalLevelId: educationalLevelId,
      subjectId: subjectId,
      targetDate: targetDate,
      dailyStudyMinutes: dailyStudyMinutes,
      planType: planType,
      planSchedule: planSchedule,
      milestones: milestones,
      currentStreakDays: currentStreakDays,
      longestStreakDays: longestStreakDays,
      totalStudyMinutes: totalStudyMinutes,
      isActive: isActive,
      aiGenerated: aiGenerated,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─── 8. StudyPlanActivityModel ─────────────────────────────────────

class StudyPlanActivityModel {
  const StudyPlanActivityModel({
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

  factory StudyPlanActivityModel.fromJson(Map<String, dynamic> json) {
    return StudyPlanActivityModel(
      id: _readField<String>(json, 'id', 'id')!,
      studyPlanId: _readField<String>(json, 'study_plan_id', 'studyPlanId')!,
      activityType: StudyActivityType.fromString(
            _readField<String>(json, 'activity_type', 'activityType'),
          ) ??
          StudyActivityType.practice,
      title: _readField<String>(json, 'title', 'title')!,
      description: _readField<String>(json, 'description', 'description'),
      subjectId: _readField<String>(json, 'subject_id', 'subjectId'),
      topicId: _readField<String>(json, 'topic_id', 'topicId'),
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId'),
      durationMinutes:
          _readField<int>(json, 'duration_minutes', 'durationMinutes'),
      scheduledDate: _readDateTime(json, 'scheduled_date', 'scheduledDate'),
      completedAt:
          _readNullableDateTime(json, 'completed_at', 'completedAt'),
      isCompleted: _readField<bool>(json, 'is_completed', 'isCompleted') ?? false,
      performanceScore:
          (_readField<num>(json, 'performance_score', 'performanceScore'))
              ?.toDouble(),
      metadata: _readMap(json['metadata'] ?? json['metadata']),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'study_plan_id': studyPlanId,
      'activity_type': activityType.value,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'topic_id': topicId,
      'content_item_id': contentItemId,
      'duration_minutes': durationMinutes,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_completed': isCompleted,
      'performance_score': performanceScore,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudyPlanActivityModel.fromEntity(StudyPlanActivity entity) {
    return StudyPlanActivityModel(
      id: entity.id,
      studyPlanId: entity.studyPlanId,
      activityType: entity.activityType,
      title: entity.title,
      description: entity.description,
      subjectId: entity.subjectId,
      topicId: entity.topicId,
      contentItemId: entity.contentItemId,
      durationMinutes: entity.durationMinutes,
      scheduledDate: entity.scheduledDate,
      completedAt: entity.completedAt,
      isCompleted: entity.isCompleted,
      performanceScore: entity.performanceScore,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  StudyPlanActivity toEntity() {
    return StudyPlanActivity(
      id: id,
      studyPlanId: studyPlanId,
      activityType: activityType,
      title: title,
      description: description,
      subjectId: subjectId,
      topicId: topicId,
      contentItemId: contentItemId,
      durationMinutes: durationMinutes,
      scheduledDate: scheduledDate,
      completedAt: completedAt,
      isCompleted: isCompleted,
      performanceScore: performanceScore,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
