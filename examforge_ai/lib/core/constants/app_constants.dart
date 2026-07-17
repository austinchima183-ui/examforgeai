/// Application-wide constants for ExamForge AI.
///
/// Centralizes all magic values, configuration defaults, and storage keys
/// so that every layer references the same source of truth.
class AppConstants {
  AppConstants._();

  // ─── App Metadata ──────────────────────────────────────────────────
  static const String appName = 'ExamForge AI';
  static const String appVersion = '1.0.0';

  // ─── Network & Retry ───────────────────────────────────────────────
  static const int maxRetryAttempts = 3;
  static const Duration cacheTimeout = Duration(hours: 1);

  // ─── Pagination ────────────────────────────────────────────────────
  static const int itemsPerPage = 20;

  // ─── Auth / Security ───────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;
  static const int sessionTimeoutMinutes = 30;

  // ─── Animation ─────────────────────────────────────────────────────
  static const Duration animationDuration = Duration(milliseconds: 300);

  // ─── Secure / Local Storage Keys ───────────────────────────────────
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String onboardingComplete = 'onboarding_complete';
  static const String rememberMe = 'remember_me';
  static const String biometricEnabled = 'biometric_enabled';
}
