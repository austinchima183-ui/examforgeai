import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/communication_models.dart';

abstract class CommunicationRemoteDataSource {
  // ── Conversations ─────────────────────────────────────────────────────
  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int perPage = 20,
  });

  Future<ConversationModel> getConversation(String conversationId);

  Future<ConversationModel> createConversation(Map<String, dynamic> data);

  Future<ConversationModel> updateConversation(
    String conversationId,
    Map<String, dynamic> data,
  );

  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    String role = 'member',
  });

  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  });

  Future<void> leaveConversation(String conversationId);

  // ── Messages ──────────────────────────────────────────────────────────
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int page = 1,
    int perPage = 50,
    DateTime? before,
  });

  Future<MessageModel> sendMessage(Map<String, dynamic> data);

  Future<MessageModel> editMessage({
    required String messageId,
    required String body,
  });

  Future<void> deleteMessage(String messageId);

  Future<void> pinMessage(String messageId);

  Future<void> unpinMessage(String messageId);

  Future<void> markAsRead({
    required String conversationId,
    required String messageId,
  });

  // ── Message Reactions ─────────────────────────────────────────────────
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  });

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  });

  // ── Announcements ─────────────────────────────────────────────────────
  Future<List<AnnouncementModel>> getAnnouncements({
    String? type,
    String? priority,
    bool publishedOnly = true,
    int page = 1,
    int perPage = 20,
  });

  Future<AnnouncementModel> getAnnouncement(String announcementId);

  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> data);

  Future<AnnouncementModel> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  );

  Future<void> deleteAnnouncement(String announcementId);

  Future<void> acknowledgeAnnouncement(String announcementId);

  // ── Notifications ─────────────────────────────────────────────────────
  Future<List<CommunicationNotificationModel>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  });

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllNotificationsRead();

  Future<NotificationPreferencesModel> getNotificationPreferences();

  Future<NotificationPreferencesModel> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  );

  // ── Discussion Forums ─────────────────────────────────────────────────
  Future<List<DiscussionForumModel>> getForums({
    String? type,
    int page = 1,
    int perPage = 20,
  });

  Future<DiscussionForumModel> getForum(String forumId);

  Future<DiscussionForumModel> createForum(Map<String, dynamic> data);

  // ── Forum Posts ───────────────────────────────────────────────────────
  Future<List<ForumPostModel>> getForumPosts({
    required String forumId,
    int page = 1,
    int perPage = 20,
  });

  Future<ForumPostModel> createForumPost(Map<String, dynamic> data);

  Future<ForumPostModel> updateForumPost(
    String postId,
    Map<String, dynamic> data,
  );

  Future<void> deleteForumPost(String postId);

  // ── Forum Comments ────────────────────────────────────────────────────
  Future<List<ForumCommentModel>> getForumComments({
    required String postId,
    int page = 1,
    int perPage = 20,
  });

  Future<ForumCommentModel> createForumComment(Map<String, dynamic> data);

  // ── Calendar Events ───────────────────────────────────────────────────
  Future<List<CalendarEventModel>> getCalendarEvents({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  });

  Future<CalendarEventModel> createCalendarEvent(Map<String, dynamic> data);

  Future<CalendarEventModel> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> data,
  );

  Future<void> deleteCalendarEvent(String eventId);

  Future<void> rsvpToEvent({
    required String eventId,
    required String status,
  });

  // ── AI Communication Assistant ────────────────────────────────────────
  Future<AiCommunicationAssistantModel> draftAnnouncement(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> rewriteMessage(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> summarizeConversation(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> translateMessage(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> suggestReply(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> correctGrammar(
    Map<String, dynamic> params,
  );

  Future<AiCommunicationAssistantModel> adjustTone(
    Map<String, dynamic> params,
  );

  // ── AI School Knowledge Assistant ─────────────────────────────────────
  Future<AiSchoolKnowledgeResponseModel> askSchoolKnowledge(
    Map<String, dynamic> params,
  );

  Future<List<SchoolKnowledgeDocumentModel>> getKnowledgeDocuments({
    String? documentType,
    int page = 1,
    int perPage = 20,
  });

  Future<SchoolKnowledgeDocumentModel> uploadKnowledgeDocument(
    Map<String, dynamic> data,
  );

  Future<void> deleteKnowledgeDocument(String documentId);

  // ── File Sharing ──────────────────────────────────────────────────────
  Future<MessageAttachmentModel> uploadAttachment(Map<String, dynamic> data);

  // ── Moderation ────────────────────────────────────────────────────────
  Future<void> reportMessage({
    required String messageId,
    required String reason,
  });

  Future<void> blockUser({
    required String userId,
  });

  Future<void> muteConversation(String conversationId);

  Future<void> archiveConversation(String conversationId);

  // ── Audit Logs ────────────────────────────────────────────────────────
  Future<List<CommunicationAuditLogModel>> getAuditLogs({
    String? action,
    String? resourceType,
    int page = 1,
    int perPage = 20,
  });

  // ── Dashboard ─────────────────────────────────────────────────────────
  Future<CommunicationDashboardModel> getCommunicationDashboard();

  // ── Typing & Presence ─────────────────────────────────────────────────
  Future<void> setTyping({
    required String conversationId,
    required bool isTyping,
  });

  Future<void> updatePresence({
    required bool isOnline,
  });
}

class CommunicationRemoteDataSourceImpl
    implements CommunicationRemoteDataSource {
  CommunicationRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _conversationsTable = 'conversations';
  static const _participantsTable = 'conversation_participants';
  static const _messagesTable = 'messages';
  static const _reactionsTable = 'message_reactions';
  static const _attachmentsTable = 'message_attachments';
  static const _announcementsTable = 'announcements';
  static const _notificationsTable = 'communication_notifications';
  static const _notificationPrefsTable = 'notification_preferences';
  static const _forumsTable = 'discussion_forums';
  static const _forumPostsTable = 'forum_posts';
  static const _forumCommentsTable = 'forum_comments';
  static const _calendarEventsTable = 'calendar_events';
  static const _eventRsvpsTable = 'calendar_event_rsvps';
  static const _knowledgeDocsTable = 'school_knowledge_documents';
  static const _auditLogsTable = 'communication_audit_logs';
  static const _blockedUsersTable = 'blocked_users';
  static const _messageReportsTable = 'message_reports';

  // ── Exception mapping helper ───────────────────────────────────────────
  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(e.message);
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
          statusCode: int.tryParse(e.code ?? '') ?? 500,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching conversations (page: $page, perPage: $perPage)');
      final response = await _supabase.rpc(
        'get_user_conversations',
        params: {
          'p_user_id': _supabase.auth.currentUser?.id,
          'p_page': page,
          'p_per_page': perPage,
        },
      );
      final list = response as List<dynamic>;
      AppLogger.info('Fetched ${list.length} conversations');
      return list
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch conversations', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ConversationModel> getConversation(String conversationId) async {
    try {
      AppLogger.info('Fetching conversation: $conversationId');
      final response = await _supabase
          .from(_conversationsTable)
          .select('*, participants:$_participantsTable(*)')
          .eq('id', conversationId)
          .single();
      AppLogger.info('Conversation fetched successfully');
      return ConversationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(
          message: 'Conversation not found: $conversationId',
        );
      }
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch conversation: $conversationId', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ConversationModel> createConversation(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating conversation');
      final response = await _supabase
          .from(_conversationsTable)
          .insert(data)
          .select('*, participants:$_participantsTable(*)')
          .single();
      AppLogger.info('Conversation created successfully');
      return ConversationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create conversation', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ConversationModel> updateConversation(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating conversation: $conversationId');
      final response = await _supabase
          .from(_conversationsTable)
          .update(data)
          .eq('id', conversationId)
          .select('*, participants:$_participantsTable(*)')
          .single();
      AppLogger.info('Conversation updated successfully');
      return ConversationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update conversation: $conversationId', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      AppLogger.info('Adding participant $userId to conversation $conversationId');
      await _supabase.from(_participantsTable).insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': role,
        'school_id': _supabase.auth.currentUser?.id,
        'user_role': 'member',
      });
      AppLogger.info('Participant added successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to add participant', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      AppLogger.info('Removing participant $userId from conversation $conversationId');
      await _supabase
          .from(_participantsTable)
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
      AppLogger.info('Participant removed successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to remove participant', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      AppLogger.info('Leaving conversation: $conversationId');
      await _supabase
          .from(_participantsTable)
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
      AppLogger.info('Left conversation successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to leave conversation', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int page = 1,
    int perPage = 50,
    DateTime? before,
  }) async {
    try {
      AppLogger.info('Fetching messages for conversation: $conversationId');
      final response = await _supabase.rpc(
        'get_conversation_messages',
        params: {
          'p_conversation_id': conversationId,
          'p_page': page,
          'p_per_page': perPage,
          if (before != null) 'p_before': before.toIso8601String(),
        },
      );
      final list = response as List<dynamic>;
      AppLogger.info('Fetched ${list.length} messages');
      return list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch messages', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<MessageModel> sendMessage(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Sending message');
      final response = await _supabase
          .from(_messagesTable)
          .insert(data)
          .select('*, reactions:$_reactionsTable(*), attachments:$_attachmentsTable(*)')
          .single();
      AppLogger.info('Message sent successfully');
      return MessageModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to send message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<MessageModel> editMessage({
    required String messageId,
    required String body,
  }) async {
    try {
      AppLogger.info('Editing message: $messageId');
      final response = await _supabase
          .from(_messagesTable)
          .update({
            'body': body,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .select('*, reactions:$_reactionsTable(*), attachments:$_attachmentsTable(*)')
          .single();
      AppLogger.info('Message edited successfully');
      return MessageModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to edit message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      AppLogger.info('Deleting message: $messageId');
      await _supabase
          .from(_messagesTable)
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': _supabase.auth.currentUser?.id,
          })
          .eq('id', messageId);
      AppLogger.info('Message deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> pinMessage(String messageId) async {
    try {
      AppLogger.info('Pinning message: $messageId');
      await _supabase
          .from(_messagesTable)
          .update({
            'is_pinned': true,
            'pinned_at': DateTime.now().toIso8601String(),
            'pinned_by': _supabase.auth.currentUser?.id,
          })
          .eq('id', messageId);
      AppLogger.info('Message pinned successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to pin message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> unpinMessage(String messageId) async {
    try {
      AppLogger.info('Unpinning message: $messageId');
      await _supabase
          .from(_messagesTable)
          .update({
            'is_pinned': false,
            'pinned_at': null,
            'pinned_by': null,
          })
          .eq('id', messageId);
      AppLogger.info('Message unpinned successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to unpin message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      AppLogger.info('Marking message $messageId as read in conversation $conversationId');
      await _supabase
          .from(_participantsTable)
          .update({
            'last_read_message_id': messageId,
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
      AppLogger.info('Message marked as read');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to mark message as read', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE REACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      AppLogger.info('Adding reaction $emoji to message $messageId');
      await _supabase.from(_reactionsTable).insert({
        'message_id': messageId,
        'user_id': _supabase.auth.currentUser?.id,
        'emoji': emoji,
      });
      AppLogger.info('Reaction added successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to add reaction', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      AppLogger.info('Removing reaction $emoji from message $messageId');
      await _supabase
          .from(_reactionsTable)
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .eq('emoji', emoji);
      AppLogger.info('Reaction removed successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to remove reaction', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<AnnouncementModel>> getAnnouncements({
    String? type,
    String? priority,
    bool publishedOnly = true,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching announcements');
      var query = _supabase
          .from(_announcementsTable)
          .select()
          .order('created_at', ascending: false)
          .range((page - 1) * perPage, page * perPage - 1);

      if (publishedOnly) {
        query = query.eq('is_published', true);
      }
      if (type != null) {
        query = query.eq('announcement_type', type);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} announcements');
      return response
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch announcements', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AnnouncementModel> getAnnouncement(String announcementId) async {
    try {
      AppLogger.info('Fetching announcement: $announcementId');
      final response = await _supabase
          .from(_announcementsTable)
          .select()
          .eq('id', announcementId)
          .single();
      AppLogger.info('Announcement fetched successfully');
      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(
          message: 'Announcement not found: $announcementId',
        );
      }
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch announcement', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating announcement');
      final response = await _supabase
          .from(_announcementsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Announcement created successfully');
      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create announcement', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AnnouncementModel> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating announcement: $announcementId');
      final response = await _supabase
          .from(_announcementsTable)
          .update(data)
          .eq('id', announcementId)
          .select()
          .single();
      AppLogger.info('Announcement updated successfully');
      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update announcement', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      AppLogger.info('Deleting announcement: $announcementId');
      await _supabase
          .from(_announcementsTable)
          .delete()
          .eq('id', announcementId);
      AppLogger.info('Announcement deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete announcement', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> acknowledgeAnnouncement(String announcementId) async {
    try {
      AppLogger.info('Acknowledging announcement: $announcementId');
      await _supabase.rpc(
        'acknowledge_announcement',
        params: {
          'p_announcement_id': announcementId,
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('Announcement acknowledged successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to acknowledge announcement', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<CommunicationNotificationModel>> getNotifications({
    String? category,
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching notifications');
      var query = _supabase
          .from(_notificationsTable)
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .order('created_at', ascending: false)
          .range((page - 1) * perPage, page * perPage - 1);

      if (category != null) {
        query = query.eq('category', category);
      }
      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} notifications');
      return response
          .map((e) =>
              CommunicationNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch notifications', error: e);
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
      AppLogger.info('Notification marked as read');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    try {
      AppLogger.info('Marking all notifications as read');
      await _supabase
          .from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .eq('is_read', false);
      AppLogger.info('All notifications marked as read');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<NotificationPreferencesModel> getNotificationPreferences() async {
    try {
      AppLogger.info('Fetching notification preferences');
      final response = await _supabase
          .from(_notificationPrefsTable)
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .single();
      AppLogger.info('Notification preferences fetched successfully');
      return NotificationPreferencesModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No preferences found, return defaults
        return NotificationPreferencesModel(
          id: '',
          userId: _supabase.auth.currentUser?.id ?? '',
          schoolId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch notification preferences', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<NotificationPreferencesModel> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      AppLogger.info('Updating notification preferences');
      final response = await _supabase
          .from(_notificationPrefsTable)
          .upsert({
            'user_id': _supabase.auth.currentUser?.id,
            ...preferences,
          })
          .select()
          .single();
      AppLogger.info('Notification preferences updated successfully');
      return NotificationPreferencesModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update notification preferences', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCUSSION FORUMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<DiscussionForumModel>> getForums({
    String? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching forums');
      var query = _supabase
          .from(_forumsTable)
          .select()
          .order('last_activity_at', ascending: false, nullsFirst: true)
          .range((page - 1) * perPage, page * perPage - 1);

      if (type != null) {
        query = query.eq('forum_type', type);
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} forums');
      return response
          .map((e) => DiscussionForumModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch forums', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<DiscussionForumModel> getForum(String forumId) async {
    try {
      AppLogger.info('Fetching forum: $forumId');
      final response = await _supabase
          .from(_forumsTable)
          .select()
          .eq('id', forumId)
          .single();
      AppLogger.info('Forum fetched successfully');
      return DiscussionForumModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Forum not found: $forumId');
      }
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch forum', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<DiscussionForumModel> createForum(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating forum');
      final response = await _supabase
          .from(_forumsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Forum created successfully');
      return DiscussionForumModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create forum', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM POSTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ForumPostModel>> getForumPosts({
    required String forumId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching posts for forum: $forumId');
      final response = await _supabase
          .from(_forumPostsTable)
          .select('*, comments:$_forumCommentsTable(*)')
          .eq('forum_id', forumId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} forum posts');
      return response
          .map((e) => ForumPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch forum posts', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ForumPostModel> createForumPost(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating forum post');
      final response = await _supabase
          .from(_forumPostsTable)
          .insert(data)
          .select('*, comments:$_forumCommentsTable(*)')
          .single();
      AppLogger.info('Forum post created successfully');
      return ForumPostModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create forum post', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ForumPostModel> updateForumPost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating forum post: $postId');
      final response = await _supabase
          .from(_forumPostsTable)
          .update(data)
          .eq('id', postId)
          .select('*, comments:$_forumCommentsTable(*)')
          .single();
      AppLogger.info('Forum post updated successfully');
      return ForumPostModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update forum post', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteForumPost(String postId) async {
    try {
      AppLogger.info('Deleting forum post: $postId');
      await _supabase
          .from(_forumPostsTable)
          .delete()
          .eq('id', postId);
      AppLogger.info('Forum post deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete forum post', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM COMMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<ForumCommentModel>> getForumComments({
    required String postId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching comments for post: $postId');
      final response = await _supabase
          .from(_forumCommentsTable)
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} forum comments');
      return response
          .map((e) => ForumCommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch forum comments', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ForumCommentModel> createForumComment(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating forum comment');
      final response = await _supabase
          .from(_forumCommentsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Forum comment created successfully');
      return ForumCommentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create forum comment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<CalendarEventModel>> getCalendarEvents({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching calendar events');
      var query = _supabase
          .from(_calendarEventsTable)
          .select()
          .order('start_time', ascending: true)
          .range((page - 1) * perPage, page * perPage - 1);

      if (type != null) {
        query = query.eq('event_type', type);
      }
      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} calendar events');
      return response
          .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch calendar events', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CalendarEventModel> createCalendarEvent(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating calendar event');
      final response = await _supabase
          .from(_calendarEventsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Calendar event created successfully');
      return CalendarEventModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create calendar event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CalendarEventModel> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating calendar event: $eventId');
      final response = await _supabase
          .from(_calendarEventsTable)
          .update(data)
          .eq('id', eventId)
          .select()
          .single();
      AppLogger.info('Calendar event updated successfully');
      return CalendarEventModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update calendar event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      AppLogger.info('Deleting calendar event: $eventId');
      await _supabase
          .from(_calendarEventsTable)
          .delete()
          .eq('id', eventId);
      AppLogger.info('Calendar event deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete calendar event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> rsvpToEvent({
    required String eventId,
    required String status,
  }) async {
    try {
      AppLogger.info('RSVP to event: $eventId with status: $status');
      await _supabase.from(_eventRsvpsTable).upsert({
        'event_id': eventId,
        'user_id': _supabase.auth.currentUser?.id,
        'status': status,
      });
      AppLogger.info('RSVP recorded successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to RSVP to event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI COMMUNICATION ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<AiCommunicationAssistantModel> draftAnnouncement(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Drafting announcement');
      final response = await _supabase.rpc(
        'ai_draft_announcement',
        params: {
          'p_topic': params['topic'],
          'p_audience': params['audience'],
          'p_tone': params['tone'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI announcement drafted successfully');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to draft announcement via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> rewriteMessage(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Rewriting message');
      final response = await _supabase.rpc(
        'ai_rewrite_message',
        params: {
          'p_text': params['text'],
          'p_tone': params['tone'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI message rewritten successfully');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to rewrite message via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> summarizeConversation(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Summarizing conversation');
      final response = await _supabase.rpc(
        'ai_summarize_conversation',
        params: {
          'p_conversation_id': params['conversation_id'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI conversation summarized successfully');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to summarize conversation via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> translateMessage(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Translating message');
      final response = await _supabase.rpc(
        'ai_translate_message',
        params: {
          'p_text': params['text'],
          'p_target_language': params['target_language'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI message translated successfully');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to translate message via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> suggestReply(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Suggesting reply');
      final response = await _supabase.rpc(
        'ai_suggest_reply',
        params: {
          'p_conversation_id': params['conversation_id'],
          'p_message_id': params['message_id'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI reply suggested successfully');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to suggest reply via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> correctGrammar(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Correcting grammar');
      final response = await _supabase.rpc(
        'ai_correct_grammar',
        params: {
          'p_text': params['text'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI grammar correction completed');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to correct grammar via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiCommunicationAssistantModel> adjustTone(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Adjusting tone');
      final response = await _supabase.rpc(
        'ai_adjust_tone',
        params: {
          'p_text': params['text'],
          'p_target_tone': params['target_tone'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI tone adjustment completed');
      return AiCommunicationAssistantModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to adjust tone via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI SCHOOL KNOWLEDGE ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<AiSchoolKnowledgeResponseModel> askSchoolKnowledge(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('AI: Asking school knowledge');
      final response = await _supabase.rpc(
        'search_school_knowledge',
        params: {
          'p_query': params['query'],
          'p_user_id': _supabase.auth.currentUser?.id,
        },
      );
      AppLogger.info('AI school knowledge response received');
      return AiSchoolKnowledgeResponseModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to ask school knowledge via AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<SchoolKnowledgeDocumentModel>> getKnowledgeDocuments({
    String? documentType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching knowledge documents');
      var query = _supabase
          .from(_knowledgeDocsTable)
          .select()
          .order('created_at', ascending: false)
          .range((page - 1) * perPage, page * perPage - 1);

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} knowledge documents');
      return response
          .map((e) =>
              SchoolKnowledgeDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch knowledge documents', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<SchoolKnowledgeDocumentModel> uploadKnowledgeDocument(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Uploading knowledge document');
      final response = await _supabase
          .from(_knowledgeDocsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Knowledge document uploaded successfully');
      return SchoolKnowledgeDocumentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to upload knowledge document', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteKnowledgeDocument(String documentId) async {
    try {
      AppLogger.info('Deleting knowledge document: $documentId');
      await _supabase
          .from(_knowledgeDocsTable)
          .delete()
          .eq('id', documentId);
      AppLogger.info('Knowledge document deleted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete knowledge document', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILE SHARING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<MessageAttachmentModel> uploadAttachment(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Uploading attachment');
      final response = await _supabase
          .from(_attachmentsTable)
          .insert(data)
          .select()
          .single();
      AppLogger.info('Attachment uploaded successfully');
      return MessageAttachmentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to upload attachment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MODERATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<void> reportMessage({
    required String messageId,
    required String reason,
  }) async {
    try {
      AppLogger.info('Reporting message: $messageId');
      await _supabase.from(_messageReportsTable).insert({
        'message_id': messageId,
        'reporter_id': _supabase.auth.currentUser?.id,
        'reason': reason,
      });
      AppLogger.info('Message reported successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to report message', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> blockUser({required String userId}) async {
    try {
      AppLogger.info('Blocking user: $userId');
      await _supabase.from(_blockedUsersTable).insert({
        'blocker_id': _supabase.auth.currentUser?.id,
        'blocked_id': userId,
      });
      AppLogger.info('User blocked successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to block user', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    try {
      AppLogger.info('Muting conversation: $conversationId');
      await _supabase
          .from(_participantsTable)
          .update({'is_muted': true})
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
      AppLogger.info('Conversation muted successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to mute conversation', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> archiveConversation(String conversationId) async {
    try {
      AppLogger.info('Archiving conversation: $conversationId');
      await _supabase
          .from(_participantsTable)
          .update({'is_archived': true})
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
      AppLogger.info('Conversation archived successfully');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to archive conversation', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<CommunicationAuditLogModel>> getAuditLogs({
    String? action,
    String? resourceType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      AppLogger.info('Fetching audit logs');
      var query = _supabase
          .from(_auditLogsTable)
          .select()
          .order('created_at', ascending: false)
          .range((page - 1) * perPage, page * perPage - 1);

      if (action != null) {
        query = query.eq('action', action);
      }
      if (resourceType != null) {
        query = query.eq('resource_type', resourceType);
      }

      final response = await query;
      AppLogger.info('Fetched ${response.length} audit logs');
      return response
          .map((e) =>
              CommunicationAuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch audit logs', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<CommunicationDashboardModel> getCommunicationDashboard() async {
    try {
      AppLogger.info('Fetching communication dashboard');
      final response = await _supabase.rpc(
        'get_communication_dashboard',
        params: {'p_user_id': _supabase.auth.currentUser?.id},
      );
      AppLogger.info('Communication dashboard fetched successfully');
      return CommunicationDashboardModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch communication dashboard', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPING & PRESENCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<void> setTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      AppLogger.debug('Setting typing: $isTyping for conversation: $conversationId');
      await _supabase
          .from(_participantsTable)
          .update({
            'is_typing': isTyping,
            'typing_at': isTyping ? DateTime.now().toIso8601String() : null,
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to set typing status', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> updatePresence({required bool isOnline}) async {
    try {
      AppLogger.debug('Updating presence: isOnline=$isOnline');
      await _supabase
          .from(_participantsTable)
          .update({
            'is_online': isOnline,
            'last_seen_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update presence', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }
}
