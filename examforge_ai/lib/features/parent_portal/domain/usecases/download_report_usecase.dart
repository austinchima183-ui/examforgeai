import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [DownloadReportUseCase].
class DownloadReportParams extends Equatable {
  const DownloadReportParams({
    required this.studentId,
    required this.reportType,
    required this.format,
  });

  final String studentId;
  final String reportType;
  final String format;

  @override
  List<Object?> get props => [studentId, reportType, format];
}

/// Use case for downloading a child's report.
///
/// Validates that all fields are not empty and that
/// [DownloadReportParams.format] is one of the allowed values
/// (`pdf`, `excel`, `printable`) before delegating to the
/// [ParentPortalRepository].
class DownloadReportUseCase {
  DownloadReportUseCase(this._repository);
  final ParentPortalRepository _repository;

  static const _allowedFormats = {'pdf', 'excel', 'printable'};

  /// Downloads a report for the specified child.
  ///
  /// Returns a [Result] containing the [ParentReportDownloadEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ParentReportDownloadEntity>> call(DownloadReportParams params) async {
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Student ID is required',
        fieldErrors: {'studentId': 'Student ID cannot be empty'},
      ));
    }
    if (params.reportType.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Report type is required',
        fieldErrors: {'reportType': 'Report type cannot be empty'},
      ));
    }
    if (params.format.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Format is required',
        fieldErrors: {'format': 'Format cannot be empty'},
      ));
    }
    if (!_allowedFormats.contains(params.format.trim().toLowerCase())) {
      return FailureResult(Failure.validation(
        message: 'Invalid format. Allowed values: pdf, excel, printable',
        fieldErrors: {
          'format': 'Must be one of: ${_allowedFormats.join(', ')}',
        },
      ));
    }
    return _repository.downloadReport({
      'studentId': params.studentId,
      'reportType': params.reportType,
      'format': params.format.trim().toLowerCase(),
    });
  }
}
