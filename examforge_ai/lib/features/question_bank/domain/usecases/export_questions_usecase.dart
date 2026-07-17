import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [ExportQuestionsUseCase].
class ExportQuestionsParams {
  const ExportQuestionsParams({
    required this.exportJob,
  });

  /// The export job entity describing the format, filter, and metadata.
  final QuestionExportEntity exportJob;
}

/// Use case that starts a bulk question export job.
///
/// Validates that the export job has all required fields (school ID,
/// creator, and format), then delegates to
/// [QuestionBankRepository.startExport].
///
/// ```dart
/// final result = await exportQuestionsUseCase(
///   ExportQuestionsParams(
///     exportJob: QuestionExportEntity(
///       id: '',
///       schoolId: 'sch-001',
///       createdBy: 'user-123',
///       format: 'excel',
///       filter: QuestionFilterEntity(subjectId: 'math-101'),
///       createdAt: DateTime.now(),
///     ),
///   ),
/// );
/// result.fold(
///   onSuccess: (job) => pollExportStatus(job.id),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ExportQuestionsUseCase {
  ExportQuestionsUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<QuestionExportEntity>> call(
    ExportQuestionsParams params,
  ) async {
    // ── Validate required fields ────────────────────────────────────
    if (params.exportJob.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required for export',
          fieldErrors: {'schoolId': 'Select a school'},
        ),
      );
    }

    if (params.exportJob.createdBy.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Creator ID is required for export',
          fieldErrors: {'createdBy': 'User identity is missing'},
        ),
      );
    }

    // ── Validate format ─────────────────────────────────────────────
    const validFormats = {'csv', 'excel', 'json', 'pdf'};
    if (!validFormats.contains(params.exportJob.format)) {
      return FailureResult(
        Failure.validation(
          message:
              'Invalid export format: "${params.exportJob.format}". '
              'Must be one of: ${validFormats.join(', ')}',
          fieldErrors: {'format': 'Select a valid export format'},
        ),
      );
    }

    return _repository.startExport(params.exportJob);
  }
}
