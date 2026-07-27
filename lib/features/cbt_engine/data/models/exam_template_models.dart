import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/entities/exam_template_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TEMPLATE DATA MODELS
// ═══════════════════════════════════════════════════════════════════════
// Plain class models (NOT Equatable) for the Exam Template data layer.
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

// ───────────────────────────────────────────────────────────────────────
// Helper: parse list of strings from JSON
// ───────────────────────────────────────────────────────────────────────

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

// ───────────────────────────────────────────────────────────────────────
// Helper: parse nested model lists from JSON
// ───────────────────────────────────────────────────────────────────────

List<ExamTemplateSectionModel> _parseTemplateSections(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamTemplateSectionModel.fromJson(e))
        .toList();
  }
  return const [];
}

List<QuestionSelectionRuleModel> _parseQuestionSelectionRules(dynamic data) {
  if (data == null) return const [];
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => QuestionSelectionRuleModel.fromJson(e))
        .toList();
  }
  return const [];
}

// ═══════════════════════════════════════════════════════════════════════
// QuestionSelectionRuleModel
// ═══════════════════════════════════════════════════════════════════════

class QuestionSelectionRuleModel {
  const QuestionSelectionRuleModel({
    required this.id,
    required this.subjectId,
    this.topicIds = const [],
    this.difficultyLevels = const [],
    this.questionTypes = const [],
    this.curriculumTypes = const [],
    required this.minQuestions,
    required this.maxQuestions,
    required this.marksPerQuestion,
    this.selectionMode = 'random',
    this.includeImages = false,
    this.includeAudio = false,
    this.includeVideo = false,
  });

