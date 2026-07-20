import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Categories of educational levels in the system.
enum EducationalLevelCategory {
  earlyChildhood(value: 'early_childhood', label: 'Early Childhood'),
  primary(value: 'primary', label: 'Primary'),
  juniorSecondary(value: 'junior_secondary', label: 'Junior Secondary'),
  seniorSecondary(value: 'senior_secondary', label: 'Senior Secondary'),
  technical(value: 'technical', label: 'Technical'),
  tertiaryCollege(value: 'tertiary_college', label: 'Tertiary College'),
  tertiaryUniversity(value: 'tertiary_university', label: 'Tertiary University');

  const EducationalLevelCategory({required this.value, required this.label});
  final String value;
  final String label;

  static EducationalLevelCategory? fromString(String? value) {
    if (value == null) return null;
    return EducationalLevelCategory.values.cast<EducationalLevelCategory?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Types of curricula supported by the system.
enum CurriculumType {
  nerdc(value: 'nerdc', label: 'NERDC'),
  waec(value: 'waec', label: 'WAEC'),
  neco(value: 'neco', label: 'NECO'),
  nabteb(value: 'nabteb', label: 'NABTEB'),
  custom(value: 'custom', label: 'Custom'),
  international(value: 'international', label: 'International');

  const CurriculumType({required this.value, required this.label});
  final String value;
  final String label;

  static CurriculumType? fromString(String? value) {
    if (value == null) return null;
    return CurriculumType.values.cast<CurriculumType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Status of content items in the system.
enum ContentStatus {
  draft(value: 'draft', label: 'Draft'),
  review(value: 'review', label: 'Review'),
  published(value: 'published', label: 'Published'),
  archived(value: 'archived', label: 'Archived'),
  deprecated(value: 'deprecated', label: 'Deprecated');

  const ContentStatus({required this.value, required this.label});
  final String value;
  final String label;

  static ContentStatus? fromString(String? value) {
    if (value == null) return null;
    return ContentStatus.values.cast<ContentStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Types of content that can be created in the CCMS.
enum ContentType {
  question(value: 'question', label: 'Question'),
  explanation(value: 'explanation', label: 'Explanation'),
  markingScheme(value: 'marking_scheme', label: 'Marking Scheme'),
  teacherNote(value: 'teacher_note', label: 'Teacher Note'),
  lessonNote(value: 'lesson_note', label: 'Lesson Note'),
  worksheet(value: 'worksheet', label: 'Worksheet'),
  practicalGuide(value: 'practical_guide', label: 'Practical Guide'),
  readingMaterial(value: 'reading_material', label: 'Reading Material'),
  videoScript(value: 'video_script', label: 'Video Script'),
  assessmentRubric(value: 'assessment_rubric', label: 'Assessment Rubric');

  const ContentType({required this.value, required this.label});
  final String value;
  final String label;

  static ContentType? fromString(String? value) {
    if (value == null) return null;
    return ContentType.values.cast<ContentType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Categories of questions for assessment content.
enum QuestionCategory {
  objective(value: 'objective', label: 'Objective'),
  theory(value: 'theory', label: 'Theory'),
  practical(value: 'practical', label: 'Practical'),
  oral(value: 'oral', label: 'Oral'),
  project(value: 'project', label: 'Project'),
  essay(value: 'essay', label: 'Essay'),
  fillInBlank(value: 'fill_in_blank', label: 'Fill in Blank'),
  trueFalse(value: 'true_false', label: 'True/False'),
  matching(value: 'matching', label: 'Matching'),
  ordering(value: 'ordering', label: 'Ordering'),
  multipleChoice(value: 'multiple_choice', label: 'Multiple Choice');

  const QuestionCategory({required this.value, required this.label});
  final String value;
  final String label;

  static QuestionCategory? fromString(String? value) {
    if (value == null) return null;
    return QuestionCategory.values.cast<QuestionCategory?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Difficulty levels for content items.
enum DifficultyLevel {
  beginner(value: 'beginner', label: 'Beginner'),
  elementary(value: 'elementary', label: 'Elementary'),
  intermediate(value: 'intermediate', label: 'Intermediate'),
  advanced(value: 'advanced', label: 'Advanced'),
  expert(value: 'expert', label: 'Expert');

  const DifficultyLevel({required this.value, required this.label});
  final String value;
  final String label;

  static DifficultyLevel? fromString(String? value) {
    if (value == null) return null;
    return DifficultyLevel.values.cast<DifficultyLevel?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Bloom's Taxonomy cognitive levels.
enum BloomTaxonomy {
  remember(value: 'remember', label: 'Remember'),
  understand(value: 'understand', label: 'Understand'),
  apply(value: 'apply', label: 'Apply'),
  analyze(value: 'analyze', label: 'Analyze'),
  evaluate(value: 'evaluate', label: 'Evaluate'),
  create(value: 'create', label: 'Create');

  const BloomTaxonomy({required this.value, required this.label});
  final String value;
  final String label;

  static BloomTaxonomy? fromString(String? value) {
    if (value == null) return null;
    return BloomTaxonomy.values.cast<BloomTaxonomy?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Status of content import operations.
enum ImportStatus {
  pending(value: 'pending', label: 'Pending'),
  processing(value: 'processing', label: 'Processing'),
  completed(value: 'completed', label: 'Completed'),
  failed(value: 'failed', label: 'Failed'),
  partiallyCompleted(value: 'partially_completed', label: 'Partially Completed');

  const ImportStatus({required this.value, required this.label});
  final String value;
  final String label;

  static ImportStatus? fromString(String? value) {
    if (value == null) return null;
    return ImportStatus.values.cast<ImportStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Supported MFA methods.
enum MfaMethod {
  sms(value: 'sms', label: 'SMS'),
  email(value: 'email', label: 'Email'),
  authenticatorApp(value: 'authenticator_app', label: 'Authenticator App'),
  hardwareKey(value: 'hardware_key', label: 'Hardware Key');

  const MfaMethod({required this.value, required this.label});
  final String value;
  final String label;

  static MfaMethod? fromString(String? value) {
    if (value == null) return null;
    return MfaMethod.values.cast<MfaMethod?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Types of audit actions that can be recorded.
enum AuditAction {
  create(value: 'create', label: 'Create'),
  read(value: 'read', label: 'Read'),
  update(value: 'update', label: 'Update'),
  delete(value: 'delete', label: 'Delete'),
  login(value: 'login', label: 'Login'),
  logout(value: 'logout', label: 'Logout'),
  export(value: 'export', label: 'Export'),
  import(value: 'import', label: 'Import'),
  approve(value: 'approve', label: 'Approve'),
  reject(value: 'reject', label: 'Reject'),
  archive(value: 'archive', label: 'Archive'),
  restore(value: 'restore', label: 'Restore'),
  permissionChange(value: 'permission_change', label: 'Permission Change'),
  roleChange(value: 'role_change', label: 'Role Change'),
  passwordChange(value: 'password_change', label: 'Password Change'),
  mfaEnable(value: 'mfa_enable', label: 'MFA Enable'),
  mfaDisable(value: 'mfa_disable', label: 'MFA Disable'),
  sessionInvalidate(value: 'session_invalidate', label: 'Session Invalidate'),
  apiKeyCreate(value: 'api_key_create', label: 'API Key Create'),
  apiKeyRevoke(value: 'api_key_revoke', label: 'API Key Revoke');

  const AuditAction({required this.value, required this.label});
  final String value;
  final String label;

  static AuditAction? fromString(String? value) {
    if (value == null) return null;
    return AuditAction.values.cast<AuditAction?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Severity levels for system alerts.
enum AlertSeverity {
  info(value: 'info', label: 'Info'),
  warning(value: 'warning', label: 'Warning'),
  critical(value: 'critical', label: 'Critical'),
  emergency(value: 'emergency', label: 'Emergency');

  const AlertSeverity({required this.value, required this.label});
  final String value;
  final String label;

  static AlertSeverity? fromString(String? value) {
    if (value == null) return null;
    return AlertSeverity.values.cast<AlertSeverity?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Status of deployment operations.
enum DeploymentStatus {
  pending(value: 'pending', label: 'Pending'),
  running(value: 'running', label: 'Running'),
  success(value: 'success', label: 'Success'),
  failed(value: 'failed', label: 'Failed'),
  rolledBack(value: 'rolled_back', label: 'Rolled Back');

  const DeploymentStatus({required this.value, required this.label});
  final String value;
  final String label;

  static DeploymentStatus? fromString(String? value) {
    if (value == null) return null;
    return DeploymentStatus.values.cast<DeploymentStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Types of automated tests.
enum TestType {
  unit(value: 'unit', label: 'Unit'),
  widget(value: 'widget', label: 'Widget'),
  integration(value: 'integration', label: 'Integration'),
  e2e(value: 'e2e', label: 'E2E'),
  load(value: 'load', label: 'Load'),
  security(value: 'security', label: 'Security'),
  performance(value: 'performance', label: 'Performance');

  const TestType({required this.value, required this.label});
  final String value;
  final String label;

  static TestType? fromString(String? value) {
    if (value == null) return null;
    return TestType.values.cast<TestType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Scopes for rate limiting configuration.
enum RateLimitScope {
  global(value: 'global', label: 'Global'),
  perUser(value: 'per_user', label: 'Per User'),
  perIp(value: 'per_ip', label: 'Per IP'),
  perApiKey(value: 'per_api_key', label: 'Per API Key'),
  perEndpoint(value: 'per_endpoint', label: 'Per Endpoint');

  const RateLimitScope({required this.value, required this.label});
  final String value;
  final String label;

  static RateLimitScope? fromString(String? value) {
    if (value == null) return null;
    return RateLimitScope.values.cast<RateLimitScope?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Types of system metrics.
enum MetricType {
  counter(value: 'counter', label: 'Counter'),
  gauge(value: 'gauge', label: 'Gauge'),
  histogram(value: 'histogram', label: 'Histogram'),
  summary(value: 'summary', label: 'Summary');

  const MetricType({required this.value, required this.label});
  final String value;
  final String label;

  static MetricType? fromString(String? value) {
    if (value == null) return null;
    return MetricType.values.cast<MetricType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// Represents an educational level in the curriculum hierarchy.
class EducationalLevel extends Equatable {
  const EducationalLevel({
    required this.id,
    required this.code,
    required this.name,
    required this.levelCategory,
    required this.levelOrder,
    this.minAge,
    this.maxAge,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final EducationalLevelCategory levelCategory;
  final int levelOrder;
  final int? minAge;
  final int? maxAge;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EducationalLevel copyWith({
    String? id,
    String? code,
    String? name,
    EducationalLevelCategory? levelCategory,
    int? levelOrder,
    int? minAge,
    int? maxAge,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationalLevel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      levelCategory: levelCategory ?? this.levelCategory,
      levelOrder: levelOrder ?? this.levelOrder,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        levelCategory,
        levelOrder,
        minAge,
        maxAge,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Configuration for a school's educational level.
class SchoolLevelConfiguration extends Equatable {
  const SchoolLevelConfiguration({
    required this.id,
    required this.schoolId,
    required this.educationalLevelId,
    required this.isEnabled,
    this.customName,
    this.academicYearStart,
    this.academicYearEnd,
    this.maxStudentsPerClass,
    this.gradingSystem,
    this.configuration,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String educationalLevelId;
  final bool isEnabled;
  final String? customName;
  final String? academicYearStart;
  final String? academicYearEnd;
  final int? maxStudentsPerClass;
  final Map<String, dynamic>? gradingSystem;
  final Map<String, dynamic>? configuration;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolLevelConfiguration copyWith({
    String? id,
    String? schoolId,
    String? educationalLevelId,
    bool? isEnabled,
    String? customName,
    String? academicYearStart,
    String? academicYearEnd,
    int? maxStudentsPerClass,
    Map<String, dynamic>? gradingSystem,
    Map<String, dynamic>? configuration,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolLevelConfiguration(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      isEnabled: isEnabled ?? this.isEnabled,
      customName: customName ?? this.customName,
      academicYearStart: academicYearStart ?? this.academicYearStart,
      academicYearEnd: academicYearEnd ?? this.academicYearEnd,
      maxStudentsPerClass: maxStudentsPerClass ?? this.maxStudentsPerClass,
      gradingSystem: gradingSystem ?? this.gradingSystem,
      configuration: configuration ?? this.configuration,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        educationalLevelId,
        isEnabled,
        customName,
        academicYearStart,
        academicYearEnd,
        maxStudentsPerClass,
        gradingSystem,
        configuration,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a curriculum standard (e.g., NERDC, WAEC).
class Curriculum extends Equatable {
  const Curriculum({
    required this.id,
    required this.name,
    required this.code,
    required this.curriculumType,
    required this.countryCode,
    this.description,
    this.publisher,
    this.edition,
    this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    this.parentCurriculumId,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final CurriculumType curriculumType;
  final String countryCode;
  final String? description;
  final String? publisher;
  final String? edition;
  final DateTime? effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final String? parentCurriculumId;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Curriculum copyWith({
    String? id,
    String? name,
    String? code,
    CurriculumType? curriculumType,
    String? countryCode,
    String? description,
    String? publisher,
    String? edition,
    DateTime? effectiveDate,
    DateTime? expiryDate,
    bool? isActive,
    String? parentCurriculumId,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Curriculum(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      curriculumType: curriculumType ?? this.curriculumType,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      edition: edition ?? this.edition,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      parentCurriculumId: parentCurriculumId ?? this.parentCurriculumId,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        curriculumType,
        countryCode,
        description,
        publisher,
        edition,
        effectiveDate,
        expiryDate,
        isActive,
        parentCurriculumId,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a version of a curriculum for change tracking.
class CurriculumVersion extends Equatable {
  const CurriculumVersion({
    required this.id,
    required this.curriculumId,
    required this.versionNumber,
    required this.changeSummary,
    this.changelog,
    required this.isCurrent,
    this.publishedAt,
    this.publishedBy,
    required this.createdAt,
  });

  final String id;
  final String curriculumId;
  final int versionNumber;
  final String changeSummary;
  final String? changelog;
  final bool isCurrent;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime createdAt;

  CurriculumVersion copyWith({
    String? id,
    String? curriculumId,
    int? versionNumber,
    String? changeSummary,
    String? changelog,
    bool? isCurrent,
    DateTime? publishedAt,
    String? publishedBy,
    DateTime? createdAt,
  }) {
    return CurriculumVersion(
      id: id ?? this.id,
      curriculumId: curriculumId ?? this.curriculumId,
      versionNumber: versionNumber ?? this.versionNumber,
      changeSummary: changeSummary ?? this.changeSummary,
      changelog: changelog ?? this.changelog,
      isCurrent: isCurrent ?? this.isCurrent,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        curriculumId,
        versionNumber,
        changeSummary,
        changelog,
        isCurrent,
        publishedAt,
        publishedBy,
        createdAt,
      ];
}

/// Maps which educational levels apply to a curriculum.
class CurriculumLevelMapping extends Equatable {
  const CurriculumLevelMapping({
    required this.id,
    required this.curriculumId,
    required this.educationalLevelId,
    required this.isApplicable,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String curriculumId;
  final String educationalLevelId;
  final bool isApplicable;
  final String? notes;
  final DateTime createdAt;

  CurriculumLevelMapping copyWith({
    String? id,
    String? curriculumId,
    String? educationalLevelId,
    bool? isApplicable,
    String? notes,
    DateTime? createdAt,
  }) {
    return CurriculumLevelMapping(
      id: id ?? this.id,
      curriculumId: curriculumId ?? this.curriculumId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      isApplicable: isApplicable ?? this.isApplicable,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        curriculumId,
        educationalLevelId,
        isApplicable,
        notes,
        createdAt,
      ];
}

/// Represents a subject within the curriculum.
class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.curriculumId,
    required this.educationalLevelId,
    this.schoolId,
    this.subjectGroup,
    required this.isCore,
    required this.isElective,
    required this.isVocational,
    this.languageOfInstruction,
    this.description,
    this.iconUrl,
    this.colorCode,
    required this.sortOrder,
    required this.isActive,
    required this.isCustom,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String curriculumId;
  final String educationalLevelId;
  final String? schoolId;
  final String? subjectGroup;
  final bool isCore;
  final bool isElective;
  final bool isVocational;
  final String? languageOfInstruction;
  final String? description;
  final String? iconUrl;
  final String? colorCode;
  final int sortOrder;
  final bool isActive;
  final bool isCustom;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? curriculumId,
    String? educationalLevelId,
    String? schoolId,
    String? subjectGroup,
    bool? isCore,
    bool? isElective,
    bool? isVocational,
    String? languageOfInstruction,
    String? description,
    String? iconUrl,
    String? colorCode,
    int? sortOrder,
    bool? isActive,
    bool? isCustom,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      curriculumId: curriculumId ?? this.curriculumId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      schoolId: schoolId ?? this.schoolId,
      subjectGroup: subjectGroup ?? this.subjectGroup,
      isCore: isCore ?? this.isCore,
      isElective: isElective ?? this.isElective,
      isVocational: isVocational ?? this.isVocational,
      languageOfInstruction: languageOfInstruction ?? this.languageOfInstruction,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      colorCode: colorCode ?? this.colorCode,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        curriculumId,
        educationalLevelId,
        schoolId,
        subjectGroup,
        isCore,
        isElective,
        isVocational,
        languageOfInstruction,
        description,
        iconUrl,
        colorCode,
        sortOrder,
        isActive,
        isCustom,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a topic within a subject.
class Topic extends Equatable {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.educationalLevelId,
    required this.curriculumId,
    required this.title,
    required this.code,
    this.description,
    required this.sortOrder,
    this.estimatedDurationMinutes,
    this.iconUrl,
    this.parentTopicId,
    required this.depthLevel,
    required this.isActive,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  final String educationalLevelId;
  final String curriculumId;
  final String title;
  final String code;
  final String? description;
  final int sortOrder;
  final int? estimatedDurationMinutes;
  final String? iconUrl;
  final String? parentTopicId;
  final int depthLevel;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic copyWith({
    String? id,
    String? subjectId,
    String? educationalLevelId,
    String? curriculumId,
    String? title,
    String? code,
    String? description,
    int? sortOrder,
    int? estimatedDurationMinutes,
    String? iconUrl,
    String? parentTopicId,
    int? depthLevel,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      curriculumId: curriculumId ?? this.curriculumId,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      iconUrl: iconUrl ?? this.iconUrl,
      parentTopicId: parentTopicId ?? this.parentTopicId,
      depthLevel: depthLevel ?? this.depthLevel,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subjectId,
        educationalLevelId,
        curriculumId,
        title,
        code,
        description,
        sortOrder,
        estimatedDurationMinutes,
        iconUrl,
        parentTopicId,
        depthLevel,
        isActive,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a subtopic within a topic.
class Subtopic extends Equatable {
  const Subtopic({
    required this.id,
    required this.topicId,
    required this.title,
    required this.code,
    this.description,
    required this.sortOrder,
    this.estimatedDurationMinutes,
    required this.isActive,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String title;
  final String code;
  final String? description;
  final int sortOrder;
  final int? estimatedDurationMinutes;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subtopic copyWith({
    String? id,
    String? topicId,
    String? title,
    String? code,
    String? description,
    int? sortOrder,
    int? estimatedDurationMinutes,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subtopic(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        topicId,
        title,
        code,
        description,
        sortOrder,
        estimatedDurationMinutes,
        isActive,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a learning objective tied to topics/subtopics.
class LearningObjective extends Equatable {
  const LearningObjective({
    required this.id,
    required this.topicId,
    this.subtopicId,
    required this.subjectId,
    required this.educationalLevelId,
    required this.code,
    required this.description,
    required this.bloomLevel,
    required this.isAssessable,
    required this.sortOrder,
    required this.isActive,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String? subtopicId;
  final String subjectId;
  final String educationalLevelId;
  final String code;
  final String description;
  final BloomTaxonomy bloomLevel;
  final bool isAssessable;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningObjective copyWith({
    String? id,
    String? topicId,
    String? subtopicId,
    String? subjectId,
    String? educationalLevelId,
    String? code,
    String? description,
    BloomTaxonomy? bloomLevel,
    bool? isAssessable,
    int? sortOrder,
    bool? isActive,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningObjective(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      code: code ?? this.code,
      description: description ?? this.description,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      isAssessable: isAssessable ?? this.isAssessable,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        topicId,
        subtopicId,
        subjectId,
        educationalLevelId,
        code,
        description,
        bloomLevel,
        isAssessable,
        sortOrder,
        isActive,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a content item in the CCMS.
class ContentItem extends Equatable {
  const ContentItem({
    required this.id,
    required this.title,
    required this.contentType,
    required this.subjectId,
    required this.educationalLevelId,
    this.topicId,
    this.subtopicId,
    this.curriculumId,
    this.schoolId,
    this.questionCategory,
    this.difficultyLevel,
    this.bloomLevel,
    required this.body,
    this.bodyRich,
    this.options,
    this.correctAnswer,
    this.stepByStepExplanation,
    this.markingScheme,
    this.teacherNotes,
    this.learningObjectiveIds,
    this.curriculumReferences,
    this.marksAllocated,
    this.timeAllocatedSeconds,
    this.sourceType,
    this.sourceReference,
    this.isPastQuestion,
    this.pastExamYear,
    this.pastExamBody,
    this.hasLicensingRights,
    this.licenseDetails,
    this.tags,
    this.mediaUrls,
    required this.status,
    required this.version,
    this.parentContentId,
    this.reviewCount,
    this.averageQualityScore,
    this.usageCount,
    this.isAiGenerated,
    this.aiGenerationMetadata,
    this.metadata,
    this.createdBy,
    this.reviewedBy,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final ContentType contentType;
  final String subjectId;
  final String educationalLevelId;
  final String? topicId;
  final String? subtopicId;
  final String? curriculumId;
  final String? schoolId;
  final QuestionCategory? questionCategory;
  final DifficultyLevel? difficultyLevel;
  final BloomTaxonomy? bloomLevel;
  final String body;
  final Map<String, dynamic>? bodyRich;
  final List<Map<String, dynamic>>? options;
  final Map<String, dynamic>? correctAnswer;
  final String? stepByStepExplanation;
  final Map<String, dynamic>? markingScheme;
  final String? teacherNotes;
  final List<String>? learningObjectiveIds;
  final List<Map<String, dynamic>>? curriculumReferences;
  final int? marksAllocated;
  final int? timeAllocatedSeconds;
  final String? sourceType;
  final String? sourceReference;
  final bool? isPastQuestion;
  final String? pastExamYear;
  final String? pastExamBody;
  final bool? hasLicensingRights;
  final Map<String, dynamic>? licenseDetails;
  final List<String>? tags;
  final List<Map<String, dynamic>>? mediaUrls;
  final ContentStatus status;
  final int version;
  final String? parentContentId;
  final int? reviewCount;
  final double? averageQualityScore;
  final int? usageCount;
  final bool? isAiGenerated;
  final Map<String, dynamic>? aiGenerationMetadata;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final String? reviewedBy;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentItem copyWith({
    String? id,
    String? title,
    ContentType? contentType,
    String? subjectId,
    String? educationalLevelId,
    String? topicId,
    String? subtopicId,
    String? curriculumId,
    String? schoolId,
    QuestionCategory? questionCategory,
    DifficultyLevel? difficultyLevel,
    BloomTaxonomy? bloomLevel,
    String? body,
    Map<String, dynamic>? bodyRich,
    List<Map<String, dynamic>>? options,
    Map<String, dynamic>? correctAnswer,
    String? stepByStepExplanation,
    Map<String, dynamic>? markingScheme,
    String? teacherNotes,
    List<String>? learningObjectiveIds,
    List<Map<String, dynamic>>? curriculumReferences,
    int? marksAllocated,
    int? timeAllocatedSeconds,
    String? sourceType,
    String? sourceReference,
    bool? isPastQuestion,
    String? pastExamYear,
    String? pastExamBody,
    bool? hasLicensingRights,
    Map<String, dynamic>? licenseDetails,
    List<String>? tags,
    List<Map<String, dynamic>>? mediaUrls,
    ContentStatus? status,
    int? version,
    String? parentContentId,
    int? reviewCount,
    double? averageQualityScore,
    int? usageCount,
    bool? isAiGenerated,
    Map<String, dynamic>? aiGenerationMetadata,
    Map<String, dynamic>? metadata,
    String? createdBy,
    String? reviewedBy,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      curriculumId: curriculumId ?? this.curriculumId,
      schoolId: schoolId ?? this.schoolId,
      questionCategory: questionCategory ?? this.questionCategory,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      body: body ?? this.body,
      bodyRich: bodyRich ?? this.bodyRich,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      stepByStepExplanation: stepByStepExplanation ?? this.stepByStepExplanation,
      markingScheme: markingScheme ?? this.markingScheme,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      learningObjectiveIds: learningObjectiveIds ?? this.learningObjectiveIds,
      curriculumReferences: curriculumReferences ?? this.curriculumReferences,
      marksAllocated: marksAllocated ?? this.marksAllocated,
      timeAllocatedSeconds: timeAllocatedSeconds ?? this.timeAllocatedSeconds,
      sourceType: sourceType ?? this.sourceType,
      sourceReference: sourceReference ?? this.sourceReference,
      isPastQuestion: isPastQuestion ?? this.isPastQuestion,
      pastExamYear: pastExamYear ?? this.pastExamYear,
      pastExamBody: pastExamBody ?? this.pastExamBody,
      hasLicensingRights: hasLicensingRights ?? this.hasLicensingRights,
      licenseDetails: licenseDetails ?? this.licenseDetails,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      status: status ?? this.status,
      version: version ?? this.version,
      parentContentId: parentContentId ?? this.parentContentId,
      reviewCount: reviewCount ?? this.reviewCount,
      averageQualityScore: averageQualityScore ?? this.averageQualityScore,
      usageCount: usageCount ?? this.usageCount,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiGenerationMetadata: aiGenerationMetadata ?? this.aiGenerationMetadata,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        contentType,
        subjectId,
        educationalLevelId,
        topicId,
        subtopicId,
        curriculumId,
        schoolId,
        questionCategory,
        difficultyLevel,
        bloomLevel,
        body,
        bodyRich,
        options,
        correctAnswer,
        stepByStepExplanation,
        markingScheme,
        teacherNotes,
        learningObjectiveIds,
        curriculumReferences,
        marksAllocated,
        timeAllocatedSeconds,
        sourceType,
        sourceReference,
        isPastQuestion,
        pastExamYear,
        pastExamBody,
        hasLicensingRights,
        licenseDetails,
        tags,
        mediaUrls,
        status,
        version,
        parentContentId,
        reviewCount,
        averageQualityScore,
        usageCount,
        isAiGenerated,
        aiGenerationMetadata,
        metadata,
        createdBy,
        reviewedBy,
        publishedAt,
        createdAt,
        updatedAt,
      ];
}

/// Represents a version snapshot of a content item.
class ContentVersion extends Equatable {
  const ContentVersion({
    required this.id,
    required this.contentItemId,
    required this.versionNumber,
    required this.title,
    required this.body,
    this.bodyRich,
    this.options,
    this.correctAnswer,
    this.stepByStepExplanation,
    this.markingScheme,
    this.teacherNotes,
    this.difficultyLevel,
    this.bloomLevel,
    required this.changeSummary,
    this.changedFields,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String contentItemId;
  final int versionNumber;
  final String title;
  final String body;
  final Map<String, dynamic>? bodyRich;
  final List<Map<String, dynamic>>? options;
  final Map<String, dynamic>? correctAnswer;
  final String? stepByStepExplanation;
  final Map<String, dynamic>? markingScheme;
  final String? teacherNotes;
  final DifficultyLevel? difficultyLevel;
  final BloomTaxonomy? bloomLevel;
  final String changeSummary;
  final List<String>? changedFields;
  final String? createdBy;
  final DateTime createdAt;

  ContentVersion copyWith({
    String? id,
    String? contentItemId,
    int? versionNumber,
    String? title,
    String? body,
    Map<String, dynamic>? bodyRich,
    List<Map<String, dynamic>>? options,
    Map<String, dynamic>? correctAnswer,
    String? stepByStepExplanation,
    Map<String, dynamic>? markingScheme,
    String? teacherNotes,
    DifficultyLevel? difficultyLevel,
    BloomTaxonomy? bloomLevel,
    String? changeSummary,
    List<String>? changedFields,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ContentVersion(
      id: id ?? this.id,
      contentItemId: contentItemId ?? this.contentItemId,
      versionNumber: versionNumber ?? this.versionNumber,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyRich: bodyRich ?? this.bodyRich,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      stepByStepExplanation: stepByStepExplanation ?? this.stepByStepExplanation,
      markingScheme: markingScheme ?? this.markingScheme,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      changeSummary: changeSummary ?? this.changeSummary,
      changedFields: changedFields ?? this.changedFields,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentItemId,
        versionNumber,
        title,
        body,
        bodyRich,
        options,
        correctAnswer,
        stepByStepExplanation,
        markingScheme,
        teacherNotes,
        difficultyLevel,
        bloomLevel,
        changeSummary,
        changedFields,
        createdBy,
        createdAt,
      ];
}

/// Represents a review of a content item.
class ContentReview extends Equatable {
  const ContentReview({
    required this.id,
    required this.contentItemId,
    required this.reviewerId,
    required this.qualityScore,
    required this.accuracyScore,
    required this.relevanceScore,
    required this.curriculumAlignmentScore,
    this.comment,
    required this.status,
    required this.reviewedAt,
  });

  final String id;
  final String contentItemId;
  final String reviewerId;
  final double qualityScore;
  final double accuracyScore;
  final double relevanceScore;
  final double curriculumAlignmentScore;
  final String? comment;
  final ContentStatus status;
  final DateTime reviewedAt;

  ContentReview copyWith({
    String? id,
    String? contentItemId,
    String? reviewerId,
    double? qualityScore,
    double? accuracyScore,
    double? relevanceScore,
    double? curriculumAlignmentScore,
    String? comment,
    ContentStatus? status,
    DateTime? reviewedAt,
  }) {
    return ContentReview(
      id: id ?? this.id,
      contentItemId: contentItemId ?? this.contentItemId,
      reviewerId: reviewerId ?? this.reviewerId,
      qualityScore: qualityScore ?? this.qualityScore,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      curriculumAlignmentScore: curriculumAlignmentScore ?? this.curriculumAlignmentScore,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentItemId,
        reviewerId,
        qualityScore,
        accuracyScore,
        relevanceScore,
        curriculumAlignmentScore,
        comment,
        status,
        reviewedAt,
      ];
}

/// Represents a content import operation.
class ContentImport extends Equatable {
  const ContentImport({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.educationalLevelId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSizeBytes,
    required this.totalItems,
    required this.processedItems,
    required this.successfulItems,
    required this.failedItems,
    required this.status,
    this.errorLog,
    this.mappingConfig,
    this.hasLicensingDeclaration,
    this.licenseDetails,
    this.startedAt,
    this.completedAt,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String subjectId;
  final String educationalLevelId;
  final String fileName;
  final String fileUrl;
  final int fileSizeBytes;
  final int totalItems;
  final int processedItems;
  final int successfulItems;
  final int failedItems;
  final ImportStatus status;
  final List<Map<String, dynamic>>? errorLog;
  final Map<String, dynamic>? mappingConfig;
  final bool? hasLicensingDeclaration;
  final Map<String, dynamic>? licenseDetails;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? createdBy;
  final DateTime createdAt;

  ContentImport copyWith({
    String? id,
    String? schoolId,
    String? subjectId,
    String? educationalLevelId,
    String? fileName,
    String? fileUrl,
    int? fileSizeBytes,
    int? totalItems,
    int? processedItems,
    int? successfulItems,
    int? failedItems,
    ImportStatus? status,
    List<Map<String, dynamic>>? errorLog,
    Map<String, dynamic>? mappingConfig,
    bool? hasLicensingDeclaration,
    Map<String, dynamic>? licenseDetails,
    DateTime? startedAt,
    DateTime? completedAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ContentImport(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      successfulItems: successfulItems ?? this.successfulItems,
      failedItems: failedItems ?? this.failedItems,
      status: status ?? this.status,
      errorLog: errorLog ?? this.errorLog,
      mappingConfig: mappingConfig ?? this.mappingConfig,
      hasLicensingDeclaration: hasLicensingDeclaration ?? this.hasLicensingDeclaration,
      licenseDetails: licenseDetails ?? this.licenseDetails,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        subjectId,
        educationalLevelId,
        fileName,
        fileUrl,
        fileSizeBytes,
        totalItems,
        processedItems,
        successfulItems,
        failedItems,
        status,
        errorLog,
        mappingConfig,
        hasLicensingDeclaration,
        licenseDetails,
        startedAt,
        completedAt,
        createdBy,
        createdAt,
      ];
}

/// Represents a collection of content items.
class ContentCollection extends Equatable {
  const ContentCollection({
    required this.id,
    required this.name,
    this.description,
    required this.subjectId,
    required this.educationalLevelId,
    this.schoolId,
    required this.collectionType,
    required this.isPublic,
    required this.sortOrder,
    required this.contentCount,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String subjectId;
  final String educationalLevelId;
  final String? schoolId;
  final String collectionType;
  final bool isPublic;
  final int sortOrder;
  final int contentCount;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? subjectId,
    String? educationalLevelId,
    String? schoolId,
    String? collectionType,
    bool? isPublic,
    int? sortOrder,
    int? contentCount,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      schoolId: schoolId ?? this.schoolId,
      collectionType: collectionType ?? this.collectionType,
      isPublic: isPublic ?? this.isPublic,
      sortOrder: sortOrder ?? this.sortOrder,
      contentCount: contentCount ?? this.contentCount,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subjectId,
        educationalLevelId,
        schoolId,
        collectionType,
        isPublic,
        sortOrder,
        contentCount,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents an item within a content collection.
class ContentCollectionItem extends Equatable {
  const ContentCollectionItem({
    required this.id,
    required this.collectionId,
    required this.contentItemId,
    required this.sortOrder,
    required this.addedAt,
  });

  final String id;
  final String collectionId;
  final String contentItemId;
  final int sortOrder;
  final DateTime addedAt;

  ContentCollectionItem copyWith({
    String? id,
    String? collectionId,
    String? contentItemId,
    int? sortOrder,
    DateTime? addedAt,
  }) {
    return ContentCollectionItem(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      contentItemId: contentItemId ?? this.contentItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        contentItemId,
        sortOrder,
        addedAt,
      ];
}

/// Configuration for AI-driven curriculum content generation.
class AiCurriculumConfig extends Equatable {
  const AiCurriculumConfig({
    required this.id,
    required this.schoolId,
    required this.subjectId,
    required this.educationalLevelId,
    required this.curriculumId,
    this.preferredDifficulty,
    this.preferredBloomLevels,
    this.questionTypeDistribution,
    this.languageStyle,
    this.includeExplanations,
    this.includeMarkingSchemes,
    this.includeTeacherNotes,
    this.contentTone,
    this.culturalContext,
    this.maxQuestionsPerGeneration,
    this.qualityThreshold,
    this.autoApproveThreshold,
    this.topicCoveragePreference,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String subjectId;
  final String educationalLevelId;
  final String curriculumId;
  final DifficultyLevel? preferredDifficulty;
  final List<BloomTaxonomy>? preferredBloomLevels;
  final Map<String, dynamic>? questionTypeDistribution;
  final String? languageStyle;
  final bool? includeExplanations;
  final bool? includeMarkingSchemes;
  final bool? includeTeacherNotes;
  final String? contentTone;
  final String? culturalContext;
  final int? maxQuestionsPerGeneration;
  final double? qualityThreshold;
  final double? autoApproveThreshold;
  final String? topicCoveragePreference;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiCurriculumConfig copyWith({
    String? id,
    String? schoolId,
    String? subjectId,
    String? educationalLevelId,
    String? curriculumId,
    DifficultyLevel? preferredDifficulty,
    List<BloomTaxonomy>? preferredBloomLevels,
    Map<String, dynamic>? questionTypeDistribution,
    String? languageStyle,
    bool? includeExplanations,
    bool? includeMarkingSchemes,
    bool? includeTeacherNotes,
    String? contentTone,
    String? culturalContext,
    int? maxQuestionsPerGeneration,
    double? qualityThreshold,
    double? autoApproveThreshold,
    String? topicCoveragePreference,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiCurriculumConfig(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      curriculumId: curriculumId ?? this.curriculumId,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      preferredBloomLevels: preferredBloomLevels ?? this.preferredBloomLevels,
      questionTypeDistribution: questionTypeDistribution ?? this.questionTypeDistribution,
      languageStyle: languageStyle ?? this.languageStyle,
      includeExplanations: includeExplanations ?? this.includeExplanations,
      includeMarkingSchemes: includeMarkingSchemes ?? this.includeMarkingSchemes,
      includeTeacherNotes: includeTeacherNotes ?? this.includeTeacherNotes,
      contentTone: contentTone ?? this.contentTone,
      culturalContext: culturalContext ?? this.culturalContext,
      maxQuestionsPerGeneration: maxQuestionsPerGeneration ?? this.maxQuestionsPerGeneration,
      qualityThreshold: qualityThreshold ?? this.qualityThreshold,
      autoApproveThreshold: autoApproveThreshold ?? this.autoApproveThreshold,
      topicCoveragePreference: topicCoveragePreference ?? this.topicCoveragePreference,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        subjectId,
        educationalLevelId,
        curriculumId,
        preferredDifficulty,
        preferredBloomLevels,
        questionTypeDistribution,
        languageStyle,
        includeExplanations,
        includeMarkingSchemes,
        includeTeacherNotes,
        contentTone,
        culturalContext,
        maxQuestionsPerGeneration,
        qualityThreshold,
        autoApproveThreshold,
        topicCoveragePreference,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a rule for AI content generation.
class AiGenerationRule extends Equatable {
  const AiGenerationRule({
    required this.id,
    required this.educationalLevelId,
    required this.subjectId,
    required this.ruleName,
    required this.ruleType,
    this.conditions,
    this.actions,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String educationalLevelId;
  final String subjectId;
  final String ruleName;
  final String ruleType;
  final Map<String, dynamic>? conditions;
  final Map<String, dynamic>? actions;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiGenerationRule copyWith({
    String? id,
    String? educationalLevelId,
    String? subjectId,
    String? ruleName,
    String? ruleType,
    Map<String, dynamic>? conditions,
    Map<String, dynamic>? actions,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiGenerationRule(
      id: id ?? this.id,
      educationalLevelId: educationalLevelId ?? this.educationalLevelId,
      subjectId: subjectId ?? this.subjectId,
      ruleName: ruleName ?? this.ruleName,
      ruleType: ruleType ?? this.ruleType,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        educationalLevelId,
        subjectId,
        ruleName,
        ruleType,
        conditions,
        actions,
        priority,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Represents an entry in the answer repository.
class AnswerRepositoryEntry extends Equatable {
  const AnswerRepositoryEntry({
    required this.id,
    required this.contentItemId,
    required this.correctAnswers,
    this.stepByStepExplanation,
    this.explanationRich,
    this.markingScheme,
    this.alternativeAnswers,
    this.commonMistakes,
    this.teacherNotes,
    this.curriculumReferences,
    this.learningObjectiveIds,
    this.difficultyJustification,
    required this.version,
    required this.isVerified,
    this.verifiedBy,
    this.verifiedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String contentItemId;
  final List<Map<String, dynamic>> correctAnswers;
  final String? stepByStepExplanation;
  final Map<String, dynamic>? explanationRich;
  final Map<String, dynamic>? markingScheme;
  final List<Map<String, dynamic>>? alternativeAnswers;
  final List<Map<String, dynamic>>? commonMistakes;
  final String? teacherNotes;
  final List<Map<String, dynamic>>? curriculumReferences;
  final List<String>? learningObjectiveIds;
  final String? difficultyJustification;
  final int version;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnswerRepositoryEntry copyWith({
    String? id,
    String? contentItemId,
    List<Map<String, dynamic>>? correctAnswers,
    String? stepByStepExplanation,
    Map<String, dynamic>? explanationRich,
    Map<String, dynamic>? markingScheme,
    List<Map<String, dynamic>>? alternativeAnswers,
    List<Map<String, dynamic>>? commonMistakes,
    String? teacherNotes,
    List<Map<String, dynamic>>? curriculumReferences,
    List<String>? learningObjectiveIds,
    String? difficultyJustification,
    int? version,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnswerRepositoryEntry(
      id: id ?? this.id,
      contentItemId: contentItemId ?? this.contentItemId,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      stepByStepExplanation: stepByStepExplanation ?? this.stepByStepExplanation,
      explanationRich: explanationRich ?? this.explanationRich,
      markingScheme: markingScheme ?? this.markingScheme,
      alternativeAnswers: alternativeAnswers ?? this.alternativeAnswers,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      curriculumReferences: curriculumReferences ?? this.curriculumReferences,
      learningObjectiveIds: learningObjectiveIds ?? this.learningObjectiveIds,
      difficultyJustification: difficultyJustification ?? this.difficultyJustification,
      version: version ?? this.version,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentItemId,
        correctAnswers,
        stepByStepExplanation,
        explanationRich,
        markingScheme,
        alternativeAnswers,
        commonMistakes,
        teacherNotes,
        curriculumReferences,
        learningObjectiveIds,
        difficultyJustification,
        version,
        isVerified,
        verifiedBy,
        verifiedAt,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents an audit log entry.
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.userId,
    this.schoolId,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.sessionId,
    this.apiEndpoint,
    this.httpMethod,
    this.responseStatus,
    this.durationMs,
    this.metadata,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? schoolId;
  final AuditAction action;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? sessionId;
  final String? apiEndpoint;
  final String? httpMethod;
  final int? responseStatus;
  final int? durationMs;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditEntry copyWith({
    String? id,
    String? userId,
    String? schoolId,
    AuditAction? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    String? sessionId,
    String? apiEndpoint,
    String? httpMethod,
    int? responseStatus,
    int? durationMs,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AuditEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      responseStatus: responseStatus ?? this.responseStatus,
      durationMs: durationMs ?? this.durationMs,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        schoolId,
        action,
        resourceType,
        resourceId,
        oldValues,
        newValues,
        ipAddress,
        userAgent,
        deviceId,
        sessionId,
        apiEndpoint,
        httpMethod,
        responseStatus,
        durationMs,
        metadata,
        createdAt,
      ];
}

/// Represents MFA configuration for a user.
class MfaConfiguration extends Equatable {
  const MfaConfiguration({
    required this.id,
    required this.userId,
    required this.mfaMethod,
    required this.isEnabled,
    required this.isVerified,
    this.secretEncrypted,
    this.backupCodesEncrypted,
    this.phoneNumberEncrypted,
    this.verificationAttempts,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final MfaMethod mfaMethod;
  final bool isEnabled;
  final bool isVerified;
  final String? secretEncrypted;
  final String? backupCodesEncrypted;
  final String? phoneNumberEncrypted;
  final int? verificationAttempts;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MfaConfiguration copyWith({
    String? id,
    String? userId,
    MfaMethod? mfaMethod,
    bool? isEnabled,
    bool? isVerified,
    String? secretEncrypted,
    String? backupCodesEncrypted,
    String? phoneNumberEncrypted,
    int? verificationAttempts,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MfaConfiguration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mfaMethod: mfaMethod ?? this.mfaMethod,
      isEnabled: isEnabled ?? this.isEnabled,
      isVerified: isVerified ?? this.isVerified,
      secretEncrypted: secretEncrypted ?? this.secretEncrypted,
      backupCodesEncrypted: backupCodesEncrypted ?? this.backupCodesEncrypted,
      phoneNumberEncrypted: phoneNumberEncrypted ?? this.phoneNumberEncrypted,
      verificationAttempts: verificationAttempts ?? this.verificationAttempts,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        mfaMethod,
        isEnabled,
        isVerified,
        secretEncrypted,
        backupCodesEncrypted,
        phoneNumberEncrypted,
        verificationAttempts,
        lastUsedAt,
        createdAt,
        updatedAt,
      ];
}

/// Represents an API key for programmatic access.
class ApiKey extends Equatable {
  const ApiKey({
    required this.id,
    required this.userId,
    this.schoolId,
    required this.keyHash,
    required this.keyPrefix,
    required this.name,
    this.scopes,
    required this.isActive,
    this.rateLimitOverride,
    this.expiresAt,
    this.lastUsedAt,
    this.usageCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? schoolId;
  final String keyHash;
  final String keyPrefix;
  final String name;
  final List<String>? scopes;
  final bool isActive;
  final int? rateLimitOverride;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int? usageCount;
  final DateTime createdAt;

  ApiKey copyWith({
    String? id,
    String? userId,
    String? schoolId,
    String? keyHash,
    String? keyPrefix,
    String? name,
    List<String>? scopes,
    bool? isActive,
    int? rateLimitOverride,
    DateTime? expiresAt,
    DateTime? lastUsedAt,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return ApiKey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      keyHash: keyHash ?? this.keyHash,
      keyPrefix: keyPrefix ?? this.keyPrefix,
      name: name ?? this.name,
      scopes: scopes ?? this.scopes,
      isActive: isActive ?? this.isActive,
      rateLimitOverride: rateLimitOverride ?? this.rateLimitOverride,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        schoolId,
        keyHash,
        keyPrefix,
        name,
        scopes,
        isActive,
        rateLimitOverride,
        expiresAt,
        lastUsedAt,
        usageCount,
        createdAt,
      ];
}

/// Represents a security event in the system.
class SecurityEvent extends Equatable {
  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    this.userId,
    this.schoolId,
    this.ipAddress,
    this.userAgent,
    this.details,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final AlertSeverity severity;
  final String? userId;
  final String? schoolId;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? details;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  SecurityEvent copyWith({
    String? id,
    String? eventType,
    AlertSeverity? severity,
    String? userId,
    String? schoolId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? details,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return SecurityEvent(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      severity: severity ?? this.severity,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      details: details ?? this.details,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        severity,
        userId,
        schoolId,
        ipAddress,
        userAgent,
        details,
        isResolved,
        resolvedBy,
        resolvedAt,
        createdAt,
      ];
}

/// Represents rate limiting configuration.
class RateLimitConfig extends Equatable {
  const RateLimitConfig({
    required this.id,
    required this.scope,
    required this.identifier,
    this.endpointPattern,
    required this.maxRequests,
    required this.windowSeconds,
    this.actionOnLimit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final RateLimitScope scope;
  final String identifier;
  final String? endpointPattern;
  final int maxRequests;
  final int windowSeconds;
  final String? actionOnLimit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RateLimitConfig copyWith({
    String? id,
    RateLimitScope? scope,
    String? identifier,
    String? endpointPattern,
    int? maxRequests,
    int? windowSeconds,
    String? actionOnLimit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RateLimitConfig(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      identifier: identifier ?? this.identifier,
      endpointPattern: endpointPattern ?? this.endpointPattern,
      maxRequests: maxRequests ?? this.maxRequests,
      windowSeconds: windowSeconds ?? this.windowSeconds,
      actionOnLimit: actionOnLimit ?? this.actionOnLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        scope,
        identifier,
        endpointPattern,
        maxRequests,
        windowSeconds,
        actionOnLimit,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Represents a user session.
class UserSession extends Equatable {
  const UserSession({
    required this.id,
    required this.userId,
    required this.sessionTokenHash,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.ipAddress,
    this.userAgent,
    required this.isActive,
    required this.lastActivityAt,
    required this.expiresAt,
    this.invalidatedBy,
    this.invalidatedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String sessionTokenHash;
  final String? deviceId;
  final String? deviceName;
  final String? deviceType;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final String? invalidatedBy;
  final DateTime? invalidatedAt;
  final DateTime createdAt;

  UserSession copyWith({
    String? id,
    String? userId,
    String? sessionTokenHash,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    DateTime? lastActivityAt,
    DateTime? expiresAt,
    String? invalidatedBy,
    DateTime? invalidatedAt,
    DateTime? createdAt,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionTokenHash: sessionTokenHash ?? this.sessionTokenHash,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      expiresAt: expiresAt ?? this.expiresAt,
      invalidatedBy: invalidatedBy ?? this.invalidatedBy,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionTokenHash,
        deviceId,
        deviceName,
        deviceType,
        ipAddress,
        userAgent,
        isActive,
        lastActivityAt,
        expiresAt,
        invalidatedBy,
        invalidatedAt,
        createdAt,
      ];
}

/// Represents a system metric data point.
class SystemMetric extends Equatable {
  const SystemMetric({
    required this.id,
    required this.metricName,
    required this.metricType,
    required this.value,
    this.unit,
    this.tags,
    this.schoolId,
    required this.recordedAt,
  });

  final String id;
  final String metricName;
  final MetricType metricType;
  final double value;
  final String? unit;
  final Map<String, dynamic>? tags;
  final String? schoolId;
  final DateTime recordedAt;

  SystemMetric copyWith({
    String? id,
    String? metricName,
    MetricType? metricType,
    double? value,
    String? unit,
    Map<String, dynamic>? tags,
    String? schoolId,
    DateTime? recordedAt,
  }) {
    return SystemMetric(
      id: id ?? this.id,
      metricName: metricName ?? this.metricName,
      metricType: metricType ?? this.metricType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      tags: tags ?? this.tags,
      schoolId: schoolId ?? this.schoolId,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        metricName,
        metricType,
        value,
        unit,
        tags,
        schoolId,
        recordedAt,
      ];
}

/// Represents an alert rule for monitoring.
class AlertRule extends Equatable {
  const AlertRule({
    required this.id,
    required this.name,
    this.description,
    required this.metricName,
    required this.conditionOperator,
    required this.thresholdValue,
    this.durationSeconds,
    required this.severity,
    this.notificationChannels,
    required this.isActive,
    this.lastTriggeredAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String metricName;
  final String conditionOperator;
  final double thresholdValue;
  final int? durationSeconds;
  final AlertSeverity severity;
  final List<String>? notificationChannels;
  final bool isActive;
  final DateTime? lastTriggeredAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertRule copyWith({
    String? id,
    String? name,
    String? description,
    String? metricName,
    String? conditionOperator,
    double? thresholdValue,
    int? durationSeconds,
    AlertSeverity? severity,
    List<String>? notificationChannels,
    bool? isActive,
    DateTime? lastTriggeredAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metricName: metricName ?? this.metricName,
      conditionOperator: conditionOperator ?? this.conditionOperator,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      severity: severity ?? this.severity,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      isActive: isActive ?? this.isActive,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        metricName,
        conditionOperator,
        thresholdValue,
        durationSeconds,
        severity,
        notificationChannels,
        isActive,
        lastTriggeredAt,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents an alert incident triggered by a rule.
class AlertIncident extends Equatable {
  const AlertIncident({
    required this.id,
    required this.alertRuleId,
    required this.currentValue,
    required this.thresholdValue,
    required this.severity,
    required this.status,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
  });

  final String id;
  final String alertRuleId;
  final double currentValue;
  final double thresholdValue;
  final AlertSeverity severity;
  final String status;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;

  AlertIncident copyWith({
    String? id,
    String? alertRuleId,
    double? currentValue,
    double? thresholdValue,
    AlertSeverity? severity,
    String? status,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    DateTime? createdAt,
  }) {
    return AlertIncident(
      id: id ?? this.id,
      alertRuleId: alertRuleId ?? this.alertRuleId,
      currentValue: currentValue ?? this.currentValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        alertRuleId,
        currentValue,
        thresholdValue,
        severity,
        status,
        acknowledgedBy,
        acknowledgedAt,
        resolvedAt,
        resolutionNotes,
        createdAt,
      ];
}

/// Represents a performance log entry.
class PerformanceLog extends Equatable {
  const PerformanceLog({
    required this.id,
    required this.operationType,
    required this.operationName,
    required this.durationMs,
    required this.isSlow,
    this.userId,
    this.schoolId,
    this.endpoint,
    this.queryHash,
    this.requestPayloadSizeBytes,
    this.responsePayloadSizeBytes,
    this.errorMessage,
    this.metadata,
    required this.createdAt,
  });

  final String id;
  final String operationType;
  final String operationName;
  final int durationMs;
  final bool isSlow;
  final String? userId;
  final String? schoolId;
  final String? endpoint;
  final String? queryHash;
  final int? requestPayloadSizeBytes;
  final int? responsePayloadSizeBytes;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  PerformanceLog copyWith({
    String? id,
    String? operationType,
    String? operationName,
    int? durationMs,
    bool? isSlow,
    String? userId,
    String? schoolId,
    String? endpoint,
    String? queryHash,
    int? requestPayloadSizeBytes,
    int? responsePayloadSizeBytes,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return PerformanceLog(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      operationName: operationName ?? this.operationName,
      durationMs: durationMs ?? this.durationMs,
      isSlow: isSlow ?? this.isSlow,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      endpoint: endpoint ?? this.endpoint,
      queryHash: queryHash ?? this.queryHash,
      requestPayloadSizeBytes: requestPayloadSizeBytes ?? this.requestPayloadSizeBytes,
      responsePayloadSizeBytes: responsePayloadSizeBytes ?? this.responsePayloadSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operationType,
        operationName,
        durationMs,
        isSlow,
        userId,
        schoolId,
        endpoint,
        queryHash,
        requestPayloadSizeBytes,
        responsePayloadSizeBytes,
        errorMessage,
        metadata,
        createdAt,
      ];
}

/// Represents an error report.
class ErrorReport extends Equatable {
  const ErrorReport({
    required this.id,
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    required this.errorHash,
    required this.occurrenceCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.userId,
    this.schoolId,
    this.deviceInfo,
    this.appVersion,
    this.platform,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    this.metadata,
  });

  final String id;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final String errorHash;
  final int occurrenceCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String? userId;
  final String? schoolId;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final String? platform;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final Map<String, dynamic>? metadata;

  ErrorReport copyWith({
    String? id,
    String? errorType,
    String? errorMessage,
    String? stackTrace,
    String? errorHash,
    int? occurrenceCount,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    String? userId,
    String? schoolId,
    Map<String, dynamic>? deviceInfo,
    String? appVersion,
    String? platform,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ErrorReport(
      id: id ?? this.id,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      errorHash: errorHash ?? this.errorHash,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        errorType,
        errorMessage,
        stackTrace,
        errorHash,
        occurrenceCount,
        firstSeenAt,
        lastSeenAt,
        userId,
        schoolId,
        deviceInfo,
        appVersion,
        platform,
        isResolved,
        resolvedBy,
        resolvedAt,
        metadata,
      ];
}

/// Represents a deployment record.
class Deployment extends Equatable {
  const Deployment({
    required this.id,
    required this.environment,
    required this.version,
    required this.commitHash,
    required this.branch,
    this.deployerId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.rollbackFrom,
    this.notes,
    this.metadata,
  });

  final String id;
  final String environment;
  final String version;
  final String commitHash;
  final String branch;
  final String? deployerId;
  final DeploymentStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? rollbackFrom;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Deployment copyWith({
    String? id,
    String? environment,
    String? version,
    String? commitHash,
    String? branch,
    String? deployerId,
    DeploymentStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? rollbackFrom,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Deployment(
      id: id ?? this.id,
      environment: environment ?? this.environment,
      version: version ?? this.version,
      commitHash: commitHash ?? this.commitHash,
      branch: branch ?? this.branch,
      deployerId: deployerId ?? this.deployerId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rollbackFrom: rollbackFrom ?? this.rollbackFrom,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        environment,
        version,
        commitHash,
        branch,
        deployerId,
        status,
        startedAt,
        completedAt,
        rollbackFrom,
        notes,
        metadata,
      ];
}

/// Represents a test result record.
class TestResult extends Equatable {
  const TestResult({
    required this.id,
    required this.testType,
    required this.testSuite,
    required this.testName,
    required this.status,
    required this.durationMs,
    this.errorMessage,
    this.stackTrace,
    this.coveragePercentage,
    this.metadata,
    this.deploymentId,
    required this.createdAt,
  });

  final String id;
  final TestType testType;
  final String testSuite;
  final String testName;
  final String status;
  final int durationMs;
  final String? errorMessage;
  final String? stackTrace;
  final double? coveragePercentage;
  final Map<String, dynamic>? metadata;
  final String? deploymentId;
  final DateTime createdAt;

  TestResult copyWith({
    String? id,
    TestType? testType,
    String? testSuite,
    String? testName,
    String? status,
    int? durationMs,
    String? errorMessage,
    String? stackTrace,
    double? coveragePercentage,
    Map<String, dynamic>? metadata,
    String? deploymentId,
    DateTime? createdAt,
  }) {
    return TestResult(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      testSuite: testSuite ?? this.testSuite,
      testName: testName ?? this.testName,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      coveragePercentage: coveragePercentage ?? this.coveragePercentage,
      metadata: metadata ?? this.metadata,
      deploymentId: deploymentId ?? this.deploymentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        testType,
        testSuite,
        testName,
        status,
        durationMs,
        errorMessage,
        stackTrace,
        coveragePercentage,
        metadata,
        deploymentId,
        createdAt,
      ];
}

/// Represents aggregate statistics for the CCMS module.
class CcmsStats extends Equatable {
  const CcmsStats({
    required this.totalSubjects,
    required this.totalTopics,
    required this.totalContent,
    required this.publishedContent,
    required this.draftContent,
    required this.aiGeneratedContent,
    required this.pastQuestions,
    required this.avgQualityScore,
    required this.totalImports,
    required this.totalCollections,
    required this.pendingReviews,
    this.contentByType,
    this.contentByDifficulty,
  });

  final int totalSubjects;
  final int totalTopics;
  final int totalContent;
  final int publishedContent;
  final int draftContent;
  final int aiGeneratedContent;
  final int pastQuestions;
  final double avgQualityScore;
  final int totalImports;
  final int totalCollections;
  final int pendingReviews;
  final Map<String, dynamic>? contentByType;
  final Map<String, dynamic>? contentByDifficulty;

  CcmsStats copyWith({
    int? totalSubjects,
    int? totalTopics,
    int? totalContent,
    int? publishedContent,
    int? draftContent,
    int? aiGeneratedContent,
    int? pastQuestions,
    double? avgQualityScore,
    int? totalImports,
    int? totalCollections,
    int? pendingReviews,
    Map<String, dynamic>? contentByType,
    Map<String, dynamic>? contentByDifficulty,
  }) {
    return CcmsStats(
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalTopics: totalTopics ?? this.totalTopics,
      totalContent: totalContent ?? this.totalContent,
      publishedContent: publishedContent ?? this.publishedContent,
      draftContent: draftContent ?? this.draftContent,
      aiGeneratedContent: aiGeneratedContent ?? this.aiGeneratedContent,
      pastQuestions: pastQuestions ?? this.pastQuestions,
      avgQualityScore: avgQualityScore ?? this.avgQualityScore,
      totalImports: totalImports ?? this.totalImports,
      totalCollections: totalCollections ?? this.totalCollections,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      contentByType: contentByType ?? this.contentByType,
      contentByDifficulty: contentByDifficulty ?? this.contentByDifficulty,
    );
  }

  @override
  List<Object?> get props => [
        totalSubjects,
        totalTopics,
        totalContent,
        publishedContent,
        draftContent,
        aiGeneratedContent,
        pastQuestions,
        avgQualityScore,
        totalImports,
        totalCollections,
        pendingReviews,
        contentByType,
        contentByDifficulty,
      ];
}
