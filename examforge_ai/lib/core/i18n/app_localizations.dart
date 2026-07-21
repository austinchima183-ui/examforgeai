// ============================================================================
// ExamForge AI — Localization / Internationalization (i18n) Infrastructure
// ============================================================================
// Provides a complete localization framework supporting:
//   - English (primary)
//   - Future Nigerian languages (Yoruba, Igbo, Hausa)
//   - RTL compatibility
//   - Date formatting (locale-aware)
//   - Number formatting (locale-aware)
//   - Currency formatting (Nigerian Naira)
//   - Pluralization support
//
// DESIGN:
//   - Every user-facing string must go through AppLocalizations
//   - Fallback to English for missing translations
//   - Supports runtime locale switching
//   - Generates a coverage report per locale
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTED LOCALES
// ═══════════════════════════════════════════════════════════════════════

class AppLocales {
  AppLocales._();

  static const Locale english = Locale('en');
  static const Locale yoruba = Locale('yo');
  static const Locale igbo = Locale('ig');
  static const Locale hausa = Locale('ha');

  static const List<Locale> supported = [english, yoruba, igbo, hausa];

  static const Map<String, String> nativeNames = {
    'en': 'English',
    'yo': 'Yorùbá',
    'ig': 'Igbo',
    'ha': 'Hausa',
  };

  static const Set<String> rtlLocales = {};

  static bool isRTL(Locale locale) => rtlLocales.contains(locale.languageCode);
}

// ═══════════════════════════════════════════════════════════════════════
// LOCALIZATION KEYS
// ═══════════════════════════════════════════════════════════════════════

class L10nKeys {
  L10nKeys._();

  // Auth
  static const authWelcomeBack = 'auth.welcome_back';
  static const authSignInToContinue = 'auth.sign_in_to_continue';
  static const authEmail = 'auth.email';
  static const authPassword = 'auth.password';
  static const authRememberMe = 'auth.remember_me';
  static const authForgotPassword = 'auth.forgot_password';
  static const authSignIn = 'auth.sign_in';
  static const authOr = 'auth.or';
  static const authGoogleSignIn = 'auth.google_sign_in';
  static const authAppleSignIn = 'auth.apple_sign_in';
  static const authNoAccount = 'auth.no_account';
  static const authSignUp = 'auth.sign_up';
  static const authEmailRequired = 'auth.email_required';
  static const authInvalidEmail = 'auth.invalid_email';
  static const authPasswordRequired = 'auth.password_required';
  static const authLoginFailed = 'auth.login_failed';
  static const authLoggingIn = 'auth.logging_in';

  // Dashboard
  static const dashWelcome = 'dash.welcome';
  static const dashUpcomingExams = 'dash.upcoming_exams';
  static const dashCompletedExams = 'dash.completed_exams';
  static const dashAverageScore = 'dash.average_score';
  static const dashTakeExam = 'dash.take_exam';
  static const dashViewResults = 'dash.view_results';
  static const dashPracticeMode = 'dash.practice_mode';
  static const dashTotalStudents = 'dash.total_students';
  static const dashCreateExam = 'dash.create_exam';
  static const dashQuestionBank = 'dash.question_bank';
  static const dashGradeExams = 'dash.grade_exams';
  static const dashViewReports = 'dash.view_reports';
  static const dashRecentActivity = 'dash.recent_activity';
  static const dashSubjects = 'dash.subjects';
  static const dashClasses = 'dash.classes';
  static const dashPendingExams = 'dash.pending_exams';

