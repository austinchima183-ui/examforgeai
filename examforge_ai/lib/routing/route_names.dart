/// Centralized route name constants for ExamForge AI.
///
/// Every navigable path in the application is defined here as a single
/// source of truth. Using constants instead of raw strings prevents
/// typos, makes refactoring safe, and enables IDE autocomplete.
///
/// ```dart
/// context.go(RouteNames.dashboard);
/// GoRouter.of(context).goNamed(RouteNames.login);
/// ```
///
/// Convention: all paths are lowercase with hyphens for multi-word
/// segments (kebab-case), matching common web URL conventions.
class RouteNames {
  RouteNames._();

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC (UNAUTHENTICATED) ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Splash / cold-start screen.
  static const String splash = '/splash';

  /// First-time onboarding flow (feature tour, role selection, etc.).
  static const String onboarding = '/onboarding';

  /// Email + password sign-in.
  static const String login = '/login';

  /// New account registration.
  static const String register = '/register';

  /// "I forgot my password" flow — sends a reset email.
  static const String forgotPassword = '/forgot-password';

  /// Email verification screen (deep-link target after sign-up).
  static const String verifyEmail = '/verify-email';

  /// New password entry screen (deep-link target from reset email).
  static const String resetPassword = '/reset-password';

  // ═══════════════════════════════════════════════════════════════════════
  // PROTECTED (AUTHENTICATED) ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Top-level dashboard that role-redirects to the correct sub-dashboard.
  static const String dashboard = '/dashboard';

  /// Dashboard for users with the **teacher** role.
  static const String teacherDashboard = '/dashboard/teacher';

  /// Dashboard for users with the **student** role.
  static const String studentDashboard = '/dashboard/student';

  /// Dashboard for users with the **school-admin** role.
  static const String schoolAdminDashboard = '/dashboard/school-admin';

  /// Dashboard for users with the **super-admin** role.
  static const String superAdminDashboard = '/dashboard/super-admin';

  /// User profile / account page.
  static const String profile = '/profile';

  /// Application settings.
  static const String settings = '/settings';

  /// Notifications inbox.
  static const String notifications = '/notifications';

  // ═══════════════════════════════════════════════════════════════════════
  // QUESTION BANK ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Question Bank module root / landing page.
  static const String questionBank = '/question-bank';

  /// Question Bank list view (browse, filter, search).
  static const String questionBankList = '/question-bank/list';

  /// Create a new question.
  static const String questionBankCreate = '/question-bank/create';

  /// View a single question's details.
  static const String questionBankDetail = '/question-bank/detail';

  /// Edit an existing question.
  static const String questionBankEdit = '/question-bank/edit';

  /// Import questions from file (CSV, Excel, JSON, Word).
  static const String questionBankImport = '/question-bank/import';

  /// Export questions to file (CSV, Excel, JSON, PDF).
  static const String questionBankExport = '/question-bank/export';

  /// Manage question collections (folders / playlists).
  static const String questionBankCollections = '/question-bank/collections';

  /// Question Bank statistics dashboard.
  static const String questionBankStats = '/question-bank/stats';

  // ═══════════════════════════════════════════════════════════════════════
  // AI GENERATOR ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// AI Generator module root / landing page.
  static const String aiGenerator = '/ai-generator';

  /// AI question generation form and execution.
  static const String aiGeneratorGenerate = '/ai-generator/generate';

  /// Review generated questions (approve, reject, request revision).
  static const String aiGeneratorReview = '/ai-generator/review';

  /// Improve generated questions with AI assistance.
  static const String aiGeneratorImprove = '/ai-generator/improve';

  /// Upload and process documents for question extraction.
  static const String aiGeneratorDocument = '/ai-generator/document';

  /// View generation request history.
  static const String aiGeneratorHistory = '/ai-generator/history';

  /// Manage prompt templates for AI generation.
  static const String aiGeneratorPrompts = '/ai-generator/prompts';

  /// AI Generator dashboard statistics.
  static const String aiGeneratorStats = '/ai-generator/stats';

  // ═══════════════════════════════════════════════════════════════════════
  // CBT ENGINE ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// CBT Engine module root / exam listing.
  static const String exams = '/exams';

  /// Create a new exam.
  static const String examCreate = '/exams/create';

  /// Edit an existing exam.
  static const String examEdit = '/exams/edit';

  /// View exam details.
  static const String examDetail = '/exams/detail';

