import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';

/// Abstract contract for all question bank operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class QuestionBankRepository {
  // ─── CRUD ──────────────────────────────────────────────────────────

  /// Creates a new question and returns the persisted entity.
  Future<Result<QuestionEntity>> createQuestion(QuestionEntity question);

  /// Updates an existing question and returns the updated entity.
  Future<Result<QuestionEntity>> updateQuestion(QuestionEntity question);

  /// Permanently deletes a question by [questionId].
  Future<Result<void>> deleteQuestion(String questionId);

  /// Retrieves a question by [questionId] without related details.
  Future<Result<QuestionEntity>> getQuestion(String questionId);

  /// Retrieves a question by [questionId] with all related details
  /// (answer options, matching pairs, ordering items, fill-in-blank
  /// answers, attachments, and tags).
  Future<Result<QuestionEntity>> getQuestionWithDetails(String questionId);

  /// Retrieves a filtered list of questions based on [filter].
  Future<Result<List<QuestionEntity>>> getQuestions(
    QuestionFilterEntity filter,
  );

  /// Returns the total count of questions matching [filter].
  Future<Result<int>> getQuestionCount(QuestionFilterEntity filter);

  // ─── Status Management ─────────────────────────────────────────────

  /// Publishes a draft question so it becomes visible to students.
  Future<Result<void>> publishQuestion(String questionId);

  /// Archives a question, hiding it from active lists.
  Future<Result<void>> archiveQuestion(String questionId);

  /// Restores an archived question back to active status.
  Future<Result<void>> restoreQuestion(String questionId);

  /// Creates a deep copy of a question with a new ID and resets
  /// version to 1, returning the duplicated entity.
  Future<Result<QuestionEntity>> duplicateQuestion(String questionId);

  /// Moves a batch of questions to a new topic and/or category.
  Future<Result<void>> moveQuestions(
    List<String> questionIds, {
    String? topicId,
    String? categoryId,
  });

  // ─── Answer Options ────────────────────────────────────────────────

  /// Retrieves all answer options for a question.
  Future<Result<List<AnswerOptionEntity>>> getAnswerOptions(
    String questionId,
  );

  /// Replaces all answer options for a question with [options].
  Future<Result<List<AnswerOptionEntity>>> updateAnswerOptions(
    String questionId,
    List<AnswerOptionEntity> options,
  );

  // ─── Tags ──────────────────────────────────────────────────────────

  /// Retrieves tags, optionally filtered by [schoolId] or [searchQuery].
  Future<Result<List<QuestionTagEntity>>> getTags({
    String? schoolId,
    String? searchQuery,
  });

  /// Creates a new tag.
  Future<Result<QuestionTagEntity>> createTag(QuestionTagEntity tag);

  /// Associates one or more tags with a question.
  Future<Result<void>> addTagsToQuestion(
    String questionId,
    List<String> tagIds,
  );

  /// Removes a single tag association from a question.
  Future<Result<void>> removeTagFromQuestion(
    String questionId,
    String tagId,
  );

  // ─── Favorites ─────────────────────────────────────────────────────

  /// Toggles the favorite status of a question for the current user.
  Future<Result<void>> toggleFavorite(String questionId);

  /// Retrieves the current user's favorited questions with pagination.
  Future<Result<List<QuestionEntity>>> getFavorites({
    int page = 1,
    int perPage = 20,
  });

  /// Returns whether [questionId] is favorited by the current user.
  Future<Result<bool>> isFavorite(String questionId);

  // ─── Collections ───────────────────────────────────────────────────

  /// Creates a new question collection.
  Future<Result<QuestionCollectionEntity>> createCollection(
    QuestionCollectionEntity collection,
  );

  /// Updates an existing question collection.
  Future<Result<QuestionCollectionEntity>> updateCollection(
    QuestionCollectionEntity collection,
  );

  /// Deletes a question collection by [collectionId].
  Future<Result<void>> deleteCollection(String collectionId);

  /// Retrieves collections, optionally filtered by [schoolId],
  /// [createdBy], or [isShared].
  Future<Result<List<QuestionCollectionEntity>>> getCollections({
    String? schoolId,
    String? createdBy,
    bool? isShared,
  });

  /// Adds a question to a collection.
  Future<Result<void>> addQuestionToCollection(
    String collectionId,
    String questionId,
  );

  /// Removes a question from a collection.
  Future<Result<void>> removeQuestionFromCollection(
    String collectionId,
    String questionId,
  );

  /// Retrieves questions within a collection with pagination.
  Future<Result<List<QuestionEntity>>> getCollectionQuestions(
    String collectionId, {
    int page = 1,
    int perPage = 20,
  });

  // ─── Sharing ───────────────────────────────────────────────────────

  /// Shares a question with another user.
  ///
  /// [permission] is one of: 'read', 'edit', 'admin'.
  Future<Result<void>> shareQuestion(
    String questionId,
    String sharedWith, {
    String permission = 'read',
    String? message,
  });

  /// Removes a share record by [shareId].
  Future<Result<void>> removeShare(String shareId);

  /// Retrieves questions shared with a specific user.
  Future<Result<List<QuestionShareEntity>>> getSharedQuestions({
    String? sharedWith,
  });

  // ─── Import / Export ───────────────────────────────────────────────

  /// Starts an asynchronous import job and returns the job entity.
  Future<Result<QuestionImportEntity>> startImport(
    QuestionImportEntity importJob,
  );

  /// Retrieves the current status of an import job.
  Future<Result<QuestionImportEntity>> getImportStatus(String importId);

  /// Starts an asynchronous export job and returns the job entity.
  Future<Result<QuestionExportEntity>> startExport(
    QuestionExportEntity exportJob,
  );

  /// Retrieves the current status of an export job.
  Future<Result<QuestionExportEntity>> getExportStatus(String exportId);

  // ─── Search ────────────────────────────────────────────────────────

  /// Full-text search across questions, further refined by [filter].
  Future<Result<List<QuestionEntity>>> searchQuestions(
    String query,
    QuestionFilterEntity filter,
  );

  // ─── Stats ─────────────────────────────────────────────────────────

  /// Retrieves aggregated question bank statistics.
  Future<Result<QuestionBankStatsEntity>> getStats({String? schoolId});

  /// Retrieves all topics for a given [subjectId].
  Future<Result<List<TopicEntity>>> getTopics(String subjectId);

  /// Retrieves all subtopics for a given [topicId].
  Future<Result<List<SubtopicEntity>>> getSubtopics(String topicId);

  /// Retrieves question categories, optionally filtered by [schoolId].
  Future<Result<List<QuestionCategoryEntity>>> getCategories({
    String? schoolId,
  });

  /// Retrieves academic sessions, optionally filtered by [schoolId].
  Future<Result<List<AcademicSessionEntity>>> getAcademicSessions({
    String? schoolId,
  });

  // ─── Version History ───────────────────────────────────────────────

  /// Retrieves the full version history for a question.
  Future<Result<List<QuestionVersionEntity>>> getVersionHistory(
    String questionId,
  );

  /// Restores a question to a specific [version], creating a new
  /// version entry.
  Future<Result<QuestionEntity>> restoreVersion(
    String questionId,
    int version,
  );
}