  // CBT Exam
  static const cbtLoadingExam = 'cbt.loading_exam';
  static const cbtSaving = 'cbt.saving';
  static const cbtSaved = 'cbt.saved';
  static const cbtConnected = 'cbt.connected';
  static const cbtOffline = 'cbt.offline';
  static const cbtReconnecting = 'cbt.reconnecting';
  static const cbtPrevious = 'cbt.previous';
  static const cbtNext = 'cbt.next';
  static const cbtFlagForReview = 'cbt.flag_for_review';
  static const cbtUnflag = 'cbt.unflag';
  static const cbtQuestionNavigator = 'cbt.question_navigator';
  static const cbtNoQuestion = 'cbt.no_question';
  static const cbtSubmitExam = 'cbt.submit_exam';
  static const cbtSubmitConfirm = 'cbt.submit_confirm';
  static const cbtSubmitConfirmMsg = 'cbt.submit_confirm_msg';
  static const cbtTimeWarning = 'cbt.time_warning';
  static const cbtTimeCritical = 'cbt.time_critical';
  static const cbtExamComplete = 'cbt.exam_complete';
  static const cbtQuestionOf = 'cbt.question_of';

  // Results
  static const resultsTitle = 'results.title';
  static const resultsScore = 'results.score';
  static const resultsPassed = 'results.passed';
  static const resultsFailed = 'results.failed';
  static const resultsTimeTaken = 'results.time_taken';
  static const resultsReviewAnswers = 'results.review_answers';
  static const resultsBackToDashboard = 'results.back_to_dashboard';

  // Marketplace
  static const mktTitle = 'mkt.title';
  static const mktDiscover = 'mkt.discover';
  static const mktSearchHint = 'mkt.search_hint';
  static const mktFeatured = 'mkt.featured';
  static const mktSeeAll = 'mkt.see_all';
  static const mktTrending = 'mkt.trending';
  static const mktCategories = 'mkt.categories';
  static const mktRecommended = 'mkt.recommended';
  static const mktAddToCart = 'mkt.add_to_cart';
  static const mktBuyNow = 'mkt.buy_now';
  static const mktFree = 'mkt.free';

  // Common
  static const commonRetry = 'common.retry';
  static const commonCancel = 'common.cancel';
  static const commonConfirm = 'common.confirm';
  static const commonSave = 'common.save';
  static const commonDelete = 'common.delete';
  static const commonEdit = 'common.edit';
  static const commonClose = 'common.close';
  static const commonLoading = 'common.loading';
  static const commonError = 'common.error';
  static const commonSuccess = 'common.success';
  static const commonNoData = 'common.no_data';
  static const commonSearch = 'common.search';
  static const commonJustNow = 'common.just_now';
  static const commonMinutesAgo = 'common.minutes_ago';
  static const commonHoursAgo = 'common.hours_ago';
  static const commonDaysAgo = 'common.days_ago';

  // Admin
  static const adminDashboard = 'admin.dashboard';
  static const adminUsers = 'admin.users';
  static const adminSchools = 'admin.schools';
  static const adminBilling = 'admin.billing';
  static const adminSecurity = 'admin.security';
  static const adminSettings = 'admin.settings';
  static const adminTotalSchools = 'admin.total_schools';
  static const adminRevenueToday = 'admin.revenue_today';

  // Accessibility
  static const a11yLoadingContent = 'a11y.loading_content';
  static const a11yErrorOccurred = 'a11y.error_occurred';
  static const a11yNavigationMenu = 'a11y.navigation_menu';
}

// ═══════════════════════════════════════════════════════════════════════
// ENGLISH TRANSLATIONS (COMPLETE)
// ═══════════════════════════════════════════════════════════════════════

