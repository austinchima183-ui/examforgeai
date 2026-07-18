import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/entities/exam_template_entities.dart';
import '../../domain/repositories/exam_template_repository.dart';
import '../datasources/exam_template_remote_datasource.dart';
import '../models/exam_template_models.dart';

/// Concrete implementation of [ExamTemplateRepository] that delegates
/// all operations to [ExamTemplateRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class ExamTemplateRepositoryImpl implements ExamTemplateRepository {
  ExamTemplateRepositoryImpl({
    required ExamTemplateRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ExamTemplateRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Convert exceptions to Failures
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapExceptionToFailure(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
    } else if (e is CacheException) {
      return Failure.cache(message: e.message);
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
    } else {
      AppLogger.error(
        'Unexpected exception in ExamTemplateRepositoryImpl',
        error: e,
      );
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Template CRUD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamTemplateEntity>> saveAsTemplate(
    ExamTemplateEntity template,
  ) async {
    try {
      final model = ExamTemplateModel.fromEntity(template);
      final created = await _remoteDataSource.saveAsTemplate(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ExamTemplateEntity>>> getTemplates({
    String? schoolId,
    TemplateCategory? category,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (schoolId != null) filters['school_id'] = schoolId;
      if (category != null) filters['category'] = category.value;

      final models = await _remoteDataSource.getTemplates(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ExamTemplateEntity>> getTemplate(String templateId) async {
    try {
      final model = await _remoteDataSource.getTemplate(templateId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTemplate(String templateId) async {
    try {
      await _remoteDataSource.deleteTemplate(templateId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Exam Creation from Template
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ExamEntity>> createExamFromTemplate(
    String templateId,
    Map<String, dynamic> overrides,
  ) async {
    try {
      final model = await _remoteDataSource.createExamFromTemplate(
        templateId,
        overrides,
      );
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Submission Receipts
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SubmissionReceiptEntity>> getSubmissionReceipt(
    String attemptId,
  ) async {
    try {
      final model =
          await _remoteDataSource.getSubmissionReceipt(attemptId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> verifyReceipt(String receiptNumber) async {
    try {
      final isVerified = await _remoteDataSource.verifyReceipt(receiptNumber);
      return Success(isVerified);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
