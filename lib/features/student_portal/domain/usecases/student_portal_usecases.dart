import '../../../../core/utils/result.dart';
import '../entities/student_portal_entities.dart';
import '../repositories/student_portal_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI TUTOR USE CASES
// ═══════════════════════════════════════════════════════════════════════

class CreateConversationUseCase {
  final StudentPortalRepository _repository;
  CreateConversationUseCase(this._repository);

  Future<Result<AiTutorConversationEntity>> call({
    required String studentId,
    String? schoolId,
    String title = 'New Conversation',
    String? subjectId,
    String? topic,
    String curriculumType = 'nigerian',
  }) =>
      _repository.createConversation(
        studentId: studentId,
        schoolId: schoolId,
        title: title,
        subjectId: subjectId,
        topic: topic,
        curriculumType: curriculumType,
      );
}

class GetConversationsUseCase {
  final StudentPortalRepository _repository;
  GetConversationsUseCase(this._repository);

  Future<Result<List<AiTutorConversationEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getConversations(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
      );
}

class GetConversationDetailUseCase {
  final StudentPortalRepository _repository;
  GetConversationDetailUseCase(this._repository);

  Future<Result<AiTutorConversationEntity>> call({
    required String conversationId,
  }) =>
      _repository.getConversationDetail(conversationId: conversationId);
}

class SendMessageUseCase {
  final StudentPortalRepository _repository;
  SendMessageUseCase(this._repository);

  Future<Result<AiTutorMessageEntity>> call({
    required String conversationId,
    required String content,
    String? subjectId,
    String? topic,
    String? curriculumType,
  }) =>
      _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        subjectId: subjectId,
        topic: topic,
        curriculumType: curriculumType,
      );
}

class DeleteConversationUseCase {
  final StudentPortalRepository _repository;
  DeleteConversationUseCase(this._repository);

  Future<Result<void>> call({required String conversationId}) =>
      _repository.deleteConversation(conversationId: conversationId);
}

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE SESSION USE CASES
// ═══════════════════════════════════════════════════════════════════════

class CreatePracticeSessionUseCase {
  final StudentPortalRepository _repository;
  CreatePracticeSessionUseCase(this._repository);

  Future<Result<PracticeSessionEntity>> call({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    PracticeMode mode = PracticeMode.untimed,
    int? timeLimitSec,
    int questionCount = 10,
  }) =>
      _repository.createPracticeSession(
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        difficulty: difficulty,
        mode: mode,
        timeLimitSec: timeLimitSec,
        questionCount: questionCount,
      );
}

class GetPracticeSessionsUseCase {
  final StudentPortalRepository _repository;
  GetPracticeSessionsUseCase(this._repository);

  Future<Result<List<PracticeSessionEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    PracticeSessionStatus? status,
    String? subjectId,
  }) =>
      _repository.getPracticeSessions(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
        status: status,
        subjectId: subjectId,
      );
}

class GetPracticeSessionDetailUseCase {
  final StudentPortalRepository _repository;
  GetPracticeSessionDetailUseCase(this._repository);

  Future<Result<PracticeSessionEntity>> call({
    required String sessionId,
  }) =>
      _repository.getPracticeSessionDetail(sessionId: sessionId);
}

class SubmitPracticeAnswerUseCase {
  final StudentPortalRepository _repository;
  SubmitPracticeAnswerUseCase(this._repository);

  Future<Result<PracticeAnswerEntity>> call({
    required String sessionId,
    required String questionId,
    required Map<String, dynamic> studentAnswer,
    int timeSpentSec = 0,
  }) =>
      _repository.submitPracticeAnswer(
        sessionId: sessionId,
        questionId: questionId,
        studentAnswer: studentAnswer,
        timeSpentSec: timeSpentSec,
      );
}

class CompletePracticeSessionUseCase {
  final StudentPortalRepository _repository;
  CompletePracticeSessionUseCase(this._repository);

