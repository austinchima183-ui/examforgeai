import '../../domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTING MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a topic within a subject.
class TopicModel {
  const TopicModel({
    required this.id,
    required this.name,
    required this.subjectId,
    this.description,
    this.code,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String subjectId;
  final String? description;
  final String? code;
  final int sortOrder;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      description: json['description'] as String?,
      code: json['code'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
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
      'name': name,
      'subject_id': subjectId,
      'description': description,
      'code': code,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TopicModel.fromEntity(TopicEntity entity) {
    return TopicModel(
      id: entity.id,
      name: entity.name,
      subjectId: entity.subjectId,
      description: entity.description,
      code: entity.code,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TopicEntity toEntity() {
    return TopicEntity(
      id: id,
      name: name,
      subjectId: subjectId,
      description: description,
      code: code,
      sortOrder: sortOrder,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TopicModel copyWith({
    String? id,
    String? name,
    String? subjectId,
    String? description,
    String? code,
    int? sortOrder,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      description: description ?? this.description,
      code: code ?? this.code,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          subjectId == other.subjectId &&
          description == other.description &&
          code == other.code &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        subjectId,
        description,
        code,
        sortOrder,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'TopicModel(id: $id, name: $name, subjectId: $subjectId)';
}

/// Data-layer representation of a subtopic within a topic.
class SubtopicModel {
  const SubtopicModel({
    required this.id,
    required this.name,
    required this.topicId,
    this.description,
    this.code,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String topicId;
  final String? description;
  final String? code;
  final int sortOrder;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SubtopicModel.fromJson(Map<String, dynamic> json) {
    return SubtopicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      topicId: json['topic_id'] as String? ?? json['topicId'] as String? ?? '',
      description: json['description'] as String?,
      code: json['code'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
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
      'name': name,
      'topic_id': topicId,
      'description': description,
      'code': code,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SubtopicModel.fromEntity(SubtopicEntity entity) {
    return SubtopicModel(
      id: entity.id,
      name: entity.name,
      topicId: entity.topicId,
      description: entity.description,
      code: entity.code,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SubtopicEntity toEntity() {
    return SubtopicEntity(
      id: id,
      name: name,
      topicId: topicId,
      description: description,
      code: code,
      sortOrder: sortOrder,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SubtopicModel copyWith({
    String? id,
    String? name,
    String? topicId,
    String? description,
    String? code,
    int? sortOrder,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubtopicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      topicId: topicId ?? this.topicId,
      description: description ?? this.description,
      code: code ?? this.code,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtopicModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          topicId == other.topicId &&
          description == other.description &&
          code == other.code &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        topicId,
        description,
        code,
        sortOrder,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'SubtopicModel(id: $id, name: $name, topicId: $topicId)';
}

/// Data-layer representation of a question category.
class QuestionCategoryModel {
  const QuestionCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.schoolId,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? schoolId;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuestionCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
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
      'name': name,
      'description': description,
      'school_id': schoolId,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionCategoryModel.fromEntity(QuestionCategoryEntity entity) {
    return QuestionCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      schoolId: entity.schoolId,
      icon: entity.icon,
      color: entity.color,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  QuestionCategoryEntity toEntity() {
    return QuestionCategoryEntity(
      id: id,
      name: name,
      description: description,
      schoolId: schoolId,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? schoolId,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          schoolId == other.schoolId &&
          icon == other.icon &&
          color == other.color &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        schoolId,
        icon,
        color,
        sortOrder,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'QuestionCategoryModel(id: $id, name: $name)';
}

/// Data-layer representation of an academic session.
class AcademicSessionModel {
  const AcademicSessionModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.term,
    this.isCurrent = false,
    this.schoolId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? term;
  final bool isCurrent;
  final String? schoolId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AcademicSessionModel.fromJson(Map<String, dynamic> json) {
    return AcademicSessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : json['endDate'] != null
              ? DateTime.parse(json['endDate'] as String)
              : DateTime.now(),
      term: json['term'] as String?,
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
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
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'term': term,
      'is_current': isCurrent,
      'school_id': schoolId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AcademicSessionModel.fromEntity(AcademicSessionEntity entity) {
    return AcademicSessionModel(
      id: entity.id,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      term: entity.term,
      isCurrent: entity.isCurrent,
      schoolId: entity.schoolId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AcademicSessionEntity toEntity() {
    return AcademicSessionEntity(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      term: term,
      isCurrent: isCurrent,
      schoolId: schoolId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AcademicSessionModel copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? term,
    bool? isCurrent,
    String? schoolId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicSessionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      term: term ?? this.term,
      isCurrent: isCurrent ?? this.isCurrent,
      schoolId: schoolId ?? this.schoolId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          term == other.term &&
          isCurrent == other.isCurrent &&
          schoolId == other.schoolId &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        startDate,
        endDate,
        term,
        isCurrent,
        schoolId,
        isActive,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'AcademicSessionModel(id: $id, name: $name)';
}

/// Data-layer representation of an answer option.
class AnswerOptionModel {
  const AnswerOptionModel({
    required this.id,
    required this.questionId,
    required this.content,
    this.contentJson,
    this.isCorrect = false,
    this.marks = 0.0,
    this.sortOrder = 0,
    this.explanation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String questionId;
  final String content;
  final Map<String, dynamic>? contentJson;
  final bool isCorrect;
  final double marks;
  final int sortOrder;
  final String? explanation;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      content: json['content'] as String,
      contentJson: json['content_json'] as Map<String, dynamic>? ??
          json['contentJson'] as Map<String, dynamic>?,
      isCorrect: json['is_correct'] as bool? ?? json['isCorrect'] as bool? ?? false,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      explanation: json['explanation'] as String?,
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
      'question_id': questionId,
      'content': content,
      'content_json': contentJson,
      'is_correct': isCorrect,
      'marks': marks,
      'sort_order': sortOrder,
      'explanation': explanation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AnswerOptionModel.fromEntity(AnswerOptionEntity entity) {
    return AnswerOptionModel(
      id: entity.id,
      questionId: entity.questionId,
      content: entity.content,
      contentJson: entity.contentJson,
      isCorrect: entity.isCorrect,
      marks: entity.marks,
      sortOrder: entity.sortOrder,
      explanation: entity.explanation,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AnswerOptionEntity toEntity() {
    return AnswerOptionEntity(
      id: id,
      questionId: questionId,
      content: content,
      contentJson: contentJson,
      isCorrect: isCorrect,
      marks: marks,
      sortOrder: sortOrder,
      explanation: explanation,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AnswerOptionModel copyWith({
    String? id,
    String? questionId,
    String? content,
    Map<String, dynamic>? contentJson,
    bool? isCorrect,
    double? marks,
    int? sortOrder,
    String? explanation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnswerOptionModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      isCorrect: isCorrect ?? this.isCorrect,
      marks: marks ?? this.marks,
      sortOrder: sortOrder ?? this.sortOrder,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerOptionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          content == other.content &&
          contentJson == other.contentJson &&
          isCorrect == other.isCorrect &&
          marks == other.marks &&
          sortOrder == other.sortOrder &&
          explanation == other.explanation &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        content,
        contentJson,
        isCorrect,
        marks,
        sortOrder,
        explanation,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'AnswerOptionModel(id: $id, questionId: $questionId, isCorrect: $isCorrect)';
}

/// Data-layer representation of a matching pair.
class MatchingPairModel {
  const MatchingPairModel({
    required this.id,
    required this.questionId,
    required this.leftContent,
    required this.rightContent,
    this.leftMediaUrl,
    this.rightMediaUrl,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String leftContent;
  final String rightContent;
  final String? leftMediaUrl;
  final String? rightMediaUrl;
  final int sortOrder;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory MatchingPairModel.fromJson(Map<String, dynamic> json) {
    return MatchingPairModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      leftContent: json['left_content'] as String? ?? json['leftContent'] as String? ?? '',
      rightContent: json['right_content'] as String? ?? json['rightContent'] as String? ?? '',
      leftMediaUrl: json['left_media_url'] as String? ?? json['leftMediaUrl'] as String?,
      rightMediaUrl: json['right_media_url'] as String? ?? json['rightMediaUrl'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
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
      'question_id': questionId,
      'left_content': leftContent,
      'right_content': rightContent,
      'left_media_url': leftMediaUrl,
      'right_media_url': rightMediaUrl,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory MatchingPairModel.fromEntity(MatchingPairEntity entity) {
    return MatchingPairModel(
      id: entity.id,
      questionId: entity.questionId,
      leftContent: entity.leftContent,
      rightContent: entity.rightContent,
      leftMediaUrl: entity.leftMediaUrl,
      rightMediaUrl: entity.rightMediaUrl,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }

  MatchingPairEntity toEntity() {
    return MatchingPairEntity(
      id: id,
      questionId: questionId,
      leftContent: leftContent,
      rightContent: rightContent,
      leftMediaUrl: leftMediaUrl,
      rightMediaUrl: rightMediaUrl,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  MatchingPairModel copyWith({
    String? id,
    String? questionId,
    String? leftContent,
    String? rightContent,
    String? leftMediaUrl,
    String? rightMediaUrl,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return MatchingPairModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      leftContent: leftContent ?? this.leftContent,
      rightContent: rightContent ?? this.rightContent,
      leftMediaUrl: leftMediaUrl ?? this.leftMediaUrl,
      rightMediaUrl: rightMediaUrl ?? this.rightMediaUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchingPairModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          leftContent == other.leftContent &&
          rightContent == other.rightContent &&
          leftMediaUrl == other.leftMediaUrl &&
          rightMediaUrl == other.rightMediaUrl &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        leftContent,
        rightContent,
        leftMediaUrl,
        rightMediaUrl,
        sortOrder,
        createdAt,
      );

  @override
  String toString() =>
      'MatchingPairModel(id: $id, questionId: $questionId)';
}

/// Data-layer representation of an ordering item.
class OrderingItemModel {
  const OrderingItemModel({
    required this.id,
    required this.questionId,
    required this.content,
    required this.correctPosition,
    this.mediaUrl,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String content;
  final int correctPosition;
  final String? mediaUrl;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory OrderingItemModel.fromJson(Map<String, dynamic> json) {
    return OrderingItemModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      content: json['content'] as String,
      correctPosition: json['correct_position'] as int? ?? json['correctPosition'] as int? ?? 0,
      mediaUrl: json['media_url'] as String? ?? json['mediaUrl'] as String?,
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
      'question_id': questionId,
      'content': content,
      'correct_position': correctPosition,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory OrderingItemModel.fromEntity(OrderingItemEntity entity) {
    return OrderingItemModel(
      id: entity.id,
      questionId: entity.questionId,
      content: entity.content,
      correctPosition: entity.correctPosition,
      mediaUrl: entity.mediaUrl,
      createdAt: entity.createdAt,
    );
  }

  OrderingItemEntity toEntity() {
    return OrderingItemEntity(
      id: id,
      questionId: questionId,
      content: content,
      correctPosition: correctPosition,
      mediaUrl: mediaUrl,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  OrderingItemModel copyWith({
    String? id,
    String? questionId,
    String? content,
    int? correctPosition,
    String? mediaUrl,
    DateTime? createdAt,
  }) {
    return OrderingItemModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      correctPosition: correctPosition ?? this.correctPosition,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderingItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          content == other.content &&
          correctPosition == other.correctPosition &&
          mediaUrl == other.mediaUrl &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        content,
        correctPosition,
        mediaUrl,
        createdAt,
      );

  @override
  String toString() =>
      'OrderingItemModel(id: $id, questionId: $questionId, position: $correctPosition)';
}

/// Data-layer representation of a fill-in-the-blank answer.
class FillInBlankAnswerModel {
  const FillInBlankAnswerModel({
    required this.id,
    required this.questionId,
    required this.blankIndex,
    required this.acceptableAnswers,
    this.isCaseSensitive = false,
    this.marks = 0.0,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final int blankIndex;
  final List<String> acceptableAnswers;
  final bool isCaseSensitive;
  final double marks;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory FillInBlankAnswerModel.fromJson(Map<String, dynamic> json) {
    // Supabase stores TEXT[] natively, but JSON might have it as List<dynamic>
    final rawAnswers = json['acceptable_answers'] ?? json['acceptableAnswers'];
    final List<String> answers = rawAnswers is List
        ? rawAnswers.map((e) => e.toString()).toList()
        : <String>[];

    return FillInBlankAnswerModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      blankIndex: json['blank_index'] as int? ?? json['blankIndex'] as int? ?? 0,
      acceptableAnswers: answers,
      isCaseSensitive: json['is_case_sensitive'] as bool? ?? json['isCaseSensitive'] as bool? ?? false,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
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
      'question_id': questionId,
      'blank_index': blankIndex,
      'acceptable_answers': acceptableAnswers,
      'is_case_sensitive': isCaseSensitive,
      'marks': marks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory FillInBlankAnswerModel.fromEntity(FillInBlankAnswerEntity entity) {
    return FillInBlankAnswerModel(
      id: entity.id,
      questionId: entity.questionId,
      blankIndex: entity.blankIndex,
      acceptableAnswers: entity.acceptableAnswers,
      isCaseSensitive: entity.isCaseSensitive,
      marks: entity.marks,
      createdAt: entity.createdAt,
    );
  }

  FillInBlankAnswerEntity toEntity() {
    return FillInBlankAnswerEntity(
      id: id,
      questionId: questionId,
      blankIndex: blankIndex,
      acceptableAnswers: acceptableAnswers,
      isCaseSensitive: isCaseSensitive,
      marks: marks,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  FillInBlankAnswerModel copyWith({
    String? id,
    String? questionId,
    int? blankIndex,
    List<String>? acceptableAnswers,
    bool? isCaseSensitive,
    double? marks,
    DateTime? createdAt,
  }) {
    return FillInBlankAnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      blankIndex: blankIndex ?? this.blankIndex,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      marks: marks ?? this.marks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FillInBlankAnswerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          blankIndex == other.blankIndex &&
          _listEquals(acceptableAnswers, other.acceptableAnswers) &&
          isCaseSensitive == other.isCaseSensitive &&
          marks == other.marks &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        blankIndex,
        Object.hashAll(acceptableAnswers),
        isCaseSensitive,
        marks,
        createdAt,
      );

  @override
  String toString() =>
      'FillInBlankAnswerModel(id: $id, questionId: $questionId, blankIndex: $blankIndex)';
}

/// Data-layer representation of a question attachment.
class QuestionAttachmentModel {
  const QuestionAttachmentModel({
    required this.id,
    required this.questionId,
    required this.contentType,
    required this.url,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.altText,
    this.caption,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String contentType;
  final String url;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? altText;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionAttachmentModel.fromJson(Map<String, dynamic> json) {
    return QuestionAttachmentModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      contentType: json['content_type'] as String? ?? json['contentType'] as String? ?? 'image',
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      fileName: json['file_name'] as String? ?? json['fileName'] as String?,
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int?,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      altText: json['alt_text'] as String? ?? json['altText'] as String?,
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
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
      'question_id': questionId,
      'content_type': contentType,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'alt_text': altText,
      'caption': caption,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionAttachmentModel.fromEntity(QuestionAttachmentEntity entity) {
    return QuestionAttachmentModel(
      id: entity.id,
      questionId: entity.questionId,
      contentType: entity.contentType,
      url: entity.url,
      thumbnailUrl: entity.thumbnailUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      altText: entity.altText,
      caption: entity.caption,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
    );
  }

  QuestionAttachmentEntity toEntity() {
    return QuestionAttachmentEntity(
      id: id,
      questionId: questionId,
      contentType: contentType,
      url: url,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      altText: altText,
      caption: caption,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionAttachmentModel copyWith({
    String? id,
    String? questionId,
    String? contentType,
    String? url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? altText,
    String? caption,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return QuestionAttachmentModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      contentType: contentType ?? this.contentType,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      altText: altText ?? this.altText,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAttachmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          contentType == other.contentType &&
          url == other.url &&
          thumbnailUrl == other.thumbnailUrl &&
          fileName == other.fileName &&
          fileSize == other.fileSize &&
          mimeType == other.mimeType &&
          altText == other.altText &&
          caption == other.caption &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        contentType,
        url,
        thumbnailUrl,
        fileName,
        fileSize,
        mimeType,
        altText,
        caption,
        sortOrder,
        createdAt,
      );

  @override
  String toString() =>
      'QuestionAttachmentModel(id: $id, contentType: $contentType)';
}

/// Data-layer representation of a question tag.
class QuestionTagModel {
  const QuestionTagModel({
    required this.id,
    required this.name,
    this.schoolId,
    this.usageCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? schoolId;
  final int usageCount;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionTagModel.fromJson(Map<String, dynamic> json) {
    return QuestionTagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      usageCount: json['usage_count'] as int? ?? json['usageCount'] as int? ?? 0,
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
      'name': name,
      'school_id': schoolId,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionTagModel.fromEntity(QuestionTagEntity entity) {
    return QuestionTagModel(
      id: entity.id,
      name: entity.name,
      schoolId: entity.schoolId,
      usageCount: entity.usageCount,
      createdAt: entity.createdAt,
    );
  }

  QuestionTagEntity toEntity() {
    return QuestionTagEntity(
      id: id,
      name: name,
      schoolId: schoolId,
      usageCount: usageCount,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionTagModel copyWith({
    String? id,
    String? name,
    String? schoolId,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return QuestionTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionTagModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          schoolId == other.schoolId &&
          usageCount == other.usageCount &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        schoolId,
        usageCount,
        createdAt,
      );

  @override
  String toString() => 'QuestionTagModel(id: $id, name: $name)';
}

/// Data-layer representation of a question collection.
class QuestionCollectionModel {
  const QuestionCollectionModel({
    required this.id,
    required this.name,
    this.description,
    this.schoolId,
    this.createdBy,
    this.isShared = false,
    this.isOfficial = false,
    this.questionCount = 0,
    this.coverImageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? schoolId;
  final String? createdBy;
  final bool isShared;
  final bool isOfficial;
  final int questionCount;
  final String? coverImageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionCollectionModel.fromJson(Map<String, dynamic> json) {
    return QuestionCollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      isShared: json['is_shared'] as bool? ?? json['isShared'] as bool? ?? false,
      isOfficial: json['is_official'] as bool? ?? json['isOfficial'] as bool? ?? false,
      questionCount: json['question_count'] as int? ?? json['questionCount'] as int? ?? 0,
      coverImageUrl: json['cover_image_url'] as String? ?? json['coverImageUrl'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
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
      'name': name,
      'description': description,
      'school_id': schoolId,
      'created_by': createdBy,
      'is_shared': isShared,
      'is_official': isOfficial,
      'question_count': questionCount,
      'cover_image_url': coverImageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionCollectionModel.fromEntity(QuestionCollectionEntity entity) {
    return QuestionCollectionModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      schoolId: entity.schoolId,
      createdBy: entity.createdBy,
      isShared: entity.isShared,
      isOfficial: entity.isOfficial,
      questionCount: entity.questionCount,
      coverImageUrl: entity.coverImageUrl,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  QuestionCollectionEntity toEntity() {
    return QuestionCollectionEntity(
      id: id,
      name: name,
      description: description,
      schoolId: schoolId,
      createdBy: createdBy,
      isShared: isShared,
      isOfficial: isOfficial,
      questionCount: questionCount,
      coverImageUrl: coverImageUrl,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionCollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? schoolId,
    String? createdBy,
    bool? isShared,
    bool? isOfficial,
    int? questionCount,
    String? coverImageUrl,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      isShared: isShared ?? this.isShared,
      isOfficial: isOfficial ?? this.isOfficial,
      questionCount: questionCount ?? this.questionCount,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionCollectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          schoolId == other.schoolId &&
          createdBy == other.createdBy &&
          isShared == other.isShared &&
          isOfficial == other.isOfficial &&
          questionCount == other.questionCount &&
          coverImageUrl == other.coverImageUrl &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        schoolId,
        createdBy,
        isShared,
        isOfficial,
        questionCount,
        coverImageUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'QuestionCollectionModel(id: $id, name: $name)';
}

/// Data-layer representation of a question share record.
class QuestionShareModel {
  const QuestionShareModel({
    required this.id,
    required this.questionId,
    required this.sharedBy,
    required this.sharedWith,
    this.permission = 'read',
    this.message,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String sharedBy;
  final String sharedWith;
  final String permission;
  final String? message;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionShareModel.fromJson(Map<String, dynamic> json) {
    return QuestionShareModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      sharedBy: json['shared_by'] as String? ?? json['sharedBy'] as String? ?? '',
      sharedWith: json['shared_with'] as String? ?? json['sharedWith'] as String? ?? '',
      permission: json['permission'] as String? ?? 'read',
      message: json['message'] as String?,
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
      'question_id': questionId,
      'shared_by': sharedBy,
      'shared_with': sharedWith,
      'permission': permission,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionShareModel.fromEntity(QuestionShareEntity entity) {
    return QuestionShareModel(
      id: entity.id,
      questionId: entity.questionId,
      sharedBy: entity.sharedBy,
      sharedWith: entity.sharedWith,
      permission: entity.permission,
      message: entity.message,
      createdAt: entity.createdAt,
    );
  }

  QuestionShareEntity toEntity() {
    return QuestionShareEntity(
      id: id,
      questionId: questionId,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      permission: permission,
      message: message,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionShareModel copyWith({
    String? id,
    String? questionId,
    String? sharedBy,
    String? sharedWith,
    String? permission,
    String? message,
    DateTime? createdAt,
  }) {
    return QuestionShareModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedWith: sharedWith ?? this.sharedWith,
      permission: permission ?? this.permission,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionShareModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          sharedBy == other.sharedBy &&
          sharedWith == other.sharedWith &&
          permission == other.permission &&
          message == other.message &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        sharedBy,
        sharedWith,
        permission,
        message,
        createdAt,
      );

  @override
  String toString() =>
      'QuestionShareModel(id: $id, questionId: $questionId, permission: $permission)';
}

/// Data-layer representation of an import job.
class QuestionImportModel {
  const QuestionImportModel({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.source,
    this.fileName,
    this.fileUrl,
    this.totalQuestions = 0,
    this.importedCount = 0,
    this.failedCount = 0,
    this.status = 'pending',
    this.errors,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String schoolId;
  final String createdBy;
  final String source;
  final String? fileName;
  final String? fileUrl;
  final int totalQuestions;
  final int importedCount;
  final int failedCount;
  final String status;
  final List<Map<String, dynamic>>? errors;
  final DateTime createdAt;
  final DateTime? completedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionImportModel.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['error_log'] ?? json['errors'];
    List<Map<String, dynamic>>? parsedErrors;
    if (rawErrors is List) {
      parsedErrors = rawErrors
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    }

    return QuestionImportModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      createdBy: json['uploaded_by'] as String? ?? json['createdBy'] as String? ?? '',
      source: json['import_format'] as String? ?? json['source'] as String? ?? 'csv',
      fileName: json['file_name'] as String? ?? json['fileName'] as String?,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String?,
      totalQuestions: json['total_questions'] as int? ?? json['totalQuestions'] as int? ?? 0,
      importedCount: json['imported_count'] as int? ?? json['importedCount'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? json['failedCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      errors: parsedErrors,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'uploaded_by': createdBy,
      'import_format': source,
      'file_name': fileName,
      'file_url': fileUrl,
      'total_questions': totalQuestions,
      'imported_count': importedCount,
      'failed_count': failedCount,
      'status': status,
      'error_log': errors,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionImportModel.fromEntity(QuestionImportEntity entity) {
    return QuestionImportModel(
      id: entity.id,
      schoolId: entity.schoolId,
      createdBy: entity.createdBy,
      source: entity.source,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      totalQuestions: entity.totalQuestions,
      importedCount: entity.importedCount,
      failedCount: entity.failedCount,
      status: entity.status,
      errors: entity.errors,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
    );
  }

  QuestionImportEntity toEntity() {
    return QuestionImportEntity(
      id: id,
      schoolId: schoolId,
      createdBy: createdBy,
      source: source,
      fileName: fileName,
      fileUrl: fileUrl,
      totalQuestions: totalQuestions,
      importedCount: importedCount,
      failedCount: failedCount,
      status: status,
      errors: errors,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionImportModel copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? source,
    String? fileName,
    String? fileUrl,
    int? totalQuestions,
    int? importedCount,
    int? failedCount,
    String? status,
    List<Map<String, dynamic>>? errors,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return QuestionImportModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      source: source ?? this.source,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      importedCount: importedCount ?? this.importedCount,
      failedCount: failedCount ?? this.failedCount,
      status: status ?? this.status,
      errors: errors ?? this.errors,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionImportModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          createdBy == other.createdBy &&
          source == other.source &&
          fileName == other.fileName &&
          fileUrl == other.fileUrl &&
          totalQuestions == other.totalQuestions &&
          importedCount == other.importedCount &&
          failedCount == other.failedCount &&
          status == other.status &&
          createdAt == other.createdAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        createdBy,
        source,
        fileName,
        fileUrl,
        totalQuestions,
        importedCount,
        failedCount,
        status,
        createdAt,
        completedAt,
      );

  @override
  String toString() =>
      'QuestionImportModel(id: $id, status: $status, source: $source)';
}

/// Data-layer representation of an export job.
class QuestionExportModel {
  const QuestionExportModel({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.format,
    this.filter,
    this.totalQuestions = 0,
    this.exportedCount = 0,
    this.status = 'pending',
    this.fileUrl,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String schoolId;
  final String createdBy;
  final String format;
  final QuestionFilterModel? filter;
  final int totalQuestions;
  final int exportedCount;
  final String status;
  final String? fileUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionExportModel.fromJson(Map<String, dynamic> json) {
    final rawFilter = json['filters'] ?? json['filter'];
    QuestionFilterModel? parsedFilter;
    if (rawFilter is Map<String, dynamic>) {
      parsedFilter = QuestionFilterModel.fromJson(rawFilter);
    }

    return QuestionExportModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      createdBy: json['exported_by'] as String? ?? json['createdBy'] as String? ?? '',
      format: json['export_format'] as String? ?? json['format'] as String? ?? 'json',
      filter: parsedFilter,
      totalQuestions: json['total_questions'] as int? ?? json['totalQuestions'] as int? ?? 0,
      exportedCount: json['exported_count'] as int? ?? json['exportedCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String?,
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'exported_by': createdBy,
      'export_format': format,
      'filters': filter?.toJson(),
      'total_questions': totalQuestions,
      'exported_count': exportedCount,
      'status': status,
      'file_url': fileUrl,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionExportModel.fromEntity(QuestionExportEntity entity) {
    return QuestionExportModel(
      id: entity.id,
      schoolId: entity.schoolId,
      createdBy: entity.createdBy,
      format: entity.format,
      filter: entity.filter != null
          ? QuestionFilterModel.fromEntity(entity.filter!)
          : null,
      totalQuestions: entity.totalQuestions,
      exportedCount: entity.exportedCount,
      status: entity.status,
      fileUrl: entity.fileUrl,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
    );
  }

  QuestionExportEntity toEntity() {
    return QuestionExportEntity(
      id: id,
      schoolId: schoolId,
      createdBy: createdBy,
      format: format,
      filter: filter?.toEntity(),
      totalQuestions: totalQuestions,
      exportedCount: exportedCount,
      status: status,
      fileUrl: fileUrl,
      errorMessage: errorMessage,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionExportModel copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? format,
    QuestionFilterModel? filter,
    int? totalQuestions,
    int? exportedCount,
    String? status,
    String? fileUrl,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return QuestionExportModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      format: format ?? this.format,
      filter: filter ?? this.filter,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      exportedCount: exportedCount ?? this.exportedCount,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionExportModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          createdBy == other.createdBy &&
          format == other.format &&
          filter == other.filter &&
          totalQuestions == other.totalQuestions &&
          exportedCount == other.exportedCount &&
          status == other.status &&
          fileUrl == other.fileUrl &&
          errorMessage == other.errorMessage &&
          createdAt == other.createdAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        createdBy,
        format,
        filter,
        totalQuestions,
        exportedCount,
        status,
        fileUrl,
        errorMessage,
        createdAt,
        completedAt,
      );

  @override
  String toString() =>
      'QuestionExportModel(id: $id, status: $status, format: $format)';
}

/// Data-layer representation of a question version snapshot.
class QuestionVersionModel {
  const QuestionVersionModel({
    required this.id,
    required this.questionId,
    required this.version,
    required this.content,
    this.contentJson,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final int version;
  final String content;
  final Map<String, dynamic>? contentJson;
  final String createdBy;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionVersionModel.fromJson(Map<String, dynamic> json) {
    // In the DB, the snapshot column holds the full question JSON.
    // We extract content/contentJson from it if not directly available.
    final snapshot = json['snapshot'] as Map<String, dynamic>?;

    return QuestionVersionModel(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      content: json['content'] as String? ??
          snapshot?['content'] as String? ??
          '',
      contentJson: json['content_json'] as Map<String, dynamic>? ??
          json['contentJson'] as Map<String, dynamic>? ??
          snapshot?['content_json'] as Map<String, dynamic>? ??
          snapshot?['contentJson'] as Map<String, dynamic>?,
      createdBy: json['changed_by'] as String? ??
          json['created_by'] as String? ??
          json['createdBy'] as String? ??
          '',
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
      'question_id': questionId,
      'version': version,
      'snapshot': {
        'content': content,
        'content_json': contentJson,
      },
      'changed_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionVersionModel.fromEntity(QuestionVersionEntity entity) {
    return QuestionVersionModel(
      id: entity.id,
      questionId: entity.questionId,
      version: entity.version,
      content: entity.content,
      contentJson: entity.contentJson,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  QuestionVersionEntity toEntity() {
    return QuestionVersionEntity(
      id: id,
      questionId: questionId,
      version: version,
      content: content,
      contentJson: contentJson,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionVersionModel copyWith({
    String? id,
    String? questionId,
    int? version,
    String? content,
    Map<String, dynamic>? contentJson,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return QuestionVersionModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      version: version ?? this.version,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionVersionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          questionId == other.questionId &&
          version == other.version &&
          content == other.content &&
          contentJson == other.contentJson &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        questionId,
        version,
        content,
        contentJson,
        createdBy,
        createdAt,
      );

  @override
  String toString() =>
      'QuestionVersionModel(id: $id, questionId: $questionId, version: $version)';
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of the central question entity.
class QuestionModel {
  const QuestionModel({
    required this.id,
    this.schoolId,
    required this.subjectId,
    this.topicId,
    this.subtopicId,
    this.classId,
    this.categoryId,
    this.curriculumStandardId,
    this.academicSessionId,
    required this.questionType,
    required this.difficulty,
    this.examType,
    required this.content,
    this.contentJson,
    this.explanation,
    this.teacherNotes,
    this.referenceMaterials,
    this.marks = 0.0,
    this.negativeMarks = 0.0,
    this.timeAllowedSeconds,
    this.isPublished = false,
    this.isArchived = false,
    this.isFeatured = false,
    this.version = 1,
    this.parentId,
    this.createdBy,
    this.updatedBy,
    this.usageCount = 0,
    this.avgScore = 0.0,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.answerOptions = const [],
    this.matchingPairs = const [],
    this.orderingItems = const [],
    this.fillInBlankAnswers = const [],
    this.attachments = const [],
    this.tags = const [],
  });

  final String id;
  final String? schoolId;
  final String subjectId;
  final String? topicId;
  final String? subtopicId;
  final String? classId;
  final String? categoryId;
  final String? curriculumStandardId;
  final String? academicSessionId;
  final String questionType;
  final String difficulty;
  final String? examType;
  final String content;
  final Map<String, dynamic>? contentJson;
  final String? explanation;
  final String? teacherNotes;
  final String? referenceMaterials;
  final double marks;
  final double negativeMarks;
  final int? timeAllowedSeconds;
  final bool isPublished;
  final bool isArchived;
  final bool isFeatured;
  final int version;
  final String? parentId;
  final String? createdBy;
  final String? updatedBy;
  final int usageCount;
  final double avgScore;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AnswerOptionModel> answerOptions;
  final List<MatchingPairModel> matchingPairs;
  final List<OrderingItemModel> orderingItems;
  final List<FillInBlankAnswerModel> fillInBlankAnswers;
  final List<QuestionAttachmentModel> attachments;
  final List<QuestionTagModel> tags;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse nested answer options
    final rawOptions = json['answer_options'] ?? json['answerOptions'];
    final List<AnswerOptionModel> options = rawOptions is List
        ? rawOptions
            .map((e) =>
                AnswerOptionModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <AnswerOptionModel>[];

    // Parse nested matching pairs
    final rawPairs = json['matching_pairs'] ?? json['matchingPairs'];
    final List<MatchingPairModel> pairs = rawPairs is List
        ? rawPairs
            .map((e) =>
                MatchingPairModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <MatchingPairModel>[];

    // Parse nested ordering items
    final rawItems = json['ordering_items'] ?? json['orderingItems'];
    final List<OrderingItemModel> items = rawItems is List
        ? rawItems
            .map((e) =>
                OrderingItemModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <OrderingItemModel>[];

    // Parse nested fill-in-blank answers
    final rawFiba =
        json['fill_in_blank_answers'] ?? json['fillInBlankAnswers'];
    final List<FillInBlankAnswerModel> fiba = rawFiba is List
        ? rawFiba
            .map((e) =>
                FillInBlankAnswerModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <FillInBlankAnswerModel>[];

    // Parse nested attachments
    final rawAttachments =
        json['question_attachments'] ?? json['attachments'];
    final List<QuestionAttachmentModel> att = rawAttachments is List
        ? rawAttachments
            .map((e) =>
                QuestionAttachmentModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <QuestionAttachmentModel>[];

    // Parse nested tags (from join table or embedded)
    final rawTags = json['question_tags'] ?? json['tags'];
    final List<QuestionTagModel> tagList = rawTags is List
        ? rawTags
            .map((e) =>
                QuestionTagModel.fromJson(e as Map<String, dynamic>),)
            .toList()
        : <QuestionTagModel>[];

    return QuestionModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? json['topicId'] as String?,
      subtopicId: json['subtopic_id'] as String? ?? json['subtopicId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      categoryId: json['category_id'] as String? ?? json['categoryId'] as String?,
      curriculumStandardId: json['curriculum_standard_id'] as String? ??
          json['curriculumStandardId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      questionType: json['question_type'] as String? ??
          json['questionType'] as String? ??
          'multiple_choice',
      difficulty:
          json['difficulty'] as String? ?? 'medium',
      examType: json['exam_type'] as String? ?? json['examType'] as String?,
      content: json['content'] as String,
      contentJson: json['content_json'] as Map<String, dynamic>? ??
          json['contentJson'] as Map<String, dynamic>?,
      explanation: json['explanation'] as String?,
      teacherNotes: json['teacher_notes'] as String? ??
          json['teacherNotes'] as String?,
      referenceMaterials: json['reference_materials'] as String? ??
          json['referenceMaterials'] as String?,
      marks: (json['marks'] as num?)?.toDouble() ?? 0.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 0.0,
      timeAllowedSeconds: json['time_allowed_seconds'] as int? ??
          json['timeAllowedSeconds'] as int?,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      isFeatured: json['is_featured'] as bool? ??
          json['isFeatured'] as bool? ??
          false,
      version: json['version'] as int? ?? 1,
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      updatedBy: json['updated_by'] as String? ?? json['updatedBy'] as String?,
      usageCount: json['usage_count'] as int? ?? json['usageCount'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ??
          (json['avgScore'] as num?)?.toDouble() ??
          0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
      answerOptions: options,
      matchingPairs: pairs,
      orderingItems: items,
      fillInBlankAnswers: fiba,
      attachments: att,
      tags: tagList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'subject_id': subjectId,
      'topic_id': topicId,
      'subtopic_id': subtopicId,
      'class_id': classId,
      'category_id': categoryId,
      'curriculum_standard_id': curriculumStandardId,
      'academic_session_id': academicSessionId,
      'question_type': questionType,
      'difficulty': difficulty,
      'exam_type': examType,
      'content': content,
      'content_json': contentJson,
      'explanation': explanation,
      'teacher_notes': teacherNotes,
      'reference_materials': referenceMaterials,
      'marks': marks,
      'negative_marks': negativeMarks,
      'time_allowed_seconds': timeAllowedSeconds,
      'is_published': isPublished,
      'is_archived': isArchived,
      'is_featured': isFeatured,
      'version': version,
      'parent_id': parentId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'usage_count': usageCount,
      'avg_score': avgScore,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionModel.fromEntity(QuestionEntity entity) {
    return QuestionModel(
      id: entity.id,
      schoolId: entity.schoolId,
      subjectId: entity.subjectId,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      classId: entity.classId,
      categoryId: entity.categoryId,
      curriculumStandardId: entity.curriculumStandardId,
      academicSessionId: entity.academicSessionId,
      questionType: entity.questionType.value,
      difficulty: entity.difficulty.value,
      examType: entity.examType?.value,
      content: entity.content,
      contentJson: entity.contentJson,
      explanation: entity.explanation,
      teacherNotes: entity.teacherNotes,
      referenceMaterials: entity.referenceMaterials,
      marks: entity.marks,
      negativeMarks: entity.negativeMarks,
      timeAllowedSeconds: entity.timeAllowedSeconds,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      isFeatured: entity.isFeatured,
      version: entity.version,
      parentId: entity.parentId,
      createdBy: entity.createdBy,
      updatedBy: entity.updatedBy,
      usageCount: entity.usageCount,
      avgScore: entity.avgScore,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      answerOptions:
          entity.answerOptions.map(AnswerOptionModel.fromEntity).toList(),
      matchingPairs:
          entity.matchingPairs.map(MatchingPairModel.fromEntity).toList(),
      orderingItems:
          entity.orderingItems.map(OrderingItemModel.fromEntity).toList(),
      fillInBlankAnswers: entity.fillInBlankAnswers
          .map(FillInBlankAnswerModel.fromEntity)
          .toList(),
      attachments:
          entity.attachments.map(QuestionAttachmentModel.fromEntity).toList(),
      tags: entity.tags.map(QuestionTagModel.fromEntity).toList(),
    );
  }

  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      schoolId: schoolId,
      subjectId: subjectId,
      topicId: topicId,
      subtopicId: subtopicId,
      classId: classId,
      categoryId: categoryId,
      curriculumStandardId: curriculumStandardId,
      academicSessionId: academicSessionId,
      questionType: QuestionType.fromString(questionType) ??
          QuestionType.multipleChoice,
      difficulty:
          DifficultyLevel.fromString(difficulty) ?? DifficultyLevel.medium,
      examType: ExamType.fromString(examType),
      content: content,
      contentJson: contentJson,
      explanation: explanation,
      teacherNotes: teacherNotes,
      referenceMaterials: referenceMaterials,
      marks: marks,
      negativeMarks: negativeMarks,
      timeAllowedSeconds: timeAllowedSeconds,
      isPublished: isPublished,
      isArchived: isArchived,
      isFeatured: isFeatured,
      version: version,
      parentId: parentId,
      createdBy: createdBy,
      updatedBy: updatedBy,
      usageCount: usageCount,
      avgScore: avgScore,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      answerOptions: answerOptions.map((m) => m.toEntity()).toList(),
      matchingPairs: matchingPairs.map((m) => m.toEntity()).toList(),
      orderingItems: orderingItems.map((m) => m.toEntity()).toList(),
      fillInBlankAnswers:
          fillInBlankAnswers.map((m) => m.toEntity()).toList(),
      attachments: attachments.map((m) => m.toEntity()).toList(),
      tags: tags.map((m) => m.toEntity()).toList(),
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionModel copyWith({
    String? id,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classId,
    String? categoryId,
    String? curriculumStandardId,
    String? academicSessionId,
    String? questionType,
    String? difficulty,
    String? examType,
    String? content,
    Map<String, dynamic>? contentJson,
    String? explanation,
    String? teacherNotes,
    String? referenceMaterials,
    double? marks,
    double? negativeMarks,
    int? timeAllowedSeconds,
    bool? isPublished,
    bool? isArchived,
    bool? isFeatured,
    int? version,
    String? parentId,
    String? createdBy,
    String? updatedBy,
    int? usageCount,
    double? avgScore,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AnswerOptionModel>? answerOptions,
    List<MatchingPairModel>? matchingPairs,
    List<OrderingItemModel>? orderingItems,
    List<FillInBlankAnswerModel>? fillInBlankAnswers,
    List<QuestionAttachmentModel>? attachments,
    List<QuestionTagModel>? tags,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      classId: classId ?? this.classId,
      categoryId: categoryId ?? this.categoryId,
      curriculumStandardId: curriculumStandardId ?? this.curriculumStandardId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      examType: examType ?? this.examType,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      explanation: explanation ?? this.explanation,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      referenceMaterials: referenceMaterials ?? this.referenceMaterials,
      marks: marks ?? this.marks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      timeAllowedSeconds: timeAllowedSeconds ?? this.timeAllowedSeconds,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      isFeatured: isFeatured ?? this.isFeatured,
      version: version ?? this.version,
      parentId: parentId ?? this.parentId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      usageCount: usageCount ?? this.usageCount,
      avgScore: avgScore ?? this.avgScore,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answerOptions: answerOptions ?? this.answerOptions,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      orderingItems: orderingItems ?? this.orderingItems,
      fillInBlankAnswers: fillInBlankAnswers ?? this.fillInBlankAnswers,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          subjectId == other.subjectId &&
          topicId == other.topicId &&
          subtopicId == other.subtopicId &&
          classId == other.classId &&
          categoryId == other.categoryId &&
          curriculumStandardId == other.curriculumStandardId &&
          academicSessionId == other.academicSessionId &&
          questionType == other.questionType &&
          difficulty == other.difficulty &&
          examType == other.examType &&
          content == other.content &&
          contentJson == other.contentJson &&
          explanation == other.explanation &&
          teacherNotes == other.teacherNotes &&
          referenceMaterials == other.referenceMaterials &&
          marks == other.marks &&
          negativeMarks == other.negativeMarks &&
          timeAllowedSeconds == other.timeAllowedSeconds &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          isFeatured == other.isFeatured &&
          version == other.version &&
          parentId == other.parentId &&
          createdBy == other.createdBy &&
          updatedBy == other.updatedBy &&
          usageCount == other.usageCount &&
          avgScore == other.avgScore &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        schoolId,
        subjectId,
        topicId,
        subtopicId,
        classId,
        categoryId,
        curriculumStandardId,
        academicSessionId,
        questionType,
        difficulty,
        examType,
        content,
        explanation,
        marks,
        negativeMarks,
        isPublished,
        isArchived,
        isFeatured,
        version,
        createdBy,
        usageCount,
        avgScore,
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'QuestionModel(id: $id, type: $questionType, difficulty: $difficulty)';
}

// ═══════════════════════════════════════════════════════════════════════
// FILTER & STATS MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of question filter criteria for API queries.
class QuestionFilterModel {
  const QuestionFilterModel({
    this.subjectId,
    this.topicId,
    this.subtopicId,
    this.classId,
    this.categoryId,
    this.difficulty,
    this.questionType,
    this.examType,
    this.academicSessionId,
    this.isPublished,
    this.isArchived,
    this.isFeatured,
    this.createdBy,
    this.searchQuery,
    this.tags = const [],
    this.sortBy = 'newest',
    this.page = 1,
    this.perPage = 20,
  });

  final String? subjectId;
  final String? topicId;
  final String? subtopicId;
  final String? classId;
  final String? categoryId;
  final String? difficulty;
  final String? questionType;
  final String? examType;
  final String? academicSessionId;
  final bool? isPublished;
  final bool? isArchived;
  final bool? isFeatured;
  final String? createdBy;
  final String? searchQuery;
  final List<String> tags;
  final String sortBy;
  final int page;
  final int perPage;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionFilterModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final List<String> parsedTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    return QuestionFilterModel(
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      topicId: json['topic_id'] as String? ?? json['topicId'] as String?,
      subtopicId:
          json['subtopic_id'] as String? ?? json['subtopicId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      categoryId:
          json['category_id'] as String? ?? json['categoryId'] as String?,
      difficulty: json['difficulty'] as String?,
      questionType: json['question_type'] as String? ??
          json['questionType'] as String?,
      examType: json['exam_type'] as String? ?? json['examType'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      isPublished: json['is_published'] as bool? ?? json['isPublished'] as bool?,
      isArchived: json['is_archived'] as bool? ?? json['isArchived'] as bool?,
      isFeatured: json['is_featured'] as bool? ?? json['isFeatured'] as bool?,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String?,
      searchQuery: json['search_query'] as String? ??
          json['searchQuery'] as String?,
      tags: parsedTags,
      sortBy: json['sort_by'] as String? ?? json['sortBy'] as String? ?? 'newest',
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? json['perPage'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'topic_id': topicId,
      'subtopic_id': subtopicId,
      'class_id': classId,
      'category_id': categoryId,
      'difficulty': difficulty,
      'question_type': questionType,
      'exam_type': examType,
      'academic_session_id': academicSessionId,
      'is_published': isPublished,
      'is_archived': isArchived,
      'is_featured': isFeatured,
      'created_by': createdBy,
      'search_query': searchQuery,
      'tags': tags,
      'sort_by': sortBy,
      'page': page,
      'per_page': perPage,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionFilterModel.fromEntity(QuestionFilterEntity entity) {
    return QuestionFilterModel(
      subjectId: entity.subjectId,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      classId: entity.classId,
      categoryId: entity.categoryId,
      difficulty: entity.difficulty?.value,
      questionType: entity.questionType?.value,
      examType: entity.examType?.value,
      academicSessionId: entity.academicSessionId,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      isFeatured: entity.isFeatured,
      createdBy: entity.createdBy,
      searchQuery: entity.searchQuery,
      tags: entity.tags,
      sortBy: entity.sortBy,
      page: entity.page,
      perPage: entity.perPage,
    );
  }

  QuestionFilterEntity toEntity() {
    return QuestionFilterEntity(
      subjectId: subjectId,
      topicId: topicId,
      subtopicId: subtopicId,
      classId: classId,
      categoryId: categoryId,
      difficulty: DifficultyLevel.fromString(difficulty),
      questionType: QuestionType.fromString(questionType),
      examType: ExamType.fromString(examType),
      academicSessionId: academicSessionId,
      isPublished: isPublished,
      isArchived: isArchived,
      isFeatured: isFeatured,
      createdBy: createdBy,
      searchQuery: searchQuery,
      tags: tags,
      sortBy: sortBy,
      page: page,
      perPage: perPage,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionFilterModel copyWith({
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classId,
    String? categoryId,
    String? difficulty,
    String? questionType,
    String? examType,
    String? academicSessionId,
    bool? isPublished,
    bool? isArchived,
    bool? isFeatured,
    String? createdBy,
    String? searchQuery,
    List<String>? tags,
    String? sortBy,
    int? page,
    int? perPage,
  }) {
    return QuestionFilterModel(
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      classId: classId ?? this.classId,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      questionType: questionType ?? this.questionType,
      examType: examType ?? this.examType,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionFilterModel &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          topicId == other.topicId &&
          subtopicId == other.subtopicId &&
          classId == other.classId &&
          categoryId == other.categoryId &&
          difficulty == other.difficulty &&
          questionType == other.questionType &&
          examType == other.examType &&
          academicSessionId == other.academicSessionId &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          isFeatured == other.isFeatured &&
          createdBy == other.createdBy &&
          searchQuery == other.searchQuery &&
          _listEquals(tags, other.tags) &&
          sortBy == other.sortBy &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode => Object.hash(
        subjectId,
        topicId,
        subtopicId,
        classId,
        categoryId,
        difficulty,
        questionType,
        examType,
        academicSessionId,
        isPublished,
        isArchived,
        isFeatured,
        createdBy,
        searchQuery,
        Object.hashAll(tags),
        sortBy,
        page,
        perPage,
      );

  @override
  String toString() =>
      'QuestionFilterModel(subjectId: $subjectId, page: $page, perPage: $perPage)';
}

/// Data-layer representation of question bank statistics.
class QuestionBankStatsModel {
  const QuestionBankStatsModel({
    this.totalQuestions = 0,
    this.publishedQuestions = 0,
    this.draftQuestions = 0,
    this.archivedQuestions = 0,
    this.questionsBySubject = const {},
    this.questionsByDifficulty = const {},
    this.questionsByType = const {},
    this.questionsByExamType = const {},
    this.recentQuestions = 0,
    this.totalCollections = 0,
    this.totalFavorites = 0,
    this.mostUsedQuestions = const [],
  });

  final int totalQuestions;
  final int publishedQuestions;
  final int draftQuestions;
  final int archivedQuestions;
  final Map<String, int> questionsBySubject;
  final Map<String, int> questionsByDifficulty;
  final Map<String, int> questionsByType;
  final Map<String, int> questionsByExamType;
  final int recentQuestions;
  final int totalCollections;
  final int totalFavorites;
  final List<QuestionModel> mostUsedQuestions;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory QuestionBankStatsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseMap(dynamic raw) {
      if (raw is Map) {
        return raw.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
      }
      return <String, int>{};
    }

    final rawMostUsed = json['most_used_questions'] ?? json['mostUsedQuestions'];
    final List<QuestionModel> used = rawMostUsed is List
        ? rawMostUsed
            .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <QuestionModel>[];

    return QuestionBankStatsModel(
      totalQuestions: json['total_questions'] as int? ??
          json['totalQuestions'] as int? ??
          0,
      publishedQuestions: json['published_questions'] as int? ??
          json['publishedQuestions'] as int? ??
          0,
      draftQuestions: json['draft_questions'] as int? ??
          json['draftQuestions'] as int? ??
          0,
      archivedQuestions: json['archived_questions'] as int? ??
          json['archivedQuestions'] as int? ??
          0,
      questionsBySubject:
          parseMap(json['questions_by_subject'] ?? json['questionsBySubject']),
      questionsByDifficulty: parseMap(
          json['questions_by_difficulty'] ?? json['questionsByDifficulty'],),
      questionsByType:
          parseMap(json['questions_by_type'] ?? json['questionsByType']),
      questionsByExamType: parseMap(
          json['questions_by_exam_type'] ?? json['questionsByExamType'],),
      recentQuestions: json['recent_questions'] as int? ??
          json['recentQuestions'] as int? ??
          0,
      totalCollections: json['total_collections'] as int? ??
          json['totalCollections'] as int? ??
          0,
      totalFavorites: json['total_favorites'] as int? ??
          json['totalFavorites'] as int? ??
          0,
      mostUsedQuestions: used,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_questions': totalQuestions,
      'published_questions': publishedQuestions,
      'draft_questions': draftQuestions,
      'archived_questions': archivedQuestions,
      'questions_by_subject': questionsBySubject,
      'questions_by_difficulty': questionsByDifficulty,
      'questions_by_type': questionsByType,
      'questions_by_exam_type': questionsByExamType,
      'recent_questions': recentQuestions,
      'total_collections': totalCollections,
      'total_favorites': totalFavorites,
      'most_used_questions':
          mostUsedQuestions.map((q) => q.toJson()).toList(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory QuestionBankStatsModel.fromEntity(QuestionBankStatsEntity entity) {
    return QuestionBankStatsModel(
      totalQuestions: entity.totalQuestions,
      publishedQuestions: entity.publishedQuestions,
      draftQuestions: entity.draftQuestions,
      archivedQuestions: entity.archivedQuestions,
      questionsBySubject: entity.questionsBySubject,
      questionsByDifficulty: entity.questionsByDifficulty,
      questionsByType: entity.questionsByType,
      questionsByExamType: entity.questionsByExamType,
      recentQuestions: entity.recentQuestions,
      totalCollections: entity.totalCollections,
      totalFavorites: entity.totalFavorites,
      mostUsedQuestions:
          entity.mostUsedQuestions.map(QuestionModel.fromEntity).toList(),
    );
  }

  QuestionBankStatsEntity toEntity() {
    return QuestionBankStatsEntity(
      totalQuestions: totalQuestions,
      publishedQuestions: publishedQuestions,
      draftQuestions: draftQuestions,
      archivedQuestions: archivedQuestions,
      questionsBySubject: questionsBySubject,
      questionsByDifficulty: questionsByDifficulty,
      questionsByType: questionsByType,
      questionsByExamType: questionsByExamType,
      recentQuestions: recentQuestions,
      totalCollections: totalCollections,
      totalFavorites: totalFavorites,
      mostUsedQuestions: mostUsedQuestions.map((m) => m.toEntity()).toList(),
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  QuestionBankStatsModel copyWith({
    int? totalQuestions,
    int? publishedQuestions,
    int? draftQuestions,
    int? archivedQuestions,
    Map<String, int>? questionsBySubject,
    Map<String, int>? questionsByDifficulty,
    Map<String, int>? questionsByType,
    Map<String, int>? questionsByExamType,
    int? recentQuestions,
    int? totalCollections,
    int? totalFavorites,
    List<QuestionModel>? mostUsedQuestions,
  }) {
    return QuestionBankStatsModel(
      totalQuestions: totalQuestions ?? this.totalQuestions,
      publishedQuestions: publishedQuestions ?? this.publishedQuestions,
      draftQuestions: draftQuestions ?? this.draftQuestions,
      archivedQuestions: archivedQuestions ?? this.archivedQuestions,
      questionsBySubject: questionsBySubject ?? this.questionsBySubject,
      questionsByDifficulty:
          questionsByDifficulty ?? this.questionsByDifficulty,
      questionsByType: questionsByType ?? this.questionsByType,
      questionsByExamType: questionsByExamType ?? this.questionsByExamType,
      recentQuestions: recentQuestions ?? this.recentQuestions,
      totalCollections: totalCollections ?? this.totalCollections,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      mostUsedQuestions: mostUsedQuestions ?? this.mostUsedQuestions,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionBankStatsModel &&
          runtimeType == other.runtimeType &&
          totalQuestions == other.totalQuestions &&
          publishedQuestions == other.publishedQuestions &&
          draftQuestions == other.draftQuestions &&
          archivedQuestions == other.archivedQuestions &&
          _mapEquals(questionsBySubject, other.questionsBySubject) &&
          _mapEquals(questionsByDifficulty, other.questionsByDifficulty) &&
          _mapEquals(questionsByType, other.questionsByType) &&
          _mapEquals(questionsByExamType, other.questionsByExamType) &&
          recentQuestions == other.recentQuestions &&
          totalCollections == other.totalCollections &&
          totalFavorites == other.totalFavorites;

  @override
  int get hashCode => Object.hash(
        totalQuestions,
        publishedQuestions,
        draftQuestions,
        archivedQuestions,
        recentQuestions,
        totalCollections,
        totalFavorites,
      );

  @override
  String toString() =>
      'QuestionBankStatsModel(total: $totalQuestions, published: $publishedQuestions)';
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}
