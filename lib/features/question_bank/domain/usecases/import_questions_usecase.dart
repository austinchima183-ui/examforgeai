import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [ImportQuestionsUseCase].
class ImportQuestionsParams {
  const ImportQuestionsParams({
    required this.importJob,
  });

  /// The import job entity describing the source, file, and metadata.
  final QuestionImportEntity importJob;
}

/// Use case that starts a bulk question import job.
///
/// Validates that the import job has all required fields (school ID,
/// creator, source type, and file reference), then delegates to
/// [QuestionBankRepository.startImport].
///
/// ```dart
/// final result = await importQuestionsUseCase(
///   ImportQuestionsParams(
///     importJob: QuestionImportEntity(
///       id: '',
///       schoolId: 'sch-001',
///       createdBy: 'user-123',
///       source: 'csv',
///       fileName: 'questions.csv',
///       createdAt: DateTime.now(),
///     ),
///   ),
/// );
/// result.fold(
///   onSuccess: (job) => pollImportStatus(job.id),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class ImportQuestionsUseCase {
  ImportQuestionsUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<QuestionImportEntity>> call(
    ImportQuestionsParams params,
  ) async {
    // ── Validate required fields ────────────────────────────────────
    if (params.importJob.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required for import',
          fieldErrors: {'schoolId': 'Select a school'},
        ),
      );
    }

    if (params.importJob.createdBy.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Creator ID is required for import',
          fieldErrors: {'createdBy': 'User identity is missing'},
        ),
      );
    }

    // ── Validate source type ────────────────────────────────────────
    const validSources = {'csv', 'excel', 'json', 'word'};
    if (!validSources.contains(params.importJob.source)) {
      return FailureResult(
        Failure.validation(
          message:
              'Invalid import source: "${params.importJob.source}". '
              'Must be one of: ${validSources.join(', ')}',
          fieldErrors: {'source': 'Select a valid import format'},
        ),
      );
    }

    // ── Validate file reference ─────────────────────────────────────
    if ((params.importJob.fileName ?? '').trim().isEmpty &&
        (params.importJob.fileUrl ?? '').trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'A file must be provided for import',
          fieldErrors: {'file': 'Upload a file to import'},
        ),
      );
    }

    return _repository.startImport(params.importJob);
  }
}
