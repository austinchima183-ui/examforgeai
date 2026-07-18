import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/parent_portal_models.dart';

abstract class ParentPortalRemoteDataSource {
  // ── Dashboard ──────────────────────────────────────────────────────────
  Future<ParentDashboardModel> getDashboard();

  // ── Child Profile ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getChildProfile(String studentId);

  // ── Child Performance ──────────────────────────────────────────────────
  Future<ChildPerformanceModel> getChildPerformance(
    String studentId,
    String? academicSessionId,
  );

  // ── Child Attendance ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getChildAttendance(
    String studentId,
    DateTime? startDate,
    DateTime? endDate,
  );

  // ── Child Assignments ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getChildAssignments(
    String studentId,
    String? status,
  );

  // ── Messages ───────────────────────────────────────────────────────────
  Future<ParentMessageModel> sendMessage(Map<String, dynamic> data);
  Future<List<ParentMessageModel>> getMessages(Map<String, dynamic> params);
  Future<List<Map<String, dynamic>>> getMessageThreads(int page, int perPage);
  Future<void> markMessageRead(String messageId);

  // ── Notifications ──────────────────────────────────────────────────────
  Future<List<ParentNotificationModel>> getNotifications(
    Map<String, dynamic> params,
  );
  Future<void> markNotificationRead(String notificationId);
  Future<void> markAllNotificationsRead();

  // ── Calendar ───────────────────────────────────────────────────────────
  Future<List<ParentCalendarEventModel>> getCalendarEvents(
    Map<String, dynamic> params,
  );

  // ── AI Assistant ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> askAssistant(Map<String, dynamic> params);

  // ── AI Insights ────────────────────────────────────────────────────────
  Future<List<ParentAiInsightModel>> getInsights(Map<String, dynamic> params);
  Future<void> dismissInsight(String insightId);
  Future<void> markInsightRead(String insightId);

  // ── Reports & Downloads ────────────────────────────────────────────────
  Future<ParentReportDownloadModel> downloadReport(Map<String, dynamic> params);
  Future<List<ParentReportDownloadModel>> getDownloadHistory(String studentId);

  // ── Engagement Tracking ────────────────────────────────────────────────
  Future<void> recordEngagement(Map<String, dynamic> params);
  Future<Map<String, dynamic>> getEngagementAnalytics(String schoolId);
}

