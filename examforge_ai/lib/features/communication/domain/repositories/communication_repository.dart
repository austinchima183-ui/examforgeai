import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';


abstract class CommunicationRepository {
  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<ConversationEntity>>> getConversations({
    int page = 1,
    int perPage = 20,
  });

  Future<Result<ConversationEntity>> getConversation(String conversationId);

  Future<Result<ConversationEntity>> createConversation({
    required String name,
    required ConversationType type,
    required List<String> participantIds,
    String? classId,
    String? departmentId,
    String? subjectId,
  });

  Future<Result<ConversationEntity>> updateConversation(
    String conversationId,
    Map<String, dynamic> data,
  );

  Future<Result<void>> addParticipant({
    required String conversationId,
    required String userId,
    String role = 'member',
  });

  Future<Result<void>> removeParticipant({
    required String conversationId,
    required String userId,
  });

  Future<Result<void>> leaveConversation(String conversationId);

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<MessageEntity>>> getMessages({
    required String conversationId,
    int page = 1,
    int perPage = 50,
    DateTime? before,
  });

  Future<Result<MessageEntity>> sendMessage({
    required String conversationId,
    required String body,
    MessageType type = MessageType.text,
    String? replyToId,
    List<Map<String, dynamic>>? attachments,
  });

  Future<Result<MessageEntity>> editMessage({
    required String messageId,
    required String body,
  });

  Future<Result<void>> deleteMessage(String messageId);

  Future<Result<void>> pinMessage(String messageId);

  Future<Result<void>> unpinMessage(String messageId);

  Future<Result<void>> markAsRead({
    required String conversationId,
    required String messageId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE REACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<void>> addReaction({
    required String messageId,
    required String emoji,
  });

  Future<Result<void>> removeReaction({
    required String messageId,
    required String emoji,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<AnnouncementEntity>>> getAnnouncements({
    String? type,
    String? priority,
    bool publishedOnly = true,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<AnnouncementEntity>> getAnnouncement(String announcementId);

  Future<Result<AnnouncementEntity>> createAnnouncement({
    required String title,
    required String body,
    AnnouncementType announcementType = AnnouncementType.general,
    AnnouncementPriority priority = AnnouncementPriority.normal,
    List<String>? targetAudience,
    List<String>? targetClassIds,
    bool isScheduled = false,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  });

  Future<Result<AnnouncementEntity>> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  );

  Future<Result<void>> deleteAnnouncement(String announcementId);

  Future<Result<void>> acknowledgeAnnouncement(String announcementId);

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<CommunicationNotificationEntity>>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<void>> markNotificationRead(String notificationId);

  Future<Result<void>> markAllNotificationsRead();

  Future<Result<NotificationPreferencesEntity>> getNotificationPreferences();

  Future<Result<NotificationPreferencesEntity>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  );

  // ═══════════════════════════════════════════════════════════════════════
  // DISCUSSION FORUMS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<DiscussionForumEntity>>> getForums({
    ForumType? type,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<DiscussionForumEntity>> getForum(String forumId);

  Future<Result<DiscussionForumEntity>> createForum({
    required String name,
    String? description,
    ForumType forumType = ForumType.schoolCommunity,
    String? classId,
    String? subjectId,
    String? departmentId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM POSTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<ForumPostEntity>>> getForumPosts({
    required String forumId,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<ForumPostEntity>> createForumPost({
    required String forumId,
    required String title,
    required String body,
    List<Map<String, dynamic>>? attachments,
  });

  Future<Result<ForumPostEntity>> updateForumPost(
    String postId,
    Map<String, dynamic> data,
  );

  Future<Result<void>> deleteForumPost(String postId);

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM COMMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<ForumCommentEntity>>> getForumComments({
    required String postId,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<ForumCommentEntity>> createForumComment({
    required String postId,
    required String forumId,
    required String body,
    String? parentCommentId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<CalendarEventEntity>>> getCalendarEvents({
    CalendarEventType? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<CalendarEventEntity>> createCalendarEvent({
    required String title,
    String? description,
    CalendarEventType eventType = CalendarEventType.custom,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? location,
    String? meetingLink,
    List<String>? attendeeIds,
    bool rsvpRequired = false,
  });

  Future<Result<CalendarEventEntity>> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> data,
  );

  Future<Result<void>> deleteCalendarEvent(String eventId);

  Future<Result<void>> rsvpToEvent({
    required String eventId,
    required String status,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AI COMMUNICATION ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<AiCommunicationAssistantEntity>> draftAnnouncement({
    required String topic,
    String? audience,
    String? tone,
  });

  Future<Result<AiCommunicationAssistantEntity>> rewriteMessage({
    required String text,
    String? tone,
  });

  Future<Result<AiCommunicationAssistantEntity>> summarizeConversation({
    required String conversationId,
  });

  Future<Result<AiCommunicationAssistantEntity>> translateMessage({
    required String text,
    required String targetLanguage,
  });

  Future<Result<AiCommunicationAssistantEntity>> suggestReply({
    required String conversationId,
    required String messageId,
  });

  Future<Result<AiCommunicationAssistantEntity>> correctGrammar({
    required String text,
  });

  Future<Result<AiCommunicationAssistantEntity>> adjustTone({
    required String text,
    required String targetTone,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AI SCHOOL KNOWLEDGE ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<AiSchoolKnowledgeResponseEntity>> askSchoolKnowledge({
    required String query,
  });

  Future<Result<List<SchoolKnowledgeDocumentEntity>>> getKnowledgeDocuments({
    String? documentType,
    int page = 1,
    int perPage = 20,
  });

  Future<Result<SchoolKnowledgeDocumentEntity>> uploadKnowledgeDocument({
    required String title,
    required String fileName,
    required String fileUrl,
    String? description,
    String documentType = 'policy',
    List<String>? tags,
  });

  Future<Result<void>> deleteKnowledgeDocument(String documentId);

  // ═══════════════════════════════════════════════════════════════════════
  // FILE SHARING
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<MessageAttachmentEntity>> uploadAttachment({
    required String conversationId,
    required String messageId,
    required String fileName,
    required String fileUrl,
    required AttachmentType fileType,
    int? fileSizeBytes,
    String? mimeType,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // MODERATION
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<void>> reportMessage({
    required String messageId,
    required String reason,
  });

  Future<Result<void>> blockUser({
    required String userId,
  });

  Future<Result<void>> muteConversation(String conversationId);

  Future<Result<void>> archiveConversation(String conversationId);

  // ═══════════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<List<CommunicationAuditLogEntity>>> getAuditLogs({
    String? action,
    String? resourceType,
    int page = 1,
    int perPage = 20,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<CommunicationDashboardEntity>> getCommunicationDashboard();

  // ═══════════════════════════════════════════════════════════════════════
  // TYPING INDICATORS & PRESENCE
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<void>> setTyping({
    required String conversationId,
    required bool isTyping,
  });

  Future<Result<void>> updatePresence({
    required bool isOnline,
  });
}
