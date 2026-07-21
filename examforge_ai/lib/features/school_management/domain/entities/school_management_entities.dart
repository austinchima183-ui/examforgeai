import 'package:equatable/equatable.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Term type: whether a term is semester-based or term-based.
enum TermType {
  firstTerm(value: 'first_term', label: 'First Term'),
  secondTerm(value: 'second_term', label: 'Second Term'),
  thirdTerm(value: 'third_term', label: 'Third Term'),
  firstSemester(value: 'first_semester', label: 'First Semester'),
  secondSemester(value: 'second_semester', label: 'Second Semester');

  const TermType({required this.value, required this.label});

  final String value;
  final String label;

  static TermType? fromString(String? value) {
    if (value == null) return null;
    return TermType.values.cast<TermType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Term lifecycle status.
enum TermStatus {
  upcoming(value: 'upcoming', label: 'Upcoming', color: '#9CA3AF'),
  active(value: 'active', label: 'Active', color: '#22C55E'),
  completed(value: 'completed', label: 'Completed', color: '#6366F1'),
  archived(value: 'archived', label: 'Archived', color: '#78716C');

  const TermStatus({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final String color;

  static TermStatus? fromString(String? value) {
    if (value == null) return null;
    return TermStatus.values.cast<TermStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Attendance status for students and teachers.
enum AttendanceStatus {
  present(value: 'present', label: 'Present', color: '#22C55E', isPresent: true),
  absent(value: 'absent', label: 'Absent', color: '#EF4444', isPresent: false),
  late(value: 'late', label: 'Late', color: '#F59E0B', isPresent: true),
  excused(value: 'excused', label: 'Excused', color: '#3B82F6', isPresent: false),
  sick(value: 'sick', label: 'Sick', color: '#8B5CF6', isPresent: false);

  const AttendanceStatus({
    required this.value,
    required this.label,
    required this.color,
    required this.isPresent,
  });

  final String value;
  final String label;
  final String color;
  final bool isPresent;

  static AttendanceStatus? fromString(String? value) {
    if (value == null) return null;
    return AttendanceStatus.values.cast<AttendanceStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Homework lifecycle status.
enum HomeworkStatus {
  draft(value: 'draft', label: 'Draft', color: '#9CA3AF', isEditable: true),
  published(value: 'published', label: 'Published', color: '#3B82F6', isEditable: false),
  closed(value: 'closed', label: 'Closed', color: '#F59E0B', isEditable: false),
  graded(value: 'graded', label: 'Graded', color: '#22C55E', isEditable: false);

  const HomeworkStatus({
    required this.value,
    required this.label,
    required this.color,
    required this.isEditable,
  });

  final String value;
  final String label;
  final String color;
  final bool isEditable;

  static HomeworkStatus? fromString(String? value) {
    if (value == null) return null;
    return HomeworkStatus.values.cast<HomeworkStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Homework submission status.
enum SubmissionStatus {
  pending(value: 'pending', label: 'Pending', color: '#9CA3AF'),
  submitted(value: 'submitted', label: 'Submitted', color: '#3B82F6'),
  lateSubmitted(value: 'late_submitted', label: 'Late', color: '#F59E0B'),
  graded(value: 'graded', label: 'Graded', color: '#22C55E'),
  returned(value: 'returned', label: 'Returned', color: '#8B5CF6');

  const SubmissionStatus({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final String color;

  static SubmissionStatus? fromString(String? value) {
    if (value == null) return null;
    return SubmissionStatus.values.cast<SubmissionStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Announcement type category.
enum AnnouncementType {
  notice(value: 'notice', label: 'Notice', icon: 'info'),
  event(value: 'event', label: 'Event', icon: 'event'),
  circular(value: 'circular', label: 'Circular', icon: 'description'),
  holiday(value: 'holiday', label: 'Holiday', icon: 'beach_access'),
  emergency(value: 'emergency', label: 'Emergency', icon: 'warning');

  const AnnouncementType({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final String icon;

  static AnnouncementType? fromString(String? value) {
    if (value == null) return null;
    return AnnouncementType.values.cast<AnnouncementType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Announcement priority/urgency.
enum AnnouncementPriority {
  low(value: 'low', label: 'Low', color: '#9CA3AF'),
  normal(value: 'normal', label: 'Normal', color: '#3B82F6'),
  high(value: 'high', label: 'High', color: '#F59E0B'),
  urgent(value: 'urgent', label: 'Urgent', color: '#EF4444');

  const AnnouncementPriority({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final String color;

  static AnnouncementPriority? fromString(String? value) {
    if (value == null) return null;
    return AnnouncementPriority.values.cast<AnnouncementPriority?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Document type category.
enum DocumentType {
  studentDocument(value: 'student_document', label: 'Student Document'),
  schoolPolicy(value: 'school_policy', label: 'School Policy'),
  curriculumFile(value: 'curriculum_file', label: 'Curriculum File'),
  certificate(value: 'certificate', label: 'Certificate'),
  general(value: 'general', label: 'General'),
  homeworkAttachment(value: 'homework_attachment', label: 'Homework Attachment'),
  reportCard(value: 'report_card', label: 'Report Card');

  const DocumentType({required this.value, required this.label});

  final String value;
  final String label;

  static DocumentType? fromString(String? value) {
    if (value == null) return null;
    return DocumentType.values.cast<DocumentType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Day of the week for timetable slots.
enum DayOfWeek {
  monday(value: 'monday', label: 'Monday', order: 1),
  tuesday(value: 'tuesday', label: 'Tuesday', order: 2),
  wednesday(value: 'wednesday', label: 'Wednesday', order: 3),
  thursday(value: 'thursday', label: 'Thursday', order: 4),
  friday(value: 'friday', label: 'Friday', order: 5),
  saturday(value: 'saturday', label: 'Saturday', order: 6),
  sunday(value: 'sunday', label: 'Sunday', order: 7);

  const DayOfWeek({required this.value, required this.label, required this.order});

  final String value;
  final String label;
  final int order;

  static DayOfWeek? fromString(String? value) {
    if (value == null) return null;
    return DayOfWeek.values.cast<DayOfWeek?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Student promotion status.
enum PromotionStatus {
  promoted(value: 'promoted', label: 'Promoted', color: '#22C55E'),
  retained(value: 'retained', label: 'Retained', color: '#EF4444'),
  graduated(value: 'graduated', label: 'Graduated', color: '#6366F1'),
  transferred(value: 'transferred', label: 'Transferred', color: '#3B82F6'),
  withdrawn(value: 'withdrawn', label: 'Withdrawn', color: '#78716C');

  const PromotionStatus({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final String color;

  static PromotionStatus? fromString(String? value) {
    if (value == null) return null;
    return PromotionStatus.values.cast<PromotionStatus?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Teacher employment type.
enum EmploymentType {
  fullTime(value: 'full_time', label: 'Full Time'),
  partTime(value: 'part_time', label: 'Part Time'),
  contract(value: 'contract', label: 'Contract'),
  volunteer(value: 'volunteer', label: 'Volunteer'),
  intern(value: 'intern', label: 'Intern');

  const EmploymentType({required this.value, required this.label});

  final String value;
  final String label;

  static EmploymentType? fromString(String? value) {
    if (value == null) return null;
    return EmploymentType.values.cast<EmploymentType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Calendar event type.
enum CalendarEventType {
  holiday(value: 'holiday', label: 'Holiday', color: '#EF4444'),
  event(value: 'event', label: 'Event', color: '#3B82F6'),
  examPeriod(value: 'exam_period', label: 'Exam Period', color: '#F59E0B'),
  parentTeacherConference(value: 'parent_teacher_conference', label: 'PTA Meeting', color: '#8B5CF6'),
  staffMeeting(value: 'staff_meeting', label: 'Staff Meeting', color: '#6366F1'),
  sportsDay(value: 'sports_day', label: 'Sports Day', color: '#22C55E'),
  culturalDay(value: 'cultural_day', label: 'Cultural Day', color: '#EC4899'),
  graduation(value: 'graduation', label: 'Graduation', color: '#6366F1'),
  resumption(value: 'resumption', label: 'Resumption', color: '#22C55E'),
  midTermBreak(value: 'mid_term_break', label: 'Mid-Term Break', color: '#F59E0B');

  const CalendarEventType({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final String color;

  static CalendarEventType? fromString(String? value) {
    if (value == null) return null;
    return CalendarEventType.values.cast<CalendarEventType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// Extended school entity with branding and additional fields.
class SchoolEntity extends Equatable {
  const SchoolEntity({
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
    this.branches = const [],
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
  final List<SchoolBranchEntity> branches;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, name, code, email, isActive];

  SchoolEntity copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    String? motto,
    String? principalName,
    String? primaryColor,
    String? secondaryColor,
    String? customDomain,
    String? schoolType,
    String? schoolLevel,
    DateTime? establishedDate,
    String? registrationNumber,
    String? subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    int? maxStudents,
    int? maxTeachers,
    bool? isActive,
    Map<String, dynamic>? settings,
    List<SchoolBranchEntity>? branches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      motto: motto ?? this.motto,
      principalName: principalName ?? this.principalName,
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
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      branches: branches ?? this.branches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// School branch / campus entity.
class SchoolBranchEntity extends Equatable {
  const SchoolBranchEntity({
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

  @override
  List<Object?> get props => [id, schoolId, name, code];

  SchoolBranchEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? email,
    String? headName,
    bool? isActive,
    bool? isMainCampus,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolBranchEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      headName: headName ?? this.headName,
      isActive: isActive ?? this.isActive,
      isMainCampus: isMainCampus ?? this.isMainCampus,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Department entity within a school.
class DepartmentEntity extends Equatable {
  const DepartmentEntity({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.code,
    this.headTeacherId,
    this.headTeacherName,
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
  final String? headTeacherName;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, name, code];

  DepartmentEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? code,
    String? headTeacherId,
    String? headTeacherName,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      headTeacherId: headTeacherId ?? this.headTeacherId,
      headTeacherName: headTeacherName ?? this.headTeacherName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Extended student profile entity.
class StudentProfileEntity extends Equatable {
  const StudentProfileEntity({
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
    this.currentClassName,
    this.isActive = true,
    this.isGraduated = false,
    this.graduationDate,
    this.isAlumni = false,
    this.promotedToClassId,
    this.metadata = const {},
    this.parentLinks = const [],
    this.promotionHistory = const [],
    this.createdAt,
    this.updatedAt,
    // User-level fields
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
  final String? currentClassName;
  final bool isActive;
  final bool isGraduated;
  final DateTime? graduationDate;
  final bool isAlumni;
  final String? promotedToClassId;
  final Map<String, dynamic> metadata;
  final List<ParentStudentLinkEntity> parentLinks;
  final List<PromotionHistoryEntity> promotionHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // User-level fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, userId, schoolId, admissionNumber];

  StudentProfileEntity copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? admissionNumber,
    String? studentIdCardNumber,
    String? passportPhotoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? genotype,
    String? medicalConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? homeAddress,
    String? stateOfOrigin,
    String? localGovernment,
    String? nationality,
    String? religion,
    DateTime? admissionDate,
    String? currentClassId,
    String? currentClassName,
    bool? isActive,
    bool? isGraduated,
    DateTime? graduationDate,
    bool? isAlumni,
    String? promotedToClassId,
    Map<String, dynamic>? metadata,
    List<ParentStudentLinkEntity>? parentLinks,
    List<PromotionHistoryEntity>? promotionHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return StudentProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      studentIdCardNumber: studentIdCardNumber ?? this.studentIdCardNumber,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
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
      currentClassName: currentClassName ?? this.currentClassName,
      isActive: isActive ?? this.isActive,
      isGraduated: isGraduated ?? this.isGraduated,
      graduationDate: graduationDate ?? this.graduationDate,
      isAlumni: isAlumni ?? this.isAlumni,
      promotedToClassId: promotedToClassId ?? this.promotedToClassId,
      metadata: metadata ?? this.metadata,
      parentLinks: parentLinks ?? this.parentLinks,
      promotionHistory: promotionHistory ?? this.promotionHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// Extended teacher profile entity.
class TeacherProfileEntity extends Equatable {
  const TeacherProfileEntity({
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
    this.departmentName,
    this.employmentType = EmploymentType.fullTime,
    this.employmentStartDate,
    this.employmentEndDate,
    this.yearsOfExperience = 0,
    this.isHeadOfDepartment = false,
    this.isActive = true,
    this.metadata = const {},
    this.assignedSubjects = const [],
    this.assignedClasses = const [],
    this.createdAt,
    this.updatedAt,
    // User-level fields
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
  final String? departmentName;
  final EmploymentType employmentType;
  final DateTime? employmentStartDate;
  final DateTime? employmentEndDate;
  final int yearsOfExperience;
  final bool isHeadOfDepartment;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, userId, schoolId, employeeId];

  TeacherProfileEntity copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? employeeId,
    String? staffIdCardNumber,
    String? passportPhotoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? qualification,
    String? specialization,
    String? departmentId,
    String? departmentName,
    EmploymentType? employmentType,
    DateTime? employmentStartDate,
    DateTime? employmentEndDate,
    int? yearsOfExperience,
    bool? isHeadOfDepartment,
    bool? isActive,
    Map<String, dynamic>? metadata,
    List<String>? assignedSubjects,
    List<String>? assignedClasses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return TeacherProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      employeeId: employeeId ?? this.employeeId,
      staffIdCardNumber: staffIdCardNumber ?? this.staffIdCardNumber,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      employmentType: employmentType ?? this.employmentType,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      employmentEndDate: employmentEndDate ?? this.employmentEndDate,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      isHeadOfDepartment: isHeadOfDepartment ?? this.isHeadOfDepartment,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// Parent profile entity.
class ParentProfileEntity extends Equatable {
  const ParentProfileEntity({
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
    this.children = const [],
    this.createdAt,
    this.updatedAt,
    // User-level fields
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
  final List<ParentStudentLinkEntity> children;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, userId, schoolId];

  ParentProfileEntity copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? occupation,
    String? employer,
    String? homeAddress,
    String? officeAddress,
    String? relationshipType,
    bool? isActive,
    Map<String, dynamic>? metadata,
    List<ParentStudentLinkEntity>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return ParentProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      occupation: occupation ?? this.occupation,
      employer: employer ?? this.employer,
      homeAddress: homeAddress ?? this.homeAddress,
      officeAddress: officeAddress ?? this.officeAddress,
      relationshipType: relationshipType ?? this.relationshipType,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// Parent-student relationship link.
class ParentStudentLinkEntity extends Equatable {
  const ParentStudentLinkEntity({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.relationship = 'parent',
    this.isPrimaryContact = false,
    this.canPickup = true,
    // Denormalized for display
    this.parentName,
    this.studentName,
    this.studentAdmissionNumber,
  });

  final String id;
  final String parentId;
  final String studentId;
  final String relationship;
  final bool isPrimaryContact;
  final bool canPickup;
  final String? parentName;
  final String? studentName;
  final String? studentAdmissionNumber;

  @override
  List<Object?> get props => [id, parentId, studentId];

  ParentStudentLinkEntity copyWith({
    String? id,
    String? parentId,
    String? studentId,
    String? relationship,
    bool? isPrimaryContact,
    bool? canPickup,
    String? parentName,
    String? studentName,
    String? studentAdmissionNumber,
  }) {
    return ParentStudentLinkEntity(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      relationship: relationship ?? this.relationship,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      canPickup: canPickup ?? this.canPickup,
      parentName: parentName ?? this.parentName,
      studentName: studentName ?? this.studentName,
      studentAdmissionNumber: studentAdmissionNumber ?? this.studentAdmissionNumber,
    );
  }
}

/// Academic session entity.
class AcademicSessionEntity extends Equatable {
  const AcademicSessionEntity({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.sessionYear,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    this.isActive = true,
    this.settings = const {},
    this.terms = const [],
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
  final List<TermEntity> terms;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, sessionYear];

  AcademicSessionEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? sessionYear,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    bool? isActive,
    Map<String, dynamic>? settings,
    List<TermEntity>? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicSessionEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      sessionYear: sessionYear ?? this.sessionYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Term / Semester entity.
class TermEntity extends Equatable {
  const TermEntity({
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
    this.calendarEvents = const [],
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
  final List<CalendarEventEntity> calendarEvents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, academicSessionId, termNumber];

  TermEntity copyWith({
    String? id,
    String? academicSessionId,
    String? schoolId,
    String? name,
    TermType? termType,
    int? termNumber,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    TermStatus? status,
    Map<String, dynamic>? settings,
    List<CalendarEventEntity>? calendarEvents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TermEntity(
      id: id ?? this.id,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      termType: termType ?? this.termType,
      termNumber: termNumber ?? this.termNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// School calendar event entity.
class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
    required this.id,
    required this.schoolId,
    required this.title,
    this.termId,
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
  final String title;
  final String? termId;
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

  @override
  List<Object?> get props => [id, schoolId, title, startDate];

  CalendarEventEntity copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? termId,
    String? description,
    CalendarEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFullDay,
    bool? isRecurring,
    String? recurrenceRule,
    String? targetAudience,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      termId: termId ?? this.termId,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFullDay: isFullDay ?? this.isFullDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Timetable entity.
class TimetableEntity extends Equatable {
  const TimetableEntity({
    required this.id,
    required this.schoolId,
    required this.termId,
    required this.name,
    this.timetableType = 'class',
    this.classId,
    this.className,
    this.isActive = true,
    this.isPublished = false,
    this.createdBy,
    this.settings = const {},
    this.slots = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String termId;
  final String name;
  final String timetableType;
  final String? classId;
  final String? className;
  final bool isActive;
  final bool isPublished;
  final String? createdBy;
  final Map<String, dynamic> settings;
  final List<TimetableSlotEntity> slots;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, termId, name];

  TimetableEntity copyWith({
    String? id,
    String? schoolId,
    String? termId,
    String? name,
    String? timetableType,
    String? classId,
    String? className,
    bool? isActive,
    bool? isPublished,
    String? createdBy,
    Map<String, dynamic>? settings,
    List<TimetableSlotEntity>? slots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId,
      name: name ?? this.name,
      timetableType: timetableType ?? this.timetableType,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      slots: slots ?? this.slots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Individual timetable slot entity.
class TimetableSlotEntity extends Equatable {
  const TimetableSlotEntity({
    required this.id,
    required this.timetableId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.subjectId,
    this.subjectName,
    this.teacherId,
    this.teacherName,
    this.classroom,
    this.classId,
    this.className,
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
  final DateTime startTime;
  final DateTime endTime;
  final String? subjectId;
  final String? subjectName;
  final String? teacherId;
  final String? teacherName;
  final String? classroom;
  final String? classId;
  final String? className;
  final bool isBreak;
  final String? breakLabel;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, timetableId, dayOfWeek, periodNumber];

  TimetableSlotEntity copyWith({
    String? id,
    String? timetableId,
    DayOfWeek? dayOfWeek,
    int? periodNumber,
    DateTime? startTime,
    DateTime? endTime,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    String? classroom,
    String? classId,
    String? className,
    bool? isBreak,
    String? breakLabel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableSlotEntity(
      id: id ?? this.id,
      timetableId: timetableId ?? this.timetableId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periodNumber: periodNumber ?? this.periodNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classroom: classroom ?? this.classroom,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      isBreak: isBreak ?? this.isBreak,
      breakLabel: breakLabel ?? this.breakLabel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Attendance record entity (one per class per day).
class AttendanceRecordEntity extends Equatable {
  const AttendanceRecordEntity({
    required this.id,
    required this.schoolId,
    required this.termId,
    required this.classId,
    required this.date,
    this.attendanceType = 'student',
    this.subjectId,
    this.recordedBy,
    this.notes,
    this.entries = const [],
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
  final List<AttendanceEntryEntity> entries;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, classId, date, attendanceType];

  AttendanceRecordEntity copyWith({
    String? id,
    String? schoolId,
    String? termId,
    String? classId,
    DateTime? date,
    String? attendanceType,
    String? subjectId,
    String? recordedBy,
    String? notes,
    List<AttendanceEntryEntity>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecordEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      attendanceType: attendanceType ?? this.attendanceType,
      subjectId: subjectId ?? this.subjectId,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Individual attendance entry (per student/teacher).
class AttendanceEntryEntity extends Equatable {
  const AttendanceEntryEntity({
    required this.id,
    required this.attendanceRecordId,
    required this.userId,
    this.status = AttendanceStatus.present,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    // Denormalized for display
    this.userName,
    this.userAvatarUrl,
    this.admissionNumber,
  });

  final String id;
  final String attendanceRecordId;
  final String userId;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final String? userName;
  final String? userAvatarUrl;
  final String? admissionNumber;

  @override
  List<Object?> get props => [id, attendanceRecordId, userId];

  AttendanceEntryEntity copyWith({
    String? id,
    String? attendanceRecordId,
    String? userId,
    AttendanceStatus? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
    String? userName,
    String? userAvatarUrl,
    String? admissionNumber,
  }) {
    return AttendanceEntryEntity(
      id: id ?? this.id,
      attendanceRecordId: attendanceRecordId ?? this.attendanceRecordId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      admissionNumber: admissionNumber ?? this.admissionNumber,
    );
  }
}

/// Homework entity.
class HomeworkEntity extends Equatable {
  const HomeworkEntity({
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
    this.submissions = const [],
    // Denormalized
    this.className,
    this.subjectName,
    this.teacherName,
    this.submissionCount,
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
  final List<HomeworkSubmissionEntity> submissions;
  final String? className;
  final String? subjectName;
  final String? teacherName;
  final int? submissionCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, title];

  HomeworkEntity copyWith({
    String? id,
    String? schoolId,
    String? termId,
    String? classId,
    String? subjectId,
    String? teacherId,
    String? title,
    String? description,
    String? instructions,
    List<String>? attachmentUrls,
    double? totalMarks,
    DateTime? deadline,
    bool? allowLateSubmission,
    HomeworkStatus? status,
    bool? isPublished,
    Map<String, dynamic>? metadata,
    List<HomeworkSubmissionEntity>? submissions,
    String? className,
    String? subjectName,
    String? teacherName,
    int? submissionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeworkEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      termId: termId ?? this.termId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      totalMarks: totalMarks ?? this.totalMarks,
      deadline: deadline ?? this.deadline,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
      submissions: submissions ?? this.submissions,
      className: className ?? this.className,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
      submissionCount: submissionCount ?? this.submissionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Homework submission entity.
class HomeworkSubmissionEntity extends Equatable {
  const HomeworkSubmissionEntity({
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
    // Denormalized
    this.studentName,
    this.studentAvatarUrl,
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
  final String? studentName;
  final String? studentAvatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, homeworkId, studentId];

  HomeworkSubmissionEntity copyWith({
    String? id,
    String? homeworkId,
    String? studentId,
    String? content,
    List<String>? attachmentUrls,
    SubmissionStatus? status,
    DateTime? submittedAt,
    double? marksAwarded,
    double? maxMarks,
    String? teacherComment,
    String? gradedBy,
    DateTime? gradedAt,
    bool? isLate,
    Map<String, dynamic>? metadata,
    String? studentName,
    String? studentAvatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeworkSubmissionEntity(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      maxMarks: maxMarks ?? this.maxMarks,
      teacherComment: teacherComment ?? this.teacherComment,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      isLate: isLate ?? this.isLate,
      metadata: metadata ?? this.metadata,
      studentName: studentName ?? this.studentName,
      studentAvatarUrl: studentAvatarUrl ?? this.studentAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Announcement entity.
class AnnouncementEntity extends Equatable {
  const AnnouncementEntity({
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
    this.createdByName,
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
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, title];

  AnnouncementEntity copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? content,
    AnnouncementType? announcementType,
    AnnouncementPriority? priority,
    String? targetAudience,
    List<String>? targetClassIds,
    List<String>? attachmentUrls,
    bool? isPinned,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? expiresAt,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      content: content ?? this.content,
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
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Document entity for the document center.
class DocumentEntity extends Equatable {
  const DocumentEntity({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.fileUrl,
    required this.fileName,
    this.description,
    this.documentType = DocumentType.general,
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
  final String fileUrl;
  final String fileName;
  final String? description;
  final DocumentType documentType;
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

  @override
  List<Object?> get props => [id, schoolId, title, fileUrl];

  DocumentEntity copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? fileUrl,
    String? fileName,
    String? description,
    DocumentType? documentType,
    int? fileSize,
    String? mimeType,
    String? category,
    List<String>? tags,
    bool? isPublic,
    bool? downloadable,
    String? targetAudience,
    String? uploadedBy,
    String? studentId,
    int? downloadCount,
    int? version,
    String? parentDocumentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      description: description ?? this.description,
      documentType: documentType ?? this.documentType,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      downloadable: downloadable ?? this.downloadable,
      targetAudience: targetAudience ?? this.targetAudience,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      studentId: studentId ?? this.studentId,
      downloadCount: downloadCount ?? this.downloadCount,
      version: version ?? this.version,
      parentDocumentId: parentDocumentId ?? this.parentDocumentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Promotion history entity.
class PromotionHistoryEntity extends Equatable {
  const PromotionHistoryEntity({
    required this.id,
    required this.studentId,
    required this.schoolId,
    this.fromClassId,
    this.fromClassName,
    this.toClassId,
    this.toClassName,
    this.academicSessionId,
    this.sessionYear,
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
  final String? fromClassName;
  final String? toClassId;
  final String? toClassName;
  final String? academicSessionId;
  final String? sessionYear;
  final String? termId;
  final PromotionStatus promotionStatus;
  final double? averageScore;
  final String? classTeacherComment;
  final String? principalComment;
  final String? promotedBy;
  final DateTime? promotedAt;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, studentId, schoolId, promotionStatus];

  PromotionHistoryEntity copyWith({
    String? id,
    String? studentId,
    String? schoolId,
    String? fromClassId,
    String? fromClassName,
    String? toClassId,
    String? toClassName,
    String? academicSessionId,
    String? sessionYear,
    String? termId,
    PromotionStatus? promotionStatus,
    double? averageScore,
    String? classTeacherComment,
    String? principalComment,
    String? promotedBy,
    DateTime? promotedAt,
    DateTime? createdAt,
  }) {
    return PromotionHistoryEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      fromClassId: fromClassId ?? this.fromClassId,
      fromClassName: fromClassName ?? this.fromClassName,
      toClassId: toClassId ?? this.toClassId,
      toClassName: toClassName ?? this.toClassName,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      sessionYear: sessionYear ?? this.sessionYear,
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
}

/// Attendance summary for reports.
class AttendanceSummaryEntity extends Equatable {
  const AttendanceSummaryEntity({
    required this.classId,
    required this.termId,
    this.className,
    this.totalStudents = 0,
    this.totalDays = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.averageAttendanceRate = 0.0,
    this.topAttendees = const [],
    this.lowAttendees = const [],
  });

  final String classId;
  final String termId;
  final String? className;
  final int totalStudents;
  final int totalDays;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double averageAttendanceRate;
  final List<StudentAttendanceDetail> topAttendees;
  final List<StudentAttendanceDetail> lowAttendees;

  @override
  List<Object?> get props => [classId, termId];
}

/// Individual student attendance detail for reports.
class StudentAttendanceDetail extends Equatable {
  const StudentAttendanceDetail({
    required this.studentId,
    this.studentName,
    this.admissionNumber,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.excusedDays = 0,
    this.attendanceRate = 0.0,
  });

  final String studentId;
  final String? studentName;
  final String? admissionNumber;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final double attendanceRate;

  @override
  List<Object?> get props => [studentId];
}

/// Class entity (enhanced with school management fields).
class ClassEntity extends Equatable {
  const ClassEntity({
    required this.id,
    required this.name,
    this.section,
    required this.schoolId,
    this.teacherId,
    this.teacherName,
    this.academicYear,
    this.gradeLevel,
    this.capacity = 40,
    this.isActive = true,
    this.studentCount = 0,
    this.subjects = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? section;
  final String schoolId;
  final String? teacherId;
  final String? teacherName;
  final String? academicYear;
  final String? gradeLevel;
  final int capacity;
  final bool isActive;
  final int studentCount;
  final List<String> subjects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, schoolId, name];

  ClassEntity copyWith({
    String? id,
    String? name,
    String? section,
    String? schoolId,
    String? teacherId,
    String? teacherName,
    String? academicYear,
    String? gradeLevel,
    int? capacity,
    bool? isActive,
    int? studentCount,
    List<String>? subjects,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      section: section ?? this.section,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      academicYear: academicYear ?? this.academicYear,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      studentCount: studentCount ?? this.studentCount,
      subjects: subjects ?? this.subjects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Subject entity (enhanced with school management fields).
class SubjectEntity extends Equatable {
  const SubjectEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.schoolId,
    this.category,
    this.iconUrl,
    this.isActive = true,
    this.isCompulsory = true,
    this.isElective = false,
    this.assignedTeacherIds = const [],
    this.assignedClassIds = const [],
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
  final bool isCompulsory;
  final bool isElective;
  final List<String> assignedTeacherIds;
  final List<String> assignedClassIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, name, code];

  SubjectEntity copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? schoolId,
    String? category,
    String? iconUrl,
    bool? isActive,
    bool? isCompulsory,
    bool? isElective,
    List<String>? assignedTeacherIds,
    List<String>? assignedClassIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      isCompulsory: isCompulsory ?? this.isCompulsory,
      isElective: isElective ?? this.isElective,
      assignedTeacherIds: assignedTeacherIds ?? this.assignedTeacherIds,
      assignedClassIds: assignedClassIds ?? this.assignedClassIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
