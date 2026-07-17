import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/results_entities.dart';
import '../../domain/repositories/results_repository.dart';
import '../datasources/results_remote_datasource.dart';
import '../models/results_models.dart';

/// Concrete implementation of [ResultsRepository] that delegates
/// all operations to [ResultsRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class ResultsRepositoryImpl implements ResultsRepository {
  ResultsRepositoryImpl({
    required ResultsRemoteDataSource remoteDataSource,
    required sb.SupabaseClient supabaseClient,
  })  : _remoteDataSource = remoteDataSource,
        _supabaseClient = supabaseClient;

  final ResultsRemoteDataSource _remoteDataSource;
  final sb.SupabaseClient _supabaseClient;

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
      AppLogger.error('Unexpected exception in ResultsRepositoryImpl', error: e);
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Grade Scales
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<GradeScaleEntity>> createGradeScale(
    GradeScaleEntity scale,
  ) async {
    try {
      final model = GradeScaleModel.fromEntity(scale);
      final created = await _remoteDataSource.createGradeScale(model);
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<GradeScaleEntity>> updateGradeScale(
    GradeScaleEntity scale,
  ) async {
    try {
      final model = GradeScaleModel.fromEntity(scale);
      final updated = await _remoteDataSource.updateGradeScale(model);
      return Success(updated.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteGradeScale(String scaleId) async {
    try {
      await _remoteDataSource.deleteGradeScale(scaleId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<GradeScaleEntity>> getGradeScale(String scaleId) async {
    try {
      final model = await _remoteDataSource.getGradeScale(scaleId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<GradeScaleEntity>>> getGradeScales(
    String schoolId, {
    bool? isActive,
    GradeType? gradeType,
  }) async {
    try {
      final models = await _remoteDataSource.getGradeScales(
        schoolId,
        isActive: isActive,
        gradeType: gradeType?.value,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<GradeScaleEntryEntity?>> applyGradeScale(
    double percentage,
    String scaleId,
  ) async {
    try {
      final scaleModel = await _remoteDataSource.getGradeScale(scaleId);
      final scale = scaleModel.toEntity();

      // Find the matching entry for the given percentage
      GradeScaleEntryEntity? match;
      for (final entry in scale.scaleEntries) {
        if (percentage >= entry.minPercentage &&
            percentage <= entry.maxPercentage) {
          match = entry;
          break;
        }
      }

      return Success(match);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI Grading
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiGradingResultEntity>> requestAiGrading({
    required String answerId,
    required String examId,
    required String studentId,
    required String questionContent,
    required String studentAnswer,
    required String markingScheme,
    required double maxPossible,
    String? aiProvider,
  }) async {
    try {
      // The AI service call happens at the provider/use-case level.
      // Here we persist the AI grading result that was produced.
      // Since the caller provides the grading output, this method
      // inserts the result into the data store.
      final now = DateTime.now();
      final result = AiGradingResultModel(
        id: const Uuid().v4(),
        answerId: answerId,
        examId: examId,
        studentId: studentId,
        aiProvider: aiProvider ?? 'openai',
        suggestedScore: 0,
        maxPossible: maxPossible,
        confidenceScore: 0,
        gradingRubric: {'marking_scheme': markingScheme},
        explanation: '',
        strengths: [],
        weaknesses: [],
        suggestions: [],
        status: 'pending',
        inputTokens: 0,
        outputTokens: 0,
        processingTimeMs: 0,
        errorMessage: null,
        reviewedBy: null,
        reviewedAt: null,
        finalScore: null,
        reviewComment: null,
        isAccepted: null,
        createdAt: now,
        updatedAt: now,
      );

      final inserted = await _remoteDataSource.insertAiGradingResult(result);
      return Success(inserted.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiGradingResultEntity?>> getAiGradingResult(
    String answerId,
  ) async {
    try {
      final model = await _remoteDataSource.getAiGradingByAnswer(answerId);
      return Success(model?.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AiGradingResultEntity>>> getPendingAiGradings(
    String examId,
  ) async {
    try {
      final models = await _remoteDataSource.getPendingAiGradings(examId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiGradingResultEntity>> reviewAiGrading({
    required String aiGradingId,
    required double finalScore,
    required bool isAccepted,
    String? reviewComment,
  }) async {
    try {
      // Fetch the existing AI grading result to update it
      final existingList = await _supabaseClient
          .from('ai_grading_results')
          .select()
          .eq('id', aiGradingId)
          .single();

      final existing = AiGradingResultModel.fromJson(existingList);

      final updated = existing.copyWith(
        finalScore: finalScore,
        isAccepted: isAccepted,
        reviewComment: reviewComment,
        reviewedAt: DateTime.now(),
        status: isAccepted ? 'overridden' : existing.status,
      );

      final result = await _remoteDataSource.updateAiGradingResult(updated);
      return Success(result.toEntity());
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return FailureResult(
          Failure.notFound(message: 'AI grading result not found: $aiGradingId'),
        );
      }
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AiGradingResultEntity>>> batchAiGrading(
    String examId,
  ) async {
    try {
      // Returns pending AI grading results for an exam.
      // The actual AI service orchestration happens at the use-case/provider level.
      final models = await _remoteDataSource.getPendingAiGradings(examId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Teacher Feedback
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TeacherFeedbackEntity>> saveTeacherFeedback(
    TeacherFeedbackEntity feedback,
  ) async {
    try {
      final model = TeacherFeedbackModel.fromEntity(feedback);
      final saved = await _remoteDataSource.upsertTeacherFeedback(model);
      return Success(saved.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeacherFeedbackEntity?>> getTeacherFeedback(
    String answerId,
  ) async {
    try {
      final model = await _remoteDataSource.getTeacherFeedbackByAnswer(answerId);
      return Success(model?.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TeacherFeedbackEntity>>> getTeacherFeedbackByExam(
    String examId,
    String teacherId,
  ) async {
    try {
      final models = await _remoteDataSource.getTeacherFeedbackByExam(
        examId,
        teacherId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Student Subject Results
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<StudentSubjectResultEntity>> getStudentSubjectResult({
    required String studentId,
    required String subjectId,
    required String classId,
    required String academicSessionId,
  }) async {
    try {
      // Call the Supabase RPC to compute and upsert the student subject result
      final response = await _supabaseClient.rpc(
        'compute_student_subject_result',
        params: {
          'p_student_id': studentId,
          'p_subject_id': subjectId,
          'p_class_id': classId,
          'p_academic_session_id': academicSessionId,
        },
      );

      if (response == null) {
        return FailureResult(Failure.notFound(
          message: 'Student subject result not found',
        ));
      }

      final model = StudentSubjectResultModel.fromJson(
        response as Map<String, dynamic>,
      );
      return Success(model.toEntity());
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Compute student subject result RPC failed', error: e);
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<StudentSubjectResultEntity>>> getStudentSubjectResults({
    required String studentId,
    required String academicSessionId,
  }) async {
    try {
      final models = await _remoteDataSource.getStudentSubjectResults(
        studentId,
        academicSessionId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<StudentSubjectResultEntity>>> getClassSubjectResults({
    required String classId,
    required String subjectId,
    required String academicSessionId,
  }) async {
    try {
      final models = await _remoteDataSource.getClassSubjectResults(
        classId,
        subjectId,
        academicSessionId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Student Overall Results
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<StudentOverallResultEntity>> getStudentOverallResult({
    required String studentId,
    required String classId,
    required String academicSessionId,
  }) async {
    try {
      final model = await _remoteDataSource.getStudentOverallResult(
        studentId,
        classId,
        academicSessionId,
      );

      if (model == null) {
        return FailureResult(Failure.notFound(
          message:
              'Student overall result not found for student $studentId in class $classId',
        ));
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<StudentOverallResultEntity>>> getClassOverallResults({
    required String classId,
    required String academicSessionId,
  }) async {
    try {
      final models = await _remoteDataSource.getClassOverallResults(
        classId,
        academicSessionId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<StudentOverallResultEntity>> updateTeacherComment({
    required String resultId,
    required String comment,
  }) async {
    try {
      // Fetch the existing overall result
      final response = await _supabaseClient
          .from('student_overall_results')
          .select()
          .eq('id', resultId)
          .single();

      final existing = StudentOverallResultModel.fromJson(response);

      // Update with the new teacher comment
      final updated = existing.copyWith(teacherComment: comment);

      final result = await _remoteDataSource.upsertStudentOverallResult(updated);
      return Success(result.toEntity());
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return FailureResult(
          Failure.notFound(message: 'Overall result not found: $resultId'),
        );
      }
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Topic Mastery
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TopicMasteryEntity>> getTopicMastery({
    required String studentId,
    required String topicId,
  }) async {
    try {
      final model = await _remoteDataSource.getTopicMastery(
        studentId,
        topicId,
      );

      if (model == null) {
        return FailureResult(Failure.notFound(
          message: 'Topic mastery not found for student $studentId, topic $topicId',
        ));
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TopicMasteryEntity>>> getStudentTopicMastery({
    required String studentId,
    required String subjectId,
  }) async {
    try {
      final models = await _remoteDataSource.getStudentTopicMastery(
        studentId,
        subjectId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TopicMasteryEntity>>> getClassTopicMastery({
    required String classId,
    required String subjectId,
  }) async {
    try {
      final models = await _remoteDataSource.getClassTopicMastery(
        classId,
        subjectId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Class Performance
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ClassPerformanceEntity>> getClassPerformance({
    required String classId,
    String? subjectId,
    required String academicSessionId,
  }) async {
    try {
      final model = await _remoteDataSource.getClassPerformance(
        classId,
        subjectId,
        academicSessionId,
      );

      if (model == null) {
        return FailureResult(Failure.notFound(
          message:
              'Class performance not found for class $classId${subjectId != null ? ', subject $subjectId' : ''}',
        ));
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ClassPerformanceEntity>>> getSchoolClassPerformances({
    required String schoolId,
    required String academicSessionId,
  }) async {
    try {
      final models = await _remoteDataSource.getSchoolClassPerformances(
        schoolId,
        academicSessionId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // School Performance
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SchoolPerformanceEntity>> getSchoolPerformance({
    required String schoolId,
    required String academicSessionId,
  }) async {
    try {
      final model = await _remoteDataSource.getSchoolPerformance(
        schoolId,
        academicSessionId,
      );

      if (model == null) {
        return FailureResult(Failure.notFound(
          message: 'School performance not found for school $schoolId',
        ));
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Analytics Snapshots
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AnalyticsSnapshotEntity?>> getAnalyticsSnapshot({
    required String schoolId,
    required String snapshotType,
    String? entityId,
    String? academicSessionId,
  }) async {
    try {
      final model = await _remoteDataSource.getAnalyticsSnapshot(
        schoolId,
        snapshotType,
        entityId: entityId,
        academicSessionId: academicSessionId,
      );
      return Success(model?.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AnalyticsSnapshotEntity>> createAnalyticsSnapshot(
    AnalyticsSnapshotEntity snapshot,
  ) async {
    try {
      final model = AnalyticsSnapshotModel.fromEntity(snapshot);
      final created = await _remoteDataSource.createAnalyticsSnapshot(model);
      return Success(created.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Dashboard Configurations
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DashboardConfigurationEntity>> getDashboardConfiguration({
    required String schoolId,
    required String role,
  }) async {
    try {
      final model = await _remoteDataSource.getDashboardConfiguration(
        schoolId,
        role,
      );

      if (model == null) {
        return FailureResult(Failure.notFound(
          message:
              'Dashboard configuration not found for school $schoolId, role $role',
        ));
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DashboardConfigurationEntity>> saveDashboardConfiguration(
    DashboardConfigurationEntity config,
  ) async {
    try {
      final model = DashboardConfigurationModel.fromEntity(config);
      final saved = await _remoteDataSource.upsertDashboardConfiguration(model);
      return Success(saved.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> updateDashboardWidgets({
    required String dashboardId,
    required List<DashboardWidgetConfigEntity> widgets,
  }) async {
    try {
      final widgetModels =
          widgets.map(DashboardWidgetConfigModel.fromEntity).toList();
      await _remoteDataSource.updateDashboardWidgets(
        dashboardId,
        widgetModels,
      );
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Report Exports
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ReportExportEntity>> createReportExport({
    required String schoolId,
    required String requestedBy,
    required ReportType reportType,
    required ReportFormat reportFormat,
    required String title,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final now = DateTime.now();
      final export = ReportExportModel(
        id: const Uuid().v4(),
        schoolId: schoolId,
        requestedBy: requestedBy,
        reportType: reportType.value,
        reportFormat: reportFormat.value,
        status: 'pending',
        title: title,
        parameters: parameters ?? {},
        filters: filters ?? {},
        fileUrl: null,
        fileSizeBytes: null,
        rowCount: null,
        errorMessage: null,
        processingTimeMs: null,
        expiresAt: null,
        downloadedAt: null,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _remoteDataSource.createReportExport(export);
      return Success(created.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ReportExportEntity>> getReportExport(String exportId) async {
    try {
      final model = await _remoteDataSource.getReportExport(exportId);

      if (model == null) {
        return FailureResult(
          Failure.notFound(message: 'Report export not found: $exportId'),
        );
      }

      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ReportExportEntity>>> getReportExports({
    String? schoolId,
    String? requestedBy,
    ReportStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getReportExports(
        schoolId: schoolId,
        requestedBy: requestedBy,
        status: status?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> downloadReport(String exportId) async {
    try {
      final model = await _remoteDataSource.getReportExport(exportId);

      if (model == null) {
        return FailureResult(
          Failure.notFound(message: 'Report export not found: $exportId'),
        );
      }

      if (model.fileUrl == null) {
        return FailureResult(Failure.server(
          message: 'Report file is not yet available',
          statusCode: 404,
        ));
      }

      // Update downloaded_at timestamp
      final now = DateTime.now();
      final updated = model.copyWith(downloadedAt: now);
      await _remoteDataSource.updateReportExport(updated);

      return Success(model.fileUrl!);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Result Locks
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ResultLockEntity>> lockResults({
    required String examId,
    required String schoolId,
    required String lockedBy,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      final lock = ResultLockModel(
        id: const Uuid().v4(),
        examId: examId,
        schoolId: schoolId,
        lockedBy: lockedBy,
        lockedAt: now,
        reason: reason,
        isLocked: true,
        unlockedBy: null,
        unlockedAt: null,
        createdAt: now,
      );

      final created = await _remoteDataSource.createResultLock(lock);
      return Success(created.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ResultLockEntity>> unlockResults({
    required String examId,
    required String unlockedBy,
  }) async {
    try {
      final existing = await _remoteDataSource.getResultLock(examId);

      if (existing == null) {
        return FailureResult(Failure.notFound(
          message: 'No result lock found for exam: $examId',
        ));
      }

      final updated = existing.copyWith(
        isLocked: false,
        unlockedBy: unlockedBy,
        unlockedAt: DateTime.now(),
      );

      final result = await _remoteDataSource.updateResultLock(updated);
      return Success(result.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> isResultLocked(String examId) async {
    try {
      final lock = await _remoteDataSource.getResultLock(examId);
      return Success(lock?.isLocked ?? false);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Result Access Logging
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> logResultAccess({
    required String userId,
    required String schoolId,
    required String action,
    required String entityType,
    required String entityId,
    ResultAccessLevel accessLevel = ResultAccessLevel.limited,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _remoteDataSource.insertResultAccessLog(
        schoolId: schoolId,
        userId: userId,
        action: action,
        resourceType: entityType,
        resourceId: entityId,
        details: {
          if (accessLevel != ResultAccessLevel.limited)
            'access_level': accessLevel.value,
          if (ipAddress != null) 'ip_address': ipAddress,
          if (userAgent != null) 'user_agent': userAgent,
          if (details != null) ...details,
        },
      );
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Bulk Operations
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> recomputeClassResults({
    required String classId,
    required String academicSessionId,
  }) async {
    try {
      // 1. Get all student/subject pairs for this class and session
      final subjectResults = await _supabaseClient
          .from('student_subject_results')
          .select('student_id, subject_id')
          .eq('class_id', classId)
          .eq('academic_session_id', academicSessionId);

      // 2. Call the compute_student_subject_result RPC for each pair
      for (final row in subjectResults as List) {
        try {
          await _supabaseClient.rpc(
            'compute_student_subject_result',
            params: {
              'p_student_id': row['student_id'],
              'p_subject_id': row['subject_id'],
              'p_class_id': classId,
              'p_academic_session_id': academicSessionId,
            },
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to recompute result for student ${row['student_id']}, '
            'subject ${row['subject_id']}: $e',
          );
          // Continue with other students even if one fails
        }
      }

      // 3. Recompute overall results for all students in the class
      final studentIds = (subjectResults as List)
          .map((r) => r['student_id'] as String)
          .toSet();

      for (final studentId in studentIds) {
        try {
          await _supabaseClient.rpc(
            'compute_student_overall_result',
            params: {
              'p_student_id': studentId,
              'p_class_id': classId,
              'p_academic_session_id': academicSessionId,
            },
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to recompute overall result for student $studentId: $e',
          );
          // Continue with other students even if one fails
        }
      }

      return const Success(null);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Recompute class results failed', error: e);
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishResults(String examId) async {
    try {
      // Update exam_results: set is_released = true, released_at = now()
      await _supabaseClient
          .from('exam_results')
          .update({
            'is_released': true,
            'released_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('exam_id', examId);

      return const Success(null);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Publish results failed', error: e);
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> withholdResults(String examId) async {
    try {
      // Update exam_results: set is_released = false
      await _supabaseClient
          .from('exam_results')
          .update({'is_released': false})
          .eq('exam_id', examId);

      return const Success(null);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Withhold results failed', error: e);
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
