import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateCommunicationUseCase].
class GenerateCommunicationParams extends Equatable {
  const GenerateCommunicationParams({
    required this.communicationType,
    required this.purpose,
    required this.tone,
    required this.recipientType,
    this.subjectId,
    this.classId,
    this.customInstructions,
  });

  final String communicationType;
  final String? subjectId;
  final String? classId;
  final String purpose;
  final String tone;
  final String recipientType;
  final String? customInstructions;

  @override
  List<Object?> get props => [
        communicationType,
        subjectId,
        classId,
        purpose,
        tone,
        recipientType,
        customInstructions,
      ];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.generateCommunication].
  Map<String, dynamic> toMap() => {
    'communicationType': communicationType,
    'subjectId': subjectId,
    'classId': classId,
    'purpose': purpose,
    'tone': tone,
    'recipientType': recipientType,
    'customInstructions': customInstructions,
  };
}

/// Use case for generating a communication using AI.
///
/// Validates that the [GenerateCommunicationParams.purpose] is not
/// empty before delegating to the [TeacherWorkspaceRepository].
class GenerateCommunicationUseCase {
  GenerateCommunicationUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Generates a communication based on the provided [params].
  ///
  /// Returns a [Result] containing the generated [CommunicationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<CommunicationEntity>> call(
    GenerateCommunicationParams params,
  ) async {
    if (params.purpose.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Purpose is required',
        fieldErrors: {'purpose': 'Purpose cannot be empty'},
      ),);
    }
    return _repository.generateCommunication(params.toMap());
  }
}
