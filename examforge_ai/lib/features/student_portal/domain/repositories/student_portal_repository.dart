import '../../../../core/utils/result.dart';
import '../entities/student_portal_entities.dart';

/// Abstract contract for the Student Portal repository.
///
/// Defines all operations the Student Learning Portal requires from
/// the data layer. The implementation maps Supabase / network
/// exceptions to domain [Failure]s and wraps results in [Result<T>].
abstract class StudentPortalRepository {
  // ═══════════════════════════════════════════════════════════════════════
  // AI TUTOR
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a new AI tutor conversation.
  Future<Result<AiTutorConversationEntity>> createConversation({
    required String studentId,
    String? schoolId,
    String title = 'New Conversation',
    String? subjectId,
    String? topic,
    String curriculumType = 'nigerian',
  });

  /// Fetches all conversations for a student.
  Future<Result<List<AiTutorConversationEntity>>> getConversations({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  });

  /// Gets a single conversation with its messages.
  Future<Result<AiTutorConversationEntity>> getConversationDetail({
    required String conversationId,
  });

  /// Sends a message and receives AI response.
  Future<Result<AiTutorMessageEntity>> sendMessage({
    required String conversationId,
    required String content,
    String? subjectId,
    String? topic,
    String? curriculumType,
  });

  /// Archives a conversation.
  Future<Result<void>> archiveConversation({required String conversationId});

  /// Deletes a conversation and all its messages.
  Future<Result<void>> deleteConversation({required String conversationId});

  // ═══════════════════════════════════════════════════════════════════════
  // PRACTICE SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a new practice session (fetches questions from QB).
  Future<Result<PracticeSessionEntity>> createPracticeSession({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    PracticeMode mode = PracticeMode.untimed,
    int? timeLimitSec,
    int questionCount = 10,
  });

