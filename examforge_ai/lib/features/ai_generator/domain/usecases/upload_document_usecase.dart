import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_generator_repository.dart';

/// Parameters for the [UploadDocumentUseCase].
class UploadDocumentParams {
  const UploadDocumentParams({
    required this.document,
  });

  /// The document upload entity containing file metadata.
  final DocumentUploadEntity document;
}

/// Use case that uploads a document for AI extraction and question
/// generation.
///
/// Validates that the document has all required fields (file name,
/// URL, size, MIME type, school ID, uploader ID), then delegates to
/// [AiGeneratorRepository.uploadDocument].
///
/// ```dart
/// final result = await uploadDocumentUseCase(
///   UploadDocumentParams(
///     document: DocumentUploadEntity(
///       id: 'doc-001',
///       schoolId: 'sch-001',
///       uploadedBy: 'user-001',
///       fileName: 'physics_notes.pdf',
///       fileUrl: 'https://storage.example.com/physics_notes.pdf',
///       fileSize: 2048000,
///       mimeType: 'application/pdf',
///       documentType: 'textbook',
///       createdAt: DateTime.now(),
///     ),
///   ),
/// );
/// result.fold(
///   onSuccess: (document) => showSuccess('Document uploaded'),
///   onFailure: (failure) => showError(failure),
/// );
/// ```
class UploadDocumentUseCase {
  UploadDocumentUseCase(this._repository);

  final AiGeneratorRepository _repository;

  Future<Result<DocumentUploadEntity>> call(
    UploadDocumentParams params,
  ) async {
    final doc = params.document;

    // ── Validate school ID ──────────────────────────────────────────
    if (doc.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Associate this document with a school'},
        ),
      );
    }

    // ── Validate uploader ───────────────────────────────────────────
    if (doc.uploadedBy.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Uploader ID is required',
          fieldErrors: {'uploadedBy': 'Identify who is uploading this file'},
        ),
      );
    }

    // ── Validate file name ──────────────────────────────────────────
    if (doc.fileName.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'File name is required',
          fieldErrors: {'fileName': 'Provide a file name'},
        ),
      );
    }

    // ── Validate file URL ───────────────────────────────────────────
    if (doc.fileUrl.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'File URL is required',
          fieldErrors: {'fileUrl': 'Upload the file first to get a URL'},
        ),
      );
    }

    // ── Validate file size ──────────────────────────────────────────
    if (doc.fileSize <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'File size must be greater than zero',
          fieldErrors: {'fileSize': 'Invalid file size'},
        ),
      );
    }

    // ── Validate MIME type ──────────────────────────────────────────
    if (doc.mimeType.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'MIME type is required',
          fieldErrors: {'mimeType': 'Specify the file type'},
        ),
      );
    }

    // ── Validate document type ──────────────────────────────────────
    if (doc.documentType.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Document type is required',
          fieldErrors: {'documentType': 'Specify the document type'},
        ),
      );
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.uploadDocument(doc);
  }
}
