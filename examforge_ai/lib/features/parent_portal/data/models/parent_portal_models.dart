import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT MESSAGE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a parent message, mapping to the
/// `parent_messages` table.
class ParentMessageModel {
  const ParentMessageModel({
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

  final String id;
  final String schoolId;
  final String senderId;
  final String senderRole;
  final String recipientId;
  final String recipientRole;
  final String? studentId;
  final String subject;
  final String body;
  final String? parentMessageId;
  final String? threadId;
  final String direction;
  final String status;
  final bool isFlagged;
  final bool isArchived;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final List<Map<String, dynamic>> attachments;
  final String? senderName;
  final String? recipientName;
  final String? studentName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentMessageModel.fromJson(Map<String, dynamic> json) {
    return ParentMessageModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? json['senderRole'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? json['recipientId'] as String? ?? '',
      recipientRole: json['recipient_role'] as String? ?? json['recipientRole'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      parentMessageId: json['parent_message_id'] as String? ?? json['parentMessageId'] as String?,
      threadId: json['thread_id'] as String? ?? json['threadId'] as String?,
      direction: json['direction'] as String? ?? 'incoming',
      status: json['status'] as String? ?? 'sent',
      isFlagged: json['is_flagged'] as bool? ?? json['isFlagged'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? json['isArchived'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : json['deliveredAt'] != null
              ? DateTime.parse(json['deliveredAt'] as String)
              : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      senderName: json['sender_name'] as String? ?? json['senderName'] as String?,
      recipientName: json['recipient_name'] as String? ?? json['recipientName'] as String?,
      studentName: json['student_name'] as String? ?? json['studentName'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'recipient_id': recipientId,
      'recipient_role': recipientRole,
      'student_id': studentId,
      'subject': subject,
      'body': body,
      'parent_message_id': parentMessageId,
      'thread_id': threadId,
      'direction': direction,
      'status': status,
      'is_flagged': isFlagged,
      'is_archived': isArchived,
      'read_at': readAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'attachments': attachments,
      'sender_name': senderName,
      'recipient_name': recipientName,
      'student_name': studentName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentMessageModel.fromEntity(ParentMessageEntity entity) {
    return ParentMessageModel(
      id: entity.id,
      schoolId: entity.schoolId,
      senderId: entity.senderId,
      senderRole: entity.senderRole,
      recipientId: entity.recipientId,
      recipientRole: entity.recipientRole,
      studentId: entity.studentId,
      subject: entity.subject,
      body: entity.body,
      parentMessageId: entity.parentMessageId,
      threadId: entity.threadId,
      direction: entity.direction.value,
      status: entity.status.value,
      isFlagged: entity.isFlagged,
      isArchived: entity.isArchived,
      readAt: entity.readAt,
      deliveredAt: entity.deliveredAt,
      attachments: entity.attachments,
      senderName: entity.senderName,
      recipientName: entity.recipientName,
      studentName: entity.studentName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ParentMessageEntity toEntity() {
    return ParentMessageEntity(
      id: id,
      schoolId: schoolId,
      senderId: senderId,
      senderRole: senderRole,
      recipientId: recipientId,
      recipientRole: recipientRole,
      studentId: studentId,
      subject: subject,
      body: body,
      parentMessageId: parentMessageId,
      threadId: threadId,
      direction: MessageDirection.fromString(direction) ?? MessageDirection.incoming,
      status: MessageStatus.fromString(status) ?? MessageStatus.sent,
      isFlagged: isFlagged,
      isArchived: isArchived,
      readAt: readAt,
      deliveredAt: deliveredAt,
      attachments: attachments,
      senderName: senderName,
      recipientName: recipientName,
      studentName: studentName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT NOTIFICATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a parent notification, mapping to the
/// `parent_notifications` table.
class ParentNotificationModel {
  const ParentNotificationModel({
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

  final String id;
  final String schoolId;
  final String parentId;
  final String? studentId;
  final String title;
  final String body;
  final String notificationType;
  final String category;
  final String priority;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final bool deliveredInApp;
  final bool deliveredPush;
  final bool deliveredEmail;
  final bool deliveredSms;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime? expiresAt;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentNotificationModel.fromJson(Map<String, dynamic> json) {
    return ParentNotificationModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? json['notificationType'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'medium',
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
      deliveredInApp: json['delivered_in_app'] as bool? ?? json['deliveredInApp'] as bool? ?? false,
      deliveredPush: json['delivered_push'] as bool? ?? json['deliveredPush'] as bool? ?? false,
      deliveredEmail: json['delivered_email'] as bool? ?? json['deliveredEmail'] as bool? ?? false,
      deliveredSms: json['delivered_sms'] as bool? ?? json['deliveredSms'] as bool? ?? false,
      actionUrl: json['action_url'] as String? ?? json['actionUrl'] as String?,
      actionLabel: json['action_label'] as String? ?? json['actionLabel'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'category': category,
      'priority': priority,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'delivered_in_app': deliveredInApp,
      'delivered_push': deliveredPush,
      'delivered_email': deliveredEmail,
      'delivered_sms': deliveredSms,
      'action_url': actionUrl,
      'action_label': actionLabel,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentNotificationModel.fromEntity(ParentNotificationEntity entity) {
    return ParentNotificationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      title: entity.title,
      body: entity.body,
      notificationType: entity.notificationType,
      category: entity.category.value,
      priority: entity.priority,
      data: entity.data,
      isRead: entity.isRead,
      readAt: entity.readAt,
      deliveredInApp: entity.deliveredInApp,
      deliveredPush: entity.deliveredPush,
      deliveredEmail: entity.deliveredEmail,
      deliveredSms: entity.deliveredSms,
      actionUrl: entity.actionUrl,
      actionLabel: entity.actionLabel,
      expiresAt: entity.expiresAt,
      createdAt: entity.createdAt,
    );
  }

  ParentNotificationEntity toEntity() {
    return ParentNotificationEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      title: title,
      body: body,
      notificationType: notificationType,
      category: NotificationCategory.fromString(category) ?? NotificationCategory.general,
      priority: priority,
      data: data,
      isRead: isRead,
      readAt: readAt,
      deliveredInApp: deliveredInApp,
      deliveredPush: deliveredPush,
      deliveredEmail: deliveredEmail,
      deliveredSms: deliveredSms,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT ACTIVITY LOG MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a parent activity log entry, mapping to
/// the `parent_activity_logs` table.
class ParentActivityLogModel {
  const ParentActivityLogModel({
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

  final String id;
  final String schoolId;
  final String parentId;
  final String? studentId;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceType;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ParentActivityLogModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? json['resourceType'] as String?,
      resourceId: json['resource_id'] as String? ?? json['resourceId'] as String?,
      details: json['details'] as Map<String, dynamic>? ?? {},
      ipAddress: json['ip_address'] as String? ?? json['ipAddress'] as String?,
      userAgent: json['user_agent'] as String? ?? json['userAgent'] as String?,
      deviceType: json['device_type'] as String? ?? json['deviceType'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details': details,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_type': deviceType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentActivityLogModel.fromEntity(ParentActivityLogEntity entity) {
    return ParentActivityLogModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      action: entity.action,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      details: entity.details,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      deviceType: entity.deviceType,
      createdAt: entity.createdAt,
    );
  }

  ParentActivityLogEntity toEntity() {
    return ParentActivityLogEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceType: deviceType,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT AI INSIGHT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an AI insight for a parent, mapping to
/// the `parent_ai_insights` table.
class ParentAiInsightModel {
  const ParentAiInsightModel({
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

  final String id;
  final String schoolId;
  final String parentId;
  final String studentId;
  final String insightType;
  final String title;
  final String description;
  final String severity;
  final List<String> recommendations;
  final bool isAiGenerated;
  final String? aiModel;
  final Map<String, dynamic> dataSnapshot;
  final bool isRead;
  final bool isDismissed;
  final bool isActionable;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentAiInsightModel.fromJson(Map<String, dynamic> json) {
    return ParentAiInsightModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      insightType: json['insight_type'] as String? ?? json['insightType'] as String? ?? 'performance_trend',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      recommendations: (json['recommendations'] as List<dynamic>?)?.cast<String>() ?? const [],
      isAiGenerated: json['is_ai_generated'] as bool? ?? json['isAiGenerated'] as bool? ?? false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      dataSnapshot: json['data_snapshot'] as Map<String, dynamic>? ?? json['dataSnapshot'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? json['isDismissed'] as bool? ?? false,
      isActionable: json['is_actionable'] as bool? ?? json['isActionable'] as bool? ?? false,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : json['validFrom'] != null
              ? DateTime.parse(json['validFrom'] as String)
              : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : json['validUntil'] != null
              ? DateTime.parse(json['validUntil'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'insight_type': insightType,
      'title': title,
      'description': description,
      'severity': severity,
      'recommendations': recommendations,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'data_snapshot': dataSnapshot,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'is_actionable': isActionable,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentAiInsightModel.fromEntity(ParentAiInsightEntity entity) {
    return ParentAiInsightModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      insightType: entity.insightType.value,
      title: entity.title,
      description: entity.description,
      severity: entity.severity.value,
      recommendations: entity.recommendations,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      dataSnapshot: entity.dataSnapshot,
      isRead: entity.isRead,
      isDismissed: entity.isDismissed,
      isActionable: entity.isActionable,
      validFrom: entity.validFrom,
      validUntil: entity.validUntil,
      createdAt: entity.createdAt,
    );
  }

  ParentAiInsightEntity toEntity() {
    return ParentAiInsightEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      insightType: ParentInsightType.fromString(insightType) ?? ParentInsightType.performanceTrend,
      title: title,
      description: description,
      severity: InsightSeverity.fromString(severity) ?? InsightSeverity.info,
      recommendations: recommendations,
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      dataSnapshot: dataSnapshot,
      isRead: isRead,
      isDismissed: isDismissed,
      isActionable: isActionable,
      validFrom: validFrom,
      validUntil: validUntil,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT REPORT DOWNLOAD MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a report download record, mapping to the
/// `parent_report_downloads` table.
class ParentReportDownloadModel {
  const ParentReportDownloadModel({
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

  final String id;
  final String schoolId;
  final String parentId;
  final String studentId;
  final String reportType;
  final String? reportId;
  final String format;
  final String fileUrl;
  final String fileName;
  final int? fileSizeBytes;
  final DateTime downloadedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentReportDownloadModel.fromJson(Map<String, dynamic> json) {
    return ParentReportDownloadModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      reportType: json['report_type'] as String? ?? json['reportType'] as String? ?? 'report_card',
      reportId: json['report_id'] as String? ?? json['reportId'] as String?,
      format: json['format'] as String? ?? 'pdf',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? json['fileSizeBytes'] as int?,
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.parse(json['downloaded_at'] as String)
          : json['downloadedAt'] != null
              ? DateTime.parse(json['downloadedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'report_type': reportType,
      'report_id': reportId,
      'format': format,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'downloaded_at': downloadedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentReportDownloadModel.fromEntity(ParentReportDownloadEntity entity) {
    return ParentReportDownloadModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      reportType: entity.reportType.value,
      reportId: entity.reportId,
      format: entity.format,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSizeBytes: entity.fileSizeBytes,
      downloadedAt: entity.downloadedAt,
    );
  }

  ParentReportDownloadEntity toEntity() {
    return ParentReportDownloadEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      reportType: ReportType.fromString(reportType) ?? ReportType.reportCard,
      reportId: reportId,
      format: format,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      downloadedAt: downloadedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT CALENDAR EVENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a calendar event visible to a parent,
/// mapping to the `parent_calendar_events` table.
class ParentCalendarEventModel {
  const ParentCalendarEventModel({
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

  final String id;
  final String schoolId;
  final String? parentId;
  final String? studentId;
  final String title;
  final String? description;
  final String eventType;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? sourceType;
  final String? sourceId;
  final List<int> reminderMinutes;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return ParentCalendarEventModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ?? json['eventType'] as String? ?? 'event',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : DateTime.now(),
      location: json['location'] as String?,
      sourceType: json['source_type'] as String? ?? json['sourceType'] as String?,
      sourceId: json['source_id'] as String? ?? json['sourceId'] as String?,
      reminderMinutes: (json['reminder_minutes'] as List<dynamic>?)
              ?.cast<int>() ??
          (json['reminderMinutes'] as List<dynamic>?)
              ?.cast<int>() ??
          const [],
      isAllDay: json['is_all_day'] as bool? ?? json['isAllDay'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? json['isRecurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String? ?? json['recurrenceRule'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'source_type': sourceType,
      'source_id': sourceId,
      'reminder_minutes': reminderMinutes,
      'is_all_day': isAllDay,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentCalendarEventModel.fromEntity(ParentCalendarEventEntity entity) {
    return ParentCalendarEventModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType.value,
      startTime: entity.startTime,
      endTime: entity.endTime,
      location: entity.location,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      reminderMinutes: entity.reminderMinutes,
      isAllDay: entity.isAllDay,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ParentCalendarEventEntity toEntity() {
    return ParentCalendarEventEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      title: title,
      description: description,
      eventType: CalendarEventType.fromString(eventType) ?? CalendarEventType.event,
      startTime: startTime,
      endTime: endTime,
      location: location,
      sourceType: sourceType,
      sourceId: sourceId,
      reminderMinutes: reminderMinutes,
      isAllDay: isAllDay,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENGAGEMENT METRIC MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an engagement metric, mapping to the
/// `parent_engagement_metrics` table.
class EngagementMetricModel {
  const EngagementMetricModel({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.metricType,
    required this.metricValue,
    this.details = const {},
    required this.recordedAt,
  });

  final String id;
  final String schoolId;
  final String parentId;
  final String studentId;
  final String metricType;
  final double metricValue;
  final Map<String, dynamic> details;
  final DateTime recordedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory EngagementMetricModel.fromJson(Map<String, dynamic> json) {
    return EngagementMetricModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      metricType: json['metric_type'] as String? ?? json['metricType'] as String? ?? 'report_card_viewed',
      metricValue: (json['metric_value'] as num?)?.toDouble() ?? (json['metricValue'] as num?)?.toDouble() ?? 0.0,
      details: json['details'] as Map<String, dynamic>? ?? {},
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : json['recordedAt'] != null
              ? DateTime.parse(json['recordedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'metric_type': metricType,
      'metric_value': metricValue,
      'details': details,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory EngagementMetricModel.fromEntity(EngagementMetricEntity entity) {
    return EngagementMetricModel(
      id: entity.id,
      schoolId: entity.schoolId,
      parentId: entity.parentId,
      studentId: entity.studentId,
      metricType: entity.metricType.value,
      metricValue: entity.metricValue,
      details: entity.details,
      recordedAt: entity.recordedAt,
    );
  }

  EngagementMetricEntity toEntity() {
    return EngagementMetricEntity(
      id: id,
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      metricType: EngagementMetricType.fromString(metricType) ?? EngagementMetricType.reportCardViewed,
      metricValue: metricValue,
      details: details,
      recordedAt: recordedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT DASHBOARD MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of the parent dashboard, mapping to the
/// aggregated RPC response from `get_parent_dashboard`.
///
/// Contains nested raw lists that are reconstructed into entity trees
/// in [toEntity].
class ParentDashboardModel {
  const ParentDashboardModel({
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

  final String parentId;
  final String schoolId;
  final String? parentName;
  final String? parentEmail;
  final String? parentPhone;
  final String? parentAvatar;
  final int childCount;
  final int unreadNotifications;
  final int unreadMessages;
  final int activeInsights;
  final List<Map<String, dynamic>> children;
  final List<Map<String, dynamic>> upcomingEvents;
  final List<Map<String, dynamic>> recentAnnouncements;
  final DateTime? lastActiveAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentDashboardModel.fromJson(Map<String, dynamic> json) {
    return ParentDashboardModel(
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      parentName: json['parent_name'] as String? ?? json['parentName'] as String?,
      parentEmail: json['parent_email'] as String? ?? json['parentEmail'] as String?,
      parentPhone: json['parent_phone'] as String? ?? json['parentPhone'] as String?,
      parentAvatar: json['parent_avatar'] as String? ?? json['parentAvatar'] as String?,
      childCount: json['child_count'] as int? ?? json['childCount'] as int? ?? 0,
      unreadNotifications: json['unread_notifications'] as int? ?? json['unreadNotifications'] as int? ?? 0,
      unreadMessages: json['unread_messages'] as int? ?? json['unreadMessages'] as int? ?? 0,
      activeInsights: json['active_insights'] as int? ?? json['activeInsights'] as int? ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      upcomingEvents: (json['upcoming_events'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      recentAnnouncements: (json['recent_announcements'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : json['lastActiveAt'] != null
              ? DateTime.parse(json['lastActiveAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'school_id': schoolId,
      'parent_name': parentName,
      'parent_email': parentEmail,
      'parent_phone': parentPhone,
      'parent_avatar': parentAvatar,
      'child_count': childCount,
      'unread_notifications': unreadNotifications,
      'unread_messages': unreadMessages,
      'active_insights': activeInsights,
      'children': children,
      'upcoming_events': upcomingEvents,
      'recent_announcements': recentAnnouncements,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentDashboardModel.fromEntity(ParentDashboardEntity entity) {
    return ParentDashboardModel(
      parentId: entity.parentId,
      schoolId: entity.schoolId,
      parentName: entity.parentName,
      parentEmail: entity.parentEmail,
      parentPhone: entity.parentPhone,
      parentAvatar: entity.parentAvatar,
      childCount: entity.childCount,
      unreadNotifications: entity.unreadNotifications,
      unreadMessages: entity.unreadMessages,
      activeInsights: entity.activeInsights,
      children: entity.children.map((child) => _childSummaryToMap(child)).toList(),
      upcomingEvents: entity.upcomingEvents
          .map((event) => ParentCalendarEventModel.fromEntity(event).toJson())
          .toList(),
      recentAnnouncements: entity.recentAnnouncements
          .map((ann) => _announcementSummaryToMap(ann))
          .toList(),
      lastActiveAt: entity.lastActiveAt,
    );
  }

  ParentDashboardEntity toEntity() {
    return ParentDashboardEntity(
      parentId: parentId,
      schoolId: schoolId,
      parentName: parentName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
      parentAvatar: parentAvatar,
      childCount: childCount,
      unreadNotifications: unreadNotifications,
      unreadMessages: unreadMessages,
      activeInsights: activeInsights,
      children: children.map(_mapToChildSummaryEntity).toList(),
      upcomingEvents: upcomingEvents
          .map((e) => ParentCalendarEventModel.fromJson(e).toEntity())
          .toList(),
      recentAnnouncements: recentAnnouncements
          .map(_mapToAnnouncementSummaryEntity)
          .toList(),
      lastActiveAt: lastActiveAt,
    );
  }

  // ─── Private helpers for nested entity reconstruction ───────────────

  static ChildSummaryEntity _mapToChildSummaryEntity(Map<String, dynamic> map) {
    final attendanceRaw = map['attendance_summary'] as Map<String, dynamic>? ??
        map['attendanceSummary'] as Map<String, dynamic>? ??
        {};
    final latestResultsRaw = map['latest_results'] as List<dynamic>? ??
        map['latestResults'] as List<dynamic>? ??
        [];

    return ChildSummaryEntity(
      studentId: map['student_id'] as String? ?? map['studentId'] as String? ?? '',
      studentName: map['student_name'] as String? ?? map['studentName'] as String? ?? '',
      admissionNumber: map['admission_number'] as String? ?? map['admissionNumber'] as String?,
      className: map['class_name'] as String? ?? map['className'] as String?,
      avatarUrl: map['avatar_url'] as String? ?? map['avatarUrl'] as String?,
      relationship: map['relationship'] as String? ?? '',
      isPrimaryContact: map['is_primary_contact'] as bool? ?? map['isPrimaryContact'] as bool? ?? false,
      attendanceSummary: AttendanceSummaryEntity(
        presentDays: attendanceRaw['present_days'] as int? ?? attendanceRaw['presentDays'] as int? ?? 0,
        absentDays: attendanceRaw['absent_days'] as int? ?? attendanceRaw['absentDays'] as int? ?? 0,
        lateDays: attendanceRaw['late_days'] as int? ?? attendanceRaw['lateDays'] as int? ?? 0,
        excusedDays: attendanceRaw['excused_days'] as int? ?? attendanceRaw['excusedDays'] as int? ?? 0,
        totalDays: attendanceRaw['total_days'] as int? ?? attendanceRaw['totalDays'] as int? ?? 0,
        attendanceRate: (attendanceRaw['attendance_rate'] as num?)?.toDouble() ??
            (attendanceRaw['attendanceRate'] as num?)?.toDouble() ??
            0.0,
      ),
      pendingAssignmentsCount: map['pending_assignments_count'] as int? ??
          map['pendingAssignmentsCount'] as int? ?? 0,
      latestResults: latestResultsRaw
          .map((e) => _mapToChildResultEntity(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  static ChildResultEntity _mapToChildResultEntity(Map<String, dynamic> map) {
    return ChildResultEntity(
      examTitle: map['exam_title'] as String? ?? map['examTitle'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (map['total_marks'] as num?)?.toDouble() ??
          (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? map['subjectName'] as String?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : null,
    );
  }

  static AnnouncementSummaryEntity _mapToAnnouncementSummaryEntity(
    Map<String, dynamic> map,
  ) {
    return AnnouncementSummaryEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'medium',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
    );
  }

  static Map<String, dynamic> _childSummaryToMap(ChildSummaryEntity entity) {
    return {
      'student_id': entity.studentId,
      'student_name': entity.studentName,
      'admission_number': entity.admissionNumber,
      'class_name': entity.className,
      'avatar_url': entity.avatarUrl,
      'relationship': entity.relationship,
      'is_primary_contact': entity.isPrimaryContact,
      'attendance_summary': {
        'present_days': entity.attendanceSummary.presentDays,
        'absent_days': entity.attendanceSummary.absentDays,
        'late_days': entity.attendanceSummary.lateDays,
        'excused_days': entity.attendanceSummary.excusedDays,
        'total_days': entity.attendanceSummary.totalDays,
        'attendance_rate': entity.attendanceSummary.attendanceRate,
      },
      'pending_assignments_count': entity.pendingAssignmentsCount,
      'latest_results': entity.latestResults.map((r) => {
        'exam_title': r.examTitle,
        'score': r.score,
        'total_marks': r.totalMarks,
        'grade': r.grade,
        'subject_name': r.subjectName,
        'date': r.date?.toIso8601String(),
      }).toList(),
    };
  }

  static Map<String, dynamic> _announcementSummaryToMap(
    AnnouncementSummaryEntity entity,
  ) {
    return {
      'id': entity.id,
      'title': entity.title,
      'type': entity.type,
      'priority': entity.priority,
      'created_at': entity.createdAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD PERFORMANCE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a child's academic performance, mapping
/// to the aggregated RPC response from `get_child_performance`.
///
/// Contains nested raw lists that are reconstructed into entity trees
/// in [toEntity].
class ChildPerformanceModel {
  const ChildPerformanceModel({
    required this.studentId,
    this.subjects = const [],
    this.overallAverage,
    this.classAverage,
    this.attendanceRate,
    this.teacherRemarks = const [],
  });

  final String studentId;
  final List<Map<String, dynamic>> subjects;
  final double? overallAverage;
  final double? classAverage;
  final double? attendanceRate;
  final List<Map<String, dynamic>> teacherRemarks;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ChildPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ChildPerformanceModel(
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      overallAverage: (json['overall_average'] as num?)?.toDouble() ??
          (json['overallAverage'] as num?)?.toDouble(),
      classAverage: (json['class_average'] as num?)?.toDouble() ??
          (json['classAverage'] as num?)?.toDouble(),
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ??
          (json['attendanceRate'] as num?)?.toDouble(),
      teacherRemarks: (json['teacher_remarks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['teacherRemarks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'subjects': subjects,
      'overall_average': overallAverage,
      'class_average': classAverage,
      'attendance_rate': attendanceRate,
      'teacher_remarks': teacherRemarks,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ChildPerformanceModel.fromEntity(ChildPerformanceEntity entity) {
    return ChildPerformanceModel(
      studentId: entity.studentId,
      subjects: entity.subjects
          .map((s) => _subjectPerformanceToMap(s))
          .toList(),
      overallAverage: entity.overallAverage,
      classAverage: entity.classAverage,
      attendanceRate: entity.attendanceRate,
      teacherRemarks: entity.teacherRemarks
          .map((r) => _teacherRemarkToMap(r))
          .toList(),
    );
  }

  ChildPerformanceEntity toEntity() {
    return ChildPerformanceEntity(
      studentId: studentId,
      subjects: subjects.map(_mapToSubjectPerformanceEntity).toList(),
      overallAverage: overallAverage,
      classAverage: classAverage,
      attendanceRate: attendanceRate,
      teacherRemarks: teacherRemarks.map(_mapToTeacherRemarkEntity).toList(),
    );
  }

  // ─── Private helpers for nested entity reconstruction ───────────────

  static SubjectPerformanceEntity _mapToSubjectPerformanceEntity(
    Map<String, dynamic> map,
  ) {
    return SubjectPerformanceEntity(
      subjectId: map['subject_id'] as String? ?? map['subjectId'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? map['subjectName'] as String? ?? '',
      teacherName: map['teacher_name'] as String? ?? map['teacherName'] as String?,
      latestScore: (map['latest_score'] as num?)?.toDouble() ??
          (map['latestScore'] as num?)?.toDouble(),
      averageScore: (map['average_score'] as num?)?.toDouble() ??
          (map['averageScore'] as num?)?.toDouble(),
      grade: map['grade'] as String?,
    );
  }

  static TeacherRemarkEntity _mapToTeacherRemarkEntity(
    Map<String, dynamic> map,
  ) {
    return TeacherRemarkEntity(
      teacherName: map['teacher_name'] as String? ?? map['teacherName'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      remark: map['remark'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> _subjectPerformanceToMap(
    SubjectPerformanceEntity entity,
  ) {
    return {
      'subject_id': entity.subjectId,
      'subject_name': entity.subjectName,
      'teacher_name': entity.teacherName,
      'latest_score': entity.latestScore,
      'average_score': entity.averageScore,
      'grade': entity.grade,
    };
  }

  static Map<String, dynamic> _teacherRemarkToMap(TeacherRemarkEntity entity) {
    return {
      'teacher_name': entity.teacherName,
      'subject': entity.subject,
      'remark': entity.remark,
      'date': entity.date.toIso8601String(),
    };
  }
}
