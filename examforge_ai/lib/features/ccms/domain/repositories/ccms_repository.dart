import '../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';

/// Abstract contract for the CCMS repository.
///
/// All CCMS operations flow through this interface, enabling
/// Clean Architecture separation and testability.
abstract class CcmsRepository {
  // ─── Educational Levels ──────────────────────────────────────────────

  /// Get all educational levels.
  Future<Result<List<EducationalLevel>>> getEducationalLevels();

  /// Get school-level configurations for a given school.
  Future<Result<List<SchoolLevelConfiguration>>> getSchoolLevels(String schoolId);

  /// Configure a new school level.
  Future<Result<SchoolLevelConfiguration>> configureSchoolLevel(
    SchoolLevelConfiguration configuration,
  );

  /// Update an existing school level configuration.
  Future<Result<SchoolLevelConfiguration>> updateSchoolLevelConfiguration(
    SchoolLevelConfiguration configuration,
  );

  // ─── Curricula ───────────────────────────────────────────────────────

  /// Get curricula with optional filtering.
  Future<Result<List<Curriculum>>> getCurricula({
    String? countryCode,
    CurriculumType? curriculumType,
    bool? isActive,
  });

  /// Get a single curriculum by ID.
  Future<Result<Curriculum>> getCurriculumById(String id);

  /// Create a new curriculum.
  Future<Result<Curriculum>> createCurriculum(Curriculum curriculum);

  /// Update an existing curriculum.
  Future<Result<Curriculum>> updateCurriculum(Curriculum curriculum);

  /// Get versions for a given curriculum.
  Future<Result<List<CurriculumVersion>>> getCurriculumVersions(String curriculumId);

  /// Get level mappings for a given curriculum.
  Future<Result<List<CurriculumLevelMapping>>> getCurriculumLevelMappings(String curriculumId);

  // ─── Subjects ────────────────────────────────────────────────────────

  /// Get subjects with optional filtering.
  Future<Result<List<Subject>>> getSubjects({
    String? schoolId,
    String? educationalLevelId,
    String? curriculumId,
  });

  /// Get a single subject by ID.
  Future<Result<Subject>> getSubjectById(String id);

  /// Create a new subject.
  Future<Result<Subject>> createSubject(Subject subject);

  /// Update an existing subject.
  Future<Result<Subject>> updateSubject(Subject subject);

  /// Delete a subject by ID.
  Future<Result<bool>> deleteSubject(String id);

  /// Get subjects for a specific educational level.
  Future<Result<List<Subject>>> getLevelSubjects(String educationalLevelId);

  // ─── Topics ──────────────────────────────────────────────────────────

  /// Get topics with optional filtering.
  Future<Result<List<Topic>>> getTopics({
    String? subjectId,
    String? educationalLevelId,
    String? curriculumId,
    String? parentTopicId,
  });

  /// Get a single topic by ID.
  Future<Result<Topic>> getTopicById(String id);

  /// Create a new topic.
  Future<Result<Topic>> createTopic(Topic topic);

  /// Update an existing topic.
  Future<Result<Topic>> updateTopic(Topic topic);

  /// Delete a topic by ID.
  Future<Result<bool>> deleteTopic(String id);

  /// Get subtopics for a given topic.
  Future<Result<List<Subtopic>>> getSubtopics(String topicId);

  /// Create a new subtopic.
  Future<Result<Subtopic>> createSubtopic(Subtopic subtopic);

  /// Update an existing subtopic.
  Future<Result<Subtopic>> updateSubtopic(Subtopic subtopic);

  /// Delete a subtopic by ID.
  Future<Result<bool>> deleteSubtopic(String id);

  /// Get the full curriculum tree for a subject.
  Future<Result<List<Topic>>> getCurriculumTree(String subjectId);

  // ─── Learning Objectives ─────────────────────────────────────────────

  /// Get learning objectives with optional filtering.
  Future<Result<List<LearningObjective>>> getLearningObjectives({
    String? topicId,
    String? subtopicId,
    String? subjectId,
    String? educationalLevelId,
  });

  /// Create a new learning objective.
  Future<Result<LearningObjective>> createLearningObjective(
    LearningObjective learningObjective,
  );

  /// Update an existing learning objective.
  Future<Result<LearningObjective>> updateLearningObjective(
    LearningObjective learningObjective,
  );

  /// Delete a learning objective by ID.
  Future<Result<bool>> deleteLearningObjective(String id);

  // ─── Content ─────────────────────────────────────────────────────────

