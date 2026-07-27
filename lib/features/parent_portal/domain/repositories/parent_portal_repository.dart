import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';

/// Abstract contract for all Parent Portal operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class ParentPortalRepository {
  // ─── Dashboard ──────────────────────────────────────────────────────

  /// Retrieves the aggregated dashboard summary for the current parent.
  Future<Result<ParentDashboardEntity>> getParentDashboard();

  // ─── Child Profile ──────────────────────────────────────────────────

  /// Retrieves the profile details for a specific child identified by
  /// [studentId].
  Future<Result<ChildProfileEntity>> getChildProfile(String studentId);

  // ─── Academic Performance ───────────────────────────────────────────

  /// Retrieves academic performance data for a specific child, optionally
  /// scoped to an [academicSessionId].
  Future<Result<ChildPerformanceEntity>> getChildPerformance({
    required String studentId,
    String? academicSessionId,
  });

  // ─── Attendance ─────────────────────────────────────────────────────

  /// Retrieves attendance records for a specific child within an optional
  /// date range defined by [startDate] and [endDate].
  Future<Result<ChildAttendanceEntity>> getChildAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // ─── Assignments ────────────────────────────────────────────────────

  /// Retrieves a list of assignments for a specific child, optionally
  /// filtered by [status].
  Future<Result<List<ChildAssignmentEntity>>> getChildAssignments({
    required String studentId,
    String? status,
  });

  // ─── Messages ───────────────────────────────────────────────────────

  /// Sends a message using the provided [params] map.
  Future<Result<ParentMessageEntity>> sendMessage(Map<String, dynamic> params);

  /// Retrieves a list of messages matching the given [params].
  Future<Result<List<ParentMessageEntity>>> getMessages(
    Map<String, dynamic> params,
  );

  /// Retrieves paginated message threads for the current parent.
  Future<Result<List<ParentMessageThreadEntity>>> getMessageThreads({
    int page = 1,
    int perPage = 20,
  });

  /// Marks a specific message as read by [messageId].
  Future<Result<void>> markMessageRead(String messageId);

  // ─── Notifications ──────────────────────────────────────────────────

  /// Retrieves paginated notifications, optionally filtered by [category]
  /// and/or [isRead] status.
  Future<Result<List<ParentNotificationEntity>>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  });

  /// Marks a specific notification as read by [notificationId].
  Future<Result<void>> markNotificationRead(String notificationId);

  /// Marks all notifications as read for the current parent.
  Future<Result<void>> markAllNotificationsRead();

  // ─── Calendar ───────────────────────────────────────────────────────

  /// Retrieves calendar events within the specified date range,
  /// optionally scoped to a specific [studentId].
  Future<Result<List<ParentCalendarEventEntity>>> getCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? studentId,
  });

  // ─── AI Parent Assistant ────────────────────────────────────────────

  /// Sends a query to the AI parent assistant and returns the response
  /// based on the provided [params].
  Future<Result<ParentAssistantResponseEntity>> askAssistant(
    Map<String, dynamic> params,
  );

  // ─── AI Insights ────────────────────────────────────────────────────

  /// Retrieves AI-generated insights, optionally filtered by [studentId]
  /// and/or [isRead] status.
  Future<Result<List<ParentAiInsightEntity>>> getInsights({
    String? studentId,
    bool? isRead,
  });

  /// Dismisses an AI insight so it no longer appears in the feed.
  Future<Result<void>> dismissInsight(String insightId);

  /// Marks an AI insight as read by [insightId].
  Future<Result<void>> markInsightRead(String insightId);

  // ─── Reports & Downloads ────────────────────────────────────────────

  /// Downloads a report based on the provided [params] and returns the
  /// download entity with the file URL and metadata.
  Future<Result<ParentReportDownloadEntity>> downloadReport(
    Map<String, dynamic> params,
  );

  /// Retrieves the download history for a specific [studentId].
  Future<Result<List<ParentReportDownloadEntity>>> getDownloadHistory(
    String studentId,
  );

  // ─── Engagement Tracking ────────────────────────────────────────────

  /// Records a parent engagement event using the provided [params].
  Future<Result<void>> recordEngagement(Map<String, dynamic> params);

  // ─── Engagement Analytics (Admin) ───────────────────────────────────

  /// Retrieves engagement analytics aggregated for a specific [schoolId].
  Future<Result<EngagementAnalyticsEntity>> getEngagementAnalytics(
    String schoolId,
  );
}
