# CBT Engine Data Layer & Service Layer

## Task ID: cbt-engine-data-service-main

## Summary
Created the complete Data Layer and CBT Service Layer for the ExamForge AI CBT Engine module.

## Files Created

### Data Layer (3 files)
1. **`lib/features/cbt_engine/data/models/cbt_models.dart`** - All CBT data models:
   - ExamModel, ExamSectionModel, ExamQuestionModel, ExamStudentModel
   - ExamAttemptModel, StudentAnswerModel, ExamSessionModel
   - MonitoringLogModel, ExamResultModel, ExamRankingModel
   - ExamNotificationModel, GradeScaleEntryModel, GradeScaleModel
   - ExamStatisticsModel, LiveExamStatsModel, ExamCreateInputModel
   - All follow project pattern: plain class, fromJson (snake_case & camelCase), toJson (snake_case), fromEntity, toEntity, copyWith, manual == and hashCode
   - Helper functions for nested list parsing, Map parsing, IP restriction parsing
   - QuestionEntity ↔ JSON conversion helpers

2. **`lib/features/cbt_engine/data/datasources/cbt_remote_datasource.dart`** - Abstract + Supabase implementation:
   - Abstract `CbtRemoteDataSource` with all 30+ method signatures
   - `CbtRemoteDataSourceImpl` with full Supabase CRUD operations
   - Exam CRUD, lifecycle (publish/archive/clone)
   - Question management (add/remove/reorder)
   - Student management (assign/remove)
   - Attempt management (start/submit/get)
   - Answer management (save/flag/autoSave)
   - Session management (update/heartbeat)
   - Monitoring (log/get)
   - Results (get/grade/release)
   - Statistics & Rankings
   - Realtime subscriptions using Supabase channel subscriptions
   - Proper error handling converting PostgrestException to custom exceptions

3. **`lib/features/cbt_engine/data/repositories/cbt_repository_impl.dart`** - Repository implementation:
   - Implements all methods from `CbtRepository` interface
   - Entity ↔ Model conversion at boundaries
   - try/catch → Failure → Result<T> pattern
   - Handles all exception types (Auth, Server, Cache, Network, Validation, NotFound, Unauthorized, Forbidden)
   - Stream mapping for realtime subscriptions

### Service Layer (6 files)
4. **`lib/services/cbt/auto_save_service.dart`** - Timer-based auto-save:
   - Configurable interval and save callback
   - Concurrency guard (won't save if previous save still in progress)
   - Force save capability
   - Non-blocking error handling (failures don't disrupt the student)

5. **`lib/services/cbt/exam_timer_service.dart`** - Countdown timer:
   - Start/pause/resume/stop lifecycle
   - Warning threshold callback (e.g., 5 minutes left)
   - Time-up callback
   - Progress tracking (0.0 to 1.0)
   - Formatted time strings (HH:MM:SS)
   - Set remaining time for session recovery

6. **`lib/services/cbt/session_recovery_service.dart`** - Session crash recovery:
   - Save/recover session state via SharedPreferences
   - Stale session detection (24-hour max age)
   - List all recoverable sessions
   - Clear individual or all sessions
   - JSON serialization for SessionState

7. **`lib/services/cbt/anti_cheat_service.dart`** - Anti-cheating detection:
   - Tab visibility change detection
   - Copy/paste attempt detection
   - Right-click detection
   - Fullscreen exit detection
   - Keyboard shortcut detection (Ctrl+C, Ctrl+V, F12, PrintScreen, etc.)
   - Idle timeout detection
   - Window resize detection
   - Disqualification threshold checking
   - ViolationSummary generation from monitoring logs
   - Severity classification (info/warning/critical)

8. **`lib/services/cbt/result_processor.dart`** - Result processing:
   - Auto-grading for all objective question types
   - Manual grading support for subjective questions
   - Per-question grading: MCQ, multiple response, true/false, fill-in-blank, matching, ordering, numerical
   - Partial credit calculation
   - Negative marking support
   - Total score calculation
   - Grade scale application
   - Statistics computation (average, median, pass rate, etc.)
   - Ranking generation with tie handling

9. **`lib/services/cbt/realtime_service.dart`** - Supabase Realtime service:
   - Watch exam sessions stream
   - Watch exam attempts stream
   - Watch monitoring events stream
   - Heartbeat sending
   - Session state updates
   - Channel subscription management
   - Unsubscribe all / dispose
   - Initial data fetching for streams

## Key Design Decisions
- Models use snake_case for toJson (Supabase convention), accept both cases in fromJson
- ExamModel handles sections and questions as nested lists
- ExamAttemptModel handles answers as nested list
- ExamSessionModel is the REALTIME model, optimized for frequent updates
- StudentAnswerModel.answerData is Map<String, dynamic> for flexibility
- All service classes are injectable and testable
- Error handling follows project's Result<T> pattern
- Realtime uses Supabase channel subscriptions with broadcast StreamControllers
