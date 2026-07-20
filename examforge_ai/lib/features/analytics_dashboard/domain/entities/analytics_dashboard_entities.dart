import 'package:equatable/equatable.dart';

// ============================================================================
// ENTITIES
// ============================================================================

class AnalyticsEvent extends Equatable {
  final String id;
  final String eventType;
  final String eventName;
  final String? userId;
  final String? schoolId;
  final String? sessionId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> deviceInfo;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.id, required this.eventType, required this.eventName,
    this.userId, this.schoolId, this.sessionId,
    required this.properties, required this.deviceInfo, required this.timestamp,
  });

  @override
  List<Object?> get props => [id, eventType, eventName, userId, schoolId, sessionId, properties, deviceInfo, timestamp];

  AnalyticsEvent copyWith({
    String? id, String? eventType, String? eventName, String? userId,
    String? schoolId, String? sessionId, Map<String, dynamic>? properties,
    Map<String, dynamic>? deviceInfo, DateTime? timestamp,
  }) => AnalyticsEvent(
    id: id ?? this.id, eventType: eventType ?? this.eventType, eventName: eventName ?? this.eventName,
    userId: userId ?? this.userId, schoolId: schoolId ?? this.schoolId,
    sessionId: sessionId ?? this.sessionId, properties: properties ?? this.properties,
    deviceInfo: deviceInfo ?? this.deviceInfo, timestamp: timestamp ?? this.timestamp,
  );
}

class DailyAnalytic extends Equatable {
  final String id;
  final DateTime date;
  final String schoolId;
  final String metricName;
  final String metricType;
  final double value;
  final Map<String, dynamic> dimensions;
  final DateTime createdAt;

  const DailyAnalytic({
    required this.id, required this.date, required this.schoolId,
    required this.metricName, required this.metricType, required this.value,
    required this.dimensions, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, date, schoolId, metricName, metricType, value, dimensions, createdAt];

  DailyAnalytic copyWith({
    String? id, DateTime? date, String? schoolId, String? metricName,
    String? metricType, double? value, Map<String, dynamic>? dimensions,
    DateTime? createdAt,
  }) => DailyAnalytic(
    id: id ?? this.id, date: date ?? this.date, schoolId: schoolId ?? this.schoolId,
    metricName: metricName ?? this.metricName, metricType: metricType ?? this.metricType,
    value: value ?? this.value, dimensions: dimensions ?? this.dimensions,
    createdAt: createdAt ?? this.createdAt,
  );
}

class ReleaseNote extends Equatable {
  final String id;
  final String version;
  final String title;
  final String content;
  final Map<String, dynamic> contentRich;
  final String releaseType;
  final bool isPublished;
  final DateTime? publishedAt;
  final String createdBy;
  final DateTime createdAt;

  const ReleaseNote({
    required this.id, required this.version, required this.title,
    required this.content, required this.contentRich, required this.releaseType,
    required this.isPublished, this.publishedAt, required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, version, title, content, contentRich, releaseType, isPublished, publishedAt, createdBy, createdAt];

  ReleaseNote copyWith({
    String? id, String? version, String? title, String? content,
    Map<String, dynamic>? contentRich, String? releaseType, bool? isPublished,
    DateTime? publishedAt, String? createdBy, DateTime? createdAt,
  }) => ReleaseNote(
    id: id ?? this.id, version: version ?? this.version, title: title ?? this.title,
    content: content ?? this.content, contentRich: contentRich ?? this.contentRich,
    releaseType: releaseType ?? this.releaseType, isPublished: isPublished ?? this.isPublished,
    publishedAt: publishedAt ?? this.publishedAt, createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );
}
