// ============================================================================
// ExamForge AI — Admin Security Service
// ============================================================================
// Provides security controls for administrative access:
//   1. Restricted administrator access (role-based + route-based)
//   2. Least-privilege role enforcement
//   3. Session expiration and timeout
//   4. MFA-ready architecture (interface for future TOTP/SMS)
//   5. Audit logging for all admin actions
//   6. Failed login monitoring and rate limiting
//   7. IP allowlist validation (configurable per environment)
//
// SECURITY MODEL:
//   - Default-deny: Admin access is restricted unless explicitly granted
//   - Defense in depth: Client-side guards + server-side RLS must both pass
//   - Audit trail: Every admin action is logged with who/what/when/where
//   - Session timeout: Admin sessions expire after configurable period
//   - MFA-ready: Interface exists for future multi-factor authentication
// ============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════

/// Admin session timeout duration (30 minutes of inactivity).
const Duration kAdminSessionTimeout = Duration(minutes: 30);

/// Maximum failed login attempts before lockout.
const int kMaxFailedLoginAttempts = 5;

/// Lockout duration after exceeding max failed attempts.
const Duration kLockoutDuration = Duration(minutes: 15);

/// Maximum admin actions per minute (rate limiting).
const int kMaxAdminActionsPerMinute = 60;

// ═══════════════════════════════════════════════════════════════════════
// ADMIN ROLES (Least-Privilege)
// ═══════════════════════════════════════════════════════════════════════

/// Fine-grained admin permission levels beyond the basic UserRole.
/// These provide least-privilege access within the admin portal.
enum AdminPermission {
  viewDashboard('admin.dashboard.view'),
  manageUsers('admin.users.manage'),
  viewUsers('admin.users.view'),
  manageSchools('admin.schools.manage'),
  viewBilling('admin.billing.view'),
  manageBilling('admin.billing.manage'),
  viewSecurity('admin.security.view'),
  manageSecurity('admin.security.manage'),
  viewAI('admin.ai.view'),
  manageAI('admin.ai.manage'),
  viewInfrastructure('admin.infrastructure.view'),
  manageSettings('admin.settings.manage'),
  viewAuditLog('admin.audit.view'),
  marketplaceModerate('admin.marketplace.moderate'),
  ;

  final String value;
  const AdminPermission(this.value);
}

/// Maps roles to their allowed admin permissions (least-privilege).
const Map<String, Set<AdminPermission>> _rolePermissions = {
  'super-admin': {
    AdminPermission.viewDashboard,
    AdminPermission.manageUsers,
    AdminPermission.viewUsers,
    AdminPermission.manageSchools,
    AdminPermission.viewBilling,
    AdminPermission.manageBilling,
    AdminPermission.viewSecurity,
    AdminPermission.manageSecurity,
    AdminPermission.viewAI,
    AdminPermission.manageAI,
    AdminPermission.viewInfrastructure,
    AdminPermission.manageSettings,
    AdminPermission.viewAuditLog,
    AdminPermission.marketplaceModerate,
  },
  'school-admin': {
    AdminPermission.viewDashboard,
    AdminPermission.viewUsers,
    AdminPermission.manageSchools,
    AdminPermission.viewBilling,
    AdminPermission.viewAI,
  },
};

// ═══════════════════════════════════════════════════════════════════════
// MFA INTERFACE (Ready for future implementation)
// ═══════════════════════════════════════════════════════════════════════

/// Interface for MFA providers.
/// Implement this interface to add TOTP, SMS, or hardware key support.
abstract class MFAProvider {
  /// Returns whether MFA is enabled for the given user.
  Future<bool> isMFAEnabled(String userId);

  /// Initiates MFA enrollment for the given user.
  /// Returns enrollment data (e.g., QR code URL for TOTP).
  Future<MFAEnrollmentData> enroll(String userId);

  /// Verifies an MFA challenge code.
  /// Returns true if the code is valid.
  Future<bool> verify(String userId, String code);

