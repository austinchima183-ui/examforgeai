import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../datasources/cbt_remote_datasource.dart';
import '../models/cbt_models.dart';


/// Concrete implementation of [CbtRepository] that delegates
/// all operations to [CbtRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class CbtRepositoryImpl implements CbtRepository {
  CbtRepositoryImpl({
    required CbtRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CbtRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Convert exceptions to Failures
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapExceptionToFailure(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
    } else if (e is CacheException) {
      return Failure.cache(message: e.message);
    } else if (e is NetworkException) {
      return Failure.network(message: e.message);
    } else if (e is ValidationException) {
      return Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
    } else if (e is NotFoundException) {
      return Failure.notFound(message: e.message);
    } else if (e is UnauthorizedException) {
      return Failure.unauthorized(message: e.message);
    } else if (e is ForbiddenException) {
      return Failure.forbidden(message: e.message);
    } else {
      AppLogger.error('Unexpected exception in CbtRepositoryImpl', error: e);
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam CRUD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamEntity>> createExam(ExamEntity exam) async {
    try {
      final model = ExamModel.fromEntity(exam);
      final created = await _remoteDataSource.createExam(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamEntity>> updateExam(ExamEntity exam) async {
    try {
      final model = ExamModel.fromEntity(exam);
      final updated = await _remoteDataSource.updateExam(
        exam.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteExam(String examId) async {
    try {
      await _remoteDataSource.deleteExam(examId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamEntity>> getExam(String examId) async {
    try {
      final model = await _remoteDataSource.getExam(examId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamEntity>> getExamWithDetails(String examId) async {
    try {
      final model = await _remoteDataSource.getExamWithDetails(examId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ExamEntity>>> getExams({
    String? schoolId,
    String? subjectId,
    ExamStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (schoolId != null) filters['school_id'] = schoolId;
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (status != null) filters['status'] = status.value;

      final models = await _remoteDataSource.getExams(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamEntity>> publishExam(String examId) async {
    try {
      final model = await _remoteDataSource.publishExam(examId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamEntity>> archiveExam(String examId) async {
    try {
      final model = await _remoteDataSource.archiveExam(examId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamEntity>> cloneExam(String examId) async {
    try {
      final model = await _remoteDataSource.cloneExam(examId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam Questions
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> addQuestionsToExam(
    String examId,
    List<ExamQuestionEntity> questions,
  ) async {
    try {
      final questionMaps = questions
          .map((q) => ExamQuestionModel.fromEntity(q).toJson())
          .toList();
      await _remoteDataSource.addQuestionsToExam(examId, questionMaps);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeQuestionFromExam(
    String examId,
    String questionId,
  ) async {
    try {
      await _remoteDataSource.removeQuestionFromExam(examId, questionId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> reorderQuestions(
    String examId,
    List<String> questionIds,
  ) async {
    try {
      await _remoteDataSource.reorderQuestions(examId, questionIds);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam Students
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> assignStudents(
    String examId,
    List<String> studentIds,
  ) async {
    try {
      await _remoteDataSource.assignStudents(examId, studentIds);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeStudent(String examId, String studentId) async {
    try {
      await _remoteDataSource.removeStudent(examId, studentId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam Attempts
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamAttemptEntity>> startAttempt(String examId) async {
    try {
      final model = await _remoteDataSource.startAttempt(examId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamResultEntity>> submitAttempt(
    String attemptId, {
    SubmissionType type = SubmissionType.manual,
  }) async {
    try {
      final model = await _remoteDataSource.submitAttempt(
        attemptId,
        submissionType: type.value,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamAttemptEntity>> getAttempt(String attemptId) async {
    try {
      final model = await _remoteDataSource.getAttempt(attemptId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamAttemptEntity>> getAttemptWithAnswers(
    String attemptId,
  ) async {
    try {
      final model = await _remoteDataSource.getAttemptWithAnswers(attemptId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ExamAttemptEntity>>> getStudentAttempts(
    String examId,
    String studentId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getStudentAttempts(examId, studentId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Answer Handling
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<StudentAnswerEntity>> saveAnswer(
    String attemptId,
    String questionId,
    Map<String, dynamic> answerData,
  ) async {
    try {
      final model = await _remoteDataSource.saveAnswer(
        attemptId,
        questionId,
        answerData,
      );
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> flagQuestion(
    String attemptId,
    String questionId,
    bool isFlagged,
  ) async {
    try {
      await _remoteDataSource.flagQuestion(attemptId, questionId, isFlagged);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> autoSave(
    String attemptId,
    Map<String, dynamic> saveData,
  ) async {
    try {
      await _remoteDataSource.autoSave(attemptId, saveData);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Session Management
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> updateSession(ExamSessionEntity session) async {
    try {
      final model = ExamSessionModel.fromEntity(session);
      await _remoteDataSource.updateSession(model.toJson());
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> heartbeat(String sessionId) async {
    try {
      await _remoteDataSource.heartbeat(sessionId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Monitoring
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> logMonitoringEvent(MonitoringLogEntity event) async {
    try {
      final model = MonitoringLogModel.fromEntity(event);
      await _remoteDataSource.logMonitoringEvent(model.toJson());
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<MonitoringLogEntity>>> getMonitoringLogs(
    String examId, {
    String? studentId,
  }) async {
    try {
      final models = await _remoteDataSource.getMonitoringLogs(
        examId,
        studentId: studentId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Results & Grading
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ExamResultEntity>>> getExamResults(
    String examId, {
    bool? isReleased,
  }) async {
    try {
      final models = await _remoteDataSource.getExamResults(
        examId,
        isReleased: isReleased,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamResultEntity?>> getStudentResult(
    String examId,
    String studentId,
  ) async {
    try {
      final model =
          await _remoteDataSource.getStudentResult(examId, studentId);
      return Success(model?.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<StudentAnswerEntity>> gradeAnswer(
    String answerId,
    double marksAwarded, {
    String? comment,
  }) async {
    try {
      final model = await _remoteDataSource.gradeAnswer(
        answerId,
        marksAwarded,
        comment: comment,
      );
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> releaseResults(String examId) async {
    try {
      await _remoteDataSource.releaseResults(examId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Statistics & Rankings
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamStatistics>> getExamStatistics(String examId) async {
    try {
      final model = await _remoteDataSource.getExamStatistics(examId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LiveExamStats>> getLiveExamStats(String examId) async {
    try {
      final model = await _remoteDataSource.getLiveExamStats(examId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ExamRankingEntity>>> getRankings(String examId) async {
    try {
      final models = await _remoteDataSource.getRankings(examId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Realtime Streams
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Stream<ExamSessionEntity> watchExamSessions(String examId) {
    return _remoteDataSource.watchExamSessions(examId).map((model) {
      return model.toEntity();
    });
  }

  @override
  Stream<ExamAttemptEntity> watchExamAttempts(String examId) {
    return _remoteDataSource.watchExamAttempts(examId).map((model) {
      return model.toEntity();
    });
  }

  @override
  Stream<MonitoringLogEntity> watchMonitoringEvents(String examId) {
    return _remoteDataSource.watchMonitoringEvents(examId).map((model) {
      return model.toEntity();
    });
  }
}
