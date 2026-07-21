import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [DismissInsightUseCase].
class DismissInsightParams extends Equatable {
  const DismissInsightParams({required this.insightId});
  final String insightId;

  @override
  List<Object?> get props => [insightId];
}

/// Use case for dismissing a parent insight.
///
/// Validates that the [DismissInsightParams.insightId] is not
/// empty before delegating to the [ParentPortalRepository].
class DismissInsightUseCase {
  DismissInsightUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Dismisses the specified insight so it no longer appears.
  ///
  /// Returns a [Result] containing `void` on success, or a
  /// [FailureResult] if validation fails or the repository
  /// encounters an error.
  Future<Result<void>> call(DismissInsightParams params) async {
    if (params.insightId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Insight ID is required',
        fieldErrors: {'insightId': 'Insight ID cannot be empty'},
      ));
    }
    return _repository.dismissInsight(params.insightId);
  }
}
