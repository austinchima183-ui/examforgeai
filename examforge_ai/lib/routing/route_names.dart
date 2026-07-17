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
  };
}
