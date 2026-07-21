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
import '../features/onboarding/presentation/pages/onboarding_page.dart';
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
import '../features/student_portal/presentation/pages/study_planner_page.dart' hide StudyPlannerPage;
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
import '../features/school_management/presentation/pages/announcement/announcement_list_page.dart' hide AnnouncementListPage;
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
import '../features/billing/presentation/pages/referral_program_page.dart' hide ReferralProgramPage;
import '../features/billing/presentation/pages/license_management_page.dart';
import '../features/billing/presentation/pages/revenue_dashboard_page.dart';
import '../features/billing/presentation/pages/school_billing_page.dart';

// ── Marketplace ──
import '../features/marketplace/presentation/pages/marketplace_home_page.dart';
import '../features/marketplace/presentation/pages/marketplace_search_page.dart';
import '../features/marketplace/presentation/pages/product_detail_page.dart';
import '../features/marketplace/presentation/pages/category_products_page.dart';
import '../features/marketplace/presentation/pages/buyer_dashboard_page.dart';
import '../features/marketplace/presentation/pages/seller_dashboard_page.dart';
import '../features/marketplace/presentation/pages/create_product_page.dart';
import '../features/marketplace/presentation/pages/ai_resource_generator_page.dart';
import '../features/marketplace/presentation/pages/quality_review_page.dart';
import '../features/marketplace/presentation/pages/cart_page.dart';
import '../features/marketplace/presentation/pages/checkout_page.dart' as mp;
import '../features/marketplace/presentation/pages/product_reviews_page.dart';
import '../features/marketplace/presentation/pages/marketplace_moderation_page.dart';
import '../features/marketplace/presentation/pages/commission_management_page.dart';
import '../features/marketplace/presentation/pages/marketplace_analytics_page.dart';
import '../features/marketplace/presentation/pages/marketplace_notifications_page.dart';

