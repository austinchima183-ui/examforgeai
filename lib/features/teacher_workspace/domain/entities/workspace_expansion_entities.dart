import 'package:equatable/equatable.dart';

import 'teacher_workspace_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the type of a presentation.
enum PresentationType {
  powerpoint(
    value: 'powerpoint',
    label: 'PowerPoint',
  ),
  teachingSlides(
    value: 'teaching_slides',
    label: 'Teaching Slides',
  ),
  infographic(
    value: 'infographic',
    label: 'Infographic',
  ),
  diagram(
    value: 'diagram',
    label: 'Diagram',
  ),
  flowchart(
    value: 'flowchart',
    label: 'Flowchart',
  ),
  mindMap(
    value: 'mind_map',
    label: 'Mind Map',
  ),
  summarySheet(
    value: 'summary_sheet',
    label: 'Summary Sheet',
  );

  const PresentationType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [PresentationType].
  ///
  /// Returns `null` if the value does not match any known type.
  static PresentationType? fromString(String? value) {
    if (value == null) return null;
    return PresentationType.values.cast<PresentationType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a communication.
enum CommunicationType {
  parentLetter(
    value: 'parent_letter',
    label: 'Parent Letter',
  ),
  studentFeedback(
    value: 'student_feedback',
    label: 'Student Feedback',
  ),
  email(
    value: 'email',
    label: 'Email',
  ),
  sms(
    value: 'sms',
    label: 'SMS',
  ),
  announcement(
    value: 'announcement',
    label: 'Announcement',
  ),
  meetingInvitation(
    value: 'meeting_invitation',
    label: 'Meeting Invitation',
  ),
  permissionLetter(
    value: 'permission_letter',
    label: 'Permission Letter',
  ),
  certificate(
    value: 'certificate',
    label: 'Certificate',
  );

  const CommunicationType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [CommunicationType].
  ///
  /// Returns `null` if the value does not match any known type.
  static CommunicationType? fromString(String? value) {
    if (value == null) return null;
    return CommunicationType.values.cast<CommunicationType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the tone of a communication.
enum CommunicationTone {
  formal(
    value: 'formal',
    label: 'Formal',
  ),
  friendly(
    value: 'friendly',
    label: 'Friendly',
  ),
  encouraging(
    value: 'encouraging',
    label: 'Encouraging',
  ),
  professional(
    value: 'professional',
    label: 'Professional',
  );

  const CommunicationTone({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [CommunicationTone].
  ///
  /// Returns `null` if the value does not match any known tone.
  static CommunicationTone? fromString(String? value) {
    if (value == null) return null;
    return CommunicationTone.values.cast<CommunicationTone?>().firstWhere(
          (tone) => tone?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the priority level of a task.
enum TaskPriority {
  low(
    value: 'low',
    label: 'Low',
  ),
  medium(
    value: 'medium',
    label: 'Medium',
  ),
  high(
    value: 'high',
    label: 'High',
  ),
  urgent(
    value: 'urgent',
    label: 'Urgent',
  );

  const TaskPriority({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [TaskPriority].
  ///
  /// Returns `null` if the value does not match any known priority.
  static TaskPriority? fromString(String? value) {
    if (value == null) return null;
    return TaskPriority.values.cast<TaskPriority?>().firstWhere(
          (priority) => priority?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the status of a task.
enum TaskStatus {
  pending(
    value: 'pending',
    label: 'Pending',
  ),
  inProgress(
    value: 'in_progress',
    label: 'In Progress',
  ),
  completed(
    value: 'completed',
    label: 'Completed',
  ),
  cancelled(
    value: 'cancelled',
    label: 'Cancelled',
  );

  const TaskStatus({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [TaskStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static TaskStatus? fromString(String? value) {
    if (value == null) return null;
    return TaskStatus.values.cast<TaskStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the category of a task.
enum TaskCategory {
  lesson(
    value: 'lesson',
    label: 'Lesson',
  ),
  grading(
    value: 'grading',
    label: 'Grading',
  ),
  meeting(
    value: 'meeting',
    label: 'Meeting',
  ),
  admin(
    value: 'admin',
    label: 'Admin',
  ),
  personal(
    value: 'personal',
    label: 'Personal',
  ),
  general(
    value: 'general',
    label: 'General',
  );

  const TaskCategory({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [TaskCategory].
  ///
  /// Returns `null` if the value does not match any known category.
  static TaskCategory? fromString(String? value) {
    if (value == null) return null;
    return TaskCategory.values.cast<TaskCategory?>().firstWhere(
          (category) => category?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the proficiency level for a rubric criterion.
enum RubricCriterionLevel {
  beginning(
    value: 'beginning',
    label: 'Beginning',
  ),
  developing(
    value: 'developing',
    label: 'Developing',
  ),
  proficient(
    value: 'proficient',
    label: 'Proficient',
  ),
  exemplary(
    value: 'exemplary',
    label: 'Exemplary',
  );

  const RubricCriterionLevel({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [RubricCriterionLevel].
  ///
  /// Returns `null` if the value does not match any known level.
  static RubricCriterionLevel? fromString(String? value) {
    if (value == null) return null;
    return RubricCriterionLevel.values.cast<RubricCriterionLevel?>().firstWhere(
          (level) => level?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of an assessment.
enum AssessmentType {
  oral(
    value: 'oral',
    label: 'Oral',
  ),
  practical(
    value: 'practical',
    label: 'Practical',
  ),
  rubricBased(
    value: 'rubric_based',
    label: 'Rubric-Based',
  );

  const AssessmentType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into an [AssessmentType].
  ///
  /// Returns `null` if the value does not match any known type.
  static AssessmentType? fromString(String? value) {
    if (value == null) return null;
    return AssessmentType.values.cast<AssessmentType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a subtask within a task.
class SubtaskEntity extends Equatable {
  const SubtaskEntity({
    this.id,
    required this.title,
    this.isCompleted = false,
  });

  /// Unique identifier for the subtask.
  final String? id;

  /// The title of the subtask.
  final String title;

  /// Whether the subtask has been completed.
  final bool isCompleted;

  /// Creates a copy of this [SubtaskEntity] with the given fields replaced.
  SubtaskEntity copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        isCompleted,
      ];
}

/// Represents a level within a rubric criterion.
class RubricLevelEntity extends Equatable {
  const RubricLevelEntity({
    required this.level,
    required this.description,
    required this.score,
  });

  /// The proficiency level for this rubric level.
  final RubricCriterionLevel level;

  /// Description of what this level looks like.
  final String description;

  /// The numeric score associated with this level.
  final double score;

  /// Creates a copy of this [RubricLevelEntity] with the given fields replaced.
  RubricLevelEntity copyWith({
    RubricCriterionLevel? level,
    String? description,
    double? score,
  }) {
    return RubricLevelEntity(
      level: level ?? this.level,
      description: description ?? this.description,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props => [
        level,
        description,
        score,
      ];
}

/// Represents a single criterion within a rubric.
class RubricCriterionEntity extends Equatable {
  const RubricCriterionEntity({
    required this.criterion,
    required this.weight,
    this.levels = const [],
  });

  /// The name of the criterion being assessed.
  final String criterion;

  /// The weight of this criterion relative to others.
  final double weight;

  /// The proficiency levels defined for this criterion.
  final List<RubricLevelEntity> levels;

  /// Creates a copy of this [RubricCriterionEntity] with the given fields replaced.
  RubricCriterionEntity copyWith({
    String? criterion,
    double? weight,
    List<RubricLevelEntity>? levels,
  }) {
    return RubricCriterionEntity(
      criterion: criterion ?? this.criterion,
      weight: weight ?? this.weight,
      levels: levels ?? this.levels,
    );
  }

  @override
  List<Object?> get props => [
        criterion,
        weight,
        levels,
      ];
}

/// Represents a single oral question item within an oral question set.
class OralQuestionItemEntity extends Equatable {
  const OralQuestionItemEntity({
    required this.question,
    this.expectedAnswer,
    this.marks = 0.0,
    this.difficulty,
    this.bloomLevel,
  });

  /// The question text.
  final String question;

  /// The expected answer for reference.
  final String? expectedAnswer;

  /// The marks allocated to this question.
  final double marks;

  /// The difficulty level of this question.
  final String? difficulty;

  /// The Bloom's taxonomy level targeted by this question.
  final String? bloomLevel;

  /// Creates a copy of this [OralQuestionItemEntity] with the given fields replaced.
  OralQuestionItemEntity copyWith({
    String? question,
    String? expectedAnswer,
    double? marks,
    String? difficulty,
    String? bloomLevel,
  }) {
    return OralQuestionItemEntity(
      question: question ?? this.question,
      expectedAnswer: expectedAnswer ?? this.expectedAnswer,
      marks: marks ?? this.marks,
      difficulty: difficulty ?? this.difficulty,
      bloomLevel: bloomLevel ?? this.bloomLevel,
    );
  }

  @override
  List<Object?> get props => [
        question,
        expectedAnswer,
        marks,
        difficulty,
        bloomLevel,
      ];
}

/// Represents statistics for the teacher workspace dashboard.
class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    this.lessonPlans = 0,
    this.worksheets = 0,
    this.assignments = 0,
    this.presentations = 0,
    this.rubrics = 0,
    this.resources = 0,
    this.aiGenerations = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.sharedWithMe = 0,
  });

  /// Total number of lesson plans.
  final int lessonPlans;

  /// Total number of worksheets.
  final int worksheets;

  /// Total number of assignments.
  final int assignments;

  /// Total number of presentations.
  final int presentations;

  /// Total number of rubrics.
  final int rubrics;

  /// Total number of resources.
  final int resources;

  /// Total number of AI generations.
  final int aiGenerations;

  /// Number of pending tasks.
  final int pendingTasks;

  /// Number of overdue tasks.
  final int overdueTasks;

  /// Number of resources shared with the teacher.
  final int sharedWithMe;

  /// Creates a copy of this [DashboardStatsEntity] with the given fields replaced.
  DashboardStatsEntity copyWith({
    int? lessonPlans,
    int? worksheets,
    int? assignments,
    int? presentations,
    int? rubrics,
    int? resources,
    int? aiGenerations,
    int? pendingTasks,
    int? overdueTasks,
    int? sharedWithMe,
  }) {
    return DashboardStatsEntity(
      lessonPlans: lessonPlans ?? this.lessonPlans,
      worksheets: worksheets ?? this.worksheets,
      assignments: assignments ?? this.assignments,
      presentations: presentations ?? this.presentations,
      rubrics: rubrics ?? this.rubrics,
      resources: resources ?? this.resources,
      aiGenerations: aiGenerations ?? this.aiGenerations,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      sharedWithMe: sharedWithMe ?? this.sharedWithMe,
    );
  }

  @override
  List<Object?> get props => [
        lessonPlans,
        worksheets,
        assignments,
        presentations,
        rubrics,
        resources,
        aiGenerations,
        pendingTasks,
        overdueTasks,
        sharedWithMe,
      ];
}

/// Represents an event on the teacher workspace dashboard.
class DashboardEventEntity extends Equatable {
  const DashboardEventEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.eventType,
  });

  /// Unique identifier for the event.
  final String id;

  /// The title of the event.
  final String title;

  /// The start time of the event.
  final DateTime startTime;

  /// The end time of the event.
  final DateTime endTime;

  /// The type of the event.
  final String eventType;

  /// Creates a copy of this [DashboardEventEntity] with the given fields replaced.
  DashboardEventEntity copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? eventType,
  }) {
    return DashboardEventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      eventType: eventType ?? this.eventType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        startTime,
        endTime,
        eventType,
      ];
}

/// Represents an assignment item on the teacher workspace dashboard.
class DashboardAssignmentEntity extends Equatable {
  const DashboardAssignmentEntity({
    required this.id,
    required this.title,
    this.deadline,
    required this.status,
  });

  /// Unique identifier for the assignment.
  final String id;

  /// The title of the assignment.
  final String title;

  /// The deadline for the assignment.
  final DateTime? deadline;

  /// The current status of the assignment.
  final String status;

  /// Creates a copy of this [DashboardAssignmentEntity] with the given fields replaced.
  DashboardAssignmentEntity copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    String? status,
  }) {
    return DashboardAssignmentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        deadline,
        status,
      ];
}

/// Represents a recently accessed document on the dashboard.
class RecentDocumentEntity extends Equatable {
  const RecentDocumentEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.updatedAt,
  });

  /// Unique identifier for the document.
  final String id;

  /// The title of the document.
  final String title;

  /// The type of the document.
  final String type;

  /// When the document was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [RecentDocumentEntity] with the given fields replaced.
  RecentDocumentEntity copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? updatedAt,
  }) {
    return RecentDocumentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        updatedAt,
      ];
}

/// Represents a template item on the teacher workspace dashboard.
class DashboardTemplateEntity extends Equatable {
  const DashboardTemplateEntity({
    required this.id,
    required this.name,
    required this.templateType,
    this.usageCount = 0,
  });

  /// Unique identifier for the template.
  final String id;

  /// The name of the template.
  final String name;

  /// The type of the template.
  final String templateType;

  /// How many times this template has been used.
  final int usageCount;

  /// Creates a copy of this [DashboardTemplateEntity] with the given fields replaced.
  DashboardTemplateEntity copyWith({
    String? id,
    String? name,
    String? templateType,
    int? usageCount,
  }) {
    return DashboardTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      templateType: templateType ?? this.templateType,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        templateType,
        usageCount,
      ];
}

/// Represents aggregated teaching statistics for the dashboard.
class TeachingStatisticsEntity extends Equatable {
  const TeachingStatisticsEntity({
    this.totalStudents = 0,
    this.classesTaught = 0,
    this.questionsGenerated = 0,
    this.resourcesShared = 0,
  });

  /// Total number of students taught.
  final int totalStudents;

  /// Total number of classes taught.
  final int classesTaught;

  /// Total number of questions generated via AI.
  final int questionsGenerated;

  /// Total number of resources shared with others.
  final int resourcesShared;

  /// Creates a copy of this [TeachingStatisticsEntity] with the given fields replaced.
  TeachingStatisticsEntity copyWith({
    int? totalStudents,
    int? classesTaught,
    int? questionsGenerated,
    int? resourcesShared,
  }) {
    return TeachingStatisticsEntity(
      totalStudents: totalStudents ?? this.totalStudents,
      classesTaught: classesTaught ?? this.classesTaught,
      questionsGenerated: questionsGenerated ?? this.questionsGenerated,
      resourcesShared: resourcesShared ?? this.resourcesShared,
    );
  }

  @override
  List<Object?> get props => [
        totalStudents,
        classesTaught,
        questionsGenerated,
        resourcesShared,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a presentation created by a teacher.
class PresentationEntity extends Equatable {
  const PresentationEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    required this.presentationType,
    this.slides = const [],
    this.speakerNotes,
    this.totalSlides = 0,
    this.topic,
    this.curriculum,
    this.difficulty,
    this.customInstructions,
    this.isAiGenerated = false,
    this.aiModel,
    this.generationTimeMs,
    this.tokensUsed,
    this.isPublished = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.isTemplate = false,
    this.templateId,
    this.lastExportFormat,
    this.lastExportedAt,
    this.version = 1,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the presentation.
  final String id;

  /// The school identifier this presentation belongs to.
  final String? schoolId;

  /// The teacher who created this presentation.
  final String teacherId;

  /// The subject this presentation is associated with.
  final String? subjectId;

  /// The class this presentation is associated with.
  final String? classId;

  /// The title of the presentation.
  final String title;

  /// An optional description of the presentation.
  final String? description;

  /// The type of the presentation.
  final PresentationType presentationType;

  /// The slides content of the presentation.
  final List<Map<String, dynamic>> slides;

  /// Speaker notes accompanying the presentation.
  final String? speakerNotes;

  /// Total number of slides in the presentation.
  final int totalSlides;

  /// The topic covered by the presentation.
  final String? topic;

  /// The curriculum type the presentation aligns with.
  final CurriculumType? curriculum;

  /// The difficulty level targeted by the presentation.
  final StudentLevel? difficulty;

  /// Custom instructions for AI generation.
  final String? customInstructions;

  /// Whether this presentation was AI-generated.
  final bool isAiGenerated;

  /// The AI model used for generation.
  final String? aiModel;

  /// Time taken for AI generation in milliseconds.
  final int? generationTimeMs;

  /// Number of tokens used for AI generation.
  final int? tokensUsed;

  /// Whether this presentation is published.
  final bool isPublished;

  /// Whether this presentation is archived.
  final bool isArchived;

  /// Whether this presentation is marked as a favorite.
  final bool isFavorite;

  /// Whether this presentation is a template.
  final bool isTemplate;

  /// The template this presentation was created from.
  final String? templateId;

  /// The format of the last export.
  final String? lastExportFormat;

  /// When the presentation was last exported.
  final DateTime? lastExportedAt;

  /// The version number of the presentation.
  final int version;

  /// Tags for categorizing and filtering the presentation.
  final List<String> tags;

  /// When the presentation was created.
  final DateTime createdAt;

  /// When the presentation was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [PresentationEntity] with the given fields replaced.
  PresentationEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    PresentationType? presentationType,
    List<Map<String, dynamic>>? slides,
    String? speakerNotes,
    int? totalSlides,
    String? topic,
    CurriculumType? curriculum,
    StudentLevel? difficulty,
    String? customInstructions,
    bool? isAiGenerated,
    String? aiModel,
    int? generationTimeMs,
    int? tokensUsed,
    bool? isPublished,
    bool? isArchived,
    bool? isFavorite,
    bool? isTemplate,
    String? templateId,
    String? lastExportFormat,
    DateTime? lastExportedAt,
    int? version,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PresentationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      presentationType: presentationType ?? this.presentationType,
      slides: slides ?? this.slides,
      speakerNotes: speakerNotes ?? this.speakerNotes,
      totalSlides: totalSlides ?? this.totalSlides,
      topic: topic ?? this.topic,
      curriculum: curriculum ?? this.curriculum,
      difficulty: difficulty ?? this.difficulty,
      customInstructions: customInstructions ?? this.customInstructions,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      isTemplate: isTemplate ?? this.isTemplate,
      templateId: templateId ?? this.templateId,
      lastExportFormat: lastExportFormat ?? this.lastExportFormat,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      version: version ?? this.version,
      tags: tags ?? this.tags,
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
        presentationType,
        slides,
        speakerNotes,
        totalSlides,
        topic,
        curriculum,
        difficulty,
        customInstructions,
        isAiGenerated,
        aiModel,
        generationTimeMs,
        tokensUsed,
        isPublished,
        isArchived,
        isFavorite,
        isTemplate,
        templateId,
        lastExportFormat,
        lastExportedAt,
        version,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents a communication created by a teacher.
class CommunicationEntity extends Equatable {
  const CommunicationEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    required this.content,
    required this.communicationType,
    required this.tone,
    required this.recipientType,
    this.recipientIds = const [],
    this.purpose,
    this.customInstructions,
    this.isAiGenerated = false,
    this.aiModel,
    this.generationTimeMs,
    this.tokensUsed,
    this.isSent = false,
    this.isDraft = true,
    this.isArchived = false,
    this.isTemplate = false,
    this.sentAt,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the communication.
  final String id;

  /// The school identifier this communication belongs to.
  final String? schoolId;

  /// The teacher who created this communication.
  final String teacherId;

  /// The subject this communication is associated with.
  final String? subjectId;

  /// The class this communication is associated with.
  final String? classId;

  /// The title of the communication.
  final String title;

  /// The content of the communication.
  final String content;

  /// The type of the communication.
  final CommunicationType communicationType;

  /// The tone of the communication.
  final CommunicationTone tone;

  /// The type of recipients (e.g., parents, students).
  final String recipientType;

  /// The IDs of the recipients.
  final List<String> recipientIds;

  /// The purpose of the communication.
  final String? purpose;

  /// Custom instructions for AI generation.
  final String? customInstructions;

  /// Whether this communication was AI-generated.
  final bool isAiGenerated;

  /// The AI model used for generation.
  final String? aiModel;

  /// Time taken for AI generation in milliseconds.
  final int? generationTimeMs;

  /// Number of tokens used for AI generation.
  final int? tokensUsed;

  /// Whether this communication has been sent.
  final bool isSent;

  /// Whether this communication is a draft.
  final bool isDraft;

  /// Whether this communication is archived.
  final bool isArchived;

  /// Whether this communication is a template.
  final bool isTemplate;

  /// When the communication was sent.
  final DateTime? sentAt;

  /// Tags for categorizing and filtering the communication.
  final List<String> tags;

  /// When the communication was created.
  final DateTime createdAt;

  /// When the communication was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [CommunicationEntity] with the given fields replaced.
  CommunicationEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? content,
    CommunicationType? communicationType,
    CommunicationTone? tone,
    String? recipientType,
    List<String>? recipientIds,
    String? purpose,
    String? customInstructions,
    bool? isAiGenerated,
    String? aiModel,
    int? generationTimeMs,
    int? tokensUsed,
    bool? isSent,
    bool? isDraft,
    bool? isArchived,
    bool? isTemplate,
    DateTime? sentAt,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunicationEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      content: content ?? this.content,
      communicationType: communicationType ?? this.communicationType,
      tone: tone ?? this.tone,
      recipientType: recipientType ?? this.recipientType,
      recipientIds: recipientIds ?? this.recipientIds,
      purpose: purpose ?? this.purpose,
      customInstructions: customInstructions ?? this.customInstructions,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      isSent: isSent ?? this.isSent,
      isDraft: isDraft ?? this.isDraft,
      isArchived: isArchived ?? this.isArchived,
      isTemplate: isTemplate ?? this.isTemplate,
      sentAt: sentAt ?? this.sentAt,
      tags: tags ?? this.tags,
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
        content,
        communicationType,
        tone,
        recipientType,
        recipientIds,
        purpose,
        customInstructions,
        isAiGenerated,
        aiModel,
        generationTimeMs,
        tokensUsed,
        isSent,
        isDraft,
        isArchived,
        isTemplate,
        sentAt,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents a task created by a teacher.
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.category,
    this.relatedResourceType,
    this.relatedResourceId,
    this.dueDate,
    this.reminderAt,
    this.isReminderSent = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.subtasks = const [],
    this.completedAt,
    this.completionNotes,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the task.
  final String id;

  /// The school identifier this task belongs to.
  final String? schoolId;

  /// The teacher who created this task.
  final String teacherId;

  /// The title of the task.
  final String title;

  /// An optional description of the task.
  final String? description;

  /// The priority level of the task.
  final TaskPriority priority;

  /// The current status of the task.
  final TaskStatus status;

  /// The category of the task.
  final TaskCategory category;

  /// The type of the related resource.
  final String? relatedResourceType;

  /// The ID of the related resource.
  final String? relatedResourceId;

  /// When the task is due.
  final DateTime? dueDate;

  /// When a reminder should be triggered.
  final DateTime? reminderAt;

  /// Whether the reminder has been sent.
  final bool isReminderSent;

  /// Whether the task is recurring.
  final bool isRecurring;

  /// The recurrence rule (e.g., RRULE format).
  final String? recurrenceRule;

  /// The subtasks within this task.
  final List<SubtaskEntity> subtasks;

  /// When the task was completed.
  final DateTime? completedAt;

  /// Notes added upon task completion.
  final String? completionNotes;

  /// Who the task is assigned to.
  final String? assignedTo;

  /// When the task was created.
  final DateTime createdAt;

  /// When the task was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [TaskEntity] with the given fields replaced.
  TaskEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    TaskCategory? category,
    String? relatedResourceType,
    String? relatedResourceId,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? isReminderSent,
    bool? isRecurring,
    String? recurrenceRule,
    List<SubtaskEntity>? subtasks,
    DateTime? completedAt,
    String? completionNotes,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      relatedResourceType: relatedResourceType ?? this.relatedResourceType,
      relatedResourceId: relatedResourceId ?? this.relatedResourceId,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      isReminderSent: isReminderSent ?? this.isReminderSent,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      subtasks: subtasks ?? this.subtasks,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      assignedTo: assignedTo ?? this.assignedTo,
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
        priority,
        status,
        category,
        relatedResourceType,
        relatedResourceId,
        dueDate,
        reminderAt,
        isReminderSent,
        isRecurring,
        recurrenceRule,
        subtasks,
        completedAt,
        completionNotes,
        assignedTo,
        createdAt,
        updatedAt,
      ];
}

/// Represents a rubric created by a teacher.
class RubricEntity extends Equatable {
  const RubricEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    this.criteria = const [],
    this.totalPoints = 0.0,
    this.topic,
    this.isAiGenerated = false,
    this.aiModel,
    this.isPublished = false,
    this.isTemplate = false,
    this.isArchived = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the rubric.
  final String id;

  /// The school identifier this rubric belongs to.
  final String? schoolId;

  /// The teacher who created this rubric.
  final String teacherId;

  /// The subject this rubric is associated with.
  final String? subjectId;

  /// The class this rubric is associated with.
  final String? classId;

  /// The title of the rubric.
  final String title;

  /// An optional description of the rubric.
  final String? description;

  /// The criteria defined in the rubric.
  final List<RubricCriterionEntity> criteria;

  /// The total points possible across all criteria.
  final double totalPoints;

  /// The topic this rubric covers.
  final String? topic;

  /// Whether this rubric was AI-generated.
  final bool isAiGenerated;

  /// The AI model used for generation.
  final String? aiModel;

  /// Whether this rubric is published.
  final bool isPublished;

  /// Whether this rubric is a template.
  final bool isTemplate;

  /// Whether this rubric is archived.
  final bool isArchived;

  /// Tags for categorizing and filtering the rubric.
  final List<String> tags;

  /// When the rubric was created.
  final DateTime createdAt;

  /// When the rubric was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [RubricEntity] with the given fields replaced.
  RubricEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    List<RubricCriterionEntity>? criteria,
    double? totalPoints,
    String? topic,
    bool? isAiGenerated,
    String? aiModel,
    bool? isPublished,
    bool? isTemplate,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RubricEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      totalPoints: totalPoints ?? this.totalPoints,
      topic: topic ?? this.topic,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      isPublished: isPublished ?? this.isPublished,
      isTemplate: isTemplate ?? this.isTemplate,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
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
        criteria,
        totalPoints,
        topic,
        isAiGenerated,
        aiModel,
        isPublished,
        isTemplate,
        isArchived,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents an oral question set created by a teacher.
class OralQuestionEntity extends Equatable {
  const OralQuestionEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    this.questions = const [],
    this.totalMarks = 0.0,
    this.estimatedDurationMinutes,
    this.topic,
    this.curriculum,
    this.difficulty,
    this.isAiGenerated = false,
    this.aiModel,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the oral question set.
  final String id;

  /// The school identifier this oral question set belongs to.
  final String? schoolId;

  /// The teacher who created this oral question set.
  final String teacherId;

  /// The subject this oral question set is associated with.
  final String? subjectId;

  /// The class this oral question set is associated with.
  final String? classId;

  /// The title of the oral question set.
  final String title;

  /// An optional description of the oral question set.
  final String? description;

  /// The list of oral questions.
  final List<OralQuestionItemEntity> questions;

  /// The total marks for the oral question set.
  final double totalMarks;

  /// The estimated duration in minutes.
  final int? estimatedDurationMinutes;

  /// The topic covered by the oral questions.
  final String? topic;

  /// The curriculum type the questions align with.
  final CurriculumType? curriculum;

  /// The difficulty level targeted by the questions.
  final StudentLevel? difficulty;

  /// Whether this oral question set was AI-generated.
  final bool isAiGenerated;

  /// The AI model used for generation.
  final String? aiModel;

  /// Whether this oral question set is published.
  final bool isPublished;

  /// Whether this oral question set is archived.
  final bool isArchived;

  /// Tags for categorizing and filtering the oral question set.
  final List<String> tags;

  /// When the oral question set was created.
  final DateTime createdAt;

  /// When the oral question set was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [OralQuestionEntity] with the given fields replaced.
  OralQuestionEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    List<OralQuestionItemEntity>? questions,
    double? totalMarks,
    int? estimatedDurationMinutes,
    String? topic,
    CurriculumType? curriculum,
    StudentLevel? difficulty,
    bool? isAiGenerated,
    String? aiModel,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OralQuestionEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      totalMarks: totalMarks ?? this.totalMarks,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      topic: topic ?? this.topic,
      curriculum: curriculum ?? this.curriculum,
      difficulty: difficulty ?? this.difficulty,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
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
        questions,
        totalMarks,
        estimatedDurationMinutes,
        topic,
        curriculum,
        difficulty,
        isAiGenerated,
        aiModel,
        isPublished,
        isArchived,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents a practical assessment created by a teacher.
class PracticalAssessmentEntity extends Equatable {
  const PracticalAssessmentEntity({
    required this.id,
    this.schoolId,
    required this.teacherId,
    this.subjectId,
    this.classId,
    required this.title,
    this.description,
    this.objectives = const [],
    this.materialsNeeded = const [],
    this.procedureSteps = const [],
    this.safetyPrecautions = const [],
    this.expectedResults,
    this.assessmentCriteria = const [],
    this.totalMarks = 0.0,
    this.estimatedDurationMinutes,
    this.topic,
    this.curriculum,
    this.difficulty,
    this.isAiGenerated = false,
    this.aiModel,
    this.rubricId,
    this.isPublished = false,
    this.isArchived = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the practical assessment.
  final String id;

  /// The school identifier this practical assessment belongs to.
  final String? schoolId;

  /// The teacher who created this practical assessment.
  final String teacherId;

  /// The subject this practical assessment is associated with.
  final String? subjectId;

  /// The class this practical assessment is associated with.
  final String? classId;

  /// The title of the practical assessment.
  final String title;

  /// An optional description of the practical assessment.
  final String? description;

  /// The learning objectives of the practical assessment.
  final List<String> objectives;

  /// Materials needed for the practical assessment.
  final List<String> materialsNeeded;

  /// Step-by-step procedure for the practical assessment.
  final List<String> procedureSteps;

  /// Safety precautions for the practical assessment.
  final List<String> safetyPrecautions;

  /// Expected results from the practical assessment.
  final String? expectedResults;

  /// Assessment criteria for evaluating the practical.
  final List<Map<String, dynamic>> assessmentCriteria;

  /// The total marks for the practical assessment.
  final double totalMarks;

  /// The estimated duration in minutes.
  final int? estimatedDurationMinutes;

  /// The topic covered by the practical assessment.
  final String? topic;

  /// The curriculum type the assessment aligns with.
  final CurriculumType? curriculum;

  /// The difficulty level targeted by the assessment.
  final StudentLevel? difficulty;

  /// Whether this practical assessment was AI-generated.
  final bool isAiGenerated;

  /// The AI model used for generation.
  final String? aiModel;

  /// The rubric associated with this practical assessment.
  final String? rubricId;

  /// Whether this practical assessment is published.
  final bool isPublished;

  /// Whether this practical assessment is archived.
  final bool isArchived;

  /// Tags for categorizing and filtering the practical assessment.
  final List<String> tags;

  /// When the practical assessment was created.
  final DateTime createdAt;

  /// When the practical assessment was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [PracticalAssessmentEntity] with the given fields replaced.
  PracticalAssessmentEntity copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    List<String>? objectives,
    List<String>? materialsNeeded,
    List<String>? procedureSteps,
    List<String>? safetyPrecautions,
    String? expectedResults,
    List<Map<String, dynamic>>? assessmentCriteria,
    double? totalMarks,
    int? estimatedDurationMinutes,
    String? topic,
    CurriculumType? curriculum,
    StudentLevel? difficulty,
    bool? isAiGenerated,
    String? aiModel,
    String? rubricId,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticalAssessmentEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      objectives: objectives ?? this.objectives,
      materialsNeeded: materialsNeeded ?? this.materialsNeeded,
      procedureSteps: procedureSteps ?? this.procedureSteps,
      safetyPrecautions: safetyPrecautions ?? this.safetyPrecautions,
      expectedResults: expectedResults ?? this.expectedResults,
      assessmentCriteria: assessmentCriteria ?? this.assessmentCriteria,
      totalMarks: totalMarks ?? this.totalMarks,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      topic: topic ?? this.topic,
      curriculum: curriculum ?? this.curriculum,
      difficulty: difficulty ?? this.difficulty,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModel: aiModel ?? this.aiModel,
      rubricId: rubricId ?? this.rubricId,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
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
        objectives,
        materialsNeeded,
        procedureSteps,
        safetyPrecautions,
        expectedResults,
        assessmentCriteria,
        totalMarks,
        estimatedDurationMinutes,
        topic,
        curriculum,
        difficulty,
        isAiGenerated,
        aiModel,
        rubricId,
        isPublished,
        isArchived,
        tags,
        createdAt,
        updatedAt,
      ];
}

/// Represents a shared resource between users.
class SharedResourceEntity extends Equatable {
  const SharedResourceEntity({
    required this.id,
    required this.schoolId,
    required this.resourceType,
    required this.resourceId,
    required this.sharedBy,
    required this.sharedWith,
    this.canEdit = false,
    this.canView = true,
    this.canComment = false,
    this.canDownload = true,
    this.message,
    this.isAccepted,
    required this.createdAt,
  });

  /// Unique identifier for the shared resource.
  final String id;

  /// The school identifier this shared resource belongs to.
  final String schoolId;

  /// The type of the shared resource.
  final String resourceType;

  /// The ID of the shared resource.
  final String resourceId;

  /// The user who shared the resource.
  final String sharedBy;

  /// The user with whom the resource is shared.
  final String sharedWith;

  /// Whether the recipient can edit the resource.
  final bool canEdit;

  /// Whether the recipient can view the resource.
  final bool canView;

  /// Whether the recipient can comment on the resource.
  final bool canComment;

  /// Whether the recipient can download the resource.
  final bool canDownload;

  /// An optional message accompanying the share.
  final String? message;

  /// Whether the share invitation has been accepted.
  final bool? isAccepted;

  /// When the resource was shared.
  final DateTime createdAt;

  /// Creates a copy of this [SharedResourceEntity] with the given fields replaced.
  SharedResourceEntity copyWith({
    String? id,
    String? schoolId,
    String? resourceType,
    String? resourceId,
    String? sharedBy,
    String? sharedWith,
    bool? canEdit,
    bool? canView,
    bool? canComment,
    bool? canDownload,
    String? message,
    bool? isAccepted,
    DateTime? createdAt,
  }) {
    return SharedResourceEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedWith: sharedWith ?? this.sharedWith,
      canEdit: canEdit ?? this.canEdit,
      canView: canView ?? this.canView,
      canComment: canComment ?? this.canComment,
      canDownload: canDownload ?? this.canDownload,
      message: message ?? this.message,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceType,
        resourceId,
        sharedBy,
        sharedWith,
        canEdit,
        canView,
        canComment,
        canDownload,
        message,
        isAccepted,
        createdAt,
      ];
}

/// Represents a collaboration comment on a shared resource.
class CollaborationCommentEntity extends Equatable {
  const CollaborationCommentEntity({
    required this.id,
    required this.schoolId,
    required this.resourceType,
    required this.resourceId,
    required this.content,
    required this.authorId,
    this.parentCommentId,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the comment.
  final String id;

  /// The school identifier this comment belongs to.
  final String schoolId;

  /// The type of the resource being commented on.
  final String resourceType;

  /// The ID of the resource being commented on.
  final String resourceId;

  /// The content of the comment.
  final String content;

  /// The author of the comment.
  final String authorId;

  /// The ID of the parent comment for threaded discussions.
  final String? parentCommentId;

  /// Whether the comment thread is resolved.
  final bool isResolved;

  /// The user who resolved the comment.
  final String? resolvedBy;

  /// When the comment was resolved.
  final DateTime? resolvedAt;

  /// When the comment was created.
  final DateTime createdAt;

  /// When the comment was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this [CollaborationCommentEntity] with the given fields replaced.
  CollaborationCommentEntity copyWith({
    String? id,
    String? schoolId,
    String? resourceType,
    String? resourceId,
    String? content,
    String? authorId,
    String? parentCommentId,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollaborationCommentEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceType,
        resourceId,
        content,
        authorId,
        parentCommentId,
        isResolved,
        resolvedBy,
        resolvedAt,
        createdAt,
        updatedAt,
      ];
}

/// Represents an enhanced dashboard with comprehensive workspace data.
class EnhancedWorkspaceDashboardEntity extends Equatable {
  const EnhancedWorkspaceDashboardEntity({
    required this.stats,
    this.todayClasses = const [],
    this.pendingAssignments = const [],
    this.recentDocuments = const [],
    this.savedTemplates = const [],
    this.upcomingEvents = const [],
    required this.teachingStatistics,
    this.notificationsCount = 0,
  });

  /// Aggregated statistics for the dashboard.
  final DashboardStatsEntity stats;

  /// Today's scheduled classes.
  final List<DashboardEventEntity> todayClasses;

  /// Assignments pending review or grading.
  final List<DashboardAssignmentEntity> pendingAssignments;

  /// Recently accessed documents.
  final List<RecentDocumentEntity> recentDocuments;

  /// Saved templates for quick access.
  final List<DashboardTemplateEntity> savedTemplates;

  /// Upcoming events and deadlines.
  final List<DashboardEventEntity> upcomingEvents;

  /// Aggregated teaching statistics.
  final TeachingStatisticsEntity teachingStatistics;

  /// Number of unread notifications.
  final int notificationsCount;

  /// Creates a copy of this [EnhancedWorkspaceDashboardEntity] with the given fields replaced.
  EnhancedWorkspaceDashboardEntity copyWith({
    DashboardStatsEntity? stats,
    List<DashboardEventEntity>? todayClasses,
    List<DashboardAssignmentEntity>? pendingAssignments,
    List<RecentDocumentEntity>? recentDocuments,
    List<DashboardTemplateEntity>? savedTemplates,
    List<DashboardEventEntity>? upcomingEvents,
    TeachingStatisticsEntity? teachingStatistics,
    int? notificationsCount,
  }) {
    return EnhancedWorkspaceDashboardEntity(
      stats: stats ?? this.stats,
      todayClasses: todayClasses ?? this.todayClasses,
      pendingAssignments: pendingAssignments ?? this.pendingAssignments,
      recentDocuments: recentDocuments ?? this.recentDocuments,
      savedTemplates: savedTemplates ?? this.savedTemplates,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      teachingStatistics: teachingStatistics ?? this.teachingStatistics,
      notificationsCount: notificationsCount ?? this.notificationsCount,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        todayClasses,
        pendingAssignments,
        recentDocuments,
        savedTemplates,
        upcomingEvents,
        teachingStatistics,
        notificationsCount,
      ];
}
