import 'dart:math';

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';
import '../models/student_portal_models.dart';

/// Remote datasource for the Student Portal feature.
///
/// Uses the Supabase Flutter client to interact with the database,
/// Storage, and Edge Functions. All methods return model types that
/// can be mapped to domain entities by the repository implementation.
class StudentPortalRemoteDatasource {
  StudentPortalRemoteDatasource({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _aiTutorConversationsTable = 'ai_tutor_conversations';
  static const _aiTutorMessagesTable = 'ai_tutor_messages';
  static const _practiceSessionsTable = 'practice_sessions';
  static const _practiceAnswersTable = 'practice_answers';
  static const _assignmentSubmissionsTable = 'assignment_submissions';
  static const _studentLearningResourcesTable = 'student_learning_resources';
  static const _resourceAccessLogTable = 'resource_access_log';
  static const _documentChatsTable = 'document_chats';
  static const _documentChatMessagesTable = 'document_chat_messages';
  static const _flashcardDecksTable = 'flashcard_decks';
  static const _flashcardsTable = 'flashcards';
  static const _studyPlansTable = 'study_plans';
  static const _studyTasksTable = 'study_tasks';
  static const _studentGoalsTable = 'student_goals';
  static const _studentProgressSnapshotsTable = 'student_progress_snapshots';
  static const _studentDailyActivityTable = 'student_daily_activity';
  static const _studentNotificationsTable = 'student_notifications';
  static const _studentDashboardView = 'v_student_dashboard';
  static const _questionsTable = 'questions';

  // ── Storage bucket ─────────────────────────────────────────────────────
  static const _studentDocumentsBucket = 'student-documents';

  // ── Edge function names ────────────────────────────────────────────────
  static const _aiTutorChatFunction = 'ai-tutor-chat';
  static const _generateFlashcardsFunction = 'generate-flashcards';
  static const _suggestStudyPlanFunction = 'suggest-study-plan';
  static const _processDocumentFunction = 'process-document';
  static const _generateQuestionsFunction = 'generate-questions';

  // ── Exception mapping helper ───────────────────────────────────────────

  /// Maps a [sb.PostgrestException] to the appropriate domain exception.
  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(message: e.message);
      case '23505':
        throw const ServerException(
          message: 'A record with this data already exists.',
          statusCode: 409,
        );
      case '23503':
        throw const ServerException(
          message: 'Referenced record not found.',
          statusCode: 404,
        );
      case '42501':
        throw const ForbiddenException(
          message: 'You do not have permission for this action.',
        );
      default:
        throw ServerException(
          message: e.message,
          statusCode: int.tryParse(e.code ?? '') ?? 500,
        );
    }
  }

  /// Handles generic catch-all exceptions.
  Never _handleGenericException(Object e, String operation) {
    AppLogger.error('Failed to $operation', error: e);
    if (e is sb.AuthException) {
      throw UnauthorizedException(message: e.message);
    }
    throw ServerException(message: e.toString(), statusCode: 500);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI TUTOR
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a new AI tutor conversation.
  ///
  /// Inserts a new row into [ai_tutor_conversations] and returns the
  /// fully-hydrated model from the database.
  Future<AiTutorConversationModel> createConversation({
    required String studentId,
    String? schoolId,
    String title = 'New Conversation',
    String? subjectId,
    String? topic,
    String curriculumType = 'nigerian',
  }) async {
    try {
      AppLogger.info('Creating AI tutor conversation for student: $studentId');
      final response = await _supabase
          .from(_aiTutorConversationsTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'title': title,
            'subject_id': subjectId,
            'topic': topic,
            'curriculum_type': curriculumType,
          })
          .select()
          .single();
      AppLogger.info('AI tutor conversation created successfully');
      return AiTutorConversationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create AI tutor conversation');
    }
  }

