import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/dependency_injection.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/dashboard/presentation/pages/dashboard_redirector.dart';
import '../features/dashboard/presentation/pages/dashboard_shell.dart';
import '../features/dashboard/presentation/pages/school_admin_dashboard_page.dart';
import '../features/dashboard/presentation/pages/student_dashboard_page.dart';
// Original dashboard redirector — now replaced by full Super Admin Platform
import '../features/dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/question_bank/presentation/pages/question_bank_dashboard_page.dart';
import '../features/question_bank/presentation/pages/question_list_page.dart';
import '../features/question_bank/presentation/pages/question_editor_page.dart';
import '../features/question_bank/presentation/pages/question_detail_page.dart';
import '../features/question_bank/presentation/pages/question_import_page.dart';
import '../features/question_bank/presentation/pages/question_export_page.dart';
import '../features/question_bank/presentation/pages/collections_page.dart';
import '../features/ai_generator/presentation/pages/ai_dashboard_page.dart';
import '../features/ai_generator/presentation/pages/ai_generate_page.dart';
import '../features/ai_generator/presentation/pages/ai_review_page.dart';
import '../features/ai_generator/presentation/pages/ai_improve_page.dart';
import '../features/ai_generator/presentation/pages/ai_document_page.dart';
import '../features/ai_generator/presentation/pages/ai_history_page.dart';
import '../features/ai_generator/presentation/pages/ai_prompts_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_list_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_builder_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_detail_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_monitor_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_results_page.dart';
import '../features/cbt_engine/presentation/pages/teacher/exam_templates_page.dart';
import '../features/cbt_engine/presentation/pages/student/exam_take_page.dart';
import '../features/cbt_engine/presentation/pages/student/student_exams_page.dart';
import '../features/cbt_engine/presentation/pages/student/exam_result_view_page.dart';
import '../features/cbt_engine/presentation/pages/student/submission_receipt_page.dart';
import '../features/results/presentation/pages/teacher/teacher_grading_page.dart';
import '../features/results/presentation/pages/teacher/class_results_page.dart';
import '../features/results/presentation/pages/teacher/grade_scales_page.dart';
import '../features/results/presentation/pages/teacher/result_management_page.dart';
import '../features/results/presentation/pages/student/student_results_page.dart';
import '../features/results/presentation/pages/student/topic_mastery_page.dart';
import '../features/results/presentation/pages/admin/school_analytics_page.dart';
import '../features/results/presentation/pages/admin/reports_page.dart';
import '../features/teacher_workspace/presentation/pages/teacher_workspace_dashboard_page.dart';
import '../features/teacher_workspace/presentation/pages/lesson_plan_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/lesson_plan_list_page.dart';
import '../features/teacher_workspace/presentation/pages/lesson_plan_detail_page.dart';
import '../features/teacher_workspace/presentation/pages/scheme_of_work_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/scheme_of_work_list_page.dart';
import '../features/teacher_workspace/presentation/pages/worksheet_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/worksheet_list_page.dart';
import '../features/teacher_workspace/presentation/pages/assignment_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/assignment_list_page.dart';
import '../features/teacher_workspace/presentation/pages/report_comment_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/teaching_resources_page.dart';
import '../features/teacher_workspace/presentation/pages/content_assistant_page.dart';
import '../features/teacher_workspace/presentation/pages/resource_library_page.dart';
import '../features/teacher_workspace/presentation/pages/calendar_planner_page.dart';
import '../features/teacher_workspace/presentation/pages/enhanced_workspace_dashboard_page.dart';
import '../features/teacher_workspace/presentation/pages/presentation_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/presentation_list_page.dart';
import '../features/teacher_workspace/presentation/pages/communication_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/communication_list_page.dart';
import '../features/teacher_workspace/presentation/pages/task_manager_page.dart';
import '../features/teacher_workspace/presentation/pages/rubric_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/rubric_list_page.dart';
import '../features/teacher_workspace/presentation/pages/oral_question_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/oral_question_list_page.dart';
import '../features/teacher_workspace/presentation/pages/practical_assessment_generator_page.dart';
import '../features/teacher_workspace/presentation/pages/practical_assessment_list_page.dart';
import '../features/teacher_workspace/presentation/pages/shared_resources_page.dart';
import '../features/student_portal/presentation/pages/student_portal_dashboard_page.dart';
import '../features/student_portal/presentation/pages/ai_tutor_page.dart';
import '../features/student_portal/presentation/pages/practice_mode_page.dart';
import '../features/student_portal/presentation/pages/assignment_portal_page.dart';
import '../features/student_portal/presentation/pages/learning_resources_page.dart';
import '../features/student_portal/presentation/pages/document_chat_page.dart';
import '../features/student_portal/presentation/pages/flashcard_page.dart';
import '../features/student_portal/presentation/pages/study_planner_page.dart';
import '../features/student_portal/presentation/pages/goals_page.dart';
import '../features/student_portal/presentation/pages/progress_page.dart';
import '../features/student_portal/presentation/pages/student_notifications_page.dart';
import '../features/school_management/presentation/pages/admin/school_list_page.dart';
import '../features/school_management/presentation/pages/admin/school_detail_page.dart';
import '../features/school_management/presentation/pages/admin/school_form_page.dart';
import '../features/school_management/presentation/pages/admin/academic_session_page.dart';
import '../features/school_management/presentation/pages/admin/school_calendar_page.dart';
import '../features/school_management/presentation/pages/admin/school_settings_page.dart';
import '../features/school_management/presentation/pages/student/student_list_page.dart';
import '../features/school_management/presentation/pages/student/student_detail_page.dart';
import '../features/school_management/presentation/pages/student/student_form_page.dart';
import '../features/school_management/presentation/pages/student/promotion_page.dart';
import '../features/school_management/presentation/pages/teacher/teacher_list_page.dart';
import '../features/school_management/presentation/pages/teacher/teacher_detail_page.dart';
import '../features/school_management/presentation/pages/teacher/teacher_form_page.dart';
import '../features/school_management/presentation/pages/parent/parent_list_page.dart';
import '../features/school_management/presentation/pages/parent/parent_detail_page.dart';
import '../features/school_management/presentation/pages/parent/parent_portal_page.dart';
import '../features/school_management/presentation/pages/class_group/class_list_page.dart';
import '../features/school_management/presentation/pages/class_group/class_detail_page.dart';
import '../features/school_management/presentation/pages/class_group/class_form_page.dart';
import '../features/school_management/presentation/pages/subject/subject_list_page.dart';
import '../features/school_management/presentation/pages/subject/subject_form_page.dart';
import '../features/school_management/presentation/pages/timetable/timetable_list_page.dart';
import '../features/school_management/presentation/pages/timetable/timetable_builder_page.dart';
import '../features/school_management/presentation/pages/timetable/timetable_view_page.dart';
import '../features/school_management/presentation/pages/attendance/attendance_page.dart';
import '../features/school_management/presentation/pages/attendance/attendance_report_page.dart';
import '../features/school_management/presentation/pages/homework/homework_list_page.dart';
import '../features/school_management/presentation/pages/homework/homework_form_page.dart';
import '../features/school_management/presentation/pages/homework/homework_submissions_page.dart';
import '../features/school_management/presentation/pages/announcement/announcement_list_page.dart';
import '../features/school_management/presentation/pages/announcement/announcement_form_page.dart';
import '../features/school_management/presentation/pages/document/document_center_page.dart';
import '../features/school_management/presentation/pages/document/document_upload_page.dart';
import '../features/school_management/presentation/pages/report/report_dashboard_page.dart';
import '../features/school_management/presentation/pages/report/student_report_page.dart';
import '../features/school_management/presentation/pages/report/attendance_report_page.dart' as sm;
import '../features/parent_portal/presentation/pages/parent_dashboard_page.dart';
import '../features/parent_portal/presentation/pages/child_profile_page.dart';
import '../features/parent_portal/presentation/pages/child_performance_page.dart';
import '../features/parent_portal/presentation/pages/child_attendance_page.dart';
import '../features/parent_portal/presentation/pages/child_assignments_page.dart';
import '../features/parent_portal/presentation/pages/parent_messaging_page.dart';
import '../features/parent_portal/presentation/pages/parent_calendar_page.dart';
import '../features/parent_portal/presentation/pages/parent_assistant_page.dart';
import '../features/parent_portal/presentation/pages/parent_notifications_page.dart';
import '../features/parent_portal/presentation/pages/parent_insights_page.dart';
import '../features/parent_portal/presentation/pages/parent_reports_page.dart';
import '../features/parent_portal/presentation/pages/parent_engagement_dashboard_page.dart';
import '../features/communication/presentation/pages/communication_dashboard_page.dart';
import '../features/communication/presentation/pages/conversation_list_page.dart';
import '../features/communication/presentation/pages/chat_page.dart';
import '../features/communication/presentation/pages/create_conversation_page.dart';
import '../features/communication/presentation/pages/announcement_list_page.dart';
import '../features/communication/presentation/pages/announcement_detail_page.dart';
import '../features/communication/presentation/pages/notification_center_page.dart';
import '../features/communication/presentation/pages/notification_preferences_page.dart';
import '../features/communication/presentation/pages/forum_list_page.dart';
import '../features/communication/presentation/pages/forum_detail_page.dart';
import '../features/communication/presentation/pages/forum_post_detail_page.dart';
import '../features/communication/presentation/pages/calendar_page.dart';
import '../features/communication/presentation/pages/create_event_page.dart';
import '../features/communication/presentation/pages/ai_assistant_page.dart';
import '../features/communication/presentation/pages/knowledge_assistant_page.dart';
import '../features/communication/presentation/pages/moderation_audit_page.dart';

