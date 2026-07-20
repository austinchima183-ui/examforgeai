import '../../domain/entities/analytics_dashboard_entities.dart';

class AnalyticsEventModel {
  final String id;
  final String eventType;
  final String eventName;
  final String? userId;
  final String? schoolId;
  final String? sessionId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> deviceInfo;
  final DateTime timestamp;

  const AnalyticsEventModel({
    required this.id, required this.eventType, required this.eventName,
    this.userId, this.schoolId, this.sessionId,
    required this.properties, required this.deviceInfo, required this.timestamp,
  });

  factory AnalyticsEventModel.fromJson(Map<String, dynamic> json) => AnalyticsEventModel(
    id: json['id'] as String, eventType: json['event_type'] as String,
    eventName: json['event_name'] as String, userId: json['user_id'] as String?,
    schoolId: json['school_id'] as String?, sessionId: json['session_id'] as String?,
    properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    deviceInfo: Map<String, dynamic>.from(json['device_info'] as Map? ?? {}),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'event_type': eventType, 'event_name': eventName,
    'user_id': userId, 'school_id': schoolId, 'session_id': sessionId,
    'properties': properties, 'device_info': deviceInfo,
    'timestamp': timestamp.toIso8601String(),
  };

  AnalyticsEvent toEntity() => AnalyticsEvent(
    id: id, eventType: eventType, eventName: eventName, userId: userId,
    schoolId: schoolId, sessionId: sessionId, properties: properties,
    deviceInfo: deviceInfo, timestamp: timestamp,
  );
}

class DailyAnalyticModel {
  final String id;
  final DateTime date;
  final String schoolId;
  final String metricName;
  final String metricType;
  final double value;
  final Map<String, dynamic> dimensions;
  final DateTime createdAt;

  const DailyAnalyticModel({
    required this.id, required this.date, required this.schoolId,
    required this.metricName, required this.metricType, required this.value,
    required this.dimensions, required this.createdAt,
  });

  factory DailyAnalyticModel.fromJson(Map<String, dynamic> json) => DailyAnalyticModel(
    id: json['id'] as String, date: DateTime.parse(json['date'] as String),
    schoolId: json['school_id'] as String, metricName: json['metric_name'] as String,
    metricType: json['metric_type'] as String, value: (json['value'] as num?)?.toDouble() ?? 0.0,
    dimensions: Map<String, dynamic>.from(json['dimensions'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String().substring(0, 10),
    'school_id': schoolId, 'metric_name': metricName, 'metric_type': metricType,
    'value': value, 'dimensions': dimensions, 'created_at': createdAt.toIso8601String(),
  };

  DailyAnalytic toEntity() => DailyAnalytic(
    id: id, date: date, schoolId: schoolId, metricName: metricName,
    metricType: metricType, value: value, dimensions: dimensions, createdAt: createdAt,
  );
}

class ReleaseNoteModel {
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

  const ReleaseNoteModel({
    required this.id, required this.version, required this.title,
    required this.content, required this.contentRich, required this.releaseType,
    required this.isPublished, this.publishedAt, required this.createdBy,
    required this.createdAt,
  });

  factory ReleaseNoteModel.fromJson(Map<String, dynamic> json) => ReleaseNoteModel(
    id: json['id'] as String, version: json['version'] as String,
    title: json['title'] as String, content: json['content'] as String,
    contentRich: Map<String, dynamic>.from(json['content_rich'] as Map? ?? {}),
    releaseType: json['release_type'] as String? ?? 'patch',
    isPublished: json['is_published'] as bool? ?? false,
    publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'version': version, 'title': title, 'content': content,
    'content_rich': contentRich, 'release_type': releaseType,
    'is_published': isPublished, 'published_at': publishedAt?.toIso8601String(),
    'created_by': createdBy, 'created_at': createdAt.toIso8601String(),
  };

  ReleaseNote toEntity() => ReleaseNote(
    id: id, version: version, title: title, content: content,
    contentRich: contentRich, releaseType: releaseType, isPublished: isPublished,
    publishedAt: publishedAt, createdBy: createdBy, createdAt: createdAt,
  );
}
