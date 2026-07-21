import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetParentDashboardUseCase].
///
/// No parameters are required — the repository infers the current
/// parent from the authenticated session.
class GetParentDashboardParams extends Equatable {
  const GetParentDashboardParams();

  @override
  List<Object?> get props => [];
}

/// Use case for retrieving the parent dashboard summary.
///
/// The parent dashboard provides an overview of children's academic
/// progress, upcoming events, recent notifications, and quick-action
/// links for the currently authenticated parent.
class GetParentDashboardUseCase {
  GetParentDashboardUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves the dashboard for the current parent.
  ///
  /// Returns a [Result] containing the [ParentDashboardEntity]
  /// on success, or a [FailureResult] if the repository encounters
  /// an error.
  Future<Result<ParentDashboardEntity>> call(
    GetParentDashboardParams params,
  ) {
    return _repository.getParentDashboard();
  }
}
