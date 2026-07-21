import '../../domain/entities/communication_entities.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart' hide AnnouncementEntity, AnnouncementPriority, AnnouncementType, CalendarEventEntity, CalendarEventType;


// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a conversation, mapping to the
/// `conversations` table.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.schoolId,
    this.type = 'direct',
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
  final String type;
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
  final List<ConversationParticipantModel> participants;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      type: json['type'] as String? ?? json['type'] as String? ?? 'direct',
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      departmentId: json['department_id'] as String? ?? json['departmentId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      isMuted: json['is_muted'] as bool? ?? json['isMuted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? json['isArchived'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
      lastMessageId: json['last_message_id'] as String? ?? json['lastMessageId'] as String?,
      lastMessageText: json['last_message_text'] as String? ?? json['lastMessageText'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : json['lastMessageAt'] != null
              ? DateTime.parse(json['lastMessageAt'] as String)
              : null,
      lastSenderId: json['last_sender_id'] as String? ?? json['lastSenderId'] as String?,
      lastSenderName: json['last_sender_name'] as String? ?? json['lastSenderName'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ConversationParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      unreadCount: json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
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
      'type': type,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'department_id': departmentId,
      'class_id': classId,
      'subject_id': subjectId,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'is_pinned': isPinned,
      'created_by': createdBy,
      'last_message_id': lastMessageId,
      'last_message_text': lastMessageText,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_sender_id': lastSenderId,
      'last_sender_name': lastSenderName,
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ConversationModel.fromEntity(ConversationEntity entity) {
    return ConversationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      type: entity.type.value,
      name: entity.name,
      description: entity.description,
      avatarUrl: entity.avatarUrl,
      departmentId: entity.departmentId,
      classId: entity.classId,
      subjectId: entity.subjectId,
      isMuted: entity.isMuted,
      isArchived: entity.isArchived,
      isPinned: entity.isPinned,
      createdBy: entity.createdBy,
      lastMessageId: entity.lastMessageId,
      lastMessageText: entity.lastMessageText,
      lastMessageAt: entity.lastMessageAt,
      lastSenderId: entity.lastSenderId,
      lastSenderName: entity.lastSenderName,
      participants: entity.participants
          .map((p) => ConversationParticipantModel.fromEntity(p))
          .toList(),
      unreadCount: entity.unreadCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      schoolId: schoolId,
      type: ConversationType.fromString(type) ?? ConversationType.direct,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      departmentId: departmentId,
      classId: classId,
      subjectId: subjectId,
      isMuted: isMuted,
      isArchived: isArchived,
      isPinned: isPinned,
      createdBy: createdBy,
      lastMessageId: lastMessageId,
      lastMessageText: lastMessageText,
      lastMessageAt: lastMessageAt,
      lastSenderId: lastSenderId,
      lastSenderName: lastSenderName,
      participants: participants.map((p) => p.toEntity()).toList(),
      unreadCount: unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  ConversationModel copyWith({
    String? id,
    String? schoolId,
    String? type,
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
    List<ConversationParticipantModel>? participants,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          type == other.type &&
          unreadCount == other.unreadCount &&
          lastMessageAt == other.lastMessageAt;

  @override
  int get hashCode => Object.hash(id, schoolId, type, unreadCount, lastMessageAt);

  @override
  String toString() => 'ConversationModel(id: $id, type: $type, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION PARTICIPANT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a conversation participant, mapping to the
/// `conversation_participants` table.
class ConversationParticipantModel {
  const ConversationParticipantModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) {
    return ConversationParticipantModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String? ?? json['conversationId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      userRole: json['user_role'] as String? ?? json['userRole'] as String? ?? '',
      isMuted: json['is_muted'] as bool? ?? json['isMuted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? json['isArchived'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? json['isBlocked'] as bool? ?? false,
      lastReadMessageId: json['last_read_message_id'] as String? ?? json['lastReadMessageId'] as String?,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : json['lastReadAt'] != null
              ? DateTime.parse(json['lastReadAt'] as String)
              : null,
      unreadCount: json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
      isTyping: json['is_typing'] as bool? ?? json['isTyping'] as bool? ?? false,
      typingAt: json['typing_at'] != null
          ? DateTime.parse(json['typing_at'] as String)
          : json['typingAt'] != null
              ? DateTime.parse(json['typingAt'] as String)
              : null,
      isOnline: json['is_online'] as bool? ?? json['isOnline'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : json['lastSeenAt'] != null
              ? DateTime.parse(json['lastSeenAt'] as String)
              : null,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : json['joinedAt'] != null
              ? DateTime.parse(json['joinedAt'] as String)
              : DateTime.now(),
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'] as String)
          : json['leftAt'] != null
              ? DateTime.parse(json['leftAt'] as String)
              : null,
      userName: json['user_name'] as String? ?? json['userName'] as String?,
      userAvatar: json['user_avatar'] as String? ?? json['userAvatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'school_id': schoolId,
      'role': role,
      'user_role': userRole,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'is_pinned': isPinned,
      'is_blocked': isBlocked,
      'last_read_message_id': lastReadMessageId,
      'last_read_at': lastReadAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_typing': isTyping,
      'typing_at': typingAt?.toIso8601String(),
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'user_name': userName,
      'user_avatar': userAvatar,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ConversationParticipantModel.fromEntity(ConversationParticipantEntity entity) {
    return ConversationParticipantModel(
      id: entity.id,
      conversationId: entity.conversationId,
      userId: entity.userId,
      schoolId: entity.schoolId,
      role: entity.role,
      userRole: entity.userRole,
      isMuted: entity.isMuted,
      isArchived: entity.isArchived,
      isPinned: entity.isPinned,
      isBlocked: entity.isBlocked,
      lastReadMessageId: entity.lastReadMessageId,
      lastReadAt: entity.lastReadAt,
      unreadCount: entity.unreadCount,
      isTyping: entity.isTyping,
      typingAt: entity.typingAt,
      isOnline: entity.isOnline,
      lastSeenAt: entity.lastSeenAt,
      joinedAt: entity.joinedAt,
      leftAt: entity.leftAt,
      userName: entity.userName,
      userAvatar: entity.userAvatar,
    );
  }

  ConversationParticipantEntity toEntity() {
    return ConversationParticipantEntity(
      id: id,
      conversationId: conversationId,
      userId: userId,
      schoolId: schoolId,
      role: role,
      userRole: userRole,
      isMuted: isMuted,
      isArchived: isArchived,
      isPinned: isPinned,
      isBlocked: isBlocked,
      lastReadMessageId: lastReadMessageId,
      lastReadAt: lastReadAt,
      unreadCount: unreadCount,
      isTyping: isTyping,
      typingAt: typingAt,
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
      joinedAt: joinedAt,
      leftAt: leftAt,
      userName: userName,
      userAvatar: userAvatar,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  ConversationParticipantModel copyWith({
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
    return ConversationParticipantModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationParticipantModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          userId == other.userId &&
          unreadCount == other.unreadCount &&
          isOnline == other.isOnline;

  @override
  int get hashCode => Object.hash(id, conversationId, userId, unreadCount, isOnline);

  @override
  String toString() => 'ConversationParticipantModel(id: $id, userId: $userId)';
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a message, mapping to the
/// `messages` table.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.schoolId,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    this.senderAvatar,
    this.type = 'text',
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
  final String type;
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
  final List<MessageReactionModel> reactions;
  final List<MessageAttachmentModel> attachments;
  final MessageModel? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? json['conversationId'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? json['senderRole'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? json['senderName'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String? ?? json['senderAvatar'] as String?,
      type: json['type'] as String? ?? 'text',
      body: json['body'] as String? ?? '',
      replyToId: json['reply_to_id'] as String? ?? json['replyToId'] as String?,
      forwardedFromId: json['forwarded_from_id'] as String? ?? json['forwardedFromId'] as String?,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'] as String)
          : json['pinnedAt'] != null
              ? DateTime.parse(json['pinnedAt'] as String)
              : null,
      pinnedBy: json['pinned_by'] as String? ?? json['pinnedBy'] as String?,
      isEdited: json['is_edited'] as bool? ?? json['isEdited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : json['editedAt'] != null
              ? DateTime.parse(json['editedAt'] as String)
              : null,
      isDeleted: json['is_deleted'] as bool? ?? json['isDeleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : json['deletedAt'] != null
              ? DateTime.parse(json['deletedAt'] as String)
              : null,
      deletedBy: json['deleted_by'] as String? ?? json['deletedBy'] as String?,
      readBy: (json['read_by'] as List<dynamic>?)?.cast<String>() ?? const [],
      deliveredTo: (json['delivered_to'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MessageAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      replyTo: json['reply_to'] != null
          ? MessageModel.fromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
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
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'type': type,
      'body': body,
      'reply_to_id': replyToId,
      'forwarded_from_id': forwardedFromId,
      'is_pinned': isPinned,
      'pinned_at': pinnedAt?.toIso8601String(),
      'pinned_by': pinnedBy,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      'read_by': readBy,
      'delivered_to': deliveredTo,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      schoolId: entity.schoolId,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      senderRole: entity.senderRole,
      senderName: entity.senderName,
      senderAvatar: entity.senderAvatar,
      type: entity.type.value,
      body: entity.body,
      replyToId: entity.replyToId,
      forwardedFromId: entity.forwardedFromId,
      isPinned: entity.isPinned,
      pinnedAt: entity.pinnedAt,
      pinnedBy: entity.pinnedBy,
      isEdited: entity.isEdited,
      editedAt: entity.editedAt,
      isDeleted: entity.isDeleted,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
      readBy: entity.readBy,
      deliveredTo: entity.deliveredTo,
      metadata: entity.metadata,
      reactions: entity.reactions.map((r) => MessageReactionModel.fromEntity(r)).toList(),
      attachments: entity.attachments.map((a) => MessageAttachmentModel.fromEntity(a)).toList(),
      replyTo: entity.replyTo != null ? MessageModel.fromEntity(entity.replyTo!) : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      schoolId: schoolId,
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.fromString(type) ?? MessageType.text,
      body: body,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      isPinned: isPinned,
      pinnedAt: pinnedAt,
      pinnedBy: pinnedBy,
      isEdited: isEdited,
      editedAt: editedAt,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      readBy: readBy,
      deliveredTo: deliveredTo,
      metadata: metadata,
      reactions: reactions.map((r) => r.toEntity()).toList(),
      attachments: attachments.map((a) => a.toEntity()).toList(),
      replyTo: replyTo?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  MessageModel copyWith({
    String? id,
    String? schoolId,
    String? conversationId,
    String? senderId,
    String? senderRole,
    String? senderName,
    String? senderAvatar,
    String? type,
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
    List<MessageReactionModel>? reactions,
    List<MessageAttachmentModel>? attachments,
    MessageModel? replyTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          body == other.body &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, conversationId, senderId, body, createdAt);

  @override
  String toString() => 'MessageModel(id: $id, type: $type, sender: $senderName)';
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE REACTION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a message reaction, mapping to the
/// `message_reactions` table.
class MessageReactionModel {
  const MessageReactionModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String? ?? json['messageId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
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
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory MessageReactionModel.fromEntity(MessageReactionEntity entity) {
    return MessageReactionModel(
      id: entity.id,
      messageId: entity.messageId,
      userId: entity.userId,
      emoji: entity.emoji,
      createdAt: entity.createdAt,
    );
  }

  MessageReactionEntity toEntity() {
    return MessageReactionEntity(
      id: id,
      messageId: messageId,
      userId: userId,
      emoji: emoji,
      createdAt: createdAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  MessageReactionModel copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) {
    return MessageReactionModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageReactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messageId == other.messageId &&
          userId == other.userId &&
          emoji == other.emoji;

  @override
  int get hashCode => Object.hash(id, messageId, userId, emoji);

  @override
  String toString() => 'MessageReactionModel(id: $id, emoji: $emoji)';
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE ATTACHMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a message attachment, mapping to the
/// `message_attachments` table.
class MessageAttachmentModel {
  const MessageAttachmentModel({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'other',
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
  final String fileType;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? thumbnailUrl;
  final String? previewText;
  final bool isPreviewable;
  final String uploadedBy;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String? ?? json['messageId'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileType: json['file_type'] as String? ?? json['fileType'] as String? ?? 'other',
      fileSizeBytes: json['file_size_bytes'] as int? ?? json['fileSizeBytes'] as int?,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      previewText: json['preview_text'] as String? ?? json['previewText'] as String?,
      isPreviewable: json['is_previewable'] as bool? ?? json['isPreviewable'] as bool? ?? false,
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String? ?? '',
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
      'message_id': messageId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'thumbnail_url': thumbnailUrl,
      'preview_text': previewText,
      'is_previewable': isPreviewable,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory MessageAttachmentModel.fromEntity(MessageAttachmentEntity entity) {
    return MessageAttachmentModel(
      id: entity.id,
      messageId: entity.messageId,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileType: entity.fileType.value,
      fileSizeBytes: entity.fileSizeBytes,
      mimeType: entity.mimeType,
      thumbnailUrl: entity.thumbnailUrl,
      previewText: entity.previewText,
      isPreviewable: entity.isPreviewable,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
    );
  }

  MessageAttachmentEntity toEntity() {
    return MessageAttachmentEntity(
      id: id,
      messageId: messageId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileType: AttachmentType.fromString(fileType) ?? AttachmentType.other,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
      previewText: previewText,
      isPreviewable: isPreviewable,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  MessageAttachmentModel copyWith({
    String? id,
    String? messageId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSizeBytes,
    String? mimeType,
    String? thumbnailUrl,
    String? previewText,
    bool? isPreviewable,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return MessageAttachmentModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewText: previewText ?? this.previewText,
      isPreviewable: isPreviewable ?? this.isPreviewable,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAttachmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messageId == other.messageId &&
          fileUrl == other.fileUrl;

  @override
  int get hashCode => Object.hash(id, messageId, fileUrl);

  @override
  String toString() => 'MessageAttachmentModel(id: $id, fileName: $fileName)';
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an announcement, mapping to the
/// `announcements` table.
class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    this.announcementType = 'general',
    this.priority = 'normal',
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
  final String announcementType;
  final String priority;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      announcementType: json['announcement_type'] as String? ?? json['announcementType'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'normal',
      targetAudience: (json['target_audience'] as List<dynamic>?)?.cast<String>() ??
          (json['targetAudience'] as List<dynamic>?)?.cast<String>() ??
          const ['all'],
      targetClassIds: (json['target_class_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['targetClassIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      targetDepartmentIds: (json['target_department_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['targetDepartmentIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      targetSubjectIds: (json['target_subject_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['targetSubjectIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      authorId: json['author_id'] as String? ?? json['authorId'] as String? ?? '',
      authorName: json['author_name'] as String? ?? json['authorName'] as String? ?? '',
      authorRole: json['author_role'] as String? ?? json['authorRole'] as String? ?? '',
      isScheduled: json['is_scheduled'] as bool? ?? json['isScheduled'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : json['scheduledAt'] != null
              ? DateTime.parse(json['scheduledAt'] as String)
              : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      isPublished: json['is_published'] as bool? ?? json['isPublished'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : json['publishedAt'] != null
              ? DateTime.parse(json['publishedAt'] as String)
              : null,
      viewCount: json['view_count'] as int? ?? json['viewCount'] as int? ?? 0,
      acknowledgedBy: (json['acknowledged_by'] as List<dynamic>?)?.cast<String>() ??
          (json['acknowledgedBy'] as List<dynamic>?)?.cast<String>() ??
          const [],
      isAiGenerated: json['is_ai_generated'] as bool? ?? json['isAiGenerated'] as bool? ?? false,
      aiReviewed: json['ai_reviewed'] as bool? ?? json['aiReviewed'] as bool? ?? false,
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
      'title': title,
      'body': body,
      'announcement_type': announcementType,
      'priority': priority,
      'target_audience': targetAudience,
      'target_class_ids': targetClassIds,
      'target_department_ids': targetDepartmentIds,
      'target_subject_ids': targetSubjectIds,
      'author_id': authorId,
      'author_name': authorName,
      'author_role': authorRole,
      'is_scheduled': isScheduled,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_pinned': isPinned,
      'attachments': attachments,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'view_count': viewCount,
      'acknowledged_by': acknowledgedBy,
      'is_ai_generated': isAiGenerated,
      'ai_reviewed': aiReviewed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AnnouncementModel.fromEntity(AnnouncementEntity entity) {
    return AnnouncementModel(
      id: entity.id,
      schoolId: entity.schoolId,
      title: entity.title,
      body: entity.body,
      announcementType: entity.announcementType.value,
      priority: entity.priority.value,
      targetAudience: entity.targetAudience,
      targetClassIds: entity.targetClassIds,
      targetDepartmentIds: entity.targetDepartmentIds,
      targetSubjectIds: entity.targetSubjectIds,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorRole: entity.authorRole,
      isScheduled: entity.isScheduled,
      scheduledAt: entity.scheduledAt,
      expiresAt: entity.expiresAt,
      isPinned: entity.isPinned,
      attachments: entity.attachments,
      isPublished: entity.isPublished,
      publishedAt: entity.publishedAt,
      viewCount: entity.viewCount,
      acknowledgedBy: entity.acknowledgedBy,
      isAiGenerated: entity.isAiGenerated,
      aiReviewed: entity.aiReviewed,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AnnouncementEntity toEntity() {
    return AnnouncementEntity(
      id: id,
      schoolId: schoolId,
      title: title,
      body: body,
      announcementType: AnnouncementType.fromString(announcementType) ?? AnnouncementType.general,
      priority: AnnouncementPriority.fromString(priority) ?? AnnouncementPriority.normal,
      targetAudience: targetAudience,
      targetClassIds: targetClassIds,
      targetDepartmentIds: targetDepartmentIds,
      targetSubjectIds: targetSubjectIds,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      isScheduled: isScheduled,
      scheduledAt: scheduledAt,
      expiresAt: expiresAt,
      isPinned: isPinned,
      attachments: attachments,
      isPublished: isPublished,
      publishedAt: publishedAt,
      viewCount: viewCount,
      acknowledgedBy: acknowledgedBy,
      isAiGenerated: isAiGenerated,
      aiReviewed: aiReviewed,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  AnnouncementModel copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? body,
    String? announcementType,
    String? priority,
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
    return AnnouncementModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, schoolId, title, createdAt);

  @override
  String toString() => 'AnnouncementModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION NOTIFICATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a communication notification, mapping to the
/// `communication_notifications` table.
class CommunicationNotificationModel {
  const CommunicationNotificationModel({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.title,
    required this.body,
    this.category = 'general',
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
  final String category;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CommunicationNotificationModel.fromJson(Map<String, dynamic> json) {
    return CommunicationNotificationModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'normal',
      sourceType: json['source_type'] as String? ?? json['sourceType'] as String?,
      sourceId: json['source_id'] as String? ?? json['sourceId'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
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
      'user_id': userId,
      'title': title,
      'body': body,
      'category': category,
      'priority': priority,
      'source_type': sourceType,
      'source_id': sourceId,
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

  factory CommunicationNotificationModel.fromEntity(CommunicationNotificationEntity entity) {
    return CommunicationNotificationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      category: entity.category.value,
      priority: entity.priority,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
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

  CommunicationNotificationEntity toEntity() {
    return CommunicationNotificationEntity(
      id: id,
      schoolId: schoolId,
      userId: userId,
      title: title,
      body: body,
      category: NotificationCategory.fromString(category) ?? NotificationCategory.general,
      priority: priority,
      sourceType: sourceType,
      sourceId: sourceId,
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

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  CommunicationNotificationModel copyWith({
    String? id,
    String? schoolId,
    String? userId,
    String? title,
    String? body,
    String? category,
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
    return CommunicationNotificationModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationNotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, userId, title, isRead, createdAt);

  @override
  String toString() => 'CommunicationNotificationModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION PREFERENCES MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of notification preferences, mapping to the
/// `notification_preferences` table.
class NotificationPreferencesModel {
  const NotificationPreferencesModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String? ?? json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? json['quietHoursEnd'] as String? ?? '07:00',
      digestEnabled: json['digest_enabled'] as bool? ?? json['digestEnabled'] as bool? ?? false,
      digestFrequency: json['digest_frequency'] as String? ?? json['digestFrequency'] as String? ?? 'daily',
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
      'user_id': userId,
      'school_id': schoolId,
      'preferences': preferences,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'digest_enabled': digestEnabled,
      'digest_frequency': digestFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory NotificationPreferencesModel.fromEntity(NotificationPreferencesEntity entity) {
    return NotificationPreferencesModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      preferences: entity.preferences,
      quietHoursEnabled: entity.quietHoursEnabled,
      quietHoursStart: entity.quietHoursStart,
      quietHoursEnd: entity.quietHoursEnd,
      digestEnabled: entity.digestEnabled,
      digestFrequency: entity.digestFrequency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  NotificationPreferencesEntity toEntity() {
    return NotificationPreferencesEntity(
      id: id,
      userId: userId,
      schoolId: schoolId,
      preferences: preferences,
      quietHoursEnabled: quietHoursEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      digestEnabled: digestEnabled,
      digestFrequency: digestFrequency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  NotificationPreferencesModel copyWith({
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
    return NotificationPreferencesModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          schoolId == other.schoolId;

  @override
  int get hashCode => Object.hash(id, userId, schoolId);

  @override
  String toString() => 'NotificationPreferencesModel(id: $id, userId: $userId)';
}

// ═══════════════════════════════════════════════════════════════════════
// DISCUSSION FORUM MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a discussion forum, mapping to the
/// `discussion_forums` table.
class DiscussionForumModel {
  const DiscussionForumModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    this.forumType = 'school_community',
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
  final String forumType;
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory DiscussionForumModel.fromJson(Map<String, dynamic> json) {
    return DiscussionForumModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      forumType: json['forum_type'] as String? ?? json['forumType'] as String? ?? 'school_community',
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      departmentId: json['department_id'] as String? ?? json['departmentId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      isModerated: json['is_moderated'] as bool? ?? json['isModerated'] as bool? ?? true,
      isLocked: json['is_locked'] as bool? ?? json['isLocked'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      moderatorIds: (json['moderator_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['moderatorIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
      postCount: json['post_count'] as int? ?? json['postCount'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? json['memberCount'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : json['lastActivityAt'] != null
              ? DateTime.parse(json['lastActivityAt'] as String)
              : null,
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
      'name': name,
      'description': description,
      'forum_type': forumType,
      'avatar_url': avatarUrl,
      'department_id': departmentId,
      'class_id': classId,
      'subject_id': subjectId,
      'is_moderated': isModerated,
      'is_locked': isLocked,
      'is_pinned': isPinned,
      'moderator_ids': moderatorIds,
      'created_by': createdBy,
      'post_count': postCount,
      'member_count': memberCount,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory DiscussionForumModel.fromEntity(DiscussionForumEntity entity) {
    return DiscussionForumModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      description: entity.description,
      forumType: entity.forumType.value,
      avatarUrl: entity.avatarUrl,
      departmentId: entity.departmentId,
      classId: entity.classId,
      subjectId: entity.subjectId,
      isModerated: entity.isModerated,
      isLocked: entity.isLocked,
      isPinned: entity.isPinned,
      moderatorIds: entity.moderatorIds,
      createdBy: entity.createdBy,
      postCount: entity.postCount,
      memberCount: entity.memberCount,
      lastActivityAt: entity.lastActivityAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DiscussionForumEntity toEntity() {
    return DiscussionForumEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      description: description,
      forumType: ForumType.fromString(forumType) ?? ForumType.schoolCommunity,
      avatarUrl: avatarUrl,
      departmentId: departmentId,
      classId: classId,
      subjectId: subjectId,
      isModerated: isModerated,
      isLocked: isLocked,
      isPinned: isPinned,
      moderatorIds: moderatorIds,
      createdBy: createdBy,
      postCount: postCount,
      memberCount: memberCount,
      lastActivityAt: lastActivityAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  DiscussionForumModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? description,
    String? forumType,
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
    return DiscussionForumModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionForumModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, schoolId, name);

  @override
  String toString() => 'DiscussionForumModel(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// FORUM POST MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a forum post, mapping to the
/// `forum_posts` table.
class ForumPostModel {
  const ForumPostModel({
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
  final List<ForumCommentModel> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      id: json['id'] as String,
      forumId: json['forum_id'] as String? ?? json['forumId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      authorId: json['author_id'] as String? ?? json['authorId'] as String? ?? '',
      authorName: json['author_name'] as String? ?? json['authorName'] as String? ?? '',
      authorAvatar: json['author_avatar'] as String? ?? json['authorAvatar'] as String?,
      authorRole: json['author_role'] as String? ?? json['authorRole'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? json['isLocked'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? json['isHidden'] as bool? ?? false,
      hiddenReason: json['hidden_reason'] as String? ?? json['hiddenReason'] as String?,
      commentCount: json['comment_count'] as int? ?? json['commentCount'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? json['viewCount'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? json['likeCount'] as int? ?? 0,
      reportedCount: json['reported_count'] as int? ?? json['reportedCount'] as int? ?? 0,
      isReported: json['is_reported'] as bool? ?? json['isReported'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => ForumCommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'forum_id': forumId,
      'school_id': schoolId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'title': title,
      'body': body,
      'attachments': attachments,
      'is_pinned': isPinned,
      'is_locked': isLocked,
      'is_hidden': isHidden,
      'hidden_reason': hiddenReason,
      'comment_count': commentCount,
      'view_count': viewCount,
      'like_count': likeCount,
      'reported_count': reportedCount,
      'is_reported': isReported,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ForumPostModel.fromEntity(ForumPostEntity entity) {
    return ForumPostModel(
      id: entity.id,
      forumId: entity.forumId,
      schoolId: entity.schoolId,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorAvatar: entity.authorAvatar,
      authorRole: entity.authorRole,
      title: entity.title,
      body: entity.body,
      attachments: entity.attachments,
      isPinned: entity.isPinned,
      isLocked: entity.isLocked,
      isHidden: entity.isHidden,
      hiddenReason: entity.hiddenReason,
      commentCount: entity.commentCount,
      viewCount: entity.viewCount,
      likeCount: entity.likeCount,
      reportedCount: entity.reportedCount,
      isReported: entity.isReported,
      comments: entity.comments.map((c) => ForumCommentModel.fromEntity(c)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ForumPostEntity toEntity() {
    return ForumPostEntity(
      id: id,
      forumId: forumId,
      schoolId: schoolId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorRole: authorRole,
      title: title,
      body: body,
      attachments: attachments,
      isPinned: isPinned,
      isLocked: isLocked,
      isHidden: isHidden,
      hiddenReason: hiddenReason,
      commentCount: commentCount,
      viewCount: viewCount,
      likeCount: likeCount,
      reportedCount: reportedCount,
      isReported: isReported,
      comments: comments.map((c) => c.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  ForumPostModel copyWith({
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
    List<ForumCommentModel>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForumPostModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumPostModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          forumId == other.forumId &&
          title == other.title &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, forumId, title, createdAt);

  @override
  String toString() => 'ForumPostModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// FORUM COMMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a forum comment, mapping to the
/// `forum_comments` table.
class ForumCommentModel {
  const ForumCommentModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ForumCommentModel.fromJson(Map<String, dynamic> json) {
    return ForumCommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? json['postId'] as String? ?? '',
      forumId: json['forum_id'] as String? ?? json['forumId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      authorId: json['author_id'] as String? ?? json['authorId'] as String? ?? '',
      authorName: json['author_name'] as String? ?? json['authorName'] as String? ?? '',
      authorAvatar: json['author_avatar'] as String? ?? json['authorAvatar'] as String?,
      authorRole: json['author_role'] as String? ?? json['authorRole'] as String? ?? '',
      body: json['body'] as String? ?? '',
      parentCommentId: json['parent_comment_id'] as String? ?? json['parentCommentId'] as String?,
      replyToUserId: json['reply_to_user_id'] as String? ?? json['replyToUserId'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      isHidden: json['is_hidden'] as bool? ?? json['isHidden'] as bool? ?? false,
      hiddenReason: json['hidden_reason'] as String? ?? json['hiddenReason'] as String?,
      likeCount: json['like_count'] as int? ?? json['likeCount'] as int? ?? 0,
      reportedCount: json['reported_count'] as int? ?? json['reportedCount'] as int? ?? 0,
      isReported: json['is_reported'] as bool? ?? json['isReported'] as bool? ?? false,
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
      'post_id': postId,
      'forum_id': forumId,
      'school_id': schoolId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'body': body,
      'parent_comment_id': parentCommentId,
      'reply_to_user_id': replyToUserId,
      'attachments': attachments,
      'is_hidden': isHidden,
      'hidden_reason': hiddenReason,
      'like_count': likeCount,
      'reported_count': reportedCount,
      'is_reported': isReported,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ForumCommentModel.fromEntity(ForumCommentEntity entity) {
    return ForumCommentModel(
      id: entity.id,
      postId: entity.postId,
      forumId: entity.forumId,
      schoolId: entity.schoolId,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorAvatar: entity.authorAvatar,
      authorRole: entity.authorRole,
      body: entity.body,
      parentCommentId: entity.parentCommentId,
      replyToUserId: entity.replyToUserId,
      attachments: entity.attachments,
      isHidden: entity.isHidden,
      hiddenReason: entity.hiddenReason,
      likeCount: entity.likeCount,
      reportedCount: entity.reportedCount,
      isReported: entity.isReported,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ForumCommentEntity toEntity() {
    return ForumCommentEntity(
      id: id,
      postId: postId,
      forumId: forumId,
      schoolId: schoolId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorRole: authorRole,
      body: body,
      parentCommentId: parentCommentId,
      replyToUserId: replyToUserId,
      attachments: attachments,
      isHidden: isHidden,
      hiddenReason: hiddenReason,
      likeCount: likeCount,
      reportedCount: reportedCount,
      isReported: isReported,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  ForumCommentModel copyWith({
    String? id,
    String? postId,
    String? forumId,
    String? schoolId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
    String? body,
    String? parentCommentId,
    String? replyToUserId,
    List<Map<String, dynamic>>? attachments,
    bool? isHidden,
    String? hiddenReason,
    int? likeCount,
    int? reportedCount,
    bool? isReported,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForumCommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      forumId: forumId ?? this.forumId,
      schoolId: schoolId ?? this.schoolId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      body: body ?? this.body,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      attachments: attachments ?? this.attachments,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      likeCount: likeCount ?? this.likeCount,
      reportedCount: reportedCount ?? this.reportedCount,
      isReported: isReported ?? this.isReported,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumCommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          postId == other.postId &&
          body == other.body &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, postId, body, createdAt);

  @override
  String toString() => 'ForumCommentModel(id: $id, postId: $postId)';
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR EVENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a calendar event, mapping to the
/// `calendar_events` table.
class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    this.eventType = 'custom',
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
    this.meetingStatus = 'scheduled',
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
  final String eventType;
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
  final String meetingStatus;
  final int? maxAttendees;
  final int? currentAttendees;
  final String? sourceType;
  final String? sourceId;
  final List<int> reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ?? json['eventType'] as String? ?? 'custom',
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
      isAllDay: json['is_all_day'] as bool? ?? json['isAllDay'] as bool? ?? false,
      location: json['location'] as String?,
      meetingLink: json['meeting_link'] as String? ?? json['meetingLink'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? json['isRecurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String? ?? json['recurrenceRule'] as String?,
      organizerId: json['organizer_id'] as String? ?? json['organizerId'] as String? ?? '',
      organizerName: json['organizer_name'] as String? ?? json['organizerName'] as String? ?? '',
      targetAudience: (json['target_audience'] as List<dynamic>?)?.cast<String>() ??
          (json['targetAudience'] as List<dynamic>?)?.cast<String>() ??
          const ['all'],
      targetClassIds: (json['target_class_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['targetClassIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      targetDepartmentIds: (json['target_department_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['targetDepartmentIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      attendeeIds: (json['attendee_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['attendeeIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      rsvpRequired: json['rsvp_required'] as bool? ?? json['rsvpRequired'] as bool? ?? false,
      meetingStatus: json['meeting_status'] as String? ?? json['meetingStatus'] as String? ?? 'scheduled',
      maxAttendees: json['max_attendees'] as int? ?? json['maxAttendees'] as int?,
      currentAttendees: json['current_attendees'] as int? ?? json['currentAttendees'] as int?,
      sourceType: json['source_type'] as String? ?? json['sourceType'] as String?,
      sourceId: json['source_id'] as String? ?? json['sourceId'] as String?,
      reminderMinutes: (json['reminder_minutes'] as List<dynamic>?)?.cast<int>() ??
          (json['reminderMinutes'] as List<dynamic>?)?.cast<int>() ??
          const [15, 60],
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
      'title': title,
      'description': description,
      'event_type': eventType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay,
      'location': location,
      'meeting_link': meetingLink,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'target_audience': targetAudience,
      'target_class_ids': targetClassIds,
      'target_department_ids': targetDepartmentIds,
      'attendee_ids': attendeeIds,
      'rsvp_required': rsvpRequired,
      'meeting_status': meetingStatus,
      'max_attendees': maxAttendees,
      'current_attendees': currentAttendees,
      'source_type': sourceType,
      'source_id': sourceId,
      'reminder_minutes': reminderMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CalendarEventModel.fromEntity(CalendarEventEntity entity) {
    return CalendarEventModel(
      id: entity.id,
      schoolId: entity.schoolId,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType.value,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isAllDay: entity.isAllDay,
      location: entity.location,
      meetingLink: entity.meetingLink,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      organizerId: entity.organizerId,
      organizerName: entity.organizerName,
      targetAudience: entity.targetAudience,
      targetClassIds: entity.targetClassIds,
      targetDepartmentIds: entity.targetDepartmentIds,
      attendeeIds: entity.attendeeIds,
      rsvpRequired: entity.rsvpRequired,
      meetingStatus: entity.meetingStatus.value,
      maxAttendees: entity.maxAttendees,
      currentAttendees: entity.currentAttendees,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      reminderMinutes: entity.reminderMinutes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CalendarEventEntity toEntity() {
    return CalendarEventEntity(
      id: id,
      schoolId: schoolId,
      title: title,
      description: description,
      eventType: CalendarEventType.fromString(eventType) ?? CalendarEventType.custom,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: location,
      meetingLink: meetingLink,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      organizerId: organizerId,
      organizerName: organizerName,
      targetAudience: targetAudience,
      targetClassIds: targetClassIds,
      targetDepartmentIds: targetDepartmentIds,
      attendeeIds: attendeeIds,
      rsvpRequired: rsvpRequired,
      meetingStatus: MeetingStatus.fromString(meetingStatus) ?? MeetingStatus.scheduled,
      maxAttendees: maxAttendees,
      currentAttendees: currentAttendees,
      sourceType: sourceType,
      sourceId: sourceId,
      reminderMinutes: reminderMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  CalendarEventModel copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? description,
    String? eventType,
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
    String? meetingStatus,
    int? maxAttendees,
    int? currentAttendees,
    String? sourceType,
    String? sourceId,
    List<int>? reminderMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title &&
          startTime == other.startTime;

  @override
  int get hashCode => Object.hash(id, schoolId, title, startTime);

  @override
  String toString() => 'CalendarEventModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION AUDIT LOG MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a communication audit log, mapping to the
/// `communication_audit_logs` table.
class CommunicationAuditLogModel {
  const CommunicationAuditLogModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CommunicationAuditLogModel.fromJson(Map<String, dynamic> json) {
    return CommunicationAuditLogModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      userRole: json['user_role'] as String? ?? json['userRole'] as String? ?? '',
      userName: json['user_name'] as String? ?? json['userName'] as String? ?? '',
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? json['resourceType'] as String? ?? '',
      resourceId: json['resource_id'] as String? ?? json['resourceId'] as String?,
      details: json['details'] as Map<String, dynamic>? ?? const {},
      severity: json['severity'] as String? ?? 'info',
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
      'user_id': userId,
      'user_role': userRole,
      'user_name': userName,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details': details,
      'severity': severity,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_type': deviceType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CommunicationAuditLogModel.fromEntity(CommunicationAuditLogEntity entity) {
    return CommunicationAuditLogModel(
      id: entity.id,
      schoolId: entity.schoolId,
      userId: entity.userId,
      userRole: entity.userRole,
      userName: entity.userName,
      action: entity.action,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      details: entity.details,
      severity: entity.severity,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      deviceType: entity.deviceType,
      createdAt: entity.createdAt,
    );
  }

  CommunicationAuditLogEntity toEntity() {
    return CommunicationAuditLogEntity(
      id: id,
      schoolId: schoolId,
      userId: userId,
      userRole: userRole,
      userName: userName,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      severity: severity,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceType: deviceType,
      createdAt: createdAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  CommunicationAuditLogModel copyWith({
    String? id,
    String? schoolId,
    String? userId,
    String? userRole,
    String? userName,
    String? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? severity,
    String? ipAddress,
    String? userAgent,
    String? deviceType,
    DateTime? createdAt,
  }) {
    return CommunicationAuditLogModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      details: details ?? this.details,
      severity: severity ?? this.severity,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceType: deviceType ?? this.deviceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationAuditLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          action == other.action &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, userId, action, createdAt);

  @override
  String toString() => 'CommunicationAuditLogModel(id: $id, action: $action)';
}

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL KNOWLEDGE DOCUMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a school knowledge document, mapping to the
/// `school_knowledge_documents` table.
class SchoolKnowledgeDocumentModel {
  const SchoolKnowledgeDocumentModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SchoolKnowledgeDocumentModel.fromJson(Map<String, dynamic> json) {
    return SchoolKnowledgeDocumentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      documentType: json['document_type'] as String? ?? json['documentType'] as String? ?? 'policy',
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? json['fileSizeBytes'] as int?,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      status: json['status'] as String? ?? 'pending',
      processingError: json['processing_error'] as String? ?? json['processingError'] as String?,
      chunkCount: json['chunk_count'] as int? ?? json['chunkCount'] as int? ?? 0,
      extractedText: json['extracted_text'] as String? ?? json['extractedText'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String? ?? '',
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
      'title': title,
      'description': description,
      'document_type': documentType,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'status': status,
      'processing_error': processingError,
      'chunk_count': chunkCount,
      'extracted_text': extractedText,
      'tags': tags,
      'is_active': isActive,
      'version': version,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SchoolKnowledgeDocumentModel.fromEntity(SchoolKnowledgeDocumentEntity entity) {
    return SchoolKnowledgeDocumentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      title: entity.title,
      description: entity.description,
      documentType: entity.documentType,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileSizeBytes: entity.fileSizeBytes,
      mimeType: entity.mimeType,
      status: entity.status,
      processingError: entity.processingError,
      chunkCount: entity.chunkCount,
      extractedText: entity.extractedText,
      tags: entity.tags,
      isActive: entity.isActive,
      version: entity.version,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolKnowledgeDocumentEntity toEntity() {
    return SchoolKnowledgeDocumentEntity(
      id: id,
      schoolId: schoolId,
      title: title,
      description: description,
      documentType: documentType,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      status: status,
      processingError: processingError,
      chunkCount: chunkCount,
      extractedText: extractedText,
      tags: tags,
      isActive: isActive,
      version: version,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  SchoolKnowledgeDocumentModel copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? description,
    String? documentType,
    String? fileName,
    String? fileUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? status,
    String? processingError,
    int? chunkCount,
    String? extractedText,
    List<String>? tags,
    bool? isActive,
    int? version,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolKnowledgeDocumentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      description: description ?? this.description,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      processingError: processingError ?? this.processingError,
      chunkCount: chunkCount ?? this.chunkCount,
      extractedText: extractedText ?? this.extractedText,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolKnowledgeDocumentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title &&
          documentType == other.documentType;

  @override
  int get hashCode => Object.hash(id, schoolId, title, documentType);

  @override
  String toString() => 'SchoolKnowledgeDocumentModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// AI COMMUNICATION ASSISTANT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an AI communication assistant response,
/// mapping to the `ai_communication_assistant` table.
class AiCommunicationAssistantModel {
  const AiCommunicationAssistantModel({
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
  final String type;
  final String content;
  final List<String> suggestions;
  final String? tone;
  final String? language;
  final double confidence;
  final bool requiresReview;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AiCommunicationAssistantModel.fromJson(Map<String, dynamic> json) {
    return AiCommunicationAssistantModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? const [],
      tone: json['tone'] as String?,
      language: json['language'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      requiresReview: json['requires_review'] as bool? ?? json['requiresReview'] as bool? ?? true,
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
      'type': type,
      'content': content,
      'suggestions': suggestions,
      'tone': tone,
      'language': language,
      'confidence': confidence,
      'requires_review': requiresReview,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AiCommunicationAssistantModel.fromEntity(AiCommunicationAssistantEntity entity) {
    return AiCommunicationAssistantModel(
      id: entity.id,
      type: entity.type,
      content: entity.content,
      suggestions: entity.suggestions,
      tone: entity.tone,
      language: entity.language,
      confidence: entity.confidence,
      requiresReview: entity.requiresReview,
      createdAt: entity.createdAt,
    );
  }

  AiCommunicationAssistantEntity toEntity() {
    return AiCommunicationAssistantEntity(
      id: id,
      type: type,
      content: content,
      suggestions: suggestions,
      tone: tone,
      language: language,
      confidence: confidence,
      requiresReview: requiresReview,
      createdAt: createdAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  AiCommunicationAssistantModel copyWith({
    String? id,
    String? type,
    String? content,
    List<String>? suggestions,
    String? tone,
    String? language,
    double? confidence,
    bool? requiresReview,
    DateTime? createdAt,
  }) {
    return AiCommunicationAssistantModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      suggestions: suggestions ?? this.suggestions,
      tone: tone ?? this.tone,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      requiresReview: requiresReview ?? this.requiresReview,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCommunicationAssistantModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          content == other.content;

  @override
  int get hashCode => Object.hash(id, type, content);

  @override
  String toString() => 'AiCommunicationAssistantModel(id: $id, type: $type)';
}

// ═══════════════════════════════════════════════════════════════════════
// AI SCHOOL KNOWLEDGE RESPONSE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an AI school knowledge response,
/// mapping to the `ai_school_knowledge_responses` table.
class AiSchoolKnowledgeResponseModel {
  const AiSchoolKnowledgeResponseModel({
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
  final List<KnowledgeSourceModel> sources;
  final double confidence;
  final bool isGrounded;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AiSchoolKnowledgeResponseModel.fromJson(Map<String, dynamic> json) {
    return AiSchoolKnowledgeResponseModel(
      id: json['id'] as String,
      query: json['query'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => KnowledgeSourceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isGrounded: json['is_grounded'] as bool? ?? json['isGrounded'] as bool? ?? false,
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
      'query': query,
      'answer': answer,
      'sources': sources.map((s) => s.toJson()).toList(),
      'confidence': confidence,
      'is_grounded': isGrounded,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AiSchoolKnowledgeResponseModel.fromEntity(AiSchoolKnowledgeResponseEntity entity) {
    return AiSchoolKnowledgeResponseModel(
      id: entity.id,
      query: entity.query,
      answer: entity.answer,
      sources: entity.sources.map((s) => KnowledgeSourceModel.fromEntity(s)).toList(),
      confidence: entity.confidence,
      isGrounded: entity.isGrounded,
      createdAt: entity.createdAt,
    );
  }

  AiSchoolKnowledgeResponseEntity toEntity() {
    return AiSchoolKnowledgeResponseEntity(
      id: id,
      query: query,
      answer: answer,
      sources: sources.map((s) => s.toEntity()).toList(),
      confidence: confidence,
      isGrounded: isGrounded,
      createdAt: createdAt,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  AiSchoolKnowledgeResponseModel copyWith({
    String? id,
    String? query,
    String? answer,
    List<KnowledgeSourceModel>? sources,
    double? confidence,
    bool? isGrounded,
    DateTime? createdAt,
  }) {
    return AiSchoolKnowledgeResponseModel(
      id: id ?? this.id,
      query: query ?? this.query,
      answer: answer ?? this.answer,
      sources: sources ?? this.sources,
      confidence: confidence ?? this.confidence,
      isGrounded: isGrounded ?? this.isGrounded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSchoolKnowledgeResponseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          query == other.query &&
          answer == other.answer;

  @override
  int get hashCode => Object.hash(id, query, answer);

  @override
  String toString() => 'AiSchoolKnowledgeResponseModel(id: $id, query: $query)';
}

// ═══════════════════════════════════════════════════════════════════════
// KNOWLEDGE SOURCE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a knowledge source reference,
/// used within AI knowledge responses.
class KnowledgeSourceModel {
  const KnowledgeSourceModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory KnowledgeSourceModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceModel(
      documentId: json['document_id'] as String? ?? json['documentId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      documentType: json['document_type'] as String? ?? json['documentType'] as String? ?? '',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      snippet: json['snippet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'title': title,
      'document_type': documentType,
      'relevance': relevance,
      'snippet': snippet,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory KnowledgeSourceModel.fromEntity(KnowledgeSourceEntity entity) {
    return KnowledgeSourceModel(
      documentId: entity.documentId,
      title: entity.title,
      documentType: entity.documentType,
      relevance: entity.relevance,
      snippet: entity.snippet,
    );
  }

  KnowledgeSourceEntity toEntity() {
    return KnowledgeSourceEntity(
      documentId: documentId,
      title: title,
      documentType: documentType,
      relevance: relevance,
      snippet: snippet,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  KnowledgeSourceModel copyWith({
    String? documentId,
    String? title,
    String? documentType,
    double? relevance,
    String? snippet,
  }) {
    return KnowledgeSourceModel(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      relevance: relevance ?? this.relevance,
      snippet: snippet ?? this.snippet,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeSourceModel &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(documentId, title);

  @override
  String toString() => 'KnowledgeSourceModel(documentId: $documentId, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION DASHBOARD MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of the communication dashboard,
/// typically returned by an RPC function.
class CommunicationDashboardModel {
  const CommunicationDashboardModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CommunicationDashboardModel.fromJson(Map<String, dynamic> json) {
    return CommunicationDashboardModel(
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      totalConversations: json['total_conversations'] as int? ?? json['totalConversations'] as int? ?? 0,
      activeConversations: json['active_conversations'] as int? ?? json['activeConversations'] as int? ?? 0,
      totalMessagesToday: json['total_messages_today'] as int? ?? json['totalMessagesToday'] as int? ?? 0,
      totalAnnouncements: json['total_announcements'] as int? ?? json['totalAnnouncements'] as int? ?? 0,
      unreadNotifications: json['unread_notifications'] as int? ?? json['unreadNotifications'] as int? ?? 0,
      upcomingEvents: (json['upcoming_events'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['upcomingEvents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      activeForums: json['active_forums'] as int? ?? json['activeForums'] as int? ?? 0,
      knowledgeDocuments: json['knowledge_documents'] as int? ?? json['knowledgeDocuments'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'school_id': schoolId,
      'total_conversations': totalConversations,
      'active_conversations': activeConversations,
      'total_messages_today': totalMessagesToday,
      'total_announcements': totalAnnouncements,
      'unread_notifications': unreadNotifications,
      'upcoming_events': upcomingEvents,
      'active_forums': activeForums,
      'knowledge_documents': knowledgeDocuments,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CommunicationDashboardModel.fromEntity(CommunicationDashboardEntity entity) {
    return CommunicationDashboardModel(
      schoolId: entity.schoolId,
      totalConversations: entity.totalConversations,
      activeConversations: entity.activeConversations,
      totalMessagesToday: entity.totalMessagesToday,
      totalAnnouncements: entity.totalAnnouncements,
      unreadNotifications: entity.unreadNotifications,
      upcomingEvents: entity.upcomingEvents,
      activeForums: entity.activeForums,
      knowledgeDocuments: entity.knowledgeDocuments,
    );
  }

  CommunicationDashboardEntity toEntity() {
    return CommunicationDashboardEntity(
      schoolId: schoolId,
      totalConversations: totalConversations,
      activeConversations: activeConversations,
      totalMessagesToday: totalMessagesToday,
      totalAnnouncements: totalAnnouncements,
      unreadNotifications: unreadNotifications,
      upcomingEvents: upcomingEvents,
      activeForums: activeForums,
      knowledgeDocuments: knowledgeDocuments,
    );
  }

  // ─── copyWith, ==, hashCode, toString ──────────────────────────────

  CommunicationDashboardModel copyWith({
    String? schoolId,
    int? totalConversations,
    int? activeConversations,
    int? totalMessagesToday,
    int? totalAnnouncements,
    int? unreadNotifications,
    List<Map<String, dynamic>>? upcomingEvents,
    int? activeForums,
    int? knowledgeDocuments,
  }) {
    return CommunicationDashboardModel(
      schoolId: schoolId ?? this.schoolId,
      totalConversations: totalConversations ?? this.totalConversations,
      activeConversations: activeConversations ?? this.activeConversations,
      totalMessagesToday: totalMessagesToday ?? this.totalMessagesToday,
      totalAnnouncements: totalAnnouncements ?? this.totalAnnouncements,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      activeForums: activeForums ?? this.activeForums,
      knowledgeDocuments: knowledgeDocuments ?? this.knowledgeDocuments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationDashboardModel &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId;

  @override
  int get hashCode => schoolId.hashCode;

  @override
  String toString() => 'CommunicationDashboardModel(schoolId: $schoolId)';
}
