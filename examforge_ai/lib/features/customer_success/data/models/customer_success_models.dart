import '../../domain/entities/customer_success_entities.dart';

// ============================================================================
// ONBOARDING FLOW MODEL
// ============================================================================

class OnboardingFlowModel {
  final String id;
  final String role;
  final int stepOrder;
  final String stepType;
  final String title;
  final String description;
  final Map<String, dynamic> content;
  final bool actionRequired;
  final bool isSkippable;
  final DateTime createdAt;

  const OnboardingFlowModel({
    required this.id,
    required this.role,
    required this.stepOrder,
    required this.stepType,
    required this.title,
    required this.description,
    required this.content,
    required this.actionRequired,
    required this.isSkippable,
    required this.createdAt,
  });

  factory OnboardingFlowModel.fromJson(Map<String, dynamic> json) {
    return OnboardingFlowModel(
      id: json['id'] as String,
      role: json['role'] as String,
      stepOrder: json['step_order'] as int,
      stepType: json['step_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: Map<String, dynamic>.from(json['content'] as Map? ?? {}),
      actionRequired: json['action_required'] as bool? ?? false,
      isSkippable: json['is_skippable'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'step_order': stepOrder,
    'step_type': stepType,
    'title': title,
    'description': description,
    'content': content,
    'action_required': actionRequired,
    'is_skippable': isSkippable,
    'created_at': createdAt.toIso8601String(),
  };

  OnboardingFlow toEntity() => OnboardingFlow(
    id: id,
    role: role,
    stepOrder: stepOrder,
    stepType: OnboardingStepType.fromString(stepType),
    title: title,
    description: description,
    content: content,
    actionRequired: actionRequired,
    isSkippable: isSkippable,
    createdAt: createdAt,
  );
}

// ============================================================================
// ONBOARDING PROGRESS MODEL
// ============================================================================

class OnboardingProgressModel {
  final String id;
  final String userId;
  final String onboardingFlowId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnboardingProgressModel({
    required this.id,
    required this.userId,
    required this.onboardingFlowId,
    required this.isCompleted,
    this.completedAt,
    this.skippedAt,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnboardingProgressModel.fromJson(Map<String, dynamic> json) {
    return OnboardingProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      onboardingFlowId: json['onboarding_flow_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      skippedAt: json['skipped_at'] != null ? DateTime.parse(json['skipped_at'] as String) : null,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'onboarding_flow_id': onboardingFlowId,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
    'skipped_at': skippedAt?.toIso8601String(),
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  OnboardingProgress toEntity() => OnboardingProgress(
    id: id,
    userId: userId,
    onboardingFlowId: onboardingFlowId,
    isCompleted: isCompleted,
    completedAt: completedAt,
    skippedAt: skippedAt,
    data: data,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ============================================================================
// PRODUCT TOUR MODEL
// ============================================================================

class ProductTourModel {
  final String id;
  final String name;
  final String description;
  final String targetRole;
  final List<Map<String, dynamic>> steps;
  final bool isActive;
  final String triggerEvent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductTourModel({
    required this.id,
    required this.name,
    required this.description,
    required this.targetRole,
    required this.steps,
    required this.isActive,
    required this.triggerEvent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductTourModel.fromJson(Map<String, dynamic> json) {
    return ProductTourModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      targetRole: json['target_role'] as String,
      steps: (json['steps'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      triggerEvent: json['trigger_event'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'target_role': targetRole,
    'steps': steps,
    'is_active': isActive,
    'trigger_event': triggerEvent,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  ProductTour toEntity() => ProductTour(
    id: id,
    name: name,
    description: description,
    targetRole: targetRole,
    steps: steps,
    isActive: isActive,
    triggerEvent: triggerEvent,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ============================================================================
// HELP ARTICLE MODEL
// ============================================================================

class HelpArticleModel {
  final String id;
  final String category;
  final String title;
  final String slug;
  final String content;
  final Map<String, dynamic> contentRich;
  final List<String> tags;
  final int viewsCount;
  final int helpfulCount;
  final bool isPublished;
  final int sortOrder;
  final String authorId;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HelpArticleModel({
    required this.id,
    required this.category,
    required this.title,
    required this.slug,
    required this.content,
    required this.contentRich,
    required this.tags,
    required this.viewsCount,
    required this.helpfulCount,
    required this.isPublished,
    required this.sortOrder,
    required this.authorId,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpArticleModel.fromJson(Map<String, dynamic> json) {
    return HelpArticleModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      content: json['content'] as String,
      contentRich: Map<String, dynamic>.from(json['content_rich'] as Map? ?? {}),
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      viewsCount: json['views_count'] as int? ?? 0,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      authorId: json['author_id'] as String,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'slug': slug,
    'content': content,
    'content_rich': contentRich,
    'tags': tags,
    'views_count': viewsCount,
    'helpful_count': helpfulCount,
    'is_published': isPublished,
    'sort_order': sortOrder,
    'author_id': authorId,
    'published_at': publishedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  HelpArticle toEntity() => HelpArticle(
    id: id,
    category: category,
    title: title,
    slug: slug,
    content: content,
    contentRich: contentRich,
    tags: tags,
    viewsCount: viewsCount,
    helpfulCount: helpfulCount,
    isPublished: isPublished,
    sortOrder: sortOrder,
    authorId: authorId,
    publishedAt: publishedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ============================================================================
// VIDEO TUTORIAL MODEL
// ============================================================================

class VideoTutorialModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final String category;
  final List<String> targetRoles;
  final int viewsCount;
  final bool isPublished;
  final int sortOrder;
  final String createdBy;
  final DateTime createdAt;

  const VideoTutorialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.category,
    required this.targetRoles,
    required this.viewsCount,
    required this.isPublished,
    required this.sortOrder,
    required this.createdBy,
    required this.createdAt,
  });

  factory VideoTutorialModel.fromJson(Map<String, dynamic> json) {
    return VideoTutorialModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      category: json['category'] as String,
      targetRoles: (json['target_roles'] as List?)?.map((e) => e as String).toList() ?? [],
      viewsCount: json['views_count'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'video_url': videoUrl,
    'thumbnail_url': thumbnailUrl,
    'duration_seconds': durationSeconds,
    'category': category,
    'target_roles': targetRoles,
    'views_count': viewsCount,
    'is_published': isPublished,
    'sort_order': sortOrder,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };

  VideoTutorial toEntity() => VideoTutorial(
    id: id,
    title: title,
    description: description,
    videoUrl: videoUrl,
    thumbnailUrl: thumbnailUrl,
    durationSeconds: durationSeconds,
    category: category,
    targetRoles: targetRoles,
    viewsCount: viewsCount,
    isPublished: isPublished,
    sortOrder: sortOrder,
    createdBy: createdBy,
    createdAt: createdAt,
  );
}

// ============================================================================
// FEEDBACK SUBMISSION MODEL
// ============================================================================

class FeedbackSubmissionModel {
  final String id;
  final String userId;
  final String feedbackType;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final List<String> attachments;
  final String? resolution;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeedbackSubmissionModel({
    required this.id,
    required this.userId,
    required this.feedbackType,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.attachments,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackSubmissionModel.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmissionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      feedbackType: json['feedback_type'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      attachments: (json['attachments'] as List?)?.map((e) => e as String).toList() ?? [],
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'feedback_type': feedbackType,
    'subject': subject,
    'description': description,
    'priority': priority,
    'status': status,
    'attachments': attachments,
    'resolution': resolution,
    'resolved_by': resolvedBy,
    'resolved_at': resolvedAt?.toIso8601String(),
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  FeedbackSubmission toEntity() => FeedbackSubmission(
    id: id,
    userId: userId,
    feedbackType: FeedbackType.fromString(feedbackType),
    subject: subject,
    description: description,
    priority: priority,
    status: status,
    attachments: attachments,
    resolution: resolution,
    resolvedBy: resolvedBy,
    resolvedAt: resolvedAt,
    metadata: metadata,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ============================================================================
// FEATURE REQUEST MODEL
// ============================================================================

class FeatureRequestModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final int upvotes;
  final bool isUnderConsideration;
  final String implementationStatus;
  final String? response;
  final String? respondedBy;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeatureRequestModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.upvotes,
    required this.isUnderConsideration,
    required this.implementationStatus,
    this.response,
    this.respondedBy,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeatureRequestModel.fromJson(Map<String, dynamic> json) {
    return FeatureRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String? ?? 'open',
      upvotes: json['upvotes'] as int? ?? 0,
      isUnderConsideration: json['is_under_consideration'] as bool? ?? false,
      implementationStatus: json['implementation_status'] as String? ?? 'not_started',
      response: json['response'] as String?,
      respondedBy: json['responded_by'] as String?,
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'category': category,
    'status': status,
    'upvotes': upvotes,
    'is_under_consideration': isUnderConsideration,
    'implementation_status': implementationStatus,
    'response': response,
    'responded_by': respondedBy,
    'responded_at': respondedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  FeatureRequest toEntity() => FeatureRequest(
    id: id,
    userId: userId,
    title: title,
    description: description,
    category: category,
    status: status,
    upvotes: upvotes,
    isUnderConsideration: isUnderConsideration,
    implementationStatus: implementationStatus,
    response: response,
    respondedBy: respondedBy,
    respondedAt: respondedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
