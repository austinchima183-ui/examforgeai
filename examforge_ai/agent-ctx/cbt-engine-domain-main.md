# CBT Engine Domain Layer - Task Summary

## Task ID: cbt-engine-domain-main

## Files Created

### 1. Entities (`domain/entities/cbt_entities.dart`)
- **6 Enums**: ExamStatus, AttemptStatus, SubmissionType, GradingStatus, MonitoringEventType, NotificationCategory
- **15 Entity Classes**: ExamSectionEntity, ExamQuestionEntity, ExamStudentEntity, StudentAnswerEntity, ExamAttemptEntity, ExamSessionEntity, MonitoringLogEntity, ExamResultEntity, ExamRankingEntity, ExamNotificationEntity, GradeScaleEntry, GradeScaleEntity, ExamEntity, ExamStatistics, LiveExamStats
- **1 Input DTO**: ExamCreateInput
- All entities extend Equatable with const constructors, final fields, copyWith, and props
- All enums have enhanced metadata (value, label, etc.) with static fromString()
- ExamEntity has convenience getters: effectivePassMark, isWithinTimeWindow, hasNotStarted, hasEnded

### 2. Repository (`domain/repositories/cbt_repository.dart`)
- Abstract CbtRepository with 30+ methods
- CRUD: createExam, updateExam, deleteExam, getExam, getExamWithDetails, getExams
- Lifecycle: publishExam, archiveExam, cloneExam
- Questions: addQuestionsToExam, removeQuestionFromExam, reorderQuestions
- Students: assignStudents, removeStudent
- Attempts: startAttempt, submitAttempt, getAttempt, getAttemptWithAnswers, getStudentAttempts
- Answers: saveAnswer, flagQuestion, autoSave
- Sessions: updateSession, heartbeat
- Monitoring: logMonitoringEvent, getMonitoringLogs
- Results & Grading: getExamResults, getStudentResult, gradeAnswer, releaseResults
- Statistics: getExamStatistics, getLiveExamStats, getRankings
- Realtime: watchExamSessions, watchExamAttempts, watchMonitoringEvents

### 3. Use Cases (9 files in `domain/usecases/`)
1. **CreateExamUseCase** - Validates input, builds ExamEntity, assigns students
2. **UpdateExamUseCase** - Validates editability status, field consistency
3. **StartExamAttemptUseCase** - Validates exam active, time window, questions
4. **SubmitExamAttemptUseCase** - Validates attempt in progress, not terminal
5. **SaveAnswerUseCase** - Validates attempt active, answer not empty
6. **GradeExamUseCase** - Single or bulk grading, marks validation
7. **GetExamResultsUseCase** - Validates exam exists, supports release filter
8. **GetExamStatisticsUseCase** - Validates exam not draft
9. **ManageExamStatusUseCase** - Publish/Archive/Clone/Cancel with state machine
10. **GetLiveExamStatsUseCase** - Validates monitorable status

## Patterns Followed
- Entities: Equatable + const constructor + final fields + copyWith + props
- Repository: Abstract class returning Result<T>
- Use Cases: Params class + call() method
- Import paths match existing project structure (3 levels up for core)
- Uses existing QuestionType, ExamType, DifficultyLevel from question_entities.dart
- Uses existing Result<T> and Failure types from core
