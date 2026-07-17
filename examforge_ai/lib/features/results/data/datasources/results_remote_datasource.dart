import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/results_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote Results Engine data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class ResultsRemoteDataSource {
  // ─── Grade Scales ──────────────────────────────────────────────────

  Future<GradeScaleModel> createGradeScale(GradeScaleModel scale);
  Future<GradeScaleModel> updateGradeScale(GradeScaleModel scale);
  Future<void> deleteGradeScale(String scaleId);
  Future<GradeScaleModel> getGradeScale(String scaleId);
  Future<List<GradeScaleModel>> getGradeScales(
    String schoolId, {
    bool? isActive,
    String? gradeType,
  });

  // ─── AI Grading ────────────────────────────────────────────────────

  Future<AiGradingResultModel> insertAiGradingResult(
    AiGradingResultModel result,
  );
  Future<AiGradingResultModel> updateAiGradingResult(
    AiGradingResultModel result,
  );
  Future<AiGradingResultModel?> getAiGradingByAnswer(String answerId);
  Future<List<AiGradingResultModel>> getPendingAiGradings(String examId);

  // ─── Teacher Feedback ──────────────────────────────────────────────

  Future<TeacherFeedbackModel> upsertTeacherFeedback(
    TeacherFeedbackModel feedback,
  );
  Future<TeacherFeedbackModel?> getTeacherFeedbackByAnswer(String answerId);
  Future<List<TeacherFeedbackModel>> getTeacherFeedbackByExam(
    String examId,
    String teacherId,
  );

  // ─── Student Results ───────────────────────────────────────────────

  Future<StudentSubjectResultModel> upsertStudentSubjectResult(
    StudentSubjectResultModel result,
  );
  Future<List<StudentSubjectResultModel>> getStudentSubjectResults(
    String studentId,
    String academicSessionId,
  );
  Future<List<StudentSubjectResultModel>> getClassSubjectResults(
    String classId,
    String subjectId,
    String academicSessionId,
  );
  Future<StudentOverallResultModel> upsertStudentOverallResult(
    StudentOverallResultModel result,
  );
  Future<StudentOverallResultModel?> getStudentOverallResult(
    String studentId,
    String classId,
    String academicSessionId,
  );
  Future<List<StudentOverallResultModel>> getClassOverallResults(
    String classId,
    String academicSessionId,
  );

  // ─── Topic Mastery ────────────────────────────────────────────────

  Future<TopicMasteryModel> upsertTopicMastery(TopicMasteryModel mastery);
  Future<TopicMasteryModel?> getTopicMastery(
    String studentId,
    String topicId,
  );
  Future<List<TopicMasteryModel>> getStudentTopicMastery(
    String studentId,
    String subjectId,
  );
  Future<List<TopicMasteryModel>> getClassTopicMastery(
    String classId,
    String subjectId,
  );

  // ─── Class / School Performance ───────────────────────────────────

  Future<ClassPerformanceModel> upsertClassPerformance(
    ClassPerformanceModel performance,
  );
  Future<ClassPerformanceModel?> getClassPerformance(
    String classId,
    String? subjectId,
    String academicSessionId,
  );
  Future<List<ClassPerformanceModel>> getSchoolClassPerformances(
    String schoolId,
    String academicSessionId,
  );
  Future<SchoolPerformanceModel> upsertSchoolPerformance(
    SchoolPerformanceModel performance,
  );
  Future<SchoolPerformanceModel?> getSchoolPerformance(
    String schoolId,
    String academicSessionId,
  );

  // ─── Analytics Snapshots ──────────────────────────────────────────

  Future<AnalyticsSnapshotModel> createAnalyticsSnapshot(
    AnalyticsSnapshotModel snapshot,
  );
  Future<AnalyticsSnapshotModel?> getAnalyticsSnapshot(
    String schoolId,
    String snapshotType, {
    String? entityId,
    String? academicSessionId,
  });

  // ─── Dashboard Configuration ──────────────────────────────────────

  Future<DashboardConfigurationModel> upsertDashboardConfiguration(
    DashboardConfigurationModel config,
  );
  Future<DashboardConfigurationModel?> getDashboardConfiguration(
    String schoolId,
    String role,
  );
  Future<void> updateDashboardWidgets(
    String dashboardId,
    List<DashboardWidgetConfigModel> widgets,
  );

  // ─── Report Exports ───────────────────────────────────────────────

  Future<ReportExportModel> createReportExport(ReportExportModel export);
  Future<ReportExportModel> updateReportExport(ReportExportModel export);
  Future<ReportExportModel?> getReportExport(String exportId);
  Future<List<ReportExportModel>> getReportExports({
    String? schoolId,
    String? requestedBy,
    String? status,
    int page = 1,
    int perPage = 20,
  });

  // ─── Result Locks ─────────────────────────────────────────────────

  Future<ResultLockModel> createResultLock(ResultLockModel lock);
  Future<ResultLockModel> updateResultLock(ResultLockModel lock);
  Future<ResultLockModel?> getResultLock(String examId);

  // ─── Result Access Log ────────────────────────────────────────────

  Future<void> insertResultAccessLog({
    required String schoolId,
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class ResultsRemoteDataSourceImpl implements ResultsRemoteDataSource {
  ResultsRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Table names ────────────────────────────────────────────────────

  static const _gradeScalesTable = 'grade_scales';
  static const _gradeScaleEntriesTable = 'grade_scale_entries';
  static const _aiGradingResultsTable = 'ai_grading_results';
  static const _teacherFeedbackTable = 'teacher_feedback';
  static const _studentSubjectResultsTable = 'student_subject_results';
  static const _studentOverallResultsTable = 'student_overall_results';
  static const _topicMasteryTable = 'topic_mastery';
  static const _classPerformanceTable = 'class_performance_summaries';
  static const _schoolPerformanceTable = 'school_performance_summaries';
  static const _analyticsSnapshotsTable = 'analytics_snapshots';
  static const _dashboardConfigurationsTable = 'dashboard_configurations';
  static const _dashboardWidgetConfigsTable = 'dashboard_widget_configs';
  static const _reportExportsTable = 'report_exports';
  static const _resultLocksTable = 'result_locks';
  static const _resultAccessLogTable = 'result_access_log';

  // ═══════════════════════════════════════════════════════════════════
  // Grade Scales
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<GradeScaleModel> createGradeScale(GradeScaleModel scale) async {
    try {
      // 1. Insert the grade_scale row (without nested entries)
      final scaleJson = scale.toJson()
        ..remove('scale_entries');

      final response = await _supabaseClient
          .from(_gradeScalesTable)
          .insert(scaleJson)
          .select()
          .single();

      final createdScale = GradeScaleModel.fromJson(response);

      // 2. Insert entries
      if (scale.scaleEntries.isNotEmpty) {
        final entriesRows = scale.scaleEntries.map((e) {
          final json = e.toJson();
          json['grade_scale_id'] = createdScale.id;
          return json;
        }).toList();

        await _supabaseClient
            .from(_gradeScaleEntriesTable)
            .insert(entriesRows);
      }

      // 3. Return scale with entries populated
      return createdScale.copyWith(
        scaleEntries: scale.scaleEntries,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create grade scale failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create grade scale unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create grade scale: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GradeScaleModel> updateGradeScale(GradeScaleModel scale) async {
    try {
      // 1. Update the grade_scale row
      final scaleJson = scale.toJson()
        ..remove('scale_entries');

      final response = await _supabaseClient
          .from(_gradeScalesTable)
          .update(scaleJson)
          .eq('id', scale.id)
          .select()
          .single();

      final updatedScale = GradeScaleModel.fromJson(response);

      // 2. Delete existing entries and re-insert
      await _supabaseClient
          .from(_gradeScaleEntriesTable)
          .delete()
          .eq('grade_scale_id', scale.id);

      if (scale.scaleEntries.isNotEmpty) {
        final entriesRows = scale.scaleEntries.map((e) {
          final json = e.toJson();
          json['grade_scale_id'] = scale.id;
          return json;
        }).toList();

        await _supabaseClient
            .from(_gradeScaleEntriesTable)
            .insert(entriesRows);
      }

      // 3. Return scale with entries populated
      return updatedScale.copyWith(
        scaleEntries: scale.scaleEntries,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update grade scale failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Grade scale not found: ${scale.id}');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update grade scale unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update grade scale: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteGradeScale(String scaleId) async {
    try {
      await _supabaseClient
          .from(_gradeScalesTable)
          .delete()
          .eq('id', scaleId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete grade scale failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete grade scale unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete grade scale: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GradeScaleModel> getGradeScale(String scaleId) async {
    try {
      final response = await _supabaseClient
          .from(_gradeScalesTable)
          .select('*, grade_scale_entries(*)')
          .eq('id', scaleId)
          .single();

      // Map nested entries from the join
      final mappedResponse = _mapGradeScaleEntries(response);

      return GradeScaleModel.fromJson(mappedResponse);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get grade scale failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Grade scale not found: $scaleId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get grade scale unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get grade scale: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<GradeScaleModel>> getGradeScales(
    String schoolId, {
    bool? isActive,
    String? gradeType,
  }) async {
    try {
      var query = _supabaseClient
          .from(_gradeScalesTable)
          .select('*, grade_scale_entries(*)');

      query = query.eq('school_id', schoolId);

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (gradeType != null) {
        query = query.eq('grade_type', gradeType);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return response.map<GradeScaleModel>((json) {
        final mappedJson = _mapGradeScaleEntries(json);
        return GradeScaleModel.fromJson(mappedJson);
      }).toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get grade scales failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get grade scales unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get grade scales: $e',
        statusCode: 500,
      );
    }
  }

  /// Maps the nested `grade_scale_entries` join result to the model's
  /// expected `scale_entries` key.
  Map<String, dynamic> _mapGradeScaleEntries(Map<String, dynamic> json) {
    final entries = json['grade_scale_entries'];
    if (entries is List) {
      return {
        ...json,
        'scale_entries': entries,
      };
    }
    return json;
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI Grading
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AiGradingResultModel> insertAiGradingResult(
    AiGradingResultModel result,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_aiGradingResultsTable)
          .insert(result.toJson())
          .select()
          .single();

      return AiGradingResultModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Insert AI grading result failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Insert AI grading result unexpected error', error: e);
      throw ServerException(
        message: 'Failed to insert AI grading result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiGradingResultModel> updateAiGradingResult(
    AiGradingResultModel result,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_aiGradingResultsTable)
          .update(result.toJson())
          .eq('id', result.id)
          .select()
          .single();

      return AiGradingResultModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update AI grading result failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(
          'AI grading result not found: ${result.id}',
        );
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update AI grading result unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update AI grading result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiGradingResultModel?> getAiGradingByAnswer(String answerId) async {
    try {
      final response = await _supabaseClient
          .from(_aiGradingResultsTable)
          .select()
          .eq('answer_id', answerId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;

      return AiGradingResultModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get AI grading by answer failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get AI grading by answer unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get AI grading by answer: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AiGradingResultModel>> getPendingAiGradings(
    String examId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_aiGradingResultsTable)
          .select()
          .eq('exam_id', examId)
          .eq('status', 'pending')
          .order('created_at');

      return response
          .map<AiGradingResultModel>(
            (json) => AiGradingResultModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get pending AI gradings failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get pending AI gradings unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get pending AI gradings: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Teacher Feedback
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<TeacherFeedbackModel> upsertTeacherFeedback(
    TeacherFeedbackModel feedback,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherFeedbackTable)
          .upsert(
            feedback.toJson(),
            onConflict: 'answer_id',
          )
          .select()
          .single();

      return TeacherFeedbackModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert teacher feedback failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Upsert teacher feedback unexpected error', error: e);
      throw ServerException(
        message: 'Failed to upsert teacher feedback: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TeacherFeedbackModel?> getTeacherFeedbackByAnswer(
    String answerId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherFeedbackTable)
          .select()
          .eq('answer_id', answerId)
          .limit(1);

      if (response.isEmpty) return null;

      return TeacherFeedbackModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get teacher feedback by answer failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get teacher feedback by answer unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get teacher feedback by answer: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TeacherFeedbackModel>> getTeacherFeedbackByExam(
    String examId,
    String teacherId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherFeedbackTable)
          .select()
          .eq('exam_id', examId)
          .eq('teacher_id', teacherId)
          .order('created_at');

      return response
          .map<TeacherFeedbackModel>(
            (json) => TeacherFeedbackModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get teacher feedback by exam failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get teacher feedback by exam unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get teacher feedback by exam: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Student Results
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<StudentSubjectResultModel> upsertStudentSubjectResult(
    StudentSubjectResultModel result,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentSubjectResultsTable)
          .upsert(
            result.toJson(),
            onConflict: 'student_id,subject_id,class_id,academic_session_id',
          )
          .select()
          .single();

      return StudentSubjectResultModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert student subject result failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Upsert student subject result unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to upsert student subject result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<StudentSubjectResultModel>> getStudentSubjectResults(
    String studentId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentSubjectResultsTable)
          .select()
          .eq('student_id', studentId)
          .eq('academic_session_id', academicSessionId)
          .order('created_at');

      return response
          .map<StudentSubjectResultModel>(
            (json) => StudentSubjectResultModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student subject results failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get student subject results unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get student subject results: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<StudentSubjectResultModel>> getClassSubjectResults(
    String classId,
    String subjectId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentSubjectResultsTable)
          .select()
          .eq('class_id', classId)
          .eq('subject_id', subjectId)
          .eq('academic_session_id', academicSessionId)
          .order('percentage', ascending: false);

      return response
          .map<StudentSubjectResultModel>(
            (json) => StudentSubjectResultModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get class subject results failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get class subject results unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get class subject results: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentOverallResultModel> upsertStudentOverallResult(
    StudentOverallResultModel result,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentOverallResultsTable)
          .upsert(
            result.toJson(),
            onConflict: 'student_id,class_id,academic_session_id',
          )
          .select()
          .single();

      return StudentOverallResultModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert student overall result failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Upsert student overall result unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to upsert student overall result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentOverallResultModel?> getStudentOverallResult(
    String studentId,
    String classId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentOverallResultsTable)
          .select()
          .eq('student_id', studentId)
          .eq('class_id', classId)
          .eq('academic_session_id', academicSessionId)
          .limit(1);

      if (response.isEmpty) return null;

      return StudentOverallResultModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student overall result failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get student overall result unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get student overall result: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<StudentOverallResultModel>> getClassOverallResults(
    String classId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentOverallResultsTable)
          .select()
          .eq('class_id', classId)
          .eq('academic_session_id', academicSessionId)
          .order('overall_percentage', ascending: false);

      return response
          .map<StudentOverallResultModel>(
            (json) => StudentOverallResultModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get class overall results failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get class overall results unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get class overall results: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Topic Mastery
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<TopicMasteryModel> upsertTopicMastery(
    TopicMasteryModel mastery,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_topicMasteryTable)
          .upsert(
            mastery.toJson(),
            onConflict: 'student_id,topic_id',
          )
          .select()
          .single();

      return TopicMasteryModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert topic mastery failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Upsert topic mastery unexpected error', error: e);
      throw ServerException(
        message: 'Failed to upsert topic mastery: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TopicMasteryModel?> getTopicMastery(
    String studentId,
    String topicId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_topicMasteryTable)
          .select()
          .eq('student_id', studentId)
          .eq('topic_id', topicId)
          .limit(1);

      if (response.isEmpty) return null;

      return TopicMasteryModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get topic mastery failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get topic mastery unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get topic mastery: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TopicMasteryModel>> getStudentTopicMastery(
    String studentId,
    String subjectId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_topicMasteryTable)
          .select()
          .eq('student_id', studentId)
          .eq('subject_id', subjectId)
          .order('updated_at', ascending: false);

      return response
          .map<TopicMasteryModel>(
            (json) => TopicMasteryModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student topic mastery failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student topic mastery unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student topic mastery: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TopicMasteryModel>> getClassTopicMastery(
    String classId,
    String subjectId,
  ) async {
    try {
      // topic_mastery rows don't have class_id directly; filter by
      // school_id + subject_id and let the caller narrow by class
      // enrollment. For now, query by subject_id across the school.
      final response = await _supabaseClient
          .from(_topicMasteryTable)
          .select()
          .eq('subject_id', subjectId)
          .order('accuracy_percentage', ascending: false);

      return response
          .map<TopicMasteryModel>(
            (json) => TopicMasteryModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get class topic mastery failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get class topic mastery unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get class topic mastery: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Class / School Performance
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ClassPerformanceModel> upsertClassPerformance(
    ClassPerformanceModel performance,
  ) async {
    try {
      // Build conflict string depending on whether subjectId is present
      final onConflict = performance.subjectId != null
          ? 'class_id,subject_id,academic_session_id'
          : 'class_id,academic_session_id';

      final response = await _supabaseClient
          .from(_classPerformanceTable)
          .upsert(
            performance.toJson(),
            onConflict: onConflict,
          )
          .select()
          .single();

      return ClassPerformanceModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert class performance failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Upsert class performance unexpected error', error: e);
      throw ServerException(
        message: 'Failed to upsert class performance: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ClassPerformanceModel?> getClassPerformance(
    String classId,
    String? subjectId,
    String academicSessionId,
  ) async {
    try {
      var query = _supabaseClient
          .from(_classPerformanceTable)
          .select()
          .eq('class_id', classId)
          .eq('academic_session_id', academicSessionId);

      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      } else {
        query = query.is_('subject_id', null);
      }

      final response = await query.limit(1);

      if (response.isEmpty) return null;

      return ClassPerformanceModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get class performance failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get class performance unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get class performance: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ClassPerformanceModel>> getSchoolClassPerformances(
    String schoolId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_classPerformanceTable)
          .select()
          .eq('school_id', schoolId)
          .eq('academic_session_id', academicSessionId)
          .order('average_score', ascending: false);

      return response
          .map<ClassPerformanceModel>(
            (json) => ClassPerformanceModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get school class performances failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get school class performances unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get school class performances: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolPerformanceModel> upsertSchoolPerformance(
    SchoolPerformanceModel performance,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_schoolPerformanceTable)
          .upsert(
            performance.toJson(),
            onConflict: 'school_id,academic_session_id',
          )
          .select()
          .single();

      return SchoolPerformanceModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert school performance failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Upsert school performance unexpected error', error: e);
      throw ServerException(
        message: 'Failed to upsert school performance: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolPerformanceModel?> getSchoolPerformance(
    String schoolId,
    String academicSessionId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_schoolPerformanceTable)
          .select()
          .eq('school_id', schoolId)
          .eq('academic_session_id', academicSessionId)
          .limit(1);

      if (response.isEmpty) return null;

      return SchoolPerformanceModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get school performance failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get school performance unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get school performance: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Analytics Snapshots
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AnalyticsSnapshotModel> createAnalyticsSnapshot(
    AnalyticsSnapshotModel snapshot,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_analyticsSnapshotsTable)
          .insert(snapshot.toJson())
          .select()
          .single();

      return AnalyticsSnapshotModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create analytics snapshot failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create analytics snapshot unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create analytics snapshot: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AnalyticsSnapshotModel?> getAnalyticsSnapshot(
    String schoolId,
    String snapshotType, {
    String? entityId,
    String? academicSessionId,
  }) async {
    try {
      var query = _supabaseClient
          .from(_analyticsSnapshotsTable)
          .select()
          .eq('school_id', schoolId)
          .eq('snapshot_type', snapshotType);

      if (entityId != null) {
        query = query.eq('entity_id', entityId);
      }
      if (academicSessionId != null) {
        query = query.eq('academic_session_id', academicSessionId);
      }

      query = query.order('computed_at', ascending: false).limit(1);

      final response = await query;

      if (response.isEmpty) return null;

      return AnalyticsSnapshotModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get analytics snapshot failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get analytics snapshot unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get analytics snapshot: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dashboard Configuration
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DashboardConfigurationModel> upsertDashboardConfiguration(
    DashboardConfigurationModel config,
  ) async {
    try {
      // 1. Upsert the dashboard configuration row (without nested widgets)
      final configJson = config.toJson()
        ..remove('widgets');

      final response = await _supabaseClient
          .from(_dashboardConfigurationsTable)
          .upsert(
            configJson,
            onConflict: 'school_id,role',
          )
          .select()
          .single();

      final savedConfig = DashboardConfigurationModel.fromJson(response);

      // 2. Delete existing widget configs and re-insert
      await _supabaseClient
          .from(_dashboardWidgetConfigsTable)
          .delete()
          .eq('dashboard_id', savedConfig.id);

      if (config.widgets.isNotEmpty) {
        final widgetRows = config.widgets.map((w) {
          final json = w.toJson();
          json['dashboard_id'] = savedConfig.id;
          return json;
        }).toList();

        await _supabaseClient
            .from(_dashboardWidgetConfigsTable)
            .insert(widgetRows);
      }

      // 3. Return config with widgets populated
      return savedConfig.copyWith(
        widgets: config.widgets,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Upsert dashboard configuration failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Upsert dashboard configuration unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to upsert dashboard configuration: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DashboardConfigurationModel?> getDashboardConfiguration(
    String schoolId,
    String role,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_dashboardConfigurationsTable)
          .select('*, dashboard_widget_configs(*)')
          .eq('school_id', schoolId)
          .eq('role', role)
          .limit(1);

      if (response.isEmpty) return null;

      final mappedJson = _mapDashboardWidgets(
        response.first as Map<String, dynamic>,
      );

      return DashboardConfigurationModel.fromJson(mappedJson);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get dashboard configuration failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        'Get dashboard configuration unexpected error',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get dashboard configuration: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> updateDashboardWidgets(
    String dashboardId,
    List<DashboardWidgetConfigModel> widgets,
  ) async {
    try {
      // 1. Delete existing widget configs
      await _supabaseClient
          .from(_dashboardWidgetConfigsTable)
          .delete()
          .eq('dashboard_id', dashboardId);

      // 2. Insert new widget configs
      if (widgets.isNotEmpty) {
        final widgetRows = widgets.map((w) {
          final json = w.toJson();
          json['dashboard_id'] = dashboardId;
          return json;
        }).toList();

        await _supabaseClient
            .from(_dashboardWidgetConfigsTable)
            .insert(widgetRows);
      }
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update dashboard widgets failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update dashboard widgets unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update dashboard widgets: $e',
        statusCode: 500,
      );
    }
  }

  /// Maps the nested `dashboard_widget_configs` join result to the
  /// model's expected `widgets` key.
  Map<String, dynamic> _mapDashboardWidgets(Map<String, dynamic> json) {
    final widgets = json['dashboard_widget_configs'];
    if (widgets is List) {
      return {
        ...json,
        'widgets': widgets,
      };
    }
    return json;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Report Exports
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ReportExportModel> createReportExport(
    ReportExportModel export,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_reportExportsTable)
          .insert(export.toJson())
          .select()
          .single();

      return ReportExportModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create report export failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create report export unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create report export: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ReportExportModel> updateReportExport(
    ReportExportModel export,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_reportExportsTable)
          .update(export.toJson())
          .eq('id', export.id)
          .select()
          .single();

      return ReportExportModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update report export failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Report export not found: ${export.id}');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update report export unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update report export: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ReportExportModel?> getReportExport(String exportId) async {
    try {
      final response = await _supabaseClient
          .from(_reportExportsTable)
          .select()
          .eq('id', exportId)
          .single();

      return ReportExportModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null;
      AppLogger.error('Get report export failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get report export unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get report export: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ReportExportModel>> getReportExports({
    String? schoolId,
    String? requestedBy,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient.from(_reportExportsTable).select();

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (requestedBy != null) {
        query = query.eq('requested_by', requestedBy);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<ReportExportModel>(
            (json) => ReportExportModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get report exports failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get report exports unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get report exports: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Result Locks
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ResultLockModel> createResultLock(ResultLockModel lock) async {
    try {
      final response = await _supabaseClient
          .from(_resultLocksTable)
          .insert(lock.toJson())
          .select()
          .single();

      return ResultLockModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create result lock failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create result lock unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create result lock: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ResultLockModel> updateResultLock(ResultLockModel lock) async {
    try {
      final response = await _supabaseClient
          .from(_resultLocksTable)
          .update(lock.toJson())
          .eq('id', lock.id)
          .select()
          .single();

      return ResultLockModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update result lock failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Result lock not found: ${lock.id}');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update result lock unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update result lock: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ResultLockModel?> getResultLock(String examId) async {
    try {
      final response = await _supabaseClient
          .from(_resultLocksTable)
          .select()
          .eq('exam_id', examId)
          .limit(1);

      if (response.isEmpty) return null;

      return ResultLockModel.fromJson(
        response.first as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get result lock failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get result lock unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get result lock: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Result Access Log
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> insertResultAccessLog({
    required String schoolId,
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _supabaseClient.from(_resultAccessLogTable).insert({
        'school_id': schoolId,
        'user_id': userId,
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'details': details,
        'accessed_at': DateTime.now().toIso8601String(),
      });
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Insert result access log failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Insert result access log unexpected error', error: e);
      throw ServerException(
        message: 'Failed to insert result access log: $e',
        statusCode: 500,
      );
    }
  }
}
