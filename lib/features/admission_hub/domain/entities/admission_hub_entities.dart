import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Type of university institution.
enum UniversityType {
  federal(value: 'federal', label: 'Federal'),
  state(value: 'state', label: 'State'),
  private(value: 'private', label: 'Private'),
  polytechnic(value: 'polytechnic', label: 'Polytechnic'),
  collegeOfEducation(value: 'college_of_education', label: 'College of Education'),
  monotechnic(value: 'monotechnic', label: 'Monotechnic');

  const UniversityType({required this.value, required this.label});
  final String value;
  final String label;

  static UniversityType? fromString(String? value) {
    if (value == null) return null;
    return UniversityType.values.cast<UniversityType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Status of an admission application.
enum AdmissionStatus {
  notApplied(value: 'not_applied', label: 'Not Applied'),
  applied(value: 'applied', label: 'Applied'),
  accepted(value: 'accepted', label: 'Accepted'),
  rejected(value: 'rejected', label: 'Rejected'),
  deferred(value: 'deferred', label: 'Deferred'),
  withdrawn(value: 'withdrawn', label: 'Withdrawn');

  const AdmissionStatus({required this.value, required this.label});
  final String value;
  final String label;

  static AdmissionStatus? fromString(String? value) {
    if (value == null) return null;
    return AdmissionStatus.values.cast<AdmissionStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY
// ═══════════════════════════════════════════════════════════════════════

/// Represents a university or tertiary institution.
class University extends Equatable {
  const University({
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

  final String id;
  final String name;
  final String code;
  final UniversityType universityType;
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

  @override
  List<Object?> get props => [
        id, name, code, universityType, city, state, country,
        logoUrl, websiteUrl, description, yearFounded,
        accreditationStatus, isActive, rankingNational, metadata,
        createdAt, updatedAt,
      ];

  University copyWith({
    String? name,
    String? code,
    UniversityType? universityType,
    String? city,
    String? state,
    String? country,
    String? logoUrl,
    String? websiteUrl,
    String? description,
    int? yearFounded,
    String? accreditationStatus,
    bool? isActive,
    int? rankingNational,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return University(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      universityType: universityType ?? this.universityType,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      description: description ?? this.description,
      yearFounded: yearFounded ?? this.yearFounded,
      accreditationStatus: accreditationStatus ?? this.accreditationStatus,
      isActive: isActive ?? this.isActive,
      rankingNational: rankingNational ?? this.rankingNational,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY FACULTY
// ═══════════════════════════════════════════════════════════════════════

/// Represents a faculty within a university.
class UniversityFaculty extends Equatable {
  const UniversityFaculty({
    required this.id,
    required this.universityId,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final String id;
  final String universityId;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id, universityId, name, code, description,
        isActive, sortOrder, createdAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY DEPARTMENT
// ═══════════════════════════════════════════════════════════════════════

/// Represents a department within a faculty.
class UniversityDepartment extends Equatable {
  const UniversityDepartment({
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

  @override
  List<Object?> get props => [
        id, facultyId, name, code, description, degreeType,
        durationYears, utmeSubjects, oLevelRequirements,
        jambSubjectCombination, cutOffMark, isActive,
        sortOrder, metadata, createdAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// POST-UTME PRODUCT
// ═══════════════════════════════════════════════════════════════════════

/// Represents a Post-UTME practice test product.
class PostUtmeProduct extends Equatable {
  const PostUtmeProduct({
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

  @override
  List<Object?> get props => [
        id, universityId, departmentId, facultyId, name,
        description, year, durationMinutes, totalQuestions,
        totalMarks, passMark, instructions, settings,
        isActive, isPremium, sourceType, hasLicensingRights,
        licenseDetails, createdBy, createdAt, updatedAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION CHECKLIST
// ═══════════════════════════════════════════════════════════════════════

/// Represents a user's admission preparation checklist.
class AdmissionChecklist extends Equatable {
  const AdmissionChecklist({
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

  @override
  List<Object?> get props => [
        id, userId, universityId, departmentId,
        checklistItems, completedItems, documents,
        deadlines, overallReadinessScore, status,
        metadata, createdAt, updatedAt,
      ];

  /// Computes completion percentage from completed / total items.
  double get completionPct {
    if (checklistItems.isEmpty) return 0.0;
    return (completedItems.length / checklistItems.length) * 100;
  }

  AdmissionChecklist copyWith({
    List<Map<String, dynamic>>? checklistItems,
    List<Map<String, dynamic>>? completedItems,
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? deadlines,
    double? overallReadinessScore,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return AdmissionChecklist(
      id: id,
      userId: userId,
      universityId: universityId,
      departmentId: departmentId,
      checklistItems: checklistItems ?? this.checklistItems,
      completedItems: completedItems ?? this.completedItems,
      documents: documents ?? this.documents,
      deadlines: deadlines ?? this.deadlines,
      overallReadinessScore: overallReadinessScore ?? this.overallReadinessScore,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION APPLICATION
// ═══════════════════════════════════════════════════════════════════════

/// Represents a student's application to a university department.
class AdmissionApplication extends Equatable {
  const AdmissionApplication({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.departmentId,
    required this.course,
    this.admissionStatus = AdmissionStatus.notApplied,
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

  final String id;
  final String userId;
  final String universityId;
  final String departmentId;
  final String course;
  final AdmissionStatus admissionStatus;
  final int applicationYear;
  final double? jambScore;
  final double? postUtmeScore;
  final List<Map<String, dynamic>> oLevelResults;
  final List<Map<String, dynamic>> documents;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id, userId, universityId, departmentId, course,
        admissionStatus, applicationYear, jambScore,
        postUtmeScore, oLevelResults, documents, notes,
        metadata, createdAt, updatedAt,
      ];

  AdmissionApplication copyWith({
    AdmissionStatus? admissionStatus,
    double? jambScore,
    double? postUtmeScore,
    List<Map<String, dynamic>>? oLevelResults,
    List<Map<String, dynamic>>? documents,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return AdmissionApplication(
      id: id,
      userId: userId,
      universityId: universityId,
      departmentId: departmentId,
      course: course,
      admissionStatus: admissionStatus ?? this.admissionStatus,
      applicationYear: applicationYear,
      jambScore: jambScore ?? this.jambScore,
      postUtmeScore: postUtmeScore ?? this.postUtmeScore,
      oLevelResults: oLevelResults ?? this.oLevelResults,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ELIGIBILITY RESULT (value object returned by checker)
// ═══════════════════════════════════════════════════════════════════════

/// Result of an admission eligibility check.
class EligibilityResult extends Equatable {
  const EligibilityResult({
    required this.universityId,
    required this.departmentId,
    required this.isEligible,
    required this.eligibilityScore,
    this.jambScoreMet = false,
    this.oLevelRequirementsMet = false,
    this.subjectCombinationCorrect = false,
    this.missingSubjects = const [],
    this.missingOLevelGrades = const [],
    this.recommendations = const [],
    this.details = const {},
  });

  final String universityId;
  final String departmentId;
  final bool isEligible;
  final double eligibilityScore;
  final bool jambScoreMet;
  final bool oLevelRequirementsMet;
  final bool subjectCombinationCorrect;
  final List<String> missingSubjects;
  final List<String> missingOLevelGrades;
  final List<String> recommendations;
  final Map<String, dynamic> details;

  @override
  List<Object?> get props => [
        universityId, departmentId, isEligible, eligibilityScore,
        jambScoreMet, oLevelRequirementsMet, subjectCombinationCorrect,
        missingSubjects, missingOLevelGrades, recommendations, details,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// UNIVERSITY COMPARISON (value object)
// ═══════════════════════════════════════════════════════════════════════

/// Side-by-side comparison of multiple universities.
class UniversityComparison extends Equatable {
  const UniversityComparison({
    required this.universities,
    this.comparisonData = const {},
  });

  final List<University> universities;
  final Map<String, dynamic> comparisonData;

  @override
  List<Object?> get props => [universities, comparisonData];
}
