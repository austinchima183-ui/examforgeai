/// Student Portal — Presentation Providers Barrel File
///
/// Exports all provider files for the Student Portal feature.
/// Import this file to access any student portal provider.
///
/// ```dart
/// import 'package:examforge_ai/features/student_portal/presentation/providers/student_portal_providers.dart';
///
/// final dashboard = ref.watch(studentDashboardProvider);
/// final tutor    = ref.watch(aiTutorProvider);
/// ```
library;

// ─── Shared Providers (re-exported) ──────────────────────────────────
export 'student_dashboard_provider.dart'
    show
        currentStudentIdProvider,
        studentDashboardProvider,
        StudentDashboardNotifier,
        StudentDashboardState;

// ─── AI Tutor ────────────────────────────────────────────────────────
export 'ai_tutor_provider.dart'
    show aiTutorProvider, AiTutorNotifier, AiTutorState;

// ─── Practice Sessions ───────────────────────────────────────────────
export 'practice_provider.dart'
    show practiceProvider, PracticeNotifier, PracticeState;

// ─── Assignment Submissions ──────────────────────────────────────────
export 'assignment_provider.dart'
    show studentAssignmentProvider, AssignmentNotifier, AssignmentState;

// ─── Learning Resources ──────────────────────────────────────────────
export 'resource_provider.dart'
    show
        resourceProvider,
        ResourceNotifier,
        ResourceState,
        studentSchoolIdProvider;

// ─── Document Chat ───────────────────────────────────────────────────
export 'document_chat_provider.dart'
    show documentChatProvider, DocumentChatNotifier, DocumentChatState;

// ─── Flashcards ──────────────────────────────────────────────────────
export 'flashcard_provider.dart'
    show flashcardProvider, FlashcardNotifier, FlashcardState;

// ─── Study Planner ───────────────────────────────────────────────────
export 'study_planner_provider.dart'
    show studyPlannerProvider, StudyPlannerNotifier, StudyPlannerState;

// ─── Goals ───────────────────────────────────────────────────────────
export 'goals_provider.dart'
    show goalsProvider, GoalsNotifier, GoalsState;

// ─── Progress & Analytics ────────────────────────────────────────────
export 'progress_provider.dart'
    show progressProvider, ProgressNotifier, ProgressState;

// ─── Notifications ───────────────────────────────────────────────────
export 'student_notification_provider.dart'
    show
        studentNotificationProvider,
        StudentNotificationNotifier,
        StudentNotificationState;
