import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateCommunicationUseCase].
class CreateCommunicationParams extends Equatable {
  const CreateCommunicationParams({required this.communication});
  final CommunicationEntity communication;

  @override
  List<Object?> get props => [communication];
}

/// Use case for creating a new communication.
///
/// Validates that the [CreateCommunicationParams.communication] title
/// is not empty before delegating to the [TeacherWorkspaceRepository].
class CreateCommunicationUseCase {
  CreateCommunicationUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new communication from the provided [params].
  ///
  /// Returns a [Result] containing the persisted [CommunicationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<CommunicationEntity>> call(
    CreateCommunicationParams params,
  ) async {
    if (params.communication.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Communication title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    return _repository.createCommunication(params.communication);
  }
}
