import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [RecordEngagementUseCase].
class RecordEngagementParams extends Equatable {
  const RecordEngagementParams({
    required this.metricType,
    required this.studentId,
    this.details,
  });

  final String metricType;
  final String studentId;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [metricType, studentId, details];
}

/// Use case for recording a parent engagement metric.
///
/// Validates that [RecordEngagementParams.metricType] and
/// [RecordEngagementParams.studentId] are not empty before
/// delegating to the [ParentPortalRepository].
class RecordEngagementUseCase {
  RecordEngagementUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Records an engagement metric for the specified student.
  ///
  /// Returns a [Result] containing the [EngagementRecordEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<EngagementRecordEntity>> call(
    RecordEngagementParams params,
  ) async {
    if (params.metricType.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Metric type is required',
        fieldErrors: {'metricType': 'Metric type cannot be empty'},
      ));
    }
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ));
    }
    return _repository.recordEngagement(
      metricType: params.metricType,
      studentId: params.studentId,
      details: params.details,
    );
  }
}
