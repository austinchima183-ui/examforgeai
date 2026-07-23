import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../../domain/repositories/super_admin_repository.dart';
import '../datasources/super_admin_remote_datasource.dart';
import '../models/super_admin_models.dart';

/// Implementation of [SuperAdminRepository] that bridges the domain layer
/// with the remote data source.
///
/// Calls the appropriate datasource method, converts models to entities
/// via `.toEntity()`, and maps data-layer exceptions to domain [Failure]
/// types wrapped in [FailureResult].
class SuperAdminRepositoryImpl implements SuperAdminRepository {
  SuperAdminRepositoryImpl({required SuperAdminRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final SuperAdminRemoteDataSource _remoteDataSource;

  // ═══ Dashboard ═══════════════════════════════════════════════════════════

  @override
  Future<Result<DashboardMetrics>> getDashboardMetrics({bool forceRefresh = false}) async {
    try {
      final model = await _remoteDataSource.getDashboardMetrics(forceRefresh: forceRefresh);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getDashboardMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Platform Settings ═══════════════════════════════════════════════════

  @override
  Future<Result<List<PlatformSetting>>> getPlatformSettings({SettingScope? scope}) async {
    try {
      final models = await _remoteDataSource.getPlatformSettings(scope: scope?.value);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getPlatformSettings error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformSetting>> getPlatformSetting(String key, {SettingScope? scope}) async {
    try {
      final model = await _remoteDataSource.getPlatformSetting(key, scope: scope?.value);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getPlatformSetting error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformSetting>> updatePlatformSetting(PlatformSetting setting) async {
    try {
      final model = await _remoteDataSource.updatePlatformSetting(
        PlatformSettingModel.fromEntity(setting).toJson(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updatePlatformSetting error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<PlatformSetting>>> bulkUpdateSettings(List<PlatformSetting> settings) async {
    try {
      final models = await _remoteDataSource.bulkUpdateSettings(
        settings.map((s) => PlatformSettingModel.fromEntity(s).toJson()).toList(),
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected bulkUpdateSettings error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Feature Flags ═══════════════════════════════════════════════════════

  @override
  Future<Result<List<FeatureFlag>>> getFeatureFlags({bool? isActive}) async {
    try {
      final models = await _remoteDataSource.getFeatureFlags(isActive: isActive);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getFeatureFlags error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<FeatureFlag>> getFeatureFlag(String key) async {
    try {
      final model = await _remoteDataSource.getFeatureFlag(key);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getFeatureFlag error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<FeatureFlag>> createFeatureFlag(FeatureFlag flag) async {
    try {
      final model = await _remoteDataSource.createFeatureFlag(
        FeatureFlagModel.fromEntity(flag).toJson(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createFeatureFlag error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<FeatureFlag>> updateFeatureFlag(FeatureFlag flag) async {
    try {
      final model = await _remoteDataSource.updateFeatureFlag(
        flag.id,
        FeatureFlagModel.fromEntity(flag).toJson(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateFeatureFlag error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> deleteFeatureFlag(String flagId) async {
    try {
      await _remoteDataSource.deleteFeatureFlag(flagId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected deleteFeatureFlag error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<FeatureFlag>> toggleFeatureFlag(String flagId, bool isActive) async {
    try {
      final model = await _remoteDataSource.toggleFeatureFlag(flagId, isActive);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected toggleFeatureFlag error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Audit Logs ══════════════════════════════════════════════════════════

  @override
  Future<Result<List<AuditLog>>> getAuditLogs({
    AuditCategory? category,
    AuditSeverity? severity,
    String? actorId,
    String? resourceType,
    String? resourceId,
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getAuditLogs(
        category: category?.value,
        severity: severity?.value,
        actorId: actorId,
        resourceType: resourceType,
        resourceId: resourceId,
        schoolId: schoolId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAuditLogs error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AuditLog>> createAuditLog(AuditLog log) async {
    try {
      final model = await _remoteDataSource.createAuditLog({
        'id': log.id,
        'actor_id': log.actorId,
        'actor_email': log.actorEmail,
        'actor_role': log.actorRole,
        'action': log.action,
        'category': log.category.value,
        'severity': log.severity.value,
        'resource_type': log.resourceType,
        'resource_id': log.resourceId,
        'school_id': log.schoolId,
        'description': log.description,
        'old_values': log.oldValues,
        'new_values': log.newValues,
        'metadata': log.metadata,
        'ip_address': log.ipAddress,
        'user_agent': log.userAgent,
        'session_id': log.sessionId,
        'request_id': log.requestId,
        'duration_ms': log.durationMs,
        'is_sensitive': log.isSensitive,
        'created_at': log.createdAt.toIso8601String(),
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createAuditLog error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getAuditLogCount({AuditCategory? category, DateTime? startDate, DateTime? endDate}) async {
    try {
      final count = await _remoteDataSource.getAuditLogCount(
        category: category?.value,
        startDate: startDate,
        endDate: endDate,
      );
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAuditLogCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ School Management ═══════════════════════════════════════════════════

  @override
  Future<Result<List<SchoolManagementDetail>>> getSchools({
    bool? isActive,
    bool? isVerified,
    String? search,
    String? subscriptionStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getSchools(
        isActive: isActive,
        isVerified: isVerified,
        search: search,
        subscriptionStatus: subscriptionStatus,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSchools error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SchoolManagementDetail>> getSchool(String schoolId) async {
    try {
      final model = await _remoteDataSource.getSchool(schoolId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SchoolManagementDetail>> createSchool(Map<String, dynamic> schoolData) async {
    try {
      final model = await _remoteDataSource.createSchool(schoolData);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SchoolManagementDetail>> updateSchool(String schoolId, Map<String, dynamic> data) async {
    try {
      final model = await _remoteDataSource.updateSchool(schoolId, data);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> suspendSchool(String schoolId, String reason) async {
    try {
      await _remoteDataSource.suspendSchool(schoolId, reason);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected suspendSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> reactivateSchool(String schoolId) async {
    try {
      await _remoteDataSource.reactivateSchool(schoolId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected reactivateSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> deleteSchool(String schoolId) async {
    try {
      await _remoteDataSource.deleteSchool(schoolId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected deleteSchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> verifySchool(String schoolId) async {
    try {
      await _remoteDataSource.verifySchool(schoolId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected verifySchool error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getSchoolCount({bool? isActive}) async {
    try {
      final count = await _remoteDataSource.getSchoolCount(isActive: isActive);
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSchoolCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ User Management ═════════════════════════════════════════════════════

  @override
  Future<Result<List<UserManagementDetail>>> getUsers({
    String? role,
    String? schoolId,
    bool? isActive,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getUsers(
        role: role,
        schoolId: schoolId,
        isActive: isActive,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getUsers error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<UserManagementDetail>> getUser(String userId) async {
    try {
      final model = await _remoteDataSource.getUser(userId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getUser error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> suspendUser(String userId, String reason) async {
    try {
      await _remoteDataSource.suspendUser(userId, reason);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected suspendUser error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> activateUser(String userId) async {
    try {
      await _remoteDataSource.activateUser(userId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected activateUser error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> resetUserPassword(String userId) async {
    try {
      await _remoteDataSource.resetUserPassword(userId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected resetUserPassword error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> changeUserRole(String userId, String newRole) async {
    try {
      await _remoteDataSource.changeUserRole(userId, newRole);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected changeUserRole error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<ImpersonationSession>> startImpersonation(String targetUserId, String reason) async {
    try {
      final model = await _remoteDataSource.startImpersonation({
        'target_user_id': targetUserId,
        'reason': reason,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected startImpersonation error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> endImpersonation(String sessionId) async {
    try {
      await _remoteDataSource.endImpersonation(sessionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected endImpersonation error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<ImpersonationSession>>> getImpersonationSessions({String? status, int limit = 20}) async {
    try {
      final models = await _remoteDataSource.getImpersonationSessions(status: status, limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getImpersonationSessions error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getUserCount({String? role, bool? isActive}) async {
    try {
      final count = await _remoteDataSource.getUserCount(role: role, isActive: isActive);
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getUserCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ AI Management ═══════════════════════════════════════════════════════

  @override
  Future<Result<List<AIProvider>>> getAIProviders({bool? isActive}) async {
    try {
      final models = await _remoteDataSource.getAIProviders(isActive: isActive);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAIProviders error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AIProvider>> getAIProvider(String providerId) async {
    try {
      final model = await _remoteDataSource.getAIProvider(providerId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAIProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AIProvider>> createAIProvider(AIProvider provider) async {
    try {
      final model = await _remoteDataSource.createAIProvider(
        AIProviderModel.fromEntity(provider).toJson(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createAIProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AIProvider>> updateAIProvider(AIProvider provider) async {
    try {
      final model = await _remoteDataSource.updateAIProvider(
        provider.id,
        AIProviderModel.fromEntity(provider).toJson(),
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateAIProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> deleteAIProvider(String providerId) async {
    try {
      await _remoteDataSource.deleteAIProvider(providerId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected deleteAIProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AIProvider>> setDefaultProvider(String providerId) async {
    try {
      final model = await _remoteDataSource.setDefaultProvider(providerId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected setDefaultProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<AIProvider>> toggleProvider(String providerId, bool isActive) async {
    try {
      final model = await _remoteDataSource.toggleProvider(providerId, isActive);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected toggleProvider error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<AIRequestLog>>> getAIRequestLogs({
    String? providerId,
    String? userId,
    String? schoolId,
    bool? isSuccess,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getAIRequestLogs(
        providerId: providerId,
        userId: userId,
        schoolId: schoolId,
        isSuccess: isSuccess,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAIRequestLogs error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAIUsageAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _remoteDataSource.getAIUsageAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getAIUsageAnalytics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Infrastructure ══════════════════════════════════════════════════════

  @override
  Future<Result<List<InfrastructureService>>> getInfrastructureServices({HealthStatus? status}) async {
    try {
      final models = await _remoteDataSource.getInfrastructureServices(status: status?.value);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getInfrastructureServices error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<InfrastructureService>> getInfrastructureService(String serviceId) async {
    try {
      final model = await _remoteDataSource.getInfrastructureService(serviceId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getInfrastructureService error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<InfrastructureService>> updateInfrastructureService(InfrastructureService service) async {
    try {
      final model = await _remoteDataSource.updateInfrastructureService(
        service.id,
        {
          'id': service.id,
          'service_name': service.serviceName,
          'service_type': service.serviceType,
          'endpoint_url': service.endpointUrl,
          'health_status': service.healthStatus.value,
          'last_check_at': service.lastCheckAt?.toIso8601String(),
          'last_healthy_at': service.lastHealthyAt?.toIso8601String(),
          'response_time_ms': service.responseTimeMs,
          'uptime_percentage': service.uptimePercentage,
          'error_rate': service.errorRate,
          'configuration': service.configuration,
          'metadata': service.metadata,
          'is_critical': service.isCritical,
          'alert_threshold_response_ms': service.alertThresholdResponseMs,
          'alert_threshold_error_rate': service.alertThresholdErrorRate,
          'created_at': service.createdAt.toIso8601String(),
          'updated_at': service.updatedAt.toIso8601String(),
        },
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateInfrastructureService error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> runHealthCheck(String serviceId) async {
    try {
      await _remoteDataSource.runHealthCheck(serviceId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected runHealthCheck error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> runAllHealthChecks() async {
    try {
      await _remoteDataSource.runAllHealthChecks();
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected runAllHealthChecks error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Support Tickets ═════════════════════════════════════════════════════

  @override
  Future<Result<List<SupportTicket>>> getSupportTickets({
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
    String? schoolId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getSupportTickets(
        status: status?.value,
        priority: priority?.value,
        category: category?.value,
        assignedTo: assignedTo,
        schoolId: schoolId,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSupportTickets error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SupportTicket>> getSupportTicket(String ticketId) async {
    try {
      final model = await _remoteDataSource.getSupportTicket(ticketId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSupportTicket error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SupportTicket>> updateSupportTicket(SupportTicket ticket) async {
    try {
      final model = await _remoteDataSource.updateSupportTicket(
        ticket.id,
        {
          'id': ticket.id,
          'ticket_number': ticket.ticketNumber,
          'reporter_id': ticket.reporterId,
          'school_id': ticket.schoolId,
          'subject': ticket.subject,
          'description': ticket.description,
          'category': ticket.category.value,
          'priority': ticket.priority.value,
          'status': ticket.status.value,
          'assigned_to': ticket.assignedTo,
          'related_resource_type': ticket.relatedResourceType,
          'related_resource_id': ticket.relatedResourceId,
          'tags': ticket.tags,
          'attachments': ticket.attachments,
          'resolution_notes': ticket.resolutionNotes,
          'first_response_at': ticket.firstResponseAt?.toIso8601String(),
          'resolved_at': ticket.resolvedAt?.toIso8601String(),
          'closed_at': ticket.closedAt?.toIso8601String(),
          'satisfaction_rating': ticket.satisfactionRating,
          'satisfaction_comment': ticket.satisfactionComment,
          'is_escalated': ticket.isEscalated,
          'escalated_at': ticket.escalatedAt?.toIso8601String(),
          'escalated_to': ticket.escalatedTo,
          'due_date': ticket.dueDate?.toIso8601String(),
          'created_at': ticket.createdAt.toIso8601String(),
          'updated_at': ticket.updatedAt.toIso8601String(),
        },
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateSupportTicket error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SupportTicket>> assignTicket(String ticketId, String assignToUserId) async {
    try {
      final model = await _remoteDataSource.assignTicket(ticketId, assignToUserId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected assignTicket error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SupportTicket>> escalateTicket(String ticketId, String escalateToUserId, String reason) async {
    try {
      final model = await _remoteDataSource.escalateTicket(ticketId, escalateToUserId, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected escalateTicket error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SupportTicket>> resolveTicket(String ticketId, String resolutionNotes) async {
    try {
      final model = await _remoteDataSource.resolveTicket(ticketId, resolutionNotes);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected resolveTicket error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<TicketComment>> addTicketComment(String ticketId, String content, {bool isInternal = false}) async {
    try {
      final model = await _remoteDataSource.addTicketComment({
        'ticket_id': ticketId,
        'content': content,
        'is_internal': isInternal,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected addTicketComment error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<TicketComment>>> getTicketComments(String ticketId) async {
    try {
      final models = await _remoteDataSource.getTicketComments(ticketId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getTicketComments error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getTicketCount({TicketStatus? status}) async {
    try {
      final count = await _remoteDataSource.getTicketCount(status: status?.value);
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getTicketCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Marketplace ═════════════════════════════════════════════════════════

  @override
  Future<Result<List<MarketplaceContent>>> getMarketplaceContent({
    MarketplaceStatus? status,
    MarketplaceContentType? contentType,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getMarketplaceContent(
        status: status?.value,
        contentType: contentType?.value,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> getMarketplaceItem(String contentId) async {
    try {
      final model = await _remoteDataSource.getMarketplaceItem(contentId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceItem error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> approveMarketplaceContent(String contentId, {String? notes}) async {
    try {
      final model = await _remoteDataSource.approveMarketplaceContent(contentId, notes: notes);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected approveMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> rejectMarketplaceContent(String contentId, String reason) async {
    try {
      final model = await _remoteDataSource.rejectMarketplaceContent(contentId, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected rejectMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> featureMarketplaceContent(String contentId, DateTime? until) async {
    try {
      final model = await _remoteDataSource.featureMarketplaceContent(contentId, until);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected featureMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> removeMarketplaceContent(String contentId, String reason) async {
    try {
      final model = await _remoteDataSource.removeMarketplaceContent(contentId, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected removeMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MarketplaceContent>> flagMarketplaceContent(String contentId, String reason) async {
    try {
      final model = await _remoteDataSource.flagMarketplaceContent(contentId, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected flagMarketplaceContent error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getMarketplaceContentCount({MarketplaceStatus? status}) async {
    try {
      final count = await _remoteDataSource.getMarketplaceContentCount(status: status?.value);
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getMarketplaceContentCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Platform Notifications ══════════════════════════════════════════════

  @override
  Future<Result<List<PlatformNotification>>> getNotifications({
    String? recipientId,
    NotificationCategory? category,
    NotificationPriority? priority,
    bool? unreadOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getNotifications(
        recipientId: recipientId,
        category: category?.value,
        priority: priority?.value,
        unreadOnly: unreadOnly,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getNotifications error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformNotification>> markNotificationRead(String notificationId) async {
    try {
      final model = await _remoteDataSource.markNotificationRead(notificationId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected markNotificationRead error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> markAllNotificationsRead({String? recipientId}) async {
    try {
      await _remoteDataSource.markAllNotificationsRead(recipientId: recipientId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected markAllNotificationsRead error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> dismissNotification(String notificationId) async {
    try {
      await _remoteDataSource.dismissNotification(notificationId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected dismissNotification error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformNotification>> createNotification(PlatformNotification notification) async {
    try {
      final model = await _remoteDataSource.createNotification({
        'id': notification.id,
        'recipient_id': notification.recipientId,
        'category': notification.category.value,
        'priority': notification.priority.value,
        'title': notification.title,
        'message': notification.message,
        'action_url': notification.actionUrl,
        'action_label': notification.actionLabel,
        'is_read': notification.isRead,
        'read_at': notification.readAt?.toIso8601String(),
        'is_dismissed': notification.isDismissed,
        'dismissed_at': notification.dismissedAt?.toIso8601String(),
        'related_entity_type': notification.relatedEntityType,
        'related_entity_id': notification.relatedEntityId,
        'metadata': notification.metadata,
        'expires_at': notification.expiresAt?.toIso8601String(),
        'created_at': notification.createdAt.toIso8601String(),
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createNotification error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<int>> getUnreadNotificationCount({String? recipientId}) async {
    try {
      final count = await _remoteDataSource.getUnreadNotificationCount(recipientId: recipientId);
      return Success(count);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getUnreadNotificationCount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Operations Intelligence ═════════════════════════════════════════════

  @override
  Future<Result<List<IntelligenceAlert>>> getIntelligenceAlerts({
    IntelligenceAlertType? alertType,
    IntelligenceSeverity? severity,
    bool? unacknowledgedOnly,
    bool? unresolvedOnly,
    String? schoolId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getIntelligenceAlerts(
        alertType: alertType?.value,
        severity: severity?.value,
        unacknowledgedOnly: unacknowledgedOnly,
        unresolvedOnly: unresolvedOnly,
        schoolId: schoolId,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getIntelligenceAlerts error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<IntelligenceAlert>> getIntelligenceAlert(String alertId) async {
    try {
      final model = await _remoteDataSource.getIntelligenceAlert(alertId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getIntelligenceAlert error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<IntelligenceAlert>> acknowledgeAlert(String alertId) async {
    try {
      final model = await _remoteDataSource.acknowledgeAlert(alertId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected acknowledgeAlert error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<IntelligenceAlert>> resolveAlert(String alertId, String resolutionNotes) async {
    try {
      final model = await _remoteDataSource.resolveAlert(alertId, resolutionNotes);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected resolveAlert error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<IntelligenceAlert>>> generateIntelligenceInsights() async {
    try {
      final models = await _remoteDataSource.generateIntelligenceInsights();
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected generateIntelligenceInsights error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getChurnPredictions({int limit = 20}) async {
    try {
      final data = await _remoteDataSource.getChurnPredictions(limit: limit);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getChurnPredictions error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getRevenueForecast({int monthsAhead = 6}) async {
    try {
      final data = await _remoteDataSource.getRevenueForecast(monthsAhead: monthsAhead);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getRevenueForecast error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getEngagementInsights() async {
    try {
      final data = await _remoteDataSource.getEngagementInsights();
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getEngagementInsights error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getCostOptimizationSuggestions() async {
    try {
      final data = await _remoteDataSource.getCostOptimizationSuggestions();
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getCostOptimizationSuggestions error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Revenue Analytics ═══════════════════════════════════════════════════

  @override
  Future<Result<RevenueAnalytics>> getRevenueAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final model = await _remoteDataSource.getRevenueAnalytics(startDate: startDate, endDate: endDate);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getRevenueAnalytics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Security ════════════════════════════════════════════════════════════

  @override
  Future<Result<List<LoginMonitoringEntry>>> getLoginMonitoring({
    String? userId,
    bool? failedOnly,
    String? ipAddress,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getLoginMonitoring(
        userId: userId,
        failedOnly: failedOnly,
        ipAddress: ipAddress,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getLoginMonitoring error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<ActiveSession>>> getActiveSessions({String? userId}) async {
    try {
      final models = await _remoteDataSource.getActiveSessions(userId: userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getActiveSessions error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> terminateSession(String sessionId) async {
    try {
      await _remoteDataSource.terminateSession(sessionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected terminateSession error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> detectSuspiciousActivity({int lookbackHours = 24}) async {
    try {
      final data = await _remoteDataSource.detectSuspiciousActivity(lookbackHours: lookbackHours);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected detectSuspiciousActivity error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> lockUserAccount(String userId, String reason) async {
    try {
      await _remoteDataSource.lockUserAccount(userId, reason);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected lockUserAccount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> unlockUserAccount(String userId) async {
    try {
      await _remoteDataSource.unlockUserAccount(userId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected unlockUserAccount error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ System Reports ══════════════════════════════════════════════════════

  @override
  Future<Result<List<SystemReport>>> getSystemReports({ReportType? type, String? status}) async {
    try {
      final models = await _remoteDataSource.getSystemReports(type: type?.value, status: status);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSystemReports error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SystemReport>> generateReport(ReportType type, Map<String, dynamic> parameters, {String format = 'pdf'}) async {
    try {
      final params = {
        'report_type': type.value,
        'format': format,
        ...parameters,
      };
      final model = await _remoteDataSource.generateReport(params);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected generateReport error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<SystemReport>> getSystemReport(String reportId) async {
    try {
      final model = await _remoteDataSource.getSystemReport(reportId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSystemReport error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Maintenance Windows ═════════════════════════════════════════════════

  @override
  Future<Result<List<MaintenanceWindow>>> getMaintenanceWindows({MaintenanceStatus? status}) async {
    try {
      final models = await _remoteDataSource.getMaintenanceWindows(status: status?.value);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getMaintenanceWindows error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MaintenanceWindow>> createMaintenanceWindow(MaintenanceWindow window) async {
    try {
      final model = await _remoteDataSource.createMaintenanceWindow({
        'id': window.id,
        'title': window.title,
        'description': window.description,
        'status': window.status.value,
        'affected_services': window.affectedServices,
        'start_at': window.startAt.toIso8601String(),
        'end_at': window.endAt.toIso8601String(),
        'actual_start_at': window.actualStartAt?.toIso8601String(),
        'actual_end_at': window.actualEndAt?.toIso8601String(),
        'is_planned': window.isPlanned,
        'notification_sent': window.notificationSent,
        'created_by': window.createdBy,
        'created_at': window.createdAt.toIso8601String(),
        'updated_at': window.updatedAt.toIso8601String(),
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected createMaintenanceWindow error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<MaintenanceWindow>> updateMaintenanceWindow(MaintenanceWindow window) async {
    try {
      final model = await _remoteDataSource.updateMaintenanceWindow(
        window.id,
        {
          'id': window.id,
          'title': window.title,
          'description': window.description,
          'status': window.status.value,
          'affected_services': window.affectedServices,
          'start_at': window.startAt.toIso8601String(),
          'end_at': window.endAt.toIso8601String(),
          'actual_start_at': window.actualStartAt?.toIso8601String(),
          'actual_end_at': window.actualEndAt?.toIso8601String(),
          'is_planned': window.isPlanned,
          'notification_sent': window.notificationSent,
          'created_by': window.createdBy,
          'created_at': window.createdAt.toIso8601String(),
          'updated_at': window.updatedAt.toIso8601String(),
        },
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updateMaintenanceWindow error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<void>> cancelMaintenanceWindow(String windowId) async {
    try {
      await _remoteDataSource.cancelMaintenanceWindow(windowId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected cancelMaintenanceWindow error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Platform Policies ═══════════════════════════════════════════════════

  @override
  Future<Result<List<PlatformPolicy>>> getPlatformPolicies({bool? isActive}) async {
    try {
      final models = await _remoteDataSource.getPlatformPolicies(isActive: isActive);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getPlatformPolicies error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformPolicy>> getPlatformPolicy(String policyKey) async {
    try {
      final model = await _remoteDataSource.getPlatformPolicy(policyKey);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getPlatformPolicy error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<PlatformPolicy>> upsertPlatformPolicy(PlatformPolicy policy) async {
    try {
      final model = await _remoteDataSource.upsertPlatformPolicy({
        'id': policy.id,
        'policy_key': policy.policyKey,
        'title': policy.title,
        'content': policy.content,
        'version': policy.version,
        'is_active': policy.isActive,
        'effective_date': policy.effectiveDate.toIso8601String(),
        'created_by': policy.createdBy,
        'created_at': policy.createdAt.toIso8601String(),
        'updated_at': policy.updatedAt.toIso8601String(),
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected upsertPlatformPolicy error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Email Templates ═════════════════════════════════════════════════════

  @override
  Future<Result<List<EmailTemplate>>> getEmailTemplates({String? category}) async {
    try {
      final models = await _remoteDataSource.getEmailTemplates(category: category);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getEmailTemplates error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<EmailTemplate>> getEmailTemplate(String templateKey) async {
    try {
      final model = await _remoteDataSource.getEmailTemplate(templateKey);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getEmailTemplate error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<EmailTemplate>> upsertEmailTemplate(EmailTemplate template) async {
    try {
      final model = await _remoteDataSource.upsertEmailTemplate({
        'id': template.id,
        'template_key': template.templateKey,
        'name': template.name,
        'subject': template.subject,
        'html_body': template.htmlBody,
        'text_body': template.textBody,
        'category': template.category,
        'variables': template.variables,
        'is_active': template.isActive,
        'created_at': template.createdAt.toIso8601String(),
        'updated_at': template.updatedAt.toIso8601String(),
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected upsertEmailTemplate error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  // ═══ Platform Analytics ══════════════════════════════════════════════════

  @override
  Future<Result<Map<String, dynamic>>> getSchoolGrowthMetrics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDataSource.getSchoolGrowthMetrics(startDate: startDate, endDate: endDate);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getSchoolGrowthMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserGrowthMetrics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDataSource.getUserGrowthMetrics(startDate: startDate, endDate: endDate);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getUserGrowthMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getFeatureUsageMetrics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final data = await _remoteDataSource.getFeatureUsageMetrics(startDate: startDate, endDate: endDate);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getFeatureUsageMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getStorageUsageMetrics() async {
    try {
      final data = await _remoteDataSource.getStorageUsageMetrics();
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getStorageUsageMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getGeographicDistribution() async {
    try {
      final data = await _remoteDataSource.getGeographicDistribution();
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getGeographicDistribution error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getRetentionMetrics({int months = 12}) async {
    try {
      final data = await _remoteDataSource.getRetentionMetrics(months: months);
      return Success(data);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getRetentionMetrics error', error: e);
      return const FailureResult(Failure.server(message: 'An unexpected error occurred.', statusCode: 500));
    }
  }
}
