import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/offline_entities.dart';
import '../../repositories/offline_repository.dart';

/// Parameters for [SaveOfflineExamAttemptUseCase].
class SaveOfflineExamAttemptParams extends Equatable {
  const SaveOfflineExamAttemptParams({required this.attempt});

  final OfflineExamAttempt attempt;

  @override
  List<Object?> get props => [attempt];
}

/// Use case: save an offline exam attempt locally.
class SaveOfflineExamAttemptUseCase {
  SaveOfflineExamAttemptUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<OfflineExamAttempt>> call(
    SaveOfflineExamAttemptParams params,
  ) async {
    if (params.attempt.id.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Attempt ID cannot be empty'),
      );
    }
    if (params.attempt.examId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Exam ID cannot be empty'),
      );
    }
    if (params.attempt.studentId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Student ID cannot be empty'),
      );
    }
    if (params.attempt.integrityHash.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Integrity hash cannot be empty'),
      );
    }

    return _repository.saveOfflineExamAttempt(params.attempt);
  }
}