  final String id;
  final String subjectId;
  final List<String> topicIds;
  final List<String> difficultyLevels;
  final List<String> questionTypes;
  final List<String> curriculumTypes;
  final int minQuestions;
  final int maxQuestions;
  final double marksPerQuestion;
  final String selectionMode;
  final bool includeImages;
  final bool includeAudio;
  final bool includeVideo;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionSelectionRuleModel.fromJson(Map<String, dynamic> json) {
    return QuestionSelectionRuleModel(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String? ??
          json['subjectId'] as String? ??
          '',
      topicIds: _parseStringList(
        json['topic_ids'] ?? json['topicIds'],
      ),
      difficultyLevels: _parseStringList(
        json['difficulty_levels'] ?? json['difficultyLevels'],
      ),
      questionTypes: _parseStringList(
        json['question_types'] ?? json['questionTypes'],
      ),
      curriculumTypes: _parseStringList(
        json['curriculum_types'] ?? json['curriculumTypes'],
      ),
      minQuestions: json['min_questions'] as int? ??
          json['minQuestions'] as int? ??
          0,
      maxQuestions: json['max_questions'] as int? ??
          json['maxQuestions'] as int? ??
          0,
      marksPerQuestion:
          (json['marks_per_question'] as num?)?.toDouble() ??
              (json['marksPerQuestion'] as num?)?.toDouble() ??
              0.0,
      selectionMode: json['selection_mode'] as String? ??
          json['selectionMode'] as String? ??
          'random',
      includeImages: json['include_images'] as bool? ??
          json['includeImages'] as bool? ??
          false,
      includeAudio: json['include_audio'] as bool? ??
          json['includeAudio'] as bool? ??
          false,
      includeVideo: json['include_video'] as bool? ??
          json['includeVideo'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'topic_ids': topicIds,
      'difficulty_levels': difficultyLevels,
      'question_types': questionTypes,
      'curriculum_types': curriculumTypes,
      'min_questions': minQuestions,
      'max_questions': maxQuestions,
      'marks_per_question': marksPerQuestion,
      'selection_mode': selectionMode,
      'include_images': includeImages,
      'include_audio': includeAudio,
      'include_video': includeVideo,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionSelectionRuleModel.fromEntity(
    QuestionSelectionRuleEntity entity,
  ) {
    return QuestionSelectionRuleModel(
      id: entity.id,
      subjectId: entity.subjectId,
      topicIds: entity.topicIds,
      difficultyLevels:
          entity.difficultyLevels.map((e) => e.value).toList(),
      questionTypes:
          entity.questionTypes.map((e) => e.value).toList(),
      curriculumTypes: entity.curriculumTypes,
      minQuestions: entity.minQuestions,
      maxQuestions: entity.maxQuestions,
      marksPerQuestion: entity.marksPerQuestion,
      selectionMode: entity.selectionMode.value,
      includeImages: entity.includeImages,
      includeAudio: entity.includeAudio,
      includeVideo: entity.includeVideo,
    );
  }

  QuestionSelectionRuleEntity toEntity() {
    return QuestionSelectionRuleEntity(
      id: id,
      subjectId: subjectId,
      topicIds: topicIds,
      difficultyLevels: difficultyLevels
          .map((e) => DifficultyLevel.fromString(e))
          .whereType<DifficultyLevel>()
          .toList(),
      questionTypes: questionTypes
          .map((e) => QuestionType.fromString(e))
          .whereType<QuestionType>()
          .toList(),
      curriculumTypes: curriculumTypes,
      minQuestions: minQuestions,
      maxQuestions: maxQuestions,
      marksPerQuestion: marksPerQuestion,
      selectionMode: QuestionSelectionMode.fromString(selectionMode) ??
          QuestionSelectionMode.random,
      includeImages: includeImages,
      includeAudio: includeAudio,
      includeVideo: includeVideo,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionSelectionRuleModel copyWith({
    String? id,
    String? subjectId,
    List<String>? topicIds,
    List<String>? difficultyLevels,
    List<String>? questionTypes,
    List<String>? curriculumTypes,
    int? minQuestions,
    int? maxQuestions,
    double? marksPerQuestion,
    String? selectionMode,
    bool? includeImages,
    bool? includeAudio,
    bool? includeVideo,
  }) {
    return QuestionSelectionRuleModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionSelectionRuleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subjectId == other.subjectId &&
          _listEquals(topicIds, other.topicIds) &&
          _listEquals(difficultyLevels, other.difficultyLevels) &&
          _listEquals(questionTypes, other.questionTypes) &&
          _listEquals(curriculumTypes, other.curriculumTypes) &&
          minQuestions == other.minQuestions &&
          maxQuestions == other.maxQuestions &&
          marksPerQuestion == other.marksPerQuestion &&
          selectionMode == other.selectionMode &&
          includeImages == other.includeImages &&
          includeAudio == other.includeAudio &&
          includeVideo == other.includeVideo;

  @override
  int get hashCode => Object.hash(
        id,
        subjectId,
        Object.hashAll(topicIds),
        Object.hashAll(difficultyLevels),
        Object.hashAll(questionTypes),
        Object.hashAll(curriculumTypes),
        minQuestions,
        maxQuestions,
        marksPerQuestion,
        selectionMode,
        includeImages,
        includeAudio,
        includeVideo,
      );

  @override
  String toString() =>
      'QuestionSelectionRuleModel(id: $id, subjectId: $subjectId, minQuestions: $minQuestions, maxQuestions: $maxQuestions)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamTemplateSectionModel
// ═══════════════════════════════════════════════════════════════════════

class ExamTemplateSectionModel {
  const ExamTemplateSectionModel({
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
  final QuestionSelectionRuleModel? questionSelectionRule;
  final double marksPerQuestion;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamTemplateSectionModel.fromJson(Map<String, dynamic> json) {
    return ExamTemplateSectionModel(
      id: json['id'] as String,
      templateId: json['template_id'] as String? ??
          json['templateId'] as String? ??
          '',
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      sortOrder: json['sort_order'] as int? ??
          json['sortOrder'] as int? ??
          0,
      timeLimitMinutes: json['time_limit_minutes'] as int? ??
          json['timeLimitMinutes'] as int?,
      randomizeQuestions: json['randomize_questions'] as bool? ??
          json['randomizeQuestions'] as bool? ??
          false,
      questionSelectionRule: _parseQuestionSelectionRule(
        json['question_selection_rule'] ??
            json['questionSelectionRule'],
      ),
      marksPerQuestion:
          (json['marks_per_question'] as num?)?.toDouble() ??
              (json['marksPerQuestion'] as num?)?.toDouble() ??
              1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'sort_order': sortOrder,
      'time_limit_minutes': timeLimitMinutes,
      'randomize_questions': randomizeQuestions,
      'question_selection_rule': questionSelectionRule?.toJson(),
      'marks_per_question': marksPerQuestion,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamTemplateSectionModel.fromEntity(
    ExamTemplateSectionEntity entity,
  ) {
    return ExamTemplateSectionModel(
      id: entity.id,
      templateId: entity.templateId,
      title: entity.title,
      description: entity.description,
      instructions: entity.instructions,
      sortOrder: entity.sortOrder,
      timeLimitMinutes: entity.timeLimitMinutes,
      randomizeQuestions: entity.randomizeQuestions,
      questionSelectionRule: entity.questionSelectionRule != null
          ? QuestionSelectionRuleModel.fromEntity(
              entity.questionSelectionRule!,)
          : null,
      marksPerQuestion: entity.marksPerQuestion,
    );
  }

  ExamTemplateSectionEntity toEntity() {
    return ExamTemplateSectionEntity(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      instructions: instructions,
      sortOrder: sortOrder,
      timeLimitMinutes: timeLimitMinutes,
      randomizeQuestions: randomizeQuestions,
      questionSelectionRule: questionSelectionRule?.toEntity(),
      marksPerQuestion: marksPerQuestion,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamTemplateSectionModel copyWith({
    String? id,
    String? templateId,
    String? title,
    String? description,
    String? instructions,
    int? sortOrder,
    int? timeLimitMinutes,
    bool? randomizeQuestions,
    QuestionSelectionRuleModel? questionSelectionRule,
    double? marksPerQuestion,
  }) {
    return ExamTemplateSectionModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamTemplateSectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          templateId == other.templateId &&
          title == other.title &&
          description == other.description &&
          instructions == other.instructions &&
          sortOrder == other.sortOrder &&
          timeLimitMinutes == other.timeLimitMinutes &&
          randomizeQuestions == other.randomizeQuestions &&
          questionSelectionRule == other.questionSelectionRule &&
          marksPerQuestion == other.marksPerQuestion;

  @override
  int get hashCode => Object.hash(
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
      );

  @override
  String toString() =>
      'ExamTemplateSectionModel(id: $id, title: $title, templateId: $templateId)';
}

// ═══════════════════════════════════════════════════════════════════════
// ExamTemplateModel
// ═══════════════════════════════════════════════════════════════════════

class ExamTemplateModel {
  const ExamTemplateModel({
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
    this.category = 'custom',
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
  final String examType;

  // ── Timing ──────────────────────────────────────────────────────────
  final int timeLimitMinutes;

  // ── Scoring ─────────────────────────────────────────────────────────
  final double passMark;
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
  final String showResults;
  final bool showCorrectAnswers;
  final bool showExplanations;

  // ── Security ────────────────────────────────────────────────────────
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;

  // ── Structure ───────────────────────────────────────────────────────
  final List<ExamTemplateSectionModel> sections;
  final List<QuestionSelectionRuleModel> questionSelectionRules;

  // ── Extensibility ───────────────────────────────────────────────────
  final Map<String, dynamic>? metadata;

  // ── Usage & Sharing ─────────────────────────────────────────────────
  final int usageCount;
  final bool isPublic;
  final String category;
  final List<String> tags;

  // ── Timestamps ──────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ExamTemplateModel.fromJson(Map<String, dynamic> json) {
    return ExamTemplateModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ??
          json['schoolId'] as String? ??
          '',
      createdBy: json['created_by'] as String? ??
          json['createdBy'] as String? ??
          '',
      name: json['name'] as String,
      description: json['description'] as String?,
      subjectId: json['subject_id'] as String? ??
          json['subjectId'] as String? ??
          '',
      classId: json['class_id'] as String? ??
          json['classId'] as String? ??
          '',
      examType: json['exam_type'] as String? ??
          json['examType'] as String? ??
          'custom',
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
      requireFullScreen: json['require_full_screen'] as bool? ??
          json['requireFullScreen'] as bool? ??
          false,
      allowResume: json['allow_resume'] as bool? ??
          json['allowResume'] as bool? ??
          true,
      browserLockdown: json['browser_lockdown'] as bool? ??
          json['browserLockdown'] as bool? ??
          false,
      sections: _parseTemplateSections(
        json['sections'] ?? json['exam_template_sections'],
      ),
      questionSelectionRules: _parseQuestionSelectionRules(
        json['question_selection_rules'],
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      usageCount: json['usage_count'] as int? ??
          json['usageCount'] as int? ??
          0,
      isPublic: json['is_public'] as bool? ??
          json['isPublic'] as bool? ??
          false,
      category: json['category'] as String? ??
          'custom',
      tags: _parseStringList(json['tags']),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
      updatedAt: _parseDateTime(
        json['updated_at'] ?? json['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'created_by': createdBy,
      'name': name,
      'description': description,
      'subject_id': subjectId,
      'class_id': classId,
      'exam_type': examType,
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
      'require_full_screen': requireFullScreen,
      'allow_resume': allowResume,
      'browser_lockdown': browserLockdown,
      'sections': sections.map((s) => s.toJson()).toList(),
      'question_selection_rules':
          questionSelectionRules.map((r) => r.toJson()).toList(),
      'metadata': metadata,
      'usage_count': usageCount,
      'is_public': isPublic,
      'category': category,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ExamTemplateModel.fromEntity(ExamTemplateEntity entity) {
    return ExamTemplateModel(
      id: entity.id,
      schoolId: entity.schoolId,
      createdBy: entity.createdBy,
      name: entity.name,
      description: entity.description,
      subjectId: entity.subjectId,
      classId: entity.classId,
      examType: entity.examType.value,
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
      requireFullScreen: entity.requireFullScreen,
      allowResume: entity.allowResume,
      browserLockdown: entity.browserLockdown,
      sections: entity.sections
          .map((s) => ExamTemplateSectionModel.fromEntity(s))
          .toList(),
      questionSelectionRules: entity.questionSelectionRules
          .map((r) => QuestionSelectionRuleModel.fromEntity(r))
          .toList(),
      metadata: entity.metadata,
      usageCount: entity.usageCount,
      isPublic: entity.isPublic,
      category: entity.category.value,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExamTemplateEntity toEntity() {
    return ExamTemplateEntity(
      id: id,
      schoolId: schoolId,
      createdBy: createdBy,
      name: name,
      description: description,
      subjectId: subjectId,
      classId: classId,
      examType: ExamType.fromString(examType) ?? ExamType.custom,
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
      requireFullScreen: requireFullScreen,
      allowResume: allowResume,
      browserLockdown: browserLockdown,
      sections: sections.map((s) => s.toEntity()).toList(),
      questionSelectionRules:
          questionSelectionRules.map((r) => r.toEntity()).toList(),
      metadata: metadata,
      usageCount: usageCount,
      isPublic: isPublic,
      category: TemplateCategory.fromString(category) ??
          TemplateCategory.custom,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ExamTemplateModel copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? name,
    String? description,
    String? subjectId,
    String? classId,
    String? examType,
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
    List<ExamTemplateSectionModel>? sections,
    List<QuestionSelectionRuleModel>? questionSelectionRules,
    Map<String, dynamic>? metadata,
    int? usageCount,
    bool? isPublic,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamTemplateModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamTemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          createdBy == other.createdBy &&
          name == other.name &&
          description == other.description &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          examType == other.examType &&
          timeLimitMinutes == other.timeLimitMinutes &&
          passMark == other.passMark &&
          passMarkType == other.passMarkType &&
          instructions == other.instructions &&
          allowedAttempts == other.allowedAttempts &&
          negativeMarkingEnabled == other.negativeMarkingEnabled &&
          negativeMarkValue == other.negativeMarkValue &&
          gracePeriodMinutes == other.gracePeriodMinutes &&
          autoSubmit == other.autoSubmit &&
          randomizeQuestions == other.randomizeQuestions &&
          randomizeOptions == other.randomizeOptions &&
          showResults == other.showResults &&
          showCorrectAnswers == other.showCorrectAnswers &&
          showExplanations == other.showExplanations &&
          requireFullScreen == other.requireFullScreen &&
          allowResume == other.allowResume &&
          browserLockdown == other.browserLockdown &&
          _listEquals(sections, other.sections) &&
          _listEquals(questionSelectionRules, other.questionSelectionRules) &&
          metadata == other.metadata &&
          usageCount == other.usageCount &&
          isPublic == other.isPublic &&
          category == other.category &&
          _listEquals(tags, other.tags) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        Object.hash(
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
        ),
        Object.hash(
          showCorrectAnswers,
          showExplanations,
          requireFullScreen,
          allowResume,
          browserLockdown,
          Object.hashAll(sections),
          Object.hashAll(questionSelectionRules),
          metadata,
          usageCount,
          isPublic,
          category,
          Object.hashAll(tags),
          createdAt,
          updatedAt,
        ),
      );

  @override
  String toString() =>
      'ExamTemplateModel(id: $id, name: $name, category: $category)';
}

// ═══════════════════════════════════════════════════════════════════════
// SubmissionReceiptModel
// ═══════════════════════════════════════════════════════════════════════

class SubmissionReceiptModel {
  const SubmissionReceiptModel({
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
  final String submissionType;
  final int totalQuestions;
  final int answeredQuestions;
  final int unansweredQuestions;
  final int flaggedQuestions;
  final int timeSpentMinutes;
  final String? ipAddress;
  final Map<String, dynamic>? deviceInfo;
  final String receiptNumber;
  final bool isVerified;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SubmissionReceiptModel.fromJson(Map<String, dynamic> json) {
    return SubmissionReceiptModel(
      id: json['id'] as String,
      attemptId: json['attempt_id'] as String? ??
          json['attemptId'] as String? ??
          '',
      examId: json['exam_id'] as String? ??
          json['examId'] as String? ??
          '',
      studentId: json['student_id'] as String? ??
          json['studentId'] as String? ??
          '',
      examTitle: json['exam_title'] as String? ??
          json['examTitle'] as String? ??
          '',
      submittedAt: _parseDateTime(
        json['submitted_at'] ?? json['submittedAt'],
      ),
      submissionType: json['submission_type'] as String? ??
          json['submissionType'] as String? ??
          'manual',
      totalQuestions: json['total_questions'] as int? ??
          json['totalQuestions'] as int? ??
          0,
      answeredQuestions: json['answered_questions'] as int? ??
          json['answeredQuestions'] as int? ??
          0,
      unansweredQuestions: json['unanswered_questions'] as int? ??
          json['unansweredQuestions'] as int? ??
          0,
      flaggedQuestions: json['flagged_questions'] as int? ??
          json['flaggedQuestions'] as int? ??
          0,
      timeSpentMinutes: json['time_spent_minutes'] as int? ??
          json['timeSpentMinutes'] as int? ??
          0,
      ipAddress: json['ip_address'] as String? ??
          json['ipAddress'] as String?,
      deviceInfo: json['device_info'] as Map<String, dynamic>? ??
          json['deviceInfo'] as Map<String, dynamic>?,
      receiptNumber: json['receipt_number'] as String? ??
          json['receiptNumber'] as String? ??
          '',
      isVerified: json['is_verified'] as bool? ??
          json['isVerified'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'exam_id': examId,
      'student_id': studentId,
      'exam_title': examTitle,
      'submitted_at': submittedAt.toIso8601String(),
      'submission_type': submissionType,
      'total_questions': totalQuestions,
      'answered_questions': answeredQuestions,
      'unanswered_questions': unansweredQuestions,
      'flagged_questions': flaggedQuestions,
      'time_spent_minutes': timeSpentMinutes,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
      'receipt_number': receiptNumber,
      'is_verified': isVerified,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SubmissionReceiptModel.fromEntity(
    SubmissionReceiptEntity entity,
  ) {
    return SubmissionReceiptModel(
      id: entity.id,
      attemptId: entity.attemptId,
      examId: entity.examId,
      studentId: entity.studentId,
      examTitle: entity.examTitle,
      submittedAt: entity.submittedAt,
      submissionType: entity.submissionType.value,
      totalQuestions: entity.totalQuestions,
      answeredQuestions: entity.answeredQuestions,
      unansweredQuestions: entity.unansweredQuestions,
      flaggedQuestions: entity.flaggedQuestions,
      timeSpentMinutes: entity.timeSpentMinutes,
      ipAddress: entity.ipAddress,
      deviceInfo: entity.deviceInfo,
      receiptNumber: entity.receiptNumber,
      isVerified: entity.isVerified,
    );
  }

  SubmissionReceiptEntity toEntity() {
    return SubmissionReceiptEntity(
      id: id,
      attemptId: attemptId,
      examId: examId,
      studentId: studentId,
      examTitle: examTitle,
      submittedAt: submittedAt,
      submissionType: SubmissionType.fromString(submissionType) ??
          SubmissionType.manual,
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      unansweredQuestions: unansweredQuestions,
      flaggedQuestions: flaggedQuestions,
      timeSpentMinutes: timeSpentMinutes,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
      receiptNumber: receiptNumber,
      isVerified: isVerified,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SubmissionReceiptModel copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    String? examTitle,
    DateTime? submittedAt,
    String? submissionType,
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
    return SubmissionReceiptModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionReceiptModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attemptId == other.attemptId &&
          examId == other.examId &&
          studentId == other.studentId &&
          examTitle == other.examTitle &&
          submittedAt == other.submittedAt &&
          submissionType == other.submissionType &&
          totalQuestions == other.totalQuestions &&
          answeredQuestions == other.answeredQuestions &&
          unansweredQuestions == other.unansweredQuestions &&
          flaggedQuestions == other.flaggedQuestions &&
          timeSpentMinutes == other.timeSpentMinutes &&
          ipAddress == other.ipAddress &&
          deviceInfo == other.deviceInfo &&
          receiptNumber == other.receiptNumber &&
          isVerified == other.isVerified;

  @override
  int get hashCode => Object.hash(
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
      );

  @override
  String toString() =>
      'SubmissionReceiptModel(id: $id, receiptNumber: $receiptNumber, examTitle: $examTitle)';
}

// ───────────────────────────────────────────────────────────────────────
// Private helpers
// ───────────────────────────────────────────────────────────────────────

QuestionSelectionRuleModel? _parseQuestionSelectionRule(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) {
    return QuestionSelectionRuleModel.fromJson(data);
  }
  return null;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
