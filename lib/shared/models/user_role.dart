/// Canonical import path for the [UserRole] enum and its utilities.
///
/// Instead of importing from `routing/route_guards.dart` throughout the
/// app, import this file to keep the dependency graph clean and avoid
/// leaking routing concerns into domain / presentation layers.
///
/// ```dart
/// import '../../shared/models/user_role.dart';
///
/// final role = UserRole.fromString('teacher');
/// print(role?.label); // 'Teacher'
/// ```
///
/// This file re-exports the [UserRole] enum and the
/// [currentRoleProvider] from the routing layer, and adds convenience
/// extensions for UI and business logic.
library;

import '../../core/utils/logger.dart';
import '../../routing/route_guards.dart';

// ─── Re-export from route_guards.dart ──────────────────────────────────
export '../../routing/route_guards.dart' show UserRole, currentRoleProvider;

// ═══════════════════════════════════════════════════════════════════════
// USER ROLE UTILITIES
// ═══════════════════════════════════════════════════════════════════════

/// Extension methods on [UserRole] for UI display, icons, and
/// permission checks beyond what the base enum provides.
extension UserRoleX on UserRole {
  /// A short, machine-safe key suitable for API payloads, storage,
  /// and topic subscriptions (e.g. `role_teacher`).
  String get storageKey => value;

  /// Whether this role has administrative privileges (school-admin or
  /// super-admin).
  bool get isAdmin =>
      this == UserRole.schoolAdmin || this == UserRole.superAdmin;

  /// Whether this role is a teaching role (teacher or school-admin).
  bool get isTeacher =>
      this == UserRole.teacher || this == UserRole.schoolAdmin;

  /// Whether this role can manage other users within a school.
  bool get canManageUsers =>
      this == UserRole.schoolAdmin || this == UserRole.superAdmin;

  /// Whether this role can create and manage exams.
  bool get canManageExams =>
      this == UserRole.teacher ||
      this == UserRole.schoolAdmin ||
      this == UserRole.superAdmin;

  /// Whether this role can access analytics dashboards.
  bool get canViewAnalytics =>
      this == UserRole.schoolAdmin || this == UserRole.superAdmin;

  /// Whether this role can take exams (as a student).
  bool get canTakeExams => this == UserRole.student;

  /// A human-readable description of this role's primary purpose.
  String get description => switch (this) {
        UserRole.teacher =>
          'Create and manage exams, view student performance',
        UserRole.student =>
          'Take exams, view results and progress',
        UserRole.schoolAdmin =>
          'Manage school, teachers, and students',
        UserRole.superAdmin =>
          'Full system access across all schools',
      };
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════

/// Parses a raw [value] string into a [UserRole], returning
/// [defaultRole] if the value is `null` or unrecognized.
///
/// This is safer than [UserRole.fromString] which returns `null`
/// for unknown values. Use this when a fallback is preferred.
UserRole parseUserRoleOrDefault(String? value, {UserRole defaultRole = UserRole.student}) {
  final role = UserRole.fromString(value);
  if (role != null) return role;

  AppLogger.warning(
    'Unknown user role "$value" — falling back to ${defaultRole.label}',
  );
  return defaultRole;
}

/// Returns all [UserRole] values sorted by [UserRole.privilegeLevel]
/// in ascending order (least privileged first).
List<UserRole> get rolesByPrivilege {
  final roles = UserRole.values.toList()
    ..sort((a, b) => a.privilegeLevel.compareTo(b.privilegeLevel));
  return roles;
}

/// Returns the set of roles that have a privilege level equal to or
/// greater than [role].
Set<UserRole> rolesAtOrAbove(UserRole role) {
  return UserRole.values
      .where((r) => r.privilegeLevel >= role.privilegeLevel)
      .toSet();
}