  /// Live exam monitoring dashboard.
  static const String examMonitor = '/exams/monitor';

  /// Exam results and grading.
  static const String examResults = '/exams/results';

  /// Student exam-taking interface.
  static const String examTake = '/exams/take';

  /// Student's exam list (assigned exams).
  static const String studentExams = '/exams/my-exams';

  /// Exam templates library.
  static const String examTemplates = '/exams/templates';

  /// Submission receipt view.
  static const String submissionReceipt = '/exams/receipt';

  // ═══════════════════════════════════════════════════════════════════════
  // RESULTS & ANALYTICS ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Results module root / dashboard.
  static const String results = '/results';

  /// Teacher grading interface (review AI grading, manual grading).
  static const String teacherGrading = '/results/grading';

  /// Class results and rankings.
  static const String classResults = '/results/class-results';

  /// Grade scale management.
  static const String gradeScales = '/results/grade-scales';

  /// Result management (lock, publish, withhold).
  static const String resultManagement = '/results/management';

  /// Student results portal (personal results).
  static const String studentResults = '/results/my-results';

  /// Student topic mastery view.
  static const String topicMastery = '/results/topic-mastery';

  /// School analytics dashboard.
  static const String schoolAnalytics = '/results/analytics';

  /// Report generation and exports.
  static const String reports = '/results/reports';

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER WORKSPACE ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Teacher Workspace module root / dashboard.
  static const String workspace = '/workspace';

  /// Teacher Workspace dashboard page.
  static const String workspaceDashboard = '/workspace/dashboard';

  /// Lesson plan list.
  static const String lessonPlanList = '/workspace/lesson-plans';

  /// Create a new lesson plan.
  static const String lessonPlanCreate = '/workspace/lesson-plans/create';

  /// View lesson plan details.
  static const String lessonPlanDetail = '/workspace/lesson-plans/detail';

  /// Scheme of work list.
  static const String schemeOfWorkList = '/workspace/schemes';

  /// Create a new scheme of work.
  static const String schemeOfWorkCreate = '/workspace/schemes/create';

  /// Worksheet list.
  static const String worksheetList = '/workspace/worksheets';

  /// Create a new worksheet.
  static const String worksheetCreate = '/workspace/worksheets/create';

  /// Resource library.
  static const String resourceLibrary = '/workspace/library';

  /// Assignment list page.
  static const String assignmentList = '/workspace/assignments';

  /// Create / generate a new assignment (AI generator).
  static const String assignmentGenerator = '/workspace/assignments/generator';

  /// Create a new assignment (alias for generator).
  static const String assignmentCreate = '/workspace/assignments/create';

  /// Report comment generator.
  static const String reportCommentGenerator =
      '/workspace/report-comments/generator';

  /// AI content assistant.
  static const String contentAssistant = '/workspace/ai-assistant';

  /// Teaching resources library.
  static const String teachingResources = '/workspace/resources';

  /// Calendar / planner view.
  static const String calendarPlanner = '/workspace/planner';

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT PORTAL ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Student Portal module root / dashboard.
  static const String studentPortal = '/student-portal';

  /// Student Portal dashboard page.
  static const String studentPortalDashboard = '/student-portal/dashboard';

  /// AI Tutor chat interface.
  static const String aiTutor = '/student-portal/ai-tutor';

  /// Practice mode (quiz setup, session, results).
  static const String practiceMode = '/student-portal/practice';

  /// Assignment portal.
  static const String assignmentPortal = '/student-portal/assignments';

  /// Learning resource library.
  static const String learningResources = '/student-portal/resources';

  /// Document chat (PDF/DOCX upload and AI chat).
  static const String documentChat = '/student-portal/document-chat';

  /// Flashcard system (decks and study mode).
  static const String flashcards = '/student-portal/flashcards';

  /// Study planner.
  static const String studyPlanner = '/student-portal/study-planner';

  /// Student goals.
  static const String studentGoals = '/student-portal/goals';

  /// Progress analytics.
  static const String studentProgress = '/student-portal/progress';

  /// Student notifications.
  static const String studentNotifications = '/student-portal/notifications';

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER SETS
  // ═══════════════════════════════════════════════════════════════════════

  /// All routes that do **not** require authentication.
  ///
  /// Useful in redirect logic to decide whether an unauthenticated user
  /// should be sent to the login page.
  static const Set<String> publicRoutes = <String>{
    splash,
    onboarding,
    login,
    register,
    forgotPassword,
    verifyEmail,
    resetPassword,
  };

