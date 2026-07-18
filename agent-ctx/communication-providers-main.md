# Task: Communication Module Presentation Providers

## Agent: Main Developer

## Summary

Created 10 production-ready StateNotifier provider files for the ExamForge AI Communication module at `/home/z/my-project/examforge_ai/lib/features/communication/presentation/providers/`.

All files follow the exact pattern from the existing Parent Portal messaging provider (`parent_messaging_provider.dart`):

- **Immutable State class** with `const` constructor, `copyWith()`, and `clearError()`
- **StateNotifier** with use case injection via named constructor parameters
- **Methods**: set isLoading → call use case → fold onSuccess/onFailure → update state
- **`_mapFailureToMessage(Failure failure)`** using `failure.when()` exhaustive matching
- **`StateNotifierProvider`** at the bottom with placeholder provider names for dependency injection

## Files Created

1. **`conversation_provider.dart`** — ConversationState + ConversationNotifier
   - State: conversations, currentConversation, isLoading, isCreating, error, successMessage, unreadTotalCount
   - Methods: loadConversations(), loadConversation(id), createConversation(params), muteConversation(id), archiveConversation(id), leaveConversation(id), clearError()

2. **`message_provider.dart`** — MessageState + MessageNotifier
   - State: messages, isLoading, isSending, isEditing, error, successMessage, currentConversationId, hasMoreMessages, pinnedMessages
   - Methods: loadMessages(conversationId), loadMoreMessages(), sendMessage(params), editMessage(params), deleteMessage(id), pinMessage(id, isPinned), markAsRead(conversationId, messageId), addReaction(messageId, emoji), removeReaction(messageId, emoji), clearError()

3. **`announcement_provider.dart`** — AnnouncementState + AnnouncementNotifier
   - State: announcements, currentAnnouncement, isLoading, isCreating, error, successMessage
   - Methods: loadAnnouncements(params), loadAnnouncement(id), createAnnouncement(params), updateAnnouncement(id, data), acknowledgeAnnouncement(id), clearError()

4. **`notification_provider.dart`** — NotificationState + NotificationNotifier
   - State: notifications, isLoading, error, unreadCount, preferences
   - Methods: loadNotifications(params), markRead(id), markAllRead(), loadPreferences(), updatePreferences(prefs), clearError()

5. **`forum_provider.dart`** — ForumState + ForumNotifier
   - State: forums, currentForum, forumPosts, forumComments, isLoading, isCreating, error, successMessage
   - Methods: loadForums(params), loadForum(id), createForum(params), loadForumPosts(forumId), createForumPost(params), loadForumComments(postId), createForumComment(params), clearError()

6. **`calendar_provider.dart`** — CalendarState + CalendarNotifier
   - State: events, currentEvent, isLoading, isCreating, error, successMessage
   - Methods: loadEvents(params), createEvent(params), updateEvent(id, data), deleteEvent(id), rsvpToEvent(eventId, status), clearError()

7. **`ai_assistant_provider.dart`** — AiAssistantState + AiAssistantNotifier
   - State: response, isLoading, error, conversationHistory (list of AiAssistantExchange)
   - Methods: draftAnnouncement(params), rewriteMessage(params), summarizeConversation(conversationId), translateMessage(params), suggestReply(params), correctGrammar(params), adjustTone(params), clearResponse(), clearError()

8. **`knowledge_assistant_provider.dart`** — KnowledgeAssistantState + KnowledgeAssistantNotifier
   - State: response, documents, isLoading, error, searchHistory (list of KnowledgeSearchEntry)
   - Methods: askQuestion(query), loadDocuments(params), uploadDocument(params), deleteDocument(id), clearResponse(), clearError()

9. **`communication_dashboard_provider.dart`** — CommunicationDashboardState + CommunicationDashboardNotifier
   - State: dashboardData, isLoading, error
   - Methods: loadDashboard(), clearError()

10. **`moderation_provider.dart`** — ModerationState + ModerationNotifier
    - State: auditLogs, isLoading, isReporting, error, successMessage
    - Methods: reportMessage(params), muteConversation(id), archiveConversation(id), loadAuditLogs(params), clearError()

## Key Design Decisions

- All entities imported from `../../domain/entities/communication_entities.dart`
- All use cases imported from their individual files under `../../domain/usecases/`
- `failure.when()` exhaustive matching with all 8 failure types (server, cache, auth, network, validation, notFound, unauthorized, forbidden)
- `AppLogger.info()` for success logs, `AppLogger.warning()` for failure logs
- StateNotifierProvider uses placeholder provider names (e.g., `getConversationsUseCaseProvider`) to be wired in `dependency_injection.dart`
- Special `clearX` boolean flags in copyWith for nullable fields (e.g., `clearCurrentConversation`, `clearResponse`)
- Pagination state tracked in message_provider via `_currentPage` and `hasMoreMessages`
