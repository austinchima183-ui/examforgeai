import 'package:equatable/equatable.dart';

import '../../domain/entities/ccms_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// HELPER EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════

/// Helper to read a field from JSON that may be in snake_case (Supabase)
/// or camelCase (internal).
T? _readField<T>(Map<String, dynamic> json, String snakeKey, String camelKey) {
  return json[snakeKey] as T? ?? json[camelKey] as T?;
}

/// Helper to read a DateTime field from JSON (snake_case or camelCase).
DateTime _readDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  final raw = json[snakeKey] as String? ?? json[camelKey] as String;
  return DateTime.parse(raw);
}

/// Helper to read a nullable DateTime field from JSON.
DateTime? _readNullableDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  final raw = json[snakeKey] as String? ?? json[camelKey] as String?;
  if (raw == null) return null;
  return DateTime.parse(raw);
}

/// Helper to read a List<Map<String, dynamic>> from JSON.
List<Map<String, dynamic>> _readListOfMaps(dynamic value) {
  if (value == null) return [];
  return (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

/// Helper to read a nullable List<Map<String, dynamic>> from JSON.
List<Map<String, dynamic>>? _readNullableListOfMaps(dynamic value) {
  if (value == null) return null;
  return (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

/// Helper to read a List<String> from JSON.
List<String> _readListOfStrings(dynamic value) {
  if (value == null) return [];
  return (value as List).cast<String>();
}

/// Helper to read a nullable List<String> from JSON.
List<String>? _readNullableListOfStrings(dynamic value) {
  if (value == null) return null;
  return (value as List).cast<String>();
}

/// Helper to read a nullable Map<String, dynamic> from JSON.
Map<String, dynamic>? _readNullableMap(dynamic value) {
  if (value == null) return null;
  return Map<String, dynamic>.from(value as Map);
}

/// Helper to read a non-null Map<String, dynamic> from JSON.
Map<String, dynamic> _readMap(dynamic value) {
  if (value == null) return {};
  return Map<String, dynamic>.from(value as Map);
}

/// Helper to read a List<BloomTaxonomy> from JSON (stored as list of strings).
List<BloomTaxonomy>? _readNullableBloomList(dynamic value) {
  if (value == null) return null;
  return (value as List).map((e) {
    final str = e as String;
    return BloomTaxonomy.fromString(str) ?? BloomTaxonomy.remember;
  }).toList();
}

// ═══════════════════════════════════════════════════════════════════════
// MODEL CLASSES
// ═══════════════════════════════════════════════════════════════════════

// ─── 1. EducationalLevelModel ────────────────────────────────────────

class EducationalLevelModel extends Equatable {
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

  const EducationalLevelModel({
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

  factory EducationalLevelModel.fromJson(Map<String, dynamic> json) {
    return EducationalLevelModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      levelCategory: EducationalLevelCategory.fromString(
            _readField<String>(json, 'level_category', 'levelCategory'),
          ) ??
          EducationalLevelCategory.primary,
      levelOrder: _readField<int>(json, 'level_order', 'levelOrder') ?? 0,
      minAge: _readField<int>(json, 'min_age', 'minAge'),
      maxAge: _readField<int>(json, 'max_age', 'maxAge'),
      description: json['description'] as String?,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'level_category': levelCategory.value,
      'level_order': levelOrder,
      'min_age': minAge,
      'max_age': maxAge,
      'description': description,
      'is_active': isActive,
    };
  }

  factory EducationalLevelModel.fromEntity(EducationalLevel entity) {
    return EducationalLevelModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      levelCategory: entity.levelCategory,
      levelOrder: entity.levelOrder,
      minAge: entity.minAge,
      maxAge: entity.maxAge,
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  EducationalLevel toEntity() {
    return EducationalLevel(
      id: id,
      code: code,
      name: name,
      levelCategory: levelCategory,
      levelOrder: levelOrder,
      minAge: minAge,
      maxAge: maxAge,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, code, name, levelCategory, levelOrder];
}

// ─── 2. SchoolLevelConfigurationModel ────────────────────────────────

class SchoolLevelConfigurationModel extends Equatable {
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

  const SchoolLevelConfigurationModel({
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

  factory SchoolLevelConfigurationModel.fromJson(Map<String, dynamic> json) {
    return SchoolLevelConfigurationModel(
      id: json['id'] as String,
      schoolId: _readField<String>(json, 'school_id', 'schoolId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ?? '',
      isEnabled: _readField<bool>(json, 'is_enabled', 'isEnabled') ?? true,
      customName: _readField<String>(json, 'custom_name', 'customName'),
      academicYearStart:
          _readField<String>(json, 'academic_year_start', 'academicYearStart'),
      academicYearEnd:
          _readField<String>(json, 'academic_year_end', 'academicYearEnd'),
      maxStudentsPerClass:
          _readField<int>(json, 'max_students_per_class', 'maxStudentsPerClass'),
      gradingSystem: _readNullableMap(json['grading_system'] ?? json['gradingSystem']),
      configuration: _readNullableMap(json['configuration']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'educational_level_id': educationalLevelId,
      'is_enabled': isEnabled,
      'custom_name': customName,
      'academic_year_start': academicYearStart,
      'academic_year_end': academicYearEnd,
      'max_students_per_class': maxStudentsPerClass,
      'grading_system': gradingSystem,
      'configuration': configuration,
      'created_by': createdBy,
    };
  }

  factory SchoolLevelConfigurationModel.fromEntity(
    SchoolLevelConfiguration entity,
  ) {
    return SchoolLevelConfigurationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      educationalLevelId: entity.educationalLevelId,
      isEnabled: entity.isEnabled,
      customName: entity.customName,
      academicYearStart: entity.academicYearStart,
      academicYearEnd: entity.academicYearEnd,
      maxStudentsPerClass: entity.maxStudentsPerClass,
      gradingSystem: entity.gradingSystem,
      configuration: entity.configuration,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchoolLevelConfiguration toEntity() {
    return SchoolLevelConfiguration(
      id: id,
      schoolId: schoolId,
      educationalLevelId: educationalLevelId,
      isEnabled: isEnabled,
      customName: customName,
      academicYearStart: academicYearStart,
      academicYearEnd: academicYearEnd,
      maxStudentsPerClass: maxStudentsPerClass,
      gradingSystem: gradingSystem,
      configuration: configuration,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, educationalLevelId];
}

// ─── 3. CurriculumModel ──────────────────────────────────────────────

class CurriculumModel extends Equatable {
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

  const CurriculumModel({
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

  factory CurriculumModel.fromJson(Map<String, dynamic> json) {
    return CurriculumModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      curriculumType: CurriculumType.fromString(
            _readField<String>(json, 'curriculum_type', 'curriculumType'),
          ) ??
          CurriculumType.custom,
      countryCode: _readField<String>(json, 'country_code', 'countryCode') ?? 'NG',
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      edition: json['edition'] as String?,
      effectiveDate: _readNullableDateTime(json, 'effective_date', 'effectiveDate'),
      expiryDate: _readNullableDateTime(json, 'expiry_date', 'expiryDate'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      parentCurriculumId:
          _readField<String>(json, 'parent_curriculum_id', 'parentCurriculumId'),
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'curriculum_type': curriculumType.value,
      'country_code': countryCode,
      'description': description,
      'publisher': publisher,
      'edition': edition,
      'effective_date': effectiveDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_active': isActive,
      'parent_curriculum_id': parentCurriculumId,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory CurriculumModel.fromEntity(Curriculum entity) {
    return CurriculumModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      curriculumType: entity.curriculumType,
      countryCode: entity.countryCode,
      description: entity.description,
      publisher: entity.publisher,
      edition: entity.edition,
      effectiveDate: entity.effectiveDate,
      expiryDate: entity.expiryDate,
      isActive: entity.isActive,
      parentCurriculumId: entity.parentCurriculumId,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Curriculum toEntity() {
    return Curriculum(
      id: id,
      name: name,
      code: code,
      curriculumType: curriculumType,
      countryCode: countryCode,
      description: description,
      publisher: publisher,
      edition: edition,
      effectiveDate: effectiveDate,
      expiryDate: expiryDate,
      isActive: isActive,
      parentCurriculumId: parentCurriculumId,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, code, name, curriculumType];
}

// ─── 4. CurriculumVersionModel ───────────────────────────────────────

class CurriculumVersionModel extends Equatable {
  final String id;
  final String curriculumId;
  final int versionNumber;
  final String changeSummary;
  final String? changelog;
  final bool isCurrent;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime createdAt;

  const CurriculumVersionModel({
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

  factory CurriculumVersionModel.fromJson(Map<String, dynamic> json) {
    return CurriculumVersionModel(
      id: json['id'] as String,
      curriculumId: _readField<String>(json, 'curriculum_id', 'curriculumId') ?? '',
      versionNumber:
          _readField<int>(json, 'version_number', 'versionNumber') ?? 1,
      changeSummary:
          _readField<String>(json, 'change_summary', 'changeSummary') ?? '',
      changelog: json['changelog'] as String?,
      isCurrent: _readField<bool>(json, 'is_current', 'isCurrent') ?? false,
      publishedAt: _readNullableDateTime(json, 'published_at', 'publishedAt'),
      publishedBy: _readField<String>(json, 'published_by', 'publishedBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curriculum_id': curriculumId,
      'version_number': versionNumber,
      'change_summary': changeSummary,
      'changelog': changelog,
      'is_current': isCurrent,
      'published_at': publishedAt?.toIso8601String(),
      'published_by': publishedBy,
    };
  }

  factory CurriculumVersionModel.fromEntity(CurriculumVersion entity) {
    return CurriculumVersionModel(
      id: entity.id,
      curriculumId: entity.curriculumId,
      versionNumber: entity.versionNumber,
      changeSummary: entity.changeSummary,
      changelog: entity.changelog,
      isCurrent: entity.isCurrent,
      publishedAt: entity.publishedAt,
      publishedBy: entity.publishedBy,
      createdAt: entity.createdAt,
    );
  }

  CurriculumVersion toEntity() {
    return CurriculumVersion(
      id: id,
      curriculumId: curriculumId,
      versionNumber: versionNumber,
      changeSummary: changeSummary,
      changelog: changelog,
      isCurrent: isCurrent,
      publishedAt: publishedAt,
      publishedBy: publishedBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, curriculumId, versionNumber];
}

// ─── 5. CurriculumLevelMappingModel ──────────────────────────────────

class CurriculumLevelMappingModel extends Equatable {
  final String id;
  final String curriculumId;
  final String educationalLevelId;
  final bool isApplicable;
  final String? notes;
  final DateTime createdAt;

  const CurriculumLevelMappingModel({
    required this.id,
    required this.curriculumId,
    required this.educationalLevelId,
    required this.isApplicable,
    this.notes,
    required this.createdAt,
  });

  factory CurriculumLevelMappingModel.fromJson(Map<String, dynamic> json) {
    return CurriculumLevelMappingModel(
      id: json['id'] as String,
      curriculumId: _readField<String>(json, 'curriculum_id', 'curriculumId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      isApplicable:
          _readField<bool>(json, 'is_applicable', 'isApplicable') ?? true,
      notes: json['notes'] as String?,
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curriculum_id': curriculumId,
      'educational_level_id': educationalLevelId,
      'is_applicable': isApplicable,
      'notes': notes,
    };
  }

  factory CurriculumLevelMappingModel.fromEntity(CurriculumLevelMapping entity) {
    return CurriculumLevelMappingModel(
      id: entity.id,
      curriculumId: entity.curriculumId,
      educationalLevelId: entity.educationalLevelId,
      isApplicable: entity.isApplicable,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  CurriculumLevelMapping toEntity() {
    return CurriculumLevelMapping(
      id: id,
      curriculumId: curriculumId,
      educationalLevelId: educationalLevelId,
      isApplicable: isApplicable,
      notes: notes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, curriculumId, educationalLevelId];
}

// ─── 6. SubjectModel ─────────────────────────────────────────────────

class SubjectModel extends Equatable {
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

  const SubjectModel({
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

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      curriculumId:
          _readField<String>(json, 'curriculum_id', 'curriculumId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      subjectGroup: _readField<String>(json, 'subject_group', 'subjectGroup'),
      isCore: _readField<bool>(json, 'is_core', 'isCore') ?? false,
      isElective: _readField<bool>(json, 'is_elective', 'isElective') ?? false,
      isVocational: _readField<bool>(json, 'is_vocational', 'isVocational') ?? false,
      languageOfInstruction:
          _readField<String>(json, 'language_of_instruction', 'languageOfInstruction'),
      description: json['description'] as String?,
      iconUrl: _readField<String>(json, 'icon_url', 'iconUrl'),
      colorCode: _readField<String>(json, 'color_code', 'colorCode'),
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      isCustom: _readField<bool>(json, 'is_custom', 'isCustom') ?? false,
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'curriculum_id': curriculumId,
      'educational_level_id': educationalLevelId,
      'school_id': schoolId,
      'subject_group': subjectGroup,
      'is_core': isCore,
      'is_elective': isElective,
      'is_vocational': isVocational,
      'language_of_instruction': languageOfInstruction,
      'description': description,
      'icon_url': iconUrl,
      'color_code': colorCode,
      'sort_order': sortOrder,
      'is_active': isActive,
      'is_custom': isCustom,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory SubjectModel.fromEntity(Subject entity) {
    return SubjectModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      curriculumId: entity.curriculumId,
      educationalLevelId: entity.educationalLevelId,
      schoolId: entity.schoolId,
      subjectGroup: entity.subjectGroup,
      isCore: entity.isCore,
      isElective: entity.isElective,
      isVocational: entity.isVocational,
      languageOfInstruction: entity.languageOfInstruction,
      description: entity.description,
      iconUrl: entity.iconUrl,
      colorCode: entity.colorCode,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      isCustom: entity.isCustom,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Subject toEntity() {
    return Subject(
      id: id,
      name: name,
      code: code,
      curriculumId: curriculumId,
      educationalLevelId: educationalLevelId,
      schoolId: schoolId,
      subjectGroup: subjectGroup,
      isCore: isCore,
      isElective: isElective,
      isVocational: isVocational,
      languageOfInstruction: languageOfInstruction,
      description: description,
      iconUrl: iconUrl,
      colorCode: colorCode,
      sortOrder: sortOrder,
      isActive: isActive,
      isCustom: isCustom,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, code, curriculumId, educationalLevelId];
}

// ─── 7. TopicModel ───────────────────────────────────────────────────

class TopicModel extends Equatable {
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

  const TopicModel({
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

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      curriculumId: _readField<String>(json, 'curriculum_id', 'curriculumId') ?? '',
      title: json['title'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      estimatedDurationMinutes:
          _readField<int>(json, 'estimated_duration_minutes', 'estimatedDurationMinutes'),
      iconUrl: _readField<String>(json, 'icon_url', 'iconUrl'),
      parentTopicId:
          _readField<String>(json, 'parent_topic_id', 'parentTopicId'),
      depthLevel: _readField<int>(json, 'depth_level', 'depthLevel') ?? 0,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'curriculum_id': curriculumId,
      'title': title,
      'code': code,
      'description': description,
      'sort_order': sortOrder,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'icon_url': iconUrl,
      'parent_topic_id': parentTopicId,
      'depth_level': depthLevel,
      'is_active': isActive,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory TopicModel.fromEntity(Topic entity) {
    return TopicModel(
      id: entity.id,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      curriculumId: entity.curriculumId,
      title: entity.title,
      code: entity.code,
      description: entity.description,
      sortOrder: entity.sortOrder,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      iconUrl: entity.iconUrl,
      parentTopicId: entity.parentTopicId,
      depthLevel: entity.depthLevel,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Topic toEntity() {
    return Topic(
      id: id,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      curriculumId: curriculumId,
      title: title,
      code: code,
      description: description,
      sortOrder: sortOrder,
      estimatedDurationMinutes: estimatedDurationMinutes,
      iconUrl: iconUrl,
      parentTopicId: parentTopicId,
      depthLevel: depthLevel,
      isActive: isActive,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, subjectId, title, code];
}

// ─── 8. SubtopicModel ────────────────────────────────────────────────

class SubtopicModel extends Equatable {
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

  const SubtopicModel({
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

  factory SubtopicModel.fromJson(Map<String, dynamic> json) {
    return SubtopicModel(
      id: json['id'] as String,
      topicId: _readField<String>(json, 'topic_id', 'topicId') ?? '',
      title: json['title'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      estimatedDurationMinutes:
          _readField<int>(json, 'estimated_duration_minutes', 'estimatedDurationMinutes'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'title': title,
      'code': code,
      'description': description,
      'sort_order': sortOrder,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'is_active': isActive,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory SubtopicModel.fromEntity(Subtopic entity) {
    return SubtopicModel(
      id: entity.id,
      topicId: entity.topicId,
      title: entity.title,
      code: entity.code,
      description: entity.description,
      sortOrder: entity.sortOrder,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Subtopic toEntity() {
    return Subtopic(
      id: id,
      topicId: topicId,
      title: title,
      code: code,
      description: description,
      sortOrder: sortOrder,
      estimatedDurationMinutes: estimatedDurationMinutes,
      isActive: isActive,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, topicId, title, code];
}

// ─── 9. LearningObjectiveModel ───────────────────────────────────────

class LearningObjectiveModel extends Equatable {
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

  const LearningObjectiveModel({
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

  factory LearningObjectiveModel.fromJson(Map<String, dynamic> json) {
    return LearningObjectiveModel(
      id: json['id'] as String,
      topicId: _readField<String>(json, 'topic_id', 'topicId') ?? '',
      subtopicId: _readField<String>(json, 'subtopic_id', 'subtopicId'),
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      code: json['code'] as String,
      description: json['description'] as String,
      bloomLevel: BloomTaxonomy.fromString(
            _readField<String>(json, 'bloom_level', 'bloomLevel'),
          ) ??
          BloomTaxonomy.remember,
      isAssessable: _readField<bool>(json, 'is_assessable', 'isAssessable') ?? true,
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'subtopic_id': subtopicId,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'code': code,
      'description': description,
      'bloom_level': bloomLevel.value,
      'is_assessable': isAssessable,
      'sort_order': sortOrder,
      'is_active': isActive,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory LearningObjectiveModel.fromEntity(LearningObjective entity) {
    return LearningObjectiveModel(
      id: entity.id,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      code: entity.code,
      description: entity.description,
      bloomLevel: entity.bloomLevel,
      isAssessable: entity.isAssessable,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LearningObjective toEntity() {
    return LearningObjective(
      id: id,
      topicId: topicId,
      subtopicId: subtopicId,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      code: code,
      description: description,
      bloomLevel: bloomLevel,
      isAssessable: isAssessable,
      sortOrder: sortOrder,
      isActive: isActive,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, topicId, code, subjectId];
}

// ─── 10. ContentItemModel ────────────────────────────────────────────

class ContentItemModel extends Equatable {
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

  const ContentItemModel({
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

  factory ContentItemModel.fromJson(Map<String, dynamic> json) {
    return ContentItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      contentType: ContentType.fromString(
            _readField<String>(json, 'content_type', 'contentType'),
          ) ??
          ContentType.question,
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      topicId: _readField<String>(json, 'topic_id', 'topicId'),
      subtopicId: _readField<String>(json, 'subtopic_id', 'subtopicId'),
      curriculumId: _readField<String>(json, 'curriculum_id', 'curriculumId'),
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      questionCategory: QuestionCategory.fromString(
        _readField<String>(json, 'question_category', 'questionCategory'),
      ),
      difficultyLevel: DifficultyLevel.fromString(
        _readField<String>(json, 'difficulty_level', 'difficultyLevel'),
      ),
      bloomLevel: BloomTaxonomy.fromString(
        _readField<String>(json, 'bloom_level', 'bloomLevel'),
      ),
      body: json['body'] as String,
      bodyRich: _readNullableMap(
        json['body_rich'] ?? json['bodyRich'],
      ),
      options: _readNullableListOfMaps(
        json['options'],
      ),
      correctAnswer: _readNullableMap(
        json['correct_answer'] ?? json['correctAnswer'],
      ),
      stepByStepExplanation: _readField<String>(
        json, 'step_by_step_explanation', 'stepByStepExplanation',
      ),
      markingScheme: _readNullableMap(
        json['marking_scheme'] ?? json['markingScheme'],
      ),
      teacherNotes: _readField<String>(
        json, 'teacher_notes', 'teacherNotes',
      ),
      learningObjectiveIds: _readNullableListOfStrings(
        json['learning_objective_ids'] ?? json['learningObjectiveIds'],
      ),
      curriculumReferences: _readNullableListOfMaps(
        json['curriculum_references'] ?? json['curriculumReferences'],
      ),
      marksAllocated: _readField<int>(json, 'marks_allocated', 'marksAllocated'),
      timeAllocatedSeconds:
          _readField<int>(json, 'time_allocated_seconds', 'timeAllocatedSeconds'),
      sourceType: _readField<String>(json, 'source_type', 'sourceType'),
      sourceReference:
          _readField<String>(json, 'source_reference', 'sourceReference'),
      isPastQuestion:
          _readField<bool>(json, 'is_past_question', 'isPastQuestion'),
      pastExamYear: _readField<String>(json, 'past_exam_year', 'pastExamYear'),
      pastExamBody: _readField<String>(json, 'past_exam_body', 'pastExamBody'),
      hasLicensingRights:
          _readField<bool>(json, 'has_licensing_rights', 'hasLicensingRights'),
      licenseDetails: _readNullableMap(
        json['license_details'] ?? json['licenseDetails'],
      ),
      tags: _readNullableListOfStrings(json['tags']),
      mediaUrls: _readNullableListOfMaps(
        json['media_urls'] ?? json['mediaUrls'],
      ),
      status: ContentStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          ContentStatus.draft,
      version: json['version'] as int? ?? 1,
      parentContentId:
          _readField<String>(json, 'parent_content_id', 'parentContentId'),
      reviewCount: _readField<int>(json, 'review_count', 'reviewCount'),
      averageQualityScore: _readField<double>(
        json, 'average_quality_score', 'averageQualityScore',
      ),
      usageCount: _readField<int>(json, 'usage_count', 'usageCount'),
      isAiGenerated: _readField<bool>(json, 'is_ai_generated', 'isAiGenerated'),
      aiGenerationMetadata: _readNullableMap(
        json['ai_generation_metadata'] ?? json['aiGenerationMetadata'],
      ),
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      reviewedBy: _readField<String>(json, 'reviewed_by', 'reviewedBy'),
      publishedAt: _readNullableDateTime(json, 'published_at', 'publishedAt'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content_type': contentType.value,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'topic_id': topicId,
      'subtopic_id': subtopicId,
      'curriculum_id': curriculumId,
      'school_id': schoolId,
      'question_category': questionCategory?.value,
      'difficulty_level': difficultyLevel?.value,
      'bloom_level': bloomLevel?.value,
      'body': body,
      'body_rich': bodyRich,
      'options': options,
      'correct_answer': correctAnswer,
      'step_by_step_explanation': stepByStepExplanation,
      'marking_scheme': markingScheme,
      'teacher_notes': teacherNotes,
      'learning_objective_ids': learningObjectiveIds,
      'curriculum_references': curriculumReferences,
      'marks_allocated': marksAllocated,
      'time_allocated_seconds': timeAllocatedSeconds,
      'source_type': sourceType,
      'source_reference': sourceReference,
      'is_past_question': isPastQuestion,
      'past_exam_year': pastExamYear,
      'past_exam_body': pastExamBody,
      'has_licensing_rights': hasLicensingRights,
      'license_details': licenseDetails,
      'tags': tags,
      'media_urls': mediaUrls,
      'status': status.value,
      'version': version,
      'parent_content_id': parentContentId,
      'review_count': reviewCount,
      'average_quality_score': averageQualityScore,
      'usage_count': usageCount,
      'is_ai_generated': isAiGenerated,
      'ai_generation_metadata': aiGenerationMetadata,
      'metadata': metadata,
      'created_by': createdBy,
      'reviewed_by': reviewedBy,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  factory ContentItemModel.fromEntity(ContentItem entity) {
    return ContentItemModel(
      id: entity.id,
      title: entity.title,
      contentType: entity.contentType,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      curriculumId: entity.curriculumId,
      schoolId: entity.schoolId,
      questionCategory: entity.questionCategory,
      difficultyLevel: entity.difficultyLevel,
      bloomLevel: entity.bloomLevel,
      body: entity.body,
      bodyRich: entity.bodyRich,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      stepByStepExplanation: entity.stepByStepExplanation,
      markingScheme: entity.markingScheme,
      teacherNotes: entity.teacherNotes,
      learningObjectiveIds: entity.learningObjectiveIds,
      curriculumReferences: entity.curriculumReferences,
      marksAllocated: entity.marksAllocated,
      timeAllocatedSeconds: entity.timeAllocatedSeconds,
      sourceType: entity.sourceType,
      sourceReference: entity.sourceReference,
      isPastQuestion: entity.isPastQuestion,
      pastExamYear: entity.pastExamYear,
      pastExamBody: entity.pastExamBody,
      hasLicensingRights: entity.hasLicensingRights,
      licenseDetails: entity.licenseDetails,
      tags: entity.tags,
      mediaUrls: entity.mediaUrls,
      status: entity.status,
      version: entity.version,
      parentContentId: entity.parentContentId,
      reviewCount: entity.reviewCount,
      averageQualityScore: entity.averageQualityScore,
      usageCount: entity.usageCount,
      isAiGenerated: entity.isAiGenerated,
      aiGenerationMetadata: entity.aiGenerationMetadata,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      reviewedBy: entity.reviewedBy,
      publishedAt: entity.publishedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ContentItem toEntity() {
    return ContentItem(
      id: id,
      title: title,
      contentType: contentType,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      topicId: topicId,
      subtopicId: subtopicId,
      curriculumId: curriculumId,
      schoolId: schoolId,
      questionCategory: questionCategory,
      difficultyLevel: difficultyLevel,
      bloomLevel: bloomLevel,
      body: body,
      bodyRich: bodyRich,
      options: options,
      correctAnswer: correctAnswer,
      stepByStepExplanation: stepByStepExplanation,
      markingScheme: markingScheme,
      teacherNotes: teacherNotes,
      learningObjectiveIds: learningObjectiveIds,
      curriculumReferences: curriculumReferences,
      marksAllocated: marksAllocated,
      timeAllocatedSeconds: timeAllocatedSeconds,
      sourceType: sourceType,
      sourceReference: sourceReference,
      isPastQuestion: isPastQuestion,
      pastExamYear: pastExamYear,
      pastExamBody: pastExamBody,
      hasLicensingRights: hasLicensingRights,
      licenseDetails: licenseDetails,
      tags: tags,
      mediaUrls: mediaUrls,
      status: status,
      version: version,
      parentContentId: parentContentId,
      reviewCount: reviewCount,
      averageQualityScore: averageQualityScore,
      usageCount: usageCount,
      isAiGenerated: isAiGenerated,
      aiGenerationMetadata: aiGenerationMetadata,
      metadata: metadata,
      createdBy: createdBy,
      reviewedBy: reviewedBy,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, contentType, subjectId, version];
}

// ─── 11. ContentVersionModel ─────────────────────────────────────────

class ContentVersionModel extends Equatable {
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

  const ContentVersionModel({
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

  factory ContentVersionModel.fromJson(Map<String, dynamic> json) {
    return ContentVersionModel(
      id: json['id'] as String,
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId') ?? '',
      versionNumber:
          _readField<int>(json, 'version_number', 'versionNumber') ?? 1,
      title: json['title'] as String,
      body: json['body'] as String,
      bodyRich: _readNullableMap(json['body_rich'] ?? json['bodyRich']),
      options: _readNullableListOfMaps(json['options']),
      correctAnswer: _readNullableMap(
        json['correct_answer'] ?? json['correctAnswer'],
      ),
      stepByStepExplanation: _readField<String>(
        json, 'step_by_step_explanation', 'stepByStepExplanation',
      ),
      markingScheme: _readNullableMap(
        json['marking_scheme'] ?? json['markingScheme'],
      ),
      teacherNotes: _readField<String>(json, 'teacher_notes', 'teacherNotes'),
      difficultyLevel: DifficultyLevel.fromString(
        _readField<String>(json, 'difficulty_level', 'difficultyLevel'),
      ),
      bloomLevel: BloomTaxonomy.fromString(
        _readField<String>(json, 'bloom_level', 'bloomLevel'),
      ),
      changeSummary:
          _readField<String>(json, 'change_summary', 'changeSummary') ?? '',
      changedFields: _readNullableListOfStrings(
        json['changed_fields'] ?? json['changedFields'],
      ),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_item_id': contentItemId,
      'version_number': versionNumber,
      'title': title,
      'body': body,
      'body_rich': bodyRich,
      'options': options,
      'correct_answer': correctAnswer,
      'step_by_step_explanation': stepByStepExplanation,
      'marking_scheme': markingScheme,
      'teacher_notes': teacherNotes,
      'difficulty_level': difficultyLevel?.value,
      'bloom_level': bloomLevel?.value,
      'change_summary': changeSummary,
      'changed_fields': changedFields,
      'created_by': createdBy,
    };
  }

  factory ContentVersionModel.fromEntity(ContentVersion entity) {
    return ContentVersionModel(
      id: entity.id,
      contentItemId: entity.contentItemId,
      versionNumber: entity.versionNumber,
      title: entity.title,
      body: entity.body,
      bodyRich: entity.bodyRich,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      stepByStepExplanation: entity.stepByStepExplanation,
      markingScheme: entity.markingScheme,
      teacherNotes: entity.teacherNotes,
      difficultyLevel: entity.difficultyLevel,
      bloomLevel: entity.bloomLevel,
      changeSummary: entity.changeSummary,
      changedFields: entity.changedFields,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  ContentVersion toEntity() {
    return ContentVersion(
      id: id,
      contentItemId: contentItemId,
      versionNumber: versionNumber,
      title: title,
      body: body,
      bodyRich: bodyRich,
      options: options,
      correctAnswer: correctAnswer,
      stepByStepExplanation: stepByStepExplanation,
      markingScheme: markingScheme,
      teacherNotes: teacherNotes,
      difficultyLevel: difficultyLevel,
      bloomLevel: bloomLevel,
      changeSummary: changeSummary,
      changedFields: changedFields,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, contentItemId, versionNumber];
}

// ─── 12. ContentReviewModel ──────────────────────────────────────────

class ContentReviewModel extends Equatable {
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

  const ContentReviewModel({
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

  factory ContentReviewModel.fromJson(Map<String, dynamic> json) {
    return ContentReviewModel(
      id: json['id'] as String,
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId') ?? '',
      reviewerId: _readField<String>(json, 'reviewer_id', 'reviewerId') ?? '',
      qualityScore:
          (_readField<num>(json, 'quality_score', 'qualityScore') ?? 0).toDouble(),
      accuracyScore:
          (_readField<num>(json, 'accuracy_score', 'accuracyScore') ?? 0).toDouble(),
      relevanceScore:
          (_readField<num>(json, 'relevance_score', 'relevanceScore') ?? 0)
              .toDouble(),
      curriculumAlignmentScore: (_readField<num>(
        json,
        'curriculum_alignment_score',
        'curriculumAlignmentScore',
      ) ?? 0)
          .toDouble(),
      comment: json['comment'] as String?,
      status: ContentStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          ContentStatus.draft,
      reviewedAt: _readDateTime(json, 'reviewed_at', 'reviewedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_item_id': contentItemId,
      'reviewer_id': reviewerId,
      'quality_score': qualityScore,
      'accuracy_score': accuracyScore,
      'relevance_score': relevanceScore,
      'curriculum_alignment_score': curriculumAlignmentScore,
      'comment': comment,
      'status': status.value,
    };
  }

  factory ContentReviewModel.fromEntity(ContentReview entity) {
    return ContentReviewModel(
      id: entity.id,
      contentItemId: entity.contentItemId,
      reviewerId: entity.reviewerId,
      qualityScore: entity.qualityScore,
      accuracyScore: entity.accuracyScore,
      relevanceScore: entity.relevanceScore,
      curriculumAlignmentScore: entity.curriculumAlignmentScore,
      comment: entity.comment,
      status: entity.status,
      reviewedAt: entity.reviewedAt,
    );
  }

  ContentReview toEntity() {
    return ContentReview(
      id: id,
      contentItemId: contentItemId,
      reviewerId: reviewerId,
      qualityScore: qualityScore,
      accuracyScore: accuracyScore,
      relevanceScore: relevanceScore,
      curriculumAlignmentScore: curriculumAlignmentScore,
      comment: comment,
      status: status,
      reviewedAt: reviewedAt,
    );
  }

  @override
  List<Object?> get props => [id, contentItemId, reviewerId];
}

// ─── 13. ContentImportModel ──────────────────────────────────────────

class ContentImportModel extends Equatable {
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

  const ContentImportModel({
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

  factory ContentImportModel.fromJson(Map<String, dynamic> json) {
    return ContentImportModel(
      id: json['id'] as String,
      schoolId: _readField<String>(json, 'school_id', 'schoolId') ?? '',
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      fileName: _readField<String>(json, 'file_name', 'fileName') ?? '',
      fileUrl: _readField<String>(json, 'file_url', 'fileUrl') ?? '',
      fileSizeBytes:
          _readField<int>(json, 'file_size_bytes', 'fileSizeBytes') ?? 0,
      totalItems: _readField<int>(json, 'total_items', 'totalItems') ?? 0,
      processedItems:
          _readField<int>(json, 'processed_items', 'processedItems') ?? 0,
      successfulItems:
          _readField<int>(json, 'successful_items', 'successfulItems') ?? 0,
      failedItems: _readField<int>(json, 'failed_items', 'failedItems') ?? 0,
      status: ImportStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          ImportStatus.pending,
      errorLog: _readNullableListOfMaps(
        json['error_log'] ?? json['errorLog'],
      ),
      mappingConfig: _readNullableMap(
        json['mapping_config'] ?? json['mappingConfig'],
      ),
      hasLicensingDeclaration: _readField<bool>(
        json, 'has_licensing_declaration', 'hasLicensingDeclaration',
      ),
      licenseDetails: _readNullableMap(
        json['license_details'] ?? json['licenseDetails'],
      ),
      startedAt: _readNullableDateTime(json, 'started_at', 'startedAt'),
      completedAt: _readNullableDateTime(json, 'completed_at', 'completedAt'),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'total_items': totalItems,
      'processed_items': processedItems,
      'successful_items': successfulItems,
      'failed_items': failedItems,
      'status': status.value,
      'error_log': errorLog,
      'mapping_config': mappingConfig,
      'has_licensing_declaration': hasLicensingDeclaration,
      'license_details': licenseDetails,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  factory ContentImportModel.fromEntity(ContentImport entity) {
    return ContentImportModel(
      id: entity.id,
      schoolId: entity.schoolId,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileSizeBytes: entity.fileSizeBytes,
      totalItems: entity.totalItems,
      processedItems: entity.processedItems,
      successfulItems: entity.successfulItems,
      failedItems: entity.failedItems,
      status: entity.status,
      errorLog: entity.errorLog,
      mappingConfig: entity.mappingConfig,
      hasLicensingDeclaration: entity.hasLicensingDeclaration,
      licenseDetails: entity.licenseDetails,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  ContentImport toEntity() {
    return ContentImport(
      id: id,
      schoolId: schoolId,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      totalItems: totalItems,
      processedItems: processedItems,
      successfulItems: successfulItems,
      failedItems: failedItems,
      status: status,
      errorLog: errorLog,
      mappingConfig: mappingConfig,
      hasLicensingDeclaration: hasLicensingDeclaration,
      licenseDetails: licenseDetails,
      startedAt: startedAt,
      completedAt: completedAt,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, subjectId, fileName];
}

// ─── 14. ContentCollectionModel ──────────────────────────────────────

class ContentCollectionModel extends Equatable {
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

  const ContentCollectionModel({
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

  factory ContentCollectionModel.fromJson(Map<String, dynamic> json) {
    return ContentCollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      collectionType:
          _readField<String>(json, 'collection_type', 'collectionType') ?? '',
      isPublic: _readField<bool>(json, 'is_public', 'isPublic') ?? false,
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      contentCount: _readField<int>(json, 'content_count', 'contentCount') ?? 0,
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'school_id': schoolId,
      'collection_type': collectionType,
      'is_public': isPublic,
      'sort_order': sortOrder,
      'content_count': contentCount,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory ContentCollectionModel.fromEntity(ContentCollection entity) {
    return ContentCollectionModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      schoolId: entity.schoolId,
      collectionType: entity.collectionType,
      isPublic: entity.isPublic,
      sortOrder: entity.sortOrder,
      contentCount: entity.contentCount,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ContentCollection toEntity() {
    return ContentCollection(
      id: id,
      name: name,
      description: description,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      schoolId: schoolId,
      collectionType: collectionType,
      isPublic: isPublic,
      sortOrder: sortOrder,
      contentCount: contentCount,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, subjectId];
}

// ─── 15. ContentCollectionItemModel ──────────────────────────────────

class ContentCollectionItemModel extends Equatable {
  final String id;
  final String collectionId;
  final String contentItemId;
  final int sortOrder;
  final DateTime addedAt;

  const ContentCollectionItemModel({
    required this.id,
    required this.collectionId,
    required this.contentItemId,
    required this.sortOrder,
    required this.addedAt,
  });

  factory ContentCollectionItemModel.fromJson(Map<String, dynamic> json) {
    return ContentCollectionItemModel(
      id: json['id'] as String,
      collectionId:
          _readField<String>(json, 'collection_id', 'collectionId') ?? '',
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId') ?? '',
      sortOrder: _readField<int>(json, 'sort_order', 'sortOrder') ?? 0,
      addedAt: _readDateTime(json, 'added_at', 'addedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_id': collectionId,
      'content_item_id': contentItemId,
      'sort_order': sortOrder,
    };
  }

  factory ContentCollectionItemModel.fromEntity(ContentCollectionItem entity) {
    return ContentCollectionItemModel(
      id: entity.id,
      collectionId: entity.collectionId,
      contentItemId: entity.contentItemId,
      sortOrder: entity.sortOrder,
      addedAt: entity.addedAt,
    );
  }

  ContentCollectionItem toEntity() {
    return ContentCollectionItem(
      id: id,
      collectionId: collectionId,
      contentItemId: contentItemId,
      sortOrder: sortOrder,
      addedAt: addedAt,
    );
  }

  @override
  List<Object?> get props => [id, collectionId, contentItemId];
}

// ─── 16. AiCurriculumConfigModel ─────────────────────────────────────

class AiCurriculumConfigModel extends Equatable {
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

  const AiCurriculumConfigModel({
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

  factory AiCurriculumConfigModel.fromJson(Map<String, dynamic> json) {
    return AiCurriculumConfigModel(
      id: json['id'] as String,
      schoolId: _readField<String>(json, 'school_id', 'schoolId') ?? '',
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      curriculumId: _readField<String>(json, 'curriculum_id', 'curriculumId') ?? '',
      preferredDifficulty: DifficultyLevel.fromString(
        _readField<String>(json, 'preferred_difficulty', 'preferredDifficulty'),
      ),
      preferredBloomLevels: _readNullableBloomList(
        json['preferred_bloom_levels'] ?? json['preferredBloomLevels'],
      ),
      questionTypeDistribution: _readNullableMap(
        json['question_type_distribution'] ?? json['questionTypeDistribution'],
      ),
      languageStyle:
          _readField<String>(json, 'language_style', 'languageStyle'),
      includeExplanations:
          _readField<bool>(json, 'include_explanations', 'includeExplanations'),
      includeMarkingSchemes:
          _readField<bool>(json, 'include_marking_schemes', 'includeMarkingSchemes'),
      includeTeacherNotes:
          _readField<bool>(json, 'include_teacher_notes', 'includeTeacherNotes'),
      contentTone: _readField<String>(json, 'content_tone', 'contentTone'),
      culturalContext:
          _readField<String>(json, 'cultural_context', 'culturalContext'),
      maxQuestionsPerGeneration: _readField<int>(
        json, 'max_questions_per_generation', 'maxQuestionsPerGeneration',
      ),
      qualityThreshold: _readField<double>(
        json, 'quality_threshold', 'qualityThreshold',
      ),
      autoApproveThreshold: _readField<double>(
        json, 'auto_approve_threshold', 'autoApproveThreshold',
      ),
      topicCoveragePreference: _readField<String>(
        json, 'topic_coverage_preference', 'topicCoveragePreference',
      ),
      metadata: _readNullableMap(json['metadata']),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'subject_id': subjectId,
      'educational_level_id': educationalLevelId,
      'curriculum_id': curriculumId,
      'preferred_difficulty': preferredDifficulty?.value,
      'preferred_bloom_levels':
          preferredBloomLevels?.map((e) => e.value).toList(),
      'question_type_distribution': questionTypeDistribution,
      'language_style': languageStyle,
      'include_explanations': includeExplanations,
      'include_marking_schemes': includeMarkingSchemes,
      'include_teacher_notes': includeTeacherNotes,
      'content_tone': contentTone,
      'cultural_context': culturalContext,
      'max_questions_per_generation': maxQuestionsPerGeneration,
      'quality_threshold': qualityThreshold,
      'auto_approve_threshold': autoApproveThreshold,
      'topic_coverage_preference': topicCoveragePreference,
      'metadata': metadata,
      'created_by': createdBy,
    };
  }

  factory AiCurriculumConfigModel.fromEntity(AiCurriculumConfig entity) {
    return AiCurriculumConfigModel(
      id: entity.id,
      schoolId: entity.schoolId,
      subjectId: entity.subjectId,
      educationalLevelId: entity.educationalLevelId,
      curriculumId: entity.curriculumId,
      preferredDifficulty: entity.preferredDifficulty,
      preferredBloomLevels: entity.preferredBloomLevels,
      questionTypeDistribution: entity.questionTypeDistribution,
      languageStyle: entity.languageStyle,
      includeExplanations: entity.includeExplanations,
      includeMarkingSchemes: entity.includeMarkingSchemes,
      includeTeacherNotes: entity.includeTeacherNotes,
      contentTone: entity.contentTone,
      culturalContext: entity.culturalContext,
      maxQuestionsPerGeneration: entity.maxQuestionsPerGeneration,
      qualityThreshold: entity.qualityThreshold,
      autoApproveThreshold: entity.autoApproveThreshold,
      topicCoveragePreference: entity.topicCoveragePreference,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiCurriculumConfig toEntity() {
    return AiCurriculumConfig(
      id: id,
      schoolId: schoolId,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
      curriculumId: curriculumId,
      preferredDifficulty: preferredDifficulty,
      preferredBloomLevels: preferredBloomLevels,
      questionTypeDistribution: questionTypeDistribution,
      languageStyle: languageStyle,
      includeExplanations: includeExplanations,
      includeMarkingSchemes: includeMarkingSchemes,
      includeTeacherNotes: includeTeacherNotes,
      contentTone: contentTone,
      culturalContext: culturalContext,
      maxQuestionsPerGeneration: maxQuestionsPerGeneration,
      qualityThreshold: qualityThreshold,
      autoApproveThreshold: autoApproveThreshold,
      topicCoveragePreference: topicCoveragePreference,
      metadata: metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, schoolId, subjectId, curriculumId];
}

// ─── 17. AiGenerationRuleModel ───────────────────────────────────────

class AiGenerationRuleModel extends Equatable {
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

  const AiGenerationRuleModel({
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

  factory AiGenerationRuleModel.fromJson(Map<String, dynamic> json) {
    return AiGenerationRuleModel(
      id: json['id'] as String,
      educationalLevelId:
          _readField<String>(json, 'educational_level_id', 'educationalLevelId') ??
              '',
      subjectId: _readField<String>(json, 'subject_id', 'subjectId') ?? '',
      ruleName: _readField<String>(json, 'rule_name', 'ruleName') ?? '',
      ruleType: _readField<String>(json, 'rule_type', 'ruleType') ?? '',
      conditions: _readNullableMap(json['conditions']),
      actions: _readNullableMap(json['actions']),
      priority: _readField<int>(json, 'priority', 'priority') ?? 0,
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'educational_level_id': educationalLevelId,
      'subject_id': subjectId,
      'rule_name': ruleName,
      'rule_type': ruleType,
      'conditions': conditions,
      'actions': actions,
      'priority': priority,
      'is_active': isActive,
    };
  }

  factory AiGenerationRuleModel.fromEntity(AiGenerationRule entity) {
    return AiGenerationRuleModel(
      id: entity.id,
      educationalLevelId: entity.educationalLevelId,
      subjectId: entity.subjectId,
      ruleName: entity.ruleName,
      ruleType: entity.ruleType,
      conditions: entity.conditions,
      actions: entity.actions,
      priority: entity.priority,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiGenerationRule toEntity() {
    return AiGenerationRule(
      id: id,
      educationalLevelId: educationalLevelId,
      subjectId: subjectId,
      ruleName: ruleName,
      ruleType: ruleType,
      conditions: conditions,
      actions: actions,
      priority: priority,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, ruleName, subjectId];
}

// ─── 18. AnswerRepositoryEntryModel ──────────────────────────────────

class AnswerRepositoryEntryModel extends Equatable {
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

  const AnswerRepositoryEntryModel({
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

  factory AnswerRepositoryEntryModel.fromJson(Map<String, dynamic> json) {
    return AnswerRepositoryEntryModel(
      id: json['id'] as String,
      contentItemId:
          _readField<String>(json, 'content_item_id', 'contentItemId') ?? '',
      correctAnswers: _readListOfMaps(
        json['correct_answers'] ?? json['correctAnswers'],
      ),
      stepByStepExplanation: _readField<String>(
        json, 'step_by_step_explanation', 'stepByStepExplanation',
      ),
      explanationRich: _readNullableMap(
        json['explanation_rich'] ?? json['explanationRich'],
      ),
      markingScheme: _readNullableMap(
        json['marking_scheme'] ?? json['markingScheme'],
      ),
      alternativeAnswers: _readNullableListOfMaps(
        json['alternative_answers'] ?? json['alternativeAnswers'],
      ),
      commonMistakes: _readNullableListOfMaps(
        json['common_mistakes'] ?? json['commonMistakes'],
      ),
      teacherNotes: _readField<String>(json, 'teacher_notes', 'teacherNotes'),
      curriculumReferences: _readNullableListOfMaps(
        json['curriculum_references'] ?? json['curriculumReferences'],
      ),
      learningObjectiveIds: _readNullableListOfStrings(
        json['learning_objective_ids'] ?? json['learningObjectiveIds'],
      ),
      difficultyJustification: _readField<String>(
        json, 'difficulty_justification', 'difficultyJustification',
      ),
      version: json['version'] as int? ?? 1,
      isVerified: _readField<bool>(json, 'is_verified', 'isVerified') ?? false,
      verifiedBy: _readField<String>(json, 'verified_by', 'verifiedBy'),
      verifiedAt: _readNullableDateTime(json, 'verified_at', 'verifiedAt'),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_item_id': contentItemId,
      'correct_answers': correctAnswers,
      'step_by_step_explanation': stepByStepExplanation,
      'explanation_rich': explanationRich,
      'marking_scheme': markingScheme,
      'alternative_answers': alternativeAnswers,
      'common_mistakes': commonMistakes,
      'teacher_notes': teacherNotes,
      'curriculum_references': curriculumReferences,
      'learning_objective_ids': learningObjectiveIds,
      'difficulty_justification': difficultyJustification,
      'version': version,
      'is_verified': isVerified,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  factory AnswerRepositoryEntryModel.fromEntity(AnswerRepositoryEntry entity) {
    return AnswerRepositoryEntryModel(
      id: entity.id,
      contentItemId: entity.contentItemId,
      correctAnswers: entity.correctAnswers,
      stepByStepExplanation: entity.stepByStepExplanation,
      explanationRich: entity.explanationRich,
      markingScheme: entity.markingScheme,
      alternativeAnswers: entity.alternativeAnswers,
      commonMistakes: entity.commonMistakes,
      teacherNotes: entity.teacherNotes,
      curriculumReferences: entity.curriculumReferences,
      learningObjectiveIds: entity.learningObjectiveIds,
      difficultyJustification: entity.difficultyJustification,
      version: entity.version,
      isVerified: entity.isVerified,
      verifiedBy: entity.verifiedBy,
      verifiedAt: entity.verifiedAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AnswerRepositoryEntry toEntity() {
    return AnswerRepositoryEntry(
      id: id,
      contentItemId: contentItemId,
      correctAnswers: correctAnswers,
      stepByStepExplanation: stepByStepExplanation,
      explanationRich: explanationRich,
      markingScheme: markingScheme,
      alternativeAnswers: alternativeAnswers,
      commonMistakes: commonMistakes,
      teacherNotes: teacherNotes,
      curriculumReferences: curriculumReferences,
      learningObjectiveIds: learningObjectiveIds,
      difficultyJustification: difficultyJustification,
      version: version,
      isVerified: isVerified,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, contentItemId, version];
}

// ─── 19. AuditEntryModel ─────────────────────────────────────────────

class AuditEntryModel extends Equatable {
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

  const AuditEntryModel({
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

  factory AuditEntryModel.fromJson(Map<String, dynamic> json) {
    return AuditEntryModel(
      id: json['id'] as String,
      userId: _readField<String>(json, 'user_id', 'userId') ?? '',
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      action: AuditAction.fromString(
            _readField<String>(json, 'action', 'action'),
          ) ??
          AuditAction.read,
      resourceType:
          _readField<String>(json, 'resource_type', 'resourceType') ?? '',
      resourceId: _readField<String>(json, 'resource_id', 'resourceId'),
      oldValues: _readNullableMap(json['old_values'] ?? json['oldValues']),
      newValues: _readNullableMap(json['new_values'] ?? json['newValues']),
      ipAddress: _readField<String>(json, 'ip_address', 'ipAddress'),
      userAgent: _readField<String>(json, 'user_agent', 'userAgent'),
      deviceId: _readField<String>(json, 'device_id', 'deviceId'),
      sessionId: _readField<String>(json, 'session_id', 'sessionId'),
      apiEndpoint: _readField<String>(json, 'api_endpoint', 'apiEndpoint'),
      httpMethod: _readField<String>(json, 'http_method', 'httpMethod'),
      responseStatus:
          _readField<int>(json, 'response_status', 'responseStatus'),
      durationMs: _readField<int>(json, 'duration_ms', 'durationMs'),
      metadata: _readNullableMap(json['metadata']),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'action': action.value,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_id': deviceId,
      'session_id': sessionId,
      'api_endpoint': apiEndpoint,
      'http_method': httpMethod,
      'response_status': responseStatus,
      'duration_ms': durationMs,
      'metadata': metadata,
    };
  }

  factory AuditEntryModel.fromEntity(AuditEntry entity) {
    return AuditEntryModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      action: entity.action,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      oldValues: entity.oldValues,
      newValues: entity.newValues,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      deviceId: entity.deviceId,
      sessionId: entity.sessionId,
      apiEndpoint: entity.apiEndpoint,
      httpMethod: entity.httpMethod,
      responseStatus: entity.responseStatus,
      durationMs: entity.durationMs,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  AuditEntry toEntity() {
    return AuditEntry(
      id: id,
      userId: userId,
      schoolId: schoolId,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      oldValues: oldValues,
      newValues: newValues,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      sessionId: sessionId,
      apiEndpoint: apiEndpoint,
      httpMethod: httpMethod,
      responseStatus: responseStatus,
      durationMs: durationMs,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, action, resourceType];
}

// ─── 20. MfaConfigurationModel ───────────────────────────────────────

class MfaConfigurationModel extends Equatable {
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

  const MfaConfigurationModel({
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

  factory MfaConfigurationModel.fromJson(Map<String, dynamic> json) {
    return MfaConfigurationModel(
      id: json['id'] as String,
      userId: _readField<String>(json, 'user_id', 'userId') ?? '',
      mfaMethod: MfaMethod.fromString(
            _readField<String>(json, 'mfa_method', 'mfaMethod'),
          ) ??
          MfaMethod.authenticatorApp,
      isEnabled: _readField<bool>(json, 'is_enabled', 'isEnabled') ?? false,
      isVerified: _readField<bool>(json, 'is_verified', 'isVerified') ?? false,
      secretEncrypted:
          _readField<String>(json, 'secret_encrypted', 'secretEncrypted'),
      backupCodesEncrypted:
          _readField<String>(json, 'backup_codes_encrypted', 'backupCodesEncrypted'),
      phoneNumberEncrypted: _readField<String>(
        json, 'phone_number_encrypted', 'phoneNumberEncrypted',
      ),
      verificationAttempts:
          _readField<int>(json, 'verification_attempts', 'verificationAttempts'),
      lastUsedAt: _readNullableDateTime(json, 'last_used_at', 'lastUsedAt'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mfa_method': mfaMethod.value,
      'is_enabled': isEnabled,
      'is_verified': isVerified,
      'secret_encrypted': secretEncrypted,
      'backup_codes_encrypted': backupCodesEncrypted,
      'phone_number_encrypted': phoneNumberEncrypted,
      'verification_attempts': verificationAttempts,
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  factory MfaConfigurationModel.fromEntity(MfaConfiguration entity) {
    return MfaConfigurationModel(
      id: entity.id,
      userId: entity.userId,
      mfaMethod: entity.mfaMethod,
      isEnabled: entity.isEnabled,
      isVerified: entity.isVerified,
      secretEncrypted: entity.secretEncrypted,
      backupCodesEncrypted: entity.backupCodesEncrypted,
      phoneNumberEncrypted: entity.phoneNumberEncrypted,
      verificationAttempts: entity.verificationAttempts,
      lastUsedAt: entity.lastUsedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MfaConfiguration toEntity() {
    return MfaConfiguration(
      id: id,
      userId: userId,
      mfaMethod: mfaMethod,
      isEnabled: isEnabled,
      isVerified: isVerified,
      secretEncrypted: secretEncrypted,
      backupCodesEncrypted: backupCodesEncrypted,
      phoneNumberEncrypted: phoneNumberEncrypted,
      verificationAttempts: verificationAttempts,
      lastUsedAt: lastUsedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, mfaMethod];
}

// ─── 21. ApiKeyModel ─────────────────────────────────────────────────

class ApiKeyModel extends Equatable {
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

  const ApiKeyModel({
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

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      id: json['id'] as String,
      userId: _readField<String>(json, 'user_id', 'userId') ?? '',
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      keyHash: _readField<String>(json, 'key_hash', 'keyHash') ?? '',
      keyPrefix: _readField<String>(json, 'key_prefix', 'keyPrefix') ?? '',
      name: json['name'] as String,
      scopes: _readNullableListOfStrings(json['scopes']),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      rateLimitOverride:
          _readField<int>(json, 'rate_limit_override', 'rateLimitOverride'),
      expiresAt: _readNullableDateTime(json, 'expires_at', 'expiresAt'),
      lastUsedAt: _readNullableDateTime(json, 'last_used_at', 'lastUsedAt'),
      usageCount: _readField<int>(json, 'usage_count', 'usageCount'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'school_id': schoolId,
      'key_hash': keyHash,
      'key_prefix': keyPrefix,
      'name': name,
      'scopes': scopes,
      'is_active': isActive,
      'rate_limit_override': rateLimitOverride,
      'expires_at': expiresAt?.toIso8601String(),
      'usage_count': usageCount,
    };
  }

  factory ApiKeyModel.fromEntity(ApiKey entity) {
    return ApiKeyModel(
      id: entity.id,
      userId: entity.userId,
      schoolId: entity.schoolId,
      keyHash: entity.keyHash,
      keyPrefix: entity.keyPrefix,
      name: entity.name,
      scopes: entity.scopes,
      isActive: entity.isActive,
      rateLimitOverride: entity.rateLimitOverride,
      expiresAt: entity.expiresAt,
      lastUsedAt: entity.lastUsedAt,
      usageCount: entity.usageCount,
      createdAt: entity.createdAt,
    );
  }

  ApiKey toEntity() {
    return ApiKey(
      id: id,
      userId: userId,
      schoolId: schoolId,
      keyHash: keyHash,
      keyPrefix: keyPrefix,
      name: name,
      scopes: scopes,
      isActive: isActive,
      rateLimitOverride: rateLimitOverride,
      expiresAt: expiresAt,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, keyHash];
}

// ─── 22. SecurityEventModel ──────────────────────────────────────────

class SecurityEventModel extends Equatable {
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

  const SecurityEventModel({
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

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      id: json['id'] as String,
      eventType: _readField<String>(json, 'event_type', 'eventType') ?? '',
      severity: AlertSeverity.fromString(
            _readField<String>(json, 'severity', 'severity'),
          ) ??
          AlertSeverity.info,
      userId: _readField<String>(json, 'user_id', 'userId'),
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      ipAddress: _readField<String>(json, 'ip_address', 'ipAddress'),
      userAgent: _readField<String>(json, 'user_agent', 'userAgent'),
      details: _readNullableMap(json['details']),
      isResolved: _readField<bool>(json, 'is_resolved', 'isResolved') ?? false,
      resolvedBy: _readField<String>(json, 'resolved_by', 'resolvedBy'),
      resolvedAt: _readNullableDateTime(json, 'resolved_at', 'resolvedAt'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'severity': severity.value,
      'user_id': userId,
      'school_id': schoolId,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'details': details,
      'is_resolved': isResolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory SecurityEventModel.fromEntity(SecurityEvent entity) {
    return SecurityEventModel(
      id: entity.id,
      eventType: entity.eventType,
      severity: entity.severity,
      userId: entity.userId,
      schoolId: entity.schoolId,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      details: entity.details,
      isResolved: entity.isResolved,
      resolvedBy: entity.resolvedBy,
      resolvedAt: entity.resolvedAt,
      createdAt: entity.createdAt,
    );
  }

  SecurityEvent toEntity() {
    return SecurityEvent(
      id: id,
      eventType: eventType,
      severity: severity,
      userId: userId,
      schoolId: schoolId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      details: details,
      isResolved: isResolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, eventType, severity];
}

// ─── 23. RateLimitConfigModel ────────────────────────────────────────

class RateLimitConfigModel extends Equatable {
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

  const RateLimitConfigModel({
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

  factory RateLimitConfigModel.fromJson(Map<String, dynamic> json) {
    return RateLimitConfigModel(
      id: json['id'] as String,
      scope: RateLimitScope.fromString(
            _readField<String>(json, 'scope', 'scope'),
          ) ??
          RateLimitScope.global,
      identifier: _readField<String>(json, 'identifier', 'identifier') ?? '',
      endpointPattern:
          _readField<String>(json, 'endpoint_pattern', 'endpointPattern'),
      maxRequests: _readField<int>(json, 'max_requests', 'maxRequests') ?? 100,
      windowSeconds:
          _readField<int>(json, 'window_seconds', 'windowSeconds') ?? 60,
      actionOnLimit:
          _readField<String>(json, 'action_on_limit', 'actionOnLimit'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scope': scope.value,
      'identifier': identifier,
      'endpoint_pattern': endpointPattern,
      'max_requests': maxRequests,
      'window_seconds': windowSeconds,
      'action_on_limit': actionOnLimit,
      'is_active': isActive,
    };
  }

  factory RateLimitConfigModel.fromEntity(RateLimitConfig entity) {
    return RateLimitConfigModel(
      id: entity.id,
      scope: entity.scope,
      identifier: entity.identifier,
      endpointPattern: entity.endpointPattern,
      maxRequests: entity.maxRequests,
      windowSeconds: entity.windowSeconds,
      actionOnLimit: entity.actionOnLimit,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RateLimitConfig toEntity() {
    return RateLimitConfig(
      id: id,
      scope: scope,
      identifier: identifier,
      endpointPattern: endpointPattern,
      maxRequests: maxRequests,
      windowSeconds: windowSeconds,
      actionOnLimit: actionOnLimit,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, scope, identifier];
}

// ─── 24. UserSessionModel ────────────────────────────────────────────

class UserSessionModel extends Equatable {
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

  const UserSessionModel({
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

  factory UserSessionModel.fromJson(Map<String, dynamic> json) {
    return UserSessionModel(
      id: json['id'] as String,
      userId: _readField<String>(json, 'user_id', 'userId') ?? '',
      sessionTokenHash:
          _readField<String>(json, 'session_token_hash', 'sessionTokenHash') ?? '',
      deviceId: _readField<String>(json, 'device_id', 'deviceId'),
      deviceName: _readField<String>(json, 'device_name', 'deviceName'),
      deviceType: _readField<String>(json, 'device_type', 'deviceType'),
      ipAddress: _readField<String>(json, 'ip_address', 'ipAddress'),
      userAgent: _readField<String>(json, 'user_agent', 'userAgent'),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      lastActivityAt:
          _readDateTime(json, 'last_activity_at', 'lastActivityAt'),
      expiresAt: _readDateTime(json, 'expires_at', 'expiresAt'),
      invalidatedBy:
          _readField<String>(json, 'invalidated_by', 'invalidatedBy'),
      invalidatedAt:
          _readNullableDateTime(json, 'invalidated_at', 'invalidatedAt'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_token_hash': sessionTokenHash,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'is_active': isActive,
      'last_activity_at': lastActivityAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'invalidated_by': invalidatedBy,
      'invalidated_at': invalidatedAt?.toIso8601String(),
    };
  }

  factory UserSessionModel.fromEntity(UserSession entity) {
    return UserSessionModel(
      id: entity.id,
      userId: entity.userId,
      sessionTokenHash: entity.sessionTokenHash,
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      deviceType: entity.deviceType,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      isActive: entity.isActive,
      lastActivityAt: entity.lastActivityAt,
      expiresAt: entity.expiresAt,
      invalidatedBy: entity.invalidatedBy,
      invalidatedAt: entity.invalidatedAt,
      createdAt: entity.createdAt,
    );
  }

  UserSession toEntity() {
    return UserSession(
      id: id,
      userId: userId,
      sessionTokenHash: sessionTokenHash,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: isActive,
      lastActivityAt: lastActivityAt,
      expiresAt: expiresAt,
      invalidatedBy: invalidatedBy,
      invalidatedAt: invalidatedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, sessionTokenHash];
}

// ─── 25. SystemMetricModel ───────────────────────────────────────────

class SystemMetricModel extends Equatable {
  final String id;
  final String metricName;
  final MetricType metricType;
  final double value;
  final String? unit;
  final Map<String, dynamic>? tags;
  final String? schoolId;
  final DateTime recordedAt;

  const SystemMetricModel({
    required this.id,
    required this.metricName,
    required this.metricType,
    required this.value,
    this.unit,
    this.tags,
    this.schoolId,
    required this.recordedAt,
  });

  factory SystemMetricModel.fromJson(Map<String, dynamic> json) {
    return SystemMetricModel(
      id: json['id'] as String,
      metricName: _readField<String>(json, 'metric_name', 'metricName') ?? '',
      metricType: MetricType.fromString(
            _readField<String>(json, 'metric_type', 'metricType'),
          ) ??
          MetricType.counter,
      value: (_readField<num>(json, 'value', 'value') ?? 0).toDouble(),
      unit: json['unit'] as String?,
      tags: _readNullableMap(json['tags']),
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      recordedAt: _readDateTime(json, 'recorded_at', 'recordedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metric_name': metricName,
      'metric_type': metricType.value,
      'value': value,
      'unit': unit,
      'tags': tags,
      'school_id': schoolId,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  factory SystemMetricModel.fromEntity(SystemMetric entity) {
    return SystemMetricModel(
      id: entity.id,
      metricName: entity.metricName,
      metricType: entity.metricType,
      value: entity.value,
      unit: entity.unit,
      tags: entity.tags,
      schoolId: entity.schoolId,
      recordedAt: entity.recordedAt,
    );
  }

  SystemMetric toEntity() {
    return SystemMetric(
      id: id,
      metricName: metricName,
      metricType: metricType,
      value: value,
      unit: unit,
      tags: tags,
      schoolId: schoolId,
      recordedAt: recordedAt,
    );
  }

  @override
  List<Object?> get props => [id, metricName, metricType];
}

// ─── 26. AlertRuleModel ──────────────────────────────────────────────

class AlertRuleModel extends Equatable {
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

  const AlertRuleModel({
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

  factory AlertRuleModel.fromJson(Map<String, dynamic> json) {
    return AlertRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      metricName:
          _readField<String>(json, 'metric_name', 'metricName') ?? '',
      conditionOperator:
          _readField<String>(json, 'condition_operator', 'conditionOperator') ?? '',
      thresholdValue: (_readField<num>(
        json, 'threshold_value', 'thresholdValue',
      ) ?? 0).toDouble(),
      durationSeconds:
          _readField<int>(json, 'duration_seconds', 'durationSeconds'),
      severity: AlertSeverity.fromString(
            _readField<String>(json, 'severity', 'severity'),
          ) ??
          AlertSeverity.warning,
      notificationChannels: _readNullableListOfStrings(
        json['notification_channels'] ?? json['notificationChannels'],
      ),
      isActive: _readField<bool>(json, 'is_active', 'isActive') ?? true,
      lastTriggeredAt:
          _readNullableDateTime(json, 'last_triggered_at', 'lastTriggeredAt'),
      createdBy: _readField<String>(json, 'created_by', 'createdBy'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _readDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metric_name': metricName,
      'condition_operator': conditionOperator,
      'threshold_value': thresholdValue,
      'duration_seconds': durationSeconds,
      'severity': severity.value,
      'notification_channels': notificationChannels,
      'is_active': isActive,
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  factory AlertRuleModel.fromEntity(AlertRule entity) {
    return AlertRuleModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      metricName: entity.metricName,
      conditionOperator: entity.conditionOperator,
      thresholdValue: entity.thresholdValue,
      durationSeconds: entity.durationSeconds,
      severity: entity.severity,
      notificationChannels: entity.notificationChannels,
      isActive: entity.isActive,
      lastTriggeredAt: entity.lastTriggeredAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AlertRule toEntity() {
    return AlertRule(
      id: id,
      name: name,
      description: description,
      metricName: metricName,
      conditionOperator: conditionOperator,
      thresholdValue: thresholdValue,
      durationSeconds: durationSeconds,
      severity: severity,
      notificationChannels: notificationChannels,
      isActive: isActive,
      lastTriggeredAt: lastTriggeredAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, metricName];
}

// ─── 27. AlertIncidentModel ──────────────────────────────────────────

class AlertIncidentModel extends Equatable {
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

  const AlertIncidentModel({
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

  factory AlertIncidentModel.fromJson(Map<String, dynamic> json) {
    return AlertIncidentModel(
      id: json['id'] as String,
      alertRuleId:
          _readField<String>(json, 'alert_rule_id', 'alertRuleId') ?? '',
      currentValue: (_readField<num>(
        json, 'current_value', 'currentValue',
      ) ?? 0).toDouble(),
      thresholdValue: (_readField<num>(
        json, 'threshold_value', 'thresholdValue',
      ) ?? 0).toDouble(),
      severity: AlertSeverity.fromString(
            _readField<String>(json, 'severity', 'severity'),
          ) ??
          AlertSeverity.warning,
      status: json['status'] as String? ?? 'open',
      acknowledgedBy:
          _readField<String>(json, 'acknowledged_by', 'acknowledgedBy'),
      acknowledgedAt:
          _readNullableDateTime(json, 'acknowledged_at', 'acknowledgedAt'),
      resolvedAt: _readNullableDateTime(json, 'resolved_at', 'resolvedAt'),
      resolutionNotes:
          _readField<String>(json, 'resolution_notes', 'resolutionNotes'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_rule_id': alertRuleId,
      'current_value': currentValue,
      'threshold_value': thresholdValue,
      'severity': severity.value,
      'status': status,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
    };
  }

  factory AlertIncidentModel.fromEntity(AlertIncident entity) {
    return AlertIncidentModel(
      id: entity.id,
      alertRuleId: entity.alertRuleId,
      currentValue: entity.currentValue,
      thresholdValue: entity.thresholdValue,
      severity: entity.severity,
      status: entity.status,
      acknowledgedBy: entity.acknowledgedBy,
      acknowledgedAt: entity.acknowledgedAt,
      resolvedAt: entity.resolvedAt,
      resolutionNotes: entity.resolutionNotes,
      createdAt: entity.createdAt,
    );
  }

  AlertIncident toEntity() {
    return AlertIncident(
      id: id,
      alertRuleId: alertRuleId,
      currentValue: currentValue,
      thresholdValue: thresholdValue,
      severity: severity,
      status: status,
      acknowledgedBy: acknowledgedBy,
      acknowledgedAt: acknowledgedAt,
      resolvedAt: resolvedAt,
      resolutionNotes: resolutionNotes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, alertRuleId, status];
}

// ─── 28. PerformanceLogModel ─────────────────────────────────────────

class PerformanceLogModel extends Equatable {
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

  const PerformanceLogModel({
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

  factory PerformanceLogModel.fromJson(Map<String, dynamic> json) {
    return PerformanceLogModel(
      id: json['id'] as String,
      operationType:
          _readField<String>(json, 'operation_type', 'operationType') ?? '',
      operationName:
          _readField<String>(json, 'operation_name', 'operationName') ?? '',
      durationMs: _readField<int>(json, 'duration_ms', 'durationMs') ?? 0,
      isSlow: _readField<bool>(json, 'is_slow', 'isSlow') ?? false,
      userId: _readField<String>(json, 'user_id', 'userId'),
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      endpoint: json['endpoint'] as String?,
      queryHash: _readField<String>(json, 'query_hash', 'queryHash'),
      requestPayloadSizeBytes: _readField<int>(
        json, 'request_payload_size_bytes', 'requestPayloadSizeBytes',
      ),
      responsePayloadSizeBytes: _readField<int>(
        json, 'response_payload_size_bytes', 'responsePayloadSizeBytes',
      ),
      errorMessage:
          _readField<String>(json, 'error_message', 'errorMessage'),
      metadata: _readNullableMap(json['metadata']),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_type': operationType,
      'operation_name': operationName,
      'duration_ms': durationMs,
      'is_slow': isSlow,
      'user_id': userId,
      'school_id': schoolId,
      'endpoint': endpoint,
      'query_hash': queryHash,
      'request_payload_size_bytes': requestPayloadSizeBytes,
      'response_payload_size_bytes': responsePayloadSizeBytes,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  factory PerformanceLogModel.fromEntity(PerformanceLog entity) {
    return PerformanceLogModel(
      id: entity.id,
      operationType: entity.operationType,
      operationName: entity.operationName,
      durationMs: entity.durationMs,
      isSlow: entity.isSlow,
      userId: entity.userId,
      schoolId: entity.schoolId,
      endpoint: entity.endpoint,
      queryHash: entity.queryHash,
      requestPayloadSizeBytes: entity.requestPayloadSizeBytes,
      responsePayloadSizeBytes: entity.responsePayloadSizeBytes,
      errorMessage: entity.errorMessage,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  PerformanceLog toEntity() {
    return PerformanceLog(
      id: id,
      operationType: operationType,
      operationName: operationName,
      durationMs: durationMs,
      isSlow: isSlow,
      userId: userId,
      schoolId: schoolId,
      endpoint: endpoint,
      queryHash: queryHash,
      requestPayloadSizeBytes: requestPayloadSizeBytes,
      responsePayloadSizeBytes: responsePayloadSizeBytes,
      errorMessage: errorMessage,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, operationType, operationName, durationMs];
}

// ─── 29. ErrorReportModel ────────────────────────────────────────────

class ErrorReportModel extends Equatable {
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

  const ErrorReportModel({
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

  factory ErrorReportModel.fromJson(Map<String, dynamic> json) {
    return ErrorReportModel(
      id: json['id'] as String,
      errorType: _readField<String>(json, 'error_type', 'errorType') ?? '',
      errorMessage:
          _readField<String>(json, 'error_message', 'errorMessage') ?? '',
      stackTrace: _readField<String>(json, 'stack_trace', 'stackTrace'),
      errorHash: _readField<String>(json, 'error_hash', 'errorHash') ?? '',
      occurrenceCount:
          _readField<int>(json, 'occurrence_count', 'occurrenceCount') ?? 1,
      firstSeenAt: _readDateTime(json, 'first_seen_at', 'firstSeenAt'),
      lastSeenAt: _readDateTime(json, 'last_seen_at', 'lastSeenAt'),
      userId: _readField<String>(json, 'user_id', 'userId'),
      schoolId: _readField<String>(json, 'school_id', 'schoolId'),
      deviceInfo: _readNullableMap(
        json['device_info'] ?? json['deviceInfo'],
      ),
      appVersion: _readField<String>(json, 'app_version', 'appVersion'),
      platform: json['platform'] as String?,
      isResolved: _readField<bool>(json, 'is_resolved', 'isResolved') ?? false,
      resolvedBy: _readField<String>(json, 'resolved_by', 'resolvedBy'),
      resolvedAt: _readNullableDateTime(json, 'resolved_at', 'resolvedAt'),
      metadata: _readNullableMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'error_hash': errorHash,
      'occurrence_count': occurrenceCount,
      'first_seen_at': firstSeenAt.toIso8601String(),
      'last_seen_at': lastSeenAt.toIso8601String(),
      'user_id': userId,
      'school_id': schoolId,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'platform': platform,
      'is_resolved': isResolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ErrorReportModel.fromEntity(ErrorReport entity) {
    return ErrorReportModel(
      id: entity.id,
      errorType: entity.errorType,
      errorMessage: entity.errorMessage,
      stackTrace: entity.stackTrace,
      errorHash: entity.errorHash,
      occurrenceCount: entity.occurrenceCount,
      firstSeenAt: entity.firstSeenAt,
      lastSeenAt: entity.lastSeenAt,
      userId: entity.userId,
      schoolId: entity.schoolId,
      deviceInfo: entity.deviceInfo,
      appVersion: entity.appVersion,
      platform: entity.platform,
      isResolved: entity.isResolved,
      resolvedBy: entity.resolvedBy,
      resolvedAt: entity.resolvedAt,
      metadata: entity.metadata,
    );
  }

  ErrorReport toEntity() {
    return ErrorReport(
      id: id,
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      errorHash: errorHash,
      occurrenceCount: occurrenceCount,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt,
      userId: userId,
      schoolId: schoolId,
      deviceInfo: deviceInfo,
      appVersion: appVersion,
      platform: platform,
      isResolved: isResolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, errorHash, errorType];
}

// ─── 30. DeploymentModel ─────────────────────────────────────────────

class DeploymentModel extends Equatable {
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

  const DeploymentModel({
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

  factory DeploymentModel.fromJson(Map<String, dynamic> json) {
    return DeploymentModel(
      id: json['id'] as String,
      environment: json['environment'] as String,
      version: json['version'] as String,
      commitHash: _readField<String>(json, 'commit_hash', 'commitHash') ?? '',
      branch: json['branch'] as String,
      deployerId: _readField<String>(json, 'deployer_id', 'deployerId'),
      status: DeploymentStatus.fromString(
            _readField<String>(json, 'status', 'status'),
          ) ??
          DeploymentStatus.pending,
      startedAt: _readDateTime(json, 'started_at', 'startedAt'),
      completedAt: _readNullableDateTime(json, 'completed_at', 'completedAt'),
      rollbackFrom: _readField<String>(json, 'rollback_from', 'rollbackFrom'),
      notes: json['notes'] as String?,
      metadata: _readNullableMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'environment': environment,
      'version': version,
      'commit_hash': commitHash,
      'branch': branch,
      'deployer_id': deployerId,
      'status': status.value,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'rollback_from': rollbackFrom,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory DeploymentModel.fromEntity(Deployment entity) {
    return DeploymentModel(
      id: entity.id,
      environment: entity.environment,
      version: entity.version,
      commitHash: entity.commitHash,
      branch: entity.branch,
      deployerId: entity.deployerId,
      status: entity.status,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      rollbackFrom: entity.rollbackFrom,
      notes: entity.notes,
      metadata: entity.metadata,
    );
  }

  Deployment toEntity() {
    return Deployment(
      id: id,
      environment: environment,
      version: version,
      commitHash: commitHash,
      branch: branch,
      deployerId: deployerId,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      rollbackFrom: rollbackFrom,
      notes: notes,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, environment, version, commitHash];
}

// ─── 31. TestResultModel ─────────────────────────────────────────────

class TestResultModel extends Equatable {
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

  const TestResultModel({
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

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      id: json['id'] as String,
      testType: TestType.fromString(
            _readField<String>(json, 'test_type', 'testType'),
          ) ??
          TestType.unit,
      testSuite: _readField<String>(json, 'test_suite', 'testSuite') ?? '',
      testName: _readField<String>(json, 'test_name', 'testName') ?? '',
      status: json['status'] as String? ?? 'passed',
      durationMs: _readField<int>(json, 'duration_ms', 'durationMs') ?? 0,
      errorMessage:
          _readField<String>(json, 'error_message', 'errorMessage'),
      stackTrace: _readField<String>(json, 'stack_trace', 'stackTrace'),
      coveragePercentage: _readField<double>(
        json, 'coverage_percentage', 'coveragePercentage',
      ),
      metadata: _readNullableMap(json['metadata']),
      deploymentId: _readField<String>(json, 'deployment_id', 'deploymentId'),
      createdAt: _readDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_type': testType.value,
      'test_suite': testSuite,
      'test_name': testName,
      'status': status,
      'duration_ms': durationMs,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'coverage_percentage': coveragePercentage,
      'metadata': metadata,
      'deployment_id': deploymentId,
    };
  }

  factory TestResultModel.fromEntity(TestResult entity) {
    return TestResultModel(
      id: entity.id,
      testType: entity.testType,
      testSuite: entity.testSuite,
      testName: entity.testName,
      status: entity.status,
      durationMs: entity.durationMs,
      errorMessage: entity.errorMessage,
      stackTrace: entity.stackTrace,
      coveragePercentage: entity.coveragePercentage,
      metadata: entity.metadata,
      deploymentId: entity.deploymentId,
      createdAt: entity.createdAt,
    );
  }

  TestResult toEntity() {
    return TestResult(
      id: id,
      testType: testType,
      testSuite: testSuite,
      testName: testName,
      status: status,
      durationMs: durationMs,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      coveragePercentage: coveragePercentage,
      metadata: metadata,
      deploymentId: deploymentId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, testType, testSuite, testName];
}

// ─── 32. CcmsStatsModel ──────────────────────────────────────────────

class CcmsStatsModel extends Equatable {
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

  const CcmsStatsModel({
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

  factory CcmsStatsModel.fromJson(Map<String, dynamic> json) {
    return CcmsStatsModel(
      totalSubjects:
          _readField<int>(json, 'total_subjects', 'totalSubjects') ?? 0,
      totalTopics: _readField<int>(json, 'total_topics', 'totalTopics') ?? 0,
      totalContent: _readField<int>(json, 'total_content', 'totalContent') ?? 0,
      publishedContent:
          _readField<int>(json, 'published_content', 'publishedContent') ?? 0,
      draftContent:
          _readField<int>(json, 'draft_content', 'draftContent') ?? 0,
      aiGeneratedContent:
          _readField<int>(json, 'ai_generated_content', 'aiGeneratedContent') ?? 0,
      pastQuestions:
          _readField<int>(json, 'past_questions', 'pastQuestions') ?? 0,
      avgQualityScore: (_readField<num>(
        json, 'avg_quality_score', 'avgQualityScore',
      ) ?? 0).toDouble(),
      totalImports: _readField<int>(json, 'total_imports', 'totalImports') ?? 0,
      totalCollections:
          _readField<int>(json, 'total_collections', 'totalCollections') ?? 0,
      pendingReviews:
          _readField<int>(json, 'pending_reviews', 'pendingReviews') ?? 0,
      contentByType: _readNullableMap(
        json['content_by_type'] ?? json['contentByType'],
      ),
      contentByDifficulty: _readNullableMap(
        json['content_by_difficulty'] ?? json['contentByDifficulty'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_subjects': totalSubjects,
      'total_topics': totalTopics,
      'total_content': totalContent,
      'published_content': publishedContent,
      'draft_content': draftContent,
      'ai_generated_content': aiGeneratedContent,
      'past_questions': pastQuestions,
      'avg_quality_score': avgQualityScore,
      'total_imports': totalImports,
      'total_collections': totalCollections,
      'pending_reviews': pendingReviews,
      'content_by_type': contentByType,
      'content_by_difficulty': contentByDifficulty,
    };
  }

  factory CcmsStatsModel.fromEntity(CcmsStats entity) {
    return CcmsStatsModel(
      totalSubjects: entity.totalSubjects,
      totalTopics: entity.totalTopics,
      totalContent: entity.totalContent,
      publishedContent: entity.publishedContent,
      draftContent: entity.draftContent,
      aiGeneratedContent: entity.aiGeneratedContent,
      pastQuestions: entity.pastQuestions,
      avgQualityScore: entity.avgQualityScore,
      totalImports: entity.totalImports,
      totalCollections: entity.totalCollections,
      pendingReviews: entity.pendingReviews,
      contentByType: entity.contentByType,
      contentByDifficulty: entity.contentByDifficulty,
    );
  }

  CcmsStats toEntity() {
    return CcmsStats(
      totalSubjects: totalSubjects,
      totalTopics: totalTopics,
      totalContent: totalContent,
      publishedContent: publishedContent,
      draftContent: draftContent,
      aiGeneratedContent: aiGeneratedContent,
      pastQuestions: pastQuestions,
      avgQualityScore: avgQualityScore,
      totalImports: totalImports,
      totalCollections: totalCollections,
      pendingReviews: pendingReviews,
      contentByType: contentByType,
      contentByDifficulty: contentByDifficulty,
    );
  }

  @override
  List<Object?> get props => [totalContent, publishedContent, totalSubjects];
}
