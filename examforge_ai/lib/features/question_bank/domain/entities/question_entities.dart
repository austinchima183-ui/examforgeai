import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the type of a question.
///
/// Each type carries metadata about whether it has options, a correct
/// answer, and supports partial marking — useful for UI rendering and
/// validation rules.
enum QuestionType {
  multipleChoice(
    value: 'multiple_choice',
    label: 'Multiple Choice',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  multipleResponse(
    value: 'multiple_response',
    label: 'Multiple Response',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: true,
  ),
  trueFalse(
    value: 'true_false',
    label: 'True / False',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  fillInBlank(
    value: 'fill_in_blank',
    label: 'Fill in the Blank',
    hasOptions: false,
    hasCorrectAnswer: true,
    supportsPartialMarks: true,
  ),
  matching(
    value: 'matching',
    label: 'Matching',
    hasOptions: false,
    hasCorrectAnswer: true,
    supportsPartialMarks: true,
  ),
  ordering(
    value: 'ordering',
    label: 'Ordering',
    hasOptions: false,
    hasCorrectAnswer: true,
    supportsPartialMarks: true,
  ),
  shortAnswer(
    value: 'short_answer',
    label: 'Short Answer',
    hasOptions: false,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  essay(
    value: 'essay',
    label: 'Essay',
    hasOptions: false,
    hasCorrectAnswer: false,
    supportsPartialMarks: true,
  ),
  numerical(
    value: 'numerical',
    label: 'Numerical',
    hasOptions: false,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  imageBased(
    value: 'image_based',
    label: 'Image Based',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  audioBased(
    value: 'audio_based',
    label: 'Audio Based',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  videoBased(
    value: 'video_based',
    label: 'Video Based',
    hasOptions: true,
    hasCorrectAnswer: true,
    supportsPartialMarks: false,
  ),
  practical(
    value: 'practical',
    label: 'Practical',
    hasOptions: false,
    hasCorrectAnswer: false,
    supportsPartialMarks: true,
  ),
  caseStudy(
    value: 'case_study',
    label: 'Case Study',
    hasOptions: false,
    hasCorrectAnswer: false,
    supportsPartialMarks: true,
  );

  const QuestionType({
    required this.value,
    required this.label,
    required this.hasOptions,
    required this.hasCorrectAnswer,
    required this.supportsPartialMarks,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Whether this question type uses answer options (A, B, C, D…).
  final bool hasOptions;

  /// Whether this question type has a single correct answer.
  final bool hasCorrectAnswer;

  /// Whether partial marks can be awarded for partially correct answers.
  final bool supportsPartialMarks;

  /// Parses a raw [value] string into a [QuestionType].
  ///
  /// Returns `null` if the value does not match any known type.
  static QuestionType? fromString(String? value) {
    if (value == null) return null;
    return QuestionType.values.cast<QuestionType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }

  /// All question type values as a list.
  static List<QuestionType> get valuesList => QuestionType.values;
}

/// Represents the difficulty level of a question.
enum DifficultyLevel {
  easy(
    value: 'easy',
    label: 'Easy',
    color: '#22C55E',
  ),
  medium(
    value: 'medium',
    label: 'Medium',
    color: '#F59E0B',
  ),
  hard(
    value: 'hard',
    label: 'Hard',
    color: '#EF4444',
  ),
  expert(
    value: 'expert',
    label: 'Expert',
    color: '#7C3AED',
  );

  const DifficultyLevel({
    required this.value,
    required this.label,
    required this.color,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Hex color string for UI rendering.
  final String color;

  /// Parses a raw [value] string into a [DifficultyLevel].
  ///
  /// Returns `null` if the value does not match any known level.
  static DifficultyLevel? fromString(String? value) {
    if (value == null) return null;
    return DifficultyLevel.values.cast<DifficultyLevel?>().firstWhere(
          (level) => level?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the exam type a question is associated with.
enum ExamType {
  waec(
    value: 'waec',
    label: 'WAEC',
  ),
  neco(
    value: 'neco',
    label: 'NECO',
  ),
  jamb(
    value: 'jamb',
    label: 'JAMB',
  ),
  schoolExam(
    value: 'school_exam',
    label: 'School Exam',
  ),
  mock(
    value: 'mock',
    label: 'Mock Exam',
  ),
  practice(
    value: 'practice',
    label: 'Practice',
  ),
  custom(
    value: 'custom',
    label: 'Custom',
  );

  const ExamType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [ExamType].
  ///
  /// Returns `null` if the value does not match any known type.
  static ExamType? fromString(String? value) {
    if (value == null) return null;
    return ExamType.values.cast<ExamType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTING ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a topic within a subject.
class TopicEntity extends Equatable {
  const TopicEntity({
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

  TopicEntity copyWith({
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
    return TopicEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a subtopic within a topic.
class SubtopicEntity extends Equatable {
  const SubtopicEntity({
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

  SubtopicEntity copyWith({
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
    return SubtopicEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a category for organizing questions.
class QuestionCategoryEntity extends Equatable {
  const QuestionCategoryEntity({
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

  QuestionCategoryEntity copyWith({
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
    return QuestionCategoryEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents an academic session (term / year).
class AcademicSessionEntity extends Equatable {
  const AcademicSessionEntity({
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

  AcademicSessionEntity copyWith({
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
    return AcademicSessionEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a single answer option for a question.
class AnswerOptionEntity extends Equatable {
  const AnswerOptionEntity({
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

  AnswerOptionEntity copyWith({
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
    return AnswerOptionEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a matching pair in a matching-type question.
class MatchingPairEntity extends Equatable {
  const MatchingPairEntity({
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

  MatchingPairEntity copyWith({
    String? id,
    String? questionId,
    String? leftContent,
    String? rightContent,
    String? leftMediaUrl,
    String? rightMediaUrl,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return MatchingPairEntity(
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

  @override
  List<Object?> get props => [
        id,
        questionId,
        leftContent,
        rightContent,
        leftMediaUrl,
        rightMediaUrl,
        sortOrder,
        createdAt,
      ];
}

/// Represents an ordering item in an ordering-type question.
class OrderingItemEntity extends Equatable {
  const OrderingItemEntity({
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

  OrderingItemEntity copyWith({
    String? id,
    String? questionId,
    String? content,
    int? correctPosition,
    String? mediaUrl,
    DateTime? createdAt,
  }) {
    return OrderingItemEntity(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      content: content ?? this.content,
      correctPosition: correctPosition ?? this.correctPosition,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        content,
        correctPosition,
        mediaUrl,
        createdAt,
      ];
}

/// Represents a fill-in-the-blank answer entry.
class FillInBlankAnswerEntity extends Equatable {
  const FillInBlankAnswerEntity({
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

  FillInBlankAnswerEntity copyWith({
    String? id,
    String? questionId,
    int? blankIndex,
    List<String>? acceptableAnswers,
    bool? isCaseSensitive,
    double? marks,
    DateTime? createdAt,
  }) {
    return FillInBlankAnswerEntity(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      blankIndex: blankIndex ?? this.blankIndex,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      marks: marks ?? this.marks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        blankIndex,
        acceptableAnswers,
        isCaseSensitive,
        marks,
        createdAt,
      ];
}

/// Represents an attachment (image, audio, video, document) on a question.
class QuestionAttachmentEntity extends Equatable {
  const QuestionAttachmentEntity({
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

  /// One of: 'image', 'audio', 'video', 'document'.
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

  QuestionAttachmentEntity copyWith({
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
    return QuestionAttachmentEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a tag that can be applied to questions.
class QuestionTagEntity extends Equatable {
  const QuestionTagEntity({
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

  QuestionTagEntity copyWith({
    String? id,
    String? name,
    String? schoolId,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return QuestionTagEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        schoolId,
        usageCount,
        createdAt,
      ];
}

/// Represents a collection of questions (like a playlist or folder).
class QuestionCollectionEntity extends Equatable {
  const QuestionCollectionEntity({
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

  QuestionCollectionEntity copyWith({
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
    return QuestionCollectionEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a question sharing record.
class QuestionShareEntity extends Equatable {
  const QuestionShareEntity({
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

  /// One of: 'read', 'edit', 'admin'.
  final String permission;
  final String? message;
  final DateTime createdAt;

  QuestionShareEntity copyWith({
    String? id,
    String? questionId,
    String? sharedBy,
    String? sharedWith,
    String? permission,
    String? message,
    DateTime? createdAt,
  }) {
    return QuestionShareEntity(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedWith: sharedWith ?? this.sharedWith,
      permission: permission ?? this.permission,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        sharedBy,
        sharedWith,
        permission,
        message,
        createdAt,
      ];
}

/// Represents an import job for bulk question upload.
class QuestionImportEntity extends Equatable {
  const QuestionImportEntity({
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

  /// One of: 'csv', 'excel', 'json', 'word'.
  final String source;
  final String? fileName;
  final String? fileUrl;
  final int totalQuestions;
  final int importedCount;
  final int failedCount;

  /// One of: 'pending', 'processing', 'completed', 'failed'.
  final String status;
  final List<Map<String, dynamic>>? errors;
  final DateTime createdAt;
  final DateTime? completedAt;

  QuestionImportEntity copyWith({
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
    return QuestionImportEntity(
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

  @override
  List<Object?> get props => [
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
        errors,
        createdAt,
        completedAt,
      ];
}

/// Represents an export job for bulk question download.
class QuestionExportEntity extends Equatable {
  const QuestionExportEntity({
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

  /// One of: 'csv', 'excel', 'json', 'pdf'.
  final String format;
  final QuestionFilterEntity? filter;
  final int totalQuestions;
  final int exportedCount;

  /// One of: 'pending', 'processing', 'completed', 'failed'.
  final String status;
  final String? fileUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  QuestionExportEntity copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? format,
    QuestionFilterEntity? filter,
    int? totalQuestions,
    int? exportedCount,
    String? status,
    String? fileUrl,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return QuestionExportEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a version snapshot of a question.
class QuestionVersionEntity extends Equatable {
  const QuestionVersionEntity({
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

  QuestionVersionEntity copyWith({
    String? id,
    String? questionId,
    int? version,
    String? content,
    Map<String, dynamic>? contentJson,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return QuestionVersionEntity(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      version: version ?? this.version,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        version,
        content,
        contentJson,
        createdBy,
        createdAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN ENTITY
// ═══════════════════════════════════════════════════════════════════════

/// The central question entity for the question bank module.
///
/// Contains all core question data, type/difficulty/exam classification,
/// publishing state, and relational child entities for answers, matching
/// pairs, ordering items, fill-in-blank answers, attachments, and tags.
class QuestionEntity extends Equatable {
  const QuestionEntity({
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

  // ── Identifiers ─────────────────────────────────────────────────────
  final String id;
  final String? schoolId;
  final String subjectId;
  final String? topicId;
  final String? subtopicId;
  final String? classId;
  final String? categoryId;
  final String? curriculumStandardId;
  final String? academicSessionId;

  // ── Classification ──────────────────────────────────────────────────
  final QuestionType questionType;
  final DifficultyLevel difficulty;
  final ExamType? examType;

  // ── Content ─────────────────────────────────────────────────────────
  final String content;
  final Map<String, dynamic>? contentJson;
  final String? explanation;
  final String? teacherNotes;
  final String? referenceMaterials;

  // ── Scoring & Timing ────────────────────────────────────────────────
  final double marks;
  final double negativeMarks;
  final int? timeAllowedSeconds;

  // ── Status ──────────────────────────────────────────────────────────
  final bool isPublished;
  final bool isArchived;
  final bool isFeatured;

  // ── Versioning ──────────────────────────────────────────────────────
  final int version;
  final String? parentId;

  // ── Audit ───────────────────────────────────────────────────────────
  final String? createdBy;
  final String? updatedBy;

  // ── Usage Metrics ───────────────────────────────────────────────────
  final int usageCount;
  final double avgScore;

  // ── Extensibility ───────────────────────────────────────────────────
  final Map<String, dynamic>? metadata;

  // ── Timestamps ──────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Relations (not persisted, used for display) ─────────────────────
  final List<AnswerOptionEntity> answerOptions;
  final List<MatchingPairEntity> matchingPairs;
  final List<OrderingItemEntity> orderingItems;
  final List<FillInBlankAnswerEntity> fillInBlankAnswers;
  final List<QuestionAttachmentEntity> attachments;
  final List<QuestionTagEntity> tags;

  QuestionEntity copyWith({
    String? id,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classId,
    String? categoryId,
    String? curriculumStandardId,
    String? academicSessionId,
    QuestionType? questionType,
    DifficultyLevel? difficulty,
    ExamType? examType,
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
    List<AnswerOptionEntity>? answerOptions,
    List<MatchingPairEntity>? matchingPairs,
    List<OrderingItemEntity>? orderingItems,
    List<FillInBlankAnswerEntity>? fillInBlankAnswers,
    List<QuestionAttachmentEntity>? attachments,
    List<QuestionTagEntity>? tags,
  }) {
    return QuestionEntity(
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

  @override
  List<Object?> get props => [
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
        contentJson,
        explanation,
        teacherNotes,
        referenceMaterials,
        marks,
        negativeMarks,
        timeAllowedSeconds,
        isPublished,
        isArchived,
        isFeatured,
        version,
        parentId,
        createdBy,
        updatedBy,
        usageCount,
        avgScore,
        metadata,
        createdAt,
        updatedAt,
        answerOptions,
        matchingPairs,
        orderingItems,
        fillInBlankAnswers,
        attachments,
        tags,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// FILTER & STATS ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// Encapsulates filter criteria for querying questions.
class QuestionFilterEntity extends Equatable {
  const QuestionFilterEntity({
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
  final DifficultyLevel? difficulty;
  final QuestionType? questionType;
  final ExamType? examType;
  final String? academicSessionId;
  final bool? isPublished;
  final bool? isArchived;
  final bool? isFeatured;
  final String? createdBy;
  final String? searchQuery;
  final List<String> tags;

  /// One of: 'newest', 'oldest', 'most_used', 'least_used',
  /// 'highest_rated', 'a_z', 'z_a'.
  final String sortBy;
  final int page;
  final int perPage;

  QuestionFilterEntity copyWith({
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classId,
    String? categoryId,
    DifficultyLevel? difficulty,
    QuestionType? questionType,
    ExamType? examType,
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
    return QuestionFilterEntity(
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

  @override
  List<Object?> get props => [
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
        tags,
        sortBy,
        page,
        perPage,
      ];
}

/// Aggregated statistics for the question bank dashboard.
class QuestionBankStatsEntity extends Equatable {
  const QuestionBankStatsEntity({
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

  /// Questions created in the last 7 days.
  final int recentQuestions;
  final int totalCollections;
  final int totalFavorites;

  /// Top 5 most-used questions.
  final List<QuestionEntity> mostUsedQuestions;

  QuestionBankStatsEntity copyWith({
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
    List<QuestionEntity>? mostUsedQuestions,
  }) {
    return QuestionBankStatsEntity(
      totalQuestions: totalQuestions ?? this.totalQuestions,
      publishedQuestions: publishedQuestions ?? this.publishedQuestions,
      draftQuestions: draftQuestions ?? this.draftQuestions,
      archivedQuestions: archivedQuestions ?? this.archivedQuestions,
      questionsBySubject: questionsBySubject ?? this.questionsBySubject,
      questionsByDifficulty: questionsByDifficulty ?? this.questionsByDifficulty,
      questionsByType: questionsByType ?? this.questionsByType,
      questionsByExamType: questionsByExamType ?? this.questionsByExamType,
      recentQuestions: recentQuestions ?? this.recentQuestions,
      totalCollections: totalCollections ?? this.totalCollections,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      mostUsedQuestions: mostUsedQuestions ?? this.mostUsedQuestions,
    );
  }

  @override
  List<Object?> get props => [
        totalQuestions,
        publishedQuestions,
        draftQuestions,
        archivedQuestions,
        questionsBySubject,
        questionsByDifficulty,
        questionsByType,
        questionsByExamType,
        recentQuestions,
        totalCollections,
        totalFavorites,
        mostUsedQuestions,
      ];
}
