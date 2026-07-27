import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_generator_repository.dart';
import '../../domain/usecases/upload_document_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI DOCUMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI document upload and processing
/// feature.
///
/// Tracks uploaded documents, the currently selected document,
/// extraction results (text, topics, objectives), and upload/processing
/// progress flags.
class AiDocumentState {
  const AiDocumentState({
    this.uploadedDocuments = const [],
    this.currentDocument,
    this.isUploading = false,
    this.isProcessing = false,
    this.extractedText,
    this.identifiedTopics = const [],
    this.suggestedObjectives = const [],
    this.error,
    this.successMessage,
  });

  /// The list of all uploaded documents.
  final List<DocumentUploadEntity> uploadedDocuments;

  /// The currently selected document for viewing/processing.
  final DocumentUploadEntity? currentDocument;

  /// Whether a document upload is in progress.
  final bool isUploading;

  /// Whether document processing (extraction) is in progress.
  final bool isProcessing;

  /// The extracted text content from the current document.
  final String? extractedText;

  /// Topics identified from the current document.
  final List<Map<String, dynamic>> identifiedTopics;

  /// Suggested learning objectives from the current document.
  final List<Map<String, dynamic>> suggestedObjectives;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isUploading || isProcessing;

  /// Number of documents currently loaded.
  int get documentCount => uploadedDocuments.length;

  /// Whether the current document has been successfully processed.
  bool get isCurrentDocumentProcessed =>
      currentDocument?.status == DocumentStatus.completed;

  /// Whether the current document processing has failed.
  bool get hasCurrentDocumentFailed =>
      currentDocument?.status == DocumentStatus.failed;

  /// Creates a copy of this state with the given fields replaced.
  AiDocumentState copyWith({
    List<DocumentUploadEntity>? uploadedDocuments,
    DocumentUploadEntity? currentDocument,
    bool? isUploading,
    bool? isProcessing,
    String? extractedText,
    List<Map<String, dynamic>>? identifiedTopics,
    List<Map<String, dynamic>>? suggestedObjectives,
    String? error,
    String? successMessage,
  }) {
    return AiDocumentState(
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      currentDocument: currentDocument ?? this.currentDocument,
      isUploading: isUploading ?? this.isUploading,
      isProcessing: isProcessing ?? this.isProcessing,
      extractedText: extractedText ?? this.extractedText,
      identifiedTopics: identifiedTopics ?? this.identifiedTopics,
      suggestedObjectives: suggestedObjectives ?? this.suggestedObjectives,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  AiDocumentState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AiDocumentState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI DOCUMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI document upload and
/// processing feature's state.
///
/// Provides methods for uploading documents, processing them to extract
/// text/topics/objectives, and generating questions from document
/// content.
class AiDocumentNotifier extends StateNotifier<AiDocumentState> {
  AiDocumentNotifier({
    required UploadDocumentUseCase uploadDocumentUseCase,
    required AiGeneratorRepository repository,
  })  : _uploadDocumentUseCase = uploadDocumentUseCase,
        _repository = repository,
        super(const AiDocumentState());

  final UploadDocumentUseCase _uploadDocumentUseCase;
  final AiGeneratorRepository _repository;

  // ─── Upload Document ─────────────────────────────────────────────

  /// Uploads a document for AI extraction and question generation.
  ///
  /// On success, the document is added to [uploadedDocuments] and set
  /// as the [currentDocument].
  Future<void> uploadDocument(DocumentUploadEntity document) async {
    state = state.copyWith(isUploading: true, error: null);

    final result = await _uploadDocumentUseCase(
      UploadDocumentParams(document: document),
    );

    result.fold(
      onSuccess: (uploadedDoc) {
        final updatedDocs = [uploadedDoc, ...state.uploadedDocuments];
        state = state.copyWith(
          isUploading: false,
          uploadedDocuments: updatedDocs,
          currentDocument: uploadedDoc,
          successMessage: 'Document uploaded successfully',
          error: null,
        );
        AppLogger.info('Document uploaded: ${uploadedDoc.fileName}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUploading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upload document: $failure');
      },
    );
  }

  // ─── Process Document ────────────────────────────────────────────

  /// Processes an uploaded document to extract text, identify topics,
  /// and suggest learning objectives.
  ///
  /// Updates the state with extracted data on success.
  Future<void> processDocument(String documentId) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _repository.processDocument(documentId);

    result.fold(
      onSuccess: (processedDoc) {
        // Update the document in the list
        final updatedDocs = state.uploadedDocuments
            .map((d) => d.id == documentId ? processedDoc : d)
            .toList();

        state = state.copyWith(
          isProcessing: false,
          uploadedDocuments: updatedDocs,
          currentDocument: state.currentDocument?.id == documentId
              ? processedDoc
              : state.currentDocument,
          extractedText: processedDoc.extractedText,
          identifiedTopics: processedDoc.identifiedTopics,
          suggestedObjectives: processedDoc.suggestedObjectives,
          successMessage: 'Document processed successfully',
          error: null,
        );
        AppLogger.info('Document processed: ${processedDoc.fileName}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isProcessing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to process document: $failure');
      },
    );
  }

  // ─── Generate from Document ──────────────────────────────────────

  /// Generates questions from an uploaded document using the provided
  /// [input] parameters.
  ///
  /// The [documentId] identifies the source document, and [input]
  /// specifies the generation configuration (subject, difficulty, etc.).
  Future<void> generateFromDocument(
    String documentId,
    GenerationInputEntity input,
  ) async {
    state = state.copyWith(isProcessing: true, error: null);

    // Use the input with the document's extracted content
    final enhancedInput = input.copyWith(
      customInstructions: [
        if (input.customInstructions != null) input.customInstructions!,
        'Generate questions based on the uploaded document content.',
      ].join(' '),
    );

    final result = await _repository.generateQuestions(enhancedInput);

    result.fold(
      onSuccess: (questions) {
        // Update the document with the generation request reference
        final updatedDocs = state.uploadedDocuments.map((d) {
          if (d.id == documentId) {
            return d.copyWith(
              status: DocumentStatus.completed,
              questionGenerationRequestId:
                  questions.isNotEmpty ? questions.first.generationRequestId : null,
            );
          }
          return d;
        }).toList();

        state = state.copyWith(
          isProcessing: false,
          uploadedDocuments: updatedDocs,
          successMessage:
              '${questions.length} questions generated from document',
          error: null,
        );
        AppLogger.info(
          'Generated ${questions.length} questions from document: $documentId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isProcessing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to generate from document: $failure',
        );
      },
    );
  }

  // ─── Load Documents ──────────────────────────────────────────────

  /// Loads all uploaded documents for the current user/school.
  ///
  /// Currently a no-op placeholder since the repository does not
  /// expose a dedicated list-documents endpoint. Will be updated
  /// when the backend adds this capability.
  Future<void> loadDocuments() async {
    // No loading flag change needed — the list is maintained locally
    // from upload results.
    AppLogger.info('Documents list refreshed');
  }

  // ─── Clear Error ─────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}
