import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../datasources/question_bank_remote_datasource.dart';
import '../models/question_models.dart';

/// Concrete implementation of [QuestionBankRepository] that delegates
/// all operations to [QuestionBankRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class QuestionBankRepositoryImpl implements QuestionBankRepository {
  QuestionBankRepositoryImpl({
    required QuestionBankRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final QuestionBankRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<QuestionEntity>> createQuestion(
    QuestionEntity question,
  ) async {
    try {
      final model = QuestionModel.fromEntity(question);
      final created = await _remoteDataSource.createQuestion(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionEntity>> updateQuestion(
    QuestionEntity question,
  ) async {
    try {
      final model = QuestionModel.fromEntity(question);
      final updated = await _remoteDataSource.updateQuestion(
        question.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> deleteQuestion(String questionId) async {
    try {
      await _remoteDataSource.deleteQuestion(questionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected deleteQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionEntity>> getQuestion(String questionId) async {
    try {
      final model = await _remoteDataSource.getQuestion(questionId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getQuestion error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionEntity>> getQuestionWithDetails(
    String questionId,
  ) async {
    try {
      final json = await _remoteDataSource.getQuestionWithDetails(questionId);
      final model = QuestionModel.fromJson(json);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error(
        'Unexpected getQuestionWithDetails error in repository',
        error: e,
      );
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionEntity>>> getQuestions(
    QuestionFilterEntity filter,
  ) async {
    try {
      final filterModel = QuestionFilterModel.fromEntity(filter);
      final models =
          await _remoteDataSource.getQuestions(filterModel.toJson());
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getQuestions error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<int>> getQuestionCount(QuestionFilterEntity filter) async {
    try {
      final filterModel = QuestionFilterModel.fromEntity(filter);
      final count =
          await _remoteDataSource.getQuestionCount(filterModel.toJson());
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getQuestionCount error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATUS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> publishQuestion(String questionId) async {
    try {
      await _remoteDataSource.publishQuestion(questionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected publishQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> archiveQuestion(String questionId) async {
    try {
      await _remoteDataSource.archiveQuestion(questionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected archiveQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> restoreQuestion(String questionId) async {
    try {
      await _remoteDataSource.restoreQuestion(questionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected restoreQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionEntity>> duplicateQuestion(String questionId) async {
    try {
      final model =
          await _remoteDataSource.duplicateQuestion(questionId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected duplicateQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> moveQuestions(
    List<String> questionIds, {
    String? topicId,
    String? categoryId,
  }) async {
    try {
      final target = <String, dynamic>{};
      if (topicId != null) target['topic_id'] = topicId;
      if (categoryId != null) target['category_id'] = categoryId;

      await _remoteDataSource.moveQuestions(questionIds, target);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected moveQuestions error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANSWER OPTIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AnswerOptionEntity>>> getAnswerOptions(
    String questionId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getAnswerOptions(questionId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAnswerOptions error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<AnswerOptionEntity>>> updateAnswerOptions(
    String questionId,
    List<AnswerOptionEntity> options,
  ) async {
    try {
      final optionsData = options
          .map((o) => AnswerOptionModel.fromEntity(o).toJson())
          .toList();
      final models = await _remoteDataSource.updateAnswerOptions(
        questionId,
        optionsData,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateAnswerOptions error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAGS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<QuestionTagEntity>>> getTags({
    String? schoolId,
    String? searchQuery,
  }) async {
    try {
      final models = await _remoteDataSource.getTags(
        schoolId: schoolId,
        searchQuery: searchQuery,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getTags error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionTagEntity>> createTag(QuestionTagEntity tag) async {
    try {
      final model = QuestionTagModel.fromEntity(tag);
      final created = await _remoteDataSource.createTag(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      AppLogger.error('Unexpected createTag error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> addTagsToQuestion(
    String questionId,
    List<String> tagIds,
  ) async {
    try {
      await _remoteDataSource.addTagsToQuestion(questionId, tagIds);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected addTagsToQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> removeTagFromQuestion(
    String questionId,
    String tagId,
  ) async {
    try {
      await _remoteDataSource.removeTagFromQuestion(questionId, tagId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected removeTagFromQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FAVORITES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> toggleFavorite(String questionId) async {
    try {
      await _remoteDataSource.toggleFavorite(questionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected toggleFavorite error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionEntity>>> getFavorites({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getFavorites(
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getFavorites error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<bool>> isFavorite(String questionId) async {
    try {
      final result = await _remoteDataSource.isFavorite(questionId);
      return Success(result);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected isFavorite error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<QuestionCollectionEntity>> createCollection(
    QuestionCollectionEntity collection,
  ) async {
    try {
      final model = QuestionCollectionModel.fromEntity(collection);
      final created =
          await _remoteDataSource.createCollection(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      AppLogger.error('Unexpected createCollection error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionCollectionEntity>> updateCollection(
    QuestionCollectionEntity collection,
  ) async {
    try {
      final model = QuestionCollectionModel.fromEntity(collection);
      final updated = await _remoteDataSource.updateCollection(
        collection.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateCollection error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    try {
      await _remoteDataSource.deleteCollection(collectionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected deleteCollection error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionCollectionEntity>>> getCollections({
    String? schoolId,
    String? createdBy,
    bool? isShared,
  }) async {
    try {
      final models = await _remoteDataSource.getCollections(
        schoolId: schoolId,
        createdBy: createdBy,
        isShared: isShared,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getCollections error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> addQuestionToCollection(
    String collectionId,
    String questionId,
  ) async {
    try {
      await _remoteDataSource.addQuestionToCollection(
        collectionId,
        questionId,
      );
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error(
        'Unexpected addQuestionToCollection error in repository',
        error: e,
      );
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> removeQuestionFromCollection(
    String collectionId,
    String questionId,
  ) async {
    try {
      await _remoteDataSource.removeQuestionFromCollection(
        collectionId,
        questionId,
      );
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error(
        'Unexpected removeQuestionFromCollection error in repository',
        error: e,
      );
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionEntity>>> getCollectionQuestions(
    String collectionId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getCollectionQuestions(
        collectionId,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error(
        'Unexpected getCollectionQuestions error in repository',
        error: e,
      );
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> shareQuestion(
    String questionId,
    String sharedWith, {
    String permission = 'read',
    String? message,
  }) async {
    try {
      await _remoteDataSource.shareQuestion(questionId, {
        'shared_with': sharedWith,
        'permission': permission,
        if (message != null) 'message': message,
      });
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected shareQuestion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<void>> removeShare(String shareId) async {
    try {
      await _remoteDataSource.removeShare(shareId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected removeShare error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionShareEntity>>> getSharedQuestions({
    String? sharedWith,
  }) async {
    try {
      final models = await _remoteDataSource.getSharedQuestions(
        sharedWith: sharedWith,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSharedQuestions error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // IMPORT / EXPORT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<QuestionImportEntity>> startImport(
    QuestionImportEntity importJob,
  ) async {
    try {
      final model = QuestionImportModel.fromEntity(importJob);
      final created =
          await _remoteDataSource.startImport(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected startImport error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionImportEntity>> getImportStatus(
    String importId,
  ) async {
    try {
      final model = await _remoteDataSource.getImportStatus(importId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getImportStatus error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionExportEntity>> startExport(
    QuestionExportEntity exportJob,
  ) async {
    try {
      final model = QuestionExportModel.fromEntity(exportJob);
      final created =
          await _remoteDataSource.startExport(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected startExport error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionExportEntity>> getExportStatus(
    String exportId,
  ) async {
    try {
      final model = await _remoteDataSource.getExportStatus(exportId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getExportStatus error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<QuestionEntity>>> searchQuestions(
    String query,
    QuestionFilterEntity filter,
  ) async {
    try {
      final filterModel = QuestionFilterModel.fromEntity(filter);
      final models = await _remoteDataSource.searchQuestions(
        query,
        filterModel.toJson(),
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected searchQuestions error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<QuestionBankStatsEntity>> getStats({
    String? schoolId,
  }) async {
    try {
      final model =
          await _remoteDataSource.getStats(schoolId: schoolId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getStats error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<TopicEntity>>> getTopics(String subjectId) async {
    try {
      final models = await _remoteDataSource.getTopics(subjectId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getTopics error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<SubtopicEntity>>> getSubtopics(String topicId) async {
    try {
      final models = await _remoteDataSource.getSubtopics(topicId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSubtopics error in repository', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<QuestionCategoryEntity>>> getCategories({
    String? schoolId,
  }) async {
    try {
      final models =
          await _remoteDataSource.getCategories(schoolId: schoolId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getCategories error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<List<AcademicSessionEntity>>> getAcademicSessions({
    String? schoolId,
  }) async {
    try {
      final models = await _remoteDataSource.getAcademicSessions(
        schoolId: schoolId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error(
        'Unexpected getAcademicSessions error in repository',
        error: e,
      );
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VERSION HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<QuestionVersionEntity>>> getVersionHistory(
    String questionId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getVersionHistory(questionId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getVersionHistory error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }

  @override
  Future<Result<QuestionEntity>> restoreVersion(
    String questionId,
    int version,
  ) async {
    try {
      final model =
          await _remoteDataSource.restoreVersion(questionId, version);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected restoreVersion error in repository',
          error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred.',
        statusCode: 500,
      ));
    }
  }
}
