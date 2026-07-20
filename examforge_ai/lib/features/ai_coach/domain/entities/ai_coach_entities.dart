import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Type of AI Coach session.
enum CoachSessionType {
  general(value: 'general', label: 'General Coaching'),
  studyPlan(value: 'study_plan', label: 'Study Plan'),
  weakTopics(value: 'weak_topics', label: 'Weak Topics'),
  examPrep(value: 'exam_prep', label: 'Exam Preparation'),
  motivation(value: 'motivation', label: 'Motivation'),
  careerGuidance(value: 'career_guidance', label: 'Career Guidance');

  const CoachSessionType({required this.value, required this.label});
  final String value;
  final String label;

  static CoachSessionType? fromString(String? value) {
    if (value == null) return null;
    return CoachSessionType.values.cast<CoachSessionType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Priority level for AI Coach recommendations.
enum RecommendationPriority {
  low(value: 'low', label: 'Low'),
  medium(value: 'medium', label: 'Medium'),
  high(value: 'high', label: 'High'),
  urgent(value: 'urgent', label: 'Urgent');

  const RecommendationPriority({required this.value, required this.label});
  final String value;
  final String label;

  static RecommendationPriority? fromString(String? value) {
    if (value == null) return null;
    return RecommendationPriority.values.cast<RecommendationPriority?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Type of recommendation action.
enum RecommendationActionType {
  studyTopic(value: 'study_topic', label: 'Study Topic'),
  practiceQuestion(value: 'practice_question', label: 'Practice Questions'),
  reviewMaterial(value: 'review_material', label: 'Review Material'),
  takeTest(value: 'take_test', label: 'Take Test'),
  adjustPlan(value: 'adjust_plan', label: 'Adjust Study Plan'),
  motivationalBoost(value: 'motivational_boost', label: 'Motivational Boost');

  const RecommendationActionType({required this.value, required this.label});
  final String value;
  final String label;

  static RecommendationActionType? fromString(String? value) {
    if (value == null) return null;
    return RecommendationActionType.values.cast<RecommendationActionType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AI COACH SESSION
// ═══════════════════════════════════════════════════════════════════════

/// Represents a single AI coaching session with conversation history.
class AiCoachSession extends Equatable {
  const AiCoachSession({
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

  final String id;
  final String userId;
  final CoachSessionType sessionType;
  final String? context;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> recommendations;
  final String? studyPlanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id, userId, sessionType, context, messages,
        recommendations, studyPlanId, createdAt, updatedAt,
      ];

  /// Number of messages in this session.
  int get messageCount => messages.length;

  /// Last message content.
  String? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last['content'] as String?;
  }

  /// Whether the session has any AI recommendations.
  bool get hasRecommendations => recommendations.isNotEmpty;

  AiCoachSession copyWith({
    CoachSessionType? sessionType,
    String? context,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? recommendations,
    String? studyPlanId,
    DateTime? updatedAt,
  }) {
    return AiCoachSession(
      id: id,
      userId: userId,
      sessionType: sessionType ?? this.sessionType,
      context: context ?? this.context,
      messages: messages ?? this.messages,
      recommendations: recommendations ?? this.recommendations,
      studyPlanId: studyPlanId ?? this.studyPlanId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AI COACH RECOMMENDATION
// ═══════════════════════════════════════════════════════════════════════

/// Represents a personalized AI recommendation for the student.
class AiCoachRecommendation extends Equatable {
  const AiCoachRecommendation({
    required this.id,
    required this.userId,
    required this.recommendationType,
    this.priority = RecommendationPriority.medium,
    required this.title,
    this.description,
    this.actionType,
    this.actionData = const {},
    this.isDismissed = false,
    this.dismissedAt,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String recommendationType;
  final RecommendationPriority priority;
  final String title;
  final String? description;
  final RecommendationActionType? actionType;
  final Map<String, dynamic> actionData;
  final bool isDismissed;
  final DateTime? dismissedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id, userId, recommendationType, priority, title,
        description, actionType, actionData, isDismissed,
        dismissedAt, expiresAt, createdAt,
      ];

  /// Whether the recommendation has expired.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Whether the recommendation is still active (not dismissed and not expired).
  bool get isActive => !isDismissed && !isExpired;

  AiCoachRecommendation copyWith({
    bool? isDismissed,
    DateTime? dismissedAt,
  }) {
    return AiCoachRecommendation(
      id: id,
      userId: userId,
      recommendationType: recommendationType,
      priority: priority,
      title: title,
      description: description,
      actionType: actionType,
      actionData: actionData,
      isDismissed: isDismissed ?? this.isDismissed,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// WEAK TOPIC (value object)
// ═══════════════════════════════════════════════════════════════════════

/// Represents a topic where the student is weak.
class WeakTopic extends Equatable {
  const WeakTopic({
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    this.accuracy = 0.0,
    this.attemptsCount = 0,
    this.correctCount = 0,
    this.severity = 'medium',
    this.recommendations = const [],
  });

  final String topicId;
  final String topicName;
  final String subjectName;
  final double accuracy;
  final int attemptsCount;
  final int correctCount;
  final String severity;
  final List<String> recommendations;

  @override
  List<Object?> get props => [
        topicId, topicName, subjectName, accuracy,
        attemptsCount, correctCount, severity, recommendations,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLAN GENERATION RESULT (value object)
// ═══════════════════════════════════════════════════════════════════════

/// Result of an AI-generated study plan.
class GeneratedStudyPlan extends Equatable {
  const GeneratedStudyPlan({
    required this.title,
    required this.description,
    required this.tasks,
    this.estimatedDurationDays = 30,
    this.focusAreas = const [],
    this.milestones = const [],
  });

  final String title;
  final String description;
  final List<Map<String, dynamic>> tasks;
  final int estimatedDurationDays;
  final List<String> focusAreas;
  final List<Map<String, dynamic>> milestones;

  @override
  List<Object?> get props => [
        title, description, tasks, estimatedDurationDays,
        focusAreas, milestones,
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// READINESS PREDICTION (value object)
// ═══════════════════════════════════════════════════════════════════════

/// AI prediction of exam readiness.
class ReadinessPrediction extends Equatable {
  const ReadinessPrediction({
    required this.overallScore,
    required this.confidence,
    this.subjectScores = const {},
    this.predictedGrade,
    this.improvementAreas = const [],
    this.strengths = const [],
    this.recommendedStudyHours = 0,
    this.targetDate,
  });

  final double overallScore;
  final double confidence;
  final Map<String, double> subjectScores;
  final String? predictedGrade;
  final List<String> improvementAreas;
  final List<String> strengths;
  final int recommendedStudyHours;
  final DateTime? targetDate;

  @override
  List<Object?> get props => [
        overallScore, confidence, subjectScores, predictedGrade,
        improvementAreas, strengths, recommendedStudyHours, targetDate,
      ];
}