class ParentPortalRemoteDataSourceImpl
    implements ParentPortalRemoteDataSource {
  ParentPortalRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _messagesTable = 'parent_messages';
  static const _notificationsTable = 'parent_notifications';
  static const _activityLogsTable = 'parent_activity_logs';
  static const _insightsTable = 'parent_ai_insights';
  static const _downloadsTable = 'parent_report_downloads';
  static const _calendarEventsTable = 'parent_calendar_events';
  static const _engagementMetricsTable = 'parent_engagement_metrics';

  // ── Exception mapping helper ───────────────────────────────────────────
  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(message: e.message);
      case '23505':
        throw ServerException(
          message: 'A record with this data already exists.',
          statusCode: 409,
        );
      case '23503':
        throw ServerException(
          message: 'Referenced record not found.',
          statusCode: 404,
        );
      case '42501':
        throw ForbiddenException(
          message: 'You do not have permission for this action.',
        );
      default:
        throw ServerException(
          message: e.message,
          statusCode: e.statusCode ?? 500,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ParentDashboardModel> getDashboard() async {
    try {
      AppLogger.info('Fetching parent dashboard');
      final response = await _supabase.rpc(
        'get_parent_dashboard',
        params: {'p_parent_user_id': _supabase.auth.currentUser?.id},
      );
      AppLogger.info('Parent dashboard fetched successfully');
      return ParentDashboardModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch parent dashboard', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD PROFILE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getChildProfile(String studentId) async {
    try {
      AppLogger.info('Fetching child profile for student: $studentId');
      final response = await _supabase
          .from('students')
          .select('''
            id,
            first_name,
            last_name,
            admission_number,
            avatar_url,
            class:class_id(id, name),
            parent_students!inner(relationship, is_primary_contact)
          ''')
          .eq('id', studentId)
          .eq(
            'parent_students.parent_user_id',
            _supabase.auth.currentUser?.id ?? '',
          )
          .single();
      AppLogger.info('Child profile fetched successfully');
      return response;
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(
          message: 'Child profile not found for student: $studentId',
        );
      }
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch child profile for student: $studentId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ChildPerformanceModel> getChildPerformance(
    String studentId,
    String? academicSessionId,
  ) async {
    try {
      AppLogger.info(
        'Fetching child performance for student: $studentId'
        '${academicSessionId != null ? ', session: $academicSessionId' : ''}',
      );
      final rpcParams = <String, dynamic>{'p_student_id': studentId};
      if (academicSessionId != null) {
        rpcParams['p_academic_session_id'] = academicSessionId;
      }
      final response = await _supabase.rpc(
        'get_child_performance',
        params: rpcParams,
      );
      AppLogger.info('Child performance fetched successfully');
      return ChildPerformanceModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch child performance for student: $studentId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getChildAttendance(
    String studentId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      AppLogger.info('Fetching child attendance for student: $studentId');
      var query = _supabase
          .from('attendance_records')
          .select('''
            id,
            student_id,
            date,
            status,
            check_in_time,
            check_out_time,
            remarks
          ''')
          .eq('student_id', studentId)
          .order('date', ascending: false);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T').first);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T').first);
      }

      final response = await query;
      AppLogger.info('Child attendance fetched successfully');
      return {
        'student_id': studentId,
        'records': response,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch child attendance for student: $studentId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getChildAssignments(
    String studentId,
    String? status,
  ) async {
    try {
      AppLogger.info('Fetching child assignments for student: $studentId');
      var query = _supabase
          .from('student_assignments')
          .select('''
            id,
            assignment_id,
            student_id,
            status,
            submitted_at,
            score,
            assignments(
              id,
              title,
              description,
              due_date,
              subject_id,
              subjects(name)
            )
          ''')
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      AppLogger.info(
        'Child assignments fetched: ${response.length} records',
      );
      return response.cast<Map<String, dynamic>>();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch child assignments for student: $studentId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ParentMessageModel> sendMessage(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Sending parent message');
      final response = await _supabase
          .from(_messagesTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Parent message sent successfully');
      return ParentMessageModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to send parent message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<ParentMessageModel>> getMessages(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Fetching parent messages with params: $params');
      var query = _supabase
          .from(_messagesTable)
          .select()
          .order('created_at', ascending: false);

      // Apply filters from params
      if (params.containsKey('thread_id')) {
        query = query.eq('thread_id', params['thread_id'] as String);
      }
      if (params.containsKey('student_id')) {
        query = query.eq('student_id', params['student_id'] as String);
      }
      if (params.containsKey('direction')) {
        query = query.eq('direction', params['direction'] as String);
      }
      if (params.containsKey('is_archived')) {
        query = query.eq('is_archived', params['is_archived'] as bool);
      }
      if (params.containsKey('page') && params.containsKey('per_page')) {
        final page = params['page'] as int;
        final perPage = params['per_page'] as int;
        query = query.range((page - 1) * perPage, page * perPage - 1);
      }

      final response = await query;
      AppLogger.info('Parent messages fetched: ${response.length} records');
      return response
          .map((e) => ParentMessageModel.fromJson(e))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch parent messages', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMessageThreads(
    int page,
    int perPage,
  ) async {
    try {
      AppLogger.info(
        'Fetching message threads: page=$page, perPage=$perPage',
      );
      final response = await _supabase.rpc(
        'get_parent_message_threads',
        params: {
          'p_parent_user_id': _supabase.auth.currentUser?.id,
          'p_page': page,
          'p_per_page': perPage,
        },
      );
      AppLogger.info('Message threads fetched successfully');
      return (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch message threads', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markMessageRead(String messageId) async {
    try {
      AppLogger.info('Marking message as read: $messageId');
      await _supabase
          .from(_messagesTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
      AppLogger.info('Message marked as read successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to mark message as read: $messageId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ParentNotificationModel>> getNotifications(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Fetching parent notifications with params: $params');
      final parentId = _supabase.auth.currentUser?.id ?? '';
      var query = _supabase
          .from(_notificationsTable)
          .select()
          .eq('parent_id', parentId)
          .order('created_at', ascending: false);

      // Apply filters from params
      if (params.containsKey('category')) {
        query = query.eq('category', params['category'] as String);
      }
      if (params.containsKey('is_read')) {
        query = query.eq('is_read', params['is_read'] as bool);
      }
      if (params.containsKey('page') && params.containsKey('per_page')) {
        final page = params['page'] as int;
        final perPage = params['per_page'] as int;
        query = query.range((page - 1) * perPage, page * perPage - 1);
      }

      final response = await query;
      AppLogger.info(
        'Parent notifications fetched: ${response.length} records',
      );
      return response
          .map((e) => ParentNotificationModel.fromJson(e))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch parent notifications', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      AppLogger.info('Marking notification as read: $notificationId');
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      AppLogger.info('Notification marked as read successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to mark notification as read: $notificationId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    try {
      AppLogger.info('Marking all notifications as read');
      final parentId = _supabase.auth.currentUser?.id ?? '';
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('parent_id', parentId)
          .eq('is_read', false);
      AppLogger.info('All notifications marked as read successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ParentCalendarEventModel>> getCalendarEvents(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Fetching parent calendar events with params: $params');
      var query = _supabase
          .from(_calendarEventsTable)
          .select()
          .order('start_time', ascending: true);

      // Apply filters from params
      if (params.containsKey('start_date')) {
        final startDate = params['start_date'] as String;
        query = query.gte('start_time', startDate);
      }
      if (params.containsKey('end_date')) {
        final endDate = params['end_date'] as String;
        query = query.lte('end_time', endDate);
      }
      if (params.containsKey('student_id')) {
        query = query.eq('student_id', params['student_id'] as String);
      }
      if (params.containsKey('event_type')) {
        query = query.eq('event_type', params['event_type'] as String);
      }

      final response = await query;
      AppLogger.info(
        'Parent calendar events fetched: ${response.length} records',
      );
      return response
          .map((e) => ParentCalendarEventModel.fromJson(e))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch parent calendar events', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> askAssistant(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Asking parent AI assistant');
      final response = await _supabase.rpc(
        'ask_parent_assistant',
        params: {
          'p_parent_user_id': _supabase.auth.currentUser?.id,
          'p_question': params['question'],
          'p_student_id': params['student_id'],
          'p_context': params['context'],
        },
      );
      AppLogger.info('Parent AI assistant response received');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to ask parent AI assistant', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ParentAiInsightModel>> getInsights(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Fetching parent AI insights with params: $params');
      final parentId = _supabase.auth.currentUser?.id ?? '';
      var query = _supabase
          .from(_insightsTable)
          .select()
          .eq('parent_id', parentId)
          .order('created_at', ascending: false);

      // Apply filters from params
      if (params.containsKey('student_id')) {
        query = query.eq('student_id', params['student_id'] as String);
      }
      if (params.containsKey('is_read')) {
        query = query.eq('is_read', params['is_read'] as bool);
      }
      if (params.containsKey('is_dismissed')) {
        query = query.eq('is_dismissed', params['is_dismissed'] as bool);
      } else {
        // Default: exclude dismissed insights
        query = query.eq('is_dismissed', false);
      }
      if (params.containsKey('insight_type')) {
        query = query.eq('insight_type', params['insight_type'] as String);
      }
      if (params.containsKey('severity')) {
        query = query.eq('severity', params['severity'] as String);
      }

      final response = await query;
      AppLogger.info(
        'Parent AI insights fetched: ${response.length} records',
      );
      return response
          .map((e) => ParentAiInsightModel.fromJson(e))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch parent AI insights', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> dismissInsight(String insightId) async {
    try {
      AppLogger.info('Dismissing AI insight: $insightId');
      await _supabase
          .from(_insightsTable)
          .update({'is_dismissed': true})
          .eq('id', insightId);
      AppLogger.info('AI insight dismissed successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to dismiss AI insight: $insightId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markInsightRead(String insightId) async {
    try {
      AppLogger.info('Marking AI insight as read: $insightId');
      await _supabase
          .from(_insightsTable)
          .update({
            'is_read': true,
          })
          .eq('id', insightId);
      AppLogger.info('AI insight marked as read successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to mark AI insight as read: $insightId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTS & DOWNLOADS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ParentReportDownloadModel> downloadReport(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Downloading report with params: $params');
      final data = {
        'parent_id': _supabase.auth.currentUser?.id,
        'student_id': params['student_id'],
        'report_type': params['report_type'],
        'report_id': params['report_id'],
        'format': params['format'] ?? 'pdf',
        'file_url': params['file_url'],
        'file_name': params['file_name'],
        'file_size_bytes': params['file_size_bytes'],
        'school_id': params['school_id'],
        'downloaded_at': DateTime.now().toIso8601String(),
      };
      final response = await _supabase
          .from(_downloadsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Report download recorded successfully');
      return ParentReportDownloadModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to download report', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<ParentReportDownloadModel>> getDownloadHistory(
    String studentId,
  ) async {
    try {
      AppLogger.info(
        'Fetching download history for student: $studentId',
      );
      final parentId = _supabase.auth.currentUser?.id ?? '';
      final response = await _supabase
          .from(_downloadsTable)
          .select()
          .eq('parent_id', parentId)
          .eq('student_id', studentId)
          .order('downloaded_at', ascending: false);
      AppLogger.info(
        'Download history fetched: ${response.length} records',
      );
      return response
          .map((e) => ParentReportDownloadModel.fromJson(e))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch download history for student: $studentId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGAGEMENT TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<void> recordEngagement(Map<String, dynamic> params) async {
    try {
      AppLogger.info('Recording parent engagement event');
      final data = {
        'parent_id': _supabase.auth.currentUser?.id,
        'school_id': params['school_id'],
        'student_id': params['student_id'],
        'metric_type': params['metric_type'],
        'metric_value': params['metric_value'] ?? 1.0,
        'details': params['details'] ?? {},
        'recorded_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from(_engagementMetricsTable).insert(data);
      AppLogger.info('Parent engagement event recorded successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to record parent engagement event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGAGEMENT ANALYTICS (ADMIN)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getEngagementAnalytics(String schoolId) async {
    try {
      AppLogger.info(
        'Fetching engagement analytics for school: $schoolId',
      );
      final response = await _supabase.rpc(
        'get_parent_engagement_analytics',
        params: {'p_school_id': schoolId},
      );
      AppLogger.info('Engagement analytics fetched successfully');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch engagement analytics for school: $schoolId',
        error: e,
      );
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }
}
