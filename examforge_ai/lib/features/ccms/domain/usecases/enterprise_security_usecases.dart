import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── RecordAuditEventUseCase ────────────────────────────────────────

class RecordAuditEventParams extends Equatable {
  final AuditEntry entry;

  const RecordAuditEventParams({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class RecordAuditEventUseCase {
  final CcmsRepository _repository;
  RecordAuditEventUseCase(this._repository);

  Future<Result<AuditEntry>> call(RecordAuditEventParams params) async {
    return await _repository.recordAuditEvent(params.entry);
  }
}

// ─── GetAuditTrailUseCase ───────────────────────────────────────────

class GetAuditTrailParams extends Equatable {
  final String? userId;
  final String? schoolId;
  final AuditAction? action;
  final String? resourceType;
  final String? resourceId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const GetAuditTrailParams({
    this.userId,
    this.schoolId,
    this.action,
    this.resourceType,
    this.resourceId,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
        userId,
        schoolId,
        action,
        resourceType,
        resourceId,
        startDate,
        endDate,
        limit,
        offset,
      ];
}

class GetAuditTrailUseCase {
  final CcmsRepository _repository;
  GetAuditTrailUseCase(this._repository);

  Future<Result<List<AuditEntry>>> call(GetAuditTrailParams params) async {
    return await _repository.getAuditTrail(
      userId: params.userId,
      schoolId: params.schoolId,
      action: params.action,
      resourceType: params.resourceType,
      resourceId: params.resourceId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── GetMfaConfigUseCase ────────────────────────────────────────────

class GetMfaConfigParams extends Equatable {
  final String userId;

  const GetMfaConfigParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetMfaConfigUseCase {
  final CcmsRepository _repository;
  GetMfaConfigUseCase(this._repository);

  Future<Result<MfaConfiguration>> call(GetMfaConfigParams params) async {
    return await _repository.getMfaConfig(params.userId);
  }
}

// ─── EnableMfaUseCase ───────────────────────────────────────────────

class EnableMfaParams extends Equatable {
  final String userId;
  final MfaMethod method;
  final String? phoneNumber;

  const EnableMfaParams({
    required this.userId,
    required this.method,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [userId, method, phoneNumber];
}

class EnableMfaUseCase {
  final CcmsRepository _repository;
  EnableMfaUseCase(this._repository);

  Future<Result<MfaConfiguration>> call(EnableMfaParams params) async {
    return await _repository.enableMfa(
      userId: params.userId,
      method: params.method,
      phoneNumber: params.phoneNumber,
    );
  }
}

// ─── DisableMfaUseCase ──────────────────────────────────────────────

class DisableMfaParams extends Equatable {
  final String userId;
  final String verificationCode;

  const DisableMfaParams({
    required this.userId,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [userId, verificationCode];
}

class DisableMfaUseCase {
  final CcmsRepository _repository;
  DisableMfaUseCase(this._repository);

  Future<Result<bool>> call(DisableMfaParams params) async {
    return await _repository.disableMfa(
      userId: params.userId,
      verificationCode: params.verificationCode,
    );
  }
}

// ─── VerifyMfaUseCase ───────────────────────────────────────────────

class VerifyMfaParams extends Equatable {
  final String userId;
  final String verificationCode;

  const VerifyMfaParams({
    required this.userId,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [userId, verificationCode];
}

class VerifyMfaUseCase {
  final CcmsRepository _repository;
  VerifyMfaUseCase(this._repository);

  Future<Result<bool>> call(VerifyMfaParams params) async {
    return await _repository.verifyMfa(
      userId: params.userId,
      verificationCode: params.verificationCode,
    );
  }
}

// ─── CreateApiKeyUseCase ────────────────────────────────────────────

class CreateApiKeyParams extends Equatable {
  final String userId;
  final String name;
  final String? schoolId;
  final List<String>? scopes;
  final int? rateLimitOverride;
  final DateTime? expiresAt;

  const CreateApiKeyParams({
    required this.userId,
    required this.name,
    this.schoolId,
    this.scopes,
    this.rateLimitOverride,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [userId, name, schoolId, scopes, rateLimitOverride, expiresAt];
}

class CreateApiKeyUseCase {
  final CcmsRepository _repository;
  CreateApiKeyUseCase(this._repository);

  Future<Result<ApiKey>> call(CreateApiKeyParams params) async {
    return await _repository.createApiKey(
      userId: params.userId,
      name: params.name,
      schoolId: params.schoolId,
      scopes: params.scopes,
      rateLimitOverride: params.rateLimitOverride,
      expiresAt: params.expiresAt,
    );
  }
}

// ─── RevokeApiKeyUseCase ────────────────────────────────────────────

class RevokeApiKeyParams extends Equatable {
  final String apiKeyId;

  const RevokeApiKeyParams({required this.apiKeyId});

  @override
  List<Object?> get props => [apiKeyId];
}

class RevokeApiKeyUseCase {
  final CcmsRepository _repository;
  RevokeApiKeyUseCase(this._repository);

  Future<Result<bool>> call(RevokeApiKeyParams params) async {
    return await _repository.revokeApiKey(params.apiKeyId);
  }
}

// ─── GetApiKeysUseCase ──────────────────────────────────────────────

class GetApiKeysParams extends Equatable {
  final String userId;

  const GetApiKeysParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetApiKeysUseCase {
  final CcmsRepository _repository;
  GetApiKeysUseCase(this._repository);

  Future<Result<List<ApiKey>>> call(GetApiKeysParams params) async {
    return await _repository.getApiKeys(params.userId);
  }
}

// ─── RecordSecurityEventUseCase ─────────────────────────────────────

class RecordSecurityEventParams extends Equatable {
  final SecurityEvent event;

  const RecordSecurityEventParams({required this.event});

  @override
  List<Object?> get props => [event];
}

class RecordSecurityEventUseCase {
  final CcmsRepository _repository;
  RecordSecurityEventUseCase(this._repository);

  Future<Result<SecurityEvent>> call(RecordSecurityEventParams params) async {
    return await _repository.recordSecurityEvent(params.event);
  }
}

// ─── GetSecurityEventsUseCase ───────────────────────────────────────

class GetSecurityEventsParams extends Equatable {
  final String? userId;
  final String? schoolId;
  final AlertSeverity? severity;
  final bool? isResolved;
  final int limit;
  final int offset;

  const GetSecurityEventsParams({
    this.userId,
    this.schoolId,
    this.severity,
    this.isResolved,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, schoolId, severity, isResolved, limit, offset];
}

class GetSecurityEventsUseCase {
  final CcmsRepository _repository;
  GetSecurityEventsUseCase(this._repository);

  Future<Result<List<SecurityEvent>>> call(
    GetSecurityEventsParams params,
  ) async {
    return await _repository.getSecurityEvents(
      userId: params.userId,
      schoolId: params.schoolId,
      severity: params.severity,
      isResolved: params.isResolved,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── CheckRateLimitUseCase ──────────────────────────────────────────

class CheckRateLimitParams extends Equatable {
  final RateLimitScope scope;
  final String identifier;
  final String? endpointPattern;

  const CheckRateLimitParams({
    required this.scope,
    required this.identifier,
    this.endpointPattern,
  });

  @override
  List<Object?> get props => [scope, identifier, endpointPattern];
}

class CheckRateLimitUseCase {
  final CcmsRepository _repository;
  CheckRateLimitUseCase(this._repository);

  Future<Result<bool>> call(CheckRateLimitParams params) async {
    return await _repository.checkRateLimit(
      scope: params.scope,
      identifier: params.identifier,
      endpointPattern: params.endpointPattern,
    );
  }
}

// ─── GetUserSessionsUseCase ─────────────────────────────────────────

class GetUserSessionsParams extends Equatable {
  final String userId;

  const GetUserSessionsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetUserSessionsUseCase {
  final CcmsRepository _repository;
  GetUserSessionsUseCase(this._repository);

  Future<Result<List<UserSession>>> call(GetUserSessionsParams params) async {
    return await _repository.getUserSessions(params.userId);
  }
}

// ─── InvalidateUserSessionsUseCase ──────────────────────────────────

class InvalidateUserSessionsParams extends Equatable {
  final String userId;
  final String sessionId;

  const InvalidateUserSessionsParams({
    required this.userId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [userId, sessionId];
}

class InvalidateUserSessionsUseCase {
  final CcmsRepository _repository;
  InvalidateUserSessionsUseCase(this._repository);

  Future<Result<bool>> call(InvalidateUserSessionsParams params) async {
    return await _repository.invalidateUserSessions(
      userId: params.userId,
      sessionId: params.sessionId,
    );
  }
}