  /// All dashboard sub-routes (used for role-based access checks).
  static const Set<String> dashboardRoutes = <String>{
    teacherDashboard,
    studentDashboard,
    schoolAdminDashboard,
    superAdminDashboard,
  };

  /// All question bank sub-routes (used for feature-level navigation).
  static const Set<String> questionBankRoutes = <String>{
    questionBank,
    questionBankList,
    questionBankCreate,
    questionBankDetail,
    questionBankEdit,
    questionBankImport,
    questionBankExport,
    questionBankCollections,
    questionBankStats,
  };

  /// All AI generator sub-routes (used for feature-level navigation).
  static const Set<String> aiGeneratorRoutes = <String>{
    aiGenerator,
    aiGeneratorGenerate,
    aiGeneratorReview,
    aiGeneratorImprove,
    aiGeneratorDocument,
    aiGeneratorHistory,
    aiGeneratorPrompts,
    aiGeneratorStats,
  };

  /// All CBT engine sub-routes (used for feature-level navigation).
  static const Set<String> cbtEngineRoutes = <String>{
    exams,
    examCreate,
    examEdit,
    examDetail,
    examMonitor,
    examResults,
    examTake,
    studentExams,
    examTemplates,
    submissionReceipt,
  };

  /// All results & analytics sub-routes (used for feature-level navigation).
  static const Set<String> resultsRoutes = <String>{
    results,
    teacherGrading,
    classResults,
    gradeScales,
    resultManagement,
    studentResults,
    topicMastery,
    schoolAnalytics,
    reports,
  };

  /// All teacher workspace sub-routes (used for feature-level navigation).
  static const Set<String> workspaceRoutes = <String>{
    workspace,
    workspaceDashboard,
    lessonPlanList,
    lessonPlanCreate,
    lessonPlanDetail,
    schemeOfWorkList,
    schemeOfWorkCreate,
    worksheetList,
    worksheetCreate,
    assignmentList,
    assignmentGenerator,
    assignmentCreate,
    reportCommentGenerator,
    contentAssistant,
    teachingResources,
    resourceLibrary,
    calendarPlanner,
  };

  /// All student portal sub-routes (used for feature-level navigation).
  static const Set<String> studentPortalRoutes = <String>{
    studentPortal,
    studentPortalDashboard,
    aiTutor,
    practiceMode,
    assignmentPortal,
    learningResources,
    documentChat,
    flashcards,
    studyPlanner,
    studentGoals,
    studentProgress,
    studentNotifications,
  };

  /// All routes that live inside the authenticated [ShellRoute].
  static const Set<String> protectedRoutes = <String>{
    dashboard,
    teacherDashboard,
    studentDashboard,
    schoolAdminDashboard,
    superAdminDashboard,
    profile,
    settings,
    notifications,
    questionBank,
    questionBankList,
    questionBankCreate,
    questionBankDetail,
    questionBankEdit,
    questionBankImport,
    questionBankExport,
    questionBankCollections,
    questionBankStats,
    aiGenerator,
    aiGeneratorGenerate,
    aiGeneratorReview,
    aiGeneratorImprove,
    aiGeneratorDocument,
    aiGeneratorHistory,
    aiGeneratorPrompts,
    aiGeneratorStats,
    exams,
    examCreate,
    examEdit,
    examDetail,
    examMonitor,
    examResults,
    examTake,
    studentExams,
    examTemplates,
    submissionReceipt,
    results,
    teacherGrading,
    classResults,
    gradeScales,
    resultManagement,
    studentResults,
    topicMastery,
    schoolAnalytics,
    reports,
    workspace,
    workspaceDashboard,
    lessonPlanList,
    lessonPlanCreate,
    lessonPlanDetail,
    schemeOfWorkList,
    schemeOfWorkCreate,
    worksheetList,
    worksheetCreate,
    assignmentList,
    assignmentGenerator,
    assignmentCreate,
    reportCommentGenerator,
    contentAssistant,
    teachingResources,
    resourceLibrary,
    calendarPlanner,
    studentPortal,
    studentPortalDashboard,
    aiTutor,
    practiceMode,
    assignmentPortal,
    learningResources,
    documentChat,
    flashcards,
    studyPlanner,
    studentGoals,
    studentProgress,
    studentNotifications,
  };
}
