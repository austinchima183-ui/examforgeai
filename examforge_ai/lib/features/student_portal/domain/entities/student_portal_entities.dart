import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Practice session mode: timed or untimed.
enum PracticeMode {
  timed(value: 'timed', label: 'Timed'),
  untimed(value: 'untimed', label: 'Untimed');

  const PracticeMode({required this.value, required this.label});
  final String value;
  final String label;

  static PracticeMode? fromString(String? value) {
    if (value == null) return null;
    return PracticeMode.values.cast<PracticeMode?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Practice session lifecycle status.
enum PracticeSessionStatus {
  inProgress(value: 'in_progress', label: 'In Progress'),
  completed(value: 'completed', label: 'Completed'),
  abandoned(value: 'abandoned', label: 'Abandoned');

  const PracticeSessionStatus({required this.value, required this.label});
  final String value;
  final String label;

  static PracticeSessionStatus? fromString(String? value) {
    if (value == null) return null;
    return PracticeSessionStatus.values.cast<PracticeSessionStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Assignment submission status.
enum SubmissionStatus {
  draft(value: 'draft', label: 'Draft'),
  submitted(value: 'submitted', label: 'Submitted'),
  lateSubmitted(value: 'late_submitted', label: 'Late Submitted'),
  graded(value: 'graded', label: 'Graded'),
  returned(value: 'returned', label: 'Returned'),
  resubmitted(value: 'resubmitted', label: 'Resubmitted');

  const SubmissionStatus({required this.value, required this.label});
  final String value;
  final String label;

  static SubmissionStatus? fromString(String? value) {
    if (value == null) return null;
    return SubmissionStatus.values.cast<SubmissionStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Learning resource type for the student portal.
enum StudentResourceType {
  lessonNote(value: 'lesson_note', label: 'Lesson Note'),
  worksheet(value: 'worksheet', label: 'Worksheet'),
  studyGuide(value: 'study_guide', label: 'Study Guide'),
  slide(value: 'slide', label: 'Slide'),
  handout(value: 'handout', label: 'Handout'),
  recommendedReading(value: 'recommended_reading', label: 'Recommended Reading'),
  videoLink(value: 'video_link', label: 'Video Link'),
  pastQuestion(value: 'past_question', label: 'Past Question');

  const StudentResourceType({required this.value, required this.label});
  final String value;
  final String label;

  static StudentResourceType? fromString(String? value) {
    if (value == null) return null;
    return StudentResourceType.values.cast<StudentResourceType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Document chat processing status.
enum DocumentChatStatus {
  processing(value: 'processing', label: 'Processing'),
  ready(value: 'ready', label: 'Ready'),
  failed(value: 'failed', label: 'Failed');

  const DocumentChatStatus({required this.value, required this.label});
  final String value;
  final String label;

  static DocumentChatStatus? fromString(String? value) {
    if (value == null) return null;
    return DocumentChatStatus.values.cast<DocumentChatStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Flashcard spaced repetition rating (SM-2 algorithm).
enum FlashcardRating {
  again(value: 'again', label: 'Again', intervalMult: 0.0),
  hard(value: 'hard', label: 'Hard', intervalMult: 1.2),
  good(value: 'good', label: 'Good', intervalMult: 2.5),
  easy(value: 'easy', label: 'Easy', intervalMult: 3.5);

  const FlashcardRating({
    required this.value,
    required this.label,
    required this.intervalMult,
  });
  final String value;
  final String label;
  final double intervalMult;

  static FlashcardRating? fromString(String? value) {
    if (value == null) return null;
    return FlashcardRating.values.cast<FlashcardRating?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Study plan frequency.
enum StudyPlanFrequency {
  daily(value: 'daily', label: 'Daily'),
  weekly(value: 'weekly', label: 'Weekly'),
  custom(value: 'custom', label: 'Custom');

  const StudyPlanFrequency({required this.value, required this.label});
  final String value;
  final String label;

  static StudyPlanFrequency? fromString(String? value) {
    if (value == null) return null;
    return StudyPlanFrequency.values.cast<StudyPlanFrequency?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Study task status.
enum StudyTaskStatus {
  pending(value: 'pending', label: 'Pending'),
  inProgress(value: 'in_progress', label: 'In Progress'),
  completed(value: 'completed', label: 'Completed'),
  skipped(value: 'skipped', label: 'Skipped');

  const StudyTaskStatus({required this.value, required this.label});
  final String value;
  final String label;

  static StudyTaskStatus? fromString(String? value) {
    if (value == null) return null;
    return StudyTaskStatus.values.cast<StudyTaskStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Goal priority level.
enum GoalPriority {
  low(value: 'low', label: 'Low'),
  medium(value: 'medium', label: 'Medium'),
  high(value: 'high', label: 'High'),
  urgent(value: 'urgent', label: 'Urgent');

  const GoalPriority({required this.value, required this.label});
  final String value;
  final String label;

  static GoalPriority? fromString(String? value) {
    if (value == null) return null;
    return GoalPriority.values.cast<GoalPriority?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Goal lifecycle status.
enum GoalStatus {
  notStarted(value: 'not_started', label: 'Not Started'),
  inProgress(value: 'in_progress', label: 'In Progress'),
  achieved(value: 'achieved', label: 'Achieved'),
  abandoned(value: 'abandoned', label: 'Abandoned');

  const GoalStatus({required this.value, required this.label});
  final String value;
  final String label;

  static GoalStatus? fromString(String? value) {
    if (value == null) return null;
    return GoalStatus.values.cast<GoalStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// AI Tutor message role.
enum TutorMessageRole {
  user(value: 'user', label: 'User'),
  assistant(value: 'assistant', label: 'Assistant'),
  system(value: 'system', label: 'System');

  const TutorMessageRole({required this.value, required this.label});
  final String value;
  final String label;

  static TutorMessageRole? fromString(String? value) {
    if (value == null) return null;
    return TutorMessageRole.values.cast<TutorMessageRole?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Progress snapshot period.
enum ProgressPeriod {
  daily(value: 'daily', label: 'Daily'),
  weekly(value: 'weekly', label: 'Weekly'),
  monthly(value: 'monthly', label: 'Monthly'),
  termly(value: 'termly', label: 'Termly'),
  annually(value: 'annually', label: 'Annually');

  const ProgressPeriod({required this.value, required this.label});
  final String value;
  final String label;

  static ProgressPeriod? fromString(String? value) {
    if (value == null) return null;
    return ProgressPeriod.values.cast<ProgressPeriod?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Notification type for student portal.
enum StudentNotificationType {
  newAssignment(value: 'new_assignment', label: 'New Assignment'),
  upcomingExam(value: 'upcoming_exam', label: 'Upcoming Exam'),
  resultPublished(value: 'result_published', label: 'Result Published'),
  teacherAnnouncement(value: 'teacher_announcement', label: 'Teacher Announcement'),
  studyReminder(value: 'study_reminder', label: 'Study Reminder'),
  deadlineApproaching(value: 'deadline_approaching', label: 'Deadline Approaching'),
  feedbackReceived(value: 'feedback_received', label: 'Feedback Received');

  const StudentNotificationType({required this.value, required this.label});
  final String value;
  final String label;

  static StudentNotificationType? fromString(String? value) {
    if (value == null) return null;
    return StudentNotificationType.values.cast<StudentNotificationType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a conversation in the AI Tutor.
class AiTutorConversationEntity extends Equatable {
  const AiTutorConversationEntity({
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

  AiTutorConversationEntity copyWith({
    String? title,
    String? subjectId,
    String? topic,
    String? curriculumType,
    bool? isArchived,
    String? lastMessage,
    int? messageCount,
    DateTime? updatedAt,
  }) =>
      AiTutorConversationEntity(
        id: id,
        schoolId: schoolId,
        studentId: studentId,
        title: title ?? this.title,
        subjectId: subjectId ?? this.subjectId,
        topic: topic ?? this.topic,
        curriculumType: curriculumType ?? this.curriculumType,
        isArchived: isArchived ?? this.isArchived,
        lastMessage: lastMessage ?? this.lastMessage,
        messageCount: messageCount ?? this.messageCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, studentId, title, isArchived, updatedAt];
}

/// Represents a single message in an AI Tutor conversation.
class AiTutorMessageEntity extends Equatable {
  const AiTutorMessageEntity({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final TutorMessageRole role;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, conversationId, role, content, createdAt];
}

/// Represents a practice session created by a student.
class PracticeSessionEntity extends Equatable {
  const PracticeSessionEntity({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.subjectId,
    this.topicId,
    this.difficulty = 'medium',
    this.mode = PracticeMode.untimed,
    this.timeLimitSec,
    this.totalQuestions = 0,
    this.correctCount = 0,
    this.scorePct = 0,
    this.status = PracticeSessionStatus.inProgress,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.subjectName,
    this.topicName,
    this.answers = const [],
  });

  final String id;
  final String studentId;
  final String? schoolId;
  final String? subjectId;
  final String? topicId;
  final String difficulty;
  final PracticeMode mode;
  final int? timeLimitSec;
  final int totalQuestions;
  final int correctCount;
  final double scorePct;
  final PracticeSessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? subjectName;
  final String? topicName;
  final List<PracticeAnswerEntity> answers;

  PracticeSessionEntity copyWith({
    int? totalQuestions,
    int? correctCount,
    double? scorePct,
    PracticeSessionStatus? status,
    DateTime? completedAt,
    List<PracticeAnswerEntity>? answers,
  }) =>
      PracticeSessionEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        difficulty: difficulty,
        mode: mode,
        timeLimitSec: timeLimitSec,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        correctCount: correctCount ?? this.correctCount,
        scorePct: scorePct ?? this.scorePct,
        status: status ?? this.status,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
        subjectName: subjectName,
        topicName: topicName,
        answers: answers ?? this.answers,
      );

  @override
  List<Object?> get props => [id, studentId, status, scorePct];
}

/// Represents a student's answer in a practice session.
class PracticeAnswerEntity extends Equatable {
  const PracticeAnswerEntity({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.studentAnswer,
    this.isCorrect,
    this.timeSpentSec = 0,
    required this.createdAt,
    this.questionText,
    this.correctAnswer,
    this.explanation,
  });

  final String id;
  final String sessionId;
  final String questionId;
  final Map<String, dynamic> studentAnswer;
  final bool? isCorrect;
  final int timeSpentSec;
  final DateTime createdAt;
  final String? questionText;
  final Map<String, dynamic>? correctAnswer;
  final String? explanation;

  @override
  List<Object?> get props => [id, sessionId, questionId];
}

/// Represents a student's assignment submission.
class AssignmentSubmissionEntity extends Equatable {
  const AssignmentSubmissionEntity({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.schoolId,
    this.content = const {},
    this.attachments = const [],
    this.status = SubmissionStatus.draft,
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

  final String id;
  final String assignmentId;
  final String studentId;
  final String? schoolId;
  final Map<String, dynamic> content;
  final List<AttachmentInfo> attachments;
  final SubmissionStatus status;
  final double? score;
  final double? maxScore;
  final String? teacherFeedback;
  final Map<String, dynamic>? aiFeedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? assignmentTitle;
  final String? subjectName;
  final DateTime? dueDate;
  final String? teacherName;

  AssignmentSubmissionEntity copyWith({
    Map<String, dynamic>? content,
    List<AttachmentInfo>? attachments,
    SubmissionStatus? status,
    double? score,
    double? maxScore,
    String? teacherFeedback,
    Map<String, dynamic>? aiFeedback,
    DateTime? submittedAt,
    DateTime? gradedAt,
  }) =>
      AssignmentSubmissionEntity(
        id: id,
        assignmentId: assignmentId,
        studentId: studentId,
        schoolId: schoolId,
        content: content ?? this.content,
        attachments: attachments ?? this.attachments,
        status: status ?? this.status,
        score: score ?? this.score,
        maxScore: maxScore ?? this.maxScore,
        teacherFeedback: teacherFeedback ?? this.teacherFeedback,
        aiFeedback: aiFeedback ?? this.aiFeedback,
        submittedAt: submittedAt ?? this.submittedAt,
        gradedAt: gradedAt ?? this.gradedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        assignmentTitle: assignmentTitle,
        subjectName: subjectName,
        dueDate: dueDate,
        teacherName: teacherName,
      );

  @override
  List<Object?> get props => [id, assignmentId, studentId, status];
}

/// Attachment information for submissions.
class AttachmentInfo extends Equatable {
  const AttachmentInfo({
    required this.filename,
    required this.url,
    this.size,
    this.type,
  });

  final String filename;
  final String url;
  final int? size;
  final String? type;

  @override
  List<Object?> get props => [filename, url];
}

/// Represents a learning resource accessible to students.
class LearningResourceEntity extends Equatable {
  const LearningResourceEntity({
    required this.id,
    this.schoolId,
    this.subjectId,
    this.topicId,
    required this.title,
    this.description,
    this.resourceType = StudentResourceType.lessonNote,
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

  final String id;
  final String? schoolId;
  final String? subjectId;
  final String? topicId;
  final String title;
  final String? description;
  final StudentResourceType resourceType;
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

  // Joined fields
  final String? subjectName;
  final String? teacherName;

  @override
  List<Object?> get props => [id, title, resourceType];
}

/// Represents a document uploaded for AI chat.
class DocumentChatEntity extends Equatable {
  const DocumentChatEntity({
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
    this.status = DocumentChatStatus.processing,
    this.pageCount,
    this.wordCount,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

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
  final DocumentChatStatus status;
  final int? pageCount;
  final int? wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DocumentChatMessageEntity> messages;

  DocumentChatEntity copyWith({
    String? extractedText,
    String? summary,
    String? flashcardDeckId,
    DocumentChatStatus? status,
    int? pageCount,
    int? wordCount,
    List<DocumentChatMessageEntity>? messages,
  }) =>
      DocumentChatEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileSize: fileSize,
        fileFormat: fileFormat,
        extractedText: extractedText ?? this.extractedText,
        summary: summary ?? this.summary,
        flashcardDeckId: flashcardDeckId ?? this.flashcardDeckId,
        status: status ?? this.status,
        pageCount: pageCount ?? this.pageCount,
        wordCount: wordCount ?? this.wordCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: messages ?? this.messages,
      );

  @override
  List<Object?> get props => [id, studentId, fileName, status];
}

/// Represents a message in a document chat.
class DocumentChatMessageEntity extends Equatable {
  const DocumentChatMessageEntity({
    required this.id,
    required this.documentId,
    required this.role,
    required this.content,
    this.pageReference,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String documentId;
  final TutorMessageRole role;
  final String content;
  final int? pageReference;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, documentId, role, content];
}

/// Represents a flashcard deck owned by a student.
class FlashcardDeckEntity extends Equatable {
  const FlashcardDeckEntity({
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

  // Joined / computed
  final String? subjectName;
  final int dueCount;

  FlashcardDeckEntity copyWith({
    String? title,
    String? description,
    int? cardCount,
    bool? isFavorite,
    List<String>? tags,
    int? dueCount,
  }) =>
      FlashcardDeckEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        title: title ?? this.title,
        description: description ?? this.description,
        sourceType: sourceType,
        sourceId: sourceId,
        cardCount: cardCount ?? this.cardCount,
        isFavorite: isFavorite ?? this.isFavorite,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
        dueCount: dueCount ?? this.dueCount,
      );

  @override
  List<Object?> get props => [id, studentId, title, cardCount, isFavorite];
}

/// Represents a single flashcard with spaced repetition data (SM-2).
class FlashcardEntity extends Equatable {
  const FlashcardEntity({
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
  final FlashcardRating? lastRating;
  final int totalReviews;
  final int correctReviews;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether this card is due for review.
  bool get isDue => nextReviewAt.isBefore(DateTime.now());

  /// Accuracy percentage based on review history.
  double get accuracy =>
      totalReviews == 0 ? 0 : (correctReviews / totalReviews) * 100;

  FlashcardEntity copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    FlashcardRating? lastRating,
    int? totalReviews,
    int? correctReviews,
    String? frontContent,
    String? backContent,
  }) =>
      FlashcardEntity(
        id: id,
        deckId: deckId,
        frontContent: frontContent ?? this.frontContent,
        backContent: backContent ?? this.backContent,
        hint: hint,
        imageUrl: imageUrl,
        difficulty: difficulty,
        easeFactor: easeFactor ?? this.easeFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        lastRating: lastRating ?? this.lastRating,
        totalReviews: totalReviews ?? this.totalReviews,
        correctReviews: correctReviews ?? this.correctReviews,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, deckId, frontContent, nextReviewAt];
}

/// Represents a study plan created by a student or suggested by AI.
class StudyPlanEntity extends Equatable {
  const StudyPlanEntity({
    required this.id,
    required this.studentId,
    this.schoolId,
    required this.title,
    this.description,
    this.frequency = StudyPlanFrequency.daily,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isAiSuggested = false,
    this.aiSuggestionReason,
    required this.createdAt,
    required this.updatedAt,
    this.tasks = const [],
  });

  final String id;
  final String studentId;
  final String? schoolId;
  final String title;
  final String? description;
  final StudyPlanFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isAiSuggested;
  final String? aiSuggestionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StudyTaskEntity> tasks;

  StudyPlanEntity copyWith({
    String? title,
    String? description,
    StudyPlanFrequency? frequency,
    DateTime? endDate,
    bool? isActive,
    List<StudyTaskEntity>? tasks,
  }) =>
      StudyPlanEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        title: title ?? this.title,
        description: description ?? this.description,
        frequency: frequency ?? this.frequency,
        startDate: startDate,
        endDate: endDate ?? this.endDate,
        isActive: isActive ?? this.isActive,
        isAiSuggested: isAiSuggested,
        aiSuggestionReason: aiSuggestionReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
        tasks: tasks ?? this.tasks,
      );

  @override
  List<Object?> get props => [id, studentId, title, isActive];
}

/// Represents a task within a study plan.
class StudyTaskEntity extends Equatable {
  const StudyTaskEntity({
    required this.id,
    required this.planId,
    this.subjectId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.status = StudyTaskStatus.pending,
    this.completionPct = 0,
    this.notes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
  });

  final String id;
  final String planId;
  final String? subjectId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final StudyTaskStatus status;
  final double completionPct;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? subjectName;

  StudyTaskEntity copyWith({
    StudyTaskStatus? status,
    double? completionPct,
    String? notes,
    DateTime? completedAt,
  }) =>
      StudyTaskEntity(
        id: id,
        planId: planId,
        subjectId: subjectId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
        status: status ?? this.status,
        completionPct: completionPct ?? this.completionPct,
        notes: notes ?? this.notes,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
      );

  @override
  List<Object?> get props => [id, planId, title, scheduledDate, status];
}

/// Represents a student's learning goal.
class StudentGoalEntity extends Equatable {
  const StudentGoalEntity({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.subjectId,
    required this.title,
    this.description,
    this.targetValue,
    this.currentValue = 0,
    this.unit = '%',
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.notStarted,
    this.deadline,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
  });

  final String id;
  final String studentId;
  final String? schoolId;
  final String? subjectId;
  final String title;
  final String? description;
  final double? targetValue;
  final double currentValue;
  final String unit;
  final GoalPriority priority;
  final GoalStatus status;
  final DateTime? deadline;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? subjectName;

  /// Progress percentage toward the goal.
  double get progressPct {
    if (targetValue == null || targetValue == 0) return 0;
    return ((currentValue / targetValue!) * 100).clamp(0, 100);
  }

  StudentGoalEntity copyWith({
    double? currentValue,
    GoalPriority? priority,
    GoalStatus? status,
    DateTime? completedAt,
  }) =>
      StudentGoalEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: currentValue ?? this.currentValue,
        unit: unit,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        deadline: deadline,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        subjectName: subjectName,
      );

  @override
  List<Object?> get props => [id, studentId, title, status];
}

/// Represents a snapshot of student learning progress.
class StudentProgressEntity extends Equatable {
  const StudentProgressEntity({
    required this.id,
    required this.studentId,
    this.schoolId,
    this.period = ProgressPeriod.weekly,
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

  final String id;
  final String studentId;
  final String? schoolId;
  final ProgressPeriod period;
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
  final List<TopicScoreInfo> weakTopics;
  final List<TopicScoreInfo> strongTopics;
  final List<AiSuggestion> aiSuggestions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  // Joined
  final String? subjectName;

  /// Overall accuracy percentage.
  double get accuracyPct =>
      questionsAttempted == 0
          ? 0
          : (questionsCorrect / questionsAttempted) * 100;

  @override
  List<Object?> get props => [id, studentId, period, periodStart, subjectId];
}

/// Topic score information used in progress snapshots.
class TopicScoreInfo extends Equatable {
  const TopicScoreInfo({
    required this.topicId,
    required this.topicName,
    required this.scorePct,
  });

  final String topicId;
  final String topicName;
  final double scorePct;

  @override
  List<Object?> get props => [topicId, scorePct];
}

/// AI-generated improvement suggestion.
class AiSuggestion extends Equatable {
  const AiSuggestion({
    required this.type,
    required this.message,
    this.actionLabel,
    this.actionUrl,
  });

  final String type;     // study_tip, practice_more, review_topic, etc.
  final String message;
  final String? actionLabel;
  final String? actionUrl;

  @override
  List<Object?> get props => [type, message];
}

/// Represents a daily activity record for a student.
class StudentDailyActivityEntity extends Equatable {
  const StudentDailyActivityEntity({
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

  @override
  List<Object?> get props => [id, studentId, activityDate];
}

/// Represents a notification for a student.
class StudentNotificationEntity extends Equatable {
  const StudentNotificationEntity({
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

  final String id;
  final String studentId;
  final String? schoolId;
  final StudentNotificationType type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final String? actionUrl;
  final DateTime? scheduledFor;
  final DateTime createdAt;

  StudentNotificationEntity copyWith({bool? isRead}) =>
      StudentNotificationEntity(
        id: id,
        studentId: studentId,
        schoolId: schoolId,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
        relatedType: relatedType,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl,
        scheduledFor: scheduledFor,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, isRead, createdAt];
}

/// Dashboard statistics for the student portal.
class StudentDashboardStats extends Equatable {
  const StudentDashboardStats({
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

  final int upcomingExams;
  final int pendingAssignments;
  final int learningStreak;
  final double recentAvgScore;
  final int practiceThisWeek;
  final int unreadNotifications;
  final int completedExams;
  final int totalSubjects;
  final int studyTimeThisWeekMin;

  @override
  List<Object?> get props => [
        upcomingExams, pendingAssignments, learningStreak,
        recentAvgScore, practiceThisWeek, unreadNotifications,
      ];
}
