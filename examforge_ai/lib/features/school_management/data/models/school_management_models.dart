import '../../domain/entities/school_management_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT DATA MODELS
// ═══════════════════════════════════════════════════════════════════════
// Plain class models (NOT Equatable) for the School Management data layer.
// Pattern: fromJson (snake_case & camelCase), toJson (snake_case for
// Supabase), fromEntity, toEntity, copyWith, manual == and hashCode.
// ═══════════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────────
// Helper: parse DateTime accepting both snake_case and camelCase keys
// ───────────────────────────────────────────────────────────────────────

DateTime _parseDateTime(dynamic value) {
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return DateTime.now();
}

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return null;
}

// ═══════════════════════════════════════════════════════════════════════
// 1. SchoolModel
// ═══════════════════════════════════════════════════════════════════════

class SchoolModel {
  const SchoolModel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.city,
    this.state,
    this.country = 'Nigeria',
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.motto,
    this.principalName,
    this.primaryColor = '#4F46E5',
    this.secondaryColor = '#7C3AED',
    this.customDomain,
    this.schoolType = 'mixed',
    this.schoolLevel = 'secondary',
    this.establishedDate,
    this.registrationNumber,
    this.subscriptionStatus = 'free',
    this.subscriptionExpiresAt,
    this.maxStudents = 100,
    this.maxTeachers = 10,
    this.isActive = true,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? motto;
  final String? principalName;
  final String primaryColor;
  final String secondaryColor;
  final String? customDomain;
  final String schoolType;
  final String schoolLevel;
  final DateTime? establishedDate;
  final String? registrationNumber;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final int maxStudents;
  final int maxTeachers;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'Nigeria',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      motto: json['motto'] as String?,
      principalName: json['principal_name'] as String? ?? json['principalName'] as String?,
      primaryColor: json['primary_color'] as String? ?? json['primaryColor'] as String? ?? '#4F46E5',
      secondaryColor: json['secondary_color'] as String? ?? json['secondaryColor'] as String? ?? '#7C3AED',
      customDomain: json['custom_domain'] as String? ?? json['customDomain'] as String?,
      schoolType: json['school_type'] as String? ?? json['schoolType'] as String? ?? 'mixed',
      schoolLevel: json['school_level'] as String? ?? json['schoolLevel'] as String? ?? 'secondary',
      establishedDate: _parseDateTimeNullable(json['established_date'] ?? json['establishedDate']),
      registrationNumber: json['registration_number'] as String? ?? json['registrationNumber'] as String?,
      subscriptionStatus: json['subscription_status'] as String? ?? json['subscriptionStatus'] as String? ?? 'free',
      subscriptionExpiresAt: _parseDateTimeNullable(json['subscription_expires_at'] ?? json['subscriptionExpiresAt']),
      maxStudents: json['max_students'] as int? ?? json['maxStudents'] as int? ?? 100,
      maxTeachers: json['max_teachers'] as int? ?? json['maxTeachers'] as int? ?? 10,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'motto': motto,
      'principal_name': principalName,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'custom_domain': customDomain,
      'school_type': schoolType,
      'school_level': schoolLevel,
      'established_date': establishedDate?.toIso8601String(),
      'registration_number': registrationNumber,
      'subscription_status': subscriptionStatus,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'max_students': maxStudents,
      'max_teachers': maxTeachers,
      'is_active': isActive,
      'settings': settings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SchoolModel.fromEntity(SchoolEntity entity) {
    return SchoolModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      phone: entity.phone,
      email: entity.email,
      website: entity.website,
      logoUrl: entity.logoUrl,
      motto: entity.motto,
      principalName: entity.principalName,
      primaryColor: entity.primaryColor,
      secondaryColor: entity.secondaryColor,
      customDomain: entity.customDomain,
      schoolType: entity.schoolType,
      schoolLevel: entity.schoolLevel,
      establishedDate: entity.establishedDate,
      registrationNumber: entity.registrationNumber,
      subscriptionStatus: entity.subscriptionStatus,
      subscriptionExpiresAt: entity.subscriptionExpiresAt,
      maxStudents: entity.maxStudents,
      maxTeachers: entity.maxTeachers,
      isActive: entity.isActive,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolEntity toEntity() {
    return SchoolEntity(
      id: id,
      name: name,
      code: code,
      address: address,
      city: city,
      state: state,
      country: country,
      phone: phone,
      email: email,
      website: website,
      logoUrl: logoUrl,
      motto: motto,
      principalName: principalName,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      customDomain: customDomain,
      schoolType: schoolType,
      schoolLevel: schoolLevel,
      establishedDate: establishedDate,
      registrationNumber: registrationNumber,
      subscriptionStatus: subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt,
      maxStudents: maxStudents,
      maxTeachers: maxTeachers,
      isActive: isActive,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SchoolModel copyWith({
    String? id, String? name, String? code, String? address,
    String? city, String? state, String? country, String? phone,
    String? email, String? website, String? logoUrl, String? motto,
    String? principalName, String? primaryColor, String? secondaryColor,
    String? customDomain, String? schoolType, String? schoolLevel,
    DateTime? establishedDate, String? registrationNumber,
    String? subscriptionStatus, DateTime? subscriptionExpiresAt,
    int? maxStudents, int? maxTeachers, bool? isActive,
    Map<String, dynamic>? settings, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id ?? this.id, name: name ?? this.name, code: code ?? this.code,
      address: address ?? this.address, city: city ?? this.city,
      state: state ?? this.state, country: country ?? this.country,
      phone: phone ?? this.phone, email: email ?? this.email,
      website: website ?? this.website, logoUrl: logoUrl ?? this.logoUrl,
      motto: motto ?? this.motto, principalName: principalName ?? this.principalName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      customDomain: customDomain ?? this.customDomain,
      schoolType: schoolType ?? this.schoolType,
      schoolLevel: schoolLevel ?? this.schoolLevel,
      establishedDate: establishedDate ?? this.establishedDate,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      isActive: isActive ?? this.isActive, settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, name, code);

  @override
  String toString() => 'SchoolModel(id: $id, name: $name, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════
// 2. SchoolBranchModel
// ═══════════════════════════════════════════════════════════════════════

class SchoolBranchModel {
  const SchoolBranchModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    this.address,
    this.city,
    this.state,
    this.country = 'Nigeria',
    this.phone,
    this.email,
    this.headName,
    this.isActive = true,
    this.isMainCampus = false,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String code;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final String? phone;
  final String? email;
  final String? headName;
  final bool isActive;
  final bool isMainCampus;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SchoolBranchModel.fromJson(Map<String, dynamic> json) {
    return SchoolBranchModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'Nigeria',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      headName: json['head_name'] as String? ?? json['headName'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isMainCampus: json['is_main_campus'] as bool? ?? json['isMainCampus'] as bool? ?? false,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'email': email,
      'head_name': headName,
      'is_active': isActive,
      'is_main_campus': isMainCampus,
      'settings': settings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SchoolBranchModel.fromEntity(SchoolBranchEntity entity) {
    return SchoolBranchModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      code: entity.code,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      phone: entity.phone,
      email: entity.email,
      headName: entity.headName,
      isActive: entity.isActive,
      isMainCampus: entity.isMainCampus,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolBranchEntity toEntity() {
    return SchoolBranchEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      code: code,
      address: address,
      city: city,
      state: state,
      country: country,
      phone: phone,
      email: email,
      headName: headName,
      isActive: isActive,
      isMainCampus: isMainCampus,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SchoolBranchModel copyWith({
    String? id, String? schoolId, String? name, String? code,
    String? address, String? city, String? state, String? country,
    String? phone, String? email, String? headName, bool? isActive,
    bool? isMainCampus, Map<String, dynamic>? settings,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SchoolBranchModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name, code: code ?? this.code,
      address: address ?? this.address, city: city ?? this.city,
      state: state ?? this.state, country: country ?? this.country,
      phone: phone ?? this.phone, email: email ?? this.email,
      headName: headName ?? this.headName, isActive: isActive ?? this.isActive,
      isMainCampus: isMainCampus ?? this.isMainCampus,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolBranchModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, schoolId, name, code);

  @override
  String toString() => 'SchoolBranchModel(id: $id, name: $name, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════
// 3. DepartmentModel
// ═══════════════════════════════════════════════════════════════════════

class DepartmentModel {
  const DepartmentModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    this.headTeacherId,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String code;
  final String? headTeacherId;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String,
      code: json['code'] as String,
      headTeacherId: json['head_teacher_id'] as String? ?? json['headTeacherId'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'head_teacher_id': headTeacherId,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory DepartmentModel.fromEntity(DepartmentEntity entity) {
    return DepartmentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      code: entity.code,
      headTeacherId: entity.headTeacherId,
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DepartmentEntity toEntity() {
    return DepartmentEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      code: code,
      headTeacherId: headTeacherId,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  DepartmentModel copyWith({
    String? id, String? schoolId, String? name, String? code,
    String? headTeacherId, String? description, bool? isActive,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name, code: code ?? this.code,
      headTeacherId: headTeacherId ?? this.headTeacherId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, schoolId, name, code);

  @override
  String toString() => 'DepartmentModel(id: $id, name: $name, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════
// 4. StudentProfileModel
// ═══════════════════════════════════════════════════════════════════════

class StudentProfileModel {
  const StudentProfileModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.admissionNumber,
    this.studentIdCardNumber,
    this.passportPhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.genotype,
    this.medicalConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.homeAddress,
    this.stateOfOrigin,
    this.localGovernment,
    this.nationality = 'Nigerian',
    this.religion,
    this.admissionDate,
    this.currentClassId,
    this.isActive = true,
    this.isGraduated = false,
    this.graduationDate,
    this.isAlumni = false,
    this.promotedToClassId,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    // Denormalized user fields from joined users table
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String schoolId;
  final String admissionNumber;
  final String? studentIdCardNumber;
  final String? passportPhotoUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? genotype;
  final String? medicalConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? homeAddress;
  final String? stateOfOrigin;
  final String? localGovernment;
  final String nationality;
  final String? religion;
  final DateTime? admissionDate;
  final String? currentClassId;
  final bool isActive;
  final bool isGraduated;
  final DateTime? graduationDate;
  final bool isAlumni;
  final String? promotedToClassId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Denormalized user fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      admissionNumber: json['admission_number'] as String? ?? json['admissionNumber'] as String? ?? '',
      studentIdCardNumber: json['student_id_card_number'] as String? ?? json['studentIdCardNumber'] as String?,
      passportPhotoUrl: json['passport_photo_url'] as String? ?? json['passportPhotoUrl'] as String?,
      dateOfBirth: _parseDateTimeNullable(json['date_of_birth'] ?? json['dateOfBirth']),
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String? ?? json['bloodGroup'] as String?,
      genotype: json['genotype'] as String?,
      medicalConditions: json['medical_conditions'] as String? ?? json['medicalConditions'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String? ?? json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? json['emergencyContactPhone'] as String?,
      emergencyContactRelationship: json['emergency_contact_relationship'] as String? ?? json['emergencyContactRelationship'] as String?,
      homeAddress: json['home_address'] as String? ?? json['homeAddress'] as String?,
      stateOfOrigin: json['state_of_origin'] as String? ?? json['stateOfOrigin'] as String?,
      localGovernment: json['local_government'] as String? ?? json['localGovernment'] as String?,
      nationality: json['nationality'] as String? ?? 'Nigerian',
      religion: json['religion'] as String?,
      admissionDate: _parseDateTimeNullable(json['admission_date'] ?? json['admissionDate']),
      currentClassId: json['current_class_id'] as String? ?? json['currentClassId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isGraduated: json['is_graduated'] as bool? ?? json['isGraduated'] as bool? ?? false,
      graduationDate: _parseDateTimeNullable(json['graduation_date'] ?? json['graduationDate']),
      isAlumni: json['is_alumni'] as bool? ?? json['isAlumni'] as bool? ?? false,
      promotedToClassId: json['promoted_to_class_id'] as String? ?? json['promotedToClassId'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
      // Denormalized user fields (may come from join)
      fullName: json['full_name'] as String? ?? json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'admission_number': admissionNumber,
      'student_id_card_number': studentIdCardNumber,
      'passport_photo_url': passportPhotoUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'blood_group': bloodGroup,
      'genotype': genotype,
      'medical_conditions': medicalConditions,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'home_address': homeAddress,
      'state_of_origin': stateOfOrigin,
      'local_government': localGovernment,
      'nationality': nationality,
      'religion': religion,
      'admission_date': admissionDate?.toIso8601String(),
      'current_class_id': currentClassId,
      'is_active': isActive,
      'is_graduated': isGraduated,
      'graduation_date': graduationDate?.toIso8601String(),
      'is_alumni': isAlumni,
      'promoted_to_class_id': promotedToClassId,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory StudentProfileModel.fromEntity(StudentProfileEntity entity) {
    return StudentProfileModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      admissionNumber: entity.admissionNumber,
      studentIdCardNumber: entity.studentIdCardNumber,
      passportPhotoUrl: entity.passportPhotoUrl,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      bloodGroup: entity.bloodGroup,
      genotype: entity.genotype,
      medicalConditions: entity.medicalConditions,
      emergencyContactName: entity.emergencyContactName,
      emergencyContactPhone: entity.emergencyContactPhone,
      emergencyContactRelationship: entity.emergencyContactRelationship,
      homeAddress: entity.homeAddress,
      stateOfOrigin: entity.stateOfOrigin,
      localGovernment: entity.localGovernment,
      nationality: entity.nationality,
      religion: entity.religion,
      admissionDate: entity.admissionDate,
      currentClassId: entity.currentClassId,
      isActive: entity.isActive,
      isGraduated: entity.isGraduated,
      graduationDate: entity.graduationDate,
      isAlumni: entity.isAlumni,
      promotedToClassId: entity.promotedToClassId,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
    );
  }

  StudentProfileEntity toEntity() {
    return StudentProfileEntity(
      id: id,
      userId: userId,
      schoolId: schoolId,
      admissionNumber: admissionNumber,
      studentIdCardNumber: studentIdCardNumber,
      passportPhotoUrl: passportPhotoUrl,
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodGroup: bloodGroup,
      genotype: genotype,
      medicalConditions: medicalConditions,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship,
      homeAddress: homeAddress,
      stateOfOrigin: stateOfOrigin,
      localGovernment: localGovernment,
      nationality: nationality,
      religion: religion,
      admissionDate: admissionDate,
      currentClassId: currentClassId,
      isActive: isActive,
      isGraduated: isGraduated,
      graduationDate: graduationDate,
      isAlumni: isAlumni,
      promotedToClassId: promotedToClassId,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  StudentProfileModel copyWith({
    String? id, String? userId, String? schoolId, String? admissionNumber,
    String? studentIdCardNumber, String? passportPhotoUrl,
    DateTime? dateOfBirth, String? gender, String? bloodGroup,
    String? genotype, String? medicalConditions,
    String? emergencyContactName, String? emergencyContactPhone,
    String? emergencyContactRelationship, String? homeAddress,
    String? stateOfOrigin, String? localGovernment, String? nationality,
    String? religion, DateTime? admissionDate, String? currentClassId,
    bool? isActive, bool? isGraduated, DateTime? graduationDate,
    bool? isAlumni, String? promotedToClassId,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
    String? fullName, String? email, String? phone, String? avatarUrl,
  }) {
    return StudentProfileModel(
      id: id ?? this.id, userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      studentIdCardNumber: studentIdCardNumber ?? this.studentIdCardNumber,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender, bloodGroup: bloodGroup ?? this.bloodGroup,
      genotype: genotype ?? this.genotype,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      homeAddress: homeAddress ?? this.homeAddress,
      stateOfOrigin: stateOfOrigin ?? this.stateOfOrigin,
      localGovernment: localGovernment ?? this.localGovernment,
      nationality: nationality ?? this.nationality,
      religion: religion ?? this.religion,
      admissionDate: admissionDate ?? this.admissionDate,
      currentClassId: currentClassId ?? this.currentClassId,
      isActive: isActive ?? this.isActive,
      isGraduated: isGraduated ?? this.isGraduated,
      graduationDate: graduationDate ?? this.graduationDate,
      isAlumni: isAlumni ?? this.isAlumni,
      promotedToClassId: promotedToClassId ?? this.promotedToClassId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName, email: email ?? this.email,
      phone: phone ?? this.phone, avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          schoolId == other.schoolId &&
          admissionNumber == other.admissionNumber;

  @override
  int get hashCode => Object.hash(id, userId, schoolId, admissionNumber);

  @override
  String toString() => 'StudentProfileModel(id: $id, admissionNumber: $admissionNumber)';
}

// ═══════════════════════════════════════════════════════════════════════
// 5. TeacherProfileModel
// ═══════════════════════════════════════════════════════════════════════

class TeacherProfileModel {
  const TeacherProfileModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.employeeId,
    this.staffIdCardNumber,
    this.passportPhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.qualification,
    this.specialization,
    this.departmentId,
    this.employmentType = EmploymentType.fullTime,
    this.employmentStartDate,
    this.employmentEndDate,
    this.yearsOfExperience = 0,
    this.isHeadOfDepartment = false,
    this.isActive = true,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    // Denormalized user fields
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String schoolId;
  final String employeeId;
  final String? staffIdCardNumber;
  final String? passportPhotoUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? qualification;
  final String? specialization;
  final String? departmentId;
  final EmploymentType employmentType;
  final DateTime? employmentStartDate;
  final DateTime? employmentEndDate;
  final int yearsOfExperience;
  final bool isHeadOfDepartment;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Denormalized user fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    return TeacherProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? json['employeeId'] as String? ?? '',
      staffIdCardNumber: json['staff_id_card_number'] as String? ?? json['staffIdCardNumber'] as String?,
      passportPhotoUrl: json['passport_photo_url'] as String? ?? json['passportPhotoUrl'] as String?,
      dateOfBirth: _parseDateTimeNullable(json['date_of_birth'] ?? json['dateOfBirth']),
      gender: json['gender'] as String?,
      qualification: json['qualification'] as String?,
      specialization: json['specialization'] as String?,
      departmentId: json['department_id'] as String? ?? json['departmentId'] as String?,
      employmentType: EmploymentType.fromString(
        json['employment_type'] as String? ?? json['employmentType'] as String?,
      ) ?? EmploymentType.fullTime,
      employmentStartDate: _parseDateTimeNullable(json['employment_start_date'] ?? json['employmentStartDate']),
      employmentEndDate: _parseDateTimeNullable(json['employment_end_date'] ?? json['employmentEndDate']),
      yearsOfExperience: json['years_of_experience'] as int? ?? json['yearsOfExperience'] as int? ?? 0,
      isHeadOfDepartment: json['is_head_of_department'] as bool? ?? json['isHeadOfDepartment'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
      fullName: json['full_name'] as String? ?? json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'employee_id': employeeId,
      'staff_id_card_number': staffIdCardNumber,
      'passport_photo_url': passportPhotoUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'qualification': qualification,
      'specialization': specialization,
      'department_id': departmentId,
      'employment_type': employmentType.value,
      'employment_start_date': employmentStartDate?.toIso8601String(),
      'employment_end_date': employmentEndDate?.toIso8601String(),
      'years_of_experience': yearsOfExperience,
      'is_head_of_department': isHeadOfDepartment,
      'is_active': isActive,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TeacherProfileModel.fromEntity(TeacherProfileEntity entity) {
    return TeacherProfileModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      employeeId: entity.employeeId,
      staffIdCardNumber: entity.staffIdCardNumber,
      passportPhotoUrl: entity.passportPhotoUrl,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      qualification: entity.qualification,
      specialization: entity.specialization,
      departmentId: entity.departmentId,
      employmentType: entity.employmentType,
      employmentStartDate: entity.employmentStartDate,
      employmentEndDate: entity.employmentEndDate,
      yearsOfExperience: entity.yearsOfExperience,
      isHeadOfDepartment: entity.isHeadOfDepartment,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
    );
  }

  TeacherProfileEntity toEntity() {
    return TeacherProfileEntity(
      id: id,
      userId: userId,
      schoolId: schoolId,
      employeeId: employeeId,
      staffIdCardNumber: staffIdCardNumber,
      passportPhotoUrl: passportPhotoUrl,
      dateOfBirth: dateOfBirth,
      gender: gender,
      qualification: qualification,
      specialization: specialization,
      departmentId: departmentId,
      employmentType: employmentType,
      employmentStartDate: employmentStartDate,
      employmentEndDate: employmentEndDate,
      yearsOfExperience: yearsOfExperience,
      isHeadOfDepartment: isHeadOfDepartment,
      isActive: isActive,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TeacherProfileModel copyWith({
    String? id, String? userId, String? schoolId, String? employeeId,
    String? staffIdCardNumber, String? passportPhotoUrl,
    DateTime? dateOfBirth, String? gender, String? qualification,
    String? specialization, String? departmentId,
    EmploymentType? employmentType, DateTime? employmentStartDate,
    DateTime? employmentEndDate, int? yearsOfExperience,
    bool? isHeadOfDepartment, bool? isActive,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
    String? fullName, String? email, String? phone, String? avatarUrl,
  }) {
    return TeacherProfileModel(
      id: id ?? this.id, userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      employeeId: employeeId ?? this.employeeId,
      staffIdCardNumber: staffIdCardNumber ?? this.staffIdCardNumber,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      departmentId: departmentId ?? this.departmentId,
      employmentType: employmentType ?? this.employmentType,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      employmentEndDate: employmentEndDate ?? this.employmentEndDate,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      isHeadOfDepartment: isHeadOfDepartment ?? this.isHeadOfDepartment,
      isActive: isActive ?? this.isActive, metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName, email: email ?? this.email,
      phone: phone ?? this.phone, avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          schoolId == other.schoolId &&
          employeeId == other.employeeId;

  @override
  int get hashCode => Object.hash(id, userId, schoolId, employeeId);

  @override
  String toString() => 'TeacherProfileModel(id: $id, employeeId: $employeeId)';
}

// ═══════════════════════════════════════════════════════════════════════
// 6. ParentProfileModel
// ═══════════════════════════════════════════════════════════════════════

class ParentProfileModel {
  const ParentProfileModel({
    required this.id,
    required this.userId,
    required this.schoolId,
    this.occupation,
    this.employer,
    this.homeAddress,
    this.officeAddress,
    this.relationshipType = 'parent',
    this.isActive = true,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    // Denormalized user fields
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String schoolId;
  final String? occupation;
  final String? employer;
  final String? homeAddress;
  final String? officeAddress;
  final String relationshipType;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Denormalized user fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentProfileModel.fromJson(Map<String, dynamic> json) {
    return ParentProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      occupation: json['occupation'] as String?,
      employer: json['employer'] as String?,
      homeAddress: json['home_address'] as String? ?? json['homeAddress'] as String?,
      officeAddress: json['office_address'] as String? ?? json['officeAddress'] as String?,
      relationshipType: json['relationship_type'] as String? ?? json['relationshipType'] as String? ?? 'parent',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
      fullName: json['full_name'] as String? ?? json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'occupation': occupation,
      'employer': employer,
      'home_address': homeAddress,
      'office_address': officeAddress,
      'relationship_type': relationshipType,
      'is_active': isActive,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentProfileModel.fromEntity(ParentProfileEntity entity) {
    return ParentProfileModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      occupation: entity.occupation,
      employer: entity.employer,
      homeAddress: entity.homeAddress,
      officeAddress: entity.officeAddress,
      relationshipType: entity.relationshipType,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
    );
  }

  ParentProfileEntity toEntity() {
    return ParentProfileEntity(
      id: id,
      userId: userId,
      schoolId: schoolId,
      occupation: occupation,
      employer: employer,
      homeAddress: homeAddress,
      officeAddress: officeAddress,
      relationshipType: relationshipType,
      isActive: isActive,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ParentProfileModel copyWith({
    String? id, String? userId, String? schoolId, String? occupation,
    String? employer, String? homeAddress, String? officeAddress,
    String? relationshipType, bool? isActive,
    Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
    String? fullName, String? email, String? phone, String? avatarUrl,
  }) {
    return ParentProfileModel(
      id: id ?? this.id, userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      occupation: occupation ?? this.occupation,
      employer: employer ?? this.employer,
      homeAddress: homeAddress ?? this.homeAddress,
      officeAddress: officeAddress ?? this.officeAddress,
      relationshipType: relationshipType ?? this.relationshipType,
      isActive: isActive ?? this.isActive, metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName, email: email ?? this.email,
      phone: phone ?? this.phone, avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          schoolId == other.schoolId;

  @override
  int get hashCode => Object.hash(id, userId, schoolId);

  @override
  String toString() => 'ParentProfileModel(id: $id, userId: $userId)';
}

// ═══════════════════════════════════════════════════════════════════════
// 7. ParentStudentLinkModel
// ═══════════════════════════════════════════════════════════════════════

class ParentStudentLinkModel {
  const ParentStudentLinkModel({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.relationship = 'parent',
    this.isPrimaryContact = false,
    this.canPickup = true,
    this.createdAt,
  });

  final String id;
  final String parentId;
  final String studentId;
  final String relationship;
  final bool isPrimaryContact;
  final bool canPickup;
  final DateTime? createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ParentStudentLinkModel.fromJson(Map<String, dynamic> json) {
    return ParentStudentLinkModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String? ?? json['parentId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'parent',
      isPrimaryContact: json['is_primary_contact'] as bool? ?? json['isPrimaryContact'] as bool? ?? false,
      canPickup: json['can_pickup'] as bool? ?? json['canPickup'] as bool? ?? true,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'student_id': studentId,
      'relationship': relationship,
      'is_primary_contact': isPrimaryContact,
      'can_pickup': canPickup,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ParentStudentLinkModel.fromEntity(ParentStudentLinkEntity entity) {
    return ParentStudentLinkModel(
      id: entity.id,
      parentId: entity.parentId,
      studentId: entity.studentId,
      relationship: entity.relationship,
      isPrimaryContact: entity.isPrimaryContact,
      canPickup: entity.canPickup,
      createdAt: null, // Entity doesn't expose createdAt directly
    );
  }

  ParentStudentLinkEntity toEntity() {
    return ParentStudentLinkEntity(
      id: id,
      parentId: parentId,
      studentId: studentId,
      relationship: relationship,
      isPrimaryContact: isPrimaryContact,
      canPickup: canPickup,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ParentStudentLinkModel copyWith({
    String? id, String? parentId, String? studentId,
    String? relationship, bool? isPrimaryContact, bool? canPickup,
    DateTime? createdAt,
  }) {
    return ParentStudentLinkModel(
      id: id ?? this.id, parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      relationship: relationship ?? this.relationship,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      canPickup: canPickup ?? this.canPickup,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentStudentLinkModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentId == other.parentId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(id, parentId, studentId);

  @override
  String toString() => 'ParentStudentLinkModel(id: $id, parentId: $parentId, studentId: $studentId)';
}

// ═══════════════════════════════════════════════════════════════════════
// 8. AcademicSessionModel
// ═══════════════════════════════════════════════════════════════════════

class AcademicSessionModel {
  const AcademicSessionModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.sessionYear,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.isActive = true,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String sessionYear;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AcademicSessionModel.fromJson(Map<String, dynamic> json) {
    return AcademicSessionModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String,
      sessionYear: json['session_year'] as String? ?? json['sessionYear'] as String? ?? '',
      startDate: _parseDateTime(json['start_date'] ?? json['startDate']),
      endDate: _parseDateTime(json['end_date'] ?? json['endDate']),
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'session_year': sessionYear,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_current': isCurrent,
      'is_active': isActive,
      'settings': settings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AcademicSessionModel.fromEntity(AcademicSessionEntity entity) {
    return AcademicSessionModel(
      id: entity.id,
      schoolId: entity.schoolId,
      name: entity.name,
      sessionYear: entity.sessionYear,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isCurrent: entity.isCurrent,
      isActive: entity.isActive,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AcademicSessionEntity toEntity() {
    return AcademicSessionEntity(
      id: id,
      schoolId: schoolId,
      name: name,
      sessionYear: sessionYear,
      startDate: startDate,
      endDate: endDate,
      isCurrent: isCurrent,
      isActive: isActive,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AcademicSessionModel copyWith({
    String? id, String? schoolId, String? name, String? sessionYear,
    DateTime? startDate, DateTime? endDate, bool? isCurrent, bool? isActive,
    Map<String, dynamic>? settings, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AcademicSessionModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name, sessionYear: sessionYear ?? this.sessionYear,
      startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent, isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          sessionYear == other.sessionYear;

  @override
  int get hashCode => Object.hash(id, schoolId, sessionYear);

  @override
  String toString() => 'AcademicSessionModel(id: $id, sessionYear: $sessionYear)';
}

// ═══════════════════════════════════════════════════════════════════════
// 9. TermModel
// ═══════════════════════════════════════════════════════════════════════

class TermModel {
  const TermModel({
    required this.id,
    required this.academicSessionId,
    required this.schoolId,
    required this.name,
    required this.termType,
    required this.termNumber,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.status = TermStatus.upcoming,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String academicSessionId;
  final String schoolId;
  final String name;
  final TermType termType;
  final int termNumber;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final TermStatus status;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TermModel.fromJson(Map<String, dynamic> json) {
    return TermModel(
      id: json['id'] as String,
      academicSessionId: json['academic_session_id'] as String? ?? json['academicSessionId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      name: json['name'] as String,
      termType: TermType.fromString(json['term_type'] as String? ?? json['termType'] as String?) ?? TermType.firstTerm,
      termNumber: json['term_number'] as int? ?? json['termNumber'] as int? ?? 1,
      startDate: _parseDateTime(json['start_date'] ?? json['startDate']),
      endDate: _parseDateTime(json['end_date'] ?? json['endDate']),
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      status: TermStatus.fromString(json['status'] as String?) ?? TermStatus.upcoming,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academic_session_id': academicSessionId,
      'school_id': schoolId,
      'name': name,
      'term_type': termType.value,
      'term_number': termNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_current': isCurrent,
      'status': status.value,
      'settings': settings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TermModel.fromEntity(TermEntity entity) {
    return TermModel(
      id: entity.id,
      academicSessionId: entity.academicSessionId,
      schoolId: entity.schoolId,
      name: entity.name,
      termType: entity.termType,
      termNumber: entity.termNumber,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isCurrent: entity.isCurrent,
      status: entity.status,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TermEntity toEntity() {
    return TermEntity(
      id: id,
      academicSessionId: academicSessionId,
      schoolId: schoolId,
      name: name,
      termType: termType,
      termNumber: termNumber,
      startDate: startDate,
      endDate: endDate,
      isCurrent: isCurrent,
      status: status,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TermModel copyWith({
    String? id, String? academicSessionId, String? schoolId, String? name,
    TermType? termType, int? termNumber, DateTime? startDate, DateTime? endDate,
    bool? isCurrent, TermStatus? status, Map<String, dynamic>? settings,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return TermModel(
      id: id ?? this.id,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      schoolId: schoolId ?? this.schoolId, name: name ?? this.name,
      termType: termType ?? this.termType,
      termNumber: termNumber ?? this.termNumber,
      startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent, status: status ?? this.status,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          academicSessionId == other.academicSessionId &&
          termNumber == other.termNumber;

  @override
  int get hashCode => Object.hash(id, academicSessionId, termNumber);

  @override
  String toString() => 'TermModel(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// 10. CalendarEventModel
// ═══════════════════════════════════════════════════════════════════════

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.schoolId,
    this.termId,
    required this.title,
    this.description,
    this.eventType = CalendarEventType.event,
    required this.startDate,
    this.endDate,
    this.isFullDay = true,
    this.isRecurring = false,
    this.recurrenceRule,
    this.targetAudience = 'all',
    this.createdBy,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String? termId;
  final String title;
  final String? description;
  final CalendarEventType eventType;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isFullDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final String targetAudience;
  final String? createdBy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      termId: json['term_id'] as String? ?? json['termId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: CalendarEventType.fromString(
        json['event_type'] as String? ?? json['eventType'] as String?,
      ) ?? CalendarEventType.event,
      startDate: _parseDateTime(json['start_date'] ?? json['startDate']),
      endDate: _parseDateTimeNullable(json['end_date'] ?? json['endDate']),
      isFullDay: json['is_full_day'] as bool? ?? json['isFullDay'] as bool? ?? true,
      isRecurring: json['is_recurring'] as bool? ?? json['isRecurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String? ?? json['recurrenceRule'] as String?,
      targetAudience: json['target_audience'] as String? ?? json['targetAudience'] as String? ?? 'all',
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'term_id': termId,
      'title': title,
      'description': description,
      'event_type': eventType.value,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_full_day': isFullDay,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'target_audience': targetAudience,
      'created_by': createdBy,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CalendarEventModel.fromEntity(CalendarEventEntity entity) {
    return CalendarEventModel(
      id: entity.id,
      schoolId: entity.schoolId,
      termId: entity.termId,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isFullDay: entity.isFullDay,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      targetAudience: entity.targetAudience,
      createdBy: entity.createdBy,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CalendarEventEntity toEntity() {
    return CalendarEventEntity(
      id: id,
      schoolId: schoolId,
      termId: termId,
      title: title,
      description: description,
      eventType: eventType,
      startDate: startDate,
      endDate: endDate,
      isFullDay: isFullDay,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      targetAudience: targetAudience,
      createdBy: createdBy,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  CalendarEventModel copyWith({
    String? id, String? schoolId, String? termId, String? title,
    String? description, CalendarEventType? eventType,
    DateTime? startDate, DateTime? endDate, bool? isFullDay,
    bool? isRecurring, String? recurrenceRule, String? targetAudience,
    String? createdBy, bool? isActive, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId, title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
      isFullDay: isFullDay ?? this.isFullDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title &&
          startDate == other.startDate;

  @override
  int get hashCode => Object.hash(id, schoolId, title, startDate);

  @override
  String toString() => 'CalendarEventModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// 11. TimetableModel
// ═══════════════════════════════════════════════════════════════════════

class TimetableModel {
  const TimetableModel({
    required this.id,
    required this.schoolId,
    required this.termId,
    required this.name,
    this.timetableType = 'class',
    this.classId,
    this.isActive = true,
    this.isPublished = false,
    this.createdBy,
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String termId;
  final String name;
  final String timetableType;
  final String? classId;
  final bool isActive;
  final bool isPublished;
  final String? createdBy;
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      termId: json['term_id'] as String? ?? json['termId'] as String? ?? '',
      name: json['name'] as String,
      timetableType: json['timetable_type'] as String? ?? json['timetableType'] as String? ?? 'class',
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isPublished: json['is_published'] as bool? ?? json['isPublished'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'term_id': termId,
      'name': name,
      'timetable_type': timetableType,
      'class_id': classId,
      'is_active': isActive,
      'is_published': isPublished,
      'created_by': createdBy,
      'settings': settings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TimetableModel.fromEntity(TimetableEntity entity) {
    return TimetableModel(
      id: entity.id,
      schoolId: entity.schoolId,
      termId: entity.termId,
      name: entity.name,
      timetableType: entity.timetableType,
      classId: entity.classId,
      isActive: entity.isActive,
      isPublished: entity.isPublished,
      createdBy: entity.createdBy,
      settings: entity.settings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TimetableEntity toEntity() {
    return TimetableEntity(
      id: id,
      schoolId: schoolId,
      termId: termId,
      name: name,
      timetableType: timetableType,
      classId: classId,
      isActive: isActive,
      isPublished: isPublished,
      createdBy: createdBy,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TimetableModel copyWith({
    String? id, String? schoolId, String? termId, String? name,
    String? timetableType, String? classId, bool? isActive,
    bool? isPublished, String? createdBy, Map<String, dynamic>? settings,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return TimetableModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId, name: name ?? this.name,
      timetableType: timetableType ?? this.timetableType,
      classId: classId ?? this.classId, isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy, settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          termId == other.termId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, schoolId, termId, name);

  @override
  String toString() => 'TimetableModel(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// 12. TimetableSlotModel
// ═══════════════════════════════════════════════════════════════════════
// Note: startTime/endTime stored as String (HH:mm) in the model,
// converted to/from DateTime in toEntity/fromEntity.

class TimetableSlotModel {
  const TimetableSlotModel({
    required this.id,
    required this.timetableId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.subjectId,
    this.teacherId,
    this.classroom,
    this.classId,
    this.isBreak = false,
    this.breakLabel,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String timetableId;
  final DayOfWeek dayOfWeek;
  final int periodNumber;
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final String? subjectId;
  final String? teacherId;
  final String? classroom;
  final String? classId;
  final bool isBreak;
  final String? breakLabel;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    return TimetableSlotModel(
      id: json['id'] as String,
      timetableId: json['timetable_id'] as String? ?? json['timetableId'] as String? ?? '',
      dayOfWeek: DayOfWeek.fromString(json['day_of_week'] as String? ?? json['dayOfWeek'] as String?) ?? DayOfWeek.monday,
      periodNumber: json['period_number'] as int? ?? json['periodNumber'] as int? ?? 1,
      startTime: json['start_time'] as String? ?? json['startTime'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? json['endTime'] as String? ?? '09:00',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String?,
      classroom: json['classroom'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      isBreak: json['is_break'] as bool? ?? json['isBreak'] as bool? ?? false,
      breakLabel: json['break_label'] as String? ?? json['breakLabel'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timetable_id': timetableId,
      'day_of_week': dayOfWeek.value,
      'period_number': periodNumber,
      'start_time': startTime,
      'end_time': endTime,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'classroom': classroom,
      'class_id': classId,
      'is_break': isBreak,
      'break_label': breakLabel,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TimetableSlotModel.fromEntity(TimetableSlotEntity entity) {
    // Convert DateTime to HH:mm String
    final startDt = entity.startTime;
    final endDt = entity.endTime;
    final startStr = '${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}';
    final endStr = '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';
    return TimetableSlotModel(
      id: entity.id,
      timetableId: entity.timetableId,
      dayOfWeek: entity.dayOfWeek,
      periodNumber: entity.periodNumber,
      startTime: startStr,
      endTime: endStr,
      subjectId: entity.subjectId,
      teacherId: entity.teacherId,
      classroom: entity.classroom,
      classId: entity.classId,
      isBreak: entity.isBreak,
      breakLabel: entity.breakLabel,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TimetableSlotEntity toEntity() {
    // Convert HH:mm String to DateTime (using today's date as base)
    final now = DateTime.now();
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startDt = DateTime(now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final endDt = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
    return TimetableSlotEntity(
      id: id,
      timetableId: timetableId,
      dayOfWeek: dayOfWeek,
      periodNumber: periodNumber,
      startTime: startDt,
      endTime: endDt,
      subjectId: subjectId,
      teacherId: teacherId,
      classroom: classroom,
      classId: classId,
      isBreak: isBreak,
      breakLabel: breakLabel,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TimetableSlotModel copyWith({
    String? id, String? timetableId, DayOfWeek? dayOfWeek,
    int? periodNumber, String? startTime, String? endTime,
    String? subjectId, String? teacherId, String? classroom,
    String? classId, bool? isBreak, String? breakLabel, String? notes,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return TimetableSlotModel(
      id: id ?? this.id, timetableId: timetableId ?? this.timetableId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periodNumber: periodNumber ?? this.periodNumber,
      startTime: startTime ?? this.startTime, endTime: endTime ?? this.endTime,
      subjectId: subjectId ?? this.subjectId, teacherId: teacherId ?? this.teacherId,
      classroom: classroom ?? this.classroom, classId: classId ?? this.classId,
      isBreak: isBreak ?? this.isBreak, breakLabel: breakLabel ?? this.breakLabel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSlotModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timetableId == other.timetableId &&
          dayOfWeek == other.dayOfWeek &&
          periodNumber == other.periodNumber;

  @override
  int get hashCode => Object.hash(id, timetableId, dayOfWeek, periodNumber);

  @override
  String toString() => 'TimetableSlotModel(id: $id, dayOfWeek: $dayOfWeek, period: $periodNumber)';
}

// ═══════════════════════════════════════════════════════════════════════
// 13. AttendanceRecordModel
// ═══════════════════════════════════════════════════════════════════════

class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.id,
    required this.schoolId,
    required this.termId,
    required this.classId,
    required this.date,
    this.attendanceType = 'student',
    this.subjectId,
    this.recordedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String termId;
  final String classId;
  final DateTime date;
  final String attendanceType;
  final String? subjectId;
  final String? recordedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      termId: json['term_id'] as String? ?? json['termId'] as String? ?? '',
      classId: json['class_id'] as String? ?? json['classId'] as String? ?? '',
      date: _parseDateTime(json['date']),
      attendanceType: json['attendance_type'] as String? ?? json['attendanceType'] as String? ?? 'student',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      recordedBy: json['recorded_by'] as String? ?? json['recordedBy'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'term_id': termId,
      'class_id': classId,
      'date': date.toIso8601String(),
      'attendance_type': attendanceType,
      'subject_id': subjectId,
      'recorded_by': recordedBy,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AttendanceRecordModel.fromEntity(AttendanceRecordEntity entity) {
    return AttendanceRecordModel(
      id: entity.id,
      schoolId: entity.schoolId,
      termId: entity.termId,
      classId: entity.classId,
      date: entity.date,
      attendanceType: entity.attendanceType,
      subjectId: entity.subjectId,
      recordedBy: entity.recordedBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AttendanceRecordEntity toEntity() {
    return AttendanceRecordEntity(
      id: id,
      schoolId: schoolId,
      termId: termId,
      classId: classId,
      date: date,
      attendanceType: attendanceType,
      subjectId: subjectId,
      recordedBy: recordedBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AttendanceRecordModel copyWith({
    String? id, String? schoolId, String? termId, String? classId,
    DateTime? date, String? attendanceType, String? subjectId,
    String? recordedBy, String? notes, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId, classId: classId ?? this.classId,
      date: date ?? this.date,
      attendanceType: attendanceType ?? this.attendanceType,
      subjectId: subjectId ?? this.subjectId,
      recordedBy: recordedBy ?? this.recordedBy, notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          classId == other.classId &&
          date == other.date &&
          attendanceType == other.attendanceType;

  @override
  int get hashCode => Object.hash(id, schoolId, classId, date, attendanceType);

  @override
  String toString() => 'AttendanceRecordModel(id: $id, classId: $classId, date: $date)';
}

// ═══════════════════════════════════════════════════════════════════════
// 14. AttendanceEntryModel
// ═══════════════════════════════════════════════════════════════════════

class AttendanceEntryModel {
  const AttendanceEntryModel({
    required this.id,
    required this.attendanceRecordId,
    required this.userId,
    this.status = AttendanceStatus.present,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String attendanceRecordId;
  final String userId;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AttendanceEntryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEntryModel(
      id: json['id'] as String,
      attendanceRecordId: json['attendance_record_id'] as String? ?? json['attendanceRecordId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      status: AttendanceStatus.fromString(json['status'] as String?) ?? AttendanceStatus.present,
      checkInTime: _parseDateTimeNullable(json['check_in_time'] ?? json['checkInTime']),
      checkOutTime: _parseDateTimeNullable(json['check_out_time'] ?? json['checkOutTime']),
      notes: json['notes'] as String?,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendance_record_id': attendanceRecordId,
      'user_id': userId,
      'status': status.value,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AttendanceEntryModel.fromEntity(AttendanceEntryEntity entity) {
    return AttendanceEntryModel(
      id: entity.id,
      attendanceRecordId: entity.attendanceRecordId,
      userId: entity.userId,
      status: entity.status,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      notes: entity.notes,
    );
  }

  AttendanceEntryEntity toEntity() {
    return AttendanceEntryEntity(
      id: id,
      attendanceRecordId: attendanceRecordId,
      userId: userId,
      status: status,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      notes: notes,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AttendanceEntryModel copyWith({
    String? id, String? attendanceRecordId, String? userId,
    AttendanceStatus? status, DateTime? checkInTime, DateTime? checkOutTime,
    String? notes, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AttendanceEntryModel(
      id: id ?? this.id,
      attendanceRecordId: attendanceRecordId ?? this.attendanceRecordId,
      userId: userId ?? this.userId, status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceEntryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attendanceRecordId == other.attendanceRecordId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, attendanceRecordId, userId);

  @override
  String toString() => 'AttendanceEntryModel(id: $id, userId: $userId, status: $status)';
}

// ═══════════════════════════════════════════════════════════════════════
// 15. HomeworkModel
// ═══════════════════════════════════════════════════════════════════════

class HomeworkModel {
  const HomeworkModel({
    required this.id,
    required this.schoolId,
    required this.termId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.title,
    this.description,
    this.instructions,
    this.attachmentUrls = const [],
    this.totalMarks = 0,
    this.deadline,
    this.allowLateSubmission = false,
    this.status = HomeworkStatus.draft,
    this.isPublished = false,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String termId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String title;
  final String? description;
  final String? instructions;
  final List<String> attachmentUrls;
  final double totalMarks;
  final DateTime? deadline;
  final bool allowLateSubmission;
  final HomeworkStatus status;
  final bool isPublished;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      termId: json['term_id'] as String? ?? json['termId'] as String? ?? '',
      classId: json['class_id'] as String? ?? json['classId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? (json['totalMarks'] as num?)?.toDouble() ?? 0,
      deadline: _parseDateTimeNullable(json['deadline']),
      allowLateSubmission: json['allow_late_submission'] as bool? ?? json['allowLateSubmission'] as bool? ?? false,
      status: HomeworkStatus.fromString(json['status'] as String?) ?? HomeworkStatus.draft,
      isPublished: json['is_published'] as bool? ?? json['isPublished'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'term_id': termId,
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'attachment_urls': attachmentUrls,
      'total_marks': totalMarks,
      'deadline': deadline?.toIso8601String(),
      'allow_late_submission': allowLateSubmission,
      'status': status.value,
      'is_published': isPublished,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory HomeworkModel.fromEntity(HomeworkEntity entity) {
    return HomeworkModel(
      id: entity.id,
      schoolId: entity.schoolId,
      termId: entity.termId,
      classId: entity.classId,
      subjectId: entity.subjectId,
      teacherId: entity.teacherId,
      title: entity.title,
      description: entity.description,
      instructions: entity.instructions,
      attachmentUrls: entity.attachmentUrls,
      totalMarks: entity.totalMarks,
      deadline: entity.deadline,
      allowLateSubmission: entity.allowLateSubmission,
      status: entity.status,
      isPublished: entity.isPublished,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  HomeworkEntity toEntity() {
    return HomeworkEntity(
      id: id,
      schoolId: schoolId,
      termId: termId,
      classId: classId,
      subjectId: subjectId,
      teacherId: teacherId,
      title: title,
      description: description,
      instructions: instructions,
      attachmentUrls: attachmentUrls,
      totalMarks: totalMarks,
      deadline: deadline,
      allowLateSubmission: allowLateSubmission,
      status: status,
      isPublished: isPublished,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  HomeworkModel copyWith({
    String? id, String? schoolId, String? termId, String? classId,
    String? subjectId, String? teacherId, String? title, String? description,
    String? instructions, List<String>? attachmentUrls, double? totalMarks,
    DateTime? deadline, bool? allowLateSubmission, HomeworkStatus? status,
    bool? isPublished, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return HomeworkModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId, classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId, teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title, description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      totalMarks: totalMarks ?? this.totalMarks, deadline: deadline ?? this.deadline,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      status: status ?? this.status, isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, schoolId, title);

  @override
  String toString() => 'HomeworkModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// 16. HomeworkSubmissionModel
// ═══════════════════════════════════════════════════════════════════════

class HomeworkSubmissionModel {
  const HomeworkSubmissionModel({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    this.content,
    this.attachmentUrls = const [],
    this.status = SubmissionStatus.pending,
    this.submittedAt,
    this.marksAwarded,
    this.maxMarks,
    this.teacherComment,
    this.gradedBy,
    this.gradedAt,
    this.isLate = false,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String homeworkId;
  final String studentId;
  final String? content;
  final List<String> attachmentUrls;
  final SubmissionStatus status;
  final DateTime? submittedAt;
  final double? marksAwarded;
  final double? maxMarks;
  final String? teacherComment;
  final String? gradedBy;
  final DateTime? gradedAt;
  final bool isLate;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmissionModel(
      id: json['id'] as String,
      homeworkId: json['homework_id'] as String? ?? json['homeworkId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      content: json['content'] as String?,
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      status: SubmissionStatus.fromString(json['status'] as String?) ?? SubmissionStatus.pending,
      submittedAt: _parseDateTimeNullable(json['submitted_at'] ?? json['submittedAt']),
      marksAwarded: (json['marks_awarded'] as num?)?.toDouble() ?? (json['marksAwarded'] as num?)?.toDouble(),
      maxMarks: (json['max_marks'] as num?)?.toDouble() ?? (json['maxMarks'] as num?)?.toDouble(),
      teacherComment: json['teacher_comment'] as String? ?? json['teacherComment'] as String?,
      gradedBy: json['graded_by'] as String? ?? json['gradedBy'] as String?,
      gradedAt: _parseDateTimeNullable(json['graded_at'] ?? json['gradedAt']),
      isLate: json['is_late'] as bool? ?? json['isLate'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homework_id': homeworkId,
      'student_id': studentId,
      'content': content,
      'attachment_urls': attachmentUrls,
      'status': status.value,
      'submitted_at': submittedAt?.toIso8601String(),
      'marks_awarded': marksAwarded,
      'max_marks': maxMarks,
      'teacher_comment': teacherComment,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
      'is_late': isLate,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory HomeworkSubmissionModel.fromEntity(HomeworkSubmissionEntity entity) {
    return HomeworkSubmissionModel(
      id: entity.id,
      homeworkId: entity.homeworkId,
      studentId: entity.studentId,
      content: entity.content,
      attachmentUrls: entity.attachmentUrls,
      status: entity.status,
      submittedAt: entity.submittedAt,
      marksAwarded: entity.marksAwarded,
      maxMarks: entity.maxMarks,
      teacherComment: entity.teacherComment,
      gradedBy: entity.gradedBy,
      gradedAt: entity.gradedAt,
      isLate: entity.isLate,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  HomeworkSubmissionEntity toEntity() {
    return HomeworkSubmissionEntity(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      content: content,
      attachmentUrls: attachmentUrls,
      status: status,
      submittedAt: submittedAt,
      marksAwarded: marksAwarded,
      maxMarks: maxMarks,
      teacherComment: teacherComment,
      gradedBy: gradedBy,
      gradedAt: gradedAt,
      isLate: isLate,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  HomeworkSubmissionModel copyWith({
    String? id, String? homeworkId, String? studentId, String? content,
    List<String>? attachmentUrls, SubmissionStatus? status,
    DateTime? submittedAt, double? marksAwarded, double? maxMarks,
    String? teacherComment, String? gradedBy, DateTime? gradedAt,
    bool? isLate, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return HomeworkSubmissionModel(
      id: id ?? this.id, homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId, content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status, submittedAt: submittedAt ?? this.submittedAt,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      maxMarks: maxMarks ?? this.maxMarks,
      teacherComment: teacherComment ?? this.teacherComment,
      gradedBy: gradedBy ?? this.gradedBy, gradedAt: gradedAt ?? this.gradedAt,
      isLate: isLate ?? this.isLate, metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkSubmissionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          homeworkId == other.homeworkId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(id, homeworkId, studentId);

  @override
  String toString() => 'HomeworkSubmissionModel(id: $id, homeworkId: $homeworkId, studentId: $studentId)';
}

// ═══════════════════════════════════════════════════════════════════════
// 17. AnnouncementModel
// ═══════════════════════════════════════════════════════════════════════

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.content,
    this.announcementType = AnnouncementType.notice,
    this.priority = AnnouncementPriority.normal,
    this.targetAudience = 'all',
    this.targetClassIds = const [],
    this.attachmentUrls = const [],
    this.isPinned = false,
    this.isPublished = false,
    this.publishedAt,
    this.expiresAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String content;
  final AnnouncementType announcementType;
  final AnnouncementPriority priority;
  final String targetAudience;
  final List<String> targetClassIds;
  final List<String> attachmentUrls;
  final bool isPinned;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      title: json['title'] as String,
      content: json['content'] as String,
      announcementType: AnnouncementType.fromString(
        json['announcement_type'] as String? ?? json['announcementType'] as String?,
      ) ?? AnnouncementType.notice,
      priority: AnnouncementPriority.fromString(
        json['priority'] as String?,
      ) ?? AnnouncementPriority.normal,
      targetAudience: json['target_audience'] as String? ?? json['targetAudience'] as String? ?? 'all',
      targetClassIds: (json['target_class_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? json['isPublished'] as bool? ?? false,
      publishedAt: _parseDateTimeNullable(json['published_at'] ?? json['publishedAt']),
      expiresAt: _parseDateTimeNullable(json['expires_at'] ?? json['expiresAt']),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'content': content,
      'announcement_type': announcementType.value,
      'priority': priority.value,
      'target_audience': targetAudience,
      'target_class_ids': targetClassIds,
      'attachment_urls': attachmentUrls,
      'is_pinned': isPinned,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AnnouncementModel.fromEntity(AnnouncementEntity entity) {
    return AnnouncementModel(
      id: entity.id,
      schoolId: entity.schoolId,
      title: entity.title,
      content: entity.content,
      announcementType: entity.announcementType,
      priority: entity.priority,
      targetAudience: entity.targetAudience,
      targetClassIds: entity.targetClassIds,
      attachmentUrls: entity.attachmentUrls,
      isPinned: entity.isPinned,
      isPublished: entity.isPublished,
      publishedAt: entity.publishedAt,
      expiresAt: entity.expiresAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AnnouncementEntity toEntity() {
    return AnnouncementEntity(
      id: id,
      schoolId: schoolId,
      title: title,
      content: content,
      announcementType: announcementType,
      priority: priority,
      targetAudience: targetAudience,
      targetClassIds: targetClassIds,
      attachmentUrls: attachmentUrls,
      isPinned: isPinned,
      isPublished: isPublished,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AnnouncementModel copyWith({
    String? id, String? schoolId, String? title, String? content,
    AnnouncementType? announcementType, AnnouncementPriority? priority,
    String? targetAudience, List<String>? targetClassIds,
    List<String>? attachmentUrls, bool? isPinned, bool? isPublished,
    DateTime? publishedAt, DateTime? expiresAt, String? createdBy,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title, content: content ?? this.content,
      announcementType: announcementType ?? this.announcementType,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      targetClassIds: targetClassIds ?? this.targetClassIds,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isPinned: isPinned ?? this.isPinned,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, schoolId, title);

  @override
  String toString() => 'AnnouncementModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// 18. DocumentModel
// ═══════════════════════════════════════════════════════════════════════

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    this.documentType = DocumentType.general,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.category,
    this.tags = const [],
    this.isPublic = false,
    this.downloadable = true,
    this.targetAudience = 'all',
    this.uploadedBy,
    this.studentId,
    this.downloadCount = 0,
    this.version = 1,
    this.parentDocumentId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final DocumentType documentType;
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final String? category;
  final List<String> tags;
  final bool isPublic;
  final bool downloadable;
  final String targetAudience;
  final String? uploadedBy;
  final String? studentId;
  final int downloadCount;
  final int version;
  final String? parentDocumentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      documentType: DocumentType.fromString(
        json['document_type'] as String? ?? json['documentType'] as String?,
      ) ?? DocumentType.general,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int?,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublic: json['is_public'] as bool? ?? json['isPublic'] as bool? ?? false,
      downloadable: json['downloadable'] as bool? ?? true,
      targetAudience: json['target_audience'] as String? ?? json['targetAudience'] as String? ?? 'all',
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String?,
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      downloadCount: json['download_count'] as int? ?? json['downloadCount'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      parentDocumentId: json['parent_document_id'] as String? ?? json['parentDocumentId'] as String?,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'description': description,
      'document_type': documentType.value,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'category': category,
      'tags': tags,
      'is_public': isPublic,
      'downloadable': downloadable,
      'target_audience': targetAudience,
      'uploaded_by': uploadedBy,
      'student_id': studentId,
      'download_count': downloadCount,
      'version': version,
      'parent_document_id': parentDocumentId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      title: entity.title,
      description: entity.description,
      documentType: entity.documentType,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      category: entity.category,
      tags: entity.tags,
      isPublic: entity.isPublic,
      downloadable: entity.downloadable,
      targetAudience: entity.targetAudience,
      uploadedBy: entity.uploadedBy,
      studentId: entity.studentId,
      downloadCount: entity.downloadCount,
      version: entity.version,
      parentDocumentId: entity.parentDocumentId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      schoolId: schoolId,
      title: title,
      description: description,
      documentType: documentType,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      category: category,
      tags: tags,
      isPublic: isPublic,
      downloadable: downloadable,
      targetAudience: targetAudience,
      uploadedBy: uploadedBy,
      studentId: studentId,
      downloadCount: downloadCount,
      version: version,
      parentDocumentId: parentDocumentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  DocumentModel copyWith({
    String? id, String? schoolId, String? title, String? description,
    DocumentType? documentType, String? fileUrl, String? fileName,
    int? fileSize, String? mimeType, String? category, List<String>? tags,
    bool? isPublic, bool? downloadable, String? targetAudience,
    String? uploadedBy, String? studentId, int? downloadCount,
    int? version, String? parentDocumentId,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id, schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title, description: description ?? this.description,
      documentType: documentType ?? this.documentType,
      fileUrl: fileUrl ?? this.fileUrl, fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize, mimeType: mimeType ?? this.mimeType,
      category: category ?? this.category, tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      downloadable: downloadable ?? this.downloadable,
      targetAudience: targetAudience ?? this.targetAudience,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      studentId: studentId ?? this.studentId,
      downloadCount: downloadCount ?? this.downloadCount,
      version: version ?? this.version,
      parentDocumentId: parentDocumentId ?? this.parentDocumentId,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          title == other.title &&
          fileUrl == other.fileUrl;

  @override
  int get hashCode => Object.hash(id, schoolId, title, fileUrl);

  @override
  String toString() => 'DocumentModel(id: $id, title: $title)';
}

// ═══════════════════════════════════════════════════════════════════════
// 19. PromotionHistoryModel
// ═══════════════════════════════════════════════════════════════════════

class PromotionHistoryModel {
  const PromotionHistoryModel({
    required this.id,
    required this.studentId,
    required this.schoolId,
    this.fromClassId,
    this.toClassId,
    this.academicSessionId,
    this.termId,
    this.promotionStatus = PromotionStatus.promoted,
    this.averageScore,
    this.classTeacherComment,
    this.principalComment,
    this.promotedBy,
    this.promotedAt,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String? fromClassId;
  final String? toClassId;
  final String? academicSessionId;
  final String? termId;
  final PromotionStatus promotionStatus;
  final double? averageScore;
  final String? classTeacherComment;
  final String? principalComment;
  final String? promotedBy;
  final DateTime? promotedAt;
  final DateTime? createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory PromotionHistoryModel.fromJson(Map<String, dynamic> json) {
    return PromotionHistoryModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      fromClassId: json['from_class_id'] as String? ?? json['fromClassId'] as String?,
      toClassId: json['to_class_id'] as String? ?? json['toClassId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ?? json['academicSessionId'] as String?,
      termId: json['term_id'] as String? ?? json['termId'] as String?,
      promotionStatus: PromotionStatus.fromString(json['promotion_status'] as String?) ?? PromotionStatus.promoted,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? (json['averageScore'] as num?)?.toDouble(),
      classTeacherComment: json['class_teacher_comment'] as String? ?? json['classTeacherComment'] as String?,
      principalComment: json['principal_comment'] as String? ?? json['principalComment'] as String?,
      promotedBy: json['promoted_by'] as String? ?? json['promotedBy'] as String?,
      promotedAt: _parseDateTimeNullable(json['promoted_at'] ?? json['promotedAt']),
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'from_class_id': fromClassId,
      'to_class_id': toClassId,
      'academic_session_id': academicSessionId,
      'term_id': termId,
      'promotion_status': promotionStatus.value,
      'average_score': averageScore,
      'class_teacher_comment': classTeacherComment,
      'principal_comment': principalComment,
      'promoted_by': promotedBy,
      'promoted_at': promotedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory PromotionHistoryModel.fromEntity(PromotionHistoryEntity entity) {
    return PromotionHistoryModel(
      id: entity.id,
      studentId: entity.studentId,
      schoolId: entity.schoolId,
      fromClassId: entity.fromClassId,
      toClassId: entity.toClassId,
      academicSessionId: entity.academicSessionId,
      termId: entity.termId,
      promotionStatus: entity.promotionStatus,
      averageScore: entity.averageScore,
      classTeacherComment: entity.classTeacherComment,
      principalComment: entity.principalComment,
      promotedBy: entity.promotedBy,
      promotedAt: entity.promotedAt,
      createdAt: entity.createdAt,
    );
  }

  PromotionHistoryEntity toEntity() {
    return PromotionHistoryEntity(
      id: id,
      studentId: studentId,
      schoolId: schoolId,
      fromClassId: fromClassId,
      toClassId: toClassId,
      academicSessionId: academicSessionId,
      termId: termId,
      promotionStatus: promotionStatus,
      averageScore: averageScore,
      classTeacherComment: classTeacherComment,
      principalComment: principalComment,
      promotedBy: promotedBy,
      promotedAt: promotedAt,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  PromotionHistoryModel copyWith({
    String? id, String? studentId, String? schoolId, String? fromClassId,
    String? toClassId, String? academicSessionId, String? termId,
    PromotionStatus? promotionStatus, double? averageScore,
    String? classTeacherComment, String? principalComment,
    String? promotedBy, DateTime? promotedAt, DateTime? createdAt,
  }) {
    return PromotionHistoryModel(
      id: id ?? this.id, studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      fromClassId: fromClassId ?? this.fromClassId,
      toClassId: toClassId ?? this.toClassId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      termId: termId ?? this.termId,
      promotionStatus: promotionStatus ?? this.promotionStatus,
      averageScore: averageScore ?? this.averageScore,
      classTeacherComment: classTeacherComment ?? this.classTeacherComment,
      principalComment: principalComment ?? this.principalComment,
      promotedBy: promotedBy ?? this.promotedBy,
      promotedAt: promotedAt ?? this.promotedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionHistoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          schoolId == other.schoolId &&
          promotionStatus == other.promotionStatus;

  @override
  int get hashCode => Object.hash(id, studentId, schoolId, promotionStatus);

  @override
  String toString() => 'PromotionHistoryModel(id: $id, studentId: $studentId, status: $promotionStatus)';
}

// ═══════════════════════════════════════════════════════════════════════
// 20. ClassModel
// ═══════════════════════════════════════════════════════════════════════

class ClassModel {
  const ClassModel({
    required this.id,
    required this.name,
    this.section,
    required this.schoolId,
    this.teacherId,
    this.academicYear,
    this.gradeLevel,
    this.capacity = 40,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    // Denormalized fields
    this.teacherName,
    this.studentCount = 0,
  });

  final String id;
  final String name;
  final String? section;
  final String schoolId;
  final String? teacherId;
  final String? academicYear;
  final String? gradeLevel;
  final int capacity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Denormalized fields
  final String? teacherName;
  final int studentCount;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      section: json['section'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String?,
      academicYear: json['academic_year'] as String? ?? json['academicYear'] as String?,
      gradeLevel: json['grade_level'] as String? ?? json['gradeLevel'] as String?,
      capacity: json['capacity'] as int? ?? 40,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
      // Denormalized fields (may come from join)
      teacherName: json['teacher_name'] as String? ?? json['teacherName'] as String?,
      studentCount: json['student_count'] as int? ?? json['studentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'section': section,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'academic_year': academicYear,
      'grade_level': gradeLevel,
      'capacity': capacity,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ClassModel.fromEntity(ClassEntity entity) {
    return ClassModel(
      id: entity.id,
      name: entity.name,
      section: entity.section,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      academicYear: entity.academicYear,
      gradeLevel: entity.gradeLevel,
      capacity: entity.capacity,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      teacherName: entity.teacherName,
      studentCount: entity.studentCount,
    );
  }

  ClassEntity toEntity() {
    return ClassEntity(
      id: id,
      name: name,
      section: section,
      schoolId: schoolId,
      teacherId: teacherId,
      teacherName: teacherName,
      academicYear: academicYear,
      gradeLevel: gradeLevel,
      capacity: capacity,
      isActive: isActive,
      studentCount: studentCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ClassModel copyWith({
    String? id, String? name, String? section, String? schoolId,
    String? teacherId, String? academicYear, String? gradeLevel,
    int? capacity, bool? isActive, DateTime? createdAt, DateTime? updatedAt,
    String? teacherName, int? studentCount,
  }) {
    return ClassModel(
      id: id ?? this.id, name: name ?? this.name,
      section: section ?? this.section, schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      academicYear: academicYear ?? this.academicYear,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      capacity: capacity ?? this.capacity, isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      teacherName: teacherName ?? this.teacherName,
      studentCount: studentCount ?? this.studentCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, schoolId, name);

  @override
  String toString() => 'ClassModel(id: $id, name: $name)';
}

// ═══════════════════════════════════════════════════════════════════════
// 21. SubjectModel
// ═══════════════════════════════════════════════════════════════════════

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.schoolId,
    this.category,
    this.iconUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final String? schoolId;
  final String? category;
  final String? iconUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      category: json['category'] as String?,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTimeNullable(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'school_id': schoolId,
      'category': category,
      'icon_url': iconUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SubjectModel.fromEntity(SubjectEntity entity) {
    return SubjectModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      description: entity.description,
      schoolId: entity.schoolId,
      category: entity.category,
      iconUrl: entity.iconUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SubjectEntity toEntity() {
    return SubjectEntity(
      id: id,
      name: name,
      code: code,
      description: description,
      schoolId: schoolId,
      category: category,
      iconUrl: iconUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SubjectModel copyWith({
    String? id, String? name, String? code, String? description,
    String? schoolId, String? category, String? iconUrl, bool? isActive,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id, name: name ?? this.name, code: code ?? this.code,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId, category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl, isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, name, code);

  @override
  String toString() => 'SubjectModel(id: $id, name: $name, code: $code)';
}