  /// Fetches paginated conversations for a student.
  ///
  /// Results are ordered by [updated_at] descending so the most
  /// recently active conversations appear first.
  Future<List<AiTutorConversationModel>> getConversations({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info(
        'Fetching AI tutor conversations for student: $studentId (page: $page)',
      );
      final offset = (page - 1) * pageSize;
      final response = await _supabase
          .from(_aiTutorConversationsTable)
          .select()
          .eq('student_id', studentId)
          .eq('is_archived', false)
          .order('updated_at', ascending: false)
          .range(offset, offset + pageSize - 1);
      return response
          .map((json) => AiTutorConversationModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch AI tutor conversations');
    }
  }

  /// Gets a single conversation with all its messages.
  ///
  /// Returns a map containing both the conversation and its messages
  /// for the repository to assemble into a rich domain entity.
  Future<Map<String, dynamic>> getConversationDetail({
    required String conversationId,
  }) async {
    try {
      AppLogger.info(
        'Fetching AI tutor conversation detail: $conversationId',
      );

      // Fetch the conversation record
      final conversationResponse = await _supabase
          .from(_aiTutorConversationsTable)
          .select()
          .eq('id', conversationId)
          .single();

      // Fetch all messages for this conversation
      // PERF: Added limit to prevent unbounded query on ai_tutor_messages
      final messagesResponse = await _supabase
          .from(_aiTutorMessagesTable)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      final messages = messagesResponse
          .map((json) => AiTutorMessageModel.fromJson(json))
          .toList();

      return {
        'conversation': AiTutorConversationModel.fromJson(conversationResponse),
        'messages': messages,
      };
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch conversation detail');
    }
  }

  /// Sends a message in an AI tutor conversation and receives an AI response.
  ///
  /// The flow is:
  /// 1. Insert the user message into [ai_tutor_messages].
  /// 2. Call the `ai-tutor-chat` Edge Function with conversation context.
  /// 3. Insert the AI assistant message into [ai_tutor_messages].
  /// 4. Update the conversation's [last_message] and [message_count].
  /// 5. Return the AI response model.
  Future<AiTutorMessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? subjectId,
    String? topic,
    String? curriculumType,
  }) async {
    try {
      AppLogger.info(
        'Sending message in conversation: $conversationId',
      );

      // 1. Insert the user message
      final userMessageResponse = await _supabase
          .from(_aiTutorMessagesTable)
          .insert({
            'conversation_id': conversationId,
            'role': 'user',
            'content': content,
          })
          .select()
          .single();

      AppLogger.info('User message inserted');

      // 2. Call the AI tutor Edge Function for a response
      final aiResponse = await _supabase.functions.invoke(
        _aiTutorChatFunction,
        body: {
          'conversation_id': conversationId,
          'message': content,
          'subject_id': subjectId,
          'topic': topic,
          'curriculum_type': curriculumType,
        },
      );

      if (aiResponse.status != 200) {
        AppLogger.error(
          'AI tutor edge function returned status: ${aiResponse.status}',
        );
        throw ServerException(
          message: 'AI tutor service returned an error: ${aiResponse.data}',
          statusCode: aiResponse.status,
        );
      }

      final aiContent = aiResponse.data['content'] as String? ??
          'I apologize, but I was unable to generate a response. Please try again.';
      final aiMetadata = aiResponse.data['metadata'] as Map<String, dynamic>?;

      // 3. Insert the AI assistant message
      final assistantMessageResponse = await _supabase
          .from(_aiTutorMessagesTable)
          .insert({
            'conversation_id': conversationId,
            'role': 'assistant',
            'content': aiContent,
            'metadata': aiMetadata ?? {},
          })
          .select()
          .single();

      // 4. Update the conversation's last_message and message_count
      await _supabase
          .from(_aiTutorConversationsTable)
          .update({
            'last_message': aiContent.length > 100
                ? '${aiContent.substring(0, 100)}...'
                : aiContent,
          })
          .eq('id', conversationId);

      AppLogger.info('AI response message inserted');

      return AiTutorMessageModel.fromJson(assistantMessageResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'send AI tutor message');
    }
  }

  /// Deletes a conversation and all its messages.
  ///
  /// Relies on the database CASCADE delete configured on the
  /// foreign key from [ai_tutor_messages] to [ai_tutor_conversations].
  Future<void> deleteConversation({
    required String conversationId,
  }) async {
    try {
      AppLogger.info('Deleting conversation: $conversationId');
      await _supabase
          .from(_aiTutorConversationsTable)
          .delete()
          .eq('id', conversationId);
      AppLogger.info('Conversation deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete conversation');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRACTICE SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a new practice session and fetches random questions from
  /// the question bank matching the given filters.
  ///
  /// The session is created in `in_progress` status. Questions are
  /// selected from the [questions] table using random ordering and
  /// subject/difficulty filters.
  Future<PracticeSessionModel> createPracticeSession({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    String mode = 'untimed',
    int? timeLimitSec,
    int questionCount = 10,
  }) async {
    try {
      AppLogger.info(
        'Creating practice session for student: $studentId',
      );

      // Insert the practice session
      final sessionResponse = await _supabase
          .from(_practiceSessionsTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'subject_id': subjectId,
            'topic_id': topicId,
            'difficulty': difficulty,
            'mode': mode,
            'time_limit_sec': timeLimitSec,
            'total_questions': questionCount,
            'status': 'in_progress',
            'started_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      final sessionId = sessionResponse['id'] as String;

      // Fetch random questions from the question bank
      var query = _supabase
          .from(_questionsTable)
          .select('id')
          .eq('status', 'approved');

      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (difficulty != 'mixed') {
        query = query.eq('difficulty', difficulty);
      }

      // Use limit and random ordering via Supabase
      final questionIds = await query
          .limit(questionCount * 3) // Fetch extra for randomness
          .order('id');

      // Randomly select the desired number of questions
      final selectedQuestions = <Map<String, dynamic>>[];
      if (questionIds.isNotEmpty) {
        final shuffled = List<Map<String, dynamic>>.from(questionIds)..shuffle();
        selectedQuestions.addAll(
          shuffled.take(min(questionCount, shuffled.length)),
        );
      }

      // Store the question IDs as the session's question set
      // (practice_answers will be created as students answer)
      // Update the total_questions to match actual available count
      if (selectedQuestions.length != questionCount) {
        await _supabase
            .from(_practiceSessionsTable)
            .update({'total_questions': selectedQuestions.length})
            .eq('id', sessionId);
        sessionResponse['total_questions'] = selectedQuestions.length;
      }

      AppLogger.info(
        'Practice session created: $sessionId with ${selectedQuestions.length} questions',
      );

      return PracticeSessionModel.fromJson(sessionResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create practice session');
    }
  }

  /// Gets practice sessions for a student with pagination and optional
  /// status/subject filters.
  Future<List<PracticeSessionModel>> getPracticeSessions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    String? status,
    String? subjectId,
  }) async {
    try {
      AppLogger.info(
        'Fetching practice sessions for student: $studentId',
      );
      final offset = (page - 1) * pageSize;

      var query = _supabase
          .from(_practiceSessionsTable)
          .select('*, subjects(name)')
          .eq('student_id', studentId);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) {
        // Flatten joined subject name
        final subjectData = json['subjects'] as Map<String, dynamic>?;
        return PracticeSessionModel.fromJson({
          ...json,
          'subject_name': subjectData?['name'] as String?,
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch practice sessions');
    }
  }

  /// Gets a single practice session detail, including all answers.
  Future<PracticeSessionModel> getPracticeSessionDetail({
    required String sessionId,
  }) async {
    try {
      AppLogger.info('Fetching practice session detail: $sessionId');

      final sessionResponse = await _supabase
          .from(_practiceSessionsTable)
          .select('*, subjects(name)')
          .eq('id', sessionId)
          .single();

      // Fetch answers for this session
      // PERF: Added limit to prevent unbounded query on practice_answers
      final answersResponse = await _supabase
          .from(_practiceAnswersTable)
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      final subjectData = sessionResponse['subjects'] as Map<String, dynamic>?;

      return PracticeSessionModel.fromJson({
        ...sessionResponse,
        'subject_name': subjectData?['name'] as String?,
        // Answers are available for the repository to assemble
        'answers': answersResponse
            .map((a) => PracticeAnswerModel.fromJson(a))
            .toList(),
      });
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch practice session detail');
    }
  }

  /// Submits an answer for a practice question.
  ///
  /// Inserts the answer and, if correct, increments the session's
  /// [correct_count]. The [score_pct] is recalculated on the fly.
  Future<PracticeAnswerModel> submitPracticeAnswer({
    required String sessionId,
    required String questionId,
    required Map<String, dynamic> studentAnswer,
    int timeSpentSec = 0,
  }) async {
    try {
      AppLogger.info(
        'Submitting practice answer for session: $sessionId, question: $questionId',
      );

      // Insert the answer
      final answerResponse = await _supabase
          .from(_practiceAnswersTable)
          .insert({
            'session_id': sessionId,
            'question_id': questionId,
            'student_answer': studentAnswer,
            'time_spent_sec': timeSpentSec,
          })
          .select()
          .single();

      final isCorrect = answerResponse['is_correct'] as bool? ?? false;

      // Update session correct_count if answer is correct
      if (isCorrect) {
        await _supabase.rpc('increment_practice_correct_count', params: {
          'session_id': sessionId,
        },);
      }

      AppLogger.info('Practice answer submitted successfully');
      return PracticeAnswerModel.fromJson(answerResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'submit practice answer');
    }
  }

  /// Completes a practice session.
  ///
  /// Sets the status to `completed`, calculates the final score
  /// percentage, and records the completion timestamp.
  Future<PracticeSessionModel> completePracticeSession({
    required String sessionId,
  }) async {
    try {
      AppLogger.info('Completing practice session: $sessionId');

      // Fetch current session to compute score
      final current = await _supabase
          .from(_practiceSessionsTable)
          .select('total_questions, correct_count')
          .eq('id', sessionId)
          .single();

      final totalQ = current['total_questions'] as int? ?? 0;
      final correctQ = current['correct_count'] as int? ?? 0;
      final scorePct = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;

      final response = await _supabase
          .from(_practiceSessionsTable)
          .update({
            'status': 'completed',
            'score_pct': scorePct,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      AppLogger.info(
        'Practice session completed: $sessionId (score: ${scorePct.toStringAsFixed(1)}%)',
      );
      return PracticeSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'complete practice session');
    }
  }

  /// Abandons a practice session.
  ///
  /// Sets the status to `abandoned` and records the completion
  /// timestamp so the session is no longer shown as active.
  Future<void> abandonPracticeSession({
    required String sessionId,
  }) async {
    try {
      AppLogger.info('Abandoning practice session: $sessionId');
      await _supabase
          .from(_practiceSessionsTable)
          .update({
            'status': 'abandoned',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId);
      AppLogger.info('Practice session abandoned');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'abandon practice session');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT SUBMISSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all submissions for a student with pagination and optional
  /// status filter. Joins assignment info for display.
  Future<List<AssignmentSubmissionModel>> getSubmissions({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      AppLogger.info('Fetching submissions for student: $studentId');
      final offset = (page - 1) * pageSize;

      var query = _supabase
          .from(_assignmentSubmissionsTable)
          .select('*, workspace_assignments(title, due_date, subjects(name), profiles!workspace_assignments_teacher_id_fkey(full_name))')
          .eq('student_id', studentId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) {
        final assignment = json['workspace_assignments'] as Map<String, dynamic>?;
        final subject = assignment?['subjects'] as Map<String, dynamic>?;
        final teacher = assignment?['profiles'] as Map<String, dynamic>?;
        return AssignmentSubmissionModel.fromJson({
          ...json,
          'assignment_title': assignment?['title'] as String?,
          'due_date': assignment?['due_date'] as String?,
          'subject_name': subject?['name'] as String?,
          'teacher_name': teacher?['full_name'] as String?,
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch submissions');
    }
  }

  /// Gets a single submission by ID, including assignment metadata.
  Future<AssignmentSubmissionModel> getSubmissionDetail({
    required String submissionId,
  }) async {
    try {
      AppLogger.info('Fetching submission detail: $submissionId');

      final response = await _supabase
          .from(_assignmentSubmissionsTable)
          .select('*, workspace_assignments(title, due_date, max_score, subjects(name), profiles!workspace_assignments_teacher_id_fkey(full_name))')
          .eq('id', submissionId)
          .single();

      final assignment =
          response['workspace_assignments'] as Map<String, dynamic>?;
      final subject = assignment?['subjects'] as Map<String, dynamic>?;
      final teacher = assignment?['profiles'] as Map<String, dynamic>?;

      return AssignmentSubmissionModel.fromJson({
        ...response,
        'assignment_title': assignment?['title'] as String?,
        'due_date': assignment?['due_date'] as String?,
        'max_score': assignment?['max_score'],
        'subject_name': subject?['name'] as String?,
        'teacher_name': teacher?['full_name'] as String?,
      });
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch submission detail');
    }
  }

  /// Creates a draft submission for an assignment.
  Future<AssignmentSubmissionModel> createSubmission({
    required String assignmentId,
    required String studentId,
    String? schoolId,
    Map<String, dynamic> content = const {},
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      AppLogger.info(
        'Creating submission for assignment: $assignmentId',
      );
      final response = await _supabase
          .from(_assignmentSubmissionsTable)
          .insert({
            'assignment_id': assignmentId,
            'student_id': studentId,
            'school_id': schoolId,
            'content': content,
            'attachments': attachments,
            'status': 'draft',
          })
          .select()
          .single();
      AppLogger.info('Draft submission created successfully');
      return AssignmentSubmissionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create submission');
    }
  }

  /// Updates a submission (save draft or add attachments).
  Future<AssignmentSubmissionModel> updateSubmission({
    required String submissionId,
    Map<String, dynamic>? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      AppLogger.info('Updating submission: $submissionId');

      final updateData = <String, dynamic>{};
      if (content != null) updateData['content'] = content;
      if (attachments != null) updateData['attachments'] = attachments;

      final response = await _supabase
          .from(_assignmentSubmissionsTable)
          .update(updateData)
          .eq('id', submissionId)
          .select()
          .single();

      AppLogger.info('Submission updated successfully');
      return AssignmentSubmissionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update submission');
    }
  }

  /// Submits a draft assignment (changes status from draft to submitted).
  Future<AssignmentSubmissionModel> submitAssignment({
    required String submissionId,
  }) async {
    try {
      AppLogger.info('Submitting assignment: $submissionId');

      // Check if past due date for late_submitted logic
      final existing = await _supabase
          .from(_assignmentSubmissionsTable)
          .select('status, workspace_assignments(due_date)')
          .eq('id', submissionId)
          .single();

      final assignment = existing['workspace_assignments'] as Map<String, dynamic>?;
      final dueDate = assignment?['due_date'] != null
          ? DateTime.tryParse(assignment!['due_date'] as String)
          : null;
      final isLate = dueDate != null && DateTime.now().isAfter(dueDate);

      final newStatus = isLate ? 'late_submitted' : 'submitted';

      final response = await _supabase
          .from(_assignmentSubmissionsTable)
          .update({
            'status': newStatus,
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', submissionId)
          .select()
          .single();

      AppLogger.info('Assignment submitted with status: $newStatus');
      return AssignmentSubmissionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'submit assignment');
    }
  }

  /// Gets assignments assigned to the student that don't have a
  /// submission yet (for the "pending assignments" view).
  Future<List<AssignmentSubmissionModel>> getAssignedAssignments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info(
        'Fetching assigned assignments for student: $studentId',
      );
      final offset = (page - 1) * pageSize;

      // Fetch assigned assignments the student hasn't submitted yet
      final response = await _supabase
          .from(_assignmentSubmissionsTable)
          .select('*, workspace_assignments(title, due_date, subjects(name), profiles!workspace_assignments_teacher_id_fkey(full_name))')
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) {
        final assignment =
            json['workspace_assignments'] as Map<String, dynamic>?;
        final subject = assignment?['subjects'] as Map<String, dynamic>?;
        final teacher = assignment?['profiles'] as Map<String, dynamic>?;
        return AssignmentSubmissionModel.fromJson({
          ...json,
          'assignment_title': assignment?['title'] as String?,
          'due_date': assignment?['due_date'] as String?,
          'subject_name': subject?['name'] as String?,
          'teacher_name': teacher?['full_name'] as String?,
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch assigned assignments');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LEARNING RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets learning resources visible to a student (school-level + public).
  ///
  /// Supports filtering by resource type, subject, and free-text
  /// search query. Results are paginated.
  Future<List<LearningResourceModel>> getResources({
    required String studentId,
    String? schoolId,
    int page = 1,
    int pageSize = 20,
    String? resourceType,
    String? subjectId,
    String? searchQuery,
  }) async {
    try {
      AppLogger.info('Fetching learning resources for student: $studentId');
      final offset = (page - 1) * pageSize;

      var query = _supabase
          .from(_studentLearningResourcesTable)
          .select('*, subjects(name), profiles!teacher_id(full_name)')
          .or('is_public.eq.true,school_id.eq.$schoolId');

      if (resourceType != null) {
        query = query.eq('resource_type', resourceType);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) {
        final subject = json['subjects'] as Map<String, dynamic>?;
        final teacher = json['profiles'] as Map<String, dynamic>?;
        return LearningResourceModel.fromJson({
          ...json,
          'subject_name': subject?['name'] as String?,
          'teacher_name': teacher?['full_name'] as String?,
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch learning resources');
    }
  }

  /// Gets a single learning resource by ID.
  Future<LearningResourceModel> getResourceDetail({
    required String resourceId,
  }) async {
    try {
      AppLogger.info('Fetching resource detail: $resourceId');

      final response = await _supabase
          .from(_studentLearningResourcesTable)
          .select('*, subjects(name), profiles!teacher_id(full_name)')
          .eq('id', resourceId)
          .single();

      final subject = response['subjects'] as Map<String, dynamic>?;
      final teacher = response['profiles'] as Map<String, dynamic>?;

      return LearningResourceModel.fromJson({
        ...response,
        'subject_name': subject?['name'] as String?,
        'teacher_name': teacher?['full_name'] as String?,
      });
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch resource detail');
    }
  }

  /// Logs a resource access event (view or download).
  Future<void> logResourceAccess({
    required String resourceId,
    required String studentId,
    String accessType = 'view',
  }) async {
    try {
      AppLogger.info(
        'Logging resource access: $resourceId by student: $studentId',
      );

      await _supabase.from(_resourceAccessLogTable).insert({
        'resource_id': resourceId,
        'student_id': studentId,
        'access_type': accessType,
      });

      // Increment view/download counter on the resource
      final counterField =
          accessType == 'download' ? 'download_count' : 'view_count';
      await _supabase.rpc(
        'increment_resource_counter',
        params: {
          'resource_id': resourceId,
          'counter_field': counterField,
        },
      );

      AppLogger.info('Resource access logged successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'log resource access');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT CHAT
  // ═══════════════════════════════════════════════════════════════════════

  /// Uploads a document for AI chat processing.
  ///
  /// The flow is:
  /// 1. Upload the file to Supabase Storage bucket `student-documents`.
  /// 2. Create a `document_chats` record.
  /// 3. Call the `process-document` Edge Function for text extraction
  ///    (runs asynchronously).
  Future<DocumentChatModel> uploadDocument({
    required String studentId,
    String? schoolId,
    required String fileName,
    required Uint8List fileBytes,
    required String fileFormat,
    int? fileSize,
  }) async {
    try {
      AppLogger.info(
        'Uploading document for student: $studentId, file: $fileName',
      );

      // 1. Upload file to Supabase Storage
      final storagePath =
          '$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage
          .from(_studentDocumentsBucket)
          .uploadBinary(storagePath, fileBytes);

      // Get the public URL for the uploaded file
      final fileUrl = _supabase.storage
          .from(_studentDocumentsBucket)
          .getPublicUrl(storagePath);

      // 2. Create a document_chats record
      final response = await _supabase
          .from(_documentChatsTable)
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

      // Fire-and-forget: trigger the process-document edge function (async)
      // Errors are logged but don't block the upload response.
      _supabase.functions.invoke(
        _processDocumentFunction,
        body: {
          'document_id': documentId,
          'file_url': fileUrl,
          'file_format': fileFormat,
        },
      ).then((_) {
        AppLogger.info('Document processing initiated for $documentId');
      }).catchError((error) {
        AppLogger.error(
          'Process document edge function failed',
          error: error,
        );
      });

      AppLogger.info('Document uploaded and processing started: $documentId');
      return DocumentChatModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } on sb.StorageException catch (e) {
      AppLogger.error('Storage upload failed', error: e);
      throw ServerException(
        message: 'File upload failed: ${e.message}',
        statusCode: 500,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'upload document');
    }
  }

  /// Gets all documents for a student (paginated).
  Future<List<DocumentChatModel>> getDocuments({
    required String studentId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('Fetching documents for student: $studentId');
      final offset = (page - 1) * pageSize;

      final response = await _supabase
          .from(_documentChatsTable)
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response
          .map((json) => DocumentChatModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch documents');
    }
  }

  /// Gets a single document with its chat messages.
  Future<DocumentChatModel> getDocumentDetail({
    required String documentId,
  }) async {
    try {
      AppLogger.info('Fetching document detail: $documentId');

      final docResponse = await _supabase
          .from(_documentChatsTable)
          .select()
          .eq('id', documentId)
          .single();

      // Fetch chat messages for this document
      // PERF: Added limit to prevent unbounded query on document_chat_messages
      final messagesResponse = await _supabase
          .from(_documentChatMessagesTable)
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return DocumentChatModel.fromJson({
        ...docResponse,
        'messages': messagesResponse
            .map((m) => DocumentChatMessageModel.fromJson(m))
            .toList(),
      });
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch document detail');
    }
  }

  /// Sends a message in a document chat and receives an AI response.
  ///
  /// Inserts the user message, calls the AI Edge Function, then
  /// inserts the AI response message.
  Future<DocumentChatMessageModel> sendDocumentMessage({
    required String documentId,
    required String content,
  }) async {
    try {
      AppLogger.info(
        'Sending document message for document: $documentId',
      );

      // 1. Insert user message
      await _supabase.from(_documentChatMessagesTable).insert({
        'document_id': documentId,
        'role': 'user',
        'content': content,
      });

      // 2. Call AI edge function for document chat response
      final aiResponse = await _supabase.functions.invoke(
        _aiTutorChatFunction,
        body: {
          'document_id': documentId,
          'message': content,
          'mode': 'document_chat',
        },
      );

      if (aiResponse.status != 200) {
        throw ServerException(
          message: 'Document chat AI service error',
          statusCode: aiResponse.status,
        );
      }

      final aiContent = aiResponse.data['content'] as String? ??
          'I was unable to process your question about this document. Please try again.';
      final aiMetadata = aiResponse.data['metadata'] as Map<String, dynamic>?;

      // 3. Insert AI response message
      final assistantMessageResponse = await _supabase
          .from(_documentChatMessagesTable)
          .insert({
            'document_id': documentId,
            'role': 'assistant',
            'content': aiContent,
            'metadata': aiMetadata ?? {},
          })
          .select()
          .single();

      AppLogger.info('Document chat message sent successfully');
      return DocumentChatMessageModel.fromJson(assistantMessageResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'send document message');
    }
  }

  /// Deletes a document, its chat messages, and the stored file.
  Future<void> deleteDocument({required String documentId}) async {
    try {
      AppLogger.info('Deleting document: $documentId');

      // Fetch the document to get the storage path
      final doc = await _supabase
          .from(_documentChatsTable)
          .select('file_url, student_id')
          .eq('id', documentId)
          .single();

      // Delete from database (cascade deletes messages)
      await _supabase
          .from(_documentChatsTable)
          .delete()
          .eq('id', documentId);

      // Attempt to remove the file from storage (best-effort)
      final fileUrl = doc['file_url'] as String?;
      if (fileUrl != null) {
        try {
          final studentId = doc['student_id'] as String;
          // Extract the storage path from the URL
          final uri = Uri.parse(fileUrl);
          final pathSegments = uri.pathSegments;
          final storagePath = pathSegments.skip(2).join('/');
          await _supabase.storage
              .from(_studentDocumentsBucket)
              .remove([storagePath]);
        } catch (storageError) {
          AppLogger.warning(
            'Failed to delete document from storage (non-critical)',
            error: storageError,
          );
        }
      }

      AppLogger.info('Document deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete document');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FLASHCARDS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all flashcard decks for a student.
  ///
  /// Includes a computed [due_count] — the number of cards whose
  /// next review date has passed. Supports filtering by favorite
  /// status and subject.
  Future<List<FlashcardDeckModel>> getFlashcardDecks({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? isFavorite,
    String? subjectId,
  }) async {
    try {
      AppLogger.info('Fetching flashcard decks for student: $studentId');
      final offset = (page - 1) * pageSize;

      var query = _supabase
          .from(_flashcardDecksTable)
          .select('*, subjects(name), flashcards(count)')
          .eq('student_id', studentId);

      if (isFavorite != null) {
        query = query.eq('is_favorite', isFavorite);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response.map((json) {
        final subject = json['subjects'] as Map<String, dynamic>?;
        final flashcardAgg = json['flashcards'] as List<dynamic>?;

        // Compute due count from flashcards (cards where next_review <= now)
        const int dueCount = 0;
        // The aggregate count from Supabase gives total, we need a
        // separate query for due count — use a fallback approach
        return FlashcardDeckModel.fromJson({
          ...json,
          'subject_name': subject?['name'] as String?,
          'card_count': flashcardAgg?.first?['count'] as int? ?? 0,
          'due_count': dueCount, // Will be enriched separately
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch flashcard decks');
    }
  }

  /// Creates a new flashcard deck.
  Future<FlashcardDeckModel> createFlashcardDeck({
    required String studentId,
    String? schoolId,
    String? subjectId,
    String? topicId,
    required String title,
    String? description,
    String sourceType = 'manual',
    String? sourceId,
    List<String> tags = const [],
  }) async {
    try {
      AppLogger.info('Creating flashcard deck: $title');
      final response = await _supabase
          .from(_flashcardDecksTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'subject_id': subjectId,
            'topic_id': topicId,
            'title': title,
            'description': description,
            'source_type': sourceType,
            'source_id': sourceId,
            'tags': tags,
          })
          .select()
          .single();
      AppLogger.info('Flashcard deck created successfully');
      return FlashcardDeckModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create flashcard deck');
    }
  }

  /// Updates a flashcard deck's metadata.
  Future<FlashcardDeckModel> updateFlashcardDeck({
    required String deckId,
    String? title,
    String? description,
    bool? isFavorite,
    List<String>? tags,
  }) async {
    try {
      AppLogger.info('Updating flashcard deck: $deckId');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;
      if (tags != null) updateData['tags'] = tags;

      final response = await _supabase
          .from(_flashcardDecksTable)
          .update(updateData)
          .eq('id', deckId)
          .select()
          .single();

      AppLogger.info('Flashcard deck updated successfully');
      return FlashcardDeckModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update flashcard deck');
    }
  }

  /// Deletes a flashcard deck and all its cards (cascade).
  Future<void> deleteFlashcardDeck({required String deckId}) async {
    try {
      AppLogger.info('Deleting flashcard deck: $deckId');
      await _supabase
          .from(_flashcardDecksTable)
          .delete()
          .eq('id', deckId);
      AppLogger.info('Flashcard deck deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete flashcard deck');
    }
  }

  /// Gets flashcards in a deck.
  ///
  /// When [dueOnly] is true, only returns cards whose [next_review]
  /// datetime is in the past (i.e. they are due for review).
  Future<List<FlashcardModel>> getFlashcards({
    required String deckId,
    bool dueOnly = false,
  }) async {
    try {
      AppLogger.info(
        'Fetching flashcards for deck: $deckId (dueOnly: $dueOnly)',
      );

      var query = _supabase
          .from(_flashcardsTable)
          .select()
          .eq('deck_id', deckId);

      if (dueOnly) {
        query = query.lte('next_review', DateTime.now().toUtc().toIso8601String());
      }

      // PERF: Added limit to prevent unbounded query on flashcards
      final response = await query.order('created_at', ascending: true).limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map((json) => FlashcardModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch flashcards');
    }
  }

  /// Creates a new flashcard in a deck.
  Future<FlashcardModel> createFlashcard({
    required String deckId,
    required String frontContent,
    required String backContent,
    String? hint,
    String? imageUrl,
    String difficulty = 'medium',
  }) async {
    try {
      AppLogger.info('Creating flashcard in deck: $deckId');
      final response = await _supabase
          .from(_flashcardsTable)
          .insert({
            'deck_id': deckId,
            'front_content': frontContent,
            'back_content': backContent,
            'hint': hint,
            'image_url': imageUrl,
            'difficulty': difficulty,
            'ease_factor': 2.5,
            'interval': 0,
            'repetitions': 0,
            'next_review': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      AppLogger.info('Flashcard created successfully');
      return FlashcardModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create flashcard');
    }
  }

  /// Updates a flashcard's content fields.
  Future<FlashcardModel> updateFlashcard({
    required String cardId,
    String? frontContent,
    String? backContent,
    String? hint,
  }) async {
    try {
      AppLogger.info('Updating flashcard: $cardId');

      final updateData = <String, dynamic>{};
      if (frontContent != null) updateData['front_content'] = frontContent;
      if (backContent != null) updateData['back_content'] = backContent;
      if (hint != null) updateData['hint'] = hint;

      final response = await _supabase
          .from(_flashcardsTable)
          .update(updateData)
          .eq('id', cardId)
          .select()
          .single();

      AppLogger.info('Flashcard updated successfully');
      return FlashcardModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update flashcard');
    }
  }

  /// Rates a flashcard using the SM-2 spaced repetition algorithm.
  ///
  /// The rating can be one of: `again`, `hard`, `good`, `easy`.
  ///
  /// **SM-2 Algorithm Implementation:**
  /// - `again`: repetitions = 0, interval = 1 min
  /// - `hard`:  easeFactor -= 0.15, interval = interval * 1.2
  /// - `good`:  interval = interval * easeFactor
  /// - `easy`:  easeFactor += 0.15, interval = interval * easeFactor * 1.3
  /// - easeFactor is clamped between 1.3 and 3.0
  /// - If repetitions == 0: interval = 1 day
  /// - If repetitions == 1: interval = 6 days
  /// - Else: interval = previousInterval * easeFactor
  Future<FlashcardModel> rateFlashcard({
    required String cardId,
    required String rating,
  }) async {
    try {
      AppLogger.info('Rating flashcard: $cardId with rating: $rating');

      // 1. Fetch the current card state
      final current = await _supabase
          .from(_flashcardsTable)
          .select()
          .eq('id', cardId)
          .single();

      var repetitions = current['repetitions'] as int? ?? 0;
      var easeFactor = (current['ease_factor'] as num?)?.toDouble() ?? 2.5;
      var interval = (current['interval'] as num?)?.toDouble() ?? 0.0;
      final previousInterval = interval;

      // 2. Apply SM-2 algorithm based on rating
      switch (rating) {
        case 'again':
          repetitions = 0;
          interval = 1.0 / 1440.0; // 1 minute in days (~0.000694 days)
          // Alternatively, we can set next_review to now + 1 minute directly
          break;
        case 'hard':
          easeFactor = max(1.3, easeFactor - 0.15);
          interval = previousInterval * 1.2;
          if (interval < 1) interval = 1;
          repetitions = repetitions + 1;
          break;
        case 'good':
          if (repetitions == 0) {
            interval = 1; // 1 day
          } else if (repetitions == 1) {
            interval = 6; // 6 days
          } else {
            interval = previousInterval * easeFactor;
          }
          repetitions = repetitions + 1;
          break;
        case 'easy':
          easeFactor = min(3.0, easeFactor + 0.15);
          if (repetitions == 0) {
            interval = 1;
          } else if (repetitions == 1) {
            interval = 6;
          } else {
            interval = previousInterval * easeFactor;
          }
          interval = interval * 1.3;
          repetitions = repetitions + 1;
          break;
        default:
          throw ValidationException(
            message: 'Invalid flashcard rating: $rating',
            fieldErrors: {'rating': 'Must be one of: again, hard, good, easy'},
          );
      }

      // 3. Clamp easeFactor
      easeFactor = easeFactor.clamp(1.3, 3.0);

      // 4. Compute next review date
      final nextReview = DateTime.now().add(Duration(
        milliseconds: (interval * 24 * 60 * 60 * 1000).round(),
      ),);

      // 5. Persist the updated SM-2 state
      final response = await _supabase
          .from(_flashcardsTable)
          .update({
            'repetitions': repetitions,
            'ease_factor': easeFactor,
            'interval': interval,
            'next_review': nextReview.toUtc().toIso8601String(),
            'last_reviewed': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', cardId)
          .select()
          .single();

      AppLogger.info(
        'Flashcard rated: $cardId → next review in ${interval.toStringAsFixed(1)} days',
      );
      return FlashcardModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ValidationException) rethrow;
      _handleGenericException(e, 'rate flashcard');
    }
  }

  /// Deletes a single flashcard.
  Future<void> deleteFlashcard({required String cardId}) async {
    try {
      AppLogger.info('Deleting flashcard: $cardId');
      await _supabase
          .from(_flashcardsTable)
          .delete()
          .eq('id', cardId);
      AppLogger.info('Flashcard deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete flashcard');
    }
  }

  /// Generates flashcards from content using AI.
  ///
  /// Calls the `generate-flashcards` Edge Function, then creates
  /// a deck and populates it with the generated cards.
  Future<FlashcardDeckModel> generateFlashcards({
    required String studentId,
    String? schoolId,
    required String title,
    String? subjectId,
    String? topicId,
    required String sourceContent,
    String sourceType = 'ai_generated',
    int cardCount = 10,
  }) async {
    try {
      AppLogger.info(
        'Generating flashcards from content for student: $studentId',
      );

      // 1. Call the generate-flashcards edge function
      final aiResponse = await _supabase.functions.invoke(
        _generateFlashcardsFunction,
        body: {
          'student_id': studentId,
          'title': title,
          'subject_id': subjectId,
          'topic_id': topicId,
          'source_content': sourceContent,
          'card_count': cardCount,
        },
      );

      if (aiResponse.status != 200) {
        throw ServerException(
          message: 'Flashcard generation failed: ${aiResponse.data}',
          statusCode: aiResponse.status,
        );
      }

      final generatedCards = aiResponse.data['cards'] as List<dynamic>? ?? [];

      // 2. Create the deck
      final deckResponse = await _supabase
          .from(_flashcardDecksTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'subject_id': subjectId,
            'topic_id': topicId,
            'title': title,
            'source_type': sourceType,
            'tags': ['ai_generated'],
          })
          .select()
          .single();

      final deckId = deckResponse['id'] as String;

      // 3. Create all the generated flashcards in the deck
      if (generatedCards.isNotEmpty) {
        final cardsToInsert = generatedCards.map((card) {
          final cardMap = card as Map<String, dynamic>;
          return {
            'deck_id': deckId,
            'front_content': cardMap['front'] as String? ?? '',
            'back_content': cardMap['back'] as String? ?? '',
            'hint': cardMap['hint'] as String?,
            'difficulty': cardMap['difficulty'] as String? ?? 'medium',
            'ease_factor': 2.5,
            'interval': 0,
            'repetitions': 0,
            'next_review': DateTime.now().toUtc().toIso8601String(),
          };
        }).toList();

        await _supabase
            .from(_flashcardsTable)
            .insert(cardsToInsert);
      }

      AppLogger.info(
        'Generated flashcard deck: $deckId with ${generatedCards.length} cards',
      );
      return FlashcardDeckModel.fromJson(deckResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'generate flashcards');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLANNER
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all study plans for a student, optionally including their
  /// tasks. Supports filtering by [isActive] status.
  Future<List<StudyPlanModel>> getStudyPlans({
    required String studentId,
    bool? isActive,
  }) async {
    try {
      AppLogger.info('Fetching study plans for student: $studentId');

      var query = _supabase
          .from(_studyPlansTable)
          .select('*, study_tasks(*)')
          .eq('student_id', studentId);

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      // PERF: Added limit to prevent unbounded query on study_plans
      final response = await query
          .order('created_at', ascending: false)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response.map((json) {
        final tasks = (json['study_tasks'] as List<dynamic>?)
                ?.map((t) => StudyTaskModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [];
        return StudyPlanModel.fromJson({
          ...json,
          'tasks': tasks,
        });
      }).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch study plans');
    }
  }

  /// Creates a new study plan with optional initial tasks.
  Future<StudyPlanModel> createStudyPlan({
    required String studentId,
    String? schoolId,
    required String title,
    String? description,
    String frequency = 'daily',
    required DateTime startDate,
    DateTime? endDate,
    List<Map<String, dynamic>> tasks = const [],
  }) async {
    try {
      AppLogger.info('Creating study plan: $title');

      final planResponse = await _supabase
          .from(_studyPlansTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'title': title,
            'description': description,
            'frequency': frequency,
            'start_date': startDate.toUtc().toIso8601String(),
            'end_date': endDate?.toUtc().toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();

      final planId = planResponse['id'] as String;

      // Insert initial tasks if provided
      if (tasks.isNotEmpty) {
        final tasksToInsert = tasks.map((task) {
          return {
            'plan_id': planId,
            'subject_id': task['subject_id'] as String?,
            'title': task['title'] as String,
            'description': task['description'] as String?,
            'scheduled_date': (task['scheduled_date'] as DateTime)
                .toUtc()
                .toIso8601String(),
            'start_time': task['start_time'] != null
                ? (task['start_time'] as DateTime).toUtc().toIso8601String()
                : null,
            'end_time': task['end_time'] != null
                ? (task['end_time'] as DateTime).toUtc().toIso8601String()
                : null,
          };
        }).toList();

        await _supabase.from(_studyTasksTable).insert(tasksToInsert);
      }

      AppLogger.info('Study plan created: $planId');
      return StudyPlanModel.fromJson(planResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create study plan');
    }
  }

  /// Updates a study plan's metadata.
  Future<StudyPlanModel> updateStudyPlan({
    required String planId,
    String? title,
    String? description,
    String? frequency,
    DateTime? endDate,
    bool? isActive,
  }) async {
    try {
      AppLogger.info('Updating study plan: $planId');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (frequency != null) updateData['frequency'] = frequency;
      if (endDate != null) updateData['end_date'] = endDate.toUtc().toIso8601String();
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from(_studyPlansTable)
          .update(updateData)
          .eq('id', planId)
          .select()
          .single();

      AppLogger.info('Study plan updated successfully');
      return StudyPlanModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update study plan');
    }
  }

  /// Deletes a study plan and all its tasks (cascade).
  Future<void> deleteStudyPlan({required String planId}) async {
    try {
      AppLogger.info('Deleting study plan: $planId');
      await _supabase
          .from(_studyPlansTable)
          .delete()
          .eq('id', planId);
      AppLogger.info('Study plan deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete study plan');
    }
  }

  /// Creates a new study task within a plan.
  Future<StudyTaskModel> createStudyTask({
    required String planId,
    String? subjectId,
    required String title,
    String? description,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.info('Creating study task: $title in plan: $planId');

      final response = await _supabase
          .from(_studyTasksTable)
          .insert({
            'plan_id': planId,
            'subject_id': subjectId,
            'title': title,
            'description': description,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'start_time': startTime?.toUtc().toIso8601String(),
            'end_time': endTime?.toUtc().toIso8601String(),
          })
          .select()
          .single();

      AppLogger.info('Study task created successfully');
      return StudyTaskModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create study task');
    }
  }

  /// Updates a study task's status, completion, or notes.
  Future<StudyTaskModel> updateStudyTask({
    required String taskId,
    String? status,
    double? completionPct,
    String? notes,
  }) async {
    try {
      AppLogger.info('Updating study task: $taskId');

      final updateData = <String, dynamic>{};
      if (status != null) updateData['status'] = status;
      if (completionPct != null) updateData['completion_pct'] = completionPct;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabase
          .from(_studyTasksTable)
          .update(updateData)
          .eq('id', taskId)
          .select()
          .single();

      AppLogger.info('Study task updated successfully');
      return StudyTaskModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update study task');
    }
  }

  /// Deletes a study task.
  Future<void> deleteStudyTask({required String taskId}) async {
    try {
      AppLogger.info('Deleting study task: $taskId');
      await _supabase
          .from(_studyTasksTable)
          .delete()
          .eq('id', taskId);
      AppLogger.info('Study task deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete study task');
    }
  }

  /// Gets an AI-suggested study plan based on student progress.
  ///
  /// Calls the `suggest-study-plan` Edge Function which analyzes
  /// the student's performance data and generates a personalized plan.
  Future<StudyPlanModel> suggestStudyPlan({
    required String studentId,
    String? schoolId,
    String? focusSubjectId,
  }) async {
    try {
      AppLogger.info(
        'Requesting AI study plan suggestion for student: $studentId',
      );

      final aiResponse = await _supabase.functions.invoke(
        _suggestStudyPlanFunction,
        body: {
          'student_id': studentId,
          'school_id': schoolId,
          'focus_subject_id': focusSubjectId,
        },
      );

      if (aiResponse.status != 200) {
        throw ServerException(
          message: 'Study plan suggestion failed: ${aiResponse.data}',
          statusCode: aiResponse.status,
        );
      }

      final planData = aiResponse.data as Map<String, dynamic>;
      final tasksData = planData['tasks'] as List<dynamic>? ?? [];

      // Create the suggested plan
      final planResponse = await _supabase
          .from(_studyPlansTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'title': planData['title'] as String? ?? 'AI Suggested Study Plan',
            'description':
                planData['description'] as String? ?? 'Personalized study plan based on your progress',
            'frequency': planData['frequency'] as String? ?? 'daily',
            'start_date': DateTime.now().toUtc().toIso8601String(),
            'is_active': true,
            'is_ai_suggested': true,
          })
          .select()
          .single();

      final planId = planResponse['id'] as String;

      // Insert the suggested tasks
      if (tasksData.isNotEmpty) {
        final tasksToInsert = tasksData.map((task) {
          final t = task as Map<String, dynamic>;
          return {
            'plan_id': planId,
            'subject_id': t['subject_id'] as String?,
            'title': t['title'] as String,
            'description': t['description'] as String?,
            'scheduled_date': t['scheduled_date'] as String,
            'start_time': t['start_time'] as String?,
            'end_time': t['end_time'] as String?,
          };
        }).toList();

        await _supabase.from(_studyTasksTable).insert(tasksToInsert);
      }

      AppLogger.info('AI study plan created: $planId');
      return StudyPlanModel.fromJson(planResponse);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'suggest study plan');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT GOALS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all goals for a student, optionally filtered by status
  /// and subject.
  Future<List<StudentGoalModel>> getGoals({
    required String studentId,
    String? status,
    String? subjectId,
  }) async {
    try {
      AppLogger.info('Fetching goals for student: $studentId');

      var query = _supabase
          .from(_studentGoalsTable)
          .select()
          .eq('student_id', studentId);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }

      // PERF: Added limit to prevent unbounded query on student_goals
      final response = await query
          .order('deadline', ascending: true, nullsFirst: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response
          .map((json) => StudentGoalModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch goals');
    }
  }

  /// Creates a new student goal.
  Future<StudentGoalModel> createGoal({
    required String studentId,
    String? schoolId,
    String? subjectId,
    required String title,
    String? description,
    double? targetValue,
    String unit = '%',
    String priority = 'medium',
    DateTime? deadline,
  }) async {
    try {
      AppLogger.info('Creating goal: $title for student: $studentId');

      final response = await _supabase
          .from(_studentGoalsTable)
          .insert({
            'student_id': studentId,
            'school_id': schoolId,
            'subject_id': subjectId,
            'title': title,
            'description': description,
            'target_value': targetValue,
            'current_value': 0,
            'unit': unit,
            'priority': priority,
            'status': 'in_progress',
            'deadline': deadline?.toUtc().toIso8601String(),
          })
          .select()
          .single();

      AppLogger.info('Goal created successfully');
      return StudentGoalModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create goal');
    }
  }

  /// Updates a goal's progress, priority, or status.
  Future<StudentGoalModel> updateGoal({
    required String goalId,
    double? currentValue,
    String? priority,
    String? status,
  }) async {
    try {
      AppLogger.info('Updating goal: $goalId');

      final updateData = <String, dynamic>{};
      if (currentValue != null) updateData['current_value'] = currentValue;
      if (priority != null) updateData['priority'] = priority;
      if (status != null) updateData['status'] = status;

      // Auto-mark as completed if current_value reaches target_value
      if (currentValue != null && status == null) {
        final current = await _supabase
            .from(_studentGoalsTable)
            .select('target_value')
            .eq('id', goalId)
            .single();
        final targetValue =
            (current['target_value'] as num?)?.toDouble();
        if (targetValue != null && currentValue >= targetValue) {
          updateData['status'] = 'achieved';
        }
      }

      final response = await _supabase
          .from(_studentGoalsTable)
          .update(updateData)
          .eq('id', goalId)
          .select()
          .single();

      AppLogger.info('Goal updated successfully');
      return StudentGoalModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update goal');
    }
  }

  /// Deletes a goal.
  Future<void> deleteGoal({required String goalId}) async {
    try {
      AppLogger.info('Deleting goal: $goalId');
      await _supabase
          .from(_studentGoalsTable)
          .delete()
          .eq('id', goalId);
      AppLogger.info('Goal deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'delete goal');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROGRESS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets progress snapshots for a student.
  ///
  /// Supports filtering by period granularity and subject. Results
  /// are limited to [limit] most recent snapshots.
  Future<List<StudentProgressModel>> getProgress({
    required String studentId,
    String? period,
    String? subjectId,
    int limit = 12,
  }) async {
    try {
      AppLogger.info('Fetching progress for student: $studentId');

      var query = _supabase
          .from(_studentProgressSnapshotsTable)
          .select()
          .eq('student_id', studentId);

      if (period != null) {
        query = query.eq('period', period);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }

      final response = await query
          .order('snapshot_date', ascending: false)
          .limit(limit);

      return response
          .map((json) => StudentProgressModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch progress');
    }
  }

  /// Gets the latest overall progress snapshot for a student.
  Future<StudentProgressModel> getLatestProgress({
    required String studentId,
  }) async {
    try {
      AppLogger.info(
        'Fetching latest progress snapshot for student: $studentId',
      );

      final response = await _supabase
          .from(_studentProgressSnapshotsTable)
          .select()
          .eq('student_id', studentId)
          .isFilter('subject_id', null) // Overall progress (no specific subject)
          .order('snapshot_date', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        throw NotFoundException(
          message: 'No progress snapshot found for student: $studentId',
        );
      }

      return StudentProgressModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      _handleGenericException(e, 'fetch latest progress');
    }
  }

  /// Gets daily activity records for a date range.
  Future<List<StudentDailyActivityModel>> getDailyActivity({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
        'Fetching daily activity for student: $studentId '
        'from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );

      // PERF: Added limit to prevent unbounded query on student_daily_activity
      final response = await _supabase
          .from(_studentDailyActivityTable)
          .select()
          .eq('student_id', studentId)
          .gte('activity_date', startDate.toUtc().toIso8601String().substring(0, 10))
          .lte('activity_date', endDate.toUtc().toIso8601String().substring(0, 10))
          .order('activity_date', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response
          .map((json) => StudentDailyActivityModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch daily activity');
    }
  }

  /// Records or updates daily activity for a student.
  ///
  /// Uses upsert to create or increment the activity counters for
  /// the given date.
  Future<StudentDailyActivityModel> upsertDailyActivity({
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
  }) async {
    try {
      AppLogger.info(
        'Upserting daily activity for student: $studentId on ${activityDate.toIso8601String()}',
      );

      final dateStr = activityDate.toUtc().toIso8601String().substring(0, 10);

      // Try to find existing record for this date
      final existing = await _supabase
          .from(_studentDailyActivityTable)
          .select()
          .eq('student_id', studentId)
          .eq('activity_date', dateStr)
          .maybeSingle();

      Map<String, dynamic> data;

      if (existing != null) {
        // Increment existing values
        final updateData = <String, dynamic>{};
        if (studyTimeMin != null) {
          updateData['study_time_min'] =
              (existing['study_time_min'] as int? ?? 0) + studyTimeMin;
        }
        if (questionsAttempted != null) {
          updateData['questions_attempted'] =
              (existing['questions_attempted'] as int? ?? 0) + questionsAttempted;
        }
        if (questionsCorrect != null) {
          updateData['questions_correct'] =
              (existing['questions_correct'] as int? ?? 0) + questionsCorrect;
        }
        if (practiceSessions != null) {
          updateData['practice_sessions'] =
              (existing['practice_sessions'] as int? ?? 0) + practiceSessions;
        }
        if (flashcardsReviewed != null) {
          updateData['flashcards_reviewed'] =
              (existing['flashcards_reviewed'] as int? ?? 0) + flashcardsReviewed;
        }
        if (assignmentsSubmitted != null) {
          updateData['assignments_submitted'] =
              (existing['assignments_submitted'] as int? ?? 0) + assignmentsSubmitted;
        }
        if (resourcesViewed != null) {
          updateData['resources_viewed'] =
              (existing['resources_viewed'] as int? ?? 0) + resourcesViewed;
        }
        if (tutorQuestions != null) {
          updateData['tutor_questions'] =
              (existing['tutor_questions'] as int? ?? 0) + tutorQuestions;
        }

        final response = await _supabase
            .from(_studentDailyActivityTable)
            .update(updateData)
            .eq('id', existing['id'] as String)
            .select()
            .single();

        data = response;
      } else {
        // Create new record
        final response = await _supabase
            .from(_studentDailyActivityTable)
            .insert({
              'student_id': studentId,
              'activity_date': dateStr,
              'study_time_min': studyTimeMin ?? 0,
              'questions_attempted': questionsAttempted ?? 0,
              'questions_correct': questionsCorrect ?? 0,
              'practice_sessions': practiceSessions ?? 0,
              'flashcards_reviewed': flashcardsReviewed ?? 0,
              'assignments_submitted': assignmentsSubmitted ?? 0,
              'resources_viewed': resourcesViewed ?? 0,
              'tutor_questions': tutorQuestions ?? 0,
            })
            .select()
            .single();

        data = response;
      }

      AppLogger.info('Daily activity upserted successfully');
      return StudentDailyActivityModel.fromJson(data);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'upsert daily activity');
    }
  }

  /// Gets student dashboard stats using the `v_student_dashboard` view.
  ///
  /// This view provides pre-computed aggregate stats for fast reads
  /// on the student dashboard.
  Future<StudentDashboardStatsModel> getDashboardStats({
    required String studentId,
  }) async {
    try {
      AppLogger.info(
        'Fetching dashboard stats for student: $studentId',
      );

      final response = await _supabase
          .from(_studentDashboardView)
          .select()
          .eq('student_id', studentId)
          .single();

      AppLogger.info('Dashboard stats fetched successfully');
      return StudentDashboardStatsModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch dashboard stats');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets notifications for a student (paginated).
  ///
  /// Supports filtering to show only unread notifications.
  Future<List<StudentNotificationModel>> getNotifications({
    required String studentId,
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) async {
    try {
      AppLogger.info('Fetching notifications for student: $studentId');
      final offset = (page - 1) * pageSize;

      var query = _supabase
          .from(_studentNotificationsTable)
          .select()
          .eq('student_id', studentId);

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return response
          .map((json) => StudentNotificationModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'fetch notifications');
    }
  }

  /// Marks a single notification as read.
  Future<void> markNotificationRead({
    required String notificationId,
  }) async {
    try {
      AppLogger.info('Marking notification as read: $notificationId');
      await _supabase
          .from(_studentNotificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId);
      AppLogger.info('Notification marked as read');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'mark notification read');
    }
  }

  /// Marks all notifications as read for a student.
  Future<void> markAllNotificationsRead({
    required String studentId,
  }) async {
    try {
      AppLogger.info(
        'Marking all notifications as read for student: $studentId',
      );
      await _supabase
          .from(_studentNotificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('student_id', studentId)
          .eq('is_read', false);
      AppLogger.info('All notifications marked as read');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'mark all notifications read');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTEGRATION: AI QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Generates practice questions from content using the AI Generation
  /// Engine.
  ///
  /// Calls the `generate-questions` Edge Function which processes the
  /// provided content and returns a list of generated question objects.
  Future<List<Map<String, dynamic>>> generateQuestionsFromContent({
    required String studentId,
    required String content,
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    int questionCount = 5,
    String questionType = 'multiple_choice',
  }) async {
    try {
      AppLogger.info(
        'Generating questions from content for student: $studentId',
      );

      final aiResponse = await _supabase.functions.invoke(
        _generateQuestionsFunction,
        body: {
          'student_id': studentId,
          'content': content,
          'subject_id': subjectId,
          'topic_id': topicId,
          'difficulty': difficulty,
          'question_count': questionCount,
          'question_type': questionType,
        },
      );

      if (aiResponse.status != 200) {
        throw ServerException(
          message: 'Question generation failed: ${aiResponse.data}',
          statusCode: aiResponse.status,
        );
      }

      final questions = (aiResponse.data['questions'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .toList();

      AppLogger.info(
        'Generated ${questions.length} questions from content',
      );
      return questions;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'generate questions from content');
    }
  }
}