const Map<String, String> _englishTranslations = {
  L10nKeys.authWelcomeBack: 'Welcome Back',
  L10nKeys.authSignInToContinue: 'Sign in to continue to ExamForge AI',
  L10nKeys.authEmail: 'Email',
  L10nKeys.authPassword: 'Password',
  L10nKeys.authRememberMe: 'Remember me',
  L10nKeys.authForgotPassword: 'Forgot Password?',
  L10nKeys.authSignIn: 'Sign In',
  L10nKeys.authOr: 'OR',
  L10nKeys.authGoogleSignIn: 'Google Sign-In coming soon',
  L10nKeys.authAppleSignIn: 'Apple Sign-In coming soon',
  L10nKeys.authNoAccount: "Don't have an account?",
  L10nKeys.authSignUp: 'Sign Up',
  L10nKeys.authEmailRequired: 'Email is required',
  L10nKeys.authInvalidEmail: 'Enter a valid email address',
  L10nKeys.authPasswordRequired: 'Password is required',
  L10nKeys.authLoginFailed: 'Login failed. Please check your credentials.',
  L10nKeys.authLoggingIn: 'Signing in...',
  L10nKeys.dashWelcome: 'Welcome',
  L10nKeys.dashUpcomingExams: 'Upcoming Exams',
  L10nKeys.dashCompletedExams: 'Completed Exams',
  L10nKeys.dashAverageScore: 'Average Score',
  L10nKeys.dashTakeExam: 'Take Exam',
  L10nKeys.dashViewResults: 'View Results',
  L10nKeys.dashPracticeMode: 'Practice Mode',
  L10nKeys.dashRecentActivity: 'Recent Activity',
  L10nKeys.dashTotalStudents: 'Total Students',
  L10nKeys.dashClasses: 'Classes',
  L10nKeys.dashPendingExams: 'Pending Exams',
  L10nKeys.dashCreateExam: 'Create Exam',
  L10nKeys.dashQuestionBank: 'Question Bank',
  L10nKeys.dashGradeExams: 'Grade Exams',
  L10nKeys.dashViewReports: 'View Reports',
  L10nKeys.dashSubjects: 'Subjects',
  L10nKeys.cbtLoadingExam: 'Loading exam...',
  L10nKeys.cbtSaving: 'Saving...',
  L10nKeys.cbtSaved: 'Saved',
  L10nKeys.cbtConnected: 'Connected',
  L10nKeys.cbtOffline: 'Offline',
  L10nKeys.cbtReconnecting: 'Reconnecting...',
  L10nKeys.cbtPrevious: 'Previous',
  L10nKeys.cbtNext: 'Next',
  L10nKeys.cbtFlagForReview: 'Flag for Review',
  L10nKeys.cbtUnflag: 'Unflag',
  L10nKeys.cbtQuestionNavigator: 'Question Navigator',
  L10nKeys.cbtNoQuestion: 'No question to display',
  L10nKeys.cbtSubmitExam: 'Submit Exam',
  L10nKeys.cbtSubmitConfirm: 'Submit Exam?',
  L10nKeys.cbtSubmitConfirmMsg: 'Are you sure you want to submit? You cannot change your answers after submission.',
  L10nKeys.cbtTimeWarning: 'Warning: Less than 15 minutes remaining!',
  L10nKeys.cbtTimeCritical: 'URGENT: Less than 5 minutes remaining!',
  L10nKeys.cbtExamComplete: 'Exam Complete',
  L10nKeys.cbtQuestionOf: 'Question {current} of {total}',
  L10nKeys.resultsTitle: 'Results',
  L10nKeys.resultsScore: 'Score',
  L10nKeys.resultsPassed: 'Passed',
  L10nKeys.resultsFailed: 'Failed',
  L10nKeys.resultsTimeTaken: 'Time Taken',
  L10nKeys.resultsReviewAnswers: 'Review Answers',
  L10nKeys.resultsBackToDashboard: 'Back to Dashboard',
  L10nKeys.mktTitle: 'Marketplace',
  L10nKeys.mktDiscover: 'Discover Educational\nResources',
  L10nKeys.mktSearchHint: 'Find question banks, study materials...',
  L10nKeys.mktFeatured: 'Featured Products',
  L10nKeys.mktSeeAll: 'See All',
  L10nKeys.mktTrending: 'Trending Now',
  L10nKeys.mktCategories: 'Browse Categories',
  L10nKeys.mktRecommended: 'Recommended for You',
  L10nKeys.mktAddToCart: 'Add to Cart',
  L10nKeys.mktBuyNow: 'Buy Now',
  L10nKeys.mktFree: 'Free',
  L10nKeys.commonRetry: 'Retry',
  L10nKeys.commonCancel: 'Cancel',
  L10nKeys.commonConfirm: 'Confirm',
  L10nKeys.commonSave: 'Save',
  L10nKeys.commonDelete: 'Delete',
  L10nKeys.commonEdit: 'Edit',
  L10nKeys.commonClose: 'Close',
  L10nKeys.commonLoading: 'Loading',
  L10nKeys.commonError: 'Something went wrong',
  L10nKeys.commonSuccess: 'Success',
  L10nKeys.commonNoData: 'No data available',
  L10nKeys.commonSearch: 'Search',
  L10nKeys.commonJustNow: 'Just now',
  L10nKeys.commonMinutesAgo: '{count} min ago',
  L10nKeys.commonHoursAgo: '{count}h ago',
  L10nKeys.commonDaysAgo: '{count}d ago',
  L10nKeys.adminDashboard: 'Super Admin Dashboard',
  L10nKeys.adminUsers: 'User Management',
  L10nKeys.adminSchools: 'School Management',
  L10nKeys.adminBilling: 'Billing Management',
  L10nKeys.adminSecurity: 'Security Center',
  L10nKeys.adminSettings: 'Global Settings',
  L10nKeys.adminTotalSchools: 'Total Schools',
  L10nKeys.adminRevenueToday: 'Revenue Today',
  L10nKeys.a11yLoadingContent: 'Loading content, please wait',
  L10nKeys.a11yErrorOccurred: 'An error occurred',
  L10nKeys.a11yNavigationMenu: 'Navigation menu',
};

