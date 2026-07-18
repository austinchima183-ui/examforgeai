# Communication Domain Use Cases Creation

## Task
Created 42 use case files for the ExamForge AI Communication module at `/home/z/my-project/examforge_ai/lib/features/communication/domain/usecases/`.

## Pattern Applied
Each use case follows the clean architecture pattern:
- **Params class** extending `Equatable` with `const` constructor and `props` override
- **UseCase class** with repository dependency via constructor injection
- **`call()` method** returning `Future<Result<T>>`
- **Input validation** before delegating to repository, returning `FailureResult(Failure.validation(...))` for invalid inputs

## Files Created (42 total)

### Conversations (2)
1. `get_conversations_usecase.dart` - Validates page/perPage bounds
2. `create_conversation_usecase.dart` - Validates non-empty name and participants

### Messages (7)
3. `get_messages_usecase.dart` - Validates conversationId, page/perPage
4. `send_message_usecase.dart` - Validates conversationId and non-empty body
5. `edit_message_usecase.dart` - Validates messageId and non-empty body
6. `delete_message_usecase.dart` - Validates non-empty messageId
7. `pin_message_usecase.dart` - Validates messageId, routes to pin/unpin based on isPinned
8. `add_reaction_usecase.dart` - Validates messageId and non-empty emoji
9. `mark_as_read_usecase.dart` - Validates both conversationId and messageId

### Announcements (3)
10. `get_announcements_usecase.dart` - Validates page/perPage bounds
11. `create_announcement_usecase.dart` - Validates title, body, and scheduledAt when isScheduled
12. `acknowledge_announcement_usecase.dart` - Validates non-empty announcementId

### Notifications (5)
13. `get_notifications_usecase.dart` - Validates page/perPage bounds
14. `mark_notification_read_usecase.dart` - Validates non-empty notificationId
15. `mark_all_notifications_read_usecase.dart` - No params needed
16. `get_notification_preferences_usecase.dart` - No params needed
17. `update_notification_preferences_usecase.dart` - Validates non-empty preferences map

### Forums (5)
18. `get_forums_usecase.dart` - Validates page/perPage bounds
19. `create_forum_usecase.dart` - Validates non-empty forum name
20. `get_forum_posts_usecase.dart` - Validates forumId, page/perPage
21. `create_forum_post_usecase.dart` - Validates forumId, title, body
22. `create_forum_comment_usecase.dart` - Validates postId, forumId, body

### Calendar Events (3)
23. `get_calendar_events_usecase.dart` - Validates page/perPage and endDate > startDate
24. `create_calendar_event_usecase.dart` - Validates title and endTime > startTime (when not all-day)
25. `rsvp_to_event_usecase.dart` - Validates eventId and valid RSVP status

### AI Communication Assistant (7)
26. `ai_draft_announcement_usecase.dart` - Validates non-empty topic
27. `ai_rewrite_message_usecase.dart` - Validates non-empty text
28. `ai_summarize_conversation_usecase.dart` - Validates non-empty conversationId
29. `ai_translate_message_usecase.dart` - Validates text and targetLanguage
30. `ai_suggest_reply_usecase.dart` - Validates conversationId and messageId
31. `ai_correct_grammar_usecase.dart` - Validates non-empty text
32. `ai_adjust_tone_usecase.dart` - Validates text and targetTone

### AI School Knowledge (3)
33. `ask_school_knowledge_usecase.dart` - Validates non-empty query
34. `get_knowledge_documents_usecase.dart` - Validates page/perPage bounds
35. `upload_knowledge_document_usecase.dart` - Validates title, fileName, fileUrl

### Moderation (3)
36. `report_message_usecase.dart` - Validates messageId and reason
37. `mute_conversation_usecase.dart` - Validates non-empty conversationId
38. `archive_conversation_usecase.dart` - Validates non-empty conversationId

### Admin & Dashboard (2)
39. `get_audit_logs_usecase.dart` - Validates page/perPage bounds
40. `get_communication_dashboard_usecase.dart` - No params, direct repository call

### Presence & Typing (2)
41. `set_typing_usecase.dart` - Validates non-empty conversationId
42. `update_presence_usecase.dart` - Takes isOnline bool, no validation needed

## Key Design Decisions
- All `Params` classes use `Equatable` for value equality
- Page/perPage validation: page >= 1, perPage between 1-100
- String ID validation: checks `.trim().isEmpty` to reject whitespace-only values
- PinMessageUseCase routes to `pinMessage()` or `unpinMessage()` based on `isPinned` boolean
- RsvpToEventUseCase validates status against accepted values: accepted, declined, tentative
- CreateAnnouncementUseCase cross-validates `isScheduled` with `scheduledAt`
- CreateCalendarEventUseCase cross-validates `endTime > startTime` (only when not all-day)
- GetCalendarEventsUseCase cross-validates `endDate > startDate` when both provided
