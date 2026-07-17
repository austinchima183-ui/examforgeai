import 'package:equatable/equatable.dart';

import '../../../../routing/route_guards.dart';

/// Pure domain entity representing an authenticated user.
///
/// This class contains no serialization logic or framework dependencies.
/// It is the canonical representation of a user throughout the domain
/// and presentation layers.
///
/// [Equatable] provides value-based equality so that state comparisons
/// in Riverpod / BLoC work correctly without reference equality issues.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.schoolId,
    this.isActive = true,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  /// Unique identifier from Supabase Auth.
  final String id;

  /// User's email address (used as login credential).
  final String email;

  /// Full display name.
  final String fullName;

  /// Optional phone number.
  final String? phone;

  /// URL to the user's avatar image.
  final String? avatarUrl;

  /// Role string that maps to [UserRole].
  final String role;

  /// Optional school identifier for non-student roles.
  final String? schoolId;

  /// Whether the account is currently active.
  final bool isActive;

  /// Whether the user has verified their email address.
  final bool isEmailVerified;

  /// Timestamp when the account was created.
  final DateTime createdAt;

  /// Timestamp when the account was last updated.
  final DateTime updatedAt;

  /// Timestamp of the most recent login, or `null` if never logged in.
  final DateTime? lastLoginAt;

  /// Convenience getter that resolves [role] to a typed [UserRole].
  UserRole? get userRole => UserRole.fromString(role);

  /// Creates a copy of this entity with the given fields replaced.
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? schoolId,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        avatarUrl,
        role,
        schoolId,
        isActive,
        isEmailVerified,
        createdAt,
        updatedAt,
        lastLoginAt,
      ];
}
