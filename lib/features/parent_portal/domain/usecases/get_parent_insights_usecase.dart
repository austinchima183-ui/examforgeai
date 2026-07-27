import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetParentInsightsUseCase].
class GetParentInsightsParams extends Equatable {
  const GetParentInsightsParams({
    this.studentId,
    this.isRead,
  });

  final String? studentId;
  final bool? isRead;

  @override
  List<Object?> get props => [studentId, isRead];
}

/// Use case for retrieving AI-generated parent insights.
///
/// Delegates directly to the [ParentPortalRepository] without
/// additional validation since all parameters are optional filters.
class GetParentInsightsUseCase {
  GetParentInsightsUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves insights for the current parent.
  ///
  /// Returns a [Result] containing a list of [ParentAiInsightEntity]
  /// on success, or a [FailureResult] if the repository encounters
  /// an error.
  Future<Result<List<ParentAiInsightEntity>>> call(
    GetParentInsightsParams params,
  ) {
    return _repository.getInsights(
      studentId: params.studentId,
      isRead: params.isRead,
    );
  }
}