  /// Get content items with optional filtering and pagination.
  Future<Result<List<ContentItem>>> getContentItems({
    String? subjectId,
    String? educationalLevelId,
    String? topicId,
    String? subtopicId,
    String? curriculumId,
    String? schoolId,
    ContentType? contentType,
    QuestionCategory? questionCategory,
    DifficultyLevel? difficultyLevel,
    BloomTaxonomy? bloomLevel,
    ContentStatus? status,
    bool? isPastQuestion,
    bool? isAiGenerated,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  /// Get a single content item by ID.
  Future<Result<ContentItem>> getContentById(String id);

  /// Create a new content item.
  Future<Result<ContentItem>> createContent(ContentItem content);

  /// Update an existing content item.
  Future<Result<ContentItem>> updateContent(ContentItem content);

  /// Delete a content item by ID.
  Future<Result<bool>> deleteContent(String id);

  /// Publish a content item.
  Future<Result<ContentItem>> publishContent(String id);

  /// Archive a content item.
  Future<Result<ContentItem>> archiveContent(String id);

  /// Get version history for a content item.
  Future<Result<List<ContentVersion>>> getContentVersions(String contentItemId);

  /// Get a content item with full details including reviews and versions.
  Future<Result<ContentItem>> getContentWithDetails(String id);

  // ─── Reviews ─────────────────────────────────────────────────────────

  /// Create a content review.
  Future<Result<ContentReview>> createReview(ContentReview review);

  /// Get reviews for a content item.
  Future<Result<List<ContentReview>>> getContentReviews(String contentItemId);

  // ─── Imports ─────────────────────────────────────────────────────────

  /// Create a new content import.
  Future<Result<ContentImport>> createImport(ContentImport importEntry);

  /// Get imports with optional filtering.
  Future<Result<List<ContentImport>>> getImports({
    String? schoolId,
    ImportStatus? status,
    int limit = 20,
    int offset = 0,
  });

  /// Get a single import by ID.
  Future<Result<ContentImport>> getImportById(String id);

  // ─── Collections ─────────────────────────────────────────────────────

  /// Get content collections with optional filtering.
  Future<Result<List<ContentCollection>>> getCollections({
    String? subjectId,
    String? educationalLevelId,
    String? schoolId,
    bool? isPublic,
    int limit = 20,
    int offset = 0,
  });

  /// Get a single collection by ID.
  Future<Result<ContentCollection>> getCollectionById(String id);

  /// Create a new content collection.
  Future<Result<ContentCollection>> createCollection(ContentCollection collection);

  /// Update an existing content collection.
  Future<Result<ContentCollection>> updateCollection(ContentCollection collection);

  /// Delete a content collection by ID.
  Future<Result<bool>> deleteCollection(String id);

  /// Add an item to a collection.
  Future<Result<ContentCollectionItem>> addCollectionItem(
    ContentCollectionItem item,
  );

  /// Remove an item from a collection.
  Future<Result<bool>> removeCollectionItem(String collectionItemId);

  // ─── AI Curriculum ───────────────────────────────────────────────────

  /// Get AI curriculum configuration for a school/subject/level.
  Future<Result<AiCurriculumConfig>> getAiCurriculumConfig({
    required String schoolId,
    required String subjectId,
    required String educationalLevelId,
  });

  /// Create or update an AI curriculum configuration.
  Future<Result<AiCurriculumConfig>> upsertAiCurriculumConfig(
    AiCurriculumConfig config,
  );

  /// Get AI generation rules with optional filtering.
  Future<Result<List<AiGenerationRule>>> getAiGenerationRules({
    String? educationalLevelId,
    String? subjectId,
    bool? isActive,
  });

  /// Create a new AI generation rule.
  Future<Result<AiGenerationRule>> createAiGenerationRule(AiGenerationRule rule);

  /// Update an existing AI generation rule.
  Future<Result<AiGenerationRule>> updateAiGenerationRule(AiGenerationRule rule);

  // ─── Answer Repository ───────────────────────────────────────────────

  /// Get an answer repository entry by content item ID.
  Future<Result<AnswerRepositoryEntry>> getAnswerRepositoryEntry(String contentItemId);

  /// Create a new answer repository entry.
  Future<Result<AnswerRepositoryEntry>> createAnswerEntry(
    AnswerRepositoryEntry entry,
  );

  /// Update an existing answer repository entry.
  Future<Result<AnswerRepositoryEntry>> updateAnswerEntry(
    AnswerRepositoryEntry entry,
  );

  /// Verify an answer repository entry.
  Future<Result<AnswerRepositoryEntry>> verifyAnswer({
    required String entryId,
    required String verifiedBy,
  });

  // ─── Stats ───────────────────────────────────────────────────────────

  /// Get CCMS aggregate statistics.
  Future<Result<CcmsStats>> getCcmsStats({
    String? schoolId,
    String? educationalLevelId,
    String? subjectId,
  });

  // ─── Audit ───────────────────────────────────────────────────────────

  /// Record an audit event.
  Future<Result<AuditEntry>> recordAuditEvent(AuditEntry entry);

  /// Get audit trail with optional filtering.
  Future<Result<List<AuditEntry>>> getAuditTrail({
    String? userId,
    String? schoolId,
    AuditAction? action,
    String? resourceType,
    String? resourceId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });

  // ─── MFA ─────────────────────────────────────────────────────────────

  /// Get MFA configuration for a user.
  Future<Result<MfaConfiguration>> getMfaConfig(String userId);

  /// Enable MFA for a user.
  Future<Result<MfaConfiguration>> enableMfa({
    required String userId,
    required MfaMethod method,
    String? phoneNumber,
  });

  /// Disable MFA for a user.
  Future<Result<bool>> disableMfa({
    required String userId,
    required String verificationCode,
  });

  /// Verify an MFA challenge.
  Future<Result<bool>> verifyMfa({
    required String userId,
    required String verificationCode,
  });

  // ─── API Keys ────────────────────────────────────────────────────────

  /// Create a new API key.
  Future<Result<ApiKey>> createApiKey({
    required String userId,
    required String name,
    String? schoolId,
    List<String>? scopes,
    int? rateLimitOverride,
    DateTime? expiresAt,
  });

  /// Revoke an API key.
  Future<Result<bool>> revokeApiKey(String apiKeyId);

  /// Get API keys for a user.
  Future<Result<List<ApiKey>>> getApiKeys(String userId);

  // ─── Security ────────────────────────────────────────────────────────

  /// Record a security event.
  Future<Result<SecurityEvent>> recordSecurityEvent(SecurityEvent event);

  /// Get security events with optional filtering.
  Future<Result<List<SecurityEvent>>> getSecurityEvents({
    String? userId,
    String? schoolId,
    AlertSeverity? severity,
    bool? isResolved,
    int limit = 50,
    int offset = 0,
  });

  /// Check if a request is within rate limits.
  Future<Result<bool>> checkRateLimit({
    required RateLimitScope scope,
    required String identifier,
    String? endpointPattern,
  });

  // ─── Sessions ────────────────────────────────────────────────────────

  /// Get active sessions for a user.
  Future<Result<List<UserSession>>> getUserSessions(String userId);

  /// Invalidate a specific user session.
  Future<Result<bool>> invalidateUserSessions({
    required String userId,
    required String sessionId,
  });

  /// Invalidate all other sessions for a user except the current one.
  Future<Result<bool>> invalidateAllOtherSessions({
    required String userId,
    required String currentSessionId,
  });

  // ─── Monitoring ──────────────────────────────────────────────────────

  /// Record a system metric.
  Future<Result<SystemMetric>> recordMetric(SystemMetric metric);

  /// Get system metrics with optional filtering.
  Future<Result<List<SystemMetric>>> getSystemMetrics({
    String? metricName,
    MetricType? metricType,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });

  /// Get alert rules with optional filtering.
  Future<Result<List<AlertRule>>> getAlertRules({
    bool? isActive,
    AlertSeverity? severity,
  });

  /// Create a new alert rule.
  Future<Result<AlertRule>> createAlertRule(AlertRule rule);

  /// Get alert incidents with optional filtering.
  Future<Result<List<AlertIncident>>> getAlertIncidents({
    String? alertRuleId,
    String? status,
    AlertSeverity? severity,
    int limit = 50,
    int offset = 0,
  });

  /// Acknowledge an alert incident.
  Future<Result<AlertIncident>> acknowledgeAlert({
    required String incidentId,
    required String acknowledgedBy,
  });

  /// Resolve an alert incident.
  Future<Result<AlertIncident>> resolveAlert({
    required String incidentId,
    required String resolutionNotes,
  });

  // ─── Performance ─────────────────────────────────────────────────────

  /// Record a performance log entry.
  Future<Result<PerformanceLog>> recordPerformanceLog(PerformanceLog log);

  /// Get performance logs with optional filtering.
  Future<Result<List<PerformanceLog>>> getPerformanceLogs({
    String? operationType,
    String? operationName,
    bool? isSlow,
    String? userId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });

  // ─── Errors ──────────────────────────────────────────────────────────

  /// Report an error.
  Future<Result<ErrorReport>> reportError(ErrorReport report);

  /// Get error reports with optional filtering.
  Future<Result<List<ErrorReport>>> getErrorReports({
    String? errorType,
    bool? isResolved,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  });

  /// Resolve an error report.
  Future<Result<ErrorReport>> resolveError({
    required String errorId,
    required String resolvedBy,
  });

  // ─── Deployments ─────────────────────────────────────────────────────

  /// Get deployments with optional filtering.
  Future<Result<List<Deployment>>> getDeployments({
    String? environment,
    DeploymentStatus? status,
    int limit = 20,
    int offset = 0,
  });

  /// Create a new deployment record.
  Future<Result<Deployment>> createDeployment(Deployment deployment);

  /// Update the status of a deployment.
  Future<Result<Deployment>> updateDeploymentStatus({
    required String deploymentId,
    required DeploymentStatus status,
    String? notes,
  });

  // ─── Testing ─────────────────────────────────────────────────────────

  /// Record a test result.
  Future<Result<TestResult>> recordTestResult(TestResult result);

  /// Get test results with optional filtering.
  Future<Result<List<TestResult>>> getTestResults({
    TestType? testType,
    String? deploymentId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
}