// ── Offline & Connectivity ──
import '../features/offline/presentation/pages/offline_center_page.dart';
import '../features/offline/presentation/pages/connectivity_status_page.dart';
import '../features/offline/presentation/pages/offline_exam_page.dart';
import '../features/ccms/presentation/pages/ccms_dashboard_page.dart';
import '../features/ccms/presentation/pages/educational_levels_page.dart';
import '../features/ccms/presentation/pages/curricula_management_page.dart';
import '../features/ccms/presentation/pages/subjects_management_page.dart';
import '../features/ccms/presentation/pages/topic_management_page.dart';
import '../features/ccms/presentation/pages/content_library_page.dart';
import '../features/ccms/presentation/pages/content_editor_page.dart';
import '../features/ccms/presentation/pages/content_detail_page.dart';
import '../features/ccms/presentation/pages/content_import_page.dart';
import '../features/ccms/presentation/pages/content_collections_page.dart';
import '../features/ccms/presentation/pages/ai_curriculum_engine_page.dart';
import '../features/ccms/presentation/pages/answer_repository_page.dart';
import '../features/ccms/presentation/pages/audit_trail_page.dart' as ccms_audit;
import '../features/ccms/presentation/pages/security_center_page.dart' as ccms_security;
import '../features/ccms/presentation/pages/monitoring_dashboard_page.dart' as ccms_monitoring;
import '../features/ccms/presentation/pages/deployment_page.dart';
import '../features/exam_ecosystem/presentation/pages/exam_ecosystem_dashboard_page.dart';
import '../features/exam_ecosystem/presentation/pages/mock_exam_list_page.dart';
import '../features/exam_ecosystem/presentation/pages/mock_exam_take_page.dart';
import '../features/exam_ecosystem/presentation/pages/readiness_dashboard_page.dart';
import '../features/exam_ecosystem/presentation/pages/study_planner_page.dart';
import '../features/exam_ecosystem/presentation/pages/jamb_preparation_page.dart';
import '../features/admission_hub/presentation/pages/admission_hub_dashboard_page.dart';
import '../features/admission_hub/presentation/pages/university_search_page.dart';
import '../features/admission_hub/presentation/pages/post_utme_center_page.dart';
import '../features/admission_hub/presentation/pages/admission_checker_page.dart';
import '../features/admission_hub/presentation/pages/admission_checklist_page.dart';
import '../features/ai_coach/presentation/pages/ai_coach_dashboard_page.dart';
import '../features/ai_coach/presentation/pages/coach_chat_page.dart';
import '../features/ai_coach/presentation/pages/weak_topics_page.dart';
import '../features/customer_success/presentation/pages/customer_success_dashboard_page.dart';
import '../features/customer_success/presentation/pages/onboarding_wizard_page.dart';
import '../features/customer_success/presentation/pages/help_center_page.dart';
import '../features/customer_success/presentation/pages/feedback_page.dart';
import '../features/customer_success/presentation/pages/feature_requests_page.dart';
import '../features/marketing/presentation/pages/marketing_dashboard_page.dart';
import '../features/marketing/presentation/pages/blog_management_page.dart';
import '../features/marketing/presentation/pages/referral_program_page.dart';
import '../features/marketing/presentation/pages/affiliate_program_page.dart';
import '../features/edu_os/presentation/pages/edu_os_dashboard_page.dart';
import '../features/edu_os/presentation/pages/module_detail_page.dart';
import '../features/edu_os/presentation/pages/school_modules_page.dart';
import '../features/analytics_dashboard/presentation/pages/analytics_dashboard_home_page.dart';
import '../features/analytics_dashboard/presentation/pages/user_acquisition_page.dart';
import '../features/analytics_dashboard/presentation/pages/revenue_analytics_page.dart';
import '../features/analytics_dashboard/presentation/pages/release_notes_page.dart';

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
      // ── Loading Guard ───────────────────────────────────────
      // While loading, only allow splash to avoid flicker.
      if (authState.isLoading && currentPath != RouteNames.splash) {
        return RouteNames.splash;
      }

      final isAuthenticated = authState.when(
        data: (authData) => authData.session != null,
        loading: () => false, // Handled by loading guard above.
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
            builder: (context, state) => const StudentListPage(),
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
              final userId = state.uri.queryParameters['userId'];
              return StudentFormPage(studentId: userId);
            },
          ),
          GoRoute(
            path: RouteNames.studentPromotion,
            name: 'studentPromotion',
            builder: (context, state) => const PromotionPage(),
          ),

          // Teachers
          GoRoute(
            path: RouteNames.teacherList,
            name: 'smTeacherList',
            builder: (context, state) => const TeacherListPage(),
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
              final userId = state.uri.queryParameters['userId'];
              return TeacherFormPage(teacherId: userId);
            },
          ),

          // Parents
          GoRoute(
            path: RouteNames.parentList,
            name: 'smParentList',
            builder: (context, state) => const ParentListPage(),
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
            builder: (context, state) => const ClassListPage(),
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
              final classId = state.uri.queryParameters['id'];
              return ClassFormPage(classId: classId);
            },
          ),

          // Subjects
          GoRoute(
            path: RouteNames.subjectList,
            name: 'smSubjectList',
            builder: (context, state) => const SubjectListPage(),
          ),
          GoRoute(
            path: RouteNames.subjectForm,
            name: 'smSubjectForm',
            builder: (context, state) {
              final subjectId = state.uri.queryParameters['id'];
              return SubjectFormPage(subjectId: subjectId);
            },
          ),

          // Timetables
          GoRoute(
            path: RouteNames.timetableList,
            name: 'timetableList',
            builder: (context, state) => const TimetableListPage(),
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
            builder: (context, state) => const AttendancePage(),
          ),
          GoRoute(
            path: RouteNames.attendanceReport,
            name: 'smAttendanceReport',
            builder: (context, state) => const AttendanceReportPage(),
          ),

          // Homework
          GoRoute(
            path: RouteNames.homeworkList,
            name: 'smHomeworkList',
            builder: (context, state) => const HomeworkListPage(),
          ),
          GoRoute(
            path: RouteNames.homeworkForm,
            name: 'smHomeworkForm',
            builder: (context, state) {
              final homeworkId = state.uri.queryParameters['id'];
              return HomeworkFormPage(homeworkId: homeworkId);
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
            builder: (context, state) => const AnnouncementListPage(),
          ),
          GoRoute(
            path: RouteNames.announcementForm,
            name: 'smAnnouncementForm',
            builder: (context, state) {
              final announcementId = state.uri.queryParameters['id'];
              return AnnouncementFormPage(announcementId: announcementId);
            },
          ),

          // Documents
          GoRoute(
            path: RouteNames.documentCenter,
            name: 'documentCenter',
            builder: (context, state) => const DocumentCenterPage(),
          ),
          GoRoute(
            path: RouteNames.documentUpload,
            name: 'documentUpload',
            builder: (context, state) => const DocumentUploadPage(),
          ),

          // Reports
          GoRoute(
            path: RouteNames.reportDashboard,
            name: 'smReportDashboard',
            builder: (context, state) => const ReportDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.studentReport,
            name: 'smStudentReport',
            builder: (context, state) => const StudentReportPage(),
          ),
          GoRoute(
            path: RouteNames.reportAttendance,
            name: 'smReportAttendance',
            builder: (context, state) => const sm.AttendanceReportPage(),
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
            builder: (context, state) => ForumPostDetailPage(forumId: state.uri.queryParameters['forumId'] ?? '', postId: state.uri.queryParameters['id'] ?? ''),
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
              final planId = state.uri.queryParameters['planId'] ?? '';
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

          // ── Marketplace Routes ──────────────────────────────────────
          GoRoute(
            path: RouteNames.marketplace,
            name: 'marketplace',
            builder: (context, state) => const MarketplaceHomePage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceSearch,
            name: 'marketplace-search',
            builder: (context, state) => const MarketplaceSearchPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceProductDetail,
            name: 'marketplace-product-detail',
            builder: (context, state) {
              final productId = state.uri.queryParameters['id'] ?? '';
              return ProductDetailPage(productId: productId);
            },
          ),
          GoRoute(
            path: RouteNames.marketplaceCategory,
            name: 'marketplace-category',
            builder: (context, state) {
              final categoryId = state.uri.queryParameters['id'] ?? '';
              final categoryName = state.uri.queryParameters['name'] ?? 'Category';
              return CategoryProductsPage(
                categoryId: categoryId,
                categoryName: categoryName,
              );
            },
          ),
          GoRoute(
            path: RouteNames.marketplaceBuyerDashboard,
            name: 'marketplace-buyer-dashboard',
            builder: (context, state) => const BuyerDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceSellerDashboard,
            name: 'marketplace-seller-dashboard',
            builder: (context, state) => const SellerDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceCreateProduct,
            name: 'marketplace-create-product',
            builder: (context, state) {
              final productId = state.uri.queryParameters['id'];
              return CreateProductPage(productId: productId);
            },
          ),
          GoRoute(
            path: RouteNames.marketplaceAiGenerator,
            name: 'marketplace-ai-generator',
            builder: (context, state) => const AiResourceGeneratorPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceQualityReview,
            name: 'marketplace-quality-review',
            builder: (context, state) {
              final productId = state.uri.queryParameters['productId'];
              return QualityReviewPage(productId: productId);
            },
          ),
          GoRoute(
            path: RouteNames.marketplaceCart,
            name: 'marketplace-cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceCheckout,
            name: 'marketplace-checkout',
            builder: (context, state) => const mp.CheckoutPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceReviews,
            name: 'marketplace-reviews',
            builder: (context, state) {
              final productId = state.uri.queryParameters['productId'] ?? '';
              return ProductReviewsPage(productId: productId);
            },
          ),
          GoRoute(
            path: RouteNames.marketplaceModeration,
            name: 'marketplace-moderation',
            builder: (context, state) => const MarketplaceModerationPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceCommissions,
            name: 'marketplace-commissions',
            builder: (context, state) => const CommissionManagementPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceAnalytics,
            name: 'marketplace-analytics',
            builder: (context, state) => const MarketplaceAnalyticsPage(),
          ),
          GoRoute(
            path: RouteNames.marketplaceNotifications,
            name: 'marketplace-notifications',
            builder: (context, state) => const MarketplaceNotificationsPage(),
          ),

          // ── Offline & Connectivity Routes ──────────────────────────
          GoRoute(
            path: RouteNames.offlineCenter,
            name: 'offline-center',
            builder: (context, state) => const OfflineCenterPage(),
          ),
          GoRoute(
            path: RouteNames.connectivityStatus,
            name: 'connectivity-status',
            builder: (context, state) => const ConnectivityStatusPage(),
          ),
          GoRoute(
            path: RouteNames.offlineExam,
            name: 'offline-exam',
            builder: (context, state) {
              final examId = state.uri.queryParameters['examId'] ?? '';
              final examTitle = state.uri.queryParameters['examTitle'] ?? 'Exam';
              return OfflineExamPage(examId: examId, examTitle: examTitle);
            },
          ),

          // ── CCMS & Enterprise Routes ──────────────────────────────
          GoRoute(
            path: RouteNames.ccmsDashboard,
            name: 'ccms-dashboard',
            builder: (context, state) => const CcmsDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.educationalLevels,
            name: 'educational-levels',
            builder: (context, state) => const EducationalLevelsPage(),
          ),
          GoRoute(
            path: RouteNames.curriculaManagement,
            name: 'curricula-management',
            builder: (context, state) => const CurriculaManagementPage(),
          ),
          GoRoute(
            path: RouteNames.subjectsManagement,
            name: 'subjects-management',
            builder: (context, state) => const SubjectsManagementPage(),
          ),
          GoRoute(
            path: RouteNames.topicManagement,
            name: 'topic-management',
            builder: (context, state) => const TopicManagementPage(),
          ),
          GoRoute(
            path: RouteNames.contentLibrary,
            name: 'content-library',
            builder: (context, state) => const ContentLibraryPage(),
          ),
          GoRoute(
            path: RouteNames.contentEditor,
            name: 'content-editor',
            builder: (context, state) {
              final contentId = state.uri.queryParameters['id'];
              return ContentEditorPage(contentId: contentId);
            },
          ),
          GoRoute(
            path: RouteNames.contentDetail,
            name: 'content-detail',
            builder: (context, state) {
              final contentId = state.uri.queryParameters['id'] ?? '';
              return ContentDetailPage(contentId: contentId);
            },
          ),
          GoRoute(
            path: RouteNames.contentImport,
            name: 'content-import',
            builder: (context, state) => const ContentImportPage(),
          ),
          GoRoute(
            path: RouteNames.contentCollections,
            name: 'content-collections',
            builder: (context, state) => const ContentCollectionsPage(),
          ),
          GoRoute(
            path: RouteNames.aiCurriculumEngine,
            name: 'ai-curriculum-engine',
            builder: (context, state) => const AiCurriculumEnginePage(),
          ),
          GoRoute(
            path: RouteNames.answerRepository,
            name: 'answer-repository',
            builder: (context, state) => const AnswerRepositoryPage(),
          ),
          GoRoute(
            path: RouteNames.auditTrail,
            name: 'audit-trail',
            builder: (context, state) => const ccms_audit.AuditTrailPage(),
          ),
          GoRoute(
            path: RouteNames.securityCenter,
            name: 'ccms-security-center',
            builder: (context, state) => const ccms_security.SecurityCenterPage(),
          ),
          GoRoute(
            path: RouteNames.monitoringDashboard,
            name: 'monitoring-dashboard',
            builder: (context, state) => const ccms_monitoring.MonitoringDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.deploymentCenter,
            name: 'deployment-center',
            builder: (context, state) => const DeploymentPage(),
          ),

          // ── Exam Ecosystem Routes ──────────────────────────────
          GoRoute(path: RouteNames.examEcosystemDashboard, name: 'exam-ecosystem', builder: (context, state) => const ExamEcosystemDashboardPage()),
          GoRoute(path: RouteNames.mockExamList, name: 'mock-exam-list', builder: (context, state) => const MockExamListPage()),
          GoRoute(path: RouteNames.mockExamTake, name: 'mock-exam-take', builder: (context, state) { final examId = state.uri.queryParameters['id'] ?? ''; return MockExamTakePage(examId: examId); }),
          GoRoute(path: RouteNames.readinessDashboard, name: 'readiness-dashboard', builder: (context, state) => const ReadinessDashboardPage()),
          GoRoute(path: RouteNames.studyPlanner, name: 'study-planner', builder: (context, state) => const StudyPlannerPage()),
          GoRoute(path: RouteNames.jambPreparation, name: 'jamb-preparation', builder: (context, state) => const JambPreparationPage()),

          // ── Admission Hub Routes ──────────────────────────────
          GoRoute(path: RouteNames.admissionHubDashboard, name: 'admission-hub', builder: (context, state) => const AdmissionHubDashboardPage()),
          GoRoute(path: RouteNames.universitySearch, name: 'university-search', builder: (context, state) => const UniversitySearchPage()),
          GoRoute(path: RouteNames.postUtmeCenter, name: 'post-utme-center', builder: (context, state) => const PostUtmeCenterPage()),
          GoRoute(path: RouteNames.admissionChecker, name: 'admission-checker', builder: (context, state) => const AdmissionCheckerPage()),
          GoRoute(path: RouteNames.admissionChecklist, name: 'admission-checklist', builder: (context, state) => const AdmissionChecklistPage()),

          // ── AI Coach Routes ──────────────────────────────
          GoRoute(path: RouteNames.aiCoachDashboard, name: 'ai-coach', builder: (context, state) => const AiCoachDashboardPage()),
          GoRoute(path: RouteNames.coachChat, name: 'coach-chat', builder: (context, state) => const CoachChatPage()),
          GoRoute(path: RouteNames.weakTopics, name: 'weak-topics', builder: (context, state) => const WeakTopicsPage()),

          // ── Customer Success Routes ──────────────────────────────
          GoRoute(path: RouteNames.customerSuccessDashboard, name: 'customer-success', builder: (context, state) => const CustomerSuccessDashboardPage()),
          GoRoute(path: RouteNames.onboardingWizard, name: 'onboarding-wizard', builder: (context, state) => const OnboardingWizardPage()),
          GoRoute(path: RouteNames.helpCenter, name: 'help-center', builder: (context, state) => const HelpCenterPage()),
          GoRoute(path: RouteNames.feedbackPage, name: 'feedback', builder: (context, state) => const FeedbackPage()),
          GoRoute(path: RouteNames.featureRequestsPage, name: 'feature-requests', builder: (context, state) => const FeatureRequestsPage()),

          // ── Marketing Routes ──────────────────────────────
          GoRoute(path: RouteNames.marketingDashboard, name: 'marketing', builder: (context, state) => const MarketingDashboardPage()),
          GoRoute(path: RouteNames.blogManagement, name: 'blog-management', builder: (context, state) => const BlogManagementPage()),
          GoRoute(path: RouteNames.referralProgram, name: 'referral-program', builder: (context, state) => const ReferralProgramPage()),
          GoRoute(path: RouteNames.affiliateProgram, name: 'affiliate-program', builder: (context, state) => const AffiliateProgramPage()),

          // ── EduOS Routes ──────────────────────────────
          GoRoute(path: RouteNames.eduOsDashboard, name: 'edu-os', builder: (context, state) => const EduOsDashboardPage()),
          GoRoute(path: RouteNames.moduleDetail, name: 'module-detail', builder: (context, state) { final code = state.uri.queryParameters['code'] ?? ''; return ModuleDetailPage(moduleCode: code); }),
          GoRoute(path: RouteNames.schoolModules, name: 'school-modules', builder: (context, state) {
            final schoolId = state.uri.queryParameters['schoolId'] ?? '';
            return SchoolModulesPage(schoolId: schoolId);
          }),

          // ── Analytics Dashboard Routes ──────────────────────────────
          GoRoute(path: RouteNames.analyticsDashboardHome, name: 'analytics', builder: (context, state) => const AnalyticsDashboardHomePage()),
          GoRoute(path: RouteNames.userAcquisition, name: 'user-acquisition', builder: (context, state) => const UserAcquisitionPage()),
          GoRoute(path: RouteNames.revenueAnalytics, name: 'revenue-analytics', builder: (context, state) => const RevenueAnalyticsPage()),
          GoRoute(path: RouteNames.releaseNotes, name: 'release-notes', builder: (context, state) => const ReleaseNotesPage()),

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
