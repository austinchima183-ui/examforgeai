import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../datasources/student_portal_remote_datasource.dart';
import '../models/student_portal_models.dart';

/// Concrete implementation of [StudentPortalRepository] that delegates
/// all operations to [StudentPortalRemoteDatasource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class StudentPortalRepositoryImpl implements StudentPortalRepository {
  StudentPortalRepositoryImpl({
    required StudentPortalRemoteDatasource remoteDatasource,
    required sb.SupabaseClient supabaseClient,
  })  : _datasource = remoteDatasource,
        _supabaseClient = supabaseClient;

  final StudentPortalRemoteDatasource _datasource;
  final sb.SupabaseClient _supabaseClient;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Safe call with exception → Failure mapping
  // ═══════════════════════════════════════════════════════════════════════

  /// Executes [call] and wraps the result in [Result<T>].
  ///
  /// Catches all known exception types and maps them to the appropriate
  /// [Failure] variant. Unknown exceptions become [ServerFailure] with
  /// status code 500.
  Future<Result<T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected exception in StudentPortalRepositoryImpl',
          error: e);
      return FailureResult(Failure.server(
        message: e.toString(),
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI TUTOR
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiTutorConversationEntity>> createConversation({
    required String studentId,
    String? schoolId,
    String title = 'New Conversation',
    String? subjectId,
    String? topic,
    String curriculumType = 'nigerian',
  }) =>
      _safeCall(() async {
        final model = await _datasource.createConversation(
          studentId: studentId,
          schoolId: schoolId,
          title: title,
          subjectId: subjectId,
          topic: topic,
          curriculumType: curriculumType,
        );
        return model.toEntity();
      });

  @override
  Future<Result<List<AiTutorConversationEntity>>> getConversations({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getConversations(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AiTutorConversationEntity>> getConversationDetail({
    required String conversationId,
  }) =>
      _safeCall(() async {
        final result = await _datasource.getConversationDetail(
          conversationId: conversationId,
        );
        final conversation =
            result['conversation'] as AiTutorConversationModel;
        return conversation.toEntity();
      });

  @override
  Future<Result<AiTutorMessageEntity>> sendMessage({
    required String conversationId,
    required String content,
    String? subjectId,
    String? topic,
    String? curriculumType,
  }) =>
      _safeCall(() async {
        final model = await _datasource.sendMessage(
          conversationId: conversationId,
          content: content,
          subjectId: subjectId,
          topic: topic,
          curriculumType: curriculumType,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> archiveConversation({
    required String conversationId,
  }) =>
      _safeCall(() async {
        await _supabaseClient
            .from('ai_tutor_conversations')
            .update({'is_archived': true})
            .eq('id', conversationId);
      });

  @override
  Future<Result<void>> deleteConversation({
    required String conversationId,
  }) =>
      _safeCall(() async {
        await _datasource.deleteConversation(conversationId: conversationId);
      });

  // ═══════════════════════════════════════════════════════════════════════
  // PRACTICE SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<PracticeSessionEntity>> createPracticeSession({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    PracticeMode mode = PracticeMode.untimed,
    int? timeLimitSec,
    int questionCount = 10,
  }) =>
      _safeCall(() async {
        final model = await _datasource.createPracticeSession(
          studentId: studentId,
          schoolId: schoolId,
          subjectId: subjectId,
          topicId: topicId,
          difficulty: difficulty,
          mode: mode.value,
          timeLimitSec: timeLimitSec,
          questionCount: questionCount,
        );
        return model.toEntity();
      });

  @override
  Future<Result<List<PracticeSessionEntity>>> getPracticeSessions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    PracticeSessionStatus? status,
    String? subjectId,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getPracticeSessions(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
          status: status?.value,
          subjectId: subjectId,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<PracticeSessionEntity>> getPracticeSessionDetail({
    required String sessionId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getPracticeSessionDetail(
          sessionId: sessionId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<PracticeAnswerEntity>> submitPracticeAnswer({
    required String sessionId,
    required String questionId,
    required Map<String, dynamic> studentAnswer,
    int timeSpentSec = 0,
  }) =>
      _safeCall(() async {
        final model = await _datasource.submitPracticeAnswer(
          sessionId: sessionId,
          questionId: questionId,
          studentAnswer: studentAnswer,
          timeSpentSec: timeSpentSec,
        );
        return model.toEntity();
      });

  @override
  Future<Result<PracticeSessionEntity>> completePracticeSession({
    required String sessionId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.completePracticeSession(
          sessionId: sessionId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> abandonPracticeSession({
    required String sessionId,
  }) =>
      _safeCall(() async {
        await _datasource.abandonPracticeSession(sessionId: sessionId);
      });

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT SUBMISSIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AssignmentSubmissionEntity>>> getSubmissions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    SubmissionStatus? status,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getSubmissions(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
          status: status?.value,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AssignmentSubmissionEntity>> getSubmissionDetail({
    required String submissionId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getSubmissionDetail(
          submissionId: submissionId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<AssignmentSubmissionEntity>> createSubmission({
    required String assignmentId,
    required String studentId,
    String? schoolId,
    Map<String, dynamic> content = const {},
    List<AttachmentInfo> attachments = const [],
  }) =>
      _safeCall(() async {
        final model = await _datasource.createSubmission(
          assignmentId: assignmentId,
          studentId: studentId,
          schoolId: schoolId,
          content: content,
          attachments: attachments
              .map((a) => {
                    'filename': a.filename,
                    'url': a.url,
                    'size': a.size,
                    'type': a.type,
                  })
              .toList(),
        );
        return model.toEntity();
      });

  @override
  Future<Result<AssignmentSubmissionEntity>> updateSubmission({
    required String submissionId,
    Map<String, dynamic>? content,
    List<AttachmentInfo>? attachments,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateSubmission(
          submissionId: submissionId,
          content: content,
          attachments: attachments
              ?.map((a) => {
                    'filename': a.filename,
                    'url': a.url,
                    'size': a.size,
                    'type': a.type,
                  })
              .toList(),
        );
        return model.toEntity();
      });

  @override
  Future<Result<AssignmentSubmissionEntity>> submitAssignment({
    required String submissionId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.submitAssignment(
          submissionId: submissionId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<List<AssignmentSubmissionEntity>>> getAssignedAssignments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getAssignedAssignments(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // LEARNING RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<LearningResourceEntity>>> getResources({
    required String studentId,
    String? schoolId,
    int page = 1,
    int pageSize = 20,
    StudentResourceType? resourceType,
    String? subjectId,
    String? searchQuery,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getResources(
          studentId: studentId,
          schoolId: schoolId,
          page: page,
          pageSize: pageSize,
          resourceType: resourceType?.value,
          subjectId: subjectId,
          searchQuery: searchQuery,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<LearningResourceEntity>> getResourceDetail({
    required String resourceId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getResourceDetail(
          resourceId: resourceId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> logResourceAccess({
    required String resourceId,
    required String studentId,
    String accessType = 'view',
  }) =>
      _safeCall(() async {
        await _datasource.logResourceAccess(
          resourceId: resourceId,
          studentId: studentId,
          accessType: accessType,
        );
      });

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT CHAT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DocumentChatEntity>> uploadDocument({
    required String studentId,
    String? schoolId,
    required String fileName,
    required String fileUrl,
    required String fileFormat,
    int? fileSize,
  }) =>
      _safeCall(() async {
        // The repository receives a pre-uploaded file URL, so we create
        // the document_chats record directly and trigger processing.
        final response = await _supabaseClient
            .from('document_chats')
            .insert({
              'student_id': studentId,
              'school_id': schoolId,
              'file_name': fileName,
              'file_url': fileUrl,
              'file_size': fileSize,
              'file_format': fileFormat,
              'status': 'processing',
            })
            .select()
            .single();

        final documentId = response['id'] as String;

        // Trigger the process-document edge function asynchronously
        _supabaseClient.functions
            .invoke(
          'process-document',
          body: {
            'document_id': documentId,
            'file_url': fileUrl,
            'file_format': fileFormat,
          },
        )
            .catchError((error) {
          AppLogger.error('Process document edge function failed',
              error: error);
        });

        return DocumentChatModel.fromJson(response).toEntity();
      });

  @override
  Future<Result<List<DocumentChatEntity>>> getDocuments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getDocuments(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<DocumentChatEntity>> getDocumentDetail({
    required String documentId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getDocumentDetail(
          documentId: documentId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<DocumentChatMessageEntity>> sendDocumentMessage({
    required String documentId,
    required String content,
  }) =>
      _safeCall(() async {
        final model = await _datasource.sendDocumentMessage(
          documentId: documentId,
          content: content,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteDocument({required String documentId}) =>
      _safeCall(() async {
        await _datasource.deleteDocument(documentId: documentId);
      });

  // ═══════════════════════════════════════════════════════════════════════
  // FLASHCARDS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<FlashcardDeckEntity>>> getFlashcardDecks({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? isFavorite,
    String? subjectId,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getFlashcardDecks(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
          isFavorite: isFavorite,
          subjectId: subjectId,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
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
  }) =>
      _safeCall(() async {
        final model = await _datasource.createFlashcardDeck(
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
        return model.toEntity();
      });

  @override
  Future<Result<FlashcardDeckEntity>> updateFlashcardDeck({
    required String deckId,
    String? title,
    String? description,
    bool? isFavorite,
    List<String>? tags,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateFlashcardDeck(
          deckId: deckId,
          title: title,
          description: description,
          isFavorite: isFavorite,
          tags: tags,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteFlashcardDeck({required String deckId}) =>
      _safeCall(() async {
        await _datasource.deleteFlashcardDeck(deckId: deckId);
      });

  @override
  Future<Result<List<FlashcardEntity>>> getFlashcards({
    required String deckId,
    bool dueOnly = false,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getFlashcards(
          deckId: deckId,
          dueOnly: dueOnly,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<FlashcardEntity>> createFlashcard({
    required String deckId,
    required String frontContent,
    required String backContent,
    String? hint,
    String? imageUrl,
    String difficulty = 'medium',
  }) =>
      _safeCall(() async {
        final model = await _datasource.createFlashcard(
          deckId: deckId,
          frontContent: frontContent,
          backContent: backContent,
          hint: hint,
          imageUrl: imageUrl,
          difficulty: difficulty,
        );
        return model.toEntity();
      });

  @override
  Future<Result<FlashcardEntity>> updateFlashcard({
    required String cardId,
    String? frontContent,
    String? backContent,
    String? hint,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateFlashcard(
          cardId: cardId,
          frontContent: frontContent,
          backContent: backContent,
          hint: hint,
        );
        return model.toEntity();
      });

  @override
  Future<Result<FlashcardEntity>> rateFlashcard({
    required String cardId,
    required FlashcardRating rating,
  }) =>
      _safeCall(() async {
        final model = await _datasource.rateFlashcard(
          cardId: cardId,
          rating: rating.value,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteFlashcard({required String cardId}) =>
      _safeCall(() async {
        await _datasource.deleteFlashcard(cardId: cardId);
      });

  @override
  Future<Result<FlashcardDeckEntity>> generateFlashcards({
    required String studentId,
    String? schoolId,
    required String title,
    String? subjectId,
    String? topicId,
    required String sourceContent,
    String sourceType = 'ai_generated',
    int cardCount = 10,
  }) =>
      _safeCall(() async {
        final model = await _datasource.generateFlashcards(
          studentId: studentId,
          schoolId: schoolId,
          title: title,
          subjectId: subjectId,
          topicId: topicId,
          sourceContent: sourceContent,
          sourceType: sourceType,
          cardCount: cardCount,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLANNER
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudyPlanEntity>>> getStudyPlans({
    required String studentId,
    bool? isActive,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getStudyPlans(
          studentId: studentId,
          isActive: isActive,
        );
        // Each StudyPlanModel includes embedded StudyTaskModel list from the
        // datasource. Map tasks to entities before converting the plan.
        return models
            .map((m) => m.toEntity(
                  tasks: const [], // Tasks are already embedded via fromJson
                ))
            .toList();
      });

  @override
  Future<Result<StudyPlanEntity>> createStudyPlan({
    required String studentId,
    String? schoolId,
    required String title,
    String? description,
    StudyPlanFrequency frequency = StudyPlanFrequency.daily,
    required DateTime startDate,
    DateTime? endDate,
    List<StudyTaskEntity> tasks = const [],
  }) =>
      _safeCall(() async {
        final model = await _datasource.createStudyPlan(
          studentId: studentId,
          schoolId: schoolId,
          title: title,
          description: description,
          frequency: frequency.value,
          startDate: startDate,
          endDate: endDate,
          tasks: tasks
              .map((t) => {
                    'subject_id': t.subjectId,
                    'title': t.title,
                    'description': t.description,
                    'scheduled_date': t.scheduledDate,
                    'start_time': t.startTime,
                    'end_time': t.endTime,
                  })
              .toList(),
        );
        return model.toEntity();
      });

  @override
  Future<Result<StudyPlanEntity>> updateStudyPlan({
    required String planId,
    String? title,
    String? description,
    StudyPlanFrequency? frequency,
    DateTime? endDate,
    bool? isActive,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateStudyPlan(
          planId: planId,
          title: title,
          description: description,
          frequency: frequency?.value,
          endDate: endDate,
          isActive: isActive,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteStudyPlan({required String planId}) =>
      _safeCall(() async {
        await _datasource.deleteStudyPlan(planId: planId);
      });

  @override
  Future<Result<StudyTaskEntity>> createStudyTask({
    required String planId,
    String? subjectId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      _safeCall(() async {
        final model = await _datasource.createStudyTask(
          planId: planId,
          subjectId: subjectId,
          title: title,
          description: description,
          scheduledDate: scheduledDate,
          startTime: startTime,
          endTime: endTime,
        );
        return model.toEntity();
      });

  @override
  Future<Result<StudyTaskEntity>> updateStudyTask({
    required String taskId,
    StudyTaskStatus? status,
    double? completionPct,
    String? notes,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateStudyTask(
          taskId: taskId,
          status: status?.value,
          completionPct: completionPct,
          notes: notes,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteStudyTask({required String taskId}) =>
      _safeCall(() async {
        await _datasource.deleteStudyTask(taskId: taskId);
      });

  @override
  Future<Result<StudyPlanEntity>> suggestStudyPlan({
    required String studentId,
    String? schoolId,
    String? focusSubjectId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.suggestStudyPlan(
          studentId: studentId,
          schoolId: schoolId,
          focusSubjectId: focusSubjectId,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT GOALS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudentGoalEntity>>> getGoals({
    required String studentId,
    GoalStatus? status,
    String? subjectId,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getGoals(
          studentId: studentId,
          status: status?.value,
          subjectId: subjectId,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
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
  }) =>
      _safeCall(() async {
        final model = await _datasource.createGoal(
          studentId: studentId,
          schoolId: schoolId,
          subjectId: subjectId,
          title: title,
          description: description,
          targetValue: targetValue,
          unit: unit,
          priority: priority.value,
          deadline: deadline,
        );
        return model.toEntity();
      });

  @override
  Future<Result<StudentGoalEntity>> updateGoal({
    required String goalId,
    double? currentValue,
    GoalPriority? priority,
    GoalStatus? status,
  }) =>
      _safeCall(() async {
        final model = await _datasource.updateGoal(
          goalId: goalId,
          currentValue: currentValue,
          priority: priority?.value,
          status: status?.value,
        );
        return model.toEntity();
      });

  @override
  Future<Result<void>> deleteGoal({required String goalId}) =>
      _safeCall(() async {
        await _datasource.deleteGoal(goalId: goalId);
      });

  // ═══════════════════════════════════════════════════════════════════════
  // PROGRESS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudentProgressEntity>>> getProgress({
    required String studentId,
    ProgressPeriod? period,
    String? subjectId,
    int limit = 12,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getProgress(
          studentId: studentId,
          period: period?.value,
          subjectId: subjectId,
          limit: limit,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<StudentProgressEntity>> getLatestProgress({
    required String studentId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getLatestProgress(
          studentId: studentId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<List<StudentDailyActivityEntity>>> getDailyActivity({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getDailyActivity(
          studentId: studentId,
          startDate: startDate,
          endDate: endDate,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
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
  }) =>
      _safeCall(() async {
        final model = await _datasource.upsertDailyActivity(
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
        return model.toEntity();
      });

  @override
  Future<Result<StudentDashboardStats>> getDashboardStats({
    required String studentId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getDashboardStats(
          studentId: studentId,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudentNotificationEntity>>> getNotifications({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getNotifications(
          studentId: studentId,
          page: page,
          pageSize: pageSize,
          unreadOnly: unreadOnly,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<void>> markNotificationRead({
    required String notificationId,
  }) =>
      _safeCall(() async {
        await _datasource.markNotificationRead(
          notificationId: notificationId,
        );
      });

  @override
  Future<Result<void>> markAllNotificationsRead({
    required String studentId,
  }) =>
      _safeCall(() async {
        await _datasource.markAllNotificationsRead(studentId: studentId);
      });

  // ═══════════════════════════════════════════════════════════════════════
  // INTEGRATION: AI QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<Map<String, dynamic>>>> generateQuestionsFromContent({
    required String studentId,
    required String content,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    int questionCount = 5,
    String questionType = 'multiple_choice',
  }) =>
      _safeCall(() async {
        final result = await _datasource.generateQuestionsFromContent(
          studentId: studentId,
          content: content,
          subjectId: subjectId,
          topicId: topicId,
          difficulty: difficulty,
          questionCount: questionCount,
          questionType: questionType,
        );
        return result;
      });
}
