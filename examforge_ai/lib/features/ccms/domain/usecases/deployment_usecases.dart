import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetDeploymentsUseCase ──────────────────────────────────────────

class GetDeploymentsParams extends Equatable {
  final String? environment;
  final DeploymentStatus? status;
  final int limit;
  final int offset;

  const GetDeploymentsParams({
    this.environment,
    this.status,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [environment, status, limit, offset];
}

class GetDeploymentsUseCase {
  final CcmsRepository _repository;
  GetDeploymentsUseCase(this._repository);

  Future<Result<List<Deployment>>> call(GetDeploymentsParams params) async {
    return await _repository.getDeployments(
      environment: params.environment,
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── CreateDeploymentUseCase ────────────────────────────────────────

class CreateDeploymentParams extends Equatable {
  final Deployment deployment;

  const CreateDeploymentParams({required this.deployment});

  @override
  List<Object?> get props => [deployment];
}

class CreateDeploymentUseCase {
  final CcmsRepository _repository;
  CreateDeploymentUseCase(this._repository);

  Future<Result<Deployment>> call(CreateDeploymentParams params) async {
    return await _repository.createDeployment(params.deployment);
  }
}

// ─── UpdateDeploymentStatusUseCase ──────────────────────────────────

class UpdateDeploymentStatusParams extends Equatable {
  final String deploymentId;
  final DeploymentStatus status;
  final String? notes;

  const UpdateDeploymentStatusParams({
    required this.deploymentId,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [deploymentId, status, notes];
}

class UpdateDeploymentStatusUseCase {
  final CcmsRepository _repository;
  UpdateDeploymentStatusUseCase(this._repository);

  Future<Result<Deployment>> call(
    UpdateDeploymentStatusParams params,
  ) async {
    return await _repository.updateDeploymentStatus(
      deploymentId: params.deploymentId,
      status: params.status,
      notes: params.notes,
    );
  }
}

// ─── RecordTestResultUseCase ────────────────────────────────────────

class RecordTestResultParams extends Equatable {
  final TestResult result;

  const RecordTestResultParams({required this.result});

  @override
  List<Object?> get props => [result];
}

class RecordTestResultUseCase {
  final CcmsRepository _repository;
  RecordTestResultUseCase(this._repository);

  Future<Result<TestResult>> call(RecordTestResultParams params) async {
    return await _repository.recordTestResult(params.result);
  }
}

// ─── GetTestResultsUseCase ──────────────────────────────────────────

class GetTestResultsParams extends Equatable {
  final TestType? testType;
  final String? deploymentId;
  final String? status;
  final int limit;
  final int offset;

  const GetTestResultsParams({
    this.testType,
    this.deploymentId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [testType, deploymentId, status, limit, offset];
}

class GetTestResultsUseCase {
  final CcmsRepository _repository;
  GetTestResultsUseCase(this._repository);

  Future<Result<List<TestResult>>> call(GetTestResultsParams params) async {
    return await _repository.getTestResults(
      testType: params.testType,
      deploymentId: params.deploymentId,
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
