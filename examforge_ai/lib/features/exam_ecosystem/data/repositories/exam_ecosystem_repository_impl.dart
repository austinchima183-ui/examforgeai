import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../../domain/repositories/exam_ecosystem_repository.dart';
import '../datasources/exam_ecosystem_remote_datasource.dart';
import '../models/exam_ecosystem_models.dart';

/// Concrete implementation of [ExamEcosystemRepository] that delegates
/// all operations to [ExamEcosystemRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class ExamEcosystemRepositoryImpl implements ExamEcosystemRepository {
  ExamEcosystemRepositoryImpl({
    required ExamEcosystemRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ExamEcosystemRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER: Exception → Failure mapping
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapException(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
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
    } else if (e is FormatException) {
      return Failure.server(
        message: 'Data format error: ${e.message}',
        statusCode: 422,
      );
    } else {
      AppLogger.error('Unexpected ExamEcosystem repository error', error: e);
      return Failure.server(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAMINATION BODIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ExaminationBody>>> getExaminationBodies({
    bool? isActive,
  }) async {
    try {
      final data = await _remoteDataSource.getExaminationBodies(isActive: isActive);
      final entities = data
          .map((e) => ExaminationBodyModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ExaminationBody>> getExaminationBodyById(String id) async {
    try {
      final data = await _remoteDataSource.getExaminationBodyById(id);
      return Success(ExaminationBodyModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ExaminationBody>>> getExaminationBodiesByType(
    ExamBodyType examBodyType,
  ) async {
    try {
      final data = await _remoteDataSource.getExaminationBodiesByType(
        examBodyType.value,
      );
      final entities = data
          .map((e) => ExaminationBodyModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAMINATION PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ExaminationProduct>>> getExaminationProducts({
    String? examBodyId,
    ExamCategoryType? examCategory,
    PreparationType? preparationType,
    String? educationalLevelId,
    String? subjectId,
    bool? isActive,
  }) async {
    try {
      final filters = <String, dynamic>{
        if (examBodyId != null) 'exam_body_id': examBodyId,
        if (examCategory != null) 'exam_category': examCategory.value,
        if (preparationType != null) 'preparation_type': preparationType.value,
        if (educationalLevelId != null) 'educational_level_id': educationalLevelId,
        if (subjectId != null) 'subject_id': subjectId,
        if (isActive != null) 'is_active': isActive,
      };
      final data = await _remoteDataSource.getExaminationProducts(filters);
      final entities = data
          .map((e) => ExaminationProductModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ExaminationProduct>> getExaminationProductById(String id) async {
    try {
      final data = await _remoteDataSource.getExaminationProductById(id);
      return Success(ExaminationProductModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ExaminationProduct>> createExaminationProduct(
    ExaminationProduct product,
  ) async {
    try {
      final model = ExaminationProductModel.fromEntity(product);
      final data = await _remoteDataSource.createExaminationProduct(model.toJson());
      return Success(ExaminationProductModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ExaminationProduct>> updateExaminationProduct(
    ExaminationProduct product,
  ) async {
    try {
      final model = ExaminationProductModel.fromEntity(product);
      final data = await _remoteDataSource.updateExaminationProduct(
        product.id,
        model.toJson(),
      );
      return Success(ExaminationProductModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOCK EXAMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<MockExam>>> getMockExams({
    String? examinationProductId,
    String? schoolId,
    ExamBodyType? examBodyType,
    MockExamStatus? status,
  }) async {
    try {
      final filters = <String, dynamic>{
        if (examinationProductId != null) 'examination_product_id': examinationProductId,
        if (schoolId != null) 'school_id': schoolId,
        if (examBodyType != null) 'exam_body_type': examBodyType.value,
        if (status != null) 'status': status.value,
      };
      final data = await _remoteDataSource.getMockExams(filters);
      final entities = data
          .map((e) => MockExamModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExam>> getMockExamById(String id) async {
    try {
      final data = await _remoteDataSource.getMockExamById(id);
      return Success(MockExamModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExam>> createMockExam(MockExam mockExam) async {
    try {
      final model = MockExamModel.fromEntity(mockExam);
      final data = await _remoteDataSource.createMockExam(model.toJson());
      return Success(MockExamModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExam>> updateMockExam(MockExam mockExam) async {
    try {
      final model = MockExamModel.fromEntity(mockExam);
      final data = await _remoteDataSource.updateMockExam(
        mockExam.id,
        model.toJson(),
      );
      return Success(MockExamModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteMockExam(String id) async {
    try {
      await _remoteDataSource.deleteMockExam(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExam>> publishMockExam(String id) async {
    try {
      final data = await _remoteDataSource.publishMockExam(id);
      return Success(MockExamModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExamQuestion>> addMockExamQuestion(
    MockExamQuestion question,
  ) async {
    try {
      final model = MockExamQuestionModel.fromEntity(question);
      final data = await _remoteDataSource.addMockExamQuestion(model.toJson());
      return Success(MockExamQuestionModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> removeMockExamQuestion(String questionId) async {
    try {
      await _remoteDataSource.removeMockExamQuestion(questionId);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOCK EXAM ATTEMPTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<MockExamAttempt>> startMockExamAttempt({
    required String mockExamId,
    required String userId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final data = await _remoteDataSource.startMockExamAttempt({
        'mock_exam_id': mockExamId,
        'user_id': userId,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
        if (deviceInfo != null) 'device_info': deviceInfo,
      });
      return Success(MockExamAttemptModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExamAttempt>> submitMockExamAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
    int? timeTakenSeconds,
  }) async {
    try {
      final data = await _remoteDataSource.submitMockExamAttempt(
        attemptId,
        {
          'answers': answers,
          'is_completed': true,
          'submitted_at': DateTime.now().toIso8601String(),
          'status': 'submitted',
          if (timeTakenSeconds != null)
            'time_taken_seconds': timeTakenSeconds,
        },
      );
      return Success(MockExamAttemptModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MockExamAttempt>> getMockExamAttempt(String attemptId) async {
    try {
      final data = await _remoteDataSource.getMockExamAttempt(attemptId);
      return Success(MockExamAttemptModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<MockExamAttempt>>> getUserMockExamAttempts({
    required String userId,
    String? mockExamId,
  }) async {
    try {
      final filters = <String, dynamic>{
        'user_id': userId,
        if (mockExamId != null) 'mock_exam_id': mockExamId,
      };
      final data = await _remoteDataSource.getUserMockExamAttempts(filters);
      final entities = data
          .map((e) => MockExamAttemptModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<MockExamAttempt>>> getMockExamResults(
    String mockExamId,
  ) async {
    try {
      final data = await _remoteDataSource.getMockExamResults(mockExamId);
      final entities = data
          .map((e) => MockExamAttemptModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // READINESS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ReadinessAssessment>> getReadinessAssessment(String id) async {
    try {
      final data = await _remoteDataSource.getReadinessAssessment(id);
      return Success(ReadinessAssessmentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ReadinessAssessment>>> getUserReadiness({
    required String userId,
    String? examBodyId,
    String? subjectId,
  }) async {
    try {
      final filters = <String, dynamic>{
        'user_id': userId,
        if (examBodyId != null) 'exam_body_id': examBodyId,
        if (subjectId != null) 'subject_id': subjectId,
      };
      final data = await _remoteDataSource.getUserReadiness(filters);
      final entities = data
          .map((e) => ReadinessAssessmentModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ReadinessAssessment>> calculateReadiness({
    required String userId,
    required String examBodyId,
    String? subjectId,
  }) async {
    try {
      final data = await _remoteDataSource.calculateReadiness({
        'p_user_id': userId,
        'p_exam_body_id': examBodyId,
        if (subjectId != null) 'p_subject_id': subjectId,
      });
      return Success(ReadinessAssessmentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ReadinessAssessment>>> getExamReadiness({
    required String userId,
    required String examBodyId,
  }) async {
    try {
      final data = await _remoteDataSource.getExamReadiness({
        'p_user_id': userId,
        'p_exam_body_id': examBodyId,
      });
      final entities = data
          .map((e) => ReadinessAssessmentModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLANS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudyPlan>>> getStudyPlans({
    required String userId,
    bool? isActive,
  }) async {
    try {
      final filters = <String, dynamic>{
        'user_id': userId,
        if (isActive != null) 'is_active': isActive,
      };
      final data = await _remoteDataSource.getStudyPlans(filters);
      final entities = data
          .map((e) => StudyPlanModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlan>> getStudyPlanById(String id) async {
    try {
      final data = await _remoteDataSource.getStudyPlanById(id);
      return Success(StudyPlanModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlan>> createStudyPlan(StudyPlan studyPlan) async {
    try {
      final model = StudyPlanModel.fromEntity(studyPlan);
      final data = await _remoteDataSource.createStudyPlan(model.toJson());
      return Success(StudyPlanModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlan>> updateStudyPlan(StudyPlan studyPlan) async {
    try {
      final model = StudyPlanModel.fromEntity(studyPlan);
      final data = await _remoteDataSource.updateStudyPlan(
        studyPlan.id,
        model.toJson(),
      );
      return Success(StudyPlanModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteStudyPlan(String id) async {
    try {
      await _remoteDataSource.deleteStudyPlan(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlan>> generateAiStudyPlan({
    required String userId,
    required String examBodyId,
    String? subjectId,
    String? educationalLevelId,
    DateTime? targetDate,
    int dailyStudyMinutes = 60,
  }) async {
    try {
      final data = await _remoteDataSource.generateAiStudyPlan({
        'p_user_id': userId,
        'p_exam_body_id': examBodyId,
        if (subjectId != null) 'p_subject_id': subjectId,
        if (educationalLevelId != null)
          'p_educational_level_id': educationalLevelId,
        if (targetDate != null)
          'p_target_date': targetDate.toIso8601String(),
        'p_daily_study_minutes': dailyStudyMinutes,
      });
      return Success(StudyPlanModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLAN ACTIVITIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<StudyPlanActivity>>> getStudyPlanActivities(
    String studyPlanId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  }) async {
    try {
      final filters = <String, dynamic>{
        if (isCompleted != null) 'is_completed': isCompleted,
      };
      final data = await _remoteDataSource.getStudyPlanActivities(
        studyPlanId,
        filters: filters.isNotEmpty ? filters : null,
      );
      var entities = data
          .map((e) => StudyPlanActivityModel.fromJson(e).toEntity())
          .toList();

      // Apply date range filtering client-side for flexibility
      if (startDate != null) {
        entities = entities
            .where((a) => a.scheduledDate.isAfter(startDate) ||
                a.scheduledDate.isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null) {
        entities = entities
            .where((a) => a.scheduledDate.isBefore(endDate) ||
                a.scheduledDate.isAtSameMomentAs(endDate))
            .toList();
      }

      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlanActivity>> createStudyPlanActivity(
    StudyPlanActivity activity,
  ) async {
    try {
      final model = StudyPlanActivityModel.fromEntity(activity);
      final data = await _remoteDataSource.createStudyPlanActivity(
        model.toJson(),
      );
      return Success(StudyPlanActivityModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlanActivity>> updateStudyPlanActivity(
    StudyPlanActivity activity,
  ) async {
    try {
      final model = StudyPlanActivityModel.fromEntity(activity);
      final data = await _remoteDataSource.updateStudyPlanActivity(
        activity.id,
        model.toJson(),
      );
      return Success(StudyPlanActivityModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<StudyPlanActivity>> completeStudyPlanActivity({
    required String activityId,
    double? performanceScore,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = await _remoteDataSource.completeStudyPlanActivity(
        activityId,
        {
          if (performanceScore != null)
            'performance_score': performanceScore,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return Success(StudyPlanActivityModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }
}
