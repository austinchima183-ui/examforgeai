import '../../domain/entities/student_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI TUTOR MODELS
// ═══════════════════════════════════════════════════════════════════════

class AiTutorConversationModel {
  final String id;
  final String? schoolId;
  final String studentId;
  final String title;
  final String? subjectId;
  final String? topic;
  final String curriculumType;
  final bool isArchived;
  final String? lastMessage;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiTutorConversationModel({
    required this.id,
    this.schoolId,
    required this.studentId,
    this.title = 'New Conversation',
    this.subjectId,
    this.topic,
    this.curriculumType = 'nigerian',
    this.isArchived = false,
    this.lastMessage,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiTutorConversationModel.fromJson(Map<String, dynamic> json) =>
      AiTutorConversationModel(
        id: json['id'] as String,
        schoolId: json['school_id'] as String?,
        studentId: json['student_id'] as String,
        title: json['title'] as String? ?? 'New Conversation',
        subjectId: json['subject_id'] as String?,
        topic: json['topic'] as String?,
        curriculumType: json['curriculum_type'] as String? ?? 'nigerian',
        isArchived: json['is_archived'] as bool? ?? false,
        lastMessage: json['last_message'] as String?,
        messageCount: json['message_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'school_id': schoolId,
        'student_id': studentId,
        'title': title,
        'subject_id': subjectId,
        'topic': topic,
        'curriculum_type': curriculumType,
        'is_archived': isArchived,
      };

  AiTutorConversationEntity toEntity() => AiTutorConversationEntity(
        id: id,
        schoolId: schoolId,
        studentId: studentId,
        title: title,
        subjectId: subjectId,
        topic: topic,
        curriculumType: curriculumType,
        isArchived: isArchived,
        lastMessage: lastMessage,
        messageCount: messageCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class AiTutorMessageModel {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AiTutorMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.metadata = const {},
    required this.createdAt,
  });

  factory AiTutorMessageModel.fromJson(Map<String, dynamic> json) =>
      AiTutorMessageModel(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'metadata': metadata,
      };

  AiTutorMessageEntity toEntity() => AiTutorMessageEntity(
        id: id,
        conversationId: conversationId,
        role: TutorMessageRole.fromString(role) ?? TutorMessageRole.user,
        content: content,
        metadata: metadata,
        createdAt: createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE SESSION MODELS
// ═══════════════════════════════════════════════════════════════════════

class PracticeSessionModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String? subjectId;
  final String? topicId;
  final String difficulty;
  final String mode;
  final int? timeLimitSec;
  final int totalQuestions;
  final int correctCount;
  final double scorePct;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? subjectName;
  final String? topicName;

  const PracticeSessionModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.subjectId,
    this.topicId,
    this.difficulty = 'medium',
    this.mode = 'untimed',
    this.timeLimitSec,
    this.totalQuestions = 0,
    this.correctCount = 0,
    this.scorePct = 0,
    this.status = 'in_progress',
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.subjectName,
    this.topicName,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) =>
      PracticeSessionModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        subjectId: json['subject_id'] as String?,
        topicId: json['topic_id'] as String?,
        difficulty: json['difficulty'] as String? ?? 'medium',
        mode: json['mode'] as String? ?? 'untimed',
        timeLimitSec: json['time_limit_sec'] as int?,
        totalQuestions: json['total_questions'] as int? ?? 0,
        correctCount: json['correct_count'] as int? ?? 0,
        scorePct: (json['score_pct'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'in_progress',
        startedAt: DateTime.parse(json['started_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        subjectName: json['subject_name'] as String?,
        topicName: json['topic_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'school_id': schoolId,
        'subject_id': subjectId,
        'topic_id': topicId,
        'difficulty': difficulty,
        'mode': mode,
        'time_limit_sec': timeLimitSec,
        'total_questions': totalQuestions,
      };

  PracticeSessionEntity toEntity() => PracticeSessionEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        difficulty: difficulty,
        mode: PracticeMode.fromString(mode) ?? PracticeMode.untimed,
        timeLimitSec: timeLimitSec,
        totalQuestions: totalQuestions,
        correctCount: correctCount,
        scorePct: scorePct,
        status: PracticeSessionStatus.fromString(status) ??
            PracticeSessionStatus.inProgress,
        startedAt: startedAt,
        completedAt: completedAt,
        createdAt: createdAt,
        subjectName: subjectName,
        topicName: topicName,
      );
}

class PracticeAnswerModel {
  final String id;
  final String sessionId;
  final String questionId;
  final Map<String, dynamic> studentAnswer;
  final bool? isCorrect;
  final int timeSpentSec;
  final DateTime createdAt;

  const PracticeAnswerModel({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.studentAnswer,
    this.isCorrect,
    this.timeSpentSec = 0,
    required this.createdAt,
  });

  factory PracticeAnswerModel.fromJson(Map<String, dynamic> json) =>
      PracticeAnswerModel(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        questionId: json['question_id'] as String,
        studentAnswer: json['student_answer'] as Map<String, dynamic>? ?? {},
        isCorrect: json['is_correct'] as bool?,
        timeSpentSec: json['time_spent_sec'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'question_id': questionId,
        'student_answer': studentAnswer,
        'is_correct': isCorrect,
        'time_spent_sec': timeSpentSec,
      };

  PracticeAnswerEntity toEntity() => PracticeAnswerEntity(
        id: id,
        sessionId: sessionId,
        questionId: questionId,
        studentAnswer: studentAnswer,
        isCorrect: isCorrect,
        timeSpentSec: timeSpentSec,
        createdAt: createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT SUBMISSION MODELS
// ═══════════════════════════════════════════════════════════════════════

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? schoolId;
  final Map<String, dynamic> content;
  final List<Map<String, dynamic>> attachments;
  final String status;
  final double? score;
  final double? maxScore;
  final String? teacherFeedback;
  final Map<String, dynamic>? aiFeedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignmentTitle;
  final String? subjectName;
  final DateTime? dueDate;
  final String? teacherName;

  const AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.schoolId,
    this.content = const {},
    this.attachments = const [],
    this.status = 'draft',
    this.score,
    this.maxScore,
    this.teacherFeedback,
    this.aiFeedback,
    this.submittedAt,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignmentTitle,
    this.subjectName,
    this.dueDate,
    this.teacherName,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) =>
      AssignmentSubmissionModel(
        id: json['id'] as String,
        assignmentId: json['assignment_id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        content: json['content'] as Map<String, dynamic>? ?? {},
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        status: json['status'] as String? ?? 'draft',
        score: (json['score'] as num?)?.toDouble(),
        maxScore: (json['max_score'] as num?)?.toDouble(),
        teacherFeedback: json['teacher_feedback'] as String?,
        aiFeedback: json['ai_feedback'] as Map<String, dynamic>?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        gradedAt: json['graded_at'] != null
            ? DateTime.parse(json['graded_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        assignmentTitle: json['assignment_title'] as String?,
        subjectName: json['subject_name'] as String?,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        teacherName: json['teacher_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'assignment_id': assignmentId,
        'student_id': studentId,
        'school_id': schoolId,
        'content': content,
        'attachments': attachments,
        'status': status,
      };

  AssignmentSubmissionEntity toEntity() => AssignmentSubmissionEntity(
        id: id,
        assignmentId: assignmentId,
        studentId: studentId,
        schoolId: schoolId,
        content: content,
        attachments: attachments
            .map((a) => AttachmentInfo(
                  filename: a['filename'] as String? ?? '',
                  url: a['url'] as String? ?? '',
                  size: a['size'] as int?,
                  type: a['type'] as String?,
                ),)
            .toList(),
        status: SubmissionStatus.fromString(status) ?? SubmissionStatus.draft,
        score: score,
        maxScore: maxScore,
        teacherFeedback: teacherFeedback,
        aiFeedback: aiFeedback,
        submittedAt: submittedAt,
        gradedAt: gradedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        assignmentTitle: assignmentTitle,
        subjectName: subjectName,
        dueDate: dueDate,
        teacherName: teacherName,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// LEARNING RESOURCE MODEL
// ═══════════════════════════════════════════════════════════════════════

class LearningResourceModel {
  final String id;
  final String? schoolId;
  final String? subjectId;
  final String? topicId;
  final String title;
  final String? description;
  final String resourceType;
  final String? fileUrl;
  final int? fileSize;
  final String? fileFormat;
  final String? content;
  final String? thumbnailUrl;
  final String? teacherId;
  final bool isDownloadable;
  final bool isPublic;
  final List<String> tags;
  final int viewCount;
  final int downloadCount;
  final String curriculumType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectName;
  final String? teacherName;

  const LearningResourceModel({
    required this.id,
    this.schoolId,
    this.subjectId,
    this.topicId,
    required this.title,
    this.description,
    this.resourceType = 'lesson_note',
    this.fileUrl,
    this.fileSize,
    this.fileFormat,
    this.content,
    this.thumbnailUrl,
    this.teacherId,
    this.isDownloadable = true,
    this.isPublic = false,
    this.tags = const [],
    this.viewCount = 0,
    this.downloadCount = 0,
    this.curriculumType = 'nigerian',
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.teacherName,
  });

  factory LearningResourceModel.fromJson(Map<String, dynamic> json) =>
      LearningResourceModel(
        id: json['id'] as String,
        schoolId: json['school_id'] as String?,
        subjectId: json['subject_id'] as String?,
        topicId: json['topic_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        resourceType: json['resource_type'] as String? ?? 'lesson_note',
        fileUrl: json['file_url'] as String?,
        fileSize: json['file_size'] as int?,
        fileFormat: json['file_format'] as String?,
        content: json['content'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        teacherId: json['teacher_id'] as String?,
        isDownloadable: json['is_downloadable'] as bool? ?? true,
        isPublic: json['is_public'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        viewCount: json['view_count'] as int? ?? 0,
        downloadCount: json['download_count'] as int? ?? 0,
        curriculumType: json['curriculum_type'] as String? ?? 'nigerian',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        subjectName: json['subject_name'] as String?,
        teacherName: json['teacher_name'] as String?,
      );

  LearningResourceEntity toEntity() => LearningResourceEntity(
        id: id,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        title: title,
        description: description,
        resourceType: StudentResourceType.fromString(resourceType) ??
            StudentResourceType.lessonNote,
        fileUrl: fileUrl,
        fileSize: fileSize,
        fileFormat: fileFormat,
        content: content,
        thumbnailUrl: thumbnailUrl,
        teacherId: teacherId,
        isDownloadable: isDownloadable,
        isPublic: isPublic,
        tags: tags,
        viewCount: viewCount,
        downloadCount: downloadCount,
        curriculumType: curriculumType,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
        teacherName: teacherName,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CHAT MODELS
// ═══════════════════════════════════════════════════════════════════════

class DocumentChatModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String fileFormat;
  final String? extractedText;
  final String? summary;
  final String? flashcardDeckId;
  final String status;
  final int? pageCount;
  final int? wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentChatModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    required this.fileFormat,
    this.extractedText,
    this.summary,
    this.flashcardDeckId,
    this.status = 'processing',
    this.pageCount,
    this.wordCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentChatModel.fromJson(Map<String, dynamic> json) =>
      DocumentChatModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        fileName: json['file_name'] as String,
        fileUrl: json['file_url'] as String,
        fileSize: json['file_size'] as int?,
        fileFormat: json['file_format'] as String,
        extractedText: json['extracted_text'] as String?,
        summary: json['summary'] as String?,
        flashcardDeckId: json['flashcard_deck_id'] as String?,
        status: json['status'] as String? ?? 'processing',
        pageCount: json['page_count'] as int?,
        wordCount: json['word_count'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'school_id': schoolId,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_format': fileFormat,
        'file_size': fileSize,
      };

  DocumentChatEntity toEntity({
    List<DocumentChatMessageEntity> messages = const [],
  }) =>
      DocumentChatEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileSize: fileSize,
        fileFormat: fileFormat,
        extractedText: extractedText,
        summary: summary,
        flashcardDeckId: flashcardDeckId,
        status: DocumentChatStatus.fromString(status) ??
            DocumentChatStatus.processing,
        pageCount: pageCount,
        wordCount: wordCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: messages,
      );
}

class DocumentChatMessageModel {
  final String id;
  final String documentId;
  final String role;
  final String content;
  final int? pageReference;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const DocumentChatMessageModel({
    required this.id,
    required this.documentId,
    required this.role,
    required this.content,
    this.pageReference,
    this.metadata = const {},
    required this.createdAt,
  });

  factory DocumentChatMessageModel.fromJson(Map<String, dynamic> json) =>
      DocumentChatMessageModel(
        id: json['id'] as String,
        documentId: json['document_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        pageReference: json['page_reference'] as int?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'role': role,
        'content': content,
        'page_reference': pageReference,
        'metadata': metadata,
      };

  DocumentChatMessageEntity toEntity() => DocumentChatMessageEntity(
        id: id,
        documentId: documentId,
        role: TutorMessageRole.fromString(role) ?? TutorMessageRole.user,
        content: content,
        pageReference: pageReference,
        metadata: metadata,
        createdAt: createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD MODELS
// ═══════════════════════════════════════════════════════════════════════

class FlashcardDeckModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String? subjectId;
  final String? topicId;
  final String title;
  final String? description;
  final String sourceType;
  final String? sourceId;
  final int cardCount;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectName;
  final int dueCount;

  const FlashcardDeckModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.subjectId,
    this.topicId,
    required this.title,
    this.description,
    this.sourceType = 'manual',
    this.sourceId,
    this.cardCount = 0,
    this.isFavorite = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.dueCount = 0,
  });

  factory FlashcardDeckModel.fromJson(Map<String, dynamic> json) =>
      FlashcardDeckModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        subjectId: json['subject_id'] as String?,
        topicId: json['topic_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        sourceType: json['source_type'] as String? ?? 'manual',
        sourceId: json['source_id'] as String?,
        cardCount: json['card_count'] as int? ?? 0,
        isFavorite: json['is_favorite'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        subjectName: json['subject_name'] as String?,
        dueCount: json['due_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'school_id': schoolId,
        'subject_id': subjectId,
        'topic_id': topicId,
        'title': title,
        'description': description,
        'source_type': sourceType,
        'source_id': sourceId,
        'tags': tags,
      };

  FlashcardDeckEntity toEntity() => FlashcardDeckEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        title: title,
        description: description,
        sourceType: sourceType,
        sourceId: sourceId,
        cardCount: cardCount,
        isFavorite: isFavorite,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
        dueCount: dueCount,
      );
}

class FlashcardModel {
  final String id;
  final String deckId;
  final String frontContent;
  final String backContent;
  final String? hint;
  final String? imageUrl;
  final String difficulty;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;
  final String? lastRating;
  final int totalReviews;
  final int correctReviews;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.frontContent,
    required this.backContent,
    this.hint,
    this.imageUrl,
    this.difficulty = 'medium',
    this.easeFactor = 2.50,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.nextReviewAt,
    this.lastReviewedAt,
    this.lastRating,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
        id: json['id'] as String,
        deckId: json['deck_id'] as String,
        frontContent: json['front_content'] as String,
        backContent: json['back_content'] as String,
        hint: json['hint'] as String?,
        imageUrl: json['image_url'] as String?,
        difficulty: json['difficulty'] as String? ?? 'medium',
        easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.50,
        intervalDays: json['interval_days'] as int? ?? 0,
        repetitions: json['repetitions'] as int? ?? 0,
        nextReviewAt: DateTime.parse(json['next_review_at'] as String),
        lastReviewedAt: json['last_reviewed_at'] != null
            ? DateTime.parse(json['last_reviewed_at'] as String)
            : null,
        lastRating: json['last_rating'] as String?,
        totalReviews: json['total_reviews'] as int? ?? 0,
        correctReviews: json['correct_reviews'] as int? ?? 0,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'deck_id': deckId,
        'front_content': frontContent,
        'back_content': backContent,
        'hint': hint,
        'difficulty': difficulty,
      };

  FlashcardEntity toEntity() => FlashcardEntity(
        id: id,
        deckId: deckId,
        frontContent: frontContent,
        backContent: backContent,
        hint: hint,
        imageUrl: imageUrl,
        difficulty: difficulty,
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        repetitions: repetitions,
        nextReviewAt: nextReviewAt,
        lastReviewedAt: lastReviewedAt,
        lastRating: FlashcardRating.fromString(lastRating),
        totalReviews: totalReviews,
        correctReviews: correctReviews,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLAN & TASK MODELS
// ═══════════════════════════════════════════════════════════════════════

class StudyPlanModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String title;
  final String? description;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isAiSuggested;
  final String? aiSuggestionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPlanModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    required this.title,
    this.description,
    this.frequency = 'daily',
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isAiSuggested = false,
    this.aiSuggestionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudyPlanModel.fromJson(Map<String, dynamic> json) => StudyPlanModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        frequency: json['frequency'] as String? ?? 'daily',
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
        aiSuggestionReason: json['ai_suggestion_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'school_id': schoolId,
        'title': title,
        'description': description,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
      };

  StudyPlanEntity toEntity({List<StudyTaskEntity> tasks = const []}) =>
      StudyPlanEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        title: title,
        description: description,
        frequency: StudyPlanFrequency.fromString(frequency) ??
            StudyPlanFrequency.daily,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        isAiSuggested: isAiSuggested,
        aiSuggestionReason: aiSuggestionReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
        tasks: tasks,
      );
}

class StudyTaskModel {
  final String id;
  final String planId;
  final String? subjectId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final double completionPct;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectName;

  const StudyTaskModel({
    required this.id,
    required this.planId,
    this.subjectId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.status = 'pending',
    this.completionPct = 0,
    this.notes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
  });

  factory StudyTaskModel.fromJson(Map<String, dynamic> json) => StudyTaskModel(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        subjectId: json['subject_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        startTime: json['start_time'] != null
            ? DateTime.parse(json['start_time'] as String)
            : null,
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String)
            : null,
        status: json['status'] as String? ?? 'pending',
        completionPct: (json['completion_pct'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        subjectName: json['subject_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'subject_id': subjectId,
        'title': title,
        'description': description,
        'scheduled_date': scheduledDate.toIso8601String().split('T').first,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      };

  StudyTaskEntity toEntity() => StudyTaskEntity(
        id: id,
        planId: planId,
        subjectId: subjectId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
        status: StudyTaskStatus.fromString(status) ?? StudyTaskStatus.pending,
        completionPct: completionPct,
        notes: notes,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT GOAL MODEL
// ═══════════════════════════════════════════════════════════════════════

class StudentGoalModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String? subjectId;
  final String title;
  final String? description;
  final double? targetValue;
  final double currentValue;
  final String unit;
  final String priority;
  final String status;
  final DateTime? deadline;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subjectName;

  const StudentGoalModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.subjectId,
    required this.title,
    this.description,
    this.targetValue,
    this.currentValue = 0,
    this.unit = '%',
    this.priority = 'medium',
    this.status = 'not_started',
    this.deadline,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
  });

  factory StudentGoalModel.fromJson(Map<String, dynamic> json) =>
      StudentGoalModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        subjectId: json['subject_id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        targetValue: (json['target_value'] as num?)?.toDouble(),
        currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '%',
        priority: json['priority'] as String? ?? 'medium',
        status: json['status'] as String? ?? 'not_started',
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        subjectName: json['subject_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'school_id': schoolId,
        'subject_id': subjectId,
        'title': title,
        'description': description,
        'target_value': targetValue,
        'unit': unit,
        'priority': priority,
        'deadline': deadline?.toIso8601String().split('T').first,
      };

  StudentGoalEntity toEntity() => StudentGoalEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: currentValue,
        unit: unit,
        priority: GoalPriority.fromString(priority) ?? GoalPriority.medium,
        status: GoalStatus.fromString(status) ?? GoalStatus.notStarted,
        deadline: deadline,
        completedAt: completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT PROGRESS & NOTIFICATION MODELS
// ═══════════════════════════════════════════════════════════════════════

class StudentProgressModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? subjectId;
  final double? avgScore;
  final int examsTaken;
  final int practiceSessions;
  final int questionsAttempted;
  final int questionsCorrect;
  final int studyTimeMin;
  final int assignmentsCompleted;
  final int assignmentsPending;
  final int flashcardsReviewed;
  final int learningStreak;
  final List<Map<String, dynamic>> weakTopics;
  final List<Map<String, dynamic>> strongTopics;
  final List<Map<String, dynamic>> aiSuggestions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String? subjectName;

  const StudentProgressModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.period = 'weekly',
    required this.periodStart,
    required this.periodEnd,
    this.subjectId,
    this.avgScore,
    this.examsTaken = 0,
    this.practiceSessions = 0,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.studyTimeMin = 0,
    this.assignmentsCompleted = 0,
    this.assignmentsPending = 0,
    this.flashcardsReviewed = 0,
    this.learningStreak = 0,
    this.weakTopics = const [],
    this.strongTopics = const [],
    this.aiSuggestions = const [],
    this.metadata = const {},
    required this.createdAt,
    this.subjectName,
  });

  factory StudentProgressModel.fromJson(Map<String, dynamic> json) =>
      StudentProgressModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        period: json['period'] as String? ?? 'weekly',
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        subjectId: json['subject_id'] as String?,
        avgScore: (json['avg_score'] as num?)?.toDouble(),
        examsTaken: json['exams_taken'] as int? ?? 0,
        practiceSessions: json['practice_sessions'] as int? ?? 0,
        questionsAttempted: json['questions_attempted'] as int? ?? 0,
        questionsCorrect: json['questions_correct'] as int? ?? 0,
        studyTimeMin: json['study_time_min'] as int? ?? 0,
        assignmentsCompleted: json['assignments_completed'] as int? ?? 0,
        assignmentsPending: json['assignments_pending'] as int? ?? 0,
        flashcardsReviewed: json['flashcards_reviewed'] as int? ?? 0,
        learningStreak: json['learning_streak'] as int? ?? 0,
        weakTopics: (json['weak_topics'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        strongTopics: (json['strong_topics'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        aiSuggestions: (json['ai_suggestions'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        subjectName: json['subject_name'] as String?,
      );

  StudentProgressEntity toEntity() => StudentProgressEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        period: ProgressPeriod.fromString(period) ?? ProgressPeriod.weekly,
        periodStart: periodStart,
        periodEnd: periodEnd,
        subjectId: subjectId,
        avgScore: avgScore,
        examsTaken: examsTaken,
        practiceSessions: practiceSessions,
        questionsAttempted: questionsAttempted,
        questionsCorrect: questionsCorrect,
        studyTimeMin: studyTimeMin,
        assignmentsCompleted: assignmentsCompleted,
        assignmentsPending: assignmentsPending,
        flashcardsReviewed: flashcardsReviewed,
        learningStreak: learningStreak,
        weakTopics: weakTopics
            .map((t) => TopicScoreInfo(
                  topicId: t['topic_id'] as String? ?? '',
                  topicName: t['topic_name'] as String? ?? '',
                  scorePct: (t['score_pct'] as num?)?.toDouble() ?? 0,
                ),)
            .toList(),
        strongTopics: strongTopics
            .map((t) => TopicScoreInfo(
                  topicId: t['topic_id'] as String? ?? '',
                  topicName: t['topic_name'] as String? ?? '',
                  scorePct: (t['score_pct'] as num?)?.toDouble() ?? 0,
                ),)
            .toList(),
        aiSuggestions: aiSuggestions
            .map((s) => AiSuggestion(
                  type: s['type'] as String? ?? '',
                  message: s['message'] as String? ?? '',
                  actionLabel: s['action_label'] as String?,
                  actionUrl: s['action_url'] as String?,
                ),)
            .toList(),
        metadata: metadata,
        createdAt: createdAt,
        subjectName: subjectName,
      );
}

class StudentNotificationModel {
  final String id;
  final String studentId;
  final String? schoolId;
  final String type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final String? actionUrl;
  final DateTime? scheduledFor;
  final DateTime createdAt;

  const StudentNotificationModel({
    required this.id,
    required this.studentId,
    this.schoolId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    this.isRead = false,
    this.actionUrl,
    this.scheduledFor,
    required this.createdAt,
  });

  factory StudentNotificationModel.fromJson(Map<String, dynamic> json) =>
      StudentNotificationModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        schoolId: json['school_id'] as String?,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        relatedId: json['related_id'] as String?,
        relatedType: json['related_type'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        actionUrl: json['action_url'] as String?,
        scheduledFor: json['scheduled_for'] != null
            ? DateTime.parse(json['scheduled_for'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  StudentNotificationEntity toEntity() => StudentNotificationEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        type: StudentNotificationType.fromString(type) ??
            StudentNotificationType.teacherAnnouncement,
        title: title,
        message: message,
        relatedId: relatedId,
        relatedType: relatedType,
        isRead: isRead,
        actionUrl: actionUrl,
        scheduledFor: scheduledFor,
        createdAt: createdAt,
      );
}

class StudentDailyActivityModel {
  final String id;
  final String studentId;
  final DateTime activityDate;
  final int studyTimeMin;
  final int questionsAttempted;
  final int questionsCorrect;
  final int practiceSessions;
  final int flashcardsReviewed;
  final int assignmentsSubmitted;
  final int resourcesViewed;
  final int tutorQuestions;
  final bool isActiveDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentDailyActivityModel({
    required this.id,
    required this.studentId,
    required this.activityDate,
    this.studyTimeMin = 0,
    this.questionsAttempted = 0,
    this.questionsCorrect = 0,
    this.practiceSessions = 0,
    this.flashcardsReviewed = 0,
    this.assignmentsSubmitted = 0,
    this.resourcesViewed = 0,
    this.tutorQuestions = 0,
    this.isActiveDay = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentDailyActivityModel.fromJson(Map<String, dynamic> json) =>
      StudentDailyActivityModel(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        activityDate: DateTime.parse(json['activity_date'] as String),
        studyTimeMin: json['study_time_min'] as int? ?? 0,
        questionsAttempted: json['questions_attempted'] as int? ?? 0,
        questionsCorrect: json['questions_correct'] as int? ?? 0,
        practiceSessions: json['practice_sessions'] as int? ?? 0,
        flashcardsReviewed: json['flashcards_reviewed'] as int? ?? 0,
        assignmentsSubmitted: json['assignments_submitted'] as int? ?? 0,
        resourcesViewed: json['resources_viewed'] as int? ?? 0,
        tutorQuestions: json['tutor_questions'] as int? ?? 0,
        isActiveDay: json['is_active_day'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  StudentDailyActivityEntity toEntity() => StudentDailyActivityEntity(
        id: id,
        studentId: studentId,
        activityDate: activityDate,
        studyTimeMin: studyTimeMin,
        questionsAttempted: questionsAttempted,
        questionsCorrect: questionsCorrect,
        practiceSessions: practiceSessions,
        flashcardsReviewed: flashcardsReviewed,
        assignmentsSubmitted: assignmentsSubmitted,
        resourcesViewed: resourcesViewed,
        tutorQuestions: tutorQuestions,
        isActiveDay: isActiveDay,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// DASHBOARD STATS MODEL
// ═══════════════════════════════════════════════════════════════════════

class StudentDashboardStatsModel {
  final int upcomingExams;
  final int pendingAssignments;
  final int learningStreak;
  final double recentAvgScore;
  final int practiceThisWeek;
  final int unreadNotifications;
  final int completedExams;
  final int totalSubjects;
  final int studyTimeThisWeekMin;

  const StudentDashboardStatsModel({
    this.upcomingExams = 0,
    this.pendingAssignments = 0,
    this.learningStreak = 0,
    this.recentAvgScore = 0,
    this.practiceThisWeek = 0,
    this.unreadNotifications = 0,
    this.completedExams = 0,
    this.totalSubjects = 0,
    this.studyTimeThisWeekMin = 0,
  });

  factory StudentDashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      StudentDashboardStatsModel(
        upcomingExams: json['upcoming_exams'] as int? ?? 0,
        pendingAssignments: json['pending_assignments'] as int? ?? 0,
        learningStreak: json['learning_streak'] as int? ?? 0,
        recentAvgScore: (json['recent_avg_score'] as num?)?.toDouble() ?? 0,
        practiceThisWeek: json['practice_this_week'] as int? ?? 0,
        unreadNotifications: json['unread_notifications'] as int? ?? 0,
        completedExams: json['completed_exams'] as int? ?? 0,
        totalSubjects: json['total_subjects'] as int? ?? 0,
        studyTimeThisWeekMin: json['study_time_this_week_min'] as int? ?? 0,
      );

  StudentDashboardStats toEntity() => StudentDashboardStats(
        upcomingExams: upcomingExams,
        pendingAssignments: pendingAssignments,
        learningStreak: learningStreak,
        recentAvgScore: recentAvgScore,
        practiceThisWeek: practiceThisWeek,
        unreadNotifications: unreadNotifications,
        completedExams: completedExams,
        totalSubjects: totalSubjects,
        studyTimeThisWeekMin: studyTimeThisWeekMin,
      );
}