// ── Billing & Subscription ──
import '../features/billing/presentation/pages/billing_dashboard_page.dart';
import '../features/billing/presentation/pages/subscription_plans_page.dart';
import '../features/billing/presentation/pages/checkout_page.dart';
import '../features/billing/presentation/pages/payment_callback_page.dart';
import '../features/billing/presentation/pages/billing_history_page.dart';
import '../features/billing/presentation/pages/invoice_detail_page.dart';
import '../features/billing/presentation/pages/ai_credits_page.dart';
import '../features/billing/presentation/pages/coupon_management_page.dart';
import '../features/billing/presentation/pages/referral_program_page.dart';
import '../features/billing/presentation/pages/license_management_page.dart';
import '../features/billing/presentation/pages/revenue_dashboard_page.dart';
import '../features/billing/presentation/pages/school_billing_page.dart';

// ── Super Admin Platform ──
import '../features/super_admin/presentation/pages/super_admin_dashboard_page.dart';
import '../features/super_admin/presentation/pages/school_management_page.dart';
import '../features/super_admin/presentation/pages/user_management_page.dart';
import '../features/super_admin/presentation/pages/ai_management_page.dart';
import '../features/super_admin/presentation/pages/billing_management_page.dart';
import '../features/super_admin/presentation/pages/support_center_page.dart';
import '../features/super_admin/presentation/pages/security_center_page.dart';
import '../features/super_admin/presentation/pages/infrastructure_monitoring_page.dart';
import '../features/super_admin/presentation/pages/intelligence_center_page.dart';
import '../features/super_admin/presentation/pages/marketplace_management_page.dart';
import '../features/super_admin/presentation/pages/platform_analytics_page.dart';
import '../features/super_admin/presentation/pages/global_settings_page.dart';
import 'route_guards.dart';
import 'route_names.dart';