  Future<Result<PracticeSessionEntity>> call({
    required String sessionId,
  }) =>
      _repository.completePracticeSession(sessionId: sessionId);
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT SUBMISSION USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetSubmissionsUseCase {
  final StudentPortalRepository _repository;
  GetSubmissionsUseCase(this._repository);

  Future<Result<List<AssignmentSubmissionEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    SubmissionStatus? status,
  }) =>
      _repository.getSubmissions(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
        status: status,
      );
}

class CreateSubmissionUseCase {
  final StudentPortalRepository _repository;
  CreateSubmissionUseCase(this._repository);

  Future<Result<AssignmentSubmissionEntity>> call({
    required String assignmentId,
    required String studentId,
    String? schoolId,
    Map<String, dynamic> content = const {},
    List<AttachmentInfo> attachments = const [],
  }) =>
      _repository.createSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        schoolId: schoolId,
        content: content,
        attachments: attachments,
      );
}

class SubmitAssignmentUseCase {
  final StudentPortalRepository _repository;
  SubmitAssignmentUseCase(this._repository);

  Future<Result<AssignmentSubmissionEntity>> call({
    required String submissionId,
  }) =>
      _repository.submitAssignment(submissionId: submissionId);
}

class GetAssignedAssignmentsUseCase {
  final StudentPortalRepository _repository;
  GetAssignedAssignmentsUseCase(this._repository);

  Future<Result<List<AssignmentSubmissionEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getAssignedAssignments(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
      );
}

class GetSubmissionDetailUseCase {
  final StudentPortalRepository _repository;
  GetSubmissionDetailUseCase(this._repository);

  Future<Result<AssignmentSubmissionEntity>> call({
    required String submissionId,
  }) =>
      _repository.getSubmissionDetail(submissionId: submissionId);
}

// ═══════════════════════════════════════════════════════════════════════
// LEARNING RESOURCES USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetStudentResourcesUseCase {
  final StudentPortalRepository _repository;
  GetStudentResourcesUseCase(this._repository);

  Future<Result<List<LearningResourceEntity>>> call({
    required String studentId,
    String? schoolId,
    int page = 1,
    int pageSize = 20,
    StudentResourceType? resourceType,
    String? subjectId,
    String? searchQuery,
  }) =>
      _repository.getResources(
        studentId: studentId,
        schoolId: schoolId,
        page: page,
        pageSize: pageSize,
        resourceType: resourceType,
        subjectId: subjectId,
        searchQuery: searchQuery,
      );
}

class GetResourceDetailUseCase {
  final StudentPortalRepository _repository;
  GetResourceDetailUseCase(this._repository);

  Future<Result<LearningResourceEntity>> call({
    required String resourceId,
  }) =>
      _repository.getResourceDetail(resourceId: resourceId);
}

class LogResourceAccessUseCase {
  final StudentPortalRepository _repository;
  LogResourceAccessUseCase(this._repository);

  Future<Result<void>> call({
    required String resourceId,
    required String studentId,
    String accessType = 'view',
  }) =>
      _repository.logResourceAccess(
        resourceId: resourceId,
        studentId: studentId,
        accessType: accessType,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CHAT USE CASES
// ═══════════════════════════════════════════════════════════════════════

class UploadDocumentUseCase {
  final StudentPortalRepository _repository;
  UploadDocumentUseCase(this._repository);

  Future<Result<DocumentChatEntity>> call({
    required String studentId,
    String? schoolId,
    required String fileName,
    required String fileUrl,
    required String fileFormat,
    int? fileSize,
  }) =>
      _repository.uploadDocument(
        studentId: studentId,
        schoolId: schoolId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileFormat: fileFormat,
        fileSize: fileSize,
      );
}

class GetDocumentsUseCase {
  final StudentPortalRepository _repository;
  GetDocumentsUseCase(this._repository);

  Future<Result<List<DocumentChatEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getDocuments(studentId: studentId, page: page, pageSize: pageSize);
}

class SendDocumentMessageUseCase {
  final StudentPortalRepository _repository;
  SendDocumentMessageUseCase(this._repository);

  Future<Result<DocumentChatMessageEntity>> call({
    required String documentId,
    required String content,
  }) =>
      _repository.sendDocumentMessage(documentId: documentId, content: content);
}

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetFlashcardDecksUseCase {
  final StudentPortalRepository _repository;
  GetFlashcardDecksUseCase(this._repository);

  Future<Result<List<FlashcardDeckEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? isFavorite,
    String? subjectId,
  }) =>
      _repository.getFlashcardDecks(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
        isFavorite: isFavorite,
        subjectId: subjectId,
      );
}