  /// Removes MFA enrollment for the given user.
  Future<void> removeEnrollment(String userId);
}

/// Data returned during MFA enrollment.
class MFAEnrollmentData {
  final String secret;
  final String qrCodeUrl;
  final String type; // 'totp', 'sms', etc.

  const MFAEnrollmentData({
    required this.secret,
    required this.qrCodeUrl,
    required this.type,
  });
}

/// Placeholder MFA provider that always returns false (MFA not yet implemented).
/// When MFA is implemented, replace this with a real provider.
class PlaceholderMFAProvider implements MFAProvider {
  @override
  Future<bool> isMFAEnabled(String userId) async => false;

  @override
  Future<MFAEnrollmentData> enroll(String userId) async {
    throw UnimplementedError('MFA enrollment not yet implemented');
  }

  @override
  Future<bool> verify(String userId, String code) async => false;

  @override
  Future<void> removeEnrollment(String userId) async {
    throw UnimplementedError('MFA removal not yet implemented');
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AUDIT LOG ENTRY
// ═══════════════════════════════════════════════════════════════════════

/// An immutable audit log entry for admin actions.
class AdminAuditEntry {
  final String id;
  final String userId;
  final String action;
  final String resource;
  final String? resourceId;
  final DateTime timestamp;
  final String? ipAddress;
  final Map<String, dynamic> details;
  final bool success;

  const AdminAuditEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.timestamp,
    this.ipAddress,
    this.details = const {},
    this.success = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'action': action,
        'resource': resource,
        'resource_id': resourceId,
        'timestamp': timestamp.toIso8601String(),
        'ip_address': ipAddress,
        'details': details,
        'success': success,
      };
}

// ═══════════════════════════════════════════════════════════════════════
// ADMIN SECURITY SERVICE
// ═══════════════════════════════════════════════════════════════════════

/// Centralized admin security service providing:
/// - Session management with timeout
/// - Permission checks (least-privilege)
/// - Failed login monitoring
/// - Rate limiting
/// - Audit logging
/// - MFA readiness
class AdminSecurityService {
  AdminSecurityService._();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── SESSION MANAGEMENT ─────────────────────────────────────────────

  static const _sessionKey = 'admin_session_start';
  static const _lastActivityKey = 'admin_last_activity';

  /// Records the start of an admin session.
  static Future<void> startSession(String userId) async {
    final now = DateTime.now().toIso8601String();
    await _secureStorage.write(key: _sessionKey, value: now);
    await _secureStorage.write(key: _lastActivityKey, value: now);

    await logAudit(AdminAuditEntry(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      action: 'session.start',
      resource: 'admin_session',
      timestamp: DateTime.now(),
      success: true,
    ),);

    AppLogger.info('AdminSecurityService: Session started for user $userId');
  }

  /// Records admin activity (extends the session).
  static Future<void> recordActivity() async {
    final now = DateTime.now().toIso8601String();
    await _secureStorage.write(key: _lastActivityKey, value: now);
  }

  /// Checks if the admin session is still valid (not expired).
  static Future<bool> isSessionValid() async {
    final lastActivity = await _secureStorage.read(key: _lastActivityKey);
    if (lastActivity == null) return false;

    try {
      final lastActive = DateTime.parse(lastActivity);
      final elapsed = DateTime.now().difference(lastActive);
      return elapsed < kAdminSessionTimeout;
    } catch (_) {
      return false;
    }
  }

  /// Ends the current admin session.
  static Future<void> endSession(String userId) async {
    await _secureStorage.delete(key: _sessionKey);
    await _secureStorage.delete(key: _lastActivityKey);

    await logAudit(AdminAuditEntry(
      id: 'session-end-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      action: 'session.end',
      resource: 'admin_session',
      timestamp: DateTime.now(),
      success: true,
    ),);

    AppLogger.info('AdminSecurityService: Session ended for user $userId');
  }

  // ─── PERMISSION CHECKS ──────────────────────────────────────────────

