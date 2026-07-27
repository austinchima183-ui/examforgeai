import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/edu_os_entities.dart';
import '../../domain/repositories/edu_os_repository.dart';
import '../datasources/edu_os_remote_datasource.dart';

/// Concrete implementation of [EduOsRepository].
class EduOsRepositoryImpl implements EduOsRepository {
  EduOsRepositoryImpl(this._remoteDatasource);
  final EduOsRemoteDatasource _remoteDatasource;

  Result<T> _handleError<T>(Object e) {
    if (e is ServerException) return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    if (e is NetworkException) return FailureResult(Failure.network(message: e.message));
    if (e is AuthException) return FailureResult(Failure.auth(message: e.message, code: e.code));
    if (e is NotFoundException) return FailureResult(Failure.notFound(message: e.message));
    return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
  }

  @override
  Future<Result<List<EduosModule>>> getModules({ModuleStatus? status, ModuleTier? tier}) async {
    try {
      final models = await _remoteDatasource.getModules(status: status?.value, tier: tier?.value);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EduosModule>> getModuleByCode(String code) async {
    try {
      final model = await _remoteDatasource.getModuleByCode(code);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<EduosModuleSubscription>>> getModuleSubscriptions({required String schoolId, bool? isEnabled}) async {
    try {
      final models = await _remoteDatasource.getModuleSubscriptions(schoolId: schoolId, isEnabled: isEnabled);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EduosModuleSubscription>> subscribeModule({required String schoolId, required String moduleId, required ModuleTier tier}) async {
    try {
      final model = await _remoteDatasource.subscribeModule({'school_id': schoolId, 'module_id': moduleId, 'module_tier': tier.value});
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<bool>> unsubscribeModule({required String subscriptionId}) async {
    try {
      await _remoteDatasource.unsubscribeModule(subscriptionId);
      return const Success(true);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EduosModuleSubscription>> enableModule({required String subscriptionId}) async {
    try {
      final model = await _remoteDatasource.enableModule(subscriptionId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EduosModuleSubscription>> disableModule({required String subscriptionId}) async {
    try {
      final model = await _remoteDatasource.disableModule(subscriptionId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<EduosModuleApi>>> getModuleApis({required String moduleId}) async {
    try {
      final models = await _remoteDatasource.getModuleApis(moduleId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<bool>> trackAnalyticsEvent({required String eventType, required Map<String, dynamic> properties}) async {
    try {
      final result = await _remoteDatasource.trackAnalyticsEvent({'event_type': eventType, 'properties': properties});
      return Success(result);
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAnalyticsSummary({required String schoolId}) async {
    try {
      final data = await _remoteDatasource.getAnalyticsSummary(schoolId);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }
}
