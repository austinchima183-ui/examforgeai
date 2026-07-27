import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetEngagementAnalyticsUseCase].
class GetEngagementAnalyticsParams extends Equatable {
  const GetEngagementAnalyticsParams({required this.schoolId});
  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// Use case for retrieving engagement analytics.
///
/// Validates that the [GetEngagementAnalyticsParams.schoolId] is not
/// empty before delegating to the [ParentPortalRepository].
class GetEngagementAnalyticsUseCase {
  GetEngagementAnalyticsUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves engagement analytics for the specified school.
  ///
  /// Returns a [Result] containing the [EngagementAnalyticsEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<EngagementAnalyticsEntity>> call(
    GetEngagementAnalyticsParams params,
  ) async {
    if (params.schoolId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'School ID is required',
        fieldErrors: {'schoolId': 'School ID cannot be empty'},
      ),);
    }
    return _repository.getEngagementAnalytics(params.schoolId);
  }
}