class CreateFlashcardDeckUseCase {
  final StudentPortalRepository _repository;
  CreateFlashcardDeckUseCase(this._repository);

  Future<Result<FlashcardDeckEntity>> call({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    required String title,
    String? description,
    String sourceType = 'manual',
    String? sourceId,
    List<String> tags = const [],
  }) =>
      _repository.createFlashcardDeck(
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        topicId: topicId,
        title: title,
        description: description,
        sourceType: sourceType,
        sourceId: sourceId,
        tags: tags,
      );
}

class GetFlashcardsUseCase {
  final StudentPortalRepository _repository;
  GetFlashcardsUseCase(this._repository);

  Future<Result<List<FlashcardEntity>>> call({
    required String deckId,
    bool dueOnly = false,
  }) =>
      _repository.getFlashcards(deckId: deckId, dueOnly: dueOnly);
}

class CreateFlashcardUseCase {
  final StudentPortalRepository _repository;
  CreateFlashcardUseCase(this._repository);

  Future<Result<FlashcardEntity>> call({
    required String deckId,
    required String frontContent,
    required String backContent,
    String? hint,
    String? imageUrl,
    String difficulty = 'medium',
  }) =>
      _repository.createFlashcard(
        deckId: deckId,
        frontContent: frontContent,
        backContent: backContent,
        hint: hint,
        imageUrl: imageUrl,
        difficulty: difficulty,
      );
}

class RateFlashcardUseCase {
  final StudentPortalRepository _repository;
  RateFlashcardUseCase(this._repository);

  Future<Result<FlashcardEntity>> call({
    required String cardId,
    required FlashcardRating rating,
  }) =>
      _repository.rateFlashcard(cardId: cardId, rating: rating);
}

class GenerateFlashcardsUseCase {
  final StudentPortalRepository _repository;
  GenerateFlashcardsUseCase(this._repository);

  Future<Result<FlashcardDeckEntity>> call({
    required String studentId,
    String? schoolId,
    required String title,
    String? subjectId,
    String? topicId,
    required String sourceContent,
    String sourceType = 'ai_generated',
    int cardCount = 10,
  }) =>
      _repository.generateFlashcards(
        studentId: studentId,
        schoolId: schoolId,
        title: title,
        subjectId: subjectId,
        topicId: topicId,
        sourceContent: sourceContent,
        sourceType: sourceType,
        cardCount: cardCount,
      );
}

class DeleteFlashcardDeckUseCase {
  final StudentPortalRepository _repository;
  DeleteFlashcardDeckUseCase(this._repository);

  Future<Result<void>> call({required String deckId}) =>
      _repository.deleteFlashcardDeck(deckId: deckId);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLANNER USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetStudyPlansUseCase {
  final StudentPortalRepository _repository;
  GetStudyPlansUseCase(this._repository);

  Future<Result<List<StudyPlanEntity>>> call({
    required String studentId,
    bool? isActive,
  }) =>
      _repository.getStudyPlans(studentId: studentId, isActive: isActive);
}

class CreateStudyPlanUseCase {
  final StudentPortalRepository _repository;
  CreateStudyPlanUseCase(this._repository);

