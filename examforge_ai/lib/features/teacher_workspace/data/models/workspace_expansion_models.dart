import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a presentation, mapping to `presentations` table.
class PresentationModel {
  const PresentationModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final String presentationType;
  final List<Map<String, dynamic>> slides;
  final String? speakerNotes;
  final int totalSlides;
  final String? topic;
  final String? curriculum;
  final String? difficulty;
  final String? customInstructions;
  final bool isAiGenerated;
  final String? aiModel;
  final int? generationTimeMs;
  final int? tokensUsed;
  final bool isPublished;
  final bool isArchived;
  final bool isFavorite;
  final bool isTemplate;
  final String? templateId;
  final String? lastExportFormat;
  final DateTime? lastExportedAt;
  final int version;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory PresentationModel.fromJson(Map<String, dynamic> json) {
    return PresentationModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      presentationType: json['presentation_type'] as String? ??
          json['presentationType'] as String? ??
          'teaching_slides',
      slides: (json['slides'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      speakerNotes: json['speaker_notes'] as String? ??
          json['speakerNotes'] as String?,
      totalSlides: json['total_slides'] as int? ??
          json['totalSlides'] as int? ??
          0,
      topic: json['topic'] as String?,
      curriculum: json['curriculum'] as String?,
      difficulty: json['difficulty'] as String?,
      customInstructions: json['custom_instructions'] as String? ??
          json['customInstructions'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      generationTimeMs: json['generation_time_ms'] as int? ??
          json['generationTimeMs'] as int?,
      tokensUsed: json['tokens_used'] as int? ?? json['tokensUsed'] as int?,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      isFavorite: json['is_favorite'] as bool? ??
          json['isFavorite'] as bool? ??
          false,
      isTemplate: json['is_template'] as bool? ??
          json['isTemplate'] as bool? ??
          false,
      templateId: json['template_id'] as String? ??
          json['templateId'] as String?,
      lastExportFormat: json['last_export_format'] as String? ??
          json['lastExportFormat'] as String?,
      lastExportedAt: json['last_exported_at'] != null
          ? DateTime.parse(json['last_exported_at'] as String)
          : json['lastExportedAt'] != null
              ? DateTime.parse(json['lastExportedAt'] as String)
              : null,
      version: json['version'] as int? ?? 1,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'presentation_type': presentationType,
      'slides': slides,
      'speaker_notes': speakerNotes,
      'total_slides': totalSlides,
      'topic': topic,
      'curriculum': curriculum,
      'difficulty': difficulty,
      'custom_instructions': customInstructions,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'generation_time_ms': generationTimeMs,
      'tokens_used': tokensUsed,
      'is_published': isPublished,
      'is_archived': isArchived,
      'is_favorite': isFavorite,
      'is_template': isTemplate,
      'template_id': templateId,
      'last_export_format': lastExportFormat,
      'last_exported_at': lastExportedAt?.toIso8601String(),
      'version': version,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory PresentationModel.fromEntity(PresentationEntity entity) {
    return PresentationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      presentationType: entity.presentationType.value,
      slides: entity.slides,
      speakerNotes: entity.speakerNotes,
      totalSlides: entity.totalSlides,
      topic: entity.topic,
      curriculum: entity.curriculum?.value,
      difficulty: entity.difficulty?.value,
      customInstructions: entity.customInstructions,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      generationTimeMs: entity.generationTimeMs,
      tokensUsed: entity.tokensUsed,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      isFavorite: entity.isFavorite,
      isTemplate: entity.isTemplate,
      templateId: entity.templateId,
      lastExportFormat: entity.lastExportFormat,
      lastExportedAt: entity.lastExportedAt,
      version: entity.version,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PresentationEntity toEntity() {
    return PresentationEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      presentationType: PresentationType.fromString(presentationType) ??
          PresentationType.teachingSlides,
      slides: slides,
      speakerNotes: speakerNotes,
      totalSlides: totalSlides,
      topic: topic,
      curriculum: CurriculumType.fromString(curriculum),
      difficulty: StudentLevel.fromString(difficulty),
      customInstructions: customInstructions,
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      generationTimeMs: generationTimeMs,
      tokensUsed: tokensUsed,
      isPublished: isPublished,
      isArchived: isArchived,
      isFavorite: isFavorite,
      isTemplate: isTemplate,
      templateId: templateId,
      lastExportFormat: lastExportFormat,
      lastExportedAt: lastExportedAt,
      version: version,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  PresentationModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    String? presentationType,
    List<Map<String, dynamic>>? slides,
    String? speakerNotes,
    int? totalSlides,
    String? topic,
    String? curriculum,
    String? difficulty,
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
    return PresentationModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          presentationType == other.presentationType &&
          slides == other.slides &&
          speakerNotes == other.speakerNotes &&
          totalSlides == other.totalSlides &&
          topic == other.topic &&
          curriculum == other.curriculum &&
          difficulty == other.difficulty &&
          customInstructions == other.customInstructions &&
          isAiGenerated == other.isAiGenerated &&
          aiModel == other.aiModel &&
          generationTimeMs == other.generationTimeMs &&
          tokensUsed == other.tokensUsed &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          isFavorite == other.isFavorite &&
          isTemplate == other.isTemplate &&
          templateId == other.templateId &&
          lastExportFormat == other.lastExportFormat &&
          lastExportedAt == other.lastExportedAt &&
          version == other.version &&
          tags == other.tags &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        title,
        description,
        presentationType,
        Object.hashAll(slides),
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
        Object.hashAll(tags),
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'PresentationModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION VERSION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a presentation version, mapping to `presentation_versions` table.
class PresentationVersionModel {
  const PresentationVersionModel({
    required this.id,
    required this.presentationId,
    required this.versionNumber,
    this.snapshot = const {},
    this.changeSummary,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String presentationId;
  final int versionNumber;
  final Map<String, dynamic> snapshot;
  final String? changeSummary;
  final String? createdBy;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory PresentationVersionModel.fromJson(Map<String, dynamic> json) {
    return PresentationVersionModel(
      id: json['id'] as String,
      presentationId: json['presentation_id'] as String? ??
          json['presentationId'] as String? ??
          '',
      versionNumber: json['version_number'] as int? ??
          json['versionNumber'] as int? ??
          1,
      snapshot: json['snapshot'] as Map<String, dynamic>? ?? const {},
      changeSummary: json['change_summary'] as String? ??
          json['changeSummary'] as String?,
      createdBy: json['created_by'] as String? ??
          json['createdBy'] as String?,
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
      'presentation_id': presentationId,
      'version_number': versionNumber,
      'snapshot': snapshot,
      'change_summary': changeSummary,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  PresentationVersionModel copyWith({
    String? id,
    String? presentationId,
    int? versionNumber,
    Map<String, dynamic>? snapshot,
    String? changeSummary,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PresentationVersionModel(
      id: id ?? this.id,
      presentationId: presentationId ?? this.presentationId,
      versionNumber: versionNumber ?? this.versionNumber,
      snapshot: snapshot ?? this.snapshot,
      changeSummary: changeSummary ?? this.changeSummary,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVersionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          presentationId == other.presentationId &&
          versionNumber == other.versionNumber &&
          snapshot == other.snapshot &&
          changeSummary == other.changeSummary &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        presentationId,
        versionNumber,
        snapshot,
        changeSummary,
        createdBy,
        createdAt,
      );

  @override
  String toString() =>
      'PresentationVersionModel(id: $id, presentationId: $presentationId, versionNumber: $versionNumber)';

  // ─── Entity Conversion ─────────────────────────────────────────────

  WorkspaceVersionEntity toEntity() {
    return WorkspaceVersionEntity(
      id: id,
      teacherId: createdBy ?? '',
      resourceType: 'presentation',
      resourceId: presentationId,
      versionNumber: versionNumber,
      snapshot: snapshot,
      changeSummary: changeSummary,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a communication, mapping to `communications` table.
class CommunicationModel {
  const CommunicationModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String content;
  final String communicationType;
  final String tone;
  final String recipientType;
  final List<String> recipientIds;
  final String? purpose;
  final String? customInstructions;
  final bool isAiGenerated;
  final String? aiModel;
  final int? generationTimeMs;
  final int? tokensUsed;
  final bool isSent;
  final bool isDraft;
  final bool isArchived;
  final bool isTemplate;
  final DateTime? sentAt;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CommunicationModel.fromJson(Map<String, dynamic> json) {
    return CommunicationModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      communicationType: json['communication_type'] as String? ??
          json['communicationType'] as String? ??
          'parent_letter',
      tone: json['tone'] as String? ?? json['tone'] as String? ?? 'formal',
      recipientType: json['recipient_type'] as String? ??
          json['recipientType'] as String? ??
          'parents',
      recipientIds: (json['recipient_ids'] as List<dynamic>?)?.cast<String>() ??
          (json['recipientIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      purpose: json['purpose'] as String?,
      customInstructions: json['custom_instructions'] as String? ??
          json['customInstructions'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      generationTimeMs: json['generation_time_ms'] as int? ??
          json['generationTimeMs'] as int?,
      tokensUsed: json['tokens_used'] as int? ?? json['tokensUsed'] as int?,
      isSent: json['is_sent'] as bool? ?? json['isSent'] as bool? ?? false,
      isDraft: json['is_draft'] as bool? ?? json['isDraft'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      isTemplate: json['is_template'] as bool? ??
          json['isTemplate'] as bool? ??
          false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : json['sentAt'] != null
              ? DateTime.parse(json['sentAt'] as String)
              : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'content': content,
      'communication_type': communicationType,
      'tone': tone,
      'recipient_type': recipientType,
      'recipient_ids': recipientIds,
      'purpose': purpose,
      'custom_instructions': customInstructions,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'generation_time_ms': generationTimeMs,
      'tokens_used': tokensUsed,
      'is_sent': isSent,
      'is_draft': isDraft,
      'is_archived': isArchived,
      'is_template': isTemplate,
      'sent_at': sentAt?.toIso8601String(),
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CommunicationModel.fromEntity(CommunicationEntity entity) {
    return CommunicationModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      content: entity.content,
      communicationType: entity.communicationType.value,
      tone: entity.tone.value,
      recipientType: entity.recipientType,
      recipientIds: entity.recipientIds,
      purpose: entity.purpose,
      customInstructions: entity.customInstructions,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      generationTimeMs: entity.generationTimeMs,
      tokensUsed: entity.tokensUsed,
      isSent: entity.isSent,
      isDraft: entity.isDraft,
      isArchived: entity.isArchived,
      isTemplate: entity.isTemplate,
      sentAt: entity.sentAt,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CommunicationEntity toEntity() {
    return CommunicationEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      content: content,
      communicationType: CommunicationType.fromString(communicationType) ??
          CommunicationType.parentLetter,
      tone: CommunicationTone.fromString(tone) ?? CommunicationTone.formal,
      recipientType: recipientType,
      recipientIds: recipientIds,
      purpose: purpose,
      customInstructions: customInstructions,
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      generationTimeMs: generationTimeMs,
      tokensUsed: tokensUsed,
      isSent: isSent,
      isDraft: isDraft,
      isArchived: isArchived,
      isTemplate: isTemplate,
      sentAt: sentAt,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  CommunicationModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? content,
    String? communicationType,
    String? tone,
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
    return CommunicationModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          content == other.content &&
          communicationType == other.communicationType &&
          tone == other.tone &&
          recipientType == other.recipientType &&
          recipientIds == other.recipientIds &&
          purpose == other.purpose &&
          customInstructions == other.customInstructions &&
          isAiGenerated == other.isAiGenerated &&
          aiModel == other.aiModel &&
          generationTimeMs == other.generationTimeMs &&
          tokensUsed == other.tokensUsed &&
          isSent == other.isSent &&
          isDraft == other.isDraft &&
          isArchived == other.isArchived &&
          isTemplate == other.isTemplate &&
          sentAt == other.sentAt &&
          tags == other.tags &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
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
        Object.hashAll(recipientIds),
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
        Object.hashAll(tags),
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'CommunicationModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// TASK MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a task, mapping to `tasks` table.
class TaskModel {
  const TaskModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String category;
  final String? relatedResourceType;
  final String? relatedResourceId;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isReminderSent;
  final bool isRecurring;
  final String? recurrenceRule;
  final List<Map<String, dynamic>> subtasks;
  final DateTime? completedAt;
  final String? completionNotes;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? json['status'] as String? ?? 'pending',
      category: json['category'] as String? ?? json['category'] as String? ?? 'general',
      relatedResourceType: json['related_resource_type'] as String? ??
          json['relatedResourceType'] as String?,
      relatedResourceId: json['related_resource_id'] as String? ??
          json['relatedResourceId'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : null,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : json['reminderAt'] != null
              ? DateTime.parse(json['reminderAt'] as String)
              : null,
      isReminderSent: json['is_reminder_sent'] as bool? ??
          json['isReminderSent'] as bool? ??
          false,
      isRecurring: json['is_recurring'] as bool? ??
          json['isRecurring'] as bool? ??
          false,
      recurrenceRule: json['recurrence_rule'] as String? ??
          json['recurrenceRule'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      completionNotes: json['completion_notes'] as String? ??
          json['completionNotes'] as String?,
      assignedTo: json['assigned_to'] as String? ??
          json['assignedTo'] as String?,
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
      'priority': priority,
      'status': status,
      'category': category,
      'related_resource_type': relatedResourceType,
      'related_resource_id': relatedResourceId,
      'due_date': dueDate?.toIso8601String(),
      'reminder_at': reminderAt?.toIso8601String(),
      'is_reminder_sent': isReminderSent,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'subtasks': subtasks,
      'completed_at': completedAt?.toIso8601String(),
      'completion_notes': completionNotes,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      title: entity.title,
      description: entity.description,
      priority: entity.priority.value,
      status: entity.status.value,
      category: entity.category.value,
      relatedResourceType: entity.relatedResourceType,
      relatedResourceId: entity.relatedResourceId,
      dueDate: entity.dueDate,
      reminderAt: entity.reminderAt,
      isReminderSent: entity.isReminderSent,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      subtasks: entity.subtasks
          .map((s) => <String, dynamic>{
                'id': s.id,
                'title': s.title,
                'is_completed': s.isCompleted,
              })
          .toList(),
      completedAt: entity.completedAt,
      completionNotes: entity.completionNotes,
      assignedTo: entity.assignedTo,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      title: title,
      description: description,
      priority: TaskPriority.fromString(priority) ?? TaskPriority.medium,
      status: TaskStatus.fromString(status) ?? TaskStatus.pending,
      category: TaskCategory.fromString(category) ?? TaskCategory.general,
      relatedResourceType: relatedResourceType,
      relatedResourceId: relatedResourceId,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isReminderSent: isReminderSent,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      subtasks: subtasks
          .map((s) => SubtaskEntity(
                id: s['id'] as String?,
                title: (s['title'] as String?) ?? '',
                isCompleted: (s['is_completed'] as bool?) ??
                    (s['isCompleted'] as bool?) ??
                    false,
              ))
          .toList(),
      completedAt: completedAt,
      completionNotes: completionNotes,
      assignedTo: assignedTo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  TaskModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? category,
    String? relatedResourceType,
    String? relatedResourceId,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? isReminderSent,
    bool? isRecurring,
    String? recurrenceRule,
    List<Map<String, dynamic>>? subtasks,
    DateTime? completedAt,
    String? completionNotes,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          title == other.title &&
          description == other.description &&
          priority == other.priority &&
          status == other.status &&
          category == other.category &&
          relatedResourceType == other.relatedResourceType &&
          relatedResourceId == other.relatedResourceId &&
          dueDate == other.dueDate &&
          reminderAt == other.reminderAt &&
          isReminderSent == other.isReminderSent &&
          isRecurring == other.isRecurring &&
          recurrenceRule == other.recurrenceRule &&
          subtasks == other.subtasks &&
          completedAt == other.completedAt &&
          completionNotes == other.completionNotes &&
          assignedTo == other.assignedTo &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
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
        Object.hashAll(subtasks),
        completedAt,
        completionNotes,
        assignedTo,
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// RUBRIC MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a rubric, mapping to `rubrics` table.
class RubricModel {
  const RubricModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final List<Map<String, dynamic>> criteria;
  final double totalPoints;
  final String? topic;
  final bool isAiGenerated;
  final String? aiModel;
  final bool isPublished;
  final bool isTemplate;
  final bool isArchived;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory RubricModel.fromJson(Map<String, dynamic> json) {
    return RubricModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      totalPoints: (json['total_points'] as num?)?.toDouble() ??
          (json['totalPoints'] as num?)?.toDouble() ??
          0.0,
      topic: json['topic'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isTemplate: json['is_template'] as bool? ??
          json['isTemplate'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'criteria': criteria,
      'total_points': totalPoints,
      'topic': topic,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'is_published': isPublished,
      'is_template': isTemplate,
      'is_archived': isArchived,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory RubricModel.fromEntity(RubricEntity entity) {
    return RubricModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      criteria: entity.criteria
          .map((c) => <String, dynamic>{
                'criterion': c.criterion,
                'weight': c.weight,
                'levels': c.levels
                    .map((l) => <String, dynamic>{
                          'level': l.level.value,
                          'description': l.description,
                          'score': l.score,
                        })
                    .toList(),
              })
          .toList(),
      totalPoints: entity.totalPoints,
      topic: entity.topic,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      isPublished: entity.isPublished,
      isTemplate: entity.isTemplate,
      isArchived: entity.isArchived,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RubricEntity toEntity() {
    return RubricEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      criteria: criteria
          .map((c) => RubricCriterionEntity(
                criterion: (c['criterion'] as String?) ?? '',
                weight: (c['weight'] as num?)?.toDouble() ?? 0.0,
                levels: ((c['levels'] as List<dynamic>?) ?? [])
                    .map((l) => RubricLevelEntity(
                          level: RubricCriterionLevel.fromString(
                                  l['level'] as String?) ??
                              RubricCriterionLevel.beginning,
                          description: (l['description'] as String?) ?? '',
                          score: (l['score'] as num?)?.toDouble() ?? 0.0,
                        ))
                    .toList(),
              ))
          .toList(),
      totalPoints: totalPoints,
      topic: topic,
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      isPublished: isPublished,
      isTemplate: isTemplate,
      isArchived: isArchived,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  RubricModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    List<Map<String, dynamic>>? criteria,
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
    return RubricModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RubricModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          criteria == other.criteria &&
          totalPoints == other.totalPoints &&
          topic == other.topic &&
          isAiGenerated == other.isAiGenerated &&
          aiModel == other.aiModel &&
          isPublished == other.isPublished &&
          isTemplate == other.isTemplate &&
          isArchived == other.isArchived &&
          tags == other.tags &&
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
        Object.hashAll(criteria),
        totalPoints,
        topic,
        isAiGenerated,
        aiModel,
        isPublished,
        isTemplate,
        isArchived,
        Object.hashAll(tags),
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'RubricModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of an oral question set, mapping to `oral_questions` table.
class OralQuestionModel {
  const OralQuestionModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final List<Map<String, dynamic>> questions;
  final double totalMarks;
  final int? estimatedDurationMinutes;
  final String? topic;
  final String? curriculum;
  final String? difficulty;
  final bool isAiGenerated;
  final String? aiModel;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory OralQuestionModel.fromJson(Map<String, dynamic> json) {
    return OralQuestionModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ??
          json['estimatedDurationMinutes'] as int?,
      topic: json['topic'] as String?,
      curriculum: json['curriculum'] as String?,
      difficulty: json['difficulty'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'questions': questions,
      'total_marks': totalMarks,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'topic': topic,
      'curriculum': curriculum,
      'difficulty': difficulty,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory OralQuestionModel.fromEntity(OralQuestionEntity entity) {
    return OralQuestionModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      questions: entity.questions
          .map((q) => <String, dynamic>{
                'question': q.question,
                'expected_answer': q.expectedAnswer,
                'marks': q.marks,
                'difficulty': q.difficulty,
                'bloom_level': q.bloomLevel,
              })
          .toList(),
      totalMarks: entity.totalMarks,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      topic: entity.topic,
      curriculum: entity.curriculum?.value,
      difficulty: entity.difficulty?.value,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  OralQuestionEntity toEntity() {
    return OralQuestionEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      questions: questions
          .map((q) => OralQuestionItemEntity(
                question: (q['question'] as String?) ?? '',
                expectedAnswer: q['expected_answer'] as String? ??
                    q['expectedAnswer'] as String?,
                marks: (q['marks'] as num?)?.toDouble() ?? 0.0,
                difficulty: q['difficulty'] as String?,
                bloomLevel: q['bloom_level'] as String? ??
                    q['bloomLevel'] as String?,
              ))
          .toList(),
      totalMarks: totalMarks,
      estimatedDurationMinutes: estimatedDurationMinutes,
      topic: topic,
      curriculum: CurriculumType.fromString(curriculum),
      difficulty: StudentLevel.fromString(difficulty),
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  OralQuestionModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? subjectId,
    String? classId,
    String? title,
    String? description,
    List<Map<String, dynamic>>? questions,
    double? totalMarks,
    int? estimatedDurationMinutes,
    String? topic,
    String? curriculum,
    String? difficulty,
    bool? isAiGenerated,
    String? aiModel,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OralQuestionModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OralQuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          questions == other.questions &&
          totalMarks == other.totalMarks &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          topic == other.topic &&
          curriculum == other.curriculum &&
          difficulty == other.difficulty &&
          isAiGenerated == other.isAiGenerated &&
          aiModel == other.aiModel &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
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
        Object.hashAll(questions),
        totalMarks,
        estimatedDurationMinutes,
        topic,
        curriculum,
        difficulty,
        isAiGenerated,
        aiModel,
        isPublished,
        isArchived,
        Object.hashAll(tags),
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'OralQuestionModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// PRACTICAL ASSESSMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a practical assessment, mapping to `practical_assessments` table.
class PracticalAssessmentModel {
  const PracticalAssessmentModel({
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

  final String id;
  final String? schoolId;
  final String teacherId;
  final String? subjectId;
  final String? classId;
  final String title;
  final String? description;
  final List<String> objectives;
  final List<String> materialsNeeded;
  final List<String> procedureSteps;
  final List<String> safetyPrecautions;
  final String? expectedResults;
  final List<Map<String, dynamic>> assessmentCriteria;
  final double totalMarks;
  final int? estimatedDurationMinutes;
  final String? topic;
  final String? curriculum;
  final String? difficulty;
  final bool isAiGenerated;
  final String? aiModel;
  final String? rubricId;
  final bool isPublished;
  final bool isArchived;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory PracticalAssessmentModel.fromJson(Map<String, dynamic> json) {
    return PracticalAssessmentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      teacherId: json['teacher_id'] as String? ?? json['teacherId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      objectives: (json['objectives'] as List<dynamic>?)?.cast<String>() ??
          const [],
      materialsNeeded:
          (json['materials_needed'] as List<dynamic>?)?.cast<String>() ??
              (json['materialsNeeded'] as List<dynamic>?)?.cast<String>() ??
              const [],
      procedureSteps:
          (json['procedure_steps'] as List<dynamic>?)?.cast<String>() ??
              (json['procedureSteps'] as List<dynamic>?)?.cast<String>() ??
              const [],
      safetyPrecautions:
          (json['safety_precautions'] as List<dynamic>?)?.cast<String>() ??
              (json['safetyPrecautions'] as List<dynamic>?)?.cast<String>() ??
              const [],
      expectedResults: json['expected_results'] as String? ??
          json['expectedResults'] as String?,
      assessmentCriteria: (json['assessment_criteria'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['assessmentCriteria'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      totalMarks: (json['total_marks'] as num?)?.toDouble() ??
          (json['totalMarks'] as num?)?.toDouble() ??
          0.0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ??
          json['estimatedDurationMinutes'] as int?,
      topic: json['topic'] as String?,
      curriculum: json['curriculum'] as String?,
      difficulty: json['difficulty'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      rubricId: json['rubric_id'] as String? ?? json['rubricId'] as String?,
      isPublished: json['is_published'] as bool? ??
          json['isPublished'] as bool? ??
          false,
      isArchived: json['is_archived'] as bool? ??
          json['isArchived'] as bool? ??
          false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
      'objectives': objectives,
      'materials_needed': materialsNeeded,
      'procedure_steps': procedureSteps,
      'safety_precautions': safetyPrecautions,
      'expected_results': expectedResults,
      'assessment_criteria': assessmentCriteria,
      'total_marks': totalMarks,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'topic': topic,
      'curriculum': curriculum,
      'difficulty': difficulty,
      'is_ai_generated': isAiGenerated,
      'ai_model': aiModel,
      'rubric_id': rubricId,
      'is_published': isPublished,
      'is_archived': isArchived,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory PracticalAssessmentModel.fromEntity(PracticalAssessmentEntity entity) {
    return PracticalAssessmentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      teacherId: entity.teacherId,
      subjectId: entity.subjectId,
      classId: entity.classId,
      title: entity.title,
      description: entity.description,
      objectives: entity.objectives,
      materialsNeeded: entity.materialsNeeded,
      procedureSteps: entity.procedureSteps,
      safetyPrecautions: entity.safetyPrecautions,
      expectedResults: entity.expectedResults,
      assessmentCriteria: entity.assessmentCriteria,
      totalMarks: entity.totalMarks,
      estimatedDurationMinutes: entity.estimatedDurationMinutes,
      topic: entity.topic,
      curriculum: entity.curriculum?.value,
      difficulty: entity.difficulty?.value,
      isAiGenerated: entity.isAiGenerated,
      aiModel: entity.aiModel,
      rubricId: entity.rubricId,
      isPublished: entity.isPublished,
      isArchived: entity.isArchived,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PracticalAssessmentEntity toEntity() {
    return PracticalAssessmentEntity(
      id: id,
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
      title: title,
      description: description,
      objectives: objectives,
      materialsNeeded: materialsNeeded,
      procedureSteps: procedureSteps,
      safetyPrecautions: safetyPrecautions,
      expectedResults: expectedResults,
      assessmentCriteria: assessmentCriteria,
      totalMarks: totalMarks,
      estimatedDurationMinutes: estimatedDurationMinutes,
      topic: topic,
      curriculum: CurriculumType.fromString(curriculum),
      difficulty: StudentLevel.fromString(difficulty),
      isAiGenerated: isAiGenerated,
      aiModel: aiModel,
      rubricId: rubricId,
      isPublished: isPublished,
      isArchived: isArchived,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  PracticalAssessmentModel copyWith({
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
    String? curriculum,
    String? difficulty,
    bool? isAiGenerated,
    String? aiModel,
    String? rubricId,
    bool? isPublished,
    bool? isArchived,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticalAssessmentModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticalAssessmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          teacherId == other.teacherId &&
          subjectId == other.subjectId &&
          classId == other.classId &&
          title == other.title &&
          description == other.description &&
          objectives == other.objectives &&
          materialsNeeded == other.materialsNeeded &&
          procedureSteps == other.procedureSteps &&
          safetyPrecautions == other.safetyPrecautions &&
          expectedResults == other.expectedResults &&
          assessmentCriteria == other.assessmentCriteria &&
          totalMarks == other.totalMarks &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          topic == other.topic &&
          curriculum == other.curriculum &&
          difficulty == other.difficulty &&
          isAiGenerated == other.isAiGenerated &&
          aiModel == other.aiModel &&
          rubricId == other.rubricId &&
          isPublished == other.isPublished &&
          isArchived == other.isArchived &&
          tags == other.tags &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        schoolId,
        teacherId,
        subjectId,
        classId,
        title,
        description,
        Object.hashAll(objectives),
        Object.hashAll(materialsNeeded),
        Object.hashAll(procedureSteps),
        Object.hashAll(safetyPrecautions),
        expectedResults,
        Object.hashAll(assessmentCriteria),
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
        Object.hashAll(tags),
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'PracticalAssessmentModel(id: $id, title: $title, teacherId: $teacherId)';
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED RESOURCE MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a shared resource, mapping to `shared_resources` table.
class SharedResourceModel {
  const SharedResourceModel({
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

  final String id;
  final String schoolId;
  final String resourceType;
  final String resourceId;
  final String sharedBy;
  final String sharedWith;
  final bool canEdit;
  final bool canView;
  final bool canComment;
  final bool canDownload;
  final String? message;
  final bool? isAccepted;
  final DateTime createdAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory SharedResourceModel.fromJson(Map<String, dynamic> json) {
    return SharedResourceModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      resourceType: json['resource_type'] as String? ??
          json['resourceType'] as String? ??
          '',
      resourceId: json['resource_id'] as String? ??
          json['resourceId'] as String? ??
          '',
      sharedBy: json['shared_by'] as String? ?? json['sharedBy'] as String? ?? '',
      sharedWith: json['shared_with'] as String? ??
          json['sharedWith'] as String? ??
          '',
      canEdit: json['can_edit'] as bool? ?? json['canEdit'] as bool? ?? false,
      canView: json['can_view'] as bool? ?? json['canView'] as bool? ?? true,
      canComment: json['can_comment'] as bool? ??
          json['canComment'] as bool? ??
          false,
      canDownload: json['can_download'] as bool? ??
          json['canDownload'] as bool? ??
          true,
      message: json['message'] as String?,
      isAccepted: json['is_accepted'] as bool? ??
          json['isAccepted'] as bool?,
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
      'resource_type': resourceType,
      'resource_id': resourceId,
      'shared_by': sharedBy,
      'shared_with': sharedWith,
      'can_edit': canEdit,
      'can_view': canView,
      'can_comment': canComment,
      'can_download': canDownload,
      'message': message,
      'is_accepted': isAccepted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory SharedResourceModel.fromEntity(SharedResourceEntity entity) {
    return SharedResourceModel(
      id: entity.id,
      schoolId: entity.schoolId,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      sharedBy: entity.sharedBy,
      sharedWith: entity.sharedWith,
      canEdit: entity.canEdit,
      canView: entity.canView,
      canComment: entity.canComment,
      canDownload: entity.canDownload,
      message: entity.message,
      isAccepted: entity.isAccepted,
      createdAt: entity.createdAt,
    );
  }

  SharedResourceEntity toEntity() {
    return SharedResourceEntity(
      id: id,
      schoolId: schoolId,
      resourceType: resourceType,
      resourceId: resourceId,
      sharedBy: sharedBy,
      sharedWith: sharedWith,
      canEdit: canEdit,
      canView: canView,
      canComment: canComment,
      canDownload: canDownload,
      message: message,
      isAccepted: isAccepted,
      createdAt: createdAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  SharedResourceModel copyWith({
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
    return SharedResourceModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedResourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          resourceType == other.resourceType &&
          resourceId == other.resourceId &&
          sharedBy == other.sharedBy &&
          sharedWith == other.sharedWith &&
          canEdit == other.canEdit &&
          canView == other.canView &&
          canComment == other.canComment &&
          canDownload == other.canDownload &&
          message == other.message &&
          isAccepted == other.isAccepted &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
      );

  @override
  String toString() =>
      'SharedResourceModel(id: $id, resourceType: $resourceType, resourceId: $resourceId)';
}

// ═══════════════════════════════════════════════════════════════════════
// COLLABORATION COMMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a collaboration comment, mapping to `collaboration_comments` table.
class CollaborationCommentModel {
  const CollaborationCommentModel({
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

  final String id;
  final String schoolId;
  final String resourceType;
  final String resourceId;
  final String content;
  final String authorId;
  final String? parentCommentId;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory CollaborationCommentModel.fromJson(Map<String, dynamic> json) {
    return CollaborationCommentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      resourceType: json['resource_type'] as String? ??
          json['resourceType'] as String? ??
          '',
      resourceId: json['resource_id'] as String? ??
          json['resourceId'] as String? ??
          '',
      content: json['content'] as String,
      authorId: json['author_id'] as String? ?? json['authorId'] as String? ?? '',
      parentCommentId: json['parent_comment_id'] as String? ??
          json['parentCommentId'] as String?,
      isResolved: json['is_resolved'] as bool? ??
          json['isResolved'] as bool? ??
          false,
      resolvedBy: json['resolved_by'] as String? ??
          json['resolvedBy'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : null,
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
      'resource_type': resourceType,
      'resource_id': resourceId,
      'content': content,
      'author_id': authorId,
      'parent_comment_id': parentCommentId,
      'is_resolved': isResolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory CollaborationCommentModel.fromEntity(CollaborationCommentEntity entity) {
    return CollaborationCommentModel(
      id: entity.id,
      schoolId: entity.schoolId,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      content: entity.content,
      authorId: entity.authorId,
      parentCommentId: entity.parentCommentId,
      isResolved: entity.isResolved,
      resolvedBy: entity.resolvedBy,
      resolvedAt: entity.resolvedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CollaborationCommentEntity toEntity() {
    return CollaborationCommentEntity(
      id: id,
      schoolId: schoolId,
      resourceType: resourceType,
      resourceId: resourceId,
      content: content,
      authorId: authorId,
      parentCommentId: parentCommentId,
      isResolved: isResolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  CollaborationCommentModel copyWith({
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
    return CollaborationCommentModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationCommentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          resourceType == other.resourceType &&
          resourceId == other.resourceId &&
          content == other.content &&
          authorId == other.authorId &&
          parentCommentId == other.parentCommentId &&
          isResolved == other.isResolved &&
          resolvedBy == other.resolvedBy &&
          resolvedAt == other.resolvedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );

  @override
  String toString() =>
      'CollaborationCommentModel(id: $id, resourceType: $resourceType, resourceId: $resourceId)';
}

// ═══════════════════════════════════════════════════════════════════════
// ENHANCED DASHBOARD MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of the enhanced workspace dashboard.
class EnhancedDashboardModel {
  const EnhancedDashboardModel({
    this.stats = const {},
    this.todayClasses = const [],
    this.pendingAssignments = const [],
    this.recentDocuments = const [],
    this.savedTemplates = const [],
    this.upcomingEvents = const [],
    this.teachingStatistics = const {},
    this.notificationsCount = 0,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> todayClasses;
  final List<Map<String, dynamic>> pendingAssignments;
  final List<Map<String, dynamic>> recentDocuments;
  final List<Map<String, dynamic>> savedTemplates;
  final List<Map<String, dynamic>> upcomingEvents;
  final Map<String, dynamic> teachingStatistics;
  final int notificationsCount;

  // ─── JSON Serialization ────────────────────────────────────────────

  factory EnhancedDashboardModel.fromJson(Map<String, dynamic> json) {
    return EnhancedDashboardModel(
      stats: json['stats'] as Map<String, dynamic>? ?? const {},
      todayClasses: (json['today_classes'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['todayClasses'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      pendingAssignments: (json['pending_assignments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['pendingAssignments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      recentDocuments: (json['recent_documents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['recentDocuments'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      savedTemplates: (json['saved_templates'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['savedTemplates'] as List<dynamic>?)
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
      teachingStatistics:
          json['teaching_statistics'] as Map<String, dynamic>? ??
              json['teachingStatistics'] as Map<String, dynamic>? ??
              const {},
      notificationsCount: json['notifications_count'] as int? ??
          json['notificationsCount'] as int? ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stats': stats,
      'today_classes': todayClasses,
      'pending_assignments': pendingAssignments,
      'recent_documents': recentDocuments,
      'saved_templates': savedTemplates,
      'upcoming_events': upcomingEvents,
      'teaching_statistics': teachingStatistics,
      'notifications_count': notificationsCount,
    };
  }

  // ─── Entity Conversion ─────────────────────────────────────────────

  factory EnhancedDashboardModel.fromEntity(EnhancedWorkspaceDashboardEntity entity) {
    return EnhancedDashboardModel(
      stats: <String, dynamic>{
        'lesson_plans': entity.stats.lessonPlans,
        'worksheets': entity.stats.worksheets,
        'assignments': entity.stats.assignments,
        'presentations': entity.stats.presentations,
        'rubrics': entity.stats.rubrics,
        'resources': entity.stats.resources,
        'ai_generations': entity.stats.aiGenerations,
        'pending_tasks': entity.stats.pendingTasks,
        'overdue_tasks': entity.stats.overdueTasks,
        'shared_with_me': entity.stats.sharedWithMe,
      },
      todayClasses: entity.todayClasses
          .map((e) => <String, dynamic>{
                'id': e.id,
                'title': e.title,
                'start_time': e.startTime.toIso8601String(),
                'end_time': e.endTime.toIso8601String(),
                'event_type': e.eventType,
              })
          .toList(),
      pendingAssignments: entity.pendingAssignments
          .map((e) => <String, dynamic>{
                'id': e.id,
                'title': e.title,
                'deadline': e.deadline?.toIso8601String(),
                'status': e.status,
              })
          .toList(),
      recentDocuments: entity.recentDocuments
          .map((e) => <String, dynamic>{
                'id': e.id,
                'title': e.title,
                'type': e.type,
                'updated_at': e.updatedAt.toIso8601String(),
              })
          .toList(),
      savedTemplates: entity.savedTemplates
          .map((e) => <String, dynamic>{
                'id': e.id,
                'name': e.name,
                'template_type': e.templateType,
                'usage_count': e.usageCount,
              })
          .toList(),
      upcomingEvents: entity.upcomingEvents
          .map((e) => <String, dynamic>{
                'id': e.id,
                'title': e.title,
                'start_time': e.startTime.toIso8601String(),
                'end_time': e.endTime.toIso8601String(),
                'event_type': e.eventType,
              })
          .toList(),
      teachingStatistics: <String, dynamic>{
        'total_students': entity.teachingStatistics.totalStudents,
        'classes_taught': entity.teachingStatistics.classesTaught,
        'questions_generated': entity.teachingStatistics.questionsGenerated,
        'resources_shared': entity.teachingStatistics.resourcesShared,
      },
      notificationsCount: entity.notificationsCount,
    );
  }

  EnhancedWorkspaceDashboardEntity toEntity() {
    return EnhancedWorkspaceDashboardEntity(
      stats: DashboardStatsEntity(
        lessonPlans: (stats['lesson_plans'] as int?) ??
            (stats['lessonPlans'] as int?) ??
            0,
        worksheets: (stats['worksheets'] as int?) ?? 0,
        assignments: (stats['assignments'] as int?) ?? 0,
        presentations: (stats['presentations'] as int?) ?? 0,
        rubrics: (stats['rubrics'] as int?) ?? 0,
        resources: (stats['resources'] as int?) ?? 0,
        aiGenerations: (stats['ai_generations'] as int?) ??
            (stats['aiGenerations'] as int?) ??
            0,
        pendingTasks: (stats['pending_tasks'] as int?) ??
            (stats['pendingTasks'] as int?) ??
            0,
        overdueTasks: (stats['overdue_tasks'] as int?) ??
            (stats['overdueTasks'] as int?) ??
            0,
        sharedWithMe: (stats['shared_with_me'] as int?) ??
            (stats['sharedWithMe'] as int?) ??
            0,
      ),
      todayClasses: todayClasses
          .map((e) => DashboardEventEntity(
                id: (e['id'] as String?) ?? '',
                title: (e['title'] as String?) ?? '',
                startTime: e['start_time'] != null
                    ? DateTime.parse(e['start_time'] as String)
                    : e['startTime'] != null
                        ? DateTime.parse(e['startTime'] as String)
                        : DateTime.now(),
                endTime: e['end_time'] != null
                    ? DateTime.parse(e['end_time'] as String)
                    : e['endTime'] != null
                        ? DateTime.parse(e['endTime'] as String)
                        : DateTime.now(),
                eventType: (e['event_type'] as String?) ??
                    (e['eventType'] as String?) ??
                    '',
              ))
          .toList(),
      pendingAssignments: pendingAssignments
          .map((e) => DashboardAssignmentEntity(
                id: (e['id'] as String?) ?? '',
                title: (e['title'] as String?) ?? '',
                deadline: e['deadline'] != null
                    ? DateTime.parse(e['deadline'] as String)
                    : null,
                status: (e['status'] as String?) ?? '',
              ))
          .toList(),
      recentDocuments: recentDocuments
          .map((e) => RecentDocumentEntity(
                id: (e['id'] as String?) ?? '',
                title: (e['title'] as String?) ?? '',
                type: (e['type'] as String?) ?? '',
                updatedAt: e['updated_at'] != null
                    ? DateTime.parse(e['updated_at'] as String)
                    : e['updatedAt'] != null
                        ? DateTime.parse(e['updatedAt'] as String)
                        : DateTime.now(),
              ))
          .toList(),
      savedTemplates: savedTemplates
          .map((e) => DashboardTemplateEntity(
                id: (e['id'] as String?) ?? '',
                name: (e['name'] as String?) ?? '',
                templateType: (e['template_type'] as String?) ??
                    (e['templateType'] as String?) ??
                    '',
                usageCount: (e['usage_count'] as int?) ??
                    (e['usageCount'] as int?) ??
                    0,
              ))
          .toList(),
      upcomingEvents: upcomingEvents
          .map((e) => DashboardEventEntity(
                id: (e['id'] as String?) ?? '',
                title: (e['title'] as String?) ?? '',
                startTime: e['start_time'] != null
                    ? DateTime.parse(e['start_time'] as String)
                    : e['startTime'] != null
                        ? DateTime.parse(e['startTime'] as String)
                        : DateTime.now(),
                endTime: e['end_time'] != null
                    ? DateTime.parse(e['end_time'] as String)
                    : e['endTime'] != null
                        ? DateTime.parse(e['endTime'] as String)
                        : DateTime.now(),
                eventType: (e['event_type'] as String?) ??
                    (e['eventType'] as String?) ??
                    '',
              ))
          .toList(),
      teachingStatistics: TeachingStatisticsEntity(
        totalStudents: (teachingStatistics['total_students'] as int?) ??
            (teachingStatistics['totalStudents'] as int?) ??
            0,
        classesTaught: (teachingStatistics['classes_taught'] as int?) ??
            (teachingStatistics['classesTaught'] as int?) ??
            0,
        questionsGenerated:
            (teachingStatistics['questions_generated'] as int?) ??
                (teachingStatistics['questionsGenerated'] as int?) ??
                0,
        resourcesShared: (teachingStatistics['resources_shared'] as int?) ??
            (teachingStatistics['resourcesShared'] as int?) ??
            0,
      ),
      notificationsCount: notificationsCount,
    );
  }

  // ─── Copy With ─────────────────────────────────────────────────────

  EnhancedDashboardModel copyWith({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? todayClasses,
    List<Map<String, dynamic>>? pendingAssignments,
    List<Map<String, dynamic>>? recentDocuments,
    List<Map<String, dynamic>>? savedTemplates,
    List<Map<String, dynamic>>? upcomingEvents,
    Map<String, dynamic>? teachingStatistics,
    int? notificationsCount,
  }) {
    return EnhancedDashboardModel(
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

  // ─── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedDashboardModel &&
          runtimeType == other.runtimeType &&
          stats == other.stats &&
          todayClasses == other.todayClasses &&
          pendingAssignments == other.pendingAssignments &&
          recentDocuments == other.recentDocuments &&
          savedTemplates == other.savedTemplates &&
          upcomingEvents == other.upcomingEvents &&
          teachingStatistics == other.teachingStatistics &&
          notificationsCount == other.notificationsCount;

  @override
  int get hashCode => Object.hash(
        stats,
        Object.hashAll(todayClasses),
        Object.hashAll(pendingAssignments),
        Object.hashAll(recentDocuments),
        Object.hashAll(savedTemplates),
        Object.hashAll(upcomingEvents),
        teachingStatistics,
        notificationsCount,
      );

  @override
  String toString() =>
      'EnhancedDashboardModel(notificationsCount: $notificationsCount)';
}