// ═══════════════════════════════════════════════════════════════════════
// NAVIGATOR KEYS
// ═══════════════════════════════════════════════════════════════════════

/// Root navigator key — owns the top-level navigation stack.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key — owns the nested navigation stack inside the
/// [DashboardShell]. This allows the shell (sidebar / bottom nav) to
/// remain mounted while inner pages transition.
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ═══════════════════════════════════════════════════════════════════════
// APP ROUTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the application's [GoRouter].
///
/// Watches [authStateProvider] so that the router automatically
/// re-evaluates its [redirect] callback whenever the authentication
/// state changes (sign-in, sign-out, token refresh).
///
/// Usage in `main.dart`:
/// ```dart
/// final router = ref.read(appRouterProvider);
/// MaterialApp.router(routerConfig: router);
/// ```
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state so the router re-evaluates redirects on change.
  final authState = ref.watch(authStateProvider);

  // Also watch onboarding state and role so those redirects stay live.
  ref.watch(onboardingCompleteProvider);
  ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,

    // ─── Global Redirect ──────────────────────────────────────────
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      final isAuthenticated = authState.when(
        data: (authData) => authData.session != null,
        loading: () {
          // While loading, only allow splash. Everything else redirects
          // to splash so we don't flash the login page briefly.
          if (currentPath != RouteNames.splash) {
            return RouteNames.splash;
          }
          return null;
        },
        error: (_, __) => false,
      );

      // ── Auth Guard ────────────────────────────────────────────
      final authRedirect = AuthGuard.evaluate(
        isAuthenticated: isAuthenticated,
        currentPath: currentPath,
      );
      if (authRedirect != null) return authRedirect;

      // ── Onboarding Guard ─────────────────────────────────────
      final onboardingAsync = ref.read(onboardingCompleteProvider);
      final isOnboardingComplete = onboardingAsync.when(
        data: (complete) => complete,
        loading: () => true, // Assume complete while loading to avoid flicker.
        error: (_, __) => true,
      );

      final onboardingRedirect = OnboardingGuard.evaluate(
        isAuthenticated: isAuthenticated,
        isOnboardingComplete: isOnboardingComplete,
        currentPath: currentPath,
      );
      if (onboardingRedirect != null) return onboardingRedirect;

      // ── Role-Based Guard ─────────────────────────────────────
      final roleAsync = ref.read(userRoleProvider);
      final userRole = roleAsync.when(
        data: UserRole.fromString,
        loading: () => null,
        error: (_, __) => null,
      );

      final roleRedirect = RoleBasedGuard.evaluate(
        userRole: userRole,
        currentPath: currentPath,
      );
      if (roleRedirect != null) return roleRedirect;

      // No redirect needed — proceed as requested.
      return null;
    },

    // ─── Route Tree ───────────────────────────────────────────────
    routes: [
      // ── Splash ────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Onboarding ───────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Auth Routes ──────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // ── Protected Shell Route ─────────────────────────────────
      // All routes inside this shell share the [DashboardShell]
      // wrapper which provides the sidebar / bottom nav and app bar.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          // Dashboard with role-based sub-routes.
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardRedirector(),
            routes: [
              GoRoute(
                path: 'teacher',
                name: 'teacherDashboard',
                builder: (context, state) => const TeacherDashboardPage(),
              ),
              GoRoute(
                path: 'student',
                name: 'studentDashboard',
                builder: (context, state) => const StudentDashboardPage(),
              ),
              GoRoute(
                path: 'school-admin',
                name: 'schoolAdminDashboard',
                builder: (context, state) => const SchoolAdminDashboardPage(),
              ),
              GoRoute(
                path: 'super-admin',
                name: 'superAdminDashboard',
                redirect: (context, state) => RouteNames.superAdminDashboard,
              ),
            ],
          ),

          // Profile.
          GoRoute(
            path: RouteNames.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),

          // Settings.
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),

          // Notifications.
          GoRoute(
            path: RouteNames.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),

          // ── Question Bank Routes ──────────────────────────────────
          GoRoute(
            path: RouteNames.questionBank,
            name: 'questionBank',
            builder: (context, state) => const QuestionBankDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankList,
            name: 'questionBankList',
            builder: (context, state) => const QuestionListPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankCreate,
            name: 'questionBankCreate',
            builder: (context, state) => const QuestionEditorPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankDetail,
            name: 'questionBankDetail',
            builder: (context, state) {
              final questionId = state.uri.queryParameters['id'] ?? '';
              return QuestionDetailPage(questionId: questionId);
            },
          ),
          GoRoute(
            path: RouteNames.questionBankEdit,
            name: 'questionBankEdit',
            builder: (context, state) {
              final questionId = state.uri.queryParameters['id'] ?? '';
              return QuestionEditorPage(questionId: questionId);
            },
          ),
          GoRoute(
            path: RouteNames.questionBankImport,
            name: 'questionBankImport',
            builder: (context, state) => const QuestionImportPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankExport,
            name: 'questionBankExport',
            builder: (context, state) => const QuestionExportPage(),
          ),
          GoRoute(
            path: RouteNames.questionBankCollections,
            name: 'questionBankCollections',
            builder: (context, state) => const CollectionsPage(),
          ),

          // ── AI Generator Routes ──────────────────────────────────
          GoRoute(
            path: RouteNames.aiGenerator,
            name: 'aiGenerator',
            builder: (context, state) => const AiDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorGenerate,
            name: 'aiGeneratorGenerate',
            builder: (context, state) => const AiGeneratePage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorReview,
            name: 'aiGeneratorReview',
            builder: (context, state) => const AiReviewPage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorImprove,
            name: 'aiGeneratorImprove',
            builder: (context, state) => const AiImprovePage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorDocument,
            name: 'aiGeneratorDocument',
            builder: (context, state) => const AiDocumentPage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorHistory,
            name: 'aiGeneratorHistory',
            builder: (context, state) => const AiHistoryPage(),
          ),
          GoRoute(
            path: RouteNames.aiGeneratorPrompts,
            name: 'aiGeneratorPrompts',
            builder: (context, state) => const AiPromptsPage(),
          ),

          // ── CBT Engine Routes ─────────────────────────────────────
          GoRoute(
            path: RouteNames.exams,
            name: 'exams',
            builder: (context, state) => const ExamListPage(),
          ),
          GoRoute(
            path: RouteNames.examCreate,
            name: 'examCreate',
            builder: (context, state) => const ExamBuilderPage(),
          ),
          GoRoute(
            path: RouteNames.examEdit,
            name: 'examEdit',
            builder: (context, state) {
              final examId = state.uri.queryParameters['id'] ?? '';
              return ExamBuilderPage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.examDetail,
            name: 'examDetail',
            builder: (context, state) {
              final examId = state.uri.queryParameters['id'] ?? '';
              return ExamDetailPage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.examMonitor,
            name: 'examMonitor',
            builder: (context, state) {
              final examId = state.uri.queryParameters['id'] ?? '';
              return ExamMonitorPage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.examResults,
            name: 'examResults',
            builder: (context, state) {
              final examId = state.uri.queryParameters['id'] ?? '';
              return ExamResultsPage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.studentExams,
            name: 'studentExams',
            builder: (context, state) => const StudentExamsPage(),
          ),
          GoRoute(
            path: RouteNames.examTake,
            name: 'examTake',
            builder: (context, state) {
              final examId = state.uri.queryParameters['id'] ?? '';
              return ExamTakePage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.examTemplates,
            name: 'examTemplates',
            builder: (context, state) => const ExamTemplatesPage(),
          ),
          GoRoute(
            path: RouteNames.submissionReceipt,
            name: 'submissionReceipt',
            builder: (context, state) {
              final attemptId = state.uri.queryParameters['attemptId'] ?? '';
              return SubmissionReceiptPage(attemptId: attemptId);
            },
          ),

          // ── Results & Analytics Routes ───────────────────────────────
          GoRoute(
            path: RouteNames.results,
            name: 'results',
            builder: (context, state) => const ClassResultsPage(
              classId: '',
              academicSessionId: '',
            ),
          ),
          GoRoute(
            path: RouteNames.teacherGrading,
            name: 'teacherGrading',
            builder: (context, state) {
              final examId = state.uri.queryParameters['examId'] ?? '';
              return TeacherGradingPage(examId: examId);
            },
          ),
          GoRoute(
            path: RouteNames.classResults,
            name: 'classResults',
            builder: (context, state) {
              final classId = state.uri.queryParameters['classId'] ?? '';
              final sessionId = state.uri.queryParameters['sessionId'] ?? '';
              return ClassResultsPage(
                classId: classId,
                academicSessionId: sessionId,
              );
            },
          ),
          GoRoute(
            path: RouteNames.gradeScales,
            name: 'gradeScales',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return GradeScalesPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.resultManagement,
            name: 'resultManagement',
            builder: (context, state) {
              final examId = state.uri.queryParameters['examId'] ?? '';
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return ResultManagementPage(
                examId: examId,
                schoolId: schoolId,
              );
            },
          ),
          GoRoute(
            path: RouteNames.studentResults,
            name: 'studentResults',
            builder: (context, state) {
              final studentId = state.uri.queryParameters['studentId'] ?? '';
              final classId = state.uri.queryParameters['classId'] ?? '';
              final sessionId = state.uri.queryParameters['sessionId'] ?? '';
              return StudentResultsPage(
                studentId: studentId,
                classId: classId,
                academicSessionId: sessionId,
              );
            },
          ),
          GoRoute(
            path: RouteNames.topicMastery,
            name: 'topicMastery',
            builder: (context, state) {
              final studentId = state.uri.queryParameters['studentId'] ?? '';
              final subjectId = state.uri.queryParameters['subjectId'] ?? '';
              return TopicMasteryPage(
                studentId: studentId,
                subjectId: subjectId,
              );
            },
          ),
          GoRoute(
            path: RouteNames.schoolAnalytics,
            name: 'schoolAnalytics',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final sessionId = state.uri.queryParameters['sessionId'] ?? '';
              return SchoolAnalyticsPage(
                schoolId: schoolId,
                academicSessionId: sessionId,
              );
            },
          ),
          GoRoute(
            path: RouteNames.reports,
            name: 'reports',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return ReportsPage(schoolId: schoolId);
            },
          ),

          // ── Teacher Workspace Routes ──────────────────────────────────
          GoRoute(
            path: RouteNames.workspace,
            name: 'workspace',
            builder: (context, state) => const TeacherWorkspaceDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.workspaceDashboard,
            name: 'workspaceDashboard',
            builder: (context, state) => const TeacherWorkspaceDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.lessonPlanList,
            name: 'lessonPlanList',
            builder: (context, state) => const LessonPlanListPage(),
          ),
          GoRoute(
            path: RouteNames.lessonPlanCreate,
            name: 'lessonPlanCreate',
            builder: (context, state) => const LessonPlanGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.lessonPlanDetail,
            name: 'lessonPlanDetail',
            builder: (context, state) {
              final planId = state.uri.queryParameters['id'] ?? '';
              return LessonPlanDetailPage(planId: planId);
            },
          ),
          GoRoute(
            path: RouteNames.schemeOfWorkList,
            name: 'schemeOfWorkList',
            builder: (context, state) => const SchemeOfWorkListPage(),
          ),
          GoRoute(
            path: RouteNames.schemeOfWorkCreate,
            name: 'schemeOfWorkCreate',
            builder: (context, state) => const SchemeOfWorkGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.worksheetList,
            name: 'worksheetList',
            builder: (context, state) => const WorksheetListPage(),
          ),
          GoRoute(
            path: RouteNames.worksheetCreate,
            name: 'worksheetCreate',
            builder: (context, state) => const WorksheetGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.assignmentList,
            name: 'assignmentList',
            builder: (context, state) => const AssignmentListPage(),
          ),
          GoRoute(
            path: RouteNames.assignmentCreate,
            name: 'assignmentCreate',
            builder: (context, state) => const AssignmentGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.assignmentGenerator,
            name: 'assignmentGenerator',
            builder: (context, state) => const AssignmentGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.reportCommentGenerator,
            name: 'reportCommentGenerator',
            builder: (context, state) => const ReportCommentGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.contentAssistant,
            name: 'contentAssistant',
            builder: (context, state) => const ContentAssistantPage(),
          ),
          GoRoute(
            path: RouteNames.teachingResources,
            name: 'teachingResources',
            builder: (context, state) => const TeachingResourcesPage(),
          ),
          GoRoute(
            path: RouteNames.resourceLibrary,
            name: 'resourceLibrary',
            builder: (context, state) => const ResourceLibraryPage(),
          ),
          GoRoute(
            path: RouteNames.calendarPlanner,
            name: 'calendarPlanner',
            builder: (context, state) => const CalendarPlannerPage(),
          ),
          GoRoute(
            path: 'enhanced-dashboard',
            name: 'workspaceEnhancedDashboard',
            builder: (context, state) => const EnhancedWorkspaceDashboardPage(),
          ),
          GoRoute(
            path: 'presentations',
            name: 'presentationList',
            builder: (context, state) => const PresentationListPage(),
          ),
          GoRoute(
            path: 'presentations/generator',
            name: 'presentationGenerator',
            builder: (context, state) => const PresentationGeneratorPage(),
          ),
          GoRoute(
            path: 'communications',
            name: 'communicationList',
            builder: (context, state) => const CommunicationListPage(),
          ),
          GoRoute(
            path: 'communications/generator',
            name: 'communicationGenerator',
            builder: (context, state) => const CommunicationGeneratorPage(),
          ),
          GoRoute(
            path: 'tasks',
            name: 'taskManager',
            builder: (context, state) => const TaskManagerPage(),
          ),
          GoRoute(
            path: 'rubrics',
            name: 'rubricList',
            builder: (context, state) => const RubricListPage(),
          ),
          GoRoute(
            path: 'rubrics/generator',
            name: 'rubricGenerator',
            builder: (context, state) => const RubricGeneratorPage(),
          ),
          GoRoute(
            path: 'oral-questions',
            name: 'oralQuestionList',
            builder: (context, state) => const OralQuestionListPage(),
          ),
          GoRoute(
            path: 'oral-questions/generator',
            name: 'oralQuestionGenerator',
            builder: (context, state) => const OralQuestionGeneratorPage(),
          ),
          GoRoute(
            path: 'practical-assessments',
            name: 'practicalAssessmentList',
            builder: (context, state) => const PracticalAssessmentListPage(),
          ),
          GoRoute(
            path: 'practical-assessments/generator',
            name: 'practicalAssessmentGenerator',
            builder: (context, state) => const PracticalAssessmentGeneratorPage(),
          ),
          GoRoute(
            path: 'shared',
            name: 'sharedResources',
            builder: (context, state) => const SharedResourcesPage(),
          ),

          // ── Student Portal Routes ─────────────────────────────────────
          GoRoute(
            path: RouteNames.studentPortal,
            name: 'studentPortal',
            builder: (context, state) => const StudentPortalDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.studentPortalDashboard,
            name: 'studentPortalDashboard',
            builder: (context, state) => const StudentPortalDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.aiTutor,
            name: 'aiTutor',
            builder: (context, state) => const AiTutorPage(),
          ),
          GoRoute(
            path: RouteNames.practiceMode,
            name: 'practiceMode',
            builder: (context, state) => const PracticeModePage(),
          ),
          GoRoute(
            path: RouteNames.assignmentPortal,
            name: 'assignmentPortal',
            builder: (context, state) => const AssignmentPortalPage(),
          ),
          GoRoute(
            path: RouteNames.learningResources,
            name: 'learningResources',
            builder: (context, state) => const LearningResourcesPage(),
          ),
          GoRoute(
            path: RouteNames.documentChat,
            name: 'documentChat',
            builder: (context, state) => const DocumentChatPage(),
          ),
          GoRoute(
            path: RouteNames.flashcards,
            name: 'flashcards',
            builder: (context, state) => const FlashcardPage(),
          ),
          GoRoute(
            path: RouteNames.studyPlanner,
            name: 'studyPlanner',
            builder: (context, state) => const StudyPlannerPage(),
          ),
          GoRoute(
            path: RouteNames.studentGoals,
            name: 'studentGoals',
            builder: (context, state) => const GoalsPage(),
          ),
          GoRoute(
            path: RouteNames.studentProgress,
            name: 'studentProgress',
            builder: (context, state) => const ProgressPage(),
          ),
          GoRoute(
            path: RouteNames.studentNotifications,
            name: 'studentNotifications',
            builder: (context, state) => const StudentNotificationsPage(),
          ),

          // ═══════════════════════════════════════════════════════════
          // SCHOOL MANAGEMENT ROUTES
          // ═══════════════════════════════════════════════════════════

          // Schools (admin)
          GoRoute(
            path: RouteNames.schoolList,
            name: 'schoolList',
            builder: (context, state) => const SchoolListPage(),
          ),
          GoRoute(
            path: RouteNames.schoolDetail,
            name: 'schoolDetail',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['id'] ?? '';
              return SchoolDetailPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.schoolForm,
            name: 'schoolForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['id'];
              return SchoolFormPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.academicSessions,
            name: 'academicSessions',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return AcademicSessionPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.schoolCalendar,
            name: 'schoolCalendar',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return SchoolCalendarPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.schoolSettings,
            name: 'schoolSettings',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return SchoolSettingsPage(schoolId: schoolId);
            },
          ),

          // Students
          GoRoute(
            path: RouteNames.studentList,
            name: 'smStudentList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return StudentListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.studentDetail,
            name: 'smStudentDetail',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'] ?? '';
              return StudentDetailPage(userId: userId);
            },
          ),
          GoRoute(
            path: RouteNames.studentForm,
            name: 'smStudentForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final userId = state.uri.queryParameters['userId'];
              return StudentFormPage(schoolId: schoolId, userId: userId);
            },
          ),
          GoRoute(
            path: RouteNames.studentPromotion,
            name: 'studentPromotion',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return PromotionPage(schoolId: schoolId);
            },
          ),

          // Teachers
          GoRoute(
            path: RouteNames.teacherList,
            name: 'smTeacherList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return TeacherListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.teacherDetail,
            name: 'smTeacherDetail',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'] ?? '';
              return TeacherDetailPage(userId: userId);
            },
          ),
          GoRoute(
            path: RouteNames.teacherForm,
            name: 'smTeacherForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final userId = state.uri.queryParameters['userId'];
              return TeacherFormPage(schoolId: schoolId, userId: userId);
            },
          ),

          // Parents
          GoRoute(
            path: RouteNames.parentList,
            name: 'smParentList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return ParentListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.parentDetail,
            name: 'smParentDetail',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'] ?? '';
              return ParentDetailPage(userId: userId);
            },
          ),
          GoRoute(
            path: RouteNames.parentPortal,
            name: 'parentPortal',
            builder: (context, state) => const ParentPortalPage(),
          ),

          // Classes
          GoRoute(
            path: RouteNames.classList,
            name: 'smClassList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return ClassListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.classDetail,
            name: 'smClassDetail',
            builder: (context, state) {
              final classId = state.uri.queryParameters['id'] ?? '';
              return ClassDetailPage(classId: classId);
            },
          ),
          GoRoute(
            path: RouteNames.classForm,
            name: 'smClassForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final classId = state.uri.queryParameters['id'];
              return ClassFormPage(schoolId: schoolId, classId: classId);
            },
          ),

          // Subjects
          GoRoute(
            path: RouteNames.subjectList,
            name: 'smSubjectList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return SubjectListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.subjectForm,
            name: 'smSubjectForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final subjectId = state.uri.queryParameters['id'];
              return SubjectFormPage(schoolId: schoolId, subjectId: subjectId);
            },
          ),

          // Timetables
          GoRoute(
            path: RouteNames.timetableList,
            name: 'timetableList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return TimetableListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.timetableBuilder,
            name: 'timetableBuilder',
            builder: (context, state) {
              final timetableId = state.uri.queryParameters['id'] ?? '';
              return TimetableBuilderPage(timetableId: timetableId);
            },
          ),
          GoRoute(
            path: RouteNames.timetableView,
            name: 'timetableView',
            builder: (context, state) {
              final timetableId = state.uri.queryParameters['id'] ?? '';
              return TimetableViewPage(timetableId: timetableId);
            },
          ),

          // Attendance
          GoRoute(
            path: RouteNames.attendance,
            name: 'smAttendance',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return AttendancePage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.attendanceReport,
            name: 'smAttendanceReport',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return AttendanceReportPage(schoolId: schoolId);
            },
          ),

          // Homework
          GoRoute(
            path: RouteNames.homeworkList,
            name: 'smHomeworkList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return HomeworkListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.homeworkForm,
            name: 'smHomeworkForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final homeworkId = state.uri.queryParameters['id'];
              return HomeworkFormPage(schoolId: schoolId, homeworkId: homeworkId);
            },
          ),
          GoRoute(
            path: RouteNames.homeworkSubmissions,
            name: 'homeworkSubmissions',
            builder: (context, state) {
              final homeworkId = state.uri.queryParameters['id'] ?? '';
              return HomeworkSubmissionsPage(homeworkId: homeworkId);
            },
          ),

          // Announcements
          GoRoute(
            path: RouteNames.announcementList,
            name: 'smAnnouncementList',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return AnnouncementListPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.announcementForm,
            name: 'smAnnouncementForm',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              final announcementId = state.uri.queryParameters['id'];
              return AnnouncementFormPage(schoolId: schoolId, announcementId: announcementId);
            },
          ),

          // Documents
          GoRoute(
            path: RouteNames.documentCenter,
            name: 'documentCenter',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return DocumentCenterPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.documentUpload,
            name: 'documentUpload',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return DocumentUploadPage(schoolId: schoolId);
            },
          ),

          // Reports
          GoRoute(
            path: RouteNames.reportDashboard,
            name: 'smReportDashboard',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return ReportDashboardPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.studentReport,
            name: 'smStudentReport',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return StudentReportPage(schoolId: schoolId);
            },
          ),
          GoRoute(
            path: RouteNames.reportAttendance,
            name: 'smReportAttendance',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return sm.AttendanceReportPage(schoolId: schoolId);
            },
          ),

          // ── Parent Portal Routes ────────────────────────────────────
          GoRoute(
            path: '/parent-portal',
            redirect: (_, __) => RouteNames.parentDashboard,
          ),
          GoRoute(
            path: 'parent-portal/dashboard',
            name: 'parentDashboard',
            builder: (context, state) => const ParentDashboardPage(),
          ),
          GoRoute(
            path: 'parent-portal/child-profile',
            name: 'childProfile',
            builder: (context, state) => ChildProfilePage(studentId: state.uri.queryParameters['studentId'] ?? ''),
          ),
          GoRoute(
            path: 'parent-portal/performance',
            name: 'childPerformance',
            builder: (context, state) => ChildPerformancePage(studentId: state.uri.queryParameters['studentId'] ?? ''),
          ),
          GoRoute(
            path: 'parent-portal/attendance',
            name: 'childAttendance',
            builder: (context, state) => ChildAttendancePage(studentId: state.uri.queryParameters['studentId'] ?? ''),
          ),
          GoRoute(
            path: 'parent-portal/assignments',
            name: 'childAssignments',
            builder: (context, state) => ChildAssignmentsPage(studentId: state.uri.queryParameters['studentId'] ?? ''),
          ),
          GoRoute(
            path: 'parent-portal/messages',
            name: 'parentMessaging',
            builder: (context, state) => const ParentMessagingPage(),
          ),
          GoRoute(
            path: 'parent-portal/calendar',
            name: 'parentCalendar',
            builder: (context, state) => const ParentCalendarPage(),
          ),
          GoRoute(
            path: 'parent-portal/assistant',
            name: 'parentAssistant',
            builder: (context, state) => const ParentAssistantPage(),
          ),
          GoRoute(
            path: 'parent-portal/notifications',
            name: 'parentNotifications',
            builder: (context, state) => const ParentNotificationsPage(),
          ),
          GoRoute(
            path: 'parent-portal/insights',
            name: 'parentInsights',
            builder: (context, state) => const ParentInsightsPage(),
          ),
          GoRoute(
            path: 'parent-portal/reports',
            name: 'parentReports',
            builder: (context, state) => const ParentReportsPage(),
          ),
          GoRoute(
            path: 'parent-portal/engagement',
            name: 'parentEngagement',
            builder: (context, state) => const ParentEngagementDashboardPage(),
          ),

          // ─── Communication System ────────────────────────────────────────────
          GoRoute(
            path: RouteNames.communication,
            name: 'communication',
            builder: (context, state) => const CommunicationDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.communicationDashboard,
            name: 'communication-dashboard',
            builder: (context, state) => const CommunicationDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.conversationList,
            name: 'conversation-list',
            builder: (context, state) => const ConversationListPage(),
          ),
          GoRoute(
            path: RouteNames.chat,
            name: 'chat',
            builder: (context, state) => ChatPage(conversationId: state.uri.queryParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RouteNames.createConversation,
            name: 'create-conversation',
            builder: (context, state) => const CreateConversationPage(),
          ),
          GoRoute(
            path: RouteNames.announcementList,
            name: 'announcement-list',
            builder: (context, state) => const AnnouncementListPage(),
          ),
          GoRoute(
            path: RouteNames.announcementDetail,
            name: 'announcement-detail',
            builder: (context, state) => AnnouncementDetailPage(announcementId: state.uri.queryParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RouteNames.notificationCenter,
            name: 'notification-center',
            builder: (context, state) => const NotificationCenterPage(),
          ),
          GoRoute(
            path: RouteNames.notificationPreferences,
            name: 'notification-preferences',
            builder: (context, state) => const NotificationPreferencesPage(),
          ),
          GoRoute(
            path: RouteNames.forumList,
            name: 'forum-list',
            builder: (context, state) => const ForumListPage(),
          ),
          GoRoute(
            path: RouteNames.forumDetail,
            name: 'forum-detail',
            builder: (context, state) => ForumDetailPage(forumId: state.uri.queryParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RouteNames.forumPostDetail,
            name: 'forum-post-detail',
            builder: (context, state) => ForumPostDetailPage(postId: state.uri.queryParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RouteNames.communicationCalendar,
            name: 'communication-calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: RouteNames.createCalendarEvent,
            name: 'create-calendar-event',
            builder: (context, state) => const CreateEventPage(),
          ),
          GoRoute(
            path: RouteNames.aiAssistant,
            name: 'ai-assistant',
            builder: (context, state) => const AiAssistantPage(),
          ),
          GoRoute(
            path: RouteNames.knowledgeAssistant,
            name: 'knowledge-assistant',
            builder: (context, state) => const KnowledgeAssistantPage(),
          ),
          GoRoute(
            path: RouteNames.communicationAuditLogs,
            name: 'communication-audit-logs',
            builder: (context, state) => const ModerationAuditPage(),
          ),

          // ── Billing & Subscription Routes ──────────────────────────
          GoRoute(
            path: RouteNames.billingDashboard,
            name: 'billing-dashboard',
            builder: (context, state) => const BillingDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.billingSubscriptionPlans,
            name: 'billing-subscription-plans',
            builder: (context, state) => const SubscriptionPlansPage(),
          ),
          GoRoute(
            path: RouteNames.billingCheckout,
            name: 'billing-checkout',
            builder: (context, state) {
              final planId = state.uri.queryParameters['planId'];
              final billingCycle = state.uri.queryParameters['billingCycle'] ?? 'monthly';
              return CheckoutPage(planId: planId, billingCycle: billingCycle);
            },
          ),
          GoRoute(
            path: RouteNames.billingPaymentCallback,
            name: 'billing-payment-callback',
            builder: (context, state) {
              final txRef = state.uri.queryParameters['tx_ref'] ??
                  state.uri.queryParameters['txRef'] ?? '';
              final status = state.uri.queryParameters['status'] ?? '';
              return PaymentCallbackPage(txRef: txRef, status: status);
            },
          ),
          GoRoute(
            path: RouteNames.billingHistory,
            name: 'billing-history',
            builder: (context, state) => const BillingHistoryPage(),
          ),
          GoRoute(
            path: RouteNames.billingInvoiceDetail,
            name: 'billing-invoice-detail',
            builder: (context, state) {
              final invoiceId = state.uri.queryParameters['id'] ?? '';
              return InvoiceDetailPage(invoiceId: invoiceId);
            },
          ),
          GoRoute(
            path: RouteNames.billingAiCredits,
            name: 'billing-ai-credits',
            builder: (context, state) => const AiCreditsPage(),
          ),
          GoRoute(
            path: RouteNames.billingCoupons,
            name: 'billing-coupons',
            builder: (context, state) => const CouponManagementPage(),
          ),
          GoRoute(
            path: RouteNames.billingReferrals,
            name: 'billing-referrals',
            builder: (context, state) => const ReferralProgramPage(),
          ),
          GoRoute(
            path: RouteNames.billingLicenses,
            name: 'billing-licenses',
            builder: (context, state) => const LicenseManagementPage(),
          ),
          GoRoute(
            path: RouteNames.billingRevenue,
            name: 'billing-revenue',
            builder: (context, state) => const RevenueDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.billingSchoolBilling,
            name: 'billing-school-billing',
            builder: (context, state) {
              final schoolId = state.uri.queryParameters['schoolId'] ?? '';
              return SchoolBillingPage(schoolId: schoolId);
            },
          ),

          // ── Super Admin Platform Routes ──────────────────────────
          GoRoute(
            path: RouteNames.superAdminDashboard,
            name: 'super-admin-dashboard',
            builder: (context, state) => const SuperAdminDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminSchools,
            name: 'super-admin-schools',
            builder: (context, state) => const SchoolManagementPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminUsers,
            name: 'super-admin-users',
            builder: (context, state) => const UserManagementPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminAI,
            name: 'super-admin-ai',
            builder: (context, state) => const AIManagementPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminBilling,
            name: 'super-admin-billing',
            builder: (context, state) => const BillingManagementPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminSupport,
            name: 'super-admin-support',
            builder: (context, state) => const SupportCenterPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminSecurity,
            name: 'super-admin-security',
            builder: (context, state) => const SecurityCenterPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminInfrastructure,
            name: 'super-admin-infrastructure',
            builder: (context, state) => const InfrastructureMonitoringPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminIntelligence,
            name: 'super-admin-intelligence',
            builder: (context, state) => const IntelligenceCenterPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminMarketplace,
            name: 'super-admin-marketplace',
            builder: (context, state) => const MarketplaceManagementPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminAnalytics,
            name: 'super-admin-analytics',
            builder: (context, state) => const PlatformAnalyticsPage(),
          ),
          GoRoute(
            path: RouteNames.superAdminSettings,
            name: 'super-admin-settings',
            builder: (context, state) => const GlobalSettingsPage(),
          ),
        ],
      ),
    ],

    // ─── Error / 404 Handler ──────────────────────────────────────
    errorBuilder: (context, state) => NotFoundPage(
      error: state.error,
      path: state.matchedLocation,
    ),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// NOT FOUND PAGE (404)
// ═══════════════════════════════════════════════════════════════════════

/// Shown when the user navigates to a route that does not exist in
/// the route tree.
///
/// Provides a friendly message and a button to navigate back to the
/// dashboard (or login if unauthenticated).
class NotFoundPage extends ConsumerWidget {
  const NotFoundPage({
    required this.error,
    this.path,
    super.key,
  });

  /// The [GoException] from GoRouter describing the error.
  final GoException? error;

  /// The unmatched path the user attempted to visit.
  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (path != null)
                Text(
                  'The page "$path" does not exist.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(
                  isAuthenticated
                      ? RouteNames.dashboard
                      : RouteNames.login,
                ),
                icon: const Icon(Icons.home),
                label: Text(
                  isAuthenticated ? 'Go to Dashboard' : 'Go to Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