  Future<Result<StudyPlanEntity>> call({
    required String studentId,
    String? schoolId,
    required String title,
    String? description,
    StudyPlanFrequency frequency = StudyPlanFrequency.daily,
    required DateTime startDate,
    DateTime? endDate,
    List<StudyTaskEntity> tasks = const [],
  }) =>
      _repository.createStudyPlan(
        studentId: studentId,
        schoolId: schoolId,
        title: title,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        tasks: tasks,
      );
}

class UpdateStudyTaskUseCase {
  final StudentPortalRepository _repository;
  UpdateStudyTaskUseCase(this._repository);

  Future<Result<StudyTaskEntity>> call({
    required String taskId,
    StudyTaskStatus? status,
    double? completionPct,
    String? notes,
  }) =>
      _repository.updateStudyTask(
        taskId: taskId,
        status: status,
        completionPct: completionPct,
        notes: notes,
      );
}

class SuggestStudyPlanUseCase {
  final StudentPortalRepository _repository;
  SuggestStudyPlanUseCase(this._repository);

  Future<Result<StudyPlanEntity>> call({
    required String studentId,
    String? schoolId,
    String? focusSubjectId,
  }) =>
      _repository.suggestStudyPlan(
        studentId: studentId,
        schoolId: schoolId,
        focusSubjectId: focusSubjectId,
      );
}

class DeleteStudyPlanUseCase {
  final StudentPortalRepository _repository;
  DeleteStudyPlanUseCase(this._repository);

  Future<Result<void>> call({required String planId}) =>
      _repository.deleteStudyPlan(planId: planId);
}

// ═══════════════════════════════════════════════════════════════════════
// GOALS USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetGoalsUseCase {
  final StudentPortalRepository _repository;
  GetGoalsUseCase(this._repository);

  Future<Result<List<StudentGoalEntity>>> call({
    required String studentId,
    GoalStatus? status,
    String? subjectId,
  }) =>
      _repository.getGoals(studentId: studentId, status: status, subjectId: subjectId);
}

class CreateGoalUseCase {
  final StudentPortalRepository _repository;
  CreateGoalUseCase(this._repository);

  Future<Result<StudentGoalEntity>> call({
    required String studentId,
    String? schoolId,
    String? subjectId,
    required String title,
    String? description,
    double? targetValue,
    String unit = '%',
    GoalPriority priority = GoalPriority.medium,
    DateTime? deadline,
  }) =>
      _repository.createGoal(
        studentId: studentId,
        schoolId: schoolId,
        subjectId: subjectId,
        title: title,
        description: description,
        targetValue: targetValue,
        unit: unit,
        priority: priority,
        deadline: deadline,
      );
}

class UpdateGoalUseCase {
  final StudentPortalRepository _repository;
  UpdateGoalUseCase(this._repository);

