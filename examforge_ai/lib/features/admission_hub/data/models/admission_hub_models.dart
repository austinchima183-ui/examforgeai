import '../../domain/entities/admission_hub_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY MODEL
// ═══════════════════════════════════════════════════════════════════════

class UniversityModel {
  final String id;
  final String name;
  final String code;
  final String universityType;
  final String city;
  final String state;
  final String country;
  final String? logoUrl;
  final String? websiteUrl;
  final String? description;
  final int? yearFounded;
  final String? accreditationStatus;
  final bool isActive;
  final int? rankingNational;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniversityModel({
    required this.id,
    required this.name,
    required this.code,
    required this.universityType,
    required this.city,
    required this.state,
    this.country = 'Nigeria',
    this.logoUrl,
    this.websiteUrl,
    this.description,
    this.yearFounded,
    this.accreditationStatus,
    this.isActive = true,
    this.rankingNational,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) =>
      UniversityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        universityType: json['university_type'] as String? ?? 'federal',
        city: json['city'] as String,
        state: json['state'] as String,
        country: json['country'] as String? ?? 'Nigeria',
        logoUrl: json['logo_url'] as String?,
        websiteUrl: json['website_url'] as String?,
        description: json['description'] as String?,
        yearFounded: json['year_founded'] as int?,
        accreditationStatus: json['accreditation_status'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        rankingNational: json['ranking_national'] as int?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'university_type': universityType,
        'city': city,
        'state': state,
        'country': country,
        'logo_url': logoUrl,
        'website_url': websiteUrl,
        'description': description,
        'year_founded': yearFounded,
        'accreditation_status': accreditationStatus,
        'is_active': isActive,
        'ranking_national': rankingNational,
        'metadata': metadata,
      };

  University toEntity() => University(
        id: id,
        name: name,
        code: code,
        universityType:
            UniversityType.fromString(universityType) ?? UniversityType.federal,
        city: city,
        state: state,
        country: country,
        logoUrl: logoUrl,
        websiteUrl: websiteUrl,
        description: description,
        yearFounded: yearFounded,
        accreditationStatus: accreditationStatus,
        isActive: isActive,
        rankingNational: rankingNational,
        metadata: metadata,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static UniversityModel fromEntity(University entity) => UniversityModel(
        id: entity.id,
        name: entity.name,
        code: entity.code,
        universityType: entity.universityType.value,
        city: entity.city,
        state: entity.state,
        country: entity.country,
        logoUrl: entity.logoUrl,
        websiteUrl: entity.websiteUrl,
        description: entity.description,
        yearFounded: entity.yearFounded,
        accreditationStatus: entity.accreditationStatus,
        isActive: entity.isActive,
        rankingNational: entity.rankingNational,
        metadata: entity.metadata,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY FACULTY MODEL
// ═══════════════════════════════════════════════════════════════════════

class UniversityFacultyModel {
  final String id;
  final String universityId;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const UniversityFacultyModel({
    required this.id,
    required this.universityId,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory UniversityFacultyModel.fromJson(Map<String, dynamic> json) =>
      UniversityFacultyModel(
        id: json['id'] as String,
        universityId: json['university_id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'university_id': universityId,
        'name': name,
        'code': code,
        'description': description,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  UniversityFaculty toEntity() => UniversityFaculty(
        id: id,
        universityId: universityId,
        name: name,
        code: code,
        description: description,
        isActive: isActive,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  static UniversityFacultyModel fromEntity(UniversityFaculty entity) =>
      UniversityFacultyModel(
        id: entity.id,
        universityId: entity.universityId,
        name: entity.name,
        code: entity.code,
        description: entity.description,
        isActive: entity.isActive,
        sortOrder: entity.sortOrder,
        createdAt: entity.createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY DEPARTMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

class UniversityDepartmentModel {
  final String id;
  final String facultyId;
  final String name;
  final String code;
  final String? description;
  final String? degreeType;
  final int? durationYears;
  final List<Map<String, dynamic>> utmeSubjects;
  final List<Map<String, dynamic>> oLevelRequirements;
  final List<Map<String, dynamic>> jambSubjectCombination;
  final double? cutOffMark;
  final bool isActive;
  final int sortOrder;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const UniversityDepartmentModel({
    required this.id,
    required this.facultyId,
    required this.name,
    required this.code,
    this.description,
    this.degreeType,
    this.durationYears,
    this.utmeSubjects = const [],
    this.oLevelRequirements = const [],
    this.jambSubjectCombination = const [],
    this.cutOffMark,
    this.isActive = true,
    this.sortOrder = 0,
    this.metadata = const {},
    required this.createdAt,
  });

  factory UniversityDepartmentModel.fromJson(Map<String, dynamic> json) =>
      UniversityDepartmentModel(
        id: json['id'] as String,
        facultyId: json['faculty_id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        degreeType: json['degree_type'] as String?,
        durationYears: json['duration_years'] as int?,
        utmeSubjects: (json['utme_subjects'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        oLevelRequirements: (json['o_level_requirements'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        jambSubjectCombination:
            (json['jamb_subject_combination'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [],
        cutOffMark: (json['cut_off_mark'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'faculty_id': facultyId,
        'name': name,
        'code': code,
        'description': description,
        'degree_type': degreeType,
        'duration_years': durationYears,
        'utme_subjects': utmeSubjects,
        'o_level_requirements': oLevelRequirements,
        'jamb_subject_combination': jambSubjectCombination,
        'cut_off_mark': cutOffMark,
        'is_active': isActive,
        'sort_order': sortOrder,
        'metadata': metadata,
      };

  UniversityDepartment toEntity() => UniversityDepartment(
        id: id,
        facultyId: facultyId,
        name: name,
        code: code,
        description: description,
        degreeType: degreeType,
        durationYears: durationYears,
        utmeSubjects: utmeSubjects,
        oLevelRequirements: oLevelRequirements,
        jambSubjectCombination: jambSubjectCombination,
        cutOffMark: cutOffMark,
        isActive: isActive,
        sortOrder: sortOrder,
        metadata: metadata,
        createdAt: createdAt,
      );

  static UniversityDepartmentModel fromEntity(UniversityDepartment entity) =>
      UniversityDepartmentModel(
        id: entity.id,
        facultyId: entity.facultyId,
        name: entity.name,
        code: entity.code,
        description: entity.description,
        degreeType: entity.degreeType,
        durationYears: entity.durationYears,
        utmeSubjects: entity.utmeSubjects,
        oLevelRequirements: entity.oLevelRequirements,
        jambSubjectCombination: entity.jambSubjectCombination,
        cutOffMark: entity.cutOffMark,
        isActive: entity.isActive,
        sortOrder: entity.sortOrder,
        metadata: entity.metadata,
        createdAt: entity.createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// POST-UTME PRODUCT MODEL
// ═══════════════════════════════════════════════════════════════════════

class PostUtmeProductModel {
  final String id;
  final String universityId;
  final String departmentId;
  final String facultyId;
  final String name;
  final String? description;
  final int year;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final double passMark;
  final List<Map<String, dynamic>> instructions;
  final Map<String, dynamic> settings;
  final bool isActive;
  final bool isPremium;
  final String sourceType;
  final bool hasLicensingRights;
  final Map<String, dynamic> licenseDetails;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostUtmeProductModel({
    required this.id,
    required this.universityId,
    required this.departmentId,
    required this.facultyId,
    required this.name,
    this.description,
    required this.year,
    this.durationMinutes = 60,
    this.totalQuestions = 50,
    this.totalMarks = 100,
    this.passMark = 50,
    this.instructions = const [],
    this.settings = const {},
    this.isActive = true,
    this.isPremium = false,
    this.sourceType = 'official',
    this.hasLicensingRights = false,
    this.licenseDetails = const {},
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostUtmeProductModel.fromJson(Map<String, dynamic> json) =>
      PostUtmeProductModel(
        id: json['id'] as String,
        universityId: json['university_id'] as String,
        departmentId: json['department_id'] as String,
        facultyId: json['faculty_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        year: json['year'] as int,
        durationMinutes: json['duration_minutes'] as int? ?? 60,
        totalQuestions: json['total_questions'] as int? ?? 50,
        totalMarks: json['total_marks'] as int? ?? 100,
        passMark: (json['pass_mark'] as num?)?.toDouble() ?? 50.0,
        instructions: (json['instructions'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        settings: json['settings'] as Map<String, dynamic>? ?? {},
        isActive: json['is_active'] as bool? ?? true,
        isPremium: json['is_premium'] as bool? ?? false,
        sourceType: json['source_type'] as String? ?? 'official',
        hasLicensingRights: json['has_licensing_rights'] as bool? ?? false,
        licenseDetails:
            json['license_details'] as Map<String, dynamic>? ?? {},
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'university_id': universityId,
        'department_id': departmentId,
        'faculty_id': facultyId,
        'name': name,
        'description': description,
        'year': year,
        'duration_minutes': durationMinutes,
        'total_questions': totalQuestions,
        'total_marks': totalMarks,
        'pass_mark': passMark,
        'instructions': instructions,
        'settings': settings,
        'is_active': isActive,
        'is_premium': isPremium,
        'source_type': sourceType,
        'has_licensing_rights': hasLicensingRights,
        'license_details': licenseDetails,
        'created_by': createdBy,
      };

  PostUtmeProduct toEntity() => PostUtmeProduct(
        id: id,
        universityId: universityId,
        departmentId: departmentId,
        facultyId: facultyId,
        name: name,
        description: description,
        year: year,
        durationMinutes: durationMinutes,
        totalQuestions: totalQuestions,
        totalMarks: totalMarks,
        passMark: passMark,
        instructions: instructions,
        settings: settings,
        isActive: isActive,
        isPremium: isPremium,
        sourceType: sourceType,
        hasLicensingRights: hasLicensingRights,
        licenseDetails: licenseDetails,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PostUtmeProductModel fromEntity(PostUtmeProduct entity) =>
      PostUtmeProductModel(
        id: entity.id,
        universityId: entity.universityId,
        departmentId: entity.departmentId,
        facultyId: entity.facultyId,
        name: entity.name,
        description: entity.description,
        year: entity.year,
        durationMinutes: entity.durationMinutes,
        totalQuestions: entity.totalQuestions,
        totalMarks: entity.totalMarks,
        passMark: entity.passMark,
        instructions: entity.instructions,
        settings: entity.settings,
        isActive: entity.isActive,
        isPremium: entity.isPremium,
        sourceType: entity.sourceType,
        hasLicensingRights: entity.hasLicensingRights,
        licenseDetails: entity.licenseDetails,
        createdBy: entity.createdBy,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION CHECKLIST MODEL
// ═══════════════════════════════════════════════════════════════════════

class AdmissionChecklistModel {
  final String id;
  final String userId;
  final String universityId;
  final String departmentId;
  final List<Map<String, dynamic>> checklistItems;
  final List<Map<String, dynamic>> completedItems;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> deadlines;
  final double overallReadinessScore;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdmissionChecklistModel({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.departmentId,
    this.checklistItems = const [],
    this.completedItems = const [],
    this.documents = const [],
    this.deadlines = const [],
    this.overallReadinessScore = 0.0,
    this.status = 'in_progress',
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdmissionChecklistModel.fromJson(Map<String, dynamic> json) =>
      AdmissionChecklistModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        universityId: json['university_id'] as String,
        departmentId: json['department_id'] as String,
        checklistItems: (json['checklist_items'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        completedItems: (json['completed_items'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        documents: (json['documents'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        deadlines: (json['deadlines'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        overallReadinessScore:
            (json['overall_readiness_score'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'in_progress',
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'university_id': universityId,
        'department_id': departmentId,
        'checklist_items': checklistItems,
        'completed_items': completedItems,
        'documents': documents,
        'deadlines': deadlines,
        'overall_readiness_score': overallReadinessScore,
        'status': status,
        'metadata': metadata,
      };

  AdmissionChecklist toEntity() => AdmissionChecklist(
        id: id,
        userId: userId,
        universityId: universityId,
        departmentId: departmentId,
        checklistItems: checklistItems,
        completedItems: completedItems,
        documents: documents,
        deadlines: deadlines,
        overallReadinessScore: overallReadinessScore,
        status: status,
        metadata: metadata,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static AdmissionChecklistModel fromEntity(AdmissionChecklist entity) =>
      AdmissionChecklistModel(
        id: entity.id,
        userId: entity.userId,
        universityId: entity.universityId,
        departmentId: entity.departmentId,
        checklistItems: entity.checklistItems,
        completedItems: entity.completedItems,
        documents: entity.documents,
        deadlines: entity.deadlines,
        overallReadinessScore: entity.overallReadinessScore,
        status: entity.status,
        metadata: entity.metadata,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION APPLICATION MODEL
// ═══════════════════════════════════════════════════════════════════════

class AdmissionApplicationModel {
  final String id;
  final String userId;
  final String universityId;
  final String departmentId;
  final String course;
  final String admissionStatus;
  final int applicationYear;
  final double? jambScore;
  final double? postUtmeScore;
  final List<Map<String, dynamic>> oLevelResults;
  final List<Map<String, dynamic>> documents;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdmissionApplicationModel({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.departmentId,
    required this.course,
    this.admissionStatus = 'not_applied',
    required this.applicationYear,
    this.jambScore,
    this.postUtmeScore,
    this.oLevelResults = const [],
    this.documents = const [],
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdmissionApplicationModel.fromJson(Map<String, dynamic> json) =>
      AdmissionApplicationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        universityId: json['university_id'] as String,
        departmentId: json['department_id'] as String,
        course: json['course'] as String,
        admissionStatus: json['admission_status'] as String? ?? 'not_applied',
        applicationYear: json['application_year'] as int,
        jambScore: (json['jamb_score'] as num?)?.toDouble(),
        postUtmeScore: (json['post_utme_score'] as num?)?.toDouble(),
        oLevelResults: (json['o_level_results'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        documents: (json['documents'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        notes: json['notes'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'university_id': universityId,
        'department_id': departmentId,
        'course': course,
        'admission_status': admissionStatus,
        'application_year': applicationYear,
        'jamb_score': jambScore,
        'post_utme_score': postUtmeScore,
        'o_level_results': oLevelResults,
        'documents': documents,
        'notes': notes,
        'metadata': metadata,
      };

  AdmissionApplication toEntity() => AdmissionApplication(
        id: id,
        userId: userId,
        universityId: universityId,
        departmentId: departmentId,
        course: course,
        admissionStatus: AdmissionStatus.fromString(admissionStatus) ??
            AdmissionStatus.notApplied,
        applicationYear: applicationYear,
        jambScore: jambScore,
        postUtmeScore: postUtmeScore,
        oLevelResults: oLevelResults,
        documents: documents,
        notes: notes,
        metadata: metadata,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static AdmissionApplicationModel fromEntity(AdmissionApplication entity) =>
      AdmissionApplicationModel(
        id: entity.id,
        userId: entity.userId,
        universityId: entity.universityId,
        departmentId: entity.departmentId,
        course: entity.course,
        admissionStatus: entity.admissionStatus.value,
        applicationYear: entity.applicationYear,
        jambScore: entity.jambScore,
        postUtmeScore: entity.postUtmeScore,
        oLevelResults: entity.oLevelResults,
        documents: entity.documents,
        notes: entity.notes,
        metadata: entity.metadata,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
