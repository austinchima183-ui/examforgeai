import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum OnboardingStepType {
  welcome(value: 'welcome', label: 'Welcome'),
  roleSelection(value: 'role_selection', label: 'Role Selection'),
  schoolSetup(value: 'school_setup', label: 'School Setup'),
  subjectConfig(value: 'subject_config', label: 'Subject Configuration'),
  featureTour(value: 'feature_tour', label: 'Feature Tour'),
  firstContent(value: 'first_content', label: 'First Content'),
  complete(value: 'complete', label: 'Complete');

  const OnboardingStepType({required this.value, required this.label});
  final String value;
  final String label;

  static OnboardingStepType fromString(String value) {
    return OnboardingStepType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OnboardingStepType.welcome,
    );
  }
}

enum TutorialType {
  video(value: 'video', label: 'Video'),
  article(value: 'article', label: 'Article'),
  interactive(value: 'interactive', label: 'Interactive'),
  walkthrough(value: 'walkthrough', label: 'Walkthrough');

  const TutorialType({required this.value, required this.label});
  final String value;
  final String label;

  static TutorialType fromString(String value) {
    return TutorialType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TutorialType.video,
    );
  }
}

enum FeedbackType {
  bugReport(value: 'bug_report', label: 'Bug Report'),
  featureRequest(value: 'feature_request', label: 'Feature Request'),
  generalFeedback(value: 'general_feedback', label: 'General Feedback'),
  complaint(value: 'complaint', label: 'Complaint'),
  praise(value: 'praise', label: 'Praise');

  const FeedbackType({required this.value, required this.label});
  final String value;
  final String label;

  static FeedbackType fromString(String value) {
    return FeedbackType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FeedbackType.generalFeedback,
    );
  }
}

// ============================================================================
// ENTITIES
// ============================================================================

class OnboardingFlow extends Equatable {
  final String id;
  final String role;
  final int stepOrder;
  final OnboardingStepType stepType;
  final String title;
  final String description;
  final Map<String, dynamic> content;
  final bool actionRequired;
  final bool isSkippable;
  final DateTime createdAt;

  const OnboardingFlow({
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

  @override
  List<Object?> get props => [id, role, stepOrder, stepType, title, description, content, actionRequired, isSkippable, createdAt];

  OnboardingFlow copyWith({
    String? id,
    String? role,
    int? stepOrder,
    OnboardingStepType? stepType,
    String? title,
    String? description,
    Map<String, dynamic>? content,
    bool? actionRequired,
    bool? isSkippable,
    DateTime? createdAt,
  }) {
    return OnboardingFlow(
      id: id ?? this.id,
      role: role ?? this.role,
      stepOrder: stepOrder ?? this.stepOrder,
      stepType: stepType ?? this.stepType,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      actionRequired: actionRequired ?? this.actionRequired,
      isSkippable: isSkippable ?? this.isSkippable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OnboardingProgress extends Equatable {
  final String id;
  final String userId;
  final String onboardingFlowId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? skippedAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnboardingProgress({
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

  @override
  List<Object?> get props => [id, userId, onboardingFlowId, isCompleted, completedAt, skippedAt, data, createdAt, updatedAt];

  OnboardingProgress copyWith({
    String? id,
    String? userId,
    String? onboardingFlowId,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? skippedAt,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OnboardingProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      onboardingFlowId: onboardingFlowId ?? this.onboardingFlowId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductTour extends Equatable {
  final String id;
  final String name;
  final String description;
  final String targetRole;
  final List<Map<String, dynamic>> steps;
  final bool isActive;
  final String triggerEvent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductTour({
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

  @override
  List<Object?> get props => [id, name, description, targetRole, steps, isActive, triggerEvent, createdAt, updatedAt];

  ProductTour copyWith({
    String? id,
    String? name,
    String? description,
    String? targetRole,
    List<Map<String, dynamic>>? steps,
    bool? isActive,
    String? triggerEvent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductTour(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetRole: targetRole ?? this.targetRole,
      steps: steps ?? this.steps,
      isActive: isActive ?? this.isActive,
      triggerEvent: triggerEvent ?? this.triggerEvent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HelpArticle extends Equatable {
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

  const HelpArticle({
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

  @override
  List<Object?> get props => [id, category, title, slug, content, contentRich, tags, viewsCount, helpfulCount, isPublished, sortOrder, authorId, publishedAt, createdAt, updatedAt];

  HelpArticle copyWith({
    String? id,
    String? category,
    String? title,
    String? slug,
    String? content,
    Map<String, dynamic>? contentRich,
    List<String>? tags,
    int? viewsCount,
    int? helpfulCount,
    bool? isPublished,
    int? sortOrder,
    String? authorId,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HelpArticle(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      contentRich: contentRich ?? this.contentRich,
      tags: tags ?? this.tags,
      viewsCount: viewsCount ?? this.viewsCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      authorId: authorId ?? this.authorId,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VideoTutorial extends Equatable {
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

  const VideoTutorial({
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

  @override
  List<Object?> get props => [id, title, description, videoUrl, thumbnailUrl, durationSeconds, category, targetRoles, viewsCount, isPublished, sortOrder, createdBy, createdAt];

  VideoTutorial copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? category,
    List<String>? targetRoles,
    int? viewsCount,
    bool? isPublished,
    int? sortOrder,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return VideoTutorial(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      category: category ?? this.category,
      targetRoles: targetRoles ?? this.targetRoles,
      viewsCount: viewsCount ?? this.viewsCount,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FeedbackSubmission extends Equatable {
  final String id;
  final String userId;
  final FeedbackType feedbackType;
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

  const FeedbackSubmission({
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

  @override
  List<Object?> get props => [id, userId, feedbackType, subject, description, priority, status, attachments, resolution, resolvedBy, resolvedAt, metadata, createdAt, updatedAt];

  FeedbackSubmission copyWith({
    String? id,
    String? userId,
    FeedbackType? feedbackType,
    String? subject,
    String? description,
    String? priority,
    String? status,
    List<String>? attachments,
    String? resolution,
    String? resolvedBy,
    DateTime? resolvedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedbackSubmission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      feedbackType: feedbackType ?? this.feedbackType,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FeatureRequest extends Equatable {
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

  const FeatureRequest({
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

  @override
  List<Object?> get props => [id, userId, title, description, category, status, upvotes, isUnderConsideration, implementationStatus, response, respondedBy, respondedAt, createdAt, updatedAt];

  FeatureRequest copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? status,
    int? upvotes,
    bool? isUnderConsideration,
    String? implementationStatus,
    String? response,
    String? respondedBy,
    DateTime? respondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      isUnderConsideration: isUnderConsideration ?? this.isUnderConsideration,
      implementationStatus: implementationStatus ?? this.implementationStatus,
      response: response ?? this.response,
      respondedBy: respondedBy ?? this.respondedBy,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