  Future<Result<StudentGoalEntity>> call({
    required String goalId,
    double? currentValue,
    GoalPriority? priority,
    GoalStatus? status,
  }) =>
      _repository.updateGoal(
        goalId: goalId,
        currentValue: currentValue,
        priority: priority,
        status: status,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PROGRESS & ANALYTICS USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetProgressUseCase {
  final StudentPortalRepository _repository;
  GetProgressUseCase(this._repository);

  Future<Result<List<StudentProgressEntity>>> call({
    required String studentId,
    ProgressPeriod? period,
    String? subjectId,
    int limit = 12,
  }) =>
      _repository.getProgress(
        studentId: studentId,
        period: period,
        subjectId: subjectId,
        limit: limit,
      );
}

class GetLatestProgressUseCase {
  final StudentPortalRepository _repository;
  GetLatestProgressUseCase(this._repository);

  Future<Result<StudentProgressEntity>> call({
    required String studentId,
  }) =>
      _repository.getLatestProgress(studentId: studentId);
}

class GetDashboardStatsUseCase {
  final StudentPortalRepository _repository;
  GetDashboardStatsUseCase(this._repository);

  Future<Result<StudentDashboardStats>> call({
    required String studentId,
  }) =>
      _repository.getDashboardStats(studentId: studentId);
}

class UpsertDailyActivityUseCase {
  final StudentPortalRepository _repository;
  UpsertDailyActivityUseCase(this._repository);

  Future<Result<StudentDailyActivityEntity>> call({
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
  }) =>
      _repository.upsertDailyActivity(
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
      );
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION USE CASES
// ═══════════════════════════════════════════════════════════════════════

class GetNotificationsUseCase {
  final StudentPortalRepository _repository;
  GetNotificationsUseCase(this._repository);

  Future<Result<List<StudentNotificationEntity>>> call({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) =>
      _repository.getNotifications(
        studentId: studentId,
        page: page,
        pageSize: pageSize,
        unreadOnly: unreadOnly,
      );
}

class MarkNotificationReadUseCase {
  final StudentPortalRepository _repository;
  MarkNotificationReadUseCase(this._repository);

  Future<Result<void>> call({required String notificationId}) =>
      _repository.markNotificationRead(notificationId: notificationId);
}

class MarkAllNotificationsReadUseCase {
  final StudentPortalRepository _repository;
  MarkAllNotificationsReadUseCase(this._repository);

  Future<Result<void>> call({required String studentId}) =>
      _repository.markAllNotificationsRead(studentId: studentId);
}

// ═══════════════════════════════════════════════════════════════════════
// AI QUESTION GENERATION INTEGRATION
// ═══════════════════════════════════════════════════════════════════════

class GenerateQuestionsFromContentUseCase {
  final StudentPortalRepository _repository;
  GenerateQuestionsFromContentUseCase(this._repository);

  Future<Result<List<Map<String, dynamic>>>> call({
    required String studentId,
    required String content,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    int questionCount = 5,
    String questionType = 'multiple_choice',
  }) =>
      _repository.generateQuestionsFromContent(
        studentId: studentId,
        content: content,
        subjectId: subjectId,
        topicId: topicId,
        difficulty: difficulty,
        questionCount: questionCount,
        questionType: questionType,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ADDITIONAL USE CASES (for presentation provider support)
// ═══════════════════════════════════════════════════════════════════════

class GetDocumentDetailUseCase {
  final StudentPortalRepository _repository;
  GetDocumentDetailUseCase(this._repository);

  Future<Result<DocumentChatEntity>> call({
    required String documentId,
  }) =>
      _repository.getDocumentDetail(documentId: documentId);
}

class DeleteDocumentUseCase {
  final StudentPortalRepository _repository;
  DeleteDocumentUseCase(this._repository);

  Future<Result<void>> call({required String documentId}) =>
      _repository.deleteDocument(documentId: documentId);
}

class DeleteFlashcardUseCase {
  final StudentPortalRepository _repository;
  DeleteFlashcardUseCase(this._repository);

  Future<Result<void>> call({required String cardId}) =>
      _repository.deleteFlashcard(cardId: cardId);
}

class CreateStudyTaskUseCase {
  final StudentPortalRepository _repository;
  CreateStudyTaskUseCase(this._repository);

  Future<Result<StudyTaskEntity>> call({
    required String planId,
    String? subjectId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      _repository.createStudyTask(
        planId: planId,
        subjectId: subjectId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
      );
}

class DeleteStudyTaskUseCase {
  final StudentPortalRepository _repository;
  DeleteStudyTaskUseCase(this._repository);

  Future<Result<void>> call({required String taskId}) =>
      _repository.deleteStudyTask(taskId: taskId);
}

class DeleteGoalUseCase {
  final StudentPortalRepository _repository;
  DeleteGoalUseCase(this._repository);

  Future<Result<void>> call({required String goalId}) =>
      _repository.deleteGoal(goalId: goalId);
}

class GetDailyActivityUseCase {
  final StudentPortalRepository _repository;
  GetDailyActivityUseCase(this._repository);

  Future<Result<List<StudentDailyActivityEntity>>> call({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _repository.getDailyActivity(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );
}
