import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CHAT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Document Chat feature.
///
/// Tracks the list of uploaded documents, the currently selected
/// document with its chat messages, loading/uploading/sending flags,
/// and upload progress.
class DocumentChatState {
  const DocumentChatState({
    this.documents = const [],
    this.currentDocument,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isUploading = false,
    this.error,
    this.uploadProgress = 0,
    this.currentPage = 1,
    this.hasMore = true,
  });

  /// All documents uploaded by the current student.
  final List<DocumentChatEntity> documents;

  /// The currently selected document, or `null`.
  final DocumentChatEntity? currentDocument;

  /// Chat messages for the currently selected document.
  final List<DocumentChatMessageEntity> messages;

  /// Whether the initial document list load is in progress.
  final bool isLoading;

  /// Whether a chat message send operation is in progress.
  final bool isSending;

  /// Whether a document upload operation is in progress.
  final bool isUploading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Upload progress as a value between 0.0 and 1.0.
  final double uploadProgress;

  /// Current page number for document pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Whether there are more document pages to load.
  final bool hasMore;

  /// Current page number for document pagination.
  int get currentPage => currentPage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSending || isUploading;

  /// Number of documents currently loaded.
  int get documentCount => documents.length;

  /// Whether the current document is ready for chat (not processing).
  bool get canChat =>
      currentDocument?.status == DocumentChatStatus.ready;

  /// Creates a copy of this state with the given fields replaced.
  DocumentChatState copyWith({
    List<DocumentChatEntity>? documents,
    DocumentChatEntity? currentDocument,
    List<DocumentChatMessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isUploading,
    String? error,
    double? uploadProgress,
    int? currentPage,
    bool? hasMore,
    bool clearCurrentDocument = false,
  }) {
    return DocumentChatState(
      documents: documents ?? this.documents,
      currentDocument: clearCurrentDocument
          ? null
          : (currentDocument ?? this.currentDocument),
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentPage: currentPage ?? currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Clears the current error message.
  DocumentChatState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CHAT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Document Chat feature's
/// state.
///
/// All document chat operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the document list, messages, and upload state on success
/// 4. Sets [error] on failure
class DocumentChatNotifier extends StateNotifier<DocumentChatState> {
  DocumentChatNotifier({
    required UploadDocumentUseCase uploadDocument,
    required GetDocumentsUseCase getDocuments,
    required SendDocumentMessageUseCase sendDocumentMessage,
    required String? studentId,
    required String? schoolId,
  })  : _uploadDocument = uploadDocument,
        _getDocuments = getDocuments,
        _sendDocumentMessage = sendDocumentMessage,
        _studentId = studentId,
        _schoolId = schoolId,
        super(const DocumentChatState());

  final UploadDocumentUseCase _uploadDocument;
  final GetDocumentsUseCase _getDocuments;
  final SendDocumentMessageUseCase _sendDocumentMessage;
  final String? _studentId;
  final String? _schoolId;

  static const int _pageSize = 20;

  // ─── Load Documents (first page) ───────────────────────────────────

  /// Loads the first page of documents for the current student.
  Future<void> loadDocuments() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getDocuments(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (documents) {
        state = state.copyWith(
          isLoading: false,
          documents: documents,
          currentPage: 1,
          hasMore: documents.length >= _pageSize,
          error: null,
        );
        AppLogger.info(
          'Loaded ${documents.length} documents (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load documents: $failure');
      },
    );
  }

  // ─── Open Document ─────────────────────────────────────────────────

  /// Opens a document by ID, setting it as the current document with
  /// its messages loaded.
  Future<void> openDocument(String documentId) async {
    state = state.copyWith(isLoading: true, error: null);

    // Find the document in the loaded list first.
    final existingDoc = state.documents
        .where((d) => d.id == documentId)
        .firstOrNull;

    if (existingDoc != null) {
      state = state.copyWith(
        isLoading: false,
        currentDocument: existingDoc,
        messages: existingDoc.messages,
        error: null,
      );
      AppLogger.info('Opened document from cache: $documentId');
      return;
    }

    // If not found in the list, we need to load it.
    // Note: GetDocumentDetailUseCase would be used here if available.
    // For now, set loading to false and report an error.
    state = state.copyWith(
      isLoading: false,
      error: 'Document not found',
    );
  }

  // ─── Upload Document ───────────────────────────────────────────────

  /// Uploads a document for AI chat processing.
  Future<void> uploadDocument({
    required String fileName,
    required String fileUrl,
    required String fileFormat,
    int? fileSize,
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0,
      error: null,
    );

    // Simulate upload progress for UX feedback.
    // In production, this would be driven by actual upload events.
    state = state.copyWith(uploadProgress: 0.3);

    final result = await _uploadDocument(
      studentId: _studentId!,
      schoolId: _schoolId,
      fileName: fileName,
      fileUrl: fileUrl,
      fileFormat: fileFormat,
      fileSize: fileSize,
    );

    result.fold(
      onSuccess: (document) {
        final updatedList = [document, ...state.documents];
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 1.0,
          documents: updatedList,
          currentDocument: document,
          messages: document.messages,
          error: null,
        );
        AppLogger.info('Uploaded document: ${document.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 0,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upload document: $failure');
      },
    );
  }

  // ─── Send Message ──────────────────────────────────────────────────

  /// Sends a chat message about the current document and appends the
  /// AI response.
  Future<void> sendMessage(String content) async {
    final document = state.currentDocument;
    if (document == null) return;

    if (document.status != DocumentChatStatus.ready) {
      state = state.copyWith(
        error: 'Document is still processing. Please wait.',
      );
      return;
    }

    state = state.copyWith(isSending: true, error: null);

    final result = await _sendDocumentMessage(
      documentId: document.id,
      content: content,
    );

    result.fold(
      onSuccess: (aiMessage) {
        // Create the user message locally.
        final userMessage = DocumentChatMessageEntity(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          documentId: document.id,
          role: TutorMessageRole.user,
          content: content,
          createdAt: DateTime.now(),
        );

        final updatedMessages = [...state.messages, userMessage, aiMessage];

        // Update current document messages.
        final updatedDocument = document.copyWith(
          messages: updatedMessages,
        );

        state = state.copyWith(
          isSending: false,
          messages: updatedMessages,
          currentDocument: updatedDocument,
          error: null,
        );
        AppLogger.info(
          'Message sent in document chat: ${document.id}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSending: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to send document message: $failure');
      },
    );
  }

  // ─── Delete Document ───────────────────────────────────────────────

  /// Removes a document from the local list.
  /// Note: Actual deletion requires a DeleteDocumentUseCase.
  void deleteDocument(String documentId) {
    final updatedList =
        state.documents.where((d) => d.id != documentId).toList();

    state = state.copyWith(
      documents: updatedList,
      currentDocument: state.currentDocument?.id == documentId
          ? null
          : state.currentDocument,
      messages: state.currentDocument?.id == documentId
          ? const []
          : state.messages,
    );
    AppLogger.info('Removed document: $documentId');
  }

  // ─── Clear Error ───────────────────────────────────────────────────

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

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CHAT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [DocumentChatNotifier] with all required use cases.
final documentChatProvider =
    StateNotifierProvider<DocumentChatNotifier, DocumentChatState>((ref) {
  return DocumentChatNotifier(
    uploadDocument: ref.watch(uploadDocumentUseCaseProvider),
    getDocuments: ref.watch(getDocumentsUseCaseProvider),
    sendDocumentMessage: ref.watch(sendDocumentMessageUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
    schoolId: ref.watch(studentSchoolIdProvider),
  );
});