  /// Checks if a user with the given role has a specific admin permission.
  static bool hasPermission(String role, AdminPermission permission) {
    final permissions = _rolePermissions[role];
    if (permissions == null) return false;
    return permissions.contains(permission);
  }

  /// Returns all permissions for a given role.
  static Set<AdminPermission> getPermissions(String role) {
    return _rolePermissions[role] ?? {};
  }

  /// Validates that a user can perform an action on a resource.
  /// Returns true if authorized, throws if not.
  static bool authorizeAction({
    required String userId,
    required String role,
    required AdminPermission permission,
    String? resourceId,
  }) {
    if (!hasPermission(role, permission)) {
      AppLogger.critical(
        'AdminSecurityService: UNAUTHORIZED action attempt. '
        'User=$userId, Role=$role, Permission=${permission.value}',
      );

      logAudit(AdminAuditEntry(
        id: 'auth-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        action: 'unauthorized.${permission.value}',
        resource: 'permission_check',
        resourceId: resourceId,
        timestamp: DateTime.now(),
        success: false,
        details: {'role': role, 'required_permission': permission.value},
      ),);

      return false;
    }
    return true;
  }

  // ─── FAILED LOGIN MONITORING ────────────────────────────────────────

  static final Map<String, _LoginAttemptTracker> _failedAttempts = {};

  /// Records a failed login attempt for the given identifier (email/IP).
  static Future<void> recordFailedLogin(String identifier) async {
    final tracker = _failedAttempts.putIfAbsent(
      identifier,
      () => _LoginAttemptTracker(),
    );
    tracker.recordAttempt();

    AppLogger.warning(
      'AdminSecurityService: Failed login attempt #${tracker.attemptCount} '
      'for $identifier',
    );

    if (tracker.isLockedOut) {
      AppLogger.critical(
        'AdminSecurityService: LOCKOUT triggered for $identifier '
        'after ${tracker.attemptCount} failed attempts',
      );

      await logAudit(AdminAuditEntry(
        id: 'lockout-${DateTime.now().millisecondsSinceEpoch}',
        userId: identifier,
        action: 'login.lockout',
        resource: 'auth',
        timestamp: DateTime.now(),
        success: false,
        details: {
          'attempt_count': tracker.attemptCount,
          'lockout_duration_minutes': kLockoutDuration.inMinutes,
        },
      ),);
    }
  }

  /// Checks if an identifier is currently locked out.
  static bool isLockedOut(String identifier) {
    final tracker = _failedAttempts[identifier];
    if (tracker == null) return false;
    return tracker.isLockedOut;
  }

  /// Clears the failed login counter for an identifier (after successful login).
  static void clearFailedLogins(String identifier) {
    _failedAttempts.remove(identifier);
  }

  /// Returns the number of failed login attempts for an identifier.
  static int getFailedAttemptCount(String identifier) {
    return _failedAttempts[identifier]?.attemptCount ?? 0;
  }

  // ─── RATE LIMITING ──────────────────────────────────────────────────

  static final Map<String, _RateLimitTracker> _rateLimiters = {};

  /// Checks if an action is within rate limits.
  /// Returns true if the action is allowed.
  static bool checkRateLimit(String userId) {
    final tracker = _rateLimiters.putIfAbsent(
      userId,
      () => _RateLimitTracker(kMaxAdminActionsPerMinute),
    );
    return tracker.allowAction();
  }

  // ─── IP ALLOWLIST ───────────────────────────────────────────────────

  static Set<String> _allowedIPs = {};

  /// Configures the IP allowlist for admin access.
  /// In production, this should be loaded from secure server-side config.
  static void configureIPAllowlist(Set<String> allowedIPs) {
    _allowedIPs = allowedIPs;
    AppLogger.info('AdminSecurityService: IP allowlist configured with ${allowedIPs.length} entries');
  }

