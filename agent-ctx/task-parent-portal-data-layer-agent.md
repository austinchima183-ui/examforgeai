# Task: Parent Portal Data Layer Creation

## Summary
Created the complete data layer for the Parent Portal module of ExamForge AI, consisting of 3 primary files and 1 supplementary update.

## Files Created

### 1. `lib/features/parent_portal/data/models/parent_portal_models.dart`
- **9 model classes** with const constructors, final fields, `fromJson()`, `toJson()`, `fromEntity()`, and `toEntity()` methods
- Models: ParentMessageModel, ParentNotificationModel, ParentActivityLogModel, ParentAiInsightModel, ParentReportDownloadModel, ParentCalendarEventModel, EngagementMetricModel, ParentDashboardModel, ChildPerformanceModel
- All `fromJson` handle both snake_case (from API) and camelCase (from internal) keys
- All `toJson` output snake_case for Supabase compatibility
- Nested entity reconstruction in `ParentDashboardModel.toEntity()` (children → ChildSummaryEntity, upcomingEvents → CalendarEventEntity, recentAnnouncements → AnnouncementSummaryEntity)
- Nested entity reconstruction in `ChildPerformanceModel.toEntity()` (subjects → SubjectPerformanceEntity, teacherRemarks → TeacherRemarkEntity)

### 2. `lib/features/parent_portal/data/datasources/parent_portal_remote_datasource.dart`
- **Abstract class** with 18 methods covering dashboard, child profile, performance, attendance, assignments, messages, notifications, calendar, AI assistant, AI insights, reports/downloads, and engagement
- **Supabase implementation** using `_supabase.rpc()` for RPC calls (`get_parent_dashboard`, `get_child_performance`, `get_parent_message_threads`, `ask_parent_assistant`, `get_parent_engagement_analytics`) and `_supabase.from().insert/select/update` for standard CRUD
- Table constants: `parent_messages`, `parent_notifications`, `parent_activity_logs`, `parent_ai_insights`, `parent_report_downloads`, `parent_calendar_events`, `parent_engagement_metrics`
- `_mapPostgrestException` helper maps Postgrest error codes to domain exceptions
- All methods wrapped in try/catch with AppLogger for observability

### 3. `lib/features/parent_portal/data/repositories/parent_portal_repository_impl.dart`
- Implements `ParentPortalRepository` interface (18 methods)
- Each method: calls datasource → converts model to entity → wraps in `Result.success/failure`
- `_mapExceptionToFailure` helper maps all exception types to Failure variants:
  - AuthException → Failure.auth()
  - ServerException → Failure.server()
  - CacheException → Failure.cache()
  - NetworkException → Failure.network()
  - ValidationException → Failure.validation()
  - NotFoundException → Failure.notFound()
  - UnauthorizedException → Failure.unauthorized()
  - ForbiddenException → Failure.forbidden()
  - Other → Failure.server()
- Complex entity reconstruction for `EngagementAnalyticsEntity` (nested StudentSupportEntity and EngagementTrendEntity lists)
- Message thread reconstruction with nested `ParentMessageModel.fromJson` for last message

### 4. Supplementary: `lib/features/parent_portal/domain/entities/parent_portal_entities.dart` (updated)
- Added 4 missing entity classes referenced by the repository interface:
  - `ChildProfileEntity` (studentId, firstName, lastName, admissionNumber, avatarUrl, className, relationship, isPrimaryContact)
  - `ChildAttendanceEntity` (studentId, records, startDate, endDate)
  - `ChildAssignmentEntity` (id, assignmentId, studentId, status, submittedAt, score, title, description, dueDate, subjectName)
  - `ParentAssistantResponseEntity` (answer, sources, studentId, followUpQuestions, confidence)

## Design Patterns Followed
- Clean Architecture: data layer depends on domain layer (never the reverse)
- Model ↔ Entity conversion keeps domain layer free of serialization concerns
- Result type for compile-time error handling across boundaries
- Exception → Failure mapping at repository boundary
- Snake_case JSON keys for Supabase, dual-key parsing in fromJson for flexibility
