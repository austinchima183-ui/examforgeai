import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the teaching style used in a lesson plan.
enum TeachingStyle {
  lecture(
    value: 'lecture',
    label: 'Lecture',
  ),
  interactive(
    value: 'interactive',
    label: 'Interactive',
  ),
  discussion(
    value: 'discussion',
    label: 'Discussion',
  ),
  handsOn(
    value: 'hands_on',
    label: 'Hands-On',
  ),
  flipped(
    value: 'flipped',
    label: 'Flipped Classroom',
  ),
  blended(
    value: 'blended',
    label: 'Blended',
  ),
  inquiryBased(
    value: 'inquiry_based',
    label: 'Inquiry-Based',
  ),
  projectBased(
    value: 'project_based',
    label: 'Project-Based',
  ),
  cooperative(
    value: 'cooperative',
    label: 'Cooperative',
  );

  const TeachingStyle({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [TeachingStyle].
  ///
  /// Returns `null` if the value does not match any known style.
  static TeachingStyle? fromString(String? value) {
    if (value == null) return null;
    return TeachingStyle.values.cast<TeachingStyle?>().firstWhere(
          (style) => style?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the student level for content targeting.
enum StudentLevel {
  beginner(
    value: 'beginner',
    label: 'Beginner',
  ),
  elementary(
    value: 'elementary',
    label: 'Elementary',
  ),
  intermediate(
    value: 'intermediate',
    label: 'Intermediate',
  ),
  advanced(
    value: 'advanced',
    label: 'Advanced',
  ),
  expert(
    value: 'expert',
    label: 'Expert',
  );

  const StudentLevel({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [StudentLevel].
  ///
  /// Returns `null` if the value does not match any known level.
  static StudentLevel? fromString(String? value) {
    if (value == null) return null;
    return StudentLevel.values.cast<StudentLevel?>().firstWhere(
          (level) => level?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a worksheet.
enum WorksheetType {
  classwork(
    value: 'classwork',
    label: 'Classwork',
  ),
  homework(
    value: 'homework',
    label: 'Homework',
  ),
  revision(
    value: 'revision',
    label: 'Revision',
  ),
  practice(
    value: 'practice',
    label: 'Practice',
  ),
  activity(
    value: 'activity',
    label: 'Activity',
  ),
  assessment(
    value: 'assessment',
    label: 'Assessment',
  );

  const WorksheetType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [WorksheetType].
  ///
  /// Returns `null` if the value does not match any known type.
  static WorksheetType? fromString(String? value) {
    if (value == null) return null;
    return WorksheetType.values.cast<WorksheetType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the duration type for a plan.
enum PlanDuration {
  weekly(
    value: 'weekly',
    label: 'Weekly',
  ),
  monthly(
    value: 'monthly',
    label: 'Monthly',
  ),
  term(
    value: 'term',
    label: 'Term',
  ),
  annual(
    value: 'annual',
    label: 'Annual',
  );

  const PlanDuration({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [PlanDuration].
  ///
  /// Returns `null` if the value does not match any known duration.
  static PlanDuration? fromString(String? value) {
    if (value == null) return null;
    return PlanDuration.values.cast<PlanDuration?>().firstWhere(
          (duration) => duration?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the curriculum type for content alignment.
enum CurriculumType {
  nigerian(
    value: 'nigerian',
    label: 'Nigerian',
  ),
  waec(
    value: 'waec',
    label: 'WAEC',
  ),
  neco(
    value: 'neco',
    label: 'NECO',
  ),
  bece(
    value: 'bece',
    label: 'BECE',
  ),
  jamb(
    value: 'jamb',
    label: 'JAMB',
  ),
  igcse(
    value: 'igcse',
    label: 'IGCSE',
  ),
  cambridge(
    value: 'cambridge',
    label: 'Cambridge',
  ),
  ib(
    value: 'ib',
    label: 'IB',
  ),
  custom(
    value: 'custom',
    label: 'Custom',
  );

  const CurriculumType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [CurriculumType].
  ///
  /// Returns `null` if the value does not match any known type.
  static CurriculumType? fromString(String? value) {
    if (value == null) return null;
    return CurriculumType.values.cast<CurriculumType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a teaching resource.
enum ResourceType {
  notes(
    value: 'notes',
    label: 'Notes',
  ),
  slides(
    value: 'slides',
    label: 'Slides',
  ),
  handout(
    value: 'handout',
    label: 'Handout',
  ),
  studyGuide(
    value: 'study_guide',
    label: 'Study Guide',
  ),
  revisionMaterial(
    value: 'revision_material',
    label: 'Revision Material',
  ),
  classroomActivity(
    value: 'classroom_activity',
    label: 'Classroom Activity',
  ),
  rubric(
    value: 'rubric',
    label: 'Rubric',
  ),
  template(
    value: 'template',
    label: 'Template',
  );

  const ResourceType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [ResourceType].
  ///
  /// Returns `null` if the value does not match any known type.
  static ResourceType? fromString(String? value) {
    if (value == null) return null;
    return ResourceType.values.cast<ResourceType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the action type for AI content generation.
enum ContentAction {
  explain(
    value: 'explain',
    label: 'Explain',
  ),
  simplify(
    value: 'simplify',
    label: 'Simplify',
  ),
  expand(
    value: 'expand',
    label: 'Expand',
  ),
  rewrite(
    value: 'rewrite',
    label: 'Rewrite',
  ),
  translate(
    value: 'translate',
    label: 'Translate',
  ),
  generateExamples(
    value: 'generate_examples',
    label: 'Generate Examples',
  ),
  generateAnalogies(
    value: 'generate_analogies',
    label: 'Generate Analogies',
  ),
  createDiscussion(
    value: 'create_discussion',
    label: 'Create Discussion',
  ),
  createActivity(
    value: 'create_activity',
    label: 'Create Activity',
  );

  const ContentAction({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [ContentAction].
  ///
  /// Returns `null` if the value does not match any known action.
  static ContentAction? fromString(String? value) {
    if (value == null) return null;
    return ContentAction.values.cast<ContentAction?>().firstWhere(
          (action) => action?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the status of an assignment.
enum AssignmentStatus {
  draft(
    value: 'draft',
    label: 'Draft',
  ),
  published(
    value: 'published',
    label: 'Published',
  ),
  closed(
    value: 'closed',
    label: 'Closed',
  ),
  graded(
    value: 'graded',
    label: 'Graded',
  );

  const AssignmentStatus({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [AssignmentStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static AssignmentStatus? fromString(String? value) {
    if (value == null) return null;
    return AssignmentStatus.values.cast<AssignmentStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a calendar event.
enum EventType {
  class_(
    value: 'class',
    label: 'Class',
  ),
  meeting(
    value: 'meeting',
    label: 'Meeting',
  ),
  deadline(
    value: 'deadline',
    label: 'Deadline',
  ),
  reminder(
    value: 'reminder',
    label: 'Reminder',
  ),
  exam(
    value: 'exam',
    label: 'Exam',
  ),
  holiday(
    value: 'holiday',
    label: 'Holiday',
  ),
  personal(
    value: 'personal',
    label: 'Personal',
  ),
  other(
    value: 'other',
    label: 'Other',
  );

  const EventType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [EventType].
  ///
  /// Returns `null` if the value does not match any known type.
  static EventType? fromString(String? value) {
    if (value == null) return null;
    return EventType.values.cast<EventType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a lesson plan created by a teacher.
class LessonPlanEntity extends Equatable {
  const LessonPlanEntity({
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
  final CurriculumType curriculum;
  final List<String> learningObjectives;
  final List<String> learningOutcomes;
  final List<String> teachingMaterials;
  final List<Map<String, dynamic>> classroomActivities;
  final List<Map<String, dynamic>> practicalActivities;
  final List<String> homework;
  final List<Map<String, dynamic>> assessmentQuestions;
  final List<String> referencesList;
  final List<String> extensionActivities;
  final TeachingStyle teachingStyle;
  final StudentLevel studentLevel;
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

  LessonPlanEntity copyWith({
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
    CurriculumType? curriculum,
    List<String>? learningObjectives,
    List<String>? learningOutcomes,
    List<String>? teachingMaterials,
    List<Map<String, dynamic>>? classroomActivities,
    List<Map<String, dynamic>>? practicalActivities,
    List<String>? homework,
    List<Map<String, dynamic>>? assessmentQuestions,
    List<String>? referencesList,
    List<String>? extensionActivities,
    TeachingStyle? teachingStyle,
    StudentLevel? studentLevel,
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
    return LessonPlanEntity(
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

  @override
  List<Object?> get props => [
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
        learningObjectives,
        learningOutcomes,
        teachingMaterials,
        classroomActivities,
        practicalActivities,
        homework,
        assessmentQuestions,
        referencesList,
        extensionActivities,
        teachingStyle,
        studentLevel,
        durationMinutes,
        notes,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a scheme of work created by a teacher.
class SchemeOfWorkEntity extends Equatable {
  const SchemeOfWorkEntity({
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
  final CurriculumType curriculum;
  final PlanDuration durationType;
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

  SchemeOfWorkEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    String? subject,
    String? className,
    CurriculumType? curriculum,
    PlanDuration? durationType,
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
    return SchemeOfWorkEntity(
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

  @override
  List<Object?> get props => [
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
        weeklyPlans,
        objectives,
        resourcesNeeded,
        assessmentStrategy,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a worksheet created by a teacher.
class WorksheetEntity extends Equatable {
  const WorksheetEntity({
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
  final WorksheetType worksheetType;
  final String? instructions;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> answerKey;
  final double totalMarks;
  final int? durationMinutes;
  final String difficulty;
  final CurriculumType curriculum;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorksheetEntity copyWith({
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
    WorksheetType? worksheetType,
    String? instructions,
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? answerKey,
    double? totalMarks,
    int? durationMinutes,
    String? difficulty,
    CurriculumType? curriculum,
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
    return WorksheetEntity(
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

  @override
  List<Object?> get props => [
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
        questions,
        answerKey,
        totalMarks,
        durationMinutes,
        difficulty,
        curriculum,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents an assignment created by a teacher.
class WorkspaceAssignmentEntity extends Equatable {
  const WorkspaceAssignmentEntity({
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
    this.assignmentStatus = AssignmentStatus.draft,
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
  final AssignmentStatus assignmentStatus;
  final CurriculumType curriculum;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptSnapshot;
  final int version;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkspaceAssignmentEntity copyWith({
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
    AssignmentStatus? assignmentStatus,
    CurriculumType? curriculum,
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
    return WorkspaceAssignmentEntity(
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

  @override
  List<Object?> get props => [
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
        questions,
        markingRubric,
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
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a report comment for a student.
class ReportCommentEntity extends Equatable {
  const ReportCommentEntity({
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

  ReportCommentEntity copyWith({
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
    return ReportCommentEntity(
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

  @override
  List<Object?> get props => [
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
        strengths,
        areasForImprovement,
        isAiGenerated,
        aiPromptSnapshot,
        isEdited,
        isPublished,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a teaching resource created or saved by a teacher.
class TeachingResourceEntity extends Equatable {
  const TeachingResourceEntity({
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
  final ResourceType resourceType;
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

  TeachingResourceEntity copyWith({
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
    ResourceType? resourceType,
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
    return TeachingResourceEntity(
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

  @override
  List<Object?> get props => [
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
        fileUrls,
        isAiGenerated,
        aiPromptSnapshot,
        version,
        isPublished,
        isArchived,
        isFavorite,
        folderId,
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a folder for organizing teaching resources.
class ResourceFolderEntity extends Equatable {
  const ResourceFolderEntity({
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

  ResourceFolderEntity copyWith({
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
    return ResourceFolderEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a history entry of AI-generated content.
class AiContentHistoryEntity extends Equatable {
  const AiContentHistoryEntity({
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
  final ContentAction actionType;
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

  AiContentHistoryEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    ContentAction? actionType,
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
    return AiContentHistoryEntity(
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

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a calendar event for a teacher.
class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
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
  final EventType eventType;
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

  CalendarEventEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? title,
    String? description,
    EventType? eventType,
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
    return CalendarEventEntity(
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
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      relatedResourceType: relatedResourceType ?? this.relatedResourceType,
      relatedResourceId: relatedResourceId ?? this.relatedResourceId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
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
      ];
}

/// Represents a reusable template in the teacher workspace.
class WorkspaceTemplateEntity extends Equatable {
  const WorkspaceTemplateEntity({
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

  WorkspaceTemplateEntity copyWith({
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
    return WorkspaceTemplateEntity(
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

  @override
  List<Object?> get props => [
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
        tags,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a version snapshot of a workspace resource.
class WorkspaceVersionEntity extends Equatable {
  const WorkspaceVersionEntity({
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

  WorkspaceVersionEntity copyWith({
    String? id,
    String? teacherId,
    String? resourceType,
    String? resourceId,
    int? versionNumber,
    Map<String, dynamic>? snapshot,
    String? changeSummary,
    DateTime? createdAt,
  }) {
    return WorkspaceVersionEntity(
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

  @override
  List<Object?> get props => [
        id,
        teacherId,
        resourceType,
        resourceId,
        versionNumber,
        snapshot,
        changeSummary,
        createdAt,
      ];
}

/// Represents the aggregated dashboard data for a teacher workspace.
class WorkspaceDashboardEntity extends Equatable {
  const WorkspaceDashboardEntity({
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

  WorkspaceDashboardEntity copyWith({
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
    return WorkspaceDashboardEntity(
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

  @override
  List<Object?> get props => [
        totalLessonPlans,
        totalSchemes,
        totalWorksheets,
        totalAssignments,
        pendingAssignments,
        totalResources,
        todayEvents,
        upcomingEvents,
        recentAiContent,
        draftLessonPlans,
      ];
}

/// Represents filter/pagination criteria for workspace list queries.
class WorkspaceFilterEntity extends Equatable {
  const WorkspaceFilterEntity({
    this.subjectId,
    this.classId,
    this.searchQuery,
    this.tags = const [],
    this.page = 1,
    this.perPage = 20,
    this.isPublished,
    this.isArchived = false,
  });

  final String? subjectId;
  final String? classId;
  final String? searchQuery;
  final List<String> tags;
  final int page;
  final int perPage;
  final bool? isPublished;
  final bool isArchived;

  WorkspaceFilterEntity copyWith({
    String? subjectId,
    String? classId,
    String? searchQuery,
    List<String>? tags,
    int? page,
    int? perPage,
    bool? isPublished,
    bool? isArchived,
  }) {
    return WorkspaceFilterEntity(
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        classId,
        searchQuery,
        tags,
        page,
        perPage,
        isPublished,
        isArchived,
      ];
}
