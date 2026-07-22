import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';
import '../models/question_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote question bank data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class QuestionBankRemoteDataSource {
  // ─── CRUD ──────────────────────────────────────────────────────────

  Future<QuestionModel> createQuestion(Map<String, dynamic> questionData);
  Future<QuestionModel> updateQuestion(
    String questionId,
    Map<String, dynamic> questionData,
  );
  Future<void> deleteQuestion(String questionId);
  Future<QuestionModel> getQuestion(String questionId);
  Future<Map<String, dynamic>> getQuestionWithDetails(String questionId);
  Future<List<QuestionModel>> getQuestions(Map<String, dynamic> filters);
  Future<int> getQuestionCount(Map<String, dynamic> filters);

  // ─── Status Management ─────────────────────────────────────────────

  Future<void> publishQuestion(String questionId);
  Future<void> archiveQuestion(String questionId);
  Future<void> restoreQuestion(String questionId);
  Future<QuestionModel> duplicateQuestion(String questionId);
  Future<void> moveQuestions(
    List<String> questionIds,
    Map<String, dynamic> target,
  );

  // ─── Answer Options ────────────────────────────────────────────────

  Future<List<AnswerOptionModel>> getAnswerOptions(String questionId);
  Future<List<AnswerOptionModel>> updateAnswerOptions(
    String questionId,
    List<Map<String, dynamic>> options,
  );

  // ─── Tags ──────────────────────────────────────────────────────────

  Future<List<QuestionTagModel>> getTags({
    String? schoolId,
    String? searchQuery,
  });
  Future<QuestionTagModel> createTag(Map<String, dynamic> tagData);
  Future<void> addTagsToQuestion(String questionId, List<String> tagIds);
  Future<void> removeTagFromQuestion(String questionId, String tagId);

  // ─── Favorites ─────────────────────────────────────────────────────

  Future<void> toggleFavorite(String questionId);
  Future<List<QuestionModel>> getFavorites({
    int page = 1,
    int perPage = 20,
  });
  Future<bool> isFavorite(String questionId);

  // ─── Collections ───────────────────────────────────────────────────

  Future<QuestionCollectionModel> createCollection(
    Map<String, dynamic> collectionData,
  );
  Future<QuestionCollectionModel> updateCollection(
    String collectionId,
    Map<String, dynamic> collectionData,
  );
  Future<void> deleteCollection(String collectionId);
  Future<List<QuestionCollectionModel>> getCollections({
    String? schoolId,
    String? createdBy,
    bool? isShared,
  });
  Future<void> addQuestionToCollection(
    String collectionId,
    String questionId,
  );
  Future<void> removeQuestionFromCollection(
    String collectionId,
    String questionId,
  );
  Future<List<QuestionModel>> getCollectionQuestions(
    String collectionId, {
    int page = 1,
    int perPage = 20,
  });

  // ─── Sharing ───────────────────────────────────────────────────────

  Future<void> shareQuestion(
    String questionId,
    Map<String, dynamic> shareData,
  );
  Future<void> removeShare(String shareId);
  Future<List<QuestionShareModel>> getSharedQuestions({
    String? sharedWith,
  });

  // ─── Import / Export ───────────────────────────────────────────────

  Future<QuestionImportModel> startImport(Map<String, dynamic> importData);
  Future<QuestionImportModel> getImportStatus(String importId);
  Future<QuestionExportModel> startExport(Map<String, dynamic> exportData);
  Future<QuestionExportModel> getExportStatus(String exportId);

  // ─── Search ────────────────────────────────────────────────────────

  Future<List<QuestionModel>> searchQuestions(
    String query,
    Map<String, dynamic> filters,
  );

  // ─── Stats ─────────────────────────────────────────────────────────

  Future<QuestionBankStatsModel> getStats({String? schoolId});

  // ─── Reference Data ────────────────────────────────────────────────

  Future<List<TopicModel>> getTopics(String subjectId);
  Future<List<SubtopicModel>> getSubtopics(String topicId);
  Future<List<QuestionCategoryModel>> getCategories({String? schoolId});
  Future<List<AcademicSessionModel>> getAcademicSessions({String? schoolId});

  // ─── Version History ───────────────────────────────────────────────

  Future<List<QuestionVersionModel>> getVersionHistory(String questionId);
  Future<QuestionModel> restoreVersion(String questionId, int version);
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Supabase-backed implementation of [QuestionBankRemoteDataSource].
///
/// Every method maps Supabase-specific responses and errors into the
/// domain-agnostic types defined in the data layer. Supabase
/// [sb.PostgrestException] instances are converted to our custom
/// exceptions with user-friendly messages.
class QuestionBankRemoteDataSourceImpl
    implements QuestionBankRemoteDataSource {
  QuestionBankRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ───────────────────────────────────────────────────
  static const _questionsTable = 'question_bank';
  static const _answerOptionsTable = 'answer_options';
  static const _matchingPairsTable = 'matching_pairs';
  static const _orderingItemsTable = 'ordering_items';
  static const _fillInBlankTable = 'fill_in_blank_answers';
  static const _attachmentsTable = 'question_attachments';
  static const _tagsTable = 'question_tags';
  static const _tagRelationsTable = 'question_tag_relations';
  static const _collectionsTable = 'question_collections';
  static const _collectionQuestionsTable = 'collection_questions';
  static const _favoritesTable = 'question_favorites';
  static const _sharesTable = 'question_shares';
  static const _versionHistoryTable = 'question_version_history';
  static const _importsTable = 'question_imports';
  static const _exportsTable = 'question_exports';
  static const _topicsTable = 'topics';
  static const _subtopicsTable = 'subtopics';
  static const _categoriesTable = 'question_categories';
  static const _academicSessionsTable = 'academic_sessions';

  // ═══════════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QuestionModel> createQuestion(
    Map<String, dynamic> questionData,
  ) async {
    try {
      final response =
          await _supabase.from(_questionsTable).insert(questionData).select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Question creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Question created: ${response.first['id']}');
      return QuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to create question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionModel> updateQuestion(
    String questionId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      questionData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_questionsTable)
          .update(questionData)
          .eq('id', questionId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Question not found for update.');
      }

      AppLogger.info('Question updated: $questionId');
      return QuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to update question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _supabase
          .from(_questionsTable)
          .delete()
          .eq('id', questionId);

      AppLogger.info('Question deleted: $questionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to delete question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionModel> getQuestion(String questionId) async {
    try {
      final response = await _supabase
          .from(_questionsTable)
          .select()
          .eq('id', questionId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Question not found.');
      }

      return QuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getQuestionWithDetails(
    String questionId,
  ) async {
    try {
      // Fetch the base question
      final questionResponse = await _supabase
          .from(_questionsTable)
          .select()
          .eq('id', questionId)
          .limit(1);

      if (questionResponse.isEmpty) {
        throw const NotFoundException(message: 'Question not found.');
      }

      final questionJson = Map<String, dynamic>.from(questionResponse.first);

      // Fetch related data in parallel
      final results = await Future.wait([
        _supabase
            .from(_answerOptionsTable)
            .select()
            .eq('question_id', questionId)
            .order('sort_order'),
        _supabase
            .from(_matchingPairsTable)
            .select()
            .eq('question_id', questionId)
            .order('sort_order'),
        _supabase
            .from(_orderingItemsTable)
            .select()
            .eq('question_id', questionId)
            .order('correct_position'),
        _supabase
            .from(_fillInBlankTable)
            .select()
            .eq('question_id', questionId)
            .order('blank_index'),
        _supabase
            .from(_attachmentsTable)
            .select()
            .eq('question_id', questionId)
            .order('sort_order'),
        // Tags need a join through the relation table
        _supabase
            .from(_tagRelationsTable)
            .select('question_tags(*)')
            .eq('question_id', questionId),
      ]);

      questionJson['answer_options'] = results[0] as List;
      questionJson['matching_pairs'] = results[1] as List;
      questionJson['ordering_items'] = results[2] as List;
      questionJson['fill_in_blank_answers'] = results[3] as List;
      questionJson['question_attachments'] = results[4] as List;

      // Flatten tag join results
      final tagRows = results[5] as List;
      final tagList = tagRows
          .map((row) => row['question_tags'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .toList();
      questionJson['question_tags'] = tagList;

      return questionJson;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getQuestionWithDetails error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve question details.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionModel>> getQuestions(
    Map<String, dynamic> filters,
  ) async {
    try {
      final filterQuery = _applyFilters(_supabase.from(_questionsTable).select(), filters);
      var transformQuery = _applySorting(filterQuery, filters['sort_by'] as String?);
      transformQuery = _applyPagination(
        transformQuery,
        page: filters['page'] as int?,
        perPage: filters['per_page'] as int?,
      );

      final response = await transformQuery;
      return response
          .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve questions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getQuestionCount(Map<String, dynamic> filters) async {
    try {
      final filterQuery = _applyFilters(
        _supabase.from(_questionsTable).select('id'),
        filters,
      );

      final response = await filterQuery;
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getQuestionCount error', error: e);
      throw const ServerException(
        message: 'Failed to count questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATUS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> publishQuestion(String questionId) async {
    try {
      await _supabase
          .from(_questionsTable)
          .update({
            'is_published': true,
            'is_archived': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questionId);

      AppLogger.info('Question published: $questionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected publishQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to publish question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> archiveQuestion(String questionId) async {
    try {
      await _supabase
          .from(_questionsTable)
          .update({
            'is_archived': true,
            'is_published': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questionId);

      AppLogger.info('Question archived: $questionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected archiveQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to archive question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> restoreQuestion(String questionId) async {
    try {
      await _supabase
          .from(_questionsTable)
          .update({
            'is_archived': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questionId);

      AppLogger.info('Question restored: $questionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected restoreQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to restore question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionModel> duplicateQuestion(String questionId) async {
    try {
      // Fetch the original question
      final original = await getQuestion(questionId);

      // Prepare the duplicate data (strip ID, reset version)
      final duplicateData = original.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at')
        ..['version'] = 1
        ..['parent_id'] = original.id
        ..['is_published'] = false
        ..['is_archived'] = false
        ..['usage_count'] = 0
        ..['avg_score'] = 0.0;

      return createQuestion(duplicateData);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected duplicateQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to duplicate question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> moveQuestions(
    List<String> questionIds,
    Map<String, dynamic> target,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (target.containsKey('topic_id')) {
        updateData['topic_id'] = target['topic_id'];
      }
      if (target.containsKey('category_id')) {
        updateData['category_id'] = target['category_id'];
      }

      for (final id in questionIds) {
        await _supabase
            .from(_questionsTable)
            .update(updateData)
            .eq('id', id);
      }

      AppLogger.info('Moved ${questionIds.length} questions');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected moveQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to move questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANSWER OPTIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<AnswerOptionModel>> getAnswerOptions(
    String questionId,
  ) async {
    try {
      final response = await _supabase
          .from(_answerOptionsTable)
          .select()
          .eq('question_id', questionId)
          .order('sort_order');

      return response
          .map((json) =>
              AnswerOptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAnswerOptions error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve answer options.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AnswerOptionModel>> updateAnswerOptions(
    String questionId,
    List<Map<String, dynamic>> options,
  ) async {
    try {
      // Delete existing options
      await _supabase
          .from(_answerOptionsTable)
          .delete()
          .eq('question_id', questionId);

      // Insert new options
      if (options.isNotEmpty) {
        final optionsData = options
            .map((o) => {
                  ...o,
                  'question_id': questionId,
                })
            .toList();

        await _supabase
            .from(_answerOptionsTable)
            .insert(optionsData);
      }

      // Fetch the newly inserted options
      return getAnswerOptions(questionId);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected updateAnswerOptions error', error: e);
      throw const ServerException(
        message: 'Failed to update answer options.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<QuestionTagModel>> getTags({
    String? schoolId,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from(_tagsTable).select();

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // PERF: Use PaginatedQueryMixin constant instead of magic number
      final response = await query.order('usage_count', ascending: false).limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map((json) =>
              QuestionTagModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTags error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve tags.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionTagModel> createTag(Map<String, dynamic> tagData) async {
    try {
      final response =
          await _supabase.from(_tagsTable).insert(tagData).select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Tag creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Tag created: ${response.first['id']}');
      return QuestionTagModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createTag error', error: e);
      throw const ServerException(
        message: 'Failed to create tag.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> addTagsToQuestion(
    String questionId,
    List<String> tagIds,
  ) async {
    try {
      final relations = tagIds
          .map((tagId) => {
                'question_id': questionId,
                'tag_id': tagId,
              })
          .toList();

      await _supabase.from(_tagRelationsTable).insert(relations);
      AppLogger.info(
        'Added ${tagIds.length} tags to question: $questionId',
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected addTagsToQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to add tags to question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeTagFromQuestion(
    String questionId,
    String tagId,
  ) async {
    try {
      await _supabase
          .from(_tagRelationsTable)
          .delete()
          .eq('question_id', questionId)
          .eq('tag_id', tagId);

      AppLogger.info(
        'Removed tag $tagId from question: $questionId',
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected removeTagFromQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to remove tag from question.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> toggleFavorite(String questionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw const UnauthorizedException(message: 'User not authenticated.');
      }

      // Check if already favorited
      final existing = await _supabase
          .from(_favoritesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('question_id', questionId);

      if (existing.isNotEmpty) {
        // Remove favorite
        await _supabase
            .from(_favoritesTable)
            .delete()
            .eq('user_id', userId)
            .eq('question_id', questionId);
        AppLogger.info('Removed favorite: $questionId');
      } else {
        // Add favorite
        await _supabase.from(_favoritesTable).insert({
          'user_id': userId,
          'question_id': questionId,
        });
        AppLogger.info('Added favorite: $questionId');
      }
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected toggleFavorite error', error: e);
      throw const ServerException(
        message: 'Failed to toggle favorite.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionModel>> getFavorites({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw const UnauthorizedException(message: 'User not authenticated.');
      }

      final offset = (page - 1) * perPage;

      // Join through favorites to get questions
      final response = await _supabase
          .from(_favoritesTable)
          .select('$_questionsTable(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + perPage - 1);

      return response
          .map((row) {
            final questionData =
                row[_questionsTable] as Map<String, dynamic>?;
            if (questionData == null) return null;
            return QuestionModel.fromJson(questionData);
          })
          .whereType<QuestionModel>()
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getFavorites error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve favorites.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> isFavorite(String questionId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final response = await _supabase
          .from(_favoritesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('question_id', questionId);

      return response.isNotEmpty;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected isFavorite error', error: e);
      throw const ServerException(
        message: 'Failed to check favorite status.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QuestionCollectionModel> createCollection(
    Map<String, dynamic> collectionData,
  ) async {
    try {
      final response = await _supabase
          .from(_collectionsTable)
          .insert(collectionData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Collection creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Collection created: ${response.first['id']}');
      return QuestionCollectionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createCollection error', error: e);
      throw const ServerException(
        message: 'Failed to create collection.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionCollectionModel> updateCollection(
    String collectionId,
    Map<String, dynamic> collectionData,
  ) async {
    try {
      collectionData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_collectionsTable)
          .update(collectionData)
          .eq('id', collectionId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Collection not found for update.');
      }

      AppLogger.info('Collection updated: $collectionId');
      return QuestionCollectionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateCollection error', error: e);
      throw const ServerException(
        message: 'Failed to update collection.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    try {
      await _supabase
          .from(_collectionsTable)
          .delete()
          .eq('id', collectionId);

      AppLogger.info('Collection deleted: $collectionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected deleteCollection error', error: e);
      throw const ServerException(
        message: 'Failed to delete collection.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionCollectionModel>> getCollections({
    String? schoolId,
    String? createdBy,
    bool? isShared,
  }) async {
    try {
      var filterQuery = _supabase.from(_collectionsTable).select();

      if (schoolId != null) {
        filterQuery = filterQuery.eq('school_id', schoolId);
      }
      if (createdBy != null) {
        filterQuery = filterQuery.eq('created_by', createdBy);
      }
      if (isShared != null) {
        filterQuery = filterQuery.eq('is_shared', isShared);
      }

      filterQuery = filterQuery.eq('is_active', true);
      var transformQuery = filterQuery.order('sort_order');

      // PERF: Added limit to prevent unbounded query on question_collections
      final response = await transformQuery.limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map((json) => QuestionCollectionModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCollections error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve collections.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> addQuestionToCollection(
    String collectionId,
    String questionId,
  ) async {
    try {
      await _supabase.from(_collectionQuestionsTable).insert({
        'collection_id': collectionId,
        'question_id': questionId,
      });

      AppLogger.info(
        'Added question $questionId to collection $collectionId',
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected addQuestionToCollection error', error: e);
      throw const ServerException(
        message: 'Failed to add question to collection.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeQuestionFromCollection(
    String collectionId,
    String questionId,
  ) async {
    try {
      await _supabase
          .from(_collectionQuestionsTable)
          .delete()
          .eq('collection_id', collectionId)
          .eq('question_id', questionId);

      AppLogger.info(
        'Removed question $questionId from collection $collectionId',
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error(
        'Unexpected removeQuestionFromCollection error',
        error: e,
      );
      throw const ServerException(
        message: 'Failed to remove question from collection.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionModel>> getCollectionQuestions(
    String collectionId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final offset = (page - 1) * perPage;

      final response = await _supabase
          .from(_collectionQuestionsTable)
          .select('$_questionsTable(*)')
          .eq('collection_id', collectionId)
          .order('sort_order')
          .range(offset, offset + perPage - 1);

      return response
          .map((row) {
            final questionData =
                row[_questionsTable] as Map<String, dynamic>?;
            if (questionData == null) return null;
            return QuestionModel.fromJson(questionData);
          })
          .whereType<QuestionModel>()
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCollectionQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve collection questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARING
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> shareQuestion(
    String questionId,
    Map<String, dynamic> shareData,
  ) async {
    try {
      await _supabase.from(_sharesTable).insert({
        'question_id': questionId,
        ...shareData,
      });

      AppLogger.info('Shared question: $questionId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected shareQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to share question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeShare(String shareId) async {
    try {
      await _supabase.from(_sharesTable).delete().eq('id', shareId);
      AppLogger.info('Removed share: $shareId');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected removeShare error', error: e);
      throw const ServerException(
        message: 'Failed to remove share.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionShareModel>> getSharedQuestions({
    String? sharedWith,
  }) async {
    try {
      var filterQuery = _supabase.from(_sharesTable).select();

      if (sharedWith != null) {
        filterQuery = filterQuery.eq('shared_with', sharedWith);
      }

      var transformQuery = filterQuery.order('created_at', ascending: false);

      // PERF: Added limit to prevent unbounded query on question_shares
      final response = await transformQuery.limit(PaginatedQueryMixin.defaultPageSize);
      return response
          .map((json) => QuestionShareModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSharedQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve shared questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // IMPORT / EXPORT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QuestionImportModel> startImport(
    Map<String, dynamic> importData,
  ) async {
    try {
      final response =
          await _supabase.from(_importsTable).insert(importData).select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Import creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Import started: ${response.first['id']}');
      return QuestionImportModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected startImport error', error: e);
      throw const ServerException(
        message: 'Failed to start import.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionImportModel> getImportStatus(String importId) async {
    try {
      final response = await _supabase
          .from(_importsTable)
          .select()
          .eq('id', importId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Import job not found.');
      }

      return QuestionImportModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getImportStatus error', error: e);
      throw const ServerException(
        message: 'Failed to get import status.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionExportModel> startExport(
    Map<String, dynamic> exportData,
  ) async {
    try {
      final response =
          await _supabase.from(_exportsTable).insert(exportData).select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Export creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Export started: ${response.first['id']}');
      return QuestionExportModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected startExport error', error: e);
      throw const ServerException(
        message: 'Failed to start export.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionExportModel> getExportStatus(String exportId) async {
    try {
      final response = await _supabase
          .from(_exportsTable)
          .select()
          .eq('id', exportId)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Export job not found.');
      }

      return QuestionExportModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getExportStatus error', error: e);
      throw const ServerException(
        message: 'Failed to get export status.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<QuestionModel>> searchQuestions(
    String query,
    Map<String, dynamic> filters,
  ) async {
    try {
      // Full-text search using Supabase text search, then apply additional filters
      final filterQuery = _applyFilters(
        _supabase.from(_questionsTable).select().textSearch(
          'content',
          query,
          config: 'english',
        ),
        filters,
      );
      var transformQuery = _applySorting(
        filterQuery,
        filters['sort_by'] as String?,
      );
      transformQuery = _applyPagination(
        transformQuery,
        page: filters['page'] as int?,
        perPage: filters['per_page'] as int?,
      );

      final response = await transformQuery;
      return response
          .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected searchQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to search questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QuestionBankStatsModel> getStats({String? schoolId}) async {
    try {
      // Base query builder
      var baseQuery = _supabase.from(_questionsTable).select();

      if (schoolId != null) {
        baseQuery = baseQuery.eq('school_id', schoolId);
      }

      // Fetch all questions for stats computation
      final allQuestions = await baseQuery;

      final totalQuestions = allQuestions.length;
      final publishedQuestions = allQuestions
          .where((q) => q['is_published'] == true)
          .length;
      final draftQuestions = allQuestions
          .where((q) => q['is_published'] == false && q['is_archived'] == false)
          .length;
      final archivedQuestions = allQuestions
          .where((q) => q['is_archived'] == true)
          .length;

      // Compute breakdowns
      final Map<String, int> bySubject = {};
      final Map<String, int> byDifficulty = {};
      final Map<String, int> byType = {};
      final Map<String, int> byExamType = {};

      for (final q in allQuestions) {
        final subjectId = q['subject_id'] as String?;
        if (subjectId != null) {
          bySubject[subjectId] = (bySubject[subjectId] ?? 0) + 1;
        }

        final diff = q['difficulty'] as String?;
        if (diff != null) {
          byDifficulty[diff] = (byDifficulty[diff] ?? 0) + 1;
        }

        final type = q['question_type'] as String?;
        if (type != null) {
          byType[type] = (byType[type] ?? 0) + 1;
        }

        final exam = q['exam_type'] as String?;
        if (exam != null) {
          byExamType[exam] = (byExamType[exam] ?? 0) + 1;
        }
      }

      // Recent questions (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentQuestions = allQuestions
          .where((q) {
            final createdAt = q['created_at'] as String?;
            if (createdAt == null) return false;
            return DateTime.parse(createdAt).isAfter(weekAgo);
          })
          .length;

      // Collection count
      var collectionQuery =
          _supabase.from(_collectionsTable).select('id');
      if (schoolId != null) {
        collectionQuery = collectionQuery.eq('school_id', schoolId);
      }
      final collections = await collectionQuery;

      // Favorites count for current user
      final userId = _currentUserId;
      int totalFavorites = 0;
      if (userId != null) {
        final favorites = await _supabase
            .from(_favoritesTable)
            .select('id')
            .eq('user_id', userId);
        totalFavorites = favorites.length;
      }

      // Most used questions (top 5)
      final sortedByUsage = List<Map<String, dynamic>>.from(allQuestions)
        ..sort((a, b) => (b['usage_count'] as int? ?? 0)
            .compareTo(a['usage_count'] as int? ?? 0));
      final mostUsed = sortedByUsage
          .take(5)
          .map((q) => QuestionModel.fromJson(q))
          .toList();

      return QuestionBankStatsModel(
        totalQuestions: totalQuestions,
        publishedQuestions: publishedQuestions,
        draftQuestions: draftQuestions,
        archivedQuestions: archivedQuestions,
        questionsBySubject: bySubject,
        questionsByDifficulty: byDifficulty,
        questionsByType: byType,
        questionsByExamType: byExamType,
        recentQuestions: recentQuestions,
        totalCollections: collections.length,
        totalFavorites: totalFavorites,
        mostUsedQuestions: mostUsed,
      );
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getStats error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve question bank stats.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REFERENCE DATA
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<TopicModel>> getTopics(String subjectId) async {
    try {
      final response = await _supabase
          .from(_topicsTable)
          .select()
          .eq('subject_id', subjectId)
          .eq('is_active', true)
          .order('sort_order');

      return response
          .map((json) =>
              TopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getTopics error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve topics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SubtopicModel>> getSubtopics(String topicId) async {
    try {
      final response = await _supabase
          .from(_subtopicsTable)
          .select()
          .eq('topic_id', topicId)
          .eq('is_active', true)
          .order('sort_order');

      return response
          .map((json) =>
              SubtopicModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getSubtopics error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve subtopics.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionCategoryModel>> getCategories({
    String? schoolId,
  }) async {
    try {
      var filterQuery = _supabase.from(_categoriesTable).select();

      if (schoolId != null) {
        filterQuery = filterQuery.eq('school_id', schoolId);
      }

      filterQuery = filterQuery.eq('is_active', true);
      var transformQuery = filterQuery.order('sort_order');

      // PERF: Added limit to prevent unbounded query on question_categories
      final response = await transformQuery.limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map((json) => QuestionCategoryModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCategories error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve categories.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AcademicSessionModel>> getAcademicSessions({
    String? schoolId,
  }) async {
    try {
      var filterQuery = _supabase.from(_academicSessionsTable).select();

      if (schoolId != null) {
        filterQuery = filterQuery.eq('school_id', schoolId);
      }

      filterQuery = filterQuery.eq('is_active', true);
      var transformQuery = filterQuery.order('start_date');

      // PERF: Added limit to prevent unbounded query on academic_sessions
      final response = await transformQuery.limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map((json) => AcademicSessionModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getAcademicSessions error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve academic sessions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // VERSION HISTORY
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<QuestionVersionModel>> getVersionHistory(
    String questionId,
  ) async {
    try {
      // PERF: Added limit to prevent unbounded query on question_version_history
      final response = await _supabase
          .from(_versionHistoryTable)
          .select()
          .eq('question_id', questionId)
          .order('version', ascending: false)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response
          .map((json) => QuestionVersionModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getVersionHistory error', error: e);
      throw const ServerException(
        message: 'Failed to retrieve version history.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionModel> restoreVersion(
    String questionId,
    int version,
  ) async {
    try {
      // Fetch the version snapshot
      final versionResponse = await _supabase
          .from(_versionHistoryTable)
          .select()
          .eq('question_id', questionId)
          .eq('version', version)
          .limit(1);

      if (versionResponse.isEmpty) {
        throw NotFoundException(
          message: 'Version $version not found for question $questionId.',
        );
      }

      final versionData = versionResponse.first;
      final snapshot = versionData['snapshot'] as Map<String, dynamic>?;

      if (snapshot == null) {
        throw const ServerException(
          message: 'Version snapshot is empty.',
          statusCode: 500,
        );
      }

      // Update the question with the snapshot data
      final restoredData = Map<String, dynamic>.from(snapshot)
        ..remove('id')
        ..remove('created_at')
        ..['updated_at'] = DateTime.now().toIso8601String()
        ..['version'] = (await getQuestion(questionId)).version + 1;

      return updateQuestion(questionId, restoredData);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected restoreVersion error', error: e);
      throw const ServerException(
        message: 'Failed to restore question version.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Returns the currently authenticated user's ID, or null.
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Applies filter criteria from a filter map to a Supabase query.
  sb.PostgrestFilterBuilder<dynamic> _applyFilters(
    sb.PostgrestFilterBuilder<dynamic> query,
    Map<String, dynamic> filters,
  ) {
    var q = query;

    if (filters['subject_id'] != null) {
      q = q.eq('subject_id', filters['subject_id'] as String);
    }
    if (filters['topic_id'] != null) {
      q = q.eq('topic_id', filters['topic_id'] as String);
    }
    if (filters['subtopic_id'] != null) {
      q = q.eq('subtopic_id', filters['subtopic_id'] as String);
    }
    if (filters['class_id'] != null) {
      q = q.eq('class_id', filters['class_id'] as String);
    }
    if (filters['category_id'] != null) {
      q = q.eq('category_id', filters['category_id'] as String);
    }
    if (filters['difficulty'] != null) {
      q = q.eq('difficulty', filters['difficulty'] as String);
    }
    if (filters['question_type'] != null) {
      q = q.eq('question_type', filters['question_type'] as String);
    }
    if (filters['exam_type'] != null) {
      q = q.eq('exam_type', filters['exam_type'] as String);
    }
    if (filters['academic_session_id'] != null) {
      q = q.eq(
        'academic_session_id',
        filters['academic_session_id'] as String,
      );
    }
    if (filters['is_published'] != null) {
      q = q.eq('is_published', filters['is_published'] as bool);
    }
    if (filters['is_archived'] != null) {
      q = q.eq('is_archived', filters['is_archived'] as bool);
    }
    if (filters['is_featured'] != null) {
      q = q.eq('is_featured', filters['is_featured'] as bool);
    }
    if (filters['created_by'] != null) {
      q = q.eq('created_by', filters['created_by'] as String);
    }
    if (filters['school_id'] != null) {
      q = q.eq('school_id', filters['school_id'] as String);
    }

    return q;
  }

  /// Applies sorting based on the [sortBy] value.
  sb.PostgrestTransformBuilder<dynamic> _applySorting(
    sb.PostgrestFilterBuilder<dynamic> query,
    String? sortBy,
  ) {
    switch (sortBy) {
      case 'oldest':
        return query.order('created_at', ascending: true);
      case 'most_used':
        return query.order('usage_count', ascending: false);
      case 'least_used':
        return query.order('usage_count', ascending: true);
      case 'highest_rated':
        return query.order('avg_score', ascending: false);
      case 'a_z':
        return query.order('content', ascending: true);
      case 'z_a':
        return query.order('content', ascending: false);
      case 'newest':
      default:
        return query.order('created_at', ascending: false);
    }
  }

  /// Applies pagination using Supabase range.
  sb.PostgrestTransformBuilder<dynamic> _applyPagination(
    sb.PostgrestTransformBuilder<dynamic> query, {
    int? page,
    int? perPage,
  }) {
    final p = page ?? 1;
    final pp = perPage ?? 20;
    final from = (p - 1) * pp;
    final to = from + pp - 1;
    return query.range(from, to);
  }

  /// Maps a Supabase [sb.PostgrestException] to a domain exception.
  Exception _mapPostgrestException(sb.PostgrestException e) {
    final statusCode = e.code != null ? int.tryParse(e.code!) ?? 0 : 0;
    final message = e.message ?? 'An unexpected database error occurred.';

    AppLogger.warning(
      'Supabase PostgrestException — code: ${e.code}, message: $message',
    );

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 422:
        return ValidationException(
          message: message,
          fieldErrors: e.details is Map<String, dynamic>
              ? e.details as Map<String, String>
              : {},
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: e.details,
        );
    }
  }
}
