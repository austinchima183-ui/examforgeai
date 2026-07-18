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
  // SCHOOL MANAGEMENT ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// School management module root.
  static const String schoolManagement = '/school-management';

  /// School admin list page.
  static const String schoolList = '/school-management/schools';

  /// School admin detail page.
  static const String schoolDetail = '/school-management/schools/detail';

  /// School admin form page (create/edit).
  static const String schoolForm = '/school-management/schools/form';

  /// Student list page.
  static const String studentList = '/school-management/students';

  /// Student detail page.
  static const String studentDetail = '/school-management/students/detail';

  /// Student form page (create/edit).
  static const String studentForm = '/school-management/students/form';

  /// Student promotion page.
  static const String studentPromotion = '/school-management/students/promotion';

  /// Teacher list page.
  static const String teacherList = '/school-management/teachers';

  /// Teacher detail page.
  static const String teacherDetail = '/school-management/teachers/detail';

  /// Teacher form page (create/edit).
  static const String teacherForm = '/school-management/teachers/form';

  /// Parent list page.
  static const String parentList = '/school-management/parents';

  /// Parent detail page.
  static const String parentDetail = '/school-management/parents/detail';

  /// Parent portal page.
  static const String parentPortal = '/school-management/parents/portal';

  // ═══════════════════════════════════════════════════════════════════════
  // ACADEMIC ADMINISTRATION ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Class list page.
  static const String classList = '/school-management/classes';

  /// Class detail page.
  static const String classDetail = '/school-management/classes/detail';

  /// Class form page (create/edit).
  static const String classForm = '/school-management/classes/form';

  /// Subject list page.
  static const String subjectList = '/school-management/subjects';

  /// Subject form page (create/edit).
  static const String subjectForm = '/school-management/subjects/form';

  /// Academic sessions page.
  static const String academicSessions = '/school-management/sessions';

  /// School calendar page.
  static const String schoolCalendar = '/school-management/calendar';

  /// School settings page.
  static const String schoolSettings = '/school-management/settings';

  // ═══════════════════════════════════════════════════════════════════════
  // TIMETABLE ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Timetable list page.
  static const String timetableList = '/school-management/timetables';

  /// Timetable builder page (interactive).
  static const String timetableBuilder = '/school-management/timetables/builder';

  /// Timetable view page (read-only published).
  static const String timetableView = '/school-management/timetables/view';

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Attendance marking page.
  static const String attendance = '/school-management/attendance';

  /// Attendance report page.
  static const String attendanceReport = '/school-management/attendance/report';

  // ═══════════════════════════════════════════════════════════════════════
  // HOMEWORK ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Homework list page.
  static const String homeworkList = '/school-management/homework';

  /// Homework form page (create/edit).
  static const String homeworkForm = '/school-management/homework/form';

  /// Homework submissions page.
  static const String homeworkSubmissions = '/school-management/homework/submissions';

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENT ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Announcement list page.
  static const String announcementList = '/school-management/announcements';

  /// Announcement form page (create/edit).
  static const String announcementForm = '/school-management/announcements/form';

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT CENTER ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Document center page.
  static const String documentCenter = '/school-management/documents';

  /// Document upload page.
  static const String documentUpload = '/school-management/documents/upload';

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTS ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Report dashboard page.
  static const String reportDashboard = '/school-management/reports';

  /// Student report page.
  static const String studentReport = '/school-management/reports/students';

  /// Attendance report page (dedicated).
  static const String reportAttendance = '/school-management/reports/attendance';

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

  /// All school management sub-routes (used for feature-level navigation).
  static const Set<String> schoolManagementRoutes = <String>{
    schoolManagement,
    schoolList,
    schoolDetail,
    schoolForm,
    studentList,
    studentDetail,
    studentForm,
    studentPromotion,
    teacherList,
    teacherDetail,
    teacherForm,
    parentList,
    parentDetail,
    parentPortal,
    classList,
    classDetail,
    classForm,
    subjectList,
    subjectForm,
    academicSessions,
    schoolCalendar,
    schoolSettings,
    timetableList,
    timetableBuilder,
    timetableView,
    attendance,
    attendanceReport,
    homeworkList,
    homeworkForm,
    homeworkSubmissions,
    announcementList,
    announcementForm,
    documentCenter,
    documentUpload,
    reportDashboard,
    studentReport,
    reportAttendance,
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
    schoolManagement,
    schoolList,
    schoolDetail,
    schoolForm,
    studentList,
    studentDetail,
    studentForm,
    studentPromotion,
    teacherList,
    teacherDetail,
    teacherForm,
    parentList,
    parentDetail,
    parentPortal,
    classList,
    classDetail,
    classForm,
    subjectList,
    subjectForm,
    academicSessions,
    schoolCalendar,
    schoolSettings,
    timetableList,
    timetableBuilder,
    timetableView,
    attendance,
    attendanceReport,
    homeworkList,
    homeworkForm,
    homeworkSubmissions,
    announcementList,
    announcementForm,
    documentCenter,
    documentUpload,
    reportDashboard,
    studentReport,
    reportAttendance,
  };
}
