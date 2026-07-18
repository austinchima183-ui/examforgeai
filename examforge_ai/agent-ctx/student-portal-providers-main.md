# Student Portal Providers — Work Log

## Task ID: student-portal-providers-main

## Summary
Created the complete presentation layer providers for the Student Portal feature of ExamForge AI, following the existing Riverpod StateNotifierProvider pattern used throughout the codebase.

## Files Created

### Provider Files (12 files)
All located at: `lib/features/student_portal/presentation/providers/`

1. **student_dashboard_provider.dart** — Main dashboard state with parallel data loading (stats, conversations, notifications, assignments, practice sessions). Includes `currentStudentIdProvider` shared by all other providers.

2. **ai_tutor_provider.dart** — AI Tutor conversations CRUD, message sending, pagination with `hasMoreConversations`.

3. **practice_provider.dart** — Practice session lifecycle (create, open, submit answers, navigate questions, complete, abandon). Includes timed mode with countdown timer via `Timer.periodic`.

4. **assignment_provider.dart** — Assignment submission management with status filtering (`filterByStatus`), pagination, create/submit flows.

5. **resource_provider.dart** — Learning resources with multi-filter support (type, subject, search query), access logging. Includes `studentSchoolIdProvider`.

6. **document_chat_provider.dart** — Document upload with progress tracking, document chat messaging, status-aware chat readiness checks.

7. **flashcard_provider.dart** — Flashcard deck CRUD, study sessions with due-card loading, SM-2 spaced repetition via `RateFlashcardUseCase`, AI flashcard generation.

8. **study_planner_provider.dart** — Study plans with AI suggestion, task management, date-based filtering, plan/task CRUD.

9. **goals_provider.dart** — Student goal management with status filtering, progress tracking, computed `averageProgress` and `activeGoalCount`.

10. **progress_provider.dart** — Progress & analytics with parallel loading (history + latest snapshot), daily activity, period/subject selectors. Uses repository directly for `getDailyActivity`.

11. **student_notification_provider.dart** — Notification management with optimistic updates for mark-as-read operations, pagination, unread count tracking.

12. **student_portal_providers.dart** — Barrel file exporting all provider classes, states, and notifiers.

## Modified Files

### `student_portal_usecases.dart`
- Added `GetSubmissionDetailUseCase` (for assignment detail viewing)
- Renamed `GetResourcesUseCase` → `GetStudentResourcesUseCase` (to avoid naming conflict with teacher workspace)
- Added `GetDocumentDetailUseCase`, `DeleteDocumentUseCase`, `DeleteFlashcardUseCase`, `CreateStudyTaskUseCase`, `DeleteStudyTaskUseCase`, `DeleteGoalUseCase`, `GetDailyActivityUseCase`

### `dependency_injection.dart`
- Added 16 import lines for student portal data/domain/presentation layers
- Added data layer providers: `studentPortalRemoteDataSourceProvider`, `studentPortalRepositoryProvider`
- Added 40+ use case providers covering all student portal operations
- Used `hide GenerateQuestionsFromContentUseCase` on the student portal usecases import to avoid naming conflict with teacher workspace

## Architecture Decisions

1. **Shared Auth Providers**: All providers read `currentStudentIdProvider` from `student_dashboard_provider.dart` (which delegates to `userIdProvider` from `auth_state_provider.dart`).

2. **Naming Conflicts Resolved**: Renamed `GetResourcesUseCase` to `GetStudentResourcesUseCase` and the DI provider to `studentGetResourcesUseCaseProvider` to avoid collision with the teacher workspace's identically-named use case.

3. **Timer Management**: `PracticeNotifier` manages a `Timer.periodic` for timed practice mode, with proper cleanup in `dispose()`.

4. **Optimistic Updates**: `StudentNotificationNotifier` uses optimistic updates for mark-as-read operations with rollback on failure.

5. **Parallel Loading**: `StudentDashboardNotifier` uses `Future.wait` for parallel data loading, and `ProgressNotifier` loads history + latest snapshot simultaneously.

6. **Repository Access**: `ProgressNotifier` directly uses `StudentPortalRepository` for `getDailyActivity` since no dedicated use case existed and adding one would be over-engineering for a single method.
