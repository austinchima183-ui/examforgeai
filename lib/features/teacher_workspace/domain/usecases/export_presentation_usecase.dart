import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [ExportPresentationUseCase].
class ExportPresentationParams extends Equatable {
  const ExportPresentationParams({
    required this.presentationId,
    required this.format,
  });

  final String presentationId;
  final String format;

  @override
  List<Object?> get props => [presentationId, format];
}

/// Use case for exporting a presentation to a specific format.
///
/// Validates that the [ExportPresentationParams.presentationId] is not
/// empty and the [ExportPresentationParams.format] is one of the
/// supported formats (pdf, pptx, html) before delegating to the
/// [TeacherWorkspaceRepository].
class ExportPresentationUseCase {
  ExportPresentationUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Exports a presentation to the specified format.
  ///
  /// Returns a [Result] containing the download URL or file path
  /// as a [String] on success, or a [FailureResult] if validation
  /// fails or the repository encounters an error.
  Future<Result<String>> call(ExportPresentationParams params) async {
    if (params.presentationId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Presentation ID is required',
        fieldErrors: {'presentationId': 'Presentation ID cannot be empty'},
      ),);
    }
    const validFormats = ['pdf', 'pptx', 'html'];
    if (!validFormats.contains(params.format.toLowerCase())) {
      return FailureResult(Failure.validation(
        message: 'Invalid export format',
        fieldErrors: {
          'format': 'Format must be one of: ${validFormats.join(', ')}',
        },
      ),);
    }
    return _repository.exportPresentation(
      params.presentationId,
      params.format.toLowerCase(),
    );
  }
}