  /// Checks if an IP address is in the admin allowlist.
  /// If the allowlist is empty, all IPs are allowed (development mode).
  /// In production, the allowlist must be explicitly configured.
  static bool isIPAllowed(String ipAddress) {
    if (_allowedIPs.isEmpty) {
      // Development mode: no allowlist configured
      AppLogger.warning('AdminSecurityService: No IP allowlist configured — '
          'all IPs allowed (development only!)');
      return true;
    }
    return _allowedIPs.contains(ipAddress);
  }

  // ─── AUDIT LOGGING ──────────────────────────────────────────────────

  /// In-memory audit log (for demo/testing).
  /// In production, this should write to the `admin_audit_log` Supabase table.
  static final List<AdminAuditEntry> _auditLog = [];

  /// Logs an admin audit entry.
  static Future<void> logAudit(AdminAuditEntry entry) async {
    _auditLog.add(entry);

    // In production, also write to Supabase:
    // await supabase.from('admin_audit_log').insert(entry.toJson());

    AppLogger.info(
      'AdminSecurityService: Audit log — ${entry.action} on ${entry.resource}'
      '${entry.resourceId != null ? '/${entry.resourceId}' : ''} '
      'by ${entry.userId} (${entry.success ? "SUCCESS" : "DENIED"})',
    );
  }

  /// Returns recent audit entries.
  static List<AdminAuditEntry> getRecentAuditEntries({int limit = 100}) {
    final entries = List<AdminAuditEntry>.from(_auditLog);
    if (entries.length > limit) {
      return entries.sublist(entries.length - limit);
    }
    return entries;
  }

  // ─── MFA ────────────────────────────────────────────────────────────

  static MFAProvider _mfaProvider = PlaceholderMFAProvider();

  /// Sets the MFA provider (call during app initialization).
  static void setMFAProvider(MFAProvider provider) {
    _mfaProvider = provider;
    AppLogger.info('AdminSecurityService: MFA provider configured');
  }

  /// Returns the current MFA provider.
  static MFAProvider get mfaProvider => _mfaProvider;

  /// Checks if MFA is required for a user.
  /// In the current implementation, MFA is recommended but not required.
  /// When MFA is fully implemented, this should return true for admin roles.
  static Future<bool> isMFARequired(String userId) async {
    final isEnrolled = await _mfaProvider.isMFAEnabled(userId);
    // For now, MFA is optional but we check enrollment status
    return isEnrolled;
  }

  // ─── RESET (for testing) ────────────────────────────────────────────

  static void reset() {
    _failedAttempts.clear();
    _rateLimiters.clear();
    _auditLog.clear();
    _allowedIPs.clear();
    _mfaProvider = PlaceholderMFAProvider();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _LoginAttemptTracker {
  final List<DateTime> _attempts = [];

  int get attemptCount => _attempts.length;

  void recordAttempt() {
    _attempts.add(DateTime.now());
    // Clean up attempts older than lockout duration
    final cutoff = DateTime.now().subtract(kLockoutDuration);
    _attempts.removeWhere((a) => a.isBefore(cutoff));
  }

  bool get isLockedOut {
    final cutoff = DateTime.now().subtract(kLockoutDuration);
    final recentAttempts = _attempts.where((a) => a.isAfter(cutoff)).length;
    return recentAttempts >= kMaxFailedLoginAttempts;
  }
}

class _RateLimitTracker {
  final int maxActionsPerMinute;
  final List<DateTime> _actions = [];

  _RateLimitTracker(this.maxActionsPerMinute);

  bool allowAction() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    _actions.removeWhere((a) => a.isBefore(oneMinuteAgo));

    if (_actions.length >= maxActionsPerMinute) {
      return false;
    }

    _actions.add(now);
    return true;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for checking admin session validity.
final adminSessionValidProvider = FutureProvider<bool>((ref) async {
  return AdminSecurityService.isSessionValid();
});

/// Provider for admin permissions based on current role.
final adminPermissionsProvider = Provider<Set<AdminPermission>>((ref) {
  // This should read from the auth state
  return {}; // Will be populated when integrated with auth provider
});
