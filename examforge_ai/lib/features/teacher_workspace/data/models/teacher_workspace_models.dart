import '../../domain/entities/teacher_workspace_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a lesson plan, mapping to `lesson_plans` table.
class LessonPlanModel {
  const LessonPlanModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    this.topicId,
    required this.title,
    this.description,
    required this.subject,
    this.className,
    this.topic,
    this.subtopic,
    required this.curriculum,
    this.learningObjectives = const [],
    this.learningOutcomes = const [],
    this.teachingMaterials = const [],
    this.classroomActivities = const [],
    this.practicalActivities = const [],
    this.homework = const [],
    this.assessmentQuestions = const [],
    this.referencesList = const [],
    this.extensionActivities = const [],
    required this.teachingStyle,
    required this.studentLevel,
    required this.durationMinutes,
    this.notes,
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.version = 1,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String? topicId;
  final String title;
  final String? description;
  final String subject;
  final String? className;
  final String? topic;
  final String? subtopic;
  final String curriculum;
  final List<String> learningObjectives;
  final List<String> learningOutcomes;
  final List<String> teachingMaterials;
  final List<Map<String, dynamic>> classroomActivities;
  final List<Map<String, dynamic>> practicalActivities;
  final List<String> homework;
  final List<Map<String, dynamic>> assessmentQuestions;
  final List<String> referencesList;
  final List<String> extensionActivities;
  final String teachingStyle;
  final String studentLevel;
  final int durationMinutes;
  final String? notes;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory LessonPlanModel.fromJson(Map<String, dynamic> json) {
    return LessonPlanModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      topicId: json['topic_id'] as String? ?? json['topicId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? json['className'] as String?,
      topic: json['topic'] as String?,
      subtopic: json['subtopic'] as String?,
      curriculum: json['curriculum'] as String? ?? 'nigerian',
      learningObjectives:
          (json['learning_objectives'] as List<dynamic>?)?.cast<String>() ??
          (json['learningObjectives'] as List<dynamic>?)?.cast<String>() ??
          const [],
      learningOutcomes:
          (json['learning_outcomes'] as List<dynamic>?)?.cast<String>() ??
          (json['learningOutcomes'] as List<dynamic>?)?.cast<String>() ??
          const [],
      teachingMaterials:
          (json['teaching_materials'] as List<dynamic>?)?.cast<String>() ??
          (json['teachingMaterials'] as List<dynamic>?)?.cast<String>() ??
          const [],
      classroomActivities:
          (json['classroom_activities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['classroomActivities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      practicalActivities:
          (json['practical_activities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['practicalActivities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      homework:
          (json['homework'] as List<dynamic>?)?.cast<String>() ?? const [],
      assessmentQuestions:
          (json['assessment_questions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['assessmentQuestions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      referencesList:
          (json['references_list'] as List<dynamic>?)?.cast<String>() ??
          (json['referencesList'] as List<dynamic>?)?.cast<String>() ??
          const [],
      extensionActivities:
          (json['extension_activities'] as List<dynamic>?)?.cast<String>() ??
          (json['extensionActivities'] as List<dynamic>?)?.cast<String>() ??
          const [],
      teachingStyle: json['teaching_style'] as String? ??
          json['teachingStyle'] as String? ??
          'lecture',
      studentLevel: json['student_level'] as String? ??
          json['studentLevel'] as String? ??
          'intermediate',
      durationMinutes: json['duration_minutes'] as int? ??
          json['durationMinutes'] as int? ??
          40,
      notes: json['notes'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'topic_id': topicId,
      'title': title,
      'description': description,
      'subject': subject,
      'class_name': className,
      'topic': topic,
      'subtopic': subtopic,
      'curriculum': curriculum,
      'learning_objectives': learningObjectives,
      'learning_outcomes': learningOutcomes,
      'teaching_materials': teachingMaterials,
      'classroom_activities': classroomActivities,
      'practical_activities': practicalActivities,
      'homework': homework,
      'assessment_questions': assessmentQuestions,
      'references_list': referencesList,
      'extension_activities': extensionActivities,
      'teaching_style': teachingStyle,
      'student_level': studentLevel,
      'duration_minutes': durationMinutes,
      'notes': notes,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'version': version,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory LessonPlanModel.fromEntity(LessonPlanEntity entity) {
    return LessonPlanModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      topicId: entity.topicId,
      title: entity.title,
      description: entity.description,
      subject: entity.subject,
      className: entity.className,
      topic: entity.topic,
      subtopic: entity.subtopic,
      curriculum: entity.curriculum.value,
      learningObjectives: entity.learningObjectives,
      learningOutcomes: entity.learningOutcomes,
      teachingMaterials: entity.teachingMaterials,
      classroomActivities: entity.classroomActivities,
      practicalActivities: entity.practicalActivities,
      homework: entity.homework,
      assessmentQuestions: entity.assessmentQuestions,
      referencesList: entity.referencesList,
      extensionActivities: entity.extensionActivities,
      teachingStyle: entity.teachingStyle.value,
      studentLevel: entity.studentLevel.value,
      durationMinutes: entity.durationMinutes,
      notes: entity.notes,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      version: entity.version,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  LessonPlanEntity toEntity() {
    return LessonPlanEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      title: title,
      description: description,
      subject: subject,
      className: className,
      topic: topic,
      subtopic: subtopic,
      curriculum: CurriculumType.fromString(curriculum) ?? CurriculumType.nigerian,
      learningObjectives: learningObjectives,
      learningOutcomes: learningOutcomes,
      teachingMaterials: teachingMaterials,
      classroomActivities: classroomActivities,
      practicalActivities: practicalActivities,
      homework: homework,
      assessmentQuestions: assessmentQuestions,
      referencesList: referencesList,
      extensionActivities: extensionActivities,
      teachingStyle: TeachingStyle.fromString(teachingStyle) ?? TeachingStyle.lecture,
      studentLevel: StudentLevel.fromString(studentLevel) ?? StudentLevel.intermediate,
      durationMinutes: durationMinutes,
      notes: notes,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      version: version,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  LessonPlanModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? topicId,
    String? title,
    String? description,
    String? subject,
    String? className,
    String? topic,
    String? subtopic,
    String? curriculum,
    List<String>? learningObjectives,
    List<String>? learningOutcomes,
    List<String>? teachingMaterials,
    List<Map<String, dynamic>>? classroomActivities,
    List<Map<String, dynamic>>? practicalActivities,
    List<String>? homework,
    List<Map<String, dynamic>>? assessmentQuestions,
    List<String>? referencesList,
    List<String>? extensionActivities,
    String? teachingStyle,
    String? studentLevel,
    int? durationMinutes,
    String? notes,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    int? version,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonPlanModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      curriculum: curriculum ?? this.curriculum,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      teachingMaterials: teachingMaterials ?? this.teachingMaterials,
      classroomActivities: classroomActivities ?? this.classroomActivities,
      practicalActivities: practicalActivities ?? this.practicalActivities,
      homework: homework ?? this.homework,
      assessmentQuestions: assessmentQuestions ?? this.assessmentQuestions,
      referencesList: referencesList ?? this.referencesList,
      extensionActivities: extensionActivities ?? this.extensionActivities,
      teachingStyle: teachingStyle ?? this.teachingStyle,
      studentLevel: studentLevel ?? this.studentLevel,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonPlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          topicId == other.topicId &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          className == other.className &&
          topic == other.topic &&
          subtopic == other.subtopic &&
          curriculum == other.curriculum &&
          learningObjectives == other.learningObjectives &&
          learningOutcomes == other.learningOutcomes &&
          teachingMaterials == other.teachingMaterials &&
          classroomActivities == other.classroomActivities &&
          practicalActivities == other.practicalActivities &&
          homework == other.homework &&
          assessmentQuestions == other.assessmentQuestions &&
          referencesList == other.referencesList &&
          extensionActivities == other.extensionActivities &&
          teachingStyle == other.teachingStyle &&
          studentLevel == other.studentLevel &&
          durationMinutes == other.durationMinutes &&
          notes == other.notes &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          version == other.version &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        topicId,
        title,
        description,
        subject,
        className,
        topic,
        subtopic,
        curriculum,
        Object.hashAll(learningObjectives),
        Object.hashAll(learningOutcomes),
        Object.hashAll(teachingMaterials),
        Object.hashAll(classroomActivities),
        Object.hashAll(practicalActivities),
        Object.hashAll(homework),
        Object.hashAll(assessmentQuestions),
        Object.hashAll(referencesList),
        Object.hashAll(extensionActivities),
        teachingStyle,
        studentLevel,
        durationMinutes,
        notes,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'LessonPlanModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// SCHEME OF WORK MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a scheme of work, mapping to `schemes_of_work` table.
class SchemeOfWorkModel {
  const SchemeOfWorkModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    required this.subject,
    this.className,
    required this.curriculum,
    required this.durationType,
    this.academicSessionId,
    this.term,
    this.startDate,
    this.endDate,
    this.weeklyPlans = const [],
    this.objectives = const [],
    this.resourcesNeeded = const [],
    this.assessmentStrategy,
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.version = 1,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final String subject;
  final String? className;
  final String curriculum;
  final String durationType;
  final String? academicSessionId;
  final String? term;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> weeklyPlans;
  final List<String> objectives;
  final List<String> resourcesNeeded;
  final String? assessmentStrategy;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SchemeOfWorkModel.fromJson(Map<String, dynamic> json) {
    return SchemeOfWorkModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? json['className'] as String?,
      curriculum: json['curriculum'] as String? ?? 'nigerian',
      durationType: json['duration_type'] as String? ??
          json['durationType'] as String? ??
          'weekly',
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      term: json['term'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : json['endDate'] != null
              ? DateTime.parse(json['endDate'] as String)
              : null,
      weeklyPlans: (json['weekly_plans'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['weeklyPlans'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      objectives:
          (json['objectives'] as List<dynamic>?)?.cast<String>() ?? const [],
      resourcesNeeded:
          (json['resources_needed'] as List<dynamic>?)?.cast<String>() ??
          (json['resourcesNeeded'] as List<dynamic>?)?.cast<String>() ??
          const [],
      assessmentStrategy: json['assessment_strategy'] as String? ??
          json['assessmentStrategy'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'title': title,
      'description': description,
      'subject': subject,
      'class_name': className,
      'curriculum': curriculum,
      'duration_type': durationType,
      'academic_session_id': academicSessionId,
      'term': term,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'weekly_plans': weeklyPlans,
      'objectives': objectives,
      'resources_needed': resourcesNeeded,
      'assessment_strategy': assessmentStrategy,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'version': version,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SchemeOfWorkModel.fromEntity(SchemeOfWorkEntity entity) {
    return SchemeOfWorkModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      subject: entity.subject,
      className: entity.className,
      curriculum: entity.curriculum.value,
      durationType: entity.durationType.value,
      academicSessionId: entity.academicSessionId,
      term: entity.term,
      startDate: entity.startDate,
      endDate: entity.endDate,
      weeklyPlans: entity.weeklyPlans,
      objectives: entity.objectives,
      resourcesNeeded: entity.resourcesNeeded,
      assessmentStrategy: entity.assessmentStrategy,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      version: entity.version,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SchemeOfWorkEntity toEntity() {
    return SchemeOfWorkEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      subject: subject,
      className: className,
      curriculum: CurriculumType.fromString(curriculum) ?? CurriculumType.nigerian,
      durationType: PlanDuration.fromString(durationType) ?? PlanDuration.weekly,
      academicSessionId: academicSessionId,
      term: term,
      startDate: startDate,
      endDate: endDate,
      weeklyPlans: weeklyPlans,
      objectives: objectives,
      resourcesNeeded: resourcesNeeded,
      assessmentStrategy: assessmentStrategy,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      version: version,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SchemeOfWorkModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    String? subject,
    String? className,
    String? curriculum,
    String? durationType,
    String? academicSessionId,
    String? term,
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, dynamic>>? weeklyPlans,
    List<String>? objectives,
    List<String>? resourcesNeeded,
    String? assessmentStrategy,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    int? version,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchemeOfWorkModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      curriculum: curriculum ?? this.curriculum,
      durationType: durationType ?? this.durationType,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      term: term ?? this.term,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weeklyPlans: weeklyPlans ?? this.weeklyPlans,
      objectives: objectives ?? this.objectives,
      resourcesNeeded: resourcesNeeded ?? this.resourcesNeeded,
      assessmentStrategy: assessmentStrategy ?? this.assessmentStrategy,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemeOfWorkModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          className == other.className &&
          curriculum == other.curriculum &&
          durationType == other.durationType &&
          academicSessionId == other.academicSessionId &&
          term == other.term &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          weeklyPlans == other.weeklyPlans &&
          objectives == other.objectives &&
          resourcesNeeded == other.resourcesNeeded &&
          assessmentStrategy == other.assessmentStrategy &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          version == other.version &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        title,
        description,
        subject,
        className,
        curriculum,
        durationType,
        academicSessionId,
        term,
        startDate,
        endDate,
        Object.hashAll(weeklyPlans),
        Object.hashAll(objectives),
        Object.hashAll(resourcesNeeded),
        assessmentStrategy,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'SchemeOfWorkModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSHEET MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a worksheet, mapping to `worksheets` table.
class WorksheetModel {
  const WorksheetModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    required this.subject,
    this.className,
    this.topic,
    required this.worksheetType,
    this.instructions,
    this.questions = const [],
    this.answerKey = const [],
    required this.totalMarks,
    this.durationMinutes,
    this.difficulty = 'medium',
    required this.curriculum,
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.version = 1,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final String subject;
  final String? className;
  final String? topic;
  final String worksheetType;
  final String? instructions;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> answerKey;
  final double totalMarks;
  final int? durationMinutes;
  final String difficulty;
  final String curriculum;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory WorksheetModel.fromJson(Map<String, dynamic> json) {
    return WorksheetModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? json['className'] as String?,
      topic: json['topic'] as String?,
      worksheetType: json['worksheet_type'] as String? ??
          json['worksheetType'] as String? ??
          'classwork',
      instructions: json['instructions'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      answerKey: (json['answer_key'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['answerKey'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      durationMinutes: json['duration_minutes'] as int? ??
          json['durationMinutes'] as int?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      curriculum: json['curriculum'] as String? ?? 'nigerian',
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'title': title,
      'description': description,
      'subject': subject,
      'class_name': className,
      'topic': topic,
      'worksheet_type': worksheetType,
      'instructions': instructions,
      'questions': questions,
      'answer_key': answerKey,
      'total_marks': totalMarks,
      'duration_minutes': durationMinutes,
      'difficulty': difficulty,
      'curriculum': curriculum,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'version': version,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory WorksheetModel.fromEntity(WorksheetEntity entity) {
    return WorksheetModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      subject: entity.subject,
      className: entity.className,
      topic: entity.topic,
      worksheetType: entity.worksheetType.value,
      instructions: entity.instructions,
      questions: entity.questions,
      answerKey: entity.answerKey,
      totalMarks: entity.totalMarks,
      durationMinutes: entity.durationMinutes,
      difficulty: entity.difficulty,
      curriculum: entity.curriculum.value,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      version: entity.version,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  WorksheetEntity toEntity() {
    return WorksheetEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      subject: subject,
      className: className,
      topic: topic,
      worksheetType: WorksheetType.fromString(worksheetType) ?? WorksheetType.classwork,
      instructions: instructions,
      questions: questions,
      answerKey: answerKey,
      totalMarks: totalMarks,
      durationMinutes: durationMinutes,
      difficulty: difficulty,
      curriculum: CurriculumType.fromString(curriculum) ?? CurriculumType.nigerian,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      version: version,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  WorksheetModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    String? subject,
    String? className,
    String? topic,
    String? worksheetType,
    String? instructions,
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? answerKey,
    double? totalMarks,
    int? durationMinutes,
    String? difficulty,
    String? curriculum,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    int? version,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorksheetModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      topic: topic ?? this.topic,
      worksheetType: worksheetType ?? this.worksheetType,
      instructions: instructions ?? this.instructions,
      questions: questions ?? this.questions,
      answerKey: answerKey ?? this.answerKey,
      totalMarks: totalMarks ?? this.totalMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      curriculum: curriculum ?? this.curriculum,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorksheetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          className == other.className &&
          topic == other.topic &&
          worksheetType == other.worksheetType &&
          instructions == other.instructions &&
          questions == other.questions &&
          answerKey == other.answerKey &&
          totalMarks == other.totalMarks &&
          durationMinutes == other.durationMinutes &&
          difficulty == other.difficulty &&
          curriculum == other.curriculum &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          version == other.version &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        title,
        description,
        subject,
        className,
        topic,
        worksheetType,
        instructions,
        Object.hashAll(questions),
        Object.hashAll(answerKey),
        totalMarks,
        durationMinutes,
        difficulty,
        curriculum,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorksheetModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE ASSIGNMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an assignment, mapping to `workspace_assignments` table.
class WorkspaceAssignmentModel {
  const WorkspaceAssignmentModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    required this.subject,
    this.className,
    this.topic,
    this.instructions,
    this.questions = const [],
    this.markingRubric = const [],
    required this.totalMarks,
    this.difficulty = 'medium',
    this.deadline,
    this.assignmentStatus = 'draft',
    required this.curriculum,
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.version = 1,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final String subject;
  final String? className;
  final String? topic;
  final String? instructions;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> markingRubric;
  final double totalMarks;
  final String difficulty;
  final DateTime? deadline;
  final String assignmentStatus;
  final String curriculum;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory WorkspaceAssignmentModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceAssignmentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? json['className'] as String?,
      topic: json['topic'] as String?,
      instructions: json['instructions'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      markingRubric: (json['marking_rubric'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['markingRubric'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      difficulty: json['difficulty'] as String? ?? 'medium',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      assignmentStatus: json['assignment_status'] as String? ??
          json['assignmentStatus'] as String? ??
          'draft',
      curriculum: json['curriculum'] as String? ?? 'nigerian',
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'title': title,
      'description': description,
      'subject': subject,
      'class_name': className,
      'topic': topic,
      'instructions': instructions,
      'questions': questions,
      'marking_rubric': markingRubric,
      'total_marks': totalMarks,
      'difficulty': difficulty,
      'deadline': deadline?.toIso8601String(),
      'assignment_status': assignmentStatus,
      'curriculum': curriculum,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'version': version,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory WorkspaceAssignmentModel.fromEntity(WorkspaceAssignmentEntity entity) {
    return WorkspaceAssignmentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      subject: entity.subject,
      className: entity.className,
      topic: entity.topic,
      instructions: entity.instructions,
      questions: entity.questions,
      markingRubric: entity.markingRubric,
      totalMarks: entity.totalMarks,
      difficulty: entity.difficulty,
      deadline: entity.deadline,
      assignmentStatus: entity.assignmentStatus.value,
      curriculum: entity.curriculum.value,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      version: entity.version,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  WorkspaceAssignmentEntity toEntity() {
    return WorkspaceAssignmentEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      subject: subject,
      className: className,
      topic: topic,
      instructions: instructions,
      questions: questions,
      markingRubric: markingRubric,
      totalMarks: totalMarks,
      difficulty: difficulty,
      deadline: deadline,
      assignmentStatus:
          AssignmentStatus.fromString(assignmentStatus) ?? AssignmentStatus.draft,
      curriculum: CurriculumType.fromString(curriculum) ?? CurriculumType.nigerian,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      version: version,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  WorkspaceAssignmentModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    String? subject,
    String? className,
    String? topic,
    String? instructions,
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? markingRubric,
    double? totalMarks,
    String? difficulty,
    DateTime? deadline,
    String? assignmentStatus,
    String? curriculum,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    int? version,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceAssignmentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      topic: topic ?? this.topic,
      instructions: instructions ?? this.instructions,
      questions: questions ?? this.questions,
      markingRubric: markingRubric ?? this.markingRubric,
      totalMarks: totalMarks ?? this.totalMarks,
      difficulty: difficulty ?? this.difficulty,
      deadline: deadline ?? this.deadline,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      curriculum: curriculum ?? this.curriculum,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceAssignmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          className == other.className &&
          topic == other.topic &&
          instructions == other.instructions &&
          questions == other.questions &&
          markingRubric == other.markingRubric &&
          totalMarks == other.totalMarks &&
          difficulty == other.difficulty &&
          deadline == other.deadline &&
          assignmentStatus == other.assignmentStatus &&
          curriculum == other.curriculum &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          version == other.version &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        title,
        description,
        subject,
        className,
        topic,
        instructions,
        Object.hashAll(questions),
        Object.hashAll(markingRubric),
        totalMarks,
        difficulty,
        deadline,
        assignmentStatus,
        curriculum,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorkspaceAssignmentModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// REPORT COMMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a report comment, mapping to `report_comments` table.
class ReportCommentModel {
  const ReportCommentModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.studentId,
    this.classId,
    this.subjectId,
    this.academicSessionId,
    this.term,
    required this.commentText,
    this.academicPerformance,
    this.attendanceComment,
    this.behaviourComment,
    this.participationComment,
    this.strengths = const [],
    this.areasForImprovement = const [],
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.isEdited = false,
    this.isPublished = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? studentId;
  final String? classId;
  final String? subjectId;
  final String? academicSessionId;
  final String? term;
  final String commentText;
  final String? academicPerformance;
  final String? attendanceComment;
  final String? behaviourComment;
  final String? participationComment;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final bool isEdited;
  final bool isPublished;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ReportCommentModel.fromJson(Map<String, dynamic> json) {
    return ReportCommentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      studentId: json['student_id'] as String? ?? json['studentId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      term: json['term'] as String?,
      commentText: json['comment_text'] as String? ?? json['commentText'] as String? ?? '',
      academicPerformance: json['academic_performance'] as String? ??
          json['academicPerformance'] as String?,
      attendanceComment: json['attendance_comment'] as String? ??
          json['attendanceComment'] as String?,
      behaviourComment: json['behaviour_comment'] as String? ??
          json['behaviourComment'] as String?,
      participationComment: json['participation_comment'] as String? ??
          json['participationComment'] as String?,
      strengths:
          (json['strengths'] as List<dynamic>?)?.cast<String>() ?? const [],
      areasForImprovement:
          (json['areas_for_improvement'] as List<dynamic>?)?.cast<String>() ??
          (json['areasForImprovement'] as List<dynamic>?)?.cast<String>() ??
          const [],
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      isEdited: json['is_edited'] as bool? ?? json['isEdited'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'student_id': studentId,
      'class_id': classId,
      'subject_id': subjectId,
      'academic_session_id': academicSessionId,
      'term': term,
      'comment_text': commentText,
      'academic_performance': academicPerformance,
      'attendance_comment': attendanceComment,
      'behaviour_comment': behaviourComment,
      'participation_comment': participationComment,
      'strengths': strengths,
      'areas_for_improvement': areasForImprovement,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'is_edited': isEdited,
      'is_published': isPublished,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ReportCommentModel.fromEntity(ReportCommentEntity entity) {
    return ReportCommentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      studentId: entity.studentId,
      classId: entity.classId,
      subjectId: entity.subjectId,
      academicSessionId: entity.academicSessionId,
      term: entity.term,
      commentText: entity.commentText,
      academicPerformance: entity.academicPerformance,
      attendanceComment: entity.attendanceComment,
      behaviourComment: entity.behaviourComment,
      participationComment: entity.participationComment,
      strengths: entity.strengths,
      areasForImprovement: entity.areasForImprovement,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      isEdited: entity.isEdited,
      isPublished: entity.isPublished,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ReportCommentEntity toEntity() {
    return ReportCommentEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      academicSessionId: academicSessionId,
      term: term,
      commentText: commentText,
      academicPerformance: academicPerformance,
      attendanceComment: attendanceComment,
      behaviourComment: behaviourComment,
      participationComment: participationComment,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      isEdited: isEdited,
      isPublished: isPublished,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ReportCommentModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? studentId,
    String? classId,
    String? subjectId,
    String? academicSessionId,
    String? term,
    String? commentText,
    String? academicPerformance,
    String? attendanceComment,
    String? behaviourComment,
    String? participationComment,
    List<String>? strengths,
    List<String>? areasForImprovement,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    bool? isEdited,
    bool? isPublished,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportCommentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      term: term ?? this.term,
      commentText: commentText ?? this.commentText,
      academicPerformance: academicPerformance ?? this.academicPerformance,
      attendanceComment: attendanceComment ?? this.attendanceComment,
      behaviourComment: behaviourComment ?? this.behaviourComment,
      participationComment: participationComment ?? this.participationComment,
      strengths: strengths ?? this.strengths,
      areasForImprovement: areasForImprovement ?? this.areasForImprovement,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      isEdited: isEdited ?? this.isEdited,
      isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportCommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          studentId == other.studentId &&
          classId == other.classId &&
          subjectId == other.subjectId &&
          academicSessionId == other.academicSessionId &&
          term == other.term &&
          commentText == other.commentText &&
          academicPerformance == other.academicPerformance &&
          attendanceComment == other.attendanceComment &&
          behaviourComment == other.behaviourComment &&
          participationComment == other.participationComment &&
          strengths == other.strengths &&
          areasForImprovement == other.areasForImprovement &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          isEdited == other.isEdited &&
          isPublished == other.isPublished &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        studentId,
        classId,
        subjectId,
        academicSessionId,
        term,
        commentText,
        academicPerformance,
        attendanceComment,
        behaviourComment,
        participationComment,
        Object.hashAll(strengths),
        Object.hashAll(areasForImprovement),
        isAiGenerated,
        aiPromptSnapshot,
        isEdited,
        isPublished,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ReportCommentModel(id: $id, teacherId: $teacherId, studentId: $studentId)';
}

// ═══════════════════════════════════════════════════════════════════════
// TEACHING RESOURCE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a teaching resource, mapping to `teaching_resources` table.
class TeachingResourceModel {
  const TeachingResourceModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    this.topicId,
    this.academicSessionId,
    required this.title,
    this.description,
    this.subject,
    this.className,
    this.topic,
    required this.resourceType,
    this.content,
    this.contentJson,
    this.fileUrls = const [],
    this.isAiGenerated = false,
    this.aiPromptSnapshot,
    this.version = 1,
    this.isPublished = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.folderId,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String? topicId;
  final String? academicSessionId;
  final String title;
  final String? description;
  final String? subject;
  final String? className;
  final String? topic;
  final String resourceType;
  final String? content;
  final Map<String, dynamic>? contentJson;
  final List<String> fileUrls;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final bool isFavorite;
  final String? folderId;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TeachingResourceModel.fromJson(Map<String, dynamic> json) {
    return TeachingResourceModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      topicId: json['topic_id'] as String? ?? json['topicId'] as String?,
      academicSessionId: json['academic_session_id'] as String? ??
          json['academicSessionId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      className: json['class_name'] as String? ?? json['className'] as String?,
      topic: json['topic'] as String?,
      resourceType: json['resource_type'] as String? ??
          json['resourceType'] as String? ??
          'notes',
      content: json['content'] as String?,
      contentJson: json['content_json'] as Map<String, dynamic>? ??
          json['contentJson'] as Map<String, dynamic>?,
      fileUrls:
          (json['file_urls'] as List<dynamic>?)?.cast<String>() ??
          (json['fileUrls'] as List<dynamic>?)?.cast<String>() ??
          const [],
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiPromptSnapshot: json['ai_prompt_snapshot'] as Map<String, dynamic>? ??
          json['aiPromptSnapshot'] as Map<String, dynamic>?,
      version: json['version'] as int? ?? 1,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      isFavorite: json['is_favorite'] as bool? ??
          json['isFavorite'] as bool? ??
          false,
      folderId: json['folder_id'] as String? ?? json['folderId'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'class_id': classId,
      'topic_id': topicId,
      'academic_session_id': academicSessionId,
      'title': title,
      'description': description,
      'subject': subject,
      'class_name': className,
      'topic': topic,
      'resource_type': resourceType,
      'content': content,
      'content_json': contentJson,
      'file_urls': fileUrls,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_snapshot': aiPromptSnapshot,
      'version': version,
      'is_published': isPublished,
      'is_archived': isArchived,
      'is_favorite': isFavorite,
      'folder_id': folderId,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TeachingResourceModel.fromEntity(TeachingResourceEntity entity) {
    return TeachingResourceModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      topicId: entity.topicId,
      academicSessionId: entity.academicSessionId,
      title: entity.title,
      description: entity.description,
      subject: entity.subject,
      className: entity.className,
      topic: entity.topic,
      resourceType: entity.resourceType.value,
      content: entity.content,
      contentJson: entity.contentJson,
      fileUrls: entity.fileUrls,
      isAiGenerated: entity.isAiGenerated,
      aiPromptSnapshot: entity.aiPromptSnapshot,
      version: entity.version,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      isFavorite: entity.isFavorite,
      folderId: entity.folderId,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TeachingResourceEntity toEntity() {
    return TeachingResourceEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      academicSessionId: academicSessionId,
      title: title,
      description: description,
      subject: subject,
      className: className,
      topic: topic,
      resourceType: ResourceType.fromString(resourceType) ?? ResourceType.notes,
      content: content,
      contentJson: contentJson,
      fileUrls: fileUrls,
      isAiGenerated: isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot,
      version: version,
      isPublished: isPublished,
      isArchived: isArchived,
      isFavorite: isFavorite,
      folderId: folderId,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TeachingResourceModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? topicId,
    String? academicSessionId,
    String? title,
    String? description,
    String? subject,
    String? className,
    String? topic,
    String? resourceType,
    String? content,
    Map<String, dynamic>? contentJson,
    List<String>? fileUrls,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptSnapshot,
    int? version,
    bool? isPublished,
    bool? isArchived,
    bool? isFavorite,
    String? folderId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeachingResourceModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      topicId: topicId ?? this.topicId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      topic: topic ?? this.topic,
      resourceType: resourceType ?? this.resourceType,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      fileUrls: fileUrls ?? this.fileUrls,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptSnapshot: aiPromptSnapshot ?? this.aiPromptSnapshot,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachingResourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          topicId == other.topicId &&
          academicSessionId == other.academicSessionId &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          className == other.className &&
          topic == other.topic &&
          resourceType == other.resourceType &&
          content == other.content &&
          contentJson == other.contentJson &&
          fileUrls == other.fileUrls &&
          isAiGenerated == other.isAiGenerated &&
          aiPromptSnapshot == other.aiPromptSnapshot &&
          version == other.version &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          isFavorite == other.isFavorite &&
          folderId == other.folderId &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        topicId,
        academicSessionId,
        title,
        description,
        subject,
        className,
        topic,
        resourceType,
        content,
        contentJson,
        Object.hashAll(fileUrls),
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        isFavorite,
        folderId,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'TeachingResourceModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE FOLDER MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a resource folder, mapping to `resource_folders` table.
class ResourceFolderModel {
  const ResourceFolderModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.parentFolderId,
    required this.name,
    this.description,
    this.icon = 'folder',
    this.color,
    this.sortOrder = 0,
    this.isShared = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? parentFolderId;
  final String name;
  final String? description;
  final String icon;
  final String? color;
  final int sortOrder;
  final bool isShared;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory ResourceFolderModel.fromJson(Map<String, dynamic> json) {
    return ResourceFolderModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      parentFolderId: json['parent_folder_id'] as String? ??
          json['parentFolderId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'folder',
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isShared: json['is_shared'] as bool? ?? json['isShared'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'parent_folder_id': parentFolderId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'is_shared': isShared,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory ResourceFolderModel.fromEntity(ResourceFolderEntity entity) {
    return ResourceFolderModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      parentFolderId: entity.parentFolderId,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      color: entity.color,
      sortOrder: entity.sortOrder,
      isShared: entity.isShared,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ResourceFolderEntity toEntity() {
    return ResourceFolderEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      parentFolderId: parentFolderId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      isShared: isShared,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  ResourceFolderModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? parentFolderId,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isShared,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResourceFolderModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isShared: isShared ?? this.isShared,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceFolderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          parentFolderId == other.parentFolderId &&
          name == other.name &&
          description == other.description &&
          icon == other.icon &&
          color == other.color &&
          sortOrder == other.sortOrder &&
          isShared == other.isShared &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        parentFolderId,
        name,
        description,
        icon,
        color,
        sortOrder,
        isShared,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ResourceFolderModel(id: $id, name: $name, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// AI CONTENT HISTORY MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of AI content history, mapping to `ai_content_history` table.
class AiContentHistoryModel {
  const AiContentHistoryModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    required this.actionType,
    required this.sourceContent,
    required this.generatedContent,
    this.subject,
    this.topic,
    this.promptSnapshot,
    this.modelUsed,
    this.tokensUsed = 0,
    this.generationTimeMs = 0,
    this.isSaved = false,
    this.savedAsType,
    this.savedAsId,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String actionType;
  final String sourceContent;
  final String generatedContent;
  final String? subject;
  final String? topic;
  final Map<String, dynamic>? promptSnapshot;
  final String? modelUsed;
  final int tokensUsed;
  final int generationTimeMs;
  final bool isSaved;
  final String? savedAsType;
  final String? savedAsId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory AiContentHistoryModel.fromJson(Map<String, dynamic> json) {
    return AiContentHistoryModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      actionType: json['action_type'] as String? ??
          json['actionType'] as String? ??
          'explain',
      sourceContent: json['source_content'] as String? ??
          json['sourceContent'] as String? ??
          '',
      generatedContent: json['generated_content'] as String? ??
          json['generatedContent'] as String? ??
          '',
      subject: json['subject'] as String?,
      topic: json['topic'] as String?,
      promptSnapshot: json['prompt_snapshot'] as Map<String, dynamic>? ??
          json['promptSnapshot'] as Map<String, dynamic>?,
      modelUsed: json['model_used'] as String? ?? json['modelUsed'] as String?,
      tokensUsed: json['tokens_used'] as int? ?? json['tokensUsed'] as int? ?? 0,
      generationTimeMs: json['generation_time_ms'] as int? ??
          json['generationTimeMs'] as int? ??
          0,
      isSaved: json['is_saved'] as bool? ?? json['isSaved'] as bool? ?? false,
      savedAsType: json['saved_as_type'] as String? ??
          json['savedAsType'] as String?,
      savedAsId: json['saved_as_id'] as String? ?? json['savedAsId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'action_type': actionType,
      'source_content': sourceContent,
      'generated_content': generatedContent,
      'subject': subject,
      'topic': topic,
      'prompt_snapshot': promptSnapshot,
      'model_used': modelUsed,
      'tokens_used': tokensUsed,
      'generation_time_ms': generationTimeMs,
      'is_saved': isSaved,
      'saved_as_type': savedAsType,
      'saved_as_id': savedAsId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory AiContentHistoryModel.fromEntity(AiContentHistoryEntity entity) {
    return AiContentHistoryModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      actionType: entity.actionType.value,
      sourceContent: entity.sourceContent,
      generatedContent: entity.generatedContent,
      subject: entity.subject,
      topic: entity.topic,
      promptSnapshot: entity.promptSnapshot,
      modelUsed: entity.modelUsed,
      tokensUsed: entity.tokensUsed,
      generationTimeMs: entity.generationTimeMs,
      isSaved: entity.isSaved,
      savedAsType: entity.savedAsType,
      savedAsId: entity.savedAsId,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  AiContentHistoryEntity toEntity() {
    return AiContentHistoryEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      actionType: ContentAction.fromString(actionType) ?? ContentAction.explain,
      sourceContent: sourceContent,
      generatedContent: generatedContent,
      subject: subject,
      topic: topic,
      promptSnapshot: promptSnapshot,
      modelUsed: modelUsed,
      tokensUsed: tokensUsed,
      generationTimeMs: generationTimeMs,
      isSaved: isSaved,
      savedAsType: savedAsType,
      savedAsId: savedAsId,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  AiContentHistoryModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? actionType,
    String? sourceContent,
    String? generatedContent,
    String? subject,
    String? topic,
    Map<String, dynamic>? promptSnapshot,
    String? modelUsed,
    int? tokensUsed,
    int? generationTimeMs,
    bool? isSaved,
    String? savedAsType,
    String? savedAsId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AiContentHistoryModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      actionType: actionType ?? this.actionType,
      sourceContent: sourceContent ?? this.sourceContent,
      generatedContent: generatedContent ?? this.generatedContent,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      promptSnapshot: promptSnapshot ?? this.promptSnapshot,
      modelUsed: modelUsed ?? this.modelUsed,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
      isSaved: isSaved ?? this.isSaved,
      savedAsType: savedAsType ?? this.savedAsType,
      savedAsId: savedAsId ?? this.savedAsId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiContentHistoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          actionType == other.actionType &&
          sourceContent == other.sourceContent &&
          generatedContent == other.generatedContent &&
          subject == other.subject &&
          topic == other.topic &&
          promptSnapshot == other.promptSnapshot &&
          modelUsed == other.modelUsed &&
          tokensUsed == other.tokensUsed &&
          generationTimeMs == other.generationTimeMs &&
          isSaved == other.isSaved &&
          savedAsType == other.savedAsType &&
          savedAsId == other.savedAsId &&
          metadata == other.metadata &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        actionType,
        sourceContent,
        generatedContent,
        subject,
        topic,
        promptSnapshot,
        modelUsed,
        tokensUsed,
        generationTimeMs,
        isSaved,
        savedAsType,
        savedAsId,
        metadata,
        createdAt,
      );

  @override
  String toString() =>
      'AiContentHistoryModel(id: $id, actionType: $actionType, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR EVENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a calendar event, mapping to `calendar_events` table.
class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.eventType,
    this.subject,
    this.subjectId,
    this.classId,
    this.location,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.color,
    this.reminderMinutesBefore,
    this.relatedResourceType,
    this.relatedResourceId,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String title;
  final String? description;
  final String eventType;
  final String? subject;
  final String? subjectId;
  final String? classId;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? color;
  final int? reminderMinutesBefore;
  final String? relatedResourceType;
  final String? relatedResourceId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ??
          json['eventType'] as String? ??
          'class',
      subject: json['subject'] as String?,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : DateTime.now(),
      isAllDay: json['is_all_day'] as bool? ?? json['isAllDay'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ??
          json['isRecurring'] as bool? ??
          false,
      recurrenceRule: json['recurrence_rule'] as String? ??
          json['recurrenceRule'] as String?,
      color: json['color'] as String?,
      reminderMinutesBefore: json['reminder_minutes_before'] as int? ??
          json['reminderMinutesBefore'] as int?,
      relatedResourceType: json['related_resource_type'] as String? ??
          json['relatedResourceType'] as String?,
      relatedResourceId: json['related_resource_id'] as String? ??
          json['relatedResourceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'subject': subject,
      'subject_id': subjectId,
      'class_id': classId,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'color': color,
      'reminder_minutes_before': reminderMinutesBefore,
      'related_resource_type': relatedResourceType,
      'related_resource_id': relatedResourceId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CalendarEventModel.fromEntity(CalendarEventEntity entity) {
    return CalendarEventModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType.value,
      subject: entity.subject,
      subjectId: entity.subjectId,
      classId: entity.classId,
      location: entity.location,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isAllDay: entity.isAllDay,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      color: entity.color,
      reminderMinutesBefore: entity.reminderMinutesBefore,
      relatedResourceType: entity.relatedResourceType,
      relatedResourceId: entity.relatedResourceId,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CalendarEventEntity toEntity() {
    return CalendarEventEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      title: title,
      description: description,
      eventType: EventType.fromString(eventType) ?? EventType.class_,
      subject: subject,
      subjectId: subjectId,
      classId: classId,
      location: location,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      color: color,
      reminderMinutesBefore: reminderMinutesBefore,
      relatedResourceType: relatedResourceType,
      relatedResourceId: relatedResourceId,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  CalendarEventModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? title,
    String? description,
    String? eventType,
    String? subject,
    String? subjectId,
    String? classId,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isRecurring,
    String? recurrenceRule,
    String? color,
    int? reminderMinutesBefore,
    String? relatedResourceType,
    String? relatedResourceId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      subject: subject ?? this.subject,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      color: color ?? this.color,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      relatedResourceType: relatedResourceType ?? this.relatedResourceType,
      relatedResourceId: relatedResourceId ?? this.relatedResourceId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          title == other.title &&
          description == other.description &&
          eventType == other.eventType &&
          subject == other.subject &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          location == other.location &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isAllDay == other.isAllDay &&
          isRecurring == other.isRecurring &&
          recurrenceRule == other.recurrenceRule &&
          color == other.color &&
          reminderMinutesBefore == other.reminderMinutesBefore &&
          relatedResourceType == other.relatedResourceType &&
          relatedResourceId == other.relatedResourceId &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        title,
        description,
        eventType,
        subject,
        subjectId,
        classId,
        location,
        startTime,
        endTime,
        isAllDay,
        isRecurring,
        recurrenceRule,
        color,
        reminderMinutesBefore,
        relatedResourceType,
        relatedResourceId,
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'CalendarEventModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE TEMPLATE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a workspace template, mapping to `workspace_templates` table.
class WorkspaceTemplateModel {
  const WorkspaceTemplateModel({
    required this.id,
    this.schoolId,
    required this.teacherId,
    required this.name,
    this.description,
    required this.templateType,
    this.content = const {},
    this.thumbnailUrl,
    this.isPublic = false,
    this.usageCount = 0,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? schoolId;
  final String teacherId;
  final String name;
  final String? description;
  final String templateType;
  final Map<String, dynamic> content;
  final String? thumbnailUrl;
  final bool isPublic;
  final int usageCount;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory WorkspaceTemplateModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceTemplateModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      templateType: json['template_type'] as String? ??
          json['templateType'] as String? ??
          'lesson_plan',
      content: json['content'] as Map<String, dynamic>? ?? {},
      thumbnailUrl: json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String?,
      isPublic: json['is_public'] as bool? ?? json['isPublic'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? json['usageCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'teacher_id': teacherId,
      'name': name,
      'description': description,
      'template_type': templateType,
      'content': content,
      'thumbnail_url': thumbnailUrl,
      'is_public': isPublic,
      'usage_count': usageCount,
      'tags': tags,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory WorkspaceTemplateModel.fromEntity(WorkspaceTemplateEntity entity) {
    return WorkspaceTemplateModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      name: entity.name,
      description: entity.description,
      templateType: entity.templateType,
      content: entity.content,
      thumbnailUrl: entity.thumbnailUrl,
      isPublic: entity.isPublic,
      usageCount: entity.usageCount,
      tags: entity.tags,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  WorkspaceTemplateEntity toEntity() {
    return WorkspaceTemplateEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      name: name,
      description: description,
      templateType: templateType,
      content: content,
      thumbnailUrl: thumbnailUrl,
      isPublic: isPublic,
      usageCount: usageCount,
      tags: tags,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  WorkspaceTemplateModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? name,
    String? description,
    String? templateType,
    Map<String, dynamic>? content,
    String? thumbnailUrl,
    bool? isPublic,
    int? usageCount,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceTemplateModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      description: description ?? this.description,
      templateType: templateType ?? this.templateType,
      content: content ?? this.content,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPublic: isPublic ?? this.isPublic,
      usageCount: usageCount ?? this.usageCount,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceTemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          name == other.name &&
          description == other.description &&
          templateType == other.templateType &&
          content == other.content &&
          thumbnailUrl == other.thumbnailUrl &&
          isPublic == other.isPublic &&
          usageCount == other.usageCount &&
          tags == other.tags &&
          metadata == other.metadata &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        schoolId,
        teacherId,
        name,
        description,
        templateType,
        content,
        thumbnailUrl,
        isPublic,
        usageCount,
        Object.hashAll(tags),
        metadata,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorkspaceTemplateModel(id: $id, name: $name, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE VERSION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a workspace version, mapping to `workspace_version_history` table.
class WorkspaceVersionModel {
  const WorkspaceVersionModel({
    required this.id,
    required this.teacherId,
    required this.resourceType,
    required this.resourceId,
    required this.versionNumber,
    this.snapshot = const {},
    this.changeSummary,
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String resourceType;
  final String resourceId;
  final int versionNumber;
  final Map<String, dynamic> snapshot;
  final String? changeSummary;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory WorkspaceVersionModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceVersionModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      resourceType: json['resource_type'] as String? ??
          json['resourceType'] as String? ??
          '',
      resourceId: json['resource_id'] as String? ??
          json['resourceId'] as String? ??
          '',
      versionNumber: json['version_number'] as int? ??
          json['versionNumber'] as int? ??
          1,
      snapshot: json['snapshot'] as Map<String, dynamic>? ?? {},
      changeSummary: json['change_summary'] as String? ??
          json['changeSummary'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'version_number': versionNumber,
      'snapshot': snapshot,
      'change_summary': changeSummary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory WorkspaceVersionModel.fromEntity(WorkspaceVersionEntity entity) {
    return WorkspaceVersionModel(
      id: entity.id,
      teacherId: entity.teacherId,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      versionNumber: entity.versionNumber,
      snapshot: entity.snapshot,
      changeSummary: entity.changeSummary,
      createdAt: entity.createdAt,
    );
  }

  WorkspaceVersionEntity toEntity() {
    return WorkspaceVersionEntity(
      id: id,
      teacherId: teacherId,
      resourceType: resourceType,
      resourceId: resourceId,
      versionNumber: versionNumber,
      snapshot: snapshot,
      changeSummary: changeSummary,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  WorkspaceVersionModel copyWith({
    String? id,
    String? teacherId,
    String? resourceType,
    String? resourceId,
    int? versionNumber,
    Map<String, dynamic>? snapshot,
    String? changeSummary,
    DateTime? createdAt,
  }) {
    return WorkspaceVersionModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      versionNumber: versionNumber ?? this.versionNumber,
      snapshot: snapshot ?? this.snapshot,
      changeSummary: changeSummary ?? this.changeSummary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceVersionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          teacherId == other.teacherId &&
          resourceType == other.resourceType &&
          resourceId == other.resourceId &&
          versionNumber == other.versionNumber &&
          snapshot == other.snapshot &&
          changeSummary == other.changeSummary &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        teacherId,
        resourceType,
        resourceId,
        versionNumber,
        snapshot,
        changeSummary,
        createdAt,
      );

  @override
  String toString() =>
      'WorkspaceVersionModel(id: $id, resourceType: $resourceType, versionNumber: $versionNumber)';
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSPACE DASHBOARD MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of workspace dashboard data, from Supabase function
/// `get_teacher_workspace_summary`. The JSON comes from the function which returns
/// nested JSONB.
class WorkspaceDashboardModel {
  const WorkspaceDashboardModel({
    this.totalLessonPlans = 0,
    this.totalSchemes = 0,
    this.totalWorksheets = 0,
    this.totalAssignments = 0,
    this.pendingAssignments = 0,
    this.totalResources = 0,
    this.todayEvents = const [],
    this.upcomingEvents = const [],
    this.recentAiContent = const [],
    this.draftLessonPlans = const [],
  });

  final int totalLessonPlans;
  final int totalSchemes;
  final int totalWorksheets;
  final int totalAssignments;
  final int pendingAssignments;
  final int totalResources;
  final List<Map<String, dynamic>> todayEvents;
  final List<Map<String, dynamic>> upcomingEvents;
  final List<Map<String, dynamic>> recentAiContent;
  final List<Map<String, dynamic>> draftLessonPlans;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory WorkspaceDashboardModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceDashboardModel(
      totalLessonPlans: json['total_lesson_plans'] as int? ??
          json['totalLessonPlans'] as int? ??
          0,
      totalSchemes: json['total_schemes'] as int? ??
          json['totalSchemes'] as int? ??
          0,
      totalWorksheets: json['total_worksheets'] as int? ??
          json['totalWorksheets'] as int? ??
          0,
      totalAssignments: json['total_assignments'] as int? ??
          json['totalAssignments'] as int? ??
          0,
      pendingAssignments: json['pending_assignments'] as int? ??
          json['pendingAssignments'] as int? ??
          0,
      totalResources: json['total_resources'] as int? ??
          json['totalResources'] as int? ??
          0,
      todayEvents: (json['today_events'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['todayEvents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      upcomingEvents: (json['upcoming_events'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['upcomingEvents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      recentAiContent: (json['recent_ai_content'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['recentAiContent'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      draftLessonPlans: (json['draft_lesson_plans'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['draftLessonPlans'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_lesson_plans': totalLessonPlans,
      'total_schemes': totalSchemes,
      'total_worksheets': totalWorksheets,
      'total_assignments': totalAssignments,
      'pending_assignments': pendingAssignments,
      'total_resources': totalResources,
      'today_events': todayEvents,
      'upcoming_events': upcomingEvents,
      'recent_ai_content': recentAiContent,
      'draft_lesson_plans': draftLessonPlans,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory WorkspaceDashboardModel.fromEntity(WorkspaceDashboardEntity entity) {
    return WorkspaceDashboardModel(
      totalLessonPlans: entity.totalLessonPlans,
      totalSchemes: entity.totalSchemes,
      totalWorksheets: entity.totalWorksheets,
      totalAssignments: entity.totalAssignments,
      pendingAssignments: entity.pendingAssignments,
      totalResources: entity.totalResources,
      todayEvents: entity.todayEvents,
      upcomingEvents: entity.upcomingEvents,
      recentAiContent: entity.recentAiContent,
      draftLessonPlans: entity.draftLessonPlans,
    );
  }

  WorkspaceDashboardEntity toEntity() {
    return WorkspaceDashboardEntity(
      totalLessonPlans: totalLessonPlans,
      totalSchemes: totalSchemes,
      totalWorksheets: totalWorksheets,
      totalAssignments: totalAssignments,
      pendingAssignments: pendingAssignments,
      totalResources: totalResources,
      todayEvents: todayEvents,
      upcomingEvents: upcomingEvents,
      recentAiContent: recentAiContent,
      draftLessonPlans: draftLessonPlans,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  WorkspaceDashboardModel copyWith({
    int? totalLessonPlans,
    int? totalSchemes,
    int? totalWorksheets,
    int? totalAssignments,
    int? pendingAssignments,
    int? totalResources,
    List<Map<String, dynamic>>? todayEvents,
    List<Map<String, dynamic>>? upcomingEvents,
    List<Map<String, dynamic>>? recentAiContent,
    List<Map<String, dynamic>>? draftLessonPlans,
  }) {
    return WorkspaceDashboardModel(
      totalLessonPlans: totalLessonPlans ?? this.totalLessonPlans,
      totalSchemes: totalSchemes ?? this.totalSchemes,
      totalWorksheets: totalWorksheets ?? this.totalWorksheets,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      pendingAssignments: pendingAssignments ?? this.pendingAssignments,
      totalResources: totalResources ?? this.totalResources,
      todayEvents: todayEvents ?? this.todayEvents,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      recentAiContent: recentAiContent ?? this.recentAiContent,
      draftLessonPlans: draftLessonPlans ?? this.draftLessonPlans,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceDashboardModel &&
          runtimeType == other.runtimeType &&
          totalLessonPlans == other.totalLessonPlans &&
          totalSchemes == other.totalSchemes &&
          totalWorksheets == other.totalWorksheets &&
          totalAssignments == other.totalAssignments &&
          pendingAssignments == other.pendingAssignments &&
          totalResources == other.totalResources &&
          todayEvents == other.todayEvents &&
          upcomingEvents == other.upcomingEvents &&
          recentAiContent == other.recentAiContent &&
          draftLessonPlans == other.draftLessonPlans;

  @override
  int get hashCode => Object.hash(
        totalLessonPlans,
        totalSchemes,
        totalWorksheets,
        totalAssignments,
        pendingAssignments,
        totalResources,
        Object.hashAll(todayEvents),
        Object.hashAll(upcomingEvents),
        Object.hashAll(recentAiContent),
        Object.hashAll(draftLessonPlans),
      );

  @override
  String toString() =>
      'WorkspaceDashboardModel(totalLessonPlans: $totalLessonPlans, totalAssignments: $totalAssignments, totalResources: $totalResources)';
}