// ═══════════════════════════════════════════════════════════════════════
// NIGERIAN LANGUAGE TRANSLATIONS (PARTIAL — FOR FUTURE COMPLETION)
// ═══════════════════════════════════════════════════════════════════════

const Map<String, String> _yorubaTranslations = {
  L10nKeys.authWelcomeBack: 'Kaabo',
  L10nKeys.authSignInToContinue: 'Wole lati tesiwaju si ExamForge AI',
  L10nKeys.authEmail: 'Imeeli',
  L10nKeys.authPassword: 'Oro igbaniwole',
  L10nKeys.authSignIn: 'Wole',
  L10nKeys.authSignUp: 'Forukosile',
  L10nKeys.commonLoading: 'Nko...',
  L10nKeys.commonError: 'Nnkan ti se',
  L10nKeys.commonRetry: 'Gbiyanju leekansi',
  L10nKeys.commonCancel: 'Nuko',
  L10nKeys.commonSave: 'Fipamo',
  L10nKeys.commonClose: 'Ti',
};

const Map<String, String> _igboTranslations = {
  L10nKeys.authWelcomeBack: 'Nnoo',
  L10nKeys.authSignInToContinue: 'Banye iji gaa nihu na ExamForge AI',
  L10nKeys.authEmail: 'Email',
  L10nKeys.authPassword: 'Okwuntughe',
  L10nKeys.authSignIn: 'Banye',
  L10nKeys.authSignUp: 'Debanye aha',
  L10nKeys.commonLoading: 'Na-edozi...',
  L10nKeys.commonError: 'Ihe adighi mma mere',
  L10nKeys.commonRetry: 'Nwalee ozo',
  L10nKeys.commonCancel: 'Kagbuo',
  L10nKeys.commonSave: 'Chekwaa',
  L10nKeys.commonClose: 'Mekie',
};

const Map<String, String> _hausaTranslations = {
  L10nKeys.authWelcomeBack: 'Barka da Zuwa',
  L10nKeys.authSignInToContinue: 'Shiga don ci gaba da ExamForge AI',
  L10nKeys.authEmail: 'Imel',
  L10nKeys.authPassword: 'Kalmar sirri',
  L10nKeys.authSignIn: 'Shiga',
  L10nKeys.authSignUp: 'Yi rajista',
  L10nKeys.commonLoading: 'Ana loda...',
  L10nKeys.commonError: 'Wani abu ya faru',
  L10nKeys.commonRetry: 'Sake gwadawa',
  L10nKeys.commonCancel: 'Soke',
  L10nKeys.commonSave: 'Ajiye',
  L10nKeys.commonClose: 'Rufe',
};

