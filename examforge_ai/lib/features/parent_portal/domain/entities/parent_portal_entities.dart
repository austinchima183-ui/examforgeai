import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the direction of a message in the parent messaging system.
enum MessageDirection {
  incoming(
    value: 'incoming',
    label: 'Incoming',
  ),
  outgoing(
    value: 'outgoing',
    label: 'Outgoing',
  );

  const MessageDirection({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [MessageDirection].
  ///
  /// Returns `null` if the value does not match any known direction.
  static MessageDirection? fromString(String? value) {
    if (value == null) return null;
    return MessageDirection.values.cast<MessageDirection?>().firstWhere(
          (direction) => direction?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the delivery status of a message.
enum MessageStatus {
  sent(
    value: 'sent',
    label: 'Sent',
  ),
  delivered(
    value: 'delivered',
    label: 'Delivered',
  ),
  read(
    value: 'read',
    label: 'Read',
  ),
  failed(
    value: 'failed',
    label: 'Failed',
  );

  const MessageStatus({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [MessageStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static MessageStatus? fromString(String? value) {
    if (value == null) return null;
    return MessageStatus.values.cast<MessageStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of AI-generated insight presented to a parent.
enum ParentInsightType {
  performanceTrend(
    value: 'performance_trend',
    label: 'Performance Trend',
  ),
  attendanceAlert(
    value: 'attendance_alert',
    label: 'Attendance Alert',
  ),
  studyRecommendation(
    value: 'study_recommendation',
    label: 'Study Recommendation',
  ),
  engagementTip(
    value: 'engagement_tip',
    label: 'Engagement Tip',
  ),
  milestone(
    value: 'milestone',
    label: 'Milestone',
  ),
  concern(
    value: 'concern',
    label: 'Concern',
  );

  const ParentInsightType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [ParentInsightType].
  ///
  /// Returns `null` if the value does not match any known insight type.
  static ParentInsightType? fromString(String? value) {
    if (value == null) return null;
    return ParentInsightType.values.cast<ParentInsightType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of engagement metric tracked for a parent.
enum EngagementMetricType {
  reportCardViewed(
    value: 'report_card_viewed',
    label: 'Report Card Viewed',
  ),
  announcementRead(
    value: 'announcement_read',
    label: 'Announcement Read',
  ),
  messageSent(
    value: 'message_sent',
    label: 'Message Sent',
  ),
  meetingAttended(
    value: 'meeting_attended',
    label: 'Meeting Attended',
  ),
  assignmentChecked(
    value: 'assignment_checked',
    label: 'Assignment Checked',
  ),
  attendanceChecked(
    value: 'attendance_checked',
    label: 'Attendance Checked',
  ),
  calendarViewed(
    value: 'calendar_viewed',
    label: 'Calendar Viewed',
  ),
  aiAssistantUsed(
    value: 'ai_assistant_used',
    label: 'AI Assistant Used',
  );

  const EngagementMetricType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [EngagementMetricType].
  ///
  /// Returns `null` if the value does not match any known metric type.
  static EngagementMetricType? fromString(String? value) {
    if (value == null) return null;
    return EngagementMetricType.values.cast<EngagementMetricType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the severity level of an AI insight.
enum InsightSeverity {
  info(
    value: 'info',
    label: 'Info',
  ),
  warning(
    value: 'warning',
    label: 'Warning',
  ),
  concern(
    value: 'concern',
    label: 'Concern',
  ),
  positive(
    value: 'positive',
    label: 'Positive',
  );

  const InsightSeverity({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [InsightSeverity].
  ///
  /// Returns `null` if the value does not match any known severity.
  static InsightSeverity? fromString(String? value) {
    if (value == null) return null;
    return InsightSeverity.values.cast<InsightSeverity?>().firstWhere(
          (severity) => severity?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a calendar event visible to parents.
enum CalendarEventType {
  school(
    value: 'school',
    label: 'School',
  ),
  holiday(
    value: 'holiday',
    label: 'Holiday',
  ),
  meeting(
    value: 'meeting',
    label: 'Meeting',
  ),
  exam(
    value: 'exam',
    label: 'Exam',
  ),
  event(
    value: 'event',
    label: 'Event',
  ),
  deadline(
    value: 'deadline',
    label: 'Deadline',
  );

  const CalendarEventType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [CalendarEventType].
  ///
  /// Returns `null` if the value does not match any known event type.
  static CalendarEventType? fromString(String? value) {
    if (value == null) return null;
    return CalendarEventType.values.cast<CalendarEventType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the category of a notification delivered to a parent.
enum NotificationCategory {
  result(
    value: 'result',
    label: 'Result',
  ),
  attendance(
    value: 'attendance',
    label: 'Attendance',
  ),
  assignment(
    value: 'assignment',
    label: 'Assignment',
  ),
  announcement(
    value: 'announcement',
    label: 'Announcement',
  ),
  exam(
    value: 'exam',
    label: 'Exam',
  ),
  message(
    value: 'message',
    label: 'Message',
  ),
  fee(
    value: 'fee',
    label: 'Fee',
  ),
  general(
    value: 'general',
    label: 'General',
  );

  const NotificationCategory({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [NotificationCategory].
  ///
  /// Returns `null` if the value does not match any known category.
  static NotificationCategory? fromString(String? value) {
    if (value == null) return null;
    return NotificationCategory.values.cast<NotificationCategory?>().firstWhere(
          (category) => category?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of report available for download by a parent.
enum ReportType {
  reportCard(
    value: 'report_card',
    label: 'Report Card',
  ),
  attendance(
    value: 'attendance',
    label: 'Attendance',
  ),
  assignments(
    value: 'assignments',
    label: 'Assignments',
  ),
  progress(
    value: 'progress',
    label: 'Progress',
  );

  const ReportType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [ReportType].
  ///
  /// Returns `null` if the value does not match any known report type.
  static ReportType? fromString(String? value) {
    if (value == null) return null;
    return ReportType.values.cast<ReportType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents an attendance summary for a child shown on the parent dashboard.
///
/// Provides a compact breakdown of attendance days and the overall rate,
/// enabling parents to gauge their child's attendance at a glance.
class AttendanceSummaryEntity extends Equatable {
  const AttendanceSummaryEntity({
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.totalDays,
    required this.attendanceRate,
  });

  /// Number of days the student was present.
  final int presentDays;

  /// Number of days the student was absent without excuse.
  final int absentDays;

  /// Number of days the student arrived late.
  final int lateDays;

  /// Number of days the student was absent with a valid excuse.
  final int excusedDays;

  /// Total number of school days in the period.
  final int totalDays;

  /// Attendance rate as a decimal between `0.0` and `1.0`.
  final double attendanceRate;

  AttendanceSummaryEntity copyWith({
    int? presentDays,
    int? absentDays,
    int? lateDays,
    int? excusedDays,
    int? totalDays,
    double? attendanceRate,
  }) {
    return AttendanceSummaryEntity(
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      lateDays: lateDays ?? this.lateDays,
      excusedDays: excusedDays ?? this.excusedDays,
      totalDays: totalDays ?? this.totalDays,
      attendanceRate: attendanceRate ?? this.attendanceRate,
    );
  }

  @override
  List<Object?> get props => [
        presentDays,
        absentDays,
        lateDays,
        excusedDays,
        totalDays,
        attendanceRate,
      ];
}

/// Represents a single result entry for a child displayed on the parent dashboard.
///
/// Captures the exam title, score, grade, and optional subject/date context
/// so parents can quickly review academic performance.
class ChildResultEntity extends Equatable {
  const ChildResultEntity({
    required this.examTitle,
    required this.score,
    required this.totalMarks,
    required this.grade,
    this.subjectName,
    this.date,
  });

  /// Title of the exam or assessment.
  final String examTitle;

  /// Score achieved by the student.
  final double score;

  /// Maximum possible marks for the exam.
  final double totalMarks;

  /// Letter grade awarded (e.g., A, B+, C).
  final String grade;

  /// Name of the subject, if applicable.
  final String? subjectName;

  /// Date the exam was taken.
  final DateTime? date;

  ChildResultEntity copyWith({
    String? examTitle,
    double? score,
    double? totalMarks,
    String? grade,
    String? subjectName,
    DateTime? date,
  }) {
    return ChildResultEntity(
      examTitle: examTitle ?? this.examTitle,
      score: score ?? this.score,
      totalMarks: totalMarks ?? this.totalMarks,
      grade: grade ?? this.grade,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        examTitle,
        score,
        totalMarks,
        grade,
        subjectName,
        date,
      ];
}

/// Represents a summary of a child displayed on the parent dashboard.
///
/// Aggregates key information about a single child including identity,
/// attendance, pending assignments, and latest results so that parents
/// can monitor each child's status without navigating to detail pages.
class ChildSummaryEntity extends Equatable {
  const ChildSummaryEntity({
    required this.studentId,
    required this.studentName,
    this.admissionNumber,
    this.className,
    this.avatarUrl,
    required this.relationship,
    this.isPrimaryContact = false,
    required this.attendanceSummary,
    this.pendingAssignmentsCount = 0,
    this.latestResults = const [],
  });

  /// Unique identifier of the student.
  final String studentId;

  /// Display name of the student.
  final String studentName;

  /// School admission number of the student.
  final String? admissionNumber;

  /// Name of the class the student belongs to.
  final String? className;

  /// URL of the student's avatar image.
  final String? avatarUrl;

  /// Relationship of the parent to the student (e.g., "Father", "Mother").
  final String relationship;

  /// Whether this parent is the primary contact for the student.
  final bool isPrimaryContact;

  /// Attendance summary for the current period.
  final AttendanceSummaryEntity attendanceSummary;

  /// Count of assignments that are pending submission.
  final int pendingAssignmentsCount;

  /// Latest academic results for the student.
  final List<ChildResultEntity> latestResults;

  ChildSummaryEntity copyWith({
    String? studentId,
    String? studentName,
    String? admissionNumber,
    String? className,
    String? avatarUrl,
    String? relationship,
    bool? isPrimaryContact,
    AttendanceSummaryEntity? attendanceSummary,
    int? pendingAssignmentsCount,
    List<ChildResultEntity>? latestResults,
  }) {
    return ChildSummaryEntity(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      className: className ?? this.className,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      relationship: relationship ?? this.relationship,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      pendingAssignmentsCount:
          pendingAssignmentsCount ?? this.pendingAssignmentsCount,
      latestResults: latestResults ?? this.latestResults,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        admissionNumber,
        className,
        avatarUrl,
        relationship,
        isPrimaryContact,
        attendanceSummary,
        pendingAssignmentsCount,
        latestResults,
      ];
}

/// Represents a brief summary of a school announcement shown on the parent dashboard.
///
/// Contains only the essential fields needed for announcement list items
/// so the dashboard stays lightweight and fast.
class AnnouncementSummaryEntity extends Equatable {
  const AnnouncementSummaryEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.createdAt,
  });

  /// Unique identifier of the announcement.
  final String id;

  /// Title of the announcement.
  final String title;

  /// Type or category of the announcement (e.g., "general", "urgent").
  final String type;

  /// Priority level of the announcement (e.g., "high", "medium", "low").
  final String priority;

  /// Timestamp when the announcement was created.
  final DateTime createdAt;

  AnnouncementSummaryEntity copyWith({
    String? id,
    String? title,
    String? type,
    String? priority,
    DateTime? createdAt,
  }) {
    return AnnouncementSummaryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        priority,
        createdAt,
      ];
}

/// Represents the performance of a student in a single subject.
///
/// Provides score averages, grades, and the teacher responsible,
/// enabling parents to understand subject-level progress.
class SubjectPerformanceEntity extends Equatable {
  const SubjectPerformanceEntity({
    required this.subjectId,
    required this.subjectName,
    this.teacherName,
    this.latestScore,
    this.averageScore,
    this.grade,
  });

  /// Unique identifier of the subject.
  final String subjectId;

  /// Display name of the subject.
  final String subjectName;

  /// Name of the teacher assigned to the subject.
  final String? teacherName;

  /// Score from the most recent assessment in this subject.
  final double? latestScore;

  /// Average score across all assessments in this subject.
  final double? averageScore;

  /// Overall letter grade for the subject.
  final String? grade;

  SubjectPerformanceEntity copyWith({
    String? subjectId,
    String? subjectName,
    String? teacherName,
    double? latestScore,
    double? averageScore,
    String? grade,
  }) {
    return SubjectPerformanceEntity(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
      latestScore: latestScore ?? this.latestScore,
      averageScore: averageScore ?? this.averageScore,
      grade: grade ?? this.grade,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        teacherName,
        latestScore,
        averageScore,
        grade,
      ];
}

/// Represents a remark written by a teacher about a student's performance.
///
/// Captures the teacher's name, subject, comment, and date so parents
/// can review qualitative feedback alongside quantitative results.
class TeacherRemarkEntity extends Equatable {
  const TeacherRemarkEntity({
    required this.teacherName,
    required this.subject,
    required this.remark,
    required this.date,
  });

  /// Name of the teacher who wrote the remark.
  final String teacherName;

  /// Subject the remark pertains to.
  final String subject;

  /// The remark text written by the teacher.
  final String remark;

  /// Date the remark was written.
  final DateTime date;

  TeacherRemarkEntity copyWith({
    String? teacherName,
    String? subject,
    String? remark,
    DateTime? date,
  }) {
    return TeacherRemarkEntity(
      teacherName: teacherName ?? this.teacherName,
      subject: subject ?? this.subject,
      remark: remark ?? this.remark,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        teacherName,
        subject,
        remark,
        date,
      ];
}

/// Represents a student identified as needing additional parental support.
///
/// Used in the admin engagement analytics dashboard to surface students
/// whose parents show low or declining engagement levels.
class StudentSupportEntity extends Equatable {
  const StudentSupportEntity({
    required this.studentId,
    required this.studentName,
    this.parentName,
    this.engagementLevel,
    this.lastActive,
  });

  /// Unique identifier of the student.
  final String studentId;

  /// Display name of the student.
  final String studentName;

  /// Name of the student's parent or guardian.
  final String? parentName;

  /// Engagement level classification (e.g., "low", "moderate", "high").
  final String? engagementLevel;

  /// Timestamp of the parent's last activity in the portal.
  final DateTime? lastActive;

  StudentSupportEntity copyWith({
    String? studentId,
    String? studentName,
    String? parentName,
    String? engagementLevel,
    DateTime? lastActive,
  }) {
    return StudentSupportEntity(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      parentName: parentName ?? this.parentName,
      engagementLevel: engagementLevel ?? this.engagementLevel,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        parentName,
        engagementLevel,
        lastActive,
      ];
}

/// Represents a single data point in an engagement trend over time.
///
/// Used to chart daily or periodic interaction counts so administrators
/// can visualise engagement patterns across the parent community.
class EngagementTrendEntity extends Equatable {
  const EngagementTrendEntity({
    required this.date,
    required this.interactions,
  });

  /// The date of the data point.
  final DateTime date;

  /// Number of interactions recorded on this date.
  final int interactions;

  EngagementTrendEntity copyWith({
    DateTime? date,
    int? interactions,
  }) {
    return EngagementTrendEntity(
      date: date ?? this.date,
      interactions: interactions ?? this.interactions,
    );
  }

  @override
  List<Object?> get props => [
        date,
        interactions,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a message sent or received by a parent in the messaging system.
///
/// Supports threaded conversations via [parentMessageId] and [threadId],
/// tracks delivery status through [status], and includes attachment metadata.
/// Optional name fields allow display without additional lookups.
class ParentMessageEntity extends Equatable {
  const ParentMessageEntity({
    required this.id,
    required this.schoolId,
    required this.senderId,
    required this.senderRole,
    required this.recipientId,
    required this.recipientRole,
    this.studentId,
    required this.subject,
    required this.body,
    this.parentMessageId,
    this.threadId,
    required this.direction,
    required this.status,
    this.isFlagged = false,
    this.isArchived = false,
    this.readAt,
    this.deliveredAt,
    this.attachments = const [],
    this.senderName,
    this.recipientName,
    this.studentName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier of the message.
  final String id;

  /// Identifier of the school this message belongs to.
  final String schoolId;

  /// Identifier of the message sender.
  final String senderId;

  /// Role of the sender (e.g., "parent", "teacher", "admin").
  final String senderRole;

  /// Identifier of the message recipient.
  final String recipientId;

  /// Role of the recipient (e.g., "parent", "teacher", "admin").
  final String recipientRole;

  /// Identifier of the student the message relates to, if applicable.
  final String? studentId;

  /// Subject line of the message.
  final String subject;

  /// Body content of the message.
  final String body;

  /// Identifier of the parent message this is replying to, for threading.
  final String? parentMessageId;

  /// Identifier of the conversation thread this message belongs to.
  final String? threadId;

  /// Direction of the message relative to the parent.
  final MessageDirection direction;

  /// Current delivery status of the message.
  final MessageStatus status;

  /// Whether the message has been flagged by the user.
  final bool isFlagged;

  /// Whether the message has been archived by the user.
  final bool isArchived;

  /// Timestamp when the message was read by the recipient.
  final DateTime? readAt;

  /// Timestamp when the message was delivered to the recipient.
  final DateTime? deliveredAt;

  /// List of attachment metadata maps (name, url, size, type, etc.).
  final List<Map<String, dynamic>> attachments;

  /// Display name of the sender, cached for quick rendering.
  final String? senderName;

  /// Display name of the recipient, cached for quick rendering.
  final String? recipientName;

  /// Display name of the related student, cached for quick rendering.
  final String? studentName;

  /// Timestamp when the message was created.
  final DateTime createdAt;

  /// Timestamp when the message was last updated.
  final DateTime updatedAt;

  ParentMessageEntity copyWith({
    String? id,
    String? schoolId,
    String? senderId,
    String? senderRole,
    String? recipientId,
    String? recipientRole,
    String? studentId,
    String? subject,
    String? body,
    String? parentMessageId,
    String? threadId,
    MessageDirection? direction,
    MessageStatus? status,
    bool? isFlagged,
    bool? isArchived,
    DateTime? readAt,
    DateTime? deliveredAt,
    List<Map<String, dynamic>>? attachments,
    String? senderName,
    String? recipientName,
    String? studentName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentMessageEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      studentId: studentId ?? this.studentId,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      threadId: threadId ?? this.threadId,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      isFlagged: isFlagged ?? this.isFlagged,
      isArchived: isArchived ?? this.isArchived,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      attachments: attachments ?? this.attachments,
      senderName: senderName ?? this.senderName,
      recipientName: recipientName ?? this.recipientName,
      studentName: studentName ?? this.studentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        senderId,
        senderRole,
        recipientId,
        recipientRole,
        studentId,
        subject,
        body,
        parentMessageId,
        threadId,
        direction,
        status,
        isFlagged,
        isArchived,
        readAt,
        deliveredAt,
        attachments,
        senderName,
        recipientName,
        studentName,
        createdAt,
        updatedAt,
      ];
}

/// Represents a notification delivered to a parent through various channels.
///
/// Tracks multi-channel delivery (in-app, push, email, SMS), read state,
/// and optional deep-link actions so parents can act on notifications directly.
class ParentNotificationEntity extends Equatable {
  const ParentNotificationEntity({
    required this.id,
    required this.schoolId,
    required this.parentId,
    this.studentId,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.category,
    required this.priority,
    this.data = const {},
    this.isRead = false,
    this.readAt,
    this.deliveredInApp = false,
    this.deliveredPush = false,
    this.deliveredEmail = false,
    this.deliveredSms = false,
    this.actionUrl,
    this.actionLabel,
    this.expiresAt,
    required this.createdAt,
  });

  /// Unique identifier of the notification.
  final String id;

  /// Identifier of the school this notification belongs to.
  final String schoolId;

  /// Identifier of the parent receiving the notification.
  final String parentId;

  /// Identifier of the student the notification relates to, if applicable.
  final String? studentId;

  /// Title of the notification.
  final String title;

  /// Body content of the notification.
  final String body;

  /// Type of notification (e.g., "report_published", "attendance_alert").
  final String notificationType;

  /// Category of the notification for grouping and filtering.
  final NotificationCategory category;

  /// Priority level (e.g., "high", "medium", "low").
  final String priority;

  /// Additional structured data payload for the notification.
  final Map<String, dynamic> data;

  /// Whether the notification has been read by the parent.
  final bool isRead;

  /// Timestamp when the notification was read.
  final DateTime? readAt;

  /// Whether the notification was delivered via the in-app channel.
  final bool deliveredInApp;

  /// Whether the notification was delivered via push notification.
  final bool deliveredPush;

  /// Whether the notification was delivered via email.
  final bool deliveredEmail;

  /// Whether the notification was delivered via SMS.
  final bool deliveredSms;

  /// Deep-link URL that the parent can navigate to from the notification.
  final String? actionUrl;

  /// Label for the action button displayed with the notification.
  final String? actionLabel;

  /// Timestamp after which the notification is considered expired.
  final DateTime? expiresAt;

  /// Timestamp when the notification was created.
  final DateTime createdAt;

  ParentNotificationEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    String? title,
    String? body,
    String? notificationType,
    NotificationCategory? category,
    String? priority,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    bool? deliveredInApp,
    bool? deliveredPush,
    bool? deliveredEmail,
    bool? deliveredSms,
    String? actionUrl,
    String? actionLabel,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return ParentNotificationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      deliveredInApp: deliveredInApp ?? this.deliveredInApp,
      deliveredPush: deliveredPush ?? this.deliveredPush,
      deliveredEmail: deliveredEmail ?? this.deliveredEmail,
      deliveredSms: deliveredSms ?? this.deliveredSms,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        title,
        body,
        notificationType,
        category,
        priority,
        data,
        isRead,
        readAt,
        deliveredInApp,
        deliveredPush,
        deliveredEmail,
        deliveredSms,
        actionUrl,
        actionLabel,
        expiresAt,
        createdAt,
      ];
}

/// Represents an activity log entry for a parent's actions within the portal.
///
/// Captures what the parent did, which resource was accessed, and contextual
/// device/network information for auditing and engagement analytics.
class ParentActivityLogEntity extends Equatable {
  const ParentActivityLogEntity({
    required this.id,
    required this.schoolId,
    required this.parentId,
    this.studentId,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.details = const {},
    this.ipAddress,
    this.userAgent,
    this.deviceType,
    required this.createdAt,
  });

  /// Unique identifier of the activity log entry.
  final String id;

  /// Identifier of the school this activity belongs to.
  final String schoolId;

  /// Identifier of the parent who performed the action.
  final String parentId;

  /// Identifier of the student the action relates to, if applicable.
  final String? studentId;

  /// Description of the action performed (e.g., "viewed_report_card").
  final String action;

  /// Type of resource that was accessed (e.g., "report", "assignment").
  final String? resourceType;

  /// Identifier of the specific resource that was accessed.
  final String? resourceId;

  /// Additional structured details about the activity.
  final Map<String, dynamic> details;

  /// IP address from which the action was performed.
  final String? ipAddress;

  /// User agent string of the client that performed the action.
  final String? userAgent;

  /// Type of device used (e.g., "mobile", "desktop", "tablet").
  final String? deviceType;

  /// Timestamp when the activity occurred.
  final DateTime createdAt;

  ParentActivityLogEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    String? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    String? deviceType,
    DateTime? createdAt,
  }) {
    return ParentActivityLogEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      details: details ?? this.details,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceType: deviceType ?? this.deviceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        action,
        resourceType,
        resourceId,
        details,
        ipAddress,
        userAgent,
        deviceType,
        createdAt,
      ];
}

/// Represents an AI-generated insight delivered to a parent about their child.
///
/// Insights can cover performance trends, attendance alerts, study
/// recommendations, engagement tips, milestones, or concerns. Each insight
/// tracks whether it was AI-generated, its severity, and whether it is
/// actionable, enabling the UI to prioritise and filter effectively.
class ParentAiInsightEntity extends Equatable {
  const ParentAiInsightEntity({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.insightType,
    required this.title,
    required this.description,
    required this.severity,
    this.recommendations = const [],
    this.isAiGenerated = false,
    this.aiModel,
    this.dataSnapshot = const {},
    this.isRead = false,
    this.isDismissed = false,
    this.isActionable = false,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  /// Unique identifier of the insight.
  final String id;

  /// Identifier of the school this insight belongs to.
  final String schoolId;

  /// Identifier of the parent receiving the insight.
  final String parentId;

  /// Identifier of the student the insight pertains to.
  final String studentId;

  /// Type category of the insight.
  final ParentInsightType insightType;

  /// Short title summarising the insight.
  final String title;

  /// Detailed description of the insight.
  final String description;

  /// Severity level indicating the importance of the insight.
  final InsightSeverity severity;

  /// List of actionable recommendations derived from the insight.
  final List<String> recommendations;

  /// Whether the insight was generated by an AI model.
  final bool isAiGenerated;

  /// Name of the AI model that generated the insight, if applicable.
  final String? aiModel;

  /// Snapshot of the underlying data that informed the insight.
  final Map<String, dynamic> dataSnapshot;

  /// Whether the parent has read the insight.
  final bool isRead;

  /// Whether the parent has dismissed the insight.
  final bool isDismissed;

  /// Whether the insight offers a concrete action the parent can take.
  final bool isActionable;

  /// Start of the time window during which the insight is relevant.
  final DateTime validFrom;

  /// End of the time window during which the insight is relevant.
  final DateTime? validUntil;

  /// Timestamp when the insight was created.
  final DateTime createdAt;

  ParentAiInsightEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    ParentInsightType? insightType,
    String? title,
    String? description,
    InsightSeverity? severity,
    List<String>? recommendations,
    bool? isAiGenerated,
    String? aiModel,
    Map<String, dynamic>? dataSnapshot,
    bool? isRead,
    bool? isDismissed,
    bool? isActionable,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
  }) {
    return ParentAiInsightEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      insightType: insightType ?? this.insightType,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      recommendations: recommendations ?? this.recommendations,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      dataSnapshot: dataSnapshot ?? this.dataSnapshot,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      isActionable: isActionable ?? this.isActionable,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        insightType,
        title,
        description,
        severity,
        recommendations,
        isAiGenerated,
        aiModel,
        dataSnapshot,
        isRead,
        isDismissed,
        isActionable,
        validFrom,
        validUntil,
        createdAt,
      ];
}

/// Represents a report file downloaded by a parent.
///
/// Tracks the report type, format, file metadata, and download timestamp
/// so the system can log engagement and provide download history.
class ParentReportDownloadEntity extends Equatable {
  const ParentReportDownloadEntity({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.reportType,
    this.reportId,
    required this.format,
    required this.fileUrl,
    required this.fileName,
    this.fileSizeBytes,
    required this.downloadedAt,
  });

  /// Unique identifier of the download record.
  final String id;

  /// Identifier of the school the report belongs to.
  final String schoolId;

  /// Identifier of the parent who downloaded the report.
  final String parentId;

  /// Identifier of the student the report is about.
  final String studentId;

  /// Type of report that was downloaded.
  final ReportType reportType;

  /// Identifier of the source report record, if available.
  final String? reportId;

  /// File format of the downloaded report (e.g., "pdf", "xlsx").
  final String format;

  /// URL from which the report file was downloaded.
  final String fileUrl;

  /// Name of the downloaded file.
  final String fileName;

  /// Size of the downloaded file in bytes.
  final int? fileSizeBytes;

  /// Timestamp when the report was downloaded.
  final DateTime downloadedAt;

  ParentReportDownloadEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    ReportType? reportType,
    String? reportId,
    String? format,
    String? fileUrl,
    String? fileName,
    int? fileSizeBytes,
    DateTime? downloadedAt,
  }) {
    return ParentReportDownloadEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      reportType: reportType ?? this.reportType,
      reportId: reportId ?? this.reportId,
      format: format ?? this.format,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        reportType,
        reportId,
        format,
        fileUrl,
        fileName,
        fileSizeBytes,
        downloadedAt,
      ];
}

/// Represents a calendar event visible to a parent.
///
/// Covers school events, holidays, parent-teacher meetings, exams,
/// and deadlines. Supports reminders, all-day flags, and recurrence rules
/// so parents can plan ahead effectively.
class ParentCalendarEventEntity extends Equatable {
  const ParentCalendarEventEntity({
    required this.id,
    required this.schoolId,
    this.parentId,
    this.studentId,
    required this.title,
    this.description,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    this.location,
    this.sourceType,
    this.sourceId,
    this.reminderMinutes = const [],
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier of the calendar event.
  final String id;

  /// Identifier of the school this event belongs to.
  final String schoolId;

  /// Identifier of the parent the event is specifically for, if applicable.
  final String? parentId;

  /// Identifier of the student the event relates to, if applicable.
  final String? studentId;

  /// Title of the event.
  final String title;

  /// Description of the event.
  final String? description;

  /// Type category of the event.
  final CalendarEventType eventType;

  /// Start time of the event.
  final DateTime startTime;

  /// End time of the event.
  final DateTime endTime;

  /// Physical or virtual location of the event.
  final String? location;

  /// Type of the source that created this event (e.g., "system", "teacher").
  final String? sourceType;

  /// Identifier of the source record that created this event.
  final String? sourceId;

  /// List of reminder lead times in minutes before the event.
  final List<int> reminderMinutes;

  /// Whether the event spans the entire day.
  final bool isAllDay;

  /// Whether the event recurs on a schedule.
  final bool isRecurring;

  /// RRULE-compatible recurrence rule string, if the event is recurring.
  final String? recurrenceRule;

  /// Timestamp when the event was created.
  final DateTime createdAt;

  /// Timestamp when the event was last updated.
  final DateTime updatedAt;

  ParentCalendarEventEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    String? title,
    String? description,
    CalendarEventType? eventType,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? sourceType,
    String? sourceId,
    List<int>? reminderMinutes,
    bool? isAllDay,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentCalendarEventEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        title,
        description,
        eventType,
        startTime,
        endTime,
        location,
        sourceType,
        sourceId,
        reminderMinutes,
        isAllDay,
        isRecurring,
        recurrenceRule,
        createdAt,
        updatedAt,
      ];
}

/// Represents a single engagement metric recorded for a parent.
///
/// Tracks discrete interaction events such as viewing a report card,
/// reading an announcement, or sending a message, enabling the system
/// to build a comprehensive picture of parental engagement.
class EngagementMetricEntity extends Equatable {
  const EngagementMetricEntity({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.metricType,
    required this.metricValue,
    this.details = const {},
    required this.recordedAt,
  });

  /// Unique identifier of the metric record.
  final String id;

  /// Identifier of the school this metric belongs to.
  final String schoolId;

  /// Identifier of the parent who performed the interaction.
  final String parentId;

  /// Identifier of the student the interaction relates to.
  final String studentId;

  /// Type of engagement metric recorded.
  final EngagementMetricType metricType;

  /// Numeric value of the metric (typically `1` for occurrence-based metrics).
  final double metricValue;

  /// Additional structured details about the interaction.
  final Map<String, dynamic> details;

  /// Timestamp when the interaction was recorded.
  final DateTime recordedAt;

  EngagementMetricEntity copyWith({
    String? id,
    String? schoolId,
    String? parentId,
    String? studentId,
    EngagementMetricType? metricType,
    double? metricValue,
    Map<String, dynamic>? details,
    DateTime? recordedAt,
  }) {
    return EngagementMetricEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      metricType: metricType ?? this.metricType,
      metricValue: metricValue ?? this.metricValue,
      details: details ?? this.details,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        parentId,
        studentId,
        metricType,
        metricValue,
        details,
        recordedAt,
      ];
}

/// Represents the parent dashboard, aggregating all key information for a parent.
///
/// Includes children summaries, notification counts, upcoming events,
/// recent announcements, and the parent's own profile details so the
/// dashboard view can be rendered in a single call.
class ParentDashboardEntity extends Equatable {
  const ParentDashboardEntity({
    required this.parentId,
    required this.schoolId,
    this.parentName,
    this.parentEmail,
    this.parentPhone,
    this.parentAvatar,
    required this.childCount,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
    this.activeInsights = 0,
    this.children = const [],
    this.upcomingEvents = const [],
    this.recentAnnouncements = const [],
    this.lastActiveAt,
  });

  /// Unique identifier of the parent.
  final String parentId;

  /// Identifier of the school the parent belongs to.
  final String schoolId;

  /// Display name of the parent.
  final String? parentName;

  /// Email address of the parent.
  final String? parentEmail;

  /// Phone number of the parent.
  final String? parentPhone;

  /// URL of the parent's avatar image.
  final String? parentAvatar;

  /// Number of children linked to this parent.
  final int childCount;

  /// Count of unread notifications for the parent.
  final int unreadNotifications;

  /// Count of unread messages for the parent.
  final int unreadMessages;

  /// Count of active (unread, non-dismissed) AI insights.
  final int activeInsights;

  /// Summaries of each child linked to this parent.
  final List<ChildSummaryEntity> children;

  /// Upcoming calendar events relevant to the parent.
  final List<ParentCalendarEventEntity> upcomingEvents;

  /// Recent school announcements visible to the parent.
  final List<AnnouncementSummaryEntity> recentAnnouncements;

  /// Timestamp of the parent's last activity in the portal.
  final DateTime? lastActiveAt;

  ParentDashboardEntity copyWith({
    String? parentId,
    String? schoolId,
    String? parentName,
    String? parentEmail,
    String? parentPhone,
    String? parentAvatar,
    int? childCount,
    int? unreadNotifications,
    int? unreadMessages,
    int? activeInsights,
    List<ChildSummaryEntity>? children,
    List<ParentCalendarEventEntity>? upcomingEvents,
    List<AnnouncementSummaryEntity>? recentAnnouncements,
    DateTime? lastActiveAt,
  }) {
    return ParentDashboardEntity(
      parentId: parentId ?? this.parentId,
      schoolId: schoolId ?? this.schoolId,
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      parentAvatar: parentAvatar ?? this.parentAvatar,
      childCount: childCount ?? this.childCount,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      activeInsights: activeInsights ?? this.activeInsights,
      children: children ?? this.children,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      recentAnnouncements: recentAnnouncements ?? this.recentAnnouncements,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
        parentId,
        schoolId,
        parentName,
        parentEmail,
        parentPhone,
        parentAvatar,
        childCount,
        unreadNotifications,
        unreadMessages,
        activeInsights,
        children,
        upcomingEvents,
        recentAnnouncements,
        lastActiveAt,
      ];
}

/// Represents the academic performance details of a child from a parent's perspective.
///
/// Aggregates subject-level performance, overall averages, attendance rate,
/// and qualitative teacher remarks so parents get a holistic academic view.
class ChildPerformanceEntity extends Equatable {
  const ChildPerformanceEntity({
    required this.studentId,
    this.subjects = const [],
    this.overallAverage,
    this.classAverage,
    this.attendanceRate,
    this.teacherRemarks = const [],
  });

  /// Unique identifier of the student.
  final String studentId;

  /// Performance breakdown by subject.
  final List<SubjectPerformanceEntity> subjects;

  /// Overall average score across all subjects.
  final double? overallAverage;

  /// Class average score for comparison.
  final double? classAverage;

  /// Attendance rate as a decimal between `0.0` and `1.0`.
  final double? attendanceRate;

  /// Qualitative remarks from teachers.
  final List<TeacherRemarkEntity> teacherRemarks;

  ChildPerformanceEntity copyWith({
    String? studentId,
    List<SubjectPerformanceEntity>? subjects,
    double? overallAverage,
    double? classAverage,
    double? attendanceRate,
    List<TeacherRemarkEntity>? teacherRemarks,
  }) {
    return ChildPerformanceEntity(
      studentId: studentId ?? this.studentId,
      subjects: subjects ?? this.subjects,
      overallAverage: overallAverage ?? this.overallAverage,
      classAverage: classAverage ?? this.classAverage,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        subjects,
        overallAverage,
        classAverage,
        attendanceRate,
        teacherRemarks,
      ];
}

/// Represents engagement analytics aggregated across all parents for an admin dashboard.
///
/// Provides segmentation of parent engagement levels, metric breakdowns,
/// students needing support, and trend data so administrators can identify
/// patterns and intervene where necessary.
class EngagementAnalyticsEntity extends Equatable {
  const EngagementAnalyticsEntity({
    required this.schoolId,
    required this.totalParents,
    required this.activeParents,
    required this.moderateParents,
    required this.inactiveParents,
    required this.reportCardNotViewed,
    this.avgMessageResponseHours,
    this.unreadAnnouncementCount,
    this.engagementByMetric = const {},
    this.studentsNeedingSupport = const [],
    this.engagementTrends = const [],
  });

  /// Identifier of the school these analytics belong to.
  final String schoolId;

  /// Total number of registered parents.
  final int totalParents;

  /// Number of parents classified as highly active.
  final int activeParents;

  /// Number of parents classified as moderately active.
  final int moderateParents;

  /// Number of parents classified as inactive.
  final int inactiveParents;

  /// Number of parents who have not viewed the latest report card.
  final int reportCardNotViewed;

  /// Average number of hours parents take to respond to messages.
  final double? avgMessageResponseHours;

  /// Count of parents with unread announcements.
  final int? unreadAnnouncementCount;

  /// Breakdown of engagement counts by metric type key.
  final Map<String, int> engagementByMetric;

  /// Students whose parents show low engagement and need support.
  final List<StudentSupportEntity> studentsNeedingSupport;

  /// Daily engagement interaction trend data.
  final List<EngagementTrendEntity> engagementTrends;

  EngagementAnalyticsEntity copyWith({
    String? schoolId,
    int? totalParents,
    int? activeParents,
    int? moderateParents,
    int? inactiveParents,
    int? reportCardNotViewed,
    double? avgMessageResponseHours,
    int? unreadAnnouncementCount,
    Map<String, int>? engagementByMetric,
    List<StudentSupportEntity>? studentsNeedingSupport,
    List<EngagementTrendEntity>? engagementTrends,
  }) {
    return EngagementAnalyticsEntity(
      schoolId: schoolId ?? this.schoolId,
      totalParents: totalParents ?? this.totalParents,
      activeParents: activeParents ?? this.activeParents,
      moderateParents: moderateParents ?? this.moderateParents,
      inactiveParents: inactiveParents ?? this.inactiveParents,
      reportCardNotViewed: reportCardNotViewed ?? this.reportCardNotViewed,
      avgMessageResponseHours:
          avgMessageResponseHours ?? this.avgMessageResponseHours,
      unreadAnnouncementCount:
          unreadAnnouncementCount ?? this.unreadAnnouncementCount,
      engagementByMetric: engagementByMetric ?? this.engagementByMetric,
      studentsNeedingSupport:
          studentsNeedingSupport ?? this.studentsNeedingSupport,
      engagementTrends: engagementTrends ?? this.engagementTrends,
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        totalParents,
        activeParents,
        moderateParents,
        inactiveParents,
        reportCardNotViewed,
        avgMessageResponseHours,
        unreadAnnouncementCount,
        engagementByMetric,
        studentsNeedingSupport,
        engagementTrends,
      ];
}

/// Represents a conversation thread for a parent in the messaging system.
///
/// Aggregates the other participant, last message, and unread count so the
/// parent can browse their conversations without loading full message history.
class ParentMessageThreadEntity extends Equatable {
  const ParentMessageThreadEntity({
    required this.threadId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.lastMessage,
    this.unreadCount = 0,
    this.studentId,
    this.studentName,
  });

  /// Unique identifier of the conversation thread.
  final String threadId;

  /// Identifier of the other participant in the conversation.
  final String otherUserId;

  /// Display name of the other participant.
  final String otherUserName;

  /// Role of the other participant (e.g., "teacher", "admin").
  final String otherUserRole;

  /// The most recent message in the thread, if any.
  final ParentMessageEntity? lastMessage;

  /// Number of unread messages in this thread.
  final int unreadCount;

  /// Identifier of the student the conversation relates to, if applicable.
  final String? studentId;

  /// Display name of the related student, if applicable.
  final String? studentName;

  ParentMessageThreadEntity copyWith({
    String? threadId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserRole,
    ParentMessageEntity? lastMessage,
    int? unreadCount,
    String? studentId,
    String? studentName,
  }) {
    return ParentMessageThreadEntity(
      threadId: threadId ?? this.threadId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserRole: otherUserRole ?? this.otherUserRole,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
    );
  }

  @override
  List<Object?> get props => [
        threadId,
        otherUserId,
        otherUserName,
        otherUserRole,
        lastMessage,
        unreadCount,
        studentId,
        studentName,
      ];
}

/// Represents the profile details of a child as seen by a parent.
///
/// Aggregates identity, class, and relationship information so the
/// parent portal can render the child's profile without additional joins.
class ChildProfileEntity extends Equatable {
  const ChildProfileEntity({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.admissionNumber,
    this.avatarUrl,
    this.className,
    required this.relationship,
    this.isPrimaryContact = false,
  });

  /// Unique identifier of the student.
  final String studentId;

  /// First name of the student.
  final String firstName;

  /// Last name / surname of the student.
  final String lastName;

  /// School admission number of the student.
  final String? admissionNumber;

  /// URL of the student's avatar image.
  final String? avatarUrl;

  /// Name of the class the student belongs to.
  final String? className;

  /// Relationship of the parent to the student (e.g., "Father", "Mother").
  final String relationship;

  /// Whether this parent is the primary contact for the student.
  final bool isPrimaryContact;

  /// Convenience getter for the full display name.
  String get displayName => '$firstName $lastName'.trim();

  ChildProfileEntity copyWith({
    String? studentId,
    String? firstName,
    String? lastName,
    String? admissionNumber,
    String? avatarUrl,
    String? className,
    String? relationship,
    bool? isPrimaryContact,
  }) {
    return ChildProfileEntity(
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      className: className ?? this.className,
      relationship: relationship ?? this.relationship,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        firstName,
        lastName,
        admissionNumber,
        avatarUrl,
        className,
        relationship,
        isPrimaryContact,
      ];
}

/// Represents attendance records for a child from a parent's perspective.
///
/// Wraps individual attendance records along with the queried date range
/// so the parent can review attendance history for specific periods.
class ChildAttendanceEntity extends Equatable {
  const ChildAttendanceEntity({
    required this.studentId,
    this.records = const [],
    this.startDate,
    this.endDate,
  });

  /// Unique identifier of the student.
  final String studentId;

  /// List of attendance record maps from the data source.
  final List<Map<String, dynamic>> records;

  /// Start of the queried date range.
  final DateTime? startDate;

  /// End of the queried date range.
  final DateTime? endDate;

  ChildAttendanceEntity copyWith({
    String? studentId,
    List<Map<String, dynamic>>? records,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ChildAttendanceEntity(
      studentId: studentId ?? this.studentId,
      records: records ?? this.records,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        records,
        startDate,
        endDate,
      ];
}

/// Represents a single assignment for a child as seen by a parent.
///
/// Aggregates assignment details and the student's submission status
/// so parents can monitor homework and coursework progress.
class ChildAssignmentEntity extends Equatable {
  const ChildAssignmentEntity({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.status,
    this.submittedAt,
    this.score,
    required this.title,
    this.description,
    this.dueDate,
    this.subjectName,
  });

  /// Unique identifier of the student-assignment record.
  final String id;

  /// Identifier of the original assignment.
  final String assignmentId;

  /// Identifier of the student.
  final String studentId;

  /// Submission status (e.g., "pending", "submitted", "graded").
  final String status;

  /// Timestamp when the assignment was submitted.
  final DateTime? submittedAt;

  /// Score received, if the assignment has been graded.
  final double? score;

  /// Title of the assignment.
  final String title;

  /// Description of the assignment.
  final String? description;

  /// Due date of the assignment.
  final DateTime? dueDate;

  /// Name of the subject the assignment belongs to.
  final String? subjectName;

  ChildAssignmentEntity copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? status,
    DateTime? submittedAt,
    double? score,
    String? title,
    String? description,
    DateTime? dueDate,
    String? subjectName,
  }) {
    return ChildAssignmentEntity(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      subjectName: subjectName ?? this.subjectName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        studentId,
        status,
        submittedAt,
        score,
        title,
        description,
        dueDate,
        subjectName,
      ];
}

/// Represents a response from the AI parent assistant.
///
/// Contains the assistant's answer, optional source references,
/// follow-up suggestions, and a confidence score so the parent
/// can evaluate the quality of the response.
class ParentAssistantResponseEntity extends Equatable {
  const ParentAssistantResponseEntity({
    required this.answer,
    this.sources = const [],
    this.studentId,
    this.followUpQuestions = const [],
    this.confidence = 0.0,
  });

  /// The assistant's answer text.
  final String answer;

  /// Source references that informed the answer.
  final List<Map<String, dynamic>> sources;

  /// Identifier of the student the question pertained to, if any.
  final String? studentId;

  /// Suggested follow-up questions the parent can ask.
  final List<String> followUpQuestions;

  /// Confidence score of the answer (0.0 – 1.0).
  final double confidence;

  ParentAssistantResponseEntity copyWith({
    String? answer,
    List<Map<String, dynamic>>? sources,
    String? studentId,
    List<String>? followUpQuestions,
    double? confidence,
  }) {
    return ParentAssistantResponseEntity(
      answer: answer ?? this.answer,
      sources: sources ?? this.sources,
      studentId: studentId ?? this.studentId,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
        answer,
        sources,
        studentId,
        followUpQuestions,
        confidence,
      ];
}
