import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../datasources/parent_portal_remote_datasource.dart';
import '../models/parent_portal_models.dart';

class ParentPortalRepositoryImpl implements ParentPortalRepository {
  ParentPortalRepositoryImpl({
    required ParentPortalRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ParentPortalRemoteDataSource _remoteDataSource;

  /// Helper: Convert exceptions to Failures
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
      AppLogger.error(
        'Unexpected exception in ParentPortalRepositoryImpl',
        error: e,
      );
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ParentDashboardEntity>> getParentDashboard() async {
    try {
      final model = await _remoteDataSource.getDashboard();
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD PROFILE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ChildProfileEntity>> getChildProfile(String studentId) async {
    try {
      final data = await _remoteDataSource.getChildProfile(studentId);
      final entity = ChildProfileEntity(
        studentId: data['id'] as String? ?? '',
        firstName: data['first_name'] as String? ?? '',
        lastName: data['last_name'] as String? ?? '',
        admissionNumber: data['admission_number'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        className: (data['class'] as Map<String, dynamic>?)?['name'] as String?,
        relationship: (data['parent_students'] as Map<String, dynamic>?)?['relationship'] as String? ?? '',
        isPrimaryContact: (data['parent_students'] as Map<String, dynamic>?)?['is_primary_contact'] as bool? ?? false,
      );
      return Success(entity);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACADEMIC PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ChildPerformanceEntity>> getChildPerformance({
    required String studentId,
    String? academicSessionId,
  }) async {
    try {
      final model = await _remoteDataSource.getChildPerformance(
        studentId,
        academicSessionId,
      );
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ChildAttendanceEntity>> getChildAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _remoteDataSource.getChildAttendance(
        studentId,
        startDate,
        endDate,
      );
      final records = (data['records'] as List<dynamic>?)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final entity = ChildAttendanceEntity(
        studentId: studentId,
        records: records,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(entity);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ChildAssignmentEntity>>> getChildAssignments({
    required String studentId,
    String? status,
  }) async {
    try {
      final data = await _remoteDataSource.getChildAssignments(
        studentId,
        status,
      );
      final entities = data.map((item) {
        final assignment = item['assignments'] as Map<String, dynamic>? ?? {};
        return ChildAssignmentEntity(
          id: item['id'] as String? ?? '',
          assignmentId: item['assignment_id'] as String? ?? '',
          studentId: item['student_id'] as String? ?? '',
          status: item['status'] as String? ?? 'pending',
          submittedAt: item['submitted_at'] != null
              ? DateTime.parse(item['submitted_at'] as String)
              : null,
          score: (item['score'] as num?)?.toDouble(),
          title: assignment['title'] as String? ?? '',
          description: assignment['description'] as String?,
          dueDate: assignment['due_date'] != null
              ? DateTime.parse(assignment['due_date'] as String)
              : null,
          subjectName: (assignment['subjects'] as Map<String, dynamic>?)?['name'] as String?,
        );
      }).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ParentMessageEntity>> sendMessage(
    Map<String, dynamic> params,
  ) async {
    try {
      final model = ParentMessageModel.fromJson(params);
      final created = await _remoteDataSource.sendMessage(model.toJson());
      return Success(created.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ParentMessageEntity>>> getMessages(
    Map<String, dynamic> params,
  ) async {
    try {
      final models = await _remoteDataSource.getMessages(params);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ParentMessageThreadEntity>>> getMessageThreads({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final data = await _remoteDataSource.getMessageThreads(page, perPage);
      final entities = data.map((item) {
        final lastMessageRaw = item['last_message'] as Map<String, dynamic>?;
        final lastMessage = lastMessageRaw != null
            ? ParentMessageModel.fromJson(lastMessageRaw).toEntity()
            : null;
        return ParentMessageThreadEntity(
          threadId: item['thread_id'] as String? ?? '',
          otherUserId: item['other_user_id'] as String? ?? '',
          otherUserName: item['other_user_name'] as String? ?? '',
          otherUserRole: item['other_user_role'] as String? ?? '',
          lastMessage: lastMessage,
          unreadCount: item['unread_count'] as int? ?? 0,
          studentId: item['student_id'] as String?,
          studentName: item['student_name'] as String?,
        );
      }).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markMessageRead(String messageId) async {
    try {
      await _remoteDataSource.markMessageRead(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ParentNotificationEntity>>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (category != null) params['category'] = category;
      if (isRead != null) params['is_read'] = isRead;

      final models = await _remoteDataSource.getNotifications(params);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markNotificationRead(String notificationId) async {
    try {
      await _remoteDataSource.markNotificationRead(notificationId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAllNotificationsRead() async {
    try {
      await _remoteDataSource.markAllNotificationsRead();
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ParentCalendarEventEntity>>> getCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? studentId,
  }) async {
    try {
      final params = <String, dynamic>{
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
      if (studentId != null) params['student_id'] = studentId;

      final models = await _remoteDataSource.getCalendarEvents(params);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI PARENT ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ParentAssistantResponseEntity>> askAssistant(
    Map<String, dynamic> params,
  ) async {
    try {
      final data = await _remoteDataSource.askAssistant(params);
      final entity = ParentAssistantResponseEntity(
        answer: data['answer'] as String? ?? '',
        sources: (data['sources'] as List<dynamic>?)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        studentId: data['student_id'] as String?,
        followUpQuestions: (data['follow_up_questions'] as List<dynamic>?)
                .cast<String>() ??
            [],
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      );
      return Success(entity);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ParentAiInsightEntity>>> getInsights({
    String? studentId,
    bool? isRead,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (studentId != null) params['student_id'] = studentId;
      if (isRead != null) params['is_read'] = isRead;

      final models = await _remoteDataSource.getInsights(params);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> dismissInsight(String insightId) async {
    try {
      await _remoteDataSource.dismissInsight(insightId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markInsightRead(String insightId) async {
    try {
      await _remoteDataSource.markInsightRead(insightId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTS & DOWNLOADS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ParentReportDownloadEntity>> downloadReport(
    Map<String, dynamic> params,
  ) async {
    try {
      final model = await _remoteDataSource.downloadReport(params);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ParentReportDownloadEntity>>> getDownloadHistory(
    String studentId,
  ) async {
    try {
      final models = await _remoteDataSource.getDownloadHistory(studentId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGAGEMENT TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> recordEngagement(Map<String, dynamic> params) async {
    try {
      await _remoteDataSource.recordEngagement(params);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGAGEMENT ANALYTICS (ADMIN)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<EngagementAnalyticsEntity>> getEngagementAnalytics(
    String schoolId,
  ) async {
    try {
      final data = await _remoteDataSource.getEngagementAnalytics(schoolId);
      final entity = EngagementAnalyticsEntity(
        schoolId: data['school_id'] as String? ?? schoolId,
        totalParents: data['total_parents'] as int? ?? 0,
        activeParents: data['active_parents'] as int? ?? 0,
        moderateParents: data['moderate_parents'] as int? ?? 0,
        inactiveParents: data['inactive_parents'] as int? ?? 0,
        reportCardNotViewed: data['report_card_not_viewed'] as int? ?? 0,
        avgMessageResponseHours:
            (data['avg_message_response_hours'] as num?)?.toDouble(),
        unreadAnnouncementCount: data['unread_announcement_count'] as int?,
        engagementByMetric:
            (data['engagement_by_metric'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
                {},
        studentsNeedingSupport: (data['students_needing_support']
                    as List<dynamic>?)
                ?.map((e) {
              final map = e as Map<String, dynamic>;
              return StudentSupportEntity(
                studentId: map['student_id'] as String? ?? '',
                studentName: map['student_name'] as String? ?? '',
                parentName: map['parent_name'] as String?,
                engagementLevel: map['engagement_level'] as String?,
                lastActive: map['last_active'] != null
                    ? DateTime.parse(map['last_active'] as String)
                    : null,
              );
            }).toList() ??
            [],
        engagementTrends: (data['engagement_trends'] as List<dynamic>?)
                ?.map((e) {
              final map = e as Map<String, dynamic>;
              return EngagementTrendEntity(
                date: map['date'] != null
                    ? DateTime.parse(map['date'] as String)
                    : DateTime.now(),
                interactions: map['interactions'] as int? ?? 0,
              );
            }).toList() ??
            [],
      );
      return Success(entity);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
