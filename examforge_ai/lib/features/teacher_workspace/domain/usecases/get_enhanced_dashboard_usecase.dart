import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetEnhancedDashboardUseCase].
///
/// No parameters are required — the repository infers the current
/// teacher from the authenticated session.
class GetEnhancedDashboardParams extends Equatable {
  const GetEnhancedDashboardParams();

  @override
  List<Object?> get props => [];
}

/// Use case for retrieving the enhanced dashboard summary.
///
/// The enhanced dashboard provides expanded analytics and insights
/// for the current teacher, including presentation counts, task
/// progress, rubric statistics, and more.
class GetEnhancedDashboardUseCase {
  GetEnhancedDashboardUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Retrieves the enhanced dashboard for the current teacher.
  ///
  /// Returns a [Result] containing the [EnhancedDashboardEntity]
  /// on success, or a [FailureResult] if the repository encounters
  /// an error.
  Future<Result<EnhancedDashboardEntity>> call(
    GetEnhancedDashboardParams params,
  ) {
    return _repository.getEnhancedDashboard();
  }
}