  /// Gets practice sessions for a student (paginated).
  Future<Result<List<PracticeSessionEntity>>> getPracticeSessions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    PracticeSessionStatus? status,
    String? subjectId,
  });

  /// Gets a single practice session with answers.
  Future<Result<PracticeSessionEntity>> getPracticeSessionDetail({
    required String sessionId,
  });

  /// Submits an answer for a practice question.
  Future<Result<PracticeAnswerEntity>> submitPracticeAnswer({
    required String sessionId,
    required String questionId,
    required Map<String, dynamic> studentAnswer,
    int timeSpentSec = 0,
  });

  /// Completes a practice session (calculates final score).
  Future<Result<PracticeSessionEntity>> completePracticeSession({
    required String sessionId,
  });

  /// Abandons a practice session.
  Future<Result<void>> abandonPracticeSession({required String sessionId});

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT SUBMISSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all submissions for a student (with assignment info joined).
  Future<Result<List<AssignmentSubmissionEntity>>> getSubmissions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    SubmissionStatus? status,
  });

  /// Gets a single submission by ID.
  Future<Result<AssignmentSubmissionEntity>> getSubmissionDetail({
    required String submissionId,
  });

  /// Creates a draft submission.
  Future<Result<AssignmentSubmissionEntity>> createSubmission({
    required String assignmentId,
    required String studentId,
    String? schoolId,
    Map<String, dynamic> content = const {},
    List<AttachmentInfo> attachments = const [],
  });

  /// Updates a submission (save draft or add attachments).
  Future<Result<AssignmentSubmissionEntity>> updateSubmission({
    required String submissionId,
    Map<String, dynamic>? content,
    List<AttachmentInfo>? attachments,
  });

  /// Submits a draft assignment.
  Future<Result<AssignmentSubmissionEntity>> submitAssignment({
    required String submissionId,
  });

  /// Gets assignments assigned to the student (from Teacher Workspace).
  Future<Result<List<AssignmentSubmissionEntity>>> getAssignedAssignments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // LEARNING RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets learning resources (school-level + public).
  Future<Result<List<LearningResourceEntity>>> getResources({
    required String studentId,
    String? schoolId,
    int page = 1,
    int pageSize = 20,
    StudentResourceType? resourceType,
    String? subjectId,
    String? searchQuery,
  });

  /// Gets a single resource detail.
  Future<Result<LearningResourceEntity>> getResourceDetail({
    required String resourceId,
  });

  /// Logs resource access (view/download).
  Future<Result<void>> logResourceAccess({
    required String resourceId,
    required String studentId,
    String accessType = 'view',
  });

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT CHAT
  // ═══════════════════════════════════════════════════════════════════════

  /// Uploads a document for AI chat processing.
  Future<Result<DocumentChatEntity>> uploadDocument({
    required String studentId,
    String? schoolId,
    required String fileName,
    required String fileUrl,
    required String fileFormat,
    int? fileSize,
  });

  /// Gets all documents for a student.
  Future<Result<List<DocumentChatEntity>>> getDocuments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  });

  /// Gets a single document with chat messages.
  Future<Result<DocumentChatEntity>> getDocumentDetail({
    required String documentId,
  });

  /// Sends a message in document chat and receives AI response.
  Future<Result<DocumentChatMessageEntity>> sendDocumentMessage({
    required String documentId,
    required String content,
  });

  /// Deletes a document and its chat.
  Future<Result<void>> deleteDocument({required String documentId});

  // ═══════════════════════════════════════════════════════════════════════
  // FLASHCARDS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all flashcard decks for a student.
  Future<Result<List<FlashcardDeckEntity>>> getFlashcardDecks({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? isFavorite,
    String? subjectId,
  });

  /// Creates a new flashcard deck.
  Future<Result<FlashcardDeckEntity>> createFlashcardDeck({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    required String title,
    String? description,
    String sourceType = 'manual',
    String? sourceId,
    List<String> tags = const [],
  });

  /// Updates a flashcard deck.
  Future<Result<FlashcardDeckEntity>> updateFlashcardDeck({
    required String deckId,
    String? title,
    String? description,
    bool? isFavorite,
    List<String>? tags,
  });

  /// Deletes a flashcard deck and all cards.
  Future<Result<void>> deleteFlashcardDeck({required String deckId});

  /// Gets flashcards in a deck.
  Future<Result<List<FlashcardEntity>>> getFlashcards({
    required String deckId,
    bool dueOnly = false,
  });

  /// Creates a flashcard.
  Future<Result<FlashcardEntity>> createFlashcard({
    required String deckId,
    required String frontContent,
    required String backContent,
    String? hint,
    String? imageUrl,
    String difficulty = 'medium',
  });

  /// Updates a flashcard's content.
  Future<Result<FlashcardEntity>> updateFlashcard({
    required String cardId,
    String? frontContent,
    String? backContent,
    String? hint,
  });

  /// Rates a flashcard (SM-2 spaced repetition).
  Future<Result<FlashcardEntity>> rateFlashcard({
    required String cardId,
    required FlashcardRating rating,
  });

  /// Deletes a flashcard.
  Future<Result<void>> deleteFlashcard({required String cardId});

  /// Generates flashcards from content using AI.
  Future<Result<FlashcardDeckEntity>> generateFlashcards({
    required String studentId,
    String? schoolId,
    required String title,
    String? subjectId,
    String? topicId,
    required String sourceContent,
    String sourceType = 'ai_generated',
    int cardCount = 10,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLANNER
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all study plans for a student.
  Future<Result<List<StudyPlanEntity>>> getStudyPlans({
    required String studentId,
    bool? isActive,
  });

  /// Creates a study plan.
  Future<Result<StudyPlanEntity>> createStudyPlan({
    required String studentId,
    String? schoolId,
    required String title,
    String? description,
    StudyPlanFrequency frequency = StudyPlanFrequency.daily,
    required DateTime startDate,
    DateTime? endDate,
    List<StudyTaskEntity> tasks = const [],
  });

  /// Updates a study plan.
  Future<Result<StudyPlanEntity>> updateStudyPlan({
    required String planId,
    String? title,
    String? description,
    StudyPlanFrequency? frequency,
    DateTime? endDate,
    bool? isActive,
  });

  /// Deletes a study plan.
  Future<Result<void>> deleteStudyPlan({required String planId});

  /// Creates a study task.
  Future<Result<StudyTaskEntity>> createStudyTask({
    required String planId,
    String? subjectId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
  });

  /// Updates a study task status.
  Future<Result<StudyTaskEntity>> updateStudyTask({
    required String taskId,
    StudyTaskStatus? status,
    double? completionPct,
    String? notes,
  });

  /// Deletes a study task.
  Future<Result<void>> deleteStudyTask({required String taskId});

  /// Gets AI-suggested study plan based on student progress.
  Future<Result<StudyPlanEntity>> suggestStudyPlan({
    required String studentId,
    String? schoolId,
    String? focusSubjectId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT GOALS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all goals for a student.
  Future<Result<List<StudentGoalEntity>>> getGoals({
    required String studentId,
    GoalStatus? status,
    String? subjectId,
  });

  /// Creates a goal.
  Future<Result<StudentGoalEntity>> createGoal({
    required String studentId,
    String? schoolId,
    String? subjectId,
    required String title,
    String? description,
    double? targetValue,
    String unit = '%',
    GoalPriority priority = GoalPriority.medium,
    DateTime? deadline,
  });

  /// Updates a goal.
  Future<Result<StudentGoalEntity>> updateGoal({
    required String goalId,
    double? currentValue,
    GoalPriority? priority,
    GoalStatus? status,
  });

  /// Deletes a goal.
  Future<Result<void>> deleteGoal({required String goalId});

  // ═══════════════════════════════════════════════════════════════════════
  // PROGRESS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets progress snapshots for a student.
  Future<Result<List<StudentProgressEntity>>> getProgress({
    required String studentId,
    ProgressPeriod? period,
    String? subjectId,
    int limit = 12,
  });

  /// Gets the latest overall progress snapshot.
  Future<Result<StudentProgressEntity>> getLatestProgress({
    required String studentId,
  });

  /// Gets daily activity for a date range.
  Future<Result<List<StudentDailyActivityEntity>>> getDailyActivity({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Records or updates daily activity.
  Future<Result<StudentDailyActivityEntity>> upsertDailyActivity({
    required String studentId,
    required DateTime activityDate,
    int? studyTimeMin,
    int? questionsAttempted,
    int? questionsCorrect,
    int? practiceSessions,
    int? flashcardsReviewed,
    int? assignmentsSubmitted,
    int? resourcesViewed,
    int? tutorQuestions,
  });

  /// Gets student dashboard stats.
  Future<Result<StudentDashboardStats>> getDashboardStats({
    required String studentId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets notifications for a student.
  Future<Result<List<StudentNotificationEntity>>> getNotifications({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  });

  /// Marks a notification as read.
  Future<Result<void>> markNotificationRead({required String notificationId});

  /// Marks all notifications as read.
  Future<Result<void>> markAllNotificationsRead({required String studentId});

  // ═══════════════════════════════════════════════════════════════════════
  // INTEGRATION: AI QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Generates practice questions from content (delegates to AI Generation Engine).
  Future<Result<List<Map<String, dynamic>>>> generateQuestionsFromContent({
    required String studentId,
    required String content,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    int questionCount = 5,
    String questionType = 'multiple_choice',
  });
}
