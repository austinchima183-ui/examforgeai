import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_remote_datasource.dart';
import '../models/communication_models.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  CommunicationRepositoryImpl({
    required CommunicationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CommunicationRemoteDataSource _remoteDataSource;

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
        'Unexpected exception in CommunicationRepositoryImpl',
        error: e,
      );
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ConversationEntity>>> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getConversations(
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ConversationEntity>> getConversation(String conversationId) async {
    try {
      final model = await _remoteDataSource.getConversation(conversationId);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ConversationEntity>> createConversation({
    required String name,
    required ConversationType type,
    required List<String> participantIds,
    String? classId,
    String? departmentId,
    String? subjectId,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'type': type.value,
        'participant_ids': participantIds,
        if (classId != null) 'class_id': classId,
        if (departmentId != null) 'department_id': departmentId,
        if (subjectId != null) 'subject_id': subjectId,
      };
      final model = await _remoteDataSource.createConversation(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ConversationEntity>> updateConversation(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final model = await _remoteDataSource.updateConversation(
        conversationId,
        data,
      );
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> addParticipant({
    required String conversationId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      await _remoteDataSource.addParticipant(
        conversationId: conversationId,
        userId: userId,
        role: role,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.removeParticipant(
        conversationId: conversationId,
        userId: userId,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> leaveConversation(String conversationId) async {
    try {
      await _remoteDataSource.leaveConversation(conversationId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<MessageEntity>>> getMessages({
    required String conversationId,
    int page = 1,
    int perPage = 50,
    DateTime? before,
  }) async {
    try {
      final models = await _remoteDataSource.getMessages(
        conversationId: conversationId,
        page: page,
        perPage: perPage,
        before: before,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<MessageEntity>> sendMessage({
    required String conversationId,
    required String body,
    MessageType type = MessageType.text,
    String? replyToId,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final data = <String, dynamic>{
        'conversation_id': conversationId,
        'body': body,
        'type': type.value,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (attachments != null) 'attachments': attachments,
      };
      final model = await _remoteDataSource.sendMessage(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<MessageEntity>> editMessage({
    required String messageId,
    required String body,
  }) async {
    try {
      final model = await _remoteDataSource.editMessage(
        messageId: messageId,
        body: body,
      );
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      await _remoteDataSource.deleteMessage(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> pinMessage(String messageId) async {
    try {
      await _remoteDataSource.pinMessage(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> unpinMessage(String messageId) async {
    try {
      await _remoteDataSource.unpinMessage(messageId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.markAsRead(
        conversationId: conversationId,
        messageId: messageId,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE REACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _remoteDataSource.addReaction(
        messageId: messageId,
        emoji: emoji,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _remoteDataSource.removeReaction(
        messageId: messageId,
        emoji: emoji,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AnnouncementEntity>>> getAnnouncements({
    String? type,
    String? priority,
    bool publishedOnly = true,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getAnnouncements(
        type: type,
        priority: priority,
        publishedOnly: publishedOnly,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AnnouncementEntity>> getAnnouncement(String announcementId) async {
    try {
      final model = await _remoteDataSource.getAnnouncement(announcementId);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
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
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'body': body,
        'announcement_type': announcementType.value,
        'priority': priority.value,
        'target_audience': targetAudience ?? ['all'],
        'target_class_ids': targetClassIds ?? [],
        'is_scheduled': isScheduled,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };
      final model = await _remoteDataSource.createAnnouncement(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AnnouncementEntity>> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  ) async {
    try {
      final model = await _remoteDataSource.updateAnnouncement(
        announcementId,
        data,
      );
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteAnnouncement(String announcementId) async {
    try {
      await _remoteDataSource.deleteAnnouncement(announcementId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> acknowledgeAnnouncement(String announcementId) async {
    try {
      await _remoteDataSource.acknowledgeAnnouncement(announcementId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<CommunicationNotificationEntity>>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getNotifications(
        category: category,
        isRead: isRead,
        page: page,
        perPage: perPage,
      );
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

  @override
  Future<Result<NotificationPreferencesEntity>> getNotificationPreferences() async {
    try {
      final model = await _remoteDataSource.getNotificationPreferences();
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<NotificationPreferencesEntity>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final model = await _remoteDataSource.updateNotificationPreferences(
        preferences,
      );
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCUSSION FORUMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<DiscussionForumEntity>>> getForums({
    ForumType? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getForums(
        type: type?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DiscussionForumEntity>> getForum(String forumId) async {
    try {
      final model = await _remoteDataSource.getForum(forumId);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DiscussionForumEntity>> createForum({
    required String name,
    String? description,
    ForumType forumType = ForumType.schoolCommunity,
    String? classId,
    String? subjectId,
    String? departmentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'description': description,
        'forum_type': forumType.value,
        if (classId != null) 'class_id': classId,
        if (subjectId != null) 'subject_id': subjectId,
        if (departmentId != null) 'department_id': departmentId,
      };
      final model = await _remoteDataSource.createForum(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM POSTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ForumPostEntity>>> getForumPosts({
    required String forumId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getForumPosts(
        forumId: forumId,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ForumPostEntity>> createForumPost({
    required String forumId,
    required String title,
    required String body,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final data = <String, dynamic>{
        'forum_id': forumId,
        'title': title,
        'body': body,
        if (attachments != null) 'attachments': attachments,
      };
      final model = await _remoteDataSource.createForumPost(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ForumPostEntity>> updateForumPost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      final model = await _remoteDataSource.updateForumPost(postId, data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteForumPost(String postId) async {
    try {
      await _remoteDataSource.deleteForumPost(postId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM COMMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ForumCommentEntity>>> getForumComments({
    required String postId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getForumComments(
        postId: postId,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ForumCommentEntity>> createForumComment({
    required String postId,
    required String forumId,
    required String body,
    String? parentCommentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'post_id': postId,
        'forum_id': forumId,
        'body': body,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      };
      final model = await _remoteDataSource.createForumComment(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<CalendarEventEntity>>> getCalendarEvents({
    CalendarEventType? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getCalendarEvents(
        type: type?.value,
        startDate: startDate,
        endDate: endDate,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
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
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'description': description,
        'event_type': eventType.value,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_all_day': isAllDay,
        'location': location,
        'meeting_link': meetingLink,
        'attendee_ids': attendeeIds ?? [],
        'rsvp_required': rsvpRequired,
      };
      final model = await _remoteDataSource.createCalendarEvent(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CalendarEventEntity>> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      final model = await _remoteDataSource.updateCalendarEvent(eventId, data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteCalendarEvent(String eventId) async {
    try {
      await _remoteDataSource.deleteCalendarEvent(eventId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> rsvpToEvent({
    required String eventId,
    required String status,
  }) async {
    try {
      await _remoteDataSource.rsvpToEvent(
        eventId: eventId,
        status: status,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI COMMUNICATION ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiCommunicationAssistantEntity>> draftAnnouncement({
    required String topic,
    String? audience,
    String? tone,
  }) async {
    try {
      final model = await _remoteDataSource.draftAnnouncement({
        'topic': topic,
        'audience': audience,
        'tone': tone,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> rewriteMessage({
    required String text,
    String? tone,
  }) async {
    try {
      final model = await _remoteDataSource.rewriteMessage({
        'text': text,
        'tone': tone,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> summarizeConversation({
    required String conversationId,
  }) async {
    try {
      final model = await _remoteDataSource.summarizeConversation({
        'conversation_id': conversationId,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> translateMessage({
    required String text,
    required String targetLanguage,
  }) async {
    try {
      final model = await _remoteDataSource.translateMessage({
        'text': text,
        'target_language': targetLanguage,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> suggestReply({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final model = await _remoteDataSource.suggestReply({
        'conversation_id': conversationId,
        'message_id': messageId,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> correctGrammar({
    required String text,
  }) async {
    try {
      final model = await _remoteDataSource.correctGrammar({
        'text': text,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiCommunicationAssistantEntity>> adjustTone({
    required String text,
    required String targetTone,
  }) async {
    try {
      final model = await _remoteDataSource.adjustTone({
        'text': text,
        'target_tone': targetTone,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI SCHOOL KNOWLEDGE ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiSchoolKnowledgeResponseEntity>> askSchoolKnowledge({
    required String query,
  }) async {
    try {
      final model = await _remoteDataSource.askSchoolKnowledge({
        'query': query,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SchoolKnowledgeDocumentEntity>>> getKnowledgeDocuments({
    String? documentType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getKnowledgeDocuments(
        documentType: documentType,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchoolKnowledgeDocumentEntity>> uploadKnowledgeDocument({
    required String title,
    required String fileName,
    required String fileUrl,
    String? description,
    String documentType = 'policy',
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'file_name': fileName,
        'file_url': fileUrl,
        'description': description,
        'document_type': documentType,
        'tags': tags ?? [],
      };
      final model = await _remoteDataSource.uploadKnowledgeDocument(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteKnowledgeDocument(String documentId) async {
    try {
      await _remoteDataSource.deleteKnowledgeDocument(documentId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILE SHARING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<MessageAttachmentEntity>> uploadAttachment({
    required String conversationId,
    required String messageId,
    required String fileName,
    required String fileUrl,
    required AttachmentType fileType,
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    try {
      final data = <String, dynamic>{
        'conversation_id': conversationId,
        'message_id': messageId,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_type': fileType.value,
        'file_size_bytes': fileSizeBytes,
        'mime_type': mimeType,
      };
      final model = await _remoteDataSource.uploadAttachment(data);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MODERATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> reportMessage({
    required String messageId,
    required String reason,
  }) async {
    try {
      await _remoteDataSource.reportMessage(
        messageId: messageId,
        reason: reason,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> blockUser({
    required String userId,
  }) async {
    try {
      await _remoteDataSource.blockUser(userId: userId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> muteConversation(String conversationId) async {
    try {
      await _remoteDataSource.muteConversation(conversationId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> archiveConversation(String conversationId) async {
    try {
      await _remoteDataSource.archiveConversation(conversationId);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<CommunicationAuditLogEntity>>> getAuditLogs({
    String? action,
    String? resourceType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getAuditLogs(
        action: action,
        resourceType: resourceType,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CommunicationDashboardEntity>> getCommunicationDashboard() async {
    try {
      final model = await _remoteDataSource.getCommunicationDashboard();
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPING INDICATORS & PRESENCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> setTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      await _remoteDataSource.setTyping(
        conversationId: conversationId,
        isTyping: isTyping,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> updatePresence({
    required bool isOnline,
  }) async {
    try {
      await _remoteDataSource.updatePresence(isOnline: isOnline);
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
