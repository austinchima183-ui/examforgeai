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
  // BILLING & SUBSCRIPTION ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Subscription plans listing page.
  static const String billingSubscriptionPlans = '/billing/subscription-plans';

  /// Billing checkout page (plan selection confirmation & payment).
  static const String billingCheckout = '/billing/checkout';

  /// Payment callback / verification page.
  static const String billingPaymentCallback = '/billing/payment-callback';

  /// Billing history (transactions & invoices).
  static const String billingHistory = '/billing/history';

  /// Invoice detail page.
  static const String billingInvoiceDetail = '/billing/invoice-detail';

  /// AI credits management page.
  static const String billingAiCredits = '/billing/ai-credits';

  /// Coupon management page (Super Admin).
  static const String billingCoupons = '/billing/coupons';

  /// Referral program page.
  static const String billingReferrals = '/billing/referrals';

  /// License management page.
  static const String billingLicenses = '/billing/licenses';

  /// Revenue dashboard page (Super Admin).
  static const String billingRevenue = '/billing/revenue';

  /// School billing management page.
  static const String billingSchoolBilling = '/billing/school-billing';

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
  // TEACHER WORKSPACE EXPANSION ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Enhanced workspace dashboard.
  static const String workspaceEnhancedDashboard = '/workspace/enhanced-dashboard';

  /// Presentation generator page.
  static const String presentationGenerator = '/workspace/presentations/generator';

  /// Presentation list page.
  static const String presentationList = '/workspace/presentations';

  /// Communication generator page.
  static const String communicationGenerator = '/workspace/communications/generator';

  /// Communication list page.
  static const String communicationList = '/workspace/communications';

  /// Task manager page.
  static const String taskManager = '/workspace/tasks';

  /// Rubric generator page.
  static const String rubricGenerator = '/workspace/rubrics/generator';

  /// Rubric list page.
  static const String rubricList = '/workspace/rubrics';

  /// Oral question generator page.
  static const String oralQuestionGenerator = '/workspace/oral-questions/generator';

  /// Oral question list page.
  static const String oralQuestionList = '/workspace/oral-questions';

  /// Practical assessment generator page.
  static const String practicalAssessmentGenerator = '/workspace/practical-assessments/generator';

  /// Practical assessment list page.
  static const String practicalAssessmentList = '/workspace/practical-assessments';

  /// Shared resources page.
  static const String sharedResources = '/workspace/shared';

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

  /// School management parent portal page (admin view).
  static const String schoolParentPortal = '/school-management/parents/portal';

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
  // PARENT PORTAL ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Parent Portal dashboard.
  static const String parentPortal = '/parent-portal';

  /// Parent Portal dashboard page.
  static const String parentDashboard = '/parent-portal/dashboard';

  /// Child profile page.
  static const String childProfile = '/parent-portal/child-profile';

  /// Child academic performance page.
  static const String childPerformance = '/parent-portal/performance';

  /// Child attendance page.
  static const String childAttendance = '/parent-portal/attendance';

  /// Child assignments page.
  static const String childAssignments = '/parent-portal/assignments';

  /// Parent messaging page.
  static const String parentMessaging = '/parent-portal/messages';

  /// Parent calendar page.
  static const String parentCalendar = '/parent-portal/calendar';

  /// AI Parent Assistant page.
  static const String parentAssistant = '/parent-portal/assistant';

  /// Parent notifications page.
  static const String parentNotifications = '/parent-portal/notifications';

  /// Parent AI insights page.
  static const String parentInsights = '/parent-portal/insights';

  /// Parent reports & downloads page.
  static const String parentReports = '/parent-portal/reports';

  /// Parent engagement dashboard (admin).
  static const String parentEngagement = '/parent-portal/engagement';

  // ═══════════════════════════════════════════════════════════════════════
  // COMMUNICATION SYSTEM ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Communication hub / dashboard.
  static const String communication = '/communication';

  /// Communication dashboard page.
  static const String communicationDashboard = '/communication/dashboard';

  /// Conversation list page.
  static const String conversationList = '/communication/conversations';

  /// Chat page (individual conversation).
  static const String chat = '/communication/chat';

  /// Create conversation page.
  static const String createConversation = '/communication/conversations/create';

  /// Announcement list page.
  static const String announcementList = '/communication/announcements';

  /// Announcement detail page.
  static const String announcementDetail = '/communication/announcements/detail';

  /// Create announcement page.
  static const String createAnnouncement = '/communication/announcements/create';

  /// Notification center page.
  static const String notificationCenter = '/communication/notifications';

  /// Notification preferences page.
  static const String notificationPreferences = '/communication/notifications/preferences';

  /// Discussion forum list page.
  static const String forumList = '/communication/forums';

  /// Forum detail page.
  static const String forumDetail = '/communication/forums/detail';

  /// Forum post detail page.
  static const String forumPostDetail = '/communication/forums/post';

  /// Calendar events page.
  static const String communicationCalendar = '/communication/calendar';

  /// Create calendar event page.
  static const String createCalendarEvent = '/communication/calendar/create';

  /// AI Communication Assistant page.
  static const String aiAssistant = '/communication/ai-assistant';

  /// AI School Knowledge Assistant page.
  static const String knowledgeAssistant = '/communication/knowledge-assistant';

  /// Communication audit logs page (admin).
  static const String communicationAuditLogs = '/communication/audit-logs';

  // ═══════════════════════════════════════════════════════════════════════
  // SUPER ADMIN ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Super Admin — School Management.
  static const String superAdminSchools = '/super-admin/schools';

  /// Super Admin — User Management.
  static const String superAdminUsers = '/super-admin/users';

  /// Super Admin — AI Management.
  static const String superAdminAI = '/super-admin/ai';

  /// Super Admin — Billing & Revenue.
  static const String superAdminBilling = '/super-admin/billing';

  /// Super Admin — Support Center.
  static const String superAdminSupport = '/super-admin/support';

  /// Super Admin — Security Center.
  static const String superAdminSecurity = '/super-admin/security';

  /// Super Admin — Infrastructure.
  static const String superAdminInfrastructure = '/super-admin/infrastructure';

  /// Super Admin — Intelligence Center.
  static const String superAdminIntelligence = '/super-admin/intelligence';

  /// Super Admin — Marketplace.
  static const String superAdminMarketplace = '/super-admin/marketplace';

  /// Super Admin — Analytics.
  static const String superAdminAnalytics = '/super-admin/analytics';

  /// Super Admin — Settings.
  static const String superAdminSettings = '/super-admin/settings';

  // ═══════════════════════════════════════════════════════════════════════
  // MARKETPLACE ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Marketplace home / browse page.
  static const String marketplace = '/marketplace';

  /// Marketplace search page.
  static const String marketplaceSearch = '/marketplace/search';

  /// Marketplace product detail page.
  static const String marketplaceProductDetail = '/marketplace/product';

  /// Marketplace category products page.
  static const String marketplaceCategory = '/marketplace/category';

  /// Buyer dashboard — purchases, wishlist, downloads.
  static const String marketplaceBuyerDashboard = '/marketplace/buyer';

  /// Seller dashboard — products, analytics, earnings.
  static const String marketplaceSellerDashboard = '/marketplace/seller';

  /// Create / edit a marketplace product.
  static const String marketplaceCreateProduct = '/marketplace/create-product';

  /// AI resource generator page.
  static const String marketplaceAiGenerator = '/marketplace/ai-generator';

  /// AI quality review page.
  static const String marketplaceQualityReview = '/marketplace/quality-review';

  /// Shopping cart page.
  static const String marketplaceCart = '/marketplace/cart';

  /// Checkout page.
  static const String marketplaceCheckout = '/marketplace/checkout';

  /// Product reviews page.
  static const String marketplaceReviews = '/marketplace/reviews';

  /// Super Admin — marketplace moderation.
  static const String marketplaceModeration = '/marketplace/moderation';

  /// Super Admin — commission management.
  static const String marketplaceCommissions = '/marketplace/commissions';

  /// Marketplace analytics page.
  static const String marketplaceAnalytics = '/marketplace/analytics';

  /// Marketplace notifications page.
  static const String marketplaceNotifications = '/marketplace/notifications';

  // ═══════════════════════════════════════════════════════════════════════
  // BILLING ROUTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Billing module root / dashboard page.
  static const String billingDashboard = '/billing';

  /// Subscription upgrade page.
  static const String billingUpgrade = '/billing/upgrade';

  /// Subscription management page.
  static const String billingManage = '/billing/manage';

  /// Invoice list page.
  static const String billingInvoices = '/billing/invoices';

  /// AI credits purchase page.
  static const String billingBuyCredits = '/billing/buy-credits';

  /// Billing notifications page.
  static const String billingNotifications = '/billing/notifications';

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
    workspaceEnhancedDashboard,
    presentationGenerator,
    presentationList,
    communicationGenerator,
    communicationList,
    taskManager,
    rubricGenerator,
    rubricList,
    oralQuestionGenerator,
    oralQuestionList,
    practicalAssessmentGenerator,
    practicalAssessmentList,
    sharedResources,
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
    schoolParentPortal,
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

  /// All parent portal sub-routes (used for feature-level navigation).
  static const Set<String> parentPortalRoutes = <String>{
    parentPortal,
    parentDashboard,
    childProfile,
    childPerformance,
    childAttendance,
    childAssignments,
    parentMessaging,
    parentCalendar,
    parentAssistant,
    parentNotifications,
    parentInsights,
    parentReports,
    parentEngagement,
  };

  /// All communication sub-routes (used for feature-level navigation).
  static const Set<String> communicationRoutes = <String>{
    communication,
    communicationDashboard,
    conversationList,
    chat,
    createConversation,
    announcementList,
    announcementDetail,
    createAnnouncement,
    notificationCenter,
    notificationPreferences,
    forumList,
    forumDetail,
    forumPostDetail,
    communicationCalendar,
    createCalendarEvent,
    aiAssistant,
    knowledgeAssistant,
    communicationAuditLogs,
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
    workspaceEnhancedDashboard,
    presentationGenerator,
    presentationList,
    communicationGenerator,
    communicationList,
    taskManager,
    rubricGenerator,
    rubricList,
    oralQuestionGenerator,
    oralQuestionList,
    practicalAssessmentGenerator,
    practicalAssessmentList,
    sharedResources,
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
    schoolParentPortal,
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
    parentPortal,
    parentDashboard,
    childProfile,
    childPerformance,
    childAttendance,
    childAssignments,
    parentMessaging,
    parentCalendar,
    parentAssistant,
    parentNotifications,
    parentInsights,
    parentReports,
    parentEngagement,
    communication,
    communicationDashboard,
    conversationList,
    chat,
    createConversation,
    announcementList,
    announcementDetail,
    createAnnouncement,
    notificationCenter,
    notificationPreferences,
    forumList,
    forumDetail,
    forumPostDetail,
    communicationCalendar,
    createCalendarEvent,
    aiAssistant,
    knowledgeAssistant,
    communicationAuditLogs,
    billingDashboard,
    billingSubscriptionPlans,
    billingCheckout,
    billingPaymentCallback,
    billingHistory,
    billingInvoiceDetail,
    billingAiCredits,
    billingCoupons,
    billingReferrals,
    billingLicenses,
    billingRevenue,
    billingSchoolBilling,
    marketplace,
    marketplaceSearch,
    marketplaceProductDetail,
    marketplaceCategory,
    marketplaceBuyerDashboard,
    marketplaceSellerDashboard,
    marketplaceCreateProduct,
    marketplaceAiGenerator,
    marketplaceQualityReview,
    marketplaceCart,
    marketplaceCheckout,
    marketplaceReviews,
    marketplaceModeration,
    marketplaceCommissions,
    marketplaceAnalytics,
    marketplaceNotifications,
  };

  /// All marketplace sub-routes (used for feature-level navigation).
  static const Set<String> marketplaceRoutes = <String>{
    marketplace,
    marketplaceSearch,
    marketplaceProductDetail,
    marketplaceCategory,
    marketplaceBuyerDashboard,
    marketplaceSellerDashboard,
    marketplaceCreateProduct,
    marketplaceAiGenerator,
    marketplaceQualityReview,
    marketplaceCart,
    marketplaceCheckout,
    marketplaceReviews,
    marketplaceModeration,
    marketplaceCommissions,
    marketplaceAnalytics,
    marketplaceNotifications,
  };
}
