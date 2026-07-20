import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/deployment_usecases.dart';

class DeploymentState extends Equatable {
  final List<Deployment> deployments;
  final List<TestResult> testResults;
  final bool isLoading;
  final String? error;

  const DeploymentState({this.deployments = const [], this.testResults = const [], this.isLoading = false, this.error});

  DeploymentState copyWith({List<Deployment>? deployments, List<TestResult>? testResults, bool? isLoading, String? error}) {
    return DeploymentState(deployments: deployments ?? this.deployments, testResults: testResults ?? this.testResults, isLoading: isLoading ?? this.isLoading, error: error);
  }

  @override
  List<Object?> get props => [deployments, testResults, isLoading, error];
}

class DeploymentNotifier extends StateNotifier<DeploymentState> {
  final GetDeploymentsUseCase _getDeploymentsUseCase;
  final CreateDeploymentUseCase _createDeploymentUseCase;
  final UpdateDeploymentStatusUseCase _updateDeploymentStatusUseCase;
  final RecordTestResultUseCase _recordTestResultUseCase;
  final GetTestResultsUseCase _getTestResultsUseCase;

  DeploymentNotifier({
    required GetDeploymentsUseCase getDeploymentsUseCase,
    required CreateDeploymentUseCase createDeploymentUseCase,
    required UpdateDeploymentStatusUseCase updateDeploymentStatusUseCase,
    required RecordTestResultUseCase recordTestResultUseCase,
    required GetTestResultsUseCase getTestResultsUseCase,
  })  : _getDeploymentsUseCase = getDeploymentsUseCase,
        _createDeploymentUseCase = createDeploymentUseCase,
        _updateDeploymentStatusUseCase = updateDeploymentStatusUseCase,
        _recordTestResultUseCase = recordTestResultUseCase,
        _getTestResultsUseCase = getTestResultsUseCase,
        super(const DeploymentState());

  Future<void> loadDeployments({String? environment, DeploymentStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getDeploymentsUseCase(GetDeploymentsParams(environment: environment, status: status));
    result.fold(
      onSuccess: (deployments) => state = state.copyWith(deployments: deployments, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createDeployment(Deployment deployment) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createDeploymentUseCase(CreateDeploymentParams(deployment: deployment));
    result.fold(
      onSuccess: (created) => state = state.copyWith(deployments: [...state.deployments, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> updateDeploymentStatus({required String deploymentId, required DeploymentStatus status, String? notes}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateDeploymentStatusUseCase(UpdateDeploymentStatusParams(deploymentId: deploymentId, status: status, notes: notes));
    result.fold(
      onSuccess: (updated) {
        final list = state.deployments.map((d) => d.id == updated.id ? updated : d).toList();
        state = state.copyWith(deployments: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> recordTestResult(TestResult result) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _recordTestResultUseCase(RecordTestResultParams(result: result));
    res.fold(
      onSuccess: (recorded) => state = state.copyWith(testResults: [...state.testResults, recorded], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadTestResults({TestType? testType, String? deploymentId}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getTestResultsUseCase(GetTestResultsParams(testType: testType, deploymentId: deploymentId));
    result.fold(
      onSuccess: (results) => state = state.copyWith(testResults: results, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }
}

String _mapFailureToMessage(Failure failure) {
  return failure.when(
    server: (message, statusCode, data) => 'Server error: $message',
    cache: (message) => 'Cache error: $message',
    auth: (message, code) => 'Auth error: $message',
    network: (message) => 'Network error: $message',
    validation: (message, fieldErrors) => 'Validation error: $message',
    notFound: (message) => 'Not found: $message',
    unauthorized: (message) => 'Unauthorized: $message',
    forbidden: (message) => 'Forbidden: $message',
  );
}
