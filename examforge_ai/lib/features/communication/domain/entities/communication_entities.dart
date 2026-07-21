import 'package:equatable/equatable.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

enum ConversationType {
  direct(value: 'direct', label: 'Direct Message'),
  group(value: 'group', label: 'Group Chat'),
  department(value: 'department', label: 'Department Chat'),
  classChat(value: 'class', label: 'Class Chat'),
  schoolWide(value: 'school_wide', label: 'School-wide Channel');

  const ConversationType({required this.value, required this.label});
  final String value;
  final String label;

  static ConversationType? fromString(String? v) {
    if (v == null) return null;
    return ConversationType.values.cast<ConversationType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum MessageType {
  text(value: 'text', label: 'Text'),
  image(value: 'image', label: 'Image'),
  pdf(value: 'pdf', label: 'PDF'),
  document(value: 'document', label: 'Document'),
  voiceNote(value: 'voice_note', label: 'Voice Note'),
  audio(value: 'audio', label: 'Audio'),
  video(value: 'video', label: 'Video'),
  system(value: 'system', label: 'System');

  const MessageType({required this.value, required this.label});
  final String value;
  final String label;

  static MessageType? fromString(String? v) {
    if (v == null) return null;
    return MessageType.values.cast<MessageType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum AnnouncementType {
  schoolWide(value: 'school_wide', label: 'School-wide'),
  classAnnouncement(value: 'class', label: 'Class'),
  subject(value: 'subject', label: 'Subject'),
  emergency(value: 'emergency', label: 'Emergency Alert'),
  event(value: 'event', label: 'Event'),
  holiday(value: 'holiday', label: 'Holiday'),
  timetableUpdate(value: 'timetable_update', label: 'Timetable Update'),
  examination(value: 'examination', label: 'Examination'),
  general(value: 'general', label: 'General');

  const AnnouncementType({required this.value, required this.label});
  final String value;
  final String label;

  static AnnouncementType? fromString(String? v) {
    if (v == null) return null;
    return AnnouncementType.values.cast<AnnouncementType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum AnnouncementPriority {
  low(value: 'low', label: 'Low'),
  normal(value: 'normal', label: 'Normal'),
  high(value: 'high', label: 'High'),
  urgent(value: 'urgent', label: 'Urgent');

  const AnnouncementPriority({required this.value, required this.label});
  final String value;
  final String label;

  static AnnouncementPriority? fromString(String? v) {
    if (v == null) return null;
    return AnnouncementPriority.values.cast<AnnouncementPriority?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum ForumType {
  schoolCommunity(value: 'school_community', label: 'School Community'),
  subject(value: 'subject', label: 'Subject'),
  classForum(value: 'class', label: 'Class'),
  club(value: 'club', label: 'Club'),
  department(value: 'department', label: 'Department');

  const ForumType({required this.value, required this.label});
  final String value;
  final String label;

  static ForumType? fromString(String? v) {
    if (v == null) return null;
    return ForumType.values.cast<ForumType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum CalendarEventType {
  meeting(value: 'meeting', label: 'Meeting'),
  parentTeacher(value: 'parent_teacher', label: 'Parent-Teacher'),
  academic(value: 'academic', label: 'Academic'),
  exam(value: 'exam', label: 'Exam'),
  holiday(value: 'holiday', label: 'Holiday'),
  event(value: 'event', label: 'Event'),
  deadline(value: 'deadline', label: 'Deadline'),
  custom(value: 'custom', label: 'Custom');

  const CalendarEventType({required this.value, required this.label});
  final String value;
  final String label;

  static CalendarEventType? fromString(String? v) {
    if (v == null) return null;
    return CalendarEventType.values.cast<CalendarEventType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum MeetingStatus {
  scheduled(value: 'scheduled', label: 'Scheduled'),
  confirmed(value: 'confirmed', label: 'Confirmed'),
  inProgress(value: 'in_progress', label: 'In Progress'),
  completed(value: 'completed', label: 'Completed'),
  cancelled(value: 'cancelled', label: 'Cancelled'),
  rescheduled(value: 'rescheduled', label: 'Rescheduled');

  const MeetingStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MeetingStatus? fromString(String? v) {
    if (v == null) return null;
    return MeetingStatus.values.cast<MeetingStatus?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum AttachmentType {
  pdf(value: 'pdf', label: 'PDF'),
  docx(value: 'docx', label: 'DOCX'),
  pptx(value: 'pptx', label: 'PPTX'),
  xlsx(value: 'xlsx', label: 'XLSX'),
  image(value: 'image', label: 'Image'),
  video(value: 'video', label: 'Video'),
  audio(value: 'audio', label: 'Audio'),
  other(value: 'other', label: 'Other');

  const AttachmentType({required this.value, required this.label});
  final String value;
  final String label;

  static AttachmentType? fromString(String? v) {
    if (v == null) return null;
    return AttachmentType.values.cast<AttachmentType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

enum NotificationCategory {
  message(value: 'message', label: 'Message'),
  assignment(value: 'assignment', label: 'Assignment'),
  exam(value: 'exam', label: 'Exam'),
  result(value: 'result', label: 'Result'),
  attendance(value: 'attendance', label: 'Attendance'),
  announcement(value: 'announcement', label: 'Announcement'),
  system(value: 'system', label: 'System'),
  payment(value: 'payment', label: 'Payment'),
  general(value: 'general', label: 'General');

  const NotificationCategory({required this.value, required this.label});
  final String value;
  final String label;

  static NotificationCategory? fromString(String? v) {
    if (v == null) return null;
    return NotificationCategory.values.cast<NotificationCategory?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION ENTITY
// ═══════════════════════════════════════════════════════════════════════

class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.schoolId,
    this.type = ConversationType.direct,
    this.name,
    this.description,
    this.avatarUrl,
    this.departmentId,
    this.classId,
    this.subjectId,
    this.isMuted = false,
    this.isArchived = false,
    this.isPinned = false,
    required this.createdBy,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastSenderId,
    this.lastSenderName,
    this.participants = const [],
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final ConversationType type;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? departmentId;
  final String? classId;
  final String? subjectId;
  final bool isMuted;
  final bool isArchived;
  final bool isPinned;
  final String createdBy;
  final String? lastMessageId;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final String? lastSenderName;
  final List<ConversationParticipantEntity> participants;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationEntity copyWith({
    String? id,
    String? schoolId,
    ConversationType? type,
    String? name,
    String? description,
    String? avatarUrl,
    String? departmentId,
    String? classId,
    String? subjectId,
    bool? isMuted,
    bool? isArchived,
    bool? isPinned,
    String? createdBy,
    String? lastMessageId,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastSenderId,
    String? lastSenderName,
    List<ConversationParticipantEntity>? participants,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      departmentId: departmentId ?? this.departmentId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      createdBy: createdBy ?? this.createdBy,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, type, name, unreadCount, lastMessageAt];
}

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION PARTICIPANT ENTITY
// ═══════════════════════════════════════════════════════════════════════

class ConversationParticipantEntity extends Equatable {
  const ConversationParticipantEntity({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.schoolId,
    this.role = 'member',
    required this.userRole,
    this.isMuted = false,
    this.isArchived = false,
    this.isPinned = false,
    this.isBlocked = false,
    this.lastReadMessageId,
    this.lastReadAt,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingAt,
    this.isOnline = false,
    this.lastSeenAt,
    required this.joinedAt,
    this.leftAt,
    this.userName,
    this.userAvatar,
  });

  final String id;
  final String conversationId;
  final String userId;
  final String schoolId;
  final String role;
  final String userRole;
  final bool isMuted;
  final bool isArchived;
  final bool isPinned;
  final bool isBlocked;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  final int unreadCount;
  final bool isTyping;
  final DateTime? typingAt;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? userName;
  final String? userAvatar;

  ConversationParticipantEntity copyWith({
    String? id,
    String? conversationId,
    String? userId,
    String? schoolId,
    String? role,
    String? userRole,
    bool? isMuted,
    bool? isArchived,
    bool? isPinned,
    bool? isBlocked,
    String? lastReadMessageId,
    DateTime? lastReadAt,
    int? unreadCount,
    bool? isTyping,
    DateTime? typingAt,
    bool? isOnline,
    DateTime? lastSeenAt,
    DateTime? joinedAt,
    DateTime? leftAt,
    String? userName,
    String? userAvatar,
  }) {
    return ConversationParticipantEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      userRole: userRole ?? this.userRole,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      isBlocked: isBlocked ?? this.isBlocked,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      typingAt: typingAt ?? this.typingAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, userId, unreadCount, isOnline];
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE ENTITY
// ═══════════════════════════════════════════════════════════════════════

class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.schoolId,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    this.senderAvatar,
    this.type = MessageType.text,
    this.body = '',
    this.replyToId,
    this.forwardedFromId,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.metadata = const {},
    this.reactions = const [],
    this.attachments = const [],
    this.replyTo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String body;
  final String? replyToId;
  final String? forwardedFromId;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final List<String> readBy;
  final List<String> deliveredTo;
  final Map<String, dynamic> metadata;
  final List<MessageReactionEntity> reactions;
  final List<MessageAttachmentEntity> attachments;
  final MessageEntity? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageEntity copyWith({
    String? id,
    String? schoolId,
    String? conversationId,
    String? senderId,
    String? senderRole,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? body,
    String? replyToId,
    String? forwardedFromId,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    List<String>? readBy,
    List<String>? deliveredTo,
    Map<String, dynamic>? metadata,
    List<MessageReactionEntity>? reactions,
    List<MessageAttachmentEntity>? attachments,
    MessageEntity? replyTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      body: body ?? this.body,
      replyToId: replyToId ?? this.replyToId,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, body, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE REACTION ENTITY
// ═══════════════════════════════════════════════════════════════════════

class MessageReactionEntity extends Equatable {
  const MessageReactionEntity({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, messageId, userId, emoji];
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE ATTACHMENT ENTITY
// ═══════════════════════════════════════════════════════════════════════

class MessageAttachmentEntity extends Equatable {
  const MessageAttachmentEntity({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.fileUrl,
    this.fileType = AttachmentType.other,
    this.fileSizeBytes,
    this.mimeType,
    this.thumbnailUrl,
    this.previewText,
    this.isPreviewable = false,
    required this.uploadedBy,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String fileName;
  final String fileUrl;
  final AttachmentType fileType;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? thumbnailUrl;
  final String? previewText;
  final bool isPreviewable;
  final String uploadedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, messageId, fileUrl];
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT ENTITY
// ═══════════════════════════════════════════════════════════════════════

class AnnouncementEntity extends Equatable {
  const AnnouncementEntity({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    this.announcementType = AnnouncementType.general,
    this.priority = AnnouncementPriority.normal,
    this.targetAudience = ['all'],
    this.targetClassIds = const [],
    this.targetDepartmentIds = const [],
    this.targetSubjectIds = const [],
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.isScheduled = false,
    this.scheduledAt,
    this.expiresAt,
    this.isPinned = false,
    this.attachments = const [],
    this.isPublished = false,
    this.publishedAt,
    this.viewCount = 0,
    this.acknowledgedBy = const [],
    this.isAiGenerated = false,
    this.aiReviewed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String body;
  final AnnouncementType announcementType;
  final AnnouncementPriority priority;
  final List<String> targetAudience;
  final List<String> targetClassIds;
  final List<String> targetDepartmentIds;
  final List<String> targetSubjectIds;
  final String authorId;
  final String authorName;
  final String authorRole;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final bool isPinned;
  final List<Map<String, dynamic>> attachments;
  final bool isPublished;
  final DateTime? publishedAt;
  final int viewCount;
  final List<String> acknowledgedBy;
  final bool isAiGenerated;
  final bool aiReviewed;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementEntity copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? body,
    AnnouncementType? announcementType,
    AnnouncementPriority? priority,
    List<String>? targetAudience,
    List<String>? targetClassIds,
    List<String>? targetDepartmentIds,
    List<String>? targetSubjectIds,
    String? authorId,
    String? authorName,
    String? authorRole,
    bool? isScheduled,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    bool? isPinned,
    List<Map<String, dynamic>>? attachments,
    bool? isPublished,
    DateTime? publishedAt,
    int? viewCount,
    List<String>? acknowledgedBy,
    bool? isAiGenerated,
    bool? aiReviewed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      body: body ?? this.body,
      announcementType: announcementType ?? this.announcementType,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      targetClassIds: targetClassIds ?? this.targetClassIds,
      targetDepartmentIds: targetDepartmentIds ?? this.targetDepartmentIds,
      targetSubjectIds: targetSubjectIds ?? this.targetSubjectIds,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPinned: isPinned ?? this.isPinned,
      attachments: attachments ?? this.attachments,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiReviewed: aiReviewed ?? this.aiReviewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, title, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION NOTIFICATION ENTITY
// ═══════════════════════════════════════════════════════════════════════

class CommunicationNotificationEntity extends Equatable {
  const CommunicationNotificationEntity({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.title,
    required this.body,
    this.category = NotificationCategory.general,
    this.priority = 'normal',
    this.sourceType,
    this.sourceId,
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
  final String userId;
  final String title;
  final String body;
  final NotificationCategory category;
  final String priority;
  final String? sourceType;
  final String? sourceId;
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

  CommunicationNotificationEntity copyWith({
    String? id,
    String? schoolId,
    String? userId,
    String? title,
    String? body,
    NotificationCategory? category,
    String? priority,
    String? sourceType,
    String? sourceId,
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
    return CommunicationNotificationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
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
  List<Object?> get props => [id, userId, title, isRead, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION PREFERENCES ENTITY
// ═══════════════════════════════════════════════════════════════════════

class NotificationPreferencesEntity extends Equatable {
  const NotificationPreferencesEntity({
    required this.id,
    required this.userId,
    required this.schoolId,
    this.preferences = const {},
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.digestEnabled = false,
    this.digestFrequency = 'daily',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String schoolId;
  final Map<String, dynamic> preferences;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool digestEnabled;
  final String digestFrequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferencesEntity copyWith({
    String? id,
    String? userId,
    String? schoolId,
    Map<String, dynamic>? preferences,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? digestEnabled,
    String? digestFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      preferences: preferences ?? this.preferences,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      digestEnabled: digestEnabled ?? this.digestEnabled,
      digestFrequency: digestFrequency ?? this.digestFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, schoolId];
}

// ═══════════════════════════════════════════════════════════════════════
// DISCUSSION FORUM ENTITY
// ═══════════════════════════════════════════════════════════════════════

class DiscussionForumEntity extends Equatable {
  const DiscussionForumEntity({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    this.forumType = ForumType.schoolCommunity,
    this.avatarUrl,
    this.departmentId,
    this.classId,
    this.subjectId,
    this.isModerated = true,
    this.isLocked = false,
    this.isPinned = false,
    this.moderatorIds = const [],
    required this.createdBy,
    this.postCount = 0,
    this.memberCount = 0,
    this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String? description;
  final ForumType forumType;
  final String? avatarUrl;
  final String? departmentId;
  final String? classId;
  final String? subjectId;
  final bool isModerated;
  final bool isLocked;
  final bool isPinned;
  final List<String> moderatorIds;
  final String createdBy;
  final int postCount;
  final int memberCount;
  final DateTime? lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiscussionForumEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? description,
    ForumType? forumType,
    String? avatarUrl,
    String? departmentId,
    String? classId,
    String? subjectId,
    bool? isModerated,
    bool? isLocked,
    bool? isPinned,
    List<String>? moderatorIds,
    String? createdBy,
    int? postCount,
    int? memberCount,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiscussionForumEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      description: description ?? this.description,
      forumType: forumType ?? this.forumType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      departmentId: departmentId ?? this.departmentId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      isModerated: isModerated ?? this.isModerated,
      isLocked: isLocked ?? this.isLocked,
      isPinned: isPinned ?? this.isPinned,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      createdBy: createdBy ?? this.createdBy,
      postCount: postCount ?? this.postCount,
      memberCount: memberCount ?? this.memberCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, name];
}

// ═══════════════════════════════════════════════════════════════════════
// FORUM POST ENTITY
// ═══════════════════════════════════════════════════════════════════════

class ForumPostEntity extends Equatable {
  const ForumPostEntity({
    required this.id,
    required this.forumId,
    required this.schoolId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.authorRole,
    required this.title,
    required this.body,
    this.attachments = const [],
    this.isPinned = false,
    this.isLocked = false,
    this.isHidden = false,
    this.hiddenReason,
    this.commentCount = 0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.reportedCount = 0,
    this.isReported = false,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String forumId;
  final String schoolId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String title;
  final String body;
  final List<Map<String, dynamic>> attachments;
  final bool isPinned;
  final bool isLocked;
  final bool isHidden;
  final String? hiddenReason;
  final int commentCount;
  final int viewCount;
  final int likeCount;
  final int reportedCount;
  final bool isReported;
  final List<ForumCommentEntity> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ForumPostEntity copyWith({
    String? id,
    String? forumId,
    String? schoolId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
    String? title,
    String? body,
    List<Map<String, dynamic>>? attachments,
    bool? isPinned,
    bool? isLocked,
    bool? isHidden,
    String? hiddenReason,
    int? commentCount,
    int? viewCount,
    int? likeCount,
    int? reportedCount,
    bool? isReported,
    List<ForumCommentEntity>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForumPostEntity(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      schoolId: schoolId ?? this.schoolId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      title: title ?? this.title,
      body: body ?? this.body,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      reportedCount: reportedCount ?? this.reportedCount,
      isReported: isReported ?? this.isReported,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, forumId, title, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// FORUM COMMENT ENTITY
// ═══════════════════════════════════════════════════════════════════════

class ForumCommentEntity extends Equatable {
  const ForumCommentEntity({
    required this.id,
    required this.postId,
    required this.forumId,
    required this.schoolId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.authorRole,
    required this.body,
    this.parentCommentId,
    this.replyToUserId,
    this.attachments = const [],
    this.isHidden = false,
    this.hiddenReason,
    this.likeCount = 0,
    this.reportedCount = 0,
    this.isReported = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String postId;
  final String forumId;
  final String schoolId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String body;
  final String? parentCommentId;
  final String? replyToUserId;
  final List<Map<String, dynamic>> attachments;
  final bool isHidden;
  final String? hiddenReason;
  final int likeCount;
  final int reportedCount;
  final bool isReported;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, postId, body, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR EVENT ENTITY
// ═══════════════════════════════════════════════════════════════════════

class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    this.eventType = CalendarEventType.custom,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
    this.meetingLink,
    this.isRecurring = false,
    this.recurrenceRule,
    required this.organizerId,
    required this.organizerName,
    this.targetAudience = ['all'],
    this.targetClassIds = const [],
    this.targetDepartmentIds = const [],
    this.attendeeIds = const [],
    this.rsvpRequired = false,
    this.meetingStatus = MeetingStatus.scheduled,
    this.maxAttendees,
    this.currentAttendees,
    this.sourceType,
    this.sourceId,
    this.reminderMinutes = [15, 60],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final CalendarEventType eventType;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? location;
  final String? meetingLink;
  final bool isRecurring;
  final String? recurrenceRule;
  final String organizerId;
  final String organizerName;
  final List<String> targetAudience;
  final List<String> targetClassIds;
  final List<String> targetDepartmentIds;
  final List<String> attendeeIds;
  final bool rsvpRequired;
  final MeetingStatus meetingStatus;
  final int? maxAttendees;
  final int? currentAttendees;
  final String? sourceType;
  final String? sourceId;
  final List<int> reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEventEntity copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? description,
    CalendarEventType? eventType,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? meetingLink,
    bool? isRecurring,
    String? recurrenceRule,
    String? organizerId,
    String? organizerName,
    List<String>? targetAudience,
    List<String>? targetClassIds,
    List<String>? targetDepartmentIds,
    List<String>? attendeeIds,
    bool? rsvpRequired,
    MeetingStatus? meetingStatus,
    int? maxAttendees,
    int? currentAttendees,
    String? sourceType,
    String? sourceId,
    List<int>? reminderMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      targetAudience: targetAudience ?? this.targetAudience,
      targetClassIds: targetClassIds ?? this.targetClassIds,
      targetDepartmentIds: targetDepartmentIds ?? this.targetDepartmentIds,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      rsvpRequired: rsvpRequired ?? this.rsvpRequired,
      meetingStatus: meetingStatus ?? this.meetingStatus,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, title, startTime];
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION AUDIT LOG ENTITY
// ═══════════════════════════════════════════════════════════════════════

class CommunicationAuditLogEntity extends Equatable {
  const CommunicationAuditLogEntity({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.userRole,
    required this.userName,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.details = const {},
    this.severity = 'info',
    this.ipAddress,
    this.userAgent,
    this.deviceType,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String userId;
  final String userRole;
  final String userName;
  final String action;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic> details;
  final String severity;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, action, createdAt];
}

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL KNOWLEDGE DOCUMENT ENTITY (AI Knowledge Assistant)
// ═══════════════════════════════════════════════════════════════════════

class SchoolKnowledgeDocumentEntity extends Equatable {
  const SchoolKnowledgeDocumentEntity({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    this.documentType = 'policy',
    required this.fileName,
    required this.fileUrl,
    this.fileSizeBytes,
    this.mimeType,
    this.status = 'pending',
    this.processingError,
    this.chunkCount = 0,
    this.extractedText,
    this.tags = const [],
    this.isActive = true,
    this.version = 1,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final int? fileSizeBytes;
  final String? mimeType;
  final String status;
  final String? processingError;
  final int chunkCount;
  final String? extractedText;
  final List<String> tags;
  final bool isActive;
  final int version;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, schoolId, title, documentType];
}

// ═══════════════════════════════════════════════════════════════════════
// AI COMMUNICATION ASSISTANT RESPONSE ENTITY
// ═══════════════════════════════════════════════════════════════════════

class AiCommunicationAssistantEntity extends Equatable {
  const AiCommunicationAssistantEntity({
    required this.id,
    required this.type,
    required this.content,
    this.suggestions = const [],
    this.tone,
    this.language,
    this.confidence = 0.0,
    this.requiresReview = true,
    required this.createdAt,
  });

  final String id;
  final String type; // draft_announcement, rewrite, summarize, translate, suggest_reply, grammar, tone_adjust
  final String content;
  final List<String> suggestions;
  final String? tone;
  final String? language;
  final double confidence;
  final bool requiresReview;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, content];
}

// ═══════════════════════════════════════════════════════════════════════
// AI SCHOOL KNOWLEDGE RESPONSE ENTITY
// ═══════════════════════════════════════════════════════════════════════

class AiSchoolKnowledgeResponseEntity extends Equatable {
  const AiSchoolKnowledgeResponseEntity({
    required this.id,
    required this.query,
    required this.answer,
    this.sources = const [],
    this.confidence = 0.0,
    this.isGrounded = false,
    required this.createdAt,
  });

  final String id;
  final String query;
  final String answer;
  final List<KnowledgeSourceEntity> sources;
  final double confidence;
  final bool isGrounded;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, query, answer];
}

// ═══════════════════════════════════════════════════════════════════════
// KNOWLEDGE SOURCE ENTITY
// ═══════════════════════════════════════════════════════════════════════

class KnowledgeSourceEntity extends Equatable {
  const KnowledgeSourceEntity({
    required this.documentId,
    required this.title,
    required this.documentType,
    this.relevance = 0.0,
    this.snippet,
  });

  final String documentId;
  final String title;
  final String documentType;
  final double relevance;
  final String? snippet;

  @override
  List<Object?> get props => [documentId, title];
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION DASHBOARD ENTITY
// ═══════════════════════════════════════════════════════════════════════

class CommunicationDashboardEntity extends Equatable {
  const CommunicationDashboardEntity({
    required this.schoolId,
    this.totalConversations = 0,
    this.activeConversations = 0,
    this.totalMessagesToday = 0,
    this.totalAnnouncements = 0,
    this.unreadNotifications = 0,
    this.upcomingEvents = const [],
    this.activeForums = 0,
    this.knowledgeDocuments = 0,
  });

  final String schoolId;
  final int totalConversations;
  final int activeConversations;
  final int totalMessagesToday;
  final int totalAnnouncements;
  final int unreadNotifications;
  final List<Map<String, dynamic>> upcomingEvents;
  final int activeForums;
  final int knowledgeDocuments;

  @override
  List<Object?> get props => [schoolId];
}
