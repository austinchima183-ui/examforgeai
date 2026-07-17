import '../../domain/entities/user_entity.dart';

/// Data-layer representation of a user, optimized for JSON serialization
/// and Supabase API compatibility.
///
/// Provides automated [fromJson] / [toJson] and conversion methods to and
/// from the domain [UserEntity] to keep the layers cleanly separated.
///
/// Designed to be migrated to Freezed + json_serializable once
/// `dart run build_runner build` is available.
class UserModel {
  const UserModel({
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

  // ─── JSON Serialization ────────────────────────────────────────────

  /// Creates a [UserModel] from a JSON map (e.g. Supabase response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'student',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isEmailVerified: json['is_email_verified'] as bool? ?? json['isEmailVerified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : json['lastLoginAt'] != null
              ? DateTime.parse(json['lastLoginAt'] as String)
              : null,
    );
  }

  /// Converts this model to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'school_id': schoolId,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  /// Creates a [UserModel] from a domain [UserEntity].
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
      role: entity.role,
      schoolId: entity.schoolId,
      isActive: entity.isActive,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastLoginAt: entity.lastLoginAt,
    );
  }

  /// Converts this model to a domain [UserEntity].
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      schoolId: schoolId,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  // ─── Supabase User Mapping ─────────────────────────────────────────

  /// Creates a [UserModel] from a Supabase [User] object's metadata.
  ///
  /// The Supabase user stores profile data in `userMetadata` and
  /// `rawUserMetaData`. This factory extracts the relevant fields
  /// and maps them to the model.
  factory UserModel.fromSupabaseUser(
    String id,
    String email, {
    Map<String, dynamic>? userMetadata,
    String? emailConfirmedAt,
    String? createdAt,
    String? lastSignInAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: userMetadata?['full_name'] as String? ?? '',
      phone: userMetadata?['phone'] as String?,
      avatarUrl: userMetadata?['avatar_url'] as String?,
      role: userMetadata?['role'] as String? ?? 'student',
      schoolId: userMetadata?['school_id'] as String?,
      isActive: true,
      isEmailVerified: emailConfirmedAt != null,
      createdAt: createdAt != null
          ? DateTime.parse(createdAt)
          : DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: lastSignInAt != null
          ? DateTime.parse(lastSignInAt)
          : null,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  /// Creates a copy of this model with the given fields replaced.
  UserModel copyWith({
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
    return UserModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          phone == other.phone &&
          avatarUrl == other.avatarUrl &&
          role == other.role &&
          schoolId == other.schoolId &&
          isActive == other.isActive &&
          isEmailVerified == other.isEmailVerified &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastLoginAt == other.lastLoginAt;

  @override
  int get hashCode => Object.hash(
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
      );

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
}
