import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/repositories/ccms_repository.dart';
import '../datasources/ccms_remote_datasource.dart';
import '../models/ccms_models.dart';

/// Concrete implementation of [CcmsRepository] that delegates
/// all operations to [CcmsRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class CcmsRepositoryImpl implements CcmsRepository {
  CcmsRepositoryImpl({
    required CcmsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CcmsRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER: Exception → Failure mapping
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapException(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
    } else if (e is NetworkException) {
      return Failure.network(message: e.message);
    } else if (e is ValidationException) {
      return Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
    } else if (e is NotFoundException) {
      return Failure.notFound(message: e.message);
    } else if (e is UnauthorizedException) {
      return Failure.unauthorized(message: e.message);
    } else if (e is ForbiddenException) {
      return Failure.forbidden(message: e.message);
    } else if (e is FormatException) {
      return Failure.server(
        message: 'Data format error: ${e.message}',
        statusCode: 422,
      );
    } else {
      AppLogger.error('Unexpected CCMS repository error', error: e);
      return Failure.server(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Educational Levels
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<EducationalLevel>>> getEducationalLevels() async {
    try {
      final data = await _remoteDataSource.getEducationalLevels();
      final entities = data
          .map((e) => EducationalLevelModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<SchoolLevelConfiguration>>> getSchoolLevels(
    String schoolId,
  ) async {
    try {
      final data = await _remoteDataSource.getSchoolLevels(schoolId);
      final entities = data
          .map((e) => SchoolLevelConfigurationModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<SchoolLevelConfiguration>> configureSchoolLevel(
    SchoolLevelConfiguration configuration,
  ) async {
    try {
      final model = SchoolLevelConfigurationModel.fromEntity(configuration);
      final data =
          await _remoteDataSource.configureSchoolLevel(model.toJson());
      return Success(SchoolLevelConfigurationModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<SchoolLevelConfiguration>> updateSchoolLevelConfiguration(
    SchoolLevelConfiguration configuration,
  ) async {
    try {
      final model = SchoolLevelConfigurationModel.fromEntity(configuration);
      final data = await _remoteDataSource.updateSchoolLevelConfiguration(
        configuration.id,
        model.toJson(),
      );
      return Success(SchoolLevelConfigurationModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Curricula
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<Curriculum>>> getCurricula({
    String? countryCode,
    CurriculumType? curriculumType,
    bool? isActive,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (countryCode != null) filters['country_code'] = countryCode;
      if (curriculumType != null) filters['curriculum_type'] = curriculumType.value;
      if (isActive != null) filters['is_active'] = isActive;

      final data = await _remoteDataSource.getCurricula(filters);
      final entities =
          data.map((e) => CurriculumModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Curriculum>> getCurriculumById(String id) async {
    try {
      final data = await _remoteDataSource.getCurriculumById(id);
      return Success(CurriculumModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Curriculum>> createCurriculum(Curriculum curriculum) async {
    try {
      final model = CurriculumModel.fromEntity(curriculum);
      final data = await _remoteDataSource.createCurriculum(model.toJson());
      return Success(CurriculumModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Curriculum>> updateCurriculum(Curriculum curriculum) async {
    try {
      final model = CurriculumModel.fromEntity(curriculum);
      final data =
          await _remoteDataSource.updateCurriculum(curriculum.id, model.toJson());
      return Success(CurriculumModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<CurriculumVersion>>> getCurriculumVersions(
    String curriculumId,
  ) async {
    try {
      final data =
          await _remoteDataSource.getCurriculumVersions(curriculumId);
      final entities = data
          .map((e) => CurriculumVersionModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<CurriculumLevelMapping>>> getCurriculumLevelMappings(
    String curriculumId,
  ) async {
    try {
      final data =
          await _remoteDataSource.getCurriculumLevelMappings(curriculumId);
      final entities = data
          .map((e) => CurriculumLevelMappingModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Subjects
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<Subject>>> getSubjects({
    String? schoolId,
    String? educationalLevelId,
    String? curriculumId,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (schoolId != null) filters['school_id'] = schoolId;
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }
      if (curriculumId != null) filters['curriculum_id'] = curriculumId;

      final data = await _remoteDataSource.getSubjects(filters);
      final entities =
          data.map((e) => SubjectModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Subject>> getSubjectById(String id) async {
    try {
      final data = await _remoteDataSource.getSubjectById(id);
      return Success(SubjectModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Subject>> createSubject(Subject subject) async {
    try {
      final model = SubjectModel.fromEntity(subject);
      final data = await _remoteDataSource.createSubject(model.toJson());
      return Success(SubjectModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Subject>> updateSubject(Subject subject) async {
    try {
      final model = SubjectModel.fromEntity(subject);
      final data =
          await _remoteDataSource.updateSubject(subject.id, model.toJson());
      return Success(SubjectModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteSubject(String id) async {
    try {
      await _remoteDataSource.deleteSubject(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<Subject>>> getLevelSubjects(
    String educationalLevelId,
  ) async {
    try {
      final data =
          await _remoteDataSource.getLevelSubjects(educationalLevelId);
      final entities =
          data.map((e) => SubjectModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Topics
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<Topic>>> getTopics({
    String? subjectId,
    String? educationalLevelId,
    String? curriculumId,
    String? parentTopicId,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }
      if (curriculumId != null) filters['curriculum_id'] = curriculumId;
      if (parentTopicId != null) filters['parent_topic_id'] = parentTopicId;

      final data = await _remoteDataSource.getTopics(filters);
      final entities =
          data.map((e) => TopicModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Topic>> getTopicById(String id) async {
    try {
      final data = await _remoteDataSource.getTopicById(id);
      return Success(TopicModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Topic>> createTopic(Topic topic) async {
    try {
      final model = TopicModel.fromEntity(topic);
      final data = await _remoteDataSource.createTopic(model.toJson());
      return Success(TopicModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Topic>> updateTopic(Topic topic) async {
    try {
      final model = TopicModel.fromEntity(topic);
      final data =
          await _remoteDataSource.updateTopic(topic.id, model.toJson());
      return Success(TopicModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteTopic(String id) async {
    try {
      await _remoteDataSource.deleteTopic(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<Subtopic>>> getSubtopics(String topicId) async {
    try {
      final data = await _remoteDataSource.getSubtopics(topicId);
      final entities =
          data.map((e) => SubtopicModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Subtopic>> createSubtopic(Subtopic subtopic) async {
    try {
      final model = SubtopicModel.fromEntity(subtopic);
      final data = await _remoteDataSource.createSubtopic(model.toJson());
      return Success(SubtopicModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Subtopic>> updateSubtopic(Subtopic subtopic) async {
    try {
      final model = SubtopicModel.fromEntity(subtopic);
      final data =
          await _remoteDataSource.updateSubtopic(subtopic.id, model.toJson());
      return Success(SubtopicModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteSubtopic(String id) async {
    try {
      await _remoteDataSource.deleteSubtopic(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<Topic>>> getCurriculumTree(String subjectId) async {
    try {
      final data = await _remoteDataSource.getCurriculumTree(subjectId);
      final entities =
          data.map((e) => TopicModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Learning Objectives
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<LearningObjective>>> getLearningObjectives({
    String? topicId,
    String? subtopicId,
    String? subjectId,
    String? educationalLevelId,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (topicId != null) filters['topic_id'] = topicId;
      if (subtopicId != null) filters['subtopic_id'] = subtopicId;
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }

      final data = await _remoteDataSource.getLearningObjectives(filters);
      final entities = data
          .map((e) => LearningObjectiveModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<LearningObjective>> createLearningObjective(
    LearningObjective learningObjective,
  ) async {
    try {
      final model = LearningObjectiveModel.fromEntity(learningObjective);
      final data =
          await _remoteDataSource.createLearningObjective(model.toJson());
      return Success(LearningObjectiveModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<LearningObjective>> updateLearningObjective(
    LearningObjective learningObjective,
  ) async {
    try {
      final model = LearningObjectiveModel.fromEntity(learningObjective);
      final data = await _remoteDataSource.updateLearningObjective(
        learningObjective.id,
        model.toJson(),
      );
      return Success(LearningObjectiveModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteLearningObjective(String id) async {
    try {
      await _remoteDataSource.deleteLearningObjective(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Content
  // ═══════════════════════════════════════════════════════════════════════

  @override
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
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }
      if (topicId != null) filters['topic_id'] = topicId;
      if (subtopicId != null) filters['subtopic_id'] = subtopicId;
      if (curriculumId != null) filters['curriculum_id'] = curriculumId;
      if (schoolId != null) filters['school_id'] = schoolId;
      if (contentType != null) filters['content_type'] = contentType.value;
      if (questionCategory != null) {
        filters['question_category'] = questionCategory.value;
      }
      if (difficultyLevel != null) {
        filters['difficulty_level'] = difficultyLevel.value;
      }
      if (bloomLevel != null) filters['bloom_level'] = bloomLevel.value;
      if (status != null) filters['status'] = status.value;
      if (isPastQuestion != null) filters['is_past_question'] = isPastQuestion;
      if (isAiGenerated != null) filters['is_ai_generated'] = isAiGenerated;
      if (search != null) filters['search'] = search;

      final data = await _remoteDataSource.getContentItems(filters);
      final entities =
          data.map((e) => ContentItemModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> getContentById(String id) async {
    try {
      final data = await _remoteDataSource.getContentById(id);
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> createContent(ContentItem content) async {
    try {
      final model = ContentItemModel.fromEntity(content);
      final data = await _remoteDataSource.createContent(model.toJson());
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> updateContent(ContentItem content) async {
    try {
      final model = ContentItemModel.fromEntity(content);
      final data =
          await _remoteDataSource.updateContent(content.id, model.toJson());
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteContent(String id) async {
    try {
      await _remoteDataSource.deleteContent(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> publishContent(String id) async {
    try {
      final data = await _remoteDataSource.publishContent(id);
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> archiveContent(String id) async {
    try {
      final data = await _remoteDataSource.archiveContent(id);
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ContentVersion>>> getContentVersions(
    String contentItemId,
  ) async {
    try {
      final data = await _remoteDataSource.getContentVersions(contentItemId);
      final entities = data
          .map((e) => ContentVersionModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentItem>> getContentWithDetails(String id) async {
    try {
      final data = await _remoteDataSource.getContentWithDetails(id);
      return Success(ContentItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Reviews
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ContentReview>> createReview(ContentReview review) async {
    try {
      final model = ContentReviewModel.fromEntity(review);
      final data = await _remoteDataSource.createReview(model.toJson());
      return Success(ContentReviewModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ContentReview>>> getContentReviews(
    String contentItemId,
  ) async {
    try {
      final data = await _remoteDataSource.getContentReviews(contentItemId);
      final entities = data
          .map((e) => ContentReviewModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Imports
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ContentImport>> createImport(ContentImport importEntry) async {
    try {
      final model = ContentImportModel.fromEntity(importEntry);
      final data = await _remoteDataSource.createImport(model.toJson());
      return Success(ContentImportModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ContentImport>>> getImports({
    String? schoolId,
    ImportStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (schoolId != null) filters['school_id'] = schoolId;
      if (status != null) filters['status'] = status.value;

      final data = await _remoteDataSource.getImports(filters);
      final entities =
          data.map((e) => ContentImportModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentImport>> getImportById(String id) async {
    try {
      final data = await _remoteDataSource.getImportById(id);
      return Success(ContentImportModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Collections
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ContentCollection>>> getCollections({
    String? subjectId,
    String? educationalLevelId,
    String? schoolId,
    bool? isPublic,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }
      if (schoolId != null) filters['school_id'] = schoolId;
      if (isPublic != null) filters['is_public'] = isPublic;

      final data = await _remoteDataSource.getCollections(filters);
      final entities = data
          .map((e) => ContentCollectionModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentCollection>> getCollectionById(String id) async {
    try {
      final data = await _remoteDataSource.getCollectionById(id);
      return Success(ContentCollectionModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentCollection>> createCollection(
    ContentCollection collection,
  ) async {
    try {
      final model = ContentCollectionModel.fromEntity(collection);
      final data = await _remoteDataSource.createCollection(model.toJson());
      return Success(ContentCollectionModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentCollection>> updateCollection(
    ContentCollection collection,
  ) async {
    try {
      final model = ContentCollectionModel.fromEntity(collection);
      final data = await _remoteDataSource.updateCollection(
        collection.id,
        model.toJson(),
      );
      return Success(ContentCollectionModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> deleteCollection(String id) async {
    try {
      await _remoteDataSource.deleteCollection(id);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ContentCollectionItem>> addCollectionItem(
    ContentCollectionItem item,
  ) async {
    try {
      final model = ContentCollectionItemModel.fromEntity(item);
      final data = await _remoteDataSource.addCollectionItem(model.toJson());
      return Success(ContentCollectionItemModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> removeCollectionItem(String collectionItemId) async {
    try {
      await _remoteDataSource.removeCollectionItem(collectionItemId);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI Curriculum
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiCurriculumConfig>> getAiCurriculumConfig({
    required String schoolId,
    required String subjectId,
    required String educationalLevelId,
  }) async {
    try {
      final data = await _remoteDataSource.getAiCurriculumConfig({
        'school_id': schoolId,
        'subject_id': subjectId,
        'educational_level_id': educationalLevelId,
      });
      return Success(AiCurriculumConfigModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AiCurriculumConfig>> upsertAiCurriculumConfig(
    AiCurriculumConfig config,
  ) async {
    try {
      final model = AiCurriculumConfigModel.fromEntity(config);
      final data =
          await _remoteDataSource.upsertAiCurriculumConfig(model.toJson());
      return Success(AiCurriculumConfigModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<AiGenerationRule>>> getAiGenerationRules({
    String? educationalLevelId,
    String? subjectId,
    bool? isActive,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (educationalLevelId != null) {
        filters['educational_level_id'] = educationalLevelId;
      }
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (isActive != null) filters['is_active'] = isActive;

      final data = await _remoteDataSource.getAiGenerationRules(filters);
      final entities = data
          .map((e) => AiGenerationRuleModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AiGenerationRule>> createAiGenerationRule(
    AiGenerationRule rule,
  ) async {
    try {
      final model = AiGenerationRuleModel.fromEntity(rule);
      final data =
          await _remoteDataSource.createAiGenerationRule(model.toJson());
      return Success(AiGenerationRuleModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AiGenerationRule>> updateAiGenerationRule(
    AiGenerationRule rule,
  ) async {
    try {
      final model = AiGenerationRuleModel.fromEntity(rule);
      final data =
          await _remoteDataSource.updateAiGenerationRule(rule.id, model.toJson());
      return Success(AiGenerationRuleModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Answer Repository
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AnswerRepositoryEntry>> getAnswerRepositoryEntry(
    String contentItemId,
  ) async {
    try {
      final data = await _remoteDataSource.getAnswerEntry(contentItemId);
      return Success(AnswerRepositoryEntryModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AnswerRepositoryEntry>> createAnswerEntry(
    AnswerRepositoryEntry entry,
  ) async {
    try {
      final model = AnswerRepositoryEntryModel.fromEntity(entry);
      final data = await _remoteDataSource.createAnswerEntry(model.toJson());
      return Success(AnswerRepositoryEntryModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AnswerRepositoryEntry>> updateAnswerEntry(
    AnswerRepositoryEntry entry,
  ) async {
    try {
      final model = AnswerRepositoryEntryModel.fromEntity(entry);
      final data =
          await _remoteDataSource.updateAnswerEntry(entry.id, model.toJson());
      return Success(AnswerRepositoryEntryModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AnswerRepositoryEntry>> verifyAnswer({
    required String entryId,
    required String verifiedBy,
  }) async {
    try {
      final data = await _remoteDataSource.verifyAnswer({
        'entry_id': entryId,
        'verified_by': verifiedBy,
      });
      return Success(AnswerRepositoryEntryModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Stats
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CcmsStats>> getCcmsStats({
    String? schoolId,
    String? educationalLevelId,
    String? subjectId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (schoolId != null) params['school_id'] = schoolId;
      if (educationalLevelId != null) {
        params['educational_level_id'] = educationalLevelId;
      }
      if (subjectId != null) params['subject_id'] = subjectId;

      final data = await _remoteDataSource.getCcmsStats(params);
      return Success(CcmsStatsModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Audit
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AuditEntry>> recordAuditEvent(AuditEntry entry) async {
    try {
      final model = AuditEntryModel.fromEntity(entry);
      final data = await _remoteDataSource.recordAuditEvent(model.toJson());
      return Success(AuditEntryModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
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
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (userId != null) filters['user_id'] = userId;
      if (schoolId != null) filters['school_id'] = schoolId;
      if (action != null) filters['action'] = action.value;
      if (resourceType != null) filters['resource_type'] = resourceType;
      if (resourceId != null) filters['resource_id'] = resourceId;

      final data = await _remoteDataSource.getAuditTrail(filters);
      final entities =
          data.map((e) => AuditEntryModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MFA
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<MfaConfiguration>> getMfaConfig(String userId) async {
    try {
      final data = await _remoteDataSource.getMfaConfig(userId);
      return Success(MfaConfigurationModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<MfaConfiguration>> enableMfa({
    required String userId,
    required MfaMethod method,
    String? phoneNumber,
  }) async {
    try {
      final data = await _remoteDataSource.enableMfa({
        'user_id': userId,
        'method': method.value,
        'phone_number': phoneNumber,
      });
      return Success(MfaConfigurationModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> disableMfa({
    required String userId,
    required String verificationCode,
  }) async {
    try {
      await _remoteDataSource.disableMfa({
        'user_id': userId,
        'verification_code': verificationCode,
      });
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> verifyMfa({
    required String userId,
    required String verificationCode,
  }) async {
    try {
      final result = await _remoteDataSource.verifyMfa({
        'user_id': userId,
        'verification_code': verificationCode,
      });
      return Success(result);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // API Keys
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ApiKey>> createApiKey({
    required String userId,
    required String name,
    String? schoolId,
    List<String>? scopes,
    int? rateLimitOverride,
    DateTime? expiresAt,
  }) async {
    try {
      final data = await _remoteDataSource.createApiKey({
        'user_id': userId,
        'name': name,
        'school_id': schoolId,
        'scopes': scopes,
        'rate_limit_override': rateLimitOverride,
        'expires_at': expiresAt?.toIso8601String(),
      });
      return Success(ApiKeyModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> revokeApiKey(String apiKeyId) async {
    try {
      await _remoteDataSource.revokeApiKey(apiKeyId);
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ApiKey>>> getApiKeys(String userId) async {
    try {
      final data = await _remoteDataSource.getApiKeys(userId);
      final entities =
          data.map((e) => ApiKeyModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Security
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SecurityEvent>> recordSecurityEvent(SecurityEvent event) async {
    try {
      final model = SecurityEventModel.fromEntity(event);
      final data = await _remoteDataSource.recordSecurityEvent(model.toJson());
      return Success(SecurityEventModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<SecurityEvent>>> getSecurityEvents({
    String? userId,
    String? schoolId,
    AlertSeverity? severity,
    bool? isResolved,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (userId != null) filters['user_id'] = userId;
      if (schoolId != null) filters['school_id'] = schoolId;
      if (severity != null) filters['severity'] = severity.value;
      if (isResolved != null) filters['is_resolved'] = isResolved;

      final data = await _remoteDataSource.getSecurityEvents(filters);
      final entities = data
          .map((e) => SecurityEventModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> checkRateLimit({
    required RateLimitScope scope,
    required String identifier,
    String? endpointPattern,
  }) async {
    try {
      final result = await _remoteDataSource.checkRateLimit({
        'scope': scope.value,
        'identifier': identifier,
        if (endpointPattern != null) 'endpoint_pattern': endpointPattern,
      });
      return Success(result);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Sessions
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<UserSession>>> getUserSessions(String userId) async {
    try {
      final data = await _remoteDataSource.getUserSessions(userId);
      final entities =
          data.map((e) => UserSessionModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> invalidateUserSessions({
    required String userId,
    required String sessionId,
  }) async {
    try {
      await _remoteDataSource.invalidateUserSessions({
        'user_id': userId,
        'session_id': sessionId,
      });
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> invalidateAllOtherSessions({
    required String userId,
    required String currentSessionId,
  }) async {
    try {
      await _remoteDataSource.invalidateAllOtherSessions({
        'user_id': userId,
        'current_session_id': currentSessionId,
      });
      return const Success(true);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Monitoring
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SystemMetric>> recordMetric(SystemMetric metric) async {
    try {
      final model = SystemMetricModel.fromEntity(metric);
      final data = await _remoteDataSource.recordMetric(model.toJson());
      return Success(SystemMetricModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<SystemMetric>>> getSystemMetrics({
    String? metricName,
    MetricType? metricType,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final filters = <String, dynamic>{'limit': limit};
      if (metricName != null) filters['metric_name'] = metricName;
      if (metricType != null) filters['metric_type'] = metricType.value;
      if (schoolId != null) filters['school_id'] = schoolId;

      final data = await _remoteDataSource.getSystemMetrics(filters);
      final entities =
          data.map((e) => SystemMetricModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<AlertRule>>> getAlertRules({
    bool? isActive,
    AlertSeverity? severity,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (isActive != null) filters['is_active'] = isActive;
      if (severity != null) filters['severity'] = severity.value;

      final data = await _remoteDataSource.getAlertRules(filters);
      final entities =
          data.map((e) => AlertRuleModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AlertRule>> createAlertRule(AlertRule rule) async {
    try {
      final model = AlertRuleModel.fromEntity(rule);
      final data = await _remoteDataSource.createAlertRule(model.toJson());
      return Success(AlertRuleModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<AlertIncident>>> getAlertIncidents({
    String? alertRuleId,
    String? status,
    AlertSeverity? severity,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (alertRuleId != null) filters['alert_rule_id'] = alertRuleId;
      if (status != null) filters['status'] = status;
      if (severity != null) filters['severity'] = severity.value;

      final data = await _remoteDataSource.getAlertIncidents(filters);
      final entities = data
          .map((e) => AlertIncidentModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AlertIncident>> acknowledgeAlert({
    required String incidentId,
    required String acknowledgedBy,
  }) async {
    try {
      final data = await _remoteDataSource.acknowledgeAlert({
        'incident_id': incidentId,
        'acknowledged_by': acknowledgedBy,
      });
      return Success(AlertIncidentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<AlertIncident>> resolveAlert({
    required String incidentId,
    required String resolutionNotes,
  }) async {
    try {
      final data = await _remoteDataSource.resolveAlert({
        'incident_id': incidentId,
        'resolution_notes': resolutionNotes,
      });
      return Success(AlertIncidentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Performance
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<PerformanceLog>> recordPerformanceLog(PerformanceLog log) async {
    try {
      final model = PerformanceLogModel.fromEntity(log);
      final data = await _remoteDataSource.recordPerformanceLog(model.toJson());
      return Success(PerformanceLogModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
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
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (operationType != null) filters['operation_type'] = operationType;
      if (operationName != null) filters['operation_name'] = operationName;
      if (isSlow != null) filters['is_slow'] = isSlow;
      if (userId != null) filters['user_id'] = userId;
      if (schoolId != null) filters['school_id'] = schoolId;

      final data = await _remoteDataSource.getPerformanceLogs(filters);
      final entities = data
          .map((e) => PerformanceLogModel.fromJson(e).toEntity())
          .toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Errors
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ErrorReport>> reportError(ErrorReport report) async {
    try {
      final model = ErrorReportModel.fromEntity(report);
      final data = await _remoteDataSource.reportError(model.toJson());
      return Success(ErrorReportModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<ErrorReport>>> getErrorReports({
    String? errorType,
    bool? isResolved,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (errorType != null) filters['error_type'] = errorType;
      if (isResolved != null) filters['is_resolved'] = isResolved;
      if (schoolId != null) filters['school_id'] = schoolId;

      final data = await _remoteDataSource.getErrorReports(filters);
      final entities =
          data.map((e) => ErrorReportModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<ErrorReport>> resolveError({
    required String errorId,
    required String resolvedBy,
  }) async {
    try {
      final data = await _remoteDataSource.resolveError({
        'error_id': errorId,
        'resolved_by': resolvedBy,
      });
      return Success(ErrorReportModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Deployments
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<Deployment>>> getDeployments({
    String? environment,
    DeploymentStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (environment != null) filters['environment'] = environment;
      if (status != null) filters['status'] = status.value;

      final data = await _remoteDataSource.getDeployments(filters);
      final entities =
          data.map((e) => DeploymentModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Deployment>> createDeployment(Deployment deployment) async {
    try {
      final model = DeploymentModel.fromEntity(deployment);
      final data = await _remoteDataSource.createDeployment(model.toJson());
      return Success(DeploymentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<Deployment>> updateDeploymentStatus({
    required String deploymentId,
    required DeploymentStatus status,
    String? notes,
  }) async {
    try {
      final data = await _remoteDataSource.updateDeploymentStatus({
        'deployment_id': deploymentId,
        'status': status.value,
        if (notes != null) 'notes': notes,
      });
      return Success(DeploymentModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Testing
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TestResult>> recordTestResult(TestResult result) async {
    try {
      final model = TestResultModel.fromEntity(result);
      final data = await _remoteDataSource.recordTestResult(model.toJson());
      return Success(TestResultModel.fromJson(data).toEntity());
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }

  @override
  Future<Result<List<TestResult>>> getTestResults({
    TestType? testType,
    String? deploymentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final filters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (testType != null) filters['test_type'] = testType.value;
      if (deploymentId != null) filters['deployment_id'] = deploymentId;
      if (status != null) filters['status'] = status;

      final data = await _remoteDataSource.getTestResults(filters);
      final entities =
          data.map((e) => TestResultModel.fromJson(e).toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return FailureResult(_mapException(e));
    }
  }
}
