import '../../domain/entities/ai_coach_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI COACH SESSION MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiCoachSessionModel {
  final String id;
  final String userId;
  final String sessionType;
  final String? context;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> recommendations;
  final String? studyPlanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiCoachSessionModel({
    required this.id,
    required this.userId,
    required this.sessionType,
    this.context,
    this.messages = const [],
    this.recommendations = const [],
    this.studyPlanId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiCoachSessionModel.fromJson(Map<String, dynamic> json) =>
      AiCoachSessionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        sessionType: json['session_type'] as String? ?? 'general',
        context: json['context'] as String?,
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        studyPlanId: json['study_plan_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'session_type': sessionType,
        'context': context,
        'messages': messages,
        'recommendations': recommendations,
        'study_plan_id': studyPlanId,
      };

  AiCoachSession toEntity() => AiCoachSession(
        id: id,
        userId: userId,
        sessionType:
            CoachSessionType.fromString(sessionType) ?? CoachSessionType.general,
        context: context,
        messages: messages,
        recommendations: recommendations,
        studyPlanId: studyPlanId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static AiCoachSessionModel fromEntity(AiCoachSession entity) =>
      AiCoachSessionModel(
        id: entity.id,
        userId: entity.userId,
        sessionType: entity.sessionType.value,
        context: entity.context,
        messages: entity.messages,
        recommendations: entity.recommendations,
        studyPlanId: entity.studyPlanId,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// AI COACH RECOMMENDATION MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiCoachRecommendationModel {
  final String id;
  final String userId;
  final String recommendationType;
  final String priority;
  final String title;
  final String? description;
  final String? actionType;
  final Map<String, dynamic> actionData;
  final bool isDismissed;
  final DateTime? dismissedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const AiCoachRecommendationModel({
    required this.id,
    required this.userId,
    required this.recommendationType,
    this.priority = 'medium',
    required this.title,
    this.description,
    this.actionType,
    this.actionData = const {},
    this.isDismissed = false,
    this.dismissedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory AiCoachRecommendationModel.fromJson(Map<String, dynamic> json) =>
      AiCoachRecommendationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        recommendationType: json['recommendation_type'] as String,
        priority: json['priority'] as String? ?? 'medium',
        title: json['title'] as String,
        description: json['description'] as String?,
        actionType: json['action_type'] as String?,
        actionData: json['action_data'] as Map<String, dynamic>? ?? {},
        isDismissed: json['is_dismissed'] as bool? ?? false,
        dismissedAt: json['dismissed_at'] != null
            ? DateTime.parse(json['dismissed_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'recommendation_type': recommendationType,
        'priority': priority,
        'title': title,
        'description': description,
        'action_type': actionType,
        'action_data': actionData,
        'is_dismissed': isDismissed,
        'dismissed_at': dismissedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

  AiCoachRecommendation toEntity() => AiCoachRecommendation(
        id: id,
        userId: userId,
        recommendationType: recommendationType,
        priority: RecommendationPriority.fromString(priority) ??
            RecommendationPriority.medium,
        title: title,
        description: description,
        actionType: RecommendationActionType.fromString(actionType),
        actionData: actionData,
        isDismissed: isDismissed,
        dismissedAt: dismissedAt,
        expiresAt: expiresAt,
        createdAt: createdAt,
      );

  static AiCoachRecommendationModel fromEntity(AiCoachRecommendation entity) =>
      AiCoachRecommendationModel(
        id: entity.id,
        userId: entity.userId,
        recommendationType: entity.recommendationType,
        priority: entity.priority.value,
        title: entity.title,
        description: entity.description,
        actionType: entity.actionType?.value,
        actionData: entity.actionData,
        isDismissed: entity.isDismissed,
        dismissedAt: entity.dismissedAt,
        expiresAt: entity.expiresAt,
        createdAt: entity.createdAt,
      );
}
