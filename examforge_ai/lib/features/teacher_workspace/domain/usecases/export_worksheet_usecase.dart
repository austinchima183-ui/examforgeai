import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [ExportWorksheetUseCase].
class ExportWorksheetParams {
  const ExportWorksheetParams({
    required this.worksheetId,
    required this.format,
  });

  final String worksheetId;
  final String format;
}

class ExportWorksheetUseCase {
  ExportWorksheetUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<String>> call(ExportWorksheetParams params) async {
    if (params.worksheetId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Worksheet ID is required',
        fieldErrors: {'worksheetId': 'Worksheet ID cannot be empty'},
      ));
    }
    const validFormats = ['pdf', 'docx', 'html'];
    if (!validFormats.contains(params.format.toLowerCase())) {
      return FailureResult(Failure.validation(
        message: 'Invalid export format',
        fieldErrors: {
          'format': 'Format must be one of: ${validFormats.join(', ')}',
        },
      ));
    }
    return _repository.exportWorksheet(
      params.worksheetId,
      params.format.toLowerCase(),
    );
  }
}
