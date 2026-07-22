import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/database/database_pool_manager.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';
import '../models/cbt_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote CBT engine data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class CbtRemoteDataSource {
  // ─── Exam CRUD ──────────────────────────────────────────────────────

  Future<ExamModel> createExam(Map<String, dynamic> examData);
  Future<ExamModel> updateExam(String examId, Map<String, dynamic> examData);
  Future<void> deleteExam(String examId);
  Future<ExamModel> getExam(String examId);
  Future<ExamModel> getExamWithDetails(String examId);
  Future<List<ExamModel>> getExams(Map<String, dynamic> filters);

  // ─── Exam Lifecycle ─────────────────────────────────────────────────

  Future<ExamModel> publishExam(String examId);
  Future<ExamModel> archiveExam(String examId);
  Future<ExamModel> cloneExam(String examId);

  // ─── Exam Questions ─────────────────────────────────────────────────

  Future<void> addQuestionsToExam(
    String examId,
    List<Map<String, dynamic>> questions,
  );
  Future<void> removeQuestionFromExam(String examId, String questionId);
  Future<void> reorderQuestions(
    String examId,
    List<String> questionIds,
  );

  // ─── Exam Students ──────────────────────────────────────────────────

  Future<void> assignStudents(String examId, List<String> studentIds);
  Future<void> removeStudent(String examId, String studentId);

  // ─── Exam Attempts ──────────────────────────────────────────────────

  Future<ExamAttemptModel> startAttempt(String examId);
  Future<ExamResultModel> submitAttempt(
    String attemptId, {
    String submissionType = 'manual',
  });
  Future<ExamAttemptModel> getAttempt(String attemptId);
  Future<ExamAttemptModel> getAttemptWithAnswers(String attemptId);
  Future<List<ExamAttemptModel>> getStudentAttempts(
    String examId,
    String studentId,
  );

  // ─── Answer Handling ────────────────────────────────────────────────

  Future<StudentAnswerModel> saveAnswer(
    String attemptId,
    String questionId,
    Map<String, dynamic> answerData,
  );
  Future<void> flagQuestion(
    String attemptId,
    String questionId,
    bool isFlagged,
  );
  Future<void> autoSave(
    String attemptId,
    Map<String, dynamic> saveData,
  );

  // ─── Session Management ─────────────────────────────────────────────

  Future<void> updateSession(Map<String, dynamic> sessionData);
  Future<void> heartbeat(String sessionId);

  // ─── Monitoring ─────────────────────────────────────────────────────

  Future<void> logMonitoringEvent(Map<String, dynamic> eventData);
  Future<List<MonitoringLogModel>> getMonitoringLogs(
    String examId, {
    String? studentId,
  });

  // ─── Results & Grading ──────────────────────────────────────────────

  Future<List<ExamResultModel>> getExamResults(
    String examId, {
    bool? isReleased,
  });
  Future<ExamResultModel?> getStudentResult(
    String examId,
    String studentId,
  );
  Future<StudentAnswerModel> gradeAnswer(
    String answerId,
    double marksAwarded, {
    String? comment,
  });
  Future<void> releaseResults(String examId);

  // ─── Statistics & Rankings ──────────────────────────────────────────

  Future<ExamStatisticsModel> getExamStatistics(String examId);
  Future<LiveExamStatsModel> getLiveExamStats(String examId);
  Future<List<ExamRankingModel>> getRankings(String examId);

  // ─── Realtime Subscriptions ─────────────────────────────────────────

  Stream<ExamSessionModel> watchExamSessions(String examId);
  Stream<ExamAttemptModel> watchExamAttempts(String examId);
  Stream<MonitoringLogModel> watchMonitoringEvents(String examId);
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class CbtRemoteDataSourceImpl implements CbtRemoteDataSource {
  CbtRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Table names ────────────────────────────────────────────────────

  static const _examsTable = 'exams';
  static const _examSectionsTable = 'exam_sections';
  static const _examQuestionsTable = 'exam_questions';
  static const _examStudentsTable = 'exam_students';
  static const _examAttemptsTable = 'exam_attempts';
  static const _studentAnswersTable = 'student_answers';
  static const _examSessionsTable = 'exam_sessions';
  static const _monitoringLogsTable = 'monitoring_logs';
  static const _examResultsTable = 'exam_results';
  static const _examRankingsTable = 'exam_rankings';

  // ─── Active Realtime channels ───────────────────────────────────────

  final Map<String, sb.RealtimeChannel> _channels = {};

  // ═══════════════════════════════════════════════════════════════════
  // Exam CRUD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    try {
      final response =
          await _supabaseClient.from(_examsTable).insert(examData).select().single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamModel> updateExam(
    String examId,
    Map<String, dynamic> examData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_examsTable)
          .update(examData)
          .eq('id', examId)
          .select()
          .single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update exam failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Exam not found: $examId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteExam(String examId) async {
    try {
      await _supabaseClient
          .from(_examsTable)
          .delete()
          .eq('id', examId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamModel> getExam(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_examsTable)
          .select()
          .eq('id', examId)
          .single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get exam failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Exam not found: $examId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamModel> getExamWithDetails(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_examsTable)
          .select('''
            *,
            exam_sections(*),
            exam_questions(
              *,
              question:question_bank(
                id, school_id, subject_id, topic_id, question_type,
                difficulty_level, content, explanation, marks, negative_marks
              )
            )
          ''')
          .eq('id', examId)
          .single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get exam with details failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Exam not found: $examId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get exam with details unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get exam with details: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExamModel>> getExams(Map<String, dynamic> filters) async {
    try {
      var filterQuery = _supabaseClient.from(_examsTable).select();

      if (filters['school_id'] != null) {
        filterQuery = filterQuery.eq('school_id', filters['school_id'] as String);
      }
      if (filters['subject_id'] != null) {
        filterQuery = filterQuery.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters['status'] != null) {
        filterQuery = filterQuery.eq('status', filters['status'] as String);
      }
      if (filters['class_id'] != null) {
        filterQuery = filterQuery.eq('class_id', filters['class_id'] as String);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['per_page'] as int? ?? filters['perPage'] as int? ?? 20;
      final offset = (page - 1) * perPage;

      var transformQuery = filterQuery.order('created_at', ascending: false).range(offset, offset + perPage - 1);

      final response = await transformQuery;

      return response
          .map<ExamModel>((json) => ExamModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get exams failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get exams unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get exams: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Lifecycle
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamModel> publishExam(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_examsTable)
          .update({
            'status': 'published',
            'published_at': DateTime.now().toIso8601String(),
          })
          .eq('id', examId)
          .select()
          .single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Publish exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Publish exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to publish exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamModel> archiveExam(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_examsTable)
          .update({'status': 'archived'})
          .eq('id', examId)
          .select()
          .single();

      return ExamModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Archive exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Archive exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to archive exam: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamModel> cloneExam(String examId) async {
    try {
      // Fetch the original exam with details
      final original = await getExamWithDetails(examId);

      final now = DateTime.now();
      final cloneData = {
        'school_id': original.schoolId,
        'created_by': original.createdBy,
        'title': '${original.title} (Copy)',
        'description': original.description,
        'subject_id': original.subjectId,
        'class_id': original.classId,
        'academic_session_id': original.academicSessionId,
        'exam_type': original.examType,
        'status': 'draft',
        'start_time': now.add(const Duration(days: 7)).toIso8601String(),
        'end_time': now.add(const Duration(days: 7, hours: 2)).toIso8601String(),
        'time_limit_minutes': original.timeLimitMinutes,
        'total_marks': original.totalMarks,
        'pass_mark': original.passMark,
        'pass_mark_type': original.passMarkType,
        'instructions': original.instructions,
        'allowed_attempts': original.allowedAttempts,
        'negative_marking_enabled': original.negativeMarkingEnabled,
        'negative_mark_value': original.negativeMarkValue,
        'grace_period_minutes': original.gracePeriodMinutes,
        'auto_submit': original.autoSubmit,
        'randomize_questions': original.randomizeQuestions,
        'randomize_options': original.randomizeOptions,
        'show_results': original.showResults,
        'show_correct_answers': original.showCorrectAnswers,
        'show_explanations': original.showExplanations,
        'is_template': original.isTemplate,
        'template_id': original.id,
        'max_students': original.maxStudents,
        'ip_restriction': original.ipRestriction,
        'require_full_screen': original.requireFullScreen,
        'allow_resume': original.allowResume,
        'browser_lockdown': original.browserLockdown,
        'metadata': original.metadata,
      };

      final clonedExam = await createExam(cloneData);

      // Clone sections
      for (final section in original.sections) {
        await _supabaseClient.from(_examSectionsTable).insert({
          'exam_id': clonedExam.id,
          'title': section.title,
          'description': section.description,
          'instructions': section.instructions,
          'sort_order': section.sortOrder,
          'time_limit_minutes': section.timeLimitMinutes,
          'randomize_questions': section.randomizeQuestions,
        });
      }

      // Clone questions
      for (final question in original.questions) {
        await _supabaseClient.from(_examQuestionsTable).insert({
          'exam_id': clonedExam.id,
          'section_id': question.sectionId,
          'question_id': question.questionId,
          'sort_order': question.sortOrder,
          'marks': question.marks,
          'negative_marks': question.negativeMarks,
          'is_compulsory': question.isCompulsory,
        });
      }

      return clonedExam;
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Clone exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Clone exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to clone exam: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Questions
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> addQuestionsToExam(
    String examId,
    List<Map<String, dynamic>> questions,
  ) async {
    try {
      final rows = questions.map((q) {
        q['exam_id'] = examId;
        return q;
      }).toList();

      await _supabaseClient.from(_examQuestionsTable).insert(rows);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Add questions to exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Add questions to exam unexpected error', error: e);
      throw ServerException(
        message: 'Failed to add questions: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeQuestionFromExam(
    String examId,
    String questionId,
  ) async {
    try {
      await _supabaseClient
          .from(_examQuestionsTable)
          .delete()
          .eq('exam_id', examId)
          .eq('question_id', questionId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Remove question from exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Remove question unexpected error', error: e);
      throw ServerException(
        message: 'Failed to remove question: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> reorderQuestions(
    String examId,
    List<String> questionIds,
  ) async {
    try {
      // Update sort_order for each question in the new order
      for (var i = 0; i < questionIds.length; i++) {
        await _supabaseClient
            .from(_examQuestionsTable)
            .update({'sort_order': i})
            .eq('exam_id', examId)
            .eq('question_id', questionIds[i]);
      }
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Reorder questions failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Reorder questions unexpected error', error: e);
      throw ServerException(
        message: 'Failed to reorder questions: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Students
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> assignStudents(
    String examId,
    List<String> studentIds,
  ) async {
    try {
      final rows = studentIds
          .map((studentId) => {
                'exam_id': examId,
                'student_id': studentId,
              })
          .toList();

      await _supabaseClient.from(_examStudentsTable).insert(rows);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Assign students failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Assign students unexpected error', error: e);
      throw ServerException(
        message: 'Failed to assign students: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeStudent(String examId, String studentId) async {
    try {
      await _supabaseClient
          .from(_examStudentsTable)
          .delete()
          .eq('exam_id', examId)
          .eq('student_id', studentId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Remove student failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Remove student unexpected error', error: e);
      throw ServerException(
        message: 'Failed to remove student: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Attempts
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamAttemptModel> startAttempt(String examId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException(
          message: 'Not authenticated',
          code: 'NOT_AUTHENTICATED',
        );
      }

      // ── Call server-side SQL function which validates eligibility,
      //    creates the attempt AND session atomically ───────────────
      final response = await _supabaseClient.rpc(
        'start_exam_attempt',
        params: {'p_exam_id': examId},
      );

      // Server returns the created attempt row as JSON
      if (response == null) {
        throw const ServerException(
          message: 'Server returned no data for start_exam_attempt',
          statusCode: 500,
        );
      }

      final attemptMap = response as Map<String, dynamic>;

      // Validate the server confirmed the attempt was started
      final attemptStatus = attemptMap['status'] as String?;
      if (attemptStatus != 'in_progress') {
        AppLogger.warning(
          'Server returned unexpected attempt status: $attemptStatus',
        );
        throw ServerException(
          message: 'Server did not start attempt. Status: $attemptStatus',
          statusCode: 409,
          data: attemptMap,
        );
      }

      return ExamAttemptModel.fromJson(attemptMap);
    } on AuthException {
      rethrow;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Start attempt RPC failed', error: e);
      // Map known Postgrest error codes to domain-meaningful exceptions
      final msg = e.message;
      if (msg.contains('not assigned') || msg.contains('not eligible')) {
        throw ForbiddenException(message: msg);
      }
      if (msg.contains('max attempts') || msg.contains('already in progress')) {
        throw ValidationException(message: msg);
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } on ForbiddenException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      AppLogger.error('Start attempt unexpected error', error: e);
      throw ServerException(
        message: 'Failed to start attempt: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamResultModel> submitAttempt(
    String attemptId, {
    String submissionType = 'manual',
  }) async {
    try {
      // ── Call server-side SQL function which validates the attempt,
      //    computes scores, deactivates the session, and creates the
      //    result row atomically ─────────────────────────────────────
      final response = await _supabaseClient.rpc(
        'submit_exam_attempt',
        params: {
          'p_attempt_id': attemptId,
          'p_submission_type': submissionType,
        },
      );

      // Server returns the result row as JSON
      if (response == null) {
        throw const ServerException(
          message: 'Server returned no data for submit_exam_attempt',
          statusCode: 500,
        );
      }

      final resultMap = response as Map<String, dynamic>;

      // Validate the server accepted the submission
      final resultGradingStatus = resultMap['grading_status'] as String?;
      if (resultGradingStatus == null) {
        throw ServerException(
          message: 'Server submission response missing grading_status',
          statusCode: 500,
          data: resultMap,
        );
      }

      return ExamResultModel.fromJson(resultMap);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Submit attempt RPC failed', error: e);
      // Handle server-rejected late submissions
      final msg = e.message;
      if (msg.contains('time_exceeded') || msg.contains('time limit')) {
        throw ValidationException(
          message: 'Submission rejected: exam time has exceeded',
          fieldErrors: {
            'time_exceeded': 'The exam time limit has been exceeded. '
                'Your answers have been auto-submitted.',
          },
        );
      }
      if (msg.contains('not in progress') || msg.contains('already submitted')) {
        throw ValidationException(message: msg);
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('Submit attempt unexpected error', error: e);
      throw ServerException(
        message: 'Failed to submit attempt: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamAttemptModel> getAttempt(String attemptId) async {
    try {
      final response = await _supabaseClient
          .from(_examAttemptsTable)
          .select()
          .eq('id', attemptId)
          .single();

      return ExamAttemptModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attempt failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Attempt not found: $attemptId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attempt unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attempt: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamAttemptModel> getAttemptWithAnswers(String attemptId) async {
    try {
      final response = await _supabaseClient
          .from(_examAttemptsTable)
          .select(''', student_answers(*)''')
          .eq('id', attemptId)
          .single();

      return ExamAttemptModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attempt with answers failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Attempt not found: $attemptId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attempt with answers unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attempt with answers: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExamAttemptModel>> getStudentAttempts(
    String examId,
    String studentId, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      // PERF: Added pagination and column selection to prevent unbounded results
      final response = await _supabaseClient
          .from(_examAttemptsTable)
          .select('id, exam_id, student_id, attempt_number, status, started_at, submitted_at, score_percentage, total_marks, time_spent_seconds, grading_status, created_at')
          .eq('exam_id', examId)
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return response
          .map<ExamAttemptModel>((a) => ExamAttemptModel.fromJson(a))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student attempts failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student attempts unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student attempts: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Answer Handling
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<StudentAnswerModel> saveAnswer(
    String attemptId,
    String questionId,
    Map<String, dynamic> answerData,
  ) async {
    try {
      // ── Validate exam timing server-side before accepting the answer ──
      final timingResponse = await _supabaseClient.rpc(
        'validate_exam_timing',
        params: {'p_attempt_id': attemptId},
      );

      final timingResult = timingResponse as Map<String, dynamic>?;
      final isWithinTime = timingResult?['is_within_time'] as bool? ?? false;

      if (!isWithinTime) {
        throw ValidationException(
          message: 'Cannot save answer: exam time has exceeded',
          fieldErrors: {
            'time_exceeded': 'The exam time limit has been exceeded. '
                'No further answers can be saved.',
          },
        );
      }

      // Use server time for the answer timestamp to avoid client clock skew
      final serverTime = timingResult?['server_time'] as String?;
      final now = serverTime != null
          ? DateTime.parse(serverTime)
          : DateTime.now();

      // Upsert: update existing answer or insert new one
      final existing = await _supabaseClient
          .from(_studentAnswersTable)
          .select('id')
          .eq('attempt_id', attemptId)
          .eq('question_id', questionId)
          .maybeSingle();

      if (existing != null) {
        final response = await _supabaseClient
            .from(_studentAnswersTable)
            .update({
              'answer_data': answerData,
              'answered_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', existing['id'] as String)
            .select()
            .single();

        return StudentAnswerModel.fromJson(response);
      } else {
        final response = await _supabaseClient
            .from(_studentAnswersTable)
            .insert({
              'attempt_id': attemptId,
              'question_id': questionId,
              'answer_data': answerData,
              'answered_at': now.toIso8601String(),
            })
            .select()
            .single();

        return StudentAnswerModel.fromJson(response);
      }
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Save answer failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      if (e is ServerException || e is ValidationException) rethrow;
      AppLogger.error('Save answer unexpected error', error: e);
      throw ServerException(
        message: 'Failed to save answer: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> flagQuestion(
    String attemptId,
    String questionId,
    bool isFlagged,
  ) async {
    try {
      await _supabaseClient
          .from(_studentAnswersTable)
          .update({'is_flagged': isFlagged})
          .eq('attempt_id', attemptId)
          .eq('question_id', questionId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Flag question failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Flag question unexpected error', error: e);
      throw ServerException(
        message: 'Failed to flag question: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> autoSave(
    String attemptId,
    Map<String, dynamic> saveData,
  ) async {
    try {
      await _supabaseClient
          .from(_examAttemptsTable)
          .update({
            'auto_save_data': saveData,
            'last_activity_at': DateTime.now().toIso8601String(),
          })
          .eq('id', attemptId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Auto-save failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Auto-save unexpected error', error: e);
      throw ServerException(
        message: 'Failed to auto-save: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Session Management
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> updateSession(Map<String, dynamic> sessionData) async {
    try {
      final sessionId = sessionData['id'] as String;
      await _supabaseClient
          .from(_examSessionsTable)
          .update(sessionData)
          .eq('id', sessionId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update session failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> heartbeat(String sessionId) async {
    try {
      await _supabaseClient
          .from(_examSessionsTable)
          .update({
            'last_heartbeat': DateTime.now().toIso8601String(),
            'connection_status': 'connected',
          })
          .eq('id', sessionId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Heartbeat failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Heartbeat unexpected error', error: e);
      throw ServerException(
        message: 'Failed to send heartbeat: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Monitoring
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> logMonitoringEvent(Map<String, dynamic> eventData) async {
    try {
      await _supabaseClient.from(_monitoringLogsTable).insert(eventData);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Log monitoring event failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Log monitoring event unexpected error', error: e);
      throw ServerException(
        message: 'Failed to log monitoring event: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<MonitoringLogModel>> getMonitoringLogs(
    String examId, {
    String? studentId,
  }) async {
    try {
      // PERF: Added pagination and column selection for monitoring logs
      var filterQuery = _supabaseClient
          .from(_monitoringLogsTable)
          .select('id, exam_id, student_id, event_type, severity, details, created_at')
          .eq('exam_id', examId);

      if (studentId != null) {
        filterQuery = filterQuery.eq('student_id', studentId);
      }

      var transformQuery = filterQuery.order('created_at', ascending: false).limit(PaginatedQueryMixin.defaultPageSize);

      final response = await transformQuery;

      return response
          .map<MonitoringLogModel>(
            (e) => MonitoringLogModel.fromJson(e),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get monitoring logs failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get monitoring logs unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get monitoring logs: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Results & Grading
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<ExamResultModel>> getExamResults(
    String examId, {
    bool? isReleased,
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      // PERF: Added pagination and column selection to prevent unbounded results
      // For large exams (500+ students), fetching all results at once is expensive
      var filterQuery = _supabaseClient
          .from(_examResultsTable)
          .select('id, exam_id, student_id, attempt_id, total_marks, total_possible, score_percentage, is_passed, time_spent_seconds, grading_status, is_released, released_at, created_at')
          .eq('exam_id', examId);

      if (isReleased != null) {
        filterQuery = filterQuery.eq('is_released', isReleased);
      }

      var transformQuery = filterQuery.order('score_percentage', ascending: false).limit(limit).range(offset, offset + limit - 1);

      final response = await transformQuery;

      return response
          .map<ExamResultModel>((r) => ExamResultModel.fromJson(r))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get exam results failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get exam results unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get exam results: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamResultModel?> getStudentResult(
    String examId,
    String studentId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_examResultsTable)
          .select()
          .eq('exam_id', examId)
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ExamResultModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student result failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student result unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentAnswerModel> gradeAnswer(
    String answerId,
    double marksAwarded, {
    String? comment,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      final now = DateTime.now();

      final updateData = <String, dynamic>{
        'marks_awarded': marksAwarded,
        'graded_by': userId,
        'graded_at': now.toIso8601String(),
      };

      if (comment != null) {
        updateData['teacher_comment'] = comment;
      }

      final response = await _supabaseClient
          .from(_studentAnswersTable)
          .update(updateData)
          .eq('id', answerId)
          .select()
          .single();

      return StudentAnswerModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Grade answer failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Grade answer unexpected error', error: e);
      throw ServerException(
        message: 'Failed to grade answer: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> releaseResults(String examId) async {
    try {
      await _supabaseClient
          .from(_examResultsTable)
          .update({
            'is_released': true,
            'released_at': DateTime.now().toIso8601String(),
          })
          .eq('exam_id', examId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Release results failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Release results unexpected error', error: e);
      throw ServerException(
        message: 'Failed to release results: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Statistics & Rankings
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamStatisticsModel> getExamStatistics(String examId) async {
    try {
      // PERF: Use DatabasePoolManager.executeMonitored for performance tracking
      // on the most expensive CBT queries
      final results = await DatabasePoolManager.executeMonitored(
        queryType: 'select',
        table: _examResultsTable,
        operation: 'get_exam_statistics',
        query: () => _supabaseClient
            .from(_examResultsTable)
            .select('score_percentage, is_passed, grading_status')
            .eq('exam_id', examId),
      );

      // PERF: Only count IDs, don't fetch full rows
      final students = await _supabaseClient
          .from(_examStudentsTable)
          .select('id')
          .eq('exam_id', examId)
          .limit(PaginatedQueryMixin.maxPageSize); // Safety cap

      // PERF: Select only columns needed for statistics calculation
      final attempts = await _supabaseClient
          .from(_examAttemptsTable)
          .select('status, time_spent_seconds')
          .eq('exam_id', examId)
          .limit(PaginatedQueryMixin.maxPageSize); // Safety cap

      final totalStudents = students.length;
      final startedStudents = attempts
          .where((a) => a['status'] != 'not_started')
          .length;
      final completedStudents = attempts
          .where((a) =>
              a['status'] == 'submitted' ||
              a['status'] == 'auto_submitted' ||
              a['status'] == 'timed_out')
          .length;
      final submittedStudents = completedStudents;

      // Calculate score statistics
      final scores = results
          .map<double>((r) => (r['score_percentage'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final averageScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;
      final highestScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a > b ? a : b)
          : 0.0;
      final lowestScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a < b ? a : b)
          : 0.0;

      // Calculate median
      double medianScore = 0.0;
      if (scores.isNotEmpty) {
        final sorted = List<double>.from(scores)..sort();
        final mid = sorted.length ~/ 2;
        medianScore = sorted.length.isEven
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid];
      }

      // Calculate pass rate
      final passedCount = results
          .where((r) => r['is_passed'] == true)
          .length;
      final passRate =
          results.isNotEmpty ? (passedCount / results.length) * 100 : 0.0;

      // Average time spent
      final timeSpentList = attempts
          .where((a) => a['time_spent_seconds'] != null)
          .map<int>((a) => a['time_spent_seconds'] as int)
          .toList();
      final averageTimeSpent = timeSpentList.isNotEmpty
          ? timeSpentList.reduce((a, b) => a + b) ~/ timeSpentList.length
          : 0;

      // Grading completion
      final gradedCount = results
          .where((r) =>
              r['grading_status'] == 'auto_graded' ||
              r['grading_status'] == 'fully_graded')
          .length;
      final gradingCompletion = results.isNotEmpty
          ? (gradedCount / results.length) * 100
          : 0.0;

      return ExamStatisticsModel(
        examId: examId,
        totalStudents: totalStudents,
        startedStudents: startedStudents,
        completedStudents: completedStudents,
        submittedStudents: submittedStudents,
        averageScore: averageScore,
        highestScore: highestScore,
        lowestScore: lowestScore,
        medianScore: medianScore,
        passRate: passRate,
        questionsByCorrectRate: {}, // Requires per-question analysis
        averageTimeSpentSeconds: averageTimeSpent,
        gradingCompletionPercentage: gradingCompletion,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get exam statistics failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get exam statistics unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get exam statistics: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<LiveExamStatsModel> getLiveExamStats(String examId) async {
    try {
      // PERF: Use DatabasePoolManager monitoring for the live stats query
      // which is polled every 5-10 seconds during active exams
      final activeSessions = await DatabasePoolManager.executeMonitored(
        queryType: 'select',
        table: _examSessionsTable,
        operation: 'get_live_stats_sessions',
        query: () => _supabaseClient
            .from(_examSessionsTable)
            .select('id, questions_answered, questions_flagged')
            .eq('exam_id', examId)
            .eq('is_active', true)
            .limit(PaginatedQueryMixin.maxPageSize),
      );

      // Count students (bounded by exam size)
      final students = await _supabaseClient
          .from(_examStudentsTable)
          .select('id')
          .eq('exam_id', examId)
          .limit(PaginatedQueryMixin.maxPageSize);

      // PERF: Only select columns needed for counting
      final submittedAttempts = await _supabaseClient
          .from(_examAttemptsTable)
          .select('id, status')
          .eq('exam_id', examId)
          .inFilter('status', ['submitted', 'auto_submitted', 'timed_out']);

      // Recent submissions (last 10)
      final recentSubmissions = await _supabaseClient
          .from(_examAttemptsTable)
          .select()
          .eq('exam_id', examId)
          .inFilter('status', ['submitted', 'auto_submitted', 'timed_out'])
          .order('submitted_at', ascending: false)
          .limit(10);

      // Recent monitoring events (last 20)
      final recentEvents = await _supabaseClient
          .from(_monitoringLogsTable)
          .select()
          .eq('exam_id', examId)
          .order('created_at', ascending: false)
          .limit(20);

      final totalEligible = students.length;
      final activeNow = activeSessions.length;
      final completed = submittedAttempts.length;
      final notStarted = totalEligible - activeNow - completed;

      // Calculate average progress
      double averageProgress = 0;
      if (activeSessions.isNotEmpty) {
        final totalQuestionsAnswered = activeSessions.fold<int>(
          0,
          (sum, s) =>
              sum + ((s['questions_answered'] as int?) ?? 0),
        );
        // Estimate total questions per exam
        averageProgress = totalEligible > 0
            ? totalQuestionsAnswered / (activeNow * 10) * 100
            : 0;
        averageProgress = averageProgress.clamp(0.0, 100.0);
      }

      return LiveExamStatsModel(
        examId: examId,
        totalEligible: totalEligible,
        activeNow: activeNow,
        completed: completed,
        notStarted: notStarted < 0 ? 0 : notStarted,
        averageProgress: averageProgress,
        recentSubmissions: recentSubmissions
            .map<ExamAttemptModel>((a) => ExamAttemptModel.fromJson(a))
            .toList(),
        activeSessions: activeSessions
            .map<ExamSessionModel>((s) => ExamSessionModel.fromJson(s))
            .toList(),
        recentMonitoringEvents: recentEvents
            .map<MonitoringLogModel>((e) => MonitoringLogModel.fromJson(e))
            .toList(),
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get live exam stats failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get live exam stats unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get live exam stats: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExamRankingModel>> getRankings(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_examResultsTable)
          .select()
          .eq('exam_id', examId)
          .eq('is_released', true)
          .order('score_percentage', ascending: false);

      // Generate rankings from sorted results
      final rankings = <ExamRankingModel>[];
      for (var i = 0; i < response.length; i++) {
        final result = response[i];
        // Check if ranking already exists
        final existingRanking = await _supabaseClient
            .from(_examRankingsTable)
            .select('id')
            .eq('attempt_id', result['attempt_id'] as String)
            .maybeSingle();

        if (existingRanking == null) {
          final rankingResponse = await _supabaseClient
              .from(_examRankingsTable)
              .insert({
                'exam_id': examId,
                'student_id': result['student_id'] as String,
                'attempt_id': result['attempt_id'] as String,
                'rank': i + 1,
                'total_marks': result['total_marks'],
                'score_percentage': result['score_percentage'],
              })
              .select()
              .single();

          rankings.add(ExamRankingModel.fromJson(rankingResponse));
        } else {
          await _supabaseClient
              .from(_examRankingsTable)
              .update({
                'rank': i + 1,
                'total_marks': result['total_marks'],
                'score_percentage': result['score_percentage'],
              })
              .eq('id', existingRanking['id'] as String);

          final updatedRanking = await _supabaseClient
              .from(_examRankingsTable)
              .select()
              .eq('id', existingRanking['id'] as String)
              .single();

          rankings.add(ExamRankingModel.fromJson(updatedRanking));
        }
      }

      return rankings;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get rankings failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get rankings unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get rankings: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Realtime Subscriptions
  // ═══════════════════════════════════════════════════════════════════

  @override
  Stream<ExamSessionModel> watchExamSessions(String examId) {
    final channelName = 'exam_sessions_$examId';
    final controller = StreamController<ExamSessionModel>();

    final channel = _supabaseClient.channel(channelName);

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _examSessionsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        if (payload.newRecord != null) {
          try {
            final session = ExamSessionModel.fromJson(payload.newRecord!);
            controller.add(session);
          } catch (e) {
            AppLogger.warning('Failed to parse session realtime event', error: e);
          }
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    // Also fetch initial sessions
    _supabaseClient
        .from(_examSessionsTable)
        .select()
        .eq('exam_id', examId)
        .then((sessions) {
      for (final session in sessions) {
        try {
          controller.add(ExamSessionModel.fromJson(session));
        } catch (_) {}
      }
    }).catchError((_) {});

    return controller.stream;
  }

  @override
  Stream<ExamAttemptModel> watchExamAttempts(String examId) {
    final channelName = 'exam_attempts_$examId';
    final controller = StreamController<ExamAttemptModel>();

    final channel = _supabaseClient.channel(channelName);

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _examAttemptsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        if (payload.newRecord != null) {
          try {
            final attempt = ExamAttemptModel.fromJson(payload.newRecord!);
            controller.add(attempt);
          } catch (e) {
            AppLogger.warning('Failed to parse attempt realtime event', error: e);
          }
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  @override
  Stream<MonitoringLogModel> watchMonitoringEvents(String examId) {
    final channelName = 'monitoring_events_$examId';
    final controller = StreamController<MonitoringLogModel>();

    final channel = _supabaseClient.channel(channelName);

    channel.onPostgresChanges(
      event: sb.PostgresChangeEvent.all,
      schema: 'public',
      table: _monitoringLogsTable,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'exam_id',
        value: examId,
      ),
      callback: (sb.PostgresChangePayload payload) {
        if (payload.newRecord != null) {
          try {
            final event = MonitoringLogModel.fromJson(payload.newRecord!);
            controller.add(event);
          } catch (e) {
            AppLogger.warning('Failed to parse monitoring realtime event', error: e);
          }
        }
      },
    );

    channel.subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Unsubscribe from a specific channel.
  void unsubscribeChannel(String channelName) {
    final channel = _channels.remove(channelName);
    if (channel != null) {
      _supabaseClient.removeChannel(channel);
    }
  }

  /// Unsubscribe from all active channels.
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      _supabaseClient.removeChannel(channel);
    }
    _channels.clear();
  }
}
