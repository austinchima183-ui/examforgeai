/// API-related constants: base headers, authenticated headers, and
/// every endpoint path used by the ExamForge AI client.
class ApiConstants {
  ApiConstants._();

  // ─── Base URL (override via .env in production) ────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.examforge.ai/v1',
  );

  // ─── Header Factories ──────────────────────────────────────────────

  /// Standard JSON headers for unauthenticated requests.
  static Map<String, String> baseHeaders() => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  /// Headers that include a bearer [token] for authenticated requests.
  static Map<String, String> authHeaders(String token) => {
        ...baseHeaders(),
        'Authorization': 'Bearer $token',
      };

  // ─── Auth Endpoints ────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';

  // ─── User Endpoints ────────────────────────────────────────────────
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // ─── School Endpoints ──────────────────────────────────────────────
  static const String school = '/schools';

  // ─── Class Endpoints ───────────────────────────────────────────────
  static const String classEndpoint = '/classes';

  // ─── Subject Endpoints ─────────────────────────────────────────────
  static const String subject = '/subjects';

  // ─── Notification Endpoints ────────────────────────────────────────
  static const String notification = '/notifications';
}