// ═══════════════════════════════════════════════════════════════════════
// APP LOCALIZATIONS CLASS
// ═══════════════════════════════════════════════════════════════════════

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _translations = {
    'en': _englishTranslations,
    'yo': _yorubaTranslations,
    'ig': _igboTranslations,
    'ha': _hausaTranslations,
  };

  Map<String, String> get _currentTranslations =>
      _translations[locale.languageCode] ?? _englishTranslations;

  /// Translate a key with optional interpolation parameters.
  String tr(String key, {Map<String, String>? params}) {
    var value = _currentTranslations[key] ?? _englishTranslations[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  /// Short alias for tr().
  String t(String key, {Map<String, String>? params}) => tr(key, params: params);

  /// Format currency (Nigerian Naira by default).
  String formatCurrency(num amount, {String currencyCode = 'NGN'}) {
    final format = NumberFormat.currency(
      locale: locale.languageCode,
      symbol: currencyCode == 'NGN' ? '\u20A6' : '$currencyCode ',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// Format a number according to locale.
  String formatNumber(num value) {
    return NumberFormat.decimalPattern(locale.languageCode).format(value);
  }

  /// Format a date according to locale.
  String formatDate(DateTime date, {String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern, locale.languageCode).format(date);
  }

  /// Format relative time.
  String formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return tr(L10nKeys.commonJustNow);
    if (diff.inMinutes < 60) return tr(L10nKeys.commonMinutesAgo, params: {'count': diff.inMinutes.toString()});
    if (diff.inHours < 24) return tr(L10nKeys.commonHoursAgo, params: {'count': diff.inHours.toString()});
    return tr(L10nKeys.commonDaysAgo, params: {'count': diff.inDays.toString()});
  }

  /// Generate a localization coverage report.
  static LocalizationCoverageReport generateCoverageReport() {
    final allKeys = _englishTranslations.keys.toSet();
    final reports = <String, LocaleCoverage>{};

    for (final entry in _translations.entries) {
      final translations = entry.value;
      final translatedKeys = translations.keys.toSet();
      final missingKeys = allKeys.difference(translatedKeys);
      final coveragePercent = translatedKeys.length / allKeys.length * 100;

      reports[entry.key] = LocaleCoverage(
        locale: entry.key,
        totalKeys: allKeys.length,
        translatedKeys: translatedKeys.length,
        missingKeys: missingKeys.length,
        coveragePercent: coveragePercent,
        missingKeyList: missingKeys.toList()..sort(),
      );
    }

    return LocalizationCoverageReport(
      totalKeys: allKeys.length,
      locales: reports,
      generatedAt: DateTime.now(),
    );
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static List<Locale> get supportedLocales => AppLocales.supported;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocales.supported.map((l) => l.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ═══════════════════════════════════════════════════════════════════════
// COVERAGE REPORT DATA
// ═══════════════════════════════════════════════════════════════════════

class LocalizationCoverageReport {
  final int totalKeys;
  final Map<String, LocaleCoverage> locales;
  final DateTime generatedAt;

  const LocalizationCoverageReport({
    required this.totalKeys,
    required this.locales,
    required this.generatedAt,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Localization Coverage Report ===');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln('Total Keys: $totalKeys');
    buffer.writeln();
    for (final entry in locales.entries) {
      final c = entry.value;
      buffer.writeln('[${entry.key}] ${c.coveragePercent.toStringAsFixed(1)}% '
          '(${c.translatedKeys}/${c.totalKeys})');
      if (c.missingKeys > 0) {
        buffer.writeln('  Missing: ${c.missingKeys} keys');
      }
    }
    return buffer.toString();
  }
}

class LocaleCoverage {
  final String locale;
  final int totalKeys;
  final int translatedKeys;
  final int missingKeys;
  final double coveragePercent;
  final List<String> missingKeyList;

  const LocaleCoverage({
    required this.locale,
    required this.totalKeys,
    required this.translatedKeys,
    required this.missingKeys,
    required this.coveragePercent,
    required this.missingKeyList,
  });
}
