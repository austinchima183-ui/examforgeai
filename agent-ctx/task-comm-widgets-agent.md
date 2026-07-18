# Task: Communication Presentation Widgets

## Summary
Created 15 presentation widget files for the ExamForge AI Communication module at
`/home/z/my-project/examforge_ai/lib/features/communication/presentation/widgets/`.

## Files Created

| # | File | Lines | Description |
|---|------|-------|-------------|
| 1 | `conversation_tile.dart` | 282 | Conversation preview with avatar, name, last message, time, unread badge (99+), muted/pinned icons, online indicator |
| 2 | `message_bubble.dart` | 381 | Chat bubble with sent/received alignment, reply preview, reactions row, attachment previews, read receipts, long-press context menu |
| 3 | `announcement_card.dart` | 248 | Announcement card with type/priority badges, author, time, view count, acknowledge button |
| 4 | `notification_tile.dart` | 198 | Notification list tile with category icon, color-coding, read/unread dot, mark-read action |
| 5 | `forum_card.dart` | 199 | Forum preview card with name, description, type badge, member/post counts, last activity |
| 6 | `forum_post_card.dart` | 205 | Forum post card with author avatar, title, body excerpt, comment/like counts, pinned indicator |
| 7 | `event_card.dart` | 281 | Calendar event card with type badge, time range, location, RSVP status, attendee count |
| 8 | `typing_indicator.dart` | 132 | Animated bouncing dots with typing user names label |
| 9 | `online_status_indicator.dart` | 54 | Small dot indicator: green=online, grey=offline |
| 10 | `message_input.dart` | 260 | Auto-growing text field, send/attach/voice buttons, reply preview bar |
| 11 | `reaction_picker.dart` | 122 | Emoji picker bottom sheet with 8 common emojis |
| 12 | `attachment_preview.dart` | 194 | File attachment preview with type icon, name, size, image thumbnail, download indicator |
| 13 | `priority_badge.dart` | 110 | Color-coded priority badge: low=grey, normal=blue, high=orange, urgent=red |
| 14 | `knowledge_source_card.dart` | 212 | AI Knowledge source card with doc icon, title, type, relevance score bar, snippet |
| 15 | `communication_widgets.dart` | 30 | Barrel export file |

## Design Patterns Used
- **AppColors, AppTypography, Spacings** from core themes (Indigo seed color, Material 3)
- **context_extensions.dart** for `context.colorScheme`, `context.textTheme`, `context.isDarkMode`
- **AppCard** shared widget for consistent card styling
- **Private builder methods** for complex sections (`_buildTypeBadge`, `_buildReplyPreview`, etc.)
- **Relative time formatting** helper consistent with existing codebase
- **Entity-typed props** (not dynamic) for type safety
